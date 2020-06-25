
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-01-10
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
                                   default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                   default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                   default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                   default = newJString("2013-01-10"))
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
          Version: string = "2013-01-10"): Recallable =
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
                                   default = newJString("2013-01-10"))
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
          CIDRIP: string = ""; Version: string = "2013-01-10";
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
                                   default = newJString("2013-01-10"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
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
  Call_PostCopyDBSnapshot_21626130 = ref object of OpenApiRestCall_21625418
proc url_PostCopyDBSnapshot_21626132(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_21626131(path: JsonNode; query: JsonNode;
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
  var valid_21626133 = query.getOrDefault("Action")
  valid_21626133 = validateParameter(valid_21626133, JString, required = true,
                                   default = newJString("CopyDBSnapshot"))
  if valid_21626133 != nil:
    section.add "Action", valid_21626133
  var valid_21626134 = query.getOrDefault("Version")
  valid_21626134 = validateParameter(valid_21626134, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626134 != nil:
    section.add "Version", valid_21626134
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
  var valid_21626135 = header.getOrDefault("X-Amz-Date")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Date", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Security-Token", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Algorithm", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Signature")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Signature", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Credential")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Credential", valid_21626141
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_21626142 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_21626142 = validateParameter(valid_21626142, JString, required = true,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_21626142
  var valid_21626143 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_21626143 = validateParameter(valid_21626143, JString, required = true,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_21626143
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626144: Call_PostCopyDBSnapshot_21626130; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626144.validator(path, query, header, formData, body, _)
  let scheme = call_21626144.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626144.makeUrl(scheme.get, call_21626144.host, call_21626144.base,
                               call_21626144.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626144, uri, valid, _)

proc call*(call_21626145: Call_PostCopyDBSnapshot_21626130;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_21626146 = newJObject()
  var formData_21626147 = newJObject()
  add(formData_21626147, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_21626146, "Action", newJString(Action))
  add(formData_21626147, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_21626146, "Version", newJString(Version))
  result = call_21626145.call(nil, query_21626146, nil, formData_21626147, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_21626130(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_21626131, base: "/",
    makeUrl: url_PostCopyDBSnapshot_21626132, schemes: {Scheme.Https, Scheme.Http})
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
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_21626116 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_21626116
  var valid_21626117 = query.getOrDefault("Action")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = newJString("CopyDBSnapshot"))
  if valid_21626117 != nil:
    section.add "Action", valid_21626117
  var valid_21626118 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_21626118
  var valid_21626119 = query.getOrDefault("Version")
  valid_21626119 = validateParameter(valid_21626119, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626119 != nil:
    section.add "Version", valid_21626119
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
  var valid_21626120 = header.getOrDefault("X-Amz-Date")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Date", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Security-Token", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Algorithm", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Signature")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Signature", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Credential")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Credential", valid_21626126
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626127: Call_GetCopyDBSnapshot_21626113; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626127.validator(path, query, header, formData, body, _)
  let scheme = call_21626127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626127.makeUrl(scheme.get, call_21626127.host, call_21626127.base,
                               call_21626127.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626127, uri, valid, _)

proc call*(call_21626128: Call_GetCopyDBSnapshot_21626113;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_21626129 = newJObject()
  add(query_21626129, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_21626129, "Action", newJString(Action))
  add(query_21626129, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_21626129, "Version", newJString(Version))
  result = call_21626128.call(nil, query_21626129, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_21626113(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_21626114,
    base: "/", makeUrl: url_GetCopyDBSnapshot_21626115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_21626187 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBInstance_21626189(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_21626188(path: JsonNode; query: JsonNode;
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
  var valid_21626190 = query.getOrDefault("Action")
  valid_21626190 = validateParameter(valid_21626190, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626190 != nil:
    section.add "Action", valid_21626190
  var valid_21626191 = query.getOrDefault("Version")
  valid_21626191 = validateParameter(valid_21626191, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626191 != nil:
    section.add "Version", valid_21626191
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
  var valid_21626192 = header.getOrDefault("X-Amz-Date")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Date", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Security-Token", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Algorithm", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Signature")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Signature", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Credential")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Credential", valid_21626198
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
  var valid_21626199 = formData.getOrDefault("DBSecurityGroups")
  valid_21626199 = validateParameter(valid_21626199, JArray, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "DBSecurityGroups", valid_21626199
  var valid_21626200 = formData.getOrDefault("Port")
  valid_21626200 = validateParameter(valid_21626200, JInt, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "Port", valid_21626200
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21626201 = formData.getOrDefault("Engine")
  valid_21626201 = validateParameter(valid_21626201, JString, required = true,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "Engine", valid_21626201
  var valid_21626202 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21626202 = validateParameter(valid_21626202, JArray, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "VpcSecurityGroupIds", valid_21626202
  var valid_21626203 = formData.getOrDefault("Iops")
  valid_21626203 = validateParameter(valid_21626203, JInt, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "Iops", valid_21626203
  var valid_21626204 = formData.getOrDefault("DBName")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "DBName", valid_21626204
  var valid_21626205 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626205 = validateParameter(valid_21626205, JString, required = true,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "DBInstanceIdentifier", valid_21626205
  var valid_21626206 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21626206 = validateParameter(valid_21626206, JInt, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "BackupRetentionPeriod", valid_21626206
  var valid_21626207 = formData.getOrDefault("DBParameterGroupName")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "DBParameterGroupName", valid_21626207
  var valid_21626208 = formData.getOrDefault("OptionGroupName")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "OptionGroupName", valid_21626208
  var valid_21626209 = formData.getOrDefault("MasterUserPassword")
  valid_21626209 = validateParameter(valid_21626209, JString, required = true,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "MasterUserPassword", valid_21626209
  var valid_21626210 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "DBSubnetGroupName", valid_21626210
  var valid_21626211 = formData.getOrDefault("AvailabilityZone")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "AvailabilityZone", valid_21626211
  var valid_21626212 = formData.getOrDefault("MultiAZ")
  valid_21626212 = validateParameter(valid_21626212, JBool, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "MultiAZ", valid_21626212
  var valid_21626213 = formData.getOrDefault("AllocatedStorage")
  valid_21626213 = validateParameter(valid_21626213, JInt, required = true,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "AllocatedStorage", valid_21626213
  var valid_21626214 = formData.getOrDefault("PubliclyAccessible")
  valid_21626214 = validateParameter(valid_21626214, JBool, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "PubliclyAccessible", valid_21626214
  var valid_21626215 = formData.getOrDefault("MasterUsername")
  valid_21626215 = validateParameter(valid_21626215, JString, required = true,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "MasterUsername", valid_21626215
  var valid_21626216 = formData.getOrDefault("DBInstanceClass")
  valid_21626216 = validateParameter(valid_21626216, JString, required = true,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "DBInstanceClass", valid_21626216
  var valid_21626217 = formData.getOrDefault("CharacterSetName")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "CharacterSetName", valid_21626217
  var valid_21626218 = formData.getOrDefault("PreferredBackupWindow")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "PreferredBackupWindow", valid_21626218
  var valid_21626219 = formData.getOrDefault("LicenseModel")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "LicenseModel", valid_21626219
  var valid_21626220 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626220 = validateParameter(valid_21626220, JBool, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626220
  var valid_21626221 = formData.getOrDefault("EngineVersion")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "EngineVersion", valid_21626221
  var valid_21626222 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626222
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626223: Call_PostCreateDBInstance_21626187; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626223.validator(path, query, header, formData, body, _)
  let scheme = call_21626223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626223.makeUrl(scheme.get, call_21626223.host, call_21626223.base,
                               call_21626223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626223, uri, valid, _)

proc call*(call_21626224: Call_PostCreateDBInstance_21626187; Engine: string;
          DBInstanceIdentifier: string; MasterUserPassword: string;
          AllocatedStorage: int; MasterUsername: string; DBInstanceClass: string;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0; DBName: string = "";
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "CreateDBInstance"; PubliclyAccessible: bool = false;
          CharacterSetName: string = ""; PreferredBackupWindow: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Version: string = "2013-01-10";
          PreferredMaintenanceWindow: string = ""): Recallable =
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
  var query_21626225 = newJObject()
  var formData_21626226 = newJObject()
  if DBSecurityGroups != nil:
    formData_21626226.add "DBSecurityGroups", DBSecurityGroups
  add(formData_21626226, "Port", newJInt(Port))
  add(formData_21626226, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_21626226.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21626226, "Iops", newJInt(Iops))
  add(formData_21626226, "DBName", newJString(DBName))
  add(formData_21626226, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626226, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_21626226, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21626226, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21626226, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21626226, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21626226, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21626226, "MultiAZ", newJBool(MultiAZ))
  add(query_21626225, "Action", newJString(Action))
  add(formData_21626226, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_21626226, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21626226, "MasterUsername", newJString(MasterUsername))
  add(formData_21626226, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21626226, "CharacterSetName", newJString(CharacterSetName))
  add(formData_21626226, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21626226, "LicenseModel", newJString(LicenseModel))
  add(formData_21626226, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_21626226, "EngineVersion", newJString(EngineVersion))
  add(query_21626225, "Version", newJString(Version))
  add(formData_21626226, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_21626224.call(nil, query_21626225, nil, formData_21626226, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_21626187(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_21626188, base: "/",
    makeUrl: url_PostCreateDBInstance_21626189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_21626148 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBInstance_21626150(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_21626149(path: JsonNode; query: JsonNode;
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
  var valid_21626151 = query.getOrDefault("Engine")
  valid_21626151 = validateParameter(valid_21626151, JString, required = true,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "Engine", valid_21626151
  var valid_21626152 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626152
  var valid_21626153 = query.getOrDefault("AllocatedStorage")
  valid_21626153 = validateParameter(valid_21626153, JInt, required = true,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "AllocatedStorage", valid_21626153
  var valid_21626154 = query.getOrDefault("OptionGroupName")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "OptionGroupName", valid_21626154
  var valid_21626155 = query.getOrDefault("DBSecurityGroups")
  valid_21626155 = validateParameter(valid_21626155, JArray, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "DBSecurityGroups", valid_21626155
  var valid_21626156 = query.getOrDefault("MasterUserPassword")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "MasterUserPassword", valid_21626156
  var valid_21626157 = query.getOrDefault("AvailabilityZone")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "AvailabilityZone", valid_21626157
  var valid_21626158 = query.getOrDefault("Iops")
  valid_21626158 = validateParameter(valid_21626158, JInt, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "Iops", valid_21626158
  var valid_21626159 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21626159 = validateParameter(valid_21626159, JArray, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "VpcSecurityGroupIds", valid_21626159
  var valid_21626160 = query.getOrDefault("MultiAZ")
  valid_21626160 = validateParameter(valid_21626160, JBool, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "MultiAZ", valid_21626160
  var valid_21626161 = query.getOrDefault("LicenseModel")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "LicenseModel", valid_21626161
  var valid_21626162 = query.getOrDefault("BackupRetentionPeriod")
  valid_21626162 = validateParameter(valid_21626162, JInt, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "BackupRetentionPeriod", valid_21626162
  var valid_21626163 = query.getOrDefault("DBName")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "DBName", valid_21626163
  var valid_21626164 = query.getOrDefault("DBParameterGroupName")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "DBParameterGroupName", valid_21626164
  var valid_21626165 = query.getOrDefault("DBInstanceClass")
  valid_21626165 = validateParameter(valid_21626165, JString, required = true,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "DBInstanceClass", valid_21626165
  var valid_21626166 = query.getOrDefault("Action")
  valid_21626166 = validateParameter(valid_21626166, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626166 != nil:
    section.add "Action", valid_21626166
  var valid_21626167 = query.getOrDefault("DBSubnetGroupName")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "DBSubnetGroupName", valid_21626167
  var valid_21626168 = query.getOrDefault("CharacterSetName")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "CharacterSetName", valid_21626168
  var valid_21626169 = query.getOrDefault("PubliclyAccessible")
  valid_21626169 = validateParameter(valid_21626169, JBool, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "PubliclyAccessible", valid_21626169
  var valid_21626170 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626170 = validateParameter(valid_21626170, JBool, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626170
  var valid_21626171 = query.getOrDefault("EngineVersion")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "EngineVersion", valid_21626171
  var valid_21626172 = query.getOrDefault("Port")
  valid_21626172 = validateParameter(valid_21626172, JInt, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "Port", valid_21626172
  var valid_21626173 = query.getOrDefault("PreferredBackupWindow")
  valid_21626173 = validateParameter(valid_21626173, JString, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "PreferredBackupWindow", valid_21626173
  var valid_21626174 = query.getOrDefault("Version")
  valid_21626174 = validateParameter(valid_21626174, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626174 != nil:
    section.add "Version", valid_21626174
  var valid_21626175 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626175 = validateParameter(valid_21626175, JString, required = true,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "DBInstanceIdentifier", valid_21626175
  var valid_21626176 = query.getOrDefault("MasterUsername")
  valid_21626176 = validateParameter(valid_21626176, JString, required = true,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "MasterUsername", valid_21626176
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
  var valid_21626177 = header.getOrDefault("X-Amz-Date")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Date", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Security-Token", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Algorithm", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Signature")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Signature", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Credential")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Credential", valid_21626183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626184: Call_GetCreateDBInstance_21626148; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626184.validator(path, query, header, formData, body, _)
  let scheme = call_21626184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626184.makeUrl(scheme.get, call_21626184.host, call_21626184.base,
                               call_21626184.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626184, uri, valid, _)

proc call*(call_21626185: Call_GetCreateDBInstance_21626148; Engine: string;
          AllocatedStorage: int; MasterUserPassword: string;
          DBInstanceClass: string; DBInstanceIdentifier: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          OptionGroupName: string = ""; DBSecurityGroups: JsonNode = nil;
          AvailabilityZone: string = ""; Iops: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          LicenseModel: string = ""; BackupRetentionPeriod: int = 0;
          DBName: string = ""; DBParameterGroupName: string = "";
          Action: string = "CreateDBInstance"; DBSubnetGroupName: string = "";
          CharacterSetName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
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
  var query_21626186 = newJObject()
  add(query_21626186, "Engine", newJString(Engine))
  add(query_21626186, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21626186, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_21626186, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_21626186.add "DBSecurityGroups", DBSecurityGroups
  add(query_21626186, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_21626186, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626186, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_21626186.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_21626186, "MultiAZ", newJBool(MultiAZ))
  add(query_21626186, "LicenseModel", newJString(LicenseModel))
  add(query_21626186, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21626186, "DBName", newJString(DBName))
  add(query_21626186, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626186, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21626186, "Action", newJString(Action))
  add(query_21626186, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626186, "CharacterSetName", newJString(CharacterSetName))
  add(query_21626186, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21626186, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21626186, "EngineVersion", newJString(EngineVersion))
  add(query_21626186, "Port", newJInt(Port))
  add(query_21626186, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21626186, "Version", newJString(Version))
  add(query_21626186, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626186, "MasterUsername", newJString(MasterUsername))
  result = call_21626185.call(nil, query_21626186, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_21626148(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_21626149, base: "/",
    makeUrl: url_GetCreateDBInstance_21626150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_21626251 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBInstanceReadReplica_21626253(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_21626252(path: JsonNode;
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
  var valid_21626254 = query.getOrDefault("Action")
  valid_21626254 = validateParameter(valid_21626254, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_21626254 != nil:
    section.add "Action", valid_21626254
  var valid_21626255 = query.getOrDefault("Version")
  valid_21626255 = validateParameter(valid_21626255, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626255 != nil:
    section.add "Version", valid_21626255
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
  var valid_21626256 = header.getOrDefault("X-Amz-Date")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Date", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Security-Token", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Algorithm", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Signature")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Signature", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Credential")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Credential", valid_21626262
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21626263 = formData.getOrDefault("Port")
  valid_21626263 = validateParameter(valid_21626263, JInt, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "Port", valid_21626263
  var valid_21626264 = formData.getOrDefault("Iops")
  valid_21626264 = validateParameter(valid_21626264, JInt, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "Iops", valid_21626264
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626265 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626265 = validateParameter(valid_21626265, JString, required = true,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "DBInstanceIdentifier", valid_21626265
  var valid_21626266 = formData.getOrDefault("OptionGroupName")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "OptionGroupName", valid_21626266
  var valid_21626267 = formData.getOrDefault("AvailabilityZone")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "AvailabilityZone", valid_21626267
  var valid_21626268 = formData.getOrDefault("PubliclyAccessible")
  valid_21626268 = validateParameter(valid_21626268, JBool, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "PubliclyAccessible", valid_21626268
  var valid_21626269 = formData.getOrDefault("DBInstanceClass")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "DBInstanceClass", valid_21626269
  var valid_21626270 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_21626270 = validateParameter(valid_21626270, JString, required = true,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21626270
  var valid_21626271 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626271 = validateParameter(valid_21626271, JBool, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626271
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626272: Call_PostCreateDBInstanceReadReplica_21626251;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626272.validator(path, query, header, formData, body, _)
  let scheme = call_21626272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626272.makeUrl(scheme.get, call_21626272.host, call_21626272.base,
                               call_21626272.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626272, uri, valid, _)

proc call*(call_21626273: Call_PostCreateDBInstanceReadReplica_21626251;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = "";
          AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   Port: int
  ##   Iops: int
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_21626274 = newJObject()
  var formData_21626275 = newJObject()
  add(formData_21626275, "Port", newJInt(Port))
  add(formData_21626275, "Iops", newJInt(Iops))
  add(formData_21626275, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626275, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21626275, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626274, "Action", newJString(Action))
  add(formData_21626275, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21626275, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21626275, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_21626275, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21626274, "Version", newJString(Version))
  result = call_21626273.call(nil, query_21626274, nil, formData_21626275, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_21626251(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_21626252, base: "/",
    makeUrl: url_PostCreateDBInstanceReadReplica_21626253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_21626227 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBInstanceReadReplica_21626229(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_21626228(path: JsonNode;
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
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_21626230 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_21626230 = validateParameter(valid_21626230, JString, required = true,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21626230
  var valid_21626231 = query.getOrDefault("OptionGroupName")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "OptionGroupName", valid_21626231
  var valid_21626232 = query.getOrDefault("AvailabilityZone")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "AvailabilityZone", valid_21626232
  var valid_21626233 = query.getOrDefault("Iops")
  valid_21626233 = validateParameter(valid_21626233, JInt, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "Iops", valid_21626233
  var valid_21626234 = query.getOrDefault("DBInstanceClass")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "DBInstanceClass", valid_21626234
  var valid_21626235 = query.getOrDefault("Action")
  valid_21626235 = validateParameter(valid_21626235, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_21626235 != nil:
    section.add "Action", valid_21626235
  var valid_21626236 = query.getOrDefault("PubliclyAccessible")
  valid_21626236 = validateParameter(valid_21626236, JBool, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "PubliclyAccessible", valid_21626236
  var valid_21626237 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626237 = validateParameter(valid_21626237, JBool, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626237
  var valid_21626238 = query.getOrDefault("Port")
  valid_21626238 = validateParameter(valid_21626238, JInt, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "Port", valid_21626238
  var valid_21626239 = query.getOrDefault("Version")
  valid_21626239 = validateParameter(valid_21626239, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626239 != nil:
    section.add "Version", valid_21626239
  var valid_21626240 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626240 = validateParameter(valid_21626240, JString, required = true,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "DBInstanceIdentifier", valid_21626240
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
  var valid_21626241 = header.getOrDefault("X-Amz-Date")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Date", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-Security-Token", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Algorithm", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Signature")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Signature", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Credential")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Credential", valid_21626247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626248: Call_GetCreateDBInstanceReadReplica_21626227;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626248.validator(path, query, header, formData, body, _)
  let scheme = call_21626248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626248.makeUrl(scheme.get, call_21626248.host, call_21626248.base,
                               call_21626248.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626248, uri, valid, _)

proc call*(call_21626249: Call_GetCreateDBInstanceReadReplica_21626227;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          OptionGroupName: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   SourceDBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21626250 = newJObject()
  add(query_21626250, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_21626250, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626250, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626250, "Iops", newJInt(Iops))
  add(query_21626250, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21626250, "Action", newJString(Action))
  add(query_21626250, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21626250, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21626250, "Port", newJInt(Port))
  add(query_21626250, "Version", newJString(Version))
  add(query_21626250, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626249.call(nil, query_21626250, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_21626227(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_21626228, base: "/",
    makeUrl: url_GetCreateDBInstanceReadReplica_21626229,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_21626294 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBParameterGroup_21626296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_21626295(path: JsonNode; query: JsonNode;
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
  var valid_21626297 = query.getOrDefault("Action")
  valid_21626297 = validateParameter(valid_21626297, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_21626297 != nil:
    section.add "Action", valid_21626297
  var valid_21626298 = query.getOrDefault("Version")
  valid_21626298 = validateParameter(valid_21626298, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626298 != nil:
    section.add "Version", valid_21626298
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
  var valid_21626299 = header.getOrDefault("X-Amz-Date")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Date", valid_21626299
  var valid_21626300 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626300 = validateParameter(valid_21626300, JString, required = false,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "X-Amz-Security-Token", valid_21626300
  var valid_21626301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626301 = validateParameter(valid_21626301, JString, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626301
  var valid_21626302 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626302 = validateParameter(valid_21626302, JString, required = false,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "X-Amz-Algorithm", valid_21626302
  var valid_21626303 = header.getOrDefault("X-Amz-Signature")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Signature", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Credential")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Credential", valid_21626305
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626306 = formData.getOrDefault("DBParameterGroupName")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "DBParameterGroupName", valid_21626306
  var valid_21626307 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "DBParameterGroupFamily", valid_21626307
  var valid_21626308 = formData.getOrDefault("Description")
  valid_21626308 = validateParameter(valid_21626308, JString, required = true,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "Description", valid_21626308
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626309: Call_PostCreateDBParameterGroup_21626294;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626309.validator(path, query, header, formData, body, _)
  let scheme = call_21626309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626309.makeUrl(scheme.get, call_21626309.host, call_21626309.base,
                               call_21626309.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626309, uri, valid, _)

proc call*(call_21626310: Call_PostCreateDBParameterGroup_21626294;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_21626311 = newJObject()
  var formData_21626312 = newJObject()
  add(formData_21626312, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626311, "Action", newJString(Action))
  add(formData_21626312, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_21626311, "Version", newJString(Version))
  add(formData_21626312, "Description", newJString(Description))
  result = call_21626310.call(nil, query_21626311, nil, formData_21626312, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_21626294(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_21626295, base: "/",
    makeUrl: url_PostCreateDBParameterGroup_21626296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_21626276 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBParameterGroup_21626278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_21626277(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Description: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Description` field"
  var valid_21626279 = query.getOrDefault("Description")
  valid_21626279 = validateParameter(valid_21626279, JString, required = true,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "Description", valid_21626279
  var valid_21626280 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626280 = validateParameter(valid_21626280, JString, required = true,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "DBParameterGroupFamily", valid_21626280
  var valid_21626281 = query.getOrDefault("DBParameterGroupName")
  valid_21626281 = validateParameter(valid_21626281, JString, required = true,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "DBParameterGroupName", valid_21626281
  var valid_21626282 = query.getOrDefault("Action")
  valid_21626282 = validateParameter(valid_21626282, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_21626282 != nil:
    section.add "Action", valid_21626282
  var valid_21626283 = query.getOrDefault("Version")
  valid_21626283 = validateParameter(valid_21626283, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626283 != nil:
    section.add "Version", valid_21626283
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
  var valid_21626284 = header.getOrDefault("X-Amz-Date")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-Date", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Security-Token", valid_21626285
  var valid_21626286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626286 = validateParameter(valid_21626286, JString, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626286
  var valid_21626287 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626287 = validateParameter(valid_21626287, JString, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "X-Amz-Algorithm", valid_21626287
  var valid_21626288 = header.getOrDefault("X-Amz-Signature")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Signature", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Credential")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Credential", valid_21626290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626291: Call_GetCreateDBParameterGroup_21626276;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626291.validator(path, query, header, formData, body, _)
  let scheme = call_21626291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626291.makeUrl(scheme.get, call_21626291.host, call_21626291.base,
                               call_21626291.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626291, uri, valid, _)

proc call*(call_21626292: Call_GetCreateDBParameterGroup_21626276;
          Description: string; DBParameterGroupFamily: string;
          DBParameterGroupName: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626293 = newJObject()
  add(query_21626293, "Description", newJString(Description))
  add(query_21626293, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_21626293, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626293, "Action", newJString(Action))
  add(query_21626293, "Version", newJString(Version))
  result = call_21626292.call(nil, query_21626293, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_21626276(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_21626277, base: "/",
    makeUrl: url_GetCreateDBParameterGroup_21626278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_21626330 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSecurityGroup_21626332(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_21626331(path: JsonNode; query: JsonNode;
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
  var valid_21626333 = query.getOrDefault("Action")
  valid_21626333 = validateParameter(valid_21626333, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_21626333 != nil:
    section.add "Action", valid_21626333
  var valid_21626334 = query.getOrDefault("Version")
  valid_21626334 = validateParameter(valid_21626334, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626334 != nil:
    section.add "Version", valid_21626334
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
  var valid_21626335 = header.getOrDefault("X-Amz-Date")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Date", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Security-Token", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Algorithm", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Signature")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Signature", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Credential")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Credential", valid_21626341
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626342 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626342 = validateParameter(valid_21626342, JString, required = true,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "DBSecurityGroupName", valid_21626342
  var valid_21626343 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_21626343 = validateParameter(valid_21626343, JString, required = true,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "DBSecurityGroupDescription", valid_21626343
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626344: Call_PostCreateDBSecurityGroup_21626330;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626344.validator(path, query, header, formData, body, _)
  let scheme = call_21626344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626344.makeUrl(scheme.get, call_21626344.host, call_21626344.base,
                               call_21626344.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626344, uri, valid, _)

proc call*(call_21626345: Call_PostCreateDBSecurityGroup_21626330;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626346 = newJObject()
  var formData_21626347 = newJObject()
  add(formData_21626347, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626346, "Action", newJString(Action))
  add(formData_21626347, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_21626346, "Version", newJString(Version))
  result = call_21626345.call(nil, query_21626346, nil, formData_21626347, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_21626330(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_21626331, base: "/",
    makeUrl: url_PostCreateDBSecurityGroup_21626332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_21626313 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSecurityGroup_21626315(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_21626314(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626316 = query.getOrDefault("DBSecurityGroupName")
  valid_21626316 = validateParameter(valid_21626316, JString, required = true,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "DBSecurityGroupName", valid_21626316
  var valid_21626317 = query.getOrDefault("DBSecurityGroupDescription")
  valid_21626317 = validateParameter(valid_21626317, JString, required = true,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "DBSecurityGroupDescription", valid_21626317
  var valid_21626318 = query.getOrDefault("Action")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_21626318 != nil:
    section.add "Action", valid_21626318
  var valid_21626319 = query.getOrDefault("Version")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626319 != nil:
    section.add "Version", valid_21626319
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
  var valid_21626320 = header.getOrDefault("X-Amz-Date")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Date", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Security-Token", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Algorithm", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Signature")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Signature", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Credential")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Credential", valid_21626326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626327: Call_GetCreateDBSecurityGroup_21626313;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626327.validator(path, query, header, formData, body, _)
  let scheme = call_21626327.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626327.makeUrl(scheme.get, call_21626327.host, call_21626327.base,
                               call_21626327.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626327, uri, valid, _)

proc call*(call_21626328: Call_GetCreateDBSecurityGroup_21626313;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626329 = newJObject()
  add(query_21626329, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626329, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_21626329, "Action", newJString(Action))
  add(query_21626329, "Version", newJString(Version))
  result = call_21626328.call(nil, query_21626329, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_21626313(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_21626314, base: "/",
    makeUrl: url_GetCreateDBSecurityGroup_21626315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_21626365 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSnapshot_21626367(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_21626366(path: JsonNode; query: JsonNode;
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
  var valid_21626368 = query.getOrDefault("Action")
  valid_21626368 = validateParameter(valid_21626368, JString, required = true,
                                   default = newJString("CreateDBSnapshot"))
  if valid_21626368 != nil:
    section.add "Action", valid_21626368
  var valid_21626369 = query.getOrDefault("Version")
  valid_21626369 = validateParameter(valid_21626369, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626369 != nil:
    section.add "Version", valid_21626369
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
  var valid_21626370 = header.getOrDefault("X-Amz-Date")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Date", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Security-Token", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-Algorithm", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Signature")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Signature", valid_21626374
  var valid_21626375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626375 = validateParameter(valid_21626375, JString, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626375
  var valid_21626376 = header.getOrDefault("X-Amz-Credential")
  valid_21626376 = validateParameter(valid_21626376, JString, required = false,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "X-Amz-Credential", valid_21626376
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626377 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626377 = validateParameter(valid_21626377, JString, required = true,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "DBInstanceIdentifier", valid_21626377
  var valid_21626378 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21626378 = validateParameter(valid_21626378, JString, required = true,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "DBSnapshotIdentifier", valid_21626378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626379: Call_PostCreateDBSnapshot_21626365; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626379.validator(path, query, header, formData, body, _)
  let scheme = call_21626379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626379.makeUrl(scheme.get, call_21626379.host, call_21626379.base,
                               call_21626379.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626379, uri, valid, _)

proc call*(call_21626380: Call_PostCreateDBSnapshot_21626365;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626381 = newJObject()
  var formData_21626382 = newJObject()
  add(formData_21626382, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626382, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21626381, "Action", newJString(Action))
  add(query_21626381, "Version", newJString(Version))
  result = call_21626380.call(nil, query_21626381, nil, formData_21626382, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_21626365(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_21626366, base: "/",
    makeUrl: url_PostCreateDBSnapshot_21626367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_21626348 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSnapshot_21626350(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_21626349(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_21626351 = query.getOrDefault("Action")
  valid_21626351 = validateParameter(valid_21626351, JString, required = true,
                                   default = newJString("CreateDBSnapshot"))
  if valid_21626351 != nil:
    section.add "Action", valid_21626351
  var valid_21626352 = query.getOrDefault("Version")
  valid_21626352 = validateParameter(valid_21626352, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626352 != nil:
    section.add "Version", valid_21626352
  var valid_21626353 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626353 = validateParameter(valid_21626353, JString, required = true,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "DBInstanceIdentifier", valid_21626353
  var valid_21626354 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21626354 = validateParameter(valid_21626354, JString, required = true,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "DBSnapshotIdentifier", valid_21626354
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
  var valid_21626355 = header.getOrDefault("X-Amz-Date")
  valid_21626355 = validateParameter(valid_21626355, JString, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "X-Amz-Date", valid_21626355
  var valid_21626356 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626356 = validateParameter(valid_21626356, JString, required = false,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "X-Amz-Security-Token", valid_21626356
  var valid_21626357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626357
  var valid_21626358 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Algorithm", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Signature")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Signature", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Credential")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Credential", valid_21626361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626362: Call_GetCreateDBSnapshot_21626348; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626362.validator(path, query, header, formData, body, _)
  let scheme = call_21626362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626362.makeUrl(scheme.get, call_21626362.host, call_21626362.base,
                               call_21626362.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626362, uri, valid, _)

proc call*(call_21626363: Call_GetCreateDBSnapshot_21626348;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21626364 = newJObject()
  add(query_21626364, "Action", newJString(Action))
  add(query_21626364, "Version", newJString(Version))
  add(query_21626364, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626364, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21626363.call(nil, query_21626364, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_21626348(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_21626349, base: "/",
    makeUrl: url_GetCreateDBSnapshot_21626350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_21626401 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSubnetGroup_21626403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_21626402(path: JsonNode; query: JsonNode;
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
  var valid_21626404 = query.getOrDefault("Action")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626404 != nil:
    section.add "Action", valid_21626404
  var valid_21626405 = query.getOrDefault("Version")
  valid_21626405 = validateParameter(valid_21626405, JString, required = true,
                                   default = newJString("2013-01-10"))
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
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626413 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626413 = validateParameter(valid_21626413, JString, required = true,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "DBSubnetGroupName", valid_21626413
  var valid_21626414 = formData.getOrDefault("SubnetIds")
  valid_21626414 = validateParameter(valid_21626414, JArray, required = true,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "SubnetIds", valid_21626414
  var valid_21626415 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "DBSubnetGroupDescription", valid_21626415
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626416: Call_PostCreateDBSubnetGroup_21626401;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626416.validator(path, query, header, formData, body, _)
  let scheme = call_21626416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626416.makeUrl(scheme.get, call_21626416.host, call_21626416.base,
                               call_21626416.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626416, uri, valid, _)

proc call*(call_21626417: Call_PostCreateDBSubnetGroup_21626401;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626418 = newJObject()
  var formData_21626419 = newJObject()
  add(formData_21626419, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21626419.add "SubnetIds", SubnetIds
  add(query_21626418, "Action", newJString(Action))
  add(formData_21626419, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626418, "Version", newJString(Version))
  result = call_21626417.call(nil, query_21626418, nil, formData_21626419, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_21626401(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_21626402, base: "/",
    makeUrl: url_PostCreateDBSubnetGroup_21626403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_21626383 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSubnetGroup_21626385(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_21626384(path: JsonNode; query: JsonNode;
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
  ##   DBSubnetGroupDescription: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626386 = query.getOrDefault("Action")
  valid_21626386 = validateParameter(valid_21626386, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626386 != nil:
    section.add "Action", valid_21626386
  var valid_21626387 = query.getOrDefault("DBSubnetGroupName")
  valid_21626387 = validateParameter(valid_21626387, JString, required = true,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "DBSubnetGroupName", valid_21626387
  var valid_21626388 = query.getOrDefault("SubnetIds")
  valid_21626388 = validateParameter(valid_21626388, JArray, required = true,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "SubnetIds", valid_21626388
  var valid_21626389 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21626389 = validateParameter(valid_21626389, JString, required = true,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "DBSubnetGroupDescription", valid_21626389
  var valid_21626390 = query.getOrDefault("Version")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626390 != nil:
    section.add "Version", valid_21626390
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
  var valid_21626391 = header.getOrDefault("X-Amz-Date")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Date", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Security-Token", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626398: Call_GetCreateDBSubnetGroup_21626383;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_GetCreateDBSubnetGroup_21626383;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626400 = newJObject()
  add(query_21626400, "Action", newJString(Action))
  add(query_21626400, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21626400.add "SubnetIds", SubnetIds
  add(query_21626400, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626400, "Version", newJString(Version))
  result = call_21626399.call(nil, query_21626400, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_21626383(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_21626384, base: "/",
    makeUrl: url_GetCreateDBSubnetGroup_21626385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_21626441 = ref object of OpenApiRestCall_21625418
proc url_PostCreateEventSubscription_21626443(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_21626442(path: JsonNode; query: JsonNode;
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
  var valid_21626444 = query.getOrDefault("Action")
  valid_21626444 = validateParameter(valid_21626444, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_21626444 != nil:
    section.add "Action", valid_21626444
  var valid_21626445 = query.getOrDefault("Version")
  valid_21626445 = validateParameter(valid_21626445, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626445 != nil:
    section.add "Version", valid_21626445
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
  var valid_21626446 = header.getOrDefault("X-Amz-Date")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Date", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Security-Token", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Algorithm", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Signature")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Signature", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Credential")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Credential", valid_21626452
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_21626453 = formData.getOrDefault("Enabled")
  valid_21626453 = validateParameter(valid_21626453, JBool, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "Enabled", valid_21626453
  var valid_21626454 = formData.getOrDefault("EventCategories")
  valid_21626454 = validateParameter(valid_21626454, JArray, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "EventCategories", valid_21626454
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_21626455 = formData.getOrDefault("SnsTopicArn")
  valid_21626455 = validateParameter(valid_21626455, JString, required = true,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "SnsTopicArn", valid_21626455
  var valid_21626456 = formData.getOrDefault("SourceIds")
  valid_21626456 = validateParameter(valid_21626456, JArray, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "SourceIds", valid_21626456
  var valid_21626457 = formData.getOrDefault("SubscriptionName")
  valid_21626457 = validateParameter(valid_21626457, JString, required = true,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "SubscriptionName", valid_21626457
  var valid_21626458 = formData.getOrDefault("SourceType")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "SourceType", valid_21626458
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626459: Call_PostCreateEventSubscription_21626441;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626459.validator(path, query, header, formData, body, _)
  let scheme = call_21626459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626459.makeUrl(scheme.get, call_21626459.host, call_21626459.base,
                               call_21626459.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626459, uri, valid, _)

proc call*(call_21626460: Call_PostCreateEventSubscription_21626441;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postCreateEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_21626461 = newJObject()
  var formData_21626462 = newJObject()
  add(formData_21626462, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_21626462.add "EventCategories", EventCategories
  add(formData_21626462, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_21626462.add "SourceIds", SourceIds
  add(formData_21626462, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626461, "Action", newJString(Action))
  add(query_21626461, "Version", newJString(Version))
  add(formData_21626462, "SourceType", newJString(SourceType))
  result = call_21626460.call(nil, query_21626461, nil, formData_21626462, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_21626441(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_21626442, base: "/",
    makeUrl: url_PostCreateEventSubscription_21626443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_21626420 = ref object of OpenApiRestCall_21625418
proc url_GetCreateEventSubscription_21626422(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_21626421(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626423 = query.getOrDefault("SourceType")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "SourceType", valid_21626423
  var valid_21626424 = query.getOrDefault("SourceIds")
  valid_21626424 = validateParameter(valid_21626424, JArray, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "SourceIds", valid_21626424
  var valid_21626425 = query.getOrDefault("Enabled")
  valid_21626425 = validateParameter(valid_21626425, JBool, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "Enabled", valid_21626425
  var valid_21626426 = query.getOrDefault("Action")
  valid_21626426 = validateParameter(valid_21626426, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_21626426 != nil:
    section.add "Action", valid_21626426
  var valid_21626427 = query.getOrDefault("SnsTopicArn")
  valid_21626427 = validateParameter(valid_21626427, JString, required = true,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "SnsTopicArn", valid_21626427
  var valid_21626428 = query.getOrDefault("EventCategories")
  valid_21626428 = validateParameter(valid_21626428, JArray, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "EventCategories", valid_21626428
  var valid_21626429 = query.getOrDefault("SubscriptionName")
  valid_21626429 = validateParameter(valid_21626429, JString, required = true,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "SubscriptionName", valid_21626429
  var valid_21626430 = query.getOrDefault("Version")
  valid_21626430 = validateParameter(valid_21626430, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626430 != nil:
    section.add "Version", valid_21626430
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
  var valid_21626431 = header.getOrDefault("X-Amz-Date")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Date", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Security-Token", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Algorithm", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Signature")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Signature", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Credential")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Credential", valid_21626437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626438: Call_GetCreateEventSubscription_21626420;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626438.validator(path, query, header, formData, body, _)
  let scheme = call_21626438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626438.makeUrl(scheme.get, call_21626438.host, call_21626438.base,
                               call_21626438.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626438, uri, valid, _)

proc call*(call_21626439: Call_GetCreateEventSubscription_21626420;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2013-01-10"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21626440 = newJObject()
  add(query_21626440, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_21626440.add "SourceIds", SourceIds
  add(query_21626440, "Enabled", newJBool(Enabled))
  add(query_21626440, "Action", newJString(Action))
  add(query_21626440, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_21626440.add "EventCategories", EventCategories
  add(query_21626440, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626440, "Version", newJString(Version))
  result = call_21626439.call(nil, query_21626440, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_21626420(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_21626421, base: "/",
    makeUrl: url_GetCreateEventSubscription_21626422,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_21626482 = ref object of OpenApiRestCall_21625418
proc url_PostCreateOptionGroup_21626484(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_21626483(path: JsonNode; query: JsonNode;
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
  var valid_21626485 = query.getOrDefault("Action")
  valid_21626485 = validateParameter(valid_21626485, JString, required = true,
                                   default = newJString("CreateOptionGroup"))
  if valid_21626485 != nil:
    section.add "Action", valid_21626485
  var valid_21626486 = query.getOrDefault("Version")
  valid_21626486 = validateParameter(valid_21626486, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626486 != nil:
    section.add "Version", valid_21626486
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
  var valid_21626487 = header.getOrDefault("X-Amz-Date")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-Date", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Security-Token", valid_21626488
  var valid_21626489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626489 = validateParameter(valid_21626489, JString, required = false,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626489
  var valid_21626490 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626490 = validateParameter(valid_21626490, JString, required = false,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "X-Amz-Algorithm", valid_21626490
  var valid_21626491 = header.getOrDefault("X-Amz-Signature")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Signature", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Credential")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Credential", valid_21626493
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_21626494 = formData.getOrDefault("MajorEngineVersion")
  valid_21626494 = validateParameter(valid_21626494, JString, required = true,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "MajorEngineVersion", valid_21626494
  var valid_21626495 = formData.getOrDefault("OptionGroupName")
  valid_21626495 = validateParameter(valid_21626495, JString, required = true,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "OptionGroupName", valid_21626495
  var valid_21626496 = formData.getOrDefault("EngineName")
  valid_21626496 = validateParameter(valid_21626496, JString, required = true,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "EngineName", valid_21626496
  var valid_21626497 = formData.getOrDefault("OptionGroupDescription")
  valid_21626497 = validateParameter(valid_21626497, JString, required = true,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "OptionGroupDescription", valid_21626497
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626498: Call_PostCreateOptionGroup_21626482;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_PostCreateOptionGroup_21626482;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626500 = newJObject()
  var formData_21626501 = newJObject()
  add(formData_21626501, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21626501, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626500, "Action", newJString(Action))
  add(formData_21626501, "EngineName", newJString(EngineName))
  add(formData_21626501, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_21626500, "Version", newJString(Version))
  result = call_21626499.call(nil, query_21626500, nil, formData_21626501, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_21626482(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_21626483, base: "/",
    makeUrl: url_PostCreateOptionGroup_21626484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_21626463 = ref object of OpenApiRestCall_21625418
proc url_GetCreateOptionGroup_21626465(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_21626464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   OptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_21626466 = query.getOrDefault("OptionGroupName")
  valid_21626466 = validateParameter(valid_21626466, JString, required = true,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "OptionGroupName", valid_21626466
  var valid_21626467 = query.getOrDefault("OptionGroupDescription")
  valid_21626467 = validateParameter(valid_21626467, JString, required = true,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "OptionGroupDescription", valid_21626467
  var valid_21626468 = query.getOrDefault("Action")
  valid_21626468 = validateParameter(valid_21626468, JString, required = true,
                                   default = newJString("CreateOptionGroup"))
  if valid_21626468 != nil:
    section.add "Action", valid_21626468
  var valid_21626469 = query.getOrDefault("Version")
  valid_21626469 = validateParameter(valid_21626469, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626469 != nil:
    section.add "Version", valid_21626469
  var valid_21626470 = query.getOrDefault("EngineName")
  valid_21626470 = validateParameter(valid_21626470, JString, required = true,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "EngineName", valid_21626470
  var valid_21626471 = query.getOrDefault("MajorEngineVersion")
  valid_21626471 = validateParameter(valid_21626471, JString, required = true,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "MajorEngineVersion", valid_21626471
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
  var valid_21626472 = header.getOrDefault("X-Amz-Date")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Date", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Security-Token", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Algorithm", valid_21626475
  var valid_21626476 = header.getOrDefault("X-Amz-Signature")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "X-Amz-Signature", valid_21626476
  var valid_21626477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626477 = validateParameter(valid_21626477, JString, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626477
  var valid_21626478 = header.getOrDefault("X-Amz-Credential")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Credential", valid_21626478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626479: Call_GetCreateOptionGroup_21626463; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626479.validator(path, query, header, formData, body, _)
  let scheme = call_21626479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626479.makeUrl(scheme.get, call_21626479.host, call_21626479.base,
                               call_21626479.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626479, uri, valid, _)

proc call*(call_21626480: Call_GetCreateOptionGroup_21626463;
          OptionGroupName: string; OptionGroupDescription: string;
          EngineName: string; MajorEngineVersion: string;
          Action: string = "CreateOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_21626481 = newJObject()
  add(query_21626481, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626481, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_21626481, "Action", newJString(Action))
  add(query_21626481, "Version", newJString(Version))
  add(query_21626481, "EngineName", newJString(EngineName))
  add(query_21626481, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21626480.call(nil, query_21626481, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_21626463(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_21626464, base: "/",
    makeUrl: url_GetCreateOptionGroup_21626465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_21626520 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBInstance_21626522(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_21626521(path: JsonNode; query: JsonNode;
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
  var valid_21626523 = query.getOrDefault("Action")
  valid_21626523 = validateParameter(valid_21626523, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626523 != nil:
    section.add "Action", valid_21626523
  var valid_21626524 = query.getOrDefault("Version")
  valid_21626524 = validateParameter(valid_21626524, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626524 != nil:
    section.add "Version", valid_21626524
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
  var valid_21626525 = header.getOrDefault("X-Amz-Date")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "X-Amz-Date", valid_21626525
  var valid_21626526 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Security-Token", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Algorithm", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Signature")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Signature", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Credential")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Credential", valid_21626531
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626532 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626532 = validateParameter(valid_21626532, JString, required = true,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "DBInstanceIdentifier", valid_21626532
  var valid_21626533 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626533
  var valid_21626534 = formData.getOrDefault("SkipFinalSnapshot")
  valid_21626534 = validateParameter(valid_21626534, JBool, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "SkipFinalSnapshot", valid_21626534
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626535: Call_PostDeleteDBInstance_21626520; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626535.validator(path, query, header, formData, body, _)
  let scheme = call_21626535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626535.makeUrl(scheme.get, call_21626535.host, call_21626535.base,
                               call_21626535.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626535, uri, valid, _)

proc call*(call_21626536: Call_PostDeleteDBInstance_21626520;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_21626537 = newJObject()
  var formData_21626538 = newJObject()
  add(formData_21626538, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626538, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626537, "Action", newJString(Action))
  add(query_21626537, "Version", newJString(Version))
  add(formData_21626538, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_21626536.call(nil, query_21626537, nil, formData_21626538, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_21626520(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_21626521, base: "/",
    makeUrl: url_PostDeleteDBInstance_21626522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_21626502 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBInstance_21626504(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_21626503(path: JsonNode; query: JsonNode;
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
  var valid_21626505 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626505 = validateParameter(valid_21626505, JString, required = false,
                                   default = nil)
  if valid_21626505 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626505
  var valid_21626506 = query.getOrDefault("Action")
  valid_21626506 = validateParameter(valid_21626506, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626506 != nil:
    section.add "Action", valid_21626506
  var valid_21626507 = query.getOrDefault("SkipFinalSnapshot")
  valid_21626507 = validateParameter(valid_21626507, JBool, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "SkipFinalSnapshot", valid_21626507
  var valid_21626508 = query.getOrDefault("Version")
  valid_21626508 = validateParameter(valid_21626508, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626508 != nil:
    section.add "Version", valid_21626508
  var valid_21626509 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "DBInstanceIdentifier", valid_21626509
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
  var valid_21626510 = header.getOrDefault("X-Amz-Date")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Date", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Security-Token", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Algorithm", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Signature")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Signature", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Credential")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Credential", valid_21626516
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626517: Call_GetDeleteDBInstance_21626502; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626517.validator(path, query, header, formData, body, _)
  let scheme = call_21626517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626517.makeUrl(scheme.get, call_21626517.host, call_21626517.base,
                               call_21626517.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626517, uri, valid, _)

proc call*(call_21626518: Call_GetDeleteDBInstance_21626502;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21626519 = newJObject()
  add(query_21626519, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626519, "Action", newJString(Action))
  add(query_21626519, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_21626519, "Version", newJString(Version))
  add(query_21626519, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626518.call(nil, query_21626519, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_21626502(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_21626503, base: "/",
    makeUrl: url_GetDeleteDBInstance_21626504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_21626555 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBParameterGroup_21626557(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_21626556(path: JsonNode; query: JsonNode;
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
  var valid_21626558 = query.getOrDefault("Action")
  valid_21626558 = validateParameter(valid_21626558, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_21626558 != nil:
    section.add "Action", valid_21626558
  var valid_21626559 = query.getOrDefault("Version")
  valid_21626559 = validateParameter(valid_21626559, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626559 != nil:
    section.add "Version", valid_21626559
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
  var valid_21626560 = header.getOrDefault("X-Amz-Date")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Date", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Security-Token", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Algorithm", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-Signature")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-Signature", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Credential")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Credential", valid_21626566
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626567 = formData.getOrDefault("DBParameterGroupName")
  valid_21626567 = validateParameter(valid_21626567, JString, required = true,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "DBParameterGroupName", valid_21626567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626568: Call_PostDeleteDBParameterGroup_21626555;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626568.validator(path, query, header, formData, body, _)
  let scheme = call_21626568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626568.makeUrl(scheme.get, call_21626568.host, call_21626568.base,
                               call_21626568.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626568, uri, valid, _)

proc call*(call_21626569: Call_PostDeleteDBParameterGroup_21626555;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626570 = newJObject()
  var formData_21626571 = newJObject()
  add(formData_21626571, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626570, "Action", newJString(Action))
  add(query_21626570, "Version", newJString(Version))
  result = call_21626569.call(nil, query_21626570, nil, formData_21626571, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_21626555(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_21626556, base: "/",
    makeUrl: url_PostDeleteDBParameterGroup_21626557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_21626539 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBParameterGroup_21626541(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_21626540(path: JsonNode; query: JsonNode;
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
  var valid_21626542 = query.getOrDefault("DBParameterGroupName")
  valid_21626542 = validateParameter(valid_21626542, JString, required = true,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "DBParameterGroupName", valid_21626542
  var valid_21626543 = query.getOrDefault("Action")
  valid_21626543 = validateParameter(valid_21626543, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_21626543 != nil:
    section.add "Action", valid_21626543
  var valid_21626544 = query.getOrDefault("Version")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true,
                                   default = newJString("2013-01-10"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626552: Call_GetDeleteDBParameterGroup_21626539;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626552.validator(path, query, header, formData, body, _)
  let scheme = call_21626552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626552.makeUrl(scheme.get, call_21626552.host, call_21626552.base,
                               call_21626552.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626552, uri, valid, _)

proc call*(call_21626553: Call_GetDeleteDBParameterGroup_21626539;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626554 = newJObject()
  add(query_21626554, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626554, "Action", newJString(Action))
  add(query_21626554, "Version", newJString(Version))
  result = call_21626553.call(nil, query_21626554, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_21626539(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_21626540, base: "/",
    makeUrl: url_GetDeleteDBParameterGroup_21626541,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_21626588 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSecurityGroup_21626590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_21626589(path: JsonNode; query: JsonNode;
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
  var valid_21626591 = query.getOrDefault("Action")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_21626591 != nil:
    section.add "Action", valid_21626591
  var valid_21626592 = query.getOrDefault("Version")
  valid_21626592 = validateParameter(valid_21626592, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626592 != nil:
    section.add "Version", valid_21626592
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
  var valid_21626593 = header.getOrDefault("X-Amz-Date")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Date", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Security-Token", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Algorithm", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Signature")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Signature", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Credential")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Credential", valid_21626599
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626600 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626600 = validateParameter(valid_21626600, JString, required = true,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "DBSecurityGroupName", valid_21626600
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626601: Call_PostDeleteDBSecurityGroup_21626588;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626601.validator(path, query, header, formData, body, _)
  let scheme = call_21626601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626601.makeUrl(scheme.get, call_21626601.host, call_21626601.base,
                               call_21626601.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626601, uri, valid, _)

proc call*(call_21626602: Call_PostDeleteDBSecurityGroup_21626588;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626603 = newJObject()
  var formData_21626604 = newJObject()
  add(formData_21626604, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626603, "Action", newJString(Action))
  add(query_21626603, "Version", newJString(Version))
  result = call_21626602.call(nil, query_21626603, nil, formData_21626604, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_21626588(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_21626589, base: "/",
    makeUrl: url_PostDeleteDBSecurityGroup_21626590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_21626572 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSecurityGroup_21626574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_21626573(path: JsonNode; query: JsonNode;
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
  var valid_21626575 = query.getOrDefault("DBSecurityGroupName")
  valid_21626575 = validateParameter(valid_21626575, JString, required = true,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "DBSecurityGroupName", valid_21626575
  var valid_21626576 = query.getOrDefault("Action")
  valid_21626576 = validateParameter(valid_21626576, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_21626576 != nil:
    section.add "Action", valid_21626576
  var valid_21626577 = query.getOrDefault("Version")
  valid_21626577 = validateParameter(valid_21626577, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626577 != nil:
    section.add "Version", valid_21626577
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
  var valid_21626578 = header.getOrDefault("X-Amz-Date")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Date", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Security-Token", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Algorithm", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Signature")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Signature", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Credential")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Credential", valid_21626584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626585: Call_GetDeleteDBSecurityGroup_21626572;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626585.validator(path, query, header, formData, body, _)
  let scheme = call_21626585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626585.makeUrl(scheme.get, call_21626585.host, call_21626585.base,
                               call_21626585.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626585, uri, valid, _)

proc call*(call_21626586: Call_GetDeleteDBSecurityGroup_21626572;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626587 = newJObject()
  add(query_21626587, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626587, "Action", newJString(Action))
  add(query_21626587, "Version", newJString(Version))
  result = call_21626586.call(nil, query_21626587, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_21626572(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_21626573, base: "/",
    makeUrl: url_GetDeleteDBSecurityGroup_21626574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_21626621 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSnapshot_21626623(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_21626622(path: JsonNode; query: JsonNode;
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
  var valid_21626624 = query.getOrDefault("Action")
  valid_21626624 = validateParameter(valid_21626624, JString, required = true,
                                   default = newJString("DeleteDBSnapshot"))
  if valid_21626624 != nil:
    section.add "Action", valid_21626624
  var valid_21626625 = query.getOrDefault("Version")
  valid_21626625 = validateParameter(valid_21626625, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626625 != nil:
    section.add "Version", valid_21626625
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
  var valid_21626626 = header.getOrDefault("X-Amz-Date")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "X-Amz-Date", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Security-Token", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Algorithm", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Signature")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Signature", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Credential")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Credential", valid_21626632
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_21626633 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21626633 = validateParameter(valid_21626633, JString, required = true,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "DBSnapshotIdentifier", valid_21626633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626634: Call_PostDeleteDBSnapshot_21626621; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626634.validator(path, query, header, formData, body, _)
  let scheme = call_21626634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626634.makeUrl(scheme.get, call_21626634.host, call_21626634.base,
                               call_21626634.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626634, uri, valid, _)

proc call*(call_21626635: Call_PostDeleteDBSnapshot_21626621;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626636 = newJObject()
  var formData_21626637 = newJObject()
  add(formData_21626637, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21626636, "Action", newJString(Action))
  add(query_21626636, "Version", newJString(Version))
  result = call_21626635.call(nil, query_21626636, nil, formData_21626637, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_21626621(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_21626622, base: "/",
    makeUrl: url_PostDeleteDBSnapshot_21626623,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_21626605 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSnapshot_21626607(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_21626606(path: JsonNode; query: JsonNode;
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
  var valid_21626608 = query.getOrDefault("Action")
  valid_21626608 = validateParameter(valid_21626608, JString, required = true,
                                   default = newJString("DeleteDBSnapshot"))
  if valid_21626608 != nil:
    section.add "Action", valid_21626608
  var valid_21626609 = query.getOrDefault("Version")
  valid_21626609 = validateParameter(valid_21626609, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626609 != nil:
    section.add "Version", valid_21626609
  var valid_21626610 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21626610 = validateParameter(valid_21626610, JString, required = true,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "DBSnapshotIdentifier", valid_21626610
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
  var valid_21626611 = header.getOrDefault("X-Amz-Date")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Date", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Security-Token", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Algorithm", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Signature")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Signature", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Credential")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Credential", valid_21626617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626618: Call_GetDeleteDBSnapshot_21626605; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626618.validator(path, query, header, formData, body, _)
  let scheme = call_21626618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626618.makeUrl(scheme.get, call_21626618.host, call_21626618.base,
                               call_21626618.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626618, uri, valid, _)

proc call*(call_21626619: Call_GetDeleteDBSnapshot_21626605;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21626620 = newJObject()
  add(query_21626620, "Action", newJString(Action))
  add(query_21626620, "Version", newJString(Version))
  add(query_21626620, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21626619.call(nil, query_21626620, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_21626605(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_21626606, base: "/",
    makeUrl: url_GetDeleteDBSnapshot_21626607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_21626654 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSubnetGroup_21626656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_21626655(path: JsonNode; query: JsonNode;
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
  var valid_21626657 = query.getOrDefault("Action")
  valid_21626657 = validateParameter(valid_21626657, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626657 != nil:
    section.add "Action", valid_21626657
  var valid_21626658 = query.getOrDefault("Version")
  valid_21626658 = validateParameter(valid_21626658, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626658 != nil:
    section.add "Version", valid_21626658
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
  var valid_21626659 = header.getOrDefault("X-Amz-Date")
  valid_21626659 = validateParameter(valid_21626659, JString, required = false,
                                   default = nil)
  if valid_21626659 != nil:
    section.add "X-Amz-Date", valid_21626659
  var valid_21626660 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626660 = validateParameter(valid_21626660, JString, required = false,
                                   default = nil)
  if valid_21626660 != nil:
    section.add "X-Amz-Security-Token", valid_21626660
  var valid_21626661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626661 = validateParameter(valid_21626661, JString, required = false,
                                   default = nil)
  if valid_21626661 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626661
  var valid_21626662 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626662 = validateParameter(valid_21626662, JString, required = false,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "X-Amz-Algorithm", valid_21626662
  var valid_21626663 = header.getOrDefault("X-Amz-Signature")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Signature", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Credential")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Credential", valid_21626665
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626666 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626666 = validateParameter(valid_21626666, JString, required = true,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "DBSubnetGroupName", valid_21626666
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626667: Call_PostDeleteDBSubnetGroup_21626654;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626667.validator(path, query, header, formData, body, _)
  let scheme = call_21626667.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626667.makeUrl(scheme.get, call_21626667.host, call_21626667.base,
                               call_21626667.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626667, uri, valid, _)

proc call*(call_21626668: Call_PostDeleteDBSubnetGroup_21626654;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626669 = newJObject()
  var formData_21626670 = newJObject()
  add(formData_21626670, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626669, "Action", newJString(Action))
  add(query_21626669, "Version", newJString(Version))
  result = call_21626668.call(nil, query_21626669, nil, formData_21626670, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_21626654(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_21626655, base: "/",
    makeUrl: url_PostDeleteDBSubnetGroup_21626656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_21626638 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSubnetGroup_21626640(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_21626639(path: JsonNode; query: JsonNode;
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
  var valid_21626641 = query.getOrDefault("Action")
  valid_21626641 = validateParameter(valid_21626641, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626641 != nil:
    section.add "Action", valid_21626641
  var valid_21626642 = query.getOrDefault("DBSubnetGroupName")
  valid_21626642 = validateParameter(valid_21626642, JString, required = true,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "DBSubnetGroupName", valid_21626642
  var valid_21626643 = query.getOrDefault("Version")
  valid_21626643 = validateParameter(valid_21626643, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626643 != nil:
    section.add "Version", valid_21626643
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
  var valid_21626644 = header.getOrDefault("X-Amz-Date")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Date", valid_21626644
  var valid_21626645 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626645 = validateParameter(valid_21626645, JString, required = false,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "X-Amz-Security-Token", valid_21626645
  var valid_21626646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Algorithm", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Signature")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Signature", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Credential")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Credential", valid_21626650
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626651: Call_GetDeleteDBSubnetGroup_21626638;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626651.validator(path, query, header, formData, body, _)
  let scheme = call_21626651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626651.makeUrl(scheme.get, call_21626651.host, call_21626651.base,
                               call_21626651.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626651, uri, valid, _)

proc call*(call_21626652: Call_GetDeleteDBSubnetGroup_21626638;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_21626653 = newJObject()
  add(query_21626653, "Action", newJString(Action))
  add(query_21626653, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626653, "Version", newJString(Version))
  result = call_21626652.call(nil, query_21626653, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_21626638(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_21626639, base: "/",
    makeUrl: url_GetDeleteDBSubnetGroup_21626640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_21626687 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteEventSubscription_21626689(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_21626688(path: JsonNode; query: JsonNode;
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
  var valid_21626690 = query.getOrDefault("Action")
  valid_21626690 = validateParameter(valid_21626690, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_21626690 != nil:
    section.add "Action", valid_21626690
  var valid_21626691 = query.getOrDefault("Version")
  valid_21626691 = validateParameter(valid_21626691, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626691 != nil:
    section.add "Version", valid_21626691
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
  var valid_21626692 = header.getOrDefault("X-Amz-Date")
  valid_21626692 = validateParameter(valid_21626692, JString, required = false,
                                   default = nil)
  if valid_21626692 != nil:
    section.add "X-Amz-Date", valid_21626692
  var valid_21626693 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626693 = validateParameter(valid_21626693, JString, required = false,
                                   default = nil)
  if valid_21626693 != nil:
    section.add "X-Amz-Security-Token", valid_21626693
  var valid_21626694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626694 = validateParameter(valid_21626694, JString, required = false,
                                   default = nil)
  if valid_21626694 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626694
  var valid_21626695 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626695 = validateParameter(valid_21626695, JString, required = false,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "X-Amz-Algorithm", valid_21626695
  var valid_21626696 = header.getOrDefault("X-Amz-Signature")
  valid_21626696 = validateParameter(valid_21626696, JString, required = false,
                                   default = nil)
  if valid_21626696 != nil:
    section.add "X-Amz-Signature", valid_21626696
  var valid_21626697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Credential")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Credential", valid_21626698
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_21626699 = formData.getOrDefault("SubscriptionName")
  valid_21626699 = validateParameter(valid_21626699, JString, required = true,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "SubscriptionName", valid_21626699
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626700: Call_PostDeleteEventSubscription_21626687;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626700.validator(path, query, header, formData, body, _)
  let scheme = call_21626700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626700.makeUrl(scheme.get, call_21626700.host, call_21626700.base,
                               call_21626700.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626700, uri, valid, _)

proc call*(call_21626701: Call_PostDeleteEventSubscription_21626687;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626702 = newJObject()
  var formData_21626703 = newJObject()
  add(formData_21626703, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626702, "Action", newJString(Action))
  add(query_21626702, "Version", newJString(Version))
  result = call_21626701.call(nil, query_21626702, nil, formData_21626703, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_21626687(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_21626688, base: "/",
    makeUrl: url_PostDeleteEventSubscription_21626689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_21626671 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteEventSubscription_21626673(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_21626672(path: JsonNode; query: JsonNode;
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
  var valid_21626674 = query.getOrDefault("Action")
  valid_21626674 = validateParameter(valid_21626674, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_21626674 != nil:
    section.add "Action", valid_21626674
  var valid_21626675 = query.getOrDefault("SubscriptionName")
  valid_21626675 = validateParameter(valid_21626675, JString, required = true,
                                   default = nil)
  if valid_21626675 != nil:
    section.add "SubscriptionName", valid_21626675
  var valid_21626676 = query.getOrDefault("Version")
  valid_21626676 = validateParameter(valid_21626676, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626676 != nil:
    section.add "Version", valid_21626676
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
  var valid_21626677 = header.getOrDefault("X-Amz-Date")
  valid_21626677 = validateParameter(valid_21626677, JString, required = false,
                                   default = nil)
  if valid_21626677 != nil:
    section.add "X-Amz-Date", valid_21626677
  var valid_21626678 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626678 = validateParameter(valid_21626678, JString, required = false,
                                   default = nil)
  if valid_21626678 != nil:
    section.add "X-Amz-Security-Token", valid_21626678
  var valid_21626679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Algorithm", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Signature")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Signature", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Credential")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Credential", valid_21626683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626684: Call_GetDeleteEventSubscription_21626671;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626684.validator(path, query, header, formData, body, _)
  let scheme = call_21626684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626684.makeUrl(scheme.get, call_21626684.host, call_21626684.base,
                               call_21626684.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626684, uri, valid, _)

proc call*(call_21626685: Call_GetDeleteEventSubscription_21626671;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21626686 = newJObject()
  add(query_21626686, "Action", newJString(Action))
  add(query_21626686, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626686, "Version", newJString(Version))
  result = call_21626685.call(nil, query_21626686, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_21626671(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_21626672, base: "/",
    makeUrl: url_GetDeleteEventSubscription_21626673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_21626720 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteOptionGroup_21626722(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_21626721(path: JsonNode; query: JsonNode;
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
  var valid_21626723 = query.getOrDefault("Action")
  valid_21626723 = validateParameter(valid_21626723, JString, required = true,
                                   default = newJString("DeleteOptionGroup"))
  if valid_21626723 != nil:
    section.add "Action", valid_21626723
  var valid_21626724 = query.getOrDefault("Version")
  valid_21626724 = validateParameter(valid_21626724, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626724 != nil:
    section.add "Version", valid_21626724
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
  var valid_21626725 = header.getOrDefault("X-Amz-Date")
  valid_21626725 = validateParameter(valid_21626725, JString, required = false,
                                   default = nil)
  if valid_21626725 != nil:
    section.add "X-Amz-Date", valid_21626725
  var valid_21626726 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626726 = validateParameter(valid_21626726, JString, required = false,
                                   default = nil)
  if valid_21626726 != nil:
    section.add "X-Amz-Security-Token", valid_21626726
  var valid_21626727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626727 = validateParameter(valid_21626727, JString, required = false,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626727
  var valid_21626728 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626728 = validateParameter(valid_21626728, JString, required = false,
                                   default = nil)
  if valid_21626728 != nil:
    section.add "X-Amz-Algorithm", valid_21626728
  var valid_21626729 = header.getOrDefault("X-Amz-Signature")
  valid_21626729 = validateParameter(valid_21626729, JString, required = false,
                                   default = nil)
  if valid_21626729 != nil:
    section.add "X-Amz-Signature", valid_21626729
  var valid_21626730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Credential")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Credential", valid_21626731
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_21626732 = formData.getOrDefault("OptionGroupName")
  valid_21626732 = validateParameter(valid_21626732, JString, required = true,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "OptionGroupName", valid_21626732
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626733: Call_PostDeleteOptionGroup_21626720;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626733.validator(path, query, header, formData, body, _)
  let scheme = call_21626733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626733.makeUrl(scheme.get, call_21626733.host, call_21626733.base,
                               call_21626733.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626733, uri, valid, _)

proc call*(call_21626734: Call_PostDeleteOptionGroup_21626720;
          OptionGroupName: string; Action: string = "DeleteOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626735 = newJObject()
  var formData_21626736 = newJObject()
  add(formData_21626736, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626735, "Action", newJString(Action))
  add(query_21626735, "Version", newJString(Version))
  result = call_21626734.call(nil, query_21626735, nil, formData_21626736, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_21626720(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_21626721, base: "/",
    makeUrl: url_PostDeleteOptionGroup_21626722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_21626704 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteOptionGroup_21626706(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_21626705(path: JsonNode; query: JsonNode;
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
  var valid_21626707 = query.getOrDefault("OptionGroupName")
  valid_21626707 = validateParameter(valid_21626707, JString, required = true,
                                   default = nil)
  if valid_21626707 != nil:
    section.add "OptionGroupName", valid_21626707
  var valid_21626708 = query.getOrDefault("Action")
  valid_21626708 = validateParameter(valid_21626708, JString, required = true,
                                   default = newJString("DeleteOptionGroup"))
  if valid_21626708 != nil:
    section.add "Action", valid_21626708
  var valid_21626709 = query.getOrDefault("Version")
  valid_21626709 = validateParameter(valid_21626709, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626709 != nil:
    section.add "Version", valid_21626709
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
  var valid_21626710 = header.getOrDefault("X-Amz-Date")
  valid_21626710 = validateParameter(valid_21626710, JString, required = false,
                                   default = nil)
  if valid_21626710 != nil:
    section.add "X-Amz-Date", valid_21626710
  var valid_21626711 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626711 = validateParameter(valid_21626711, JString, required = false,
                                   default = nil)
  if valid_21626711 != nil:
    section.add "X-Amz-Security-Token", valid_21626711
  var valid_21626712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Algorithm", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Signature")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Signature", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Credential")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Credential", valid_21626716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626717: Call_GetDeleteOptionGroup_21626704; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626717.validator(path, query, header, formData, body, _)
  let scheme = call_21626717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626717.makeUrl(scheme.get, call_21626717.host, call_21626717.base,
                               call_21626717.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626717, uri, valid, _)

proc call*(call_21626718: Call_GetDeleteOptionGroup_21626704;
          OptionGroupName: string; Action: string = "DeleteOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626719 = newJObject()
  add(query_21626719, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626719, "Action", newJString(Action))
  add(query_21626719, "Version", newJString(Version))
  result = call_21626718.call(nil, query_21626719, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_21626704(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_21626705, base: "/",
    makeUrl: url_GetDeleteOptionGroup_21626706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_21626759 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBEngineVersions_21626761(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_21626760(path: JsonNode;
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
  var valid_21626762 = query.getOrDefault("Action")
  valid_21626762 = validateParameter(valid_21626762, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626762 != nil:
    section.add "Action", valid_21626762
  var valid_21626763 = query.getOrDefault("Version")
  valid_21626763 = validateParameter(valid_21626763, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626763 != nil:
    section.add "Version", valid_21626763
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
  var valid_21626764 = header.getOrDefault("X-Amz-Date")
  valid_21626764 = validateParameter(valid_21626764, JString, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "X-Amz-Date", valid_21626764
  var valid_21626765 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Security-Token", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Algorithm", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Signature")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Signature", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Credential")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Credential", valid_21626770
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##   Engine: JString
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_21626771 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_21626771 = validateParameter(valid_21626771, JBool, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "ListSupportedCharacterSets", valid_21626771
  var valid_21626772 = formData.getOrDefault("Engine")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "Engine", valid_21626772
  var valid_21626773 = formData.getOrDefault("Marker")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "Marker", valid_21626773
  var valid_21626774 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "DBParameterGroupFamily", valid_21626774
  var valid_21626775 = formData.getOrDefault("MaxRecords")
  valid_21626775 = validateParameter(valid_21626775, JInt, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "MaxRecords", valid_21626775
  var valid_21626776 = formData.getOrDefault("EngineVersion")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "EngineVersion", valid_21626776
  var valid_21626777 = formData.getOrDefault("DefaultOnly")
  valid_21626777 = validateParameter(valid_21626777, JBool, required = false,
                                   default = nil)
  if valid_21626777 != nil:
    section.add "DefaultOnly", valid_21626777
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626778: Call_PostDescribeDBEngineVersions_21626759;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626778.validator(path, query, header, formData, body, _)
  let scheme = call_21626778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626778.makeUrl(scheme.get, call_21626778.host, call_21626778.base,
                               call_21626778.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626778, uri, valid, _)

proc call*(call_21626779: Call_PostDescribeDBEngineVersions_21626759;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-01-10";
          DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ##   ListSupportedCharacterSets: bool
  ##   Engine: string
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   DefaultOnly: bool
  var query_21626780 = newJObject()
  var formData_21626781 = newJObject()
  add(formData_21626781, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_21626781, "Engine", newJString(Engine))
  add(formData_21626781, "Marker", newJString(Marker))
  add(query_21626780, "Action", newJString(Action))
  add(formData_21626781, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_21626781, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626781, "EngineVersion", newJString(EngineVersion))
  add(query_21626780, "Version", newJString(Version))
  add(formData_21626781, "DefaultOnly", newJBool(DefaultOnly))
  result = call_21626779.call(nil, query_21626780, nil, formData_21626781, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_21626759(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_21626760, base: "/",
    makeUrl: url_PostDescribeDBEngineVersions_21626761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_21626737 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBEngineVersions_21626739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_21626738(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626740 = query.getOrDefault("Engine")
  valid_21626740 = validateParameter(valid_21626740, JString, required = false,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "Engine", valid_21626740
  var valid_21626741 = query.getOrDefault("ListSupportedCharacterSets")
  valid_21626741 = validateParameter(valid_21626741, JBool, required = false,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "ListSupportedCharacterSets", valid_21626741
  var valid_21626742 = query.getOrDefault("MaxRecords")
  valid_21626742 = validateParameter(valid_21626742, JInt, required = false,
                                   default = nil)
  if valid_21626742 != nil:
    section.add "MaxRecords", valid_21626742
  var valid_21626743 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626743 = validateParameter(valid_21626743, JString, required = false,
                                   default = nil)
  if valid_21626743 != nil:
    section.add "DBParameterGroupFamily", valid_21626743
  var valid_21626744 = query.getOrDefault("Action")
  valid_21626744 = validateParameter(valid_21626744, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626744 != nil:
    section.add "Action", valid_21626744
  var valid_21626745 = query.getOrDefault("Marker")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "Marker", valid_21626745
  var valid_21626746 = query.getOrDefault("EngineVersion")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "EngineVersion", valid_21626746
  var valid_21626747 = query.getOrDefault("DefaultOnly")
  valid_21626747 = validateParameter(valid_21626747, JBool, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "DefaultOnly", valid_21626747
  var valid_21626748 = query.getOrDefault("Version")
  valid_21626748 = validateParameter(valid_21626748, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626748 != nil:
    section.add "Version", valid_21626748
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
  var valid_21626749 = header.getOrDefault("X-Amz-Date")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Date", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Security-Token", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Algorithm", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Signature")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Signature", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-Credential")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Credential", valid_21626755
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626756: Call_GetDescribeDBEngineVersions_21626737;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626756.validator(path, query, header, formData, body, _)
  let scheme = call_21626756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626756.makeUrl(scheme.get, call_21626756.host, call_21626756.base,
                               call_21626756.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626756, uri, valid, _)

proc call*(call_21626757: Call_GetDescribeDBEngineVersions_21626737;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBEngineVersions
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   DefaultOnly: bool
  ##   Version: string (required)
  var query_21626758 = newJObject()
  add(query_21626758, "Engine", newJString(Engine))
  add(query_21626758, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_21626758, "MaxRecords", newJInt(MaxRecords))
  add(query_21626758, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_21626758, "Action", newJString(Action))
  add(query_21626758, "Marker", newJString(Marker))
  add(query_21626758, "EngineVersion", newJString(EngineVersion))
  add(query_21626758, "DefaultOnly", newJBool(DefaultOnly))
  add(query_21626758, "Version", newJString(Version))
  result = call_21626757.call(nil, query_21626758, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_21626737(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_21626738, base: "/",
    makeUrl: url_GetDescribeDBEngineVersions_21626739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_21626800 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBInstances_21626802(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_21626801(path: JsonNode; query: JsonNode;
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
  var valid_21626803 = query.getOrDefault("Action")
  valid_21626803 = validateParameter(valid_21626803, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626803 != nil:
    section.add "Action", valid_21626803
  var valid_21626804 = query.getOrDefault("Version")
  valid_21626804 = validateParameter(valid_21626804, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626804 != nil:
    section.add "Version", valid_21626804
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
  var valid_21626805 = header.getOrDefault("X-Amz-Date")
  valid_21626805 = validateParameter(valid_21626805, JString, required = false,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "X-Amz-Date", valid_21626805
  var valid_21626806 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626806 = validateParameter(valid_21626806, JString, required = false,
                                   default = nil)
  if valid_21626806 != nil:
    section.add "X-Amz-Security-Token", valid_21626806
  var valid_21626807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626807 = validateParameter(valid_21626807, JString, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626807
  var valid_21626808 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626808 = validateParameter(valid_21626808, JString, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "X-Amz-Algorithm", valid_21626808
  var valid_21626809 = header.getOrDefault("X-Amz-Signature")
  valid_21626809 = validateParameter(valid_21626809, JString, required = false,
                                   default = nil)
  if valid_21626809 != nil:
    section.add "X-Amz-Signature", valid_21626809
  var valid_21626810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626810
  var valid_21626811 = header.getOrDefault("X-Amz-Credential")
  valid_21626811 = validateParameter(valid_21626811, JString, required = false,
                                   default = nil)
  if valid_21626811 != nil:
    section.add "X-Amz-Credential", valid_21626811
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626812 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "DBInstanceIdentifier", valid_21626812
  var valid_21626813 = formData.getOrDefault("Marker")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "Marker", valid_21626813
  var valid_21626814 = formData.getOrDefault("MaxRecords")
  valid_21626814 = validateParameter(valid_21626814, JInt, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "MaxRecords", valid_21626814
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626815: Call_PostDescribeDBInstances_21626800;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626815.validator(path, query, header, formData, body, _)
  let scheme = call_21626815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626815.makeUrl(scheme.get, call_21626815.host, call_21626815.base,
                               call_21626815.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626815, uri, valid, _)

proc call*(call_21626816: Call_PostDescribeDBInstances_21626800;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21626817 = newJObject()
  var formData_21626818 = newJObject()
  add(formData_21626818, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626818, "Marker", newJString(Marker))
  add(query_21626817, "Action", newJString(Action))
  add(formData_21626818, "MaxRecords", newJInt(MaxRecords))
  add(query_21626817, "Version", newJString(Version))
  result = call_21626816.call(nil, query_21626817, nil, formData_21626818, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_21626800(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_21626801, base: "/",
    makeUrl: url_PostDescribeDBInstances_21626802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_21626782 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBInstances_21626784(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_21626783(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_21626785 = query.getOrDefault("MaxRecords")
  valid_21626785 = validateParameter(valid_21626785, JInt, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "MaxRecords", valid_21626785
  var valid_21626786 = query.getOrDefault("Action")
  valid_21626786 = validateParameter(valid_21626786, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626786 != nil:
    section.add "Action", valid_21626786
  var valid_21626787 = query.getOrDefault("Marker")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "Marker", valid_21626787
  var valid_21626788 = query.getOrDefault("Version")
  valid_21626788 = validateParameter(valid_21626788, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626788 != nil:
    section.add "Version", valid_21626788
  var valid_21626789 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "DBInstanceIdentifier", valid_21626789
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
  var valid_21626790 = header.getOrDefault("X-Amz-Date")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-Date", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Security-Token", valid_21626791
  var valid_21626792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626792 = validateParameter(valid_21626792, JString, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626792
  var valid_21626793 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "X-Amz-Algorithm", valid_21626793
  var valid_21626794 = header.getOrDefault("X-Amz-Signature")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "X-Amz-Signature", valid_21626794
  var valid_21626795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626795
  var valid_21626796 = header.getOrDefault("X-Amz-Credential")
  valid_21626796 = validateParameter(valid_21626796, JString, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "X-Amz-Credential", valid_21626796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626797: Call_GetDescribeDBInstances_21626782;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626797.validator(path, query, header, formData, body, _)
  let scheme = call_21626797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626797.makeUrl(scheme.get, call_21626797.host, call_21626797.base,
                               call_21626797.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626797, uri, valid, _)

proc call*(call_21626798: Call_GetDescribeDBInstances_21626782;
          MaxRecords: int = 0; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2013-01-10";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_21626799 = newJObject()
  add(query_21626799, "MaxRecords", newJInt(MaxRecords))
  add(query_21626799, "Action", newJString(Action))
  add(query_21626799, "Marker", newJString(Marker))
  add(query_21626799, "Version", newJString(Version))
  add(query_21626799, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626798.call(nil, query_21626799, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_21626782(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_21626783, base: "/",
    makeUrl: url_GetDescribeDBInstances_21626784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_21626837 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBParameterGroups_21626839(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_21626838(path: JsonNode;
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
  var valid_21626840 = query.getOrDefault("Action")
  valid_21626840 = validateParameter(valid_21626840, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_21626840 != nil:
    section.add "Action", valid_21626840
  var valid_21626841 = query.getOrDefault("Version")
  valid_21626841 = validateParameter(valid_21626841, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626841 != nil:
    section.add "Version", valid_21626841
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
  var valid_21626842 = header.getOrDefault("X-Amz-Date")
  valid_21626842 = validateParameter(valid_21626842, JString, required = false,
                                   default = nil)
  if valid_21626842 != nil:
    section.add "X-Amz-Date", valid_21626842
  var valid_21626843 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626843 = validateParameter(valid_21626843, JString, required = false,
                                   default = nil)
  if valid_21626843 != nil:
    section.add "X-Amz-Security-Token", valid_21626843
  var valid_21626844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626844 = validateParameter(valid_21626844, JString, required = false,
                                   default = nil)
  if valid_21626844 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626844
  var valid_21626845 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626845 = validateParameter(valid_21626845, JString, required = false,
                                   default = nil)
  if valid_21626845 != nil:
    section.add "X-Amz-Algorithm", valid_21626845
  var valid_21626846 = header.getOrDefault("X-Amz-Signature")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "X-Amz-Signature", valid_21626846
  var valid_21626847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626847 = validateParameter(valid_21626847, JString, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626847
  var valid_21626848 = header.getOrDefault("X-Amz-Credential")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "X-Amz-Credential", valid_21626848
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626849 = formData.getOrDefault("DBParameterGroupName")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "DBParameterGroupName", valid_21626849
  var valid_21626850 = formData.getOrDefault("Marker")
  valid_21626850 = validateParameter(valid_21626850, JString, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "Marker", valid_21626850
  var valid_21626851 = formData.getOrDefault("MaxRecords")
  valid_21626851 = validateParameter(valid_21626851, JInt, required = false,
                                   default = nil)
  if valid_21626851 != nil:
    section.add "MaxRecords", valid_21626851
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626852: Call_PostDescribeDBParameterGroups_21626837;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626852.validator(path, query, header, formData, body, _)
  let scheme = call_21626852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626852.makeUrl(scheme.get, call_21626852.host, call_21626852.base,
                               call_21626852.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626852, uri, valid, _)

proc call*(call_21626853: Call_PostDescribeDBParameterGroups_21626837;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21626854 = newJObject()
  var formData_21626855 = newJObject()
  add(formData_21626855, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21626855, "Marker", newJString(Marker))
  add(query_21626854, "Action", newJString(Action))
  add(formData_21626855, "MaxRecords", newJInt(MaxRecords))
  add(query_21626854, "Version", newJString(Version))
  result = call_21626853.call(nil, query_21626854, nil, formData_21626855, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_21626837(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_21626838, base: "/",
    makeUrl: url_PostDescribeDBParameterGroups_21626839,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_21626819 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBParameterGroups_21626821(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_21626820(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626822 = query.getOrDefault("MaxRecords")
  valid_21626822 = validateParameter(valid_21626822, JInt, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "MaxRecords", valid_21626822
  var valid_21626823 = query.getOrDefault("DBParameterGroupName")
  valid_21626823 = validateParameter(valid_21626823, JString, required = false,
                                   default = nil)
  if valid_21626823 != nil:
    section.add "DBParameterGroupName", valid_21626823
  var valid_21626824 = query.getOrDefault("Action")
  valid_21626824 = validateParameter(valid_21626824, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_21626824 != nil:
    section.add "Action", valid_21626824
  var valid_21626825 = query.getOrDefault("Marker")
  valid_21626825 = validateParameter(valid_21626825, JString, required = false,
                                   default = nil)
  if valid_21626825 != nil:
    section.add "Marker", valid_21626825
  var valid_21626826 = query.getOrDefault("Version")
  valid_21626826 = validateParameter(valid_21626826, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626826 != nil:
    section.add "Version", valid_21626826
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
  var valid_21626827 = header.getOrDefault("X-Amz-Date")
  valid_21626827 = validateParameter(valid_21626827, JString, required = false,
                                   default = nil)
  if valid_21626827 != nil:
    section.add "X-Amz-Date", valid_21626827
  var valid_21626828 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Security-Token", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626829 = validateParameter(valid_21626829, JString, required = false,
                                   default = nil)
  if valid_21626829 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Algorithm", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Signature")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Signature", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-Credential")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-Credential", valid_21626833
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626834: Call_GetDescribeDBParameterGroups_21626819;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626834.validator(path, query, header, formData, body, _)
  let scheme = call_21626834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626834.makeUrl(scheme.get, call_21626834.host, call_21626834.base,
                               call_21626834.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626834, uri, valid, _)

proc call*(call_21626835: Call_GetDescribeDBParameterGroups_21626819;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21626836 = newJObject()
  add(query_21626836, "MaxRecords", newJInt(MaxRecords))
  add(query_21626836, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626836, "Action", newJString(Action))
  add(query_21626836, "Marker", newJString(Marker))
  add(query_21626836, "Version", newJString(Version))
  result = call_21626835.call(nil, query_21626836, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_21626819(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_21626820, base: "/",
    makeUrl: url_GetDescribeDBParameterGroups_21626821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_21626875 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBParameters_21626877(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_21626876(path: JsonNode; query: JsonNode;
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
  var valid_21626878 = query.getOrDefault("Action")
  valid_21626878 = validateParameter(valid_21626878, JString, required = true,
                                   default = newJString("DescribeDBParameters"))
  if valid_21626878 != nil:
    section.add "Action", valid_21626878
  var valid_21626879 = query.getOrDefault("Version")
  valid_21626879 = validateParameter(valid_21626879, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626879 != nil:
    section.add "Version", valid_21626879
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
  var valid_21626880 = header.getOrDefault("X-Amz-Date")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "X-Amz-Date", valid_21626880
  var valid_21626881 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "X-Amz-Security-Token", valid_21626881
  var valid_21626882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626882 = validateParameter(valid_21626882, JString, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626882
  var valid_21626883 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626883 = validateParameter(valid_21626883, JString, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "X-Amz-Algorithm", valid_21626883
  var valid_21626884 = header.getOrDefault("X-Amz-Signature")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "X-Amz-Signature", valid_21626884
  var valid_21626885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626885 = validateParameter(valid_21626885, JString, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626885
  var valid_21626886 = header.getOrDefault("X-Amz-Credential")
  valid_21626886 = validateParameter(valid_21626886, JString, required = false,
                                   default = nil)
  if valid_21626886 != nil:
    section.add "X-Amz-Credential", valid_21626886
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626887 = formData.getOrDefault("DBParameterGroupName")
  valid_21626887 = validateParameter(valid_21626887, JString, required = true,
                                   default = nil)
  if valid_21626887 != nil:
    section.add "DBParameterGroupName", valid_21626887
  var valid_21626888 = formData.getOrDefault("Marker")
  valid_21626888 = validateParameter(valid_21626888, JString, required = false,
                                   default = nil)
  if valid_21626888 != nil:
    section.add "Marker", valid_21626888
  var valid_21626889 = formData.getOrDefault("MaxRecords")
  valid_21626889 = validateParameter(valid_21626889, JInt, required = false,
                                   default = nil)
  if valid_21626889 != nil:
    section.add "MaxRecords", valid_21626889
  var valid_21626890 = formData.getOrDefault("Source")
  valid_21626890 = validateParameter(valid_21626890, JString, required = false,
                                   default = nil)
  if valid_21626890 != nil:
    section.add "Source", valid_21626890
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626891: Call_PostDescribeDBParameters_21626875;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626891.validator(path, query, header, formData, body, _)
  let scheme = call_21626891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626891.makeUrl(scheme.get, call_21626891.host, call_21626891.base,
                               call_21626891.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626891, uri, valid, _)

proc call*(call_21626892: Call_PostDescribeDBParameters_21626875;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; MaxRecords: int = 0;
          Version: string = "2013-01-10"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_21626893 = newJObject()
  var formData_21626894 = newJObject()
  add(formData_21626894, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21626894, "Marker", newJString(Marker))
  add(query_21626893, "Action", newJString(Action))
  add(formData_21626894, "MaxRecords", newJInt(MaxRecords))
  add(query_21626893, "Version", newJString(Version))
  add(formData_21626894, "Source", newJString(Source))
  result = call_21626892.call(nil, query_21626893, nil, formData_21626894, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_21626875(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_21626876, base: "/",
    makeUrl: url_PostDescribeDBParameters_21626877,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_21626856 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBParameters_21626858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_21626857(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Source: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626859 = query.getOrDefault("MaxRecords")
  valid_21626859 = validateParameter(valid_21626859, JInt, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "MaxRecords", valid_21626859
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626860 = query.getOrDefault("DBParameterGroupName")
  valid_21626860 = validateParameter(valid_21626860, JString, required = true,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "DBParameterGroupName", valid_21626860
  var valid_21626861 = query.getOrDefault("Action")
  valid_21626861 = validateParameter(valid_21626861, JString, required = true,
                                   default = newJString("DescribeDBParameters"))
  if valid_21626861 != nil:
    section.add "Action", valid_21626861
  var valid_21626862 = query.getOrDefault("Marker")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "Marker", valid_21626862
  var valid_21626863 = query.getOrDefault("Source")
  valid_21626863 = validateParameter(valid_21626863, JString, required = false,
                                   default = nil)
  if valid_21626863 != nil:
    section.add "Source", valid_21626863
  var valid_21626864 = query.getOrDefault("Version")
  valid_21626864 = validateParameter(valid_21626864, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626864 != nil:
    section.add "Version", valid_21626864
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
  var valid_21626865 = header.getOrDefault("X-Amz-Date")
  valid_21626865 = validateParameter(valid_21626865, JString, required = false,
                                   default = nil)
  if valid_21626865 != nil:
    section.add "X-Amz-Date", valid_21626865
  var valid_21626866 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626866 = validateParameter(valid_21626866, JString, required = false,
                                   default = nil)
  if valid_21626866 != nil:
    section.add "X-Amz-Security-Token", valid_21626866
  var valid_21626867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626867 = validateParameter(valid_21626867, JString, required = false,
                                   default = nil)
  if valid_21626867 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626867
  var valid_21626868 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626868 = validateParameter(valid_21626868, JString, required = false,
                                   default = nil)
  if valid_21626868 != nil:
    section.add "X-Amz-Algorithm", valid_21626868
  var valid_21626869 = header.getOrDefault("X-Amz-Signature")
  valid_21626869 = validateParameter(valid_21626869, JString, required = false,
                                   default = nil)
  if valid_21626869 != nil:
    section.add "X-Amz-Signature", valid_21626869
  var valid_21626870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Credential")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Credential", valid_21626871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626872: Call_GetDescribeDBParameters_21626856;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626872.validator(path, query, header, formData, body, _)
  let scheme = call_21626872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626872.makeUrl(scheme.get, call_21626872.host, call_21626872.base,
                               call_21626872.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626872, uri, valid, _)

proc call*(call_21626873: Call_GetDescribeDBParameters_21626856;
          DBParameterGroupName: string; MaxRecords: int = 0;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_21626874 = newJObject()
  add(query_21626874, "MaxRecords", newJInt(MaxRecords))
  add(query_21626874, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626874, "Action", newJString(Action))
  add(query_21626874, "Marker", newJString(Marker))
  add(query_21626874, "Source", newJString(Source))
  add(query_21626874, "Version", newJString(Version))
  result = call_21626873.call(nil, query_21626874, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_21626856(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_21626857, base: "/",
    makeUrl: url_GetDescribeDBParameters_21626858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_21626913 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSecurityGroups_21626915(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_21626914(path: JsonNode;
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
  var valid_21626916 = query.getOrDefault("Action")
  valid_21626916 = validateParameter(valid_21626916, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_21626916 != nil:
    section.add "Action", valid_21626916
  var valid_21626917 = query.getOrDefault("Version")
  valid_21626917 = validateParameter(valid_21626917, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626917 != nil:
    section.add "Version", valid_21626917
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
  var valid_21626918 = header.getOrDefault("X-Amz-Date")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Date", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-Security-Token", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626920
  var valid_21626921 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "X-Amz-Algorithm", valid_21626921
  var valid_21626922 = header.getOrDefault("X-Amz-Signature")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "X-Amz-Signature", valid_21626922
  var valid_21626923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626923 = validateParameter(valid_21626923, JString, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626923
  var valid_21626924 = header.getOrDefault("X-Amz-Credential")
  valid_21626924 = validateParameter(valid_21626924, JString, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "X-Amz-Credential", valid_21626924
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626925 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626925 = validateParameter(valid_21626925, JString, required = false,
                                   default = nil)
  if valid_21626925 != nil:
    section.add "DBSecurityGroupName", valid_21626925
  var valid_21626926 = formData.getOrDefault("Marker")
  valid_21626926 = validateParameter(valid_21626926, JString, required = false,
                                   default = nil)
  if valid_21626926 != nil:
    section.add "Marker", valid_21626926
  var valid_21626927 = formData.getOrDefault("MaxRecords")
  valid_21626927 = validateParameter(valid_21626927, JInt, required = false,
                                   default = nil)
  if valid_21626927 != nil:
    section.add "MaxRecords", valid_21626927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626928: Call_PostDescribeDBSecurityGroups_21626913;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626928.validator(path, query, header, formData, body, _)
  let scheme = call_21626928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626928.makeUrl(scheme.get, call_21626928.host, call_21626928.base,
                               call_21626928.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626928, uri, valid, _)

proc call*(call_21626929: Call_PostDescribeDBSecurityGroups_21626913;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21626930 = newJObject()
  var formData_21626931 = newJObject()
  add(formData_21626931, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_21626931, "Marker", newJString(Marker))
  add(query_21626930, "Action", newJString(Action))
  add(formData_21626931, "MaxRecords", newJInt(MaxRecords))
  add(query_21626930, "Version", newJString(Version))
  result = call_21626929.call(nil, query_21626930, nil, formData_21626931, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_21626913(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_21626914, base: "/",
    makeUrl: url_PostDescribeDBSecurityGroups_21626915,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_21626895 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSecurityGroups_21626897(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_21626896(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBSecurityGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626898 = query.getOrDefault("MaxRecords")
  valid_21626898 = validateParameter(valid_21626898, JInt, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "MaxRecords", valid_21626898
  var valid_21626899 = query.getOrDefault("DBSecurityGroupName")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "DBSecurityGroupName", valid_21626899
  var valid_21626900 = query.getOrDefault("Action")
  valid_21626900 = validateParameter(valid_21626900, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_21626900 != nil:
    section.add "Action", valid_21626900
  var valid_21626901 = query.getOrDefault("Marker")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "Marker", valid_21626901
  var valid_21626902 = query.getOrDefault("Version")
  valid_21626902 = validateParameter(valid_21626902, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626902 != nil:
    section.add "Version", valid_21626902
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
  var valid_21626903 = header.getOrDefault("X-Amz-Date")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Date", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-Security-Token", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626905
  var valid_21626906 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626906 = validateParameter(valid_21626906, JString, required = false,
                                   default = nil)
  if valid_21626906 != nil:
    section.add "X-Amz-Algorithm", valid_21626906
  var valid_21626907 = header.getOrDefault("X-Amz-Signature")
  valid_21626907 = validateParameter(valid_21626907, JString, required = false,
                                   default = nil)
  if valid_21626907 != nil:
    section.add "X-Amz-Signature", valid_21626907
  var valid_21626908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626908 = validateParameter(valid_21626908, JString, required = false,
                                   default = nil)
  if valid_21626908 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626908
  var valid_21626909 = header.getOrDefault("X-Amz-Credential")
  valid_21626909 = validateParameter(valid_21626909, JString, required = false,
                                   default = nil)
  if valid_21626909 != nil:
    section.add "X-Amz-Credential", valid_21626909
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626910: Call_GetDescribeDBSecurityGroups_21626895;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626910.validator(path, query, header, formData, body, _)
  let scheme = call_21626910.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626910.makeUrl(scheme.get, call_21626910.host, call_21626910.base,
                               call_21626910.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626910, uri, valid, _)

proc call*(call_21626911: Call_GetDescribeDBSecurityGroups_21626895;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21626912 = newJObject()
  add(query_21626912, "MaxRecords", newJInt(MaxRecords))
  add(query_21626912, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626912, "Action", newJString(Action))
  add(query_21626912, "Marker", newJString(Marker))
  add(query_21626912, "Version", newJString(Version))
  result = call_21626911.call(nil, query_21626912, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_21626895(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_21626896, base: "/",
    makeUrl: url_GetDescribeDBSecurityGroups_21626897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_21626952 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSnapshots_21626954(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_21626953(path: JsonNode; query: JsonNode;
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
  var valid_21626955 = query.getOrDefault("Action")
  valid_21626955 = validateParameter(valid_21626955, JString, required = true,
                                   default = newJString("DescribeDBSnapshots"))
  if valid_21626955 != nil:
    section.add "Action", valid_21626955
  var valid_21626956 = query.getOrDefault("Version")
  valid_21626956 = validateParameter(valid_21626956, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626956 != nil:
    section.add "Version", valid_21626956
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
  var valid_21626957 = header.getOrDefault("X-Amz-Date")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-Date", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Security-Token", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Algorithm", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-Signature")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-Signature", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626962
  var valid_21626963 = header.getOrDefault("X-Amz-Credential")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "X-Amz-Credential", valid_21626963
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626964 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626964 = validateParameter(valid_21626964, JString, required = false,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "DBInstanceIdentifier", valid_21626964
  var valid_21626965 = formData.getOrDefault("SnapshotType")
  valid_21626965 = validateParameter(valid_21626965, JString, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "SnapshotType", valid_21626965
  var valid_21626966 = formData.getOrDefault("Marker")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "Marker", valid_21626966
  var valid_21626967 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21626967 = validateParameter(valid_21626967, JString, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "DBSnapshotIdentifier", valid_21626967
  var valid_21626968 = formData.getOrDefault("MaxRecords")
  valid_21626968 = validateParameter(valid_21626968, JInt, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "MaxRecords", valid_21626968
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626969: Call_PostDescribeDBSnapshots_21626952;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626969.validator(path, query, header, formData, body, _)
  let scheme = call_21626969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626969.makeUrl(scheme.get, call_21626969.host, call_21626969.base,
                               call_21626969.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626969, uri, valid, _)

proc call*(call_21626970: Call_PostDescribeDBSnapshots_21626952;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21626971 = newJObject()
  var formData_21626972 = newJObject()
  add(formData_21626972, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626972, "SnapshotType", newJString(SnapshotType))
  add(formData_21626972, "Marker", newJString(Marker))
  add(formData_21626972, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21626971, "Action", newJString(Action))
  add(formData_21626972, "MaxRecords", newJInt(MaxRecords))
  add(query_21626971, "Version", newJString(Version))
  result = call_21626970.call(nil, query_21626971, nil, formData_21626972, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_21626952(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_21626953, base: "/",
    makeUrl: url_PostDescribeDBSnapshots_21626954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_21626932 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSnapshots_21626934(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_21626933(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SnapshotType: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_21626935 = query.getOrDefault("MaxRecords")
  valid_21626935 = validateParameter(valid_21626935, JInt, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "MaxRecords", valid_21626935
  var valid_21626936 = query.getOrDefault("Action")
  valid_21626936 = validateParameter(valid_21626936, JString, required = true,
                                   default = newJString("DescribeDBSnapshots"))
  if valid_21626936 != nil:
    section.add "Action", valid_21626936
  var valid_21626937 = query.getOrDefault("Marker")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "Marker", valid_21626937
  var valid_21626938 = query.getOrDefault("SnapshotType")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "SnapshotType", valid_21626938
  var valid_21626939 = query.getOrDefault("Version")
  valid_21626939 = validateParameter(valid_21626939, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626939 != nil:
    section.add "Version", valid_21626939
  var valid_21626940 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "DBInstanceIdentifier", valid_21626940
  var valid_21626941 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "DBSnapshotIdentifier", valid_21626941
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
  var valid_21626942 = header.getOrDefault("X-Amz-Date")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Date", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Security-Token", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Algorithm", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-Signature")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-Signature", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626947
  var valid_21626948 = header.getOrDefault("X-Amz-Credential")
  valid_21626948 = validateParameter(valid_21626948, JString, required = false,
                                   default = nil)
  if valid_21626948 != nil:
    section.add "X-Amz-Credential", valid_21626948
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626949: Call_GetDescribeDBSnapshots_21626932;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626949.validator(path, query, header, formData, body, _)
  let scheme = call_21626949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626949.makeUrl(scheme.get, call_21626949.host, call_21626949.base,
                               call_21626949.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626949, uri, valid, _)

proc call*(call_21626950: Call_GetDescribeDBSnapshots_21626932;
          MaxRecords: int = 0; Action: string = "DescribeDBSnapshots";
          Marker: string = ""; SnapshotType: string = "";
          Version: string = "2013-01-10"; DBInstanceIdentifier: string = "";
          DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_21626951 = newJObject()
  add(query_21626951, "MaxRecords", newJInt(MaxRecords))
  add(query_21626951, "Action", newJString(Action))
  add(query_21626951, "Marker", newJString(Marker))
  add(query_21626951, "SnapshotType", newJString(SnapshotType))
  add(query_21626951, "Version", newJString(Version))
  add(query_21626951, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626951, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21626950.call(nil, query_21626951, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_21626932(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_21626933, base: "/",
    makeUrl: url_GetDescribeDBSnapshots_21626934,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_21626991 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSubnetGroups_21626993(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_21626992(path: JsonNode; query: JsonNode;
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
  var valid_21626994 = query.getOrDefault("Action")
  valid_21626994 = validateParameter(valid_21626994, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21626994 != nil:
    section.add "Action", valid_21626994
  var valid_21626995 = query.getOrDefault("Version")
  valid_21626995 = validateParameter(valid_21626995, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626995 != nil:
    section.add "Version", valid_21626995
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
  var valid_21626996 = header.getOrDefault("X-Amz-Date")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Date", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-Security-Token", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Algorithm", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Signature")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Signature", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Credential")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Credential", valid_21627002
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627003 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "DBSubnetGroupName", valid_21627003
  var valid_21627004 = formData.getOrDefault("Marker")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "Marker", valid_21627004
  var valid_21627005 = formData.getOrDefault("MaxRecords")
  valid_21627005 = validateParameter(valid_21627005, JInt, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "MaxRecords", valid_21627005
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627006: Call_PostDescribeDBSubnetGroups_21626991;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627006.validator(path, query, header, formData, body, _)
  let scheme = call_21627006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627006.makeUrl(scheme.get, call_21627006.host, call_21627006.base,
                               call_21627006.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627006, uri, valid, _)

proc call*(call_21627007: Call_PostDescribeDBSubnetGroups_21626991;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627008 = newJObject()
  var formData_21627009 = newJObject()
  add(formData_21627009, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21627009, "Marker", newJString(Marker))
  add(query_21627008, "Action", newJString(Action))
  add(formData_21627009, "MaxRecords", newJInt(MaxRecords))
  add(query_21627008, "Version", newJString(Version))
  result = call_21627007.call(nil, query_21627008, nil, formData_21627009, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_21626991(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_21626992, base: "/",
    makeUrl: url_PostDescribeDBSubnetGroups_21626993,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_21626973 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSubnetGroups_21626975(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_21626974(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626976 = query.getOrDefault("MaxRecords")
  valid_21626976 = validateParameter(valid_21626976, JInt, required = false,
                                   default = nil)
  if valid_21626976 != nil:
    section.add "MaxRecords", valid_21626976
  var valid_21626977 = query.getOrDefault("Action")
  valid_21626977 = validateParameter(valid_21626977, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21626977 != nil:
    section.add "Action", valid_21626977
  var valid_21626978 = query.getOrDefault("Marker")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "Marker", valid_21626978
  var valid_21626979 = query.getOrDefault("DBSubnetGroupName")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "DBSubnetGroupName", valid_21626979
  var valid_21626980 = query.getOrDefault("Version")
  valid_21626980 = validateParameter(valid_21626980, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21626980 != nil:
    section.add "Version", valid_21626980
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
  var valid_21626981 = header.getOrDefault("X-Amz-Date")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Date", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-Security-Token", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Algorithm", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Signature")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Signature", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Credential")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Credential", valid_21626987
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626988: Call_GetDescribeDBSubnetGroups_21626973;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626988.validator(path, query, header, formData, body, _)
  let scheme = call_21626988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626988.makeUrl(scheme.get, call_21626988.host, call_21626988.base,
                               call_21626988.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626988, uri, valid, _)

proc call*(call_21626989: Call_GetDescribeDBSubnetGroups_21626973;
          MaxRecords: int = 0; Action: string = "DescribeDBSubnetGroups";
          Marker: string = ""; DBSubnetGroupName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_21626990 = newJObject()
  add(query_21626990, "MaxRecords", newJInt(MaxRecords))
  add(query_21626990, "Action", newJString(Action))
  add(query_21626990, "Marker", newJString(Marker))
  add(query_21626990, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626990, "Version", newJString(Version))
  result = call_21626989.call(nil, query_21626990, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_21626973(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_21626974, base: "/",
    makeUrl: url_GetDescribeDBSubnetGroups_21626975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_21627028 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEngineDefaultParameters_21627030(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_21627029(path: JsonNode;
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
  var valid_21627031 = query.getOrDefault("Action")
  valid_21627031 = validateParameter(valid_21627031, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_21627031 != nil:
    section.add "Action", valid_21627031
  var valid_21627032 = query.getOrDefault("Version")
  valid_21627032 = validateParameter(valid_21627032, JString, required = true,
                                   default = newJString("2013-01-10"))
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
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627040 = formData.getOrDefault("Marker")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "Marker", valid_21627040
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21627041 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21627041 = validateParameter(valid_21627041, JString, required = true,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "DBParameterGroupFamily", valid_21627041
  var valid_21627042 = formData.getOrDefault("MaxRecords")
  valid_21627042 = validateParameter(valid_21627042, JInt, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "MaxRecords", valid_21627042
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627043: Call_PostDescribeEngineDefaultParameters_21627028;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627043.validator(path, query, header, formData, body, _)
  let scheme = call_21627043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627043.makeUrl(scheme.get, call_21627043.host, call_21627043.base,
                               call_21627043.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627043, uri, valid, _)

proc call*(call_21627044: Call_PostDescribeEngineDefaultParameters_21627028;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627045 = newJObject()
  var formData_21627046 = newJObject()
  add(formData_21627046, "Marker", newJString(Marker))
  add(query_21627045, "Action", newJString(Action))
  add(formData_21627046, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_21627046, "MaxRecords", newJInt(MaxRecords))
  add(query_21627045, "Version", newJString(Version))
  result = call_21627044.call(nil, query_21627045, nil, formData_21627046, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_21627028(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_21627029, base: "/",
    makeUrl: url_PostDescribeEngineDefaultParameters_21627030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_21627010 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEngineDefaultParameters_21627012(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_21627011(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupFamily: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627013 = query.getOrDefault("MaxRecords")
  valid_21627013 = validateParameter(valid_21627013, JInt, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "MaxRecords", valid_21627013
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21627014 = query.getOrDefault("DBParameterGroupFamily")
  valid_21627014 = validateParameter(valid_21627014, JString, required = true,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "DBParameterGroupFamily", valid_21627014
  var valid_21627015 = query.getOrDefault("Action")
  valid_21627015 = validateParameter(valid_21627015, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_21627015 != nil:
    section.add "Action", valid_21627015
  var valid_21627016 = query.getOrDefault("Marker")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "Marker", valid_21627016
  var valid_21627017 = query.getOrDefault("Version")
  valid_21627017 = validateParameter(valid_21627017, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627017 != nil:
    section.add "Version", valid_21627017
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

proc call*(call_21627025: Call_GetDescribeEngineDefaultParameters_21627010;
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

proc call*(call_21627026: Call_GetDescribeEngineDefaultParameters_21627010;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21627027 = newJObject()
  add(query_21627027, "MaxRecords", newJInt(MaxRecords))
  add(query_21627027, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_21627027, "Action", newJString(Action))
  add(query_21627027, "Marker", newJString(Marker))
  add(query_21627027, "Version", newJString(Version))
  result = call_21627026.call(nil, query_21627027, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_21627010(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_21627011, base: "/",
    makeUrl: url_GetDescribeEngineDefaultParameters_21627012,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_21627063 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEventCategories_21627065(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_21627064(path: JsonNode; query: JsonNode;
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
  var valid_21627066 = query.getOrDefault("Action")
  valid_21627066 = validateParameter(valid_21627066, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21627066 != nil:
    section.add "Action", valid_21627066
  var valid_21627067 = query.getOrDefault("Version")
  valid_21627067 = validateParameter(valid_21627067, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627067 != nil:
    section.add "Version", valid_21627067
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
  var valid_21627068 = header.getOrDefault("X-Amz-Date")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-Date", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-Security-Token", valid_21627069
  var valid_21627070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627070 = validateParameter(valid_21627070, JString, required = false,
                                   default = nil)
  if valid_21627070 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627070
  var valid_21627071 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627071 = validateParameter(valid_21627071, JString, required = false,
                                   default = nil)
  if valid_21627071 != nil:
    section.add "X-Amz-Algorithm", valid_21627071
  var valid_21627072 = header.getOrDefault("X-Amz-Signature")
  valid_21627072 = validateParameter(valid_21627072, JString, required = false,
                                   default = nil)
  if valid_21627072 != nil:
    section.add "X-Amz-Signature", valid_21627072
  var valid_21627073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627073 = validateParameter(valid_21627073, JString, required = false,
                                   default = nil)
  if valid_21627073 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627073
  var valid_21627074 = header.getOrDefault("X-Amz-Credential")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Credential", valid_21627074
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_21627075 = formData.getOrDefault("SourceType")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "SourceType", valid_21627075
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627076: Call_PostDescribeEventCategories_21627063;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627076.validator(path, query, header, formData, body, _)
  let scheme = call_21627076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627076.makeUrl(scheme.get, call_21627076.host, call_21627076.base,
                               call_21627076.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627076, uri, valid, _)

proc call*(call_21627077: Call_PostDescribeEventCategories_21627063;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627078 = newJObject()
  var formData_21627079 = newJObject()
  add(query_21627078, "Action", newJString(Action))
  add(query_21627078, "Version", newJString(Version))
  add(formData_21627079, "SourceType", newJString(SourceType))
  result = call_21627077.call(nil, query_21627078, nil, formData_21627079, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_21627063(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_21627064, base: "/",
    makeUrl: url_PostDescribeEventCategories_21627065,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_21627047 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEventCategories_21627049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_21627048(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627050 = query.getOrDefault("SourceType")
  valid_21627050 = validateParameter(valid_21627050, JString, required = false,
                                   default = nil)
  if valid_21627050 != nil:
    section.add "SourceType", valid_21627050
  var valid_21627051 = query.getOrDefault("Action")
  valid_21627051 = validateParameter(valid_21627051, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21627051 != nil:
    section.add "Action", valid_21627051
  var valid_21627052 = query.getOrDefault("Version")
  valid_21627052 = validateParameter(valid_21627052, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627052 != nil:
    section.add "Version", valid_21627052
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
  var valid_21627053 = header.getOrDefault("X-Amz-Date")
  valid_21627053 = validateParameter(valid_21627053, JString, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "X-Amz-Date", valid_21627053
  var valid_21627054 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627054 = validateParameter(valid_21627054, JString, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "X-Amz-Security-Token", valid_21627054
  var valid_21627055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627055 = validateParameter(valid_21627055, JString, required = false,
                                   default = nil)
  if valid_21627055 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627055
  var valid_21627056 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "X-Amz-Algorithm", valid_21627056
  var valid_21627057 = header.getOrDefault("X-Amz-Signature")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "X-Amz-Signature", valid_21627057
  var valid_21627058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627058
  var valid_21627059 = header.getOrDefault("X-Amz-Credential")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Credential", valid_21627059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627060: Call_GetDescribeEventCategories_21627047;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627060.validator(path, query, header, formData, body, _)
  let scheme = call_21627060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627060.makeUrl(scheme.get, call_21627060.host, call_21627060.base,
                               call_21627060.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627060, uri, valid, _)

proc call*(call_21627061: Call_GetDescribeEventCategories_21627047;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627062 = newJObject()
  add(query_21627062, "SourceType", newJString(SourceType))
  add(query_21627062, "Action", newJString(Action))
  add(query_21627062, "Version", newJString(Version))
  result = call_21627061.call(nil, query_21627062, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_21627047(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_21627048, base: "/",
    makeUrl: url_GetDescribeEventCategories_21627049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_21627098 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEventSubscriptions_21627100(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_21627099(path: JsonNode;
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
  var valid_21627101 = query.getOrDefault("Action")
  valid_21627101 = validateParameter(valid_21627101, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_21627101 != nil:
    section.add "Action", valid_21627101
  var valid_21627102 = query.getOrDefault("Version")
  valid_21627102 = validateParameter(valid_21627102, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627102 != nil:
    section.add "Version", valid_21627102
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
  var valid_21627103 = header.getOrDefault("X-Amz-Date")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-Date", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Security-Token", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Algorithm", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Signature")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-Signature", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-Credential")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-Credential", valid_21627109
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627110 = formData.getOrDefault("Marker")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "Marker", valid_21627110
  var valid_21627111 = formData.getOrDefault("SubscriptionName")
  valid_21627111 = validateParameter(valid_21627111, JString, required = false,
                                   default = nil)
  if valid_21627111 != nil:
    section.add "SubscriptionName", valid_21627111
  var valid_21627112 = formData.getOrDefault("MaxRecords")
  valid_21627112 = validateParameter(valid_21627112, JInt, required = false,
                                   default = nil)
  if valid_21627112 != nil:
    section.add "MaxRecords", valid_21627112
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627113: Call_PostDescribeEventSubscriptions_21627098;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627113.validator(path, query, header, formData, body, _)
  let scheme = call_21627113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627113.makeUrl(scheme.get, call_21627113.host, call_21627113.base,
                               call_21627113.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627113, uri, valid, _)

proc call*(call_21627114: Call_PostDescribeEventSubscriptions_21627098;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627115 = newJObject()
  var formData_21627116 = newJObject()
  add(formData_21627116, "Marker", newJString(Marker))
  add(formData_21627116, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627115, "Action", newJString(Action))
  add(formData_21627116, "MaxRecords", newJInt(MaxRecords))
  add(query_21627115, "Version", newJString(Version))
  result = call_21627114.call(nil, query_21627115, nil, formData_21627116, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_21627098(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_21627099, base: "/",
    makeUrl: url_PostDescribeEventSubscriptions_21627100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_21627080 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEventSubscriptions_21627082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_21627081(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627083 = query.getOrDefault("MaxRecords")
  valid_21627083 = validateParameter(valid_21627083, JInt, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "MaxRecords", valid_21627083
  var valid_21627084 = query.getOrDefault("Action")
  valid_21627084 = validateParameter(valid_21627084, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_21627084 != nil:
    section.add "Action", valid_21627084
  var valid_21627085 = query.getOrDefault("Marker")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "Marker", valid_21627085
  var valid_21627086 = query.getOrDefault("SubscriptionName")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "SubscriptionName", valid_21627086
  var valid_21627087 = query.getOrDefault("Version")
  valid_21627087 = validateParameter(valid_21627087, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627087 != nil:
    section.add "Version", valid_21627087
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
  var valid_21627088 = header.getOrDefault("X-Amz-Date")
  valid_21627088 = validateParameter(valid_21627088, JString, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "X-Amz-Date", valid_21627088
  var valid_21627089 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627089 = validateParameter(valid_21627089, JString, required = false,
                                   default = nil)
  if valid_21627089 != nil:
    section.add "X-Amz-Security-Token", valid_21627089
  var valid_21627090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627090 = validateParameter(valid_21627090, JString, required = false,
                                   default = nil)
  if valid_21627090 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627090
  var valid_21627091 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627091 = validateParameter(valid_21627091, JString, required = false,
                                   default = nil)
  if valid_21627091 != nil:
    section.add "X-Amz-Algorithm", valid_21627091
  var valid_21627092 = header.getOrDefault("X-Amz-Signature")
  valid_21627092 = validateParameter(valid_21627092, JString, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "X-Amz-Signature", valid_21627092
  var valid_21627093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627093 = validateParameter(valid_21627093, JString, required = false,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627093
  var valid_21627094 = header.getOrDefault("X-Amz-Credential")
  valid_21627094 = validateParameter(valid_21627094, JString, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "X-Amz-Credential", valid_21627094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627095: Call_GetDescribeEventSubscriptions_21627080;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627095.validator(path, query, header, formData, body, _)
  let scheme = call_21627095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627095.makeUrl(scheme.get, call_21627095.host, call_21627095.base,
                               call_21627095.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627095, uri, valid, _)

proc call*(call_21627096: Call_GetDescribeEventSubscriptions_21627080;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_21627097 = newJObject()
  add(query_21627097, "MaxRecords", newJInt(MaxRecords))
  add(query_21627097, "Action", newJString(Action))
  add(query_21627097, "Marker", newJString(Marker))
  add(query_21627097, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627097, "Version", newJString(Version))
  result = call_21627096.call(nil, query_21627097, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_21627080(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_21627081, base: "/",
    makeUrl: url_GetDescribeEventSubscriptions_21627082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_21627140 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEvents_21627142(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_21627141(path: JsonNode; query: JsonNode;
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
  var valid_21627143 = query.getOrDefault("Action")
  valid_21627143 = validateParameter(valid_21627143, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627143 != nil:
    section.add "Action", valid_21627143
  var valid_21627144 = query.getOrDefault("Version")
  valid_21627144 = validateParameter(valid_21627144, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627144 != nil:
    section.add "Version", valid_21627144
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
  var valid_21627145 = header.getOrDefault("X-Amz-Date")
  valid_21627145 = validateParameter(valid_21627145, JString, required = false,
                                   default = nil)
  if valid_21627145 != nil:
    section.add "X-Amz-Date", valid_21627145
  var valid_21627146 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627146 = validateParameter(valid_21627146, JString, required = false,
                                   default = nil)
  if valid_21627146 != nil:
    section.add "X-Amz-Security-Token", valid_21627146
  var valid_21627147 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627147 = validateParameter(valid_21627147, JString, required = false,
                                   default = nil)
  if valid_21627147 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627147
  var valid_21627148 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627148 = validateParameter(valid_21627148, JString, required = false,
                                   default = nil)
  if valid_21627148 != nil:
    section.add "X-Amz-Algorithm", valid_21627148
  var valid_21627149 = header.getOrDefault("X-Amz-Signature")
  valid_21627149 = validateParameter(valid_21627149, JString, required = false,
                                   default = nil)
  if valid_21627149 != nil:
    section.add "X-Amz-Signature", valid_21627149
  var valid_21627150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627150
  var valid_21627151 = header.getOrDefault("X-Amz-Credential")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-Credential", valid_21627151
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_21627152 = formData.getOrDefault("SourceIdentifier")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "SourceIdentifier", valid_21627152
  var valid_21627153 = formData.getOrDefault("EventCategories")
  valid_21627153 = validateParameter(valid_21627153, JArray, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "EventCategories", valid_21627153
  var valid_21627154 = formData.getOrDefault("Marker")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "Marker", valid_21627154
  var valid_21627155 = formData.getOrDefault("StartTime")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "StartTime", valid_21627155
  var valid_21627156 = formData.getOrDefault("Duration")
  valid_21627156 = validateParameter(valid_21627156, JInt, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "Duration", valid_21627156
  var valid_21627157 = formData.getOrDefault("EndTime")
  valid_21627157 = validateParameter(valid_21627157, JString, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "EndTime", valid_21627157
  var valid_21627158 = formData.getOrDefault("MaxRecords")
  valid_21627158 = validateParameter(valid_21627158, JInt, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "MaxRecords", valid_21627158
  var valid_21627159 = formData.getOrDefault("SourceType")
  valid_21627159 = validateParameter(valid_21627159, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21627159 != nil:
    section.add "SourceType", valid_21627159
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627160: Call_PostDescribeEvents_21627140; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627160.validator(path, query, header, formData, body, _)
  let scheme = call_21627160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627160.makeUrl(scheme.get, call_21627160.host, call_21627160.base,
                               call_21627160.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627160, uri, valid, _)

proc call*(call_21627161: Call_PostDescribeEvents_21627140;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; EndTime: string = "";
          MaxRecords: int = 0; Version: string = "2013-01-10";
          SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ##   SourceIdentifier: string
  ##   EventCategories: JArray
  ##   Marker: string
  ##   StartTime: string
  ##   Action: string (required)
  ##   Duration: int
  ##   EndTime: string
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627162 = newJObject()
  var formData_21627163 = newJObject()
  add(formData_21627163, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_21627163.add "EventCategories", EventCategories
  add(formData_21627163, "Marker", newJString(Marker))
  add(formData_21627163, "StartTime", newJString(StartTime))
  add(query_21627162, "Action", newJString(Action))
  add(formData_21627163, "Duration", newJInt(Duration))
  add(formData_21627163, "EndTime", newJString(EndTime))
  add(formData_21627163, "MaxRecords", newJInt(MaxRecords))
  add(query_21627162, "Version", newJString(Version))
  add(formData_21627163, "SourceType", newJString(SourceType))
  result = call_21627161.call(nil, query_21627162, nil, formData_21627163, nil)

var postDescribeEvents* = Call_PostDescribeEvents_21627140(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_21627141, base: "/",
    makeUrl: url_PostDescribeEvents_21627142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_21627117 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEvents_21627119(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_21627118(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   SourceIdentifier: JString
  ##   Marker: JString
  ##   EventCategories: JArray
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627120 = query.getOrDefault("SourceType")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21627120 != nil:
    section.add "SourceType", valid_21627120
  var valid_21627121 = query.getOrDefault("MaxRecords")
  valid_21627121 = validateParameter(valid_21627121, JInt, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "MaxRecords", valid_21627121
  var valid_21627122 = query.getOrDefault("StartTime")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "StartTime", valid_21627122
  var valid_21627123 = query.getOrDefault("Action")
  valid_21627123 = validateParameter(valid_21627123, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627123 != nil:
    section.add "Action", valid_21627123
  var valid_21627124 = query.getOrDefault("SourceIdentifier")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "SourceIdentifier", valid_21627124
  var valid_21627125 = query.getOrDefault("Marker")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "Marker", valid_21627125
  var valid_21627126 = query.getOrDefault("EventCategories")
  valid_21627126 = validateParameter(valid_21627126, JArray, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "EventCategories", valid_21627126
  var valid_21627127 = query.getOrDefault("Duration")
  valid_21627127 = validateParameter(valid_21627127, JInt, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "Duration", valid_21627127
  var valid_21627128 = query.getOrDefault("EndTime")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "EndTime", valid_21627128
  var valid_21627129 = query.getOrDefault("Version")
  valid_21627129 = validateParameter(valid_21627129, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627129 != nil:
    section.add "Version", valid_21627129
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
  var valid_21627130 = header.getOrDefault("X-Amz-Date")
  valid_21627130 = validateParameter(valid_21627130, JString, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "X-Amz-Date", valid_21627130
  var valid_21627131 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "X-Amz-Security-Token", valid_21627131
  var valid_21627132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627132 = validateParameter(valid_21627132, JString, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627132
  var valid_21627133 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627133 = validateParameter(valid_21627133, JString, required = false,
                                   default = nil)
  if valid_21627133 != nil:
    section.add "X-Amz-Algorithm", valid_21627133
  var valid_21627134 = header.getOrDefault("X-Amz-Signature")
  valid_21627134 = validateParameter(valid_21627134, JString, required = false,
                                   default = nil)
  if valid_21627134 != nil:
    section.add "X-Amz-Signature", valid_21627134
  var valid_21627135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Credential")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Credential", valid_21627136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627137: Call_GetDescribeEvents_21627117; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627137.validator(path, query, header, formData, body, _)
  let scheme = call_21627137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627137.makeUrl(scheme.get, call_21627137.host, call_21627137.base,
                               call_21627137.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627137, uri, valid, _)

proc call*(call_21627138: Call_GetDescribeEvents_21627117;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Action: string = "DescribeEvents";
          SourceIdentifier: string = ""; Marker: string = "";
          EventCategories: JsonNode = nil; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEvents
  ##   SourceType: string
  ##   MaxRecords: int
  ##   StartTime: string
  ##   Action: string (required)
  ##   SourceIdentifier: string
  ##   Marker: string
  ##   EventCategories: JArray
  ##   Duration: int
  ##   EndTime: string
  ##   Version: string (required)
  var query_21627139 = newJObject()
  add(query_21627139, "SourceType", newJString(SourceType))
  add(query_21627139, "MaxRecords", newJInt(MaxRecords))
  add(query_21627139, "StartTime", newJString(StartTime))
  add(query_21627139, "Action", newJString(Action))
  add(query_21627139, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21627139, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_21627139.add "EventCategories", EventCategories
  add(query_21627139, "Duration", newJInt(Duration))
  add(query_21627139, "EndTime", newJString(EndTime))
  add(query_21627139, "Version", newJString(Version))
  result = call_21627138.call(nil, query_21627139, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_21627117(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_21627118,
    base: "/", makeUrl: url_GetDescribeEvents_21627119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_21627183 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOptionGroupOptions_21627185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_21627184(path: JsonNode;
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
  var valid_21627186 = query.getOrDefault("Action")
  valid_21627186 = validateParameter(valid_21627186, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_21627186 != nil:
    section.add "Action", valid_21627186
  var valid_21627187 = query.getOrDefault("Version")
  valid_21627187 = validateParameter(valid_21627187, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627187 != nil:
    section.add "Version", valid_21627187
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
  var valid_21627188 = header.getOrDefault("X-Amz-Date")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Date", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Security-Token", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Algorithm", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-Signature")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-Signature", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627193
  var valid_21627194 = header.getOrDefault("X-Amz-Credential")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "X-Amz-Credential", valid_21627194
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627195 = formData.getOrDefault("MajorEngineVersion")
  valid_21627195 = validateParameter(valid_21627195, JString, required = false,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "MajorEngineVersion", valid_21627195
  var valid_21627196 = formData.getOrDefault("Marker")
  valid_21627196 = validateParameter(valid_21627196, JString, required = false,
                                   default = nil)
  if valid_21627196 != nil:
    section.add "Marker", valid_21627196
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_21627197 = formData.getOrDefault("EngineName")
  valid_21627197 = validateParameter(valid_21627197, JString, required = true,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "EngineName", valid_21627197
  var valid_21627198 = formData.getOrDefault("MaxRecords")
  valid_21627198 = validateParameter(valid_21627198, JInt, required = false,
                                   default = nil)
  if valid_21627198 != nil:
    section.add "MaxRecords", valid_21627198
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627199: Call_PostDescribeOptionGroupOptions_21627183;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627199.validator(path, query, header, formData, body, _)
  let scheme = call_21627199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627199.makeUrl(scheme.get, call_21627199.host, call_21627199.base,
                               call_21627199.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627199, uri, valid, _)

proc call*(call_21627200: Call_PostDescribeOptionGroupOptions_21627183;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627201 = newJObject()
  var formData_21627202 = newJObject()
  add(formData_21627202, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21627202, "Marker", newJString(Marker))
  add(query_21627201, "Action", newJString(Action))
  add(formData_21627202, "EngineName", newJString(EngineName))
  add(formData_21627202, "MaxRecords", newJInt(MaxRecords))
  add(query_21627201, "Version", newJString(Version))
  result = call_21627200.call(nil, query_21627201, nil, formData_21627202, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_21627183(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_21627184, base: "/",
    makeUrl: url_PostDescribeOptionGroupOptions_21627185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_21627164 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOptionGroupOptions_21627166(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_21627165(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_21627167 = query.getOrDefault("MaxRecords")
  valid_21627167 = validateParameter(valid_21627167, JInt, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "MaxRecords", valid_21627167
  var valid_21627168 = query.getOrDefault("Action")
  valid_21627168 = validateParameter(valid_21627168, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_21627168 != nil:
    section.add "Action", valid_21627168
  var valid_21627169 = query.getOrDefault("Marker")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "Marker", valid_21627169
  var valid_21627170 = query.getOrDefault("Version")
  valid_21627170 = validateParameter(valid_21627170, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627170 != nil:
    section.add "Version", valid_21627170
  var valid_21627171 = query.getOrDefault("EngineName")
  valid_21627171 = validateParameter(valid_21627171, JString, required = true,
                                   default = nil)
  if valid_21627171 != nil:
    section.add "EngineName", valid_21627171
  var valid_21627172 = query.getOrDefault("MajorEngineVersion")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "MajorEngineVersion", valid_21627172
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
  var valid_21627173 = header.getOrDefault("X-Amz-Date")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Date", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Security-Token", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Algorithm", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-Signature")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-Signature", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627178 = validateParameter(valid_21627178, JString, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627178
  var valid_21627179 = header.getOrDefault("X-Amz-Credential")
  valid_21627179 = validateParameter(valid_21627179, JString, required = false,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "X-Amz-Credential", valid_21627179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627180: Call_GetDescribeOptionGroupOptions_21627164;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627180.validator(path, query, header, formData, body, _)
  let scheme = call_21627180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627180.makeUrl(scheme.get, call_21627180.host, call_21627180.base,
                               call_21627180.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627180, uri, valid, _)

proc call*(call_21627181: Call_GetDescribeOptionGroupOptions_21627164;
          EngineName: string; MaxRecords: int = 0;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2013-01-10"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_21627182 = newJObject()
  add(query_21627182, "MaxRecords", newJInt(MaxRecords))
  add(query_21627182, "Action", newJString(Action))
  add(query_21627182, "Marker", newJString(Marker))
  add(query_21627182, "Version", newJString(Version))
  add(query_21627182, "EngineName", newJString(EngineName))
  add(query_21627182, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21627181.call(nil, query_21627182, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_21627164(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_21627165, base: "/",
    makeUrl: url_GetDescribeOptionGroupOptions_21627166,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_21627223 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOptionGroups_21627225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_21627224(path: JsonNode; query: JsonNode;
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
  var valid_21627226 = query.getOrDefault("Action")
  valid_21627226 = validateParameter(valid_21627226, JString, required = true,
                                   default = newJString("DescribeOptionGroups"))
  if valid_21627226 != nil:
    section.add "Action", valid_21627226
  var valid_21627227 = query.getOrDefault("Version")
  valid_21627227 = validateParameter(valid_21627227, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627227 != nil:
    section.add "Version", valid_21627227
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
  var valid_21627228 = header.getOrDefault("X-Amz-Date")
  valid_21627228 = validateParameter(valid_21627228, JString, required = false,
                                   default = nil)
  if valid_21627228 != nil:
    section.add "X-Amz-Date", valid_21627228
  var valid_21627229 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627229 = validateParameter(valid_21627229, JString, required = false,
                                   default = nil)
  if valid_21627229 != nil:
    section.add "X-Amz-Security-Token", valid_21627229
  var valid_21627230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627230 = validateParameter(valid_21627230, JString, required = false,
                                   default = nil)
  if valid_21627230 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627230
  var valid_21627231 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-Algorithm", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Signature")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Signature", valid_21627232
  var valid_21627233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Credential")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Credential", valid_21627234
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627235 = formData.getOrDefault("MajorEngineVersion")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "MajorEngineVersion", valid_21627235
  var valid_21627236 = formData.getOrDefault("OptionGroupName")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "OptionGroupName", valid_21627236
  var valid_21627237 = formData.getOrDefault("Marker")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "Marker", valid_21627237
  var valid_21627238 = formData.getOrDefault("EngineName")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "EngineName", valid_21627238
  var valid_21627239 = formData.getOrDefault("MaxRecords")
  valid_21627239 = validateParameter(valid_21627239, JInt, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "MaxRecords", valid_21627239
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627240: Call_PostDescribeOptionGroups_21627223;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627240.validator(path, query, header, formData, body, _)
  let scheme = call_21627240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627240.makeUrl(scheme.get, call_21627240.host, call_21627240.base,
                               call_21627240.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627240, uri, valid, _)

proc call*(call_21627241: Call_PostDescribeOptionGroups_21627223;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; MaxRecords: int = 0; Version: string = "2013-01-10"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627242 = newJObject()
  var formData_21627243 = newJObject()
  add(formData_21627243, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21627243, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627243, "Marker", newJString(Marker))
  add(query_21627242, "Action", newJString(Action))
  add(formData_21627243, "EngineName", newJString(EngineName))
  add(formData_21627243, "MaxRecords", newJInt(MaxRecords))
  add(query_21627242, "Version", newJString(Version))
  result = call_21627241.call(nil, query_21627242, nil, formData_21627243, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_21627223(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_21627224, base: "/",
    makeUrl: url_PostDescribeOptionGroups_21627225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_21627203 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOptionGroups_21627205(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_21627204(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   OptionGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_21627206 = query.getOrDefault("MaxRecords")
  valid_21627206 = validateParameter(valid_21627206, JInt, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "MaxRecords", valid_21627206
  var valid_21627207 = query.getOrDefault("OptionGroupName")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "OptionGroupName", valid_21627207
  var valid_21627208 = query.getOrDefault("Action")
  valid_21627208 = validateParameter(valid_21627208, JString, required = true,
                                   default = newJString("DescribeOptionGroups"))
  if valid_21627208 != nil:
    section.add "Action", valid_21627208
  var valid_21627209 = query.getOrDefault("Marker")
  valid_21627209 = validateParameter(valid_21627209, JString, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "Marker", valid_21627209
  var valid_21627210 = query.getOrDefault("Version")
  valid_21627210 = validateParameter(valid_21627210, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627210 != nil:
    section.add "Version", valid_21627210
  var valid_21627211 = query.getOrDefault("EngineName")
  valid_21627211 = validateParameter(valid_21627211, JString, required = false,
                                   default = nil)
  if valid_21627211 != nil:
    section.add "EngineName", valid_21627211
  var valid_21627212 = query.getOrDefault("MajorEngineVersion")
  valid_21627212 = validateParameter(valid_21627212, JString, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "MajorEngineVersion", valid_21627212
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
  var valid_21627213 = header.getOrDefault("X-Amz-Date")
  valid_21627213 = validateParameter(valid_21627213, JString, required = false,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "X-Amz-Date", valid_21627213
  var valid_21627214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627214 = validateParameter(valid_21627214, JString, required = false,
                                   default = nil)
  if valid_21627214 != nil:
    section.add "X-Amz-Security-Token", valid_21627214
  var valid_21627215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627215 = validateParameter(valid_21627215, JString, required = false,
                                   default = nil)
  if valid_21627215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627215
  var valid_21627216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "X-Amz-Algorithm", valid_21627216
  var valid_21627217 = header.getOrDefault("X-Amz-Signature")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Signature", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Credential")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Credential", valid_21627219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627220: Call_GetDescribeOptionGroups_21627203;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627220.validator(path, query, header, formData, body, _)
  let scheme = call_21627220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627220.makeUrl(scheme.get, call_21627220.host, call_21627220.base,
                               call_21627220.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627220, uri, valid, _)

proc call*(call_21627221: Call_GetDescribeOptionGroups_21627203;
          MaxRecords: int = 0; OptionGroupName: string = "";
          Action: string = "DescribeOptionGroups"; Marker: string = "";
          Version: string = "2013-01-10"; EngineName: string = "";
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_21627222 = newJObject()
  add(query_21627222, "MaxRecords", newJInt(MaxRecords))
  add(query_21627222, "OptionGroupName", newJString(OptionGroupName))
  add(query_21627222, "Action", newJString(Action))
  add(query_21627222, "Marker", newJString(Marker))
  add(query_21627222, "Version", newJString(Version))
  add(query_21627222, "EngineName", newJString(EngineName))
  add(query_21627222, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21627221.call(nil, query_21627222, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_21627203(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_21627204, base: "/",
    makeUrl: url_GetDescribeOptionGroups_21627205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_21627266 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOrderableDBInstanceOptions_21627268(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_21627267(path: JsonNode;
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
  var valid_21627269 = query.getOrDefault("Action")
  valid_21627269 = validateParameter(valid_21627269, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627269 != nil:
    section.add "Action", valid_21627269
  var valid_21627270 = query.getOrDefault("Version")
  valid_21627270 = validateParameter(valid_21627270, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627270 != nil:
    section.add "Version", valid_21627270
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
  var valid_21627271 = header.getOrDefault("X-Amz-Date")
  valid_21627271 = validateParameter(valid_21627271, JString, required = false,
                                   default = nil)
  if valid_21627271 != nil:
    section.add "X-Amz-Date", valid_21627271
  var valid_21627272 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627272 = validateParameter(valid_21627272, JString, required = false,
                                   default = nil)
  if valid_21627272 != nil:
    section.add "X-Amz-Security-Token", valid_21627272
  var valid_21627273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627273 = validateParameter(valid_21627273, JString, required = false,
                                   default = nil)
  if valid_21627273 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "X-Amz-Algorithm", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-Signature")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Signature", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-Credential")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Credential", valid_21627277
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##   Marker: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21627278 = formData.getOrDefault("Engine")
  valid_21627278 = validateParameter(valid_21627278, JString, required = true,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "Engine", valid_21627278
  var valid_21627279 = formData.getOrDefault("Marker")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "Marker", valid_21627279
  var valid_21627280 = formData.getOrDefault("Vpc")
  valid_21627280 = validateParameter(valid_21627280, JBool, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "Vpc", valid_21627280
  var valid_21627281 = formData.getOrDefault("DBInstanceClass")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "DBInstanceClass", valid_21627281
  var valid_21627282 = formData.getOrDefault("LicenseModel")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "LicenseModel", valid_21627282
  var valid_21627283 = formData.getOrDefault("MaxRecords")
  valid_21627283 = validateParameter(valid_21627283, JInt, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "MaxRecords", valid_21627283
  var valid_21627284 = formData.getOrDefault("EngineVersion")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "EngineVersion", valid_21627284
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627285: Call_PostDescribeOrderableDBInstanceOptions_21627266;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627285.validator(path, query, header, formData, body, _)
  let scheme = call_21627285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627285.makeUrl(scheme.get, call_21627285.host, call_21627285.base,
                               call_21627285.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627285, uri, valid, _)

proc call*(call_21627286: Call_PostDescribeOrderableDBInstanceOptions_21627266;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_21627287 = newJObject()
  var formData_21627288 = newJObject()
  add(formData_21627288, "Engine", newJString(Engine))
  add(formData_21627288, "Marker", newJString(Marker))
  add(query_21627287, "Action", newJString(Action))
  add(formData_21627288, "Vpc", newJBool(Vpc))
  add(formData_21627288, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627288, "LicenseModel", newJString(LicenseModel))
  add(formData_21627288, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627288, "EngineVersion", newJString(EngineVersion))
  add(query_21627287, "Version", newJString(Version))
  result = call_21627286.call(nil, query_21627287, nil, formData_21627288, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_21627266(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_21627267,
    base: "/", makeUrl: url_PostDescribeOrderableDBInstanceOptions_21627268,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_21627244 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOrderableDBInstanceOptions_21627246(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_21627245(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##   MaxRecords: JInt
  ##   LicenseModel: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_21627247 = query.getOrDefault("Engine")
  valid_21627247 = validateParameter(valid_21627247, JString, required = true,
                                   default = nil)
  if valid_21627247 != nil:
    section.add "Engine", valid_21627247
  var valid_21627248 = query.getOrDefault("MaxRecords")
  valid_21627248 = validateParameter(valid_21627248, JInt, required = false,
                                   default = nil)
  if valid_21627248 != nil:
    section.add "MaxRecords", valid_21627248
  var valid_21627249 = query.getOrDefault("LicenseModel")
  valid_21627249 = validateParameter(valid_21627249, JString, required = false,
                                   default = nil)
  if valid_21627249 != nil:
    section.add "LicenseModel", valid_21627249
  var valid_21627250 = query.getOrDefault("Vpc")
  valid_21627250 = validateParameter(valid_21627250, JBool, required = false,
                                   default = nil)
  if valid_21627250 != nil:
    section.add "Vpc", valid_21627250
  var valid_21627251 = query.getOrDefault("DBInstanceClass")
  valid_21627251 = validateParameter(valid_21627251, JString, required = false,
                                   default = nil)
  if valid_21627251 != nil:
    section.add "DBInstanceClass", valid_21627251
  var valid_21627252 = query.getOrDefault("Action")
  valid_21627252 = validateParameter(valid_21627252, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627252 != nil:
    section.add "Action", valid_21627252
  var valid_21627253 = query.getOrDefault("Marker")
  valid_21627253 = validateParameter(valid_21627253, JString, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "Marker", valid_21627253
  var valid_21627254 = query.getOrDefault("EngineVersion")
  valid_21627254 = validateParameter(valid_21627254, JString, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "EngineVersion", valid_21627254
  var valid_21627255 = query.getOrDefault("Version")
  valid_21627255 = validateParameter(valid_21627255, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627255 != nil:
    section.add "Version", valid_21627255
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
  var valid_21627256 = header.getOrDefault("X-Amz-Date")
  valid_21627256 = validateParameter(valid_21627256, JString, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "X-Amz-Date", valid_21627256
  var valid_21627257 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "X-Amz-Security-Token", valid_21627257
  var valid_21627258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627259 = validateParameter(valid_21627259, JString, required = false,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "X-Amz-Algorithm", valid_21627259
  var valid_21627260 = header.getOrDefault("X-Amz-Signature")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-Signature", valid_21627260
  var valid_21627261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627261 = validateParameter(valid_21627261, JString, required = false,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627261
  var valid_21627262 = header.getOrDefault("X-Amz-Credential")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "X-Amz-Credential", valid_21627262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627263: Call_GetDescribeOrderableDBInstanceOptions_21627244;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627263.validator(path, query, header, formData, body, _)
  let scheme = call_21627263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627263.makeUrl(scheme.get, call_21627263.host, call_21627263.base,
                               call_21627263.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627263, uri, valid, _)

proc call*(call_21627264: Call_GetDescribeOrderableDBInstanceOptions_21627244;
          Engine: string; MaxRecords: int = 0; LicenseModel: string = "";
          Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   MaxRecords: int
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_21627265 = newJObject()
  add(query_21627265, "Engine", newJString(Engine))
  add(query_21627265, "MaxRecords", newJInt(MaxRecords))
  add(query_21627265, "LicenseModel", newJString(LicenseModel))
  add(query_21627265, "Vpc", newJBool(Vpc))
  add(query_21627265, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627265, "Action", newJString(Action))
  add(query_21627265, "Marker", newJString(Marker))
  add(query_21627265, "EngineVersion", newJString(EngineVersion))
  add(query_21627265, "Version", newJString(Version))
  result = call_21627264.call(nil, query_21627265, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_21627244(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_21627245, base: "/",
    makeUrl: url_GetDescribeOrderableDBInstanceOptions_21627246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_21627313 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeReservedDBInstances_21627315(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_21627314(path: JsonNode;
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
  var valid_21627316 = query.getOrDefault("Action")
  valid_21627316 = validateParameter(valid_21627316, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_21627316 != nil:
    section.add "Action", valid_21627316
  var valid_21627317 = query.getOrDefault("Version")
  valid_21627317 = validateParameter(valid_21627317, JString, required = true,
                                   default = newJString("2013-01-10"))
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
  ##   OfferingType: JString
  ##   ReservedDBInstanceId: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_21627325 = formData.getOrDefault("OfferingType")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "OfferingType", valid_21627325
  var valid_21627326 = formData.getOrDefault("ReservedDBInstanceId")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "ReservedDBInstanceId", valid_21627326
  var valid_21627327 = formData.getOrDefault("Marker")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "Marker", valid_21627327
  var valid_21627328 = formData.getOrDefault("MultiAZ")
  valid_21627328 = validateParameter(valid_21627328, JBool, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "MultiAZ", valid_21627328
  var valid_21627329 = formData.getOrDefault("Duration")
  valid_21627329 = validateParameter(valid_21627329, JString, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "Duration", valid_21627329
  var valid_21627330 = formData.getOrDefault("DBInstanceClass")
  valid_21627330 = validateParameter(valid_21627330, JString, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "DBInstanceClass", valid_21627330
  var valid_21627331 = formData.getOrDefault("ProductDescription")
  valid_21627331 = validateParameter(valid_21627331, JString, required = false,
                                   default = nil)
  if valid_21627331 != nil:
    section.add "ProductDescription", valid_21627331
  var valid_21627332 = formData.getOrDefault("MaxRecords")
  valid_21627332 = validateParameter(valid_21627332, JInt, required = false,
                                   default = nil)
  if valid_21627332 != nil:
    section.add "MaxRecords", valid_21627332
  var valid_21627333 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627333 = validateParameter(valid_21627333, JString, required = false,
                                   default = nil)
  if valid_21627333 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627333
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627334: Call_PostDescribeReservedDBInstances_21627313;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627334.validator(path, query, header, formData, body, _)
  let scheme = call_21627334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627334.makeUrl(scheme.get, call_21627334.host, call_21627334.base,
                               call_21627334.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627334, uri, valid, _)

proc call*(call_21627335: Call_PostDescribeReservedDBInstances_21627313;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; ProductDescription: string = "";
          MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeReservedDBInstances
  ##   OfferingType: string
  ##   ReservedDBInstanceId: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_21627336 = newJObject()
  var formData_21627337 = newJObject()
  add(formData_21627337, "OfferingType", newJString(OfferingType))
  add(formData_21627337, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_21627337, "Marker", newJString(Marker))
  add(formData_21627337, "MultiAZ", newJBool(MultiAZ))
  add(query_21627336, "Action", newJString(Action))
  add(formData_21627337, "Duration", newJString(Duration))
  add(formData_21627337, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627337, "ProductDescription", newJString(ProductDescription))
  add(formData_21627337, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627337, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627336, "Version", newJString(Version))
  result = call_21627335.call(nil, query_21627336, nil, formData_21627337, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_21627313(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_21627314, base: "/",
    makeUrl: url_PostDescribeReservedDBInstances_21627315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_21627289 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeReservedDBInstances_21627291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_21627290(path: JsonNode;
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
  ##   MultiAZ: JBool
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627292 = query.getOrDefault("ProductDescription")
  valid_21627292 = validateParameter(valid_21627292, JString, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "ProductDescription", valid_21627292
  var valid_21627293 = query.getOrDefault("MaxRecords")
  valid_21627293 = validateParameter(valid_21627293, JInt, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "MaxRecords", valid_21627293
  var valid_21627294 = query.getOrDefault("OfferingType")
  valid_21627294 = validateParameter(valid_21627294, JString, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "OfferingType", valid_21627294
  var valid_21627295 = query.getOrDefault("MultiAZ")
  valid_21627295 = validateParameter(valid_21627295, JBool, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "MultiAZ", valid_21627295
  var valid_21627296 = query.getOrDefault("ReservedDBInstanceId")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "ReservedDBInstanceId", valid_21627296
  var valid_21627297 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627297
  var valid_21627298 = query.getOrDefault("DBInstanceClass")
  valid_21627298 = validateParameter(valid_21627298, JString, required = false,
                                   default = nil)
  if valid_21627298 != nil:
    section.add "DBInstanceClass", valid_21627298
  var valid_21627299 = query.getOrDefault("Action")
  valid_21627299 = validateParameter(valid_21627299, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_21627299 != nil:
    section.add "Action", valid_21627299
  var valid_21627300 = query.getOrDefault("Marker")
  valid_21627300 = validateParameter(valid_21627300, JString, required = false,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "Marker", valid_21627300
  var valid_21627301 = query.getOrDefault("Duration")
  valid_21627301 = validateParameter(valid_21627301, JString, required = false,
                                   default = nil)
  if valid_21627301 != nil:
    section.add "Duration", valid_21627301
  var valid_21627302 = query.getOrDefault("Version")
  valid_21627302 = validateParameter(valid_21627302, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627302 != nil:
    section.add "Version", valid_21627302
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

proc call*(call_21627310: Call_GetDescribeReservedDBInstances_21627289;
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

proc call*(call_21627311: Call_GetDescribeReservedDBInstances_21627289;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeReservedDBInstances
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   MultiAZ: bool
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_21627312 = newJObject()
  add(query_21627312, "ProductDescription", newJString(ProductDescription))
  add(query_21627312, "MaxRecords", newJInt(MaxRecords))
  add(query_21627312, "OfferingType", newJString(OfferingType))
  add(query_21627312, "MultiAZ", newJBool(MultiAZ))
  add(query_21627312, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_21627312, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627312, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627312, "Action", newJString(Action))
  add(query_21627312, "Marker", newJString(Marker))
  add(query_21627312, "Duration", newJString(Duration))
  add(query_21627312, "Version", newJString(Version))
  result = call_21627311.call(nil, query_21627312, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_21627289(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_21627290, base: "/",
    makeUrl: url_GetDescribeReservedDBInstances_21627291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_21627361 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeReservedDBInstancesOfferings_21627363(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_21627362(path: JsonNode;
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
  var valid_21627364 = query.getOrDefault("Action")
  valid_21627364 = validateParameter(valid_21627364, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_21627364 != nil:
    section.add "Action", valid_21627364
  var valid_21627365 = query.getOrDefault("Version")
  valid_21627365 = validateParameter(valid_21627365, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627365 != nil:
    section.add "Version", valid_21627365
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
  var valid_21627366 = header.getOrDefault("X-Amz-Date")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "X-Amz-Date", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-Security-Token", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Algorithm", valid_21627369
  var valid_21627370 = header.getOrDefault("X-Amz-Signature")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "X-Amz-Signature", valid_21627370
  var valid_21627371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627371
  var valid_21627372 = header.getOrDefault("X-Amz-Credential")
  valid_21627372 = validateParameter(valid_21627372, JString, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "X-Amz-Credential", valid_21627372
  result.add "header", section
  ## parameters in `formData` object:
  ##   OfferingType: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_21627373 = formData.getOrDefault("OfferingType")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "OfferingType", valid_21627373
  var valid_21627374 = formData.getOrDefault("Marker")
  valid_21627374 = validateParameter(valid_21627374, JString, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "Marker", valid_21627374
  var valid_21627375 = formData.getOrDefault("MultiAZ")
  valid_21627375 = validateParameter(valid_21627375, JBool, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "MultiAZ", valid_21627375
  var valid_21627376 = formData.getOrDefault("Duration")
  valid_21627376 = validateParameter(valid_21627376, JString, required = false,
                                   default = nil)
  if valid_21627376 != nil:
    section.add "Duration", valid_21627376
  var valid_21627377 = formData.getOrDefault("DBInstanceClass")
  valid_21627377 = validateParameter(valid_21627377, JString, required = false,
                                   default = nil)
  if valid_21627377 != nil:
    section.add "DBInstanceClass", valid_21627377
  var valid_21627378 = formData.getOrDefault("ProductDescription")
  valid_21627378 = validateParameter(valid_21627378, JString, required = false,
                                   default = nil)
  if valid_21627378 != nil:
    section.add "ProductDescription", valid_21627378
  var valid_21627379 = formData.getOrDefault("MaxRecords")
  valid_21627379 = validateParameter(valid_21627379, JInt, required = false,
                                   default = nil)
  if valid_21627379 != nil:
    section.add "MaxRecords", valid_21627379
  var valid_21627380 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627380 = validateParameter(valid_21627380, JString, required = false,
                                   default = nil)
  if valid_21627380 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627381: Call_PostDescribeReservedDBInstancesOfferings_21627361;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627381.validator(path, query, header, formData, body, _)
  let scheme = call_21627381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627381.makeUrl(scheme.get, call_21627381.host, call_21627381.base,
                               call_21627381.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627381, uri, valid, _)

proc call*(call_21627382: Call_PostDescribeReservedDBInstancesOfferings_21627361;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = "";
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   OfferingType: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_21627383 = newJObject()
  var formData_21627384 = newJObject()
  add(formData_21627384, "OfferingType", newJString(OfferingType))
  add(formData_21627384, "Marker", newJString(Marker))
  add(formData_21627384, "MultiAZ", newJBool(MultiAZ))
  add(query_21627383, "Action", newJString(Action))
  add(formData_21627384, "Duration", newJString(Duration))
  add(formData_21627384, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627384, "ProductDescription", newJString(ProductDescription))
  add(formData_21627384, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627384, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627383, "Version", newJString(Version))
  result = call_21627382.call(nil, query_21627383, nil, formData_21627384, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_21627361(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_21627362,
    base: "/", makeUrl: url_PostDescribeReservedDBInstancesOfferings_21627363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_21627338 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeReservedDBInstancesOfferings_21627340(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_21627339(path: JsonNode;
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
  ##   MultiAZ: JBool
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627341 = query.getOrDefault("ProductDescription")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "ProductDescription", valid_21627341
  var valid_21627342 = query.getOrDefault("MaxRecords")
  valid_21627342 = validateParameter(valid_21627342, JInt, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "MaxRecords", valid_21627342
  var valid_21627343 = query.getOrDefault("OfferingType")
  valid_21627343 = validateParameter(valid_21627343, JString, required = false,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "OfferingType", valid_21627343
  var valid_21627344 = query.getOrDefault("MultiAZ")
  valid_21627344 = validateParameter(valid_21627344, JBool, required = false,
                                   default = nil)
  if valid_21627344 != nil:
    section.add "MultiAZ", valid_21627344
  var valid_21627345 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627345 = validateParameter(valid_21627345, JString, required = false,
                                   default = nil)
  if valid_21627345 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627345
  var valid_21627346 = query.getOrDefault("DBInstanceClass")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "DBInstanceClass", valid_21627346
  var valid_21627347 = query.getOrDefault("Action")
  valid_21627347 = validateParameter(valid_21627347, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_21627347 != nil:
    section.add "Action", valid_21627347
  var valid_21627348 = query.getOrDefault("Marker")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "Marker", valid_21627348
  var valid_21627349 = query.getOrDefault("Duration")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "Duration", valid_21627349
  var valid_21627350 = query.getOrDefault("Version")
  valid_21627350 = validateParameter(valid_21627350, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627350 != nil:
    section.add "Version", valid_21627350
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
  var valid_21627351 = header.getOrDefault("X-Amz-Date")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-Date", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Security-Token", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-Algorithm", valid_21627354
  var valid_21627355 = header.getOrDefault("X-Amz-Signature")
  valid_21627355 = validateParameter(valid_21627355, JString, required = false,
                                   default = nil)
  if valid_21627355 != nil:
    section.add "X-Amz-Signature", valid_21627355
  var valid_21627356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627356 = validateParameter(valid_21627356, JString, required = false,
                                   default = nil)
  if valid_21627356 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627356
  var valid_21627357 = header.getOrDefault("X-Amz-Credential")
  valid_21627357 = validateParameter(valid_21627357, JString, required = false,
                                   default = nil)
  if valid_21627357 != nil:
    section.add "X-Amz-Credential", valid_21627357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627358: Call_GetDescribeReservedDBInstancesOfferings_21627338;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627358.validator(path, query, header, formData, body, _)
  let scheme = call_21627358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627358.makeUrl(scheme.get, call_21627358.host, call_21627358.base,
                               call_21627358.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627358, uri, valid, _)

proc call*(call_21627359: Call_GetDescribeReservedDBInstancesOfferings_21627338;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   MultiAZ: bool
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_21627360 = newJObject()
  add(query_21627360, "ProductDescription", newJString(ProductDescription))
  add(query_21627360, "MaxRecords", newJInt(MaxRecords))
  add(query_21627360, "OfferingType", newJString(OfferingType))
  add(query_21627360, "MultiAZ", newJBool(MultiAZ))
  add(query_21627360, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627360, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627360, "Action", newJString(Action))
  add(query_21627360, "Marker", newJString(Marker))
  add(query_21627360, "Duration", newJString(Duration))
  add(query_21627360, "Version", newJString(Version))
  result = call_21627359.call(nil, query_21627360, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_21627338(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_21627339,
    base: "/", makeUrl: url_GetDescribeReservedDBInstancesOfferings_21627340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_21627401 = ref object of OpenApiRestCall_21625418
proc url_PostListTagsForResource_21627403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_21627402(path: JsonNode; query: JsonNode;
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
  var valid_21627404 = query.getOrDefault("Action")
  valid_21627404 = validateParameter(valid_21627404, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627404 != nil:
    section.add "Action", valid_21627404
  var valid_21627405 = query.getOrDefault("Version")
  valid_21627405 = validateParameter(valid_21627405, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627405 != nil:
    section.add "Version", valid_21627405
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
  var valid_21627406 = header.getOrDefault("X-Amz-Date")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "X-Amz-Date", valid_21627406
  var valid_21627407 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627407 = validateParameter(valid_21627407, JString, required = false,
                                   default = nil)
  if valid_21627407 != nil:
    section.add "X-Amz-Security-Token", valid_21627407
  var valid_21627408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627408 = validateParameter(valid_21627408, JString, required = false,
                                   default = nil)
  if valid_21627408 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627408
  var valid_21627409 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627409 = validateParameter(valid_21627409, JString, required = false,
                                   default = nil)
  if valid_21627409 != nil:
    section.add "X-Amz-Algorithm", valid_21627409
  var valid_21627410 = header.getOrDefault("X-Amz-Signature")
  valid_21627410 = validateParameter(valid_21627410, JString, required = false,
                                   default = nil)
  if valid_21627410 != nil:
    section.add "X-Amz-Signature", valid_21627410
  var valid_21627411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627411 = validateParameter(valid_21627411, JString, required = false,
                                   default = nil)
  if valid_21627411 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627411
  var valid_21627412 = header.getOrDefault("X-Amz-Credential")
  valid_21627412 = validateParameter(valid_21627412, JString, required = false,
                                   default = nil)
  if valid_21627412 != nil:
    section.add "X-Amz-Credential", valid_21627412
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_21627413 = formData.getOrDefault("ResourceName")
  valid_21627413 = validateParameter(valid_21627413, JString, required = true,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "ResourceName", valid_21627413
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627414: Call_PostListTagsForResource_21627401;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627414.validator(path, query, header, formData, body, _)
  let scheme = call_21627414.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627414.makeUrl(scheme.get, call_21627414.host, call_21627414.base,
                               call_21627414.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627414, uri, valid, _)

proc call*(call_21627415: Call_PostListTagsForResource_21627401;
          ResourceName: string; Action: string = "ListTagsForResource";
          Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_21627416 = newJObject()
  var formData_21627417 = newJObject()
  add(query_21627416, "Action", newJString(Action))
  add(formData_21627417, "ResourceName", newJString(ResourceName))
  add(query_21627416, "Version", newJString(Version))
  result = call_21627415.call(nil, query_21627416, nil, formData_21627417, nil)

var postListTagsForResource* = Call_PostListTagsForResource_21627401(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_21627402, base: "/",
    makeUrl: url_PostListTagsForResource_21627403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_21627385 = ref object of OpenApiRestCall_21625418
proc url_GetListTagsForResource_21627387(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_21627386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_21627388 = query.getOrDefault("ResourceName")
  valid_21627388 = validateParameter(valid_21627388, JString, required = true,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "ResourceName", valid_21627388
  var valid_21627389 = query.getOrDefault("Action")
  valid_21627389 = validateParameter(valid_21627389, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627389 != nil:
    section.add "Action", valid_21627389
  var valid_21627390 = query.getOrDefault("Version")
  valid_21627390 = validateParameter(valid_21627390, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627390 != nil:
    section.add "Version", valid_21627390
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
  var valid_21627391 = header.getOrDefault("X-Amz-Date")
  valid_21627391 = validateParameter(valid_21627391, JString, required = false,
                                   default = nil)
  if valid_21627391 != nil:
    section.add "X-Amz-Date", valid_21627391
  var valid_21627392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627392 = validateParameter(valid_21627392, JString, required = false,
                                   default = nil)
  if valid_21627392 != nil:
    section.add "X-Amz-Security-Token", valid_21627392
  var valid_21627393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627393 = validateParameter(valid_21627393, JString, required = false,
                                   default = nil)
  if valid_21627393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627393
  var valid_21627394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627394 = validateParameter(valid_21627394, JString, required = false,
                                   default = nil)
  if valid_21627394 != nil:
    section.add "X-Amz-Algorithm", valid_21627394
  var valid_21627395 = header.getOrDefault("X-Amz-Signature")
  valid_21627395 = validateParameter(valid_21627395, JString, required = false,
                                   default = nil)
  if valid_21627395 != nil:
    section.add "X-Amz-Signature", valid_21627395
  var valid_21627396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627396 = validateParameter(valid_21627396, JString, required = false,
                                   default = nil)
  if valid_21627396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627396
  var valid_21627397 = header.getOrDefault("X-Amz-Credential")
  valid_21627397 = validateParameter(valid_21627397, JString, required = false,
                                   default = nil)
  if valid_21627397 != nil:
    section.add "X-Amz-Credential", valid_21627397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627398: Call_GetListTagsForResource_21627385;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627398.validator(path, query, header, formData, body, _)
  let scheme = call_21627398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627398.makeUrl(scheme.get, call_21627398.host, call_21627398.base,
                               call_21627398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627398, uri, valid, _)

proc call*(call_21627399: Call_GetListTagsForResource_21627385;
          ResourceName: string; Action: string = "ListTagsForResource";
          Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627400 = newJObject()
  add(query_21627400, "ResourceName", newJString(ResourceName))
  add(query_21627400, "Action", newJString(Action))
  add(query_21627400, "Version", newJString(Version))
  result = call_21627399.call(nil, query_21627400, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_21627385(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_21627386, base: "/",
    makeUrl: url_GetListTagsForResource_21627387,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_21627451 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBInstance_21627453(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_21627452(path: JsonNode; query: JsonNode;
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
  var valid_21627454 = query.getOrDefault("Action")
  valid_21627454 = validateParameter(valid_21627454, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627454 != nil:
    section.add "Action", valid_21627454
  var valid_21627455 = query.getOrDefault("Version")
  valid_21627455 = validateParameter(valid_21627455, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627455 != nil:
    section.add "Version", valid_21627455
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
  var valid_21627456 = header.getOrDefault("X-Amz-Date")
  valid_21627456 = validateParameter(valid_21627456, JString, required = false,
                                   default = nil)
  if valid_21627456 != nil:
    section.add "X-Amz-Date", valid_21627456
  var valid_21627457 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627457 = validateParameter(valid_21627457, JString, required = false,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "X-Amz-Security-Token", valid_21627457
  var valid_21627458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627458 = validateParameter(valid_21627458, JString, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627458
  var valid_21627459 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "X-Amz-Algorithm", valid_21627459
  var valid_21627460 = header.getOrDefault("X-Amz-Signature")
  valid_21627460 = validateParameter(valid_21627460, JString, required = false,
                                   default = nil)
  if valid_21627460 != nil:
    section.add "X-Amz-Signature", valid_21627460
  var valid_21627461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627461
  var valid_21627462 = header.getOrDefault("X-Amz-Credential")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Credential", valid_21627462
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
  var valid_21627463 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627463
  var valid_21627464 = formData.getOrDefault("DBSecurityGroups")
  valid_21627464 = validateParameter(valid_21627464, JArray, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "DBSecurityGroups", valid_21627464
  var valid_21627465 = formData.getOrDefault("ApplyImmediately")
  valid_21627465 = validateParameter(valid_21627465, JBool, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "ApplyImmediately", valid_21627465
  var valid_21627466 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21627466 = validateParameter(valid_21627466, JArray, required = false,
                                   default = nil)
  if valid_21627466 != nil:
    section.add "VpcSecurityGroupIds", valid_21627466
  var valid_21627467 = formData.getOrDefault("Iops")
  valid_21627467 = validateParameter(valid_21627467, JInt, required = false,
                                   default = nil)
  if valid_21627467 != nil:
    section.add "Iops", valid_21627467
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627468 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627468 = validateParameter(valid_21627468, JString, required = true,
                                   default = nil)
  if valid_21627468 != nil:
    section.add "DBInstanceIdentifier", valid_21627468
  var valid_21627469 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21627469 = validateParameter(valid_21627469, JInt, required = false,
                                   default = nil)
  if valid_21627469 != nil:
    section.add "BackupRetentionPeriod", valid_21627469
  var valid_21627470 = formData.getOrDefault("DBParameterGroupName")
  valid_21627470 = validateParameter(valid_21627470, JString, required = false,
                                   default = nil)
  if valid_21627470 != nil:
    section.add "DBParameterGroupName", valid_21627470
  var valid_21627471 = formData.getOrDefault("OptionGroupName")
  valid_21627471 = validateParameter(valid_21627471, JString, required = false,
                                   default = nil)
  if valid_21627471 != nil:
    section.add "OptionGroupName", valid_21627471
  var valid_21627472 = formData.getOrDefault("MasterUserPassword")
  valid_21627472 = validateParameter(valid_21627472, JString, required = false,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "MasterUserPassword", valid_21627472
  var valid_21627473 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627473
  var valid_21627474 = formData.getOrDefault("MultiAZ")
  valid_21627474 = validateParameter(valid_21627474, JBool, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "MultiAZ", valid_21627474
  var valid_21627475 = formData.getOrDefault("AllocatedStorage")
  valid_21627475 = validateParameter(valid_21627475, JInt, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "AllocatedStorage", valid_21627475
  var valid_21627476 = formData.getOrDefault("DBInstanceClass")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "DBInstanceClass", valid_21627476
  var valid_21627477 = formData.getOrDefault("PreferredBackupWindow")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "PreferredBackupWindow", valid_21627477
  var valid_21627478 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627478 = validateParameter(valid_21627478, JBool, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627478
  var valid_21627479 = formData.getOrDefault("EngineVersion")
  valid_21627479 = validateParameter(valid_21627479, JString, required = false,
                                   default = nil)
  if valid_21627479 != nil:
    section.add "EngineVersion", valid_21627479
  var valid_21627480 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_21627480 = validateParameter(valid_21627480, JBool, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "AllowMajorVersionUpgrade", valid_21627480
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627481: Call_PostModifyDBInstance_21627451; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627481.validator(path, query, header, formData, body, _)
  let scheme = call_21627481.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627481.makeUrl(scheme.get, call_21627481.host, call_21627481.base,
                               call_21627481.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627481, uri, valid, _)

proc call*(call_21627482: Call_PostModifyDBInstance_21627451;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-01-10"; AllowMajorVersionUpgrade: bool = false): Recallable =
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
  var query_21627483 = newJObject()
  var formData_21627484 = newJObject()
  add(formData_21627484, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_21627484.add "DBSecurityGroups", DBSecurityGroups
  add(formData_21627484, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_21627484.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21627484, "Iops", newJInt(Iops))
  add(formData_21627484, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627484, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_21627484, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21627484, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627484, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21627484, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_21627484, "MultiAZ", newJBool(MultiAZ))
  add(query_21627483, "Action", newJString(Action))
  add(formData_21627484, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_21627484, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627484, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21627484, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_21627484, "EngineVersion", newJString(EngineVersion))
  add(query_21627483, "Version", newJString(Version))
  add(formData_21627484, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_21627482.call(nil, query_21627483, nil, formData_21627484, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_21627451(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_21627452, base: "/",
    makeUrl: url_PostModifyDBInstance_21627453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_21627418 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBInstance_21627420(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_21627419(path: JsonNode; query: JsonNode;
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
  var valid_21627421 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21627421 = validateParameter(valid_21627421, JString, required = false,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627421
  var valid_21627422 = query.getOrDefault("AllocatedStorage")
  valid_21627422 = validateParameter(valid_21627422, JInt, required = false,
                                   default = nil)
  if valid_21627422 != nil:
    section.add "AllocatedStorage", valid_21627422
  var valid_21627423 = query.getOrDefault("OptionGroupName")
  valid_21627423 = validateParameter(valid_21627423, JString, required = false,
                                   default = nil)
  if valid_21627423 != nil:
    section.add "OptionGroupName", valid_21627423
  var valid_21627424 = query.getOrDefault("DBSecurityGroups")
  valid_21627424 = validateParameter(valid_21627424, JArray, required = false,
                                   default = nil)
  if valid_21627424 != nil:
    section.add "DBSecurityGroups", valid_21627424
  var valid_21627425 = query.getOrDefault("MasterUserPassword")
  valid_21627425 = validateParameter(valid_21627425, JString, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "MasterUserPassword", valid_21627425
  var valid_21627426 = query.getOrDefault("Iops")
  valid_21627426 = validateParameter(valid_21627426, JInt, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "Iops", valid_21627426
  var valid_21627427 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21627427 = validateParameter(valid_21627427, JArray, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "VpcSecurityGroupIds", valid_21627427
  var valid_21627428 = query.getOrDefault("MultiAZ")
  valid_21627428 = validateParameter(valid_21627428, JBool, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "MultiAZ", valid_21627428
  var valid_21627429 = query.getOrDefault("BackupRetentionPeriod")
  valid_21627429 = validateParameter(valid_21627429, JInt, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "BackupRetentionPeriod", valid_21627429
  var valid_21627430 = query.getOrDefault("DBParameterGroupName")
  valid_21627430 = validateParameter(valid_21627430, JString, required = false,
                                   default = nil)
  if valid_21627430 != nil:
    section.add "DBParameterGroupName", valid_21627430
  var valid_21627431 = query.getOrDefault("DBInstanceClass")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "DBInstanceClass", valid_21627431
  var valid_21627432 = query.getOrDefault("Action")
  valid_21627432 = validateParameter(valid_21627432, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627432 != nil:
    section.add "Action", valid_21627432
  var valid_21627433 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_21627433 = validateParameter(valid_21627433, JBool, required = false,
                                   default = nil)
  if valid_21627433 != nil:
    section.add "AllowMajorVersionUpgrade", valid_21627433
  var valid_21627434 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_21627434 = validateParameter(valid_21627434, JString, required = false,
                                   default = nil)
  if valid_21627434 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627434
  var valid_21627435 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627435 = validateParameter(valid_21627435, JBool, required = false,
                                   default = nil)
  if valid_21627435 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627435
  var valid_21627436 = query.getOrDefault("EngineVersion")
  valid_21627436 = validateParameter(valid_21627436, JString, required = false,
                                   default = nil)
  if valid_21627436 != nil:
    section.add "EngineVersion", valid_21627436
  var valid_21627437 = query.getOrDefault("PreferredBackupWindow")
  valid_21627437 = validateParameter(valid_21627437, JString, required = false,
                                   default = nil)
  if valid_21627437 != nil:
    section.add "PreferredBackupWindow", valid_21627437
  var valid_21627438 = query.getOrDefault("Version")
  valid_21627438 = validateParameter(valid_21627438, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627438 != nil:
    section.add "Version", valid_21627438
  var valid_21627439 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627439 = validateParameter(valid_21627439, JString, required = true,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "DBInstanceIdentifier", valid_21627439
  var valid_21627440 = query.getOrDefault("ApplyImmediately")
  valid_21627440 = validateParameter(valid_21627440, JBool, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "ApplyImmediately", valid_21627440
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
  var valid_21627441 = header.getOrDefault("X-Amz-Date")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "X-Amz-Date", valid_21627441
  var valid_21627442 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "X-Amz-Security-Token", valid_21627442
  var valid_21627443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627443 = validateParameter(valid_21627443, JString, required = false,
                                   default = nil)
  if valid_21627443 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627443
  var valid_21627444 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "X-Amz-Algorithm", valid_21627444
  var valid_21627445 = header.getOrDefault("X-Amz-Signature")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "X-Amz-Signature", valid_21627445
  var valid_21627446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627446 = validateParameter(valid_21627446, JString, required = false,
                                   default = nil)
  if valid_21627446 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627446
  var valid_21627447 = header.getOrDefault("X-Amz-Credential")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-Credential", valid_21627447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627448: Call_GetModifyDBInstance_21627418; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627448.validator(path, query, header, formData, body, _)
  let scheme = call_21627448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627448.makeUrl(scheme.get, call_21627448.host, call_21627448.base,
                               call_21627448.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627448, uri, valid, _)

proc call*(call_21627449: Call_GetModifyDBInstance_21627418;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; MasterUserPassword: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2013-01-10";
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
  var query_21627450 = newJObject()
  add(query_21627450, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21627450, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_21627450, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_21627450.add "DBSecurityGroups", DBSecurityGroups
  add(query_21627450, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_21627450, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_21627450.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_21627450, "MultiAZ", newJBool(MultiAZ))
  add(query_21627450, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627450, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21627450, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627450, "Action", newJString(Action))
  add(query_21627450, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(query_21627450, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_21627450, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21627450, "EngineVersion", newJString(EngineVersion))
  add(query_21627450, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21627450, "Version", newJString(Version))
  add(query_21627450, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627450, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_21627449.call(nil, query_21627450, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_21627418(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_21627419, base: "/",
    makeUrl: url_GetModifyDBInstance_21627420,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_21627502 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBParameterGroup_21627504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_21627503(path: JsonNode; query: JsonNode;
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
  var valid_21627505 = query.getOrDefault("Action")
  valid_21627505 = validateParameter(valid_21627505, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_21627505 != nil:
    section.add "Action", valid_21627505
  var valid_21627506 = query.getOrDefault("Version")
  valid_21627506 = validateParameter(valid_21627506, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627506 != nil:
    section.add "Version", valid_21627506
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
  var valid_21627507 = header.getOrDefault("X-Amz-Date")
  valid_21627507 = validateParameter(valid_21627507, JString, required = false,
                                   default = nil)
  if valid_21627507 != nil:
    section.add "X-Amz-Date", valid_21627507
  var valid_21627508 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627508 = validateParameter(valid_21627508, JString, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "X-Amz-Security-Token", valid_21627508
  var valid_21627509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627509
  var valid_21627510 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "X-Amz-Algorithm", valid_21627510
  var valid_21627511 = header.getOrDefault("X-Amz-Signature")
  valid_21627511 = validateParameter(valid_21627511, JString, required = false,
                                   default = nil)
  if valid_21627511 != nil:
    section.add "X-Amz-Signature", valid_21627511
  var valid_21627512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627512 = validateParameter(valid_21627512, JString, required = false,
                                   default = nil)
  if valid_21627512 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627512
  var valid_21627513 = header.getOrDefault("X-Amz-Credential")
  valid_21627513 = validateParameter(valid_21627513, JString, required = false,
                                   default = nil)
  if valid_21627513 != nil:
    section.add "X-Amz-Credential", valid_21627513
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627514 = formData.getOrDefault("DBParameterGroupName")
  valid_21627514 = validateParameter(valid_21627514, JString, required = true,
                                   default = nil)
  if valid_21627514 != nil:
    section.add "DBParameterGroupName", valid_21627514
  var valid_21627515 = formData.getOrDefault("Parameters")
  valid_21627515 = validateParameter(valid_21627515, JArray, required = true,
                                   default = nil)
  if valid_21627515 != nil:
    section.add "Parameters", valid_21627515
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627516: Call_PostModifyDBParameterGroup_21627502;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627516.validator(path, query, header, formData, body, _)
  let scheme = call_21627516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627516.makeUrl(scheme.get, call_21627516.host, call_21627516.base,
                               call_21627516.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627516, uri, valid, _)

proc call*(call_21627517: Call_PostModifyDBParameterGroup_21627502;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627518 = newJObject()
  var formData_21627519 = newJObject()
  add(formData_21627519, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_21627519.add "Parameters", Parameters
  add(query_21627518, "Action", newJString(Action))
  add(query_21627518, "Version", newJString(Version))
  result = call_21627517.call(nil, query_21627518, nil, formData_21627519, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_21627502(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_21627503, base: "/",
    makeUrl: url_PostModifyDBParameterGroup_21627504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_21627485 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBParameterGroup_21627487(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_21627486(path: JsonNode; query: JsonNode;
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
  var valid_21627488 = query.getOrDefault("DBParameterGroupName")
  valid_21627488 = validateParameter(valid_21627488, JString, required = true,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "DBParameterGroupName", valid_21627488
  var valid_21627489 = query.getOrDefault("Parameters")
  valid_21627489 = validateParameter(valid_21627489, JArray, required = true,
                                   default = nil)
  if valid_21627489 != nil:
    section.add "Parameters", valid_21627489
  var valid_21627490 = query.getOrDefault("Action")
  valid_21627490 = validateParameter(valid_21627490, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_21627490 != nil:
    section.add "Action", valid_21627490
  var valid_21627491 = query.getOrDefault("Version")
  valid_21627491 = validateParameter(valid_21627491, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627491 != nil:
    section.add "Version", valid_21627491
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
  var valid_21627492 = header.getOrDefault("X-Amz-Date")
  valid_21627492 = validateParameter(valid_21627492, JString, required = false,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "X-Amz-Date", valid_21627492
  var valid_21627493 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "X-Amz-Security-Token", valid_21627493
  var valid_21627494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627494 = validateParameter(valid_21627494, JString, required = false,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627494
  var valid_21627495 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "X-Amz-Algorithm", valid_21627495
  var valid_21627496 = header.getOrDefault("X-Amz-Signature")
  valid_21627496 = validateParameter(valid_21627496, JString, required = false,
                                   default = nil)
  if valid_21627496 != nil:
    section.add "X-Amz-Signature", valid_21627496
  var valid_21627497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627497 = validateParameter(valid_21627497, JString, required = false,
                                   default = nil)
  if valid_21627497 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627497
  var valid_21627498 = header.getOrDefault("X-Amz-Credential")
  valid_21627498 = validateParameter(valid_21627498, JString, required = false,
                                   default = nil)
  if valid_21627498 != nil:
    section.add "X-Amz-Credential", valid_21627498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627499: Call_GetModifyDBParameterGroup_21627485;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627499.validator(path, query, header, formData, body, _)
  let scheme = call_21627499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627499.makeUrl(scheme.get, call_21627499.host, call_21627499.base,
                               call_21627499.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627499, uri, valid, _)

proc call*(call_21627500: Call_GetModifyDBParameterGroup_21627485;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627501 = newJObject()
  add(query_21627501, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_21627501.add "Parameters", Parameters
  add(query_21627501, "Action", newJString(Action))
  add(query_21627501, "Version", newJString(Version))
  result = call_21627500.call(nil, query_21627501, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_21627485(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_21627486, base: "/",
    makeUrl: url_GetModifyDBParameterGroup_21627487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_21627538 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBSubnetGroup_21627540(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_21627539(path: JsonNode; query: JsonNode;
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
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627541 != nil:
    section.add "Action", valid_21627541
  var valid_21627542 = query.getOrDefault("Version")
  valid_21627542 = validateParameter(valid_21627542, JString, required = true,
                                   default = newJString("2013-01-10"))
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
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21627550 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627550 = validateParameter(valid_21627550, JString, required = true,
                                   default = nil)
  if valid_21627550 != nil:
    section.add "DBSubnetGroupName", valid_21627550
  var valid_21627551 = formData.getOrDefault("SubnetIds")
  valid_21627551 = validateParameter(valid_21627551, JArray, required = true,
                                   default = nil)
  if valid_21627551 != nil:
    section.add "SubnetIds", valid_21627551
  var valid_21627552 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21627552 = validateParameter(valid_21627552, JString, required = false,
                                   default = nil)
  if valid_21627552 != nil:
    section.add "DBSubnetGroupDescription", valid_21627552
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627553: Call_PostModifyDBSubnetGroup_21627538;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627553.validator(path, query, header, formData, body, _)
  let scheme = call_21627553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627553.makeUrl(scheme.get, call_21627553.host, call_21627553.base,
                               call_21627553.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627553, uri, valid, _)

proc call*(call_21627554: Call_PostModifyDBSubnetGroup_21627538;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_21627555 = newJObject()
  var formData_21627556 = newJObject()
  add(formData_21627556, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21627556.add "SubnetIds", SubnetIds
  add(query_21627555, "Action", newJString(Action))
  add(formData_21627556, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627555, "Version", newJString(Version))
  result = call_21627554.call(nil, query_21627555, nil, formData_21627556, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_21627538(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_21627539, base: "/",
    makeUrl: url_PostModifyDBSubnetGroup_21627540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_21627520 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBSubnetGroup_21627522(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_21627521(path: JsonNode; query: JsonNode;
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
  var valid_21627523 = query.getOrDefault("Action")
  valid_21627523 = validateParameter(valid_21627523, JString, required = true,
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627523 != nil:
    section.add "Action", valid_21627523
  var valid_21627524 = query.getOrDefault("DBSubnetGroupName")
  valid_21627524 = validateParameter(valid_21627524, JString, required = true,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "DBSubnetGroupName", valid_21627524
  var valid_21627525 = query.getOrDefault("SubnetIds")
  valid_21627525 = validateParameter(valid_21627525, JArray, required = true,
                                   default = nil)
  if valid_21627525 != nil:
    section.add "SubnetIds", valid_21627525
  var valid_21627526 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21627526 = validateParameter(valid_21627526, JString, required = false,
                                   default = nil)
  if valid_21627526 != nil:
    section.add "DBSubnetGroupDescription", valid_21627526
  var valid_21627527 = query.getOrDefault("Version")
  valid_21627527 = validateParameter(valid_21627527, JString, required = true,
                                   default = newJString("2013-01-10"))
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

proc call*(call_21627535: Call_GetModifyDBSubnetGroup_21627520;
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

proc call*(call_21627536: Call_GetModifyDBSubnetGroup_21627520;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_21627537 = newJObject()
  add(query_21627537, "Action", newJString(Action))
  add(query_21627537, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21627537.add "SubnetIds", SubnetIds
  add(query_21627537, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627537, "Version", newJString(Version))
  result = call_21627536.call(nil, query_21627537, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_21627520(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_21627521, base: "/",
    makeUrl: url_GetModifyDBSubnetGroup_21627522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_21627577 = ref object of OpenApiRestCall_21625418
proc url_PostModifyEventSubscription_21627579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_21627578(path: JsonNode; query: JsonNode;
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
  var valid_21627580 = query.getOrDefault("Action")
  valid_21627580 = validateParameter(valid_21627580, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_21627580 != nil:
    section.add "Action", valid_21627580
  var valid_21627581 = query.getOrDefault("Version")
  valid_21627581 = validateParameter(valid_21627581, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627581 != nil:
    section.add "Version", valid_21627581
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
  var valid_21627582 = header.getOrDefault("X-Amz-Date")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-Date", valid_21627582
  var valid_21627583 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627583 = validateParameter(valid_21627583, JString, required = false,
                                   default = nil)
  if valid_21627583 != nil:
    section.add "X-Amz-Security-Token", valid_21627583
  var valid_21627584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627584 = validateParameter(valid_21627584, JString, required = false,
                                   default = nil)
  if valid_21627584 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627584
  var valid_21627585 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627585 = validateParameter(valid_21627585, JString, required = false,
                                   default = nil)
  if valid_21627585 != nil:
    section.add "X-Amz-Algorithm", valid_21627585
  var valid_21627586 = header.getOrDefault("X-Amz-Signature")
  valid_21627586 = validateParameter(valid_21627586, JString, required = false,
                                   default = nil)
  if valid_21627586 != nil:
    section.add "X-Amz-Signature", valid_21627586
  var valid_21627587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627587 = validateParameter(valid_21627587, JString, required = false,
                                   default = nil)
  if valid_21627587 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627587
  var valid_21627588 = header.getOrDefault("X-Amz-Credential")
  valid_21627588 = validateParameter(valid_21627588, JString, required = false,
                                   default = nil)
  if valid_21627588 != nil:
    section.add "X-Amz-Credential", valid_21627588
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_21627589 = formData.getOrDefault("Enabled")
  valid_21627589 = validateParameter(valid_21627589, JBool, required = false,
                                   default = nil)
  if valid_21627589 != nil:
    section.add "Enabled", valid_21627589
  var valid_21627590 = formData.getOrDefault("EventCategories")
  valid_21627590 = validateParameter(valid_21627590, JArray, required = false,
                                   default = nil)
  if valid_21627590 != nil:
    section.add "EventCategories", valid_21627590
  var valid_21627591 = formData.getOrDefault("SnsTopicArn")
  valid_21627591 = validateParameter(valid_21627591, JString, required = false,
                                   default = nil)
  if valid_21627591 != nil:
    section.add "SnsTopicArn", valid_21627591
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_21627592 = formData.getOrDefault("SubscriptionName")
  valid_21627592 = validateParameter(valid_21627592, JString, required = true,
                                   default = nil)
  if valid_21627592 != nil:
    section.add "SubscriptionName", valid_21627592
  var valid_21627593 = formData.getOrDefault("SourceType")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "SourceType", valid_21627593
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627594: Call_PostModifyEventSubscription_21627577;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627594.validator(path, query, header, formData, body, _)
  let scheme = call_21627594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627594.makeUrl(scheme.get, call_21627594.host, call_21627594.base,
                               call_21627594.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627594, uri, valid, _)

proc call*(call_21627595: Call_PostModifyEventSubscription_21627577;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627596 = newJObject()
  var formData_21627597 = newJObject()
  add(formData_21627597, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_21627597.add "EventCategories", EventCategories
  add(formData_21627597, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_21627597, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627596, "Action", newJString(Action))
  add(query_21627596, "Version", newJString(Version))
  add(formData_21627597, "SourceType", newJString(SourceType))
  result = call_21627595.call(nil, query_21627596, nil, formData_21627597, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_21627577(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_21627578, base: "/",
    makeUrl: url_PostModifyEventSubscription_21627579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_21627557 = ref object of OpenApiRestCall_21625418
proc url_GetModifyEventSubscription_21627559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_21627558(path: JsonNode; query: JsonNode;
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
  var valid_21627560 = query.getOrDefault("SourceType")
  valid_21627560 = validateParameter(valid_21627560, JString, required = false,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "SourceType", valid_21627560
  var valid_21627561 = query.getOrDefault("Enabled")
  valid_21627561 = validateParameter(valid_21627561, JBool, required = false,
                                   default = nil)
  if valid_21627561 != nil:
    section.add "Enabled", valid_21627561
  var valid_21627562 = query.getOrDefault("Action")
  valid_21627562 = validateParameter(valid_21627562, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_21627562 != nil:
    section.add "Action", valid_21627562
  var valid_21627563 = query.getOrDefault("SnsTopicArn")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "SnsTopicArn", valid_21627563
  var valid_21627564 = query.getOrDefault("EventCategories")
  valid_21627564 = validateParameter(valid_21627564, JArray, required = false,
                                   default = nil)
  if valid_21627564 != nil:
    section.add "EventCategories", valid_21627564
  var valid_21627565 = query.getOrDefault("SubscriptionName")
  valid_21627565 = validateParameter(valid_21627565, JString, required = true,
                                   default = nil)
  if valid_21627565 != nil:
    section.add "SubscriptionName", valid_21627565
  var valid_21627566 = query.getOrDefault("Version")
  valid_21627566 = validateParameter(valid_21627566, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627566 != nil:
    section.add "Version", valid_21627566
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
  var valid_21627567 = header.getOrDefault("X-Amz-Date")
  valid_21627567 = validateParameter(valid_21627567, JString, required = false,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "X-Amz-Date", valid_21627567
  var valid_21627568 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627568 = validateParameter(valid_21627568, JString, required = false,
                                   default = nil)
  if valid_21627568 != nil:
    section.add "X-Amz-Security-Token", valid_21627568
  var valid_21627569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627569 = validateParameter(valid_21627569, JString, required = false,
                                   default = nil)
  if valid_21627569 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627569
  var valid_21627570 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627570 = validateParameter(valid_21627570, JString, required = false,
                                   default = nil)
  if valid_21627570 != nil:
    section.add "X-Amz-Algorithm", valid_21627570
  var valid_21627571 = header.getOrDefault("X-Amz-Signature")
  valid_21627571 = validateParameter(valid_21627571, JString, required = false,
                                   default = nil)
  if valid_21627571 != nil:
    section.add "X-Amz-Signature", valid_21627571
  var valid_21627572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627572 = validateParameter(valid_21627572, JString, required = false,
                                   default = nil)
  if valid_21627572 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627572
  var valid_21627573 = header.getOrDefault("X-Amz-Credential")
  valid_21627573 = validateParameter(valid_21627573, JString, required = false,
                                   default = nil)
  if valid_21627573 != nil:
    section.add "X-Amz-Credential", valid_21627573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627574: Call_GetModifyEventSubscription_21627557;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627574.validator(path, query, header, formData, body, _)
  let scheme = call_21627574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627574.makeUrl(scheme.get, call_21627574.host, call_21627574.base,
                               call_21627574.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627574, uri, valid, _)

proc call*(call_21627575: Call_GetModifyEventSubscription_21627557;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2013-01-10"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21627576 = newJObject()
  add(query_21627576, "SourceType", newJString(SourceType))
  add(query_21627576, "Enabled", newJBool(Enabled))
  add(query_21627576, "Action", newJString(Action))
  add(query_21627576, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_21627576.add "EventCategories", EventCategories
  add(query_21627576, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627576, "Version", newJString(Version))
  result = call_21627575.call(nil, query_21627576, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_21627557(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_21627558, base: "/",
    makeUrl: url_GetModifyEventSubscription_21627559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_21627617 = ref object of OpenApiRestCall_21625418
proc url_PostModifyOptionGroup_21627619(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_21627618(path: JsonNode; query: JsonNode;
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
  var valid_21627620 = query.getOrDefault("Action")
  valid_21627620 = validateParameter(valid_21627620, JString, required = true,
                                   default = newJString("ModifyOptionGroup"))
  if valid_21627620 != nil:
    section.add "Action", valid_21627620
  var valid_21627621 = query.getOrDefault("Version")
  valid_21627621 = validateParameter(valid_21627621, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627621 != nil:
    section.add "Version", valid_21627621
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
  var valid_21627622 = header.getOrDefault("X-Amz-Date")
  valid_21627622 = validateParameter(valid_21627622, JString, required = false,
                                   default = nil)
  if valid_21627622 != nil:
    section.add "X-Amz-Date", valid_21627622
  var valid_21627623 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627623 = validateParameter(valid_21627623, JString, required = false,
                                   default = nil)
  if valid_21627623 != nil:
    section.add "X-Amz-Security-Token", valid_21627623
  var valid_21627624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627624 = validateParameter(valid_21627624, JString, required = false,
                                   default = nil)
  if valid_21627624 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627624
  var valid_21627625 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627625 = validateParameter(valid_21627625, JString, required = false,
                                   default = nil)
  if valid_21627625 != nil:
    section.add "X-Amz-Algorithm", valid_21627625
  var valid_21627626 = header.getOrDefault("X-Amz-Signature")
  valid_21627626 = validateParameter(valid_21627626, JString, required = false,
                                   default = nil)
  if valid_21627626 != nil:
    section.add "X-Amz-Signature", valid_21627626
  var valid_21627627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627627 = validateParameter(valid_21627627, JString, required = false,
                                   default = nil)
  if valid_21627627 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627627
  var valid_21627628 = header.getOrDefault("X-Amz-Credential")
  valid_21627628 = validateParameter(valid_21627628, JString, required = false,
                                   default = nil)
  if valid_21627628 != nil:
    section.add "X-Amz-Credential", valid_21627628
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_21627629 = formData.getOrDefault("OptionsToRemove")
  valid_21627629 = validateParameter(valid_21627629, JArray, required = false,
                                   default = nil)
  if valid_21627629 != nil:
    section.add "OptionsToRemove", valid_21627629
  var valid_21627630 = formData.getOrDefault("ApplyImmediately")
  valid_21627630 = validateParameter(valid_21627630, JBool, required = false,
                                   default = nil)
  if valid_21627630 != nil:
    section.add "ApplyImmediately", valid_21627630
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_21627631 = formData.getOrDefault("OptionGroupName")
  valid_21627631 = validateParameter(valid_21627631, JString, required = true,
                                   default = nil)
  if valid_21627631 != nil:
    section.add "OptionGroupName", valid_21627631
  var valid_21627632 = formData.getOrDefault("OptionsToInclude")
  valid_21627632 = validateParameter(valid_21627632, JArray, required = false,
                                   default = nil)
  if valid_21627632 != nil:
    section.add "OptionsToInclude", valid_21627632
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627633: Call_PostModifyOptionGroup_21627617;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627633.validator(path, query, header, formData, body, _)
  let scheme = call_21627633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627633.makeUrl(scheme.get, call_21627633.host, call_21627633.base,
                               call_21627633.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627633, uri, valid, _)

proc call*(call_21627634: Call_PostModifyOptionGroup_21627617;
          OptionGroupName: string; OptionsToRemove: JsonNode = nil;
          ApplyImmediately: bool = false; OptionsToInclude: JsonNode = nil;
          Action: string = "ModifyOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627635 = newJObject()
  var formData_21627636 = newJObject()
  if OptionsToRemove != nil:
    formData_21627636.add "OptionsToRemove", OptionsToRemove
  add(formData_21627636, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_21627636, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_21627636.add "OptionsToInclude", OptionsToInclude
  add(query_21627635, "Action", newJString(Action))
  add(query_21627635, "Version", newJString(Version))
  result = call_21627634.call(nil, query_21627635, nil, formData_21627636, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_21627617(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_21627618, base: "/",
    makeUrl: url_PostModifyOptionGroup_21627619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_21627598 = ref object of OpenApiRestCall_21625418
proc url_GetModifyOptionGroup_21627600(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_21627599(path: JsonNode; query: JsonNode;
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
  var valid_21627601 = query.getOrDefault("OptionGroupName")
  valid_21627601 = validateParameter(valid_21627601, JString, required = true,
                                   default = nil)
  if valid_21627601 != nil:
    section.add "OptionGroupName", valid_21627601
  var valid_21627602 = query.getOrDefault("OptionsToRemove")
  valid_21627602 = validateParameter(valid_21627602, JArray, required = false,
                                   default = nil)
  if valid_21627602 != nil:
    section.add "OptionsToRemove", valid_21627602
  var valid_21627603 = query.getOrDefault("Action")
  valid_21627603 = validateParameter(valid_21627603, JString, required = true,
                                   default = newJString("ModifyOptionGroup"))
  if valid_21627603 != nil:
    section.add "Action", valid_21627603
  var valid_21627604 = query.getOrDefault("Version")
  valid_21627604 = validateParameter(valid_21627604, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627604 != nil:
    section.add "Version", valid_21627604
  var valid_21627605 = query.getOrDefault("ApplyImmediately")
  valid_21627605 = validateParameter(valid_21627605, JBool, required = false,
                                   default = nil)
  if valid_21627605 != nil:
    section.add "ApplyImmediately", valid_21627605
  var valid_21627606 = query.getOrDefault("OptionsToInclude")
  valid_21627606 = validateParameter(valid_21627606, JArray, required = false,
                                   default = nil)
  if valid_21627606 != nil:
    section.add "OptionsToInclude", valid_21627606
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
  var valid_21627607 = header.getOrDefault("X-Amz-Date")
  valid_21627607 = validateParameter(valid_21627607, JString, required = false,
                                   default = nil)
  if valid_21627607 != nil:
    section.add "X-Amz-Date", valid_21627607
  var valid_21627608 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "X-Amz-Security-Token", valid_21627608
  var valid_21627609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627609 = validateParameter(valid_21627609, JString, required = false,
                                   default = nil)
  if valid_21627609 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627609
  var valid_21627610 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627610 = validateParameter(valid_21627610, JString, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "X-Amz-Algorithm", valid_21627610
  var valid_21627611 = header.getOrDefault("X-Amz-Signature")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "X-Amz-Signature", valid_21627611
  var valid_21627612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627612 = validateParameter(valid_21627612, JString, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627612
  var valid_21627613 = header.getOrDefault("X-Amz-Credential")
  valid_21627613 = validateParameter(valid_21627613, JString, required = false,
                                   default = nil)
  if valid_21627613 != nil:
    section.add "X-Amz-Credential", valid_21627613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627614: Call_GetModifyOptionGroup_21627598; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627614.validator(path, query, header, formData, body, _)
  let scheme = call_21627614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627614.makeUrl(scheme.get, call_21627614.host, call_21627614.base,
                               call_21627614.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627614, uri, valid, _)

proc call*(call_21627615: Call_GetModifyOptionGroup_21627598;
          OptionGroupName: string; OptionsToRemove: JsonNode = nil;
          Action: string = "ModifyOptionGroup"; Version: string = "2013-01-10";
          ApplyImmediately: bool = false; OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_21627616 = newJObject()
  add(query_21627616, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_21627616.add "OptionsToRemove", OptionsToRemove
  add(query_21627616, "Action", newJString(Action))
  add(query_21627616, "Version", newJString(Version))
  add(query_21627616, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_21627616.add "OptionsToInclude", OptionsToInclude
  result = call_21627615.call(nil, query_21627616, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_21627598(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_21627599, base: "/",
    makeUrl: url_GetModifyOptionGroup_21627600,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_21627655 = ref object of OpenApiRestCall_21625418
proc url_PostPromoteReadReplica_21627657(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_21627656(path: JsonNode; query: JsonNode;
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
  var valid_21627658 = query.getOrDefault("Action")
  valid_21627658 = validateParameter(valid_21627658, JString, required = true,
                                   default = newJString("PromoteReadReplica"))
  if valid_21627658 != nil:
    section.add "Action", valid_21627658
  var valid_21627659 = query.getOrDefault("Version")
  valid_21627659 = validateParameter(valid_21627659, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627659 != nil:
    section.add "Version", valid_21627659
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
  var valid_21627660 = header.getOrDefault("X-Amz-Date")
  valid_21627660 = validateParameter(valid_21627660, JString, required = false,
                                   default = nil)
  if valid_21627660 != nil:
    section.add "X-Amz-Date", valid_21627660
  var valid_21627661 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627661 = validateParameter(valid_21627661, JString, required = false,
                                   default = nil)
  if valid_21627661 != nil:
    section.add "X-Amz-Security-Token", valid_21627661
  var valid_21627662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627662 = validateParameter(valid_21627662, JString, required = false,
                                   default = nil)
  if valid_21627662 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627662
  var valid_21627663 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627663 = validateParameter(valid_21627663, JString, required = false,
                                   default = nil)
  if valid_21627663 != nil:
    section.add "X-Amz-Algorithm", valid_21627663
  var valid_21627664 = header.getOrDefault("X-Amz-Signature")
  valid_21627664 = validateParameter(valid_21627664, JString, required = false,
                                   default = nil)
  if valid_21627664 != nil:
    section.add "X-Amz-Signature", valid_21627664
  var valid_21627665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627665 = validateParameter(valid_21627665, JString, required = false,
                                   default = nil)
  if valid_21627665 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627665
  var valid_21627666 = header.getOrDefault("X-Amz-Credential")
  valid_21627666 = validateParameter(valid_21627666, JString, required = false,
                                   default = nil)
  if valid_21627666 != nil:
    section.add "X-Amz-Credential", valid_21627666
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627667 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627667 = validateParameter(valid_21627667, JString, required = true,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "DBInstanceIdentifier", valid_21627667
  var valid_21627668 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21627668 = validateParameter(valid_21627668, JInt, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "BackupRetentionPeriod", valid_21627668
  var valid_21627669 = formData.getOrDefault("PreferredBackupWindow")
  valid_21627669 = validateParameter(valid_21627669, JString, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "PreferredBackupWindow", valid_21627669
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627670: Call_PostPromoteReadReplica_21627655;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627670.validator(path, query, header, formData, body, _)
  let scheme = call_21627670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627670.makeUrl(scheme.get, call_21627670.host, call_21627670.base,
                               call_21627670.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627670, uri, valid, _)

proc call*(call_21627671: Call_PostPromoteReadReplica_21627655;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_21627672 = newJObject()
  var formData_21627673 = newJObject()
  add(formData_21627673, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627673, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627672, "Action", newJString(Action))
  add(formData_21627673, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_21627672, "Version", newJString(Version))
  result = call_21627671.call(nil, query_21627672, nil, formData_21627673, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_21627655(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_21627656, base: "/",
    makeUrl: url_PostPromoteReadReplica_21627657,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_21627637 = ref object of OpenApiRestCall_21625418
proc url_GetPromoteReadReplica_21627639(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_21627638(path: JsonNode; query: JsonNode;
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
  var valid_21627640 = query.getOrDefault("BackupRetentionPeriod")
  valid_21627640 = validateParameter(valid_21627640, JInt, required = false,
                                   default = nil)
  if valid_21627640 != nil:
    section.add "BackupRetentionPeriod", valid_21627640
  var valid_21627641 = query.getOrDefault("Action")
  valid_21627641 = validateParameter(valid_21627641, JString, required = true,
                                   default = newJString("PromoteReadReplica"))
  if valid_21627641 != nil:
    section.add "Action", valid_21627641
  var valid_21627642 = query.getOrDefault("PreferredBackupWindow")
  valid_21627642 = validateParameter(valid_21627642, JString, required = false,
                                   default = nil)
  if valid_21627642 != nil:
    section.add "PreferredBackupWindow", valid_21627642
  var valid_21627643 = query.getOrDefault("Version")
  valid_21627643 = validateParameter(valid_21627643, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627643 != nil:
    section.add "Version", valid_21627643
  var valid_21627644 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627644 = validateParameter(valid_21627644, JString, required = true,
                                   default = nil)
  if valid_21627644 != nil:
    section.add "DBInstanceIdentifier", valid_21627644
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627652: Call_GetPromoteReadReplica_21627637;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627652.validator(path, query, header, formData, body, _)
  let scheme = call_21627652.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627652.makeUrl(scheme.get, call_21627652.host, call_21627652.base,
                               call_21627652.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627652, uri, valid, _)

proc call*(call_21627653: Call_GetPromoteReadReplica_21627637;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627654 = newJObject()
  add(query_21627654, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627654, "Action", newJString(Action))
  add(query_21627654, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21627654, "Version", newJString(Version))
  add(query_21627654, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627653.call(nil, query_21627654, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_21627637(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_21627638, base: "/",
    makeUrl: url_GetPromoteReadReplica_21627639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_21627692 = ref object of OpenApiRestCall_21625418
proc url_PostPurchaseReservedDBInstancesOffering_21627694(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_21627693(path: JsonNode;
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
  var valid_21627695 = query.getOrDefault("Action")
  valid_21627695 = validateParameter(valid_21627695, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_21627695 != nil:
    section.add "Action", valid_21627695
  var valid_21627696 = query.getOrDefault("Version")
  valid_21627696 = validateParameter(valid_21627696, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627696 != nil:
    section.add "Version", valid_21627696
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
  var valid_21627697 = header.getOrDefault("X-Amz-Date")
  valid_21627697 = validateParameter(valid_21627697, JString, required = false,
                                   default = nil)
  if valid_21627697 != nil:
    section.add "X-Amz-Date", valid_21627697
  var valid_21627698 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627698 = validateParameter(valid_21627698, JString, required = false,
                                   default = nil)
  if valid_21627698 != nil:
    section.add "X-Amz-Security-Token", valid_21627698
  var valid_21627699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627699 = validateParameter(valid_21627699, JString, required = false,
                                   default = nil)
  if valid_21627699 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627699
  var valid_21627700 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627700 = validateParameter(valid_21627700, JString, required = false,
                                   default = nil)
  if valid_21627700 != nil:
    section.add "X-Amz-Algorithm", valid_21627700
  var valid_21627701 = header.getOrDefault("X-Amz-Signature")
  valid_21627701 = validateParameter(valid_21627701, JString, required = false,
                                   default = nil)
  if valid_21627701 != nil:
    section.add "X-Amz-Signature", valid_21627701
  var valid_21627702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627702 = validateParameter(valid_21627702, JString, required = false,
                                   default = nil)
  if valid_21627702 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627702
  var valid_21627703 = header.getOrDefault("X-Amz-Credential")
  valid_21627703 = validateParameter(valid_21627703, JString, required = false,
                                   default = nil)
  if valid_21627703 != nil:
    section.add "X-Amz-Credential", valid_21627703
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_21627704 = formData.getOrDefault("ReservedDBInstanceId")
  valid_21627704 = validateParameter(valid_21627704, JString, required = false,
                                   default = nil)
  if valid_21627704 != nil:
    section.add "ReservedDBInstanceId", valid_21627704
  var valid_21627705 = formData.getOrDefault("DBInstanceCount")
  valid_21627705 = validateParameter(valid_21627705, JInt, required = false,
                                   default = nil)
  if valid_21627705 != nil:
    section.add "DBInstanceCount", valid_21627705
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_21627706 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627706 = validateParameter(valid_21627706, JString, required = true,
                                   default = nil)
  if valid_21627706 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627707: Call_PostPurchaseReservedDBInstancesOffering_21627692;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627707.validator(path, query, header, formData, body, _)
  let scheme = call_21627707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627707.makeUrl(scheme.get, call_21627707.host, call_21627707.base,
                               call_21627707.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627707, uri, valid, _)

proc call*(call_21627708: Call_PostPurchaseReservedDBInstancesOffering_21627692;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_21627709 = newJObject()
  var formData_21627710 = newJObject()
  add(formData_21627710, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_21627710, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_21627709, "Action", newJString(Action))
  add(formData_21627710, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627709, "Version", newJString(Version))
  result = call_21627708.call(nil, query_21627709, nil, formData_21627710, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_21627692(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_21627693,
    base: "/", makeUrl: url_PostPurchaseReservedDBInstancesOffering_21627694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_21627674 = ref object of OpenApiRestCall_21625418
proc url_GetPurchaseReservedDBInstancesOffering_21627676(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_21627675(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627677 = query.getOrDefault("DBInstanceCount")
  valid_21627677 = validateParameter(valid_21627677, JInt, required = false,
                                   default = nil)
  if valid_21627677 != nil:
    section.add "DBInstanceCount", valid_21627677
  var valid_21627678 = query.getOrDefault("ReservedDBInstanceId")
  valid_21627678 = validateParameter(valid_21627678, JString, required = false,
                                   default = nil)
  if valid_21627678 != nil:
    section.add "ReservedDBInstanceId", valid_21627678
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_21627679 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627679 = validateParameter(valid_21627679, JString, required = true,
                                   default = nil)
  if valid_21627679 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627679
  var valid_21627680 = query.getOrDefault("Action")
  valid_21627680 = validateParameter(valid_21627680, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_21627680 != nil:
    section.add "Action", valid_21627680
  var valid_21627681 = query.getOrDefault("Version")
  valid_21627681 = validateParameter(valid_21627681, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627681 != nil:
    section.add "Version", valid_21627681
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
  var valid_21627682 = header.getOrDefault("X-Amz-Date")
  valid_21627682 = validateParameter(valid_21627682, JString, required = false,
                                   default = nil)
  if valid_21627682 != nil:
    section.add "X-Amz-Date", valid_21627682
  var valid_21627683 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "X-Amz-Security-Token", valid_21627683
  var valid_21627684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627684 = validateParameter(valid_21627684, JString, required = false,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627684
  var valid_21627685 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627685 = validateParameter(valid_21627685, JString, required = false,
                                   default = nil)
  if valid_21627685 != nil:
    section.add "X-Amz-Algorithm", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-Signature")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-Signature", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-Credential")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-Credential", valid_21627688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627689: Call_GetPurchaseReservedDBInstancesOffering_21627674;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627689.validator(path, query, header, formData, body, _)
  let scheme = call_21627689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627689.makeUrl(scheme.get, call_21627689.host, call_21627689.base,
                               call_21627689.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627689, uri, valid, _)

proc call*(call_21627690: Call_GetPurchaseReservedDBInstancesOffering_21627674;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-01-10"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627691 = newJObject()
  add(query_21627691, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_21627691, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_21627691, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627691, "Action", newJString(Action))
  add(query_21627691, "Version", newJString(Version))
  result = call_21627690.call(nil, query_21627691, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_21627674(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_21627675,
    base: "/", makeUrl: url_GetPurchaseReservedDBInstancesOffering_21627676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_21627728 = ref object of OpenApiRestCall_21625418
proc url_PostRebootDBInstance_21627730(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_21627729(path: JsonNode; query: JsonNode;
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
  var valid_21627731 = query.getOrDefault("Action")
  valid_21627731 = validateParameter(valid_21627731, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627731 != nil:
    section.add "Action", valid_21627731
  var valid_21627732 = query.getOrDefault("Version")
  valid_21627732 = validateParameter(valid_21627732, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627732 != nil:
    section.add "Version", valid_21627732
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
  var valid_21627733 = header.getOrDefault("X-Amz-Date")
  valid_21627733 = validateParameter(valid_21627733, JString, required = false,
                                   default = nil)
  if valid_21627733 != nil:
    section.add "X-Amz-Date", valid_21627733
  var valid_21627734 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627734 = validateParameter(valid_21627734, JString, required = false,
                                   default = nil)
  if valid_21627734 != nil:
    section.add "X-Amz-Security-Token", valid_21627734
  var valid_21627735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627735 = validateParameter(valid_21627735, JString, required = false,
                                   default = nil)
  if valid_21627735 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627735
  var valid_21627736 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627736 = validateParameter(valid_21627736, JString, required = false,
                                   default = nil)
  if valid_21627736 != nil:
    section.add "X-Amz-Algorithm", valid_21627736
  var valid_21627737 = header.getOrDefault("X-Amz-Signature")
  valid_21627737 = validateParameter(valid_21627737, JString, required = false,
                                   default = nil)
  if valid_21627737 != nil:
    section.add "X-Amz-Signature", valid_21627737
  var valid_21627738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627738 = validateParameter(valid_21627738, JString, required = false,
                                   default = nil)
  if valid_21627738 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627738
  var valid_21627739 = header.getOrDefault("X-Amz-Credential")
  valid_21627739 = validateParameter(valid_21627739, JString, required = false,
                                   default = nil)
  if valid_21627739 != nil:
    section.add "X-Amz-Credential", valid_21627739
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627740 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627740 = validateParameter(valid_21627740, JString, required = true,
                                   default = nil)
  if valid_21627740 != nil:
    section.add "DBInstanceIdentifier", valid_21627740
  var valid_21627741 = formData.getOrDefault("ForceFailover")
  valid_21627741 = validateParameter(valid_21627741, JBool, required = false,
                                   default = nil)
  if valid_21627741 != nil:
    section.add "ForceFailover", valid_21627741
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627742: Call_PostRebootDBInstance_21627728; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627742.validator(path, query, header, formData, body, _)
  let scheme = call_21627742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627742.makeUrl(scheme.get, call_21627742.host, call_21627742.base,
                               call_21627742.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627742, uri, valid, _)

proc call*(call_21627743: Call_PostRebootDBInstance_21627728;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_21627744 = newJObject()
  var formData_21627745 = newJObject()
  add(formData_21627745, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627744, "Action", newJString(Action))
  add(formData_21627745, "ForceFailover", newJBool(ForceFailover))
  add(query_21627744, "Version", newJString(Version))
  result = call_21627743.call(nil, query_21627744, nil, formData_21627745, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_21627728(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_21627729, base: "/",
    makeUrl: url_PostRebootDBInstance_21627730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_21627711 = ref object of OpenApiRestCall_21625418
proc url_GetRebootDBInstance_21627713(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_21627712(path: JsonNode; query: JsonNode;
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
  var valid_21627714 = query.getOrDefault("Action")
  valid_21627714 = validateParameter(valid_21627714, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627714 != nil:
    section.add "Action", valid_21627714
  var valid_21627715 = query.getOrDefault("ForceFailover")
  valid_21627715 = validateParameter(valid_21627715, JBool, required = false,
                                   default = nil)
  if valid_21627715 != nil:
    section.add "ForceFailover", valid_21627715
  var valid_21627716 = query.getOrDefault("Version")
  valid_21627716 = validateParameter(valid_21627716, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627716 != nil:
    section.add "Version", valid_21627716
  var valid_21627717 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627717 = validateParameter(valid_21627717, JString, required = true,
                                   default = nil)
  if valid_21627717 != nil:
    section.add "DBInstanceIdentifier", valid_21627717
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
  var valid_21627718 = header.getOrDefault("X-Amz-Date")
  valid_21627718 = validateParameter(valid_21627718, JString, required = false,
                                   default = nil)
  if valid_21627718 != nil:
    section.add "X-Amz-Date", valid_21627718
  var valid_21627719 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627719 = validateParameter(valid_21627719, JString, required = false,
                                   default = nil)
  if valid_21627719 != nil:
    section.add "X-Amz-Security-Token", valid_21627719
  var valid_21627720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627720 = validateParameter(valid_21627720, JString, required = false,
                                   default = nil)
  if valid_21627720 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627720
  var valid_21627721 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627721 = validateParameter(valid_21627721, JString, required = false,
                                   default = nil)
  if valid_21627721 != nil:
    section.add "X-Amz-Algorithm", valid_21627721
  var valid_21627722 = header.getOrDefault("X-Amz-Signature")
  valid_21627722 = validateParameter(valid_21627722, JString, required = false,
                                   default = nil)
  if valid_21627722 != nil:
    section.add "X-Amz-Signature", valid_21627722
  var valid_21627723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627723 = validateParameter(valid_21627723, JString, required = false,
                                   default = nil)
  if valid_21627723 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627723
  var valid_21627724 = header.getOrDefault("X-Amz-Credential")
  valid_21627724 = validateParameter(valid_21627724, JString, required = false,
                                   default = nil)
  if valid_21627724 != nil:
    section.add "X-Amz-Credential", valid_21627724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627725: Call_GetRebootDBInstance_21627711; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627725.validator(path, query, header, formData, body, _)
  let scheme = call_21627725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627725.makeUrl(scheme.get, call_21627725.host, call_21627725.base,
                               call_21627725.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627725, uri, valid, _)

proc call*(call_21627726: Call_GetRebootDBInstance_21627711;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627727 = newJObject()
  add(query_21627727, "Action", newJString(Action))
  add(query_21627727, "ForceFailover", newJBool(ForceFailover))
  add(query_21627727, "Version", newJString(Version))
  add(query_21627727, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627726.call(nil, query_21627727, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_21627711(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_21627712, base: "/",
    makeUrl: url_GetRebootDBInstance_21627713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_21627763 = ref object of OpenApiRestCall_21625418
proc url_PostRemoveSourceIdentifierFromSubscription_21627765(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_21627764(path: JsonNode;
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
  var valid_21627766 = query.getOrDefault("Action")
  valid_21627766 = validateParameter(valid_21627766, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_21627766 != nil:
    section.add "Action", valid_21627766
  var valid_21627767 = query.getOrDefault("Version")
  valid_21627767 = validateParameter(valid_21627767, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627767 != nil:
    section.add "Version", valid_21627767
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
  var valid_21627768 = header.getOrDefault("X-Amz-Date")
  valid_21627768 = validateParameter(valid_21627768, JString, required = false,
                                   default = nil)
  if valid_21627768 != nil:
    section.add "X-Amz-Date", valid_21627768
  var valid_21627769 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627769 = validateParameter(valid_21627769, JString, required = false,
                                   default = nil)
  if valid_21627769 != nil:
    section.add "X-Amz-Security-Token", valid_21627769
  var valid_21627770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627770 = validateParameter(valid_21627770, JString, required = false,
                                   default = nil)
  if valid_21627770 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627770
  var valid_21627771 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627771 = validateParameter(valid_21627771, JString, required = false,
                                   default = nil)
  if valid_21627771 != nil:
    section.add "X-Amz-Algorithm", valid_21627771
  var valid_21627772 = header.getOrDefault("X-Amz-Signature")
  valid_21627772 = validateParameter(valid_21627772, JString, required = false,
                                   default = nil)
  if valid_21627772 != nil:
    section.add "X-Amz-Signature", valid_21627772
  var valid_21627773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627773 = validateParameter(valid_21627773, JString, required = false,
                                   default = nil)
  if valid_21627773 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627773
  var valid_21627774 = header.getOrDefault("X-Amz-Credential")
  valid_21627774 = validateParameter(valid_21627774, JString, required = false,
                                   default = nil)
  if valid_21627774 != nil:
    section.add "X-Amz-Credential", valid_21627774
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_21627775 = formData.getOrDefault("SourceIdentifier")
  valid_21627775 = validateParameter(valid_21627775, JString, required = true,
                                   default = nil)
  if valid_21627775 != nil:
    section.add "SourceIdentifier", valid_21627775
  var valid_21627776 = formData.getOrDefault("SubscriptionName")
  valid_21627776 = validateParameter(valid_21627776, JString, required = true,
                                   default = nil)
  if valid_21627776 != nil:
    section.add "SubscriptionName", valid_21627776
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627777: Call_PostRemoveSourceIdentifierFromSubscription_21627763;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627777.validator(path, query, header, formData, body, _)
  let scheme = call_21627777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627777.makeUrl(scheme.get, call_21627777.host, call_21627777.base,
                               call_21627777.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627777, uri, valid, _)

proc call*(call_21627778: Call_PostRemoveSourceIdentifierFromSubscription_21627763;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627779 = newJObject()
  var formData_21627780 = newJObject()
  add(formData_21627780, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_21627780, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627779, "Action", newJString(Action))
  add(query_21627779, "Version", newJString(Version))
  result = call_21627778.call(nil, query_21627779, nil, formData_21627780, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_21627763(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_21627764,
    base: "/", makeUrl: url_PostRemoveSourceIdentifierFromSubscription_21627765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_21627746 = ref object of OpenApiRestCall_21625418
proc url_GetRemoveSourceIdentifierFromSubscription_21627748(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_21627747(path: JsonNode;
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
  var valid_21627749 = query.getOrDefault("Action")
  valid_21627749 = validateParameter(valid_21627749, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_21627749 != nil:
    section.add "Action", valid_21627749
  var valid_21627750 = query.getOrDefault("SourceIdentifier")
  valid_21627750 = validateParameter(valid_21627750, JString, required = true,
                                   default = nil)
  if valid_21627750 != nil:
    section.add "SourceIdentifier", valid_21627750
  var valid_21627751 = query.getOrDefault("SubscriptionName")
  valid_21627751 = validateParameter(valid_21627751, JString, required = true,
                                   default = nil)
  if valid_21627751 != nil:
    section.add "SubscriptionName", valid_21627751
  var valid_21627752 = query.getOrDefault("Version")
  valid_21627752 = validateParameter(valid_21627752, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627752 != nil:
    section.add "Version", valid_21627752
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
  var valid_21627753 = header.getOrDefault("X-Amz-Date")
  valid_21627753 = validateParameter(valid_21627753, JString, required = false,
                                   default = nil)
  if valid_21627753 != nil:
    section.add "X-Amz-Date", valid_21627753
  var valid_21627754 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627754 = validateParameter(valid_21627754, JString, required = false,
                                   default = nil)
  if valid_21627754 != nil:
    section.add "X-Amz-Security-Token", valid_21627754
  var valid_21627755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627755 = validateParameter(valid_21627755, JString, required = false,
                                   default = nil)
  if valid_21627755 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627755
  var valid_21627756 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627756 = validateParameter(valid_21627756, JString, required = false,
                                   default = nil)
  if valid_21627756 != nil:
    section.add "X-Amz-Algorithm", valid_21627756
  var valid_21627757 = header.getOrDefault("X-Amz-Signature")
  valid_21627757 = validateParameter(valid_21627757, JString, required = false,
                                   default = nil)
  if valid_21627757 != nil:
    section.add "X-Amz-Signature", valid_21627757
  var valid_21627758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627758 = validateParameter(valid_21627758, JString, required = false,
                                   default = nil)
  if valid_21627758 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627758
  var valid_21627759 = header.getOrDefault("X-Amz-Credential")
  valid_21627759 = validateParameter(valid_21627759, JString, required = false,
                                   default = nil)
  if valid_21627759 != nil:
    section.add "X-Amz-Credential", valid_21627759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627760: Call_GetRemoveSourceIdentifierFromSubscription_21627746;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627760.validator(path, query, header, formData, body, _)
  let scheme = call_21627760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627760.makeUrl(scheme.get, call_21627760.host, call_21627760.base,
                               call_21627760.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627760, uri, valid, _)

proc call*(call_21627761: Call_GetRemoveSourceIdentifierFromSubscription_21627746;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21627762 = newJObject()
  add(query_21627762, "Action", newJString(Action))
  add(query_21627762, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21627762, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627762, "Version", newJString(Version))
  result = call_21627761.call(nil, query_21627762, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_21627746(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_21627747,
    base: "/", makeUrl: url_GetRemoveSourceIdentifierFromSubscription_21627748,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_21627798 = ref object of OpenApiRestCall_21625418
proc url_PostRemoveTagsFromResource_21627800(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_21627799(path: JsonNode; query: JsonNode;
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
  var valid_21627801 = query.getOrDefault("Action")
  valid_21627801 = validateParameter(valid_21627801, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21627801 != nil:
    section.add "Action", valid_21627801
  var valid_21627802 = query.getOrDefault("Version")
  valid_21627802 = validateParameter(valid_21627802, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627802 != nil:
    section.add "Version", valid_21627802
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
  var valid_21627803 = header.getOrDefault("X-Amz-Date")
  valid_21627803 = validateParameter(valid_21627803, JString, required = false,
                                   default = nil)
  if valid_21627803 != nil:
    section.add "X-Amz-Date", valid_21627803
  var valid_21627804 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627804 = validateParameter(valid_21627804, JString, required = false,
                                   default = nil)
  if valid_21627804 != nil:
    section.add "X-Amz-Security-Token", valid_21627804
  var valid_21627805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627805 = validateParameter(valid_21627805, JString, required = false,
                                   default = nil)
  if valid_21627805 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627805
  var valid_21627806 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627806 = validateParameter(valid_21627806, JString, required = false,
                                   default = nil)
  if valid_21627806 != nil:
    section.add "X-Amz-Algorithm", valid_21627806
  var valid_21627807 = header.getOrDefault("X-Amz-Signature")
  valid_21627807 = validateParameter(valid_21627807, JString, required = false,
                                   default = nil)
  if valid_21627807 != nil:
    section.add "X-Amz-Signature", valid_21627807
  var valid_21627808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627808 = validateParameter(valid_21627808, JString, required = false,
                                   default = nil)
  if valid_21627808 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627808
  var valid_21627809 = header.getOrDefault("X-Amz-Credential")
  valid_21627809 = validateParameter(valid_21627809, JString, required = false,
                                   default = nil)
  if valid_21627809 != nil:
    section.add "X-Amz-Credential", valid_21627809
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_21627810 = formData.getOrDefault("TagKeys")
  valid_21627810 = validateParameter(valid_21627810, JArray, required = true,
                                   default = nil)
  if valid_21627810 != nil:
    section.add "TagKeys", valid_21627810
  var valid_21627811 = formData.getOrDefault("ResourceName")
  valid_21627811 = validateParameter(valid_21627811, JString, required = true,
                                   default = nil)
  if valid_21627811 != nil:
    section.add "ResourceName", valid_21627811
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627812: Call_PostRemoveTagsFromResource_21627798;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627812.validator(path, query, header, formData, body, _)
  let scheme = call_21627812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627812.makeUrl(scheme.get, call_21627812.host, call_21627812.base,
                               call_21627812.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627812, uri, valid, _)

proc call*(call_21627813: Call_PostRemoveTagsFromResource_21627798;
          TagKeys: JsonNode; ResourceName: string;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_21627814 = newJObject()
  var formData_21627815 = newJObject()
  add(query_21627814, "Action", newJString(Action))
  if TagKeys != nil:
    formData_21627815.add "TagKeys", TagKeys
  add(formData_21627815, "ResourceName", newJString(ResourceName))
  add(query_21627814, "Version", newJString(Version))
  result = call_21627813.call(nil, query_21627814, nil, formData_21627815, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_21627798(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_21627799, base: "/",
    makeUrl: url_PostRemoveTagsFromResource_21627800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_21627781 = ref object of OpenApiRestCall_21625418
proc url_GetRemoveTagsFromResource_21627783(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_21627782(path: JsonNode; query: JsonNode;
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
  var valid_21627784 = query.getOrDefault("ResourceName")
  valid_21627784 = validateParameter(valid_21627784, JString, required = true,
                                   default = nil)
  if valid_21627784 != nil:
    section.add "ResourceName", valid_21627784
  var valid_21627785 = query.getOrDefault("Action")
  valid_21627785 = validateParameter(valid_21627785, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21627785 != nil:
    section.add "Action", valid_21627785
  var valid_21627786 = query.getOrDefault("TagKeys")
  valid_21627786 = validateParameter(valid_21627786, JArray, required = true,
                                   default = nil)
  if valid_21627786 != nil:
    section.add "TagKeys", valid_21627786
  var valid_21627787 = query.getOrDefault("Version")
  valid_21627787 = validateParameter(valid_21627787, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627787 != nil:
    section.add "Version", valid_21627787
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
  var valid_21627788 = header.getOrDefault("X-Amz-Date")
  valid_21627788 = validateParameter(valid_21627788, JString, required = false,
                                   default = nil)
  if valid_21627788 != nil:
    section.add "X-Amz-Date", valid_21627788
  var valid_21627789 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627789 = validateParameter(valid_21627789, JString, required = false,
                                   default = nil)
  if valid_21627789 != nil:
    section.add "X-Amz-Security-Token", valid_21627789
  var valid_21627790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627790 = validateParameter(valid_21627790, JString, required = false,
                                   default = nil)
  if valid_21627790 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627790
  var valid_21627791 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627791 = validateParameter(valid_21627791, JString, required = false,
                                   default = nil)
  if valid_21627791 != nil:
    section.add "X-Amz-Algorithm", valid_21627791
  var valid_21627792 = header.getOrDefault("X-Amz-Signature")
  valid_21627792 = validateParameter(valid_21627792, JString, required = false,
                                   default = nil)
  if valid_21627792 != nil:
    section.add "X-Amz-Signature", valid_21627792
  var valid_21627793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627793 = validateParameter(valid_21627793, JString, required = false,
                                   default = nil)
  if valid_21627793 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627793
  var valid_21627794 = header.getOrDefault("X-Amz-Credential")
  valid_21627794 = validateParameter(valid_21627794, JString, required = false,
                                   default = nil)
  if valid_21627794 != nil:
    section.add "X-Amz-Credential", valid_21627794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627795: Call_GetRemoveTagsFromResource_21627781;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627795.validator(path, query, header, formData, body, _)
  let scheme = call_21627795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627795.makeUrl(scheme.get, call_21627795.host, call_21627795.base,
                               call_21627795.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627795, uri, valid, _)

proc call*(call_21627796: Call_GetRemoveTagsFromResource_21627781;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_21627797 = newJObject()
  add(query_21627797, "ResourceName", newJString(ResourceName))
  add(query_21627797, "Action", newJString(Action))
  if TagKeys != nil:
    query_21627797.add "TagKeys", TagKeys
  add(query_21627797, "Version", newJString(Version))
  result = call_21627796.call(nil, query_21627797, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_21627781(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_21627782, base: "/",
    makeUrl: url_GetRemoveTagsFromResource_21627783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_21627834 = ref object of OpenApiRestCall_21625418
proc url_PostResetDBParameterGroup_21627836(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_21627835(path: JsonNode; query: JsonNode;
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
  var valid_21627837 = query.getOrDefault("Action")
  valid_21627837 = validateParameter(valid_21627837, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_21627837 != nil:
    section.add "Action", valid_21627837
  var valid_21627838 = query.getOrDefault("Version")
  valid_21627838 = validateParameter(valid_21627838, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627838 != nil:
    section.add "Version", valid_21627838
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
  var valid_21627839 = header.getOrDefault("X-Amz-Date")
  valid_21627839 = validateParameter(valid_21627839, JString, required = false,
                                   default = nil)
  if valid_21627839 != nil:
    section.add "X-Amz-Date", valid_21627839
  var valid_21627840 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627840 = validateParameter(valid_21627840, JString, required = false,
                                   default = nil)
  if valid_21627840 != nil:
    section.add "X-Amz-Security-Token", valid_21627840
  var valid_21627841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627841 = validateParameter(valid_21627841, JString, required = false,
                                   default = nil)
  if valid_21627841 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627841
  var valid_21627842 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627842 = validateParameter(valid_21627842, JString, required = false,
                                   default = nil)
  if valid_21627842 != nil:
    section.add "X-Amz-Algorithm", valid_21627842
  var valid_21627843 = header.getOrDefault("X-Amz-Signature")
  valid_21627843 = validateParameter(valid_21627843, JString, required = false,
                                   default = nil)
  if valid_21627843 != nil:
    section.add "X-Amz-Signature", valid_21627843
  var valid_21627844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627844 = validateParameter(valid_21627844, JString, required = false,
                                   default = nil)
  if valid_21627844 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627844
  var valid_21627845 = header.getOrDefault("X-Amz-Credential")
  valid_21627845 = validateParameter(valid_21627845, JString, required = false,
                                   default = nil)
  if valid_21627845 != nil:
    section.add "X-Amz-Credential", valid_21627845
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627846 = formData.getOrDefault("DBParameterGroupName")
  valid_21627846 = validateParameter(valid_21627846, JString, required = true,
                                   default = nil)
  if valid_21627846 != nil:
    section.add "DBParameterGroupName", valid_21627846
  var valid_21627847 = formData.getOrDefault("Parameters")
  valid_21627847 = validateParameter(valid_21627847, JArray, required = false,
                                   default = nil)
  if valid_21627847 != nil:
    section.add "Parameters", valid_21627847
  var valid_21627848 = formData.getOrDefault("ResetAllParameters")
  valid_21627848 = validateParameter(valid_21627848, JBool, required = false,
                                   default = nil)
  if valid_21627848 != nil:
    section.add "ResetAllParameters", valid_21627848
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627849: Call_PostResetDBParameterGroup_21627834;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627849.validator(path, query, header, formData, body, _)
  let scheme = call_21627849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627849.makeUrl(scheme.get, call_21627849.host, call_21627849.base,
                               call_21627849.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627849, uri, valid, _)

proc call*(call_21627850: Call_PostResetDBParameterGroup_21627834;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_21627851 = newJObject()
  var formData_21627852 = newJObject()
  add(formData_21627852, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_21627852.add "Parameters", Parameters
  add(query_21627851, "Action", newJString(Action))
  add(formData_21627852, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21627851, "Version", newJString(Version))
  result = call_21627850.call(nil, query_21627851, nil, formData_21627852, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_21627834(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_21627835, base: "/",
    makeUrl: url_PostResetDBParameterGroup_21627836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_21627816 = ref object of OpenApiRestCall_21625418
proc url_GetResetDBParameterGroup_21627818(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_21627817(path: JsonNode; query: JsonNode;
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
  var valid_21627819 = query.getOrDefault("DBParameterGroupName")
  valid_21627819 = validateParameter(valid_21627819, JString, required = true,
                                   default = nil)
  if valid_21627819 != nil:
    section.add "DBParameterGroupName", valid_21627819
  var valid_21627820 = query.getOrDefault("Parameters")
  valid_21627820 = validateParameter(valid_21627820, JArray, required = false,
                                   default = nil)
  if valid_21627820 != nil:
    section.add "Parameters", valid_21627820
  var valid_21627821 = query.getOrDefault("Action")
  valid_21627821 = validateParameter(valid_21627821, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_21627821 != nil:
    section.add "Action", valid_21627821
  var valid_21627822 = query.getOrDefault("ResetAllParameters")
  valid_21627822 = validateParameter(valid_21627822, JBool, required = false,
                                   default = nil)
  if valid_21627822 != nil:
    section.add "ResetAllParameters", valid_21627822
  var valid_21627823 = query.getOrDefault("Version")
  valid_21627823 = validateParameter(valid_21627823, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627823 != nil:
    section.add "Version", valid_21627823
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
  var valid_21627824 = header.getOrDefault("X-Amz-Date")
  valid_21627824 = validateParameter(valid_21627824, JString, required = false,
                                   default = nil)
  if valid_21627824 != nil:
    section.add "X-Amz-Date", valid_21627824
  var valid_21627825 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627825 = validateParameter(valid_21627825, JString, required = false,
                                   default = nil)
  if valid_21627825 != nil:
    section.add "X-Amz-Security-Token", valid_21627825
  var valid_21627826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627826 = validateParameter(valid_21627826, JString, required = false,
                                   default = nil)
  if valid_21627826 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627826
  var valid_21627827 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627827 = validateParameter(valid_21627827, JString, required = false,
                                   default = nil)
  if valid_21627827 != nil:
    section.add "X-Amz-Algorithm", valid_21627827
  var valid_21627828 = header.getOrDefault("X-Amz-Signature")
  valid_21627828 = validateParameter(valid_21627828, JString, required = false,
                                   default = nil)
  if valid_21627828 != nil:
    section.add "X-Amz-Signature", valid_21627828
  var valid_21627829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627829 = validateParameter(valid_21627829, JString, required = false,
                                   default = nil)
  if valid_21627829 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627829
  var valid_21627830 = header.getOrDefault("X-Amz-Credential")
  valid_21627830 = validateParameter(valid_21627830, JString, required = false,
                                   default = nil)
  if valid_21627830 != nil:
    section.add "X-Amz-Credential", valid_21627830
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627831: Call_GetResetDBParameterGroup_21627816;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627831.validator(path, query, header, formData, body, _)
  let scheme = call_21627831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627831.makeUrl(scheme.get, call_21627831.host, call_21627831.base,
                               call_21627831.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627831, uri, valid, _)

proc call*(call_21627832: Call_GetResetDBParameterGroup_21627816;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_21627833 = newJObject()
  add(query_21627833, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_21627833.add "Parameters", Parameters
  add(query_21627833, "Action", newJString(Action))
  add(query_21627833, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21627833, "Version", newJString(Version))
  result = call_21627832.call(nil, query_21627833, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_21627816(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_21627817, base: "/",
    makeUrl: url_GetResetDBParameterGroup_21627818,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_21627882 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBInstanceFromDBSnapshot_21627884(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_21627883(path: JsonNode;
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
  var valid_21627885 = query.getOrDefault("Action")
  valid_21627885 = validateParameter(valid_21627885, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_21627885 != nil:
    section.add "Action", valid_21627885
  var valid_21627886 = query.getOrDefault("Version")
  valid_21627886 = validateParameter(valid_21627886, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627886 != nil:
    section.add "Version", valid_21627886
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
  var valid_21627887 = header.getOrDefault("X-Amz-Date")
  valid_21627887 = validateParameter(valid_21627887, JString, required = false,
                                   default = nil)
  if valid_21627887 != nil:
    section.add "X-Amz-Date", valid_21627887
  var valid_21627888 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627888 = validateParameter(valid_21627888, JString, required = false,
                                   default = nil)
  if valid_21627888 != nil:
    section.add "X-Amz-Security-Token", valid_21627888
  var valid_21627889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627889 = validateParameter(valid_21627889, JString, required = false,
                                   default = nil)
  if valid_21627889 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627889
  var valid_21627890 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627890 = validateParameter(valid_21627890, JString, required = false,
                                   default = nil)
  if valid_21627890 != nil:
    section.add "X-Amz-Algorithm", valid_21627890
  var valid_21627891 = header.getOrDefault("X-Amz-Signature")
  valid_21627891 = validateParameter(valid_21627891, JString, required = false,
                                   default = nil)
  if valid_21627891 != nil:
    section.add "X-Amz-Signature", valid_21627891
  var valid_21627892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627892 = validateParameter(valid_21627892, JString, required = false,
                                   default = nil)
  if valid_21627892 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627892
  var valid_21627893 = header.getOrDefault("X-Amz-Credential")
  valid_21627893 = validateParameter(valid_21627893, JString, required = false,
                                   default = nil)
  if valid_21627893 != nil:
    section.add "X-Amz-Credential", valid_21627893
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21627894 = formData.getOrDefault("Port")
  valid_21627894 = validateParameter(valid_21627894, JInt, required = false,
                                   default = nil)
  if valid_21627894 != nil:
    section.add "Port", valid_21627894
  var valid_21627895 = formData.getOrDefault("Engine")
  valid_21627895 = validateParameter(valid_21627895, JString, required = false,
                                   default = nil)
  if valid_21627895 != nil:
    section.add "Engine", valid_21627895
  var valid_21627896 = formData.getOrDefault("Iops")
  valid_21627896 = validateParameter(valid_21627896, JInt, required = false,
                                   default = nil)
  if valid_21627896 != nil:
    section.add "Iops", valid_21627896
  var valid_21627897 = formData.getOrDefault("DBName")
  valid_21627897 = validateParameter(valid_21627897, JString, required = false,
                                   default = nil)
  if valid_21627897 != nil:
    section.add "DBName", valid_21627897
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627898 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627898 = validateParameter(valid_21627898, JString, required = true,
                                   default = nil)
  if valid_21627898 != nil:
    section.add "DBInstanceIdentifier", valid_21627898
  var valid_21627899 = formData.getOrDefault("OptionGroupName")
  valid_21627899 = validateParameter(valid_21627899, JString, required = false,
                                   default = nil)
  if valid_21627899 != nil:
    section.add "OptionGroupName", valid_21627899
  var valid_21627900 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627900 = validateParameter(valid_21627900, JString, required = false,
                                   default = nil)
  if valid_21627900 != nil:
    section.add "DBSubnetGroupName", valid_21627900
  var valid_21627901 = formData.getOrDefault("AvailabilityZone")
  valid_21627901 = validateParameter(valid_21627901, JString, required = false,
                                   default = nil)
  if valid_21627901 != nil:
    section.add "AvailabilityZone", valid_21627901
  var valid_21627902 = formData.getOrDefault("MultiAZ")
  valid_21627902 = validateParameter(valid_21627902, JBool, required = false,
                                   default = nil)
  if valid_21627902 != nil:
    section.add "MultiAZ", valid_21627902
  var valid_21627903 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21627903 = validateParameter(valid_21627903, JString, required = true,
                                   default = nil)
  if valid_21627903 != nil:
    section.add "DBSnapshotIdentifier", valid_21627903
  var valid_21627904 = formData.getOrDefault("PubliclyAccessible")
  valid_21627904 = validateParameter(valid_21627904, JBool, required = false,
                                   default = nil)
  if valid_21627904 != nil:
    section.add "PubliclyAccessible", valid_21627904
  var valid_21627905 = formData.getOrDefault("DBInstanceClass")
  valid_21627905 = validateParameter(valid_21627905, JString, required = false,
                                   default = nil)
  if valid_21627905 != nil:
    section.add "DBInstanceClass", valid_21627905
  var valid_21627906 = formData.getOrDefault("LicenseModel")
  valid_21627906 = validateParameter(valid_21627906, JString, required = false,
                                   default = nil)
  if valid_21627906 != nil:
    section.add "LicenseModel", valid_21627906
  var valid_21627907 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627907 = validateParameter(valid_21627907, JBool, required = false,
                                   default = nil)
  if valid_21627907 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627907
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627908: Call_PostRestoreDBInstanceFromDBSnapshot_21627882;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627908.validator(path, query, header, formData, body, _)
  let scheme = call_21627908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627908.makeUrl(scheme.get, call_21627908.host, call_21627908.base,
                               call_21627908.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627908, uri, valid, _)

proc call*(call_21627909: Call_PostRestoreDBInstanceFromDBSnapshot_21627882;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2013-01-10"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
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
  var query_21627910 = newJObject()
  var formData_21627911 = newJObject()
  add(formData_21627911, "Port", newJInt(Port))
  add(formData_21627911, "Engine", newJString(Engine))
  add(formData_21627911, "Iops", newJInt(Iops))
  add(formData_21627911, "DBName", newJString(DBName))
  add(formData_21627911, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627911, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627911, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21627911, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21627911, "MultiAZ", newJBool(MultiAZ))
  add(formData_21627911, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21627910, "Action", newJString(Action))
  add(formData_21627911, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21627911, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627911, "LicenseModel", newJString(LicenseModel))
  add(formData_21627911, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21627910, "Version", newJString(Version))
  result = call_21627909.call(nil, query_21627910, nil, formData_21627911, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_21627882(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_21627883, base: "/",
    makeUrl: url_PostRestoreDBInstanceFromDBSnapshot_21627884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_21627853 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBInstanceFromDBSnapshot_21627855(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_21627854(path: JsonNode;
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
  var valid_21627856 = query.getOrDefault("Engine")
  valid_21627856 = validateParameter(valid_21627856, JString, required = false,
                                   default = nil)
  if valid_21627856 != nil:
    section.add "Engine", valid_21627856
  var valid_21627857 = query.getOrDefault("OptionGroupName")
  valid_21627857 = validateParameter(valid_21627857, JString, required = false,
                                   default = nil)
  if valid_21627857 != nil:
    section.add "OptionGroupName", valid_21627857
  var valid_21627858 = query.getOrDefault("AvailabilityZone")
  valid_21627858 = validateParameter(valid_21627858, JString, required = false,
                                   default = nil)
  if valid_21627858 != nil:
    section.add "AvailabilityZone", valid_21627858
  var valid_21627859 = query.getOrDefault("Iops")
  valid_21627859 = validateParameter(valid_21627859, JInt, required = false,
                                   default = nil)
  if valid_21627859 != nil:
    section.add "Iops", valid_21627859
  var valid_21627860 = query.getOrDefault("MultiAZ")
  valid_21627860 = validateParameter(valid_21627860, JBool, required = false,
                                   default = nil)
  if valid_21627860 != nil:
    section.add "MultiAZ", valid_21627860
  var valid_21627861 = query.getOrDefault("LicenseModel")
  valid_21627861 = validateParameter(valid_21627861, JString, required = false,
                                   default = nil)
  if valid_21627861 != nil:
    section.add "LicenseModel", valid_21627861
  var valid_21627862 = query.getOrDefault("DBName")
  valid_21627862 = validateParameter(valid_21627862, JString, required = false,
                                   default = nil)
  if valid_21627862 != nil:
    section.add "DBName", valid_21627862
  var valid_21627863 = query.getOrDefault("DBInstanceClass")
  valid_21627863 = validateParameter(valid_21627863, JString, required = false,
                                   default = nil)
  if valid_21627863 != nil:
    section.add "DBInstanceClass", valid_21627863
  var valid_21627864 = query.getOrDefault("Action")
  valid_21627864 = validateParameter(valid_21627864, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_21627864 != nil:
    section.add "Action", valid_21627864
  var valid_21627865 = query.getOrDefault("DBSubnetGroupName")
  valid_21627865 = validateParameter(valid_21627865, JString, required = false,
                                   default = nil)
  if valid_21627865 != nil:
    section.add "DBSubnetGroupName", valid_21627865
  var valid_21627866 = query.getOrDefault("PubliclyAccessible")
  valid_21627866 = validateParameter(valid_21627866, JBool, required = false,
                                   default = nil)
  if valid_21627866 != nil:
    section.add "PubliclyAccessible", valid_21627866
  var valid_21627867 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627867 = validateParameter(valid_21627867, JBool, required = false,
                                   default = nil)
  if valid_21627867 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627867
  var valid_21627868 = query.getOrDefault("Port")
  valid_21627868 = validateParameter(valid_21627868, JInt, required = false,
                                   default = nil)
  if valid_21627868 != nil:
    section.add "Port", valid_21627868
  var valid_21627869 = query.getOrDefault("Version")
  valid_21627869 = validateParameter(valid_21627869, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627869 != nil:
    section.add "Version", valid_21627869
  var valid_21627870 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627870 = validateParameter(valid_21627870, JString, required = true,
                                   default = nil)
  if valid_21627870 != nil:
    section.add "DBInstanceIdentifier", valid_21627870
  var valid_21627871 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21627871 = validateParameter(valid_21627871, JString, required = true,
                                   default = nil)
  if valid_21627871 != nil:
    section.add "DBSnapshotIdentifier", valid_21627871
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
  var valid_21627872 = header.getOrDefault("X-Amz-Date")
  valid_21627872 = validateParameter(valid_21627872, JString, required = false,
                                   default = nil)
  if valid_21627872 != nil:
    section.add "X-Amz-Date", valid_21627872
  var valid_21627873 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627873 = validateParameter(valid_21627873, JString, required = false,
                                   default = nil)
  if valid_21627873 != nil:
    section.add "X-Amz-Security-Token", valid_21627873
  var valid_21627874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627874 = validateParameter(valid_21627874, JString, required = false,
                                   default = nil)
  if valid_21627874 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627874
  var valid_21627875 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627875 = validateParameter(valid_21627875, JString, required = false,
                                   default = nil)
  if valid_21627875 != nil:
    section.add "X-Amz-Algorithm", valid_21627875
  var valid_21627876 = header.getOrDefault("X-Amz-Signature")
  valid_21627876 = validateParameter(valid_21627876, JString, required = false,
                                   default = nil)
  if valid_21627876 != nil:
    section.add "X-Amz-Signature", valid_21627876
  var valid_21627877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627877 = validateParameter(valid_21627877, JString, required = false,
                                   default = nil)
  if valid_21627877 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627877
  var valid_21627878 = header.getOrDefault("X-Amz-Credential")
  valid_21627878 = validateParameter(valid_21627878, JString, required = false,
                                   default = nil)
  if valid_21627878 != nil:
    section.add "X-Amz-Credential", valid_21627878
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627879: Call_GetRestoreDBInstanceFromDBSnapshot_21627853;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627879.validator(path, query, header, formData, body, _)
  let scheme = call_21627879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627879.makeUrl(scheme.get, call_21627879.host, call_21627879.base,
                               call_21627879.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627879, uri, valid, _)

proc call*(call_21627880: Call_GetRestoreDBInstanceFromDBSnapshot_21627853;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   Engine: string
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   MultiAZ: bool
  ##   LicenseModel: string
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
  var query_21627881 = newJObject()
  add(query_21627881, "Engine", newJString(Engine))
  add(query_21627881, "OptionGroupName", newJString(OptionGroupName))
  add(query_21627881, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21627881, "Iops", newJInt(Iops))
  add(query_21627881, "MultiAZ", newJBool(MultiAZ))
  add(query_21627881, "LicenseModel", newJString(LicenseModel))
  add(query_21627881, "DBName", newJString(DBName))
  add(query_21627881, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627881, "Action", newJString(Action))
  add(query_21627881, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627881, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21627881, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21627881, "Port", newJInt(Port))
  add(query_21627881, "Version", newJString(Version))
  add(query_21627881, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627881, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21627880.call(nil, query_21627881, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_21627853(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_21627854, base: "/",
    makeUrl: url_GetRestoreDBInstanceFromDBSnapshot_21627855,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_21627943 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBInstanceToPointInTime_21627945(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_21627944(path: JsonNode;
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
  var valid_21627946 = query.getOrDefault("Action")
  valid_21627946 = validateParameter(valid_21627946, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_21627946 != nil:
    section.add "Action", valid_21627946
  var valid_21627947 = query.getOrDefault("Version")
  valid_21627947 = validateParameter(valid_21627947, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627947 != nil:
    section.add "Version", valid_21627947
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
  var valid_21627948 = header.getOrDefault("X-Amz-Date")
  valid_21627948 = validateParameter(valid_21627948, JString, required = false,
                                   default = nil)
  if valid_21627948 != nil:
    section.add "X-Amz-Date", valid_21627948
  var valid_21627949 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627949 = validateParameter(valid_21627949, JString, required = false,
                                   default = nil)
  if valid_21627949 != nil:
    section.add "X-Amz-Security-Token", valid_21627949
  var valid_21627950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627950 = validateParameter(valid_21627950, JString, required = false,
                                   default = nil)
  if valid_21627950 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627950
  var valid_21627951 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627951 = validateParameter(valid_21627951, JString, required = false,
                                   default = nil)
  if valid_21627951 != nil:
    section.add "X-Amz-Algorithm", valid_21627951
  var valid_21627952 = header.getOrDefault("X-Amz-Signature")
  valid_21627952 = validateParameter(valid_21627952, JString, required = false,
                                   default = nil)
  if valid_21627952 != nil:
    section.add "X-Amz-Signature", valid_21627952
  var valid_21627953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627953 = validateParameter(valid_21627953, JString, required = false,
                                   default = nil)
  if valid_21627953 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627953
  var valid_21627954 = header.getOrDefault("X-Amz-Credential")
  valid_21627954 = validateParameter(valid_21627954, JString, required = false,
                                   default = nil)
  if valid_21627954 != nil:
    section.add "X-Amz-Credential", valid_21627954
  result.add "header", section
  ## parameters in `formData` object:
  ##   UseLatestRestorableTime: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   OptionGroupName: JString
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
  var valid_21627955 = formData.getOrDefault("UseLatestRestorableTime")
  valid_21627955 = validateParameter(valid_21627955, JBool, required = false,
                                   default = nil)
  if valid_21627955 != nil:
    section.add "UseLatestRestorableTime", valid_21627955
  var valid_21627956 = formData.getOrDefault("Port")
  valid_21627956 = validateParameter(valid_21627956, JInt, required = false,
                                   default = nil)
  if valid_21627956 != nil:
    section.add "Port", valid_21627956
  var valid_21627957 = formData.getOrDefault("Engine")
  valid_21627957 = validateParameter(valid_21627957, JString, required = false,
                                   default = nil)
  if valid_21627957 != nil:
    section.add "Engine", valid_21627957
  var valid_21627958 = formData.getOrDefault("Iops")
  valid_21627958 = validateParameter(valid_21627958, JInt, required = false,
                                   default = nil)
  if valid_21627958 != nil:
    section.add "Iops", valid_21627958
  var valid_21627959 = formData.getOrDefault("DBName")
  valid_21627959 = validateParameter(valid_21627959, JString, required = false,
                                   default = nil)
  if valid_21627959 != nil:
    section.add "DBName", valid_21627959
  var valid_21627960 = formData.getOrDefault("OptionGroupName")
  valid_21627960 = validateParameter(valid_21627960, JString, required = false,
                                   default = nil)
  if valid_21627960 != nil:
    section.add "OptionGroupName", valid_21627960
  var valid_21627961 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627961 = validateParameter(valid_21627961, JString, required = false,
                                   default = nil)
  if valid_21627961 != nil:
    section.add "DBSubnetGroupName", valid_21627961
  var valid_21627962 = formData.getOrDefault("AvailabilityZone")
  valid_21627962 = validateParameter(valid_21627962, JString, required = false,
                                   default = nil)
  if valid_21627962 != nil:
    section.add "AvailabilityZone", valid_21627962
  var valid_21627963 = formData.getOrDefault("MultiAZ")
  valid_21627963 = validateParameter(valid_21627963, JBool, required = false,
                                   default = nil)
  if valid_21627963 != nil:
    section.add "MultiAZ", valid_21627963
  var valid_21627964 = formData.getOrDefault("RestoreTime")
  valid_21627964 = validateParameter(valid_21627964, JString, required = false,
                                   default = nil)
  if valid_21627964 != nil:
    section.add "RestoreTime", valid_21627964
  var valid_21627965 = formData.getOrDefault("PubliclyAccessible")
  valid_21627965 = validateParameter(valid_21627965, JBool, required = false,
                                   default = nil)
  if valid_21627965 != nil:
    section.add "PubliclyAccessible", valid_21627965
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_21627966 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_21627966 = validateParameter(valid_21627966, JString, required = true,
                                   default = nil)
  if valid_21627966 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21627966
  var valid_21627967 = formData.getOrDefault("DBInstanceClass")
  valid_21627967 = validateParameter(valid_21627967, JString, required = false,
                                   default = nil)
  if valid_21627967 != nil:
    section.add "DBInstanceClass", valid_21627967
  var valid_21627968 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_21627968 = validateParameter(valid_21627968, JString, required = true,
                                   default = nil)
  if valid_21627968 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21627968
  var valid_21627969 = formData.getOrDefault("LicenseModel")
  valid_21627969 = validateParameter(valid_21627969, JString, required = false,
                                   default = nil)
  if valid_21627969 != nil:
    section.add "LicenseModel", valid_21627969
  var valid_21627970 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627970 = validateParameter(valid_21627970, JBool, required = false,
                                   default = nil)
  if valid_21627970 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627970
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627971: Call_PostRestoreDBInstanceToPointInTime_21627943;
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

proc call*(call_21627972: Call_PostRestoreDBInstanceToPointInTime_21627943;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   UseLatestRestorableTime: bool
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   OptionGroupName: string
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
  var query_21627973 = newJObject()
  var formData_21627974 = newJObject()
  add(formData_21627974, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_21627974, "Port", newJInt(Port))
  add(formData_21627974, "Engine", newJString(Engine))
  add(formData_21627974, "Iops", newJInt(Iops))
  add(formData_21627974, "DBName", newJString(DBName))
  add(formData_21627974, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627974, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21627974, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21627974, "MultiAZ", newJBool(MultiAZ))
  add(query_21627973, "Action", newJString(Action))
  add(formData_21627974, "RestoreTime", newJString(RestoreTime))
  add(formData_21627974, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21627974, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_21627974, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627974, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_21627974, "LicenseModel", newJString(LicenseModel))
  add(formData_21627974, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21627973, "Version", newJString(Version))
  result = call_21627972.call(nil, query_21627973, nil, formData_21627974, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_21627943(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_21627944, base: "/",
    makeUrl: url_PostRestoreDBInstanceToPointInTime_21627945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_21627912 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBInstanceToPointInTime_21627914(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_21627913(path: JsonNode;
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
  var valid_21627915 = query.getOrDefault("Engine")
  valid_21627915 = validateParameter(valid_21627915, JString, required = false,
                                   default = nil)
  if valid_21627915 != nil:
    section.add "Engine", valid_21627915
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_21627916 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_21627916 = validateParameter(valid_21627916, JString, required = true,
                                   default = nil)
  if valid_21627916 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21627916
  var valid_21627917 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_21627917 = validateParameter(valid_21627917, JString, required = true,
                                   default = nil)
  if valid_21627917 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21627917
  var valid_21627918 = query.getOrDefault("AvailabilityZone")
  valid_21627918 = validateParameter(valid_21627918, JString, required = false,
                                   default = nil)
  if valid_21627918 != nil:
    section.add "AvailabilityZone", valid_21627918
  var valid_21627919 = query.getOrDefault("Iops")
  valid_21627919 = validateParameter(valid_21627919, JInt, required = false,
                                   default = nil)
  if valid_21627919 != nil:
    section.add "Iops", valid_21627919
  var valid_21627920 = query.getOrDefault("OptionGroupName")
  valid_21627920 = validateParameter(valid_21627920, JString, required = false,
                                   default = nil)
  if valid_21627920 != nil:
    section.add "OptionGroupName", valid_21627920
  var valid_21627921 = query.getOrDefault("RestoreTime")
  valid_21627921 = validateParameter(valid_21627921, JString, required = false,
                                   default = nil)
  if valid_21627921 != nil:
    section.add "RestoreTime", valid_21627921
  var valid_21627922 = query.getOrDefault("MultiAZ")
  valid_21627922 = validateParameter(valid_21627922, JBool, required = false,
                                   default = nil)
  if valid_21627922 != nil:
    section.add "MultiAZ", valid_21627922
  var valid_21627923 = query.getOrDefault("LicenseModel")
  valid_21627923 = validateParameter(valid_21627923, JString, required = false,
                                   default = nil)
  if valid_21627923 != nil:
    section.add "LicenseModel", valid_21627923
  var valid_21627924 = query.getOrDefault("DBName")
  valid_21627924 = validateParameter(valid_21627924, JString, required = false,
                                   default = nil)
  if valid_21627924 != nil:
    section.add "DBName", valid_21627924
  var valid_21627925 = query.getOrDefault("DBInstanceClass")
  valid_21627925 = validateParameter(valid_21627925, JString, required = false,
                                   default = nil)
  if valid_21627925 != nil:
    section.add "DBInstanceClass", valid_21627925
  var valid_21627926 = query.getOrDefault("Action")
  valid_21627926 = validateParameter(valid_21627926, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_21627926 != nil:
    section.add "Action", valid_21627926
  var valid_21627927 = query.getOrDefault("UseLatestRestorableTime")
  valid_21627927 = validateParameter(valid_21627927, JBool, required = false,
                                   default = nil)
  if valid_21627927 != nil:
    section.add "UseLatestRestorableTime", valid_21627927
  var valid_21627928 = query.getOrDefault("DBSubnetGroupName")
  valid_21627928 = validateParameter(valid_21627928, JString, required = false,
                                   default = nil)
  if valid_21627928 != nil:
    section.add "DBSubnetGroupName", valid_21627928
  var valid_21627929 = query.getOrDefault("PubliclyAccessible")
  valid_21627929 = validateParameter(valid_21627929, JBool, required = false,
                                   default = nil)
  if valid_21627929 != nil:
    section.add "PubliclyAccessible", valid_21627929
  var valid_21627930 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627930 = validateParameter(valid_21627930, JBool, required = false,
                                   default = nil)
  if valid_21627930 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627930
  var valid_21627931 = query.getOrDefault("Port")
  valid_21627931 = validateParameter(valid_21627931, JInt, required = false,
                                   default = nil)
  if valid_21627931 != nil:
    section.add "Port", valid_21627931
  var valid_21627932 = query.getOrDefault("Version")
  valid_21627932 = validateParameter(valid_21627932, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627932 != nil:
    section.add "Version", valid_21627932
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
  var valid_21627933 = header.getOrDefault("X-Amz-Date")
  valid_21627933 = validateParameter(valid_21627933, JString, required = false,
                                   default = nil)
  if valid_21627933 != nil:
    section.add "X-Amz-Date", valid_21627933
  var valid_21627934 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627934 = validateParameter(valid_21627934, JString, required = false,
                                   default = nil)
  if valid_21627934 != nil:
    section.add "X-Amz-Security-Token", valid_21627934
  var valid_21627935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627935 = validateParameter(valid_21627935, JString, required = false,
                                   default = nil)
  if valid_21627935 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627935
  var valid_21627936 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627936 = validateParameter(valid_21627936, JString, required = false,
                                   default = nil)
  if valid_21627936 != nil:
    section.add "X-Amz-Algorithm", valid_21627936
  var valid_21627937 = header.getOrDefault("X-Amz-Signature")
  valid_21627937 = validateParameter(valid_21627937, JString, required = false,
                                   default = nil)
  if valid_21627937 != nil:
    section.add "X-Amz-Signature", valid_21627937
  var valid_21627938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627938 = validateParameter(valid_21627938, JString, required = false,
                                   default = nil)
  if valid_21627938 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627938
  var valid_21627939 = header.getOrDefault("X-Amz-Credential")
  valid_21627939 = validateParameter(valid_21627939, JString, required = false,
                                   default = nil)
  if valid_21627939 != nil:
    section.add "X-Amz-Credential", valid_21627939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627940: Call_GetRestoreDBInstanceToPointInTime_21627912;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627940.validator(path, query, header, formData, body, _)
  let scheme = call_21627940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627940.makeUrl(scheme.get, call_21627940.host, call_21627940.base,
                               call_21627940.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627940, uri, valid, _)

proc call*(call_21627941: Call_GetRestoreDBInstanceToPointInTime_21627912;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          OptionGroupName: string = ""; RestoreTime: string = ""; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-01-10"): Recallable =
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
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   UseLatestRestorableTime: bool
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  var query_21627942 = newJObject()
  add(query_21627942, "Engine", newJString(Engine))
  add(query_21627942, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_21627942, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_21627942, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21627942, "Iops", newJInt(Iops))
  add(query_21627942, "OptionGroupName", newJString(OptionGroupName))
  add(query_21627942, "RestoreTime", newJString(RestoreTime))
  add(query_21627942, "MultiAZ", newJBool(MultiAZ))
  add(query_21627942, "LicenseModel", newJString(LicenseModel))
  add(query_21627942, "DBName", newJString(DBName))
  add(query_21627942, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627942, "Action", newJString(Action))
  add(query_21627942, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_21627942, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627942, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21627942, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21627942, "Port", newJInt(Port))
  add(query_21627942, "Version", newJString(Version))
  result = call_21627941.call(nil, query_21627942, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_21627912(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_21627913, base: "/",
    makeUrl: url_GetRestoreDBInstanceToPointInTime_21627914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_21627995 = ref object of OpenApiRestCall_21625418
proc url_PostRevokeDBSecurityGroupIngress_21627997(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_21627996(path: JsonNode;
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
  var valid_21627998 = query.getOrDefault("Action")
  valid_21627998 = validateParameter(valid_21627998, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_21627998 != nil:
    section.add "Action", valid_21627998
  var valid_21627999 = query.getOrDefault("Version")
  valid_21627999 = validateParameter(valid_21627999, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627999 != nil:
    section.add "Version", valid_21627999
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
  var valid_21628000 = header.getOrDefault("X-Amz-Date")
  valid_21628000 = validateParameter(valid_21628000, JString, required = false,
                                   default = nil)
  if valid_21628000 != nil:
    section.add "X-Amz-Date", valid_21628000
  var valid_21628001 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628001 = validateParameter(valid_21628001, JString, required = false,
                                   default = nil)
  if valid_21628001 != nil:
    section.add "X-Amz-Security-Token", valid_21628001
  var valid_21628002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628002 = validateParameter(valid_21628002, JString, required = false,
                                   default = nil)
  if valid_21628002 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628002
  var valid_21628003 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628003 = validateParameter(valid_21628003, JString, required = false,
                                   default = nil)
  if valid_21628003 != nil:
    section.add "X-Amz-Algorithm", valid_21628003
  var valid_21628004 = header.getOrDefault("X-Amz-Signature")
  valid_21628004 = validateParameter(valid_21628004, JString, required = false,
                                   default = nil)
  if valid_21628004 != nil:
    section.add "X-Amz-Signature", valid_21628004
  var valid_21628005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628005 = validateParameter(valid_21628005, JString, required = false,
                                   default = nil)
  if valid_21628005 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628005
  var valid_21628006 = header.getOrDefault("X-Amz-Credential")
  valid_21628006 = validateParameter(valid_21628006, JString, required = false,
                                   default = nil)
  if valid_21628006 != nil:
    section.add "X-Amz-Credential", valid_21628006
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21628007 = formData.getOrDefault("DBSecurityGroupName")
  valid_21628007 = validateParameter(valid_21628007, JString, required = true,
                                   default = nil)
  if valid_21628007 != nil:
    section.add "DBSecurityGroupName", valid_21628007
  var valid_21628008 = formData.getOrDefault("EC2SecurityGroupName")
  valid_21628008 = validateParameter(valid_21628008, JString, required = false,
                                   default = nil)
  if valid_21628008 != nil:
    section.add "EC2SecurityGroupName", valid_21628008
  var valid_21628009 = formData.getOrDefault("EC2SecurityGroupId")
  valid_21628009 = validateParameter(valid_21628009, JString, required = false,
                                   default = nil)
  if valid_21628009 != nil:
    section.add "EC2SecurityGroupId", valid_21628009
  var valid_21628010 = formData.getOrDefault("CIDRIP")
  valid_21628010 = validateParameter(valid_21628010, JString, required = false,
                                   default = nil)
  if valid_21628010 != nil:
    section.add "CIDRIP", valid_21628010
  var valid_21628011 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21628011 = validateParameter(valid_21628011, JString, required = false,
                                   default = nil)
  if valid_21628011 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21628011
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628012: Call_PostRevokeDBSecurityGroupIngress_21627995;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628012.validator(path, query, header, formData, body, _)
  let scheme = call_21628012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628012.makeUrl(scheme.get, call_21628012.host, call_21628012.base,
                               call_21628012.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628012, uri, valid, _)

proc call*(call_21628013: Call_PostRevokeDBSecurityGroupIngress_21627995;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-01-10";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_21628014 = newJObject()
  var formData_21628015 = newJObject()
  add(formData_21628015, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21628014, "Action", newJString(Action))
  add(formData_21628015, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_21628015, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_21628015, "CIDRIP", newJString(CIDRIP))
  add(query_21628014, "Version", newJString(Version))
  add(formData_21628015, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_21628013.call(nil, query_21628014, nil, formData_21628015, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_21627995(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_21627996, base: "/",
    makeUrl: url_PostRevokeDBSecurityGroupIngress_21627997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_21627975 = ref object of OpenApiRestCall_21625418
proc url_GetRevokeDBSecurityGroupIngress_21627977(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_21627976(path: JsonNode;
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
  var valid_21627978 = query.getOrDefault("EC2SecurityGroupId")
  valid_21627978 = validateParameter(valid_21627978, JString, required = false,
                                   default = nil)
  if valid_21627978 != nil:
    section.add "EC2SecurityGroupId", valid_21627978
  var valid_21627979 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21627979 = validateParameter(valid_21627979, JString, required = false,
                                   default = nil)
  if valid_21627979 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21627979
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21627980 = query.getOrDefault("DBSecurityGroupName")
  valid_21627980 = validateParameter(valid_21627980, JString, required = true,
                                   default = nil)
  if valid_21627980 != nil:
    section.add "DBSecurityGroupName", valid_21627980
  var valid_21627981 = query.getOrDefault("Action")
  valid_21627981 = validateParameter(valid_21627981, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_21627981 != nil:
    section.add "Action", valid_21627981
  var valid_21627982 = query.getOrDefault("CIDRIP")
  valid_21627982 = validateParameter(valid_21627982, JString, required = false,
                                   default = nil)
  if valid_21627982 != nil:
    section.add "CIDRIP", valid_21627982
  var valid_21627983 = query.getOrDefault("EC2SecurityGroupName")
  valid_21627983 = validateParameter(valid_21627983, JString, required = false,
                                   default = nil)
  if valid_21627983 != nil:
    section.add "EC2SecurityGroupName", valid_21627983
  var valid_21627984 = query.getOrDefault("Version")
  valid_21627984 = validateParameter(valid_21627984, JString, required = true,
                                   default = newJString("2013-01-10"))
  if valid_21627984 != nil:
    section.add "Version", valid_21627984
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
  var valid_21627985 = header.getOrDefault("X-Amz-Date")
  valid_21627985 = validateParameter(valid_21627985, JString, required = false,
                                   default = nil)
  if valid_21627985 != nil:
    section.add "X-Amz-Date", valid_21627985
  var valid_21627986 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627986 = validateParameter(valid_21627986, JString, required = false,
                                   default = nil)
  if valid_21627986 != nil:
    section.add "X-Amz-Security-Token", valid_21627986
  var valid_21627987 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627987 = validateParameter(valid_21627987, JString, required = false,
                                   default = nil)
  if valid_21627987 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627987
  var valid_21627988 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627988 = validateParameter(valid_21627988, JString, required = false,
                                   default = nil)
  if valid_21627988 != nil:
    section.add "X-Amz-Algorithm", valid_21627988
  var valid_21627989 = header.getOrDefault("X-Amz-Signature")
  valid_21627989 = validateParameter(valid_21627989, JString, required = false,
                                   default = nil)
  if valid_21627989 != nil:
    section.add "X-Amz-Signature", valid_21627989
  var valid_21627990 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627990 = validateParameter(valid_21627990, JString, required = false,
                                   default = nil)
  if valid_21627990 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627990
  var valid_21627991 = header.getOrDefault("X-Amz-Credential")
  valid_21627991 = validateParameter(valid_21627991, JString, required = false,
                                   default = nil)
  if valid_21627991 != nil:
    section.add "X-Amz-Credential", valid_21627991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627992: Call_GetRevokeDBSecurityGroupIngress_21627975;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627992.validator(path, query, header, formData, body, _)
  let scheme = call_21627992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627992.makeUrl(scheme.get, call_21627992.host, call_21627992.base,
                               call_21627992.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627992, uri, valid, _)

proc call*(call_21627993: Call_GetRevokeDBSecurityGroupIngress_21627975;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_21627994 = newJObject()
  add(query_21627994, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_21627994, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_21627994, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21627994, "Action", newJString(Action))
  add(query_21627994, "CIDRIP", newJString(CIDRIP))
  add(query_21627994, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_21627994, "Version", newJString(Version))
  result = call_21627993.call(nil, query_21627994, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_21627975(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_21627976, base: "/",
    makeUrl: url_GetRevokeDBSecurityGroupIngress_21627977,
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
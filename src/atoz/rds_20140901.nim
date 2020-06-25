
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
                                   default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                   default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                   default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                   default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                   default = newJString("2014-09-01"))
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
          CIDRIP: string = ""; Version: string = "2014-09-01";
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
                                   default = newJString("2014-09-01"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
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
  Call_PostCopyDBParameterGroup_21626132 = ref object of OpenApiRestCall_21625418
proc url_PostCopyDBParameterGroup_21626134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBParameterGroup_21626133(path: JsonNode; query: JsonNode;
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
  var valid_21626135 = query.getOrDefault("Action")
  valid_21626135 = validateParameter(valid_21626135, JString, required = true,
                                   default = newJString("CopyDBParameterGroup"))
  if valid_21626135 != nil:
    section.add "Action", valid_21626135
  var valid_21626136 = query.getOrDefault("Version")
  valid_21626136 = validateParameter(valid_21626136, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626136 != nil:
    section.add "Version", valid_21626136
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
  var valid_21626137 = header.getOrDefault("X-Amz-Date")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Date", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Security-Token", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Algorithm", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Signature")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Signature", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Credential")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Credential", valid_21626143
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_21626144 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_21626144 = validateParameter(valid_21626144, JString, required = true,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_21626144
  var valid_21626145 = formData.getOrDefault("Tags")
  valid_21626145 = validateParameter(valid_21626145, JArray, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "Tags", valid_21626145
  var valid_21626146 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_21626146 = validateParameter(valid_21626146, JString, required = true,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "TargetDBParameterGroupDescription", valid_21626146
  var valid_21626147 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_21626147 = validateParameter(valid_21626147, JString, required = true,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_21626147
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626148: Call_PostCopyDBParameterGroup_21626132;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626148.validator(path, query, header, formData, body, _)
  let scheme = call_21626148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626148.makeUrl(scheme.get, call_21626148.host, call_21626148.base,
                               call_21626148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626148, uri, valid, _)

proc call*(call_21626149: Call_PostCopyDBParameterGroup_21626132;
          TargetDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          SourceDBParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCopyDBParameterGroup
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Version: string (required)
  var query_21626150 = newJObject()
  var formData_21626151 = newJObject()
  add(formData_21626151, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_21626151.add "Tags", Tags
  add(query_21626150, "Action", newJString(Action))
  add(formData_21626151, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_21626151, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_21626150, "Version", newJString(Version))
  result = call_21626149.call(nil, query_21626150, nil, formData_21626151, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_21626132(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_21626133, base: "/",
    makeUrl: url_PostCopyDBParameterGroup_21626134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_21626113 = ref object of OpenApiRestCall_21625418
proc url_GetCopyDBParameterGroup_21626115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBParameterGroup_21626114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   Version: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   TargetDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  var valid_21626116 = query.getOrDefault("Tags")
  valid_21626116 = validateParameter(valid_21626116, JArray, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "Tags", valid_21626116
  var valid_21626117 = query.getOrDefault("Action")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = newJString("CopyDBParameterGroup"))
  if valid_21626117 != nil:
    section.add "Action", valid_21626117
  var valid_21626118 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_21626118
  var valid_21626119 = query.getOrDefault("Version")
  valid_21626119 = validateParameter(valid_21626119, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626119 != nil:
    section.add "Version", valid_21626119
  var valid_21626120 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_21626120 = validateParameter(valid_21626120, JString, required = true,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "TargetDBParameterGroupDescription", valid_21626120
  var valid_21626121 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_21626121 = validateParameter(valid_21626121, JString, required = true,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_21626121
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
  var valid_21626122 = header.getOrDefault("X-Amz-Date")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Date", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Security-Token", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Algorithm", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Signature")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Signature", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626127
  var valid_21626128 = header.getOrDefault("X-Amz-Credential")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "X-Amz-Credential", valid_21626128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626129: Call_GetCopyDBParameterGroup_21626113;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626129.validator(path, query, header, formData, body, _)
  let scheme = call_21626129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626129.makeUrl(scheme.get, call_21626129.host, call_21626129.base,
                               call_21626129.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626129, uri, valid, _)

proc call*(call_21626130: Call_GetCopyDBParameterGroup_21626113;
          SourceDBParameterGroupIdentifier: string;
          TargetDBParameterGroupDescription: string;
          TargetDBParameterGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyDBParameterGroup
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Version: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   TargetDBParameterGroupIdentifier: string (required)
  var query_21626131 = newJObject()
  if Tags != nil:
    query_21626131.add "Tags", Tags
  add(query_21626131, "Action", newJString(Action))
  add(query_21626131, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_21626131, "Version", newJString(Version))
  add(query_21626131, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_21626131, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_21626130.call(nil, query_21626131, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_21626113(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_21626114, base: "/",
    makeUrl: url_GetCopyDBParameterGroup_21626115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_21626170 = ref object of OpenApiRestCall_21625418
proc url_PostCopyDBSnapshot_21626172(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_21626171(path: JsonNode; query: JsonNode;
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
  var valid_21626173 = query.getOrDefault("Action")
  valid_21626173 = validateParameter(valid_21626173, JString, required = true,
                                   default = newJString("CopyDBSnapshot"))
  if valid_21626173 != nil:
    section.add "Action", valid_21626173
  var valid_21626174 = query.getOrDefault("Version")
  valid_21626174 = validateParameter(valid_21626174, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626174 != nil:
    section.add "Version", valid_21626174
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
  var valid_21626175 = header.getOrDefault("X-Amz-Date")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Date", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Security-Token", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Algorithm", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Signature")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Signature", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Credential")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Credential", valid_21626181
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_21626182 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_21626182 = validateParameter(valid_21626182, JString, required = true,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_21626182
  var valid_21626183 = formData.getOrDefault("Tags")
  valid_21626183 = validateParameter(valid_21626183, JArray, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "Tags", valid_21626183
  var valid_21626184 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_21626184 = validateParameter(valid_21626184, JString, required = true,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_21626184
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626185: Call_PostCopyDBSnapshot_21626170; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626185.validator(path, query, header, formData, body, _)
  let scheme = call_21626185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626185.makeUrl(scheme.get, call_21626185.host, call_21626185.base,
                               call_21626185.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626185, uri, valid, _)

proc call*(call_21626186: Call_PostCopyDBSnapshot_21626170;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_21626187 = newJObject()
  var formData_21626188 = newJObject()
  add(formData_21626188, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_21626188.add "Tags", Tags
  add(query_21626187, "Action", newJString(Action))
  add(formData_21626188, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_21626187, "Version", newJString(Version))
  result = call_21626186.call(nil, query_21626187, nil, formData_21626188, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_21626170(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_21626171, base: "/",
    makeUrl: url_PostCopyDBSnapshot_21626172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_21626152 = ref object of OpenApiRestCall_21625418
proc url_GetCopyDBSnapshot_21626154(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_21626153(path: JsonNode; query: JsonNode;
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
  var valid_21626155 = query.getOrDefault("Tags")
  valid_21626155 = validateParameter(valid_21626155, JArray, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "Tags", valid_21626155
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_21626156 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_21626156 = validateParameter(valid_21626156, JString, required = true,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_21626156
  var valid_21626157 = query.getOrDefault("Action")
  valid_21626157 = validateParameter(valid_21626157, JString, required = true,
                                   default = newJString("CopyDBSnapshot"))
  if valid_21626157 != nil:
    section.add "Action", valid_21626157
  var valid_21626158 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_21626158 = validateParameter(valid_21626158, JString, required = true,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_21626158
  var valid_21626159 = query.getOrDefault("Version")
  valid_21626159 = validateParameter(valid_21626159, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626159 != nil:
    section.add "Version", valid_21626159
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
  var valid_21626160 = header.getOrDefault("X-Amz-Date")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-Date", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Security-Token", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Algorithm", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Signature")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Signature", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Credential")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Credential", valid_21626166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626167: Call_GetCopyDBSnapshot_21626152; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626167.validator(path, query, header, formData, body, _)
  let scheme = call_21626167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626167.makeUrl(scheme.get, call_21626167.host, call_21626167.base,
                               call_21626167.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626167, uri, valid, _)

proc call*(call_21626168: Call_GetCopyDBSnapshot_21626152;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_21626169 = newJObject()
  if Tags != nil:
    query_21626169.add "Tags", Tags
  add(query_21626169, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_21626169, "Action", newJString(Action))
  add(query_21626169, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_21626169, "Version", newJString(Version))
  result = call_21626168.call(nil, query_21626169, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_21626152(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_21626153,
    base: "/", makeUrl: url_GetCopyDBSnapshot_21626154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_21626208 = ref object of OpenApiRestCall_21625418
proc url_PostCopyOptionGroup_21626210(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyOptionGroup_21626209(path: JsonNode; query: JsonNode;
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
  var valid_21626211 = query.getOrDefault("Action")
  valid_21626211 = validateParameter(valid_21626211, JString, required = true,
                                   default = newJString("CopyOptionGroup"))
  if valid_21626211 != nil:
    section.add "Action", valid_21626211
  var valid_21626212 = query.getOrDefault("Version")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626212 != nil:
    section.add "Version", valid_21626212
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
  var valid_21626213 = header.getOrDefault("X-Amz-Date")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Date", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Security-Token", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_21626220 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_21626220 = validateParameter(valid_21626220, JString, required = true,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "TargetOptionGroupDescription", valid_21626220
  var valid_21626221 = formData.getOrDefault("Tags")
  valid_21626221 = validateParameter(valid_21626221, JArray, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "Tags", valid_21626221
  var valid_21626222 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "SourceOptionGroupIdentifier", valid_21626222
  var valid_21626223 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_21626223 = validateParameter(valid_21626223, JString, required = true,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "TargetOptionGroupIdentifier", valid_21626223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626224: Call_PostCopyOptionGroup_21626208; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626224.validator(path, query, header, formData, body, _)
  let scheme = call_21626224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626224.makeUrl(scheme.get, call_21626224.host, call_21626224.base,
                               call_21626224.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626224, uri, valid, _)

proc call*(call_21626225: Call_PostCopyOptionGroup_21626208;
          TargetOptionGroupDescription: string;
          SourceOptionGroupIdentifier: string;
          TargetOptionGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCopyOptionGroup
  ##   TargetOptionGroupDescription: string (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetOptionGroupIdentifier: string (required)
  ##   Version: string (required)
  var query_21626226 = newJObject()
  var formData_21626227 = newJObject()
  add(formData_21626227, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_21626227.add "Tags", Tags
  add(formData_21626227, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_21626226, "Action", newJString(Action))
  add(formData_21626227, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_21626226, "Version", newJString(Version))
  result = call_21626225.call(nil, query_21626226, nil, formData_21626227, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_21626208(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_21626209, base: "/",
    makeUrl: url_PostCopyOptionGroup_21626210,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_21626189 = ref object of OpenApiRestCall_21625418
proc url_GetCopyOptionGroup_21626191(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyOptionGroup_21626190(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   TargetOptionGroupDescription: JString (required)
  ##   Version: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceOptionGroupIdentifier` field"
  var valid_21626192 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_21626192 = validateParameter(valid_21626192, JString, required = true,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "SourceOptionGroupIdentifier", valid_21626192
  var valid_21626193 = query.getOrDefault("Tags")
  valid_21626193 = validateParameter(valid_21626193, JArray, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "Tags", valid_21626193
  var valid_21626194 = query.getOrDefault("Action")
  valid_21626194 = validateParameter(valid_21626194, JString, required = true,
                                   default = newJString("CopyOptionGroup"))
  if valid_21626194 != nil:
    section.add "Action", valid_21626194
  var valid_21626195 = query.getOrDefault("TargetOptionGroupDescription")
  valid_21626195 = validateParameter(valid_21626195, JString, required = true,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "TargetOptionGroupDescription", valid_21626195
  var valid_21626196 = query.getOrDefault("Version")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626196 != nil:
    section.add "Version", valid_21626196
  var valid_21626197 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "TargetOptionGroupIdentifier", valid_21626197
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
  var valid_21626198 = header.getOrDefault("X-Amz-Date")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Date", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Security-Token", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626205: Call_GetCopyOptionGroup_21626189; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_GetCopyOptionGroup_21626189;
          SourceOptionGroupIdentifier: string;
          TargetOptionGroupDescription: string;
          TargetOptionGroupIdentifier: string; Tags: JsonNode = nil;
          Action: string = "CopyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCopyOptionGroup
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   TargetOptionGroupDescription: string (required)
  ##   Version: string (required)
  ##   TargetOptionGroupIdentifier: string (required)
  var query_21626207 = newJObject()
  add(query_21626207, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_21626207.add "Tags", Tags
  add(query_21626207, "Action", newJString(Action))
  add(query_21626207, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_21626207, "Version", newJString(Version))
  add(query_21626207, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_21626206.call(nil, query_21626207, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_21626189(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_21626190,
    base: "/", makeUrl: url_GetCopyOptionGroup_21626191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_21626271 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBInstance_21626273(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_21626272(path: JsonNode; query: JsonNode;
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
  var valid_21626274 = query.getOrDefault("Action")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626274 != nil:
    section.add "Action", valid_21626274
  var valid_21626275 = query.getOrDefault("Version")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626275 != nil:
    section.add "Version", valid_21626275
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
  var valid_21626276 = header.getOrDefault("X-Amz-Date")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Date", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Security-Token", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Algorithm", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Signature")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Signature", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Credential")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Credential", valid_21626282
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
  ##   TdeCredentialArn: JString
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialPassword: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt (required)
  ##   PubliclyAccessible: JBool
  ##   MasterUsername: JString (required)
  ##   StorageType: JString
  ##   DBInstanceClass: JString (required)
  ##   CharacterSetName: JString
  ##   PreferredBackupWindow: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredMaintenanceWindow: JString
  section = newJObject()
  var valid_21626283 = formData.getOrDefault("DBSecurityGroups")
  valid_21626283 = validateParameter(valid_21626283, JArray, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "DBSecurityGroups", valid_21626283
  var valid_21626284 = formData.getOrDefault("Port")
  valid_21626284 = validateParameter(valid_21626284, JInt, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "Port", valid_21626284
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21626285 = formData.getOrDefault("Engine")
  valid_21626285 = validateParameter(valid_21626285, JString, required = true,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "Engine", valid_21626285
  var valid_21626286 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21626286 = validateParameter(valid_21626286, JArray, required = false,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "VpcSecurityGroupIds", valid_21626286
  var valid_21626287 = formData.getOrDefault("Iops")
  valid_21626287 = validateParameter(valid_21626287, JInt, required = false,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "Iops", valid_21626287
  var valid_21626288 = formData.getOrDefault("DBName")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "DBName", valid_21626288
  var valid_21626289 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "DBInstanceIdentifier", valid_21626289
  var valid_21626290 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21626290 = validateParameter(valid_21626290, JInt, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "BackupRetentionPeriod", valid_21626290
  var valid_21626291 = formData.getOrDefault("DBParameterGroupName")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "DBParameterGroupName", valid_21626291
  var valid_21626292 = formData.getOrDefault("OptionGroupName")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "OptionGroupName", valid_21626292
  var valid_21626293 = formData.getOrDefault("Tags")
  valid_21626293 = validateParameter(valid_21626293, JArray, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "Tags", valid_21626293
  var valid_21626294 = formData.getOrDefault("MasterUserPassword")
  valid_21626294 = validateParameter(valid_21626294, JString, required = true,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "MasterUserPassword", valid_21626294
  var valid_21626295 = formData.getOrDefault("TdeCredentialArn")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "TdeCredentialArn", valid_21626295
  var valid_21626296 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "DBSubnetGroupName", valid_21626296
  var valid_21626297 = formData.getOrDefault("TdeCredentialPassword")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "TdeCredentialPassword", valid_21626297
  var valid_21626298 = formData.getOrDefault("AvailabilityZone")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "AvailabilityZone", valid_21626298
  var valid_21626299 = formData.getOrDefault("MultiAZ")
  valid_21626299 = validateParameter(valid_21626299, JBool, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "MultiAZ", valid_21626299
  var valid_21626300 = formData.getOrDefault("AllocatedStorage")
  valid_21626300 = validateParameter(valid_21626300, JInt, required = true,
                                   default = nil)
  if valid_21626300 != nil:
    section.add "AllocatedStorage", valid_21626300
  var valid_21626301 = formData.getOrDefault("PubliclyAccessible")
  valid_21626301 = validateParameter(valid_21626301, JBool, required = false,
                                   default = nil)
  if valid_21626301 != nil:
    section.add "PubliclyAccessible", valid_21626301
  var valid_21626302 = formData.getOrDefault("MasterUsername")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "MasterUsername", valid_21626302
  var valid_21626303 = formData.getOrDefault("StorageType")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "StorageType", valid_21626303
  var valid_21626304 = formData.getOrDefault("DBInstanceClass")
  valid_21626304 = validateParameter(valid_21626304, JString, required = true,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "DBInstanceClass", valid_21626304
  var valid_21626305 = formData.getOrDefault("CharacterSetName")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "CharacterSetName", valid_21626305
  var valid_21626306 = formData.getOrDefault("PreferredBackupWindow")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "PreferredBackupWindow", valid_21626306
  var valid_21626307 = formData.getOrDefault("LicenseModel")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "LicenseModel", valid_21626307
  var valid_21626308 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626308 = validateParameter(valid_21626308, JBool, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626308
  var valid_21626309 = formData.getOrDefault("EngineVersion")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "EngineVersion", valid_21626309
  var valid_21626310 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626310
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626311: Call_PostCreateDBInstance_21626271; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_PostCreateDBInstance_21626271; Engine: string;
          DBInstanceIdentifier: string; MasterUserPassword: string;
          AllocatedStorage: int; MasterUsername: string; DBInstanceClass: string;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0; DBName: string = "";
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          TdeCredentialArn: string = ""; DBSubnetGroupName: string = "";
          TdeCredentialPassword: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "CreateDBInstance";
          PubliclyAccessible: bool = false; StorageType: string = "";
          CharacterSetName: string = ""; PreferredBackupWindow: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Version: string = "2014-09-01";
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
  ##   Tags: JArray
  ##   MasterUserPassword: string (required)
  ##   TdeCredentialArn: string
  ##   DBSubnetGroupName: string
  ##   TdeCredentialPassword: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int (required)
  ##   PubliclyAccessible: bool
  ##   MasterUsername: string (required)
  ##   StorageType: string
  ##   DBInstanceClass: string (required)
  ##   CharacterSetName: string
  ##   PreferredBackupWindow: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  var query_21626313 = newJObject()
  var formData_21626314 = newJObject()
  if DBSecurityGroups != nil:
    formData_21626314.add "DBSecurityGroups", DBSecurityGroups
  add(formData_21626314, "Port", newJInt(Port))
  add(formData_21626314, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_21626314.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21626314, "Iops", newJInt(Iops))
  add(formData_21626314, "DBName", newJString(DBName))
  add(formData_21626314, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626314, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_21626314, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21626314, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21626314.add "Tags", Tags
  add(formData_21626314, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21626314, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_21626314, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21626314, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_21626314, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21626314, "MultiAZ", newJBool(MultiAZ))
  add(query_21626313, "Action", newJString(Action))
  add(formData_21626314, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_21626314, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21626314, "MasterUsername", newJString(MasterUsername))
  add(formData_21626314, "StorageType", newJString(StorageType))
  add(formData_21626314, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21626314, "CharacterSetName", newJString(CharacterSetName))
  add(formData_21626314, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21626314, "LicenseModel", newJString(LicenseModel))
  add(formData_21626314, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_21626314, "EngineVersion", newJString(EngineVersion))
  add(query_21626313, "Version", newJString(Version))
  add(formData_21626314, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_21626312.call(nil, query_21626313, nil, formData_21626314, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_21626271(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_21626272, base: "/",
    makeUrl: url_PostCreateDBInstance_21626273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_21626228 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBInstance_21626230(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_21626229(path: JsonNode; query: JsonNode;
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
  ##   StorageType: JString
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   LicenseModel: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBName: JString
  ##   DBParameterGroupName: JString
  ##   Tags: JArray
  ##   DBInstanceClass: JString (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   CharacterSetName: JString
  ##   TdeCredentialArn: JString
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
  var valid_21626231 = query.getOrDefault("Engine")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "Engine", valid_21626231
  var valid_21626232 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626232
  var valid_21626233 = query.getOrDefault("AllocatedStorage")
  valid_21626233 = validateParameter(valid_21626233, JInt, required = true,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "AllocatedStorage", valid_21626233
  var valid_21626234 = query.getOrDefault("StorageType")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "StorageType", valid_21626234
  var valid_21626235 = query.getOrDefault("OptionGroupName")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "OptionGroupName", valid_21626235
  var valid_21626236 = query.getOrDefault("DBSecurityGroups")
  valid_21626236 = validateParameter(valid_21626236, JArray, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "DBSecurityGroups", valid_21626236
  var valid_21626237 = query.getOrDefault("MasterUserPassword")
  valid_21626237 = validateParameter(valid_21626237, JString, required = true,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "MasterUserPassword", valid_21626237
  var valid_21626238 = query.getOrDefault("AvailabilityZone")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "AvailabilityZone", valid_21626238
  var valid_21626239 = query.getOrDefault("Iops")
  valid_21626239 = validateParameter(valid_21626239, JInt, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "Iops", valid_21626239
  var valid_21626240 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21626240 = validateParameter(valid_21626240, JArray, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "VpcSecurityGroupIds", valid_21626240
  var valid_21626241 = query.getOrDefault("MultiAZ")
  valid_21626241 = validateParameter(valid_21626241, JBool, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "MultiAZ", valid_21626241
  var valid_21626242 = query.getOrDefault("TdeCredentialPassword")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "TdeCredentialPassword", valid_21626242
  var valid_21626243 = query.getOrDefault("LicenseModel")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "LicenseModel", valid_21626243
  var valid_21626244 = query.getOrDefault("BackupRetentionPeriod")
  valid_21626244 = validateParameter(valid_21626244, JInt, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "BackupRetentionPeriod", valid_21626244
  var valid_21626245 = query.getOrDefault("DBName")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "DBName", valid_21626245
  var valid_21626246 = query.getOrDefault("DBParameterGroupName")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "DBParameterGroupName", valid_21626246
  var valid_21626247 = query.getOrDefault("Tags")
  valid_21626247 = validateParameter(valid_21626247, JArray, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "Tags", valid_21626247
  var valid_21626248 = query.getOrDefault("DBInstanceClass")
  valid_21626248 = validateParameter(valid_21626248, JString, required = true,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "DBInstanceClass", valid_21626248
  var valid_21626249 = query.getOrDefault("Action")
  valid_21626249 = validateParameter(valid_21626249, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626249 != nil:
    section.add "Action", valid_21626249
  var valid_21626250 = query.getOrDefault("DBSubnetGroupName")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "DBSubnetGroupName", valid_21626250
  var valid_21626251 = query.getOrDefault("CharacterSetName")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "CharacterSetName", valid_21626251
  var valid_21626252 = query.getOrDefault("TdeCredentialArn")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "TdeCredentialArn", valid_21626252
  var valid_21626253 = query.getOrDefault("PubliclyAccessible")
  valid_21626253 = validateParameter(valid_21626253, JBool, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "PubliclyAccessible", valid_21626253
  var valid_21626254 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626254 = validateParameter(valid_21626254, JBool, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626254
  var valid_21626255 = query.getOrDefault("EngineVersion")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "EngineVersion", valid_21626255
  var valid_21626256 = query.getOrDefault("Port")
  valid_21626256 = validateParameter(valid_21626256, JInt, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "Port", valid_21626256
  var valid_21626257 = query.getOrDefault("PreferredBackupWindow")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "PreferredBackupWindow", valid_21626257
  var valid_21626258 = query.getOrDefault("Version")
  valid_21626258 = validateParameter(valid_21626258, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626258 != nil:
    section.add "Version", valid_21626258
  var valid_21626259 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626259 = validateParameter(valid_21626259, JString, required = true,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "DBInstanceIdentifier", valid_21626259
  var valid_21626260 = query.getOrDefault("MasterUsername")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "MasterUsername", valid_21626260
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
  var valid_21626261 = header.getOrDefault("X-Amz-Date")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Date", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Security-Token", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Algorithm", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Signature")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Signature", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Credential")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Credential", valid_21626267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626268: Call_GetCreateDBInstance_21626228; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626268.validator(path, query, header, formData, body, _)
  let scheme = call_21626268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626268.makeUrl(scheme.get, call_21626268.host, call_21626268.base,
                               call_21626268.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626268, uri, valid, _)

proc call*(call_21626269: Call_GetCreateDBInstance_21626228; Engine: string;
          AllocatedStorage: int; MasterUserPassword: string;
          DBInstanceClass: string; DBInstanceIdentifier: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          StorageType: string = ""; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; AvailabilityZone: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          TdeCredentialPassword: string = ""; LicenseModel: string = "";
          BackupRetentionPeriod: int = 0; DBName: string = "";
          DBParameterGroupName: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance"; DBSubnetGroupName: string = "";
          CharacterSetName: string = ""; TdeCredentialArn: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBInstance
  ##   Engine: string (required)
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int (required)
  ##   StorageType: string
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   LicenseModel: string
  ##   BackupRetentionPeriod: int
  ##   DBName: string
  ##   DBParameterGroupName: string
  ##   Tags: JArray
  ##   DBInstanceClass: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   CharacterSetName: string
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Port: int
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  var query_21626270 = newJObject()
  add(query_21626270, "Engine", newJString(Engine))
  add(query_21626270, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21626270, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_21626270, "StorageType", newJString(StorageType))
  add(query_21626270, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_21626270.add "DBSecurityGroups", DBSecurityGroups
  add(query_21626270, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_21626270, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626270, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_21626270.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_21626270, "MultiAZ", newJBool(MultiAZ))
  add(query_21626270, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_21626270, "LicenseModel", newJString(LicenseModel))
  add(query_21626270, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21626270, "DBName", newJString(DBName))
  add(query_21626270, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_21626270.add "Tags", Tags
  add(query_21626270, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21626270, "Action", newJString(Action))
  add(query_21626270, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626270, "CharacterSetName", newJString(CharacterSetName))
  add(query_21626270, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_21626270, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21626270, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21626270, "EngineVersion", newJString(EngineVersion))
  add(query_21626270, "Port", newJInt(Port))
  add(query_21626270, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21626270, "Version", newJString(Version))
  add(query_21626270, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626270, "MasterUsername", newJString(MasterUsername))
  result = call_21626269.call(nil, query_21626270, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_21626228(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_21626229, base: "/",
    makeUrl: url_GetCreateDBInstance_21626230,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_21626342 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBInstanceReadReplica_21626344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_21626343(path: JsonNode;
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
  var valid_21626345 = query.getOrDefault("Action")
  valid_21626345 = validateParameter(valid_21626345, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_21626345 != nil:
    section.add "Action", valid_21626345
  var valid_21626346 = query.getOrDefault("Version")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626346 != nil:
    section.add "Version", valid_21626346
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
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Algorithm", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Signature")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Signature", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Credential")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Credential", valid_21626353
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
  ##   StorageType: JString
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21626354 = formData.getOrDefault("Port")
  valid_21626354 = validateParameter(valid_21626354, JInt, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "Port", valid_21626354
  var valid_21626355 = formData.getOrDefault("Iops")
  valid_21626355 = validateParameter(valid_21626355, JInt, required = false,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "Iops", valid_21626355
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626356 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626356 = validateParameter(valid_21626356, JString, required = true,
                                   default = nil)
  if valid_21626356 != nil:
    section.add "DBInstanceIdentifier", valid_21626356
  var valid_21626357 = formData.getOrDefault("OptionGroupName")
  valid_21626357 = validateParameter(valid_21626357, JString, required = false,
                                   default = nil)
  if valid_21626357 != nil:
    section.add "OptionGroupName", valid_21626357
  var valid_21626358 = formData.getOrDefault("Tags")
  valid_21626358 = validateParameter(valid_21626358, JArray, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "Tags", valid_21626358
  var valid_21626359 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "DBSubnetGroupName", valid_21626359
  var valid_21626360 = formData.getOrDefault("AvailabilityZone")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "AvailabilityZone", valid_21626360
  var valid_21626361 = formData.getOrDefault("PubliclyAccessible")
  valid_21626361 = validateParameter(valid_21626361, JBool, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "PubliclyAccessible", valid_21626361
  var valid_21626362 = formData.getOrDefault("StorageType")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "StorageType", valid_21626362
  var valid_21626363 = formData.getOrDefault("DBInstanceClass")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "DBInstanceClass", valid_21626363
  var valid_21626364 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21626364
  var valid_21626365 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626365 = validateParameter(valid_21626365, JBool, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626365
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626366: Call_PostCreateDBInstanceReadReplica_21626342;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626366.validator(path, query, header, formData, body, _)
  let scheme = call_21626366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626366.makeUrl(scheme.get, call_21626366.host, call_21626366.base,
                               call_21626366.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626366, uri, valid, _)

proc call*(call_21626367: Call_PostCreateDBInstanceReadReplica_21626342;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; StorageType: string = "";
          DBInstanceClass: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-09-01"): Recallable =
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
  ##   StorageType: string
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_21626368 = newJObject()
  var formData_21626369 = newJObject()
  add(formData_21626369, "Port", newJInt(Port))
  add(formData_21626369, "Iops", newJInt(Iops))
  add(formData_21626369, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626369, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21626369.add "Tags", Tags
  add(formData_21626369, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21626369, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626368, "Action", newJString(Action))
  add(formData_21626369, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21626369, "StorageType", newJString(StorageType))
  add(formData_21626369, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21626369, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_21626369, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21626368, "Version", newJString(Version))
  result = call_21626367.call(nil, query_21626368, nil, formData_21626369, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_21626342(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_21626343, base: "/",
    makeUrl: url_PostCreateDBInstanceReadReplica_21626344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_21626315 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBInstanceReadReplica_21626317(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_21626316(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   StorageType: JString
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
  var valid_21626318 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21626318
  var valid_21626319 = query.getOrDefault("StorageType")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "StorageType", valid_21626319
  var valid_21626320 = query.getOrDefault("OptionGroupName")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "OptionGroupName", valid_21626320
  var valid_21626321 = query.getOrDefault("AvailabilityZone")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "AvailabilityZone", valid_21626321
  var valid_21626322 = query.getOrDefault("Iops")
  valid_21626322 = validateParameter(valid_21626322, JInt, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "Iops", valid_21626322
  var valid_21626323 = query.getOrDefault("Tags")
  valid_21626323 = validateParameter(valid_21626323, JArray, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "Tags", valid_21626323
  var valid_21626324 = query.getOrDefault("DBInstanceClass")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "DBInstanceClass", valid_21626324
  var valid_21626325 = query.getOrDefault("Action")
  valid_21626325 = validateParameter(valid_21626325, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_21626325 != nil:
    section.add "Action", valid_21626325
  var valid_21626326 = query.getOrDefault("DBSubnetGroupName")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "DBSubnetGroupName", valid_21626326
  var valid_21626327 = query.getOrDefault("PubliclyAccessible")
  valid_21626327 = validateParameter(valid_21626327, JBool, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "PubliclyAccessible", valid_21626327
  var valid_21626328 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626328 = validateParameter(valid_21626328, JBool, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626328
  var valid_21626329 = query.getOrDefault("Port")
  valid_21626329 = validateParameter(valid_21626329, JInt, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "Port", valid_21626329
  var valid_21626330 = query.getOrDefault("Version")
  valid_21626330 = validateParameter(valid_21626330, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626330 != nil:
    section.add "Version", valid_21626330
  var valid_21626331 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626331 = validateParameter(valid_21626331, JString, required = true,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "DBInstanceIdentifier", valid_21626331
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
  var valid_21626332 = header.getOrDefault("X-Amz-Date")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Date", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Security-Token", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Algorithm", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Signature")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Signature", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Credential")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Credential", valid_21626338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626339: Call_GetCreateDBInstanceReadReplica_21626315;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626339.validator(path, query, header, formData, body, _)
  let scheme = call_21626339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626339.makeUrl(scheme.get, call_21626339.host, call_21626339.base,
                               call_21626339.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626339, uri, valid, _)

proc call*(call_21626340: Call_GetCreateDBInstanceReadReplica_21626315;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          StorageType: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; Tags: JsonNode = nil;
          DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   SourceDBInstanceIdentifier: string (required)
  ##   StorageType: string
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
  var query_21626341 = newJObject()
  add(query_21626341, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_21626341, "StorageType", newJString(StorageType))
  add(query_21626341, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626341, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626341, "Iops", newJInt(Iops))
  if Tags != nil:
    query_21626341.add "Tags", Tags
  add(query_21626341, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21626341, "Action", newJString(Action))
  add(query_21626341, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626341, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21626341, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21626341, "Port", newJInt(Port))
  add(query_21626341, "Version", newJString(Version))
  add(query_21626341, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626340.call(nil, query_21626341, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_21626315(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_21626316, base: "/",
    makeUrl: url_GetCreateDBInstanceReadReplica_21626317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_21626389 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBParameterGroup_21626391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_21626390(path: JsonNode; query: JsonNode;
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
  var valid_21626392 = query.getOrDefault("Action")
  valid_21626392 = validateParameter(valid_21626392, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_21626392 != nil:
    section.add "Action", valid_21626392
  var valid_21626393 = query.getOrDefault("Version")
  valid_21626393 = validateParameter(valid_21626393, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626393 != nil:
    section.add "Version", valid_21626393
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
  var valid_21626394 = header.getOrDefault("X-Amz-Date")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Date", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Security-Token", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Algorithm", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-Signature")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-Signature", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626399
  var valid_21626400 = header.getOrDefault("X-Amz-Credential")
  valid_21626400 = validateParameter(valid_21626400, JString, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "X-Amz-Credential", valid_21626400
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626401 = formData.getOrDefault("DBParameterGroupName")
  valid_21626401 = validateParameter(valid_21626401, JString, required = true,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "DBParameterGroupName", valid_21626401
  var valid_21626402 = formData.getOrDefault("Tags")
  valid_21626402 = validateParameter(valid_21626402, JArray, required = false,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "Tags", valid_21626402
  var valid_21626403 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626403 = validateParameter(valid_21626403, JString, required = true,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "DBParameterGroupFamily", valid_21626403
  var valid_21626404 = formData.getOrDefault("Description")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "Description", valid_21626404
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626405: Call_PostCreateDBParameterGroup_21626389;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626405.validator(path, query, header, formData, body, _)
  let scheme = call_21626405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626405.makeUrl(scheme.get, call_21626405.host, call_21626405.base,
                               call_21626405.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626405, uri, valid, _)

proc call*(call_21626406: Call_PostCreateDBParameterGroup_21626389;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_21626407 = newJObject()
  var formData_21626408 = newJObject()
  add(formData_21626408, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_21626408.add "Tags", Tags
  add(query_21626407, "Action", newJString(Action))
  add(formData_21626408, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_21626407, "Version", newJString(Version))
  add(formData_21626408, "Description", newJString(Description))
  result = call_21626406.call(nil, query_21626407, nil, formData_21626408, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_21626389(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_21626390, base: "/",
    makeUrl: url_PostCreateDBParameterGroup_21626391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_21626370 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBParameterGroup_21626372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_21626371(path: JsonNode; query: JsonNode;
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
  var valid_21626373 = query.getOrDefault("Description")
  valid_21626373 = validateParameter(valid_21626373, JString, required = true,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "Description", valid_21626373
  var valid_21626374 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626374 = validateParameter(valid_21626374, JString, required = true,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "DBParameterGroupFamily", valid_21626374
  var valid_21626375 = query.getOrDefault("Tags")
  valid_21626375 = validateParameter(valid_21626375, JArray, required = false,
                                   default = nil)
  if valid_21626375 != nil:
    section.add "Tags", valid_21626375
  var valid_21626376 = query.getOrDefault("DBParameterGroupName")
  valid_21626376 = validateParameter(valid_21626376, JString, required = true,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "DBParameterGroupName", valid_21626376
  var valid_21626377 = query.getOrDefault("Action")
  valid_21626377 = validateParameter(valid_21626377, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_21626377 != nil:
    section.add "Action", valid_21626377
  var valid_21626378 = query.getOrDefault("Version")
  valid_21626378 = validateParameter(valid_21626378, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626378 != nil:
    section.add "Version", valid_21626378
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
  var valid_21626379 = header.getOrDefault("X-Amz-Date")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Date", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Security-Token", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Algorithm", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Signature")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Signature", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Credential")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Credential", valid_21626385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626386: Call_GetCreateDBParameterGroup_21626370;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626386.validator(path, query, header, formData, body, _)
  let scheme = call_21626386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626386.makeUrl(scheme.get, call_21626386.host, call_21626386.base,
                               call_21626386.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626386, uri, valid, _)

proc call*(call_21626387: Call_GetCreateDBParameterGroup_21626370;
          Description: string; DBParameterGroupFamily: string;
          DBParameterGroupName: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626388 = newJObject()
  add(query_21626388, "Description", newJString(Description))
  add(query_21626388, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_21626388.add "Tags", Tags
  add(query_21626388, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626388, "Action", newJString(Action))
  add(query_21626388, "Version", newJString(Version))
  result = call_21626387.call(nil, query_21626388, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_21626370(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_21626371, base: "/",
    makeUrl: url_GetCreateDBParameterGroup_21626372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_21626427 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSecurityGroup_21626429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_21626428(path: JsonNode; query: JsonNode;
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
  var valid_21626430 = query.getOrDefault("Action")
  valid_21626430 = validateParameter(valid_21626430, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_21626430 != nil:
    section.add "Action", valid_21626430
  var valid_21626431 = query.getOrDefault("Version")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626431 != nil:
    section.add "Version", valid_21626431
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
  var valid_21626432 = header.getOrDefault("X-Amz-Date")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-Date", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Security-Token", valid_21626433
  var valid_21626434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626434 = validateParameter(valid_21626434, JString, required = false,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626434
  var valid_21626435 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626435 = validateParameter(valid_21626435, JString, required = false,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "X-Amz-Algorithm", valid_21626435
  var valid_21626436 = header.getOrDefault("X-Amz-Signature")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Signature", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Credential")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Credential", valid_21626438
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626439 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626439 = validateParameter(valid_21626439, JString, required = true,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "DBSecurityGroupName", valid_21626439
  var valid_21626440 = formData.getOrDefault("Tags")
  valid_21626440 = validateParameter(valid_21626440, JArray, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "Tags", valid_21626440
  var valid_21626441 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_21626441 = validateParameter(valid_21626441, JString, required = true,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "DBSecurityGroupDescription", valid_21626441
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626442: Call_PostCreateDBSecurityGroup_21626427;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626442.validator(path, query, header, formData, body, _)
  let scheme = call_21626442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626442.makeUrl(scheme.get, call_21626442.host, call_21626442.base,
                               call_21626442.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626442, uri, valid, _)

proc call*(call_21626443: Call_PostCreateDBSecurityGroup_21626427;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626444 = newJObject()
  var formData_21626445 = newJObject()
  add(formData_21626445, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_21626445.add "Tags", Tags
  add(query_21626444, "Action", newJString(Action))
  add(formData_21626445, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_21626444, "Version", newJString(Version))
  result = call_21626443.call(nil, query_21626444, nil, formData_21626445, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_21626427(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_21626428, base: "/",
    makeUrl: url_PostCreateDBSecurityGroup_21626429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_21626409 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSecurityGroup_21626411(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_21626410(path: JsonNode; query: JsonNode;
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
  var valid_21626412 = query.getOrDefault("DBSecurityGroupName")
  valid_21626412 = validateParameter(valid_21626412, JString, required = true,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "DBSecurityGroupName", valid_21626412
  var valid_21626413 = query.getOrDefault("DBSecurityGroupDescription")
  valid_21626413 = validateParameter(valid_21626413, JString, required = true,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "DBSecurityGroupDescription", valid_21626413
  var valid_21626414 = query.getOrDefault("Tags")
  valid_21626414 = validateParameter(valid_21626414, JArray, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "Tags", valid_21626414
  var valid_21626415 = query.getOrDefault("Action")
  valid_21626415 = validateParameter(valid_21626415, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_21626415 != nil:
    section.add "Action", valid_21626415
  var valid_21626416 = query.getOrDefault("Version")
  valid_21626416 = validateParameter(valid_21626416, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626416 != nil:
    section.add "Version", valid_21626416
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
  var valid_21626417 = header.getOrDefault("X-Amz-Date")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-Date", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Security-Token", valid_21626418
  var valid_21626419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626419 = validateParameter(valid_21626419, JString, required = false,
                                   default = nil)
  if valid_21626419 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626419
  var valid_21626420 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626420 = validateParameter(valid_21626420, JString, required = false,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "X-Amz-Algorithm", valid_21626420
  var valid_21626421 = header.getOrDefault("X-Amz-Signature")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Signature", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Credential")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Credential", valid_21626423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626424: Call_GetCreateDBSecurityGroup_21626409;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626424.validator(path, query, header, formData, body, _)
  let scheme = call_21626424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626424.makeUrl(scheme.get, call_21626424.host, call_21626424.base,
                               call_21626424.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626424, uri, valid, _)

proc call*(call_21626425: Call_GetCreateDBSecurityGroup_21626409;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626426 = newJObject()
  add(query_21626426, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626426, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_21626426.add "Tags", Tags
  add(query_21626426, "Action", newJString(Action))
  add(query_21626426, "Version", newJString(Version))
  result = call_21626425.call(nil, query_21626426, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_21626409(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_21626410, base: "/",
    makeUrl: url_GetCreateDBSecurityGroup_21626411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_21626464 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSnapshot_21626466(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_21626465(path: JsonNode; query: JsonNode;
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
  var valid_21626467 = query.getOrDefault("Action")
  valid_21626467 = validateParameter(valid_21626467, JString, required = true,
                                   default = newJString("CreateDBSnapshot"))
  if valid_21626467 != nil:
    section.add "Action", valid_21626467
  var valid_21626468 = query.getOrDefault("Version")
  valid_21626468 = validateParameter(valid_21626468, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626468 != nil:
    section.add "Version", valid_21626468
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
  var valid_21626469 = header.getOrDefault("X-Amz-Date")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Date", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Security-Token", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Algorithm", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-Signature")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-Signature", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626474
  var valid_21626475 = header.getOrDefault("X-Amz-Credential")
  valid_21626475 = validateParameter(valid_21626475, JString, required = false,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "X-Amz-Credential", valid_21626475
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626476 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626476 = validateParameter(valid_21626476, JString, required = true,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "DBInstanceIdentifier", valid_21626476
  var valid_21626477 = formData.getOrDefault("Tags")
  valid_21626477 = validateParameter(valid_21626477, JArray, required = false,
                                   default = nil)
  if valid_21626477 != nil:
    section.add "Tags", valid_21626477
  var valid_21626478 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21626478 = validateParameter(valid_21626478, JString, required = true,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "DBSnapshotIdentifier", valid_21626478
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626479: Call_PostCreateDBSnapshot_21626464; path: JsonNode = nil;
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

proc call*(call_21626480: Call_PostCreateDBSnapshot_21626464;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626481 = newJObject()
  var formData_21626482 = newJObject()
  add(formData_21626482, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_21626482.add "Tags", Tags
  add(formData_21626482, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21626481, "Action", newJString(Action))
  add(query_21626481, "Version", newJString(Version))
  result = call_21626480.call(nil, query_21626481, nil, formData_21626482, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_21626464(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_21626465, base: "/",
    makeUrl: url_PostCreateDBSnapshot_21626466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_21626446 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSnapshot_21626448(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_21626447(path: JsonNode; query: JsonNode;
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
  var valid_21626449 = query.getOrDefault("Tags")
  valid_21626449 = validateParameter(valid_21626449, JArray, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "Tags", valid_21626449
  var valid_21626450 = query.getOrDefault("Action")
  valid_21626450 = validateParameter(valid_21626450, JString, required = true,
                                   default = newJString("CreateDBSnapshot"))
  if valid_21626450 != nil:
    section.add "Action", valid_21626450
  var valid_21626451 = query.getOrDefault("Version")
  valid_21626451 = validateParameter(valid_21626451, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626451 != nil:
    section.add "Version", valid_21626451
  var valid_21626452 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626452 = validateParameter(valid_21626452, JString, required = true,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "DBInstanceIdentifier", valid_21626452
  var valid_21626453 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21626453 = validateParameter(valid_21626453, JString, required = true,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "DBSnapshotIdentifier", valid_21626453
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
  var valid_21626454 = header.getOrDefault("X-Amz-Date")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Date", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Security-Token", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Algorithm", valid_21626457
  var valid_21626458 = header.getOrDefault("X-Amz-Signature")
  valid_21626458 = validateParameter(valid_21626458, JString, required = false,
                                   default = nil)
  if valid_21626458 != nil:
    section.add "X-Amz-Signature", valid_21626458
  var valid_21626459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626459 = validateParameter(valid_21626459, JString, required = false,
                                   default = nil)
  if valid_21626459 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626459
  var valid_21626460 = header.getOrDefault("X-Amz-Credential")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Credential", valid_21626460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626461: Call_GetCreateDBSnapshot_21626446; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626461.validator(path, query, header, formData, body, _)
  let scheme = call_21626461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626461.makeUrl(scheme.get, call_21626461.host, call_21626461.base,
                               call_21626461.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626461, uri, valid, _)

proc call*(call_21626462: Call_GetCreateDBSnapshot_21626446;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21626463 = newJObject()
  if Tags != nil:
    query_21626463.add "Tags", Tags
  add(query_21626463, "Action", newJString(Action))
  add(query_21626463, "Version", newJString(Version))
  add(query_21626463, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626463, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21626462.call(nil, query_21626463, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_21626446(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_21626447, base: "/",
    makeUrl: url_GetCreateDBSnapshot_21626448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_21626502 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSubnetGroup_21626504(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_21626503(path: JsonNode; query: JsonNode;
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
  var valid_21626505 = query.getOrDefault("Action")
  valid_21626505 = validateParameter(valid_21626505, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626505 != nil:
    section.add "Action", valid_21626505
  var valid_21626506 = query.getOrDefault("Version")
  valid_21626506 = validateParameter(valid_21626506, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626506 != nil:
    section.add "Version", valid_21626506
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
  var valid_21626507 = header.getOrDefault("X-Amz-Date")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Date", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Security-Token", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Algorithm", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-Signature")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Signature", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Credential")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Credential", valid_21626513
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_21626514 = formData.getOrDefault("Tags")
  valid_21626514 = validateParameter(valid_21626514, JArray, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "Tags", valid_21626514
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626515 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626515 = validateParameter(valid_21626515, JString, required = true,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "DBSubnetGroupName", valid_21626515
  var valid_21626516 = formData.getOrDefault("SubnetIds")
  valid_21626516 = validateParameter(valid_21626516, JArray, required = true,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "SubnetIds", valid_21626516
  var valid_21626517 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21626517 = validateParameter(valid_21626517, JString, required = true,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "DBSubnetGroupDescription", valid_21626517
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626518: Call_PostCreateDBSubnetGroup_21626502;
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

proc call*(call_21626519: Call_PostCreateDBSubnetGroup_21626502;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSubnetGroup
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626520 = newJObject()
  var formData_21626521 = newJObject()
  if Tags != nil:
    formData_21626521.add "Tags", Tags
  add(formData_21626521, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21626521.add "SubnetIds", SubnetIds
  add(query_21626520, "Action", newJString(Action))
  add(formData_21626521, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626520, "Version", newJString(Version))
  result = call_21626519.call(nil, query_21626520, nil, formData_21626521, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_21626502(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_21626503, base: "/",
    makeUrl: url_PostCreateDBSubnetGroup_21626504,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_21626483 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSubnetGroup_21626485(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_21626484(path: JsonNode; query: JsonNode;
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
  var valid_21626486 = query.getOrDefault("Tags")
  valid_21626486 = validateParameter(valid_21626486, JArray, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "Tags", valid_21626486
  var valid_21626487 = query.getOrDefault("Action")
  valid_21626487 = validateParameter(valid_21626487, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626487 != nil:
    section.add "Action", valid_21626487
  var valid_21626488 = query.getOrDefault("DBSubnetGroupName")
  valid_21626488 = validateParameter(valid_21626488, JString, required = true,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "DBSubnetGroupName", valid_21626488
  var valid_21626489 = query.getOrDefault("SubnetIds")
  valid_21626489 = validateParameter(valid_21626489, JArray, required = true,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "SubnetIds", valid_21626489
  var valid_21626490 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21626490 = validateParameter(valid_21626490, JString, required = true,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "DBSubnetGroupDescription", valid_21626490
  var valid_21626491 = query.getOrDefault("Version")
  valid_21626491 = validateParameter(valid_21626491, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626491 != nil:
    section.add "Version", valid_21626491
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
  var valid_21626492 = header.getOrDefault("X-Amz-Date")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Date", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Security-Token", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Algorithm", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Signature")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Signature", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Credential")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Credential", valid_21626498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626499: Call_GetCreateDBSubnetGroup_21626483;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626499.validator(path, query, header, formData, body, _)
  let scheme = call_21626499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626499.makeUrl(scheme.get, call_21626499.host, call_21626499.base,
                               call_21626499.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626499, uri, valid, _)

proc call*(call_21626500: Call_GetCreateDBSubnetGroup_21626483;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626501 = newJObject()
  if Tags != nil:
    query_21626501.add "Tags", Tags
  add(query_21626501, "Action", newJString(Action))
  add(query_21626501, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21626501.add "SubnetIds", SubnetIds
  add(query_21626501, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626501, "Version", newJString(Version))
  result = call_21626500.call(nil, query_21626501, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_21626483(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_21626484, base: "/",
    makeUrl: url_GetCreateDBSubnetGroup_21626485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_21626544 = ref object of OpenApiRestCall_21625418
proc url_PostCreateEventSubscription_21626546(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_21626545(path: JsonNode; query: JsonNode;
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
  var valid_21626547 = query.getOrDefault("Action")
  valid_21626547 = validateParameter(valid_21626547, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_21626547 != nil:
    section.add "Action", valid_21626547
  var valid_21626548 = query.getOrDefault("Version")
  valid_21626548 = validateParameter(valid_21626548, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626548 != nil:
    section.add "Version", valid_21626548
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
  var valid_21626549 = header.getOrDefault("X-Amz-Date")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Date", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Security-Token", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626551
  var valid_21626552 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626552 = validateParameter(valid_21626552, JString, required = false,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "X-Amz-Algorithm", valid_21626552
  var valid_21626553 = header.getOrDefault("X-Amz-Signature")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "X-Amz-Signature", valid_21626553
  var valid_21626554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626554 = validateParameter(valid_21626554, JString, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626554
  var valid_21626555 = header.getOrDefault("X-Amz-Credential")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "X-Amz-Credential", valid_21626555
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
  var valid_21626556 = formData.getOrDefault("Enabled")
  valid_21626556 = validateParameter(valid_21626556, JBool, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "Enabled", valid_21626556
  var valid_21626557 = formData.getOrDefault("EventCategories")
  valid_21626557 = validateParameter(valid_21626557, JArray, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "EventCategories", valid_21626557
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_21626558 = formData.getOrDefault("SnsTopicArn")
  valid_21626558 = validateParameter(valid_21626558, JString, required = true,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "SnsTopicArn", valid_21626558
  var valid_21626559 = formData.getOrDefault("SourceIds")
  valid_21626559 = validateParameter(valid_21626559, JArray, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "SourceIds", valid_21626559
  var valid_21626560 = formData.getOrDefault("Tags")
  valid_21626560 = validateParameter(valid_21626560, JArray, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "Tags", valid_21626560
  var valid_21626561 = formData.getOrDefault("SubscriptionName")
  valid_21626561 = validateParameter(valid_21626561, JString, required = true,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "SubscriptionName", valid_21626561
  var valid_21626562 = formData.getOrDefault("SourceType")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "SourceType", valid_21626562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626563: Call_PostCreateEventSubscription_21626544;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626563.validator(path, query, header, formData, body, _)
  let scheme = call_21626563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626563.makeUrl(scheme.get, call_21626563.host, call_21626563.base,
                               call_21626563.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626563, uri, valid, _)

proc call*(call_21626564: Call_PostCreateEventSubscription_21626544;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Tags: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
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
  var query_21626565 = newJObject()
  var formData_21626566 = newJObject()
  add(formData_21626566, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_21626566.add "EventCategories", EventCategories
  add(formData_21626566, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_21626566.add "SourceIds", SourceIds
  if Tags != nil:
    formData_21626566.add "Tags", Tags
  add(formData_21626566, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626565, "Action", newJString(Action))
  add(query_21626565, "Version", newJString(Version))
  add(formData_21626566, "SourceType", newJString(SourceType))
  result = call_21626564.call(nil, query_21626565, nil, formData_21626566, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_21626544(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_21626545, base: "/",
    makeUrl: url_PostCreateEventSubscription_21626546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_21626522 = ref object of OpenApiRestCall_21625418
proc url_GetCreateEventSubscription_21626524(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_21626523(path: JsonNode; query: JsonNode;
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
  var valid_21626525 = query.getOrDefault("SourceType")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "SourceType", valid_21626525
  var valid_21626526 = query.getOrDefault("SourceIds")
  valid_21626526 = validateParameter(valid_21626526, JArray, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "SourceIds", valid_21626526
  var valid_21626527 = query.getOrDefault("Enabled")
  valid_21626527 = validateParameter(valid_21626527, JBool, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "Enabled", valid_21626527
  var valid_21626528 = query.getOrDefault("Tags")
  valid_21626528 = validateParameter(valid_21626528, JArray, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "Tags", valid_21626528
  var valid_21626529 = query.getOrDefault("Action")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_21626529 != nil:
    section.add "Action", valid_21626529
  var valid_21626530 = query.getOrDefault("SnsTopicArn")
  valid_21626530 = validateParameter(valid_21626530, JString, required = true,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "SnsTopicArn", valid_21626530
  var valid_21626531 = query.getOrDefault("EventCategories")
  valid_21626531 = validateParameter(valid_21626531, JArray, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "EventCategories", valid_21626531
  var valid_21626532 = query.getOrDefault("SubscriptionName")
  valid_21626532 = validateParameter(valid_21626532, JString, required = true,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "SubscriptionName", valid_21626532
  var valid_21626533 = query.getOrDefault("Version")
  valid_21626533 = validateParameter(valid_21626533, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626533 != nil:
    section.add "Version", valid_21626533
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
  var valid_21626534 = header.getOrDefault("X-Amz-Date")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Date", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-Security-Token", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626536
  var valid_21626537 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626537 = validateParameter(valid_21626537, JString, required = false,
                                   default = nil)
  if valid_21626537 != nil:
    section.add "X-Amz-Algorithm", valid_21626537
  var valid_21626538 = header.getOrDefault("X-Amz-Signature")
  valid_21626538 = validateParameter(valid_21626538, JString, required = false,
                                   default = nil)
  if valid_21626538 != nil:
    section.add "X-Amz-Signature", valid_21626538
  var valid_21626539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626539 = validateParameter(valid_21626539, JString, required = false,
                                   default = nil)
  if valid_21626539 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626539
  var valid_21626540 = header.getOrDefault("X-Amz-Credential")
  valid_21626540 = validateParameter(valid_21626540, JString, required = false,
                                   default = nil)
  if valid_21626540 != nil:
    section.add "X-Amz-Credential", valid_21626540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626541: Call_GetCreateEventSubscription_21626522;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626541.validator(path, query, header, formData, body, _)
  let scheme = call_21626541.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626541.makeUrl(scheme.get, call_21626541.host, call_21626541.base,
                               call_21626541.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626541, uri, valid, _)

proc call*(call_21626542: Call_GetCreateEventSubscription_21626522;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false; Tags: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
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
  var query_21626543 = newJObject()
  add(query_21626543, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_21626543.add "SourceIds", SourceIds
  add(query_21626543, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_21626543.add "Tags", Tags
  add(query_21626543, "Action", newJString(Action))
  add(query_21626543, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_21626543.add "EventCategories", EventCategories
  add(query_21626543, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626543, "Version", newJString(Version))
  result = call_21626542.call(nil, query_21626543, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_21626522(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_21626523, base: "/",
    makeUrl: url_GetCreateEventSubscription_21626524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_21626587 = ref object of OpenApiRestCall_21625418
proc url_PostCreateOptionGroup_21626589(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_21626588(path: JsonNode; query: JsonNode;
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
  var valid_21626590 = query.getOrDefault("Action")
  valid_21626590 = validateParameter(valid_21626590, JString, required = true,
                                   default = newJString("CreateOptionGroup"))
  if valid_21626590 != nil:
    section.add "Action", valid_21626590
  var valid_21626591 = query.getOrDefault("Version")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626591 != nil:
    section.add "Version", valid_21626591
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
  var valid_21626592 = header.getOrDefault("X-Amz-Date")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "X-Amz-Date", valid_21626592
  var valid_21626593 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Security-Token", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Algorithm", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Signature")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Signature", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Credential")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Credential", valid_21626598
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_21626599 = formData.getOrDefault("MajorEngineVersion")
  valid_21626599 = validateParameter(valid_21626599, JString, required = true,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "MajorEngineVersion", valid_21626599
  var valid_21626600 = formData.getOrDefault("OptionGroupName")
  valid_21626600 = validateParameter(valid_21626600, JString, required = true,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "OptionGroupName", valid_21626600
  var valid_21626601 = formData.getOrDefault("Tags")
  valid_21626601 = validateParameter(valid_21626601, JArray, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "Tags", valid_21626601
  var valid_21626602 = formData.getOrDefault("EngineName")
  valid_21626602 = validateParameter(valid_21626602, JString, required = true,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "EngineName", valid_21626602
  var valid_21626603 = formData.getOrDefault("OptionGroupDescription")
  valid_21626603 = validateParameter(valid_21626603, JString, required = true,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "OptionGroupDescription", valid_21626603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626604: Call_PostCreateOptionGroup_21626587;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626604.validator(path, query, header, formData, body, _)
  let scheme = call_21626604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626604.makeUrl(scheme.get, call_21626604.host, call_21626604.base,
                               call_21626604.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626604, uri, valid, _)

proc call*(call_21626605: Call_PostCreateOptionGroup_21626587;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626606 = newJObject()
  var formData_21626607 = newJObject()
  add(formData_21626607, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21626607, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21626607.add "Tags", Tags
  add(query_21626606, "Action", newJString(Action))
  add(formData_21626607, "EngineName", newJString(EngineName))
  add(formData_21626607, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_21626606, "Version", newJString(Version))
  result = call_21626605.call(nil, query_21626606, nil, formData_21626607, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_21626587(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_21626588, base: "/",
    makeUrl: url_PostCreateOptionGroup_21626589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_21626567 = ref object of OpenApiRestCall_21625418
proc url_GetCreateOptionGroup_21626569(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_21626568(path: JsonNode; query: JsonNode;
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
  var valid_21626570 = query.getOrDefault("OptionGroupName")
  valid_21626570 = validateParameter(valid_21626570, JString, required = true,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "OptionGroupName", valid_21626570
  var valid_21626571 = query.getOrDefault("Tags")
  valid_21626571 = validateParameter(valid_21626571, JArray, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "Tags", valid_21626571
  var valid_21626572 = query.getOrDefault("OptionGroupDescription")
  valid_21626572 = validateParameter(valid_21626572, JString, required = true,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "OptionGroupDescription", valid_21626572
  var valid_21626573 = query.getOrDefault("Action")
  valid_21626573 = validateParameter(valid_21626573, JString, required = true,
                                   default = newJString("CreateOptionGroup"))
  if valid_21626573 != nil:
    section.add "Action", valid_21626573
  var valid_21626574 = query.getOrDefault("Version")
  valid_21626574 = validateParameter(valid_21626574, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626574 != nil:
    section.add "Version", valid_21626574
  var valid_21626575 = query.getOrDefault("EngineName")
  valid_21626575 = validateParameter(valid_21626575, JString, required = true,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "EngineName", valid_21626575
  var valid_21626576 = query.getOrDefault("MajorEngineVersion")
  valid_21626576 = validateParameter(valid_21626576, JString, required = true,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "MajorEngineVersion", valid_21626576
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
  var valid_21626577 = header.getOrDefault("X-Amz-Date")
  valid_21626577 = validateParameter(valid_21626577, JString, required = false,
                                   default = nil)
  if valid_21626577 != nil:
    section.add "X-Amz-Date", valid_21626577
  var valid_21626578 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Security-Token", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Algorithm", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Signature")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Signature", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Credential")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Credential", valid_21626583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626584: Call_GetCreateOptionGroup_21626567; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626584.validator(path, query, header, formData, body, _)
  let scheme = call_21626584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626584.makeUrl(scheme.get, call_21626584.host, call_21626584.base,
                               call_21626584.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626584, uri, valid, _)

proc call*(call_21626585: Call_GetCreateOptionGroup_21626567;
          OptionGroupName: string; OptionGroupDescription: string;
          EngineName: string; MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_21626586 = newJObject()
  add(query_21626586, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_21626586.add "Tags", Tags
  add(query_21626586, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_21626586, "Action", newJString(Action))
  add(query_21626586, "Version", newJString(Version))
  add(query_21626586, "EngineName", newJString(EngineName))
  add(query_21626586, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21626585.call(nil, query_21626586, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_21626567(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_21626568, base: "/",
    makeUrl: url_GetCreateOptionGroup_21626569,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_21626626 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBInstance_21626628(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_21626627(path: JsonNode; query: JsonNode;
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
  var valid_21626629 = query.getOrDefault("Action")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626629 != nil:
    section.add "Action", valid_21626629
  var valid_21626630 = query.getOrDefault("Version")
  valid_21626630 = validateParameter(valid_21626630, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626630 != nil:
    section.add "Version", valid_21626630
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626638 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626638 = validateParameter(valid_21626638, JString, required = true,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "DBInstanceIdentifier", valid_21626638
  var valid_21626639 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626639
  var valid_21626640 = formData.getOrDefault("SkipFinalSnapshot")
  valid_21626640 = validateParameter(valid_21626640, JBool, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "SkipFinalSnapshot", valid_21626640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626641: Call_PostDeleteDBInstance_21626626; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626641.validator(path, query, header, formData, body, _)
  let scheme = call_21626641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626641.makeUrl(scheme.get, call_21626641.host, call_21626641.base,
                               call_21626641.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626641, uri, valid, _)

proc call*(call_21626642: Call_PostDeleteDBInstance_21626626;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_21626643 = newJObject()
  var formData_21626644 = newJObject()
  add(formData_21626644, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626644, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626643, "Action", newJString(Action))
  add(query_21626643, "Version", newJString(Version))
  add(formData_21626644, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_21626642.call(nil, query_21626643, nil, formData_21626644, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_21626626(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_21626627, base: "/",
    makeUrl: url_PostDeleteDBInstance_21626628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_21626608 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBInstance_21626610(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_21626609(path: JsonNode; query: JsonNode;
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
  var valid_21626611 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626611
  var valid_21626612 = query.getOrDefault("Action")
  valid_21626612 = validateParameter(valid_21626612, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626612 != nil:
    section.add "Action", valid_21626612
  var valid_21626613 = query.getOrDefault("SkipFinalSnapshot")
  valid_21626613 = validateParameter(valid_21626613, JBool, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "SkipFinalSnapshot", valid_21626613
  var valid_21626614 = query.getOrDefault("Version")
  valid_21626614 = validateParameter(valid_21626614, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626614 != nil:
    section.add "Version", valid_21626614
  var valid_21626615 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626615 = validateParameter(valid_21626615, JString, required = true,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "DBInstanceIdentifier", valid_21626615
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
  var valid_21626616 = header.getOrDefault("X-Amz-Date")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Date", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Security-Token", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Algorithm", valid_21626619
  var valid_21626620 = header.getOrDefault("X-Amz-Signature")
  valid_21626620 = validateParameter(valid_21626620, JString, required = false,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "X-Amz-Signature", valid_21626620
  var valid_21626621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626621 = validateParameter(valid_21626621, JString, required = false,
                                   default = nil)
  if valid_21626621 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626621
  var valid_21626622 = header.getOrDefault("X-Amz-Credential")
  valid_21626622 = validateParameter(valid_21626622, JString, required = false,
                                   default = nil)
  if valid_21626622 != nil:
    section.add "X-Amz-Credential", valid_21626622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626623: Call_GetDeleteDBInstance_21626608; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626623.validator(path, query, header, formData, body, _)
  let scheme = call_21626623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626623.makeUrl(scheme.get, call_21626623.host, call_21626623.base,
                               call_21626623.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626623, uri, valid, _)

proc call*(call_21626624: Call_GetDeleteDBInstance_21626608;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21626625 = newJObject()
  add(query_21626625, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626625, "Action", newJString(Action))
  add(query_21626625, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_21626625, "Version", newJString(Version))
  add(query_21626625, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626624.call(nil, query_21626625, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_21626608(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_21626609, base: "/",
    makeUrl: url_GetDeleteDBInstance_21626610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_21626661 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBParameterGroup_21626663(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_21626662(path: JsonNode; query: JsonNode;
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
  var valid_21626664 = query.getOrDefault("Action")
  valid_21626664 = validateParameter(valid_21626664, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_21626664 != nil:
    section.add "Action", valid_21626664
  var valid_21626665 = query.getOrDefault("Version")
  valid_21626665 = validateParameter(valid_21626665, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626665 != nil:
    section.add "Version", valid_21626665
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
  var valid_21626666 = header.getOrDefault("X-Amz-Date")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Date", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Security-Token", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Algorithm", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-Signature")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-Signature", valid_21626670
  var valid_21626671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626671 = validateParameter(valid_21626671, JString, required = false,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626671
  var valid_21626672 = header.getOrDefault("X-Amz-Credential")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Credential", valid_21626672
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626673 = formData.getOrDefault("DBParameterGroupName")
  valid_21626673 = validateParameter(valid_21626673, JString, required = true,
                                   default = nil)
  if valid_21626673 != nil:
    section.add "DBParameterGroupName", valid_21626673
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626674: Call_PostDeleteDBParameterGroup_21626661;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626674.validator(path, query, header, formData, body, _)
  let scheme = call_21626674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626674.makeUrl(scheme.get, call_21626674.host, call_21626674.base,
                               call_21626674.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626674, uri, valid, _)

proc call*(call_21626675: Call_PostDeleteDBParameterGroup_21626661;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626676 = newJObject()
  var formData_21626677 = newJObject()
  add(formData_21626677, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626676, "Action", newJString(Action))
  add(query_21626676, "Version", newJString(Version))
  result = call_21626675.call(nil, query_21626676, nil, formData_21626677, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_21626661(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_21626662, base: "/",
    makeUrl: url_PostDeleteDBParameterGroup_21626663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_21626645 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBParameterGroup_21626647(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_21626646(path: JsonNode; query: JsonNode;
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
  var valid_21626648 = query.getOrDefault("DBParameterGroupName")
  valid_21626648 = validateParameter(valid_21626648, JString, required = true,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "DBParameterGroupName", valid_21626648
  var valid_21626649 = query.getOrDefault("Action")
  valid_21626649 = validateParameter(valid_21626649, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_21626649 != nil:
    section.add "Action", valid_21626649
  var valid_21626650 = query.getOrDefault("Version")
  valid_21626650 = validateParameter(valid_21626650, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626650 != nil:
    section.add "Version", valid_21626650
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
  var valid_21626651 = header.getOrDefault("X-Amz-Date")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Date", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Security-Token", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Algorithm", valid_21626654
  var valid_21626655 = header.getOrDefault("X-Amz-Signature")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "X-Amz-Signature", valid_21626655
  var valid_21626656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626656
  var valid_21626657 = header.getOrDefault("X-Amz-Credential")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-Credential", valid_21626657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626658: Call_GetDeleteDBParameterGroup_21626645;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626658.validator(path, query, header, formData, body, _)
  let scheme = call_21626658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626658.makeUrl(scheme.get, call_21626658.host, call_21626658.base,
                               call_21626658.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626658, uri, valid, _)

proc call*(call_21626659: Call_GetDeleteDBParameterGroup_21626645;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626660 = newJObject()
  add(query_21626660, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626660, "Action", newJString(Action))
  add(query_21626660, "Version", newJString(Version))
  result = call_21626659.call(nil, query_21626660, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_21626645(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_21626646, base: "/",
    makeUrl: url_GetDeleteDBParameterGroup_21626647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_21626694 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSecurityGroup_21626696(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_21626695(path: JsonNode; query: JsonNode;
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
  var valid_21626697 = query.getOrDefault("Action")
  valid_21626697 = validateParameter(valid_21626697, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_21626697 != nil:
    section.add "Action", valid_21626697
  var valid_21626698 = query.getOrDefault("Version")
  valid_21626698 = validateParameter(valid_21626698, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626698 != nil:
    section.add "Version", valid_21626698
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
  var valid_21626699 = header.getOrDefault("X-Amz-Date")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Date", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Security-Token", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Algorithm", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Signature")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Signature", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626704
  var valid_21626705 = header.getOrDefault("X-Amz-Credential")
  valid_21626705 = validateParameter(valid_21626705, JString, required = false,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "X-Amz-Credential", valid_21626705
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626706 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626706 = validateParameter(valid_21626706, JString, required = true,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "DBSecurityGroupName", valid_21626706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626707: Call_PostDeleteDBSecurityGroup_21626694;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626707.validator(path, query, header, formData, body, _)
  let scheme = call_21626707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626707.makeUrl(scheme.get, call_21626707.host, call_21626707.base,
                               call_21626707.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626707, uri, valid, _)

proc call*(call_21626708: Call_PostDeleteDBSecurityGroup_21626694;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626709 = newJObject()
  var formData_21626710 = newJObject()
  add(formData_21626710, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626709, "Action", newJString(Action))
  add(query_21626709, "Version", newJString(Version))
  result = call_21626708.call(nil, query_21626709, nil, formData_21626710, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_21626694(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_21626695, base: "/",
    makeUrl: url_PostDeleteDBSecurityGroup_21626696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_21626678 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSecurityGroup_21626680(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_21626679(path: JsonNode; query: JsonNode;
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
  var valid_21626681 = query.getOrDefault("DBSecurityGroupName")
  valid_21626681 = validateParameter(valid_21626681, JString, required = true,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "DBSecurityGroupName", valid_21626681
  var valid_21626682 = query.getOrDefault("Action")
  valid_21626682 = validateParameter(valid_21626682, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_21626682 != nil:
    section.add "Action", valid_21626682
  var valid_21626683 = query.getOrDefault("Version")
  valid_21626683 = validateParameter(valid_21626683, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626683 != nil:
    section.add "Version", valid_21626683
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
  var valid_21626684 = header.getOrDefault("X-Amz-Date")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Date", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Security-Token", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Algorithm", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-Signature")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-Signature", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626689
  var valid_21626690 = header.getOrDefault("X-Amz-Credential")
  valid_21626690 = validateParameter(valid_21626690, JString, required = false,
                                   default = nil)
  if valid_21626690 != nil:
    section.add "X-Amz-Credential", valid_21626690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626691: Call_GetDeleteDBSecurityGroup_21626678;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626691.validator(path, query, header, formData, body, _)
  let scheme = call_21626691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626691.makeUrl(scheme.get, call_21626691.host, call_21626691.base,
                               call_21626691.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626691, uri, valid, _)

proc call*(call_21626692: Call_GetDeleteDBSecurityGroup_21626678;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626693 = newJObject()
  add(query_21626693, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626693, "Action", newJString(Action))
  add(query_21626693, "Version", newJString(Version))
  result = call_21626692.call(nil, query_21626693, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_21626678(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_21626679, base: "/",
    makeUrl: url_GetDeleteDBSecurityGroup_21626680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_21626727 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSnapshot_21626729(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_21626728(path: JsonNode; query: JsonNode;
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
  var valid_21626730 = query.getOrDefault("Action")
  valid_21626730 = validateParameter(valid_21626730, JString, required = true,
                                   default = newJString("DeleteDBSnapshot"))
  if valid_21626730 != nil:
    section.add "Action", valid_21626730
  var valid_21626731 = query.getOrDefault("Version")
  valid_21626731 = validateParameter(valid_21626731, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626731 != nil:
    section.add "Version", valid_21626731
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
  var valid_21626732 = header.getOrDefault("X-Amz-Date")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Date", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Security-Token", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Algorithm", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Signature")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Signature", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-Credential")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-Credential", valid_21626738
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_21626739 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21626739 = validateParameter(valid_21626739, JString, required = true,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "DBSnapshotIdentifier", valid_21626739
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626740: Call_PostDeleteDBSnapshot_21626727; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626740.validator(path, query, header, formData, body, _)
  let scheme = call_21626740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626740.makeUrl(scheme.get, call_21626740.host, call_21626740.base,
                               call_21626740.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626740, uri, valid, _)

proc call*(call_21626741: Call_PostDeleteDBSnapshot_21626727;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626742 = newJObject()
  var formData_21626743 = newJObject()
  add(formData_21626743, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21626742, "Action", newJString(Action))
  add(query_21626742, "Version", newJString(Version))
  result = call_21626741.call(nil, query_21626742, nil, formData_21626743, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_21626727(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_21626728, base: "/",
    makeUrl: url_PostDeleteDBSnapshot_21626729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_21626711 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSnapshot_21626713(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_21626712(path: JsonNode; query: JsonNode;
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
  var valid_21626714 = query.getOrDefault("Action")
  valid_21626714 = validateParameter(valid_21626714, JString, required = true,
                                   default = newJString("DeleteDBSnapshot"))
  if valid_21626714 != nil:
    section.add "Action", valid_21626714
  var valid_21626715 = query.getOrDefault("Version")
  valid_21626715 = validateParameter(valid_21626715, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626715 != nil:
    section.add "Version", valid_21626715
  var valid_21626716 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21626716 = validateParameter(valid_21626716, JString, required = true,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "DBSnapshotIdentifier", valid_21626716
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
  var valid_21626717 = header.getOrDefault("X-Amz-Date")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-Date", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Security-Token", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Algorithm", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Signature")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Signature", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-Credential")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-Credential", valid_21626723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626724: Call_GetDeleteDBSnapshot_21626711; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626724.validator(path, query, header, formData, body, _)
  let scheme = call_21626724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626724.makeUrl(scheme.get, call_21626724.host, call_21626724.base,
                               call_21626724.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626724, uri, valid, _)

proc call*(call_21626725: Call_GetDeleteDBSnapshot_21626711;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21626726 = newJObject()
  add(query_21626726, "Action", newJString(Action))
  add(query_21626726, "Version", newJString(Version))
  add(query_21626726, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21626725.call(nil, query_21626726, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_21626711(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_21626712, base: "/",
    makeUrl: url_GetDeleteDBSnapshot_21626713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_21626760 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSubnetGroup_21626762(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_21626761(path: JsonNode; query: JsonNode;
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
  var valid_21626763 = query.getOrDefault("Action")
  valid_21626763 = validateParameter(valid_21626763, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626763 != nil:
    section.add "Action", valid_21626763
  var valid_21626764 = query.getOrDefault("Version")
  valid_21626764 = validateParameter(valid_21626764, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626764 != nil:
    section.add "Version", valid_21626764
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
  var valid_21626765 = header.getOrDefault("X-Amz-Date")
  valid_21626765 = validateParameter(valid_21626765, JString, required = false,
                                   default = nil)
  if valid_21626765 != nil:
    section.add "X-Amz-Date", valid_21626765
  var valid_21626766 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "X-Amz-Security-Token", valid_21626766
  var valid_21626767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626767
  var valid_21626768 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Algorithm", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Signature")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Signature", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Credential")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Credential", valid_21626771
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626772 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626772 = validateParameter(valid_21626772, JString, required = true,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "DBSubnetGroupName", valid_21626772
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626773: Call_PostDeleteDBSubnetGroup_21626760;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626773.validator(path, query, header, formData, body, _)
  let scheme = call_21626773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626773.makeUrl(scheme.get, call_21626773.host, call_21626773.base,
                               call_21626773.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626773, uri, valid, _)

proc call*(call_21626774: Call_PostDeleteDBSubnetGroup_21626760;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626775 = newJObject()
  var formData_21626776 = newJObject()
  add(formData_21626776, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626775, "Action", newJString(Action))
  add(query_21626775, "Version", newJString(Version))
  result = call_21626774.call(nil, query_21626775, nil, formData_21626776, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_21626760(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_21626761, base: "/",
    makeUrl: url_PostDeleteDBSubnetGroup_21626762,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_21626744 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSubnetGroup_21626746(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_21626745(path: JsonNode; query: JsonNode;
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
  var valid_21626747 = query.getOrDefault("Action")
  valid_21626747 = validateParameter(valid_21626747, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626747 != nil:
    section.add "Action", valid_21626747
  var valid_21626748 = query.getOrDefault("DBSubnetGroupName")
  valid_21626748 = validateParameter(valid_21626748, JString, required = true,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "DBSubnetGroupName", valid_21626748
  var valid_21626749 = query.getOrDefault("Version")
  valid_21626749 = validateParameter(valid_21626749, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626749 != nil:
    section.add "Version", valid_21626749
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
  var valid_21626750 = header.getOrDefault("X-Amz-Date")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-Date", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Security-Token", valid_21626751
  var valid_21626752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626752 = validateParameter(valid_21626752, JString, required = false,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626752
  var valid_21626753 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Algorithm", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Signature")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Signature", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Credential")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Credential", valid_21626756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626757: Call_GetDeleteDBSubnetGroup_21626744;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626757.validator(path, query, header, formData, body, _)
  let scheme = call_21626757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626757.makeUrl(scheme.get, call_21626757.host, call_21626757.base,
                               call_21626757.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626757, uri, valid, _)

proc call*(call_21626758: Call_GetDeleteDBSubnetGroup_21626744;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_21626759 = newJObject()
  add(query_21626759, "Action", newJString(Action))
  add(query_21626759, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626759, "Version", newJString(Version))
  result = call_21626758.call(nil, query_21626759, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_21626744(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_21626745, base: "/",
    makeUrl: url_GetDeleteDBSubnetGroup_21626746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_21626793 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteEventSubscription_21626795(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_21626794(path: JsonNode; query: JsonNode;
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
  var valid_21626796 = query.getOrDefault("Action")
  valid_21626796 = validateParameter(valid_21626796, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_21626796 != nil:
    section.add "Action", valid_21626796
  var valid_21626797 = query.getOrDefault("Version")
  valid_21626797 = validateParameter(valid_21626797, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626797 != nil:
    section.add "Version", valid_21626797
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
  var valid_21626798 = header.getOrDefault("X-Amz-Date")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "X-Amz-Date", valid_21626798
  var valid_21626799 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626799 = validateParameter(valid_21626799, JString, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "X-Amz-Security-Token", valid_21626799
  var valid_21626800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626800 = validateParameter(valid_21626800, JString, required = false,
                                   default = nil)
  if valid_21626800 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626800
  var valid_21626801 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626801 = validateParameter(valid_21626801, JString, required = false,
                                   default = nil)
  if valid_21626801 != nil:
    section.add "X-Amz-Algorithm", valid_21626801
  var valid_21626802 = header.getOrDefault("X-Amz-Signature")
  valid_21626802 = validateParameter(valid_21626802, JString, required = false,
                                   default = nil)
  if valid_21626802 != nil:
    section.add "X-Amz-Signature", valid_21626802
  var valid_21626803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626803 = validateParameter(valid_21626803, JString, required = false,
                                   default = nil)
  if valid_21626803 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626803
  var valid_21626804 = header.getOrDefault("X-Amz-Credential")
  valid_21626804 = validateParameter(valid_21626804, JString, required = false,
                                   default = nil)
  if valid_21626804 != nil:
    section.add "X-Amz-Credential", valid_21626804
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_21626805 = formData.getOrDefault("SubscriptionName")
  valid_21626805 = validateParameter(valid_21626805, JString, required = true,
                                   default = nil)
  if valid_21626805 != nil:
    section.add "SubscriptionName", valid_21626805
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626806: Call_PostDeleteEventSubscription_21626793;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626806.validator(path, query, header, formData, body, _)
  let scheme = call_21626806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626806.makeUrl(scheme.get, call_21626806.host, call_21626806.base,
                               call_21626806.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626806, uri, valid, _)

proc call*(call_21626807: Call_PostDeleteEventSubscription_21626793;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626808 = newJObject()
  var formData_21626809 = newJObject()
  add(formData_21626809, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626808, "Action", newJString(Action))
  add(query_21626808, "Version", newJString(Version))
  result = call_21626807.call(nil, query_21626808, nil, formData_21626809, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_21626793(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_21626794, base: "/",
    makeUrl: url_PostDeleteEventSubscription_21626795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_21626777 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteEventSubscription_21626779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_21626778(path: JsonNode; query: JsonNode;
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
  var valid_21626780 = query.getOrDefault("Action")
  valid_21626780 = validateParameter(valid_21626780, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_21626780 != nil:
    section.add "Action", valid_21626780
  var valid_21626781 = query.getOrDefault("SubscriptionName")
  valid_21626781 = validateParameter(valid_21626781, JString, required = true,
                                   default = nil)
  if valid_21626781 != nil:
    section.add "SubscriptionName", valid_21626781
  var valid_21626782 = query.getOrDefault("Version")
  valid_21626782 = validateParameter(valid_21626782, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626782 != nil:
    section.add "Version", valid_21626782
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
  var valid_21626783 = header.getOrDefault("X-Amz-Date")
  valid_21626783 = validateParameter(valid_21626783, JString, required = false,
                                   default = nil)
  if valid_21626783 != nil:
    section.add "X-Amz-Date", valid_21626783
  var valid_21626784 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626784 = validateParameter(valid_21626784, JString, required = false,
                                   default = nil)
  if valid_21626784 != nil:
    section.add "X-Amz-Security-Token", valid_21626784
  var valid_21626785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Algorithm", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Signature")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Signature", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Credential")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Credential", valid_21626789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626790: Call_GetDeleteEventSubscription_21626777;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626790.validator(path, query, header, formData, body, _)
  let scheme = call_21626790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626790.makeUrl(scheme.get, call_21626790.host, call_21626790.base,
                               call_21626790.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626790, uri, valid, _)

proc call*(call_21626791: Call_GetDeleteEventSubscription_21626777;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21626792 = newJObject()
  add(query_21626792, "Action", newJString(Action))
  add(query_21626792, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626792, "Version", newJString(Version))
  result = call_21626791.call(nil, query_21626792, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_21626777(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_21626778, base: "/",
    makeUrl: url_GetDeleteEventSubscription_21626779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_21626826 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteOptionGroup_21626828(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_21626827(path: JsonNode; query: JsonNode;
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
  var valid_21626829 = query.getOrDefault("Action")
  valid_21626829 = validateParameter(valid_21626829, JString, required = true,
                                   default = newJString("DeleteOptionGroup"))
  if valid_21626829 != nil:
    section.add "Action", valid_21626829
  var valid_21626830 = query.getOrDefault("Version")
  valid_21626830 = validateParameter(valid_21626830, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626830 != nil:
    section.add "Version", valid_21626830
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
  var valid_21626831 = header.getOrDefault("X-Amz-Date")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Date", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Security-Token", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Algorithm", valid_21626834
  var valid_21626835 = header.getOrDefault("X-Amz-Signature")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "X-Amz-Signature", valid_21626835
  var valid_21626836 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626836
  var valid_21626837 = header.getOrDefault("X-Amz-Credential")
  valid_21626837 = validateParameter(valid_21626837, JString, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "X-Amz-Credential", valid_21626837
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_21626838 = formData.getOrDefault("OptionGroupName")
  valid_21626838 = validateParameter(valid_21626838, JString, required = true,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "OptionGroupName", valid_21626838
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626839: Call_PostDeleteOptionGroup_21626826;
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

proc call*(call_21626840: Call_PostDeleteOptionGroup_21626826;
          OptionGroupName: string; Action: string = "DeleteOptionGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626841 = newJObject()
  var formData_21626842 = newJObject()
  add(formData_21626842, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626841, "Action", newJString(Action))
  add(query_21626841, "Version", newJString(Version))
  result = call_21626840.call(nil, query_21626841, nil, formData_21626842, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_21626826(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_21626827, base: "/",
    makeUrl: url_PostDeleteOptionGroup_21626828,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_21626810 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteOptionGroup_21626812(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_21626811(path: JsonNode; query: JsonNode;
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
  var valid_21626813 = query.getOrDefault("OptionGroupName")
  valid_21626813 = validateParameter(valid_21626813, JString, required = true,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "OptionGroupName", valid_21626813
  var valid_21626814 = query.getOrDefault("Action")
  valid_21626814 = validateParameter(valid_21626814, JString, required = true,
                                   default = newJString("DeleteOptionGroup"))
  if valid_21626814 != nil:
    section.add "Action", valid_21626814
  var valid_21626815 = query.getOrDefault("Version")
  valid_21626815 = validateParameter(valid_21626815, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626815 != nil:
    section.add "Version", valid_21626815
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
  var valid_21626816 = header.getOrDefault("X-Amz-Date")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Date", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Security-Token", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Algorithm", valid_21626819
  var valid_21626820 = header.getOrDefault("X-Amz-Signature")
  valid_21626820 = validateParameter(valid_21626820, JString, required = false,
                                   default = nil)
  if valid_21626820 != nil:
    section.add "X-Amz-Signature", valid_21626820
  var valid_21626821 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626821 = validateParameter(valid_21626821, JString, required = false,
                                   default = nil)
  if valid_21626821 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626821
  var valid_21626822 = header.getOrDefault("X-Amz-Credential")
  valid_21626822 = validateParameter(valid_21626822, JString, required = false,
                                   default = nil)
  if valid_21626822 != nil:
    section.add "X-Amz-Credential", valid_21626822
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626823: Call_GetDeleteOptionGroup_21626810; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626823.validator(path, query, header, formData, body, _)
  let scheme = call_21626823.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626823.makeUrl(scheme.get, call_21626823.host, call_21626823.base,
                               call_21626823.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626823, uri, valid, _)

proc call*(call_21626824: Call_GetDeleteOptionGroup_21626810;
          OptionGroupName: string; Action: string = "DeleteOptionGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626825 = newJObject()
  add(query_21626825, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626825, "Action", newJString(Action))
  add(query_21626825, "Version", newJString(Version))
  result = call_21626824.call(nil, query_21626825, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_21626810(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_21626811, base: "/",
    makeUrl: url_GetDeleteOptionGroup_21626812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_21626866 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBEngineVersions_21626868(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_21626867(path: JsonNode;
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
  var valid_21626869 = query.getOrDefault("Action")
  valid_21626869 = validateParameter(valid_21626869, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626869 != nil:
    section.add "Action", valid_21626869
  var valid_21626870 = query.getOrDefault("Version")
  valid_21626870 = validateParameter(valid_21626870, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626870 != nil:
    section.add "Version", valid_21626870
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
  var valid_21626871 = header.getOrDefault("X-Amz-Date")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Date", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Security-Token", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Algorithm", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-Signature")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-Signature", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626876
  var valid_21626877 = header.getOrDefault("X-Amz-Credential")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "X-Amz-Credential", valid_21626877
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
  var valid_21626878 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_21626878 = validateParameter(valid_21626878, JBool, required = false,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "ListSupportedCharacterSets", valid_21626878
  var valid_21626879 = formData.getOrDefault("Engine")
  valid_21626879 = validateParameter(valid_21626879, JString, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "Engine", valid_21626879
  var valid_21626880 = formData.getOrDefault("Marker")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "Marker", valid_21626880
  var valid_21626881 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626881 = validateParameter(valid_21626881, JString, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "DBParameterGroupFamily", valid_21626881
  var valid_21626882 = formData.getOrDefault("Filters")
  valid_21626882 = validateParameter(valid_21626882, JArray, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "Filters", valid_21626882
  var valid_21626883 = formData.getOrDefault("MaxRecords")
  valid_21626883 = validateParameter(valid_21626883, JInt, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "MaxRecords", valid_21626883
  var valid_21626884 = formData.getOrDefault("EngineVersion")
  valid_21626884 = validateParameter(valid_21626884, JString, required = false,
                                   default = nil)
  if valid_21626884 != nil:
    section.add "EngineVersion", valid_21626884
  var valid_21626885 = formData.getOrDefault("DefaultOnly")
  valid_21626885 = validateParameter(valid_21626885, JBool, required = false,
                                   default = nil)
  if valid_21626885 != nil:
    section.add "DefaultOnly", valid_21626885
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626886: Call_PostDescribeDBEngineVersions_21626866;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626886.validator(path, query, header, formData, body, _)
  let scheme = call_21626886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626886.makeUrl(scheme.get, call_21626886.host, call_21626886.base,
                               call_21626886.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626886, uri, valid, _)

proc call*(call_21626887: Call_PostDescribeDBEngineVersions_21626866;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-09-01"; DefaultOnly: bool = false): Recallable =
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
  var query_21626888 = newJObject()
  var formData_21626889 = newJObject()
  add(formData_21626889, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_21626889, "Engine", newJString(Engine))
  add(formData_21626889, "Marker", newJString(Marker))
  add(query_21626888, "Action", newJString(Action))
  add(formData_21626889, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_21626889.add "Filters", Filters
  add(formData_21626889, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626889, "EngineVersion", newJString(EngineVersion))
  add(query_21626888, "Version", newJString(Version))
  add(formData_21626889, "DefaultOnly", newJBool(DefaultOnly))
  result = call_21626887.call(nil, query_21626888, nil, formData_21626889, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_21626866(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_21626867, base: "/",
    makeUrl: url_PostDescribeDBEngineVersions_21626868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_21626843 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBEngineVersions_21626845(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_21626844(path: JsonNode; query: JsonNode;
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
  var valid_21626846 = query.getOrDefault("Engine")
  valid_21626846 = validateParameter(valid_21626846, JString, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "Engine", valid_21626846
  var valid_21626847 = query.getOrDefault("ListSupportedCharacterSets")
  valid_21626847 = validateParameter(valid_21626847, JBool, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "ListSupportedCharacterSets", valid_21626847
  var valid_21626848 = query.getOrDefault("MaxRecords")
  valid_21626848 = validateParameter(valid_21626848, JInt, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "MaxRecords", valid_21626848
  var valid_21626849 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626849 = validateParameter(valid_21626849, JString, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "DBParameterGroupFamily", valid_21626849
  var valid_21626850 = query.getOrDefault("Filters")
  valid_21626850 = validateParameter(valid_21626850, JArray, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "Filters", valid_21626850
  var valid_21626851 = query.getOrDefault("Action")
  valid_21626851 = validateParameter(valid_21626851, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626851 != nil:
    section.add "Action", valid_21626851
  var valid_21626852 = query.getOrDefault("Marker")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "Marker", valid_21626852
  var valid_21626853 = query.getOrDefault("EngineVersion")
  valid_21626853 = validateParameter(valid_21626853, JString, required = false,
                                   default = nil)
  if valid_21626853 != nil:
    section.add "EngineVersion", valid_21626853
  var valid_21626854 = query.getOrDefault("DefaultOnly")
  valid_21626854 = validateParameter(valid_21626854, JBool, required = false,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "DefaultOnly", valid_21626854
  var valid_21626855 = query.getOrDefault("Version")
  valid_21626855 = validateParameter(valid_21626855, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626855 != nil:
    section.add "Version", valid_21626855
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
  var valid_21626856 = header.getOrDefault("X-Amz-Date")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Date", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Security-Token", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Algorithm", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-Signature")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-Signature", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626861
  var valid_21626862 = header.getOrDefault("X-Amz-Credential")
  valid_21626862 = validateParameter(valid_21626862, JString, required = false,
                                   default = nil)
  if valid_21626862 != nil:
    section.add "X-Amz-Credential", valid_21626862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626863: Call_GetDescribeDBEngineVersions_21626843;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626863.validator(path, query, header, formData, body, _)
  let scheme = call_21626863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626863.makeUrl(scheme.get, call_21626863.host, call_21626863.base,
                               call_21626863.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626863, uri, valid, _)

proc call*(call_21626864: Call_GetDescribeDBEngineVersions_21626843;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBEngineVersions";
          Marker: string = ""; EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2014-09-01"): Recallable =
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
  var query_21626865 = newJObject()
  add(query_21626865, "Engine", newJString(Engine))
  add(query_21626865, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_21626865, "MaxRecords", newJInt(MaxRecords))
  add(query_21626865, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_21626865.add "Filters", Filters
  add(query_21626865, "Action", newJString(Action))
  add(query_21626865, "Marker", newJString(Marker))
  add(query_21626865, "EngineVersion", newJString(EngineVersion))
  add(query_21626865, "DefaultOnly", newJBool(DefaultOnly))
  add(query_21626865, "Version", newJString(Version))
  result = call_21626864.call(nil, query_21626865, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_21626843(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_21626844, base: "/",
    makeUrl: url_GetDescribeDBEngineVersions_21626845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_21626909 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBInstances_21626911(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_21626910(path: JsonNode; query: JsonNode;
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
  var valid_21626912 = query.getOrDefault("Action")
  valid_21626912 = validateParameter(valid_21626912, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626912 != nil:
    section.add "Action", valid_21626912
  var valid_21626913 = query.getOrDefault("Version")
  valid_21626913 = validateParameter(valid_21626913, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626913 != nil:
    section.add "Version", valid_21626913
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
  var valid_21626914 = header.getOrDefault("X-Amz-Date")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Date", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Security-Token", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-Algorithm", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Signature")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Signature", valid_21626918
  var valid_21626919 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626919
  var valid_21626920 = header.getOrDefault("X-Amz-Credential")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "X-Amz-Credential", valid_21626920
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626921 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626921 = validateParameter(valid_21626921, JString, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "DBInstanceIdentifier", valid_21626921
  var valid_21626922 = formData.getOrDefault("Marker")
  valid_21626922 = validateParameter(valid_21626922, JString, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "Marker", valid_21626922
  var valid_21626923 = formData.getOrDefault("Filters")
  valid_21626923 = validateParameter(valid_21626923, JArray, required = false,
                                   default = nil)
  if valid_21626923 != nil:
    section.add "Filters", valid_21626923
  var valid_21626924 = formData.getOrDefault("MaxRecords")
  valid_21626924 = validateParameter(valid_21626924, JInt, required = false,
                                   default = nil)
  if valid_21626924 != nil:
    section.add "MaxRecords", valid_21626924
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626925: Call_PostDescribeDBInstances_21626909;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626925.validator(path, query, header, formData, body, _)
  let scheme = call_21626925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626925.makeUrl(scheme.get, call_21626925.host, call_21626925.base,
                               call_21626925.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626925, uri, valid, _)

proc call*(call_21626926: Call_PostDescribeDBInstances_21626909;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21626927 = newJObject()
  var formData_21626928 = newJObject()
  add(formData_21626928, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626928, "Marker", newJString(Marker))
  add(query_21626927, "Action", newJString(Action))
  if Filters != nil:
    formData_21626928.add "Filters", Filters
  add(formData_21626928, "MaxRecords", newJInt(MaxRecords))
  add(query_21626927, "Version", newJString(Version))
  result = call_21626926.call(nil, query_21626927, nil, formData_21626928, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_21626909(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_21626910, base: "/",
    makeUrl: url_PostDescribeDBInstances_21626911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_21626890 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBInstances_21626892(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_21626891(path: JsonNode; query: JsonNode;
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
  var valid_21626893 = query.getOrDefault("MaxRecords")
  valid_21626893 = validateParameter(valid_21626893, JInt, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "MaxRecords", valid_21626893
  var valid_21626894 = query.getOrDefault("Filters")
  valid_21626894 = validateParameter(valid_21626894, JArray, required = false,
                                   default = nil)
  if valid_21626894 != nil:
    section.add "Filters", valid_21626894
  var valid_21626895 = query.getOrDefault("Action")
  valid_21626895 = validateParameter(valid_21626895, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626895 != nil:
    section.add "Action", valid_21626895
  var valid_21626896 = query.getOrDefault("Marker")
  valid_21626896 = validateParameter(valid_21626896, JString, required = false,
                                   default = nil)
  if valid_21626896 != nil:
    section.add "Marker", valid_21626896
  var valid_21626897 = query.getOrDefault("Version")
  valid_21626897 = validateParameter(valid_21626897, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626897 != nil:
    section.add "Version", valid_21626897
  var valid_21626898 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "DBInstanceIdentifier", valid_21626898
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
  var valid_21626899 = header.getOrDefault("X-Amz-Date")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Date", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Security-Token", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-Algorithm", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Signature")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Signature", valid_21626903
  var valid_21626904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626904 = validateParameter(valid_21626904, JString, required = false,
                                   default = nil)
  if valid_21626904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626904
  var valid_21626905 = header.getOrDefault("X-Amz-Credential")
  valid_21626905 = validateParameter(valid_21626905, JString, required = false,
                                   default = nil)
  if valid_21626905 != nil:
    section.add "X-Amz-Credential", valid_21626905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626906: Call_GetDescribeDBInstances_21626890;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626906.validator(path, query, header, formData, body, _)
  let scheme = call_21626906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626906.makeUrl(scheme.get, call_21626906.host, call_21626906.base,
                               call_21626906.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626906, uri, valid, _)

proc call*(call_21626907: Call_GetDescribeDBInstances_21626890;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2014-09-01"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_21626908 = newJObject()
  add(query_21626908, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21626908.add "Filters", Filters
  add(query_21626908, "Action", newJString(Action))
  add(query_21626908, "Marker", newJString(Marker))
  add(query_21626908, "Version", newJString(Version))
  add(query_21626908, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626907.call(nil, query_21626908, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_21626890(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_21626891, base: "/",
    makeUrl: url_GetDescribeDBInstances_21626892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_21626951 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBLogFiles_21626953(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_21626952(path: JsonNode; query: JsonNode;
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
  var valid_21626954 = query.getOrDefault("Action")
  valid_21626954 = validateParameter(valid_21626954, JString, required = true,
                                   default = newJString("DescribeDBLogFiles"))
  if valid_21626954 != nil:
    section.add "Action", valid_21626954
  var valid_21626955 = query.getOrDefault("Version")
  valid_21626955 = validateParameter(valid_21626955, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626955 != nil:
    section.add "Version", valid_21626955
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
  var valid_21626956 = header.getOrDefault("X-Amz-Date")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Date", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-Security-Token", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626958
  var valid_21626959 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626959 = validateParameter(valid_21626959, JString, required = false,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "X-Amz-Algorithm", valid_21626959
  var valid_21626960 = header.getOrDefault("X-Amz-Signature")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "X-Amz-Signature", valid_21626960
  var valid_21626961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626961 = validateParameter(valid_21626961, JString, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626961
  var valid_21626962 = header.getOrDefault("X-Amz-Credential")
  valid_21626962 = validateParameter(valid_21626962, JString, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "X-Amz-Credential", valid_21626962
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
  var valid_21626963 = formData.getOrDefault("FilenameContains")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "FilenameContains", valid_21626963
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626964 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626964 = validateParameter(valid_21626964, JString, required = true,
                                   default = nil)
  if valid_21626964 != nil:
    section.add "DBInstanceIdentifier", valid_21626964
  var valid_21626965 = formData.getOrDefault("FileSize")
  valid_21626965 = validateParameter(valid_21626965, JInt, required = false,
                                   default = nil)
  if valid_21626965 != nil:
    section.add "FileSize", valid_21626965
  var valid_21626966 = formData.getOrDefault("Marker")
  valid_21626966 = validateParameter(valid_21626966, JString, required = false,
                                   default = nil)
  if valid_21626966 != nil:
    section.add "Marker", valid_21626966
  var valid_21626967 = formData.getOrDefault("Filters")
  valid_21626967 = validateParameter(valid_21626967, JArray, required = false,
                                   default = nil)
  if valid_21626967 != nil:
    section.add "Filters", valid_21626967
  var valid_21626968 = formData.getOrDefault("MaxRecords")
  valid_21626968 = validateParameter(valid_21626968, JInt, required = false,
                                   default = nil)
  if valid_21626968 != nil:
    section.add "MaxRecords", valid_21626968
  var valid_21626969 = formData.getOrDefault("FileLastWritten")
  valid_21626969 = validateParameter(valid_21626969, JInt, required = false,
                                   default = nil)
  if valid_21626969 != nil:
    section.add "FileLastWritten", valid_21626969
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626970: Call_PostDescribeDBLogFiles_21626951;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626970.validator(path, query, header, formData, body, _)
  let scheme = call_21626970.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626970.makeUrl(scheme.get, call_21626970.host, call_21626970.base,
                               call_21626970.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626970, uri, valid, _)

proc call*(call_21626971: Call_PostDescribeDBLogFiles_21626951;
          DBInstanceIdentifier: string; FilenameContains: string = "";
          FileSize: int = 0; Marker: string = ""; Action: string = "DescribeDBLogFiles";
          Filters: JsonNode = nil; MaxRecords: int = 0; FileLastWritten: int = 0;
          Version: string = "2014-09-01"): Recallable =
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
  var query_21626972 = newJObject()
  var formData_21626973 = newJObject()
  add(formData_21626973, "FilenameContains", newJString(FilenameContains))
  add(formData_21626973, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626973, "FileSize", newJInt(FileSize))
  add(formData_21626973, "Marker", newJString(Marker))
  add(query_21626972, "Action", newJString(Action))
  if Filters != nil:
    formData_21626973.add "Filters", Filters
  add(formData_21626973, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626973, "FileLastWritten", newJInt(FileLastWritten))
  add(query_21626972, "Version", newJString(Version))
  result = call_21626971.call(nil, query_21626972, nil, formData_21626973, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_21626951(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_21626952, base: "/",
    makeUrl: url_PostDescribeDBLogFiles_21626953,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_21626929 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBLogFiles_21626931(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_21626930(path: JsonNode; query: JsonNode;
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
  var valid_21626932 = query.getOrDefault("FileLastWritten")
  valid_21626932 = validateParameter(valid_21626932, JInt, required = false,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "FileLastWritten", valid_21626932
  var valid_21626933 = query.getOrDefault("MaxRecords")
  valid_21626933 = validateParameter(valid_21626933, JInt, required = false,
                                   default = nil)
  if valid_21626933 != nil:
    section.add "MaxRecords", valid_21626933
  var valid_21626934 = query.getOrDefault("FilenameContains")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "FilenameContains", valid_21626934
  var valid_21626935 = query.getOrDefault("FileSize")
  valid_21626935 = validateParameter(valid_21626935, JInt, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "FileSize", valid_21626935
  var valid_21626936 = query.getOrDefault("Filters")
  valid_21626936 = validateParameter(valid_21626936, JArray, required = false,
                                   default = nil)
  if valid_21626936 != nil:
    section.add "Filters", valid_21626936
  var valid_21626937 = query.getOrDefault("Action")
  valid_21626937 = validateParameter(valid_21626937, JString, required = true,
                                   default = newJString("DescribeDBLogFiles"))
  if valid_21626937 != nil:
    section.add "Action", valid_21626937
  var valid_21626938 = query.getOrDefault("Marker")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "Marker", valid_21626938
  var valid_21626939 = query.getOrDefault("Version")
  valid_21626939 = validateParameter(valid_21626939, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626939 != nil:
    section.add "Version", valid_21626939
  var valid_21626940 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626940 = validateParameter(valid_21626940, JString, required = true,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "DBInstanceIdentifier", valid_21626940
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
  var valid_21626941 = header.getOrDefault("X-Amz-Date")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Date", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-Security-Token", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626943
  var valid_21626944 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626944 = validateParameter(valid_21626944, JString, required = false,
                                   default = nil)
  if valid_21626944 != nil:
    section.add "X-Amz-Algorithm", valid_21626944
  var valid_21626945 = header.getOrDefault("X-Amz-Signature")
  valid_21626945 = validateParameter(valid_21626945, JString, required = false,
                                   default = nil)
  if valid_21626945 != nil:
    section.add "X-Amz-Signature", valid_21626945
  var valid_21626946 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626946 = validateParameter(valid_21626946, JString, required = false,
                                   default = nil)
  if valid_21626946 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626946
  var valid_21626947 = header.getOrDefault("X-Amz-Credential")
  valid_21626947 = validateParameter(valid_21626947, JString, required = false,
                                   default = nil)
  if valid_21626947 != nil:
    section.add "X-Amz-Credential", valid_21626947
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626948: Call_GetDescribeDBLogFiles_21626929;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626948.validator(path, query, header, formData, body, _)
  let scheme = call_21626948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626948.makeUrl(scheme.get, call_21626948.host, call_21626948.base,
                               call_21626948.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626948, uri, valid, _)

proc call*(call_21626949: Call_GetDescribeDBLogFiles_21626929;
          DBInstanceIdentifier: string; FileLastWritten: int = 0; MaxRecords: int = 0;
          FilenameContains: string = ""; FileSize: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBLogFiles"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_21626950 = newJObject()
  add(query_21626950, "FileLastWritten", newJInt(FileLastWritten))
  add(query_21626950, "MaxRecords", newJInt(MaxRecords))
  add(query_21626950, "FilenameContains", newJString(FilenameContains))
  add(query_21626950, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_21626950.add "Filters", Filters
  add(query_21626950, "Action", newJString(Action))
  add(query_21626950, "Marker", newJString(Marker))
  add(query_21626950, "Version", newJString(Version))
  add(query_21626950, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626949.call(nil, query_21626950, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_21626929(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_21626930, base: "/",
    makeUrl: url_GetDescribeDBLogFiles_21626931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_21626993 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBParameterGroups_21626995(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_21626994(path: JsonNode;
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
  var valid_21626996 = query.getOrDefault("Action")
  valid_21626996 = validateParameter(valid_21626996, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_21626996 != nil:
    section.add "Action", valid_21626996
  var valid_21626997 = query.getOrDefault("Version")
  valid_21626997 = validateParameter(valid_21626997, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626997 != nil:
    section.add "Version", valid_21626997
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
  var valid_21626998 = header.getOrDefault("X-Amz-Date")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Date", valid_21626998
  var valid_21626999 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "X-Amz-Security-Token", valid_21626999
  var valid_21627000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627000
  var valid_21627001 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627001 = validateParameter(valid_21627001, JString, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "X-Amz-Algorithm", valid_21627001
  var valid_21627002 = header.getOrDefault("X-Amz-Signature")
  valid_21627002 = validateParameter(valid_21627002, JString, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "X-Amz-Signature", valid_21627002
  var valid_21627003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627003 = validateParameter(valid_21627003, JString, required = false,
                                   default = nil)
  if valid_21627003 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627003
  var valid_21627004 = header.getOrDefault("X-Amz-Credential")
  valid_21627004 = validateParameter(valid_21627004, JString, required = false,
                                   default = nil)
  if valid_21627004 != nil:
    section.add "X-Amz-Credential", valid_21627004
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627005 = formData.getOrDefault("DBParameterGroupName")
  valid_21627005 = validateParameter(valid_21627005, JString, required = false,
                                   default = nil)
  if valid_21627005 != nil:
    section.add "DBParameterGroupName", valid_21627005
  var valid_21627006 = formData.getOrDefault("Marker")
  valid_21627006 = validateParameter(valid_21627006, JString, required = false,
                                   default = nil)
  if valid_21627006 != nil:
    section.add "Marker", valid_21627006
  var valid_21627007 = formData.getOrDefault("Filters")
  valid_21627007 = validateParameter(valid_21627007, JArray, required = false,
                                   default = nil)
  if valid_21627007 != nil:
    section.add "Filters", valid_21627007
  var valid_21627008 = formData.getOrDefault("MaxRecords")
  valid_21627008 = validateParameter(valid_21627008, JInt, required = false,
                                   default = nil)
  if valid_21627008 != nil:
    section.add "MaxRecords", valid_21627008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627009: Call_PostDescribeDBParameterGroups_21626993;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627009.validator(path, query, header, formData, body, _)
  let scheme = call_21627009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627009.makeUrl(scheme.get, call_21627009.host, call_21627009.base,
                               call_21627009.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627009, uri, valid, _)

proc call*(call_21627010: Call_PostDescribeDBParameterGroups_21626993;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627011 = newJObject()
  var formData_21627012 = newJObject()
  add(formData_21627012, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21627012, "Marker", newJString(Marker))
  add(query_21627011, "Action", newJString(Action))
  if Filters != nil:
    formData_21627012.add "Filters", Filters
  add(formData_21627012, "MaxRecords", newJInt(MaxRecords))
  add(query_21627011, "Version", newJString(Version))
  result = call_21627010.call(nil, query_21627011, nil, formData_21627012, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_21626993(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_21626994, base: "/",
    makeUrl: url_PostDescribeDBParameterGroups_21626995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_21626974 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBParameterGroups_21626976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_21626975(path: JsonNode;
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
  var valid_21626977 = query.getOrDefault("MaxRecords")
  valid_21626977 = validateParameter(valid_21626977, JInt, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "MaxRecords", valid_21626977
  var valid_21626978 = query.getOrDefault("Filters")
  valid_21626978 = validateParameter(valid_21626978, JArray, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "Filters", valid_21626978
  var valid_21626979 = query.getOrDefault("DBParameterGroupName")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "DBParameterGroupName", valid_21626979
  var valid_21626980 = query.getOrDefault("Action")
  valid_21626980 = validateParameter(valid_21626980, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_21626980 != nil:
    section.add "Action", valid_21626980
  var valid_21626981 = query.getOrDefault("Marker")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "Marker", valid_21626981
  var valid_21626982 = query.getOrDefault("Version")
  valid_21626982 = validateParameter(valid_21626982, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21626982 != nil:
    section.add "Version", valid_21626982
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
  var valid_21626983 = header.getOrDefault("X-Amz-Date")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Date", valid_21626983
  var valid_21626984 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626984 = validateParameter(valid_21626984, JString, required = false,
                                   default = nil)
  if valid_21626984 != nil:
    section.add "X-Amz-Security-Token", valid_21626984
  var valid_21626985 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626985 = validateParameter(valid_21626985, JString, required = false,
                                   default = nil)
  if valid_21626985 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626985
  var valid_21626986 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626986 = validateParameter(valid_21626986, JString, required = false,
                                   default = nil)
  if valid_21626986 != nil:
    section.add "X-Amz-Algorithm", valid_21626986
  var valid_21626987 = header.getOrDefault("X-Amz-Signature")
  valid_21626987 = validateParameter(valid_21626987, JString, required = false,
                                   default = nil)
  if valid_21626987 != nil:
    section.add "X-Amz-Signature", valid_21626987
  var valid_21626988 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626988 = validateParameter(valid_21626988, JString, required = false,
                                   default = nil)
  if valid_21626988 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626988
  var valid_21626989 = header.getOrDefault("X-Amz-Credential")
  valid_21626989 = validateParameter(valid_21626989, JString, required = false,
                                   default = nil)
  if valid_21626989 != nil:
    section.add "X-Amz-Credential", valid_21626989
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626990: Call_GetDescribeDBParameterGroups_21626974;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626990.validator(path, query, header, formData, body, _)
  let scheme = call_21626990.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626990.makeUrl(scheme.get, call_21626990.host, call_21626990.base,
                               call_21626990.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626990, uri, valid, _)

proc call*(call_21626991: Call_GetDescribeDBParameterGroups_21626974;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21626992 = newJObject()
  add(query_21626992, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21626992.add "Filters", Filters
  add(query_21626992, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626992, "Action", newJString(Action))
  add(query_21626992, "Marker", newJString(Marker))
  add(query_21626992, "Version", newJString(Version))
  result = call_21626991.call(nil, query_21626992, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_21626974(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_21626975, base: "/",
    makeUrl: url_GetDescribeDBParameterGroups_21626976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_21627033 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBParameters_21627035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_21627034(path: JsonNode; query: JsonNode;
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
  var valid_21627036 = query.getOrDefault("Action")
  valid_21627036 = validateParameter(valid_21627036, JString, required = true,
                                   default = newJString("DescribeDBParameters"))
  if valid_21627036 != nil:
    section.add "Action", valid_21627036
  var valid_21627037 = query.getOrDefault("Version")
  valid_21627037 = validateParameter(valid_21627037, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627037 != nil:
    section.add "Version", valid_21627037
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
  var valid_21627038 = header.getOrDefault("X-Amz-Date")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-Date", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Security-Token", valid_21627039
  var valid_21627040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627040
  var valid_21627041 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "X-Amz-Algorithm", valid_21627041
  var valid_21627042 = header.getOrDefault("X-Amz-Signature")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "X-Amz-Signature", valid_21627042
  var valid_21627043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627043
  var valid_21627044 = header.getOrDefault("X-Amz-Credential")
  valid_21627044 = validateParameter(valid_21627044, JString, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "X-Amz-Credential", valid_21627044
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627045 = formData.getOrDefault("DBParameterGroupName")
  valid_21627045 = validateParameter(valid_21627045, JString, required = true,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "DBParameterGroupName", valid_21627045
  var valid_21627046 = formData.getOrDefault("Marker")
  valid_21627046 = validateParameter(valid_21627046, JString, required = false,
                                   default = nil)
  if valid_21627046 != nil:
    section.add "Marker", valid_21627046
  var valid_21627047 = formData.getOrDefault("Filters")
  valid_21627047 = validateParameter(valid_21627047, JArray, required = false,
                                   default = nil)
  if valid_21627047 != nil:
    section.add "Filters", valid_21627047
  var valid_21627048 = formData.getOrDefault("MaxRecords")
  valid_21627048 = validateParameter(valid_21627048, JInt, required = false,
                                   default = nil)
  if valid_21627048 != nil:
    section.add "MaxRecords", valid_21627048
  var valid_21627049 = formData.getOrDefault("Source")
  valid_21627049 = validateParameter(valid_21627049, JString, required = false,
                                   default = nil)
  if valid_21627049 != nil:
    section.add "Source", valid_21627049
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627050: Call_PostDescribeDBParameters_21627033;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627050.validator(path, query, header, formData, body, _)
  let scheme = call_21627050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627050.makeUrl(scheme.get, call_21627050.host, call_21627050.base,
                               call_21627050.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627050, uri, valid, _)

proc call*(call_21627051: Call_PostDescribeDBParameters_21627033;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_21627052 = newJObject()
  var formData_21627053 = newJObject()
  add(formData_21627053, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21627053, "Marker", newJString(Marker))
  add(query_21627052, "Action", newJString(Action))
  if Filters != nil:
    formData_21627053.add "Filters", Filters
  add(formData_21627053, "MaxRecords", newJInt(MaxRecords))
  add(query_21627052, "Version", newJString(Version))
  add(formData_21627053, "Source", newJString(Source))
  result = call_21627051.call(nil, query_21627052, nil, formData_21627053, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_21627033(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_21627034, base: "/",
    makeUrl: url_PostDescribeDBParameters_21627035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_21627013 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBParameters_21627015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_21627014(path: JsonNode; query: JsonNode;
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
  var valid_21627016 = query.getOrDefault("MaxRecords")
  valid_21627016 = validateParameter(valid_21627016, JInt, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "MaxRecords", valid_21627016
  var valid_21627017 = query.getOrDefault("Filters")
  valid_21627017 = validateParameter(valid_21627017, JArray, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "Filters", valid_21627017
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627018 = query.getOrDefault("DBParameterGroupName")
  valid_21627018 = validateParameter(valid_21627018, JString, required = true,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "DBParameterGroupName", valid_21627018
  var valid_21627019 = query.getOrDefault("Action")
  valid_21627019 = validateParameter(valid_21627019, JString, required = true,
                                   default = newJString("DescribeDBParameters"))
  if valid_21627019 != nil:
    section.add "Action", valid_21627019
  var valid_21627020 = query.getOrDefault("Marker")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "Marker", valid_21627020
  var valid_21627021 = query.getOrDefault("Source")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "Source", valid_21627021
  var valid_21627022 = query.getOrDefault("Version")
  valid_21627022 = validateParameter(valid_21627022, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627022 != nil:
    section.add "Version", valid_21627022
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
  var valid_21627023 = header.getOrDefault("X-Amz-Date")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-Date", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Security-Token", valid_21627024
  var valid_21627025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627025 = validateParameter(valid_21627025, JString, required = false,
                                   default = nil)
  if valid_21627025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627025
  var valid_21627026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627026 = validateParameter(valid_21627026, JString, required = false,
                                   default = nil)
  if valid_21627026 != nil:
    section.add "X-Amz-Algorithm", valid_21627026
  var valid_21627027 = header.getOrDefault("X-Amz-Signature")
  valid_21627027 = validateParameter(valid_21627027, JString, required = false,
                                   default = nil)
  if valid_21627027 != nil:
    section.add "X-Amz-Signature", valid_21627027
  var valid_21627028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627028 = validateParameter(valid_21627028, JString, required = false,
                                   default = nil)
  if valid_21627028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627028
  var valid_21627029 = header.getOrDefault("X-Amz-Credential")
  valid_21627029 = validateParameter(valid_21627029, JString, required = false,
                                   default = nil)
  if valid_21627029 != nil:
    section.add "X-Amz-Credential", valid_21627029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627030: Call_GetDescribeDBParameters_21627013;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627030.validator(path, query, header, formData, body, _)
  let scheme = call_21627030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627030.makeUrl(scheme.get, call_21627030.host, call_21627030.base,
                               call_21627030.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627030, uri, valid, _)

proc call*(call_21627031: Call_GetDescribeDBParameters_21627013;
          DBParameterGroupName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_21627032 = newJObject()
  add(query_21627032, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627032.add "Filters", Filters
  add(query_21627032, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21627032, "Action", newJString(Action))
  add(query_21627032, "Marker", newJString(Marker))
  add(query_21627032, "Source", newJString(Source))
  add(query_21627032, "Version", newJString(Version))
  result = call_21627031.call(nil, query_21627032, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_21627013(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_21627014, base: "/",
    makeUrl: url_GetDescribeDBParameters_21627015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_21627073 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSecurityGroups_21627075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_21627074(path: JsonNode;
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
  var valid_21627076 = query.getOrDefault("Action")
  valid_21627076 = validateParameter(valid_21627076, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_21627076 != nil:
    section.add "Action", valid_21627076
  var valid_21627077 = query.getOrDefault("Version")
  valid_21627077 = validateParameter(valid_21627077, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627077 != nil:
    section.add "Version", valid_21627077
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
  var valid_21627078 = header.getOrDefault("X-Amz-Date")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Date", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-Security-Token", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627080
  var valid_21627081 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "X-Amz-Algorithm", valid_21627081
  var valid_21627082 = header.getOrDefault("X-Amz-Signature")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "X-Amz-Signature", valid_21627082
  var valid_21627083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627083 = validateParameter(valid_21627083, JString, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627083
  var valid_21627084 = header.getOrDefault("X-Amz-Credential")
  valid_21627084 = validateParameter(valid_21627084, JString, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "X-Amz-Credential", valid_21627084
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627085 = formData.getOrDefault("DBSecurityGroupName")
  valid_21627085 = validateParameter(valid_21627085, JString, required = false,
                                   default = nil)
  if valid_21627085 != nil:
    section.add "DBSecurityGroupName", valid_21627085
  var valid_21627086 = formData.getOrDefault("Marker")
  valid_21627086 = validateParameter(valid_21627086, JString, required = false,
                                   default = nil)
  if valid_21627086 != nil:
    section.add "Marker", valid_21627086
  var valid_21627087 = formData.getOrDefault("Filters")
  valid_21627087 = validateParameter(valid_21627087, JArray, required = false,
                                   default = nil)
  if valid_21627087 != nil:
    section.add "Filters", valid_21627087
  var valid_21627088 = formData.getOrDefault("MaxRecords")
  valid_21627088 = validateParameter(valid_21627088, JInt, required = false,
                                   default = nil)
  if valid_21627088 != nil:
    section.add "MaxRecords", valid_21627088
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627089: Call_PostDescribeDBSecurityGroups_21627073;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627089.validator(path, query, header, formData, body, _)
  let scheme = call_21627089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627089.makeUrl(scheme.get, call_21627089.host, call_21627089.base,
                               call_21627089.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627089, uri, valid, _)

proc call*(call_21627090: Call_PostDescribeDBSecurityGroups_21627073;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627091 = newJObject()
  var formData_21627092 = newJObject()
  add(formData_21627092, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_21627092, "Marker", newJString(Marker))
  add(query_21627091, "Action", newJString(Action))
  if Filters != nil:
    formData_21627092.add "Filters", Filters
  add(formData_21627092, "MaxRecords", newJInt(MaxRecords))
  add(query_21627091, "Version", newJString(Version))
  result = call_21627090.call(nil, query_21627091, nil, formData_21627092, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_21627073(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_21627074, base: "/",
    makeUrl: url_PostDescribeDBSecurityGroups_21627075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_21627054 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSecurityGroups_21627056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_21627055(path: JsonNode; query: JsonNode;
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
  var valid_21627057 = query.getOrDefault("MaxRecords")
  valid_21627057 = validateParameter(valid_21627057, JInt, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "MaxRecords", valid_21627057
  var valid_21627058 = query.getOrDefault("DBSecurityGroupName")
  valid_21627058 = validateParameter(valid_21627058, JString, required = false,
                                   default = nil)
  if valid_21627058 != nil:
    section.add "DBSecurityGroupName", valid_21627058
  var valid_21627059 = query.getOrDefault("Filters")
  valid_21627059 = validateParameter(valid_21627059, JArray, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "Filters", valid_21627059
  var valid_21627060 = query.getOrDefault("Action")
  valid_21627060 = validateParameter(valid_21627060, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_21627060 != nil:
    section.add "Action", valid_21627060
  var valid_21627061 = query.getOrDefault("Marker")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "Marker", valid_21627061
  var valid_21627062 = query.getOrDefault("Version")
  valid_21627062 = validateParameter(valid_21627062, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627062 != nil:
    section.add "Version", valid_21627062
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
  var valid_21627063 = header.getOrDefault("X-Amz-Date")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Date", valid_21627063
  var valid_21627064 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-Security-Token", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627065
  var valid_21627066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627066 = validateParameter(valid_21627066, JString, required = false,
                                   default = nil)
  if valid_21627066 != nil:
    section.add "X-Amz-Algorithm", valid_21627066
  var valid_21627067 = header.getOrDefault("X-Amz-Signature")
  valid_21627067 = validateParameter(valid_21627067, JString, required = false,
                                   default = nil)
  if valid_21627067 != nil:
    section.add "X-Amz-Signature", valid_21627067
  var valid_21627068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627068 = validateParameter(valid_21627068, JString, required = false,
                                   default = nil)
  if valid_21627068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627068
  var valid_21627069 = header.getOrDefault("X-Amz-Credential")
  valid_21627069 = validateParameter(valid_21627069, JString, required = false,
                                   default = nil)
  if valid_21627069 != nil:
    section.add "X-Amz-Credential", valid_21627069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627070: Call_GetDescribeDBSecurityGroups_21627054;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627070.validator(path, query, header, formData, body, _)
  let scheme = call_21627070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627070.makeUrl(scheme.get, call_21627070.host, call_21627070.base,
                               call_21627070.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627070, uri, valid, _)

proc call*(call_21627071: Call_GetDescribeDBSecurityGroups_21627054;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBSecurityGroups";
          Marker: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21627072 = newJObject()
  add(query_21627072, "MaxRecords", newJInt(MaxRecords))
  add(query_21627072, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_21627072.add "Filters", Filters
  add(query_21627072, "Action", newJString(Action))
  add(query_21627072, "Marker", newJString(Marker))
  add(query_21627072, "Version", newJString(Version))
  result = call_21627071.call(nil, query_21627072, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_21627054(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_21627055, base: "/",
    makeUrl: url_GetDescribeDBSecurityGroups_21627056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_21627114 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSnapshots_21627116(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_21627115(path: JsonNode; query: JsonNode;
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
  var valid_21627117 = query.getOrDefault("Action")
  valid_21627117 = validateParameter(valid_21627117, JString, required = true,
                                   default = newJString("DescribeDBSnapshots"))
  if valid_21627117 != nil:
    section.add "Action", valid_21627117
  var valid_21627118 = query.getOrDefault("Version")
  valid_21627118 = validateParameter(valid_21627118, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627118 != nil:
    section.add "Version", valid_21627118
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
  var valid_21627119 = header.getOrDefault("X-Amz-Date")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Date", valid_21627119
  var valid_21627120 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "X-Amz-Security-Token", valid_21627120
  var valid_21627121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627121 = validateParameter(valid_21627121, JString, required = false,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627121
  var valid_21627122 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627122 = validateParameter(valid_21627122, JString, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "X-Amz-Algorithm", valid_21627122
  var valid_21627123 = header.getOrDefault("X-Amz-Signature")
  valid_21627123 = validateParameter(valid_21627123, JString, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "X-Amz-Signature", valid_21627123
  var valid_21627124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627124 = validateParameter(valid_21627124, JString, required = false,
                                   default = nil)
  if valid_21627124 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627124
  var valid_21627125 = header.getOrDefault("X-Amz-Credential")
  valid_21627125 = validateParameter(valid_21627125, JString, required = false,
                                   default = nil)
  if valid_21627125 != nil:
    section.add "X-Amz-Credential", valid_21627125
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627126 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627126 = validateParameter(valid_21627126, JString, required = false,
                                   default = nil)
  if valid_21627126 != nil:
    section.add "DBInstanceIdentifier", valid_21627126
  var valid_21627127 = formData.getOrDefault("SnapshotType")
  valid_21627127 = validateParameter(valid_21627127, JString, required = false,
                                   default = nil)
  if valid_21627127 != nil:
    section.add "SnapshotType", valid_21627127
  var valid_21627128 = formData.getOrDefault("Marker")
  valid_21627128 = validateParameter(valid_21627128, JString, required = false,
                                   default = nil)
  if valid_21627128 != nil:
    section.add "Marker", valid_21627128
  var valid_21627129 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21627129 = validateParameter(valid_21627129, JString, required = false,
                                   default = nil)
  if valid_21627129 != nil:
    section.add "DBSnapshotIdentifier", valid_21627129
  var valid_21627130 = formData.getOrDefault("Filters")
  valid_21627130 = validateParameter(valid_21627130, JArray, required = false,
                                   default = nil)
  if valid_21627130 != nil:
    section.add "Filters", valid_21627130
  var valid_21627131 = formData.getOrDefault("MaxRecords")
  valid_21627131 = validateParameter(valid_21627131, JInt, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "MaxRecords", valid_21627131
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627132: Call_PostDescribeDBSnapshots_21627114;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627132.validator(path, query, header, formData, body, _)
  let scheme = call_21627132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627132.makeUrl(scheme.get, call_21627132.host, call_21627132.base,
                               call_21627132.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627132, uri, valid, _)

proc call*(call_21627133: Call_PostDescribeDBSnapshots_21627114;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627134 = newJObject()
  var formData_21627135 = newJObject()
  add(formData_21627135, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627135, "SnapshotType", newJString(SnapshotType))
  add(formData_21627135, "Marker", newJString(Marker))
  add(formData_21627135, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21627134, "Action", newJString(Action))
  if Filters != nil:
    formData_21627135.add "Filters", Filters
  add(formData_21627135, "MaxRecords", newJInt(MaxRecords))
  add(query_21627134, "Version", newJString(Version))
  result = call_21627133.call(nil, query_21627134, nil, formData_21627135, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_21627114(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_21627115, base: "/",
    makeUrl: url_PostDescribeDBSnapshots_21627116,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_21627093 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSnapshots_21627095(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_21627094(path: JsonNode; query: JsonNode;
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
  var valid_21627096 = query.getOrDefault("MaxRecords")
  valid_21627096 = validateParameter(valid_21627096, JInt, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "MaxRecords", valid_21627096
  var valid_21627097 = query.getOrDefault("Filters")
  valid_21627097 = validateParameter(valid_21627097, JArray, required = false,
                                   default = nil)
  if valid_21627097 != nil:
    section.add "Filters", valid_21627097
  var valid_21627098 = query.getOrDefault("Action")
  valid_21627098 = validateParameter(valid_21627098, JString, required = true,
                                   default = newJString("DescribeDBSnapshots"))
  if valid_21627098 != nil:
    section.add "Action", valid_21627098
  var valid_21627099 = query.getOrDefault("Marker")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "Marker", valid_21627099
  var valid_21627100 = query.getOrDefault("SnapshotType")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "SnapshotType", valid_21627100
  var valid_21627101 = query.getOrDefault("Version")
  valid_21627101 = validateParameter(valid_21627101, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627101 != nil:
    section.add "Version", valid_21627101
  var valid_21627102 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "DBInstanceIdentifier", valid_21627102
  var valid_21627103 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "DBSnapshotIdentifier", valid_21627103
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
  var valid_21627104 = header.getOrDefault("X-Amz-Date")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Date", valid_21627104
  var valid_21627105 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627105 = validateParameter(valid_21627105, JString, required = false,
                                   default = nil)
  if valid_21627105 != nil:
    section.add "X-Amz-Security-Token", valid_21627105
  var valid_21627106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627106 = validateParameter(valid_21627106, JString, required = false,
                                   default = nil)
  if valid_21627106 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627106
  var valid_21627107 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627107 = validateParameter(valid_21627107, JString, required = false,
                                   default = nil)
  if valid_21627107 != nil:
    section.add "X-Amz-Algorithm", valid_21627107
  var valid_21627108 = header.getOrDefault("X-Amz-Signature")
  valid_21627108 = validateParameter(valid_21627108, JString, required = false,
                                   default = nil)
  if valid_21627108 != nil:
    section.add "X-Amz-Signature", valid_21627108
  var valid_21627109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627109 = validateParameter(valid_21627109, JString, required = false,
                                   default = nil)
  if valid_21627109 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627109
  var valid_21627110 = header.getOrDefault("X-Amz-Credential")
  valid_21627110 = validateParameter(valid_21627110, JString, required = false,
                                   default = nil)
  if valid_21627110 != nil:
    section.add "X-Amz-Credential", valid_21627110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627111: Call_GetDescribeDBSnapshots_21627093;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627111.validator(path, query, header, formData, body, _)
  let scheme = call_21627111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627111.makeUrl(scheme.get, call_21627111.host, call_21627111.base,
                               call_21627111.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627111, uri, valid, _)

proc call*(call_21627112: Call_GetDescribeDBSnapshots_21627093;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2014-09-01";
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
  var query_21627113 = newJObject()
  add(query_21627113, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627113.add "Filters", Filters
  add(query_21627113, "Action", newJString(Action))
  add(query_21627113, "Marker", newJString(Marker))
  add(query_21627113, "SnapshotType", newJString(SnapshotType))
  add(query_21627113, "Version", newJString(Version))
  add(query_21627113, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627113, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21627112.call(nil, query_21627113, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_21627093(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_21627094, base: "/",
    makeUrl: url_GetDescribeDBSnapshots_21627095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_21627155 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSubnetGroups_21627157(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_21627156(path: JsonNode; query: JsonNode;
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
  var valid_21627158 = query.getOrDefault("Action")
  valid_21627158 = validateParameter(valid_21627158, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21627158 != nil:
    section.add "Action", valid_21627158
  var valid_21627159 = query.getOrDefault("Version")
  valid_21627159 = validateParameter(valid_21627159, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627159 != nil:
    section.add "Version", valid_21627159
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
  var valid_21627160 = header.getOrDefault("X-Amz-Date")
  valid_21627160 = validateParameter(valid_21627160, JString, required = false,
                                   default = nil)
  if valid_21627160 != nil:
    section.add "X-Amz-Date", valid_21627160
  var valid_21627161 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627161 = validateParameter(valid_21627161, JString, required = false,
                                   default = nil)
  if valid_21627161 != nil:
    section.add "X-Amz-Security-Token", valid_21627161
  var valid_21627162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627162 = validateParameter(valid_21627162, JString, required = false,
                                   default = nil)
  if valid_21627162 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627162
  var valid_21627163 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627163 = validateParameter(valid_21627163, JString, required = false,
                                   default = nil)
  if valid_21627163 != nil:
    section.add "X-Amz-Algorithm", valid_21627163
  var valid_21627164 = header.getOrDefault("X-Amz-Signature")
  valid_21627164 = validateParameter(valid_21627164, JString, required = false,
                                   default = nil)
  if valid_21627164 != nil:
    section.add "X-Amz-Signature", valid_21627164
  var valid_21627165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627165 = validateParameter(valid_21627165, JString, required = false,
                                   default = nil)
  if valid_21627165 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627165
  var valid_21627166 = header.getOrDefault("X-Amz-Credential")
  valid_21627166 = validateParameter(valid_21627166, JString, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "X-Amz-Credential", valid_21627166
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627167 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627167 = validateParameter(valid_21627167, JString, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "DBSubnetGroupName", valid_21627167
  var valid_21627168 = formData.getOrDefault("Marker")
  valid_21627168 = validateParameter(valid_21627168, JString, required = false,
                                   default = nil)
  if valid_21627168 != nil:
    section.add "Marker", valid_21627168
  var valid_21627169 = formData.getOrDefault("Filters")
  valid_21627169 = validateParameter(valid_21627169, JArray, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "Filters", valid_21627169
  var valid_21627170 = formData.getOrDefault("MaxRecords")
  valid_21627170 = validateParameter(valid_21627170, JInt, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "MaxRecords", valid_21627170
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627171: Call_PostDescribeDBSubnetGroups_21627155;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627171.validator(path, query, header, formData, body, _)
  let scheme = call_21627171.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627171.makeUrl(scheme.get, call_21627171.host, call_21627171.base,
                               call_21627171.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627171, uri, valid, _)

proc call*(call_21627172: Call_PostDescribeDBSubnetGroups_21627155;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627173 = newJObject()
  var formData_21627174 = newJObject()
  add(formData_21627174, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21627174, "Marker", newJString(Marker))
  add(query_21627173, "Action", newJString(Action))
  if Filters != nil:
    formData_21627174.add "Filters", Filters
  add(formData_21627174, "MaxRecords", newJInt(MaxRecords))
  add(query_21627173, "Version", newJString(Version))
  result = call_21627172.call(nil, query_21627173, nil, formData_21627174, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_21627155(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_21627156, base: "/",
    makeUrl: url_PostDescribeDBSubnetGroups_21627157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_21627136 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSubnetGroups_21627138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_21627137(path: JsonNode; query: JsonNode;
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
  var valid_21627139 = query.getOrDefault("MaxRecords")
  valid_21627139 = validateParameter(valid_21627139, JInt, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "MaxRecords", valid_21627139
  var valid_21627140 = query.getOrDefault("Filters")
  valid_21627140 = validateParameter(valid_21627140, JArray, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "Filters", valid_21627140
  var valid_21627141 = query.getOrDefault("Action")
  valid_21627141 = validateParameter(valid_21627141, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21627141 != nil:
    section.add "Action", valid_21627141
  var valid_21627142 = query.getOrDefault("Marker")
  valid_21627142 = validateParameter(valid_21627142, JString, required = false,
                                   default = nil)
  if valid_21627142 != nil:
    section.add "Marker", valid_21627142
  var valid_21627143 = query.getOrDefault("DBSubnetGroupName")
  valid_21627143 = validateParameter(valid_21627143, JString, required = false,
                                   default = nil)
  if valid_21627143 != nil:
    section.add "DBSubnetGroupName", valid_21627143
  var valid_21627144 = query.getOrDefault("Version")
  valid_21627144 = validateParameter(valid_21627144, JString, required = true,
                                   default = newJString("2014-09-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627152: Call_GetDescribeDBSubnetGroups_21627136;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627152.validator(path, query, header, formData, body, _)
  let scheme = call_21627152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627152.makeUrl(scheme.get, call_21627152.host, call_21627152.base,
                               call_21627152.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627152, uri, valid, _)

proc call*(call_21627153: Call_GetDescribeDBSubnetGroups_21627136;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_21627154 = newJObject()
  add(query_21627154, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627154.add "Filters", Filters
  add(query_21627154, "Action", newJString(Action))
  add(query_21627154, "Marker", newJString(Marker))
  add(query_21627154, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627154, "Version", newJString(Version))
  result = call_21627153.call(nil, query_21627154, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_21627136(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_21627137, base: "/",
    makeUrl: url_GetDescribeDBSubnetGroups_21627138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_21627194 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEngineDefaultParameters_21627196(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_21627195(path: JsonNode;
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
  var valid_21627197 = query.getOrDefault("Action")
  valid_21627197 = validateParameter(valid_21627197, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_21627197 != nil:
    section.add "Action", valid_21627197
  var valid_21627198 = query.getOrDefault("Version")
  valid_21627198 = validateParameter(valid_21627198, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627198 != nil:
    section.add "Version", valid_21627198
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
  var valid_21627199 = header.getOrDefault("X-Amz-Date")
  valid_21627199 = validateParameter(valid_21627199, JString, required = false,
                                   default = nil)
  if valid_21627199 != nil:
    section.add "X-Amz-Date", valid_21627199
  var valid_21627200 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627200 = validateParameter(valid_21627200, JString, required = false,
                                   default = nil)
  if valid_21627200 != nil:
    section.add "X-Amz-Security-Token", valid_21627200
  var valid_21627201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627201 = validateParameter(valid_21627201, JString, required = false,
                                   default = nil)
  if valid_21627201 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627201
  var valid_21627202 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627202 = validateParameter(valid_21627202, JString, required = false,
                                   default = nil)
  if valid_21627202 != nil:
    section.add "X-Amz-Algorithm", valid_21627202
  var valid_21627203 = header.getOrDefault("X-Amz-Signature")
  valid_21627203 = validateParameter(valid_21627203, JString, required = false,
                                   default = nil)
  if valid_21627203 != nil:
    section.add "X-Amz-Signature", valid_21627203
  var valid_21627204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627204 = validateParameter(valid_21627204, JString, required = false,
                                   default = nil)
  if valid_21627204 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627204
  var valid_21627205 = header.getOrDefault("X-Amz-Credential")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = nil)
  if valid_21627205 != nil:
    section.add "X-Amz-Credential", valid_21627205
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627206 = formData.getOrDefault("Marker")
  valid_21627206 = validateParameter(valid_21627206, JString, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "Marker", valid_21627206
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21627207 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21627207 = validateParameter(valid_21627207, JString, required = true,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "DBParameterGroupFamily", valid_21627207
  var valid_21627208 = formData.getOrDefault("Filters")
  valid_21627208 = validateParameter(valid_21627208, JArray, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "Filters", valid_21627208
  var valid_21627209 = formData.getOrDefault("MaxRecords")
  valid_21627209 = validateParameter(valid_21627209, JInt, required = false,
                                   default = nil)
  if valid_21627209 != nil:
    section.add "MaxRecords", valid_21627209
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627210: Call_PostDescribeEngineDefaultParameters_21627194;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627210.validator(path, query, header, formData, body, _)
  let scheme = call_21627210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627210.makeUrl(scheme.get, call_21627210.host, call_21627210.base,
                               call_21627210.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627210, uri, valid, _)

proc call*(call_21627211: Call_PostDescribeEngineDefaultParameters_21627194;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627212 = newJObject()
  var formData_21627213 = newJObject()
  add(formData_21627213, "Marker", newJString(Marker))
  add(query_21627212, "Action", newJString(Action))
  add(formData_21627213, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_21627213.add "Filters", Filters
  add(formData_21627213, "MaxRecords", newJInt(MaxRecords))
  add(query_21627212, "Version", newJString(Version))
  result = call_21627211.call(nil, query_21627212, nil, formData_21627213, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_21627194(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_21627195, base: "/",
    makeUrl: url_PostDescribeEngineDefaultParameters_21627196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_21627175 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEngineDefaultParameters_21627177(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_21627176(path: JsonNode;
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
  var valid_21627178 = query.getOrDefault("MaxRecords")
  valid_21627178 = validateParameter(valid_21627178, JInt, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "MaxRecords", valid_21627178
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21627179 = query.getOrDefault("DBParameterGroupFamily")
  valid_21627179 = validateParameter(valid_21627179, JString, required = true,
                                   default = nil)
  if valid_21627179 != nil:
    section.add "DBParameterGroupFamily", valid_21627179
  var valid_21627180 = query.getOrDefault("Filters")
  valid_21627180 = validateParameter(valid_21627180, JArray, required = false,
                                   default = nil)
  if valid_21627180 != nil:
    section.add "Filters", valid_21627180
  var valid_21627181 = query.getOrDefault("Action")
  valid_21627181 = validateParameter(valid_21627181, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_21627181 != nil:
    section.add "Action", valid_21627181
  var valid_21627182 = query.getOrDefault("Marker")
  valid_21627182 = validateParameter(valid_21627182, JString, required = false,
                                   default = nil)
  if valid_21627182 != nil:
    section.add "Marker", valid_21627182
  var valid_21627183 = query.getOrDefault("Version")
  valid_21627183 = validateParameter(valid_21627183, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627183 != nil:
    section.add "Version", valid_21627183
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
  var valid_21627184 = header.getOrDefault("X-Amz-Date")
  valid_21627184 = validateParameter(valid_21627184, JString, required = false,
                                   default = nil)
  if valid_21627184 != nil:
    section.add "X-Amz-Date", valid_21627184
  var valid_21627185 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627185 = validateParameter(valid_21627185, JString, required = false,
                                   default = nil)
  if valid_21627185 != nil:
    section.add "X-Amz-Security-Token", valid_21627185
  var valid_21627186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627186 = validateParameter(valid_21627186, JString, required = false,
                                   default = nil)
  if valid_21627186 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627186
  var valid_21627187 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Algorithm", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Signature")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Signature", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Credential")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Credential", valid_21627190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627191: Call_GetDescribeEngineDefaultParameters_21627175;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627191.validator(path, query, header, formData, body, _)
  let scheme = call_21627191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627191.makeUrl(scheme.get, call_21627191.host, call_21627191.base,
                               call_21627191.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627191, uri, valid, _)

proc call*(call_21627192: Call_GetDescribeEngineDefaultParameters_21627175;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21627193 = newJObject()
  add(query_21627193, "MaxRecords", newJInt(MaxRecords))
  add(query_21627193, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_21627193.add "Filters", Filters
  add(query_21627193, "Action", newJString(Action))
  add(query_21627193, "Marker", newJString(Marker))
  add(query_21627193, "Version", newJString(Version))
  result = call_21627192.call(nil, query_21627193, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_21627175(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_21627176, base: "/",
    makeUrl: url_GetDescribeEngineDefaultParameters_21627177,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_21627231 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEventCategories_21627233(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_21627232(path: JsonNode; query: JsonNode;
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
  var valid_21627234 = query.getOrDefault("Action")
  valid_21627234 = validateParameter(valid_21627234, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21627234 != nil:
    section.add "Action", valid_21627234
  var valid_21627235 = query.getOrDefault("Version")
  valid_21627235 = validateParameter(valid_21627235, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627235 != nil:
    section.add "Version", valid_21627235
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
  var valid_21627236 = header.getOrDefault("X-Amz-Date")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-Date", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Security-Token", valid_21627237
  var valid_21627238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627238
  var valid_21627239 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627239 = validateParameter(valid_21627239, JString, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "X-Amz-Algorithm", valid_21627239
  var valid_21627240 = header.getOrDefault("X-Amz-Signature")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "X-Amz-Signature", valid_21627240
  var valid_21627241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627241
  var valid_21627242 = header.getOrDefault("X-Amz-Credential")
  valid_21627242 = validateParameter(valid_21627242, JString, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "X-Amz-Credential", valid_21627242
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_21627243 = formData.getOrDefault("Filters")
  valid_21627243 = validateParameter(valid_21627243, JArray, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "Filters", valid_21627243
  var valid_21627244 = formData.getOrDefault("SourceType")
  valid_21627244 = validateParameter(valid_21627244, JString, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "SourceType", valid_21627244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627245: Call_PostDescribeEventCategories_21627231;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627245.validator(path, query, header, formData, body, _)
  let scheme = call_21627245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627245.makeUrl(scheme.get, call_21627245.host, call_21627245.base,
                               call_21627245.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627245, uri, valid, _)

proc call*(call_21627246: Call_PostDescribeEventCategories_21627231;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627247 = newJObject()
  var formData_21627248 = newJObject()
  add(query_21627247, "Action", newJString(Action))
  if Filters != nil:
    formData_21627248.add "Filters", Filters
  add(query_21627247, "Version", newJString(Version))
  add(formData_21627248, "SourceType", newJString(SourceType))
  result = call_21627246.call(nil, query_21627247, nil, formData_21627248, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_21627231(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_21627232, base: "/",
    makeUrl: url_PostDescribeEventCategories_21627233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_21627214 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEventCategories_21627216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_21627215(path: JsonNode; query: JsonNode;
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
  var valid_21627217 = query.getOrDefault("SourceType")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "SourceType", valid_21627217
  var valid_21627218 = query.getOrDefault("Filters")
  valid_21627218 = validateParameter(valid_21627218, JArray, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "Filters", valid_21627218
  var valid_21627219 = query.getOrDefault("Action")
  valid_21627219 = validateParameter(valid_21627219, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21627219 != nil:
    section.add "Action", valid_21627219
  var valid_21627220 = query.getOrDefault("Version")
  valid_21627220 = validateParameter(valid_21627220, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627220 != nil:
    section.add "Version", valid_21627220
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
  var valid_21627221 = header.getOrDefault("X-Amz-Date")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-Date", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Security-Token", valid_21627222
  var valid_21627223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627223 = validateParameter(valid_21627223, JString, required = false,
                                   default = nil)
  if valid_21627223 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627223
  var valid_21627224 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627224 = validateParameter(valid_21627224, JString, required = false,
                                   default = nil)
  if valid_21627224 != nil:
    section.add "X-Amz-Algorithm", valid_21627224
  var valid_21627225 = header.getOrDefault("X-Amz-Signature")
  valid_21627225 = validateParameter(valid_21627225, JString, required = false,
                                   default = nil)
  if valid_21627225 != nil:
    section.add "X-Amz-Signature", valid_21627225
  var valid_21627226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627226 = validateParameter(valid_21627226, JString, required = false,
                                   default = nil)
  if valid_21627226 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627226
  var valid_21627227 = header.getOrDefault("X-Amz-Credential")
  valid_21627227 = validateParameter(valid_21627227, JString, required = false,
                                   default = nil)
  if valid_21627227 != nil:
    section.add "X-Amz-Credential", valid_21627227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627228: Call_GetDescribeEventCategories_21627214;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627228.validator(path, query, header, formData, body, _)
  let scheme = call_21627228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627228.makeUrl(scheme.get, call_21627228.host, call_21627228.base,
                               call_21627228.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627228, uri, valid, _)

proc call*(call_21627229: Call_GetDescribeEventCategories_21627214;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627230 = newJObject()
  add(query_21627230, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_21627230.add "Filters", Filters
  add(query_21627230, "Action", newJString(Action))
  add(query_21627230, "Version", newJString(Version))
  result = call_21627229.call(nil, query_21627230, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_21627214(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_21627215, base: "/",
    makeUrl: url_GetDescribeEventCategories_21627216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_21627268 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEventSubscriptions_21627270(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_21627269(path: JsonNode;
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
  var valid_21627271 = query.getOrDefault("Action")
  valid_21627271 = validateParameter(valid_21627271, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_21627271 != nil:
    section.add "Action", valid_21627271
  var valid_21627272 = query.getOrDefault("Version")
  valid_21627272 = validateParameter(valid_21627272, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627272 != nil:
    section.add "Version", valid_21627272
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
  var valid_21627273 = header.getOrDefault("X-Amz-Date")
  valid_21627273 = validateParameter(valid_21627273, JString, required = false,
                                   default = nil)
  if valid_21627273 != nil:
    section.add "X-Amz-Date", valid_21627273
  var valid_21627274 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627274 = validateParameter(valid_21627274, JString, required = false,
                                   default = nil)
  if valid_21627274 != nil:
    section.add "X-Amz-Security-Token", valid_21627274
  var valid_21627275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627275 = validateParameter(valid_21627275, JString, required = false,
                                   default = nil)
  if valid_21627275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627275
  var valid_21627276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Algorithm", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-Signature")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Signature", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Credential")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Credential", valid_21627279
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627280 = formData.getOrDefault("Marker")
  valid_21627280 = validateParameter(valid_21627280, JString, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "Marker", valid_21627280
  var valid_21627281 = formData.getOrDefault("SubscriptionName")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "SubscriptionName", valid_21627281
  var valid_21627282 = formData.getOrDefault("Filters")
  valid_21627282 = validateParameter(valid_21627282, JArray, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "Filters", valid_21627282
  var valid_21627283 = formData.getOrDefault("MaxRecords")
  valid_21627283 = validateParameter(valid_21627283, JInt, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "MaxRecords", valid_21627283
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627284: Call_PostDescribeEventSubscriptions_21627268;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627284.validator(path, query, header, formData, body, _)
  let scheme = call_21627284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627284.makeUrl(scheme.get, call_21627284.host, call_21627284.base,
                               call_21627284.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627284, uri, valid, _)

proc call*(call_21627285: Call_PostDescribeEventSubscriptions_21627268;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627286 = newJObject()
  var formData_21627287 = newJObject()
  add(formData_21627287, "Marker", newJString(Marker))
  add(formData_21627287, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627286, "Action", newJString(Action))
  if Filters != nil:
    formData_21627287.add "Filters", Filters
  add(formData_21627287, "MaxRecords", newJInt(MaxRecords))
  add(query_21627286, "Version", newJString(Version))
  result = call_21627285.call(nil, query_21627286, nil, formData_21627287, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_21627268(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_21627269, base: "/",
    makeUrl: url_PostDescribeEventSubscriptions_21627270,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_21627249 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEventSubscriptions_21627251(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_21627250(path: JsonNode;
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
  var valid_21627252 = query.getOrDefault("MaxRecords")
  valid_21627252 = validateParameter(valid_21627252, JInt, required = false,
                                   default = nil)
  if valid_21627252 != nil:
    section.add "MaxRecords", valid_21627252
  var valid_21627253 = query.getOrDefault("Filters")
  valid_21627253 = validateParameter(valid_21627253, JArray, required = false,
                                   default = nil)
  if valid_21627253 != nil:
    section.add "Filters", valid_21627253
  var valid_21627254 = query.getOrDefault("Action")
  valid_21627254 = validateParameter(valid_21627254, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_21627254 != nil:
    section.add "Action", valid_21627254
  var valid_21627255 = query.getOrDefault("Marker")
  valid_21627255 = validateParameter(valid_21627255, JString, required = false,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "Marker", valid_21627255
  var valid_21627256 = query.getOrDefault("SubscriptionName")
  valid_21627256 = validateParameter(valid_21627256, JString, required = false,
                                   default = nil)
  if valid_21627256 != nil:
    section.add "SubscriptionName", valid_21627256
  var valid_21627257 = query.getOrDefault("Version")
  valid_21627257 = validateParameter(valid_21627257, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627257 != nil:
    section.add "Version", valid_21627257
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
  var valid_21627258 = header.getOrDefault("X-Amz-Date")
  valid_21627258 = validateParameter(valid_21627258, JString, required = false,
                                   default = nil)
  if valid_21627258 != nil:
    section.add "X-Amz-Date", valid_21627258
  var valid_21627259 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627259 = validateParameter(valid_21627259, JString, required = false,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "X-Amz-Security-Token", valid_21627259
  var valid_21627260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627260
  var valid_21627261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627261 = validateParameter(valid_21627261, JString, required = false,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "X-Amz-Algorithm", valid_21627261
  var valid_21627262 = header.getOrDefault("X-Amz-Signature")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "X-Amz-Signature", valid_21627262
  var valid_21627263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627263
  var valid_21627264 = header.getOrDefault("X-Amz-Credential")
  valid_21627264 = validateParameter(valid_21627264, JString, required = false,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "X-Amz-Credential", valid_21627264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627265: Call_GetDescribeEventSubscriptions_21627249;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627265.validator(path, query, header, formData, body, _)
  let scheme = call_21627265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627265.makeUrl(scheme.get, call_21627265.host, call_21627265.base,
                               call_21627265.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627265, uri, valid, _)

proc call*(call_21627266: Call_GetDescribeEventSubscriptions_21627249;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeEventSubscriptions"; Marker: string = "";
          SubscriptionName: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_21627267 = newJObject()
  add(query_21627267, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627267.add "Filters", Filters
  add(query_21627267, "Action", newJString(Action))
  add(query_21627267, "Marker", newJString(Marker))
  add(query_21627267, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627267, "Version", newJString(Version))
  result = call_21627266.call(nil, query_21627267, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_21627249(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_21627250, base: "/",
    makeUrl: url_GetDescribeEventSubscriptions_21627251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_21627312 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEvents_21627314(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_21627313(path: JsonNode; query: JsonNode;
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
  var valid_21627315 = query.getOrDefault("Action")
  valid_21627315 = validateParameter(valid_21627315, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627315 != nil:
    section.add "Action", valid_21627315
  var valid_21627316 = query.getOrDefault("Version")
  valid_21627316 = validateParameter(valid_21627316, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627316 != nil:
    section.add "Version", valid_21627316
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
  var valid_21627317 = header.getOrDefault("X-Amz-Date")
  valid_21627317 = validateParameter(valid_21627317, JString, required = false,
                                   default = nil)
  if valid_21627317 != nil:
    section.add "X-Amz-Date", valid_21627317
  var valid_21627318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627318 = validateParameter(valid_21627318, JString, required = false,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "X-Amz-Security-Token", valid_21627318
  var valid_21627319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627319 = validateParameter(valid_21627319, JString, required = false,
                                   default = nil)
  if valid_21627319 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627319
  var valid_21627320 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-Algorithm", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Signature")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Signature", valid_21627321
  var valid_21627322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627322 = validateParameter(valid_21627322, JString, required = false,
                                   default = nil)
  if valid_21627322 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-Credential")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-Credential", valid_21627323
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
  var valid_21627324 = formData.getOrDefault("SourceIdentifier")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "SourceIdentifier", valid_21627324
  var valid_21627325 = formData.getOrDefault("EventCategories")
  valid_21627325 = validateParameter(valid_21627325, JArray, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "EventCategories", valid_21627325
  var valid_21627326 = formData.getOrDefault("Marker")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "Marker", valid_21627326
  var valid_21627327 = formData.getOrDefault("StartTime")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "StartTime", valid_21627327
  var valid_21627328 = formData.getOrDefault("Duration")
  valid_21627328 = validateParameter(valid_21627328, JInt, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "Duration", valid_21627328
  var valid_21627329 = formData.getOrDefault("Filters")
  valid_21627329 = validateParameter(valid_21627329, JArray, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "Filters", valid_21627329
  var valid_21627330 = formData.getOrDefault("EndTime")
  valid_21627330 = validateParameter(valid_21627330, JString, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "EndTime", valid_21627330
  var valid_21627331 = formData.getOrDefault("MaxRecords")
  valid_21627331 = validateParameter(valid_21627331, JInt, required = false,
                                   default = nil)
  if valid_21627331 != nil:
    section.add "MaxRecords", valid_21627331
  var valid_21627332 = formData.getOrDefault("SourceType")
  valid_21627332 = validateParameter(valid_21627332, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21627332 != nil:
    section.add "SourceType", valid_21627332
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627333: Call_PostDescribeEvents_21627312; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627333.validator(path, query, header, formData, body, _)
  let scheme = call_21627333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627333.makeUrl(scheme.get, call_21627333.host, call_21627333.base,
                               call_21627333.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627333, uri, valid, _)

proc call*(call_21627334: Call_PostDescribeEvents_21627312;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; MaxRecords: int = 0; Version: string = "2014-09-01";
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
  var query_21627335 = newJObject()
  var formData_21627336 = newJObject()
  add(formData_21627336, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_21627336.add "EventCategories", EventCategories
  add(formData_21627336, "Marker", newJString(Marker))
  add(formData_21627336, "StartTime", newJString(StartTime))
  add(query_21627335, "Action", newJString(Action))
  add(formData_21627336, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_21627336.add "Filters", Filters
  add(formData_21627336, "EndTime", newJString(EndTime))
  add(formData_21627336, "MaxRecords", newJInt(MaxRecords))
  add(query_21627335, "Version", newJString(Version))
  add(formData_21627336, "SourceType", newJString(SourceType))
  result = call_21627334.call(nil, query_21627335, nil, formData_21627336, nil)

var postDescribeEvents* = Call_PostDescribeEvents_21627312(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_21627313, base: "/",
    makeUrl: url_PostDescribeEvents_21627314, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_21627288 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEvents_21627290(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_21627289(path: JsonNode; query: JsonNode;
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
  var valid_21627291 = query.getOrDefault("SourceType")
  valid_21627291 = validateParameter(valid_21627291, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21627291 != nil:
    section.add "SourceType", valid_21627291
  var valid_21627292 = query.getOrDefault("MaxRecords")
  valid_21627292 = validateParameter(valid_21627292, JInt, required = false,
                                   default = nil)
  if valid_21627292 != nil:
    section.add "MaxRecords", valid_21627292
  var valid_21627293 = query.getOrDefault("StartTime")
  valid_21627293 = validateParameter(valid_21627293, JString, required = false,
                                   default = nil)
  if valid_21627293 != nil:
    section.add "StartTime", valid_21627293
  var valid_21627294 = query.getOrDefault("Filters")
  valid_21627294 = validateParameter(valid_21627294, JArray, required = false,
                                   default = nil)
  if valid_21627294 != nil:
    section.add "Filters", valid_21627294
  var valid_21627295 = query.getOrDefault("Action")
  valid_21627295 = validateParameter(valid_21627295, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627295 != nil:
    section.add "Action", valid_21627295
  var valid_21627296 = query.getOrDefault("SourceIdentifier")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "SourceIdentifier", valid_21627296
  var valid_21627297 = query.getOrDefault("Marker")
  valid_21627297 = validateParameter(valid_21627297, JString, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "Marker", valid_21627297
  var valid_21627298 = query.getOrDefault("EventCategories")
  valid_21627298 = validateParameter(valid_21627298, JArray, required = false,
                                   default = nil)
  if valid_21627298 != nil:
    section.add "EventCategories", valid_21627298
  var valid_21627299 = query.getOrDefault("Duration")
  valid_21627299 = validateParameter(valid_21627299, JInt, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "Duration", valid_21627299
  var valid_21627300 = query.getOrDefault("EndTime")
  valid_21627300 = validateParameter(valid_21627300, JString, required = false,
                                   default = nil)
  if valid_21627300 != nil:
    section.add "EndTime", valid_21627300
  var valid_21627301 = query.getOrDefault("Version")
  valid_21627301 = validateParameter(valid_21627301, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627301 != nil:
    section.add "Version", valid_21627301
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
  var valid_21627302 = header.getOrDefault("X-Amz-Date")
  valid_21627302 = validateParameter(valid_21627302, JString, required = false,
                                   default = nil)
  if valid_21627302 != nil:
    section.add "X-Amz-Date", valid_21627302
  var valid_21627303 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627303 = validateParameter(valid_21627303, JString, required = false,
                                   default = nil)
  if valid_21627303 != nil:
    section.add "X-Amz-Security-Token", valid_21627303
  var valid_21627304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627304 = validateParameter(valid_21627304, JString, required = false,
                                   default = nil)
  if valid_21627304 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627304
  var valid_21627305 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Algorithm", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Signature")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Signature", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-Credential")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-Credential", valid_21627308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627309: Call_GetDescribeEvents_21627288; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627309.validator(path, query, header, formData, body, _)
  let scheme = call_21627309.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627309.makeUrl(scheme.get, call_21627309.host, call_21627309.base,
                               call_21627309.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627309, uri, valid, _)

proc call*(call_21627310: Call_GetDescribeEvents_21627288;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEvents"; SourceIdentifier: string = "";
          Marker: string = ""; EventCategories: JsonNode = nil; Duration: int = 0;
          EndTime: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_21627311 = newJObject()
  add(query_21627311, "SourceType", newJString(SourceType))
  add(query_21627311, "MaxRecords", newJInt(MaxRecords))
  add(query_21627311, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_21627311.add "Filters", Filters
  add(query_21627311, "Action", newJString(Action))
  add(query_21627311, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21627311, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_21627311.add "EventCategories", EventCategories
  add(query_21627311, "Duration", newJInt(Duration))
  add(query_21627311, "EndTime", newJString(EndTime))
  add(query_21627311, "Version", newJString(Version))
  result = call_21627310.call(nil, query_21627311, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_21627288(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_21627289,
    base: "/", makeUrl: url_GetDescribeEvents_21627290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_21627357 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOptionGroupOptions_21627359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_21627358(path: JsonNode;
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
  var valid_21627360 = query.getOrDefault("Action")
  valid_21627360 = validateParameter(valid_21627360, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_21627360 != nil:
    section.add "Action", valid_21627360
  var valid_21627361 = query.getOrDefault("Version")
  valid_21627361 = validateParameter(valid_21627361, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627361 != nil:
    section.add "Version", valid_21627361
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
  var valid_21627362 = header.getOrDefault("X-Amz-Date")
  valid_21627362 = validateParameter(valid_21627362, JString, required = false,
                                   default = nil)
  if valid_21627362 != nil:
    section.add "X-Amz-Date", valid_21627362
  var valid_21627363 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627363 = validateParameter(valid_21627363, JString, required = false,
                                   default = nil)
  if valid_21627363 != nil:
    section.add "X-Amz-Security-Token", valid_21627363
  var valid_21627364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627364 = validateParameter(valid_21627364, JString, required = false,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627364
  var valid_21627365 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "X-Amz-Algorithm", valid_21627365
  var valid_21627366 = header.getOrDefault("X-Amz-Signature")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "X-Amz-Signature", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-Credential")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-Credential", valid_21627368
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627369 = formData.getOrDefault("MajorEngineVersion")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "MajorEngineVersion", valid_21627369
  var valid_21627370 = formData.getOrDefault("Marker")
  valid_21627370 = validateParameter(valid_21627370, JString, required = false,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "Marker", valid_21627370
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_21627371 = formData.getOrDefault("EngineName")
  valid_21627371 = validateParameter(valid_21627371, JString, required = true,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "EngineName", valid_21627371
  var valid_21627372 = formData.getOrDefault("Filters")
  valid_21627372 = validateParameter(valid_21627372, JArray, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "Filters", valid_21627372
  var valid_21627373 = formData.getOrDefault("MaxRecords")
  valid_21627373 = validateParameter(valid_21627373, JInt, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "MaxRecords", valid_21627373
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627374: Call_PostDescribeOptionGroupOptions_21627357;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627374.validator(path, query, header, formData, body, _)
  let scheme = call_21627374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627374.makeUrl(scheme.get, call_21627374.host, call_21627374.base,
                               call_21627374.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627374, uri, valid, _)

proc call*(call_21627375: Call_PostDescribeOptionGroupOptions_21627357;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627376 = newJObject()
  var formData_21627377 = newJObject()
  add(formData_21627377, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21627377, "Marker", newJString(Marker))
  add(query_21627376, "Action", newJString(Action))
  add(formData_21627377, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_21627377.add "Filters", Filters
  add(formData_21627377, "MaxRecords", newJInt(MaxRecords))
  add(query_21627376, "Version", newJString(Version))
  result = call_21627375.call(nil, query_21627376, nil, formData_21627377, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_21627357(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_21627358, base: "/",
    makeUrl: url_PostDescribeOptionGroupOptions_21627359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_21627337 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOptionGroupOptions_21627339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_21627338(path: JsonNode;
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
  var valid_21627340 = query.getOrDefault("MaxRecords")
  valid_21627340 = validateParameter(valid_21627340, JInt, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "MaxRecords", valid_21627340
  var valid_21627341 = query.getOrDefault("Filters")
  valid_21627341 = validateParameter(valid_21627341, JArray, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "Filters", valid_21627341
  var valid_21627342 = query.getOrDefault("Action")
  valid_21627342 = validateParameter(valid_21627342, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_21627342 != nil:
    section.add "Action", valid_21627342
  var valid_21627343 = query.getOrDefault("Marker")
  valid_21627343 = validateParameter(valid_21627343, JString, required = false,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "Marker", valid_21627343
  var valid_21627344 = query.getOrDefault("Version")
  valid_21627344 = validateParameter(valid_21627344, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627344 != nil:
    section.add "Version", valid_21627344
  var valid_21627345 = query.getOrDefault("EngineName")
  valid_21627345 = validateParameter(valid_21627345, JString, required = true,
                                   default = nil)
  if valid_21627345 != nil:
    section.add "EngineName", valid_21627345
  var valid_21627346 = query.getOrDefault("MajorEngineVersion")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "MajorEngineVersion", valid_21627346
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
  var valid_21627347 = header.getOrDefault("X-Amz-Date")
  valid_21627347 = validateParameter(valid_21627347, JString, required = false,
                                   default = nil)
  if valid_21627347 != nil:
    section.add "X-Amz-Date", valid_21627347
  var valid_21627348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "X-Amz-Security-Token", valid_21627348
  var valid_21627349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Algorithm", valid_21627350
  var valid_21627351 = header.getOrDefault("X-Amz-Signature")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-Signature", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-Credential")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-Credential", valid_21627353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627354: Call_GetDescribeOptionGroupOptions_21627337;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627354.validator(path, query, header, formData, body, _)
  let scheme = call_21627354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627354.makeUrl(scheme.get, call_21627354.host, call_21627354.base,
                               call_21627354.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627354, uri, valid, _)

proc call*(call_21627355: Call_GetDescribeOptionGroupOptions_21627337;
          EngineName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2014-09-01"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_21627356 = newJObject()
  add(query_21627356, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627356.add "Filters", Filters
  add(query_21627356, "Action", newJString(Action))
  add(query_21627356, "Marker", newJString(Marker))
  add(query_21627356, "Version", newJString(Version))
  add(query_21627356, "EngineName", newJString(EngineName))
  add(query_21627356, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21627355.call(nil, query_21627356, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_21627337(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_21627338, base: "/",
    makeUrl: url_GetDescribeOptionGroupOptions_21627339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_21627399 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOptionGroups_21627401(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_21627400(path: JsonNode; query: JsonNode;
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
  var valid_21627402 = query.getOrDefault("Action")
  valid_21627402 = validateParameter(valid_21627402, JString, required = true,
                                   default = newJString("DescribeOptionGroups"))
  if valid_21627402 != nil:
    section.add "Action", valid_21627402
  var valid_21627403 = query.getOrDefault("Version")
  valid_21627403 = validateParameter(valid_21627403, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627403 != nil:
    section.add "Version", valid_21627403
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
  var valid_21627404 = header.getOrDefault("X-Amz-Date")
  valid_21627404 = validateParameter(valid_21627404, JString, required = false,
                                   default = nil)
  if valid_21627404 != nil:
    section.add "X-Amz-Date", valid_21627404
  var valid_21627405 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627405 = validateParameter(valid_21627405, JString, required = false,
                                   default = nil)
  if valid_21627405 != nil:
    section.add "X-Amz-Security-Token", valid_21627405
  var valid_21627406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627406 = validateParameter(valid_21627406, JString, required = false,
                                   default = nil)
  if valid_21627406 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627406
  var valid_21627407 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627407 = validateParameter(valid_21627407, JString, required = false,
                                   default = nil)
  if valid_21627407 != nil:
    section.add "X-Amz-Algorithm", valid_21627407
  var valid_21627408 = header.getOrDefault("X-Amz-Signature")
  valid_21627408 = validateParameter(valid_21627408, JString, required = false,
                                   default = nil)
  if valid_21627408 != nil:
    section.add "X-Amz-Signature", valid_21627408
  var valid_21627409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627409 = validateParameter(valid_21627409, JString, required = false,
                                   default = nil)
  if valid_21627409 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627409
  var valid_21627410 = header.getOrDefault("X-Amz-Credential")
  valid_21627410 = validateParameter(valid_21627410, JString, required = false,
                                   default = nil)
  if valid_21627410 != nil:
    section.add "X-Amz-Credential", valid_21627410
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627411 = formData.getOrDefault("MajorEngineVersion")
  valid_21627411 = validateParameter(valid_21627411, JString, required = false,
                                   default = nil)
  if valid_21627411 != nil:
    section.add "MajorEngineVersion", valid_21627411
  var valid_21627412 = formData.getOrDefault("OptionGroupName")
  valid_21627412 = validateParameter(valid_21627412, JString, required = false,
                                   default = nil)
  if valid_21627412 != nil:
    section.add "OptionGroupName", valid_21627412
  var valid_21627413 = formData.getOrDefault("Marker")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "Marker", valid_21627413
  var valid_21627414 = formData.getOrDefault("EngineName")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "EngineName", valid_21627414
  var valid_21627415 = formData.getOrDefault("Filters")
  valid_21627415 = validateParameter(valid_21627415, JArray, required = false,
                                   default = nil)
  if valid_21627415 != nil:
    section.add "Filters", valid_21627415
  var valid_21627416 = formData.getOrDefault("MaxRecords")
  valid_21627416 = validateParameter(valid_21627416, JInt, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "MaxRecords", valid_21627416
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627417: Call_PostDescribeOptionGroups_21627399;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627417.validator(path, query, header, formData, body, _)
  let scheme = call_21627417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627417.makeUrl(scheme.get, call_21627417.host, call_21627417.base,
                               call_21627417.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627417, uri, valid, _)

proc call*(call_21627418: Call_PostDescribeOptionGroups_21627399;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; Filters: JsonNode = nil; MaxRecords: int = 0;
          Version: string = "2014-09-01"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627419 = newJObject()
  var formData_21627420 = newJObject()
  add(formData_21627420, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21627420, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627420, "Marker", newJString(Marker))
  add(query_21627419, "Action", newJString(Action))
  add(formData_21627420, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_21627420.add "Filters", Filters
  add(formData_21627420, "MaxRecords", newJInt(MaxRecords))
  add(query_21627419, "Version", newJString(Version))
  result = call_21627418.call(nil, query_21627419, nil, formData_21627420, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_21627399(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_21627400, base: "/",
    makeUrl: url_PostDescribeOptionGroups_21627401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_21627378 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOptionGroups_21627380(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_21627379(path: JsonNode; query: JsonNode;
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
  var valid_21627381 = query.getOrDefault("MaxRecords")
  valid_21627381 = validateParameter(valid_21627381, JInt, required = false,
                                   default = nil)
  if valid_21627381 != nil:
    section.add "MaxRecords", valid_21627381
  var valid_21627382 = query.getOrDefault("OptionGroupName")
  valid_21627382 = validateParameter(valid_21627382, JString, required = false,
                                   default = nil)
  if valid_21627382 != nil:
    section.add "OptionGroupName", valid_21627382
  var valid_21627383 = query.getOrDefault("Filters")
  valid_21627383 = validateParameter(valid_21627383, JArray, required = false,
                                   default = nil)
  if valid_21627383 != nil:
    section.add "Filters", valid_21627383
  var valid_21627384 = query.getOrDefault("Action")
  valid_21627384 = validateParameter(valid_21627384, JString, required = true,
                                   default = newJString("DescribeOptionGroups"))
  if valid_21627384 != nil:
    section.add "Action", valid_21627384
  var valid_21627385 = query.getOrDefault("Marker")
  valid_21627385 = validateParameter(valid_21627385, JString, required = false,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "Marker", valid_21627385
  var valid_21627386 = query.getOrDefault("Version")
  valid_21627386 = validateParameter(valid_21627386, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627386 != nil:
    section.add "Version", valid_21627386
  var valid_21627387 = query.getOrDefault("EngineName")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "EngineName", valid_21627387
  var valid_21627388 = query.getOrDefault("MajorEngineVersion")
  valid_21627388 = validateParameter(valid_21627388, JString, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "MajorEngineVersion", valid_21627388
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
  var valid_21627389 = header.getOrDefault("X-Amz-Date")
  valid_21627389 = validateParameter(valid_21627389, JString, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "X-Amz-Date", valid_21627389
  var valid_21627390 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "X-Amz-Security-Token", valid_21627390
  var valid_21627391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627391 = validateParameter(valid_21627391, JString, required = false,
                                   default = nil)
  if valid_21627391 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627391
  var valid_21627392 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627392 = validateParameter(valid_21627392, JString, required = false,
                                   default = nil)
  if valid_21627392 != nil:
    section.add "X-Amz-Algorithm", valid_21627392
  var valid_21627393 = header.getOrDefault("X-Amz-Signature")
  valid_21627393 = validateParameter(valid_21627393, JString, required = false,
                                   default = nil)
  if valid_21627393 != nil:
    section.add "X-Amz-Signature", valid_21627393
  var valid_21627394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627394 = validateParameter(valid_21627394, JString, required = false,
                                   default = nil)
  if valid_21627394 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627394
  var valid_21627395 = header.getOrDefault("X-Amz-Credential")
  valid_21627395 = validateParameter(valid_21627395, JString, required = false,
                                   default = nil)
  if valid_21627395 != nil:
    section.add "X-Amz-Credential", valid_21627395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627396: Call_GetDescribeOptionGroups_21627378;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627396.validator(path, query, header, formData, body, _)
  let scheme = call_21627396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627396.makeUrl(scheme.get, call_21627396.host, call_21627396.base,
                               call_21627396.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627396, uri, valid, _)

proc call*(call_21627397: Call_GetDescribeOptionGroups_21627378;
          MaxRecords: int = 0; OptionGroupName: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroups"; Marker: string = "";
          Version: string = "2014-09-01"; EngineName: string = "";
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
  var query_21627398 = newJObject()
  add(query_21627398, "MaxRecords", newJInt(MaxRecords))
  add(query_21627398, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_21627398.add "Filters", Filters
  add(query_21627398, "Action", newJString(Action))
  add(query_21627398, "Marker", newJString(Marker))
  add(query_21627398, "Version", newJString(Version))
  add(query_21627398, "EngineName", newJString(EngineName))
  add(query_21627398, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21627397.call(nil, query_21627398, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_21627378(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_21627379, base: "/",
    makeUrl: url_GetDescribeOptionGroups_21627380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_21627444 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOrderableDBInstanceOptions_21627446(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_21627445(path: JsonNode;
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
  var valid_21627447 = query.getOrDefault("Action")
  valid_21627447 = validateParameter(valid_21627447, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627447 != nil:
    section.add "Action", valid_21627447
  var valid_21627448 = query.getOrDefault("Version")
  valid_21627448 = validateParameter(valid_21627448, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627448 != nil:
    section.add "Version", valid_21627448
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
  var valid_21627449 = header.getOrDefault("X-Amz-Date")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "X-Amz-Date", valid_21627449
  var valid_21627450 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627450 = validateParameter(valid_21627450, JString, required = false,
                                   default = nil)
  if valid_21627450 != nil:
    section.add "X-Amz-Security-Token", valid_21627450
  var valid_21627451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627451 = validateParameter(valid_21627451, JString, required = false,
                                   default = nil)
  if valid_21627451 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627451
  var valid_21627452 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627452 = validateParameter(valid_21627452, JString, required = false,
                                   default = nil)
  if valid_21627452 != nil:
    section.add "X-Amz-Algorithm", valid_21627452
  var valid_21627453 = header.getOrDefault("X-Amz-Signature")
  valid_21627453 = validateParameter(valid_21627453, JString, required = false,
                                   default = nil)
  if valid_21627453 != nil:
    section.add "X-Amz-Signature", valid_21627453
  var valid_21627454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627454 = validateParameter(valid_21627454, JString, required = false,
                                   default = nil)
  if valid_21627454 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627454
  var valid_21627455 = header.getOrDefault("X-Amz-Credential")
  valid_21627455 = validateParameter(valid_21627455, JString, required = false,
                                   default = nil)
  if valid_21627455 != nil:
    section.add "X-Amz-Credential", valid_21627455
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
  var valid_21627456 = formData.getOrDefault("Engine")
  valid_21627456 = validateParameter(valid_21627456, JString, required = true,
                                   default = nil)
  if valid_21627456 != nil:
    section.add "Engine", valid_21627456
  var valid_21627457 = formData.getOrDefault("Marker")
  valid_21627457 = validateParameter(valid_21627457, JString, required = false,
                                   default = nil)
  if valid_21627457 != nil:
    section.add "Marker", valid_21627457
  var valid_21627458 = formData.getOrDefault("Vpc")
  valid_21627458 = validateParameter(valid_21627458, JBool, required = false,
                                   default = nil)
  if valid_21627458 != nil:
    section.add "Vpc", valid_21627458
  var valid_21627459 = formData.getOrDefault("DBInstanceClass")
  valid_21627459 = validateParameter(valid_21627459, JString, required = false,
                                   default = nil)
  if valid_21627459 != nil:
    section.add "DBInstanceClass", valid_21627459
  var valid_21627460 = formData.getOrDefault("Filters")
  valid_21627460 = validateParameter(valid_21627460, JArray, required = false,
                                   default = nil)
  if valid_21627460 != nil:
    section.add "Filters", valid_21627460
  var valid_21627461 = formData.getOrDefault("LicenseModel")
  valid_21627461 = validateParameter(valid_21627461, JString, required = false,
                                   default = nil)
  if valid_21627461 != nil:
    section.add "LicenseModel", valid_21627461
  var valid_21627462 = formData.getOrDefault("MaxRecords")
  valid_21627462 = validateParameter(valid_21627462, JInt, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "MaxRecords", valid_21627462
  var valid_21627463 = formData.getOrDefault("EngineVersion")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "EngineVersion", valid_21627463
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627464: Call_PostDescribeOrderableDBInstanceOptions_21627444;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627464.validator(path, query, header, formData, body, _)
  let scheme = call_21627464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627464.makeUrl(scheme.get, call_21627464.host, call_21627464.base,
                               call_21627464.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627464, uri, valid, _)

proc call*(call_21627465: Call_PostDescribeOrderableDBInstanceOptions_21627444;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          LicenseModel: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_21627466 = newJObject()
  var formData_21627467 = newJObject()
  add(formData_21627467, "Engine", newJString(Engine))
  add(formData_21627467, "Marker", newJString(Marker))
  add(query_21627466, "Action", newJString(Action))
  add(formData_21627467, "Vpc", newJBool(Vpc))
  add(formData_21627467, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_21627467.add "Filters", Filters
  add(formData_21627467, "LicenseModel", newJString(LicenseModel))
  add(formData_21627467, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627467, "EngineVersion", newJString(EngineVersion))
  add(query_21627466, "Version", newJString(Version))
  result = call_21627465.call(nil, query_21627466, nil, formData_21627467, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_21627444(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_21627445,
    base: "/", makeUrl: url_PostDescribeOrderableDBInstanceOptions_21627446,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_21627421 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOrderableDBInstanceOptions_21627423(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_21627422(path: JsonNode;
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
  var valid_21627424 = query.getOrDefault("Engine")
  valid_21627424 = validateParameter(valid_21627424, JString, required = true,
                                   default = nil)
  if valid_21627424 != nil:
    section.add "Engine", valid_21627424
  var valid_21627425 = query.getOrDefault("MaxRecords")
  valid_21627425 = validateParameter(valid_21627425, JInt, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "MaxRecords", valid_21627425
  var valid_21627426 = query.getOrDefault("Filters")
  valid_21627426 = validateParameter(valid_21627426, JArray, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "Filters", valid_21627426
  var valid_21627427 = query.getOrDefault("LicenseModel")
  valid_21627427 = validateParameter(valid_21627427, JString, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "LicenseModel", valid_21627427
  var valid_21627428 = query.getOrDefault("Vpc")
  valid_21627428 = validateParameter(valid_21627428, JBool, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "Vpc", valid_21627428
  var valid_21627429 = query.getOrDefault("DBInstanceClass")
  valid_21627429 = validateParameter(valid_21627429, JString, required = false,
                                   default = nil)
  if valid_21627429 != nil:
    section.add "DBInstanceClass", valid_21627429
  var valid_21627430 = query.getOrDefault("Action")
  valid_21627430 = validateParameter(valid_21627430, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627430 != nil:
    section.add "Action", valid_21627430
  var valid_21627431 = query.getOrDefault("Marker")
  valid_21627431 = validateParameter(valid_21627431, JString, required = false,
                                   default = nil)
  if valid_21627431 != nil:
    section.add "Marker", valid_21627431
  var valid_21627432 = query.getOrDefault("EngineVersion")
  valid_21627432 = validateParameter(valid_21627432, JString, required = false,
                                   default = nil)
  if valid_21627432 != nil:
    section.add "EngineVersion", valid_21627432
  var valid_21627433 = query.getOrDefault("Version")
  valid_21627433 = validateParameter(valid_21627433, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627433 != nil:
    section.add "Version", valid_21627433
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
  var valid_21627434 = header.getOrDefault("X-Amz-Date")
  valid_21627434 = validateParameter(valid_21627434, JString, required = false,
                                   default = nil)
  if valid_21627434 != nil:
    section.add "X-Amz-Date", valid_21627434
  var valid_21627435 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627435 = validateParameter(valid_21627435, JString, required = false,
                                   default = nil)
  if valid_21627435 != nil:
    section.add "X-Amz-Security-Token", valid_21627435
  var valid_21627436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627436 = validateParameter(valid_21627436, JString, required = false,
                                   default = nil)
  if valid_21627436 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627436
  var valid_21627437 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627437 = validateParameter(valid_21627437, JString, required = false,
                                   default = nil)
  if valid_21627437 != nil:
    section.add "X-Amz-Algorithm", valid_21627437
  var valid_21627438 = header.getOrDefault("X-Amz-Signature")
  valid_21627438 = validateParameter(valid_21627438, JString, required = false,
                                   default = nil)
  if valid_21627438 != nil:
    section.add "X-Amz-Signature", valid_21627438
  var valid_21627439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627439 = validateParameter(valid_21627439, JString, required = false,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627439
  var valid_21627440 = header.getOrDefault("X-Amz-Credential")
  valid_21627440 = validateParameter(valid_21627440, JString, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "X-Amz-Credential", valid_21627440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627441: Call_GetDescribeOrderableDBInstanceOptions_21627421;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627441.validator(path, query, header, formData, body, _)
  let scheme = call_21627441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627441.makeUrl(scheme.get, call_21627441.host, call_21627441.base,
                               call_21627441.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627441, uri, valid, _)

proc call*(call_21627442: Call_GetDescribeOrderableDBInstanceOptions_21627421;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2014-09-01"): Recallable =
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
  var query_21627443 = newJObject()
  add(query_21627443, "Engine", newJString(Engine))
  add(query_21627443, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627443.add "Filters", Filters
  add(query_21627443, "LicenseModel", newJString(LicenseModel))
  add(query_21627443, "Vpc", newJBool(Vpc))
  add(query_21627443, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627443, "Action", newJString(Action))
  add(query_21627443, "Marker", newJString(Marker))
  add(query_21627443, "EngineVersion", newJString(EngineVersion))
  add(query_21627443, "Version", newJString(Version))
  result = call_21627442.call(nil, query_21627443, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_21627421(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_21627422, base: "/",
    makeUrl: url_GetDescribeOrderableDBInstanceOptions_21627423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_21627493 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeReservedDBInstances_21627495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_21627494(path: JsonNode;
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
  var valid_21627496 = query.getOrDefault("Action")
  valid_21627496 = validateParameter(valid_21627496, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_21627496 != nil:
    section.add "Action", valid_21627496
  var valid_21627497 = query.getOrDefault("Version")
  valid_21627497 = validateParameter(valid_21627497, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627497 != nil:
    section.add "Version", valid_21627497
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
  var valid_21627498 = header.getOrDefault("X-Amz-Date")
  valid_21627498 = validateParameter(valid_21627498, JString, required = false,
                                   default = nil)
  if valid_21627498 != nil:
    section.add "X-Amz-Date", valid_21627498
  var valid_21627499 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627499 = validateParameter(valid_21627499, JString, required = false,
                                   default = nil)
  if valid_21627499 != nil:
    section.add "X-Amz-Security-Token", valid_21627499
  var valid_21627500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627500 = validateParameter(valid_21627500, JString, required = false,
                                   default = nil)
  if valid_21627500 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627500
  var valid_21627501 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627501 = validateParameter(valid_21627501, JString, required = false,
                                   default = nil)
  if valid_21627501 != nil:
    section.add "X-Amz-Algorithm", valid_21627501
  var valid_21627502 = header.getOrDefault("X-Amz-Signature")
  valid_21627502 = validateParameter(valid_21627502, JString, required = false,
                                   default = nil)
  if valid_21627502 != nil:
    section.add "X-Amz-Signature", valid_21627502
  var valid_21627503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627503 = validateParameter(valid_21627503, JString, required = false,
                                   default = nil)
  if valid_21627503 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627503
  var valid_21627504 = header.getOrDefault("X-Amz-Credential")
  valid_21627504 = validateParameter(valid_21627504, JString, required = false,
                                   default = nil)
  if valid_21627504 != nil:
    section.add "X-Amz-Credential", valid_21627504
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
  var valid_21627505 = formData.getOrDefault("OfferingType")
  valid_21627505 = validateParameter(valid_21627505, JString, required = false,
                                   default = nil)
  if valid_21627505 != nil:
    section.add "OfferingType", valid_21627505
  var valid_21627506 = formData.getOrDefault("ReservedDBInstanceId")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "ReservedDBInstanceId", valid_21627506
  var valid_21627507 = formData.getOrDefault("Marker")
  valid_21627507 = validateParameter(valid_21627507, JString, required = false,
                                   default = nil)
  if valid_21627507 != nil:
    section.add "Marker", valid_21627507
  var valid_21627508 = formData.getOrDefault("MultiAZ")
  valid_21627508 = validateParameter(valid_21627508, JBool, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "MultiAZ", valid_21627508
  var valid_21627509 = formData.getOrDefault("Duration")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "Duration", valid_21627509
  var valid_21627510 = formData.getOrDefault("DBInstanceClass")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "DBInstanceClass", valid_21627510
  var valid_21627511 = formData.getOrDefault("Filters")
  valid_21627511 = validateParameter(valid_21627511, JArray, required = false,
                                   default = nil)
  if valid_21627511 != nil:
    section.add "Filters", valid_21627511
  var valid_21627512 = formData.getOrDefault("ProductDescription")
  valid_21627512 = validateParameter(valid_21627512, JString, required = false,
                                   default = nil)
  if valid_21627512 != nil:
    section.add "ProductDescription", valid_21627512
  var valid_21627513 = formData.getOrDefault("MaxRecords")
  valid_21627513 = validateParameter(valid_21627513, JInt, required = false,
                                   default = nil)
  if valid_21627513 != nil:
    section.add "MaxRecords", valid_21627513
  var valid_21627514 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627514 = validateParameter(valid_21627514, JString, required = false,
                                   default = nil)
  if valid_21627514 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627514
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627515: Call_PostDescribeReservedDBInstances_21627493;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627515.validator(path, query, header, formData, body, _)
  let scheme = call_21627515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627515.makeUrl(scheme.get, call_21627515.host, call_21627515.base,
                               call_21627515.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627515, uri, valid, _)

proc call*(call_21627516: Call_PostDescribeReservedDBInstances_21627493;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_21627517 = newJObject()
  var formData_21627518 = newJObject()
  add(formData_21627518, "OfferingType", newJString(OfferingType))
  add(formData_21627518, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_21627518, "Marker", newJString(Marker))
  add(formData_21627518, "MultiAZ", newJBool(MultiAZ))
  add(query_21627517, "Action", newJString(Action))
  add(formData_21627518, "Duration", newJString(Duration))
  add(formData_21627518, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_21627518.add "Filters", Filters
  add(formData_21627518, "ProductDescription", newJString(ProductDescription))
  add(formData_21627518, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627518, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627517, "Version", newJString(Version))
  result = call_21627516.call(nil, query_21627517, nil, formData_21627518, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_21627493(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_21627494, base: "/",
    makeUrl: url_PostDescribeReservedDBInstances_21627495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_21627468 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeReservedDBInstances_21627470(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_21627469(path: JsonNode;
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
  var valid_21627471 = query.getOrDefault("ProductDescription")
  valid_21627471 = validateParameter(valid_21627471, JString, required = false,
                                   default = nil)
  if valid_21627471 != nil:
    section.add "ProductDescription", valid_21627471
  var valid_21627472 = query.getOrDefault("MaxRecords")
  valid_21627472 = validateParameter(valid_21627472, JInt, required = false,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "MaxRecords", valid_21627472
  var valid_21627473 = query.getOrDefault("OfferingType")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "OfferingType", valid_21627473
  var valid_21627474 = query.getOrDefault("Filters")
  valid_21627474 = validateParameter(valid_21627474, JArray, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "Filters", valid_21627474
  var valid_21627475 = query.getOrDefault("MultiAZ")
  valid_21627475 = validateParameter(valid_21627475, JBool, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "MultiAZ", valid_21627475
  var valid_21627476 = query.getOrDefault("ReservedDBInstanceId")
  valid_21627476 = validateParameter(valid_21627476, JString, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "ReservedDBInstanceId", valid_21627476
  var valid_21627477 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627477
  var valid_21627478 = query.getOrDefault("DBInstanceClass")
  valid_21627478 = validateParameter(valid_21627478, JString, required = false,
                                   default = nil)
  if valid_21627478 != nil:
    section.add "DBInstanceClass", valid_21627478
  var valid_21627479 = query.getOrDefault("Action")
  valid_21627479 = validateParameter(valid_21627479, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_21627479 != nil:
    section.add "Action", valid_21627479
  var valid_21627480 = query.getOrDefault("Marker")
  valid_21627480 = validateParameter(valid_21627480, JString, required = false,
                                   default = nil)
  if valid_21627480 != nil:
    section.add "Marker", valid_21627480
  var valid_21627481 = query.getOrDefault("Duration")
  valid_21627481 = validateParameter(valid_21627481, JString, required = false,
                                   default = nil)
  if valid_21627481 != nil:
    section.add "Duration", valid_21627481
  var valid_21627482 = query.getOrDefault("Version")
  valid_21627482 = validateParameter(valid_21627482, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627482 != nil:
    section.add "Version", valid_21627482
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
  var valid_21627483 = header.getOrDefault("X-Amz-Date")
  valid_21627483 = validateParameter(valid_21627483, JString, required = false,
                                   default = nil)
  if valid_21627483 != nil:
    section.add "X-Amz-Date", valid_21627483
  var valid_21627484 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627484 = validateParameter(valid_21627484, JString, required = false,
                                   default = nil)
  if valid_21627484 != nil:
    section.add "X-Amz-Security-Token", valid_21627484
  var valid_21627485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627485 = validateParameter(valid_21627485, JString, required = false,
                                   default = nil)
  if valid_21627485 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627485
  var valid_21627486 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627486 = validateParameter(valid_21627486, JString, required = false,
                                   default = nil)
  if valid_21627486 != nil:
    section.add "X-Amz-Algorithm", valid_21627486
  var valid_21627487 = header.getOrDefault("X-Amz-Signature")
  valid_21627487 = validateParameter(valid_21627487, JString, required = false,
                                   default = nil)
  if valid_21627487 != nil:
    section.add "X-Amz-Signature", valid_21627487
  var valid_21627488 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627488
  var valid_21627489 = header.getOrDefault("X-Amz-Credential")
  valid_21627489 = validateParameter(valid_21627489, JString, required = false,
                                   default = nil)
  if valid_21627489 != nil:
    section.add "X-Amz-Credential", valid_21627489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627490: Call_GetDescribeReservedDBInstances_21627468;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627490.validator(path, query, header, formData, body, _)
  let scheme = call_21627490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627490.makeUrl(scheme.get, call_21627490.host, call_21627490.base,
                               call_21627490.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627490, uri, valid, _)

proc call*(call_21627491: Call_GetDescribeReservedDBInstances_21627468;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_21627492 = newJObject()
  add(query_21627492, "ProductDescription", newJString(ProductDescription))
  add(query_21627492, "MaxRecords", newJInt(MaxRecords))
  add(query_21627492, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_21627492.add "Filters", Filters
  add(query_21627492, "MultiAZ", newJBool(MultiAZ))
  add(query_21627492, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_21627492, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627492, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627492, "Action", newJString(Action))
  add(query_21627492, "Marker", newJString(Marker))
  add(query_21627492, "Duration", newJString(Duration))
  add(query_21627492, "Version", newJString(Version))
  result = call_21627491.call(nil, query_21627492, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_21627468(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_21627469, base: "/",
    makeUrl: url_GetDescribeReservedDBInstances_21627470,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_21627543 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeReservedDBInstancesOfferings_21627545(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_21627544(path: JsonNode;
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
  var valid_21627546 = query.getOrDefault("Action")
  valid_21627546 = validateParameter(valid_21627546, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_21627546 != nil:
    section.add "Action", valid_21627546
  var valid_21627547 = query.getOrDefault("Version")
  valid_21627547 = validateParameter(valid_21627547, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627547 != nil:
    section.add "Version", valid_21627547
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
  var valid_21627548 = header.getOrDefault("X-Amz-Date")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-Date", valid_21627548
  var valid_21627549 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627549 = validateParameter(valid_21627549, JString, required = false,
                                   default = nil)
  if valid_21627549 != nil:
    section.add "X-Amz-Security-Token", valid_21627549
  var valid_21627550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627550 = validateParameter(valid_21627550, JString, required = false,
                                   default = nil)
  if valid_21627550 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627550
  var valid_21627551 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627551 = validateParameter(valid_21627551, JString, required = false,
                                   default = nil)
  if valid_21627551 != nil:
    section.add "X-Amz-Algorithm", valid_21627551
  var valid_21627552 = header.getOrDefault("X-Amz-Signature")
  valid_21627552 = validateParameter(valid_21627552, JString, required = false,
                                   default = nil)
  if valid_21627552 != nil:
    section.add "X-Amz-Signature", valid_21627552
  var valid_21627553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627553 = validateParameter(valid_21627553, JString, required = false,
                                   default = nil)
  if valid_21627553 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627553
  var valid_21627554 = header.getOrDefault("X-Amz-Credential")
  valid_21627554 = validateParameter(valid_21627554, JString, required = false,
                                   default = nil)
  if valid_21627554 != nil:
    section.add "X-Amz-Credential", valid_21627554
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
  var valid_21627555 = formData.getOrDefault("OfferingType")
  valid_21627555 = validateParameter(valid_21627555, JString, required = false,
                                   default = nil)
  if valid_21627555 != nil:
    section.add "OfferingType", valid_21627555
  var valid_21627556 = formData.getOrDefault("Marker")
  valid_21627556 = validateParameter(valid_21627556, JString, required = false,
                                   default = nil)
  if valid_21627556 != nil:
    section.add "Marker", valid_21627556
  var valid_21627557 = formData.getOrDefault("MultiAZ")
  valid_21627557 = validateParameter(valid_21627557, JBool, required = false,
                                   default = nil)
  if valid_21627557 != nil:
    section.add "MultiAZ", valid_21627557
  var valid_21627558 = formData.getOrDefault("Duration")
  valid_21627558 = validateParameter(valid_21627558, JString, required = false,
                                   default = nil)
  if valid_21627558 != nil:
    section.add "Duration", valid_21627558
  var valid_21627559 = formData.getOrDefault("DBInstanceClass")
  valid_21627559 = validateParameter(valid_21627559, JString, required = false,
                                   default = nil)
  if valid_21627559 != nil:
    section.add "DBInstanceClass", valid_21627559
  var valid_21627560 = formData.getOrDefault("Filters")
  valid_21627560 = validateParameter(valid_21627560, JArray, required = false,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "Filters", valid_21627560
  var valid_21627561 = formData.getOrDefault("ProductDescription")
  valid_21627561 = validateParameter(valid_21627561, JString, required = false,
                                   default = nil)
  if valid_21627561 != nil:
    section.add "ProductDescription", valid_21627561
  var valid_21627562 = formData.getOrDefault("MaxRecords")
  valid_21627562 = validateParameter(valid_21627562, JInt, required = false,
                                   default = nil)
  if valid_21627562 != nil:
    section.add "MaxRecords", valid_21627562
  var valid_21627563 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627563
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627564: Call_PostDescribeReservedDBInstancesOfferings_21627543;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627564.validator(path, query, header, formData, body, _)
  let scheme = call_21627564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627564.makeUrl(scheme.get, call_21627564.host, call_21627564.base,
                               call_21627564.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627564, uri, valid, _)

proc call*(call_21627565: Call_PostDescribeReservedDBInstancesOfferings_21627543;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_21627566 = newJObject()
  var formData_21627567 = newJObject()
  add(formData_21627567, "OfferingType", newJString(OfferingType))
  add(formData_21627567, "Marker", newJString(Marker))
  add(formData_21627567, "MultiAZ", newJBool(MultiAZ))
  add(query_21627566, "Action", newJString(Action))
  add(formData_21627567, "Duration", newJString(Duration))
  add(formData_21627567, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_21627567.add "Filters", Filters
  add(formData_21627567, "ProductDescription", newJString(ProductDescription))
  add(formData_21627567, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627567, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627566, "Version", newJString(Version))
  result = call_21627565.call(nil, query_21627566, nil, formData_21627567, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_21627543(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_21627544,
    base: "/", makeUrl: url_PostDescribeReservedDBInstancesOfferings_21627545,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_21627519 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeReservedDBInstancesOfferings_21627521(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_21627520(path: JsonNode;
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
  var valid_21627522 = query.getOrDefault("ProductDescription")
  valid_21627522 = validateParameter(valid_21627522, JString, required = false,
                                   default = nil)
  if valid_21627522 != nil:
    section.add "ProductDescription", valid_21627522
  var valid_21627523 = query.getOrDefault("MaxRecords")
  valid_21627523 = validateParameter(valid_21627523, JInt, required = false,
                                   default = nil)
  if valid_21627523 != nil:
    section.add "MaxRecords", valid_21627523
  var valid_21627524 = query.getOrDefault("OfferingType")
  valid_21627524 = validateParameter(valid_21627524, JString, required = false,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "OfferingType", valid_21627524
  var valid_21627525 = query.getOrDefault("Filters")
  valid_21627525 = validateParameter(valid_21627525, JArray, required = false,
                                   default = nil)
  if valid_21627525 != nil:
    section.add "Filters", valid_21627525
  var valid_21627526 = query.getOrDefault("MultiAZ")
  valid_21627526 = validateParameter(valid_21627526, JBool, required = false,
                                   default = nil)
  if valid_21627526 != nil:
    section.add "MultiAZ", valid_21627526
  var valid_21627527 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627527 = validateParameter(valid_21627527, JString, required = false,
                                   default = nil)
  if valid_21627527 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627527
  var valid_21627528 = query.getOrDefault("DBInstanceClass")
  valid_21627528 = validateParameter(valid_21627528, JString, required = false,
                                   default = nil)
  if valid_21627528 != nil:
    section.add "DBInstanceClass", valid_21627528
  var valid_21627529 = query.getOrDefault("Action")
  valid_21627529 = validateParameter(valid_21627529, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_21627529 != nil:
    section.add "Action", valid_21627529
  var valid_21627530 = query.getOrDefault("Marker")
  valid_21627530 = validateParameter(valid_21627530, JString, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "Marker", valid_21627530
  var valid_21627531 = query.getOrDefault("Duration")
  valid_21627531 = validateParameter(valid_21627531, JString, required = false,
                                   default = nil)
  if valid_21627531 != nil:
    section.add "Duration", valid_21627531
  var valid_21627532 = query.getOrDefault("Version")
  valid_21627532 = validateParameter(valid_21627532, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627532 != nil:
    section.add "Version", valid_21627532
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
  var valid_21627533 = header.getOrDefault("X-Amz-Date")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-Date", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627534 = validateParameter(valid_21627534, JString, required = false,
                                   default = nil)
  if valid_21627534 != nil:
    section.add "X-Amz-Security-Token", valid_21627534
  var valid_21627535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627535 = validateParameter(valid_21627535, JString, required = false,
                                   default = nil)
  if valid_21627535 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627535
  var valid_21627536 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627536 = validateParameter(valid_21627536, JString, required = false,
                                   default = nil)
  if valid_21627536 != nil:
    section.add "X-Amz-Algorithm", valid_21627536
  var valid_21627537 = header.getOrDefault("X-Amz-Signature")
  valid_21627537 = validateParameter(valid_21627537, JString, required = false,
                                   default = nil)
  if valid_21627537 != nil:
    section.add "X-Amz-Signature", valid_21627537
  var valid_21627538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627538 = validateParameter(valid_21627538, JString, required = false,
                                   default = nil)
  if valid_21627538 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627538
  var valid_21627539 = header.getOrDefault("X-Amz-Credential")
  valid_21627539 = validateParameter(valid_21627539, JString, required = false,
                                   default = nil)
  if valid_21627539 != nil:
    section.add "X-Amz-Credential", valid_21627539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627540: Call_GetDescribeReservedDBInstancesOfferings_21627519;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627540.validator(path, query, header, formData, body, _)
  let scheme = call_21627540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627540.makeUrl(scheme.get, call_21627540.host, call_21627540.base,
                               call_21627540.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627540, uri, valid, _)

proc call*(call_21627541: Call_GetDescribeReservedDBInstancesOfferings_21627519;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2014-09-01"): Recallable =
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
  var query_21627542 = newJObject()
  add(query_21627542, "ProductDescription", newJString(ProductDescription))
  add(query_21627542, "MaxRecords", newJInt(MaxRecords))
  add(query_21627542, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_21627542.add "Filters", Filters
  add(query_21627542, "MultiAZ", newJBool(MultiAZ))
  add(query_21627542, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627542, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627542, "Action", newJString(Action))
  add(query_21627542, "Marker", newJString(Marker))
  add(query_21627542, "Duration", newJString(Duration))
  add(query_21627542, "Version", newJString(Version))
  result = call_21627541.call(nil, query_21627542, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_21627519(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_21627520,
    base: "/", makeUrl: url_GetDescribeReservedDBInstancesOfferings_21627521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_21627587 = ref object of OpenApiRestCall_21625418
proc url_PostDownloadDBLogFilePortion_21627589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_21627588(path: JsonNode;
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
  var valid_21627590 = query.getOrDefault("Action")
  valid_21627590 = validateParameter(valid_21627590, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_21627590 != nil:
    section.add "Action", valid_21627590
  var valid_21627591 = query.getOrDefault("Version")
  valid_21627591 = validateParameter(valid_21627591, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627591 != nil:
    section.add "Version", valid_21627591
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
  var valid_21627592 = header.getOrDefault("X-Amz-Date")
  valid_21627592 = validateParameter(valid_21627592, JString, required = false,
                                   default = nil)
  if valid_21627592 != nil:
    section.add "X-Amz-Date", valid_21627592
  var valid_21627593 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627593 = validateParameter(valid_21627593, JString, required = false,
                                   default = nil)
  if valid_21627593 != nil:
    section.add "X-Amz-Security-Token", valid_21627593
  var valid_21627594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627594 = validateParameter(valid_21627594, JString, required = false,
                                   default = nil)
  if valid_21627594 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627594
  var valid_21627595 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-Algorithm", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-Signature")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-Signature", valid_21627596
  var valid_21627597 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627597 = validateParameter(valid_21627597, JString, required = false,
                                   default = nil)
  if valid_21627597 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627597
  var valid_21627598 = header.getOrDefault("X-Amz-Credential")
  valid_21627598 = validateParameter(valid_21627598, JString, required = false,
                                   default = nil)
  if valid_21627598 != nil:
    section.add "X-Amz-Credential", valid_21627598
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_21627599 = formData.getOrDefault("NumberOfLines")
  valid_21627599 = validateParameter(valid_21627599, JInt, required = false,
                                   default = nil)
  if valid_21627599 != nil:
    section.add "NumberOfLines", valid_21627599
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627600 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627600 = validateParameter(valid_21627600, JString, required = true,
                                   default = nil)
  if valid_21627600 != nil:
    section.add "DBInstanceIdentifier", valid_21627600
  var valid_21627601 = formData.getOrDefault("Marker")
  valid_21627601 = validateParameter(valid_21627601, JString, required = false,
                                   default = nil)
  if valid_21627601 != nil:
    section.add "Marker", valid_21627601
  var valid_21627602 = formData.getOrDefault("LogFileName")
  valid_21627602 = validateParameter(valid_21627602, JString, required = true,
                                   default = nil)
  if valid_21627602 != nil:
    section.add "LogFileName", valid_21627602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627603: Call_PostDownloadDBLogFilePortion_21627587;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627603.validator(path, query, header, formData, body, _)
  let scheme = call_21627603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627603.makeUrl(scheme.get, call_21627603.host, call_21627603.base,
                               call_21627603.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627603, uri, valid, _)

proc call*(call_21627604: Call_PostDownloadDBLogFilePortion_21627587;
          DBInstanceIdentifier: string; LogFileName: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2014-09-01"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_21627605 = newJObject()
  var formData_21627606 = newJObject()
  add(formData_21627606, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_21627606, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627606, "Marker", newJString(Marker))
  add(query_21627605, "Action", newJString(Action))
  add(formData_21627606, "LogFileName", newJString(LogFileName))
  add(query_21627605, "Version", newJString(Version))
  result = call_21627604.call(nil, query_21627605, nil, formData_21627606, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_21627587(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_21627588, base: "/",
    makeUrl: url_PostDownloadDBLogFilePortion_21627589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_21627568 = ref object of OpenApiRestCall_21625418
proc url_GetDownloadDBLogFilePortion_21627570(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_21627569(path: JsonNode; query: JsonNode;
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
  var valid_21627571 = query.getOrDefault("NumberOfLines")
  valid_21627571 = validateParameter(valid_21627571, JInt, required = false,
                                   default = nil)
  if valid_21627571 != nil:
    section.add "NumberOfLines", valid_21627571
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_21627572 = query.getOrDefault("LogFileName")
  valid_21627572 = validateParameter(valid_21627572, JString, required = true,
                                   default = nil)
  if valid_21627572 != nil:
    section.add "LogFileName", valid_21627572
  var valid_21627573 = query.getOrDefault("Action")
  valid_21627573 = validateParameter(valid_21627573, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_21627573 != nil:
    section.add "Action", valid_21627573
  var valid_21627574 = query.getOrDefault("Marker")
  valid_21627574 = validateParameter(valid_21627574, JString, required = false,
                                   default = nil)
  if valid_21627574 != nil:
    section.add "Marker", valid_21627574
  var valid_21627575 = query.getOrDefault("Version")
  valid_21627575 = validateParameter(valid_21627575, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627575 != nil:
    section.add "Version", valid_21627575
  var valid_21627576 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627576 = validateParameter(valid_21627576, JString, required = true,
                                   default = nil)
  if valid_21627576 != nil:
    section.add "DBInstanceIdentifier", valid_21627576
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
  var valid_21627577 = header.getOrDefault("X-Amz-Date")
  valid_21627577 = validateParameter(valid_21627577, JString, required = false,
                                   default = nil)
  if valid_21627577 != nil:
    section.add "X-Amz-Date", valid_21627577
  var valid_21627578 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627578 = validateParameter(valid_21627578, JString, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "X-Amz-Security-Token", valid_21627578
  var valid_21627579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627579 = validateParameter(valid_21627579, JString, required = false,
                                   default = nil)
  if valid_21627579 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627580 = validateParameter(valid_21627580, JString, required = false,
                                   default = nil)
  if valid_21627580 != nil:
    section.add "X-Amz-Algorithm", valid_21627580
  var valid_21627581 = header.getOrDefault("X-Amz-Signature")
  valid_21627581 = validateParameter(valid_21627581, JString, required = false,
                                   default = nil)
  if valid_21627581 != nil:
    section.add "X-Amz-Signature", valid_21627581
  var valid_21627582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627582
  var valid_21627583 = header.getOrDefault("X-Amz-Credential")
  valid_21627583 = validateParameter(valid_21627583, JString, required = false,
                                   default = nil)
  if valid_21627583 != nil:
    section.add "X-Amz-Credential", valid_21627583
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627584: Call_GetDownloadDBLogFilePortion_21627568;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627584.validator(path, query, header, formData, body, _)
  let scheme = call_21627584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627584.makeUrl(scheme.get, call_21627584.host, call_21627584.base,
                               call_21627584.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627584, uri, valid, _)

proc call*(call_21627585: Call_GetDownloadDBLogFilePortion_21627568;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Action: string = "DownloadDBLogFilePortion"; Marker: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   LogFileName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627586 = newJObject()
  add(query_21627586, "NumberOfLines", newJInt(NumberOfLines))
  add(query_21627586, "LogFileName", newJString(LogFileName))
  add(query_21627586, "Action", newJString(Action))
  add(query_21627586, "Marker", newJString(Marker))
  add(query_21627586, "Version", newJString(Version))
  add(query_21627586, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627585.call(nil, query_21627586, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_21627568(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_21627569, base: "/",
    makeUrl: url_GetDownloadDBLogFilePortion_21627570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_21627624 = ref object of OpenApiRestCall_21625418
proc url_PostListTagsForResource_21627626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_21627625(path: JsonNode; query: JsonNode;
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
  var valid_21627627 = query.getOrDefault("Action")
  valid_21627627 = validateParameter(valid_21627627, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627627 != nil:
    section.add "Action", valid_21627627
  var valid_21627628 = query.getOrDefault("Version")
  valid_21627628 = validateParameter(valid_21627628, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627628 != nil:
    section.add "Version", valid_21627628
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
  var valid_21627629 = header.getOrDefault("X-Amz-Date")
  valid_21627629 = validateParameter(valid_21627629, JString, required = false,
                                   default = nil)
  if valid_21627629 != nil:
    section.add "X-Amz-Date", valid_21627629
  var valid_21627630 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627630 = validateParameter(valid_21627630, JString, required = false,
                                   default = nil)
  if valid_21627630 != nil:
    section.add "X-Amz-Security-Token", valid_21627630
  var valid_21627631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627631 = validateParameter(valid_21627631, JString, required = false,
                                   default = nil)
  if valid_21627631 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627631
  var valid_21627632 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627632 = validateParameter(valid_21627632, JString, required = false,
                                   default = nil)
  if valid_21627632 != nil:
    section.add "X-Amz-Algorithm", valid_21627632
  var valid_21627633 = header.getOrDefault("X-Amz-Signature")
  valid_21627633 = validateParameter(valid_21627633, JString, required = false,
                                   default = nil)
  if valid_21627633 != nil:
    section.add "X-Amz-Signature", valid_21627633
  var valid_21627634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627634 = validateParameter(valid_21627634, JString, required = false,
                                   default = nil)
  if valid_21627634 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627634
  var valid_21627635 = header.getOrDefault("X-Amz-Credential")
  valid_21627635 = validateParameter(valid_21627635, JString, required = false,
                                   default = nil)
  if valid_21627635 != nil:
    section.add "X-Amz-Credential", valid_21627635
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_21627636 = formData.getOrDefault("Filters")
  valid_21627636 = validateParameter(valid_21627636, JArray, required = false,
                                   default = nil)
  if valid_21627636 != nil:
    section.add "Filters", valid_21627636
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_21627637 = formData.getOrDefault("ResourceName")
  valid_21627637 = validateParameter(valid_21627637, JString, required = true,
                                   default = nil)
  if valid_21627637 != nil:
    section.add "ResourceName", valid_21627637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627638: Call_PostListTagsForResource_21627624;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627638.validator(path, query, header, formData, body, _)
  let scheme = call_21627638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627638.makeUrl(scheme.get, call_21627638.host, call_21627638.base,
                               call_21627638.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627638, uri, valid, _)

proc call*(call_21627639: Call_PostListTagsForResource_21627624;
          ResourceName: string; Action: string = "ListTagsForResource";
          Filters: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_21627640 = newJObject()
  var formData_21627641 = newJObject()
  add(query_21627640, "Action", newJString(Action))
  if Filters != nil:
    formData_21627641.add "Filters", Filters
  add(formData_21627641, "ResourceName", newJString(ResourceName))
  add(query_21627640, "Version", newJString(Version))
  result = call_21627639.call(nil, query_21627640, nil, formData_21627641, nil)

var postListTagsForResource* = Call_PostListTagsForResource_21627624(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_21627625, base: "/",
    makeUrl: url_PostListTagsForResource_21627626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_21627607 = ref object of OpenApiRestCall_21625418
proc url_GetListTagsForResource_21627609(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_21627608(path: JsonNode; query: JsonNode;
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
  var valid_21627610 = query.getOrDefault("Filters")
  valid_21627610 = validateParameter(valid_21627610, JArray, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "Filters", valid_21627610
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_21627611 = query.getOrDefault("ResourceName")
  valid_21627611 = validateParameter(valid_21627611, JString, required = true,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "ResourceName", valid_21627611
  var valid_21627612 = query.getOrDefault("Action")
  valid_21627612 = validateParameter(valid_21627612, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627612 != nil:
    section.add "Action", valid_21627612
  var valid_21627613 = query.getOrDefault("Version")
  valid_21627613 = validateParameter(valid_21627613, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627613 != nil:
    section.add "Version", valid_21627613
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
  var valid_21627614 = header.getOrDefault("X-Amz-Date")
  valid_21627614 = validateParameter(valid_21627614, JString, required = false,
                                   default = nil)
  if valid_21627614 != nil:
    section.add "X-Amz-Date", valid_21627614
  var valid_21627615 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627615 = validateParameter(valid_21627615, JString, required = false,
                                   default = nil)
  if valid_21627615 != nil:
    section.add "X-Amz-Security-Token", valid_21627615
  var valid_21627616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627616 = validateParameter(valid_21627616, JString, required = false,
                                   default = nil)
  if valid_21627616 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627616
  var valid_21627617 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627617 = validateParameter(valid_21627617, JString, required = false,
                                   default = nil)
  if valid_21627617 != nil:
    section.add "X-Amz-Algorithm", valid_21627617
  var valid_21627618 = header.getOrDefault("X-Amz-Signature")
  valid_21627618 = validateParameter(valid_21627618, JString, required = false,
                                   default = nil)
  if valid_21627618 != nil:
    section.add "X-Amz-Signature", valid_21627618
  var valid_21627619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627619 = validateParameter(valid_21627619, JString, required = false,
                                   default = nil)
  if valid_21627619 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627619
  var valid_21627620 = header.getOrDefault("X-Amz-Credential")
  valid_21627620 = validateParameter(valid_21627620, JString, required = false,
                                   default = nil)
  if valid_21627620 != nil:
    section.add "X-Amz-Credential", valid_21627620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627621: Call_GetListTagsForResource_21627607;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627621.validator(path, query, header, formData, body, _)
  let scheme = call_21627621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627621.makeUrl(scheme.get, call_21627621.host, call_21627621.base,
                               call_21627621.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627621, uri, valid, _)

proc call*(call_21627622: Call_GetListTagsForResource_21627607;
          ResourceName: string; Filters: JsonNode = nil;
          Action: string = "ListTagsForResource"; Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627623 = newJObject()
  if Filters != nil:
    query_21627623.add "Filters", Filters
  add(query_21627623, "ResourceName", newJString(ResourceName))
  add(query_21627623, "Action", newJString(Action))
  add(query_21627623, "Version", newJString(Version))
  result = call_21627622.call(nil, query_21627623, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_21627607(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_21627608, base: "/",
    makeUrl: url_GetListTagsForResource_21627609,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_21627678 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBInstance_21627680(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_21627679(path: JsonNode; query: JsonNode;
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
  var valid_21627681 = query.getOrDefault("Action")
  valid_21627681 = validateParameter(valid_21627681, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627681 != nil:
    section.add "Action", valid_21627681
  var valid_21627682 = query.getOrDefault("Version")
  valid_21627682 = validateParameter(valid_21627682, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627682 != nil:
    section.add "Version", valid_21627682
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
  var valid_21627683 = header.getOrDefault("X-Amz-Date")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "X-Amz-Date", valid_21627683
  var valid_21627684 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627684 = validateParameter(valid_21627684, JString, required = false,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "X-Amz-Security-Token", valid_21627684
  var valid_21627685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627685 = validateParameter(valid_21627685, JString, required = false,
                                   default = nil)
  if valid_21627685 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-Algorithm", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Signature")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Signature", valid_21627687
  var valid_21627688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627688 = validateParameter(valid_21627688, JString, required = false,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627688
  var valid_21627689 = header.getOrDefault("X-Amz-Credential")
  valid_21627689 = validateParameter(valid_21627689, JString, required = false,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "X-Amz-Credential", valid_21627689
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
  ##   TdeCredentialArn: JString
  ##   TdeCredentialPassword: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt
  ##   StorageType: JString
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   AllowMajorVersionUpgrade: JBool
  section = newJObject()
  var valid_21627690 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21627690 = validateParameter(valid_21627690, JString, required = false,
                                   default = nil)
  if valid_21627690 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627690
  var valid_21627691 = formData.getOrDefault("DBSecurityGroups")
  valid_21627691 = validateParameter(valid_21627691, JArray, required = false,
                                   default = nil)
  if valid_21627691 != nil:
    section.add "DBSecurityGroups", valid_21627691
  var valid_21627692 = formData.getOrDefault("ApplyImmediately")
  valid_21627692 = validateParameter(valid_21627692, JBool, required = false,
                                   default = nil)
  if valid_21627692 != nil:
    section.add "ApplyImmediately", valid_21627692
  var valid_21627693 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21627693 = validateParameter(valid_21627693, JArray, required = false,
                                   default = nil)
  if valid_21627693 != nil:
    section.add "VpcSecurityGroupIds", valid_21627693
  var valid_21627694 = formData.getOrDefault("Iops")
  valid_21627694 = validateParameter(valid_21627694, JInt, required = false,
                                   default = nil)
  if valid_21627694 != nil:
    section.add "Iops", valid_21627694
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627695 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627695 = validateParameter(valid_21627695, JString, required = true,
                                   default = nil)
  if valid_21627695 != nil:
    section.add "DBInstanceIdentifier", valid_21627695
  var valid_21627696 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21627696 = validateParameter(valid_21627696, JInt, required = false,
                                   default = nil)
  if valid_21627696 != nil:
    section.add "BackupRetentionPeriod", valid_21627696
  var valid_21627697 = formData.getOrDefault("DBParameterGroupName")
  valid_21627697 = validateParameter(valid_21627697, JString, required = false,
                                   default = nil)
  if valid_21627697 != nil:
    section.add "DBParameterGroupName", valid_21627697
  var valid_21627698 = formData.getOrDefault("OptionGroupName")
  valid_21627698 = validateParameter(valid_21627698, JString, required = false,
                                   default = nil)
  if valid_21627698 != nil:
    section.add "OptionGroupName", valid_21627698
  var valid_21627699 = formData.getOrDefault("MasterUserPassword")
  valid_21627699 = validateParameter(valid_21627699, JString, required = false,
                                   default = nil)
  if valid_21627699 != nil:
    section.add "MasterUserPassword", valid_21627699
  var valid_21627700 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_21627700 = validateParameter(valid_21627700, JString, required = false,
                                   default = nil)
  if valid_21627700 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627700
  var valid_21627701 = formData.getOrDefault("TdeCredentialArn")
  valid_21627701 = validateParameter(valid_21627701, JString, required = false,
                                   default = nil)
  if valid_21627701 != nil:
    section.add "TdeCredentialArn", valid_21627701
  var valid_21627702 = formData.getOrDefault("TdeCredentialPassword")
  valid_21627702 = validateParameter(valid_21627702, JString, required = false,
                                   default = nil)
  if valid_21627702 != nil:
    section.add "TdeCredentialPassword", valid_21627702
  var valid_21627703 = formData.getOrDefault("MultiAZ")
  valid_21627703 = validateParameter(valid_21627703, JBool, required = false,
                                   default = nil)
  if valid_21627703 != nil:
    section.add "MultiAZ", valid_21627703
  var valid_21627704 = formData.getOrDefault("AllocatedStorage")
  valid_21627704 = validateParameter(valid_21627704, JInt, required = false,
                                   default = nil)
  if valid_21627704 != nil:
    section.add "AllocatedStorage", valid_21627704
  var valid_21627705 = formData.getOrDefault("StorageType")
  valid_21627705 = validateParameter(valid_21627705, JString, required = false,
                                   default = nil)
  if valid_21627705 != nil:
    section.add "StorageType", valid_21627705
  var valid_21627706 = formData.getOrDefault("DBInstanceClass")
  valid_21627706 = validateParameter(valid_21627706, JString, required = false,
                                   default = nil)
  if valid_21627706 != nil:
    section.add "DBInstanceClass", valid_21627706
  var valid_21627707 = formData.getOrDefault("PreferredBackupWindow")
  valid_21627707 = validateParameter(valid_21627707, JString, required = false,
                                   default = nil)
  if valid_21627707 != nil:
    section.add "PreferredBackupWindow", valid_21627707
  var valid_21627708 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627708 = validateParameter(valid_21627708, JBool, required = false,
                                   default = nil)
  if valid_21627708 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627708
  var valid_21627709 = formData.getOrDefault("EngineVersion")
  valid_21627709 = validateParameter(valid_21627709, JString, required = false,
                                   default = nil)
  if valid_21627709 != nil:
    section.add "EngineVersion", valid_21627709
  var valid_21627710 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_21627710 = validateParameter(valid_21627710, JBool, required = false,
                                   default = nil)
  if valid_21627710 != nil:
    section.add "AllowMajorVersionUpgrade", valid_21627710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627711: Call_PostModifyDBInstance_21627678; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627711.validator(path, query, header, formData, body, _)
  let scheme = call_21627711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627711.makeUrl(scheme.get, call_21627711.host, call_21627711.base,
                               call_21627711.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627711, uri, valid, _)

proc call*(call_21627712: Call_PostModifyDBInstance_21627678;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; TdeCredentialArn: string = "";
          TdeCredentialPassword: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          StorageType: string = ""; DBInstanceClass: string = "";
          PreferredBackupWindow: string = ""; AutoMinorVersionUpgrade: bool = false;
          EngineVersion: string = ""; Version: string = "2014-09-01";
          AllowMajorVersionUpgrade: bool = false): Recallable =
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
  ##   TdeCredentialArn: string
  ##   TdeCredentialPassword: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int
  ##   StorageType: string
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   AllowMajorVersionUpgrade: bool
  var query_21627713 = newJObject()
  var formData_21627714 = newJObject()
  add(formData_21627714, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_21627714.add "DBSecurityGroups", DBSecurityGroups
  add(formData_21627714, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_21627714.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21627714, "Iops", newJInt(Iops))
  add(formData_21627714, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627714, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_21627714, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21627714, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627714, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21627714, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_21627714, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_21627714, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_21627714, "MultiAZ", newJBool(MultiAZ))
  add(query_21627713, "Action", newJString(Action))
  add(formData_21627714, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_21627714, "StorageType", newJString(StorageType))
  add(formData_21627714, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627714, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21627714, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_21627714, "EngineVersion", newJString(EngineVersion))
  add(query_21627713, "Version", newJString(Version))
  add(formData_21627714, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_21627712.call(nil, query_21627713, nil, formData_21627714, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_21627678(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_21627679, base: "/",
    makeUrl: url_PostModifyDBInstance_21627680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_21627642 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBInstance_21627644(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_21627643(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##   AllocatedStorage: JInt
  ##   StorageType: JString
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   AllowMajorVersionUpgrade: JBool
  ##   NewDBInstanceIdentifier: JString
  ##   TdeCredentialArn: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  section = newJObject()
  var valid_21627645 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21627645 = validateParameter(valid_21627645, JString, required = false,
                                   default = nil)
  if valid_21627645 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627645
  var valid_21627646 = query.getOrDefault("AllocatedStorage")
  valid_21627646 = validateParameter(valid_21627646, JInt, required = false,
                                   default = nil)
  if valid_21627646 != nil:
    section.add "AllocatedStorage", valid_21627646
  var valid_21627647 = query.getOrDefault("StorageType")
  valid_21627647 = validateParameter(valid_21627647, JString, required = false,
                                   default = nil)
  if valid_21627647 != nil:
    section.add "StorageType", valid_21627647
  var valid_21627648 = query.getOrDefault("OptionGroupName")
  valid_21627648 = validateParameter(valid_21627648, JString, required = false,
                                   default = nil)
  if valid_21627648 != nil:
    section.add "OptionGroupName", valid_21627648
  var valid_21627649 = query.getOrDefault("DBSecurityGroups")
  valid_21627649 = validateParameter(valid_21627649, JArray, required = false,
                                   default = nil)
  if valid_21627649 != nil:
    section.add "DBSecurityGroups", valid_21627649
  var valid_21627650 = query.getOrDefault("MasterUserPassword")
  valid_21627650 = validateParameter(valid_21627650, JString, required = false,
                                   default = nil)
  if valid_21627650 != nil:
    section.add "MasterUserPassword", valid_21627650
  var valid_21627651 = query.getOrDefault("Iops")
  valid_21627651 = validateParameter(valid_21627651, JInt, required = false,
                                   default = nil)
  if valid_21627651 != nil:
    section.add "Iops", valid_21627651
  var valid_21627652 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21627652 = validateParameter(valid_21627652, JArray, required = false,
                                   default = nil)
  if valid_21627652 != nil:
    section.add "VpcSecurityGroupIds", valid_21627652
  var valid_21627653 = query.getOrDefault("MultiAZ")
  valid_21627653 = validateParameter(valid_21627653, JBool, required = false,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "MultiAZ", valid_21627653
  var valid_21627654 = query.getOrDefault("TdeCredentialPassword")
  valid_21627654 = validateParameter(valid_21627654, JString, required = false,
                                   default = nil)
  if valid_21627654 != nil:
    section.add "TdeCredentialPassword", valid_21627654
  var valid_21627655 = query.getOrDefault("BackupRetentionPeriod")
  valid_21627655 = validateParameter(valid_21627655, JInt, required = false,
                                   default = nil)
  if valid_21627655 != nil:
    section.add "BackupRetentionPeriod", valid_21627655
  var valid_21627656 = query.getOrDefault("DBParameterGroupName")
  valid_21627656 = validateParameter(valid_21627656, JString, required = false,
                                   default = nil)
  if valid_21627656 != nil:
    section.add "DBParameterGroupName", valid_21627656
  var valid_21627657 = query.getOrDefault("DBInstanceClass")
  valid_21627657 = validateParameter(valid_21627657, JString, required = false,
                                   default = nil)
  if valid_21627657 != nil:
    section.add "DBInstanceClass", valid_21627657
  var valid_21627658 = query.getOrDefault("Action")
  valid_21627658 = validateParameter(valid_21627658, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627658 != nil:
    section.add "Action", valid_21627658
  var valid_21627659 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_21627659 = validateParameter(valid_21627659, JBool, required = false,
                                   default = nil)
  if valid_21627659 != nil:
    section.add "AllowMajorVersionUpgrade", valid_21627659
  var valid_21627660 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_21627660 = validateParameter(valid_21627660, JString, required = false,
                                   default = nil)
  if valid_21627660 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627660
  var valid_21627661 = query.getOrDefault("TdeCredentialArn")
  valid_21627661 = validateParameter(valid_21627661, JString, required = false,
                                   default = nil)
  if valid_21627661 != nil:
    section.add "TdeCredentialArn", valid_21627661
  var valid_21627662 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627662 = validateParameter(valid_21627662, JBool, required = false,
                                   default = nil)
  if valid_21627662 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627662
  var valid_21627663 = query.getOrDefault("EngineVersion")
  valid_21627663 = validateParameter(valid_21627663, JString, required = false,
                                   default = nil)
  if valid_21627663 != nil:
    section.add "EngineVersion", valid_21627663
  var valid_21627664 = query.getOrDefault("PreferredBackupWindow")
  valid_21627664 = validateParameter(valid_21627664, JString, required = false,
                                   default = nil)
  if valid_21627664 != nil:
    section.add "PreferredBackupWindow", valid_21627664
  var valid_21627665 = query.getOrDefault("Version")
  valid_21627665 = validateParameter(valid_21627665, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627665 != nil:
    section.add "Version", valid_21627665
  var valid_21627666 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627666 = validateParameter(valid_21627666, JString, required = true,
                                   default = nil)
  if valid_21627666 != nil:
    section.add "DBInstanceIdentifier", valid_21627666
  var valid_21627667 = query.getOrDefault("ApplyImmediately")
  valid_21627667 = validateParameter(valid_21627667, JBool, required = false,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "ApplyImmediately", valid_21627667
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
  var valid_21627668 = header.getOrDefault("X-Amz-Date")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Date", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627669 = validateParameter(valid_21627669, JString, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "X-Amz-Security-Token", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627670 = validateParameter(valid_21627670, JString, required = false,
                                   default = nil)
  if valid_21627670 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-Algorithm", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Signature")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Signature", valid_21627672
  var valid_21627673 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627673 = validateParameter(valid_21627673, JString, required = false,
                                   default = nil)
  if valid_21627673 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627673
  var valid_21627674 = header.getOrDefault("X-Amz-Credential")
  valid_21627674 = validateParameter(valid_21627674, JString, required = false,
                                   default = nil)
  if valid_21627674 != nil:
    section.add "X-Amz-Credential", valid_21627674
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627675: Call_GetModifyDBInstance_21627642; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627675.validator(path, query, header, formData, body, _)
  let scheme = call_21627675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627675.makeUrl(scheme.get, call_21627675.host, call_21627675.base,
                               call_21627675.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627675, uri, valid, _)

proc call*(call_21627676: Call_GetModifyDBInstance_21627642;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; StorageType: string = "";
          OptionGroupName: string = ""; DBSecurityGroups: JsonNode = nil;
          MasterUserPassword: string = ""; Iops: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          TdeCredentialPassword: string = ""; BackupRetentionPeriod: int = 0;
          DBParameterGroupName: string = ""; DBInstanceClass: string = "";
          Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = ""; TdeCredentialArn: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2014-09-01";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int
  ##   StorageType: string
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   NewDBInstanceIdentifier: string
  ##   TdeCredentialArn: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  var query_21627677 = newJObject()
  add(query_21627677, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21627677, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_21627677, "StorageType", newJString(StorageType))
  add(query_21627677, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_21627677.add "DBSecurityGroups", DBSecurityGroups
  add(query_21627677, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_21627677, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_21627677.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_21627677, "MultiAZ", newJBool(MultiAZ))
  add(query_21627677, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_21627677, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627677, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21627677, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627677, "Action", newJString(Action))
  add(query_21627677, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(query_21627677, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_21627677, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_21627677, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21627677, "EngineVersion", newJString(EngineVersion))
  add(query_21627677, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21627677, "Version", newJString(Version))
  add(query_21627677, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627677, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_21627676.call(nil, query_21627677, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_21627642(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_21627643, base: "/",
    makeUrl: url_GetModifyDBInstance_21627644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_21627732 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBParameterGroup_21627734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_21627733(path: JsonNode; query: JsonNode;
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
  var valid_21627735 = query.getOrDefault("Action")
  valid_21627735 = validateParameter(valid_21627735, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_21627735 != nil:
    section.add "Action", valid_21627735
  var valid_21627736 = query.getOrDefault("Version")
  valid_21627736 = validateParameter(valid_21627736, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627736 != nil:
    section.add "Version", valid_21627736
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
  var valid_21627737 = header.getOrDefault("X-Amz-Date")
  valid_21627737 = validateParameter(valid_21627737, JString, required = false,
                                   default = nil)
  if valid_21627737 != nil:
    section.add "X-Amz-Date", valid_21627737
  var valid_21627738 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627738 = validateParameter(valid_21627738, JString, required = false,
                                   default = nil)
  if valid_21627738 != nil:
    section.add "X-Amz-Security-Token", valid_21627738
  var valid_21627739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627739 = validateParameter(valid_21627739, JString, required = false,
                                   default = nil)
  if valid_21627739 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627739
  var valid_21627740 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627740 = validateParameter(valid_21627740, JString, required = false,
                                   default = nil)
  if valid_21627740 != nil:
    section.add "X-Amz-Algorithm", valid_21627740
  var valid_21627741 = header.getOrDefault("X-Amz-Signature")
  valid_21627741 = validateParameter(valid_21627741, JString, required = false,
                                   default = nil)
  if valid_21627741 != nil:
    section.add "X-Amz-Signature", valid_21627741
  var valid_21627742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627742 = validateParameter(valid_21627742, JString, required = false,
                                   default = nil)
  if valid_21627742 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627742
  var valid_21627743 = header.getOrDefault("X-Amz-Credential")
  valid_21627743 = validateParameter(valid_21627743, JString, required = false,
                                   default = nil)
  if valid_21627743 != nil:
    section.add "X-Amz-Credential", valid_21627743
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627744 = formData.getOrDefault("DBParameterGroupName")
  valid_21627744 = validateParameter(valid_21627744, JString, required = true,
                                   default = nil)
  if valid_21627744 != nil:
    section.add "DBParameterGroupName", valid_21627744
  var valid_21627745 = formData.getOrDefault("Parameters")
  valid_21627745 = validateParameter(valid_21627745, JArray, required = true,
                                   default = nil)
  if valid_21627745 != nil:
    section.add "Parameters", valid_21627745
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627746: Call_PostModifyDBParameterGroup_21627732;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627746.validator(path, query, header, formData, body, _)
  let scheme = call_21627746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627746.makeUrl(scheme.get, call_21627746.host, call_21627746.base,
                               call_21627746.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627746, uri, valid, _)

proc call*(call_21627747: Call_PostModifyDBParameterGroup_21627732;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627748 = newJObject()
  var formData_21627749 = newJObject()
  add(formData_21627749, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_21627749.add "Parameters", Parameters
  add(query_21627748, "Action", newJString(Action))
  add(query_21627748, "Version", newJString(Version))
  result = call_21627747.call(nil, query_21627748, nil, formData_21627749, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_21627732(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_21627733, base: "/",
    makeUrl: url_PostModifyDBParameterGroup_21627734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_21627715 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBParameterGroup_21627717(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_21627716(path: JsonNode; query: JsonNode;
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
  var valid_21627718 = query.getOrDefault("DBParameterGroupName")
  valid_21627718 = validateParameter(valid_21627718, JString, required = true,
                                   default = nil)
  if valid_21627718 != nil:
    section.add "DBParameterGroupName", valid_21627718
  var valid_21627719 = query.getOrDefault("Parameters")
  valid_21627719 = validateParameter(valid_21627719, JArray, required = true,
                                   default = nil)
  if valid_21627719 != nil:
    section.add "Parameters", valid_21627719
  var valid_21627720 = query.getOrDefault("Action")
  valid_21627720 = validateParameter(valid_21627720, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_21627720 != nil:
    section.add "Action", valid_21627720
  var valid_21627721 = query.getOrDefault("Version")
  valid_21627721 = validateParameter(valid_21627721, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627721 != nil:
    section.add "Version", valid_21627721
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
  var valid_21627722 = header.getOrDefault("X-Amz-Date")
  valid_21627722 = validateParameter(valid_21627722, JString, required = false,
                                   default = nil)
  if valid_21627722 != nil:
    section.add "X-Amz-Date", valid_21627722
  var valid_21627723 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627723 = validateParameter(valid_21627723, JString, required = false,
                                   default = nil)
  if valid_21627723 != nil:
    section.add "X-Amz-Security-Token", valid_21627723
  var valid_21627724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627724 = validateParameter(valid_21627724, JString, required = false,
                                   default = nil)
  if valid_21627724 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627724
  var valid_21627725 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627725 = validateParameter(valid_21627725, JString, required = false,
                                   default = nil)
  if valid_21627725 != nil:
    section.add "X-Amz-Algorithm", valid_21627725
  var valid_21627726 = header.getOrDefault("X-Amz-Signature")
  valid_21627726 = validateParameter(valid_21627726, JString, required = false,
                                   default = nil)
  if valid_21627726 != nil:
    section.add "X-Amz-Signature", valid_21627726
  var valid_21627727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627727 = validateParameter(valid_21627727, JString, required = false,
                                   default = nil)
  if valid_21627727 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627727
  var valid_21627728 = header.getOrDefault("X-Amz-Credential")
  valid_21627728 = validateParameter(valid_21627728, JString, required = false,
                                   default = nil)
  if valid_21627728 != nil:
    section.add "X-Amz-Credential", valid_21627728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627729: Call_GetModifyDBParameterGroup_21627715;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627729.validator(path, query, header, formData, body, _)
  let scheme = call_21627729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627729.makeUrl(scheme.get, call_21627729.host, call_21627729.base,
                               call_21627729.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627729, uri, valid, _)

proc call*(call_21627730: Call_GetModifyDBParameterGroup_21627715;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627731 = newJObject()
  add(query_21627731, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_21627731.add "Parameters", Parameters
  add(query_21627731, "Action", newJString(Action))
  add(query_21627731, "Version", newJString(Version))
  result = call_21627730.call(nil, query_21627731, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_21627715(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_21627716, base: "/",
    makeUrl: url_GetModifyDBParameterGroup_21627717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_21627768 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBSubnetGroup_21627770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_21627769(path: JsonNode; query: JsonNode;
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
  var valid_21627771 = query.getOrDefault("Action")
  valid_21627771 = validateParameter(valid_21627771, JString, required = true,
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627771 != nil:
    section.add "Action", valid_21627771
  var valid_21627772 = query.getOrDefault("Version")
  valid_21627772 = validateParameter(valid_21627772, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627772 != nil:
    section.add "Version", valid_21627772
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
  var valid_21627773 = header.getOrDefault("X-Amz-Date")
  valid_21627773 = validateParameter(valid_21627773, JString, required = false,
                                   default = nil)
  if valid_21627773 != nil:
    section.add "X-Amz-Date", valid_21627773
  var valid_21627774 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627774 = validateParameter(valid_21627774, JString, required = false,
                                   default = nil)
  if valid_21627774 != nil:
    section.add "X-Amz-Security-Token", valid_21627774
  var valid_21627775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627775 = validateParameter(valid_21627775, JString, required = false,
                                   default = nil)
  if valid_21627775 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627775
  var valid_21627776 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627776 = validateParameter(valid_21627776, JString, required = false,
                                   default = nil)
  if valid_21627776 != nil:
    section.add "X-Amz-Algorithm", valid_21627776
  var valid_21627777 = header.getOrDefault("X-Amz-Signature")
  valid_21627777 = validateParameter(valid_21627777, JString, required = false,
                                   default = nil)
  if valid_21627777 != nil:
    section.add "X-Amz-Signature", valid_21627777
  var valid_21627778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627778 = validateParameter(valid_21627778, JString, required = false,
                                   default = nil)
  if valid_21627778 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627778
  var valid_21627779 = header.getOrDefault("X-Amz-Credential")
  valid_21627779 = validateParameter(valid_21627779, JString, required = false,
                                   default = nil)
  if valid_21627779 != nil:
    section.add "X-Amz-Credential", valid_21627779
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21627780 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627780 = validateParameter(valid_21627780, JString, required = true,
                                   default = nil)
  if valid_21627780 != nil:
    section.add "DBSubnetGroupName", valid_21627780
  var valid_21627781 = formData.getOrDefault("SubnetIds")
  valid_21627781 = validateParameter(valid_21627781, JArray, required = true,
                                   default = nil)
  if valid_21627781 != nil:
    section.add "SubnetIds", valid_21627781
  var valid_21627782 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21627782 = validateParameter(valid_21627782, JString, required = false,
                                   default = nil)
  if valid_21627782 != nil:
    section.add "DBSubnetGroupDescription", valid_21627782
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627783: Call_PostModifyDBSubnetGroup_21627768;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627783.validator(path, query, header, formData, body, _)
  let scheme = call_21627783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627783.makeUrl(scheme.get, call_21627783.host, call_21627783.base,
                               call_21627783.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627783, uri, valid, _)

proc call*(call_21627784: Call_PostModifyDBSubnetGroup_21627768;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_21627785 = newJObject()
  var formData_21627786 = newJObject()
  add(formData_21627786, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21627786.add "SubnetIds", SubnetIds
  add(query_21627785, "Action", newJString(Action))
  add(formData_21627786, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627785, "Version", newJString(Version))
  result = call_21627784.call(nil, query_21627785, nil, formData_21627786, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_21627768(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_21627769, base: "/",
    makeUrl: url_PostModifyDBSubnetGroup_21627770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_21627750 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBSubnetGroup_21627752(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_21627751(path: JsonNode; query: JsonNode;
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
  var valid_21627753 = query.getOrDefault("Action")
  valid_21627753 = validateParameter(valid_21627753, JString, required = true,
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627753 != nil:
    section.add "Action", valid_21627753
  var valid_21627754 = query.getOrDefault("DBSubnetGroupName")
  valid_21627754 = validateParameter(valid_21627754, JString, required = true,
                                   default = nil)
  if valid_21627754 != nil:
    section.add "DBSubnetGroupName", valid_21627754
  var valid_21627755 = query.getOrDefault("SubnetIds")
  valid_21627755 = validateParameter(valid_21627755, JArray, required = true,
                                   default = nil)
  if valid_21627755 != nil:
    section.add "SubnetIds", valid_21627755
  var valid_21627756 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21627756 = validateParameter(valid_21627756, JString, required = false,
                                   default = nil)
  if valid_21627756 != nil:
    section.add "DBSubnetGroupDescription", valid_21627756
  var valid_21627757 = query.getOrDefault("Version")
  valid_21627757 = validateParameter(valid_21627757, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627757 != nil:
    section.add "Version", valid_21627757
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
  var valid_21627758 = header.getOrDefault("X-Amz-Date")
  valid_21627758 = validateParameter(valid_21627758, JString, required = false,
                                   default = nil)
  if valid_21627758 != nil:
    section.add "X-Amz-Date", valid_21627758
  var valid_21627759 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627759 = validateParameter(valid_21627759, JString, required = false,
                                   default = nil)
  if valid_21627759 != nil:
    section.add "X-Amz-Security-Token", valid_21627759
  var valid_21627760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627760 = validateParameter(valid_21627760, JString, required = false,
                                   default = nil)
  if valid_21627760 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627760
  var valid_21627761 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627761 = validateParameter(valid_21627761, JString, required = false,
                                   default = nil)
  if valid_21627761 != nil:
    section.add "X-Amz-Algorithm", valid_21627761
  var valid_21627762 = header.getOrDefault("X-Amz-Signature")
  valid_21627762 = validateParameter(valid_21627762, JString, required = false,
                                   default = nil)
  if valid_21627762 != nil:
    section.add "X-Amz-Signature", valid_21627762
  var valid_21627763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627763 = validateParameter(valid_21627763, JString, required = false,
                                   default = nil)
  if valid_21627763 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627763
  var valid_21627764 = header.getOrDefault("X-Amz-Credential")
  valid_21627764 = validateParameter(valid_21627764, JString, required = false,
                                   default = nil)
  if valid_21627764 != nil:
    section.add "X-Amz-Credential", valid_21627764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627765: Call_GetModifyDBSubnetGroup_21627750;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627765.validator(path, query, header, formData, body, _)
  let scheme = call_21627765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627765.makeUrl(scheme.get, call_21627765.host, call_21627765.base,
                               call_21627765.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627765, uri, valid, _)

proc call*(call_21627766: Call_GetModifyDBSubnetGroup_21627750;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_21627767 = newJObject()
  add(query_21627767, "Action", newJString(Action))
  add(query_21627767, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21627767.add "SubnetIds", SubnetIds
  add(query_21627767, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627767, "Version", newJString(Version))
  result = call_21627766.call(nil, query_21627767, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_21627750(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_21627751, base: "/",
    makeUrl: url_GetModifyDBSubnetGroup_21627752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_21627807 = ref object of OpenApiRestCall_21625418
proc url_PostModifyEventSubscription_21627809(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_21627808(path: JsonNode; query: JsonNode;
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
  var valid_21627810 = query.getOrDefault("Action")
  valid_21627810 = validateParameter(valid_21627810, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_21627810 != nil:
    section.add "Action", valid_21627810
  var valid_21627811 = query.getOrDefault("Version")
  valid_21627811 = validateParameter(valid_21627811, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627811 != nil:
    section.add "Version", valid_21627811
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
  var valid_21627812 = header.getOrDefault("X-Amz-Date")
  valid_21627812 = validateParameter(valid_21627812, JString, required = false,
                                   default = nil)
  if valid_21627812 != nil:
    section.add "X-Amz-Date", valid_21627812
  var valid_21627813 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627813 = validateParameter(valid_21627813, JString, required = false,
                                   default = nil)
  if valid_21627813 != nil:
    section.add "X-Amz-Security-Token", valid_21627813
  var valid_21627814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627814 = validateParameter(valid_21627814, JString, required = false,
                                   default = nil)
  if valid_21627814 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627814
  var valid_21627815 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627815 = validateParameter(valid_21627815, JString, required = false,
                                   default = nil)
  if valid_21627815 != nil:
    section.add "X-Amz-Algorithm", valid_21627815
  var valid_21627816 = header.getOrDefault("X-Amz-Signature")
  valid_21627816 = validateParameter(valid_21627816, JString, required = false,
                                   default = nil)
  if valid_21627816 != nil:
    section.add "X-Amz-Signature", valid_21627816
  var valid_21627817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627817 = validateParameter(valid_21627817, JString, required = false,
                                   default = nil)
  if valid_21627817 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627817
  var valid_21627818 = header.getOrDefault("X-Amz-Credential")
  valid_21627818 = validateParameter(valid_21627818, JString, required = false,
                                   default = nil)
  if valid_21627818 != nil:
    section.add "X-Amz-Credential", valid_21627818
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_21627819 = formData.getOrDefault("Enabled")
  valid_21627819 = validateParameter(valid_21627819, JBool, required = false,
                                   default = nil)
  if valid_21627819 != nil:
    section.add "Enabled", valid_21627819
  var valid_21627820 = formData.getOrDefault("EventCategories")
  valid_21627820 = validateParameter(valid_21627820, JArray, required = false,
                                   default = nil)
  if valid_21627820 != nil:
    section.add "EventCategories", valid_21627820
  var valid_21627821 = formData.getOrDefault("SnsTopicArn")
  valid_21627821 = validateParameter(valid_21627821, JString, required = false,
                                   default = nil)
  if valid_21627821 != nil:
    section.add "SnsTopicArn", valid_21627821
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_21627822 = formData.getOrDefault("SubscriptionName")
  valid_21627822 = validateParameter(valid_21627822, JString, required = true,
                                   default = nil)
  if valid_21627822 != nil:
    section.add "SubscriptionName", valid_21627822
  var valid_21627823 = formData.getOrDefault("SourceType")
  valid_21627823 = validateParameter(valid_21627823, JString, required = false,
                                   default = nil)
  if valid_21627823 != nil:
    section.add "SourceType", valid_21627823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627824: Call_PostModifyEventSubscription_21627807;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627824.validator(path, query, header, formData, body, _)
  let scheme = call_21627824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627824.makeUrl(scheme.get, call_21627824.host, call_21627824.base,
                               call_21627824.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627824, uri, valid, _)

proc call*(call_21627825: Call_PostModifyEventSubscription_21627807;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627826 = newJObject()
  var formData_21627827 = newJObject()
  add(formData_21627827, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_21627827.add "EventCategories", EventCategories
  add(formData_21627827, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_21627827, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627826, "Action", newJString(Action))
  add(query_21627826, "Version", newJString(Version))
  add(formData_21627827, "SourceType", newJString(SourceType))
  result = call_21627825.call(nil, query_21627826, nil, formData_21627827, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_21627807(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_21627808, base: "/",
    makeUrl: url_PostModifyEventSubscription_21627809,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_21627787 = ref object of OpenApiRestCall_21625418
proc url_GetModifyEventSubscription_21627789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_21627788(path: JsonNode; query: JsonNode;
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
  var valid_21627790 = query.getOrDefault("SourceType")
  valid_21627790 = validateParameter(valid_21627790, JString, required = false,
                                   default = nil)
  if valid_21627790 != nil:
    section.add "SourceType", valid_21627790
  var valid_21627791 = query.getOrDefault("Enabled")
  valid_21627791 = validateParameter(valid_21627791, JBool, required = false,
                                   default = nil)
  if valid_21627791 != nil:
    section.add "Enabled", valid_21627791
  var valid_21627792 = query.getOrDefault("Action")
  valid_21627792 = validateParameter(valid_21627792, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_21627792 != nil:
    section.add "Action", valid_21627792
  var valid_21627793 = query.getOrDefault("SnsTopicArn")
  valid_21627793 = validateParameter(valid_21627793, JString, required = false,
                                   default = nil)
  if valid_21627793 != nil:
    section.add "SnsTopicArn", valid_21627793
  var valid_21627794 = query.getOrDefault("EventCategories")
  valid_21627794 = validateParameter(valid_21627794, JArray, required = false,
                                   default = nil)
  if valid_21627794 != nil:
    section.add "EventCategories", valid_21627794
  var valid_21627795 = query.getOrDefault("SubscriptionName")
  valid_21627795 = validateParameter(valid_21627795, JString, required = true,
                                   default = nil)
  if valid_21627795 != nil:
    section.add "SubscriptionName", valid_21627795
  var valid_21627796 = query.getOrDefault("Version")
  valid_21627796 = validateParameter(valid_21627796, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627796 != nil:
    section.add "Version", valid_21627796
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
  var valid_21627797 = header.getOrDefault("X-Amz-Date")
  valid_21627797 = validateParameter(valid_21627797, JString, required = false,
                                   default = nil)
  if valid_21627797 != nil:
    section.add "X-Amz-Date", valid_21627797
  var valid_21627798 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627798 = validateParameter(valid_21627798, JString, required = false,
                                   default = nil)
  if valid_21627798 != nil:
    section.add "X-Amz-Security-Token", valid_21627798
  var valid_21627799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627799 = validateParameter(valid_21627799, JString, required = false,
                                   default = nil)
  if valid_21627799 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627799
  var valid_21627800 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627800 = validateParameter(valid_21627800, JString, required = false,
                                   default = nil)
  if valid_21627800 != nil:
    section.add "X-Amz-Algorithm", valid_21627800
  var valid_21627801 = header.getOrDefault("X-Amz-Signature")
  valid_21627801 = validateParameter(valid_21627801, JString, required = false,
                                   default = nil)
  if valid_21627801 != nil:
    section.add "X-Amz-Signature", valid_21627801
  var valid_21627802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627802 = validateParameter(valid_21627802, JString, required = false,
                                   default = nil)
  if valid_21627802 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627802
  var valid_21627803 = header.getOrDefault("X-Amz-Credential")
  valid_21627803 = validateParameter(valid_21627803, JString, required = false,
                                   default = nil)
  if valid_21627803 != nil:
    section.add "X-Amz-Credential", valid_21627803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627804: Call_GetModifyEventSubscription_21627787;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627804.validator(path, query, header, formData, body, _)
  let scheme = call_21627804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627804.makeUrl(scheme.get, call_21627804.host, call_21627804.base,
                               call_21627804.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627804, uri, valid, _)

proc call*(call_21627805: Call_GetModifyEventSubscription_21627787;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2014-09-01"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21627806 = newJObject()
  add(query_21627806, "SourceType", newJString(SourceType))
  add(query_21627806, "Enabled", newJBool(Enabled))
  add(query_21627806, "Action", newJString(Action))
  add(query_21627806, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_21627806.add "EventCategories", EventCategories
  add(query_21627806, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627806, "Version", newJString(Version))
  result = call_21627805.call(nil, query_21627806, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_21627787(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_21627788, base: "/",
    makeUrl: url_GetModifyEventSubscription_21627789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_21627847 = ref object of OpenApiRestCall_21625418
proc url_PostModifyOptionGroup_21627849(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_21627848(path: JsonNode; query: JsonNode;
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
  var valid_21627850 = query.getOrDefault("Action")
  valid_21627850 = validateParameter(valid_21627850, JString, required = true,
                                   default = newJString("ModifyOptionGroup"))
  if valid_21627850 != nil:
    section.add "Action", valid_21627850
  var valid_21627851 = query.getOrDefault("Version")
  valid_21627851 = validateParameter(valid_21627851, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627851 != nil:
    section.add "Version", valid_21627851
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
  var valid_21627852 = header.getOrDefault("X-Amz-Date")
  valid_21627852 = validateParameter(valid_21627852, JString, required = false,
                                   default = nil)
  if valid_21627852 != nil:
    section.add "X-Amz-Date", valid_21627852
  var valid_21627853 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627853 = validateParameter(valid_21627853, JString, required = false,
                                   default = nil)
  if valid_21627853 != nil:
    section.add "X-Amz-Security-Token", valid_21627853
  var valid_21627854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627854 = validateParameter(valid_21627854, JString, required = false,
                                   default = nil)
  if valid_21627854 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627854
  var valid_21627855 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627855 = validateParameter(valid_21627855, JString, required = false,
                                   default = nil)
  if valid_21627855 != nil:
    section.add "X-Amz-Algorithm", valid_21627855
  var valid_21627856 = header.getOrDefault("X-Amz-Signature")
  valid_21627856 = validateParameter(valid_21627856, JString, required = false,
                                   default = nil)
  if valid_21627856 != nil:
    section.add "X-Amz-Signature", valid_21627856
  var valid_21627857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627857 = validateParameter(valid_21627857, JString, required = false,
                                   default = nil)
  if valid_21627857 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627857
  var valid_21627858 = header.getOrDefault("X-Amz-Credential")
  valid_21627858 = validateParameter(valid_21627858, JString, required = false,
                                   default = nil)
  if valid_21627858 != nil:
    section.add "X-Amz-Credential", valid_21627858
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_21627859 = formData.getOrDefault("OptionsToRemove")
  valid_21627859 = validateParameter(valid_21627859, JArray, required = false,
                                   default = nil)
  if valid_21627859 != nil:
    section.add "OptionsToRemove", valid_21627859
  var valid_21627860 = formData.getOrDefault("ApplyImmediately")
  valid_21627860 = validateParameter(valid_21627860, JBool, required = false,
                                   default = nil)
  if valid_21627860 != nil:
    section.add "ApplyImmediately", valid_21627860
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_21627861 = formData.getOrDefault("OptionGroupName")
  valid_21627861 = validateParameter(valid_21627861, JString, required = true,
                                   default = nil)
  if valid_21627861 != nil:
    section.add "OptionGroupName", valid_21627861
  var valid_21627862 = formData.getOrDefault("OptionsToInclude")
  valid_21627862 = validateParameter(valid_21627862, JArray, required = false,
                                   default = nil)
  if valid_21627862 != nil:
    section.add "OptionsToInclude", valid_21627862
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627863: Call_PostModifyOptionGroup_21627847;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627863.validator(path, query, header, formData, body, _)
  let scheme = call_21627863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627863.makeUrl(scheme.get, call_21627863.host, call_21627863.base,
                               call_21627863.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627863, uri, valid, _)

proc call*(call_21627864: Call_PostModifyOptionGroup_21627847;
          OptionGroupName: string; OptionsToRemove: JsonNode = nil;
          ApplyImmediately: bool = false; OptionsToInclude: JsonNode = nil;
          Action: string = "ModifyOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627865 = newJObject()
  var formData_21627866 = newJObject()
  if OptionsToRemove != nil:
    formData_21627866.add "OptionsToRemove", OptionsToRemove
  add(formData_21627866, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_21627866, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_21627866.add "OptionsToInclude", OptionsToInclude
  add(query_21627865, "Action", newJString(Action))
  add(query_21627865, "Version", newJString(Version))
  result = call_21627864.call(nil, query_21627865, nil, formData_21627866, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_21627847(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_21627848, base: "/",
    makeUrl: url_PostModifyOptionGroup_21627849,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_21627828 = ref object of OpenApiRestCall_21625418
proc url_GetModifyOptionGroup_21627830(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_21627829(path: JsonNode; query: JsonNode;
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
  var valid_21627831 = query.getOrDefault("OptionGroupName")
  valid_21627831 = validateParameter(valid_21627831, JString, required = true,
                                   default = nil)
  if valid_21627831 != nil:
    section.add "OptionGroupName", valid_21627831
  var valid_21627832 = query.getOrDefault("OptionsToRemove")
  valid_21627832 = validateParameter(valid_21627832, JArray, required = false,
                                   default = nil)
  if valid_21627832 != nil:
    section.add "OptionsToRemove", valid_21627832
  var valid_21627833 = query.getOrDefault("Action")
  valid_21627833 = validateParameter(valid_21627833, JString, required = true,
                                   default = newJString("ModifyOptionGroup"))
  if valid_21627833 != nil:
    section.add "Action", valid_21627833
  var valid_21627834 = query.getOrDefault("Version")
  valid_21627834 = validateParameter(valid_21627834, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627834 != nil:
    section.add "Version", valid_21627834
  var valid_21627835 = query.getOrDefault("ApplyImmediately")
  valid_21627835 = validateParameter(valid_21627835, JBool, required = false,
                                   default = nil)
  if valid_21627835 != nil:
    section.add "ApplyImmediately", valid_21627835
  var valid_21627836 = query.getOrDefault("OptionsToInclude")
  valid_21627836 = validateParameter(valid_21627836, JArray, required = false,
                                   default = nil)
  if valid_21627836 != nil:
    section.add "OptionsToInclude", valid_21627836
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
  var valid_21627837 = header.getOrDefault("X-Amz-Date")
  valid_21627837 = validateParameter(valid_21627837, JString, required = false,
                                   default = nil)
  if valid_21627837 != nil:
    section.add "X-Amz-Date", valid_21627837
  var valid_21627838 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627838 = validateParameter(valid_21627838, JString, required = false,
                                   default = nil)
  if valid_21627838 != nil:
    section.add "X-Amz-Security-Token", valid_21627838
  var valid_21627839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627839 = validateParameter(valid_21627839, JString, required = false,
                                   default = nil)
  if valid_21627839 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627839
  var valid_21627840 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627840 = validateParameter(valid_21627840, JString, required = false,
                                   default = nil)
  if valid_21627840 != nil:
    section.add "X-Amz-Algorithm", valid_21627840
  var valid_21627841 = header.getOrDefault("X-Amz-Signature")
  valid_21627841 = validateParameter(valid_21627841, JString, required = false,
                                   default = nil)
  if valid_21627841 != nil:
    section.add "X-Amz-Signature", valid_21627841
  var valid_21627842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627842 = validateParameter(valid_21627842, JString, required = false,
                                   default = nil)
  if valid_21627842 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627842
  var valid_21627843 = header.getOrDefault("X-Amz-Credential")
  valid_21627843 = validateParameter(valid_21627843, JString, required = false,
                                   default = nil)
  if valid_21627843 != nil:
    section.add "X-Amz-Credential", valid_21627843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627844: Call_GetModifyOptionGroup_21627828; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627844.validator(path, query, header, formData, body, _)
  let scheme = call_21627844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627844.makeUrl(scheme.get, call_21627844.host, call_21627844.base,
                               call_21627844.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627844, uri, valid, _)

proc call*(call_21627845: Call_GetModifyOptionGroup_21627828;
          OptionGroupName: string; OptionsToRemove: JsonNode = nil;
          Action: string = "ModifyOptionGroup"; Version: string = "2014-09-01";
          ApplyImmediately: bool = false; OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_21627846 = newJObject()
  add(query_21627846, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_21627846.add "OptionsToRemove", OptionsToRemove
  add(query_21627846, "Action", newJString(Action))
  add(query_21627846, "Version", newJString(Version))
  add(query_21627846, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_21627846.add "OptionsToInclude", OptionsToInclude
  result = call_21627845.call(nil, query_21627846, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_21627828(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_21627829, base: "/",
    makeUrl: url_GetModifyOptionGroup_21627830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_21627885 = ref object of OpenApiRestCall_21625418
proc url_PostPromoteReadReplica_21627887(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_21627886(path: JsonNode; query: JsonNode;
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
  var valid_21627888 = query.getOrDefault("Action")
  valid_21627888 = validateParameter(valid_21627888, JString, required = true,
                                   default = newJString("PromoteReadReplica"))
  if valid_21627888 != nil:
    section.add "Action", valid_21627888
  var valid_21627889 = query.getOrDefault("Version")
  valid_21627889 = validateParameter(valid_21627889, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627889 != nil:
    section.add "Version", valid_21627889
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
  var valid_21627890 = header.getOrDefault("X-Amz-Date")
  valid_21627890 = validateParameter(valid_21627890, JString, required = false,
                                   default = nil)
  if valid_21627890 != nil:
    section.add "X-Amz-Date", valid_21627890
  var valid_21627891 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627891 = validateParameter(valid_21627891, JString, required = false,
                                   default = nil)
  if valid_21627891 != nil:
    section.add "X-Amz-Security-Token", valid_21627891
  var valid_21627892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627892 = validateParameter(valid_21627892, JString, required = false,
                                   default = nil)
  if valid_21627892 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627892
  var valid_21627893 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627893 = validateParameter(valid_21627893, JString, required = false,
                                   default = nil)
  if valid_21627893 != nil:
    section.add "X-Amz-Algorithm", valid_21627893
  var valid_21627894 = header.getOrDefault("X-Amz-Signature")
  valid_21627894 = validateParameter(valid_21627894, JString, required = false,
                                   default = nil)
  if valid_21627894 != nil:
    section.add "X-Amz-Signature", valid_21627894
  var valid_21627895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627895 = validateParameter(valid_21627895, JString, required = false,
                                   default = nil)
  if valid_21627895 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627895
  var valid_21627896 = header.getOrDefault("X-Amz-Credential")
  valid_21627896 = validateParameter(valid_21627896, JString, required = false,
                                   default = nil)
  if valid_21627896 != nil:
    section.add "X-Amz-Credential", valid_21627896
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627897 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627897 = validateParameter(valid_21627897, JString, required = true,
                                   default = nil)
  if valid_21627897 != nil:
    section.add "DBInstanceIdentifier", valid_21627897
  var valid_21627898 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21627898 = validateParameter(valid_21627898, JInt, required = false,
                                   default = nil)
  if valid_21627898 != nil:
    section.add "BackupRetentionPeriod", valid_21627898
  var valid_21627899 = formData.getOrDefault("PreferredBackupWindow")
  valid_21627899 = validateParameter(valid_21627899, JString, required = false,
                                   default = nil)
  if valid_21627899 != nil:
    section.add "PreferredBackupWindow", valid_21627899
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627900: Call_PostPromoteReadReplica_21627885;
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

proc call*(call_21627901: Call_PostPromoteReadReplica_21627885;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_21627902 = newJObject()
  var formData_21627903 = newJObject()
  add(formData_21627903, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627903, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627902, "Action", newJString(Action))
  add(formData_21627903, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_21627902, "Version", newJString(Version))
  result = call_21627901.call(nil, query_21627902, nil, formData_21627903, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_21627885(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_21627886, base: "/",
    makeUrl: url_PostPromoteReadReplica_21627887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_21627867 = ref object of OpenApiRestCall_21625418
proc url_GetPromoteReadReplica_21627869(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_21627868(path: JsonNode; query: JsonNode;
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
  var valid_21627870 = query.getOrDefault("BackupRetentionPeriod")
  valid_21627870 = validateParameter(valid_21627870, JInt, required = false,
                                   default = nil)
  if valid_21627870 != nil:
    section.add "BackupRetentionPeriod", valid_21627870
  var valid_21627871 = query.getOrDefault("Action")
  valid_21627871 = validateParameter(valid_21627871, JString, required = true,
                                   default = newJString("PromoteReadReplica"))
  if valid_21627871 != nil:
    section.add "Action", valid_21627871
  var valid_21627872 = query.getOrDefault("PreferredBackupWindow")
  valid_21627872 = validateParameter(valid_21627872, JString, required = false,
                                   default = nil)
  if valid_21627872 != nil:
    section.add "PreferredBackupWindow", valid_21627872
  var valid_21627873 = query.getOrDefault("Version")
  valid_21627873 = validateParameter(valid_21627873, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627873 != nil:
    section.add "Version", valid_21627873
  var valid_21627874 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627874 = validateParameter(valid_21627874, JString, required = true,
                                   default = nil)
  if valid_21627874 != nil:
    section.add "DBInstanceIdentifier", valid_21627874
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
  var valid_21627875 = header.getOrDefault("X-Amz-Date")
  valid_21627875 = validateParameter(valid_21627875, JString, required = false,
                                   default = nil)
  if valid_21627875 != nil:
    section.add "X-Amz-Date", valid_21627875
  var valid_21627876 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627876 = validateParameter(valid_21627876, JString, required = false,
                                   default = nil)
  if valid_21627876 != nil:
    section.add "X-Amz-Security-Token", valid_21627876
  var valid_21627877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627877 = validateParameter(valid_21627877, JString, required = false,
                                   default = nil)
  if valid_21627877 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627877
  var valid_21627878 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627878 = validateParameter(valid_21627878, JString, required = false,
                                   default = nil)
  if valid_21627878 != nil:
    section.add "X-Amz-Algorithm", valid_21627878
  var valid_21627879 = header.getOrDefault("X-Amz-Signature")
  valid_21627879 = validateParameter(valid_21627879, JString, required = false,
                                   default = nil)
  if valid_21627879 != nil:
    section.add "X-Amz-Signature", valid_21627879
  var valid_21627880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627880 = validateParameter(valid_21627880, JString, required = false,
                                   default = nil)
  if valid_21627880 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627880
  var valid_21627881 = header.getOrDefault("X-Amz-Credential")
  valid_21627881 = validateParameter(valid_21627881, JString, required = false,
                                   default = nil)
  if valid_21627881 != nil:
    section.add "X-Amz-Credential", valid_21627881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627882: Call_GetPromoteReadReplica_21627867;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627882.validator(path, query, header, formData, body, _)
  let scheme = call_21627882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627882.makeUrl(scheme.get, call_21627882.host, call_21627882.base,
                               call_21627882.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627882, uri, valid, _)

proc call*(call_21627883: Call_GetPromoteReadReplica_21627867;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627884 = newJObject()
  add(query_21627884, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627884, "Action", newJString(Action))
  add(query_21627884, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21627884, "Version", newJString(Version))
  add(query_21627884, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627883.call(nil, query_21627884, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_21627867(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_21627868, base: "/",
    makeUrl: url_GetPromoteReadReplica_21627869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_21627923 = ref object of OpenApiRestCall_21625418
proc url_PostPurchaseReservedDBInstancesOffering_21627925(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_21627924(path: JsonNode;
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
  var valid_21627926 = query.getOrDefault("Action")
  valid_21627926 = validateParameter(valid_21627926, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_21627926 != nil:
    section.add "Action", valid_21627926
  var valid_21627927 = query.getOrDefault("Version")
  valid_21627927 = validateParameter(valid_21627927, JString, required = true,
                                   default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_21627935 = formData.getOrDefault("ReservedDBInstanceId")
  valid_21627935 = validateParameter(valid_21627935, JString, required = false,
                                   default = nil)
  if valid_21627935 != nil:
    section.add "ReservedDBInstanceId", valid_21627935
  var valid_21627936 = formData.getOrDefault("Tags")
  valid_21627936 = validateParameter(valid_21627936, JArray, required = false,
                                   default = nil)
  if valid_21627936 != nil:
    section.add "Tags", valid_21627936
  var valid_21627937 = formData.getOrDefault("DBInstanceCount")
  valid_21627937 = validateParameter(valid_21627937, JInt, required = false,
                                   default = nil)
  if valid_21627937 != nil:
    section.add "DBInstanceCount", valid_21627937
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_21627938 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627938 = validateParameter(valid_21627938, JString, required = true,
                                   default = nil)
  if valid_21627938 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627938
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627939: Call_PostPurchaseReservedDBInstancesOffering_21627923;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627939.validator(path, query, header, formData, body, _)
  let scheme = call_21627939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627939.makeUrl(scheme.get, call_21627939.host, call_21627939.base,
                               call_21627939.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627939, uri, valid, _)

proc call*(call_21627940: Call_PostPurchaseReservedDBInstancesOffering_21627923;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; Tags: JsonNode = nil;
          DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2014-09-01"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_21627941 = newJObject()
  var formData_21627942 = newJObject()
  add(formData_21627942, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_21627942.add "Tags", Tags
  add(formData_21627942, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_21627941, "Action", newJString(Action))
  add(formData_21627942, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627941, "Version", newJString(Version))
  result = call_21627940.call(nil, query_21627941, nil, formData_21627942, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_21627923(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_21627924,
    base: "/", makeUrl: url_PostPurchaseReservedDBInstancesOffering_21627925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_21627904 = ref object of OpenApiRestCall_21625418
proc url_GetPurchaseReservedDBInstancesOffering_21627906(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_21627905(path: JsonNode;
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
  var valid_21627907 = query.getOrDefault("DBInstanceCount")
  valid_21627907 = validateParameter(valid_21627907, JInt, required = false,
                                   default = nil)
  if valid_21627907 != nil:
    section.add "DBInstanceCount", valid_21627907
  var valid_21627908 = query.getOrDefault("Tags")
  valid_21627908 = validateParameter(valid_21627908, JArray, required = false,
                                   default = nil)
  if valid_21627908 != nil:
    section.add "Tags", valid_21627908
  var valid_21627909 = query.getOrDefault("ReservedDBInstanceId")
  valid_21627909 = validateParameter(valid_21627909, JString, required = false,
                                   default = nil)
  if valid_21627909 != nil:
    section.add "ReservedDBInstanceId", valid_21627909
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_21627910 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627910 = validateParameter(valid_21627910, JString, required = true,
                                   default = nil)
  if valid_21627910 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627910
  var valid_21627911 = query.getOrDefault("Action")
  valid_21627911 = validateParameter(valid_21627911, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_21627911 != nil:
    section.add "Action", valid_21627911
  var valid_21627912 = query.getOrDefault("Version")
  valid_21627912 = validateParameter(valid_21627912, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627912 != nil:
    section.add "Version", valid_21627912
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
  var valid_21627913 = header.getOrDefault("X-Amz-Date")
  valid_21627913 = validateParameter(valid_21627913, JString, required = false,
                                   default = nil)
  if valid_21627913 != nil:
    section.add "X-Amz-Date", valid_21627913
  var valid_21627914 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627914 = validateParameter(valid_21627914, JString, required = false,
                                   default = nil)
  if valid_21627914 != nil:
    section.add "X-Amz-Security-Token", valid_21627914
  var valid_21627915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627915 = validateParameter(valid_21627915, JString, required = false,
                                   default = nil)
  if valid_21627915 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627915
  var valid_21627916 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627916 = validateParameter(valid_21627916, JString, required = false,
                                   default = nil)
  if valid_21627916 != nil:
    section.add "X-Amz-Algorithm", valid_21627916
  var valid_21627917 = header.getOrDefault("X-Amz-Signature")
  valid_21627917 = validateParameter(valid_21627917, JString, required = false,
                                   default = nil)
  if valid_21627917 != nil:
    section.add "X-Amz-Signature", valid_21627917
  var valid_21627918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627918 = validateParameter(valid_21627918, JString, required = false,
                                   default = nil)
  if valid_21627918 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627918
  var valid_21627919 = header.getOrDefault("X-Amz-Credential")
  valid_21627919 = validateParameter(valid_21627919, JString, required = false,
                                   default = nil)
  if valid_21627919 != nil:
    section.add "X-Amz-Credential", valid_21627919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627920: Call_GetPurchaseReservedDBInstancesOffering_21627904;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627920.validator(path, query, header, formData, body, _)
  let scheme = call_21627920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627920.makeUrl(scheme.get, call_21627920.host, call_21627920.base,
                               call_21627920.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627920, uri, valid, _)

proc call*(call_21627921: Call_GetPurchaseReservedDBInstancesOffering_21627904;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          Tags: JsonNode = nil; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2014-09-01"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   Tags: JArray
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627922 = newJObject()
  add(query_21627922, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_21627922.add "Tags", Tags
  add(query_21627922, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_21627922, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627922, "Action", newJString(Action))
  add(query_21627922, "Version", newJString(Version))
  result = call_21627921.call(nil, query_21627922, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_21627904(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_21627905,
    base: "/", makeUrl: url_GetPurchaseReservedDBInstancesOffering_21627906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_21627960 = ref object of OpenApiRestCall_21625418
proc url_PostRebootDBInstance_21627962(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_21627961(path: JsonNode; query: JsonNode;
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
  var valid_21627963 = query.getOrDefault("Action")
  valid_21627963 = validateParameter(valid_21627963, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627963 != nil:
    section.add "Action", valid_21627963
  var valid_21627964 = query.getOrDefault("Version")
  valid_21627964 = validateParameter(valid_21627964, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627964 != nil:
    section.add "Version", valid_21627964
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
  var valid_21627965 = header.getOrDefault("X-Amz-Date")
  valid_21627965 = validateParameter(valid_21627965, JString, required = false,
                                   default = nil)
  if valid_21627965 != nil:
    section.add "X-Amz-Date", valid_21627965
  var valid_21627966 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627966 = validateParameter(valid_21627966, JString, required = false,
                                   default = nil)
  if valid_21627966 != nil:
    section.add "X-Amz-Security-Token", valid_21627966
  var valid_21627967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627967 = validateParameter(valid_21627967, JString, required = false,
                                   default = nil)
  if valid_21627967 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627967
  var valid_21627968 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627968 = validateParameter(valid_21627968, JString, required = false,
                                   default = nil)
  if valid_21627968 != nil:
    section.add "X-Amz-Algorithm", valid_21627968
  var valid_21627969 = header.getOrDefault("X-Amz-Signature")
  valid_21627969 = validateParameter(valid_21627969, JString, required = false,
                                   default = nil)
  if valid_21627969 != nil:
    section.add "X-Amz-Signature", valid_21627969
  var valid_21627970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627970 = validateParameter(valid_21627970, JString, required = false,
                                   default = nil)
  if valid_21627970 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627970
  var valid_21627971 = header.getOrDefault("X-Amz-Credential")
  valid_21627971 = validateParameter(valid_21627971, JString, required = false,
                                   default = nil)
  if valid_21627971 != nil:
    section.add "X-Amz-Credential", valid_21627971
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627972 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627972 = validateParameter(valid_21627972, JString, required = true,
                                   default = nil)
  if valid_21627972 != nil:
    section.add "DBInstanceIdentifier", valid_21627972
  var valid_21627973 = formData.getOrDefault("ForceFailover")
  valid_21627973 = validateParameter(valid_21627973, JBool, required = false,
                                   default = nil)
  if valid_21627973 != nil:
    section.add "ForceFailover", valid_21627973
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627974: Call_PostRebootDBInstance_21627960; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627974.validator(path, query, header, formData, body, _)
  let scheme = call_21627974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627974.makeUrl(scheme.get, call_21627974.host, call_21627974.base,
                               call_21627974.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627974, uri, valid, _)

proc call*(call_21627975: Call_PostRebootDBInstance_21627960;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_21627976 = newJObject()
  var formData_21627977 = newJObject()
  add(formData_21627977, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627976, "Action", newJString(Action))
  add(formData_21627977, "ForceFailover", newJBool(ForceFailover))
  add(query_21627976, "Version", newJString(Version))
  result = call_21627975.call(nil, query_21627976, nil, formData_21627977, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_21627960(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_21627961, base: "/",
    makeUrl: url_PostRebootDBInstance_21627962,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_21627943 = ref object of OpenApiRestCall_21625418
proc url_GetRebootDBInstance_21627945(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_21627944(path: JsonNode; query: JsonNode;
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
  var valid_21627946 = query.getOrDefault("Action")
  valid_21627946 = validateParameter(valid_21627946, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627946 != nil:
    section.add "Action", valid_21627946
  var valid_21627947 = query.getOrDefault("ForceFailover")
  valid_21627947 = validateParameter(valid_21627947, JBool, required = false,
                                   default = nil)
  if valid_21627947 != nil:
    section.add "ForceFailover", valid_21627947
  var valid_21627948 = query.getOrDefault("Version")
  valid_21627948 = validateParameter(valid_21627948, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21627948 != nil:
    section.add "Version", valid_21627948
  var valid_21627949 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627949 = validateParameter(valid_21627949, JString, required = true,
                                   default = nil)
  if valid_21627949 != nil:
    section.add "DBInstanceIdentifier", valid_21627949
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
  var valid_21627950 = header.getOrDefault("X-Amz-Date")
  valid_21627950 = validateParameter(valid_21627950, JString, required = false,
                                   default = nil)
  if valid_21627950 != nil:
    section.add "X-Amz-Date", valid_21627950
  var valid_21627951 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627951 = validateParameter(valid_21627951, JString, required = false,
                                   default = nil)
  if valid_21627951 != nil:
    section.add "X-Amz-Security-Token", valid_21627951
  var valid_21627952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627952 = validateParameter(valid_21627952, JString, required = false,
                                   default = nil)
  if valid_21627952 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627952
  var valid_21627953 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627953 = validateParameter(valid_21627953, JString, required = false,
                                   default = nil)
  if valid_21627953 != nil:
    section.add "X-Amz-Algorithm", valid_21627953
  var valid_21627954 = header.getOrDefault("X-Amz-Signature")
  valid_21627954 = validateParameter(valid_21627954, JString, required = false,
                                   default = nil)
  if valid_21627954 != nil:
    section.add "X-Amz-Signature", valid_21627954
  var valid_21627955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627955 = validateParameter(valid_21627955, JString, required = false,
                                   default = nil)
  if valid_21627955 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627955
  var valid_21627956 = header.getOrDefault("X-Amz-Credential")
  valid_21627956 = validateParameter(valid_21627956, JString, required = false,
                                   default = nil)
  if valid_21627956 != nil:
    section.add "X-Amz-Credential", valid_21627956
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627957: Call_GetRebootDBInstance_21627943; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627957.validator(path, query, header, formData, body, _)
  let scheme = call_21627957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627957.makeUrl(scheme.get, call_21627957.host, call_21627957.base,
                               call_21627957.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627957, uri, valid, _)

proc call*(call_21627958: Call_GetRebootDBInstance_21627943;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627959 = newJObject()
  add(query_21627959, "Action", newJString(Action))
  add(query_21627959, "ForceFailover", newJBool(ForceFailover))
  add(query_21627959, "Version", newJString(Version))
  add(query_21627959, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627958.call(nil, query_21627959, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_21627943(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_21627944, base: "/",
    makeUrl: url_GetRebootDBInstance_21627945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_21627995 = ref object of OpenApiRestCall_21625418
proc url_PostRemoveSourceIdentifierFromSubscription_21627997(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_21627996(path: JsonNode;
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
      "RemoveSourceIdentifierFromSubscription"))
  if valid_21627998 != nil:
    section.add "Action", valid_21627998
  var valid_21627999 = query.getOrDefault("Version")
  valid_21627999 = validateParameter(valid_21627999, JString, required = true,
                                   default = newJString("2014-09-01"))
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
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_21628007 = formData.getOrDefault("SourceIdentifier")
  valid_21628007 = validateParameter(valid_21628007, JString, required = true,
                                   default = nil)
  if valid_21628007 != nil:
    section.add "SourceIdentifier", valid_21628007
  var valid_21628008 = formData.getOrDefault("SubscriptionName")
  valid_21628008 = validateParameter(valid_21628008, JString, required = true,
                                   default = nil)
  if valid_21628008 != nil:
    section.add "SubscriptionName", valid_21628008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628009: Call_PostRemoveSourceIdentifierFromSubscription_21627995;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628009.validator(path, query, header, formData, body, _)
  let scheme = call_21628009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628009.makeUrl(scheme.get, call_21628009.host, call_21628009.base,
                               call_21628009.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628009, uri, valid, _)

proc call*(call_21628010: Call_PostRemoveSourceIdentifierFromSubscription_21627995;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21628011 = newJObject()
  var formData_21628012 = newJObject()
  add(formData_21628012, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_21628012, "SubscriptionName", newJString(SubscriptionName))
  add(query_21628011, "Action", newJString(Action))
  add(query_21628011, "Version", newJString(Version))
  result = call_21628010.call(nil, query_21628011, nil, formData_21628012, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_21627995(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_21627996,
    base: "/", makeUrl: url_PostRemoveSourceIdentifierFromSubscription_21627997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_21627978 = ref object of OpenApiRestCall_21625418
proc url_GetRemoveSourceIdentifierFromSubscription_21627980(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_21627979(path: JsonNode;
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
  var valid_21627981 = query.getOrDefault("Action")
  valid_21627981 = validateParameter(valid_21627981, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_21627981 != nil:
    section.add "Action", valid_21627981
  var valid_21627982 = query.getOrDefault("SourceIdentifier")
  valid_21627982 = validateParameter(valid_21627982, JString, required = true,
                                   default = nil)
  if valid_21627982 != nil:
    section.add "SourceIdentifier", valid_21627982
  var valid_21627983 = query.getOrDefault("SubscriptionName")
  valid_21627983 = validateParameter(valid_21627983, JString, required = true,
                                   default = nil)
  if valid_21627983 != nil:
    section.add "SubscriptionName", valid_21627983
  var valid_21627984 = query.getOrDefault("Version")
  valid_21627984 = validateParameter(valid_21627984, JString, required = true,
                                   default = newJString("2014-09-01"))
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

proc call*(call_21627992: Call_GetRemoveSourceIdentifierFromSubscription_21627978;
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

proc call*(call_21627993: Call_GetRemoveSourceIdentifierFromSubscription_21627978;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21627994 = newJObject()
  add(query_21627994, "Action", newJString(Action))
  add(query_21627994, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21627994, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627994, "Version", newJString(Version))
  result = call_21627993.call(nil, query_21627994, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_21627978(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_21627979,
    base: "/", makeUrl: url_GetRemoveSourceIdentifierFromSubscription_21627980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_21628030 = ref object of OpenApiRestCall_21625418
proc url_PostRemoveTagsFromResource_21628032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_21628031(path: JsonNode; query: JsonNode;
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
  var valid_21628033 = query.getOrDefault("Action")
  valid_21628033 = validateParameter(valid_21628033, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21628033 != nil:
    section.add "Action", valid_21628033
  var valid_21628034 = query.getOrDefault("Version")
  valid_21628034 = validateParameter(valid_21628034, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628034 != nil:
    section.add "Version", valid_21628034
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
  var valid_21628035 = header.getOrDefault("X-Amz-Date")
  valid_21628035 = validateParameter(valid_21628035, JString, required = false,
                                   default = nil)
  if valid_21628035 != nil:
    section.add "X-Amz-Date", valid_21628035
  var valid_21628036 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628036 = validateParameter(valid_21628036, JString, required = false,
                                   default = nil)
  if valid_21628036 != nil:
    section.add "X-Amz-Security-Token", valid_21628036
  var valid_21628037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628037 = validateParameter(valid_21628037, JString, required = false,
                                   default = nil)
  if valid_21628037 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628037
  var valid_21628038 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628038 = validateParameter(valid_21628038, JString, required = false,
                                   default = nil)
  if valid_21628038 != nil:
    section.add "X-Amz-Algorithm", valid_21628038
  var valid_21628039 = header.getOrDefault("X-Amz-Signature")
  valid_21628039 = validateParameter(valid_21628039, JString, required = false,
                                   default = nil)
  if valid_21628039 != nil:
    section.add "X-Amz-Signature", valid_21628039
  var valid_21628040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628040 = validateParameter(valid_21628040, JString, required = false,
                                   default = nil)
  if valid_21628040 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628040
  var valid_21628041 = header.getOrDefault("X-Amz-Credential")
  valid_21628041 = validateParameter(valid_21628041, JString, required = false,
                                   default = nil)
  if valid_21628041 != nil:
    section.add "X-Amz-Credential", valid_21628041
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_21628042 = formData.getOrDefault("TagKeys")
  valid_21628042 = validateParameter(valid_21628042, JArray, required = true,
                                   default = nil)
  if valid_21628042 != nil:
    section.add "TagKeys", valid_21628042
  var valid_21628043 = formData.getOrDefault("ResourceName")
  valid_21628043 = validateParameter(valid_21628043, JString, required = true,
                                   default = nil)
  if valid_21628043 != nil:
    section.add "ResourceName", valid_21628043
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628044: Call_PostRemoveTagsFromResource_21628030;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628044.validator(path, query, header, formData, body, _)
  let scheme = call_21628044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628044.makeUrl(scheme.get, call_21628044.host, call_21628044.base,
                               call_21628044.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628044, uri, valid, _)

proc call*(call_21628045: Call_PostRemoveTagsFromResource_21628030;
          TagKeys: JsonNode; ResourceName: string;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_21628046 = newJObject()
  var formData_21628047 = newJObject()
  add(query_21628046, "Action", newJString(Action))
  if TagKeys != nil:
    formData_21628047.add "TagKeys", TagKeys
  add(formData_21628047, "ResourceName", newJString(ResourceName))
  add(query_21628046, "Version", newJString(Version))
  result = call_21628045.call(nil, query_21628046, nil, formData_21628047, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_21628030(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_21628031, base: "/",
    makeUrl: url_PostRemoveTagsFromResource_21628032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_21628013 = ref object of OpenApiRestCall_21625418
proc url_GetRemoveTagsFromResource_21628015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_21628014(path: JsonNode; query: JsonNode;
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
  var valid_21628016 = query.getOrDefault("ResourceName")
  valid_21628016 = validateParameter(valid_21628016, JString, required = true,
                                   default = nil)
  if valid_21628016 != nil:
    section.add "ResourceName", valid_21628016
  var valid_21628017 = query.getOrDefault("Action")
  valid_21628017 = validateParameter(valid_21628017, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21628017 != nil:
    section.add "Action", valid_21628017
  var valid_21628018 = query.getOrDefault("TagKeys")
  valid_21628018 = validateParameter(valid_21628018, JArray, required = true,
                                   default = nil)
  if valid_21628018 != nil:
    section.add "TagKeys", valid_21628018
  var valid_21628019 = query.getOrDefault("Version")
  valid_21628019 = validateParameter(valid_21628019, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628019 != nil:
    section.add "Version", valid_21628019
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
  var valid_21628020 = header.getOrDefault("X-Amz-Date")
  valid_21628020 = validateParameter(valid_21628020, JString, required = false,
                                   default = nil)
  if valid_21628020 != nil:
    section.add "X-Amz-Date", valid_21628020
  var valid_21628021 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628021 = validateParameter(valid_21628021, JString, required = false,
                                   default = nil)
  if valid_21628021 != nil:
    section.add "X-Amz-Security-Token", valid_21628021
  var valid_21628022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628022 = validateParameter(valid_21628022, JString, required = false,
                                   default = nil)
  if valid_21628022 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628022
  var valid_21628023 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628023 = validateParameter(valid_21628023, JString, required = false,
                                   default = nil)
  if valid_21628023 != nil:
    section.add "X-Amz-Algorithm", valid_21628023
  var valid_21628024 = header.getOrDefault("X-Amz-Signature")
  valid_21628024 = validateParameter(valid_21628024, JString, required = false,
                                   default = nil)
  if valid_21628024 != nil:
    section.add "X-Amz-Signature", valid_21628024
  var valid_21628025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628025 = validateParameter(valid_21628025, JString, required = false,
                                   default = nil)
  if valid_21628025 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628025
  var valid_21628026 = header.getOrDefault("X-Amz-Credential")
  valid_21628026 = validateParameter(valid_21628026, JString, required = false,
                                   default = nil)
  if valid_21628026 != nil:
    section.add "X-Amz-Credential", valid_21628026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628027: Call_GetRemoveTagsFromResource_21628013;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628027.validator(path, query, header, formData, body, _)
  let scheme = call_21628027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628027.makeUrl(scheme.get, call_21628027.host, call_21628027.base,
                               call_21628027.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628027, uri, valid, _)

proc call*(call_21628028: Call_GetRemoveTagsFromResource_21628013;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_21628029 = newJObject()
  add(query_21628029, "ResourceName", newJString(ResourceName))
  add(query_21628029, "Action", newJString(Action))
  if TagKeys != nil:
    query_21628029.add "TagKeys", TagKeys
  add(query_21628029, "Version", newJString(Version))
  result = call_21628028.call(nil, query_21628029, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_21628013(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_21628014, base: "/",
    makeUrl: url_GetRemoveTagsFromResource_21628015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_21628066 = ref object of OpenApiRestCall_21625418
proc url_PostResetDBParameterGroup_21628068(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_21628067(path: JsonNode; query: JsonNode;
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
  var valid_21628069 = query.getOrDefault("Action")
  valid_21628069 = validateParameter(valid_21628069, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_21628069 != nil:
    section.add "Action", valid_21628069
  var valid_21628070 = query.getOrDefault("Version")
  valid_21628070 = validateParameter(valid_21628070, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628070 != nil:
    section.add "Version", valid_21628070
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
  var valid_21628071 = header.getOrDefault("X-Amz-Date")
  valid_21628071 = validateParameter(valid_21628071, JString, required = false,
                                   default = nil)
  if valid_21628071 != nil:
    section.add "X-Amz-Date", valid_21628071
  var valid_21628072 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628072 = validateParameter(valid_21628072, JString, required = false,
                                   default = nil)
  if valid_21628072 != nil:
    section.add "X-Amz-Security-Token", valid_21628072
  var valid_21628073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628073 = validateParameter(valid_21628073, JString, required = false,
                                   default = nil)
  if valid_21628073 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628073
  var valid_21628074 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628074 = validateParameter(valid_21628074, JString, required = false,
                                   default = nil)
  if valid_21628074 != nil:
    section.add "X-Amz-Algorithm", valid_21628074
  var valid_21628075 = header.getOrDefault("X-Amz-Signature")
  valid_21628075 = validateParameter(valid_21628075, JString, required = false,
                                   default = nil)
  if valid_21628075 != nil:
    section.add "X-Amz-Signature", valid_21628075
  var valid_21628076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628076 = validateParameter(valid_21628076, JString, required = false,
                                   default = nil)
  if valid_21628076 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628076
  var valid_21628077 = header.getOrDefault("X-Amz-Credential")
  valid_21628077 = validateParameter(valid_21628077, JString, required = false,
                                   default = nil)
  if valid_21628077 != nil:
    section.add "X-Amz-Credential", valid_21628077
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21628078 = formData.getOrDefault("DBParameterGroupName")
  valid_21628078 = validateParameter(valid_21628078, JString, required = true,
                                   default = nil)
  if valid_21628078 != nil:
    section.add "DBParameterGroupName", valid_21628078
  var valid_21628079 = formData.getOrDefault("Parameters")
  valid_21628079 = validateParameter(valid_21628079, JArray, required = false,
                                   default = nil)
  if valid_21628079 != nil:
    section.add "Parameters", valid_21628079
  var valid_21628080 = formData.getOrDefault("ResetAllParameters")
  valid_21628080 = validateParameter(valid_21628080, JBool, required = false,
                                   default = nil)
  if valid_21628080 != nil:
    section.add "ResetAllParameters", valid_21628080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628081: Call_PostResetDBParameterGroup_21628066;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628081.validator(path, query, header, formData, body, _)
  let scheme = call_21628081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628081.makeUrl(scheme.get, call_21628081.host, call_21628081.base,
                               call_21628081.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628081, uri, valid, _)

proc call*(call_21628082: Call_PostResetDBParameterGroup_21628066;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_21628083 = newJObject()
  var formData_21628084 = newJObject()
  add(formData_21628084, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_21628084.add "Parameters", Parameters
  add(query_21628083, "Action", newJString(Action))
  add(formData_21628084, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21628083, "Version", newJString(Version))
  result = call_21628082.call(nil, query_21628083, nil, formData_21628084, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_21628066(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_21628067, base: "/",
    makeUrl: url_PostResetDBParameterGroup_21628068,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_21628048 = ref object of OpenApiRestCall_21625418
proc url_GetResetDBParameterGroup_21628050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_21628049(path: JsonNode; query: JsonNode;
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
  var valid_21628051 = query.getOrDefault("DBParameterGroupName")
  valid_21628051 = validateParameter(valid_21628051, JString, required = true,
                                   default = nil)
  if valid_21628051 != nil:
    section.add "DBParameterGroupName", valid_21628051
  var valid_21628052 = query.getOrDefault("Parameters")
  valid_21628052 = validateParameter(valid_21628052, JArray, required = false,
                                   default = nil)
  if valid_21628052 != nil:
    section.add "Parameters", valid_21628052
  var valid_21628053 = query.getOrDefault("Action")
  valid_21628053 = validateParameter(valid_21628053, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_21628053 != nil:
    section.add "Action", valid_21628053
  var valid_21628054 = query.getOrDefault("ResetAllParameters")
  valid_21628054 = validateParameter(valid_21628054, JBool, required = false,
                                   default = nil)
  if valid_21628054 != nil:
    section.add "ResetAllParameters", valid_21628054
  var valid_21628055 = query.getOrDefault("Version")
  valid_21628055 = validateParameter(valid_21628055, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628055 != nil:
    section.add "Version", valid_21628055
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
  var valid_21628056 = header.getOrDefault("X-Amz-Date")
  valid_21628056 = validateParameter(valid_21628056, JString, required = false,
                                   default = nil)
  if valid_21628056 != nil:
    section.add "X-Amz-Date", valid_21628056
  var valid_21628057 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628057 = validateParameter(valid_21628057, JString, required = false,
                                   default = nil)
  if valid_21628057 != nil:
    section.add "X-Amz-Security-Token", valid_21628057
  var valid_21628058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628058 = validateParameter(valid_21628058, JString, required = false,
                                   default = nil)
  if valid_21628058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628058
  var valid_21628059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628059 = validateParameter(valid_21628059, JString, required = false,
                                   default = nil)
  if valid_21628059 != nil:
    section.add "X-Amz-Algorithm", valid_21628059
  var valid_21628060 = header.getOrDefault("X-Amz-Signature")
  valid_21628060 = validateParameter(valid_21628060, JString, required = false,
                                   default = nil)
  if valid_21628060 != nil:
    section.add "X-Amz-Signature", valid_21628060
  var valid_21628061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628061 = validateParameter(valid_21628061, JString, required = false,
                                   default = nil)
  if valid_21628061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628061
  var valid_21628062 = header.getOrDefault("X-Amz-Credential")
  valid_21628062 = validateParameter(valid_21628062, JString, required = false,
                                   default = nil)
  if valid_21628062 != nil:
    section.add "X-Amz-Credential", valid_21628062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628063: Call_GetResetDBParameterGroup_21628048;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628063.validator(path, query, header, formData, body, _)
  let scheme = call_21628063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628063.makeUrl(scheme.get, call_21628063.host, call_21628063.base,
                               call_21628063.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628063, uri, valid, _)

proc call*(call_21628064: Call_GetResetDBParameterGroup_21628048;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_21628065 = newJObject()
  add(query_21628065, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_21628065.add "Parameters", Parameters
  add(query_21628065, "Action", newJString(Action))
  add(query_21628065, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21628065, "Version", newJString(Version))
  result = call_21628064.call(nil, query_21628065, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_21628048(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_21628049, base: "/",
    makeUrl: url_GetResetDBParameterGroup_21628050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_21628118 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBInstanceFromDBSnapshot_21628120(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_21628119(path: JsonNode;
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
  var valid_21628121 = query.getOrDefault("Action")
  valid_21628121 = validateParameter(valid_21628121, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_21628121 != nil:
    section.add "Action", valid_21628121
  var valid_21628122 = query.getOrDefault("Version")
  valid_21628122 = validateParameter(valid_21628122, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628122 != nil:
    section.add "Version", valid_21628122
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
  var valid_21628123 = header.getOrDefault("X-Amz-Date")
  valid_21628123 = validateParameter(valid_21628123, JString, required = false,
                                   default = nil)
  if valid_21628123 != nil:
    section.add "X-Amz-Date", valid_21628123
  var valid_21628124 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628124 = validateParameter(valid_21628124, JString, required = false,
                                   default = nil)
  if valid_21628124 != nil:
    section.add "X-Amz-Security-Token", valid_21628124
  var valid_21628125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628125 = validateParameter(valid_21628125, JString, required = false,
                                   default = nil)
  if valid_21628125 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628125
  var valid_21628126 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628126 = validateParameter(valid_21628126, JString, required = false,
                                   default = nil)
  if valid_21628126 != nil:
    section.add "X-Amz-Algorithm", valid_21628126
  var valid_21628127 = header.getOrDefault("X-Amz-Signature")
  valid_21628127 = validateParameter(valid_21628127, JString, required = false,
                                   default = nil)
  if valid_21628127 != nil:
    section.add "X-Amz-Signature", valid_21628127
  var valid_21628128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628128 = validateParameter(valid_21628128, JString, required = false,
                                   default = nil)
  if valid_21628128 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628128
  var valid_21628129 = header.getOrDefault("X-Amz-Credential")
  valid_21628129 = validateParameter(valid_21628129, JString, required = false,
                                   default = nil)
  if valid_21628129 != nil:
    section.add "X-Amz-Credential", valid_21628129
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   TdeCredentialArn: JString
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialPassword: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   PubliclyAccessible: JBool
  ##   StorageType: JString
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21628130 = formData.getOrDefault("Port")
  valid_21628130 = validateParameter(valid_21628130, JInt, required = false,
                                   default = nil)
  if valid_21628130 != nil:
    section.add "Port", valid_21628130
  var valid_21628131 = formData.getOrDefault("Engine")
  valid_21628131 = validateParameter(valid_21628131, JString, required = false,
                                   default = nil)
  if valid_21628131 != nil:
    section.add "Engine", valid_21628131
  var valid_21628132 = formData.getOrDefault("Iops")
  valid_21628132 = validateParameter(valid_21628132, JInt, required = false,
                                   default = nil)
  if valid_21628132 != nil:
    section.add "Iops", valid_21628132
  var valid_21628133 = formData.getOrDefault("DBName")
  valid_21628133 = validateParameter(valid_21628133, JString, required = false,
                                   default = nil)
  if valid_21628133 != nil:
    section.add "DBName", valid_21628133
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21628134 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21628134 = validateParameter(valid_21628134, JString, required = true,
                                   default = nil)
  if valid_21628134 != nil:
    section.add "DBInstanceIdentifier", valid_21628134
  var valid_21628135 = formData.getOrDefault("OptionGroupName")
  valid_21628135 = validateParameter(valid_21628135, JString, required = false,
                                   default = nil)
  if valid_21628135 != nil:
    section.add "OptionGroupName", valid_21628135
  var valid_21628136 = formData.getOrDefault("Tags")
  valid_21628136 = validateParameter(valid_21628136, JArray, required = false,
                                   default = nil)
  if valid_21628136 != nil:
    section.add "Tags", valid_21628136
  var valid_21628137 = formData.getOrDefault("TdeCredentialArn")
  valid_21628137 = validateParameter(valid_21628137, JString, required = false,
                                   default = nil)
  if valid_21628137 != nil:
    section.add "TdeCredentialArn", valid_21628137
  var valid_21628138 = formData.getOrDefault("DBSubnetGroupName")
  valid_21628138 = validateParameter(valid_21628138, JString, required = false,
                                   default = nil)
  if valid_21628138 != nil:
    section.add "DBSubnetGroupName", valid_21628138
  var valid_21628139 = formData.getOrDefault("TdeCredentialPassword")
  valid_21628139 = validateParameter(valid_21628139, JString, required = false,
                                   default = nil)
  if valid_21628139 != nil:
    section.add "TdeCredentialPassword", valid_21628139
  var valid_21628140 = formData.getOrDefault("AvailabilityZone")
  valid_21628140 = validateParameter(valid_21628140, JString, required = false,
                                   default = nil)
  if valid_21628140 != nil:
    section.add "AvailabilityZone", valid_21628140
  var valid_21628141 = formData.getOrDefault("MultiAZ")
  valid_21628141 = validateParameter(valid_21628141, JBool, required = false,
                                   default = nil)
  if valid_21628141 != nil:
    section.add "MultiAZ", valid_21628141
  var valid_21628142 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21628142 = validateParameter(valid_21628142, JString, required = true,
                                   default = nil)
  if valid_21628142 != nil:
    section.add "DBSnapshotIdentifier", valid_21628142
  var valid_21628143 = formData.getOrDefault("PubliclyAccessible")
  valid_21628143 = validateParameter(valid_21628143, JBool, required = false,
                                   default = nil)
  if valid_21628143 != nil:
    section.add "PubliclyAccessible", valid_21628143
  var valid_21628144 = formData.getOrDefault("StorageType")
  valid_21628144 = validateParameter(valid_21628144, JString, required = false,
                                   default = nil)
  if valid_21628144 != nil:
    section.add "StorageType", valid_21628144
  var valid_21628145 = formData.getOrDefault("DBInstanceClass")
  valid_21628145 = validateParameter(valid_21628145, JString, required = false,
                                   default = nil)
  if valid_21628145 != nil:
    section.add "DBInstanceClass", valid_21628145
  var valid_21628146 = formData.getOrDefault("LicenseModel")
  valid_21628146 = validateParameter(valid_21628146, JString, required = false,
                                   default = nil)
  if valid_21628146 != nil:
    section.add "LicenseModel", valid_21628146
  var valid_21628147 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628147 = validateParameter(valid_21628147, JBool, required = false,
                                   default = nil)
  if valid_21628147 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628147
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628148: Call_PostRestoreDBInstanceFromDBSnapshot_21628118;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628148.validator(path, query, header, formData, body, _)
  let scheme = call_21628148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628148.makeUrl(scheme.get, call_21628148.host, call_21628148.base,
                               call_21628148.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628148, uri, valid, _)

proc call*(call_21628149: Call_PostRestoreDBInstanceFromDBSnapshot_21628118;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          TdeCredentialArn: string = ""; DBSubnetGroupName: string = "";
          TdeCredentialPassword: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; StorageType: string = "";
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   TdeCredentialArn: string
  ##   DBSubnetGroupName: string
  ##   TdeCredentialPassword: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   StorageType: string
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_21628150 = newJObject()
  var formData_21628151 = newJObject()
  add(formData_21628151, "Port", newJInt(Port))
  add(formData_21628151, "Engine", newJString(Engine))
  add(formData_21628151, "Iops", newJInt(Iops))
  add(formData_21628151, "DBName", newJString(DBName))
  add(formData_21628151, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21628151, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21628151.add "Tags", Tags
  add(formData_21628151, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_21628151, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21628151, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_21628151, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21628151, "MultiAZ", newJBool(MultiAZ))
  add(formData_21628151, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21628150, "Action", newJString(Action))
  add(formData_21628151, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21628151, "StorageType", newJString(StorageType))
  add(formData_21628151, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21628151, "LicenseModel", newJString(LicenseModel))
  add(formData_21628151, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21628150, "Version", newJString(Version))
  result = call_21628149.call(nil, query_21628150, nil, formData_21628151, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_21628118(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_21628119, base: "/",
    makeUrl: url_PostRestoreDBInstanceFromDBSnapshot_21628120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_21628085 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBInstanceFromDBSnapshot_21628087(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_21628086(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   StorageType: JString
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_21628088 = query.getOrDefault("Engine")
  valid_21628088 = validateParameter(valid_21628088, JString, required = false,
                                   default = nil)
  if valid_21628088 != nil:
    section.add "Engine", valid_21628088
  var valid_21628089 = query.getOrDefault("StorageType")
  valid_21628089 = validateParameter(valid_21628089, JString, required = false,
                                   default = nil)
  if valid_21628089 != nil:
    section.add "StorageType", valid_21628089
  var valid_21628090 = query.getOrDefault("OptionGroupName")
  valid_21628090 = validateParameter(valid_21628090, JString, required = false,
                                   default = nil)
  if valid_21628090 != nil:
    section.add "OptionGroupName", valid_21628090
  var valid_21628091 = query.getOrDefault("AvailabilityZone")
  valid_21628091 = validateParameter(valid_21628091, JString, required = false,
                                   default = nil)
  if valid_21628091 != nil:
    section.add "AvailabilityZone", valid_21628091
  var valid_21628092 = query.getOrDefault("Iops")
  valid_21628092 = validateParameter(valid_21628092, JInt, required = false,
                                   default = nil)
  if valid_21628092 != nil:
    section.add "Iops", valid_21628092
  var valid_21628093 = query.getOrDefault("MultiAZ")
  valid_21628093 = validateParameter(valid_21628093, JBool, required = false,
                                   default = nil)
  if valid_21628093 != nil:
    section.add "MultiAZ", valid_21628093
  var valid_21628094 = query.getOrDefault("TdeCredentialPassword")
  valid_21628094 = validateParameter(valid_21628094, JString, required = false,
                                   default = nil)
  if valid_21628094 != nil:
    section.add "TdeCredentialPassword", valid_21628094
  var valid_21628095 = query.getOrDefault("LicenseModel")
  valid_21628095 = validateParameter(valid_21628095, JString, required = false,
                                   default = nil)
  if valid_21628095 != nil:
    section.add "LicenseModel", valid_21628095
  var valid_21628096 = query.getOrDefault("Tags")
  valid_21628096 = validateParameter(valid_21628096, JArray, required = false,
                                   default = nil)
  if valid_21628096 != nil:
    section.add "Tags", valid_21628096
  var valid_21628097 = query.getOrDefault("DBName")
  valid_21628097 = validateParameter(valid_21628097, JString, required = false,
                                   default = nil)
  if valid_21628097 != nil:
    section.add "DBName", valid_21628097
  var valid_21628098 = query.getOrDefault("DBInstanceClass")
  valid_21628098 = validateParameter(valid_21628098, JString, required = false,
                                   default = nil)
  if valid_21628098 != nil:
    section.add "DBInstanceClass", valid_21628098
  var valid_21628099 = query.getOrDefault("Action")
  valid_21628099 = validateParameter(valid_21628099, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_21628099 != nil:
    section.add "Action", valid_21628099
  var valid_21628100 = query.getOrDefault("DBSubnetGroupName")
  valid_21628100 = validateParameter(valid_21628100, JString, required = false,
                                   default = nil)
  if valid_21628100 != nil:
    section.add "DBSubnetGroupName", valid_21628100
  var valid_21628101 = query.getOrDefault("TdeCredentialArn")
  valid_21628101 = validateParameter(valid_21628101, JString, required = false,
                                   default = nil)
  if valid_21628101 != nil:
    section.add "TdeCredentialArn", valid_21628101
  var valid_21628102 = query.getOrDefault("PubliclyAccessible")
  valid_21628102 = validateParameter(valid_21628102, JBool, required = false,
                                   default = nil)
  if valid_21628102 != nil:
    section.add "PubliclyAccessible", valid_21628102
  var valid_21628103 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628103 = validateParameter(valid_21628103, JBool, required = false,
                                   default = nil)
  if valid_21628103 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628103
  var valid_21628104 = query.getOrDefault("Port")
  valid_21628104 = validateParameter(valid_21628104, JInt, required = false,
                                   default = nil)
  if valid_21628104 != nil:
    section.add "Port", valid_21628104
  var valid_21628105 = query.getOrDefault("Version")
  valid_21628105 = validateParameter(valid_21628105, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628105 != nil:
    section.add "Version", valid_21628105
  var valid_21628106 = query.getOrDefault("DBInstanceIdentifier")
  valid_21628106 = validateParameter(valid_21628106, JString, required = true,
                                   default = nil)
  if valid_21628106 != nil:
    section.add "DBInstanceIdentifier", valid_21628106
  var valid_21628107 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21628107 = validateParameter(valid_21628107, JString, required = true,
                                   default = nil)
  if valid_21628107 != nil:
    section.add "DBSnapshotIdentifier", valid_21628107
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
  var valid_21628108 = header.getOrDefault("X-Amz-Date")
  valid_21628108 = validateParameter(valid_21628108, JString, required = false,
                                   default = nil)
  if valid_21628108 != nil:
    section.add "X-Amz-Date", valid_21628108
  var valid_21628109 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628109 = validateParameter(valid_21628109, JString, required = false,
                                   default = nil)
  if valid_21628109 != nil:
    section.add "X-Amz-Security-Token", valid_21628109
  var valid_21628110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628110 = validateParameter(valid_21628110, JString, required = false,
                                   default = nil)
  if valid_21628110 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628110
  var valid_21628111 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628111 = validateParameter(valid_21628111, JString, required = false,
                                   default = nil)
  if valid_21628111 != nil:
    section.add "X-Amz-Algorithm", valid_21628111
  var valid_21628112 = header.getOrDefault("X-Amz-Signature")
  valid_21628112 = validateParameter(valid_21628112, JString, required = false,
                                   default = nil)
  if valid_21628112 != nil:
    section.add "X-Amz-Signature", valid_21628112
  var valid_21628113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628113 = validateParameter(valid_21628113, JString, required = false,
                                   default = nil)
  if valid_21628113 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628113
  var valid_21628114 = header.getOrDefault("X-Amz-Credential")
  valid_21628114 = validateParameter(valid_21628114, JString, required = false,
                                   default = nil)
  if valid_21628114 != nil:
    section.add "X-Amz-Credential", valid_21628114
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628115: Call_GetRestoreDBInstanceFromDBSnapshot_21628085;
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

proc call*(call_21628116: Call_GetRestoreDBInstanceFromDBSnapshot_21628085;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; StorageType: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          TdeCredentialPassword: string = ""; LicenseModel: string = "";
          Tags: JsonNode = nil; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; TdeCredentialArn: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2014-09-01"): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   Engine: string
  ##   StorageType: string
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21628117 = newJObject()
  add(query_21628117, "Engine", newJString(Engine))
  add(query_21628117, "StorageType", newJString(StorageType))
  add(query_21628117, "OptionGroupName", newJString(OptionGroupName))
  add(query_21628117, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21628117, "Iops", newJInt(Iops))
  add(query_21628117, "MultiAZ", newJBool(MultiAZ))
  add(query_21628117, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_21628117, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_21628117.add "Tags", Tags
  add(query_21628117, "DBName", newJString(DBName))
  add(query_21628117, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21628117, "Action", newJString(Action))
  add(query_21628117, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21628117, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_21628117, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21628117, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21628117, "Port", newJInt(Port))
  add(query_21628117, "Version", newJString(Version))
  add(query_21628117, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21628117, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21628116.call(nil, query_21628117, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_21628085(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_21628086, base: "/",
    makeUrl: url_GetRestoreDBInstanceFromDBSnapshot_21628087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_21628187 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBInstanceToPointInTime_21628189(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_21628188(path: JsonNode;
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
  var valid_21628190 = query.getOrDefault("Action")
  valid_21628190 = validateParameter(valid_21628190, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_21628190 != nil:
    section.add "Action", valid_21628190
  var valid_21628191 = query.getOrDefault("Version")
  valid_21628191 = validateParameter(valid_21628191, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628191 != nil:
    section.add "Version", valid_21628191
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
  var valid_21628192 = header.getOrDefault("X-Amz-Date")
  valid_21628192 = validateParameter(valid_21628192, JString, required = false,
                                   default = nil)
  if valid_21628192 != nil:
    section.add "X-Amz-Date", valid_21628192
  var valid_21628193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628193 = validateParameter(valid_21628193, JString, required = false,
                                   default = nil)
  if valid_21628193 != nil:
    section.add "X-Amz-Security-Token", valid_21628193
  var valid_21628194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628194 = validateParameter(valid_21628194, JString, required = false,
                                   default = nil)
  if valid_21628194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628194
  var valid_21628195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628195 = validateParameter(valid_21628195, JString, required = false,
                                   default = nil)
  if valid_21628195 != nil:
    section.add "X-Amz-Algorithm", valid_21628195
  var valid_21628196 = header.getOrDefault("X-Amz-Signature")
  valid_21628196 = validateParameter(valid_21628196, JString, required = false,
                                   default = nil)
  if valid_21628196 != nil:
    section.add "X-Amz-Signature", valid_21628196
  var valid_21628197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628197 = validateParameter(valid_21628197, JString, required = false,
                                   default = nil)
  if valid_21628197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628197
  var valid_21628198 = header.getOrDefault("X-Amz-Credential")
  valid_21628198 = validateParameter(valid_21628198, JString, required = false,
                                   default = nil)
  if valid_21628198 != nil:
    section.add "X-Amz-Credential", valid_21628198
  result.add "header", section
  ## parameters in `formData` object:
  ##   UseLatestRestorableTime: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   TdeCredentialArn: JString
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialPassword: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   RestoreTime: JString
  ##   PubliclyAccessible: JBool
  ##   StorageType: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21628199 = formData.getOrDefault("UseLatestRestorableTime")
  valid_21628199 = validateParameter(valid_21628199, JBool, required = false,
                                   default = nil)
  if valid_21628199 != nil:
    section.add "UseLatestRestorableTime", valid_21628199
  var valid_21628200 = formData.getOrDefault("Port")
  valid_21628200 = validateParameter(valid_21628200, JInt, required = false,
                                   default = nil)
  if valid_21628200 != nil:
    section.add "Port", valid_21628200
  var valid_21628201 = formData.getOrDefault("Engine")
  valid_21628201 = validateParameter(valid_21628201, JString, required = false,
                                   default = nil)
  if valid_21628201 != nil:
    section.add "Engine", valid_21628201
  var valid_21628202 = formData.getOrDefault("Iops")
  valid_21628202 = validateParameter(valid_21628202, JInt, required = false,
                                   default = nil)
  if valid_21628202 != nil:
    section.add "Iops", valid_21628202
  var valid_21628203 = formData.getOrDefault("DBName")
  valid_21628203 = validateParameter(valid_21628203, JString, required = false,
                                   default = nil)
  if valid_21628203 != nil:
    section.add "DBName", valid_21628203
  var valid_21628204 = formData.getOrDefault("OptionGroupName")
  valid_21628204 = validateParameter(valid_21628204, JString, required = false,
                                   default = nil)
  if valid_21628204 != nil:
    section.add "OptionGroupName", valid_21628204
  var valid_21628205 = formData.getOrDefault("Tags")
  valid_21628205 = validateParameter(valid_21628205, JArray, required = false,
                                   default = nil)
  if valid_21628205 != nil:
    section.add "Tags", valid_21628205
  var valid_21628206 = formData.getOrDefault("TdeCredentialArn")
  valid_21628206 = validateParameter(valid_21628206, JString, required = false,
                                   default = nil)
  if valid_21628206 != nil:
    section.add "TdeCredentialArn", valid_21628206
  var valid_21628207 = formData.getOrDefault("DBSubnetGroupName")
  valid_21628207 = validateParameter(valid_21628207, JString, required = false,
                                   default = nil)
  if valid_21628207 != nil:
    section.add "DBSubnetGroupName", valid_21628207
  var valid_21628208 = formData.getOrDefault("TdeCredentialPassword")
  valid_21628208 = validateParameter(valid_21628208, JString, required = false,
                                   default = nil)
  if valid_21628208 != nil:
    section.add "TdeCredentialPassword", valid_21628208
  var valid_21628209 = formData.getOrDefault("AvailabilityZone")
  valid_21628209 = validateParameter(valid_21628209, JString, required = false,
                                   default = nil)
  if valid_21628209 != nil:
    section.add "AvailabilityZone", valid_21628209
  var valid_21628210 = formData.getOrDefault("MultiAZ")
  valid_21628210 = validateParameter(valid_21628210, JBool, required = false,
                                   default = nil)
  if valid_21628210 != nil:
    section.add "MultiAZ", valid_21628210
  var valid_21628211 = formData.getOrDefault("RestoreTime")
  valid_21628211 = validateParameter(valid_21628211, JString, required = false,
                                   default = nil)
  if valid_21628211 != nil:
    section.add "RestoreTime", valid_21628211
  var valid_21628212 = formData.getOrDefault("PubliclyAccessible")
  valid_21628212 = validateParameter(valid_21628212, JBool, required = false,
                                   default = nil)
  if valid_21628212 != nil:
    section.add "PubliclyAccessible", valid_21628212
  var valid_21628213 = formData.getOrDefault("StorageType")
  valid_21628213 = validateParameter(valid_21628213, JString, required = false,
                                   default = nil)
  if valid_21628213 != nil:
    section.add "StorageType", valid_21628213
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_21628214 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_21628214 = validateParameter(valid_21628214, JString, required = true,
                                   default = nil)
  if valid_21628214 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21628214
  var valid_21628215 = formData.getOrDefault("DBInstanceClass")
  valid_21628215 = validateParameter(valid_21628215, JString, required = false,
                                   default = nil)
  if valid_21628215 != nil:
    section.add "DBInstanceClass", valid_21628215
  var valid_21628216 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_21628216 = validateParameter(valid_21628216, JString, required = true,
                                   default = nil)
  if valid_21628216 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21628216
  var valid_21628217 = formData.getOrDefault("LicenseModel")
  valid_21628217 = validateParameter(valid_21628217, JString, required = false,
                                   default = nil)
  if valid_21628217 != nil:
    section.add "LicenseModel", valid_21628217
  var valid_21628218 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628218 = validateParameter(valid_21628218, JBool, required = false,
                                   default = nil)
  if valid_21628218 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628218
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628219: Call_PostRestoreDBInstanceToPointInTime_21628187;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628219.validator(path, query, header, formData, body, _)
  let scheme = call_21628219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628219.makeUrl(scheme.get, call_21628219.host, call_21628219.base,
                               call_21628219.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628219, uri, valid, _)

proc call*(call_21628220: Call_PostRestoreDBInstanceToPointInTime_21628187;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          Tags: JsonNode = nil; TdeCredentialArn: string = "";
          DBSubnetGroupName: string = ""; TdeCredentialPassword: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          StorageType: string = ""; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   UseLatestRestorableTime: bool
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   TdeCredentialArn: string
  ##   DBSubnetGroupName: string
  ##   TdeCredentialPassword: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   RestoreTime: string
  ##   PubliclyAccessible: bool
  ##   StorageType: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_21628221 = newJObject()
  var formData_21628222 = newJObject()
  add(formData_21628222, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_21628222, "Port", newJInt(Port))
  add(formData_21628222, "Engine", newJString(Engine))
  add(formData_21628222, "Iops", newJInt(Iops))
  add(formData_21628222, "DBName", newJString(DBName))
  add(formData_21628222, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21628222.add "Tags", Tags
  add(formData_21628222, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_21628222, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21628222, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_21628222, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21628222, "MultiAZ", newJBool(MultiAZ))
  add(query_21628221, "Action", newJString(Action))
  add(formData_21628222, "RestoreTime", newJString(RestoreTime))
  add(formData_21628222, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21628222, "StorageType", newJString(StorageType))
  add(formData_21628222, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_21628222, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21628222, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_21628222, "LicenseModel", newJString(LicenseModel))
  add(formData_21628222, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21628221, "Version", newJString(Version))
  result = call_21628220.call(nil, query_21628221, nil, formData_21628222, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_21628187(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_21628188, base: "/",
    makeUrl: url_PostRestoreDBInstanceToPointInTime_21628189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_21628152 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBInstanceToPointInTime_21628154(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_21628153(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   StorageType: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   MultiAZ: JBool
  ##   TdeCredentialPassword: JString
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   UseLatestRestorableTime: JBool
  ##   DBSubnetGroupName: JString
  ##   TdeCredentialArn: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  section = newJObject()
  var valid_21628155 = query.getOrDefault("Engine")
  valid_21628155 = validateParameter(valid_21628155, JString, required = false,
                                   default = nil)
  if valid_21628155 != nil:
    section.add "Engine", valid_21628155
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_21628156 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_21628156 = validateParameter(valid_21628156, JString, required = true,
                                   default = nil)
  if valid_21628156 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21628156
  var valid_21628157 = query.getOrDefault("StorageType")
  valid_21628157 = validateParameter(valid_21628157, JString, required = false,
                                   default = nil)
  if valid_21628157 != nil:
    section.add "StorageType", valid_21628157
  var valid_21628158 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_21628158 = validateParameter(valid_21628158, JString, required = true,
                                   default = nil)
  if valid_21628158 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21628158
  var valid_21628159 = query.getOrDefault("AvailabilityZone")
  valid_21628159 = validateParameter(valid_21628159, JString, required = false,
                                   default = nil)
  if valid_21628159 != nil:
    section.add "AvailabilityZone", valid_21628159
  var valid_21628160 = query.getOrDefault("Iops")
  valid_21628160 = validateParameter(valid_21628160, JInt, required = false,
                                   default = nil)
  if valid_21628160 != nil:
    section.add "Iops", valid_21628160
  var valid_21628161 = query.getOrDefault("OptionGroupName")
  valid_21628161 = validateParameter(valid_21628161, JString, required = false,
                                   default = nil)
  if valid_21628161 != nil:
    section.add "OptionGroupName", valid_21628161
  var valid_21628162 = query.getOrDefault("RestoreTime")
  valid_21628162 = validateParameter(valid_21628162, JString, required = false,
                                   default = nil)
  if valid_21628162 != nil:
    section.add "RestoreTime", valid_21628162
  var valid_21628163 = query.getOrDefault("MultiAZ")
  valid_21628163 = validateParameter(valid_21628163, JBool, required = false,
                                   default = nil)
  if valid_21628163 != nil:
    section.add "MultiAZ", valid_21628163
  var valid_21628164 = query.getOrDefault("TdeCredentialPassword")
  valid_21628164 = validateParameter(valid_21628164, JString, required = false,
                                   default = nil)
  if valid_21628164 != nil:
    section.add "TdeCredentialPassword", valid_21628164
  var valid_21628165 = query.getOrDefault("LicenseModel")
  valid_21628165 = validateParameter(valid_21628165, JString, required = false,
                                   default = nil)
  if valid_21628165 != nil:
    section.add "LicenseModel", valid_21628165
  var valid_21628166 = query.getOrDefault("Tags")
  valid_21628166 = validateParameter(valid_21628166, JArray, required = false,
                                   default = nil)
  if valid_21628166 != nil:
    section.add "Tags", valid_21628166
  var valid_21628167 = query.getOrDefault("DBName")
  valid_21628167 = validateParameter(valid_21628167, JString, required = false,
                                   default = nil)
  if valid_21628167 != nil:
    section.add "DBName", valid_21628167
  var valid_21628168 = query.getOrDefault("DBInstanceClass")
  valid_21628168 = validateParameter(valid_21628168, JString, required = false,
                                   default = nil)
  if valid_21628168 != nil:
    section.add "DBInstanceClass", valid_21628168
  var valid_21628169 = query.getOrDefault("Action")
  valid_21628169 = validateParameter(valid_21628169, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_21628169 != nil:
    section.add "Action", valid_21628169
  var valid_21628170 = query.getOrDefault("UseLatestRestorableTime")
  valid_21628170 = validateParameter(valid_21628170, JBool, required = false,
                                   default = nil)
  if valid_21628170 != nil:
    section.add "UseLatestRestorableTime", valid_21628170
  var valid_21628171 = query.getOrDefault("DBSubnetGroupName")
  valid_21628171 = validateParameter(valid_21628171, JString, required = false,
                                   default = nil)
  if valid_21628171 != nil:
    section.add "DBSubnetGroupName", valid_21628171
  var valid_21628172 = query.getOrDefault("TdeCredentialArn")
  valid_21628172 = validateParameter(valid_21628172, JString, required = false,
                                   default = nil)
  if valid_21628172 != nil:
    section.add "TdeCredentialArn", valid_21628172
  var valid_21628173 = query.getOrDefault("PubliclyAccessible")
  valid_21628173 = validateParameter(valid_21628173, JBool, required = false,
                                   default = nil)
  if valid_21628173 != nil:
    section.add "PubliclyAccessible", valid_21628173
  var valid_21628174 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628174 = validateParameter(valid_21628174, JBool, required = false,
                                   default = nil)
  if valid_21628174 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628174
  var valid_21628175 = query.getOrDefault("Port")
  valid_21628175 = validateParameter(valid_21628175, JInt, required = false,
                                   default = nil)
  if valid_21628175 != nil:
    section.add "Port", valid_21628175
  var valid_21628176 = query.getOrDefault("Version")
  valid_21628176 = validateParameter(valid_21628176, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628176 != nil:
    section.add "Version", valid_21628176
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
  var valid_21628177 = header.getOrDefault("X-Amz-Date")
  valid_21628177 = validateParameter(valid_21628177, JString, required = false,
                                   default = nil)
  if valid_21628177 != nil:
    section.add "X-Amz-Date", valid_21628177
  var valid_21628178 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628178 = validateParameter(valid_21628178, JString, required = false,
                                   default = nil)
  if valid_21628178 != nil:
    section.add "X-Amz-Security-Token", valid_21628178
  var valid_21628179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628179 = validateParameter(valid_21628179, JString, required = false,
                                   default = nil)
  if valid_21628179 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628179
  var valid_21628180 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628180 = validateParameter(valid_21628180, JString, required = false,
                                   default = nil)
  if valid_21628180 != nil:
    section.add "X-Amz-Algorithm", valid_21628180
  var valid_21628181 = header.getOrDefault("X-Amz-Signature")
  valid_21628181 = validateParameter(valid_21628181, JString, required = false,
                                   default = nil)
  if valid_21628181 != nil:
    section.add "X-Amz-Signature", valid_21628181
  var valid_21628182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628182 = validateParameter(valid_21628182, JString, required = false,
                                   default = nil)
  if valid_21628182 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628182
  var valid_21628183 = header.getOrDefault("X-Amz-Credential")
  valid_21628183 = validateParameter(valid_21628183, JString, required = false,
                                   default = nil)
  if valid_21628183 != nil:
    section.add "X-Amz-Credential", valid_21628183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628184: Call_GetRestoreDBInstanceToPointInTime_21628152;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628184.validator(path, query, header, formData, body, _)
  let scheme = call_21628184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628184.makeUrl(scheme.get, call_21628184.host, call_21628184.base,
                               call_21628184.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628184, uri, valid, _)

proc call*(call_21628185: Call_GetRestoreDBInstanceToPointInTime_21628152;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; StorageType: string = ""; AvailabilityZone: string = "";
          Iops: int = 0; OptionGroupName: string = ""; RestoreTime: string = "";
          MultiAZ: bool = false; TdeCredentialPassword: string = "";
          LicenseModel: string = ""; Tags: JsonNode = nil; DBName: string = "";
          DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          TdeCredentialArn: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2014-09-01"): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   Engine: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   StorageType: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   MultiAZ: bool
  ##   TdeCredentialPassword: string
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   UseLatestRestorableTime: bool
  ##   DBSubnetGroupName: string
  ##   TdeCredentialArn: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  var query_21628186 = newJObject()
  add(query_21628186, "Engine", newJString(Engine))
  add(query_21628186, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_21628186, "StorageType", newJString(StorageType))
  add(query_21628186, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_21628186, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21628186, "Iops", newJInt(Iops))
  add(query_21628186, "OptionGroupName", newJString(OptionGroupName))
  add(query_21628186, "RestoreTime", newJString(RestoreTime))
  add(query_21628186, "MultiAZ", newJBool(MultiAZ))
  add(query_21628186, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_21628186, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_21628186.add "Tags", Tags
  add(query_21628186, "DBName", newJString(DBName))
  add(query_21628186, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21628186, "Action", newJString(Action))
  add(query_21628186, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_21628186, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21628186, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_21628186, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21628186, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21628186, "Port", newJInt(Port))
  add(query_21628186, "Version", newJString(Version))
  result = call_21628185.call(nil, query_21628186, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_21628152(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_21628153, base: "/",
    makeUrl: url_GetRestoreDBInstanceToPointInTime_21628154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_21628243 = ref object of OpenApiRestCall_21625418
proc url_PostRevokeDBSecurityGroupIngress_21628245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_21628244(path: JsonNode;
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
  var valid_21628246 = query.getOrDefault("Action")
  valid_21628246 = validateParameter(valid_21628246, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_21628246 != nil:
    section.add "Action", valid_21628246
  var valid_21628247 = query.getOrDefault("Version")
  valid_21628247 = validateParameter(valid_21628247, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628247 != nil:
    section.add "Version", valid_21628247
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
  var valid_21628248 = header.getOrDefault("X-Amz-Date")
  valid_21628248 = validateParameter(valid_21628248, JString, required = false,
                                   default = nil)
  if valid_21628248 != nil:
    section.add "X-Amz-Date", valid_21628248
  var valid_21628249 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628249 = validateParameter(valid_21628249, JString, required = false,
                                   default = nil)
  if valid_21628249 != nil:
    section.add "X-Amz-Security-Token", valid_21628249
  var valid_21628250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628250 = validateParameter(valid_21628250, JString, required = false,
                                   default = nil)
  if valid_21628250 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628250
  var valid_21628251 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628251 = validateParameter(valid_21628251, JString, required = false,
                                   default = nil)
  if valid_21628251 != nil:
    section.add "X-Amz-Algorithm", valid_21628251
  var valid_21628252 = header.getOrDefault("X-Amz-Signature")
  valid_21628252 = validateParameter(valid_21628252, JString, required = false,
                                   default = nil)
  if valid_21628252 != nil:
    section.add "X-Amz-Signature", valid_21628252
  var valid_21628253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628253 = validateParameter(valid_21628253, JString, required = false,
                                   default = nil)
  if valid_21628253 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628253
  var valid_21628254 = header.getOrDefault("X-Amz-Credential")
  valid_21628254 = validateParameter(valid_21628254, JString, required = false,
                                   default = nil)
  if valid_21628254 != nil:
    section.add "X-Amz-Credential", valid_21628254
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21628255 = formData.getOrDefault("DBSecurityGroupName")
  valid_21628255 = validateParameter(valid_21628255, JString, required = true,
                                   default = nil)
  if valid_21628255 != nil:
    section.add "DBSecurityGroupName", valid_21628255
  var valid_21628256 = formData.getOrDefault("EC2SecurityGroupName")
  valid_21628256 = validateParameter(valid_21628256, JString, required = false,
                                   default = nil)
  if valid_21628256 != nil:
    section.add "EC2SecurityGroupName", valid_21628256
  var valid_21628257 = formData.getOrDefault("EC2SecurityGroupId")
  valid_21628257 = validateParameter(valid_21628257, JString, required = false,
                                   default = nil)
  if valid_21628257 != nil:
    section.add "EC2SecurityGroupId", valid_21628257
  var valid_21628258 = formData.getOrDefault("CIDRIP")
  valid_21628258 = validateParameter(valid_21628258, JString, required = false,
                                   default = nil)
  if valid_21628258 != nil:
    section.add "CIDRIP", valid_21628258
  var valid_21628259 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21628259 = validateParameter(valid_21628259, JString, required = false,
                                   default = nil)
  if valid_21628259 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21628259
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628260: Call_PostRevokeDBSecurityGroupIngress_21628243;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628260.validator(path, query, header, formData, body, _)
  let scheme = call_21628260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628260.makeUrl(scheme.get, call_21628260.host, call_21628260.base,
                               call_21628260.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628260, uri, valid, _)

proc call*(call_21628261: Call_PostRevokeDBSecurityGroupIngress_21628243;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2014-09-01";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_21628262 = newJObject()
  var formData_21628263 = newJObject()
  add(formData_21628263, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21628262, "Action", newJString(Action))
  add(formData_21628263, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_21628263, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_21628263, "CIDRIP", newJString(CIDRIP))
  add(query_21628262, "Version", newJString(Version))
  add(formData_21628263, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_21628261.call(nil, query_21628262, nil, formData_21628263, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_21628243(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_21628244, base: "/",
    makeUrl: url_PostRevokeDBSecurityGroupIngress_21628245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_21628223 = ref object of OpenApiRestCall_21625418
proc url_GetRevokeDBSecurityGroupIngress_21628225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_21628224(path: JsonNode;
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
  var valid_21628226 = query.getOrDefault("EC2SecurityGroupId")
  valid_21628226 = validateParameter(valid_21628226, JString, required = false,
                                   default = nil)
  if valid_21628226 != nil:
    section.add "EC2SecurityGroupId", valid_21628226
  var valid_21628227 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21628227 = validateParameter(valid_21628227, JString, required = false,
                                   default = nil)
  if valid_21628227 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21628227
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21628228 = query.getOrDefault("DBSecurityGroupName")
  valid_21628228 = validateParameter(valid_21628228, JString, required = true,
                                   default = nil)
  if valid_21628228 != nil:
    section.add "DBSecurityGroupName", valid_21628228
  var valid_21628229 = query.getOrDefault("Action")
  valid_21628229 = validateParameter(valid_21628229, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_21628229 != nil:
    section.add "Action", valid_21628229
  var valid_21628230 = query.getOrDefault("CIDRIP")
  valid_21628230 = validateParameter(valid_21628230, JString, required = false,
                                   default = nil)
  if valid_21628230 != nil:
    section.add "CIDRIP", valid_21628230
  var valid_21628231 = query.getOrDefault("EC2SecurityGroupName")
  valid_21628231 = validateParameter(valid_21628231, JString, required = false,
                                   default = nil)
  if valid_21628231 != nil:
    section.add "EC2SecurityGroupName", valid_21628231
  var valid_21628232 = query.getOrDefault("Version")
  valid_21628232 = validateParameter(valid_21628232, JString, required = true,
                                   default = newJString("2014-09-01"))
  if valid_21628232 != nil:
    section.add "Version", valid_21628232
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
  var valid_21628233 = header.getOrDefault("X-Amz-Date")
  valid_21628233 = validateParameter(valid_21628233, JString, required = false,
                                   default = nil)
  if valid_21628233 != nil:
    section.add "X-Amz-Date", valid_21628233
  var valid_21628234 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628234 = validateParameter(valid_21628234, JString, required = false,
                                   default = nil)
  if valid_21628234 != nil:
    section.add "X-Amz-Security-Token", valid_21628234
  var valid_21628235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628235 = validateParameter(valid_21628235, JString, required = false,
                                   default = nil)
  if valid_21628235 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628235
  var valid_21628236 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628236 = validateParameter(valid_21628236, JString, required = false,
                                   default = nil)
  if valid_21628236 != nil:
    section.add "X-Amz-Algorithm", valid_21628236
  var valid_21628237 = header.getOrDefault("X-Amz-Signature")
  valid_21628237 = validateParameter(valid_21628237, JString, required = false,
                                   default = nil)
  if valid_21628237 != nil:
    section.add "X-Amz-Signature", valid_21628237
  var valid_21628238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628238 = validateParameter(valid_21628238, JString, required = false,
                                   default = nil)
  if valid_21628238 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628238
  var valid_21628239 = header.getOrDefault("X-Amz-Credential")
  valid_21628239 = validateParameter(valid_21628239, JString, required = false,
                                   default = nil)
  if valid_21628239 != nil:
    section.add "X-Amz-Credential", valid_21628239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628240: Call_GetRevokeDBSecurityGroupIngress_21628223;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628240.validator(path, query, header, formData, body, _)
  let scheme = call_21628240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628240.makeUrl(scheme.get, call_21628240.host, call_21628240.base,
                               call_21628240.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628240, uri, valid, _)

proc call*(call_21628241: Call_GetRevokeDBSecurityGroupIngress_21628223;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_21628242 = newJObject()
  add(query_21628242, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_21628242, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_21628242, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21628242, "Action", newJString(Action))
  add(query_21628242, "CIDRIP", newJString(CIDRIP))
  add(query_21628242, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_21628242, "Version", newJString(Version))
  result = call_21628241.call(nil, query_21628242, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_21628223(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_21628224, base: "/",
    makeUrl: url_GetRevokeDBSecurityGroupIngress_21628225,
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
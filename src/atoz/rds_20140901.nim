
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599352 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599352](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599352): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_599961 = ref object of OpenApiRestCall_599352
proc url_PostAddSourceIdentifierToSubscription_599963(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_599962(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599964 = query.getOrDefault("Action")
  valid_599964 = validateParameter(valid_599964, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_599964 != nil:
    section.add "Action", valid_599964
  var valid_599965 = query.getOrDefault("Version")
  valid_599965 = validateParameter(valid_599965, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_599965 != nil:
    section.add "Version", valid_599965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599966 = header.getOrDefault("X-Amz-Date")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Date", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Security-Token")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Security-Token", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Content-Sha256", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Algorithm")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Algorithm", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Signature")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Signature", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-SignedHeaders", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Credential")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Credential", valid_599972
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_599973 = formData.getOrDefault("SourceIdentifier")
  valid_599973 = validateParameter(valid_599973, JString, required = true,
                                 default = nil)
  if valid_599973 != nil:
    section.add "SourceIdentifier", valid_599973
  var valid_599974 = formData.getOrDefault("SubscriptionName")
  valid_599974 = validateParameter(valid_599974, JString, required = true,
                                 default = nil)
  if valid_599974 != nil:
    section.add "SubscriptionName", valid_599974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599975: Call_PostAddSourceIdentifierToSubscription_599961;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_599975.validator(path, query, header, formData, body)
  let scheme = call_599975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599975.url(scheme.get, call_599975.host, call_599975.base,
                         call_599975.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599975, url, valid)

proc call*(call_599976: Call_PostAddSourceIdentifierToSubscription_599961;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_599977 = newJObject()
  var formData_599978 = newJObject()
  add(formData_599978, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_599978, "SubscriptionName", newJString(SubscriptionName))
  add(query_599977, "Action", newJString(Action))
  add(query_599977, "Version", newJString(Version))
  result = call_599976.call(nil, query_599977, nil, formData_599978, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_599961(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_599962, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_599963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_599689 = ref object of OpenApiRestCall_599352
proc url_GetAddSourceIdentifierToSubscription_599691(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_599690(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599816 = query.getOrDefault("Action")
  valid_599816 = validateParameter(valid_599816, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_599816 != nil:
    section.add "Action", valid_599816
  var valid_599817 = query.getOrDefault("SourceIdentifier")
  valid_599817 = validateParameter(valid_599817, JString, required = true,
                                 default = nil)
  if valid_599817 != nil:
    section.add "SourceIdentifier", valid_599817
  var valid_599818 = query.getOrDefault("SubscriptionName")
  valid_599818 = validateParameter(valid_599818, JString, required = true,
                                 default = nil)
  if valid_599818 != nil:
    section.add "SubscriptionName", valid_599818
  var valid_599819 = query.getOrDefault("Version")
  valid_599819 = validateParameter(valid_599819, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_599819 != nil:
    section.add "Version", valid_599819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599820 = header.getOrDefault("X-Amz-Date")
  valid_599820 = validateParameter(valid_599820, JString, required = false,
                                 default = nil)
  if valid_599820 != nil:
    section.add "X-Amz-Date", valid_599820
  var valid_599821 = header.getOrDefault("X-Amz-Security-Token")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "X-Amz-Security-Token", valid_599821
  var valid_599822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Content-Sha256", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Algorithm")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Algorithm", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Signature")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Signature", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-SignedHeaders", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Credential")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Credential", valid_599826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599849: Call_GetAddSourceIdentifierToSubscription_599689;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_599849.validator(path, query, header, formData, body)
  let scheme = call_599849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599849.url(scheme.get, call_599849.host, call_599849.base,
                         call_599849.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599849, url, valid)

proc call*(call_599920: Call_GetAddSourceIdentifierToSubscription_599689;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_599921 = newJObject()
  add(query_599921, "Action", newJString(Action))
  add(query_599921, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_599921, "SubscriptionName", newJString(SubscriptionName))
  add(query_599921, "Version", newJString(Version))
  result = call_599920.call(nil, query_599921, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_599689(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_599690, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_599691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_599996 = ref object of OpenApiRestCall_599352
proc url_PostAddTagsToResource_599998(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_599997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_599999 = query.getOrDefault("Action")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_599999 != nil:
    section.add "Action", valid_599999
  var valid_600000 = query.getOrDefault("Version")
  valid_600000 = validateParameter(valid_600000, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600000 != nil:
    section.add "Version", valid_600000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600001 = header.getOrDefault("X-Amz-Date")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Date", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Security-Token")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Security-Token", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Content-Sha256", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Algorithm")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Algorithm", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-Signature")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-Signature", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-SignedHeaders", valid_600006
  var valid_600007 = header.getOrDefault("X-Amz-Credential")
  valid_600007 = validateParameter(valid_600007, JString, required = false,
                                 default = nil)
  if valid_600007 != nil:
    section.add "X-Amz-Credential", valid_600007
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_600008 = formData.getOrDefault("Tags")
  valid_600008 = validateParameter(valid_600008, JArray, required = true, default = nil)
  if valid_600008 != nil:
    section.add "Tags", valid_600008
  var valid_600009 = formData.getOrDefault("ResourceName")
  valid_600009 = validateParameter(valid_600009, JString, required = true,
                                 default = nil)
  if valid_600009 != nil:
    section.add "ResourceName", valid_600009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600010: Call_PostAddTagsToResource_599996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600010.validator(path, query, header, formData, body)
  let scheme = call_600010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600010.url(scheme.get, call_600010.host, call_600010.base,
                         call_600010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600010, url, valid)

proc call*(call_600011: Call_PostAddTagsToResource_599996; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_600012 = newJObject()
  var formData_600013 = newJObject()
  if Tags != nil:
    formData_600013.add "Tags", Tags
  add(query_600012, "Action", newJString(Action))
  add(formData_600013, "ResourceName", newJString(ResourceName))
  add(query_600012, "Version", newJString(Version))
  result = call_600011.call(nil, query_600012, nil, formData_600013, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_599996(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_599997, base: "/",
    url: url_PostAddTagsToResource_599998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_599979 = ref object of OpenApiRestCall_599352
proc url_GetAddTagsToResource_599981(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_599980(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_599982 = query.getOrDefault("Tags")
  valid_599982 = validateParameter(valid_599982, JArray, required = true, default = nil)
  if valid_599982 != nil:
    section.add "Tags", valid_599982
  var valid_599983 = query.getOrDefault("ResourceName")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = nil)
  if valid_599983 != nil:
    section.add "ResourceName", valid_599983
  var valid_599984 = query.getOrDefault("Action")
  valid_599984 = validateParameter(valid_599984, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_599984 != nil:
    section.add "Action", valid_599984
  var valid_599985 = query.getOrDefault("Version")
  valid_599985 = validateParameter(valid_599985, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_599985 != nil:
    section.add "Version", valid_599985
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599986 = header.getOrDefault("X-Amz-Date")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Date", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Security-Token")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Security-Token", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Content-Sha256", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-Algorithm")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-Algorithm", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Signature")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Signature", valid_599990
  var valid_599991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599991 = validateParameter(valid_599991, JString, required = false,
                                 default = nil)
  if valid_599991 != nil:
    section.add "X-Amz-SignedHeaders", valid_599991
  var valid_599992 = header.getOrDefault("X-Amz-Credential")
  valid_599992 = validateParameter(valid_599992, JString, required = false,
                                 default = nil)
  if valid_599992 != nil:
    section.add "X-Amz-Credential", valid_599992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599993: Call_GetAddTagsToResource_599979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_599993.validator(path, query, header, formData, body)
  let scheme = call_599993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599993.url(scheme.get, call_599993.host, call_599993.base,
                         call_599993.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599993, url, valid)

proc call*(call_599994: Call_GetAddTagsToResource_599979; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_599995 = newJObject()
  if Tags != nil:
    query_599995.add "Tags", Tags
  add(query_599995, "ResourceName", newJString(ResourceName))
  add(query_599995, "Action", newJString(Action))
  add(query_599995, "Version", newJString(Version))
  result = call_599994.call(nil, query_599995, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_599979(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_599980, base: "/",
    url: url_GetAddTagsToResource_599981, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_600034 = ref object of OpenApiRestCall_599352
proc url_PostAuthorizeDBSecurityGroupIngress_600036(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_600035(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600037 = query.getOrDefault("Action")
  valid_600037 = validateParameter(valid_600037, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_600037 != nil:
    section.add "Action", valid_600037
  var valid_600038 = query.getOrDefault("Version")
  valid_600038 = validateParameter(valid_600038, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600038 != nil:
    section.add "Version", valid_600038
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600039 = header.getOrDefault("X-Amz-Date")
  valid_600039 = validateParameter(valid_600039, JString, required = false,
                                 default = nil)
  if valid_600039 != nil:
    section.add "X-Amz-Date", valid_600039
  var valid_600040 = header.getOrDefault("X-Amz-Security-Token")
  valid_600040 = validateParameter(valid_600040, JString, required = false,
                                 default = nil)
  if valid_600040 != nil:
    section.add "X-Amz-Security-Token", valid_600040
  var valid_600041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600041 = validateParameter(valid_600041, JString, required = false,
                                 default = nil)
  if valid_600041 != nil:
    section.add "X-Amz-Content-Sha256", valid_600041
  var valid_600042 = header.getOrDefault("X-Amz-Algorithm")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Algorithm", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Signature")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Signature", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-SignedHeaders", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Credential")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Credential", valid_600045
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600046 = formData.getOrDefault("DBSecurityGroupName")
  valid_600046 = validateParameter(valid_600046, JString, required = true,
                                 default = nil)
  if valid_600046 != nil:
    section.add "DBSecurityGroupName", valid_600046
  var valid_600047 = formData.getOrDefault("EC2SecurityGroupName")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "EC2SecurityGroupName", valid_600047
  var valid_600048 = formData.getOrDefault("EC2SecurityGroupId")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "EC2SecurityGroupId", valid_600048
  var valid_600049 = formData.getOrDefault("CIDRIP")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "CIDRIP", valid_600049
  var valid_600050 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_600050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600051: Call_PostAuthorizeDBSecurityGroupIngress_600034;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600051.validator(path, query, header, formData, body)
  let scheme = call_600051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600051.url(scheme.get, call_600051.host, call_600051.base,
                         call_600051.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600051, url, valid)

proc call*(call_600052: Call_PostAuthorizeDBSecurityGroupIngress_600034;
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
  var query_600053 = newJObject()
  var formData_600054 = newJObject()
  add(formData_600054, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600053, "Action", newJString(Action))
  add(formData_600054, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_600054, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_600054, "CIDRIP", newJString(CIDRIP))
  add(query_600053, "Version", newJString(Version))
  add(formData_600054, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_600052.call(nil, query_600053, nil, formData_600054, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_600034(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_600035, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_600036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_600014 = ref object of OpenApiRestCall_599352
proc url_GetAuthorizeDBSecurityGroupIngress_600016(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_600015(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600017 = query.getOrDefault("EC2SecurityGroupId")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "EC2SecurityGroupId", valid_600017
  var valid_600018 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_600018
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600019 = query.getOrDefault("DBSecurityGroupName")
  valid_600019 = validateParameter(valid_600019, JString, required = true,
                                 default = nil)
  if valid_600019 != nil:
    section.add "DBSecurityGroupName", valid_600019
  var valid_600020 = query.getOrDefault("Action")
  valid_600020 = validateParameter(valid_600020, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_600020 != nil:
    section.add "Action", valid_600020
  var valid_600021 = query.getOrDefault("CIDRIP")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "CIDRIP", valid_600021
  var valid_600022 = query.getOrDefault("EC2SecurityGroupName")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "EC2SecurityGroupName", valid_600022
  var valid_600023 = query.getOrDefault("Version")
  valid_600023 = validateParameter(valid_600023, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600023 != nil:
    section.add "Version", valid_600023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600024 = header.getOrDefault("X-Amz-Date")
  valid_600024 = validateParameter(valid_600024, JString, required = false,
                                 default = nil)
  if valid_600024 != nil:
    section.add "X-Amz-Date", valid_600024
  var valid_600025 = header.getOrDefault("X-Amz-Security-Token")
  valid_600025 = validateParameter(valid_600025, JString, required = false,
                                 default = nil)
  if valid_600025 != nil:
    section.add "X-Amz-Security-Token", valid_600025
  var valid_600026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600026 = validateParameter(valid_600026, JString, required = false,
                                 default = nil)
  if valid_600026 != nil:
    section.add "X-Amz-Content-Sha256", valid_600026
  var valid_600027 = header.getOrDefault("X-Amz-Algorithm")
  valid_600027 = validateParameter(valid_600027, JString, required = false,
                                 default = nil)
  if valid_600027 != nil:
    section.add "X-Amz-Algorithm", valid_600027
  var valid_600028 = header.getOrDefault("X-Amz-Signature")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Signature", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-SignedHeaders", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Credential")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Credential", valid_600030
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600031: Call_GetAuthorizeDBSecurityGroupIngress_600014;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600031.validator(path, query, header, formData, body)
  let scheme = call_600031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600031.url(scheme.get, call_600031.host, call_600031.base,
                         call_600031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600031, url, valid)

proc call*(call_600032: Call_GetAuthorizeDBSecurityGroupIngress_600014;
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
  var query_600033 = newJObject()
  add(query_600033, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_600033, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_600033, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600033, "Action", newJString(Action))
  add(query_600033, "CIDRIP", newJString(CIDRIP))
  add(query_600033, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_600033, "Version", newJString(Version))
  result = call_600032.call(nil, query_600033, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_600014(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_600015, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_600016,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBParameterGroup_600074 = ref object of OpenApiRestCall_599352
proc url_PostCopyDBParameterGroup_600076(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBParameterGroup_600075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600077 = query.getOrDefault("Action")
  valid_600077 = validateParameter(valid_600077, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_600077 != nil:
    section.add "Action", valid_600077
  var valid_600078 = query.getOrDefault("Version")
  valid_600078 = validateParameter(valid_600078, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600078 != nil:
    section.add "Version", valid_600078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600079 = header.getOrDefault("X-Amz-Date")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Date", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Security-Token")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Security-Token", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Content-Sha256", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Algorithm")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Algorithm", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Signature")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Signature", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-SignedHeaders", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Credential")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Credential", valid_600085
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_600086 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_600086 = validateParameter(valid_600086, JString, required = true,
                                 default = nil)
  if valid_600086 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_600086
  var valid_600087 = formData.getOrDefault("Tags")
  valid_600087 = validateParameter(valid_600087, JArray, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "Tags", valid_600087
  var valid_600088 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_600088 = validateParameter(valid_600088, JString, required = true,
                                 default = nil)
  if valid_600088 != nil:
    section.add "TargetDBParameterGroupDescription", valid_600088
  var valid_600089 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_600089 = validateParameter(valid_600089, JString, required = true,
                                 default = nil)
  if valid_600089 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_600089
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600090: Call_PostCopyDBParameterGroup_600074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600090.validator(path, query, header, formData, body)
  let scheme = call_600090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600090.url(scheme.get, call_600090.host, call_600090.base,
                         call_600090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600090, url, valid)

proc call*(call_600091: Call_PostCopyDBParameterGroup_600074;
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
  var query_600092 = newJObject()
  var formData_600093 = newJObject()
  add(formData_600093, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_600093.add "Tags", Tags
  add(query_600092, "Action", newJString(Action))
  add(formData_600093, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_600093, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_600092, "Version", newJString(Version))
  result = call_600091.call(nil, query_600092, nil, formData_600093, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_600074(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_600075, base: "/",
    url: url_PostCopyDBParameterGroup_600076, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_600055 = ref object of OpenApiRestCall_599352
proc url_GetCopyDBParameterGroup_600057(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBParameterGroup_600056(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600058 = query.getOrDefault("Tags")
  valid_600058 = validateParameter(valid_600058, JArray, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "Tags", valid_600058
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600059 = query.getOrDefault("Action")
  valid_600059 = validateParameter(valid_600059, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_600059 != nil:
    section.add "Action", valid_600059
  var valid_600060 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_600060
  var valid_600061 = query.getOrDefault("Version")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600061 != nil:
    section.add "Version", valid_600061
  var valid_600062 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_600062 = validateParameter(valid_600062, JString, required = true,
                                 default = nil)
  if valid_600062 != nil:
    section.add "TargetDBParameterGroupDescription", valid_600062
  var valid_600063 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_600063 = validateParameter(valid_600063, JString, required = true,
                                 default = nil)
  if valid_600063 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_600063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600064 = header.getOrDefault("X-Amz-Date")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Date", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Security-Token")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Security-Token", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Content-Sha256", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Algorithm")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Algorithm", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Signature")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Signature", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-SignedHeaders", valid_600069
  var valid_600070 = header.getOrDefault("X-Amz-Credential")
  valid_600070 = validateParameter(valid_600070, JString, required = false,
                                 default = nil)
  if valid_600070 != nil:
    section.add "X-Amz-Credential", valid_600070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600071: Call_GetCopyDBParameterGroup_600055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600071.validator(path, query, header, formData, body)
  let scheme = call_600071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600071.url(scheme.get, call_600071.host, call_600071.base,
                         call_600071.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600071, url, valid)

proc call*(call_600072: Call_GetCopyDBParameterGroup_600055;
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
  var query_600073 = newJObject()
  if Tags != nil:
    query_600073.add "Tags", Tags
  add(query_600073, "Action", newJString(Action))
  add(query_600073, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_600073, "Version", newJString(Version))
  add(query_600073, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_600073, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_600072.call(nil, query_600073, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_600055(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_600056, base: "/",
    url: url_GetCopyDBParameterGroup_600057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_600112 = ref object of OpenApiRestCall_599352
proc url_PostCopyDBSnapshot_600114(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_600113(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600115 = query.getOrDefault("Action")
  valid_600115 = validateParameter(valid_600115, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_600115 != nil:
    section.add "Action", valid_600115
  var valid_600116 = query.getOrDefault("Version")
  valid_600116 = validateParameter(valid_600116, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600116 != nil:
    section.add "Version", valid_600116
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600117 = header.getOrDefault("X-Amz-Date")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Date", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Security-Token")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Security-Token", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Content-Sha256", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Algorithm")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Algorithm", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Signature")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Signature", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-SignedHeaders", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Credential")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Credential", valid_600123
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_600124 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_600124 = validateParameter(valid_600124, JString, required = true,
                                 default = nil)
  if valid_600124 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_600124
  var valid_600125 = formData.getOrDefault("Tags")
  valid_600125 = validateParameter(valid_600125, JArray, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "Tags", valid_600125
  var valid_600126 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_600126 = validateParameter(valid_600126, JString, required = true,
                                 default = nil)
  if valid_600126 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_600126
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600127: Call_PostCopyDBSnapshot_600112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600127.validator(path, query, header, formData, body)
  let scheme = call_600127.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600127.url(scheme.get, call_600127.host, call_600127.base,
                         call_600127.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600127, url, valid)

proc call*(call_600128: Call_PostCopyDBSnapshot_600112;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_600129 = newJObject()
  var formData_600130 = newJObject()
  add(formData_600130, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_600130.add "Tags", Tags
  add(query_600129, "Action", newJString(Action))
  add(formData_600130, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_600129, "Version", newJString(Version))
  result = call_600128.call(nil, query_600129, nil, formData_600130, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_600112(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_600113, base: "/",
    url: url_PostCopyDBSnapshot_600114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_600094 = ref object of OpenApiRestCall_599352
proc url_GetCopyDBSnapshot_600096(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_600095(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600097 = query.getOrDefault("Tags")
  valid_600097 = validateParameter(valid_600097, JArray, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "Tags", valid_600097
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_600098 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_600098 = validateParameter(valid_600098, JString, required = true,
                                 default = nil)
  if valid_600098 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_600098
  var valid_600099 = query.getOrDefault("Action")
  valid_600099 = validateParameter(valid_600099, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_600099 != nil:
    section.add "Action", valid_600099
  var valid_600100 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_600100 = validateParameter(valid_600100, JString, required = true,
                                 default = nil)
  if valid_600100 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_600100
  var valid_600101 = query.getOrDefault("Version")
  valid_600101 = validateParameter(valid_600101, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600101 != nil:
    section.add "Version", valid_600101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600102 = header.getOrDefault("X-Amz-Date")
  valid_600102 = validateParameter(valid_600102, JString, required = false,
                                 default = nil)
  if valid_600102 != nil:
    section.add "X-Amz-Date", valid_600102
  var valid_600103 = header.getOrDefault("X-Amz-Security-Token")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Security-Token", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Content-Sha256", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Algorithm")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Algorithm", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Signature")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Signature", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-SignedHeaders", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-Credential")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-Credential", valid_600108
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600109: Call_GetCopyDBSnapshot_600094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600109.validator(path, query, header, formData, body)
  let scheme = call_600109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600109.url(scheme.get, call_600109.host, call_600109.base,
                         call_600109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600109, url, valid)

proc call*(call_600110: Call_GetCopyDBSnapshot_600094;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_600111 = newJObject()
  if Tags != nil:
    query_600111.add "Tags", Tags
  add(query_600111, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_600111, "Action", newJString(Action))
  add(query_600111, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_600111, "Version", newJString(Version))
  result = call_600110.call(nil, query_600111, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_600094(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_600095,
    base: "/", url: url_GetCopyDBSnapshot_600096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_600150 = ref object of OpenApiRestCall_599352
proc url_PostCopyOptionGroup_600152(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyOptionGroup_600151(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600153 = query.getOrDefault("Action")
  valid_600153 = validateParameter(valid_600153, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_600153 != nil:
    section.add "Action", valid_600153
  var valid_600154 = query.getOrDefault("Version")
  valid_600154 = validateParameter(valid_600154, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600154 != nil:
    section.add "Version", valid_600154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600155 = header.getOrDefault("X-Amz-Date")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Date", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-Security-Token")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-Security-Token", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Content-Sha256", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Algorithm")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Algorithm", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Signature")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Signature", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-SignedHeaders", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Credential")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Credential", valid_600161
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_600162 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_600162 = validateParameter(valid_600162, JString, required = true,
                                 default = nil)
  if valid_600162 != nil:
    section.add "TargetOptionGroupDescription", valid_600162
  var valid_600163 = formData.getOrDefault("Tags")
  valid_600163 = validateParameter(valid_600163, JArray, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "Tags", valid_600163
  var valid_600164 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_600164 = validateParameter(valid_600164, JString, required = true,
                                 default = nil)
  if valid_600164 != nil:
    section.add "SourceOptionGroupIdentifier", valid_600164
  var valid_600165 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_600165 = validateParameter(valid_600165, JString, required = true,
                                 default = nil)
  if valid_600165 != nil:
    section.add "TargetOptionGroupIdentifier", valid_600165
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600166: Call_PostCopyOptionGroup_600150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600166.validator(path, query, header, formData, body)
  let scheme = call_600166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600166.url(scheme.get, call_600166.host, call_600166.base,
                         call_600166.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600166, url, valid)

proc call*(call_600167: Call_PostCopyOptionGroup_600150;
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
  var query_600168 = newJObject()
  var formData_600169 = newJObject()
  add(formData_600169, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_600169.add "Tags", Tags
  add(formData_600169, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_600168, "Action", newJString(Action))
  add(formData_600169, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_600168, "Version", newJString(Version))
  result = call_600167.call(nil, query_600168, nil, formData_600169, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_600150(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_600151, base: "/",
    url: url_PostCopyOptionGroup_600152, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_600131 = ref object of OpenApiRestCall_599352
proc url_GetCopyOptionGroup_600133(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyOptionGroup_600132(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
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
  var valid_600134 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_600134 = validateParameter(valid_600134, JString, required = true,
                                 default = nil)
  if valid_600134 != nil:
    section.add "SourceOptionGroupIdentifier", valid_600134
  var valid_600135 = query.getOrDefault("Tags")
  valid_600135 = validateParameter(valid_600135, JArray, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "Tags", valid_600135
  var valid_600136 = query.getOrDefault("Action")
  valid_600136 = validateParameter(valid_600136, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_600136 != nil:
    section.add "Action", valid_600136
  var valid_600137 = query.getOrDefault("TargetOptionGroupDescription")
  valid_600137 = validateParameter(valid_600137, JString, required = true,
                                 default = nil)
  if valid_600137 != nil:
    section.add "TargetOptionGroupDescription", valid_600137
  var valid_600138 = query.getOrDefault("Version")
  valid_600138 = validateParameter(valid_600138, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600138 != nil:
    section.add "Version", valid_600138
  var valid_600139 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_600139 = validateParameter(valid_600139, JString, required = true,
                                 default = nil)
  if valid_600139 != nil:
    section.add "TargetOptionGroupIdentifier", valid_600139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600140 = header.getOrDefault("X-Amz-Date")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Date", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Security-Token")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Security-Token", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Content-Sha256", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Algorithm")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Algorithm", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Signature")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Signature", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-SignedHeaders", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Credential")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Credential", valid_600146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600147: Call_GetCopyOptionGroup_600131; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600147.validator(path, query, header, formData, body)
  let scheme = call_600147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600147.url(scheme.get, call_600147.host, call_600147.base,
                         call_600147.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600147, url, valid)

proc call*(call_600148: Call_GetCopyOptionGroup_600131;
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
  var query_600149 = newJObject()
  add(query_600149, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_600149.add "Tags", Tags
  add(query_600149, "Action", newJString(Action))
  add(query_600149, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_600149, "Version", newJString(Version))
  add(query_600149, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_600148.call(nil, query_600149, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_600131(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_600132,
    base: "/", url: url_GetCopyOptionGroup_600133,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_600213 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBInstance_600215(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_600214(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600216 = query.getOrDefault("Action")
  valid_600216 = validateParameter(valid_600216, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600216 != nil:
    section.add "Action", valid_600216
  var valid_600217 = query.getOrDefault("Version")
  valid_600217 = validateParameter(valid_600217, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600217 != nil:
    section.add "Version", valid_600217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600218 = header.getOrDefault("X-Amz-Date")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Date", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Security-Token")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Security-Token", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Content-Sha256", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Algorithm")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Algorithm", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-Signature")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-Signature", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-SignedHeaders", valid_600223
  var valid_600224 = header.getOrDefault("X-Amz-Credential")
  valid_600224 = validateParameter(valid_600224, JString, required = false,
                                 default = nil)
  if valid_600224 != nil:
    section.add "X-Amz-Credential", valid_600224
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
  var valid_600225 = formData.getOrDefault("DBSecurityGroups")
  valid_600225 = validateParameter(valid_600225, JArray, required = false,
                                 default = nil)
  if valid_600225 != nil:
    section.add "DBSecurityGroups", valid_600225
  var valid_600226 = formData.getOrDefault("Port")
  valid_600226 = validateParameter(valid_600226, JInt, required = false, default = nil)
  if valid_600226 != nil:
    section.add "Port", valid_600226
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_600227 = formData.getOrDefault("Engine")
  valid_600227 = validateParameter(valid_600227, JString, required = true,
                                 default = nil)
  if valid_600227 != nil:
    section.add "Engine", valid_600227
  var valid_600228 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_600228 = validateParameter(valid_600228, JArray, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "VpcSecurityGroupIds", valid_600228
  var valid_600229 = formData.getOrDefault("Iops")
  valid_600229 = validateParameter(valid_600229, JInt, required = false, default = nil)
  if valid_600229 != nil:
    section.add "Iops", valid_600229
  var valid_600230 = formData.getOrDefault("DBName")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "DBName", valid_600230
  var valid_600231 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600231 = validateParameter(valid_600231, JString, required = true,
                                 default = nil)
  if valid_600231 != nil:
    section.add "DBInstanceIdentifier", valid_600231
  var valid_600232 = formData.getOrDefault("BackupRetentionPeriod")
  valid_600232 = validateParameter(valid_600232, JInt, required = false, default = nil)
  if valid_600232 != nil:
    section.add "BackupRetentionPeriod", valid_600232
  var valid_600233 = formData.getOrDefault("DBParameterGroupName")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "DBParameterGroupName", valid_600233
  var valid_600234 = formData.getOrDefault("OptionGroupName")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "OptionGroupName", valid_600234
  var valid_600235 = formData.getOrDefault("Tags")
  valid_600235 = validateParameter(valid_600235, JArray, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "Tags", valid_600235
  var valid_600236 = formData.getOrDefault("MasterUserPassword")
  valid_600236 = validateParameter(valid_600236, JString, required = true,
                                 default = nil)
  if valid_600236 != nil:
    section.add "MasterUserPassword", valid_600236
  var valid_600237 = formData.getOrDefault("TdeCredentialArn")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "TdeCredentialArn", valid_600237
  var valid_600238 = formData.getOrDefault("DBSubnetGroupName")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "DBSubnetGroupName", valid_600238
  var valid_600239 = formData.getOrDefault("TdeCredentialPassword")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "TdeCredentialPassword", valid_600239
  var valid_600240 = formData.getOrDefault("AvailabilityZone")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "AvailabilityZone", valid_600240
  var valid_600241 = formData.getOrDefault("MultiAZ")
  valid_600241 = validateParameter(valid_600241, JBool, required = false, default = nil)
  if valid_600241 != nil:
    section.add "MultiAZ", valid_600241
  var valid_600242 = formData.getOrDefault("AllocatedStorage")
  valid_600242 = validateParameter(valid_600242, JInt, required = true, default = nil)
  if valid_600242 != nil:
    section.add "AllocatedStorage", valid_600242
  var valid_600243 = formData.getOrDefault("PubliclyAccessible")
  valid_600243 = validateParameter(valid_600243, JBool, required = false, default = nil)
  if valid_600243 != nil:
    section.add "PubliclyAccessible", valid_600243
  var valid_600244 = formData.getOrDefault("MasterUsername")
  valid_600244 = validateParameter(valid_600244, JString, required = true,
                                 default = nil)
  if valid_600244 != nil:
    section.add "MasterUsername", valid_600244
  var valid_600245 = formData.getOrDefault("StorageType")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "StorageType", valid_600245
  var valid_600246 = formData.getOrDefault("DBInstanceClass")
  valid_600246 = validateParameter(valid_600246, JString, required = true,
                                 default = nil)
  if valid_600246 != nil:
    section.add "DBInstanceClass", valid_600246
  var valid_600247 = formData.getOrDefault("CharacterSetName")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "CharacterSetName", valid_600247
  var valid_600248 = formData.getOrDefault("PreferredBackupWindow")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "PreferredBackupWindow", valid_600248
  var valid_600249 = formData.getOrDefault("LicenseModel")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "LicenseModel", valid_600249
  var valid_600250 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_600250 = validateParameter(valid_600250, JBool, required = false, default = nil)
  if valid_600250 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600250
  var valid_600251 = formData.getOrDefault("EngineVersion")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "EngineVersion", valid_600251
  var valid_600252 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "PreferredMaintenanceWindow", valid_600252
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600253: Call_PostCreateDBInstance_600213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600253.validator(path, query, header, formData, body)
  let scheme = call_600253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600253.url(scheme.get, call_600253.host, call_600253.base,
                         call_600253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600253, url, valid)

proc call*(call_600254: Call_PostCreateDBInstance_600213; Engine: string;
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
  var query_600255 = newJObject()
  var formData_600256 = newJObject()
  if DBSecurityGroups != nil:
    formData_600256.add "DBSecurityGroups", DBSecurityGroups
  add(formData_600256, "Port", newJInt(Port))
  add(formData_600256, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_600256.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_600256, "Iops", newJInt(Iops))
  add(formData_600256, "DBName", newJString(DBName))
  add(formData_600256, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600256, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_600256, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600256, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_600256.add "Tags", Tags
  add(formData_600256, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_600256, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_600256, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_600256, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_600256, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_600256, "MultiAZ", newJBool(MultiAZ))
  add(query_600255, "Action", newJString(Action))
  add(formData_600256, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_600256, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_600256, "MasterUsername", newJString(MasterUsername))
  add(formData_600256, "StorageType", newJString(StorageType))
  add(formData_600256, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_600256, "CharacterSetName", newJString(CharacterSetName))
  add(formData_600256, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_600256, "LicenseModel", newJString(LicenseModel))
  add(formData_600256, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_600256, "EngineVersion", newJString(EngineVersion))
  add(query_600255, "Version", newJString(Version))
  add(formData_600256, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_600254.call(nil, query_600255, nil, formData_600256, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_600213(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_600214, base: "/",
    url: url_PostCreateDBInstance_600215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_600170 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBInstance_600172(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_600171(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600173 = query.getOrDefault("Engine")
  valid_600173 = validateParameter(valid_600173, JString, required = true,
                                 default = nil)
  if valid_600173 != nil:
    section.add "Engine", valid_600173
  var valid_600174 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "PreferredMaintenanceWindow", valid_600174
  var valid_600175 = query.getOrDefault("AllocatedStorage")
  valid_600175 = validateParameter(valid_600175, JInt, required = true, default = nil)
  if valid_600175 != nil:
    section.add "AllocatedStorage", valid_600175
  var valid_600176 = query.getOrDefault("StorageType")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "StorageType", valid_600176
  var valid_600177 = query.getOrDefault("OptionGroupName")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "OptionGroupName", valid_600177
  var valid_600178 = query.getOrDefault("DBSecurityGroups")
  valid_600178 = validateParameter(valid_600178, JArray, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "DBSecurityGroups", valid_600178
  var valid_600179 = query.getOrDefault("MasterUserPassword")
  valid_600179 = validateParameter(valid_600179, JString, required = true,
                                 default = nil)
  if valid_600179 != nil:
    section.add "MasterUserPassword", valid_600179
  var valid_600180 = query.getOrDefault("AvailabilityZone")
  valid_600180 = validateParameter(valid_600180, JString, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "AvailabilityZone", valid_600180
  var valid_600181 = query.getOrDefault("Iops")
  valid_600181 = validateParameter(valid_600181, JInt, required = false, default = nil)
  if valid_600181 != nil:
    section.add "Iops", valid_600181
  var valid_600182 = query.getOrDefault("VpcSecurityGroupIds")
  valid_600182 = validateParameter(valid_600182, JArray, required = false,
                                 default = nil)
  if valid_600182 != nil:
    section.add "VpcSecurityGroupIds", valid_600182
  var valid_600183 = query.getOrDefault("MultiAZ")
  valid_600183 = validateParameter(valid_600183, JBool, required = false, default = nil)
  if valid_600183 != nil:
    section.add "MultiAZ", valid_600183
  var valid_600184 = query.getOrDefault("TdeCredentialPassword")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "TdeCredentialPassword", valid_600184
  var valid_600185 = query.getOrDefault("LicenseModel")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "LicenseModel", valid_600185
  var valid_600186 = query.getOrDefault("BackupRetentionPeriod")
  valid_600186 = validateParameter(valid_600186, JInt, required = false, default = nil)
  if valid_600186 != nil:
    section.add "BackupRetentionPeriod", valid_600186
  var valid_600187 = query.getOrDefault("DBName")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "DBName", valid_600187
  var valid_600188 = query.getOrDefault("DBParameterGroupName")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "DBParameterGroupName", valid_600188
  var valid_600189 = query.getOrDefault("Tags")
  valid_600189 = validateParameter(valid_600189, JArray, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "Tags", valid_600189
  var valid_600190 = query.getOrDefault("DBInstanceClass")
  valid_600190 = validateParameter(valid_600190, JString, required = true,
                                 default = nil)
  if valid_600190 != nil:
    section.add "DBInstanceClass", valid_600190
  var valid_600191 = query.getOrDefault("Action")
  valid_600191 = validateParameter(valid_600191, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600191 != nil:
    section.add "Action", valid_600191
  var valid_600192 = query.getOrDefault("DBSubnetGroupName")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "DBSubnetGroupName", valid_600192
  var valid_600193 = query.getOrDefault("CharacterSetName")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "CharacterSetName", valid_600193
  var valid_600194 = query.getOrDefault("TdeCredentialArn")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "TdeCredentialArn", valid_600194
  var valid_600195 = query.getOrDefault("PubliclyAccessible")
  valid_600195 = validateParameter(valid_600195, JBool, required = false, default = nil)
  if valid_600195 != nil:
    section.add "PubliclyAccessible", valid_600195
  var valid_600196 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_600196 = validateParameter(valid_600196, JBool, required = false, default = nil)
  if valid_600196 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600196
  var valid_600197 = query.getOrDefault("EngineVersion")
  valid_600197 = validateParameter(valid_600197, JString, required = false,
                                 default = nil)
  if valid_600197 != nil:
    section.add "EngineVersion", valid_600197
  var valid_600198 = query.getOrDefault("Port")
  valid_600198 = validateParameter(valid_600198, JInt, required = false, default = nil)
  if valid_600198 != nil:
    section.add "Port", valid_600198
  var valid_600199 = query.getOrDefault("PreferredBackupWindow")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "PreferredBackupWindow", valid_600199
  var valid_600200 = query.getOrDefault("Version")
  valid_600200 = validateParameter(valid_600200, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600200 != nil:
    section.add "Version", valid_600200
  var valid_600201 = query.getOrDefault("DBInstanceIdentifier")
  valid_600201 = validateParameter(valid_600201, JString, required = true,
                                 default = nil)
  if valid_600201 != nil:
    section.add "DBInstanceIdentifier", valid_600201
  var valid_600202 = query.getOrDefault("MasterUsername")
  valid_600202 = validateParameter(valid_600202, JString, required = true,
                                 default = nil)
  if valid_600202 != nil:
    section.add "MasterUsername", valid_600202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600203 = header.getOrDefault("X-Amz-Date")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Date", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Security-Token")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Security-Token", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600210: Call_GetCreateDBInstance_600170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600210.validator(path, query, header, formData, body)
  let scheme = call_600210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600210.url(scheme.get, call_600210.host, call_600210.base,
                         call_600210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600210, url, valid)

proc call*(call_600211: Call_GetCreateDBInstance_600170; Engine: string;
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
  var query_600212 = newJObject()
  add(query_600212, "Engine", newJString(Engine))
  add(query_600212, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_600212, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_600212, "StorageType", newJString(StorageType))
  add(query_600212, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_600212.add "DBSecurityGroups", DBSecurityGroups
  add(query_600212, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_600212, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600212, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_600212.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_600212, "MultiAZ", newJBool(MultiAZ))
  add(query_600212, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_600212, "LicenseModel", newJString(LicenseModel))
  add(query_600212, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_600212, "DBName", newJString(DBName))
  add(query_600212, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_600212.add "Tags", Tags
  add(query_600212, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_600212, "Action", newJString(Action))
  add(query_600212, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600212, "CharacterSetName", newJString(CharacterSetName))
  add(query_600212, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_600212, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_600212, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_600212, "EngineVersion", newJString(EngineVersion))
  add(query_600212, "Port", newJInt(Port))
  add(query_600212, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_600212, "Version", newJString(Version))
  add(query_600212, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600212, "MasterUsername", newJString(MasterUsername))
  result = call_600211.call(nil, query_600212, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_600170(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_600171, base: "/",
    url: url_GetCreateDBInstance_600172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_600284 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBInstanceReadReplica_600286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_600285(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600287 = query.getOrDefault("Action")
  valid_600287 = validateParameter(valid_600287, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_600287 != nil:
    section.add "Action", valid_600287
  var valid_600288 = query.getOrDefault("Version")
  valid_600288 = validateParameter(valid_600288, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600288 != nil:
    section.add "Version", valid_600288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600289 = header.getOrDefault("X-Amz-Date")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Date", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Security-Token")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Security-Token", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Content-Sha256", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Algorithm")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Algorithm", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Signature")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Signature", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-SignedHeaders", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Credential")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Credential", valid_600295
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
  var valid_600296 = formData.getOrDefault("Port")
  valid_600296 = validateParameter(valid_600296, JInt, required = false, default = nil)
  if valid_600296 != nil:
    section.add "Port", valid_600296
  var valid_600297 = formData.getOrDefault("Iops")
  valid_600297 = validateParameter(valid_600297, JInt, required = false, default = nil)
  if valid_600297 != nil:
    section.add "Iops", valid_600297
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600298 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600298 = validateParameter(valid_600298, JString, required = true,
                                 default = nil)
  if valid_600298 != nil:
    section.add "DBInstanceIdentifier", valid_600298
  var valid_600299 = formData.getOrDefault("OptionGroupName")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "OptionGroupName", valid_600299
  var valid_600300 = formData.getOrDefault("Tags")
  valid_600300 = validateParameter(valid_600300, JArray, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "Tags", valid_600300
  var valid_600301 = formData.getOrDefault("DBSubnetGroupName")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "DBSubnetGroupName", valid_600301
  var valid_600302 = formData.getOrDefault("AvailabilityZone")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "AvailabilityZone", valid_600302
  var valid_600303 = formData.getOrDefault("PubliclyAccessible")
  valid_600303 = validateParameter(valid_600303, JBool, required = false, default = nil)
  if valid_600303 != nil:
    section.add "PubliclyAccessible", valid_600303
  var valid_600304 = formData.getOrDefault("StorageType")
  valid_600304 = validateParameter(valid_600304, JString, required = false,
                                 default = nil)
  if valid_600304 != nil:
    section.add "StorageType", valid_600304
  var valid_600305 = formData.getOrDefault("DBInstanceClass")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "DBInstanceClass", valid_600305
  var valid_600306 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = nil)
  if valid_600306 != nil:
    section.add "SourceDBInstanceIdentifier", valid_600306
  var valid_600307 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_600307 = validateParameter(valid_600307, JBool, required = false, default = nil)
  if valid_600307 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600307
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600308: Call_PostCreateDBInstanceReadReplica_600284;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600308.validator(path, query, header, formData, body)
  let scheme = call_600308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600308.url(scheme.get, call_600308.host, call_600308.base,
                         call_600308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600308, url, valid)

proc call*(call_600309: Call_PostCreateDBInstanceReadReplica_600284;
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
  var query_600310 = newJObject()
  var formData_600311 = newJObject()
  add(formData_600311, "Port", newJInt(Port))
  add(formData_600311, "Iops", newJInt(Iops))
  add(formData_600311, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600311, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_600311.add "Tags", Tags
  add(formData_600311, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_600311, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600310, "Action", newJString(Action))
  add(formData_600311, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_600311, "StorageType", newJString(StorageType))
  add(formData_600311, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_600311, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_600311, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_600310, "Version", newJString(Version))
  result = call_600309.call(nil, query_600310, nil, formData_600311, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_600284(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_600285, base: "/",
    url: url_PostCreateDBInstanceReadReplica_600286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_600257 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBInstanceReadReplica_600259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_600258(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600260 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_600260 = validateParameter(valid_600260, JString, required = true,
                                 default = nil)
  if valid_600260 != nil:
    section.add "SourceDBInstanceIdentifier", valid_600260
  var valid_600261 = query.getOrDefault("StorageType")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "StorageType", valid_600261
  var valid_600262 = query.getOrDefault("OptionGroupName")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "OptionGroupName", valid_600262
  var valid_600263 = query.getOrDefault("AvailabilityZone")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "AvailabilityZone", valid_600263
  var valid_600264 = query.getOrDefault("Iops")
  valid_600264 = validateParameter(valid_600264, JInt, required = false, default = nil)
  if valid_600264 != nil:
    section.add "Iops", valid_600264
  var valid_600265 = query.getOrDefault("Tags")
  valid_600265 = validateParameter(valid_600265, JArray, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "Tags", valid_600265
  var valid_600266 = query.getOrDefault("DBInstanceClass")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "DBInstanceClass", valid_600266
  var valid_600267 = query.getOrDefault("Action")
  valid_600267 = validateParameter(valid_600267, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_600267 != nil:
    section.add "Action", valid_600267
  var valid_600268 = query.getOrDefault("DBSubnetGroupName")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "DBSubnetGroupName", valid_600268
  var valid_600269 = query.getOrDefault("PubliclyAccessible")
  valid_600269 = validateParameter(valid_600269, JBool, required = false, default = nil)
  if valid_600269 != nil:
    section.add "PubliclyAccessible", valid_600269
  var valid_600270 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_600270 = validateParameter(valid_600270, JBool, required = false, default = nil)
  if valid_600270 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600270
  var valid_600271 = query.getOrDefault("Port")
  valid_600271 = validateParameter(valid_600271, JInt, required = false, default = nil)
  if valid_600271 != nil:
    section.add "Port", valid_600271
  var valid_600272 = query.getOrDefault("Version")
  valid_600272 = validateParameter(valid_600272, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600272 != nil:
    section.add "Version", valid_600272
  var valid_600273 = query.getOrDefault("DBInstanceIdentifier")
  valid_600273 = validateParameter(valid_600273, JString, required = true,
                                 default = nil)
  if valid_600273 != nil:
    section.add "DBInstanceIdentifier", valid_600273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600274 = header.getOrDefault("X-Amz-Date")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Date", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Security-Token")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Security-Token", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Content-Sha256", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Algorithm")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Algorithm", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Signature")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Signature", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-SignedHeaders", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Credential")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Credential", valid_600280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600281: Call_GetCreateDBInstanceReadReplica_600257; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600281.validator(path, query, header, formData, body)
  let scheme = call_600281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600281.url(scheme.get, call_600281.host, call_600281.base,
                         call_600281.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600281, url, valid)

proc call*(call_600282: Call_GetCreateDBInstanceReadReplica_600257;
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
  var query_600283 = newJObject()
  add(query_600283, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_600283, "StorageType", newJString(StorageType))
  add(query_600283, "OptionGroupName", newJString(OptionGroupName))
  add(query_600283, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600283, "Iops", newJInt(Iops))
  if Tags != nil:
    query_600283.add "Tags", Tags
  add(query_600283, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_600283, "Action", newJString(Action))
  add(query_600283, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600283, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_600283, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_600283, "Port", newJInt(Port))
  add(query_600283, "Version", newJString(Version))
  add(query_600283, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600282.call(nil, query_600283, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_600257(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_600258, base: "/",
    url: url_GetCreateDBInstanceReadReplica_600259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_600331 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBParameterGroup_600333(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_600332(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600334 = query.getOrDefault("Action")
  valid_600334 = validateParameter(valid_600334, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_600334 != nil:
    section.add "Action", valid_600334
  var valid_600335 = query.getOrDefault("Version")
  valid_600335 = validateParameter(valid_600335, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600335 != nil:
    section.add "Version", valid_600335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600336 = header.getOrDefault("X-Amz-Date")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Date", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Security-Token")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Security-Token", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Content-Sha256", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Algorithm")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Algorithm", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-Signature")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-Signature", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-SignedHeaders", valid_600341
  var valid_600342 = header.getOrDefault("X-Amz-Credential")
  valid_600342 = validateParameter(valid_600342, JString, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "X-Amz-Credential", valid_600342
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600343 = formData.getOrDefault("DBParameterGroupName")
  valid_600343 = validateParameter(valid_600343, JString, required = true,
                                 default = nil)
  if valid_600343 != nil:
    section.add "DBParameterGroupName", valid_600343
  var valid_600344 = formData.getOrDefault("Tags")
  valid_600344 = validateParameter(valid_600344, JArray, required = false,
                                 default = nil)
  if valid_600344 != nil:
    section.add "Tags", valid_600344
  var valid_600345 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600345 = validateParameter(valid_600345, JString, required = true,
                                 default = nil)
  if valid_600345 != nil:
    section.add "DBParameterGroupFamily", valid_600345
  var valid_600346 = formData.getOrDefault("Description")
  valid_600346 = validateParameter(valid_600346, JString, required = true,
                                 default = nil)
  if valid_600346 != nil:
    section.add "Description", valid_600346
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600347: Call_PostCreateDBParameterGroup_600331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600347.validator(path, query, header, formData, body)
  let scheme = call_600347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600347.url(scheme.get, call_600347.host, call_600347.base,
                         call_600347.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600347, url, valid)

proc call*(call_600348: Call_PostCreateDBParameterGroup_600331;
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
  var query_600349 = newJObject()
  var formData_600350 = newJObject()
  add(formData_600350, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_600350.add "Tags", Tags
  add(query_600349, "Action", newJString(Action))
  add(formData_600350, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_600349, "Version", newJString(Version))
  add(formData_600350, "Description", newJString(Description))
  result = call_600348.call(nil, query_600349, nil, formData_600350, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_600331(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_600332, base: "/",
    url: url_PostCreateDBParameterGroup_600333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_600312 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBParameterGroup_600314(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_600313(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600315 = query.getOrDefault("Description")
  valid_600315 = validateParameter(valid_600315, JString, required = true,
                                 default = nil)
  if valid_600315 != nil:
    section.add "Description", valid_600315
  var valid_600316 = query.getOrDefault("DBParameterGroupFamily")
  valid_600316 = validateParameter(valid_600316, JString, required = true,
                                 default = nil)
  if valid_600316 != nil:
    section.add "DBParameterGroupFamily", valid_600316
  var valid_600317 = query.getOrDefault("Tags")
  valid_600317 = validateParameter(valid_600317, JArray, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "Tags", valid_600317
  var valid_600318 = query.getOrDefault("DBParameterGroupName")
  valid_600318 = validateParameter(valid_600318, JString, required = true,
                                 default = nil)
  if valid_600318 != nil:
    section.add "DBParameterGroupName", valid_600318
  var valid_600319 = query.getOrDefault("Action")
  valid_600319 = validateParameter(valid_600319, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_600319 != nil:
    section.add "Action", valid_600319
  var valid_600320 = query.getOrDefault("Version")
  valid_600320 = validateParameter(valid_600320, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600320 != nil:
    section.add "Version", valid_600320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600321 = header.getOrDefault("X-Amz-Date")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Date", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Security-Token")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Security-Token", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Content-Sha256", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Algorithm")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Algorithm", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Signature")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Signature", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-SignedHeaders", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Credential")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Credential", valid_600327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600328: Call_GetCreateDBParameterGroup_600312; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600328.validator(path, query, header, formData, body)
  let scheme = call_600328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600328.url(scheme.get, call_600328.host, call_600328.base,
                         call_600328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600328, url, valid)

proc call*(call_600329: Call_GetCreateDBParameterGroup_600312; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600330 = newJObject()
  add(query_600330, "Description", newJString(Description))
  add(query_600330, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_600330.add "Tags", Tags
  add(query_600330, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600330, "Action", newJString(Action))
  add(query_600330, "Version", newJString(Version))
  result = call_600329.call(nil, query_600330, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_600312(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_600313, base: "/",
    url: url_GetCreateDBParameterGroup_600314,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_600369 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSecurityGroup_600371(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_600370(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600372 = query.getOrDefault("Action")
  valid_600372 = validateParameter(valid_600372, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_600372 != nil:
    section.add "Action", valid_600372
  var valid_600373 = query.getOrDefault("Version")
  valid_600373 = validateParameter(valid_600373, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600373 != nil:
    section.add "Version", valid_600373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600374 = header.getOrDefault("X-Amz-Date")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Date", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Security-Token")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Security-Token", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Content-Sha256", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Algorithm")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Algorithm", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-Signature")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-Signature", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-SignedHeaders", valid_600379
  var valid_600380 = header.getOrDefault("X-Amz-Credential")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Credential", valid_600380
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600381 = formData.getOrDefault("DBSecurityGroupName")
  valid_600381 = validateParameter(valid_600381, JString, required = true,
                                 default = nil)
  if valid_600381 != nil:
    section.add "DBSecurityGroupName", valid_600381
  var valid_600382 = formData.getOrDefault("Tags")
  valid_600382 = validateParameter(valid_600382, JArray, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "Tags", valid_600382
  var valid_600383 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_600383 = validateParameter(valid_600383, JString, required = true,
                                 default = nil)
  if valid_600383 != nil:
    section.add "DBSecurityGroupDescription", valid_600383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600384: Call_PostCreateDBSecurityGroup_600369; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600384.validator(path, query, header, formData, body)
  let scheme = call_600384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600384.url(scheme.get, call_600384.host, call_600384.base,
                         call_600384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600384, url, valid)

proc call*(call_600385: Call_PostCreateDBSecurityGroup_600369;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_600386 = newJObject()
  var formData_600387 = newJObject()
  add(formData_600387, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_600387.add "Tags", Tags
  add(query_600386, "Action", newJString(Action))
  add(formData_600387, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_600386, "Version", newJString(Version))
  result = call_600385.call(nil, query_600386, nil, formData_600387, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_600369(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_600370, base: "/",
    url: url_PostCreateDBSecurityGroup_600371,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_600351 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSecurityGroup_600353(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_600352(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600354 = query.getOrDefault("DBSecurityGroupName")
  valid_600354 = validateParameter(valid_600354, JString, required = true,
                                 default = nil)
  if valid_600354 != nil:
    section.add "DBSecurityGroupName", valid_600354
  var valid_600355 = query.getOrDefault("DBSecurityGroupDescription")
  valid_600355 = validateParameter(valid_600355, JString, required = true,
                                 default = nil)
  if valid_600355 != nil:
    section.add "DBSecurityGroupDescription", valid_600355
  var valid_600356 = query.getOrDefault("Tags")
  valid_600356 = validateParameter(valid_600356, JArray, required = false,
                                 default = nil)
  if valid_600356 != nil:
    section.add "Tags", valid_600356
  var valid_600357 = query.getOrDefault("Action")
  valid_600357 = validateParameter(valid_600357, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_600357 != nil:
    section.add "Action", valid_600357
  var valid_600358 = query.getOrDefault("Version")
  valid_600358 = validateParameter(valid_600358, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600358 != nil:
    section.add "Version", valid_600358
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600359 = header.getOrDefault("X-Amz-Date")
  valid_600359 = validateParameter(valid_600359, JString, required = false,
                                 default = nil)
  if valid_600359 != nil:
    section.add "X-Amz-Date", valid_600359
  var valid_600360 = header.getOrDefault("X-Amz-Security-Token")
  valid_600360 = validateParameter(valid_600360, JString, required = false,
                                 default = nil)
  if valid_600360 != nil:
    section.add "X-Amz-Security-Token", valid_600360
  var valid_600361 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600361 = validateParameter(valid_600361, JString, required = false,
                                 default = nil)
  if valid_600361 != nil:
    section.add "X-Amz-Content-Sha256", valid_600361
  var valid_600362 = header.getOrDefault("X-Amz-Algorithm")
  valid_600362 = validateParameter(valid_600362, JString, required = false,
                                 default = nil)
  if valid_600362 != nil:
    section.add "X-Amz-Algorithm", valid_600362
  var valid_600363 = header.getOrDefault("X-Amz-Signature")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Signature", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-SignedHeaders", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Credential")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Credential", valid_600365
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600366: Call_GetCreateDBSecurityGroup_600351; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600366.validator(path, query, header, formData, body)
  let scheme = call_600366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600366.url(scheme.get, call_600366.host, call_600366.base,
                         call_600366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600366, url, valid)

proc call*(call_600367: Call_GetCreateDBSecurityGroup_600351;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600368 = newJObject()
  add(query_600368, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600368, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_600368.add "Tags", Tags
  add(query_600368, "Action", newJString(Action))
  add(query_600368, "Version", newJString(Version))
  result = call_600367.call(nil, query_600368, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_600351(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_600352, base: "/",
    url: url_GetCreateDBSecurityGroup_600353, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_600406 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSnapshot_600408(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_600407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600409 = query.getOrDefault("Action")
  valid_600409 = validateParameter(valid_600409, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_600409 != nil:
    section.add "Action", valid_600409
  var valid_600410 = query.getOrDefault("Version")
  valid_600410 = validateParameter(valid_600410, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600410 != nil:
    section.add "Version", valid_600410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600411 = header.getOrDefault("X-Amz-Date")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Date", valid_600411
  var valid_600412 = header.getOrDefault("X-Amz-Security-Token")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Security-Token", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Content-Sha256", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Algorithm")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Algorithm", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Signature")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Signature", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-SignedHeaders", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Credential")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Credential", valid_600417
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600418 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600418 = validateParameter(valid_600418, JString, required = true,
                                 default = nil)
  if valid_600418 != nil:
    section.add "DBInstanceIdentifier", valid_600418
  var valid_600419 = formData.getOrDefault("Tags")
  valid_600419 = validateParameter(valid_600419, JArray, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "Tags", valid_600419
  var valid_600420 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600420 = validateParameter(valid_600420, JString, required = true,
                                 default = nil)
  if valid_600420 != nil:
    section.add "DBSnapshotIdentifier", valid_600420
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600421: Call_PostCreateDBSnapshot_600406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600421.validator(path, query, header, formData, body)
  let scheme = call_600421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600421.url(scheme.get, call_600421.host, call_600421.base,
                         call_600421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600421, url, valid)

proc call*(call_600422: Call_PostCreateDBSnapshot_600406;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600423 = newJObject()
  var formData_600424 = newJObject()
  add(formData_600424, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_600424.add "Tags", Tags
  add(formData_600424, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600423, "Action", newJString(Action))
  add(query_600423, "Version", newJString(Version))
  result = call_600422.call(nil, query_600423, nil, formData_600424, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_600406(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_600407, base: "/",
    url: url_PostCreateDBSnapshot_600408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_600388 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSnapshot_600390(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_600389(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600391 = query.getOrDefault("Tags")
  valid_600391 = validateParameter(valid_600391, JArray, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "Tags", valid_600391
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600392 = query.getOrDefault("Action")
  valid_600392 = validateParameter(valid_600392, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_600392 != nil:
    section.add "Action", valid_600392
  var valid_600393 = query.getOrDefault("Version")
  valid_600393 = validateParameter(valid_600393, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600393 != nil:
    section.add "Version", valid_600393
  var valid_600394 = query.getOrDefault("DBInstanceIdentifier")
  valid_600394 = validateParameter(valid_600394, JString, required = true,
                                 default = nil)
  if valid_600394 != nil:
    section.add "DBInstanceIdentifier", valid_600394
  var valid_600395 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600395 = validateParameter(valid_600395, JString, required = true,
                                 default = nil)
  if valid_600395 != nil:
    section.add "DBSnapshotIdentifier", valid_600395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600396 = header.getOrDefault("X-Amz-Date")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Date", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Security-Token")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Security-Token", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Content-Sha256", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Algorithm")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Algorithm", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-Signature")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-Signature", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-SignedHeaders", valid_600401
  var valid_600402 = header.getOrDefault("X-Amz-Credential")
  valid_600402 = validateParameter(valid_600402, JString, required = false,
                                 default = nil)
  if valid_600402 != nil:
    section.add "X-Amz-Credential", valid_600402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600403: Call_GetCreateDBSnapshot_600388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600403.validator(path, query, header, formData, body)
  let scheme = call_600403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600403.url(scheme.get, call_600403.host, call_600403.base,
                         call_600403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600403, url, valid)

proc call*(call_600404: Call_GetCreateDBSnapshot_600388;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_600405 = newJObject()
  if Tags != nil:
    query_600405.add "Tags", Tags
  add(query_600405, "Action", newJString(Action))
  add(query_600405, "Version", newJString(Version))
  add(query_600405, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600405, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600404.call(nil, query_600405, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_600388(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_600389, base: "/",
    url: url_GetCreateDBSnapshot_600390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_600444 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSubnetGroup_600446(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_600445(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600447 = query.getOrDefault("Action")
  valid_600447 = validateParameter(valid_600447, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600447 != nil:
    section.add "Action", valid_600447
  var valid_600448 = query.getOrDefault("Version")
  valid_600448 = validateParameter(valid_600448, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600448 != nil:
    section.add "Version", valid_600448
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600449 = header.getOrDefault("X-Amz-Date")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Date", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Security-Token")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Security-Token", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Content-Sha256", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Algorithm")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Algorithm", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Signature")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Signature", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-SignedHeaders", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Credential")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Credential", valid_600455
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_600456 = formData.getOrDefault("Tags")
  valid_600456 = validateParameter(valid_600456, JArray, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "Tags", valid_600456
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600457 = formData.getOrDefault("DBSubnetGroupName")
  valid_600457 = validateParameter(valid_600457, JString, required = true,
                                 default = nil)
  if valid_600457 != nil:
    section.add "DBSubnetGroupName", valid_600457
  var valid_600458 = formData.getOrDefault("SubnetIds")
  valid_600458 = validateParameter(valid_600458, JArray, required = true, default = nil)
  if valid_600458 != nil:
    section.add "SubnetIds", valid_600458
  var valid_600459 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_600459 = validateParameter(valid_600459, JString, required = true,
                                 default = nil)
  if valid_600459 != nil:
    section.add "DBSubnetGroupDescription", valid_600459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600460: Call_PostCreateDBSubnetGroup_600444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600460.validator(path, query, header, formData, body)
  let scheme = call_600460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600460.url(scheme.get, call_600460.host, call_600460.base,
                         call_600460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600460, url, valid)

proc call*(call_600461: Call_PostCreateDBSubnetGroup_600444;
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
  var query_600462 = newJObject()
  var formData_600463 = newJObject()
  if Tags != nil:
    formData_600463.add "Tags", Tags
  add(formData_600463, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_600463.add "SubnetIds", SubnetIds
  add(query_600462, "Action", newJString(Action))
  add(formData_600463, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600462, "Version", newJString(Version))
  result = call_600461.call(nil, query_600462, nil, formData_600463, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_600444(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_600445, base: "/",
    url: url_PostCreateDBSubnetGroup_600446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_600425 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSubnetGroup_600427(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_600426(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600428 = query.getOrDefault("Tags")
  valid_600428 = validateParameter(valid_600428, JArray, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "Tags", valid_600428
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600429 = query.getOrDefault("Action")
  valid_600429 = validateParameter(valid_600429, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600429 != nil:
    section.add "Action", valid_600429
  var valid_600430 = query.getOrDefault("DBSubnetGroupName")
  valid_600430 = validateParameter(valid_600430, JString, required = true,
                                 default = nil)
  if valid_600430 != nil:
    section.add "DBSubnetGroupName", valid_600430
  var valid_600431 = query.getOrDefault("SubnetIds")
  valid_600431 = validateParameter(valid_600431, JArray, required = true, default = nil)
  if valid_600431 != nil:
    section.add "SubnetIds", valid_600431
  var valid_600432 = query.getOrDefault("DBSubnetGroupDescription")
  valid_600432 = validateParameter(valid_600432, JString, required = true,
                                 default = nil)
  if valid_600432 != nil:
    section.add "DBSubnetGroupDescription", valid_600432
  var valid_600433 = query.getOrDefault("Version")
  valid_600433 = validateParameter(valid_600433, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600433 != nil:
    section.add "Version", valid_600433
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600434 = header.getOrDefault("X-Amz-Date")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Date", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Security-Token")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Security-Token", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Content-Sha256", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Algorithm")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Algorithm", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-Signature")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-Signature", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-SignedHeaders", valid_600439
  var valid_600440 = header.getOrDefault("X-Amz-Credential")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Credential", valid_600440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600441: Call_GetCreateDBSubnetGroup_600425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600441.validator(path, query, header, formData, body)
  let scheme = call_600441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600441.url(scheme.get, call_600441.host, call_600441.base,
                         call_600441.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600441, url, valid)

proc call*(call_600442: Call_GetCreateDBSubnetGroup_600425;
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
  var query_600443 = newJObject()
  if Tags != nil:
    query_600443.add "Tags", Tags
  add(query_600443, "Action", newJString(Action))
  add(query_600443, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_600443.add "SubnetIds", SubnetIds
  add(query_600443, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600443, "Version", newJString(Version))
  result = call_600442.call(nil, query_600443, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_600425(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_600426, base: "/",
    url: url_GetCreateDBSubnetGroup_600427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_600486 = ref object of OpenApiRestCall_599352
proc url_PostCreateEventSubscription_600488(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_600487(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600489 = query.getOrDefault("Action")
  valid_600489 = validateParameter(valid_600489, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_600489 != nil:
    section.add "Action", valid_600489
  var valid_600490 = query.getOrDefault("Version")
  valid_600490 = validateParameter(valid_600490, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600490 != nil:
    section.add "Version", valid_600490
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600491 = header.getOrDefault("X-Amz-Date")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Date", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Security-Token")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Security-Token", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Content-Sha256", valid_600493
  var valid_600494 = header.getOrDefault("X-Amz-Algorithm")
  valid_600494 = validateParameter(valid_600494, JString, required = false,
                                 default = nil)
  if valid_600494 != nil:
    section.add "X-Amz-Algorithm", valid_600494
  var valid_600495 = header.getOrDefault("X-Amz-Signature")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "X-Amz-Signature", valid_600495
  var valid_600496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600496 = validateParameter(valid_600496, JString, required = false,
                                 default = nil)
  if valid_600496 != nil:
    section.add "X-Amz-SignedHeaders", valid_600496
  var valid_600497 = header.getOrDefault("X-Amz-Credential")
  valid_600497 = validateParameter(valid_600497, JString, required = false,
                                 default = nil)
  if valid_600497 != nil:
    section.add "X-Amz-Credential", valid_600497
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
  var valid_600498 = formData.getOrDefault("Enabled")
  valid_600498 = validateParameter(valid_600498, JBool, required = false, default = nil)
  if valid_600498 != nil:
    section.add "Enabled", valid_600498
  var valid_600499 = formData.getOrDefault("EventCategories")
  valid_600499 = validateParameter(valid_600499, JArray, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "EventCategories", valid_600499
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_600500 = formData.getOrDefault("SnsTopicArn")
  valid_600500 = validateParameter(valid_600500, JString, required = true,
                                 default = nil)
  if valid_600500 != nil:
    section.add "SnsTopicArn", valid_600500
  var valid_600501 = formData.getOrDefault("SourceIds")
  valid_600501 = validateParameter(valid_600501, JArray, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "SourceIds", valid_600501
  var valid_600502 = formData.getOrDefault("Tags")
  valid_600502 = validateParameter(valid_600502, JArray, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "Tags", valid_600502
  var valid_600503 = formData.getOrDefault("SubscriptionName")
  valid_600503 = validateParameter(valid_600503, JString, required = true,
                                 default = nil)
  if valid_600503 != nil:
    section.add "SubscriptionName", valid_600503
  var valid_600504 = formData.getOrDefault("SourceType")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "SourceType", valid_600504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600505: Call_PostCreateEventSubscription_600486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600505.validator(path, query, header, formData, body)
  let scheme = call_600505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600505.url(scheme.get, call_600505.host, call_600505.base,
                         call_600505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600505, url, valid)

proc call*(call_600506: Call_PostCreateEventSubscription_600486;
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
  var query_600507 = newJObject()
  var formData_600508 = newJObject()
  add(formData_600508, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_600508.add "EventCategories", EventCategories
  add(formData_600508, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_600508.add "SourceIds", SourceIds
  if Tags != nil:
    formData_600508.add "Tags", Tags
  add(formData_600508, "SubscriptionName", newJString(SubscriptionName))
  add(query_600507, "Action", newJString(Action))
  add(query_600507, "Version", newJString(Version))
  add(formData_600508, "SourceType", newJString(SourceType))
  result = call_600506.call(nil, query_600507, nil, formData_600508, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_600486(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_600487, base: "/",
    url: url_PostCreateEventSubscription_600488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_600464 = ref object of OpenApiRestCall_599352
proc url_GetCreateEventSubscription_600466(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_600465(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600467 = query.getOrDefault("SourceType")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "SourceType", valid_600467
  var valid_600468 = query.getOrDefault("SourceIds")
  valid_600468 = validateParameter(valid_600468, JArray, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "SourceIds", valid_600468
  var valid_600469 = query.getOrDefault("Enabled")
  valid_600469 = validateParameter(valid_600469, JBool, required = false, default = nil)
  if valid_600469 != nil:
    section.add "Enabled", valid_600469
  var valid_600470 = query.getOrDefault("Tags")
  valid_600470 = validateParameter(valid_600470, JArray, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "Tags", valid_600470
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600471 = query.getOrDefault("Action")
  valid_600471 = validateParameter(valid_600471, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_600471 != nil:
    section.add "Action", valid_600471
  var valid_600472 = query.getOrDefault("SnsTopicArn")
  valid_600472 = validateParameter(valid_600472, JString, required = true,
                                 default = nil)
  if valid_600472 != nil:
    section.add "SnsTopicArn", valid_600472
  var valid_600473 = query.getOrDefault("EventCategories")
  valid_600473 = validateParameter(valid_600473, JArray, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "EventCategories", valid_600473
  var valid_600474 = query.getOrDefault("SubscriptionName")
  valid_600474 = validateParameter(valid_600474, JString, required = true,
                                 default = nil)
  if valid_600474 != nil:
    section.add "SubscriptionName", valid_600474
  var valid_600475 = query.getOrDefault("Version")
  valid_600475 = validateParameter(valid_600475, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600475 != nil:
    section.add "Version", valid_600475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600476 = header.getOrDefault("X-Amz-Date")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Date", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Security-Token")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Security-Token", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Content-Sha256", valid_600478
  var valid_600479 = header.getOrDefault("X-Amz-Algorithm")
  valid_600479 = validateParameter(valid_600479, JString, required = false,
                                 default = nil)
  if valid_600479 != nil:
    section.add "X-Amz-Algorithm", valid_600479
  var valid_600480 = header.getOrDefault("X-Amz-Signature")
  valid_600480 = validateParameter(valid_600480, JString, required = false,
                                 default = nil)
  if valid_600480 != nil:
    section.add "X-Amz-Signature", valid_600480
  var valid_600481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600481 = validateParameter(valid_600481, JString, required = false,
                                 default = nil)
  if valid_600481 != nil:
    section.add "X-Amz-SignedHeaders", valid_600481
  var valid_600482 = header.getOrDefault("X-Amz-Credential")
  valid_600482 = validateParameter(valid_600482, JString, required = false,
                                 default = nil)
  if valid_600482 != nil:
    section.add "X-Amz-Credential", valid_600482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600483: Call_GetCreateEventSubscription_600464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600483.validator(path, query, header, formData, body)
  let scheme = call_600483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600483.url(scheme.get, call_600483.host, call_600483.base,
                         call_600483.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600483, url, valid)

proc call*(call_600484: Call_GetCreateEventSubscription_600464;
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
  var query_600485 = newJObject()
  add(query_600485, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_600485.add "SourceIds", SourceIds
  add(query_600485, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_600485.add "Tags", Tags
  add(query_600485, "Action", newJString(Action))
  add(query_600485, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_600485.add "EventCategories", EventCategories
  add(query_600485, "SubscriptionName", newJString(SubscriptionName))
  add(query_600485, "Version", newJString(Version))
  result = call_600484.call(nil, query_600485, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_600464(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_600465, base: "/",
    url: url_GetCreateEventSubscription_600466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_600529 = ref object of OpenApiRestCall_599352
proc url_PostCreateOptionGroup_600531(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_600530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600532 = query.getOrDefault("Action")
  valid_600532 = validateParameter(valid_600532, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_600532 != nil:
    section.add "Action", valid_600532
  var valid_600533 = query.getOrDefault("Version")
  valid_600533 = validateParameter(valid_600533, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600533 != nil:
    section.add "Version", valid_600533
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600534 = header.getOrDefault("X-Amz-Date")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "X-Amz-Date", valid_600534
  var valid_600535 = header.getOrDefault("X-Amz-Security-Token")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Security-Token", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Content-Sha256", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Algorithm")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Algorithm", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Signature")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Signature", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-SignedHeaders", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Credential")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Credential", valid_600540
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_600541 = formData.getOrDefault("MajorEngineVersion")
  valid_600541 = validateParameter(valid_600541, JString, required = true,
                                 default = nil)
  if valid_600541 != nil:
    section.add "MajorEngineVersion", valid_600541
  var valid_600542 = formData.getOrDefault("OptionGroupName")
  valid_600542 = validateParameter(valid_600542, JString, required = true,
                                 default = nil)
  if valid_600542 != nil:
    section.add "OptionGroupName", valid_600542
  var valid_600543 = formData.getOrDefault("Tags")
  valid_600543 = validateParameter(valid_600543, JArray, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "Tags", valid_600543
  var valid_600544 = formData.getOrDefault("EngineName")
  valid_600544 = validateParameter(valid_600544, JString, required = true,
                                 default = nil)
  if valid_600544 != nil:
    section.add "EngineName", valid_600544
  var valid_600545 = formData.getOrDefault("OptionGroupDescription")
  valid_600545 = validateParameter(valid_600545, JString, required = true,
                                 default = nil)
  if valid_600545 != nil:
    section.add "OptionGroupDescription", valid_600545
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600546: Call_PostCreateOptionGroup_600529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600546.validator(path, query, header, formData, body)
  let scheme = call_600546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600546.url(scheme.get, call_600546.host, call_600546.base,
                         call_600546.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600546, url, valid)

proc call*(call_600547: Call_PostCreateOptionGroup_600529;
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
  var query_600548 = newJObject()
  var formData_600549 = newJObject()
  add(formData_600549, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_600549, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_600549.add "Tags", Tags
  add(query_600548, "Action", newJString(Action))
  add(formData_600549, "EngineName", newJString(EngineName))
  add(formData_600549, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_600548, "Version", newJString(Version))
  result = call_600547.call(nil, query_600548, nil, formData_600549, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_600529(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_600530, base: "/",
    url: url_PostCreateOptionGroup_600531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_600509 = ref object of OpenApiRestCall_599352
proc url_GetCreateOptionGroup_600511(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_600510(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600512 = query.getOrDefault("OptionGroupName")
  valid_600512 = validateParameter(valid_600512, JString, required = true,
                                 default = nil)
  if valid_600512 != nil:
    section.add "OptionGroupName", valid_600512
  var valid_600513 = query.getOrDefault("Tags")
  valid_600513 = validateParameter(valid_600513, JArray, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "Tags", valid_600513
  var valid_600514 = query.getOrDefault("OptionGroupDescription")
  valid_600514 = validateParameter(valid_600514, JString, required = true,
                                 default = nil)
  if valid_600514 != nil:
    section.add "OptionGroupDescription", valid_600514
  var valid_600515 = query.getOrDefault("Action")
  valid_600515 = validateParameter(valid_600515, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_600515 != nil:
    section.add "Action", valid_600515
  var valid_600516 = query.getOrDefault("Version")
  valid_600516 = validateParameter(valid_600516, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600516 != nil:
    section.add "Version", valid_600516
  var valid_600517 = query.getOrDefault("EngineName")
  valid_600517 = validateParameter(valid_600517, JString, required = true,
                                 default = nil)
  if valid_600517 != nil:
    section.add "EngineName", valid_600517
  var valid_600518 = query.getOrDefault("MajorEngineVersion")
  valid_600518 = validateParameter(valid_600518, JString, required = true,
                                 default = nil)
  if valid_600518 != nil:
    section.add "MajorEngineVersion", valid_600518
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600519 = header.getOrDefault("X-Amz-Date")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Date", valid_600519
  var valid_600520 = header.getOrDefault("X-Amz-Security-Token")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Security-Token", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Content-Sha256", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Algorithm")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Algorithm", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Signature")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Signature", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-SignedHeaders", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Credential")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Credential", valid_600525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600526: Call_GetCreateOptionGroup_600509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600526.validator(path, query, header, formData, body)
  let scheme = call_600526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600526.url(scheme.get, call_600526.host, call_600526.base,
                         call_600526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600526, url, valid)

proc call*(call_600527: Call_GetCreateOptionGroup_600509; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_600528 = newJObject()
  add(query_600528, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_600528.add "Tags", Tags
  add(query_600528, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_600528, "Action", newJString(Action))
  add(query_600528, "Version", newJString(Version))
  add(query_600528, "EngineName", newJString(EngineName))
  add(query_600528, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_600527.call(nil, query_600528, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_600509(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_600510, base: "/",
    url: url_GetCreateOptionGroup_600511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_600568 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBInstance_600570(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_600569(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600571 = query.getOrDefault("Action")
  valid_600571 = validateParameter(valid_600571, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600571 != nil:
    section.add "Action", valid_600571
  var valid_600572 = query.getOrDefault("Version")
  valid_600572 = validateParameter(valid_600572, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600572 != nil:
    section.add "Version", valid_600572
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600573 = header.getOrDefault("X-Amz-Date")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-Date", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Security-Token")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Security-Token", valid_600574
  var valid_600575 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600575 = validateParameter(valid_600575, JString, required = false,
                                 default = nil)
  if valid_600575 != nil:
    section.add "X-Amz-Content-Sha256", valid_600575
  var valid_600576 = header.getOrDefault("X-Amz-Algorithm")
  valid_600576 = validateParameter(valid_600576, JString, required = false,
                                 default = nil)
  if valid_600576 != nil:
    section.add "X-Amz-Algorithm", valid_600576
  var valid_600577 = header.getOrDefault("X-Amz-Signature")
  valid_600577 = validateParameter(valid_600577, JString, required = false,
                                 default = nil)
  if valid_600577 != nil:
    section.add "X-Amz-Signature", valid_600577
  var valid_600578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600578 = validateParameter(valid_600578, JString, required = false,
                                 default = nil)
  if valid_600578 != nil:
    section.add "X-Amz-SignedHeaders", valid_600578
  var valid_600579 = header.getOrDefault("X-Amz-Credential")
  valid_600579 = validateParameter(valid_600579, JString, required = false,
                                 default = nil)
  if valid_600579 != nil:
    section.add "X-Amz-Credential", valid_600579
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600580 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600580 = validateParameter(valid_600580, JString, required = true,
                                 default = nil)
  if valid_600580 != nil:
    section.add "DBInstanceIdentifier", valid_600580
  var valid_600581 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600581 = validateParameter(valid_600581, JString, required = false,
                                 default = nil)
  if valid_600581 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600581
  var valid_600582 = formData.getOrDefault("SkipFinalSnapshot")
  valid_600582 = validateParameter(valid_600582, JBool, required = false, default = nil)
  if valid_600582 != nil:
    section.add "SkipFinalSnapshot", valid_600582
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600583: Call_PostDeleteDBInstance_600568; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600583.validator(path, query, header, formData, body)
  let scheme = call_600583.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600583.url(scheme.get, call_600583.host, call_600583.base,
                         call_600583.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600583, url, valid)

proc call*(call_600584: Call_PostDeleteDBInstance_600568;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_600585 = newJObject()
  var formData_600586 = newJObject()
  add(formData_600586, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600586, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600585, "Action", newJString(Action))
  add(query_600585, "Version", newJString(Version))
  add(formData_600586, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_600584.call(nil, query_600585, nil, formData_600586, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_600568(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_600569, base: "/",
    url: url_PostDeleteDBInstance_600570, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_600550 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBInstance_600552(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_600551(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600553 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600553
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600554 = query.getOrDefault("Action")
  valid_600554 = validateParameter(valid_600554, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600554 != nil:
    section.add "Action", valid_600554
  var valid_600555 = query.getOrDefault("SkipFinalSnapshot")
  valid_600555 = validateParameter(valid_600555, JBool, required = false, default = nil)
  if valid_600555 != nil:
    section.add "SkipFinalSnapshot", valid_600555
  var valid_600556 = query.getOrDefault("Version")
  valid_600556 = validateParameter(valid_600556, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600556 != nil:
    section.add "Version", valid_600556
  var valid_600557 = query.getOrDefault("DBInstanceIdentifier")
  valid_600557 = validateParameter(valid_600557, JString, required = true,
                                 default = nil)
  if valid_600557 != nil:
    section.add "DBInstanceIdentifier", valid_600557
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600558 = header.getOrDefault("X-Amz-Date")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Date", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Security-Token")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Security-Token", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-Content-Sha256", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Algorithm")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Algorithm", valid_600561
  var valid_600562 = header.getOrDefault("X-Amz-Signature")
  valid_600562 = validateParameter(valid_600562, JString, required = false,
                                 default = nil)
  if valid_600562 != nil:
    section.add "X-Amz-Signature", valid_600562
  var valid_600563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600563 = validateParameter(valid_600563, JString, required = false,
                                 default = nil)
  if valid_600563 != nil:
    section.add "X-Amz-SignedHeaders", valid_600563
  var valid_600564 = header.getOrDefault("X-Amz-Credential")
  valid_600564 = validateParameter(valid_600564, JString, required = false,
                                 default = nil)
  if valid_600564 != nil:
    section.add "X-Amz-Credential", valid_600564
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600565: Call_GetDeleteDBInstance_600550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600565.validator(path, query, header, formData, body)
  let scheme = call_600565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600565.url(scheme.get, call_600565.host, call_600565.base,
                         call_600565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600565, url, valid)

proc call*(call_600566: Call_GetDeleteDBInstance_600550;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_600567 = newJObject()
  add(query_600567, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600567, "Action", newJString(Action))
  add(query_600567, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_600567, "Version", newJString(Version))
  add(query_600567, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600566.call(nil, query_600567, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_600550(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_600551, base: "/",
    url: url_GetDeleteDBInstance_600552, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_600603 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBParameterGroup_600605(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_600604(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600606 = query.getOrDefault("Action")
  valid_600606 = validateParameter(valid_600606, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_600606 != nil:
    section.add "Action", valid_600606
  var valid_600607 = query.getOrDefault("Version")
  valid_600607 = validateParameter(valid_600607, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600607 != nil:
    section.add "Version", valid_600607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600608 = header.getOrDefault("X-Amz-Date")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Date", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Security-Token")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Security-Token", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Content-Sha256", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Algorithm")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Algorithm", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Signature")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Signature", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-SignedHeaders", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Credential")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Credential", valid_600614
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600615 = formData.getOrDefault("DBParameterGroupName")
  valid_600615 = validateParameter(valid_600615, JString, required = true,
                                 default = nil)
  if valid_600615 != nil:
    section.add "DBParameterGroupName", valid_600615
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600616: Call_PostDeleteDBParameterGroup_600603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600616.validator(path, query, header, formData, body)
  let scheme = call_600616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600616.url(scheme.get, call_600616.host, call_600616.base,
                         call_600616.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600616, url, valid)

proc call*(call_600617: Call_PostDeleteDBParameterGroup_600603;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600618 = newJObject()
  var formData_600619 = newJObject()
  add(formData_600619, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600618, "Action", newJString(Action))
  add(query_600618, "Version", newJString(Version))
  result = call_600617.call(nil, query_600618, nil, formData_600619, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_600603(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_600604, base: "/",
    url: url_PostDeleteDBParameterGroup_600605,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_600587 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBParameterGroup_600589(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_600588(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600590 = query.getOrDefault("DBParameterGroupName")
  valid_600590 = validateParameter(valid_600590, JString, required = true,
                                 default = nil)
  if valid_600590 != nil:
    section.add "DBParameterGroupName", valid_600590
  var valid_600591 = query.getOrDefault("Action")
  valid_600591 = validateParameter(valid_600591, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_600591 != nil:
    section.add "Action", valid_600591
  var valid_600592 = query.getOrDefault("Version")
  valid_600592 = validateParameter(valid_600592, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600592 != nil:
    section.add "Version", valid_600592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600593 = header.getOrDefault("X-Amz-Date")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-Date", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Security-Token")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Security-Token", valid_600594
  var valid_600595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600595 = validateParameter(valid_600595, JString, required = false,
                                 default = nil)
  if valid_600595 != nil:
    section.add "X-Amz-Content-Sha256", valid_600595
  var valid_600596 = header.getOrDefault("X-Amz-Algorithm")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Algorithm", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Signature")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Signature", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-SignedHeaders", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Credential")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Credential", valid_600599
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600600: Call_GetDeleteDBParameterGroup_600587; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600600.validator(path, query, header, formData, body)
  let scheme = call_600600.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600600.url(scheme.get, call_600600.host, call_600600.base,
                         call_600600.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600600, url, valid)

proc call*(call_600601: Call_GetDeleteDBParameterGroup_600587;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600602 = newJObject()
  add(query_600602, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600602, "Action", newJString(Action))
  add(query_600602, "Version", newJString(Version))
  result = call_600601.call(nil, query_600602, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_600587(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_600588, base: "/",
    url: url_GetDeleteDBParameterGroup_600589,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_600636 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSecurityGroup_600638(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_600637(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600639 = query.getOrDefault("Action")
  valid_600639 = validateParameter(valid_600639, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_600639 != nil:
    section.add "Action", valid_600639
  var valid_600640 = query.getOrDefault("Version")
  valid_600640 = validateParameter(valid_600640, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600640 != nil:
    section.add "Version", valid_600640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600641 = header.getOrDefault("X-Amz-Date")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Date", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Security-Token")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Security-Token", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Content-Sha256", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-Algorithm")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-Algorithm", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Signature")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Signature", valid_600645
  var valid_600646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600646 = validateParameter(valid_600646, JString, required = false,
                                 default = nil)
  if valid_600646 != nil:
    section.add "X-Amz-SignedHeaders", valid_600646
  var valid_600647 = header.getOrDefault("X-Amz-Credential")
  valid_600647 = validateParameter(valid_600647, JString, required = false,
                                 default = nil)
  if valid_600647 != nil:
    section.add "X-Amz-Credential", valid_600647
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600648 = formData.getOrDefault("DBSecurityGroupName")
  valid_600648 = validateParameter(valid_600648, JString, required = true,
                                 default = nil)
  if valid_600648 != nil:
    section.add "DBSecurityGroupName", valid_600648
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600649: Call_PostDeleteDBSecurityGroup_600636; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600649.validator(path, query, header, formData, body)
  let scheme = call_600649.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600649.url(scheme.get, call_600649.host, call_600649.base,
                         call_600649.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600649, url, valid)

proc call*(call_600650: Call_PostDeleteDBSecurityGroup_600636;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600651 = newJObject()
  var formData_600652 = newJObject()
  add(formData_600652, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600651, "Action", newJString(Action))
  add(query_600651, "Version", newJString(Version))
  result = call_600650.call(nil, query_600651, nil, formData_600652, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_600636(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_600637, base: "/",
    url: url_PostDeleteDBSecurityGroup_600638,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_600620 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSecurityGroup_600622(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_600621(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600623 = query.getOrDefault("DBSecurityGroupName")
  valid_600623 = validateParameter(valid_600623, JString, required = true,
                                 default = nil)
  if valid_600623 != nil:
    section.add "DBSecurityGroupName", valid_600623
  var valid_600624 = query.getOrDefault("Action")
  valid_600624 = validateParameter(valid_600624, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_600624 != nil:
    section.add "Action", valid_600624
  var valid_600625 = query.getOrDefault("Version")
  valid_600625 = validateParameter(valid_600625, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600625 != nil:
    section.add "Version", valid_600625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600626 = header.getOrDefault("X-Amz-Date")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Date", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Security-Token")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Security-Token", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Content-Sha256", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-Algorithm")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-Algorithm", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Signature")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Signature", valid_600630
  var valid_600631 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600631 = validateParameter(valid_600631, JString, required = false,
                                 default = nil)
  if valid_600631 != nil:
    section.add "X-Amz-SignedHeaders", valid_600631
  var valid_600632 = header.getOrDefault("X-Amz-Credential")
  valid_600632 = validateParameter(valid_600632, JString, required = false,
                                 default = nil)
  if valid_600632 != nil:
    section.add "X-Amz-Credential", valid_600632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600633: Call_GetDeleteDBSecurityGroup_600620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600633.validator(path, query, header, formData, body)
  let scheme = call_600633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600633.url(scheme.get, call_600633.host, call_600633.base,
                         call_600633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600633, url, valid)

proc call*(call_600634: Call_GetDeleteDBSecurityGroup_600620;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600635 = newJObject()
  add(query_600635, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600635, "Action", newJString(Action))
  add(query_600635, "Version", newJString(Version))
  result = call_600634.call(nil, query_600635, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_600620(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_600621, base: "/",
    url: url_GetDeleteDBSecurityGroup_600622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_600669 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSnapshot_600671(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_600670(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600672 = query.getOrDefault("Action")
  valid_600672 = validateParameter(valid_600672, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_600672 != nil:
    section.add "Action", valid_600672
  var valid_600673 = query.getOrDefault("Version")
  valid_600673 = validateParameter(valid_600673, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600673 != nil:
    section.add "Version", valid_600673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600674 = header.getOrDefault("X-Amz-Date")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Date", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Security-Token")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Security-Token", valid_600675
  var valid_600676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Content-Sha256", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-Algorithm")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-Algorithm", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Signature")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Signature", valid_600678
  var valid_600679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600679 = validateParameter(valid_600679, JString, required = false,
                                 default = nil)
  if valid_600679 != nil:
    section.add "X-Amz-SignedHeaders", valid_600679
  var valid_600680 = header.getOrDefault("X-Amz-Credential")
  valid_600680 = validateParameter(valid_600680, JString, required = false,
                                 default = nil)
  if valid_600680 != nil:
    section.add "X-Amz-Credential", valid_600680
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_600681 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600681 = validateParameter(valid_600681, JString, required = true,
                                 default = nil)
  if valid_600681 != nil:
    section.add "DBSnapshotIdentifier", valid_600681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600682: Call_PostDeleteDBSnapshot_600669; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600682.validator(path, query, header, formData, body)
  let scheme = call_600682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600682.url(scheme.get, call_600682.host, call_600682.base,
                         call_600682.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600682, url, valid)

proc call*(call_600683: Call_PostDeleteDBSnapshot_600669;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600684 = newJObject()
  var formData_600685 = newJObject()
  add(formData_600685, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600684, "Action", newJString(Action))
  add(query_600684, "Version", newJString(Version))
  result = call_600683.call(nil, query_600684, nil, formData_600685, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_600669(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_600670, base: "/",
    url: url_PostDeleteDBSnapshot_600671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_600653 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSnapshot_600655(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_600654(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600656 = query.getOrDefault("Action")
  valid_600656 = validateParameter(valid_600656, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_600656 != nil:
    section.add "Action", valid_600656
  var valid_600657 = query.getOrDefault("Version")
  valid_600657 = validateParameter(valid_600657, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600657 != nil:
    section.add "Version", valid_600657
  var valid_600658 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600658 = validateParameter(valid_600658, JString, required = true,
                                 default = nil)
  if valid_600658 != nil:
    section.add "DBSnapshotIdentifier", valid_600658
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600659 = header.getOrDefault("X-Amz-Date")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-Date", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-Security-Token")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-Security-Token", valid_600660
  var valid_600661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600661 = validateParameter(valid_600661, JString, required = false,
                                 default = nil)
  if valid_600661 != nil:
    section.add "X-Amz-Content-Sha256", valid_600661
  var valid_600662 = header.getOrDefault("X-Amz-Algorithm")
  valid_600662 = validateParameter(valid_600662, JString, required = false,
                                 default = nil)
  if valid_600662 != nil:
    section.add "X-Amz-Algorithm", valid_600662
  var valid_600663 = header.getOrDefault("X-Amz-Signature")
  valid_600663 = validateParameter(valid_600663, JString, required = false,
                                 default = nil)
  if valid_600663 != nil:
    section.add "X-Amz-Signature", valid_600663
  var valid_600664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600664 = validateParameter(valid_600664, JString, required = false,
                                 default = nil)
  if valid_600664 != nil:
    section.add "X-Amz-SignedHeaders", valid_600664
  var valid_600665 = header.getOrDefault("X-Amz-Credential")
  valid_600665 = validateParameter(valid_600665, JString, required = false,
                                 default = nil)
  if valid_600665 != nil:
    section.add "X-Amz-Credential", valid_600665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600666: Call_GetDeleteDBSnapshot_600653; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600666.validator(path, query, header, formData, body)
  let scheme = call_600666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600666.url(scheme.get, call_600666.host, call_600666.base,
                         call_600666.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600666, url, valid)

proc call*(call_600667: Call_GetDeleteDBSnapshot_600653;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_600668 = newJObject()
  add(query_600668, "Action", newJString(Action))
  add(query_600668, "Version", newJString(Version))
  add(query_600668, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600667.call(nil, query_600668, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_600653(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_600654, base: "/",
    url: url_GetDeleteDBSnapshot_600655, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_600702 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSubnetGroup_600704(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_600703(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600705 = query.getOrDefault("Action")
  valid_600705 = validateParameter(valid_600705, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600705 != nil:
    section.add "Action", valid_600705
  var valid_600706 = query.getOrDefault("Version")
  valid_600706 = validateParameter(valid_600706, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600706 != nil:
    section.add "Version", valid_600706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600707 = header.getOrDefault("X-Amz-Date")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Date", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-Security-Token")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Security-Token", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Content-Sha256", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-Algorithm")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-Algorithm", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-Signature")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-Signature", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-SignedHeaders", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Credential")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Credential", valid_600713
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600714 = formData.getOrDefault("DBSubnetGroupName")
  valid_600714 = validateParameter(valid_600714, JString, required = true,
                                 default = nil)
  if valid_600714 != nil:
    section.add "DBSubnetGroupName", valid_600714
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600715: Call_PostDeleteDBSubnetGroup_600702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600715.validator(path, query, header, formData, body)
  let scheme = call_600715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600715.url(scheme.get, call_600715.host, call_600715.base,
                         call_600715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600715, url, valid)

proc call*(call_600716: Call_PostDeleteDBSubnetGroup_600702;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600717 = newJObject()
  var formData_600718 = newJObject()
  add(formData_600718, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600717, "Action", newJString(Action))
  add(query_600717, "Version", newJString(Version))
  result = call_600716.call(nil, query_600717, nil, formData_600718, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_600702(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_600703, base: "/",
    url: url_PostDeleteDBSubnetGroup_600704, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_600686 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSubnetGroup_600688(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_600687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600689 = query.getOrDefault("Action")
  valid_600689 = validateParameter(valid_600689, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600689 != nil:
    section.add "Action", valid_600689
  var valid_600690 = query.getOrDefault("DBSubnetGroupName")
  valid_600690 = validateParameter(valid_600690, JString, required = true,
                                 default = nil)
  if valid_600690 != nil:
    section.add "DBSubnetGroupName", valid_600690
  var valid_600691 = query.getOrDefault("Version")
  valid_600691 = validateParameter(valid_600691, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600691 != nil:
    section.add "Version", valid_600691
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600692 = header.getOrDefault("X-Amz-Date")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Date", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Security-Token")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Security-Token", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Content-Sha256", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-Algorithm")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Algorithm", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-Signature")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-Signature", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-SignedHeaders", valid_600697
  var valid_600698 = header.getOrDefault("X-Amz-Credential")
  valid_600698 = validateParameter(valid_600698, JString, required = false,
                                 default = nil)
  if valid_600698 != nil:
    section.add "X-Amz-Credential", valid_600698
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600699: Call_GetDeleteDBSubnetGroup_600686; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600699.validator(path, query, header, formData, body)
  let scheme = call_600699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600699.url(scheme.get, call_600699.host, call_600699.base,
                         call_600699.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600699, url, valid)

proc call*(call_600700: Call_GetDeleteDBSubnetGroup_600686;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_600701 = newJObject()
  add(query_600701, "Action", newJString(Action))
  add(query_600701, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600701, "Version", newJString(Version))
  result = call_600700.call(nil, query_600701, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_600686(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_600687, base: "/",
    url: url_GetDeleteDBSubnetGroup_600688, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_600735 = ref object of OpenApiRestCall_599352
proc url_PostDeleteEventSubscription_600737(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_600736(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600738 = query.getOrDefault("Action")
  valid_600738 = validateParameter(valid_600738, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_600738 != nil:
    section.add "Action", valid_600738
  var valid_600739 = query.getOrDefault("Version")
  valid_600739 = validateParameter(valid_600739, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600739 != nil:
    section.add "Version", valid_600739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600740 = header.getOrDefault("X-Amz-Date")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "X-Amz-Date", valid_600740
  var valid_600741 = header.getOrDefault("X-Amz-Security-Token")
  valid_600741 = validateParameter(valid_600741, JString, required = false,
                                 default = nil)
  if valid_600741 != nil:
    section.add "X-Amz-Security-Token", valid_600741
  var valid_600742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600742 = validateParameter(valid_600742, JString, required = false,
                                 default = nil)
  if valid_600742 != nil:
    section.add "X-Amz-Content-Sha256", valid_600742
  var valid_600743 = header.getOrDefault("X-Amz-Algorithm")
  valid_600743 = validateParameter(valid_600743, JString, required = false,
                                 default = nil)
  if valid_600743 != nil:
    section.add "X-Amz-Algorithm", valid_600743
  var valid_600744 = header.getOrDefault("X-Amz-Signature")
  valid_600744 = validateParameter(valid_600744, JString, required = false,
                                 default = nil)
  if valid_600744 != nil:
    section.add "X-Amz-Signature", valid_600744
  var valid_600745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600745 = validateParameter(valid_600745, JString, required = false,
                                 default = nil)
  if valid_600745 != nil:
    section.add "X-Amz-SignedHeaders", valid_600745
  var valid_600746 = header.getOrDefault("X-Amz-Credential")
  valid_600746 = validateParameter(valid_600746, JString, required = false,
                                 default = nil)
  if valid_600746 != nil:
    section.add "X-Amz-Credential", valid_600746
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_600747 = formData.getOrDefault("SubscriptionName")
  valid_600747 = validateParameter(valid_600747, JString, required = true,
                                 default = nil)
  if valid_600747 != nil:
    section.add "SubscriptionName", valid_600747
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600748: Call_PostDeleteEventSubscription_600735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600748.validator(path, query, header, formData, body)
  let scheme = call_600748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600748.url(scheme.get, call_600748.host, call_600748.base,
                         call_600748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600748, url, valid)

proc call*(call_600749: Call_PostDeleteEventSubscription_600735;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600750 = newJObject()
  var formData_600751 = newJObject()
  add(formData_600751, "SubscriptionName", newJString(SubscriptionName))
  add(query_600750, "Action", newJString(Action))
  add(query_600750, "Version", newJString(Version))
  result = call_600749.call(nil, query_600750, nil, formData_600751, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_600735(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_600736, base: "/",
    url: url_PostDeleteEventSubscription_600737,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_600719 = ref object of OpenApiRestCall_599352
proc url_GetDeleteEventSubscription_600721(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_600720(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600722 = query.getOrDefault("Action")
  valid_600722 = validateParameter(valid_600722, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_600722 != nil:
    section.add "Action", valid_600722
  var valid_600723 = query.getOrDefault("SubscriptionName")
  valid_600723 = validateParameter(valid_600723, JString, required = true,
                                 default = nil)
  if valid_600723 != nil:
    section.add "SubscriptionName", valid_600723
  var valid_600724 = query.getOrDefault("Version")
  valid_600724 = validateParameter(valid_600724, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600724 != nil:
    section.add "Version", valid_600724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600725 = header.getOrDefault("X-Amz-Date")
  valid_600725 = validateParameter(valid_600725, JString, required = false,
                                 default = nil)
  if valid_600725 != nil:
    section.add "X-Amz-Date", valid_600725
  var valid_600726 = header.getOrDefault("X-Amz-Security-Token")
  valid_600726 = validateParameter(valid_600726, JString, required = false,
                                 default = nil)
  if valid_600726 != nil:
    section.add "X-Amz-Security-Token", valid_600726
  var valid_600727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Content-Sha256", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Algorithm")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Algorithm", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-Signature")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Signature", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-SignedHeaders", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Credential")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Credential", valid_600731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600732: Call_GetDeleteEventSubscription_600719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600732.validator(path, query, header, formData, body)
  let scheme = call_600732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600732.url(scheme.get, call_600732.host, call_600732.base,
                         call_600732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600732, url, valid)

proc call*(call_600733: Call_GetDeleteEventSubscription_600719;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_600734 = newJObject()
  add(query_600734, "Action", newJString(Action))
  add(query_600734, "SubscriptionName", newJString(SubscriptionName))
  add(query_600734, "Version", newJString(Version))
  result = call_600733.call(nil, query_600734, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_600719(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_600720, base: "/",
    url: url_GetDeleteEventSubscription_600721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_600768 = ref object of OpenApiRestCall_599352
proc url_PostDeleteOptionGroup_600770(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_600769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600771 = query.getOrDefault("Action")
  valid_600771 = validateParameter(valid_600771, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_600771 != nil:
    section.add "Action", valid_600771
  var valid_600772 = query.getOrDefault("Version")
  valid_600772 = validateParameter(valid_600772, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600772 != nil:
    section.add "Version", valid_600772
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600773 = header.getOrDefault("X-Amz-Date")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Date", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-Security-Token")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-Security-Token", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Content-Sha256", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Algorithm")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Algorithm", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-Signature")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-Signature", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-SignedHeaders", valid_600778
  var valid_600779 = header.getOrDefault("X-Amz-Credential")
  valid_600779 = validateParameter(valid_600779, JString, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "X-Amz-Credential", valid_600779
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_600780 = formData.getOrDefault("OptionGroupName")
  valid_600780 = validateParameter(valid_600780, JString, required = true,
                                 default = nil)
  if valid_600780 != nil:
    section.add "OptionGroupName", valid_600780
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600781: Call_PostDeleteOptionGroup_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600781.validator(path, query, header, formData, body)
  let scheme = call_600781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600781.url(scheme.get, call_600781.host, call_600781.base,
                         call_600781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600781, url, valid)

proc call*(call_600782: Call_PostDeleteOptionGroup_600768; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600783 = newJObject()
  var formData_600784 = newJObject()
  add(formData_600784, "OptionGroupName", newJString(OptionGroupName))
  add(query_600783, "Action", newJString(Action))
  add(query_600783, "Version", newJString(Version))
  result = call_600782.call(nil, query_600783, nil, formData_600784, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_600768(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_600769, base: "/",
    url: url_PostDeleteOptionGroup_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_600752 = ref object of OpenApiRestCall_599352
proc url_GetDeleteOptionGroup_600754(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_600753(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600755 = query.getOrDefault("OptionGroupName")
  valid_600755 = validateParameter(valid_600755, JString, required = true,
                                 default = nil)
  if valid_600755 != nil:
    section.add "OptionGroupName", valid_600755
  var valid_600756 = query.getOrDefault("Action")
  valid_600756 = validateParameter(valid_600756, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_600756 != nil:
    section.add "Action", valid_600756
  var valid_600757 = query.getOrDefault("Version")
  valid_600757 = validateParameter(valid_600757, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600757 != nil:
    section.add "Version", valid_600757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600758 = header.getOrDefault("X-Amz-Date")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Date", valid_600758
  var valid_600759 = header.getOrDefault("X-Amz-Security-Token")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "X-Amz-Security-Token", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-Content-Sha256", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Algorithm")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Algorithm", valid_600761
  var valid_600762 = header.getOrDefault("X-Amz-Signature")
  valid_600762 = validateParameter(valid_600762, JString, required = false,
                                 default = nil)
  if valid_600762 != nil:
    section.add "X-Amz-Signature", valid_600762
  var valid_600763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600763 = validateParameter(valid_600763, JString, required = false,
                                 default = nil)
  if valid_600763 != nil:
    section.add "X-Amz-SignedHeaders", valid_600763
  var valid_600764 = header.getOrDefault("X-Amz-Credential")
  valid_600764 = validateParameter(valid_600764, JString, required = false,
                                 default = nil)
  if valid_600764 != nil:
    section.add "X-Amz-Credential", valid_600764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600765: Call_GetDeleteOptionGroup_600752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600765.validator(path, query, header, formData, body)
  let scheme = call_600765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600765.url(scheme.get, call_600765.host, call_600765.base,
                         call_600765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600765, url, valid)

proc call*(call_600766: Call_GetDeleteOptionGroup_600752; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600767 = newJObject()
  add(query_600767, "OptionGroupName", newJString(OptionGroupName))
  add(query_600767, "Action", newJString(Action))
  add(query_600767, "Version", newJString(Version))
  result = call_600766.call(nil, query_600767, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_600752(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_600753, base: "/",
    url: url_GetDeleteOptionGroup_600754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_600808 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBEngineVersions_600810(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_600809(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600811 = query.getOrDefault("Action")
  valid_600811 = validateParameter(valid_600811, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600811 != nil:
    section.add "Action", valid_600811
  var valid_600812 = query.getOrDefault("Version")
  valid_600812 = validateParameter(valid_600812, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600812 != nil:
    section.add "Version", valid_600812
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600813 = header.getOrDefault("X-Amz-Date")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Date", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Security-Token")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Security-Token", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Content-Sha256", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-Algorithm")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Algorithm", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-Signature")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-Signature", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-SignedHeaders", valid_600818
  var valid_600819 = header.getOrDefault("X-Amz-Credential")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "X-Amz-Credential", valid_600819
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
  var valid_600820 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_600820 = validateParameter(valid_600820, JBool, required = false, default = nil)
  if valid_600820 != nil:
    section.add "ListSupportedCharacterSets", valid_600820
  var valid_600821 = formData.getOrDefault("Engine")
  valid_600821 = validateParameter(valid_600821, JString, required = false,
                                 default = nil)
  if valid_600821 != nil:
    section.add "Engine", valid_600821
  var valid_600822 = formData.getOrDefault("Marker")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "Marker", valid_600822
  var valid_600823 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600823 = validateParameter(valid_600823, JString, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "DBParameterGroupFamily", valid_600823
  var valid_600824 = formData.getOrDefault("Filters")
  valid_600824 = validateParameter(valid_600824, JArray, required = false,
                                 default = nil)
  if valid_600824 != nil:
    section.add "Filters", valid_600824
  var valid_600825 = formData.getOrDefault("MaxRecords")
  valid_600825 = validateParameter(valid_600825, JInt, required = false, default = nil)
  if valid_600825 != nil:
    section.add "MaxRecords", valid_600825
  var valid_600826 = formData.getOrDefault("EngineVersion")
  valid_600826 = validateParameter(valid_600826, JString, required = false,
                                 default = nil)
  if valid_600826 != nil:
    section.add "EngineVersion", valid_600826
  var valid_600827 = formData.getOrDefault("DefaultOnly")
  valid_600827 = validateParameter(valid_600827, JBool, required = false, default = nil)
  if valid_600827 != nil:
    section.add "DefaultOnly", valid_600827
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600828: Call_PostDescribeDBEngineVersions_600808; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600828.validator(path, query, header, formData, body)
  let scheme = call_600828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600828.url(scheme.get, call_600828.host, call_600828.base,
                         call_600828.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600828, url, valid)

proc call*(call_600829: Call_PostDescribeDBEngineVersions_600808;
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
  var query_600830 = newJObject()
  var formData_600831 = newJObject()
  add(formData_600831, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_600831, "Engine", newJString(Engine))
  add(formData_600831, "Marker", newJString(Marker))
  add(query_600830, "Action", newJString(Action))
  add(formData_600831, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_600831.add "Filters", Filters
  add(formData_600831, "MaxRecords", newJInt(MaxRecords))
  add(formData_600831, "EngineVersion", newJString(EngineVersion))
  add(query_600830, "Version", newJString(Version))
  add(formData_600831, "DefaultOnly", newJBool(DefaultOnly))
  result = call_600829.call(nil, query_600830, nil, formData_600831, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_600808(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_600809, base: "/",
    url: url_PostDescribeDBEngineVersions_600810,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_600785 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBEngineVersions_600787(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_600786(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600788 = query.getOrDefault("Engine")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "Engine", valid_600788
  var valid_600789 = query.getOrDefault("ListSupportedCharacterSets")
  valid_600789 = validateParameter(valid_600789, JBool, required = false, default = nil)
  if valid_600789 != nil:
    section.add "ListSupportedCharacterSets", valid_600789
  var valid_600790 = query.getOrDefault("MaxRecords")
  valid_600790 = validateParameter(valid_600790, JInt, required = false, default = nil)
  if valid_600790 != nil:
    section.add "MaxRecords", valid_600790
  var valid_600791 = query.getOrDefault("DBParameterGroupFamily")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "DBParameterGroupFamily", valid_600791
  var valid_600792 = query.getOrDefault("Filters")
  valid_600792 = validateParameter(valid_600792, JArray, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "Filters", valid_600792
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600793 = query.getOrDefault("Action")
  valid_600793 = validateParameter(valid_600793, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600793 != nil:
    section.add "Action", valid_600793
  var valid_600794 = query.getOrDefault("Marker")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "Marker", valid_600794
  var valid_600795 = query.getOrDefault("EngineVersion")
  valid_600795 = validateParameter(valid_600795, JString, required = false,
                                 default = nil)
  if valid_600795 != nil:
    section.add "EngineVersion", valid_600795
  var valid_600796 = query.getOrDefault("DefaultOnly")
  valid_600796 = validateParameter(valid_600796, JBool, required = false, default = nil)
  if valid_600796 != nil:
    section.add "DefaultOnly", valid_600796
  var valid_600797 = query.getOrDefault("Version")
  valid_600797 = validateParameter(valid_600797, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600797 != nil:
    section.add "Version", valid_600797
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600798 = header.getOrDefault("X-Amz-Date")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Date", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Security-Token")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Security-Token", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Content-Sha256", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Algorithm")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Algorithm", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-Signature")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-Signature", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-SignedHeaders", valid_600803
  var valid_600804 = header.getOrDefault("X-Amz-Credential")
  valid_600804 = validateParameter(valid_600804, JString, required = false,
                                 default = nil)
  if valid_600804 != nil:
    section.add "X-Amz-Credential", valid_600804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600805: Call_GetDescribeDBEngineVersions_600785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600805.validator(path, query, header, formData, body)
  let scheme = call_600805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600805.url(scheme.get, call_600805.host, call_600805.base,
                         call_600805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600805, url, valid)

proc call*(call_600806: Call_GetDescribeDBEngineVersions_600785;
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
  var query_600807 = newJObject()
  add(query_600807, "Engine", newJString(Engine))
  add(query_600807, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_600807, "MaxRecords", newJInt(MaxRecords))
  add(query_600807, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_600807.add "Filters", Filters
  add(query_600807, "Action", newJString(Action))
  add(query_600807, "Marker", newJString(Marker))
  add(query_600807, "EngineVersion", newJString(EngineVersion))
  add(query_600807, "DefaultOnly", newJBool(DefaultOnly))
  add(query_600807, "Version", newJString(Version))
  result = call_600806.call(nil, query_600807, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_600785(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_600786, base: "/",
    url: url_GetDescribeDBEngineVersions_600787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_600851 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBInstances_600853(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_600852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600854 = query.getOrDefault("Action")
  valid_600854 = validateParameter(valid_600854, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600854 != nil:
    section.add "Action", valid_600854
  var valid_600855 = query.getOrDefault("Version")
  valid_600855 = validateParameter(valid_600855, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600855 != nil:
    section.add "Version", valid_600855
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600856 = header.getOrDefault("X-Amz-Date")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Date", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-Security-Token")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Security-Token", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Content-Sha256", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-Algorithm")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-Algorithm", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-Signature")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-Signature", valid_600860
  var valid_600861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "X-Amz-SignedHeaders", valid_600861
  var valid_600862 = header.getOrDefault("X-Amz-Credential")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "X-Amz-Credential", valid_600862
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600863 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600863 = validateParameter(valid_600863, JString, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "DBInstanceIdentifier", valid_600863
  var valid_600864 = formData.getOrDefault("Marker")
  valid_600864 = validateParameter(valid_600864, JString, required = false,
                                 default = nil)
  if valid_600864 != nil:
    section.add "Marker", valid_600864
  var valid_600865 = formData.getOrDefault("Filters")
  valid_600865 = validateParameter(valid_600865, JArray, required = false,
                                 default = nil)
  if valid_600865 != nil:
    section.add "Filters", valid_600865
  var valid_600866 = formData.getOrDefault("MaxRecords")
  valid_600866 = validateParameter(valid_600866, JInt, required = false, default = nil)
  if valid_600866 != nil:
    section.add "MaxRecords", valid_600866
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600867: Call_PostDescribeDBInstances_600851; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600867.validator(path, query, header, formData, body)
  let scheme = call_600867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600867.url(scheme.get, call_600867.host, call_600867.base,
                         call_600867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600867, url, valid)

proc call*(call_600868: Call_PostDescribeDBInstances_600851;
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
  var query_600869 = newJObject()
  var formData_600870 = newJObject()
  add(formData_600870, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600870, "Marker", newJString(Marker))
  add(query_600869, "Action", newJString(Action))
  if Filters != nil:
    formData_600870.add "Filters", Filters
  add(formData_600870, "MaxRecords", newJInt(MaxRecords))
  add(query_600869, "Version", newJString(Version))
  result = call_600868.call(nil, query_600869, nil, formData_600870, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_600851(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_600852, base: "/",
    url: url_PostDescribeDBInstances_600853, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_600832 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBInstances_600834(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_600833(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600835 = query.getOrDefault("MaxRecords")
  valid_600835 = validateParameter(valid_600835, JInt, required = false, default = nil)
  if valid_600835 != nil:
    section.add "MaxRecords", valid_600835
  var valid_600836 = query.getOrDefault("Filters")
  valid_600836 = validateParameter(valid_600836, JArray, required = false,
                                 default = nil)
  if valid_600836 != nil:
    section.add "Filters", valid_600836
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600837 = query.getOrDefault("Action")
  valid_600837 = validateParameter(valid_600837, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600837 != nil:
    section.add "Action", valid_600837
  var valid_600838 = query.getOrDefault("Marker")
  valid_600838 = validateParameter(valid_600838, JString, required = false,
                                 default = nil)
  if valid_600838 != nil:
    section.add "Marker", valid_600838
  var valid_600839 = query.getOrDefault("Version")
  valid_600839 = validateParameter(valid_600839, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600839 != nil:
    section.add "Version", valid_600839
  var valid_600840 = query.getOrDefault("DBInstanceIdentifier")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "DBInstanceIdentifier", valid_600840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600841 = header.getOrDefault("X-Amz-Date")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Date", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Security-Token")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Security-Token", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Content-Sha256", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-Algorithm")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-Algorithm", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-Signature")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-Signature", valid_600845
  var valid_600846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600846 = validateParameter(valid_600846, JString, required = false,
                                 default = nil)
  if valid_600846 != nil:
    section.add "X-Amz-SignedHeaders", valid_600846
  var valid_600847 = header.getOrDefault("X-Amz-Credential")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "X-Amz-Credential", valid_600847
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600848: Call_GetDescribeDBInstances_600832; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600848.validator(path, query, header, formData, body)
  let scheme = call_600848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600848.url(scheme.get, call_600848.host, call_600848.base,
                         call_600848.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600848, url, valid)

proc call*(call_600849: Call_GetDescribeDBInstances_600832; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2014-09-01";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_600850 = newJObject()
  add(query_600850, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600850.add "Filters", Filters
  add(query_600850, "Action", newJString(Action))
  add(query_600850, "Marker", newJString(Marker))
  add(query_600850, "Version", newJString(Version))
  add(query_600850, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600849.call(nil, query_600850, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_600832(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_600833, base: "/",
    url: url_GetDescribeDBInstances_600834, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_600893 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBLogFiles_600895(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_600894(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600896 = query.getOrDefault("Action")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_600896 != nil:
    section.add "Action", valid_600896
  var valid_600897 = query.getOrDefault("Version")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600897 != nil:
    section.add "Version", valid_600897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600898 = header.getOrDefault("X-Amz-Date")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Date", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Security-Token")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Security-Token", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Content-Sha256", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Algorithm")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Algorithm", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Signature")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Signature", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-SignedHeaders", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Credential")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Credential", valid_600904
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
  var valid_600905 = formData.getOrDefault("FilenameContains")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "FilenameContains", valid_600905
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600906 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600906 = validateParameter(valid_600906, JString, required = true,
                                 default = nil)
  if valid_600906 != nil:
    section.add "DBInstanceIdentifier", valid_600906
  var valid_600907 = formData.getOrDefault("FileSize")
  valid_600907 = validateParameter(valid_600907, JInt, required = false, default = nil)
  if valid_600907 != nil:
    section.add "FileSize", valid_600907
  var valid_600908 = formData.getOrDefault("Marker")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "Marker", valid_600908
  var valid_600909 = formData.getOrDefault("Filters")
  valid_600909 = validateParameter(valid_600909, JArray, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "Filters", valid_600909
  var valid_600910 = formData.getOrDefault("MaxRecords")
  valid_600910 = validateParameter(valid_600910, JInt, required = false, default = nil)
  if valid_600910 != nil:
    section.add "MaxRecords", valid_600910
  var valid_600911 = formData.getOrDefault("FileLastWritten")
  valid_600911 = validateParameter(valid_600911, JInt, required = false, default = nil)
  if valid_600911 != nil:
    section.add "FileLastWritten", valid_600911
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_PostDescribeDBLogFiles_600893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600912, url, valid)

proc call*(call_600913: Call_PostDescribeDBLogFiles_600893;
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
  var query_600914 = newJObject()
  var formData_600915 = newJObject()
  add(formData_600915, "FilenameContains", newJString(FilenameContains))
  add(formData_600915, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600915, "FileSize", newJInt(FileSize))
  add(formData_600915, "Marker", newJString(Marker))
  add(query_600914, "Action", newJString(Action))
  if Filters != nil:
    formData_600915.add "Filters", Filters
  add(formData_600915, "MaxRecords", newJInt(MaxRecords))
  add(formData_600915, "FileLastWritten", newJInt(FileLastWritten))
  add(query_600914, "Version", newJString(Version))
  result = call_600913.call(nil, query_600914, nil, formData_600915, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_600893(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_600894, base: "/",
    url: url_PostDescribeDBLogFiles_600895, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_600871 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBLogFiles_600873(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_600872(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600874 = query.getOrDefault("FileLastWritten")
  valid_600874 = validateParameter(valid_600874, JInt, required = false, default = nil)
  if valid_600874 != nil:
    section.add "FileLastWritten", valid_600874
  var valid_600875 = query.getOrDefault("MaxRecords")
  valid_600875 = validateParameter(valid_600875, JInt, required = false, default = nil)
  if valid_600875 != nil:
    section.add "MaxRecords", valid_600875
  var valid_600876 = query.getOrDefault("FilenameContains")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "FilenameContains", valid_600876
  var valid_600877 = query.getOrDefault("FileSize")
  valid_600877 = validateParameter(valid_600877, JInt, required = false, default = nil)
  if valid_600877 != nil:
    section.add "FileSize", valid_600877
  var valid_600878 = query.getOrDefault("Filters")
  valid_600878 = validateParameter(valid_600878, JArray, required = false,
                                 default = nil)
  if valid_600878 != nil:
    section.add "Filters", valid_600878
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600879 = query.getOrDefault("Action")
  valid_600879 = validateParameter(valid_600879, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_600879 != nil:
    section.add "Action", valid_600879
  var valid_600880 = query.getOrDefault("Marker")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "Marker", valid_600880
  var valid_600881 = query.getOrDefault("Version")
  valid_600881 = validateParameter(valid_600881, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600881 != nil:
    section.add "Version", valid_600881
  var valid_600882 = query.getOrDefault("DBInstanceIdentifier")
  valid_600882 = validateParameter(valid_600882, JString, required = true,
                                 default = nil)
  if valid_600882 != nil:
    section.add "DBInstanceIdentifier", valid_600882
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600883 = header.getOrDefault("X-Amz-Date")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Date", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-Security-Token")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Security-Token", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Content-Sha256", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Algorithm")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Algorithm", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-Signature")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-Signature", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-SignedHeaders", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Credential")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Credential", valid_600889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600890: Call_GetDescribeDBLogFiles_600871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600890.validator(path, query, header, formData, body)
  let scheme = call_600890.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600890.url(scheme.get, call_600890.host, call_600890.base,
                         call_600890.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600890, url, valid)

proc call*(call_600891: Call_GetDescribeDBLogFiles_600871;
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
  var query_600892 = newJObject()
  add(query_600892, "FileLastWritten", newJInt(FileLastWritten))
  add(query_600892, "MaxRecords", newJInt(MaxRecords))
  add(query_600892, "FilenameContains", newJString(FilenameContains))
  add(query_600892, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_600892.add "Filters", Filters
  add(query_600892, "Action", newJString(Action))
  add(query_600892, "Marker", newJString(Marker))
  add(query_600892, "Version", newJString(Version))
  add(query_600892, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600891.call(nil, query_600892, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_600871(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_600872, base: "/",
    url: url_GetDescribeDBLogFiles_600873, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_600935 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBParameterGroups_600937(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_600936(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600938 = query.getOrDefault("Action")
  valid_600938 = validateParameter(valid_600938, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_600938 != nil:
    section.add "Action", valid_600938
  var valid_600939 = query.getOrDefault("Version")
  valid_600939 = validateParameter(valid_600939, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600939 != nil:
    section.add "Version", valid_600939
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600940 = header.getOrDefault("X-Amz-Date")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Date", valid_600940
  var valid_600941 = header.getOrDefault("X-Amz-Security-Token")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "X-Amz-Security-Token", valid_600941
  var valid_600942 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Content-Sha256", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-Algorithm")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-Algorithm", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Signature")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Signature", valid_600944
  var valid_600945 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "X-Amz-SignedHeaders", valid_600945
  var valid_600946 = header.getOrDefault("X-Amz-Credential")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "X-Amz-Credential", valid_600946
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600947 = formData.getOrDefault("DBParameterGroupName")
  valid_600947 = validateParameter(valid_600947, JString, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "DBParameterGroupName", valid_600947
  var valid_600948 = formData.getOrDefault("Marker")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "Marker", valid_600948
  var valid_600949 = formData.getOrDefault("Filters")
  valid_600949 = validateParameter(valid_600949, JArray, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "Filters", valid_600949
  var valid_600950 = formData.getOrDefault("MaxRecords")
  valid_600950 = validateParameter(valid_600950, JInt, required = false, default = nil)
  if valid_600950 != nil:
    section.add "MaxRecords", valid_600950
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600951: Call_PostDescribeDBParameterGroups_600935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600951.validator(path, query, header, formData, body)
  let scheme = call_600951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600951.url(scheme.get, call_600951.host, call_600951.base,
                         call_600951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600951, url, valid)

proc call*(call_600952: Call_PostDescribeDBParameterGroups_600935;
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
  var query_600953 = newJObject()
  var formData_600954 = newJObject()
  add(formData_600954, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600954, "Marker", newJString(Marker))
  add(query_600953, "Action", newJString(Action))
  if Filters != nil:
    formData_600954.add "Filters", Filters
  add(formData_600954, "MaxRecords", newJInt(MaxRecords))
  add(query_600953, "Version", newJString(Version))
  result = call_600952.call(nil, query_600953, nil, formData_600954, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_600935(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_600936, base: "/",
    url: url_PostDescribeDBParameterGroups_600937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_600916 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBParameterGroups_600918(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_600917(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600919 = query.getOrDefault("MaxRecords")
  valid_600919 = validateParameter(valid_600919, JInt, required = false, default = nil)
  if valid_600919 != nil:
    section.add "MaxRecords", valid_600919
  var valid_600920 = query.getOrDefault("Filters")
  valid_600920 = validateParameter(valid_600920, JArray, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "Filters", valid_600920
  var valid_600921 = query.getOrDefault("DBParameterGroupName")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "DBParameterGroupName", valid_600921
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600922 = query.getOrDefault("Action")
  valid_600922 = validateParameter(valid_600922, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_600922 != nil:
    section.add "Action", valid_600922
  var valid_600923 = query.getOrDefault("Marker")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "Marker", valid_600923
  var valid_600924 = query.getOrDefault("Version")
  valid_600924 = validateParameter(valid_600924, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600924 != nil:
    section.add "Version", valid_600924
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600925 = header.getOrDefault("X-Amz-Date")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Date", valid_600925
  var valid_600926 = header.getOrDefault("X-Amz-Security-Token")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "X-Amz-Security-Token", valid_600926
  var valid_600927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Content-Sha256", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-Algorithm")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-Algorithm", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Signature")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Signature", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-SignedHeaders", valid_600930
  var valid_600931 = header.getOrDefault("X-Amz-Credential")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "X-Amz-Credential", valid_600931
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600932: Call_GetDescribeDBParameterGroups_600916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600932.validator(path, query, header, formData, body)
  let scheme = call_600932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600932.url(scheme.get, call_600932.host, call_600932.base,
                         call_600932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600932, url, valid)

proc call*(call_600933: Call_GetDescribeDBParameterGroups_600916;
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
  var query_600934 = newJObject()
  add(query_600934, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600934.add "Filters", Filters
  add(query_600934, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600934, "Action", newJString(Action))
  add(query_600934, "Marker", newJString(Marker))
  add(query_600934, "Version", newJString(Version))
  result = call_600933.call(nil, query_600934, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_600916(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_600917, base: "/",
    url: url_GetDescribeDBParameterGroups_600918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_600975 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBParameters_600977(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_600976(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600978 = query.getOrDefault("Action")
  valid_600978 = validateParameter(valid_600978, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_600978 != nil:
    section.add "Action", valid_600978
  var valid_600979 = query.getOrDefault("Version")
  valid_600979 = validateParameter(valid_600979, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600979 != nil:
    section.add "Version", valid_600979
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600980 = header.getOrDefault("X-Amz-Date")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-Date", valid_600980
  var valid_600981 = header.getOrDefault("X-Amz-Security-Token")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Security-Token", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Content-Sha256", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Algorithm")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Algorithm", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Signature")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Signature", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-SignedHeaders", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-Credential")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-Credential", valid_600986
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600987 = formData.getOrDefault("DBParameterGroupName")
  valid_600987 = validateParameter(valid_600987, JString, required = true,
                                 default = nil)
  if valid_600987 != nil:
    section.add "DBParameterGroupName", valid_600987
  var valid_600988 = formData.getOrDefault("Marker")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "Marker", valid_600988
  var valid_600989 = formData.getOrDefault("Filters")
  valid_600989 = validateParameter(valid_600989, JArray, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "Filters", valid_600989
  var valid_600990 = formData.getOrDefault("MaxRecords")
  valid_600990 = validateParameter(valid_600990, JInt, required = false, default = nil)
  if valid_600990 != nil:
    section.add "MaxRecords", valid_600990
  var valid_600991 = formData.getOrDefault("Source")
  valid_600991 = validateParameter(valid_600991, JString, required = false,
                                 default = nil)
  if valid_600991 != nil:
    section.add "Source", valid_600991
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600992: Call_PostDescribeDBParameters_600975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600992.validator(path, query, header, formData, body)
  let scheme = call_600992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600992.url(scheme.get, call_600992.host, call_600992.base,
                         call_600992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600992, url, valid)

proc call*(call_600993: Call_PostDescribeDBParameters_600975;
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
  var query_600994 = newJObject()
  var formData_600995 = newJObject()
  add(formData_600995, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600995, "Marker", newJString(Marker))
  add(query_600994, "Action", newJString(Action))
  if Filters != nil:
    formData_600995.add "Filters", Filters
  add(formData_600995, "MaxRecords", newJInt(MaxRecords))
  add(query_600994, "Version", newJString(Version))
  add(formData_600995, "Source", newJString(Source))
  result = call_600993.call(nil, query_600994, nil, formData_600995, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_600975(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_600976, base: "/",
    url: url_PostDescribeDBParameters_600977, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_600955 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBParameters_600957(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_600956(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600958 = query.getOrDefault("MaxRecords")
  valid_600958 = validateParameter(valid_600958, JInt, required = false, default = nil)
  if valid_600958 != nil:
    section.add "MaxRecords", valid_600958
  var valid_600959 = query.getOrDefault("Filters")
  valid_600959 = validateParameter(valid_600959, JArray, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "Filters", valid_600959
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_600960 = query.getOrDefault("DBParameterGroupName")
  valid_600960 = validateParameter(valid_600960, JString, required = true,
                                 default = nil)
  if valid_600960 != nil:
    section.add "DBParameterGroupName", valid_600960
  var valid_600961 = query.getOrDefault("Action")
  valid_600961 = validateParameter(valid_600961, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_600961 != nil:
    section.add "Action", valid_600961
  var valid_600962 = query.getOrDefault("Marker")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "Marker", valid_600962
  var valid_600963 = query.getOrDefault("Source")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "Source", valid_600963
  var valid_600964 = query.getOrDefault("Version")
  valid_600964 = validateParameter(valid_600964, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_600964 != nil:
    section.add "Version", valid_600964
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600965 = header.getOrDefault("X-Amz-Date")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-Date", valid_600965
  var valid_600966 = header.getOrDefault("X-Amz-Security-Token")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Security-Token", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Content-Sha256", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-Algorithm")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Algorithm", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-Signature")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Signature", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-SignedHeaders", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-Credential")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-Credential", valid_600971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600972: Call_GetDescribeDBParameters_600955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600972.validator(path, query, header, formData, body)
  let scheme = call_600972.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600972.url(scheme.get, call_600972.host, call_600972.base,
                         call_600972.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600972, url, valid)

proc call*(call_600973: Call_GetDescribeDBParameters_600955;
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
  var query_600974 = newJObject()
  add(query_600974, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600974.add "Filters", Filters
  add(query_600974, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600974, "Action", newJString(Action))
  add(query_600974, "Marker", newJString(Marker))
  add(query_600974, "Source", newJString(Source))
  add(query_600974, "Version", newJString(Version))
  result = call_600973.call(nil, query_600974, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_600955(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_600956, base: "/",
    url: url_GetDescribeDBParameters_600957, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_601015 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSecurityGroups_601017(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_601016(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601018 = query.getOrDefault("Action")
  valid_601018 = validateParameter(valid_601018, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601018 != nil:
    section.add "Action", valid_601018
  var valid_601019 = query.getOrDefault("Version")
  valid_601019 = validateParameter(valid_601019, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601019 != nil:
    section.add "Version", valid_601019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601020 = header.getOrDefault("X-Amz-Date")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-Date", valid_601020
  var valid_601021 = header.getOrDefault("X-Amz-Security-Token")
  valid_601021 = validateParameter(valid_601021, JString, required = false,
                                 default = nil)
  if valid_601021 != nil:
    section.add "X-Amz-Security-Token", valid_601021
  var valid_601022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "X-Amz-Content-Sha256", valid_601022
  var valid_601023 = header.getOrDefault("X-Amz-Algorithm")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "X-Amz-Algorithm", valid_601023
  var valid_601024 = header.getOrDefault("X-Amz-Signature")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Signature", valid_601024
  var valid_601025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "X-Amz-SignedHeaders", valid_601025
  var valid_601026 = header.getOrDefault("X-Amz-Credential")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Credential", valid_601026
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601027 = formData.getOrDefault("DBSecurityGroupName")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "DBSecurityGroupName", valid_601027
  var valid_601028 = formData.getOrDefault("Marker")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "Marker", valid_601028
  var valid_601029 = formData.getOrDefault("Filters")
  valid_601029 = validateParameter(valid_601029, JArray, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "Filters", valid_601029
  var valid_601030 = formData.getOrDefault("MaxRecords")
  valid_601030 = validateParameter(valid_601030, JInt, required = false, default = nil)
  if valid_601030 != nil:
    section.add "MaxRecords", valid_601030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601031: Call_PostDescribeDBSecurityGroups_601015; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601031.validator(path, query, header, formData, body)
  let scheme = call_601031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601031.url(scheme.get, call_601031.host, call_601031.base,
                         call_601031.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601031, url, valid)

proc call*(call_601032: Call_PostDescribeDBSecurityGroups_601015;
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
  var query_601033 = newJObject()
  var formData_601034 = newJObject()
  add(formData_601034, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_601034, "Marker", newJString(Marker))
  add(query_601033, "Action", newJString(Action))
  if Filters != nil:
    formData_601034.add "Filters", Filters
  add(formData_601034, "MaxRecords", newJInt(MaxRecords))
  add(query_601033, "Version", newJString(Version))
  result = call_601032.call(nil, query_601033, nil, formData_601034, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_601015(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_601016, base: "/",
    url: url_PostDescribeDBSecurityGroups_601017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_600996 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSecurityGroups_600998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_600997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600999 = query.getOrDefault("MaxRecords")
  valid_600999 = validateParameter(valid_600999, JInt, required = false, default = nil)
  if valid_600999 != nil:
    section.add "MaxRecords", valid_600999
  var valid_601000 = query.getOrDefault("DBSecurityGroupName")
  valid_601000 = validateParameter(valid_601000, JString, required = false,
                                 default = nil)
  if valid_601000 != nil:
    section.add "DBSecurityGroupName", valid_601000
  var valid_601001 = query.getOrDefault("Filters")
  valid_601001 = validateParameter(valid_601001, JArray, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "Filters", valid_601001
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601002 = query.getOrDefault("Action")
  valid_601002 = validateParameter(valid_601002, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601002 != nil:
    section.add "Action", valid_601002
  var valid_601003 = query.getOrDefault("Marker")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "Marker", valid_601003
  var valid_601004 = query.getOrDefault("Version")
  valid_601004 = validateParameter(valid_601004, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601004 != nil:
    section.add "Version", valid_601004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601005 = header.getOrDefault("X-Amz-Date")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "X-Amz-Date", valid_601005
  var valid_601006 = header.getOrDefault("X-Amz-Security-Token")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "X-Amz-Security-Token", valid_601006
  var valid_601007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Content-Sha256", valid_601007
  var valid_601008 = header.getOrDefault("X-Amz-Algorithm")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "X-Amz-Algorithm", valid_601008
  var valid_601009 = header.getOrDefault("X-Amz-Signature")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Signature", valid_601009
  var valid_601010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601010 = validateParameter(valid_601010, JString, required = false,
                                 default = nil)
  if valid_601010 != nil:
    section.add "X-Amz-SignedHeaders", valid_601010
  var valid_601011 = header.getOrDefault("X-Amz-Credential")
  valid_601011 = validateParameter(valid_601011, JString, required = false,
                                 default = nil)
  if valid_601011 != nil:
    section.add "X-Amz-Credential", valid_601011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601012: Call_GetDescribeDBSecurityGroups_600996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601012.validator(path, query, header, formData, body)
  let scheme = call_601012.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601012.url(scheme.get, call_601012.host, call_601012.base,
                         call_601012.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601012, url, valid)

proc call*(call_601013: Call_GetDescribeDBSecurityGroups_600996;
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
  var query_601014 = newJObject()
  add(query_601014, "MaxRecords", newJInt(MaxRecords))
  add(query_601014, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_601014.add "Filters", Filters
  add(query_601014, "Action", newJString(Action))
  add(query_601014, "Marker", newJString(Marker))
  add(query_601014, "Version", newJString(Version))
  result = call_601013.call(nil, query_601014, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_600996(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_600997, base: "/",
    url: url_GetDescribeDBSecurityGroups_600998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_601056 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSnapshots_601058(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_601057(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601059 = query.getOrDefault("Action")
  valid_601059 = validateParameter(valid_601059, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_601059 != nil:
    section.add "Action", valid_601059
  var valid_601060 = query.getOrDefault("Version")
  valid_601060 = validateParameter(valid_601060, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601060 != nil:
    section.add "Version", valid_601060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601061 = header.getOrDefault("X-Amz-Date")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Date", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Security-Token")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Security-Token", valid_601062
  var valid_601063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601063 = validateParameter(valid_601063, JString, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "X-Amz-Content-Sha256", valid_601063
  var valid_601064 = header.getOrDefault("X-Amz-Algorithm")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Algorithm", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Signature")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Signature", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-SignedHeaders", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Credential")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Credential", valid_601067
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601068 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "DBInstanceIdentifier", valid_601068
  var valid_601069 = formData.getOrDefault("SnapshotType")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "SnapshotType", valid_601069
  var valid_601070 = formData.getOrDefault("Marker")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "Marker", valid_601070
  var valid_601071 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "DBSnapshotIdentifier", valid_601071
  var valid_601072 = formData.getOrDefault("Filters")
  valid_601072 = validateParameter(valid_601072, JArray, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "Filters", valid_601072
  var valid_601073 = formData.getOrDefault("MaxRecords")
  valid_601073 = validateParameter(valid_601073, JInt, required = false, default = nil)
  if valid_601073 != nil:
    section.add "MaxRecords", valid_601073
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601074: Call_PostDescribeDBSnapshots_601056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601074.validator(path, query, header, formData, body)
  let scheme = call_601074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601074.url(scheme.get, call_601074.host, call_601074.base,
                         call_601074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601074, url, valid)

proc call*(call_601075: Call_PostDescribeDBSnapshots_601056;
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
  var query_601076 = newJObject()
  var formData_601077 = newJObject()
  add(formData_601077, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601077, "SnapshotType", newJString(SnapshotType))
  add(formData_601077, "Marker", newJString(Marker))
  add(formData_601077, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601076, "Action", newJString(Action))
  if Filters != nil:
    formData_601077.add "Filters", Filters
  add(formData_601077, "MaxRecords", newJInt(MaxRecords))
  add(query_601076, "Version", newJString(Version))
  result = call_601075.call(nil, query_601076, nil, formData_601077, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_601056(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_601057, base: "/",
    url: url_PostDescribeDBSnapshots_601058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_601035 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSnapshots_601037(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_601036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601038 = query.getOrDefault("MaxRecords")
  valid_601038 = validateParameter(valid_601038, JInt, required = false, default = nil)
  if valid_601038 != nil:
    section.add "MaxRecords", valid_601038
  var valid_601039 = query.getOrDefault("Filters")
  valid_601039 = validateParameter(valid_601039, JArray, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "Filters", valid_601039
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601040 = query.getOrDefault("Action")
  valid_601040 = validateParameter(valid_601040, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_601040 != nil:
    section.add "Action", valid_601040
  var valid_601041 = query.getOrDefault("Marker")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "Marker", valid_601041
  var valid_601042 = query.getOrDefault("SnapshotType")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "SnapshotType", valid_601042
  var valid_601043 = query.getOrDefault("Version")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601043 != nil:
    section.add "Version", valid_601043
  var valid_601044 = query.getOrDefault("DBInstanceIdentifier")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "DBInstanceIdentifier", valid_601044
  var valid_601045 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "DBSnapshotIdentifier", valid_601045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601046 = header.getOrDefault("X-Amz-Date")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Date", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Security-Token")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Security-Token", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Content-Sha256", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-Algorithm")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Algorithm", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Signature")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Signature", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-SignedHeaders", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Credential")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Credential", valid_601052
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601053: Call_GetDescribeDBSnapshots_601035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601053.validator(path, query, header, formData, body)
  let scheme = call_601053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601053.url(scheme.get, call_601053.host, call_601053.base,
                         call_601053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601053, url, valid)

proc call*(call_601054: Call_GetDescribeDBSnapshots_601035; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSnapshots";
          Marker: string = ""; SnapshotType: string = "";
          Version: string = "2014-09-01"; DBInstanceIdentifier: string = "";
          DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_601055 = newJObject()
  add(query_601055, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601055.add "Filters", Filters
  add(query_601055, "Action", newJString(Action))
  add(query_601055, "Marker", newJString(Marker))
  add(query_601055, "SnapshotType", newJString(SnapshotType))
  add(query_601055, "Version", newJString(Version))
  add(query_601055, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601055, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601054.call(nil, query_601055, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_601035(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_601036, base: "/",
    url: url_GetDescribeDBSnapshots_601037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_601097 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSubnetGroups_601099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_601098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601100 = query.getOrDefault("Action")
  valid_601100 = validateParameter(valid_601100, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_601100 != nil:
    section.add "Action", valid_601100
  var valid_601101 = query.getOrDefault("Version")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601101 != nil:
    section.add "Version", valid_601101
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601102 = header.getOrDefault("X-Amz-Date")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Date", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Security-Token")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Security-Token", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Content-Sha256", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Algorithm")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Algorithm", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-Signature")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-Signature", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-SignedHeaders", valid_601107
  var valid_601108 = header.getOrDefault("X-Amz-Credential")
  valid_601108 = validateParameter(valid_601108, JString, required = false,
                                 default = nil)
  if valid_601108 != nil:
    section.add "X-Amz-Credential", valid_601108
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601109 = formData.getOrDefault("DBSubnetGroupName")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "DBSubnetGroupName", valid_601109
  var valid_601110 = formData.getOrDefault("Marker")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "Marker", valid_601110
  var valid_601111 = formData.getOrDefault("Filters")
  valid_601111 = validateParameter(valid_601111, JArray, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "Filters", valid_601111
  var valid_601112 = formData.getOrDefault("MaxRecords")
  valid_601112 = validateParameter(valid_601112, JInt, required = false, default = nil)
  if valid_601112 != nil:
    section.add "MaxRecords", valid_601112
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601113: Call_PostDescribeDBSubnetGroups_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601113.validator(path, query, header, formData, body)
  let scheme = call_601113.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601113.url(scheme.get, call_601113.host, call_601113.base,
                         call_601113.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601113, url, valid)

proc call*(call_601114: Call_PostDescribeDBSubnetGroups_601097;
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
  var query_601115 = newJObject()
  var formData_601116 = newJObject()
  add(formData_601116, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601116, "Marker", newJString(Marker))
  add(query_601115, "Action", newJString(Action))
  if Filters != nil:
    formData_601116.add "Filters", Filters
  add(formData_601116, "MaxRecords", newJInt(MaxRecords))
  add(query_601115, "Version", newJString(Version))
  result = call_601114.call(nil, query_601115, nil, formData_601116, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_601097(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_601098, base: "/",
    url: url_PostDescribeDBSubnetGroups_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_601078 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSubnetGroups_601080(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_601079(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601081 = query.getOrDefault("MaxRecords")
  valid_601081 = validateParameter(valid_601081, JInt, required = false, default = nil)
  if valid_601081 != nil:
    section.add "MaxRecords", valid_601081
  var valid_601082 = query.getOrDefault("Filters")
  valid_601082 = validateParameter(valid_601082, JArray, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "Filters", valid_601082
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601083 = query.getOrDefault("Action")
  valid_601083 = validateParameter(valid_601083, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_601083 != nil:
    section.add "Action", valid_601083
  var valid_601084 = query.getOrDefault("Marker")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "Marker", valid_601084
  var valid_601085 = query.getOrDefault("DBSubnetGroupName")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "DBSubnetGroupName", valid_601085
  var valid_601086 = query.getOrDefault("Version")
  valid_601086 = validateParameter(valid_601086, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601086 != nil:
    section.add "Version", valid_601086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601087 = header.getOrDefault("X-Amz-Date")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Date", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Security-Token")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Security-Token", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Content-Sha256", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Algorithm")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Algorithm", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Signature")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Signature", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-SignedHeaders", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Credential")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Credential", valid_601093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_GetDescribeDBSubnetGroups_601078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601094, url, valid)

proc call*(call_601095: Call_GetDescribeDBSubnetGroups_601078; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSubnetGroups";
          Marker: string = ""; DBSubnetGroupName: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_601096 = newJObject()
  add(query_601096, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601096.add "Filters", Filters
  add(query_601096, "Action", newJString(Action))
  add(query_601096, "Marker", newJString(Marker))
  add(query_601096, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601096, "Version", newJString(Version))
  result = call_601095.call(nil, query_601096, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_601078(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_601079, base: "/",
    url: url_GetDescribeDBSubnetGroups_601080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_601136 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEngineDefaultParameters_601138(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_601137(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601139 = query.getOrDefault("Action")
  valid_601139 = validateParameter(valid_601139, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_601139 != nil:
    section.add "Action", valid_601139
  var valid_601140 = query.getOrDefault("Version")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601140 != nil:
    section.add "Version", valid_601140
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601141 = header.getOrDefault("X-Amz-Date")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Date", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Security-Token")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Security-Token", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Content-Sha256", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Algorithm")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Algorithm", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Signature")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Signature", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-SignedHeaders", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Credential")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Credential", valid_601147
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601148 = formData.getOrDefault("Marker")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "Marker", valid_601148
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_601149 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601149 = validateParameter(valid_601149, JString, required = true,
                                 default = nil)
  if valid_601149 != nil:
    section.add "DBParameterGroupFamily", valid_601149
  var valid_601150 = formData.getOrDefault("Filters")
  valid_601150 = validateParameter(valid_601150, JArray, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "Filters", valid_601150
  var valid_601151 = formData.getOrDefault("MaxRecords")
  valid_601151 = validateParameter(valid_601151, JInt, required = false, default = nil)
  if valid_601151 != nil:
    section.add "MaxRecords", valid_601151
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601152: Call_PostDescribeEngineDefaultParameters_601136;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601152.validator(path, query, header, formData, body)
  let scheme = call_601152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601152.url(scheme.get, call_601152.host, call_601152.base,
                         call_601152.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601152, url, valid)

proc call*(call_601153: Call_PostDescribeEngineDefaultParameters_601136;
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
  var query_601154 = newJObject()
  var formData_601155 = newJObject()
  add(formData_601155, "Marker", newJString(Marker))
  add(query_601154, "Action", newJString(Action))
  add(formData_601155, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601155.add "Filters", Filters
  add(formData_601155, "MaxRecords", newJInt(MaxRecords))
  add(query_601154, "Version", newJString(Version))
  result = call_601153.call(nil, query_601154, nil, formData_601155, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_601136(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_601137, base: "/",
    url: url_PostDescribeEngineDefaultParameters_601138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_601117 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEngineDefaultParameters_601119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_601118(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601120 = query.getOrDefault("MaxRecords")
  valid_601120 = validateParameter(valid_601120, JInt, required = false, default = nil)
  if valid_601120 != nil:
    section.add "MaxRecords", valid_601120
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_601121 = query.getOrDefault("DBParameterGroupFamily")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = nil)
  if valid_601121 != nil:
    section.add "DBParameterGroupFamily", valid_601121
  var valid_601122 = query.getOrDefault("Filters")
  valid_601122 = validateParameter(valid_601122, JArray, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "Filters", valid_601122
  var valid_601123 = query.getOrDefault("Action")
  valid_601123 = validateParameter(valid_601123, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_601123 != nil:
    section.add "Action", valid_601123
  var valid_601124 = query.getOrDefault("Marker")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "Marker", valid_601124
  var valid_601125 = query.getOrDefault("Version")
  valid_601125 = validateParameter(valid_601125, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601125 != nil:
    section.add "Version", valid_601125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601126 = header.getOrDefault("X-Amz-Date")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Date", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Security-Token")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Security-Token", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Content-Sha256", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Algorithm")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Algorithm", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Signature")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Signature", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-SignedHeaders", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Credential")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Credential", valid_601132
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601133: Call_GetDescribeEngineDefaultParameters_601117;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601133.validator(path, query, header, formData, body)
  let scheme = call_601133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601133.url(scheme.get, call_601133.host, call_601133.base,
                         call_601133.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601133, url, valid)

proc call*(call_601134: Call_GetDescribeEngineDefaultParameters_601117;
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
  var query_601135 = newJObject()
  add(query_601135, "MaxRecords", newJInt(MaxRecords))
  add(query_601135, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601135.add "Filters", Filters
  add(query_601135, "Action", newJString(Action))
  add(query_601135, "Marker", newJString(Marker))
  add(query_601135, "Version", newJString(Version))
  result = call_601134.call(nil, query_601135, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_601117(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_601118, base: "/",
    url: url_GetDescribeEngineDefaultParameters_601119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_601173 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEventCategories_601175(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_601174(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601176 = query.getOrDefault("Action")
  valid_601176 = validateParameter(valid_601176, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601176 != nil:
    section.add "Action", valid_601176
  var valid_601177 = query.getOrDefault("Version")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601177 != nil:
    section.add "Version", valid_601177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601178 = header.getOrDefault("X-Amz-Date")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Date", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Security-Token")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Security-Token", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Content-Sha256", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Algorithm")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Algorithm", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Signature")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Signature", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-SignedHeaders", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Credential")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Credential", valid_601184
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_601185 = formData.getOrDefault("Filters")
  valid_601185 = validateParameter(valid_601185, JArray, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "Filters", valid_601185
  var valid_601186 = formData.getOrDefault("SourceType")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "SourceType", valid_601186
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601187: Call_PostDescribeEventCategories_601173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601187.validator(path, query, header, formData, body)
  let scheme = call_601187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601187.url(scheme.get, call_601187.host, call_601187.base,
                         call_601187.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601187, url, valid)

proc call*(call_601188: Call_PostDescribeEventCategories_601173;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_601189 = newJObject()
  var formData_601190 = newJObject()
  add(query_601189, "Action", newJString(Action))
  if Filters != nil:
    formData_601190.add "Filters", Filters
  add(query_601189, "Version", newJString(Version))
  add(formData_601190, "SourceType", newJString(SourceType))
  result = call_601188.call(nil, query_601189, nil, formData_601190, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_601173(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_601174, base: "/",
    url: url_PostDescribeEventCategories_601175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_601156 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEventCategories_601158(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_601157(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601159 = query.getOrDefault("SourceType")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "SourceType", valid_601159
  var valid_601160 = query.getOrDefault("Filters")
  valid_601160 = validateParameter(valid_601160, JArray, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "Filters", valid_601160
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601161 = query.getOrDefault("Action")
  valid_601161 = validateParameter(valid_601161, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601161 != nil:
    section.add "Action", valid_601161
  var valid_601162 = query.getOrDefault("Version")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601162 != nil:
    section.add "Version", valid_601162
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601163 = header.getOrDefault("X-Amz-Date")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Date", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Security-Token")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Security-Token", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Content-Sha256", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Algorithm")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Algorithm", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Signature")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Signature", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-SignedHeaders", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Credential")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Credential", valid_601169
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601170: Call_GetDescribeEventCategories_601156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601170.validator(path, query, header, formData, body)
  let scheme = call_601170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601170.url(scheme.get, call_601170.host, call_601170.base,
                         call_601170.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601170, url, valid)

proc call*(call_601171: Call_GetDescribeEventCategories_601156;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601172 = newJObject()
  add(query_601172, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_601172.add "Filters", Filters
  add(query_601172, "Action", newJString(Action))
  add(query_601172, "Version", newJString(Version))
  result = call_601171.call(nil, query_601172, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_601156(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_601157, base: "/",
    url: url_GetDescribeEventCategories_601158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_601210 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEventSubscriptions_601212(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_601211(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601213 = query.getOrDefault("Action")
  valid_601213 = validateParameter(valid_601213, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_601213 != nil:
    section.add "Action", valid_601213
  var valid_601214 = query.getOrDefault("Version")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601214 != nil:
    section.add "Version", valid_601214
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601215 = header.getOrDefault("X-Amz-Date")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Date", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Security-Token")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Security-Token", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Content-Sha256", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-Algorithm")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Algorithm", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Signature")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Signature", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-SignedHeaders", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Credential")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Credential", valid_601221
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601222 = formData.getOrDefault("Marker")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "Marker", valid_601222
  var valid_601223 = formData.getOrDefault("SubscriptionName")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "SubscriptionName", valid_601223
  var valid_601224 = formData.getOrDefault("Filters")
  valid_601224 = validateParameter(valid_601224, JArray, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "Filters", valid_601224
  var valid_601225 = formData.getOrDefault("MaxRecords")
  valid_601225 = validateParameter(valid_601225, JInt, required = false, default = nil)
  if valid_601225 != nil:
    section.add "MaxRecords", valid_601225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601226: Call_PostDescribeEventSubscriptions_601210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601226.validator(path, query, header, formData, body)
  let scheme = call_601226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601226.url(scheme.get, call_601226.host, call_601226.base,
                         call_601226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601226, url, valid)

proc call*(call_601227: Call_PostDescribeEventSubscriptions_601210;
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
  var query_601228 = newJObject()
  var formData_601229 = newJObject()
  add(formData_601229, "Marker", newJString(Marker))
  add(formData_601229, "SubscriptionName", newJString(SubscriptionName))
  add(query_601228, "Action", newJString(Action))
  if Filters != nil:
    formData_601229.add "Filters", Filters
  add(formData_601229, "MaxRecords", newJInt(MaxRecords))
  add(query_601228, "Version", newJString(Version))
  result = call_601227.call(nil, query_601228, nil, formData_601229, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_601210(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_601211, base: "/",
    url: url_PostDescribeEventSubscriptions_601212,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_601191 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEventSubscriptions_601193(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_601192(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601194 = query.getOrDefault("MaxRecords")
  valid_601194 = validateParameter(valid_601194, JInt, required = false, default = nil)
  if valid_601194 != nil:
    section.add "MaxRecords", valid_601194
  var valid_601195 = query.getOrDefault("Filters")
  valid_601195 = validateParameter(valid_601195, JArray, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "Filters", valid_601195
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601196 = query.getOrDefault("Action")
  valid_601196 = validateParameter(valid_601196, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_601196 != nil:
    section.add "Action", valid_601196
  var valid_601197 = query.getOrDefault("Marker")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "Marker", valid_601197
  var valid_601198 = query.getOrDefault("SubscriptionName")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "SubscriptionName", valid_601198
  var valid_601199 = query.getOrDefault("Version")
  valid_601199 = validateParameter(valid_601199, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601199 != nil:
    section.add "Version", valid_601199
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601200 = header.getOrDefault("X-Amz-Date")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Date", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Security-Token")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Security-Token", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Content-Sha256", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Algorithm")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Algorithm", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Signature")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Signature", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-SignedHeaders", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Credential")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Credential", valid_601206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601207: Call_GetDescribeEventSubscriptions_601191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601207.validator(path, query, header, formData, body)
  let scheme = call_601207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601207.url(scheme.get, call_601207.host, call_601207.base,
                         call_601207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601207, url, valid)

proc call*(call_601208: Call_GetDescribeEventSubscriptions_601191;
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
  var query_601209 = newJObject()
  add(query_601209, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601209.add "Filters", Filters
  add(query_601209, "Action", newJString(Action))
  add(query_601209, "Marker", newJString(Marker))
  add(query_601209, "SubscriptionName", newJString(SubscriptionName))
  add(query_601209, "Version", newJString(Version))
  result = call_601208.call(nil, query_601209, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_601191(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_601192, base: "/",
    url: url_GetDescribeEventSubscriptions_601193,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_601254 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEvents_601256(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_601255(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601257 = query.getOrDefault("Action")
  valid_601257 = validateParameter(valid_601257, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601257 != nil:
    section.add "Action", valid_601257
  var valid_601258 = query.getOrDefault("Version")
  valid_601258 = validateParameter(valid_601258, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601258 != nil:
    section.add "Version", valid_601258
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601259 = header.getOrDefault("X-Amz-Date")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Date", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Security-Token")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Security-Token", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Content-Sha256", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Algorithm")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Algorithm", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Signature")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Signature", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-SignedHeaders", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Credential")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Credential", valid_601265
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
  var valid_601266 = formData.getOrDefault("SourceIdentifier")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "SourceIdentifier", valid_601266
  var valid_601267 = formData.getOrDefault("EventCategories")
  valid_601267 = validateParameter(valid_601267, JArray, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "EventCategories", valid_601267
  var valid_601268 = formData.getOrDefault("Marker")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "Marker", valid_601268
  var valid_601269 = formData.getOrDefault("StartTime")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "StartTime", valid_601269
  var valid_601270 = formData.getOrDefault("Duration")
  valid_601270 = validateParameter(valid_601270, JInt, required = false, default = nil)
  if valid_601270 != nil:
    section.add "Duration", valid_601270
  var valid_601271 = formData.getOrDefault("Filters")
  valid_601271 = validateParameter(valid_601271, JArray, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "Filters", valid_601271
  var valid_601272 = formData.getOrDefault("EndTime")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "EndTime", valid_601272
  var valid_601273 = formData.getOrDefault("MaxRecords")
  valid_601273 = validateParameter(valid_601273, JInt, required = false, default = nil)
  if valid_601273 != nil:
    section.add "MaxRecords", valid_601273
  var valid_601274 = formData.getOrDefault("SourceType")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_601274 != nil:
    section.add "SourceType", valid_601274
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601275: Call_PostDescribeEvents_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601275.validator(path, query, header, formData, body)
  let scheme = call_601275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601275.url(scheme.get, call_601275.host, call_601275.base,
                         call_601275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601275, url, valid)

proc call*(call_601276: Call_PostDescribeEvents_601254;
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
  var query_601277 = newJObject()
  var formData_601278 = newJObject()
  add(formData_601278, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_601278.add "EventCategories", EventCategories
  add(formData_601278, "Marker", newJString(Marker))
  add(formData_601278, "StartTime", newJString(StartTime))
  add(query_601277, "Action", newJString(Action))
  add(formData_601278, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_601278.add "Filters", Filters
  add(formData_601278, "EndTime", newJString(EndTime))
  add(formData_601278, "MaxRecords", newJInt(MaxRecords))
  add(query_601277, "Version", newJString(Version))
  add(formData_601278, "SourceType", newJString(SourceType))
  result = call_601276.call(nil, query_601277, nil, formData_601278, nil)

var postDescribeEvents* = Call_PostDescribeEvents_601254(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_601255, base: "/",
    url: url_PostDescribeEvents_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_601230 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEvents_601232(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_601231(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_601233 = query.getOrDefault("SourceType")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_601233 != nil:
    section.add "SourceType", valid_601233
  var valid_601234 = query.getOrDefault("MaxRecords")
  valid_601234 = validateParameter(valid_601234, JInt, required = false, default = nil)
  if valid_601234 != nil:
    section.add "MaxRecords", valid_601234
  var valid_601235 = query.getOrDefault("StartTime")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "StartTime", valid_601235
  var valid_601236 = query.getOrDefault("Filters")
  valid_601236 = validateParameter(valid_601236, JArray, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "Filters", valid_601236
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601237 = query.getOrDefault("Action")
  valid_601237 = validateParameter(valid_601237, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601237 != nil:
    section.add "Action", valid_601237
  var valid_601238 = query.getOrDefault("SourceIdentifier")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "SourceIdentifier", valid_601238
  var valid_601239 = query.getOrDefault("Marker")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "Marker", valid_601239
  var valid_601240 = query.getOrDefault("EventCategories")
  valid_601240 = validateParameter(valid_601240, JArray, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "EventCategories", valid_601240
  var valid_601241 = query.getOrDefault("Duration")
  valid_601241 = validateParameter(valid_601241, JInt, required = false, default = nil)
  if valid_601241 != nil:
    section.add "Duration", valid_601241
  var valid_601242 = query.getOrDefault("EndTime")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "EndTime", valid_601242
  var valid_601243 = query.getOrDefault("Version")
  valid_601243 = validateParameter(valid_601243, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601243 != nil:
    section.add "Version", valid_601243
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601244 = header.getOrDefault("X-Amz-Date")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Date", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Security-Token")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Security-Token", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Content-Sha256", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Algorithm")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Algorithm", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Signature")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Signature", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-SignedHeaders", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Credential")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Credential", valid_601250
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601251: Call_GetDescribeEvents_601230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601251.validator(path, query, header, formData, body)
  let scheme = call_601251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601251.url(scheme.get, call_601251.host, call_601251.base,
                         call_601251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601251, url, valid)

proc call*(call_601252: Call_GetDescribeEvents_601230;
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
  var query_601253 = newJObject()
  add(query_601253, "SourceType", newJString(SourceType))
  add(query_601253, "MaxRecords", newJInt(MaxRecords))
  add(query_601253, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_601253.add "Filters", Filters
  add(query_601253, "Action", newJString(Action))
  add(query_601253, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601253, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_601253.add "EventCategories", EventCategories
  add(query_601253, "Duration", newJInt(Duration))
  add(query_601253, "EndTime", newJString(EndTime))
  add(query_601253, "Version", newJString(Version))
  result = call_601252.call(nil, query_601253, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_601230(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_601231,
    base: "/", url: url_GetDescribeEvents_601232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_601299 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOptionGroupOptions_601301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_601300(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601302 = query.getOrDefault("Action")
  valid_601302 = validateParameter(valid_601302, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_601302 != nil:
    section.add "Action", valid_601302
  var valid_601303 = query.getOrDefault("Version")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601303 != nil:
    section.add "Version", valid_601303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601304 = header.getOrDefault("X-Amz-Date")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Date", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Security-Token")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Security-Token", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Content-Sha256", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Algorithm")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Algorithm", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Signature")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Signature", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-SignedHeaders", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Credential")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Credential", valid_601310
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601311 = formData.getOrDefault("MajorEngineVersion")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "MajorEngineVersion", valid_601311
  var valid_601312 = formData.getOrDefault("Marker")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "Marker", valid_601312
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_601313 = formData.getOrDefault("EngineName")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "EngineName", valid_601313
  var valid_601314 = formData.getOrDefault("Filters")
  valid_601314 = validateParameter(valid_601314, JArray, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "Filters", valid_601314
  var valid_601315 = formData.getOrDefault("MaxRecords")
  valid_601315 = validateParameter(valid_601315, JInt, required = false, default = nil)
  if valid_601315 != nil:
    section.add "MaxRecords", valid_601315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601316: Call_PostDescribeOptionGroupOptions_601299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601316.validator(path, query, header, formData, body)
  let scheme = call_601316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601316.url(scheme.get, call_601316.host, call_601316.base,
                         call_601316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601316, url, valid)

proc call*(call_601317: Call_PostDescribeOptionGroupOptions_601299;
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
  var query_601318 = newJObject()
  var formData_601319 = newJObject()
  add(formData_601319, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601319, "Marker", newJString(Marker))
  add(query_601318, "Action", newJString(Action))
  add(formData_601319, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_601319.add "Filters", Filters
  add(formData_601319, "MaxRecords", newJInt(MaxRecords))
  add(query_601318, "Version", newJString(Version))
  result = call_601317.call(nil, query_601318, nil, formData_601319, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_601299(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_601300, base: "/",
    url: url_PostDescribeOptionGroupOptions_601301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_601279 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOptionGroupOptions_601281(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_601280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601282 = query.getOrDefault("MaxRecords")
  valid_601282 = validateParameter(valid_601282, JInt, required = false, default = nil)
  if valid_601282 != nil:
    section.add "MaxRecords", valid_601282
  var valid_601283 = query.getOrDefault("Filters")
  valid_601283 = validateParameter(valid_601283, JArray, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "Filters", valid_601283
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601284 = query.getOrDefault("Action")
  valid_601284 = validateParameter(valid_601284, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_601284 != nil:
    section.add "Action", valid_601284
  var valid_601285 = query.getOrDefault("Marker")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "Marker", valid_601285
  var valid_601286 = query.getOrDefault("Version")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601286 != nil:
    section.add "Version", valid_601286
  var valid_601287 = query.getOrDefault("EngineName")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = nil)
  if valid_601287 != nil:
    section.add "EngineName", valid_601287
  var valid_601288 = query.getOrDefault("MajorEngineVersion")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "MajorEngineVersion", valid_601288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601289 = header.getOrDefault("X-Amz-Date")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Date", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Security-Token")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Security-Token", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Content-Sha256", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Algorithm")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Algorithm", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Signature")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Signature", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-SignedHeaders", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Credential")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Credential", valid_601295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601296: Call_GetDescribeOptionGroupOptions_601279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601296.validator(path, query, header, formData, body)
  let scheme = call_601296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601296.url(scheme.get, call_601296.host, call_601296.base,
                         call_601296.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601296, url, valid)

proc call*(call_601297: Call_GetDescribeOptionGroupOptions_601279;
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
  var query_601298 = newJObject()
  add(query_601298, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601298.add "Filters", Filters
  add(query_601298, "Action", newJString(Action))
  add(query_601298, "Marker", newJString(Marker))
  add(query_601298, "Version", newJString(Version))
  add(query_601298, "EngineName", newJString(EngineName))
  add(query_601298, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601297.call(nil, query_601298, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_601279(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_601280, base: "/",
    url: url_GetDescribeOptionGroupOptions_601281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_601341 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOptionGroups_601343(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_601342(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601344 = query.getOrDefault("Action")
  valid_601344 = validateParameter(valid_601344, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_601344 != nil:
    section.add "Action", valid_601344
  var valid_601345 = query.getOrDefault("Version")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601345 != nil:
    section.add "Version", valid_601345
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601346 = header.getOrDefault("X-Amz-Date")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Date", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Security-Token")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Security-Token", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Content-Sha256", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Algorithm")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Algorithm", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Signature")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Signature", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-SignedHeaders", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Credential")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Credential", valid_601352
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601353 = formData.getOrDefault("MajorEngineVersion")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "MajorEngineVersion", valid_601353
  var valid_601354 = formData.getOrDefault("OptionGroupName")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "OptionGroupName", valid_601354
  var valid_601355 = formData.getOrDefault("Marker")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "Marker", valid_601355
  var valid_601356 = formData.getOrDefault("EngineName")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "EngineName", valid_601356
  var valid_601357 = formData.getOrDefault("Filters")
  valid_601357 = validateParameter(valid_601357, JArray, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "Filters", valid_601357
  var valid_601358 = formData.getOrDefault("MaxRecords")
  valid_601358 = validateParameter(valid_601358, JInt, required = false, default = nil)
  if valid_601358 != nil:
    section.add "MaxRecords", valid_601358
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601359: Call_PostDescribeOptionGroups_601341; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601359.validator(path, query, header, formData, body)
  let scheme = call_601359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601359.url(scheme.get, call_601359.host, call_601359.base,
                         call_601359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601359, url, valid)

proc call*(call_601360: Call_PostDescribeOptionGroups_601341;
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
  var query_601361 = newJObject()
  var formData_601362 = newJObject()
  add(formData_601362, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601362, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601362, "Marker", newJString(Marker))
  add(query_601361, "Action", newJString(Action))
  add(formData_601362, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_601362.add "Filters", Filters
  add(formData_601362, "MaxRecords", newJInt(MaxRecords))
  add(query_601361, "Version", newJString(Version))
  result = call_601360.call(nil, query_601361, nil, formData_601362, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_601341(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_601342, base: "/",
    url: url_PostDescribeOptionGroups_601343, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_601320 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOptionGroups_601322(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_601321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601323 = query.getOrDefault("MaxRecords")
  valid_601323 = validateParameter(valid_601323, JInt, required = false, default = nil)
  if valid_601323 != nil:
    section.add "MaxRecords", valid_601323
  var valid_601324 = query.getOrDefault("OptionGroupName")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "OptionGroupName", valid_601324
  var valid_601325 = query.getOrDefault("Filters")
  valid_601325 = validateParameter(valid_601325, JArray, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "Filters", valid_601325
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601326 = query.getOrDefault("Action")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_601326 != nil:
    section.add "Action", valid_601326
  var valid_601327 = query.getOrDefault("Marker")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "Marker", valid_601327
  var valid_601328 = query.getOrDefault("Version")
  valid_601328 = validateParameter(valid_601328, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601328 != nil:
    section.add "Version", valid_601328
  var valid_601329 = query.getOrDefault("EngineName")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "EngineName", valid_601329
  var valid_601330 = query.getOrDefault("MajorEngineVersion")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "MajorEngineVersion", valid_601330
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601331 = header.getOrDefault("X-Amz-Date")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Date", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Security-Token")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Security-Token", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-Content-Sha256", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Algorithm")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Algorithm", valid_601334
  var valid_601335 = header.getOrDefault("X-Amz-Signature")
  valid_601335 = validateParameter(valid_601335, JString, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "X-Amz-Signature", valid_601335
  var valid_601336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-SignedHeaders", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Credential")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Credential", valid_601337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601338: Call_GetDescribeOptionGroups_601320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601338.validator(path, query, header, formData, body)
  let scheme = call_601338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601338.url(scheme.get, call_601338.host, call_601338.base,
                         call_601338.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601338, url, valid)

proc call*(call_601339: Call_GetDescribeOptionGroups_601320; MaxRecords: int = 0;
          OptionGroupName: string = ""; Filters: JsonNode = nil;
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
  var query_601340 = newJObject()
  add(query_601340, "MaxRecords", newJInt(MaxRecords))
  add(query_601340, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_601340.add "Filters", Filters
  add(query_601340, "Action", newJString(Action))
  add(query_601340, "Marker", newJString(Marker))
  add(query_601340, "Version", newJString(Version))
  add(query_601340, "EngineName", newJString(EngineName))
  add(query_601340, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601339.call(nil, query_601340, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_601320(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_601321, base: "/",
    url: url_GetDescribeOptionGroups_601322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_601386 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOrderableDBInstanceOptions_601388(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_601387(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601389 = query.getOrDefault("Action")
  valid_601389 = validateParameter(valid_601389, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_601389 != nil:
    section.add "Action", valid_601389
  var valid_601390 = query.getOrDefault("Version")
  valid_601390 = validateParameter(valid_601390, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601390 != nil:
    section.add "Version", valid_601390
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601391 = header.getOrDefault("X-Amz-Date")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Date", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Security-Token")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Security-Token", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Content-Sha256", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Algorithm")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Algorithm", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Signature")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Signature", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-SignedHeaders", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Credential")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Credential", valid_601397
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
  var valid_601398 = formData.getOrDefault("Engine")
  valid_601398 = validateParameter(valid_601398, JString, required = true,
                                 default = nil)
  if valid_601398 != nil:
    section.add "Engine", valid_601398
  var valid_601399 = formData.getOrDefault("Marker")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "Marker", valid_601399
  var valid_601400 = formData.getOrDefault("Vpc")
  valid_601400 = validateParameter(valid_601400, JBool, required = false, default = nil)
  if valid_601400 != nil:
    section.add "Vpc", valid_601400
  var valid_601401 = formData.getOrDefault("DBInstanceClass")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "DBInstanceClass", valid_601401
  var valid_601402 = formData.getOrDefault("Filters")
  valid_601402 = validateParameter(valid_601402, JArray, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "Filters", valid_601402
  var valid_601403 = formData.getOrDefault("LicenseModel")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "LicenseModel", valid_601403
  var valid_601404 = formData.getOrDefault("MaxRecords")
  valid_601404 = validateParameter(valid_601404, JInt, required = false, default = nil)
  if valid_601404 != nil:
    section.add "MaxRecords", valid_601404
  var valid_601405 = formData.getOrDefault("EngineVersion")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "EngineVersion", valid_601405
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601406: Call_PostDescribeOrderableDBInstanceOptions_601386;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601406.validator(path, query, header, formData, body)
  let scheme = call_601406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601406.url(scheme.get, call_601406.host, call_601406.base,
                         call_601406.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601406, url, valid)

proc call*(call_601407: Call_PostDescribeOrderableDBInstanceOptions_601386;
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
  var query_601408 = newJObject()
  var formData_601409 = newJObject()
  add(formData_601409, "Engine", newJString(Engine))
  add(formData_601409, "Marker", newJString(Marker))
  add(query_601408, "Action", newJString(Action))
  add(formData_601409, "Vpc", newJBool(Vpc))
  add(formData_601409, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_601409.add "Filters", Filters
  add(formData_601409, "LicenseModel", newJString(LicenseModel))
  add(formData_601409, "MaxRecords", newJInt(MaxRecords))
  add(formData_601409, "EngineVersion", newJString(EngineVersion))
  add(query_601408, "Version", newJString(Version))
  result = call_601407.call(nil, query_601408, nil, formData_601409, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_601386(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_601387, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_601388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_601363 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOrderableDBInstanceOptions_601365(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_601364(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601366 = query.getOrDefault("Engine")
  valid_601366 = validateParameter(valid_601366, JString, required = true,
                                 default = nil)
  if valid_601366 != nil:
    section.add "Engine", valid_601366
  var valid_601367 = query.getOrDefault("MaxRecords")
  valid_601367 = validateParameter(valid_601367, JInt, required = false, default = nil)
  if valid_601367 != nil:
    section.add "MaxRecords", valid_601367
  var valid_601368 = query.getOrDefault("Filters")
  valid_601368 = validateParameter(valid_601368, JArray, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "Filters", valid_601368
  var valid_601369 = query.getOrDefault("LicenseModel")
  valid_601369 = validateParameter(valid_601369, JString, required = false,
                                 default = nil)
  if valid_601369 != nil:
    section.add "LicenseModel", valid_601369
  var valid_601370 = query.getOrDefault("Vpc")
  valid_601370 = validateParameter(valid_601370, JBool, required = false, default = nil)
  if valid_601370 != nil:
    section.add "Vpc", valid_601370
  var valid_601371 = query.getOrDefault("DBInstanceClass")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "DBInstanceClass", valid_601371
  var valid_601372 = query.getOrDefault("Action")
  valid_601372 = validateParameter(valid_601372, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_601372 != nil:
    section.add "Action", valid_601372
  var valid_601373 = query.getOrDefault("Marker")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "Marker", valid_601373
  var valid_601374 = query.getOrDefault("EngineVersion")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "EngineVersion", valid_601374
  var valid_601375 = query.getOrDefault("Version")
  valid_601375 = validateParameter(valid_601375, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601375 != nil:
    section.add "Version", valid_601375
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601376 = header.getOrDefault("X-Amz-Date")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Date", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Security-Token")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Security-Token", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Content-Sha256", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Algorithm")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Algorithm", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Signature")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Signature", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-SignedHeaders", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Credential")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Credential", valid_601382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601383: Call_GetDescribeOrderableDBInstanceOptions_601363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601383.validator(path, query, header, formData, body)
  let scheme = call_601383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601383.url(scheme.get, call_601383.host, call_601383.base,
                         call_601383.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601383, url, valid)

proc call*(call_601384: Call_GetDescribeOrderableDBInstanceOptions_601363;
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
  var query_601385 = newJObject()
  add(query_601385, "Engine", newJString(Engine))
  add(query_601385, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601385.add "Filters", Filters
  add(query_601385, "LicenseModel", newJString(LicenseModel))
  add(query_601385, "Vpc", newJBool(Vpc))
  add(query_601385, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601385, "Action", newJString(Action))
  add(query_601385, "Marker", newJString(Marker))
  add(query_601385, "EngineVersion", newJString(EngineVersion))
  add(query_601385, "Version", newJString(Version))
  result = call_601384.call(nil, query_601385, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_601363(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_601364, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_601365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_601435 = ref object of OpenApiRestCall_599352
proc url_PostDescribeReservedDBInstances_601437(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_601436(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601438 = query.getOrDefault("Action")
  valid_601438 = validateParameter(valid_601438, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_601438 != nil:
    section.add "Action", valid_601438
  var valid_601439 = query.getOrDefault("Version")
  valid_601439 = validateParameter(valid_601439, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601439 != nil:
    section.add "Version", valid_601439
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601440 = header.getOrDefault("X-Amz-Date")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Date", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Security-Token")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Security-Token", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Content-Sha256", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Algorithm")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Algorithm", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Signature")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Signature", valid_601444
  var valid_601445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-SignedHeaders", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Credential")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Credential", valid_601446
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
  var valid_601447 = formData.getOrDefault("OfferingType")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "OfferingType", valid_601447
  var valid_601448 = formData.getOrDefault("ReservedDBInstanceId")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "ReservedDBInstanceId", valid_601448
  var valid_601449 = formData.getOrDefault("Marker")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "Marker", valid_601449
  var valid_601450 = formData.getOrDefault("MultiAZ")
  valid_601450 = validateParameter(valid_601450, JBool, required = false, default = nil)
  if valid_601450 != nil:
    section.add "MultiAZ", valid_601450
  var valid_601451 = formData.getOrDefault("Duration")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "Duration", valid_601451
  var valid_601452 = formData.getOrDefault("DBInstanceClass")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "DBInstanceClass", valid_601452
  var valid_601453 = formData.getOrDefault("Filters")
  valid_601453 = validateParameter(valid_601453, JArray, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "Filters", valid_601453
  var valid_601454 = formData.getOrDefault("ProductDescription")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "ProductDescription", valid_601454
  var valid_601455 = formData.getOrDefault("MaxRecords")
  valid_601455 = validateParameter(valid_601455, JInt, required = false, default = nil)
  if valid_601455 != nil:
    section.add "MaxRecords", valid_601455
  var valid_601456 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601456
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601457: Call_PostDescribeReservedDBInstances_601435;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601457.validator(path, query, header, formData, body)
  let scheme = call_601457.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601457.url(scheme.get, call_601457.host, call_601457.base,
                         call_601457.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601457, url, valid)

proc call*(call_601458: Call_PostDescribeReservedDBInstances_601435;
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
  var query_601459 = newJObject()
  var formData_601460 = newJObject()
  add(formData_601460, "OfferingType", newJString(OfferingType))
  add(formData_601460, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_601460, "Marker", newJString(Marker))
  add(formData_601460, "MultiAZ", newJBool(MultiAZ))
  add(query_601459, "Action", newJString(Action))
  add(formData_601460, "Duration", newJString(Duration))
  add(formData_601460, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_601460.add "Filters", Filters
  add(formData_601460, "ProductDescription", newJString(ProductDescription))
  add(formData_601460, "MaxRecords", newJInt(MaxRecords))
  add(formData_601460, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601459, "Version", newJString(Version))
  result = call_601458.call(nil, query_601459, nil, formData_601460, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_601435(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_601436, base: "/",
    url: url_PostDescribeReservedDBInstances_601437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_601410 = ref object of OpenApiRestCall_599352
proc url_GetDescribeReservedDBInstances_601412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_601411(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601413 = query.getOrDefault("ProductDescription")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "ProductDescription", valid_601413
  var valid_601414 = query.getOrDefault("MaxRecords")
  valid_601414 = validateParameter(valid_601414, JInt, required = false, default = nil)
  if valid_601414 != nil:
    section.add "MaxRecords", valid_601414
  var valid_601415 = query.getOrDefault("OfferingType")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "OfferingType", valid_601415
  var valid_601416 = query.getOrDefault("Filters")
  valid_601416 = validateParameter(valid_601416, JArray, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "Filters", valid_601416
  var valid_601417 = query.getOrDefault("MultiAZ")
  valid_601417 = validateParameter(valid_601417, JBool, required = false, default = nil)
  if valid_601417 != nil:
    section.add "MultiAZ", valid_601417
  var valid_601418 = query.getOrDefault("ReservedDBInstanceId")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "ReservedDBInstanceId", valid_601418
  var valid_601419 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601419
  var valid_601420 = query.getOrDefault("DBInstanceClass")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "DBInstanceClass", valid_601420
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601421 = query.getOrDefault("Action")
  valid_601421 = validateParameter(valid_601421, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_601421 != nil:
    section.add "Action", valid_601421
  var valid_601422 = query.getOrDefault("Marker")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "Marker", valid_601422
  var valid_601423 = query.getOrDefault("Duration")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "Duration", valid_601423
  var valid_601424 = query.getOrDefault("Version")
  valid_601424 = validateParameter(valid_601424, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601424 != nil:
    section.add "Version", valid_601424
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601425 = header.getOrDefault("X-Amz-Date")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Date", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Security-Token")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Security-Token", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Content-Sha256", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Algorithm")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Algorithm", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Signature")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Signature", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-SignedHeaders", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Credential")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Credential", valid_601431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601432: Call_GetDescribeReservedDBInstances_601410; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601432.validator(path, query, header, formData, body)
  let scheme = call_601432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601432.url(scheme.get, call_601432.host, call_601432.base,
                         call_601432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601432, url, valid)

proc call*(call_601433: Call_GetDescribeReservedDBInstances_601410;
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
  var query_601434 = newJObject()
  add(query_601434, "ProductDescription", newJString(ProductDescription))
  add(query_601434, "MaxRecords", newJInt(MaxRecords))
  add(query_601434, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_601434.add "Filters", Filters
  add(query_601434, "MultiAZ", newJBool(MultiAZ))
  add(query_601434, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_601434, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601434, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601434, "Action", newJString(Action))
  add(query_601434, "Marker", newJString(Marker))
  add(query_601434, "Duration", newJString(Duration))
  add(query_601434, "Version", newJString(Version))
  result = call_601433.call(nil, query_601434, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_601410(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_601411, base: "/",
    url: url_GetDescribeReservedDBInstances_601412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_601485 = ref object of OpenApiRestCall_599352
proc url_PostDescribeReservedDBInstancesOfferings_601487(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_601486(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601488 = query.getOrDefault("Action")
  valid_601488 = validateParameter(valid_601488, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_601488 != nil:
    section.add "Action", valid_601488
  var valid_601489 = query.getOrDefault("Version")
  valid_601489 = validateParameter(valid_601489, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601489 != nil:
    section.add "Version", valid_601489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601490 = header.getOrDefault("X-Amz-Date")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Date", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Security-Token")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Security-Token", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Content-Sha256", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Algorithm")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Algorithm", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Signature")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Signature", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-SignedHeaders", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Credential")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Credential", valid_601496
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
  var valid_601497 = formData.getOrDefault("OfferingType")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "OfferingType", valid_601497
  var valid_601498 = formData.getOrDefault("Marker")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "Marker", valid_601498
  var valid_601499 = formData.getOrDefault("MultiAZ")
  valid_601499 = validateParameter(valid_601499, JBool, required = false, default = nil)
  if valid_601499 != nil:
    section.add "MultiAZ", valid_601499
  var valid_601500 = formData.getOrDefault("Duration")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "Duration", valid_601500
  var valid_601501 = formData.getOrDefault("DBInstanceClass")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "DBInstanceClass", valid_601501
  var valid_601502 = formData.getOrDefault("Filters")
  valid_601502 = validateParameter(valid_601502, JArray, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "Filters", valid_601502
  var valid_601503 = formData.getOrDefault("ProductDescription")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "ProductDescription", valid_601503
  var valid_601504 = formData.getOrDefault("MaxRecords")
  valid_601504 = validateParameter(valid_601504, JInt, required = false, default = nil)
  if valid_601504 != nil:
    section.add "MaxRecords", valid_601504
  var valid_601505 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601505
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601506: Call_PostDescribeReservedDBInstancesOfferings_601485;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601506.validator(path, query, header, formData, body)
  let scheme = call_601506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601506.url(scheme.get, call_601506.host, call_601506.base,
                         call_601506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601506, url, valid)

proc call*(call_601507: Call_PostDescribeReservedDBInstancesOfferings_601485;
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
  var query_601508 = newJObject()
  var formData_601509 = newJObject()
  add(formData_601509, "OfferingType", newJString(OfferingType))
  add(formData_601509, "Marker", newJString(Marker))
  add(formData_601509, "MultiAZ", newJBool(MultiAZ))
  add(query_601508, "Action", newJString(Action))
  add(formData_601509, "Duration", newJString(Duration))
  add(formData_601509, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_601509.add "Filters", Filters
  add(formData_601509, "ProductDescription", newJString(ProductDescription))
  add(formData_601509, "MaxRecords", newJInt(MaxRecords))
  add(formData_601509, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601508, "Version", newJString(Version))
  result = call_601507.call(nil, query_601508, nil, formData_601509, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_601485(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_601486,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_601487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_601461 = ref object of OpenApiRestCall_599352
proc url_GetDescribeReservedDBInstancesOfferings_601463(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_601462(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601464 = query.getOrDefault("ProductDescription")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "ProductDescription", valid_601464
  var valid_601465 = query.getOrDefault("MaxRecords")
  valid_601465 = validateParameter(valid_601465, JInt, required = false, default = nil)
  if valid_601465 != nil:
    section.add "MaxRecords", valid_601465
  var valid_601466 = query.getOrDefault("OfferingType")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "OfferingType", valid_601466
  var valid_601467 = query.getOrDefault("Filters")
  valid_601467 = validateParameter(valid_601467, JArray, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "Filters", valid_601467
  var valid_601468 = query.getOrDefault("MultiAZ")
  valid_601468 = validateParameter(valid_601468, JBool, required = false, default = nil)
  if valid_601468 != nil:
    section.add "MultiAZ", valid_601468
  var valid_601469 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601469
  var valid_601470 = query.getOrDefault("DBInstanceClass")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "DBInstanceClass", valid_601470
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601471 = query.getOrDefault("Action")
  valid_601471 = validateParameter(valid_601471, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_601471 != nil:
    section.add "Action", valid_601471
  var valid_601472 = query.getOrDefault("Marker")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "Marker", valid_601472
  var valid_601473 = query.getOrDefault("Duration")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "Duration", valid_601473
  var valid_601474 = query.getOrDefault("Version")
  valid_601474 = validateParameter(valid_601474, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601474 != nil:
    section.add "Version", valid_601474
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601475 = header.getOrDefault("X-Amz-Date")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Date", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Security-Token")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Security-Token", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Content-Sha256", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Algorithm")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Algorithm", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Signature")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Signature", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-SignedHeaders", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Credential")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Credential", valid_601481
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601482: Call_GetDescribeReservedDBInstancesOfferings_601461;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601482.validator(path, query, header, formData, body)
  let scheme = call_601482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601482.url(scheme.get, call_601482.host, call_601482.base,
                         call_601482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601482, url, valid)

proc call*(call_601483: Call_GetDescribeReservedDBInstancesOfferings_601461;
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
  var query_601484 = newJObject()
  add(query_601484, "ProductDescription", newJString(ProductDescription))
  add(query_601484, "MaxRecords", newJInt(MaxRecords))
  add(query_601484, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_601484.add "Filters", Filters
  add(query_601484, "MultiAZ", newJBool(MultiAZ))
  add(query_601484, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601484, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601484, "Action", newJString(Action))
  add(query_601484, "Marker", newJString(Marker))
  add(query_601484, "Duration", newJString(Duration))
  add(query_601484, "Version", newJString(Version))
  result = call_601483.call(nil, query_601484, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_601461(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_601462, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_601463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_601529 = ref object of OpenApiRestCall_599352
proc url_PostDownloadDBLogFilePortion_601531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_601530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601532 = query.getOrDefault("Action")
  valid_601532 = validateParameter(valid_601532, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_601532 != nil:
    section.add "Action", valid_601532
  var valid_601533 = query.getOrDefault("Version")
  valid_601533 = validateParameter(valid_601533, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601533 != nil:
    section.add "Version", valid_601533
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601534 = header.getOrDefault("X-Amz-Date")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Date", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Security-Token")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Security-Token", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Content-Sha256", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Algorithm")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Algorithm", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Signature")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Signature", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-SignedHeaders", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Credential")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Credential", valid_601540
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_601541 = formData.getOrDefault("NumberOfLines")
  valid_601541 = validateParameter(valid_601541, JInt, required = false, default = nil)
  if valid_601541 != nil:
    section.add "NumberOfLines", valid_601541
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601542 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601542 = validateParameter(valid_601542, JString, required = true,
                                 default = nil)
  if valid_601542 != nil:
    section.add "DBInstanceIdentifier", valid_601542
  var valid_601543 = formData.getOrDefault("Marker")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "Marker", valid_601543
  var valid_601544 = formData.getOrDefault("LogFileName")
  valid_601544 = validateParameter(valid_601544, JString, required = true,
                                 default = nil)
  if valid_601544 != nil:
    section.add "LogFileName", valid_601544
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601545: Call_PostDownloadDBLogFilePortion_601529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601545.validator(path, query, header, formData, body)
  let scheme = call_601545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601545.url(scheme.get, call_601545.host, call_601545.base,
                         call_601545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601545, url, valid)

proc call*(call_601546: Call_PostDownloadDBLogFilePortion_601529;
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
  var query_601547 = newJObject()
  var formData_601548 = newJObject()
  add(formData_601548, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_601548, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601548, "Marker", newJString(Marker))
  add(query_601547, "Action", newJString(Action))
  add(formData_601548, "LogFileName", newJString(LogFileName))
  add(query_601547, "Version", newJString(Version))
  result = call_601546.call(nil, query_601547, nil, formData_601548, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_601529(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_601530, base: "/",
    url: url_PostDownloadDBLogFilePortion_601531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_601510 = ref object of OpenApiRestCall_599352
proc url_GetDownloadDBLogFilePortion_601512(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_601511(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601513 = query.getOrDefault("NumberOfLines")
  valid_601513 = validateParameter(valid_601513, JInt, required = false, default = nil)
  if valid_601513 != nil:
    section.add "NumberOfLines", valid_601513
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_601514 = query.getOrDefault("LogFileName")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = nil)
  if valid_601514 != nil:
    section.add "LogFileName", valid_601514
  var valid_601515 = query.getOrDefault("Action")
  valid_601515 = validateParameter(valid_601515, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_601515 != nil:
    section.add "Action", valid_601515
  var valid_601516 = query.getOrDefault("Marker")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "Marker", valid_601516
  var valid_601517 = query.getOrDefault("Version")
  valid_601517 = validateParameter(valid_601517, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601517 != nil:
    section.add "Version", valid_601517
  var valid_601518 = query.getOrDefault("DBInstanceIdentifier")
  valid_601518 = validateParameter(valid_601518, JString, required = true,
                                 default = nil)
  if valid_601518 != nil:
    section.add "DBInstanceIdentifier", valid_601518
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601519 = header.getOrDefault("X-Amz-Date")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Date", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Security-Token")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Security-Token", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Content-Sha256", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Algorithm")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Algorithm", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Signature")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Signature", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-SignedHeaders", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Credential")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Credential", valid_601525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601526: Call_GetDownloadDBLogFilePortion_601510; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601526.validator(path, query, header, formData, body)
  let scheme = call_601526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601526.url(scheme.get, call_601526.host, call_601526.base,
                         call_601526.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601526, url, valid)

proc call*(call_601527: Call_GetDownloadDBLogFilePortion_601510;
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
  var query_601528 = newJObject()
  add(query_601528, "NumberOfLines", newJInt(NumberOfLines))
  add(query_601528, "LogFileName", newJString(LogFileName))
  add(query_601528, "Action", newJString(Action))
  add(query_601528, "Marker", newJString(Marker))
  add(query_601528, "Version", newJString(Version))
  add(query_601528, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601527.call(nil, query_601528, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_601510(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_601511, base: "/",
    url: url_GetDownloadDBLogFilePortion_601512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_601566 = ref object of OpenApiRestCall_599352
proc url_PostListTagsForResource_601568(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_601567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601569 = query.getOrDefault("Action")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601569 != nil:
    section.add "Action", valid_601569
  var valid_601570 = query.getOrDefault("Version")
  valid_601570 = validateParameter(valid_601570, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601570 != nil:
    section.add "Version", valid_601570
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601571 = header.getOrDefault("X-Amz-Date")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Date", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Security-Token")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Security-Token", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Content-Sha256", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Algorithm")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Algorithm", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Signature")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Signature", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-SignedHeaders", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-Credential")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-Credential", valid_601577
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_601578 = formData.getOrDefault("Filters")
  valid_601578 = validateParameter(valid_601578, JArray, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "Filters", valid_601578
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_601579 = formData.getOrDefault("ResourceName")
  valid_601579 = validateParameter(valid_601579, JString, required = true,
                                 default = nil)
  if valid_601579 != nil:
    section.add "ResourceName", valid_601579
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601580: Call_PostListTagsForResource_601566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601580.validator(path, query, header, formData, body)
  let scheme = call_601580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601580.url(scheme.get, call_601580.host, call_601580.base,
                         call_601580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601580, url, valid)

proc call*(call_601581: Call_PostListTagsForResource_601566; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601582 = newJObject()
  var formData_601583 = newJObject()
  add(query_601582, "Action", newJString(Action))
  if Filters != nil:
    formData_601583.add "Filters", Filters
  add(formData_601583, "ResourceName", newJString(ResourceName))
  add(query_601582, "Version", newJString(Version))
  result = call_601581.call(nil, query_601582, nil, formData_601583, nil)

var postListTagsForResource* = Call_PostListTagsForResource_601566(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_601567, base: "/",
    url: url_PostListTagsForResource_601568, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_601549 = ref object of OpenApiRestCall_599352
proc url_GetListTagsForResource_601551(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_601550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601552 = query.getOrDefault("Filters")
  valid_601552 = validateParameter(valid_601552, JArray, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "Filters", valid_601552
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_601553 = query.getOrDefault("ResourceName")
  valid_601553 = validateParameter(valid_601553, JString, required = true,
                                 default = nil)
  if valid_601553 != nil:
    section.add "ResourceName", valid_601553
  var valid_601554 = query.getOrDefault("Action")
  valid_601554 = validateParameter(valid_601554, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601554 != nil:
    section.add "Action", valid_601554
  var valid_601555 = query.getOrDefault("Version")
  valid_601555 = validateParameter(valid_601555, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601555 != nil:
    section.add "Version", valid_601555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601556 = header.getOrDefault("X-Amz-Date")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Date", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Security-Token")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Security-Token", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Content-Sha256", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-Algorithm")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-Algorithm", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Signature")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Signature", valid_601560
  var valid_601561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601561 = validateParameter(valid_601561, JString, required = false,
                                 default = nil)
  if valid_601561 != nil:
    section.add "X-Amz-SignedHeaders", valid_601561
  var valid_601562 = header.getOrDefault("X-Amz-Credential")
  valid_601562 = validateParameter(valid_601562, JString, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "X-Amz-Credential", valid_601562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601563: Call_GetListTagsForResource_601549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601563.validator(path, query, header, formData, body)
  let scheme = call_601563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601563.url(scheme.get, call_601563.host, call_601563.base,
                         call_601563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601563, url, valid)

proc call*(call_601564: Call_GetListTagsForResource_601549; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601565 = newJObject()
  if Filters != nil:
    query_601565.add "Filters", Filters
  add(query_601565, "ResourceName", newJString(ResourceName))
  add(query_601565, "Action", newJString(Action))
  add(query_601565, "Version", newJString(Version))
  result = call_601564.call(nil, query_601565, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_601549(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_601550, base: "/",
    url: url_GetListTagsForResource_601551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_601620 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBInstance_601622(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_601621(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601623 = query.getOrDefault("Action")
  valid_601623 = validateParameter(valid_601623, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601623 != nil:
    section.add "Action", valid_601623
  var valid_601624 = query.getOrDefault("Version")
  valid_601624 = validateParameter(valid_601624, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601624 != nil:
    section.add "Version", valid_601624
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601625 = header.getOrDefault("X-Amz-Date")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Date", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Security-Token")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Security-Token", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Content-Sha256", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Algorithm")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Algorithm", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Signature")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Signature", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-SignedHeaders", valid_601630
  var valid_601631 = header.getOrDefault("X-Amz-Credential")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Credential", valid_601631
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
  var valid_601632 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "PreferredMaintenanceWindow", valid_601632
  var valid_601633 = formData.getOrDefault("DBSecurityGroups")
  valid_601633 = validateParameter(valid_601633, JArray, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "DBSecurityGroups", valid_601633
  var valid_601634 = formData.getOrDefault("ApplyImmediately")
  valid_601634 = validateParameter(valid_601634, JBool, required = false, default = nil)
  if valid_601634 != nil:
    section.add "ApplyImmediately", valid_601634
  var valid_601635 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601635 = validateParameter(valid_601635, JArray, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "VpcSecurityGroupIds", valid_601635
  var valid_601636 = formData.getOrDefault("Iops")
  valid_601636 = validateParameter(valid_601636, JInt, required = false, default = nil)
  if valid_601636 != nil:
    section.add "Iops", valid_601636
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601637 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601637 = validateParameter(valid_601637, JString, required = true,
                                 default = nil)
  if valid_601637 != nil:
    section.add "DBInstanceIdentifier", valid_601637
  var valid_601638 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601638 = validateParameter(valid_601638, JInt, required = false, default = nil)
  if valid_601638 != nil:
    section.add "BackupRetentionPeriod", valid_601638
  var valid_601639 = formData.getOrDefault("DBParameterGroupName")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "DBParameterGroupName", valid_601639
  var valid_601640 = formData.getOrDefault("OptionGroupName")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "OptionGroupName", valid_601640
  var valid_601641 = formData.getOrDefault("MasterUserPassword")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "MasterUserPassword", valid_601641
  var valid_601642 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "NewDBInstanceIdentifier", valid_601642
  var valid_601643 = formData.getOrDefault("TdeCredentialArn")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "TdeCredentialArn", valid_601643
  var valid_601644 = formData.getOrDefault("TdeCredentialPassword")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "TdeCredentialPassword", valid_601644
  var valid_601645 = formData.getOrDefault("MultiAZ")
  valid_601645 = validateParameter(valid_601645, JBool, required = false, default = nil)
  if valid_601645 != nil:
    section.add "MultiAZ", valid_601645
  var valid_601646 = formData.getOrDefault("AllocatedStorage")
  valid_601646 = validateParameter(valid_601646, JInt, required = false, default = nil)
  if valid_601646 != nil:
    section.add "AllocatedStorage", valid_601646
  var valid_601647 = formData.getOrDefault("StorageType")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "StorageType", valid_601647
  var valid_601648 = formData.getOrDefault("DBInstanceClass")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "DBInstanceClass", valid_601648
  var valid_601649 = formData.getOrDefault("PreferredBackupWindow")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "PreferredBackupWindow", valid_601649
  var valid_601650 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601650 = validateParameter(valid_601650, JBool, required = false, default = nil)
  if valid_601650 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601650
  var valid_601651 = formData.getOrDefault("EngineVersion")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "EngineVersion", valid_601651
  var valid_601652 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_601652 = validateParameter(valid_601652, JBool, required = false, default = nil)
  if valid_601652 != nil:
    section.add "AllowMajorVersionUpgrade", valid_601652
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601653: Call_PostModifyDBInstance_601620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601653.validator(path, query, header, formData, body)
  let scheme = call_601653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601653.url(scheme.get, call_601653.host, call_601653.base,
                         call_601653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601653, url, valid)

proc call*(call_601654: Call_PostModifyDBInstance_601620;
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
  var query_601655 = newJObject()
  var formData_601656 = newJObject()
  add(formData_601656, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_601656.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601656, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_601656.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601656, "Iops", newJInt(Iops))
  add(formData_601656, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601656, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601656, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601656, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601656, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601656, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_601656, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_601656, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_601656, "MultiAZ", newJBool(MultiAZ))
  add(query_601655, "Action", newJString(Action))
  add(formData_601656, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601656, "StorageType", newJString(StorageType))
  add(formData_601656, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601656, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601656, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601656, "EngineVersion", newJString(EngineVersion))
  add(query_601655, "Version", newJString(Version))
  add(formData_601656, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_601654.call(nil, query_601655, nil, formData_601656, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_601620(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_601621, base: "/",
    url: url_PostModifyDBInstance_601622, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_601584 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBInstance_601586(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_601585(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_601587 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "PreferredMaintenanceWindow", valid_601587
  var valid_601588 = query.getOrDefault("AllocatedStorage")
  valid_601588 = validateParameter(valid_601588, JInt, required = false, default = nil)
  if valid_601588 != nil:
    section.add "AllocatedStorage", valid_601588
  var valid_601589 = query.getOrDefault("StorageType")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "StorageType", valid_601589
  var valid_601590 = query.getOrDefault("OptionGroupName")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "OptionGroupName", valid_601590
  var valid_601591 = query.getOrDefault("DBSecurityGroups")
  valid_601591 = validateParameter(valid_601591, JArray, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "DBSecurityGroups", valid_601591
  var valid_601592 = query.getOrDefault("MasterUserPassword")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "MasterUserPassword", valid_601592
  var valid_601593 = query.getOrDefault("Iops")
  valid_601593 = validateParameter(valid_601593, JInt, required = false, default = nil)
  if valid_601593 != nil:
    section.add "Iops", valid_601593
  var valid_601594 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601594 = validateParameter(valid_601594, JArray, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "VpcSecurityGroupIds", valid_601594
  var valid_601595 = query.getOrDefault("MultiAZ")
  valid_601595 = validateParameter(valid_601595, JBool, required = false, default = nil)
  if valid_601595 != nil:
    section.add "MultiAZ", valid_601595
  var valid_601596 = query.getOrDefault("TdeCredentialPassword")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "TdeCredentialPassword", valid_601596
  var valid_601597 = query.getOrDefault("BackupRetentionPeriod")
  valid_601597 = validateParameter(valid_601597, JInt, required = false, default = nil)
  if valid_601597 != nil:
    section.add "BackupRetentionPeriod", valid_601597
  var valid_601598 = query.getOrDefault("DBParameterGroupName")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "DBParameterGroupName", valid_601598
  var valid_601599 = query.getOrDefault("DBInstanceClass")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "DBInstanceClass", valid_601599
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601600 = query.getOrDefault("Action")
  valid_601600 = validateParameter(valid_601600, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601600 != nil:
    section.add "Action", valid_601600
  var valid_601601 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_601601 = validateParameter(valid_601601, JBool, required = false, default = nil)
  if valid_601601 != nil:
    section.add "AllowMajorVersionUpgrade", valid_601601
  var valid_601602 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "NewDBInstanceIdentifier", valid_601602
  var valid_601603 = query.getOrDefault("TdeCredentialArn")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "TdeCredentialArn", valid_601603
  var valid_601604 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601604 = validateParameter(valid_601604, JBool, required = false, default = nil)
  if valid_601604 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601604
  var valid_601605 = query.getOrDefault("EngineVersion")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "EngineVersion", valid_601605
  var valid_601606 = query.getOrDefault("PreferredBackupWindow")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "PreferredBackupWindow", valid_601606
  var valid_601607 = query.getOrDefault("Version")
  valid_601607 = validateParameter(valid_601607, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601607 != nil:
    section.add "Version", valid_601607
  var valid_601608 = query.getOrDefault("DBInstanceIdentifier")
  valid_601608 = validateParameter(valid_601608, JString, required = true,
                                 default = nil)
  if valid_601608 != nil:
    section.add "DBInstanceIdentifier", valid_601608
  var valid_601609 = query.getOrDefault("ApplyImmediately")
  valid_601609 = validateParameter(valid_601609, JBool, required = false, default = nil)
  if valid_601609 != nil:
    section.add "ApplyImmediately", valid_601609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601610 = header.getOrDefault("X-Amz-Date")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Date", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Security-Token")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Security-Token", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Content-Sha256", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Algorithm")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Algorithm", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Signature")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Signature", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-SignedHeaders", valid_601615
  var valid_601616 = header.getOrDefault("X-Amz-Credential")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Credential", valid_601616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601617: Call_GetModifyDBInstance_601584; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601617.validator(path, query, header, formData, body)
  let scheme = call_601617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601617.url(scheme.get, call_601617.host, call_601617.base,
                         call_601617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601617, url, valid)

proc call*(call_601618: Call_GetModifyDBInstance_601584;
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
  var query_601619 = newJObject()
  add(query_601619, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601619, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601619, "StorageType", newJString(StorageType))
  add(query_601619, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601619.add "DBSecurityGroups", DBSecurityGroups
  add(query_601619, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601619, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601619.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601619, "MultiAZ", newJBool(MultiAZ))
  add(query_601619, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_601619, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601619, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601619, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601619, "Action", newJString(Action))
  add(query_601619, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_601619, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_601619, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_601619, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601619, "EngineVersion", newJString(EngineVersion))
  add(query_601619, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601619, "Version", newJString(Version))
  add(query_601619, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601619, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_601618.call(nil, query_601619, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_601584(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_601585, base: "/",
    url: url_GetModifyDBInstance_601586, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_601674 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBParameterGroup_601676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_601675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601677 = query.getOrDefault("Action")
  valid_601677 = validateParameter(valid_601677, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_601677 != nil:
    section.add "Action", valid_601677
  var valid_601678 = query.getOrDefault("Version")
  valid_601678 = validateParameter(valid_601678, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601678 != nil:
    section.add "Version", valid_601678
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601679 = header.getOrDefault("X-Amz-Date")
  valid_601679 = validateParameter(valid_601679, JString, required = false,
                                 default = nil)
  if valid_601679 != nil:
    section.add "X-Amz-Date", valid_601679
  var valid_601680 = header.getOrDefault("X-Amz-Security-Token")
  valid_601680 = validateParameter(valid_601680, JString, required = false,
                                 default = nil)
  if valid_601680 != nil:
    section.add "X-Amz-Security-Token", valid_601680
  var valid_601681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601681 = validateParameter(valid_601681, JString, required = false,
                                 default = nil)
  if valid_601681 != nil:
    section.add "X-Amz-Content-Sha256", valid_601681
  var valid_601682 = header.getOrDefault("X-Amz-Algorithm")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Algorithm", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Signature")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Signature", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-SignedHeaders", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Credential")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Credential", valid_601685
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601686 = formData.getOrDefault("DBParameterGroupName")
  valid_601686 = validateParameter(valid_601686, JString, required = true,
                                 default = nil)
  if valid_601686 != nil:
    section.add "DBParameterGroupName", valid_601686
  var valid_601687 = formData.getOrDefault("Parameters")
  valid_601687 = validateParameter(valid_601687, JArray, required = true, default = nil)
  if valid_601687 != nil:
    section.add "Parameters", valid_601687
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601688: Call_PostModifyDBParameterGroup_601674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601688.validator(path, query, header, formData, body)
  let scheme = call_601688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601688.url(scheme.get, call_601688.host, call_601688.base,
                         call_601688.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601688, url, valid)

proc call*(call_601689: Call_PostModifyDBParameterGroup_601674;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601690 = newJObject()
  var formData_601691 = newJObject()
  add(formData_601691, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_601691.add "Parameters", Parameters
  add(query_601690, "Action", newJString(Action))
  add(query_601690, "Version", newJString(Version))
  result = call_601689.call(nil, query_601690, nil, formData_601691, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_601674(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_601675, base: "/",
    url: url_PostModifyDBParameterGroup_601676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_601657 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBParameterGroup_601659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_601658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601660 = query.getOrDefault("DBParameterGroupName")
  valid_601660 = validateParameter(valid_601660, JString, required = true,
                                 default = nil)
  if valid_601660 != nil:
    section.add "DBParameterGroupName", valid_601660
  var valid_601661 = query.getOrDefault("Parameters")
  valid_601661 = validateParameter(valid_601661, JArray, required = true, default = nil)
  if valid_601661 != nil:
    section.add "Parameters", valid_601661
  var valid_601662 = query.getOrDefault("Action")
  valid_601662 = validateParameter(valid_601662, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_601662 != nil:
    section.add "Action", valid_601662
  var valid_601663 = query.getOrDefault("Version")
  valid_601663 = validateParameter(valid_601663, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601663 != nil:
    section.add "Version", valid_601663
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601664 = header.getOrDefault("X-Amz-Date")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Date", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Security-Token")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Security-Token", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Content-Sha256", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-Algorithm")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Algorithm", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Signature")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Signature", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-SignedHeaders", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Credential")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Credential", valid_601670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601671: Call_GetModifyDBParameterGroup_601657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601671.validator(path, query, header, formData, body)
  let scheme = call_601671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601671.url(scheme.get, call_601671.host, call_601671.base,
                         call_601671.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601671, url, valid)

proc call*(call_601672: Call_GetModifyDBParameterGroup_601657;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601673 = newJObject()
  add(query_601673, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_601673.add "Parameters", Parameters
  add(query_601673, "Action", newJString(Action))
  add(query_601673, "Version", newJString(Version))
  result = call_601672.call(nil, query_601673, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_601657(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_601658, base: "/",
    url: url_GetModifyDBParameterGroup_601659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_601710 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBSubnetGroup_601712(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_601711(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601713 = query.getOrDefault("Action")
  valid_601713 = validateParameter(valid_601713, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601713 != nil:
    section.add "Action", valid_601713
  var valid_601714 = query.getOrDefault("Version")
  valid_601714 = validateParameter(valid_601714, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601714 != nil:
    section.add "Version", valid_601714
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601715 = header.getOrDefault("X-Amz-Date")
  valid_601715 = validateParameter(valid_601715, JString, required = false,
                                 default = nil)
  if valid_601715 != nil:
    section.add "X-Amz-Date", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Security-Token")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Security-Token", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Content-Sha256", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Algorithm")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Algorithm", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-Signature")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-Signature", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-SignedHeaders", valid_601720
  var valid_601721 = header.getOrDefault("X-Amz-Credential")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Credential", valid_601721
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601722 = formData.getOrDefault("DBSubnetGroupName")
  valid_601722 = validateParameter(valid_601722, JString, required = true,
                                 default = nil)
  if valid_601722 != nil:
    section.add "DBSubnetGroupName", valid_601722
  var valid_601723 = formData.getOrDefault("SubnetIds")
  valid_601723 = validateParameter(valid_601723, JArray, required = true, default = nil)
  if valid_601723 != nil:
    section.add "SubnetIds", valid_601723
  var valid_601724 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "DBSubnetGroupDescription", valid_601724
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601725: Call_PostModifyDBSubnetGroup_601710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601725.validator(path, query, header, formData, body)
  let scheme = call_601725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601725.url(scheme.get, call_601725.host, call_601725.base,
                         call_601725.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601725, url, valid)

proc call*(call_601726: Call_PostModifyDBSubnetGroup_601710;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_601727 = newJObject()
  var formData_601728 = newJObject()
  add(formData_601728, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601728.add "SubnetIds", SubnetIds
  add(query_601727, "Action", newJString(Action))
  add(formData_601728, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601727, "Version", newJString(Version))
  result = call_601726.call(nil, query_601727, nil, formData_601728, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_601710(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_601711, base: "/",
    url: url_PostModifyDBSubnetGroup_601712, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_601692 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBSubnetGroup_601694(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_601693(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601695 = query.getOrDefault("Action")
  valid_601695 = validateParameter(valid_601695, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601695 != nil:
    section.add "Action", valid_601695
  var valid_601696 = query.getOrDefault("DBSubnetGroupName")
  valid_601696 = validateParameter(valid_601696, JString, required = true,
                                 default = nil)
  if valid_601696 != nil:
    section.add "DBSubnetGroupName", valid_601696
  var valid_601697 = query.getOrDefault("SubnetIds")
  valid_601697 = validateParameter(valid_601697, JArray, required = true, default = nil)
  if valid_601697 != nil:
    section.add "SubnetIds", valid_601697
  var valid_601698 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "DBSubnetGroupDescription", valid_601698
  var valid_601699 = query.getOrDefault("Version")
  valid_601699 = validateParameter(valid_601699, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601699 != nil:
    section.add "Version", valid_601699
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601700 = header.getOrDefault("X-Amz-Date")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-Date", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Security-Token")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Security-Token", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Content-Sha256", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Algorithm")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Algorithm", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-Signature")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Signature", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-SignedHeaders", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Credential")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Credential", valid_601706
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601707: Call_GetModifyDBSubnetGroup_601692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601707.validator(path, query, header, formData, body)
  let scheme = call_601707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601707.url(scheme.get, call_601707.host, call_601707.base,
                         call_601707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601707, url, valid)

proc call*(call_601708: Call_GetModifyDBSubnetGroup_601692;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_601709 = newJObject()
  add(query_601709, "Action", newJString(Action))
  add(query_601709, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601709.add "SubnetIds", SubnetIds
  add(query_601709, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601709, "Version", newJString(Version))
  result = call_601708.call(nil, query_601709, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_601692(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_601693, base: "/",
    url: url_GetModifyDBSubnetGroup_601694, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_601749 = ref object of OpenApiRestCall_599352
proc url_PostModifyEventSubscription_601751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_601750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601752 = query.getOrDefault("Action")
  valid_601752 = validateParameter(valid_601752, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_601752 != nil:
    section.add "Action", valid_601752
  var valid_601753 = query.getOrDefault("Version")
  valid_601753 = validateParameter(valid_601753, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601753 != nil:
    section.add "Version", valid_601753
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601754 = header.getOrDefault("X-Amz-Date")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "X-Amz-Date", valid_601754
  var valid_601755 = header.getOrDefault("X-Amz-Security-Token")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-Security-Token", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Content-Sha256", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-Algorithm")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Algorithm", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Signature")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Signature", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-SignedHeaders", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Credential")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Credential", valid_601760
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_601761 = formData.getOrDefault("Enabled")
  valid_601761 = validateParameter(valid_601761, JBool, required = false, default = nil)
  if valid_601761 != nil:
    section.add "Enabled", valid_601761
  var valid_601762 = formData.getOrDefault("EventCategories")
  valid_601762 = validateParameter(valid_601762, JArray, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "EventCategories", valid_601762
  var valid_601763 = formData.getOrDefault("SnsTopicArn")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "SnsTopicArn", valid_601763
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601764 = formData.getOrDefault("SubscriptionName")
  valid_601764 = validateParameter(valid_601764, JString, required = true,
                                 default = nil)
  if valid_601764 != nil:
    section.add "SubscriptionName", valid_601764
  var valid_601765 = formData.getOrDefault("SourceType")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "SourceType", valid_601765
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601766: Call_PostModifyEventSubscription_601749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601766.validator(path, query, header, formData, body)
  let scheme = call_601766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601766.url(scheme.get, call_601766.host, call_601766.base,
                         call_601766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601766, url, valid)

proc call*(call_601767: Call_PostModifyEventSubscription_601749;
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
  var query_601768 = newJObject()
  var formData_601769 = newJObject()
  add(formData_601769, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601769.add "EventCategories", EventCategories
  add(formData_601769, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_601769, "SubscriptionName", newJString(SubscriptionName))
  add(query_601768, "Action", newJString(Action))
  add(query_601768, "Version", newJString(Version))
  add(formData_601769, "SourceType", newJString(SourceType))
  result = call_601767.call(nil, query_601768, nil, formData_601769, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_601749(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_601750, base: "/",
    url: url_PostModifyEventSubscription_601751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_601729 = ref object of OpenApiRestCall_599352
proc url_GetModifyEventSubscription_601731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_601730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601732 = query.getOrDefault("SourceType")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "SourceType", valid_601732
  var valid_601733 = query.getOrDefault("Enabled")
  valid_601733 = validateParameter(valid_601733, JBool, required = false, default = nil)
  if valid_601733 != nil:
    section.add "Enabled", valid_601733
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601734 = query.getOrDefault("Action")
  valid_601734 = validateParameter(valid_601734, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_601734 != nil:
    section.add "Action", valid_601734
  var valid_601735 = query.getOrDefault("SnsTopicArn")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "SnsTopicArn", valid_601735
  var valid_601736 = query.getOrDefault("EventCategories")
  valid_601736 = validateParameter(valid_601736, JArray, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "EventCategories", valid_601736
  var valid_601737 = query.getOrDefault("SubscriptionName")
  valid_601737 = validateParameter(valid_601737, JString, required = true,
                                 default = nil)
  if valid_601737 != nil:
    section.add "SubscriptionName", valid_601737
  var valid_601738 = query.getOrDefault("Version")
  valid_601738 = validateParameter(valid_601738, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601738 != nil:
    section.add "Version", valid_601738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601739 = header.getOrDefault("X-Amz-Date")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Date", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Security-Token")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Security-Token", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Content-Sha256", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Algorithm")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Algorithm", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Signature")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Signature", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-SignedHeaders", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Credential")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Credential", valid_601745
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601746: Call_GetModifyEventSubscription_601729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601746.validator(path, query, header, formData, body)
  let scheme = call_601746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601746.url(scheme.get, call_601746.host, call_601746.base,
                         call_601746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601746, url, valid)

proc call*(call_601747: Call_GetModifyEventSubscription_601729;
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
  var query_601748 = newJObject()
  add(query_601748, "SourceType", newJString(SourceType))
  add(query_601748, "Enabled", newJBool(Enabled))
  add(query_601748, "Action", newJString(Action))
  add(query_601748, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601748.add "EventCategories", EventCategories
  add(query_601748, "SubscriptionName", newJString(SubscriptionName))
  add(query_601748, "Version", newJString(Version))
  result = call_601747.call(nil, query_601748, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_601729(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_601730, base: "/",
    url: url_GetModifyEventSubscription_601731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_601789 = ref object of OpenApiRestCall_599352
proc url_PostModifyOptionGroup_601791(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_601790(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601792 = query.getOrDefault("Action")
  valid_601792 = validateParameter(valid_601792, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_601792 != nil:
    section.add "Action", valid_601792
  var valid_601793 = query.getOrDefault("Version")
  valid_601793 = validateParameter(valid_601793, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601793 != nil:
    section.add "Version", valid_601793
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601794 = header.getOrDefault("X-Amz-Date")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Date", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Security-Token")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Security-Token", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Content-Sha256", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Algorithm")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Algorithm", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Signature")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Signature", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-SignedHeaders", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-Credential")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Credential", valid_601800
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_601801 = formData.getOrDefault("OptionsToRemove")
  valid_601801 = validateParameter(valid_601801, JArray, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "OptionsToRemove", valid_601801
  var valid_601802 = formData.getOrDefault("ApplyImmediately")
  valid_601802 = validateParameter(valid_601802, JBool, required = false, default = nil)
  if valid_601802 != nil:
    section.add "ApplyImmediately", valid_601802
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601803 = formData.getOrDefault("OptionGroupName")
  valid_601803 = validateParameter(valid_601803, JString, required = true,
                                 default = nil)
  if valid_601803 != nil:
    section.add "OptionGroupName", valid_601803
  var valid_601804 = formData.getOrDefault("OptionsToInclude")
  valid_601804 = validateParameter(valid_601804, JArray, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "OptionsToInclude", valid_601804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601805: Call_PostModifyOptionGroup_601789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601805.validator(path, query, header, formData, body)
  let scheme = call_601805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601805.url(scheme.get, call_601805.host, call_601805.base,
                         call_601805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601805, url, valid)

proc call*(call_601806: Call_PostModifyOptionGroup_601789; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601807 = newJObject()
  var formData_601808 = newJObject()
  if OptionsToRemove != nil:
    formData_601808.add "OptionsToRemove", OptionsToRemove
  add(formData_601808, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_601808, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_601808.add "OptionsToInclude", OptionsToInclude
  add(query_601807, "Action", newJString(Action))
  add(query_601807, "Version", newJString(Version))
  result = call_601806.call(nil, query_601807, nil, formData_601808, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_601789(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_601790, base: "/",
    url: url_PostModifyOptionGroup_601791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_601770 = ref object of OpenApiRestCall_599352
proc url_GetModifyOptionGroup_601772(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_601771(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601773 = query.getOrDefault("OptionGroupName")
  valid_601773 = validateParameter(valid_601773, JString, required = true,
                                 default = nil)
  if valid_601773 != nil:
    section.add "OptionGroupName", valid_601773
  var valid_601774 = query.getOrDefault("OptionsToRemove")
  valid_601774 = validateParameter(valid_601774, JArray, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "OptionsToRemove", valid_601774
  var valid_601775 = query.getOrDefault("Action")
  valid_601775 = validateParameter(valid_601775, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_601775 != nil:
    section.add "Action", valid_601775
  var valid_601776 = query.getOrDefault("Version")
  valid_601776 = validateParameter(valid_601776, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601776 != nil:
    section.add "Version", valid_601776
  var valid_601777 = query.getOrDefault("ApplyImmediately")
  valid_601777 = validateParameter(valid_601777, JBool, required = false, default = nil)
  if valid_601777 != nil:
    section.add "ApplyImmediately", valid_601777
  var valid_601778 = query.getOrDefault("OptionsToInclude")
  valid_601778 = validateParameter(valid_601778, JArray, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "OptionsToInclude", valid_601778
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601779 = header.getOrDefault("X-Amz-Date")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Date", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Security-Token")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Security-Token", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Content-Sha256", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-Algorithm")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-Algorithm", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Signature")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Signature", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-SignedHeaders", valid_601784
  var valid_601785 = header.getOrDefault("X-Amz-Credential")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "X-Amz-Credential", valid_601785
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601786: Call_GetModifyOptionGroup_601770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601786.validator(path, query, header, formData, body)
  let scheme = call_601786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601786.url(scheme.get, call_601786.host, call_601786.base,
                         call_601786.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601786, url, valid)

proc call*(call_601787: Call_GetModifyOptionGroup_601770; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2014-09-01"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_601788 = newJObject()
  add(query_601788, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_601788.add "OptionsToRemove", OptionsToRemove
  add(query_601788, "Action", newJString(Action))
  add(query_601788, "Version", newJString(Version))
  add(query_601788, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_601788.add "OptionsToInclude", OptionsToInclude
  result = call_601787.call(nil, query_601788, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_601770(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_601771, base: "/",
    url: url_GetModifyOptionGroup_601772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_601827 = ref object of OpenApiRestCall_599352
proc url_PostPromoteReadReplica_601829(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_601828(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601830 = query.getOrDefault("Action")
  valid_601830 = validateParameter(valid_601830, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_601830 != nil:
    section.add "Action", valid_601830
  var valid_601831 = query.getOrDefault("Version")
  valid_601831 = validateParameter(valid_601831, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601831 != nil:
    section.add "Version", valid_601831
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601832 = header.getOrDefault("X-Amz-Date")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-Date", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Security-Token")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Security-Token", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Content-Sha256", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Algorithm")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Algorithm", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Signature")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Signature", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-SignedHeaders", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Credential")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Credential", valid_601838
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601839 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601839 = validateParameter(valid_601839, JString, required = true,
                                 default = nil)
  if valid_601839 != nil:
    section.add "DBInstanceIdentifier", valid_601839
  var valid_601840 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601840 = validateParameter(valid_601840, JInt, required = false, default = nil)
  if valid_601840 != nil:
    section.add "BackupRetentionPeriod", valid_601840
  var valid_601841 = formData.getOrDefault("PreferredBackupWindow")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "PreferredBackupWindow", valid_601841
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601842: Call_PostPromoteReadReplica_601827; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601842.validator(path, query, header, formData, body)
  let scheme = call_601842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601842.url(scheme.get, call_601842.host, call_601842.base,
                         call_601842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601842, url, valid)

proc call*(call_601843: Call_PostPromoteReadReplica_601827;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_601844 = newJObject()
  var formData_601845 = newJObject()
  add(formData_601845, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601845, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601844, "Action", newJString(Action))
  add(formData_601845, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601844, "Version", newJString(Version))
  result = call_601843.call(nil, query_601844, nil, formData_601845, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_601827(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_601828, base: "/",
    url: url_PostPromoteReadReplica_601829, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_601809 = ref object of OpenApiRestCall_599352
proc url_GetPromoteReadReplica_601811(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_601810(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601812 = query.getOrDefault("BackupRetentionPeriod")
  valid_601812 = validateParameter(valid_601812, JInt, required = false, default = nil)
  if valid_601812 != nil:
    section.add "BackupRetentionPeriod", valid_601812
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601813 = query.getOrDefault("Action")
  valid_601813 = validateParameter(valid_601813, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_601813 != nil:
    section.add "Action", valid_601813
  var valid_601814 = query.getOrDefault("PreferredBackupWindow")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "PreferredBackupWindow", valid_601814
  var valid_601815 = query.getOrDefault("Version")
  valid_601815 = validateParameter(valid_601815, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601815 != nil:
    section.add "Version", valid_601815
  var valid_601816 = query.getOrDefault("DBInstanceIdentifier")
  valid_601816 = validateParameter(valid_601816, JString, required = true,
                                 default = nil)
  if valid_601816 != nil:
    section.add "DBInstanceIdentifier", valid_601816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601817 = header.getOrDefault("X-Amz-Date")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Date", valid_601817
  var valid_601818 = header.getOrDefault("X-Amz-Security-Token")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Security-Token", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Content-Sha256", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-Algorithm")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Algorithm", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Signature")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Signature", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-SignedHeaders", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Credential")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Credential", valid_601823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601824: Call_GetPromoteReadReplica_601809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601824.validator(path, query, header, formData, body)
  let scheme = call_601824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601824.url(scheme.get, call_601824.host, call_601824.base,
                         call_601824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601824, url, valid)

proc call*(call_601825: Call_GetPromoteReadReplica_601809;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601826 = newJObject()
  add(query_601826, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601826, "Action", newJString(Action))
  add(query_601826, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601826, "Version", newJString(Version))
  add(query_601826, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601825.call(nil, query_601826, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_601809(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_601810, base: "/",
    url: url_GetPromoteReadReplica_601811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_601865 = ref object of OpenApiRestCall_599352
proc url_PostPurchaseReservedDBInstancesOffering_601867(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_601866(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601868 = query.getOrDefault("Action")
  valid_601868 = validateParameter(valid_601868, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_601868 != nil:
    section.add "Action", valid_601868
  var valid_601869 = query.getOrDefault("Version")
  valid_601869 = validateParameter(valid_601869, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601869 != nil:
    section.add "Version", valid_601869
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601870 = header.getOrDefault("X-Amz-Date")
  valid_601870 = validateParameter(valid_601870, JString, required = false,
                                 default = nil)
  if valid_601870 != nil:
    section.add "X-Amz-Date", valid_601870
  var valid_601871 = header.getOrDefault("X-Amz-Security-Token")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "X-Amz-Security-Token", valid_601871
  var valid_601872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601872 = validateParameter(valid_601872, JString, required = false,
                                 default = nil)
  if valid_601872 != nil:
    section.add "X-Amz-Content-Sha256", valid_601872
  var valid_601873 = header.getOrDefault("X-Amz-Algorithm")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "X-Amz-Algorithm", valid_601873
  var valid_601874 = header.getOrDefault("X-Amz-Signature")
  valid_601874 = validateParameter(valid_601874, JString, required = false,
                                 default = nil)
  if valid_601874 != nil:
    section.add "X-Amz-Signature", valid_601874
  var valid_601875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-SignedHeaders", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Credential")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Credential", valid_601876
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_601877 = formData.getOrDefault("ReservedDBInstanceId")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "ReservedDBInstanceId", valid_601877
  var valid_601878 = formData.getOrDefault("Tags")
  valid_601878 = validateParameter(valid_601878, JArray, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "Tags", valid_601878
  var valid_601879 = formData.getOrDefault("DBInstanceCount")
  valid_601879 = validateParameter(valid_601879, JInt, required = false, default = nil)
  if valid_601879 != nil:
    section.add "DBInstanceCount", valid_601879
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_601880 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601880 = validateParameter(valid_601880, JString, required = true,
                                 default = nil)
  if valid_601880 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601880
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601881: Call_PostPurchaseReservedDBInstancesOffering_601865;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601881.validator(path, query, header, formData, body)
  let scheme = call_601881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601881.url(scheme.get, call_601881.host, call_601881.base,
                         call_601881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601881, url, valid)

proc call*(call_601882: Call_PostPurchaseReservedDBInstancesOffering_601865;
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
  var query_601883 = newJObject()
  var formData_601884 = newJObject()
  add(formData_601884, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_601884.add "Tags", Tags
  add(formData_601884, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_601883, "Action", newJString(Action))
  add(formData_601884, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601883, "Version", newJString(Version))
  result = call_601882.call(nil, query_601883, nil, formData_601884, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_601865(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_601866, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_601867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_601846 = ref object of OpenApiRestCall_599352
proc url_GetPurchaseReservedDBInstancesOffering_601848(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_601847(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601849 = query.getOrDefault("DBInstanceCount")
  valid_601849 = validateParameter(valid_601849, JInt, required = false, default = nil)
  if valid_601849 != nil:
    section.add "DBInstanceCount", valid_601849
  var valid_601850 = query.getOrDefault("Tags")
  valid_601850 = validateParameter(valid_601850, JArray, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "Tags", valid_601850
  var valid_601851 = query.getOrDefault("ReservedDBInstanceId")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "ReservedDBInstanceId", valid_601851
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_601852 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601852 = validateParameter(valid_601852, JString, required = true,
                                 default = nil)
  if valid_601852 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601852
  var valid_601853 = query.getOrDefault("Action")
  valid_601853 = validateParameter(valid_601853, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_601853 != nil:
    section.add "Action", valid_601853
  var valid_601854 = query.getOrDefault("Version")
  valid_601854 = validateParameter(valid_601854, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601854 != nil:
    section.add "Version", valid_601854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601855 = header.getOrDefault("X-Amz-Date")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-Date", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Security-Token")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Security-Token", valid_601856
  var valid_601857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "X-Amz-Content-Sha256", valid_601857
  var valid_601858 = header.getOrDefault("X-Amz-Algorithm")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "X-Amz-Algorithm", valid_601858
  var valid_601859 = header.getOrDefault("X-Amz-Signature")
  valid_601859 = validateParameter(valid_601859, JString, required = false,
                                 default = nil)
  if valid_601859 != nil:
    section.add "X-Amz-Signature", valid_601859
  var valid_601860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-SignedHeaders", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Credential")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Credential", valid_601861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601862: Call_GetPurchaseReservedDBInstancesOffering_601846;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601862.validator(path, query, header, formData, body)
  let scheme = call_601862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601862.url(scheme.get, call_601862.host, call_601862.base,
                         call_601862.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601862, url, valid)

proc call*(call_601863: Call_GetPurchaseReservedDBInstancesOffering_601846;
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
  var query_601864 = newJObject()
  add(query_601864, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_601864.add "Tags", Tags
  add(query_601864, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_601864, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601864, "Action", newJString(Action))
  add(query_601864, "Version", newJString(Version))
  result = call_601863.call(nil, query_601864, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_601846(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_601847, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_601848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_601902 = ref object of OpenApiRestCall_599352
proc url_PostRebootDBInstance_601904(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_601903(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601905 = query.getOrDefault("Action")
  valid_601905 = validateParameter(valid_601905, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601905 != nil:
    section.add "Action", valid_601905
  var valid_601906 = query.getOrDefault("Version")
  valid_601906 = validateParameter(valid_601906, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601906 != nil:
    section.add "Version", valid_601906
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601907 = header.getOrDefault("X-Amz-Date")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-Date", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-Security-Token")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Security-Token", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Content-Sha256", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Algorithm")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Algorithm", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Signature")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Signature", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-SignedHeaders", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Credential")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Credential", valid_601913
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601914 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601914 = validateParameter(valid_601914, JString, required = true,
                                 default = nil)
  if valid_601914 != nil:
    section.add "DBInstanceIdentifier", valid_601914
  var valid_601915 = formData.getOrDefault("ForceFailover")
  valid_601915 = validateParameter(valid_601915, JBool, required = false, default = nil)
  if valid_601915 != nil:
    section.add "ForceFailover", valid_601915
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601916: Call_PostRebootDBInstance_601902; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601916.validator(path, query, header, formData, body)
  let scheme = call_601916.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601916.url(scheme.get, call_601916.host, call_601916.base,
                         call_601916.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601916, url, valid)

proc call*(call_601917: Call_PostRebootDBInstance_601902;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_601918 = newJObject()
  var formData_601919 = newJObject()
  add(formData_601919, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601918, "Action", newJString(Action))
  add(formData_601919, "ForceFailover", newJBool(ForceFailover))
  add(query_601918, "Version", newJString(Version))
  result = call_601917.call(nil, query_601918, nil, formData_601919, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_601902(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_601903, base: "/",
    url: url_PostRebootDBInstance_601904, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_601885 = ref object of OpenApiRestCall_599352
proc url_GetRebootDBInstance_601887(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_601886(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601888 = query.getOrDefault("Action")
  valid_601888 = validateParameter(valid_601888, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601888 != nil:
    section.add "Action", valid_601888
  var valid_601889 = query.getOrDefault("ForceFailover")
  valid_601889 = validateParameter(valid_601889, JBool, required = false, default = nil)
  if valid_601889 != nil:
    section.add "ForceFailover", valid_601889
  var valid_601890 = query.getOrDefault("Version")
  valid_601890 = validateParameter(valid_601890, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601890 != nil:
    section.add "Version", valid_601890
  var valid_601891 = query.getOrDefault("DBInstanceIdentifier")
  valid_601891 = validateParameter(valid_601891, JString, required = true,
                                 default = nil)
  if valid_601891 != nil:
    section.add "DBInstanceIdentifier", valid_601891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601892 = header.getOrDefault("X-Amz-Date")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "X-Amz-Date", valid_601892
  var valid_601893 = header.getOrDefault("X-Amz-Security-Token")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "X-Amz-Security-Token", valid_601893
  var valid_601894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601894 = validateParameter(valid_601894, JString, required = false,
                                 default = nil)
  if valid_601894 != nil:
    section.add "X-Amz-Content-Sha256", valid_601894
  var valid_601895 = header.getOrDefault("X-Amz-Algorithm")
  valid_601895 = validateParameter(valid_601895, JString, required = false,
                                 default = nil)
  if valid_601895 != nil:
    section.add "X-Amz-Algorithm", valid_601895
  var valid_601896 = header.getOrDefault("X-Amz-Signature")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "X-Amz-Signature", valid_601896
  var valid_601897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601897 = validateParameter(valid_601897, JString, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "X-Amz-SignedHeaders", valid_601897
  var valid_601898 = header.getOrDefault("X-Amz-Credential")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "X-Amz-Credential", valid_601898
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601899: Call_GetRebootDBInstance_601885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601899.validator(path, query, header, formData, body)
  let scheme = call_601899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601899.url(scheme.get, call_601899.host, call_601899.base,
                         call_601899.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601899, url, valid)

proc call*(call_601900: Call_GetRebootDBInstance_601885;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601901 = newJObject()
  add(query_601901, "Action", newJString(Action))
  add(query_601901, "ForceFailover", newJBool(ForceFailover))
  add(query_601901, "Version", newJString(Version))
  add(query_601901, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601900.call(nil, query_601901, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_601885(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_601886, base: "/",
    url: url_GetRebootDBInstance_601887, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_601937 = ref object of OpenApiRestCall_599352
proc url_PostRemoveSourceIdentifierFromSubscription_601939(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_601938(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601940 = query.getOrDefault("Action")
  valid_601940 = validateParameter(valid_601940, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_601940 != nil:
    section.add "Action", valid_601940
  var valid_601941 = query.getOrDefault("Version")
  valid_601941 = validateParameter(valid_601941, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601941 != nil:
    section.add "Version", valid_601941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601942 = header.getOrDefault("X-Amz-Date")
  valid_601942 = validateParameter(valid_601942, JString, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "X-Amz-Date", valid_601942
  var valid_601943 = header.getOrDefault("X-Amz-Security-Token")
  valid_601943 = validateParameter(valid_601943, JString, required = false,
                                 default = nil)
  if valid_601943 != nil:
    section.add "X-Amz-Security-Token", valid_601943
  var valid_601944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601944 = validateParameter(valid_601944, JString, required = false,
                                 default = nil)
  if valid_601944 != nil:
    section.add "X-Amz-Content-Sha256", valid_601944
  var valid_601945 = header.getOrDefault("X-Amz-Algorithm")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "X-Amz-Algorithm", valid_601945
  var valid_601946 = header.getOrDefault("X-Amz-Signature")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "X-Amz-Signature", valid_601946
  var valid_601947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "X-Amz-SignedHeaders", valid_601947
  var valid_601948 = header.getOrDefault("X-Amz-Credential")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Credential", valid_601948
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_601949 = formData.getOrDefault("SourceIdentifier")
  valid_601949 = validateParameter(valid_601949, JString, required = true,
                                 default = nil)
  if valid_601949 != nil:
    section.add "SourceIdentifier", valid_601949
  var valid_601950 = formData.getOrDefault("SubscriptionName")
  valid_601950 = validateParameter(valid_601950, JString, required = true,
                                 default = nil)
  if valid_601950 != nil:
    section.add "SubscriptionName", valid_601950
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601951: Call_PostRemoveSourceIdentifierFromSubscription_601937;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601951.validator(path, query, header, formData, body)
  let scheme = call_601951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601951.url(scheme.get, call_601951.host, call_601951.base,
                         call_601951.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601951, url, valid)

proc call*(call_601952: Call_PostRemoveSourceIdentifierFromSubscription_601937;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601953 = newJObject()
  var formData_601954 = newJObject()
  add(formData_601954, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_601954, "SubscriptionName", newJString(SubscriptionName))
  add(query_601953, "Action", newJString(Action))
  add(query_601953, "Version", newJString(Version))
  result = call_601952.call(nil, query_601953, nil, formData_601954, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_601937(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_601938,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_601939,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_601920 = ref object of OpenApiRestCall_599352
proc url_GetRemoveSourceIdentifierFromSubscription_601922(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_601921(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601923 = query.getOrDefault("Action")
  valid_601923 = validateParameter(valid_601923, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_601923 != nil:
    section.add "Action", valid_601923
  var valid_601924 = query.getOrDefault("SourceIdentifier")
  valid_601924 = validateParameter(valid_601924, JString, required = true,
                                 default = nil)
  if valid_601924 != nil:
    section.add "SourceIdentifier", valid_601924
  var valid_601925 = query.getOrDefault("SubscriptionName")
  valid_601925 = validateParameter(valid_601925, JString, required = true,
                                 default = nil)
  if valid_601925 != nil:
    section.add "SubscriptionName", valid_601925
  var valid_601926 = query.getOrDefault("Version")
  valid_601926 = validateParameter(valid_601926, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601926 != nil:
    section.add "Version", valid_601926
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601927 = header.getOrDefault("X-Amz-Date")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "X-Amz-Date", valid_601927
  var valid_601928 = header.getOrDefault("X-Amz-Security-Token")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-Security-Token", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-Content-Sha256", valid_601929
  var valid_601930 = header.getOrDefault("X-Amz-Algorithm")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "X-Amz-Algorithm", valid_601930
  var valid_601931 = header.getOrDefault("X-Amz-Signature")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-Signature", valid_601931
  var valid_601932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "X-Amz-SignedHeaders", valid_601932
  var valid_601933 = header.getOrDefault("X-Amz-Credential")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-Credential", valid_601933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601934: Call_GetRemoveSourceIdentifierFromSubscription_601920;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601934.validator(path, query, header, formData, body)
  let scheme = call_601934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601934.url(scheme.get, call_601934.host, call_601934.base,
                         call_601934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601934, url, valid)

proc call*(call_601935: Call_GetRemoveSourceIdentifierFromSubscription_601920;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601936 = newJObject()
  add(query_601936, "Action", newJString(Action))
  add(query_601936, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601936, "SubscriptionName", newJString(SubscriptionName))
  add(query_601936, "Version", newJString(Version))
  result = call_601935.call(nil, query_601936, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_601920(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_601921,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_601922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_601972 = ref object of OpenApiRestCall_599352
proc url_PostRemoveTagsFromResource_601974(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_601973(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601975 = query.getOrDefault("Action")
  valid_601975 = validateParameter(valid_601975, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601975 != nil:
    section.add "Action", valid_601975
  var valid_601976 = query.getOrDefault("Version")
  valid_601976 = validateParameter(valid_601976, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601976 != nil:
    section.add "Version", valid_601976
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601977 = header.getOrDefault("X-Amz-Date")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-Date", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Security-Token")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Security-Token", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Content-Sha256", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Algorithm")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Algorithm", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Signature")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Signature", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-SignedHeaders", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Credential")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Credential", valid_601983
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_601984 = formData.getOrDefault("TagKeys")
  valid_601984 = validateParameter(valid_601984, JArray, required = true, default = nil)
  if valid_601984 != nil:
    section.add "TagKeys", valid_601984
  var valid_601985 = formData.getOrDefault("ResourceName")
  valid_601985 = validateParameter(valid_601985, JString, required = true,
                                 default = nil)
  if valid_601985 != nil:
    section.add "ResourceName", valid_601985
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601986: Call_PostRemoveTagsFromResource_601972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601986.validator(path, query, header, formData, body)
  let scheme = call_601986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601986.url(scheme.get, call_601986.host, call_601986.base,
                         call_601986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601986, url, valid)

proc call*(call_601987: Call_PostRemoveTagsFromResource_601972; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601988 = newJObject()
  var formData_601989 = newJObject()
  add(query_601988, "Action", newJString(Action))
  if TagKeys != nil:
    formData_601989.add "TagKeys", TagKeys
  add(formData_601989, "ResourceName", newJString(ResourceName))
  add(query_601988, "Version", newJString(Version))
  result = call_601987.call(nil, query_601988, nil, formData_601989, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_601972(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_601973, base: "/",
    url: url_PostRemoveTagsFromResource_601974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_601955 = ref object of OpenApiRestCall_599352
proc url_GetRemoveTagsFromResource_601957(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_601956(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601958 = query.getOrDefault("ResourceName")
  valid_601958 = validateParameter(valid_601958, JString, required = true,
                                 default = nil)
  if valid_601958 != nil:
    section.add "ResourceName", valid_601958
  var valid_601959 = query.getOrDefault("Action")
  valid_601959 = validateParameter(valid_601959, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601959 != nil:
    section.add "Action", valid_601959
  var valid_601960 = query.getOrDefault("TagKeys")
  valid_601960 = validateParameter(valid_601960, JArray, required = true, default = nil)
  if valid_601960 != nil:
    section.add "TagKeys", valid_601960
  var valid_601961 = query.getOrDefault("Version")
  valid_601961 = validateParameter(valid_601961, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601961 != nil:
    section.add "Version", valid_601961
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601962 = header.getOrDefault("X-Amz-Date")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-Date", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Security-Token")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Security-Token", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Content-Sha256", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Algorithm")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Algorithm", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-Signature")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Signature", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-SignedHeaders", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-Credential")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-Credential", valid_601968
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601969: Call_GetRemoveTagsFromResource_601955; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601969.validator(path, query, header, formData, body)
  let scheme = call_601969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601969.url(scheme.get, call_601969.host, call_601969.base,
                         call_601969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601969, url, valid)

proc call*(call_601970: Call_GetRemoveTagsFromResource_601955;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_601971 = newJObject()
  add(query_601971, "ResourceName", newJString(ResourceName))
  add(query_601971, "Action", newJString(Action))
  if TagKeys != nil:
    query_601971.add "TagKeys", TagKeys
  add(query_601971, "Version", newJString(Version))
  result = call_601970.call(nil, query_601971, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_601955(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_601956, base: "/",
    url: url_GetRemoveTagsFromResource_601957,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_602008 = ref object of OpenApiRestCall_599352
proc url_PostResetDBParameterGroup_602010(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_602009(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602011 = query.getOrDefault("Action")
  valid_602011 = validateParameter(valid_602011, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602011 != nil:
    section.add "Action", valid_602011
  var valid_602012 = query.getOrDefault("Version")
  valid_602012 = validateParameter(valid_602012, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602012 != nil:
    section.add "Version", valid_602012
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602013 = header.getOrDefault("X-Amz-Date")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Date", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Security-Token")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Security-Token", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Content-Sha256", valid_602015
  var valid_602016 = header.getOrDefault("X-Amz-Algorithm")
  valid_602016 = validateParameter(valid_602016, JString, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "X-Amz-Algorithm", valid_602016
  var valid_602017 = header.getOrDefault("X-Amz-Signature")
  valid_602017 = validateParameter(valid_602017, JString, required = false,
                                 default = nil)
  if valid_602017 != nil:
    section.add "X-Amz-Signature", valid_602017
  var valid_602018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-SignedHeaders", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Credential")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Credential", valid_602019
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602020 = formData.getOrDefault("DBParameterGroupName")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = nil)
  if valid_602020 != nil:
    section.add "DBParameterGroupName", valid_602020
  var valid_602021 = formData.getOrDefault("Parameters")
  valid_602021 = validateParameter(valid_602021, JArray, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "Parameters", valid_602021
  var valid_602022 = formData.getOrDefault("ResetAllParameters")
  valid_602022 = validateParameter(valid_602022, JBool, required = false, default = nil)
  if valid_602022 != nil:
    section.add "ResetAllParameters", valid_602022
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602023: Call_PostResetDBParameterGroup_602008; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602023.validator(path, query, header, formData, body)
  let scheme = call_602023.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602023.url(scheme.get, call_602023.host, call_602023.base,
                         call_602023.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602023, url, valid)

proc call*(call_602024: Call_PostResetDBParameterGroup_602008;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602025 = newJObject()
  var formData_602026 = newJObject()
  add(formData_602026, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602026.add "Parameters", Parameters
  add(query_602025, "Action", newJString(Action))
  add(formData_602026, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602025, "Version", newJString(Version))
  result = call_602024.call(nil, query_602025, nil, formData_602026, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_602008(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_602009, base: "/",
    url: url_PostResetDBParameterGroup_602010,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_601990 = ref object of OpenApiRestCall_599352
proc url_GetResetDBParameterGroup_601992(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_601991(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601993 = query.getOrDefault("DBParameterGroupName")
  valid_601993 = validateParameter(valid_601993, JString, required = true,
                                 default = nil)
  if valid_601993 != nil:
    section.add "DBParameterGroupName", valid_601993
  var valid_601994 = query.getOrDefault("Parameters")
  valid_601994 = validateParameter(valid_601994, JArray, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "Parameters", valid_601994
  var valid_601995 = query.getOrDefault("Action")
  valid_601995 = validateParameter(valid_601995, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_601995 != nil:
    section.add "Action", valid_601995
  var valid_601996 = query.getOrDefault("ResetAllParameters")
  valid_601996 = validateParameter(valid_601996, JBool, required = false, default = nil)
  if valid_601996 != nil:
    section.add "ResetAllParameters", valid_601996
  var valid_601997 = query.getOrDefault("Version")
  valid_601997 = validateParameter(valid_601997, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601997 != nil:
    section.add "Version", valid_601997
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601998 = header.getOrDefault("X-Amz-Date")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Date", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Security-Token")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Security-Token", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Content-Sha256", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Algorithm")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Algorithm", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Signature")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Signature", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-SignedHeaders", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Credential")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Credential", valid_602004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602005: Call_GetResetDBParameterGroup_601990; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602005.validator(path, query, header, formData, body)
  let scheme = call_602005.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602005.url(scheme.get, call_602005.host, call_602005.base,
                         call_602005.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602005, url, valid)

proc call*(call_602006: Call_GetResetDBParameterGroup_601990;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602007 = newJObject()
  add(query_602007, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602007.add "Parameters", Parameters
  add(query_602007, "Action", newJString(Action))
  add(query_602007, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602007, "Version", newJString(Version))
  result = call_602006.call(nil, query_602007, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_601990(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_601991, base: "/",
    url: url_GetResetDBParameterGroup_601992, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_602060 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBInstanceFromDBSnapshot_602062(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_602061(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602063 = query.getOrDefault("Action")
  valid_602063 = validateParameter(valid_602063, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602063 != nil:
    section.add "Action", valid_602063
  var valid_602064 = query.getOrDefault("Version")
  valid_602064 = validateParameter(valid_602064, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602064 != nil:
    section.add "Version", valid_602064
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602065 = header.getOrDefault("X-Amz-Date")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Date", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Security-Token")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Security-Token", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Content-Sha256", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Algorithm")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Algorithm", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Signature")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Signature", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-SignedHeaders", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Credential")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Credential", valid_602071
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
  var valid_602072 = formData.getOrDefault("Port")
  valid_602072 = validateParameter(valid_602072, JInt, required = false, default = nil)
  if valid_602072 != nil:
    section.add "Port", valid_602072
  var valid_602073 = formData.getOrDefault("Engine")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "Engine", valid_602073
  var valid_602074 = formData.getOrDefault("Iops")
  valid_602074 = validateParameter(valid_602074, JInt, required = false, default = nil)
  if valid_602074 != nil:
    section.add "Iops", valid_602074
  var valid_602075 = formData.getOrDefault("DBName")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "DBName", valid_602075
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602076 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602076 = validateParameter(valid_602076, JString, required = true,
                                 default = nil)
  if valid_602076 != nil:
    section.add "DBInstanceIdentifier", valid_602076
  var valid_602077 = formData.getOrDefault("OptionGroupName")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "OptionGroupName", valid_602077
  var valid_602078 = formData.getOrDefault("Tags")
  valid_602078 = validateParameter(valid_602078, JArray, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "Tags", valid_602078
  var valid_602079 = formData.getOrDefault("TdeCredentialArn")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "TdeCredentialArn", valid_602079
  var valid_602080 = formData.getOrDefault("DBSubnetGroupName")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "DBSubnetGroupName", valid_602080
  var valid_602081 = formData.getOrDefault("TdeCredentialPassword")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "TdeCredentialPassword", valid_602081
  var valid_602082 = formData.getOrDefault("AvailabilityZone")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "AvailabilityZone", valid_602082
  var valid_602083 = formData.getOrDefault("MultiAZ")
  valid_602083 = validateParameter(valid_602083, JBool, required = false, default = nil)
  if valid_602083 != nil:
    section.add "MultiAZ", valid_602083
  var valid_602084 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602084 = validateParameter(valid_602084, JString, required = true,
                                 default = nil)
  if valid_602084 != nil:
    section.add "DBSnapshotIdentifier", valid_602084
  var valid_602085 = formData.getOrDefault("PubliclyAccessible")
  valid_602085 = validateParameter(valid_602085, JBool, required = false, default = nil)
  if valid_602085 != nil:
    section.add "PubliclyAccessible", valid_602085
  var valid_602086 = formData.getOrDefault("StorageType")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "StorageType", valid_602086
  var valid_602087 = formData.getOrDefault("DBInstanceClass")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "DBInstanceClass", valid_602087
  var valid_602088 = formData.getOrDefault("LicenseModel")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "LicenseModel", valid_602088
  var valid_602089 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602089 = validateParameter(valid_602089, JBool, required = false, default = nil)
  if valid_602089 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602089
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602090: Call_PostRestoreDBInstanceFromDBSnapshot_602060;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602090.validator(path, query, header, formData, body)
  let scheme = call_602090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602090.url(scheme.get, call_602090.host, call_602090.base,
                         call_602090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602090, url, valid)

proc call*(call_602091: Call_PostRestoreDBInstanceFromDBSnapshot_602060;
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
  var query_602092 = newJObject()
  var formData_602093 = newJObject()
  add(formData_602093, "Port", newJInt(Port))
  add(formData_602093, "Engine", newJString(Engine))
  add(formData_602093, "Iops", newJInt(Iops))
  add(formData_602093, "DBName", newJString(DBName))
  add(formData_602093, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602093, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_602093.add "Tags", Tags
  add(formData_602093, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_602093, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602093, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_602093, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602093, "MultiAZ", newJBool(MultiAZ))
  add(formData_602093, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602092, "Action", newJString(Action))
  add(formData_602093, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_602093, "StorageType", newJString(StorageType))
  add(formData_602093, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602093, "LicenseModel", newJString(LicenseModel))
  add(formData_602093, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_602092, "Version", newJString(Version))
  result = call_602091.call(nil, query_602092, nil, formData_602093, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_602060(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_602061, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_602062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_602027 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBInstanceFromDBSnapshot_602029(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_602028(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602030 = query.getOrDefault("Engine")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "Engine", valid_602030
  var valid_602031 = query.getOrDefault("StorageType")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "StorageType", valid_602031
  var valid_602032 = query.getOrDefault("OptionGroupName")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "OptionGroupName", valid_602032
  var valid_602033 = query.getOrDefault("AvailabilityZone")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "AvailabilityZone", valid_602033
  var valid_602034 = query.getOrDefault("Iops")
  valid_602034 = validateParameter(valid_602034, JInt, required = false, default = nil)
  if valid_602034 != nil:
    section.add "Iops", valid_602034
  var valid_602035 = query.getOrDefault("MultiAZ")
  valid_602035 = validateParameter(valid_602035, JBool, required = false, default = nil)
  if valid_602035 != nil:
    section.add "MultiAZ", valid_602035
  var valid_602036 = query.getOrDefault("TdeCredentialPassword")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "TdeCredentialPassword", valid_602036
  var valid_602037 = query.getOrDefault("LicenseModel")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "LicenseModel", valid_602037
  var valid_602038 = query.getOrDefault("Tags")
  valid_602038 = validateParameter(valid_602038, JArray, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "Tags", valid_602038
  var valid_602039 = query.getOrDefault("DBName")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "DBName", valid_602039
  var valid_602040 = query.getOrDefault("DBInstanceClass")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "DBInstanceClass", valid_602040
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602041 = query.getOrDefault("Action")
  valid_602041 = validateParameter(valid_602041, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602041 != nil:
    section.add "Action", valid_602041
  var valid_602042 = query.getOrDefault("DBSubnetGroupName")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "DBSubnetGroupName", valid_602042
  var valid_602043 = query.getOrDefault("TdeCredentialArn")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "TdeCredentialArn", valid_602043
  var valid_602044 = query.getOrDefault("PubliclyAccessible")
  valid_602044 = validateParameter(valid_602044, JBool, required = false, default = nil)
  if valid_602044 != nil:
    section.add "PubliclyAccessible", valid_602044
  var valid_602045 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602045 = validateParameter(valid_602045, JBool, required = false, default = nil)
  if valid_602045 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602045
  var valid_602046 = query.getOrDefault("Port")
  valid_602046 = validateParameter(valid_602046, JInt, required = false, default = nil)
  if valid_602046 != nil:
    section.add "Port", valid_602046
  var valid_602047 = query.getOrDefault("Version")
  valid_602047 = validateParameter(valid_602047, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602047 != nil:
    section.add "Version", valid_602047
  var valid_602048 = query.getOrDefault("DBInstanceIdentifier")
  valid_602048 = validateParameter(valid_602048, JString, required = true,
                                 default = nil)
  if valid_602048 != nil:
    section.add "DBInstanceIdentifier", valid_602048
  var valid_602049 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602049 = validateParameter(valid_602049, JString, required = true,
                                 default = nil)
  if valid_602049 != nil:
    section.add "DBSnapshotIdentifier", valid_602049
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602050 = header.getOrDefault("X-Amz-Date")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Date", valid_602050
  var valid_602051 = header.getOrDefault("X-Amz-Security-Token")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "X-Amz-Security-Token", valid_602051
  var valid_602052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "X-Amz-Content-Sha256", valid_602052
  var valid_602053 = header.getOrDefault("X-Amz-Algorithm")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "X-Amz-Algorithm", valid_602053
  var valid_602054 = header.getOrDefault("X-Amz-Signature")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Signature", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-SignedHeaders", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Credential")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Credential", valid_602056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602057: Call_GetRestoreDBInstanceFromDBSnapshot_602027;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602057.validator(path, query, header, formData, body)
  let scheme = call_602057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602057.url(scheme.get, call_602057.host, call_602057.base,
                         call_602057.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602057, url, valid)

proc call*(call_602058: Call_GetRestoreDBInstanceFromDBSnapshot_602027;
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
  var query_602059 = newJObject()
  add(query_602059, "Engine", newJString(Engine))
  add(query_602059, "StorageType", newJString(StorageType))
  add(query_602059, "OptionGroupName", newJString(OptionGroupName))
  add(query_602059, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602059, "Iops", newJInt(Iops))
  add(query_602059, "MultiAZ", newJBool(MultiAZ))
  add(query_602059, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_602059, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_602059.add "Tags", Tags
  add(query_602059, "DBName", newJString(DBName))
  add(query_602059, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602059, "Action", newJString(Action))
  add(query_602059, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602059, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_602059, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602059, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602059, "Port", newJInt(Port))
  add(query_602059, "Version", newJString(Version))
  add(query_602059, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602059, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602058.call(nil, query_602059, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_602027(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_602028, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_602029,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_602129 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBInstanceToPointInTime_602131(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_602130(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602132 = query.getOrDefault("Action")
  valid_602132 = validateParameter(valid_602132, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_602132 != nil:
    section.add "Action", valid_602132
  var valid_602133 = query.getOrDefault("Version")
  valid_602133 = validateParameter(valid_602133, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602133 != nil:
    section.add "Version", valid_602133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602134 = header.getOrDefault("X-Amz-Date")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "X-Amz-Date", valid_602134
  var valid_602135 = header.getOrDefault("X-Amz-Security-Token")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Security-Token", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Content-Sha256", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Algorithm")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Algorithm", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Signature")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Signature", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-SignedHeaders", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Credential")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Credential", valid_602140
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
  var valid_602141 = formData.getOrDefault("UseLatestRestorableTime")
  valid_602141 = validateParameter(valid_602141, JBool, required = false, default = nil)
  if valid_602141 != nil:
    section.add "UseLatestRestorableTime", valid_602141
  var valid_602142 = formData.getOrDefault("Port")
  valid_602142 = validateParameter(valid_602142, JInt, required = false, default = nil)
  if valid_602142 != nil:
    section.add "Port", valid_602142
  var valid_602143 = formData.getOrDefault("Engine")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "Engine", valid_602143
  var valid_602144 = formData.getOrDefault("Iops")
  valid_602144 = validateParameter(valid_602144, JInt, required = false, default = nil)
  if valid_602144 != nil:
    section.add "Iops", valid_602144
  var valid_602145 = formData.getOrDefault("DBName")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "DBName", valid_602145
  var valid_602146 = formData.getOrDefault("OptionGroupName")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "OptionGroupName", valid_602146
  var valid_602147 = formData.getOrDefault("Tags")
  valid_602147 = validateParameter(valid_602147, JArray, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "Tags", valid_602147
  var valid_602148 = formData.getOrDefault("TdeCredentialArn")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "TdeCredentialArn", valid_602148
  var valid_602149 = formData.getOrDefault("DBSubnetGroupName")
  valid_602149 = validateParameter(valid_602149, JString, required = false,
                                 default = nil)
  if valid_602149 != nil:
    section.add "DBSubnetGroupName", valid_602149
  var valid_602150 = formData.getOrDefault("TdeCredentialPassword")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "TdeCredentialPassword", valid_602150
  var valid_602151 = formData.getOrDefault("AvailabilityZone")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "AvailabilityZone", valid_602151
  var valid_602152 = formData.getOrDefault("MultiAZ")
  valid_602152 = validateParameter(valid_602152, JBool, required = false, default = nil)
  if valid_602152 != nil:
    section.add "MultiAZ", valid_602152
  var valid_602153 = formData.getOrDefault("RestoreTime")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "RestoreTime", valid_602153
  var valid_602154 = formData.getOrDefault("PubliclyAccessible")
  valid_602154 = validateParameter(valid_602154, JBool, required = false, default = nil)
  if valid_602154 != nil:
    section.add "PubliclyAccessible", valid_602154
  var valid_602155 = formData.getOrDefault("StorageType")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "StorageType", valid_602155
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_602156 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = nil)
  if valid_602156 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602156
  var valid_602157 = formData.getOrDefault("DBInstanceClass")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "DBInstanceClass", valid_602157
  var valid_602158 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_602158 = validateParameter(valid_602158, JString, required = true,
                                 default = nil)
  if valid_602158 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602158
  var valid_602159 = formData.getOrDefault("LicenseModel")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "LicenseModel", valid_602159
  var valid_602160 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602160 = validateParameter(valid_602160, JBool, required = false, default = nil)
  if valid_602160 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602161: Call_PostRestoreDBInstanceToPointInTime_602129;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602161.validator(path, query, header, formData, body)
  let scheme = call_602161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602161.url(scheme.get, call_602161.host, call_602161.base,
                         call_602161.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602161, url, valid)

proc call*(call_602162: Call_PostRestoreDBInstanceToPointInTime_602129;
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
  var query_602163 = newJObject()
  var formData_602164 = newJObject()
  add(formData_602164, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_602164, "Port", newJInt(Port))
  add(formData_602164, "Engine", newJString(Engine))
  add(formData_602164, "Iops", newJInt(Iops))
  add(formData_602164, "DBName", newJString(DBName))
  add(formData_602164, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_602164.add "Tags", Tags
  add(formData_602164, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_602164, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602164, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_602164, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602164, "MultiAZ", newJBool(MultiAZ))
  add(query_602163, "Action", newJString(Action))
  add(formData_602164, "RestoreTime", newJString(RestoreTime))
  add(formData_602164, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_602164, "StorageType", newJString(StorageType))
  add(formData_602164, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_602164, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602164, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_602164, "LicenseModel", newJString(LicenseModel))
  add(formData_602164, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_602163, "Version", newJString(Version))
  result = call_602162.call(nil, query_602163, nil, formData_602164, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_602129(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_602130, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_602131,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_602094 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBInstanceToPointInTime_602096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_602095(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602097 = query.getOrDefault("Engine")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "Engine", valid_602097
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_602098 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = nil)
  if valid_602098 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602098
  var valid_602099 = query.getOrDefault("StorageType")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "StorageType", valid_602099
  var valid_602100 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = nil)
  if valid_602100 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602100
  var valid_602101 = query.getOrDefault("AvailabilityZone")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "AvailabilityZone", valid_602101
  var valid_602102 = query.getOrDefault("Iops")
  valid_602102 = validateParameter(valid_602102, JInt, required = false, default = nil)
  if valid_602102 != nil:
    section.add "Iops", valid_602102
  var valid_602103 = query.getOrDefault("OptionGroupName")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "OptionGroupName", valid_602103
  var valid_602104 = query.getOrDefault("RestoreTime")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "RestoreTime", valid_602104
  var valid_602105 = query.getOrDefault("MultiAZ")
  valid_602105 = validateParameter(valid_602105, JBool, required = false, default = nil)
  if valid_602105 != nil:
    section.add "MultiAZ", valid_602105
  var valid_602106 = query.getOrDefault("TdeCredentialPassword")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "TdeCredentialPassword", valid_602106
  var valid_602107 = query.getOrDefault("LicenseModel")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "LicenseModel", valid_602107
  var valid_602108 = query.getOrDefault("Tags")
  valid_602108 = validateParameter(valid_602108, JArray, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "Tags", valid_602108
  var valid_602109 = query.getOrDefault("DBName")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "DBName", valid_602109
  var valid_602110 = query.getOrDefault("DBInstanceClass")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "DBInstanceClass", valid_602110
  var valid_602111 = query.getOrDefault("Action")
  valid_602111 = validateParameter(valid_602111, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_602111 != nil:
    section.add "Action", valid_602111
  var valid_602112 = query.getOrDefault("UseLatestRestorableTime")
  valid_602112 = validateParameter(valid_602112, JBool, required = false, default = nil)
  if valid_602112 != nil:
    section.add "UseLatestRestorableTime", valid_602112
  var valid_602113 = query.getOrDefault("DBSubnetGroupName")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "DBSubnetGroupName", valid_602113
  var valid_602114 = query.getOrDefault("TdeCredentialArn")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "TdeCredentialArn", valid_602114
  var valid_602115 = query.getOrDefault("PubliclyAccessible")
  valid_602115 = validateParameter(valid_602115, JBool, required = false, default = nil)
  if valid_602115 != nil:
    section.add "PubliclyAccessible", valid_602115
  var valid_602116 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602116 = validateParameter(valid_602116, JBool, required = false, default = nil)
  if valid_602116 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602116
  var valid_602117 = query.getOrDefault("Port")
  valid_602117 = validateParameter(valid_602117, JInt, required = false, default = nil)
  if valid_602117 != nil:
    section.add "Port", valid_602117
  var valid_602118 = query.getOrDefault("Version")
  valid_602118 = validateParameter(valid_602118, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602118 != nil:
    section.add "Version", valid_602118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602119 = header.getOrDefault("X-Amz-Date")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Date", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Security-Token")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Security-Token", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Content-Sha256", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Algorithm")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Algorithm", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-Signature")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-Signature", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-SignedHeaders", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Credential")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Credential", valid_602125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602126: Call_GetRestoreDBInstanceToPointInTime_602094;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602126.validator(path, query, header, formData, body)
  let scheme = call_602126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602126.url(scheme.get, call_602126.host, call_602126.base,
                         call_602126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602126, url, valid)

proc call*(call_602127: Call_GetRestoreDBInstanceToPointInTime_602094;
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
  var query_602128 = newJObject()
  add(query_602128, "Engine", newJString(Engine))
  add(query_602128, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_602128, "StorageType", newJString(StorageType))
  add(query_602128, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_602128, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602128, "Iops", newJInt(Iops))
  add(query_602128, "OptionGroupName", newJString(OptionGroupName))
  add(query_602128, "RestoreTime", newJString(RestoreTime))
  add(query_602128, "MultiAZ", newJBool(MultiAZ))
  add(query_602128, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_602128, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_602128.add "Tags", Tags
  add(query_602128, "DBName", newJString(DBName))
  add(query_602128, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602128, "Action", newJString(Action))
  add(query_602128, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_602128, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602128, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_602128, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602128, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602128, "Port", newJInt(Port))
  add(query_602128, "Version", newJString(Version))
  result = call_602127.call(nil, query_602128, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_602094(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_602095, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_602096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_602185 = ref object of OpenApiRestCall_599352
proc url_PostRevokeDBSecurityGroupIngress_602187(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_602186(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602188 = query.getOrDefault("Action")
  valid_602188 = validateParameter(valid_602188, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_602188 != nil:
    section.add "Action", valid_602188
  var valid_602189 = query.getOrDefault("Version")
  valid_602189 = validateParameter(valid_602189, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602189 != nil:
    section.add "Version", valid_602189
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602190 = header.getOrDefault("X-Amz-Date")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Date", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Security-Token")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Security-Token", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Content-Sha256", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Algorithm")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Algorithm", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Signature")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Signature", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-SignedHeaders", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Credential")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Credential", valid_602196
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602197 = formData.getOrDefault("DBSecurityGroupName")
  valid_602197 = validateParameter(valid_602197, JString, required = true,
                                 default = nil)
  if valid_602197 != nil:
    section.add "DBSecurityGroupName", valid_602197
  var valid_602198 = formData.getOrDefault("EC2SecurityGroupName")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "EC2SecurityGroupName", valid_602198
  var valid_602199 = formData.getOrDefault("EC2SecurityGroupId")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "EC2SecurityGroupId", valid_602199
  var valid_602200 = formData.getOrDefault("CIDRIP")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "CIDRIP", valid_602200
  var valid_602201 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602202: Call_PostRevokeDBSecurityGroupIngress_602185;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602202.validator(path, query, header, formData, body)
  let scheme = call_602202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602202.url(scheme.get, call_602202.host, call_602202.base,
                         call_602202.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602202, url, valid)

proc call*(call_602203: Call_PostRevokeDBSecurityGroupIngress_602185;
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
  var query_602204 = newJObject()
  var formData_602205 = newJObject()
  add(formData_602205, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602204, "Action", newJString(Action))
  add(formData_602205, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_602205, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_602205, "CIDRIP", newJString(CIDRIP))
  add(query_602204, "Version", newJString(Version))
  add(formData_602205, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_602203.call(nil, query_602204, nil, formData_602205, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_602185(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_602186, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_602187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_602165 = ref object of OpenApiRestCall_599352
proc url_GetRevokeDBSecurityGroupIngress_602167(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_602166(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_602168 = query.getOrDefault("EC2SecurityGroupId")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "EC2SecurityGroupId", valid_602168
  var valid_602169 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602169
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602170 = query.getOrDefault("DBSecurityGroupName")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = nil)
  if valid_602170 != nil:
    section.add "DBSecurityGroupName", valid_602170
  var valid_602171 = query.getOrDefault("Action")
  valid_602171 = validateParameter(valid_602171, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_602171 != nil:
    section.add "Action", valid_602171
  var valid_602172 = query.getOrDefault("CIDRIP")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "CIDRIP", valid_602172
  var valid_602173 = query.getOrDefault("EC2SecurityGroupName")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "EC2SecurityGroupName", valid_602173
  var valid_602174 = query.getOrDefault("Version")
  valid_602174 = validateParameter(valid_602174, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602174 != nil:
    section.add "Version", valid_602174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602175 = header.getOrDefault("X-Amz-Date")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Date", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Security-Token")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Security-Token", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Content-Sha256", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Algorithm")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Algorithm", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Signature")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Signature", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-SignedHeaders", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Credential")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Credential", valid_602181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602182: Call_GetRevokeDBSecurityGroupIngress_602165;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602182.validator(path, query, header, formData, body)
  let scheme = call_602182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602182.url(scheme.get, call_602182.host, call_602182.base,
                         call_602182.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602182, url, valid)

proc call*(call_602183: Call_GetRevokeDBSecurityGroupIngress_602165;
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
  var query_602184 = newJObject()
  add(query_602184, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_602184, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_602184, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602184, "Action", newJString(Action))
  add(query_602184, "CIDRIP", newJString(CIDRIP))
  add(query_602184, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_602184, "Version", newJString(Version))
  result = call_602183.call(nil, query_602184, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_602165(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_602166, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_602167,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)


import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
                                 default = newJString("2013-09-09"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
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
  Call_PostCopyDBSnapshot_600073 = ref object of OpenApiRestCall_599352
proc url_PostCopyDBSnapshot_600075(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_600074(path: JsonNode; query: JsonNode;
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
  var valid_600076 = query.getOrDefault("Action")
  valid_600076 = validateParameter(valid_600076, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_600076 != nil:
    section.add "Action", valid_600076
  var valid_600077 = query.getOrDefault("Version")
  valid_600077 = validateParameter(valid_600077, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600077 != nil:
    section.add "Version", valid_600077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600078 = header.getOrDefault("X-Amz-Date")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Date", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Security-Token")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Security-Token", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Content-Sha256", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Algorithm")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Algorithm", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Signature")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Signature", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-SignedHeaders", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-Credential")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-Credential", valid_600084
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_600085 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = nil)
  if valid_600085 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_600085
  var valid_600086 = formData.getOrDefault("Tags")
  valid_600086 = validateParameter(valid_600086, JArray, required = false,
                                 default = nil)
  if valid_600086 != nil:
    section.add "Tags", valid_600086
  var valid_600087 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_600087 = validateParameter(valid_600087, JString, required = true,
                                 default = nil)
  if valid_600087 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_600087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600088: Call_PostCopyDBSnapshot_600073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600088.validator(path, query, header, formData, body)
  let scheme = call_600088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600088.url(scheme.get, call_600088.host, call_600088.base,
                         call_600088.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600088, url, valid)

proc call*(call_600089: Call_PostCopyDBSnapshot_600073;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_600090 = newJObject()
  var formData_600091 = newJObject()
  add(formData_600091, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_600091.add "Tags", Tags
  add(query_600090, "Action", newJString(Action))
  add(formData_600091, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_600090, "Version", newJString(Version))
  result = call_600089.call(nil, query_600090, nil, formData_600091, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_600073(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_600074, base: "/",
    url: url_PostCopyDBSnapshot_600075, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_600055 = ref object of OpenApiRestCall_599352
proc url_GetCopyDBSnapshot_600057(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_600056(path: JsonNode; query: JsonNode;
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
  var valid_600058 = query.getOrDefault("Tags")
  valid_600058 = validateParameter(valid_600058, JArray, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "Tags", valid_600058
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_600059 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_600059 = validateParameter(valid_600059, JString, required = true,
                                 default = nil)
  if valid_600059 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_600059
  var valid_600060 = query.getOrDefault("Action")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_600060 != nil:
    section.add "Action", valid_600060
  var valid_600061 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = nil)
  if valid_600061 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_600061
  var valid_600062 = query.getOrDefault("Version")
  valid_600062 = validateParameter(valid_600062, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600062 != nil:
    section.add "Version", valid_600062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600063 = header.getOrDefault("X-Amz-Date")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Date", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Security-Token")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Security-Token", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Content-Sha256", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Algorithm")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Algorithm", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Signature")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Signature", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-SignedHeaders", valid_600068
  var valid_600069 = header.getOrDefault("X-Amz-Credential")
  valid_600069 = validateParameter(valid_600069, JString, required = false,
                                 default = nil)
  if valid_600069 != nil:
    section.add "X-Amz-Credential", valid_600069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600070: Call_GetCopyDBSnapshot_600055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600070.validator(path, query, header, formData, body)
  let scheme = call_600070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600070.url(scheme.get, call_600070.host, call_600070.base,
                         call_600070.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600070, url, valid)

proc call*(call_600071: Call_GetCopyDBSnapshot_600055;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_600072 = newJObject()
  if Tags != nil:
    query_600072.add "Tags", Tags
  add(query_600072, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_600072, "Action", newJString(Action))
  add(query_600072, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_600072, "Version", newJString(Version))
  result = call_600071.call(nil, query_600072, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_600055(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_600056,
    base: "/", url: url_GetCopyDBSnapshot_600057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_600132 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBInstance_600134(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_600133(path: JsonNode; query: JsonNode;
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
  var valid_600135 = query.getOrDefault("Action")
  valid_600135 = validateParameter(valid_600135, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600135 != nil:
    section.add "Action", valid_600135
  var valid_600136 = query.getOrDefault("Version")
  valid_600136 = validateParameter(valid_600136, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600136 != nil:
    section.add "Version", valid_600136
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600137 = header.getOrDefault("X-Amz-Date")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Date", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Security-Token")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Security-Token", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Content-Sha256", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Algorithm")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Algorithm", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-Signature")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-Signature", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-SignedHeaders", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Credential")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Credential", valid_600143
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
  var valid_600144 = formData.getOrDefault("DBSecurityGroups")
  valid_600144 = validateParameter(valid_600144, JArray, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "DBSecurityGroups", valid_600144
  var valid_600145 = formData.getOrDefault("Port")
  valid_600145 = validateParameter(valid_600145, JInt, required = false, default = nil)
  if valid_600145 != nil:
    section.add "Port", valid_600145
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_600146 = formData.getOrDefault("Engine")
  valid_600146 = validateParameter(valid_600146, JString, required = true,
                                 default = nil)
  if valid_600146 != nil:
    section.add "Engine", valid_600146
  var valid_600147 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_600147 = validateParameter(valid_600147, JArray, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "VpcSecurityGroupIds", valid_600147
  var valid_600148 = formData.getOrDefault("Iops")
  valid_600148 = validateParameter(valid_600148, JInt, required = false, default = nil)
  if valid_600148 != nil:
    section.add "Iops", valid_600148
  var valid_600149 = formData.getOrDefault("DBName")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "DBName", valid_600149
  var valid_600150 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600150 = validateParameter(valid_600150, JString, required = true,
                                 default = nil)
  if valid_600150 != nil:
    section.add "DBInstanceIdentifier", valid_600150
  var valid_600151 = formData.getOrDefault("BackupRetentionPeriod")
  valid_600151 = validateParameter(valid_600151, JInt, required = false, default = nil)
  if valid_600151 != nil:
    section.add "BackupRetentionPeriod", valid_600151
  var valid_600152 = formData.getOrDefault("DBParameterGroupName")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "DBParameterGroupName", valid_600152
  var valid_600153 = formData.getOrDefault("OptionGroupName")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "OptionGroupName", valid_600153
  var valid_600154 = formData.getOrDefault("Tags")
  valid_600154 = validateParameter(valid_600154, JArray, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "Tags", valid_600154
  var valid_600155 = formData.getOrDefault("MasterUserPassword")
  valid_600155 = validateParameter(valid_600155, JString, required = true,
                                 default = nil)
  if valid_600155 != nil:
    section.add "MasterUserPassword", valid_600155
  var valid_600156 = formData.getOrDefault("DBSubnetGroupName")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "DBSubnetGroupName", valid_600156
  var valid_600157 = formData.getOrDefault("AvailabilityZone")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "AvailabilityZone", valid_600157
  var valid_600158 = formData.getOrDefault("MultiAZ")
  valid_600158 = validateParameter(valid_600158, JBool, required = false, default = nil)
  if valid_600158 != nil:
    section.add "MultiAZ", valid_600158
  var valid_600159 = formData.getOrDefault("AllocatedStorage")
  valid_600159 = validateParameter(valid_600159, JInt, required = true, default = nil)
  if valid_600159 != nil:
    section.add "AllocatedStorage", valid_600159
  var valid_600160 = formData.getOrDefault("PubliclyAccessible")
  valid_600160 = validateParameter(valid_600160, JBool, required = false, default = nil)
  if valid_600160 != nil:
    section.add "PubliclyAccessible", valid_600160
  var valid_600161 = formData.getOrDefault("MasterUsername")
  valid_600161 = validateParameter(valid_600161, JString, required = true,
                                 default = nil)
  if valid_600161 != nil:
    section.add "MasterUsername", valid_600161
  var valid_600162 = formData.getOrDefault("DBInstanceClass")
  valid_600162 = validateParameter(valid_600162, JString, required = true,
                                 default = nil)
  if valid_600162 != nil:
    section.add "DBInstanceClass", valid_600162
  var valid_600163 = formData.getOrDefault("CharacterSetName")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "CharacterSetName", valid_600163
  var valid_600164 = formData.getOrDefault("PreferredBackupWindow")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "PreferredBackupWindow", valid_600164
  var valid_600165 = formData.getOrDefault("LicenseModel")
  valid_600165 = validateParameter(valid_600165, JString, required = false,
                                 default = nil)
  if valid_600165 != nil:
    section.add "LicenseModel", valid_600165
  var valid_600166 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_600166 = validateParameter(valid_600166, JBool, required = false, default = nil)
  if valid_600166 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600166
  var valid_600167 = formData.getOrDefault("EngineVersion")
  valid_600167 = validateParameter(valid_600167, JString, required = false,
                                 default = nil)
  if valid_600167 != nil:
    section.add "EngineVersion", valid_600167
  var valid_600168 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "PreferredMaintenanceWindow", valid_600168
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600169: Call_PostCreateDBInstance_600132; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600169.validator(path, query, header, formData, body)
  let scheme = call_600169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600169.url(scheme.get, call_600169.host, call_600169.base,
                         call_600169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600169, url, valid)

proc call*(call_600170: Call_PostCreateDBInstance_600132; Engine: string;
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
  var query_600171 = newJObject()
  var formData_600172 = newJObject()
  if DBSecurityGroups != nil:
    formData_600172.add "DBSecurityGroups", DBSecurityGroups
  add(formData_600172, "Port", newJInt(Port))
  add(formData_600172, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_600172.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_600172, "Iops", newJInt(Iops))
  add(formData_600172, "DBName", newJString(DBName))
  add(formData_600172, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600172, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_600172, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600172, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_600172.add "Tags", Tags
  add(formData_600172, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_600172, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_600172, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_600172, "MultiAZ", newJBool(MultiAZ))
  add(query_600171, "Action", newJString(Action))
  add(formData_600172, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_600172, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_600172, "MasterUsername", newJString(MasterUsername))
  add(formData_600172, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_600172, "CharacterSetName", newJString(CharacterSetName))
  add(formData_600172, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_600172, "LicenseModel", newJString(LicenseModel))
  add(formData_600172, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_600172, "EngineVersion", newJString(EngineVersion))
  add(query_600171, "Version", newJString(Version))
  add(formData_600172, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_600170.call(nil, query_600171, nil, formData_600172, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_600132(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_600133, base: "/",
    url: url_PostCreateDBInstance_600134, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_600092 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBInstance_600094(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_600093(path: JsonNode; query: JsonNode;
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
  var valid_600095 = query.getOrDefault("Engine")
  valid_600095 = validateParameter(valid_600095, JString, required = true,
                                 default = nil)
  if valid_600095 != nil:
    section.add "Engine", valid_600095
  var valid_600096 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "PreferredMaintenanceWindow", valid_600096
  var valid_600097 = query.getOrDefault("AllocatedStorage")
  valid_600097 = validateParameter(valid_600097, JInt, required = true, default = nil)
  if valid_600097 != nil:
    section.add "AllocatedStorage", valid_600097
  var valid_600098 = query.getOrDefault("OptionGroupName")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "OptionGroupName", valid_600098
  var valid_600099 = query.getOrDefault("DBSecurityGroups")
  valid_600099 = validateParameter(valid_600099, JArray, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "DBSecurityGroups", valid_600099
  var valid_600100 = query.getOrDefault("MasterUserPassword")
  valid_600100 = validateParameter(valid_600100, JString, required = true,
                                 default = nil)
  if valid_600100 != nil:
    section.add "MasterUserPassword", valid_600100
  var valid_600101 = query.getOrDefault("AvailabilityZone")
  valid_600101 = validateParameter(valid_600101, JString, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "AvailabilityZone", valid_600101
  var valid_600102 = query.getOrDefault("Iops")
  valid_600102 = validateParameter(valid_600102, JInt, required = false, default = nil)
  if valid_600102 != nil:
    section.add "Iops", valid_600102
  var valid_600103 = query.getOrDefault("VpcSecurityGroupIds")
  valid_600103 = validateParameter(valid_600103, JArray, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "VpcSecurityGroupIds", valid_600103
  var valid_600104 = query.getOrDefault("MultiAZ")
  valid_600104 = validateParameter(valid_600104, JBool, required = false, default = nil)
  if valid_600104 != nil:
    section.add "MultiAZ", valid_600104
  var valid_600105 = query.getOrDefault("LicenseModel")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "LicenseModel", valid_600105
  var valid_600106 = query.getOrDefault("BackupRetentionPeriod")
  valid_600106 = validateParameter(valid_600106, JInt, required = false, default = nil)
  if valid_600106 != nil:
    section.add "BackupRetentionPeriod", valid_600106
  var valid_600107 = query.getOrDefault("DBName")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "DBName", valid_600107
  var valid_600108 = query.getOrDefault("DBParameterGroupName")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "DBParameterGroupName", valid_600108
  var valid_600109 = query.getOrDefault("Tags")
  valid_600109 = validateParameter(valid_600109, JArray, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "Tags", valid_600109
  var valid_600110 = query.getOrDefault("DBInstanceClass")
  valid_600110 = validateParameter(valid_600110, JString, required = true,
                                 default = nil)
  if valid_600110 != nil:
    section.add "DBInstanceClass", valid_600110
  var valid_600111 = query.getOrDefault("Action")
  valid_600111 = validateParameter(valid_600111, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600111 != nil:
    section.add "Action", valid_600111
  var valid_600112 = query.getOrDefault("DBSubnetGroupName")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "DBSubnetGroupName", valid_600112
  var valid_600113 = query.getOrDefault("CharacterSetName")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "CharacterSetName", valid_600113
  var valid_600114 = query.getOrDefault("PubliclyAccessible")
  valid_600114 = validateParameter(valid_600114, JBool, required = false, default = nil)
  if valid_600114 != nil:
    section.add "PubliclyAccessible", valid_600114
  var valid_600115 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_600115 = validateParameter(valid_600115, JBool, required = false, default = nil)
  if valid_600115 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600115
  var valid_600116 = query.getOrDefault("EngineVersion")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "EngineVersion", valid_600116
  var valid_600117 = query.getOrDefault("Port")
  valid_600117 = validateParameter(valid_600117, JInt, required = false, default = nil)
  if valid_600117 != nil:
    section.add "Port", valid_600117
  var valid_600118 = query.getOrDefault("PreferredBackupWindow")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "PreferredBackupWindow", valid_600118
  var valid_600119 = query.getOrDefault("Version")
  valid_600119 = validateParameter(valid_600119, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600119 != nil:
    section.add "Version", valid_600119
  var valid_600120 = query.getOrDefault("DBInstanceIdentifier")
  valid_600120 = validateParameter(valid_600120, JString, required = true,
                                 default = nil)
  if valid_600120 != nil:
    section.add "DBInstanceIdentifier", valid_600120
  var valid_600121 = query.getOrDefault("MasterUsername")
  valid_600121 = validateParameter(valid_600121, JString, required = true,
                                 default = nil)
  if valid_600121 != nil:
    section.add "MasterUsername", valid_600121
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600122 = header.getOrDefault("X-Amz-Date")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Date", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Security-Token")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Security-Token", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Content-Sha256", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Algorithm")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Algorithm", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Signature")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Signature", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-SignedHeaders", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-Credential")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-Credential", valid_600128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600129: Call_GetCreateDBInstance_600092; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600129.validator(path, query, header, formData, body)
  let scheme = call_600129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600129.url(scheme.get, call_600129.host, call_600129.base,
                         call_600129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600129, url, valid)

proc call*(call_600130: Call_GetCreateDBInstance_600092; Engine: string;
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
  var query_600131 = newJObject()
  add(query_600131, "Engine", newJString(Engine))
  add(query_600131, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_600131, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_600131, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_600131.add "DBSecurityGroups", DBSecurityGroups
  add(query_600131, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_600131, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600131, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_600131.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_600131, "MultiAZ", newJBool(MultiAZ))
  add(query_600131, "LicenseModel", newJString(LicenseModel))
  add(query_600131, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_600131, "DBName", newJString(DBName))
  add(query_600131, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_600131.add "Tags", Tags
  add(query_600131, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_600131, "Action", newJString(Action))
  add(query_600131, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600131, "CharacterSetName", newJString(CharacterSetName))
  add(query_600131, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_600131, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_600131, "EngineVersion", newJString(EngineVersion))
  add(query_600131, "Port", newJInt(Port))
  add(query_600131, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_600131, "Version", newJString(Version))
  add(query_600131, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600131, "MasterUsername", newJString(MasterUsername))
  result = call_600130.call(nil, query_600131, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_600092(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_600093, base: "/",
    url: url_GetCreateDBInstance_600094, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_600199 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBInstanceReadReplica_600201(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_600200(path: JsonNode;
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
  var valid_600202 = query.getOrDefault("Action")
  valid_600202 = validateParameter(valid_600202, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_600202 != nil:
    section.add "Action", valid_600202
  var valid_600203 = query.getOrDefault("Version")
  valid_600203 = validateParameter(valid_600203, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600203 != nil:
    section.add "Version", valid_600203
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600204 = header.getOrDefault("X-Amz-Date")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Date", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Security-Token")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Security-Token", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Content-Sha256", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Algorithm")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Algorithm", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-Signature")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-Signature", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-SignedHeaders", valid_600209
  var valid_600210 = header.getOrDefault("X-Amz-Credential")
  valid_600210 = validateParameter(valid_600210, JString, required = false,
                                 default = nil)
  if valid_600210 != nil:
    section.add "X-Amz-Credential", valid_600210
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
  var valid_600211 = formData.getOrDefault("Port")
  valid_600211 = validateParameter(valid_600211, JInt, required = false, default = nil)
  if valid_600211 != nil:
    section.add "Port", valid_600211
  var valid_600212 = formData.getOrDefault("Iops")
  valid_600212 = validateParameter(valid_600212, JInt, required = false, default = nil)
  if valid_600212 != nil:
    section.add "Iops", valid_600212
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600213 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600213 = validateParameter(valid_600213, JString, required = true,
                                 default = nil)
  if valid_600213 != nil:
    section.add "DBInstanceIdentifier", valid_600213
  var valid_600214 = formData.getOrDefault("OptionGroupName")
  valid_600214 = validateParameter(valid_600214, JString, required = false,
                                 default = nil)
  if valid_600214 != nil:
    section.add "OptionGroupName", valid_600214
  var valid_600215 = formData.getOrDefault("Tags")
  valid_600215 = validateParameter(valid_600215, JArray, required = false,
                                 default = nil)
  if valid_600215 != nil:
    section.add "Tags", valid_600215
  var valid_600216 = formData.getOrDefault("DBSubnetGroupName")
  valid_600216 = validateParameter(valid_600216, JString, required = false,
                                 default = nil)
  if valid_600216 != nil:
    section.add "DBSubnetGroupName", valid_600216
  var valid_600217 = formData.getOrDefault("AvailabilityZone")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "AvailabilityZone", valid_600217
  var valid_600218 = formData.getOrDefault("PubliclyAccessible")
  valid_600218 = validateParameter(valid_600218, JBool, required = false, default = nil)
  if valid_600218 != nil:
    section.add "PubliclyAccessible", valid_600218
  var valid_600219 = formData.getOrDefault("DBInstanceClass")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "DBInstanceClass", valid_600219
  var valid_600220 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_600220 = validateParameter(valid_600220, JString, required = true,
                                 default = nil)
  if valid_600220 != nil:
    section.add "SourceDBInstanceIdentifier", valid_600220
  var valid_600221 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_600221 = validateParameter(valid_600221, JBool, required = false, default = nil)
  if valid_600221 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600221
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600222: Call_PostCreateDBInstanceReadReplica_600199;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600222.validator(path, query, header, formData, body)
  let scheme = call_600222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600222.url(scheme.get, call_600222.host, call_600222.base,
                         call_600222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600222, url, valid)

proc call*(call_600223: Call_PostCreateDBInstanceReadReplica_600199;
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
  var query_600224 = newJObject()
  var formData_600225 = newJObject()
  add(formData_600225, "Port", newJInt(Port))
  add(formData_600225, "Iops", newJInt(Iops))
  add(formData_600225, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600225, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_600225.add "Tags", Tags
  add(formData_600225, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_600225, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600224, "Action", newJString(Action))
  add(formData_600225, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_600225, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_600225, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_600225, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_600224, "Version", newJString(Version))
  result = call_600223.call(nil, query_600224, nil, formData_600225, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_600199(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_600200, base: "/",
    url: url_PostCreateDBInstanceReadReplica_600201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_600173 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBInstanceReadReplica_600175(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_600174(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600176 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_600176 = validateParameter(valid_600176, JString, required = true,
                                 default = nil)
  if valid_600176 != nil:
    section.add "SourceDBInstanceIdentifier", valid_600176
  var valid_600177 = query.getOrDefault("OptionGroupName")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "OptionGroupName", valid_600177
  var valid_600178 = query.getOrDefault("AvailabilityZone")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "AvailabilityZone", valid_600178
  var valid_600179 = query.getOrDefault("Iops")
  valid_600179 = validateParameter(valid_600179, JInt, required = false, default = nil)
  if valid_600179 != nil:
    section.add "Iops", valid_600179
  var valid_600180 = query.getOrDefault("Tags")
  valid_600180 = validateParameter(valid_600180, JArray, required = false,
                                 default = nil)
  if valid_600180 != nil:
    section.add "Tags", valid_600180
  var valid_600181 = query.getOrDefault("DBInstanceClass")
  valid_600181 = validateParameter(valid_600181, JString, required = false,
                                 default = nil)
  if valid_600181 != nil:
    section.add "DBInstanceClass", valid_600181
  var valid_600182 = query.getOrDefault("Action")
  valid_600182 = validateParameter(valid_600182, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_600182 != nil:
    section.add "Action", valid_600182
  var valid_600183 = query.getOrDefault("DBSubnetGroupName")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "DBSubnetGroupName", valid_600183
  var valid_600184 = query.getOrDefault("PubliclyAccessible")
  valid_600184 = validateParameter(valid_600184, JBool, required = false, default = nil)
  if valid_600184 != nil:
    section.add "PubliclyAccessible", valid_600184
  var valid_600185 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_600185 = validateParameter(valid_600185, JBool, required = false, default = nil)
  if valid_600185 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600185
  var valid_600186 = query.getOrDefault("Port")
  valid_600186 = validateParameter(valid_600186, JInt, required = false, default = nil)
  if valid_600186 != nil:
    section.add "Port", valid_600186
  var valid_600187 = query.getOrDefault("Version")
  valid_600187 = validateParameter(valid_600187, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600187 != nil:
    section.add "Version", valid_600187
  var valid_600188 = query.getOrDefault("DBInstanceIdentifier")
  valid_600188 = validateParameter(valid_600188, JString, required = true,
                                 default = nil)
  if valid_600188 != nil:
    section.add "DBInstanceIdentifier", valid_600188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600189 = header.getOrDefault("X-Amz-Date")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Date", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Security-Token")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Security-Token", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Content-Sha256", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-Algorithm")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-Algorithm", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Signature")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Signature", valid_600193
  var valid_600194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600194 = validateParameter(valid_600194, JString, required = false,
                                 default = nil)
  if valid_600194 != nil:
    section.add "X-Amz-SignedHeaders", valid_600194
  var valid_600195 = header.getOrDefault("X-Amz-Credential")
  valid_600195 = validateParameter(valid_600195, JString, required = false,
                                 default = nil)
  if valid_600195 != nil:
    section.add "X-Amz-Credential", valid_600195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600196: Call_GetCreateDBInstanceReadReplica_600173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600196.validator(path, query, header, formData, body)
  let scheme = call_600196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600196.url(scheme.get, call_600196.host, call_600196.base,
                         call_600196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600196, url, valid)

proc call*(call_600197: Call_GetCreateDBInstanceReadReplica_600173;
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
  var query_600198 = newJObject()
  add(query_600198, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_600198, "OptionGroupName", newJString(OptionGroupName))
  add(query_600198, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600198, "Iops", newJInt(Iops))
  if Tags != nil:
    query_600198.add "Tags", Tags
  add(query_600198, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_600198, "Action", newJString(Action))
  add(query_600198, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600198, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_600198, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_600198, "Port", newJInt(Port))
  add(query_600198, "Version", newJString(Version))
  add(query_600198, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600197.call(nil, query_600198, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_600173(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_600174, base: "/",
    url: url_GetCreateDBInstanceReadReplica_600175,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_600245 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBParameterGroup_600247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_600246(path: JsonNode; query: JsonNode;
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
  var valid_600248 = query.getOrDefault("Action")
  valid_600248 = validateParameter(valid_600248, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_600248 != nil:
    section.add "Action", valid_600248
  var valid_600249 = query.getOrDefault("Version")
  valid_600249 = validateParameter(valid_600249, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600249 != nil:
    section.add "Version", valid_600249
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600250 = header.getOrDefault("X-Amz-Date")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Date", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Security-Token")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Security-Token", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-Content-Sha256", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Algorithm")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Algorithm", valid_600253
  var valid_600254 = header.getOrDefault("X-Amz-Signature")
  valid_600254 = validateParameter(valid_600254, JString, required = false,
                                 default = nil)
  if valid_600254 != nil:
    section.add "X-Amz-Signature", valid_600254
  var valid_600255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600255 = validateParameter(valid_600255, JString, required = false,
                                 default = nil)
  if valid_600255 != nil:
    section.add "X-Amz-SignedHeaders", valid_600255
  var valid_600256 = header.getOrDefault("X-Amz-Credential")
  valid_600256 = validateParameter(valid_600256, JString, required = false,
                                 default = nil)
  if valid_600256 != nil:
    section.add "X-Amz-Credential", valid_600256
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600257 = formData.getOrDefault("DBParameterGroupName")
  valid_600257 = validateParameter(valid_600257, JString, required = true,
                                 default = nil)
  if valid_600257 != nil:
    section.add "DBParameterGroupName", valid_600257
  var valid_600258 = formData.getOrDefault("Tags")
  valid_600258 = validateParameter(valid_600258, JArray, required = false,
                                 default = nil)
  if valid_600258 != nil:
    section.add "Tags", valid_600258
  var valid_600259 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600259 = validateParameter(valid_600259, JString, required = true,
                                 default = nil)
  if valid_600259 != nil:
    section.add "DBParameterGroupFamily", valid_600259
  var valid_600260 = formData.getOrDefault("Description")
  valid_600260 = validateParameter(valid_600260, JString, required = true,
                                 default = nil)
  if valid_600260 != nil:
    section.add "Description", valid_600260
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600261: Call_PostCreateDBParameterGroup_600245; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600261.validator(path, query, header, formData, body)
  let scheme = call_600261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600261.url(scheme.get, call_600261.host, call_600261.base,
                         call_600261.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600261, url, valid)

proc call*(call_600262: Call_PostCreateDBParameterGroup_600245;
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
  var query_600263 = newJObject()
  var formData_600264 = newJObject()
  add(formData_600264, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_600264.add "Tags", Tags
  add(query_600263, "Action", newJString(Action))
  add(formData_600264, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_600263, "Version", newJString(Version))
  add(formData_600264, "Description", newJString(Description))
  result = call_600262.call(nil, query_600263, nil, formData_600264, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_600245(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_600246, base: "/",
    url: url_PostCreateDBParameterGroup_600247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_600226 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBParameterGroup_600228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_600227(path: JsonNode; query: JsonNode;
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
  var valid_600229 = query.getOrDefault("Description")
  valid_600229 = validateParameter(valid_600229, JString, required = true,
                                 default = nil)
  if valid_600229 != nil:
    section.add "Description", valid_600229
  var valid_600230 = query.getOrDefault("DBParameterGroupFamily")
  valid_600230 = validateParameter(valid_600230, JString, required = true,
                                 default = nil)
  if valid_600230 != nil:
    section.add "DBParameterGroupFamily", valid_600230
  var valid_600231 = query.getOrDefault("Tags")
  valid_600231 = validateParameter(valid_600231, JArray, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "Tags", valid_600231
  var valid_600232 = query.getOrDefault("DBParameterGroupName")
  valid_600232 = validateParameter(valid_600232, JString, required = true,
                                 default = nil)
  if valid_600232 != nil:
    section.add "DBParameterGroupName", valid_600232
  var valid_600233 = query.getOrDefault("Action")
  valid_600233 = validateParameter(valid_600233, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_600233 != nil:
    section.add "Action", valid_600233
  var valid_600234 = query.getOrDefault("Version")
  valid_600234 = validateParameter(valid_600234, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600234 != nil:
    section.add "Version", valid_600234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600235 = header.getOrDefault("X-Amz-Date")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Date", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Security-Token")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Security-Token", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Content-Sha256", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-Algorithm")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-Algorithm", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Signature")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Signature", valid_600239
  var valid_600240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600240 = validateParameter(valid_600240, JString, required = false,
                                 default = nil)
  if valid_600240 != nil:
    section.add "X-Amz-SignedHeaders", valid_600240
  var valid_600241 = header.getOrDefault("X-Amz-Credential")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Credential", valid_600241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600242: Call_GetCreateDBParameterGroup_600226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600242.validator(path, query, header, formData, body)
  let scheme = call_600242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600242.url(scheme.get, call_600242.host, call_600242.base,
                         call_600242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600242, url, valid)

proc call*(call_600243: Call_GetCreateDBParameterGroup_600226; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Tags: JsonNode = nil; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600244 = newJObject()
  add(query_600244, "Description", newJString(Description))
  add(query_600244, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_600244.add "Tags", Tags
  add(query_600244, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600244, "Action", newJString(Action))
  add(query_600244, "Version", newJString(Version))
  result = call_600243.call(nil, query_600244, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_600226(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_600227, base: "/",
    url: url_GetCreateDBParameterGroup_600228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_600283 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSecurityGroup_600285(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_600284(path: JsonNode; query: JsonNode;
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
  var valid_600286 = query.getOrDefault("Action")
  valid_600286 = validateParameter(valid_600286, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_600286 != nil:
    section.add "Action", valid_600286
  var valid_600287 = query.getOrDefault("Version")
  valid_600287 = validateParameter(valid_600287, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600287 != nil:
    section.add "Version", valid_600287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600288 = header.getOrDefault("X-Amz-Date")
  valid_600288 = validateParameter(valid_600288, JString, required = false,
                                 default = nil)
  if valid_600288 != nil:
    section.add "X-Amz-Date", valid_600288
  var valid_600289 = header.getOrDefault("X-Amz-Security-Token")
  valid_600289 = validateParameter(valid_600289, JString, required = false,
                                 default = nil)
  if valid_600289 != nil:
    section.add "X-Amz-Security-Token", valid_600289
  var valid_600290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600290 = validateParameter(valid_600290, JString, required = false,
                                 default = nil)
  if valid_600290 != nil:
    section.add "X-Amz-Content-Sha256", valid_600290
  var valid_600291 = header.getOrDefault("X-Amz-Algorithm")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Algorithm", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Signature")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Signature", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-SignedHeaders", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Credential")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Credential", valid_600294
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600295 = formData.getOrDefault("DBSecurityGroupName")
  valid_600295 = validateParameter(valid_600295, JString, required = true,
                                 default = nil)
  if valid_600295 != nil:
    section.add "DBSecurityGroupName", valid_600295
  var valid_600296 = formData.getOrDefault("Tags")
  valid_600296 = validateParameter(valid_600296, JArray, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "Tags", valid_600296
  var valid_600297 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_600297 = validateParameter(valid_600297, JString, required = true,
                                 default = nil)
  if valid_600297 != nil:
    section.add "DBSecurityGroupDescription", valid_600297
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600298: Call_PostCreateDBSecurityGroup_600283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600298.validator(path, query, header, formData, body)
  let scheme = call_600298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600298.url(scheme.get, call_600298.host, call_600298.base,
                         call_600298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600298, url, valid)

proc call*(call_600299: Call_PostCreateDBSecurityGroup_600283;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_600300 = newJObject()
  var formData_600301 = newJObject()
  add(formData_600301, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_600301.add "Tags", Tags
  add(query_600300, "Action", newJString(Action))
  add(formData_600301, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_600300, "Version", newJString(Version))
  result = call_600299.call(nil, query_600300, nil, formData_600301, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_600283(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_600284, base: "/",
    url: url_PostCreateDBSecurityGroup_600285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_600265 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSecurityGroup_600267(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_600266(path: JsonNode; query: JsonNode;
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
  var valid_600268 = query.getOrDefault("DBSecurityGroupName")
  valid_600268 = validateParameter(valid_600268, JString, required = true,
                                 default = nil)
  if valid_600268 != nil:
    section.add "DBSecurityGroupName", valid_600268
  var valid_600269 = query.getOrDefault("DBSecurityGroupDescription")
  valid_600269 = validateParameter(valid_600269, JString, required = true,
                                 default = nil)
  if valid_600269 != nil:
    section.add "DBSecurityGroupDescription", valid_600269
  var valid_600270 = query.getOrDefault("Tags")
  valid_600270 = validateParameter(valid_600270, JArray, required = false,
                                 default = nil)
  if valid_600270 != nil:
    section.add "Tags", valid_600270
  var valid_600271 = query.getOrDefault("Action")
  valid_600271 = validateParameter(valid_600271, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_600271 != nil:
    section.add "Action", valid_600271
  var valid_600272 = query.getOrDefault("Version")
  valid_600272 = validateParameter(valid_600272, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600272 != nil:
    section.add "Version", valid_600272
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600273 = header.getOrDefault("X-Amz-Date")
  valid_600273 = validateParameter(valid_600273, JString, required = false,
                                 default = nil)
  if valid_600273 != nil:
    section.add "X-Amz-Date", valid_600273
  var valid_600274 = header.getOrDefault("X-Amz-Security-Token")
  valid_600274 = validateParameter(valid_600274, JString, required = false,
                                 default = nil)
  if valid_600274 != nil:
    section.add "X-Amz-Security-Token", valid_600274
  var valid_600275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600275 = validateParameter(valid_600275, JString, required = false,
                                 default = nil)
  if valid_600275 != nil:
    section.add "X-Amz-Content-Sha256", valid_600275
  var valid_600276 = header.getOrDefault("X-Amz-Algorithm")
  valid_600276 = validateParameter(valid_600276, JString, required = false,
                                 default = nil)
  if valid_600276 != nil:
    section.add "X-Amz-Algorithm", valid_600276
  var valid_600277 = header.getOrDefault("X-Amz-Signature")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Signature", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-SignedHeaders", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Credential")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Credential", valid_600279
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600280: Call_GetCreateDBSecurityGroup_600265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600280.validator(path, query, header, formData, body)
  let scheme = call_600280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600280.url(scheme.get, call_600280.host, call_600280.base,
                         call_600280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600280, url, valid)

proc call*(call_600281: Call_GetCreateDBSecurityGroup_600265;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600282 = newJObject()
  add(query_600282, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600282, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_600282.add "Tags", Tags
  add(query_600282, "Action", newJString(Action))
  add(query_600282, "Version", newJString(Version))
  result = call_600281.call(nil, query_600282, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_600265(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_600266, base: "/",
    url: url_GetCreateDBSecurityGroup_600267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_600320 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSnapshot_600322(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_600321(path: JsonNode; query: JsonNode;
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
  var valid_600323 = query.getOrDefault("Action")
  valid_600323 = validateParameter(valid_600323, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_600323 != nil:
    section.add "Action", valid_600323
  var valid_600324 = query.getOrDefault("Version")
  valid_600324 = validateParameter(valid_600324, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600324 != nil:
    section.add "Version", valid_600324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600325 = header.getOrDefault("X-Amz-Date")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Date", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-Security-Token")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-Security-Token", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Content-Sha256", valid_600327
  var valid_600328 = header.getOrDefault("X-Amz-Algorithm")
  valid_600328 = validateParameter(valid_600328, JString, required = false,
                                 default = nil)
  if valid_600328 != nil:
    section.add "X-Amz-Algorithm", valid_600328
  var valid_600329 = header.getOrDefault("X-Amz-Signature")
  valid_600329 = validateParameter(valid_600329, JString, required = false,
                                 default = nil)
  if valid_600329 != nil:
    section.add "X-Amz-Signature", valid_600329
  var valid_600330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600330 = validateParameter(valid_600330, JString, required = false,
                                 default = nil)
  if valid_600330 != nil:
    section.add "X-Amz-SignedHeaders", valid_600330
  var valid_600331 = header.getOrDefault("X-Amz-Credential")
  valid_600331 = validateParameter(valid_600331, JString, required = false,
                                 default = nil)
  if valid_600331 != nil:
    section.add "X-Amz-Credential", valid_600331
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600332 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600332 = validateParameter(valid_600332, JString, required = true,
                                 default = nil)
  if valid_600332 != nil:
    section.add "DBInstanceIdentifier", valid_600332
  var valid_600333 = formData.getOrDefault("Tags")
  valid_600333 = validateParameter(valid_600333, JArray, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "Tags", valid_600333
  var valid_600334 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600334 = validateParameter(valid_600334, JString, required = true,
                                 default = nil)
  if valid_600334 != nil:
    section.add "DBSnapshotIdentifier", valid_600334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600335: Call_PostCreateDBSnapshot_600320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600335.validator(path, query, header, formData, body)
  let scheme = call_600335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600335.url(scheme.get, call_600335.host, call_600335.base,
                         call_600335.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600335, url, valid)

proc call*(call_600336: Call_PostCreateDBSnapshot_600320;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600337 = newJObject()
  var formData_600338 = newJObject()
  add(formData_600338, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_600338.add "Tags", Tags
  add(formData_600338, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600337, "Action", newJString(Action))
  add(query_600337, "Version", newJString(Version))
  result = call_600336.call(nil, query_600337, nil, formData_600338, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_600320(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_600321, base: "/",
    url: url_PostCreateDBSnapshot_600322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_600302 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSnapshot_600304(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_600303(path: JsonNode; query: JsonNode;
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
  var valid_600305 = query.getOrDefault("Tags")
  valid_600305 = validateParameter(valid_600305, JArray, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "Tags", valid_600305
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600306 = query.getOrDefault("Action")
  valid_600306 = validateParameter(valid_600306, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_600306 != nil:
    section.add "Action", valid_600306
  var valid_600307 = query.getOrDefault("Version")
  valid_600307 = validateParameter(valid_600307, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600307 != nil:
    section.add "Version", valid_600307
  var valid_600308 = query.getOrDefault("DBInstanceIdentifier")
  valid_600308 = validateParameter(valid_600308, JString, required = true,
                                 default = nil)
  if valid_600308 != nil:
    section.add "DBInstanceIdentifier", valid_600308
  var valid_600309 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600309 = validateParameter(valid_600309, JString, required = true,
                                 default = nil)
  if valid_600309 != nil:
    section.add "DBSnapshotIdentifier", valid_600309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600310 = header.getOrDefault("X-Amz-Date")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-Date", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Security-Token")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Security-Token", valid_600311
  var valid_600312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Content-Sha256", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Algorithm")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Algorithm", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Signature")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Signature", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-SignedHeaders", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Credential")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Credential", valid_600316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600317: Call_GetCreateDBSnapshot_600302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600317.validator(path, query, header, formData, body)
  let scheme = call_600317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600317.url(scheme.get, call_600317.host, call_600317.base,
                         call_600317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600317, url, valid)

proc call*(call_600318: Call_GetCreateDBSnapshot_600302;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_600319 = newJObject()
  if Tags != nil:
    query_600319.add "Tags", Tags
  add(query_600319, "Action", newJString(Action))
  add(query_600319, "Version", newJString(Version))
  add(query_600319, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600319, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600318.call(nil, query_600319, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_600302(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_600303, base: "/",
    url: url_GetCreateDBSnapshot_600304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_600358 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSubnetGroup_600360(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_600359(path: JsonNode; query: JsonNode;
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
  var valid_600361 = query.getOrDefault("Action")
  valid_600361 = validateParameter(valid_600361, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600361 != nil:
    section.add "Action", valid_600361
  var valid_600362 = query.getOrDefault("Version")
  valid_600362 = validateParameter(valid_600362, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600362 != nil:
    section.add "Version", valid_600362
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600363 = header.getOrDefault("X-Amz-Date")
  valid_600363 = validateParameter(valid_600363, JString, required = false,
                                 default = nil)
  if valid_600363 != nil:
    section.add "X-Amz-Date", valid_600363
  var valid_600364 = header.getOrDefault("X-Amz-Security-Token")
  valid_600364 = validateParameter(valid_600364, JString, required = false,
                                 default = nil)
  if valid_600364 != nil:
    section.add "X-Amz-Security-Token", valid_600364
  var valid_600365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Content-Sha256", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-Algorithm")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Algorithm", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Signature")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Signature", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-SignedHeaders", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Credential")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Credential", valid_600369
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_600370 = formData.getOrDefault("Tags")
  valid_600370 = validateParameter(valid_600370, JArray, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "Tags", valid_600370
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600371 = formData.getOrDefault("DBSubnetGroupName")
  valid_600371 = validateParameter(valid_600371, JString, required = true,
                                 default = nil)
  if valid_600371 != nil:
    section.add "DBSubnetGroupName", valid_600371
  var valid_600372 = formData.getOrDefault("SubnetIds")
  valid_600372 = validateParameter(valid_600372, JArray, required = true, default = nil)
  if valid_600372 != nil:
    section.add "SubnetIds", valid_600372
  var valid_600373 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_600373 = validateParameter(valid_600373, JString, required = true,
                                 default = nil)
  if valid_600373 != nil:
    section.add "DBSubnetGroupDescription", valid_600373
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600374: Call_PostCreateDBSubnetGroup_600358; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600374.validator(path, query, header, formData, body)
  let scheme = call_600374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600374.url(scheme.get, call_600374.host, call_600374.base,
                         call_600374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600374, url, valid)

proc call*(call_600375: Call_PostCreateDBSubnetGroup_600358;
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
  var query_600376 = newJObject()
  var formData_600377 = newJObject()
  if Tags != nil:
    formData_600377.add "Tags", Tags
  add(formData_600377, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_600377.add "SubnetIds", SubnetIds
  add(query_600376, "Action", newJString(Action))
  add(formData_600377, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600376, "Version", newJString(Version))
  result = call_600375.call(nil, query_600376, nil, formData_600377, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_600358(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_600359, base: "/",
    url: url_PostCreateDBSubnetGroup_600360, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_600339 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSubnetGroup_600341(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_600340(path: JsonNode; query: JsonNode;
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
  var valid_600342 = query.getOrDefault("Tags")
  valid_600342 = validateParameter(valid_600342, JArray, required = false,
                                 default = nil)
  if valid_600342 != nil:
    section.add "Tags", valid_600342
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600343 = query.getOrDefault("Action")
  valid_600343 = validateParameter(valid_600343, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600343 != nil:
    section.add "Action", valid_600343
  var valid_600344 = query.getOrDefault("DBSubnetGroupName")
  valid_600344 = validateParameter(valid_600344, JString, required = true,
                                 default = nil)
  if valid_600344 != nil:
    section.add "DBSubnetGroupName", valid_600344
  var valid_600345 = query.getOrDefault("SubnetIds")
  valid_600345 = validateParameter(valid_600345, JArray, required = true, default = nil)
  if valid_600345 != nil:
    section.add "SubnetIds", valid_600345
  var valid_600346 = query.getOrDefault("DBSubnetGroupDescription")
  valid_600346 = validateParameter(valid_600346, JString, required = true,
                                 default = nil)
  if valid_600346 != nil:
    section.add "DBSubnetGroupDescription", valid_600346
  var valid_600347 = query.getOrDefault("Version")
  valid_600347 = validateParameter(valid_600347, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600347 != nil:
    section.add "Version", valid_600347
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600348 = header.getOrDefault("X-Amz-Date")
  valid_600348 = validateParameter(valid_600348, JString, required = false,
                                 default = nil)
  if valid_600348 != nil:
    section.add "X-Amz-Date", valid_600348
  var valid_600349 = header.getOrDefault("X-Amz-Security-Token")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Security-Token", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Content-Sha256", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Algorithm")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Algorithm", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Signature")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Signature", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-SignedHeaders", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-Credential")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-Credential", valid_600354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600355: Call_GetCreateDBSubnetGroup_600339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600355.validator(path, query, header, formData, body)
  let scheme = call_600355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600355.url(scheme.get, call_600355.host, call_600355.base,
                         call_600355.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600355, url, valid)

proc call*(call_600356: Call_GetCreateDBSubnetGroup_600339;
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
  var query_600357 = newJObject()
  if Tags != nil:
    query_600357.add "Tags", Tags
  add(query_600357, "Action", newJString(Action))
  add(query_600357, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_600357.add "SubnetIds", SubnetIds
  add(query_600357, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600357, "Version", newJString(Version))
  result = call_600356.call(nil, query_600357, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_600339(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_600340, base: "/",
    url: url_GetCreateDBSubnetGroup_600341, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_600400 = ref object of OpenApiRestCall_599352
proc url_PostCreateEventSubscription_600402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_600401(path: JsonNode; query: JsonNode;
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
  var valid_600403 = query.getOrDefault("Action")
  valid_600403 = validateParameter(valid_600403, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_600403 != nil:
    section.add "Action", valid_600403
  var valid_600404 = query.getOrDefault("Version")
  valid_600404 = validateParameter(valid_600404, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600404 != nil:
    section.add "Version", valid_600404
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600405 = header.getOrDefault("X-Amz-Date")
  valid_600405 = validateParameter(valid_600405, JString, required = false,
                                 default = nil)
  if valid_600405 != nil:
    section.add "X-Amz-Date", valid_600405
  var valid_600406 = header.getOrDefault("X-Amz-Security-Token")
  valid_600406 = validateParameter(valid_600406, JString, required = false,
                                 default = nil)
  if valid_600406 != nil:
    section.add "X-Amz-Security-Token", valid_600406
  var valid_600407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600407 = validateParameter(valid_600407, JString, required = false,
                                 default = nil)
  if valid_600407 != nil:
    section.add "X-Amz-Content-Sha256", valid_600407
  var valid_600408 = header.getOrDefault("X-Amz-Algorithm")
  valid_600408 = validateParameter(valid_600408, JString, required = false,
                                 default = nil)
  if valid_600408 != nil:
    section.add "X-Amz-Algorithm", valid_600408
  var valid_600409 = header.getOrDefault("X-Amz-Signature")
  valid_600409 = validateParameter(valid_600409, JString, required = false,
                                 default = nil)
  if valid_600409 != nil:
    section.add "X-Amz-Signature", valid_600409
  var valid_600410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600410 = validateParameter(valid_600410, JString, required = false,
                                 default = nil)
  if valid_600410 != nil:
    section.add "X-Amz-SignedHeaders", valid_600410
  var valid_600411 = header.getOrDefault("X-Amz-Credential")
  valid_600411 = validateParameter(valid_600411, JString, required = false,
                                 default = nil)
  if valid_600411 != nil:
    section.add "X-Amz-Credential", valid_600411
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
  var valid_600412 = formData.getOrDefault("Enabled")
  valid_600412 = validateParameter(valid_600412, JBool, required = false, default = nil)
  if valid_600412 != nil:
    section.add "Enabled", valid_600412
  var valid_600413 = formData.getOrDefault("EventCategories")
  valid_600413 = validateParameter(valid_600413, JArray, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "EventCategories", valid_600413
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_600414 = formData.getOrDefault("SnsTopicArn")
  valid_600414 = validateParameter(valid_600414, JString, required = true,
                                 default = nil)
  if valid_600414 != nil:
    section.add "SnsTopicArn", valid_600414
  var valid_600415 = formData.getOrDefault("SourceIds")
  valid_600415 = validateParameter(valid_600415, JArray, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "SourceIds", valid_600415
  var valid_600416 = formData.getOrDefault("Tags")
  valid_600416 = validateParameter(valid_600416, JArray, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "Tags", valid_600416
  var valid_600417 = formData.getOrDefault("SubscriptionName")
  valid_600417 = validateParameter(valid_600417, JString, required = true,
                                 default = nil)
  if valid_600417 != nil:
    section.add "SubscriptionName", valid_600417
  var valid_600418 = formData.getOrDefault("SourceType")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "SourceType", valid_600418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600419: Call_PostCreateEventSubscription_600400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600419.validator(path, query, header, formData, body)
  let scheme = call_600419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600419.url(scheme.get, call_600419.host, call_600419.base,
                         call_600419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600419, url, valid)

proc call*(call_600420: Call_PostCreateEventSubscription_600400;
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
  var query_600421 = newJObject()
  var formData_600422 = newJObject()
  add(formData_600422, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_600422.add "EventCategories", EventCategories
  add(formData_600422, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_600422.add "SourceIds", SourceIds
  if Tags != nil:
    formData_600422.add "Tags", Tags
  add(formData_600422, "SubscriptionName", newJString(SubscriptionName))
  add(query_600421, "Action", newJString(Action))
  add(query_600421, "Version", newJString(Version))
  add(formData_600422, "SourceType", newJString(SourceType))
  result = call_600420.call(nil, query_600421, nil, formData_600422, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_600400(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_600401, base: "/",
    url: url_PostCreateEventSubscription_600402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_600378 = ref object of OpenApiRestCall_599352
proc url_GetCreateEventSubscription_600380(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_600379(path: JsonNode; query: JsonNode;
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
  var valid_600381 = query.getOrDefault("SourceType")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "SourceType", valid_600381
  var valid_600382 = query.getOrDefault("SourceIds")
  valid_600382 = validateParameter(valid_600382, JArray, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "SourceIds", valid_600382
  var valid_600383 = query.getOrDefault("Enabled")
  valid_600383 = validateParameter(valid_600383, JBool, required = false, default = nil)
  if valid_600383 != nil:
    section.add "Enabled", valid_600383
  var valid_600384 = query.getOrDefault("Tags")
  valid_600384 = validateParameter(valid_600384, JArray, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "Tags", valid_600384
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600385 = query.getOrDefault("Action")
  valid_600385 = validateParameter(valid_600385, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_600385 != nil:
    section.add "Action", valid_600385
  var valid_600386 = query.getOrDefault("SnsTopicArn")
  valid_600386 = validateParameter(valid_600386, JString, required = true,
                                 default = nil)
  if valid_600386 != nil:
    section.add "SnsTopicArn", valid_600386
  var valid_600387 = query.getOrDefault("EventCategories")
  valid_600387 = validateParameter(valid_600387, JArray, required = false,
                                 default = nil)
  if valid_600387 != nil:
    section.add "EventCategories", valid_600387
  var valid_600388 = query.getOrDefault("SubscriptionName")
  valid_600388 = validateParameter(valid_600388, JString, required = true,
                                 default = nil)
  if valid_600388 != nil:
    section.add "SubscriptionName", valid_600388
  var valid_600389 = query.getOrDefault("Version")
  valid_600389 = validateParameter(valid_600389, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600389 != nil:
    section.add "Version", valid_600389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600390 = header.getOrDefault("X-Amz-Date")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Date", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Security-Token")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Security-Token", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Content-Sha256", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-Algorithm")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-Algorithm", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Signature")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Signature", valid_600394
  var valid_600395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-SignedHeaders", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Credential")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Credential", valid_600396
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600397: Call_GetCreateEventSubscription_600378; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600397.validator(path, query, header, formData, body)
  let scheme = call_600397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600397.url(scheme.get, call_600397.host, call_600397.base,
                         call_600397.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600397, url, valid)

proc call*(call_600398: Call_GetCreateEventSubscription_600378;
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
  var query_600399 = newJObject()
  add(query_600399, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_600399.add "SourceIds", SourceIds
  add(query_600399, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_600399.add "Tags", Tags
  add(query_600399, "Action", newJString(Action))
  add(query_600399, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_600399.add "EventCategories", EventCategories
  add(query_600399, "SubscriptionName", newJString(SubscriptionName))
  add(query_600399, "Version", newJString(Version))
  result = call_600398.call(nil, query_600399, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_600378(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_600379, base: "/",
    url: url_GetCreateEventSubscription_600380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_600443 = ref object of OpenApiRestCall_599352
proc url_PostCreateOptionGroup_600445(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_600444(path: JsonNode; query: JsonNode;
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
  var valid_600446 = query.getOrDefault("Action")
  valid_600446 = validateParameter(valid_600446, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_600446 != nil:
    section.add "Action", valid_600446
  var valid_600447 = query.getOrDefault("Version")
  valid_600447 = validateParameter(valid_600447, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600447 != nil:
    section.add "Version", valid_600447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600448 = header.getOrDefault("X-Amz-Date")
  valid_600448 = validateParameter(valid_600448, JString, required = false,
                                 default = nil)
  if valid_600448 != nil:
    section.add "X-Amz-Date", valid_600448
  var valid_600449 = header.getOrDefault("X-Amz-Security-Token")
  valid_600449 = validateParameter(valid_600449, JString, required = false,
                                 default = nil)
  if valid_600449 != nil:
    section.add "X-Amz-Security-Token", valid_600449
  var valid_600450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600450 = validateParameter(valid_600450, JString, required = false,
                                 default = nil)
  if valid_600450 != nil:
    section.add "X-Amz-Content-Sha256", valid_600450
  var valid_600451 = header.getOrDefault("X-Amz-Algorithm")
  valid_600451 = validateParameter(valid_600451, JString, required = false,
                                 default = nil)
  if valid_600451 != nil:
    section.add "X-Amz-Algorithm", valid_600451
  var valid_600452 = header.getOrDefault("X-Amz-Signature")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Signature", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-SignedHeaders", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Credential")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Credential", valid_600454
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_600455 = formData.getOrDefault("MajorEngineVersion")
  valid_600455 = validateParameter(valid_600455, JString, required = true,
                                 default = nil)
  if valid_600455 != nil:
    section.add "MajorEngineVersion", valid_600455
  var valid_600456 = formData.getOrDefault("OptionGroupName")
  valid_600456 = validateParameter(valid_600456, JString, required = true,
                                 default = nil)
  if valid_600456 != nil:
    section.add "OptionGroupName", valid_600456
  var valid_600457 = formData.getOrDefault("Tags")
  valid_600457 = validateParameter(valid_600457, JArray, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "Tags", valid_600457
  var valid_600458 = formData.getOrDefault("EngineName")
  valid_600458 = validateParameter(valid_600458, JString, required = true,
                                 default = nil)
  if valid_600458 != nil:
    section.add "EngineName", valid_600458
  var valid_600459 = formData.getOrDefault("OptionGroupDescription")
  valid_600459 = validateParameter(valid_600459, JString, required = true,
                                 default = nil)
  if valid_600459 != nil:
    section.add "OptionGroupDescription", valid_600459
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600460: Call_PostCreateOptionGroup_600443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600460.validator(path, query, header, formData, body)
  let scheme = call_600460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600460.url(scheme.get, call_600460.host, call_600460.base,
                         call_600460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600460, url, valid)

proc call*(call_600461: Call_PostCreateOptionGroup_600443;
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
  var query_600462 = newJObject()
  var formData_600463 = newJObject()
  add(formData_600463, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_600463, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_600463.add "Tags", Tags
  add(query_600462, "Action", newJString(Action))
  add(formData_600463, "EngineName", newJString(EngineName))
  add(formData_600463, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_600462, "Version", newJString(Version))
  result = call_600461.call(nil, query_600462, nil, formData_600463, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_600443(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_600444, base: "/",
    url: url_PostCreateOptionGroup_600445, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_600423 = ref object of OpenApiRestCall_599352
proc url_GetCreateOptionGroup_600425(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_600424(path: JsonNode; query: JsonNode;
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
  var valid_600426 = query.getOrDefault("OptionGroupName")
  valid_600426 = validateParameter(valid_600426, JString, required = true,
                                 default = nil)
  if valid_600426 != nil:
    section.add "OptionGroupName", valid_600426
  var valid_600427 = query.getOrDefault("Tags")
  valid_600427 = validateParameter(valid_600427, JArray, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "Tags", valid_600427
  var valid_600428 = query.getOrDefault("OptionGroupDescription")
  valid_600428 = validateParameter(valid_600428, JString, required = true,
                                 default = nil)
  if valid_600428 != nil:
    section.add "OptionGroupDescription", valid_600428
  var valid_600429 = query.getOrDefault("Action")
  valid_600429 = validateParameter(valid_600429, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_600429 != nil:
    section.add "Action", valid_600429
  var valid_600430 = query.getOrDefault("Version")
  valid_600430 = validateParameter(valid_600430, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600430 != nil:
    section.add "Version", valid_600430
  var valid_600431 = query.getOrDefault("EngineName")
  valid_600431 = validateParameter(valid_600431, JString, required = true,
                                 default = nil)
  if valid_600431 != nil:
    section.add "EngineName", valid_600431
  var valid_600432 = query.getOrDefault("MajorEngineVersion")
  valid_600432 = validateParameter(valid_600432, JString, required = true,
                                 default = nil)
  if valid_600432 != nil:
    section.add "MajorEngineVersion", valid_600432
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600433 = header.getOrDefault("X-Amz-Date")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Date", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-Security-Token")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-Security-Token", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Content-Sha256", valid_600435
  var valid_600436 = header.getOrDefault("X-Amz-Algorithm")
  valid_600436 = validateParameter(valid_600436, JString, required = false,
                                 default = nil)
  if valid_600436 != nil:
    section.add "X-Amz-Algorithm", valid_600436
  var valid_600437 = header.getOrDefault("X-Amz-Signature")
  valid_600437 = validateParameter(valid_600437, JString, required = false,
                                 default = nil)
  if valid_600437 != nil:
    section.add "X-Amz-Signature", valid_600437
  var valid_600438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600438 = validateParameter(valid_600438, JString, required = false,
                                 default = nil)
  if valid_600438 != nil:
    section.add "X-Amz-SignedHeaders", valid_600438
  var valid_600439 = header.getOrDefault("X-Amz-Credential")
  valid_600439 = validateParameter(valid_600439, JString, required = false,
                                 default = nil)
  if valid_600439 != nil:
    section.add "X-Amz-Credential", valid_600439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600440: Call_GetCreateOptionGroup_600423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600440.validator(path, query, header, formData, body)
  let scheme = call_600440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600440.url(scheme.get, call_600440.host, call_600440.base,
                         call_600440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600440, url, valid)

proc call*(call_600441: Call_GetCreateOptionGroup_600423; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_600442 = newJObject()
  add(query_600442, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_600442.add "Tags", Tags
  add(query_600442, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_600442, "Action", newJString(Action))
  add(query_600442, "Version", newJString(Version))
  add(query_600442, "EngineName", newJString(EngineName))
  add(query_600442, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_600441.call(nil, query_600442, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_600423(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_600424, base: "/",
    url: url_GetCreateOptionGroup_600425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_600482 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBInstance_600484(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_600483(path: JsonNode; query: JsonNode;
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
  var valid_600485 = query.getOrDefault("Action")
  valid_600485 = validateParameter(valid_600485, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600485 != nil:
    section.add "Action", valid_600485
  var valid_600486 = query.getOrDefault("Version")
  valid_600486 = validateParameter(valid_600486, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600486 != nil:
    section.add "Version", valid_600486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600487 = header.getOrDefault("X-Amz-Date")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Date", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Security-Token")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Security-Token", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Content-Sha256", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Algorithm")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Algorithm", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-Signature")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-Signature", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-SignedHeaders", valid_600492
  var valid_600493 = header.getOrDefault("X-Amz-Credential")
  valid_600493 = validateParameter(valid_600493, JString, required = false,
                                 default = nil)
  if valid_600493 != nil:
    section.add "X-Amz-Credential", valid_600493
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600494 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600494 = validateParameter(valid_600494, JString, required = true,
                                 default = nil)
  if valid_600494 != nil:
    section.add "DBInstanceIdentifier", valid_600494
  var valid_600495 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600495 = validateParameter(valid_600495, JString, required = false,
                                 default = nil)
  if valid_600495 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600495
  var valid_600496 = formData.getOrDefault("SkipFinalSnapshot")
  valid_600496 = validateParameter(valid_600496, JBool, required = false, default = nil)
  if valid_600496 != nil:
    section.add "SkipFinalSnapshot", valid_600496
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600497: Call_PostDeleteDBInstance_600482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600497.validator(path, query, header, formData, body)
  let scheme = call_600497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600497.url(scheme.get, call_600497.host, call_600497.base,
                         call_600497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600497, url, valid)

proc call*(call_600498: Call_PostDeleteDBInstance_600482;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_600499 = newJObject()
  var formData_600500 = newJObject()
  add(formData_600500, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600500, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600499, "Action", newJString(Action))
  add(query_600499, "Version", newJString(Version))
  add(formData_600500, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_600498.call(nil, query_600499, nil, formData_600500, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_600482(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_600483, base: "/",
    url: url_PostDeleteDBInstance_600484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_600464 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBInstance_600466(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_600465(path: JsonNode; query: JsonNode;
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
  var valid_600467 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600467
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600468 = query.getOrDefault("Action")
  valid_600468 = validateParameter(valid_600468, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600468 != nil:
    section.add "Action", valid_600468
  var valid_600469 = query.getOrDefault("SkipFinalSnapshot")
  valid_600469 = validateParameter(valid_600469, JBool, required = false, default = nil)
  if valid_600469 != nil:
    section.add "SkipFinalSnapshot", valid_600469
  var valid_600470 = query.getOrDefault("Version")
  valid_600470 = validateParameter(valid_600470, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600470 != nil:
    section.add "Version", valid_600470
  var valid_600471 = query.getOrDefault("DBInstanceIdentifier")
  valid_600471 = validateParameter(valid_600471, JString, required = true,
                                 default = nil)
  if valid_600471 != nil:
    section.add "DBInstanceIdentifier", valid_600471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600472 = header.getOrDefault("X-Amz-Date")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Date", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Security-Token")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Security-Token", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Content-Sha256", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Algorithm")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Algorithm", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-Signature")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-Signature", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-SignedHeaders", valid_600477
  var valid_600478 = header.getOrDefault("X-Amz-Credential")
  valid_600478 = validateParameter(valid_600478, JString, required = false,
                                 default = nil)
  if valid_600478 != nil:
    section.add "X-Amz-Credential", valid_600478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600479: Call_GetDeleteDBInstance_600464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600479.validator(path, query, header, formData, body)
  let scheme = call_600479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600479.url(scheme.get, call_600479.host, call_600479.base,
                         call_600479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600479, url, valid)

proc call*(call_600480: Call_GetDeleteDBInstance_600464;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_600481 = newJObject()
  add(query_600481, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600481, "Action", newJString(Action))
  add(query_600481, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_600481, "Version", newJString(Version))
  add(query_600481, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600480.call(nil, query_600481, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_600464(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_600465, base: "/",
    url: url_GetDeleteDBInstance_600466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_600517 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBParameterGroup_600519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_600518(path: JsonNode; query: JsonNode;
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
  var valid_600520 = query.getOrDefault("Action")
  valid_600520 = validateParameter(valid_600520, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_600520 != nil:
    section.add "Action", valid_600520
  var valid_600521 = query.getOrDefault("Version")
  valid_600521 = validateParameter(valid_600521, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600521 != nil:
    section.add "Version", valid_600521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600522 = header.getOrDefault("X-Amz-Date")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Date", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Security-Token")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Security-Token", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Content-Sha256", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-Algorithm")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-Algorithm", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Signature")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Signature", valid_600526
  var valid_600527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "X-Amz-SignedHeaders", valid_600527
  var valid_600528 = header.getOrDefault("X-Amz-Credential")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "X-Amz-Credential", valid_600528
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600529 = formData.getOrDefault("DBParameterGroupName")
  valid_600529 = validateParameter(valid_600529, JString, required = true,
                                 default = nil)
  if valid_600529 != nil:
    section.add "DBParameterGroupName", valid_600529
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600530: Call_PostDeleteDBParameterGroup_600517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600530.validator(path, query, header, formData, body)
  let scheme = call_600530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600530.url(scheme.get, call_600530.host, call_600530.base,
                         call_600530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600530, url, valid)

proc call*(call_600531: Call_PostDeleteDBParameterGroup_600517;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600532 = newJObject()
  var formData_600533 = newJObject()
  add(formData_600533, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600532, "Action", newJString(Action))
  add(query_600532, "Version", newJString(Version))
  result = call_600531.call(nil, query_600532, nil, formData_600533, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_600517(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_600518, base: "/",
    url: url_PostDeleteDBParameterGroup_600519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_600501 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBParameterGroup_600503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_600502(path: JsonNode; query: JsonNode;
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
  var valid_600504 = query.getOrDefault("DBParameterGroupName")
  valid_600504 = validateParameter(valid_600504, JString, required = true,
                                 default = nil)
  if valid_600504 != nil:
    section.add "DBParameterGroupName", valid_600504
  var valid_600505 = query.getOrDefault("Action")
  valid_600505 = validateParameter(valid_600505, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_600505 != nil:
    section.add "Action", valid_600505
  var valid_600506 = query.getOrDefault("Version")
  valid_600506 = validateParameter(valid_600506, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600506 != nil:
    section.add "Version", valid_600506
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600507 = header.getOrDefault("X-Amz-Date")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-Date", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Security-Token")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Security-Token", valid_600508
  var valid_600509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "X-Amz-Content-Sha256", valid_600509
  var valid_600510 = header.getOrDefault("X-Amz-Algorithm")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "X-Amz-Algorithm", valid_600510
  var valid_600511 = header.getOrDefault("X-Amz-Signature")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "X-Amz-Signature", valid_600511
  var valid_600512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "X-Amz-SignedHeaders", valid_600512
  var valid_600513 = header.getOrDefault("X-Amz-Credential")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Credential", valid_600513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600514: Call_GetDeleteDBParameterGroup_600501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600514.validator(path, query, header, formData, body)
  let scheme = call_600514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600514.url(scheme.get, call_600514.host, call_600514.base,
                         call_600514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600514, url, valid)

proc call*(call_600515: Call_GetDeleteDBParameterGroup_600501;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600516 = newJObject()
  add(query_600516, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600516, "Action", newJString(Action))
  add(query_600516, "Version", newJString(Version))
  result = call_600515.call(nil, query_600516, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_600501(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_600502, base: "/",
    url: url_GetDeleteDBParameterGroup_600503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_600550 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSecurityGroup_600552(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_600551(path: JsonNode; query: JsonNode;
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
  var valid_600553 = query.getOrDefault("Action")
  valid_600553 = validateParameter(valid_600553, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_600553 != nil:
    section.add "Action", valid_600553
  var valid_600554 = query.getOrDefault("Version")
  valid_600554 = validateParameter(valid_600554, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600554 != nil:
    section.add "Version", valid_600554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600555 = header.getOrDefault("X-Amz-Date")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Date", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Security-Token")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Security-Token", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Content-Sha256", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Algorithm")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Algorithm", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Signature")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Signature", valid_600559
  var valid_600560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600560 = validateParameter(valid_600560, JString, required = false,
                                 default = nil)
  if valid_600560 != nil:
    section.add "X-Amz-SignedHeaders", valid_600560
  var valid_600561 = header.getOrDefault("X-Amz-Credential")
  valid_600561 = validateParameter(valid_600561, JString, required = false,
                                 default = nil)
  if valid_600561 != nil:
    section.add "X-Amz-Credential", valid_600561
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600562 = formData.getOrDefault("DBSecurityGroupName")
  valid_600562 = validateParameter(valid_600562, JString, required = true,
                                 default = nil)
  if valid_600562 != nil:
    section.add "DBSecurityGroupName", valid_600562
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600563: Call_PostDeleteDBSecurityGroup_600550; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600563.validator(path, query, header, formData, body)
  let scheme = call_600563.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600563.url(scheme.get, call_600563.host, call_600563.base,
                         call_600563.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600563, url, valid)

proc call*(call_600564: Call_PostDeleteDBSecurityGroup_600550;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600565 = newJObject()
  var formData_600566 = newJObject()
  add(formData_600566, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600565, "Action", newJString(Action))
  add(query_600565, "Version", newJString(Version))
  result = call_600564.call(nil, query_600565, nil, formData_600566, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_600550(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_600551, base: "/",
    url: url_PostDeleteDBSecurityGroup_600552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_600534 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSecurityGroup_600536(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_600535(path: JsonNode; query: JsonNode;
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
  var valid_600537 = query.getOrDefault("DBSecurityGroupName")
  valid_600537 = validateParameter(valid_600537, JString, required = true,
                                 default = nil)
  if valid_600537 != nil:
    section.add "DBSecurityGroupName", valid_600537
  var valid_600538 = query.getOrDefault("Action")
  valid_600538 = validateParameter(valid_600538, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_600538 != nil:
    section.add "Action", valid_600538
  var valid_600539 = query.getOrDefault("Version")
  valid_600539 = validateParameter(valid_600539, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600539 != nil:
    section.add "Version", valid_600539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600540 = header.getOrDefault("X-Amz-Date")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Date", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Security-Token")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Security-Token", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Content-Sha256", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-Algorithm")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-Algorithm", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Signature")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Signature", valid_600544
  var valid_600545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600545 = validateParameter(valid_600545, JString, required = false,
                                 default = nil)
  if valid_600545 != nil:
    section.add "X-Amz-SignedHeaders", valid_600545
  var valid_600546 = header.getOrDefault("X-Amz-Credential")
  valid_600546 = validateParameter(valid_600546, JString, required = false,
                                 default = nil)
  if valid_600546 != nil:
    section.add "X-Amz-Credential", valid_600546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600547: Call_GetDeleteDBSecurityGroup_600534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600547.validator(path, query, header, formData, body)
  let scheme = call_600547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600547.url(scheme.get, call_600547.host, call_600547.base,
                         call_600547.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600547, url, valid)

proc call*(call_600548: Call_GetDeleteDBSecurityGroup_600534;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600549 = newJObject()
  add(query_600549, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600549, "Action", newJString(Action))
  add(query_600549, "Version", newJString(Version))
  result = call_600548.call(nil, query_600549, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_600534(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_600535, base: "/",
    url: url_GetDeleteDBSecurityGroup_600536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_600583 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSnapshot_600585(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_600584(path: JsonNode; query: JsonNode;
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
  var valid_600586 = query.getOrDefault("Action")
  valid_600586 = validateParameter(valid_600586, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_600586 != nil:
    section.add "Action", valid_600586
  var valid_600587 = query.getOrDefault("Version")
  valid_600587 = validateParameter(valid_600587, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600587 != nil:
    section.add "Version", valid_600587
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600588 = header.getOrDefault("X-Amz-Date")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Date", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Security-Token")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Security-Token", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Content-Sha256", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-Algorithm")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-Algorithm", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Signature")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Signature", valid_600592
  var valid_600593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600593 = validateParameter(valid_600593, JString, required = false,
                                 default = nil)
  if valid_600593 != nil:
    section.add "X-Amz-SignedHeaders", valid_600593
  var valid_600594 = header.getOrDefault("X-Amz-Credential")
  valid_600594 = validateParameter(valid_600594, JString, required = false,
                                 default = nil)
  if valid_600594 != nil:
    section.add "X-Amz-Credential", valid_600594
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_600595 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600595 = validateParameter(valid_600595, JString, required = true,
                                 default = nil)
  if valid_600595 != nil:
    section.add "DBSnapshotIdentifier", valid_600595
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600596: Call_PostDeleteDBSnapshot_600583; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600596.validator(path, query, header, formData, body)
  let scheme = call_600596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600596.url(scheme.get, call_600596.host, call_600596.base,
                         call_600596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600596, url, valid)

proc call*(call_600597: Call_PostDeleteDBSnapshot_600583;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600598 = newJObject()
  var formData_600599 = newJObject()
  add(formData_600599, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600598, "Action", newJString(Action))
  add(query_600598, "Version", newJString(Version))
  result = call_600597.call(nil, query_600598, nil, formData_600599, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_600583(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_600584, base: "/",
    url: url_PostDeleteDBSnapshot_600585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_600567 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSnapshot_600569(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_600568(path: JsonNode; query: JsonNode;
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
  var valid_600570 = query.getOrDefault("Action")
  valid_600570 = validateParameter(valid_600570, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_600570 != nil:
    section.add "Action", valid_600570
  var valid_600571 = query.getOrDefault("Version")
  valid_600571 = validateParameter(valid_600571, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600571 != nil:
    section.add "Version", valid_600571
  var valid_600572 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600572 = validateParameter(valid_600572, JString, required = true,
                                 default = nil)
  if valid_600572 != nil:
    section.add "DBSnapshotIdentifier", valid_600572
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600580: Call_GetDeleteDBSnapshot_600567; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600580.validator(path, query, header, formData, body)
  let scheme = call_600580.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600580.url(scheme.get, call_600580.host, call_600580.base,
                         call_600580.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600580, url, valid)

proc call*(call_600581: Call_GetDeleteDBSnapshot_600567;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_600582 = newJObject()
  add(query_600582, "Action", newJString(Action))
  add(query_600582, "Version", newJString(Version))
  add(query_600582, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600581.call(nil, query_600582, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_600567(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_600568, base: "/",
    url: url_GetDeleteDBSnapshot_600569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_600616 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSubnetGroup_600618(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_600617(path: JsonNode; query: JsonNode;
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
  var valid_600619 = query.getOrDefault("Action")
  valid_600619 = validateParameter(valid_600619, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600619 != nil:
    section.add "Action", valid_600619
  var valid_600620 = query.getOrDefault("Version")
  valid_600620 = validateParameter(valid_600620, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600620 != nil:
    section.add "Version", valid_600620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600621 = header.getOrDefault("X-Amz-Date")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Date", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Security-Token")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Security-Token", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Content-Sha256", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-Algorithm")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Algorithm", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Signature")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Signature", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-SignedHeaders", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Credential")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Credential", valid_600627
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600628 = formData.getOrDefault("DBSubnetGroupName")
  valid_600628 = validateParameter(valid_600628, JString, required = true,
                                 default = nil)
  if valid_600628 != nil:
    section.add "DBSubnetGroupName", valid_600628
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600629: Call_PostDeleteDBSubnetGroup_600616; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600629.validator(path, query, header, formData, body)
  let scheme = call_600629.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600629.url(scheme.get, call_600629.host, call_600629.base,
                         call_600629.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600629, url, valid)

proc call*(call_600630: Call_PostDeleteDBSubnetGroup_600616;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600631 = newJObject()
  var formData_600632 = newJObject()
  add(formData_600632, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600631, "Action", newJString(Action))
  add(query_600631, "Version", newJString(Version))
  result = call_600630.call(nil, query_600631, nil, formData_600632, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_600616(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_600617, base: "/",
    url: url_PostDeleteDBSubnetGroup_600618, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_600600 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSubnetGroup_600602(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_600601(path: JsonNode; query: JsonNode;
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
  var valid_600603 = query.getOrDefault("Action")
  valid_600603 = validateParameter(valid_600603, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600603 != nil:
    section.add "Action", valid_600603
  var valid_600604 = query.getOrDefault("DBSubnetGroupName")
  valid_600604 = validateParameter(valid_600604, JString, required = true,
                                 default = nil)
  if valid_600604 != nil:
    section.add "DBSubnetGroupName", valid_600604
  var valid_600605 = query.getOrDefault("Version")
  valid_600605 = validateParameter(valid_600605, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600605 != nil:
    section.add "Version", valid_600605
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600606 = header.getOrDefault("X-Amz-Date")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-Date", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Security-Token")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Security-Token", valid_600607
  var valid_600608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600608 = validateParameter(valid_600608, JString, required = false,
                                 default = nil)
  if valid_600608 != nil:
    section.add "X-Amz-Content-Sha256", valid_600608
  var valid_600609 = header.getOrDefault("X-Amz-Algorithm")
  valid_600609 = validateParameter(valid_600609, JString, required = false,
                                 default = nil)
  if valid_600609 != nil:
    section.add "X-Amz-Algorithm", valid_600609
  var valid_600610 = header.getOrDefault("X-Amz-Signature")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Signature", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-SignedHeaders", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Credential")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Credential", valid_600612
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600613: Call_GetDeleteDBSubnetGroup_600600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600613.validator(path, query, header, formData, body)
  let scheme = call_600613.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600613.url(scheme.get, call_600613.host, call_600613.base,
                         call_600613.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600613, url, valid)

proc call*(call_600614: Call_GetDeleteDBSubnetGroup_600600;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_600615 = newJObject()
  add(query_600615, "Action", newJString(Action))
  add(query_600615, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600615, "Version", newJString(Version))
  result = call_600614.call(nil, query_600615, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_600600(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_600601, base: "/",
    url: url_GetDeleteDBSubnetGroup_600602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_600649 = ref object of OpenApiRestCall_599352
proc url_PostDeleteEventSubscription_600651(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_600650(path: JsonNode; query: JsonNode;
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
  var valid_600652 = query.getOrDefault("Action")
  valid_600652 = validateParameter(valid_600652, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_600652 != nil:
    section.add "Action", valid_600652
  var valid_600653 = query.getOrDefault("Version")
  valid_600653 = validateParameter(valid_600653, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600653 != nil:
    section.add "Version", valid_600653
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600654 = header.getOrDefault("X-Amz-Date")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Date", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Security-Token")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Security-Token", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Content-Sha256", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-Algorithm")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-Algorithm", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-Signature")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-Signature", valid_600658
  var valid_600659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600659 = validateParameter(valid_600659, JString, required = false,
                                 default = nil)
  if valid_600659 != nil:
    section.add "X-Amz-SignedHeaders", valid_600659
  var valid_600660 = header.getOrDefault("X-Amz-Credential")
  valid_600660 = validateParameter(valid_600660, JString, required = false,
                                 default = nil)
  if valid_600660 != nil:
    section.add "X-Amz-Credential", valid_600660
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_600661 = formData.getOrDefault("SubscriptionName")
  valid_600661 = validateParameter(valid_600661, JString, required = true,
                                 default = nil)
  if valid_600661 != nil:
    section.add "SubscriptionName", valid_600661
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600662: Call_PostDeleteEventSubscription_600649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600662.validator(path, query, header, formData, body)
  let scheme = call_600662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600662.url(scheme.get, call_600662.host, call_600662.base,
                         call_600662.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600662, url, valid)

proc call*(call_600663: Call_PostDeleteEventSubscription_600649;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600664 = newJObject()
  var formData_600665 = newJObject()
  add(formData_600665, "SubscriptionName", newJString(SubscriptionName))
  add(query_600664, "Action", newJString(Action))
  add(query_600664, "Version", newJString(Version))
  result = call_600663.call(nil, query_600664, nil, formData_600665, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_600649(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_600650, base: "/",
    url: url_PostDeleteEventSubscription_600651,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_600633 = ref object of OpenApiRestCall_599352
proc url_GetDeleteEventSubscription_600635(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_600634(path: JsonNode; query: JsonNode;
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
  var valid_600636 = query.getOrDefault("Action")
  valid_600636 = validateParameter(valid_600636, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_600636 != nil:
    section.add "Action", valid_600636
  var valid_600637 = query.getOrDefault("SubscriptionName")
  valid_600637 = validateParameter(valid_600637, JString, required = true,
                                 default = nil)
  if valid_600637 != nil:
    section.add "SubscriptionName", valid_600637
  var valid_600638 = query.getOrDefault("Version")
  valid_600638 = validateParameter(valid_600638, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600638 != nil:
    section.add "Version", valid_600638
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600639 = header.getOrDefault("X-Amz-Date")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-Date", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Security-Token")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Security-Token", valid_600640
  var valid_600641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600641 = validateParameter(valid_600641, JString, required = false,
                                 default = nil)
  if valid_600641 != nil:
    section.add "X-Amz-Content-Sha256", valid_600641
  var valid_600642 = header.getOrDefault("X-Amz-Algorithm")
  valid_600642 = validateParameter(valid_600642, JString, required = false,
                                 default = nil)
  if valid_600642 != nil:
    section.add "X-Amz-Algorithm", valid_600642
  var valid_600643 = header.getOrDefault("X-Amz-Signature")
  valid_600643 = validateParameter(valid_600643, JString, required = false,
                                 default = nil)
  if valid_600643 != nil:
    section.add "X-Amz-Signature", valid_600643
  var valid_600644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600644 = validateParameter(valid_600644, JString, required = false,
                                 default = nil)
  if valid_600644 != nil:
    section.add "X-Amz-SignedHeaders", valid_600644
  var valid_600645 = header.getOrDefault("X-Amz-Credential")
  valid_600645 = validateParameter(valid_600645, JString, required = false,
                                 default = nil)
  if valid_600645 != nil:
    section.add "X-Amz-Credential", valid_600645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600646: Call_GetDeleteEventSubscription_600633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600646.validator(path, query, header, formData, body)
  let scheme = call_600646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600646.url(scheme.get, call_600646.host, call_600646.base,
                         call_600646.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600646, url, valid)

proc call*(call_600647: Call_GetDeleteEventSubscription_600633;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_600648 = newJObject()
  add(query_600648, "Action", newJString(Action))
  add(query_600648, "SubscriptionName", newJString(SubscriptionName))
  add(query_600648, "Version", newJString(Version))
  result = call_600647.call(nil, query_600648, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_600633(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_600634, base: "/",
    url: url_GetDeleteEventSubscription_600635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_600682 = ref object of OpenApiRestCall_599352
proc url_PostDeleteOptionGroup_600684(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_600683(path: JsonNode; query: JsonNode;
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
  var valid_600685 = query.getOrDefault("Action")
  valid_600685 = validateParameter(valid_600685, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_600685 != nil:
    section.add "Action", valid_600685
  var valid_600686 = query.getOrDefault("Version")
  valid_600686 = validateParameter(valid_600686, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600686 != nil:
    section.add "Version", valid_600686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600687 = header.getOrDefault("X-Amz-Date")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "X-Amz-Date", valid_600687
  var valid_600688 = header.getOrDefault("X-Amz-Security-Token")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "X-Amz-Security-Token", valid_600688
  var valid_600689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600689 = validateParameter(valid_600689, JString, required = false,
                                 default = nil)
  if valid_600689 != nil:
    section.add "X-Amz-Content-Sha256", valid_600689
  var valid_600690 = header.getOrDefault("X-Amz-Algorithm")
  valid_600690 = validateParameter(valid_600690, JString, required = false,
                                 default = nil)
  if valid_600690 != nil:
    section.add "X-Amz-Algorithm", valid_600690
  var valid_600691 = header.getOrDefault("X-Amz-Signature")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Signature", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-SignedHeaders", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Credential")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Credential", valid_600693
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_600694 = formData.getOrDefault("OptionGroupName")
  valid_600694 = validateParameter(valid_600694, JString, required = true,
                                 default = nil)
  if valid_600694 != nil:
    section.add "OptionGroupName", valid_600694
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600695: Call_PostDeleteOptionGroup_600682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600695.validator(path, query, header, formData, body)
  let scheme = call_600695.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600695.url(scheme.get, call_600695.host, call_600695.base,
                         call_600695.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600695, url, valid)

proc call*(call_600696: Call_PostDeleteOptionGroup_600682; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600697 = newJObject()
  var formData_600698 = newJObject()
  add(formData_600698, "OptionGroupName", newJString(OptionGroupName))
  add(query_600697, "Action", newJString(Action))
  add(query_600697, "Version", newJString(Version))
  result = call_600696.call(nil, query_600697, nil, formData_600698, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_600682(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_600683, base: "/",
    url: url_PostDeleteOptionGroup_600684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_600666 = ref object of OpenApiRestCall_599352
proc url_GetDeleteOptionGroup_600668(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_600667(path: JsonNode; query: JsonNode;
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
  var valid_600669 = query.getOrDefault("OptionGroupName")
  valid_600669 = validateParameter(valid_600669, JString, required = true,
                                 default = nil)
  if valid_600669 != nil:
    section.add "OptionGroupName", valid_600669
  var valid_600670 = query.getOrDefault("Action")
  valid_600670 = validateParameter(valid_600670, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_600670 != nil:
    section.add "Action", valid_600670
  var valid_600671 = query.getOrDefault("Version")
  valid_600671 = validateParameter(valid_600671, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600671 != nil:
    section.add "Version", valid_600671
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600672 = header.getOrDefault("X-Amz-Date")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-Date", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-Security-Token")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-Security-Token", valid_600673
  var valid_600674 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600674 = validateParameter(valid_600674, JString, required = false,
                                 default = nil)
  if valid_600674 != nil:
    section.add "X-Amz-Content-Sha256", valid_600674
  var valid_600675 = header.getOrDefault("X-Amz-Algorithm")
  valid_600675 = validateParameter(valid_600675, JString, required = false,
                                 default = nil)
  if valid_600675 != nil:
    section.add "X-Amz-Algorithm", valid_600675
  var valid_600676 = header.getOrDefault("X-Amz-Signature")
  valid_600676 = validateParameter(valid_600676, JString, required = false,
                                 default = nil)
  if valid_600676 != nil:
    section.add "X-Amz-Signature", valid_600676
  var valid_600677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600677 = validateParameter(valid_600677, JString, required = false,
                                 default = nil)
  if valid_600677 != nil:
    section.add "X-Amz-SignedHeaders", valid_600677
  var valid_600678 = header.getOrDefault("X-Amz-Credential")
  valid_600678 = validateParameter(valid_600678, JString, required = false,
                                 default = nil)
  if valid_600678 != nil:
    section.add "X-Amz-Credential", valid_600678
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600679: Call_GetDeleteOptionGroup_600666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600679.validator(path, query, header, formData, body)
  let scheme = call_600679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600679.url(scheme.get, call_600679.host, call_600679.base,
                         call_600679.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600679, url, valid)

proc call*(call_600680: Call_GetDeleteOptionGroup_600666; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600681 = newJObject()
  add(query_600681, "OptionGroupName", newJString(OptionGroupName))
  add(query_600681, "Action", newJString(Action))
  add(query_600681, "Version", newJString(Version))
  result = call_600680.call(nil, query_600681, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_600666(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_600667, base: "/",
    url: url_GetDeleteOptionGroup_600668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_600722 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBEngineVersions_600724(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_600723(path: JsonNode; query: JsonNode;
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
  var valid_600725 = query.getOrDefault("Action")
  valid_600725 = validateParameter(valid_600725, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600725 != nil:
    section.add "Action", valid_600725
  var valid_600726 = query.getOrDefault("Version")
  valid_600726 = validateParameter(valid_600726, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600726 != nil:
    section.add "Version", valid_600726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600727 = header.getOrDefault("X-Amz-Date")
  valid_600727 = validateParameter(valid_600727, JString, required = false,
                                 default = nil)
  if valid_600727 != nil:
    section.add "X-Amz-Date", valid_600727
  var valid_600728 = header.getOrDefault("X-Amz-Security-Token")
  valid_600728 = validateParameter(valid_600728, JString, required = false,
                                 default = nil)
  if valid_600728 != nil:
    section.add "X-Amz-Security-Token", valid_600728
  var valid_600729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "X-Amz-Content-Sha256", valid_600729
  var valid_600730 = header.getOrDefault("X-Amz-Algorithm")
  valid_600730 = validateParameter(valid_600730, JString, required = false,
                                 default = nil)
  if valid_600730 != nil:
    section.add "X-Amz-Algorithm", valid_600730
  var valid_600731 = header.getOrDefault("X-Amz-Signature")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "X-Amz-Signature", valid_600731
  var valid_600732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-SignedHeaders", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-Credential")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Credential", valid_600733
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
  var valid_600734 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_600734 = validateParameter(valid_600734, JBool, required = false, default = nil)
  if valid_600734 != nil:
    section.add "ListSupportedCharacterSets", valid_600734
  var valid_600735 = formData.getOrDefault("Engine")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "Engine", valid_600735
  var valid_600736 = formData.getOrDefault("Marker")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "Marker", valid_600736
  var valid_600737 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "DBParameterGroupFamily", valid_600737
  var valid_600738 = formData.getOrDefault("Filters")
  valid_600738 = validateParameter(valid_600738, JArray, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "Filters", valid_600738
  var valid_600739 = formData.getOrDefault("MaxRecords")
  valid_600739 = validateParameter(valid_600739, JInt, required = false, default = nil)
  if valid_600739 != nil:
    section.add "MaxRecords", valid_600739
  var valid_600740 = formData.getOrDefault("EngineVersion")
  valid_600740 = validateParameter(valid_600740, JString, required = false,
                                 default = nil)
  if valid_600740 != nil:
    section.add "EngineVersion", valid_600740
  var valid_600741 = formData.getOrDefault("DefaultOnly")
  valid_600741 = validateParameter(valid_600741, JBool, required = false, default = nil)
  if valid_600741 != nil:
    section.add "DefaultOnly", valid_600741
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600742: Call_PostDescribeDBEngineVersions_600722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600742.validator(path, query, header, formData, body)
  let scheme = call_600742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600742.url(scheme.get, call_600742.host, call_600742.base,
                         call_600742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600742, url, valid)

proc call*(call_600743: Call_PostDescribeDBEngineVersions_600722;
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
  var query_600744 = newJObject()
  var formData_600745 = newJObject()
  add(formData_600745, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_600745, "Engine", newJString(Engine))
  add(formData_600745, "Marker", newJString(Marker))
  add(query_600744, "Action", newJString(Action))
  add(formData_600745, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_600745.add "Filters", Filters
  add(formData_600745, "MaxRecords", newJInt(MaxRecords))
  add(formData_600745, "EngineVersion", newJString(EngineVersion))
  add(query_600744, "Version", newJString(Version))
  add(formData_600745, "DefaultOnly", newJBool(DefaultOnly))
  result = call_600743.call(nil, query_600744, nil, formData_600745, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_600722(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_600723, base: "/",
    url: url_PostDescribeDBEngineVersions_600724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_600699 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBEngineVersions_600701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_600700(path: JsonNode; query: JsonNode;
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
  var valid_600702 = query.getOrDefault("Engine")
  valid_600702 = validateParameter(valid_600702, JString, required = false,
                                 default = nil)
  if valid_600702 != nil:
    section.add "Engine", valid_600702
  var valid_600703 = query.getOrDefault("ListSupportedCharacterSets")
  valid_600703 = validateParameter(valid_600703, JBool, required = false, default = nil)
  if valid_600703 != nil:
    section.add "ListSupportedCharacterSets", valid_600703
  var valid_600704 = query.getOrDefault("MaxRecords")
  valid_600704 = validateParameter(valid_600704, JInt, required = false, default = nil)
  if valid_600704 != nil:
    section.add "MaxRecords", valid_600704
  var valid_600705 = query.getOrDefault("DBParameterGroupFamily")
  valid_600705 = validateParameter(valid_600705, JString, required = false,
                                 default = nil)
  if valid_600705 != nil:
    section.add "DBParameterGroupFamily", valid_600705
  var valid_600706 = query.getOrDefault("Filters")
  valid_600706 = validateParameter(valid_600706, JArray, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "Filters", valid_600706
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600707 = query.getOrDefault("Action")
  valid_600707 = validateParameter(valid_600707, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600707 != nil:
    section.add "Action", valid_600707
  var valid_600708 = query.getOrDefault("Marker")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "Marker", valid_600708
  var valid_600709 = query.getOrDefault("EngineVersion")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "EngineVersion", valid_600709
  var valid_600710 = query.getOrDefault("DefaultOnly")
  valid_600710 = validateParameter(valid_600710, JBool, required = false, default = nil)
  if valid_600710 != nil:
    section.add "DefaultOnly", valid_600710
  var valid_600711 = query.getOrDefault("Version")
  valid_600711 = validateParameter(valid_600711, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600711 != nil:
    section.add "Version", valid_600711
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600712 = header.getOrDefault("X-Amz-Date")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Date", valid_600712
  var valid_600713 = header.getOrDefault("X-Amz-Security-Token")
  valid_600713 = validateParameter(valid_600713, JString, required = false,
                                 default = nil)
  if valid_600713 != nil:
    section.add "X-Amz-Security-Token", valid_600713
  var valid_600714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "X-Amz-Content-Sha256", valid_600714
  var valid_600715 = header.getOrDefault("X-Amz-Algorithm")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "X-Amz-Algorithm", valid_600715
  var valid_600716 = header.getOrDefault("X-Amz-Signature")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "X-Amz-Signature", valid_600716
  var valid_600717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600717 = validateParameter(valid_600717, JString, required = false,
                                 default = nil)
  if valid_600717 != nil:
    section.add "X-Amz-SignedHeaders", valid_600717
  var valid_600718 = header.getOrDefault("X-Amz-Credential")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "X-Amz-Credential", valid_600718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600719: Call_GetDescribeDBEngineVersions_600699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600719.validator(path, query, header, formData, body)
  let scheme = call_600719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600719.url(scheme.get, call_600719.host, call_600719.base,
                         call_600719.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600719, url, valid)

proc call*(call_600720: Call_GetDescribeDBEngineVersions_600699;
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
  var query_600721 = newJObject()
  add(query_600721, "Engine", newJString(Engine))
  add(query_600721, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_600721, "MaxRecords", newJInt(MaxRecords))
  add(query_600721, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_600721.add "Filters", Filters
  add(query_600721, "Action", newJString(Action))
  add(query_600721, "Marker", newJString(Marker))
  add(query_600721, "EngineVersion", newJString(EngineVersion))
  add(query_600721, "DefaultOnly", newJBool(DefaultOnly))
  add(query_600721, "Version", newJString(Version))
  result = call_600720.call(nil, query_600721, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_600699(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_600700, base: "/",
    url: url_GetDescribeDBEngineVersions_600701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_600765 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBInstances_600767(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_600766(path: JsonNode; query: JsonNode;
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
  var valid_600768 = query.getOrDefault("Action")
  valid_600768 = validateParameter(valid_600768, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600768 != nil:
    section.add "Action", valid_600768
  var valid_600769 = query.getOrDefault("Version")
  valid_600769 = validateParameter(valid_600769, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600769 != nil:
    section.add "Version", valid_600769
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600770 = header.getOrDefault("X-Amz-Date")
  valid_600770 = validateParameter(valid_600770, JString, required = false,
                                 default = nil)
  if valid_600770 != nil:
    section.add "X-Amz-Date", valid_600770
  var valid_600771 = header.getOrDefault("X-Amz-Security-Token")
  valid_600771 = validateParameter(valid_600771, JString, required = false,
                                 default = nil)
  if valid_600771 != nil:
    section.add "X-Amz-Security-Token", valid_600771
  var valid_600772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Content-Sha256", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Algorithm")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Algorithm", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-Signature")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-Signature", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-SignedHeaders", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Credential")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Credential", valid_600776
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600777 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "DBInstanceIdentifier", valid_600777
  var valid_600778 = formData.getOrDefault("Marker")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "Marker", valid_600778
  var valid_600779 = formData.getOrDefault("Filters")
  valid_600779 = validateParameter(valid_600779, JArray, required = false,
                                 default = nil)
  if valid_600779 != nil:
    section.add "Filters", valid_600779
  var valid_600780 = formData.getOrDefault("MaxRecords")
  valid_600780 = validateParameter(valid_600780, JInt, required = false, default = nil)
  if valid_600780 != nil:
    section.add "MaxRecords", valid_600780
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600781: Call_PostDescribeDBInstances_600765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600781.validator(path, query, header, formData, body)
  let scheme = call_600781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600781.url(scheme.get, call_600781.host, call_600781.base,
                         call_600781.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600781, url, valid)

proc call*(call_600782: Call_PostDescribeDBInstances_600765;
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
  var query_600783 = newJObject()
  var formData_600784 = newJObject()
  add(formData_600784, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600784, "Marker", newJString(Marker))
  add(query_600783, "Action", newJString(Action))
  if Filters != nil:
    formData_600784.add "Filters", Filters
  add(formData_600784, "MaxRecords", newJInt(MaxRecords))
  add(query_600783, "Version", newJString(Version))
  result = call_600782.call(nil, query_600783, nil, formData_600784, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_600765(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_600766, base: "/",
    url: url_PostDescribeDBInstances_600767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_600746 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBInstances_600748(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_600747(path: JsonNode; query: JsonNode;
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
  var valid_600749 = query.getOrDefault("MaxRecords")
  valid_600749 = validateParameter(valid_600749, JInt, required = false, default = nil)
  if valid_600749 != nil:
    section.add "MaxRecords", valid_600749
  var valid_600750 = query.getOrDefault("Filters")
  valid_600750 = validateParameter(valid_600750, JArray, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "Filters", valid_600750
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600751 = query.getOrDefault("Action")
  valid_600751 = validateParameter(valid_600751, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600751 != nil:
    section.add "Action", valid_600751
  var valid_600752 = query.getOrDefault("Marker")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "Marker", valid_600752
  var valid_600753 = query.getOrDefault("Version")
  valid_600753 = validateParameter(valid_600753, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600753 != nil:
    section.add "Version", valid_600753
  var valid_600754 = query.getOrDefault("DBInstanceIdentifier")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "DBInstanceIdentifier", valid_600754
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600755 = header.getOrDefault("X-Amz-Date")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "X-Amz-Date", valid_600755
  var valid_600756 = header.getOrDefault("X-Amz-Security-Token")
  valid_600756 = validateParameter(valid_600756, JString, required = false,
                                 default = nil)
  if valid_600756 != nil:
    section.add "X-Amz-Security-Token", valid_600756
  var valid_600757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600757 = validateParameter(valid_600757, JString, required = false,
                                 default = nil)
  if valid_600757 != nil:
    section.add "X-Amz-Content-Sha256", valid_600757
  var valid_600758 = header.getOrDefault("X-Amz-Algorithm")
  valid_600758 = validateParameter(valid_600758, JString, required = false,
                                 default = nil)
  if valid_600758 != nil:
    section.add "X-Amz-Algorithm", valid_600758
  var valid_600759 = header.getOrDefault("X-Amz-Signature")
  valid_600759 = validateParameter(valid_600759, JString, required = false,
                                 default = nil)
  if valid_600759 != nil:
    section.add "X-Amz-Signature", valid_600759
  var valid_600760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600760 = validateParameter(valid_600760, JString, required = false,
                                 default = nil)
  if valid_600760 != nil:
    section.add "X-Amz-SignedHeaders", valid_600760
  var valid_600761 = header.getOrDefault("X-Amz-Credential")
  valid_600761 = validateParameter(valid_600761, JString, required = false,
                                 default = nil)
  if valid_600761 != nil:
    section.add "X-Amz-Credential", valid_600761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600762: Call_GetDescribeDBInstances_600746; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600762.validator(path, query, header, formData, body)
  let scheme = call_600762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600762.url(scheme.get, call_600762.host, call_600762.base,
                         call_600762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600762, url, valid)

proc call*(call_600763: Call_GetDescribeDBInstances_600746; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBInstances";
          Marker: string = ""; Version: string = "2013-09-09";
          DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_600764 = newJObject()
  add(query_600764, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600764.add "Filters", Filters
  add(query_600764, "Action", newJString(Action))
  add(query_600764, "Marker", newJString(Marker))
  add(query_600764, "Version", newJString(Version))
  add(query_600764, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600763.call(nil, query_600764, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_600746(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_600747, base: "/",
    url: url_GetDescribeDBInstances_600748, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_600807 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBLogFiles_600809(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_600808(path: JsonNode; query: JsonNode;
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
  var valid_600810 = query.getOrDefault("Action")
  valid_600810 = validateParameter(valid_600810, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_600810 != nil:
    section.add "Action", valid_600810
  var valid_600811 = query.getOrDefault("Version")
  valid_600811 = validateParameter(valid_600811, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600811 != nil:
    section.add "Version", valid_600811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600812 = header.getOrDefault("X-Amz-Date")
  valid_600812 = validateParameter(valid_600812, JString, required = false,
                                 default = nil)
  if valid_600812 != nil:
    section.add "X-Amz-Date", valid_600812
  var valid_600813 = header.getOrDefault("X-Amz-Security-Token")
  valid_600813 = validateParameter(valid_600813, JString, required = false,
                                 default = nil)
  if valid_600813 != nil:
    section.add "X-Amz-Security-Token", valid_600813
  var valid_600814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600814 = validateParameter(valid_600814, JString, required = false,
                                 default = nil)
  if valid_600814 != nil:
    section.add "X-Amz-Content-Sha256", valid_600814
  var valid_600815 = header.getOrDefault("X-Amz-Algorithm")
  valid_600815 = validateParameter(valid_600815, JString, required = false,
                                 default = nil)
  if valid_600815 != nil:
    section.add "X-Amz-Algorithm", valid_600815
  var valid_600816 = header.getOrDefault("X-Amz-Signature")
  valid_600816 = validateParameter(valid_600816, JString, required = false,
                                 default = nil)
  if valid_600816 != nil:
    section.add "X-Amz-Signature", valid_600816
  var valid_600817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600817 = validateParameter(valid_600817, JString, required = false,
                                 default = nil)
  if valid_600817 != nil:
    section.add "X-Amz-SignedHeaders", valid_600817
  var valid_600818 = header.getOrDefault("X-Amz-Credential")
  valid_600818 = validateParameter(valid_600818, JString, required = false,
                                 default = nil)
  if valid_600818 != nil:
    section.add "X-Amz-Credential", valid_600818
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
  var valid_600819 = formData.getOrDefault("FilenameContains")
  valid_600819 = validateParameter(valid_600819, JString, required = false,
                                 default = nil)
  if valid_600819 != nil:
    section.add "FilenameContains", valid_600819
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600820 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600820 = validateParameter(valid_600820, JString, required = true,
                                 default = nil)
  if valid_600820 != nil:
    section.add "DBInstanceIdentifier", valid_600820
  var valid_600821 = formData.getOrDefault("FileSize")
  valid_600821 = validateParameter(valid_600821, JInt, required = false, default = nil)
  if valid_600821 != nil:
    section.add "FileSize", valid_600821
  var valid_600822 = formData.getOrDefault("Marker")
  valid_600822 = validateParameter(valid_600822, JString, required = false,
                                 default = nil)
  if valid_600822 != nil:
    section.add "Marker", valid_600822
  var valid_600823 = formData.getOrDefault("Filters")
  valid_600823 = validateParameter(valid_600823, JArray, required = false,
                                 default = nil)
  if valid_600823 != nil:
    section.add "Filters", valid_600823
  var valid_600824 = formData.getOrDefault("MaxRecords")
  valid_600824 = validateParameter(valid_600824, JInt, required = false, default = nil)
  if valid_600824 != nil:
    section.add "MaxRecords", valid_600824
  var valid_600825 = formData.getOrDefault("FileLastWritten")
  valid_600825 = validateParameter(valid_600825, JInt, required = false, default = nil)
  if valid_600825 != nil:
    section.add "FileLastWritten", valid_600825
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600826: Call_PostDescribeDBLogFiles_600807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600826.validator(path, query, header, formData, body)
  let scheme = call_600826.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600826.url(scheme.get, call_600826.host, call_600826.base,
                         call_600826.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600826, url, valid)

proc call*(call_600827: Call_PostDescribeDBLogFiles_600807;
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
  var query_600828 = newJObject()
  var formData_600829 = newJObject()
  add(formData_600829, "FilenameContains", newJString(FilenameContains))
  add(formData_600829, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600829, "FileSize", newJInt(FileSize))
  add(formData_600829, "Marker", newJString(Marker))
  add(query_600828, "Action", newJString(Action))
  if Filters != nil:
    formData_600829.add "Filters", Filters
  add(formData_600829, "MaxRecords", newJInt(MaxRecords))
  add(formData_600829, "FileLastWritten", newJInt(FileLastWritten))
  add(query_600828, "Version", newJString(Version))
  result = call_600827.call(nil, query_600828, nil, formData_600829, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_600807(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_600808, base: "/",
    url: url_PostDescribeDBLogFiles_600809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_600785 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBLogFiles_600787(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_600786(path: JsonNode; query: JsonNode;
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
  var valid_600788 = query.getOrDefault("FileLastWritten")
  valid_600788 = validateParameter(valid_600788, JInt, required = false, default = nil)
  if valid_600788 != nil:
    section.add "FileLastWritten", valid_600788
  var valid_600789 = query.getOrDefault("MaxRecords")
  valid_600789 = validateParameter(valid_600789, JInt, required = false, default = nil)
  if valid_600789 != nil:
    section.add "MaxRecords", valid_600789
  var valid_600790 = query.getOrDefault("FilenameContains")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "FilenameContains", valid_600790
  var valid_600791 = query.getOrDefault("FileSize")
  valid_600791 = validateParameter(valid_600791, JInt, required = false, default = nil)
  if valid_600791 != nil:
    section.add "FileSize", valid_600791
  var valid_600792 = query.getOrDefault("Filters")
  valid_600792 = validateParameter(valid_600792, JArray, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "Filters", valid_600792
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600793 = query.getOrDefault("Action")
  valid_600793 = validateParameter(valid_600793, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_600793 != nil:
    section.add "Action", valid_600793
  var valid_600794 = query.getOrDefault("Marker")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "Marker", valid_600794
  var valid_600795 = query.getOrDefault("Version")
  valid_600795 = validateParameter(valid_600795, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600795 != nil:
    section.add "Version", valid_600795
  var valid_600796 = query.getOrDefault("DBInstanceIdentifier")
  valid_600796 = validateParameter(valid_600796, JString, required = true,
                                 default = nil)
  if valid_600796 != nil:
    section.add "DBInstanceIdentifier", valid_600796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600797 = header.getOrDefault("X-Amz-Date")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "X-Amz-Date", valid_600797
  var valid_600798 = header.getOrDefault("X-Amz-Security-Token")
  valid_600798 = validateParameter(valid_600798, JString, required = false,
                                 default = nil)
  if valid_600798 != nil:
    section.add "X-Amz-Security-Token", valid_600798
  var valid_600799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600799 = validateParameter(valid_600799, JString, required = false,
                                 default = nil)
  if valid_600799 != nil:
    section.add "X-Amz-Content-Sha256", valid_600799
  var valid_600800 = header.getOrDefault("X-Amz-Algorithm")
  valid_600800 = validateParameter(valid_600800, JString, required = false,
                                 default = nil)
  if valid_600800 != nil:
    section.add "X-Amz-Algorithm", valid_600800
  var valid_600801 = header.getOrDefault("X-Amz-Signature")
  valid_600801 = validateParameter(valid_600801, JString, required = false,
                                 default = nil)
  if valid_600801 != nil:
    section.add "X-Amz-Signature", valid_600801
  var valid_600802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600802 = validateParameter(valid_600802, JString, required = false,
                                 default = nil)
  if valid_600802 != nil:
    section.add "X-Amz-SignedHeaders", valid_600802
  var valid_600803 = header.getOrDefault("X-Amz-Credential")
  valid_600803 = validateParameter(valid_600803, JString, required = false,
                                 default = nil)
  if valid_600803 != nil:
    section.add "X-Amz-Credential", valid_600803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600804: Call_GetDescribeDBLogFiles_600785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600804.validator(path, query, header, formData, body)
  let scheme = call_600804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600804.url(scheme.get, call_600804.host, call_600804.base,
                         call_600804.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600804, url, valid)

proc call*(call_600805: Call_GetDescribeDBLogFiles_600785;
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
  var query_600806 = newJObject()
  add(query_600806, "FileLastWritten", newJInt(FileLastWritten))
  add(query_600806, "MaxRecords", newJInt(MaxRecords))
  add(query_600806, "FilenameContains", newJString(FilenameContains))
  add(query_600806, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_600806.add "Filters", Filters
  add(query_600806, "Action", newJString(Action))
  add(query_600806, "Marker", newJString(Marker))
  add(query_600806, "Version", newJString(Version))
  add(query_600806, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600805.call(nil, query_600806, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_600785(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_600786, base: "/",
    url: url_GetDescribeDBLogFiles_600787, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_600849 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBParameterGroups_600851(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_600850(path: JsonNode; query: JsonNode;
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
  var valid_600852 = query.getOrDefault("Action")
  valid_600852 = validateParameter(valid_600852, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_600852 != nil:
    section.add "Action", valid_600852
  var valid_600853 = query.getOrDefault("Version")
  valid_600853 = validateParameter(valid_600853, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600853 != nil:
    section.add "Version", valid_600853
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600854 = header.getOrDefault("X-Amz-Date")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Date", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-Security-Token")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-Security-Token", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Content-Sha256", valid_600856
  var valid_600857 = header.getOrDefault("X-Amz-Algorithm")
  valid_600857 = validateParameter(valid_600857, JString, required = false,
                                 default = nil)
  if valid_600857 != nil:
    section.add "X-Amz-Algorithm", valid_600857
  var valid_600858 = header.getOrDefault("X-Amz-Signature")
  valid_600858 = validateParameter(valid_600858, JString, required = false,
                                 default = nil)
  if valid_600858 != nil:
    section.add "X-Amz-Signature", valid_600858
  var valid_600859 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600859 = validateParameter(valid_600859, JString, required = false,
                                 default = nil)
  if valid_600859 != nil:
    section.add "X-Amz-SignedHeaders", valid_600859
  var valid_600860 = header.getOrDefault("X-Amz-Credential")
  valid_600860 = validateParameter(valid_600860, JString, required = false,
                                 default = nil)
  if valid_600860 != nil:
    section.add "X-Amz-Credential", valid_600860
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600861 = formData.getOrDefault("DBParameterGroupName")
  valid_600861 = validateParameter(valid_600861, JString, required = false,
                                 default = nil)
  if valid_600861 != nil:
    section.add "DBParameterGroupName", valid_600861
  var valid_600862 = formData.getOrDefault("Marker")
  valid_600862 = validateParameter(valid_600862, JString, required = false,
                                 default = nil)
  if valid_600862 != nil:
    section.add "Marker", valid_600862
  var valid_600863 = formData.getOrDefault("Filters")
  valid_600863 = validateParameter(valid_600863, JArray, required = false,
                                 default = nil)
  if valid_600863 != nil:
    section.add "Filters", valid_600863
  var valid_600864 = formData.getOrDefault("MaxRecords")
  valid_600864 = validateParameter(valid_600864, JInt, required = false, default = nil)
  if valid_600864 != nil:
    section.add "MaxRecords", valid_600864
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600865: Call_PostDescribeDBParameterGroups_600849; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600865.validator(path, query, header, formData, body)
  let scheme = call_600865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600865.url(scheme.get, call_600865.host, call_600865.base,
                         call_600865.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600865, url, valid)

proc call*(call_600866: Call_PostDescribeDBParameterGroups_600849;
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
  var query_600867 = newJObject()
  var formData_600868 = newJObject()
  add(formData_600868, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600868, "Marker", newJString(Marker))
  add(query_600867, "Action", newJString(Action))
  if Filters != nil:
    formData_600868.add "Filters", Filters
  add(formData_600868, "MaxRecords", newJInt(MaxRecords))
  add(query_600867, "Version", newJString(Version))
  result = call_600866.call(nil, query_600867, nil, formData_600868, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_600849(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_600850, base: "/",
    url: url_PostDescribeDBParameterGroups_600851,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_600830 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBParameterGroups_600832(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_600831(path: JsonNode; query: JsonNode;
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
  var valid_600833 = query.getOrDefault("MaxRecords")
  valid_600833 = validateParameter(valid_600833, JInt, required = false, default = nil)
  if valid_600833 != nil:
    section.add "MaxRecords", valid_600833
  var valid_600834 = query.getOrDefault("Filters")
  valid_600834 = validateParameter(valid_600834, JArray, required = false,
                                 default = nil)
  if valid_600834 != nil:
    section.add "Filters", valid_600834
  var valid_600835 = query.getOrDefault("DBParameterGroupName")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "DBParameterGroupName", valid_600835
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600836 = query.getOrDefault("Action")
  valid_600836 = validateParameter(valid_600836, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_600836 != nil:
    section.add "Action", valid_600836
  var valid_600837 = query.getOrDefault("Marker")
  valid_600837 = validateParameter(valid_600837, JString, required = false,
                                 default = nil)
  if valid_600837 != nil:
    section.add "Marker", valid_600837
  var valid_600838 = query.getOrDefault("Version")
  valid_600838 = validateParameter(valid_600838, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600838 != nil:
    section.add "Version", valid_600838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600839 = header.getOrDefault("X-Amz-Date")
  valid_600839 = validateParameter(valid_600839, JString, required = false,
                                 default = nil)
  if valid_600839 != nil:
    section.add "X-Amz-Date", valid_600839
  var valid_600840 = header.getOrDefault("X-Amz-Security-Token")
  valid_600840 = validateParameter(valid_600840, JString, required = false,
                                 default = nil)
  if valid_600840 != nil:
    section.add "X-Amz-Security-Token", valid_600840
  var valid_600841 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600841 = validateParameter(valid_600841, JString, required = false,
                                 default = nil)
  if valid_600841 != nil:
    section.add "X-Amz-Content-Sha256", valid_600841
  var valid_600842 = header.getOrDefault("X-Amz-Algorithm")
  valid_600842 = validateParameter(valid_600842, JString, required = false,
                                 default = nil)
  if valid_600842 != nil:
    section.add "X-Amz-Algorithm", valid_600842
  var valid_600843 = header.getOrDefault("X-Amz-Signature")
  valid_600843 = validateParameter(valid_600843, JString, required = false,
                                 default = nil)
  if valid_600843 != nil:
    section.add "X-Amz-Signature", valid_600843
  var valid_600844 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600844 = validateParameter(valid_600844, JString, required = false,
                                 default = nil)
  if valid_600844 != nil:
    section.add "X-Amz-SignedHeaders", valid_600844
  var valid_600845 = header.getOrDefault("X-Amz-Credential")
  valid_600845 = validateParameter(valid_600845, JString, required = false,
                                 default = nil)
  if valid_600845 != nil:
    section.add "X-Amz-Credential", valid_600845
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600846: Call_GetDescribeDBParameterGroups_600830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600846.validator(path, query, header, formData, body)
  let scheme = call_600846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600846.url(scheme.get, call_600846.host, call_600846.base,
                         call_600846.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600846, url, valid)

proc call*(call_600847: Call_GetDescribeDBParameterGroups_600830;
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
  var query_600848 = newJObject()
  add(query_600848, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600848.add "Filters", Filters
  add(query_600848, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600848, "Action", newJString(Action))
  add(query_600848, "Marker", newJString(Marker))
  add(query_600848, "Version", newJString(Version))
  result = call_600847.call(nil, query_600848, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_600830(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_600831, base: "/",
    url: url_GetDescribeDBParameterGroups_600832,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_600889 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBParameters_600891(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_600890(path: JsonNode; query: JsonNode;
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
  var valid_600892 = query.getOrDefault("Action")
  valid_600892 = validateParameter(valid_600892, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_600892 != nil:
    section.add "Action", valid_600892
  var valid_600893 = query.getOrDefault("Version")
  valid_600893 = validateParameter(valid_600893, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600893 != nil:
    section.add "Version", valid_600893
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600894 = header.getOrDefault("X-Amz-Date")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Date", valid_600894
  var valid_600895 = header.getOrDefault("X-Amz-Security-Token")
  valid_600895 = validateParameter(valid_600895, JString, required = false,
                                 default = nil)
  if valid_600895 != nil:
    section.add "X-Amz-Security-Token", valid_600895
  var valid_600896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600896 = validateParameter(valid_600896, JString, required = false,
                                 default = nil)
  if valid_600896 != nil:
    section.add "X-Amz-Content-Sha256", valid_600896
  var valid_600897 = header.getOrDefault("X-Amz-Algorithm")
  valid_600897 = validateParameter(valid_600897, JString, required = false,
                                 default = nil)
  if valid_600897 != nil:
    section.add "X-Amz-Algorithm", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Signature")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Signature", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-SignedHeaders", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Credential")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Credential", valid_600900
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600901 = formData.getOrDefault("DBParameterGroupName")
  valid_600901 = validateParameter(valid_600901, JString, required = true,
                                 default = nil)
  if valid_600901 != nil:
    section.add "DBParameterGroupName", valid_600901
  var valid_600902 = formData.getOrDefault("Marker")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "Marker", valid_600902
  var valid_600903 = formData.getOrDefault("Filters")
  valid_600903 = validateParameter(valid_600903, JArray, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "Filters", valid_600903
  var valid_600904 = formData.getOrDefault("MaxRecords")
  valid_600904 = validateParameter(valid_600904, JInt, required = false, default = nil)
  if valid_600904 != nil:
    section.add "MaxRecords", valid_600904
  var valid_600905 = formData.getOrDefault("Source")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "Source", valid_600905
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600906: Call_PostDescribeDBParameters_600889; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600906.validator(path, query, header, formData, body)
  let scheme = call_600906.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600906.url(scheme.get, call_600906.host, call_600906.base,
                         call_600906.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600906, url, valid)

proc call*(call_600907: Call_PostDescribeDBParameters_600889;
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
  var query_600908 = newJObject()
  var formData_600909 = newJObject()
  add(formData_600909, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600909, "Marker", newJString(Marker))
  add(query_600908, "Action", newJString(Action))
  if Filters != nil:
    formData_600909.add "Filters", Filters
  add(formData_600909, "MaxRecords", newJInt(MaxRecords))
  add(query_600908, "Version", newJString(Version))
  add(formData_600909, "Source", newJString(Source))
  result = call_600907.call(nil, query_600908, nil, formData_600909, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_600889(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_600890, base: "/",
    url: url_PostDescribeDBParameters_600891, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_600869 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBParameters_600871(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_600870(path: JsonNode; query: JsonNode;
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
  var valid_600872 = query.getOrDefault("MaxRecords")
  valid_600872 = validateParameter(valid_600872, JInt, required = false, default = nil)
  if valid_600872 != nil:
    section.add "MaxRecords", valid_600872
  var valid_600873 = query.getOrDefault("Filters")
  valid_600873 = validateParameter(valid_600873, JArray, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "Filters", valid_600873
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_600874 = query.getOrDefault("DBParameterGroupName")
  valid_600874 = validateParameter(valid_600874, JString, required = true,
                                 default = nil)
  if valid_600874 != nil:
    section.add "DBParameterGroupName", valid_600874
  var valid_600875 = query.getOrDefault("Action")
  valid_600875 = validateParameter(valid_600875, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_600875 != nil:
    section.add "Action", valid_600875
  var valid_600876 = query.getOrDefault("Marker")
  valid_600876 = validateParameter(valid_600876, JString, required = false,
                                 default = nil)
  if valid_600876 != nil:
    section.add "Marker", valid_600876
  var valid_600877 = query.getOrDefault("Source")
  valid_600877 = validateParameter(valid_600877, JString, required = false,
                                 default = nil)
  if valid_600877 != nil:
    section.add "Source", valid_600877
  var valid_600878 = query.getOrDefault("Version")
  valid_600878 = validateParameter(valid_600878, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600878 != nil:
    section.add "Version", valid_600878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600879 = header.getOrDefault("X-Amz-Date")
  valid_600879 = validateParameter(valid_600879, JString, required = false,
                                 default = nil)
  if valid_600879 != nil:
    section.add "X-Amz-Date", valid_600879
  var valid_600880 = header.getOrDefault("X-Amz-Security-Token")
  valid_600880 = validateParameter(valid_600880, JString, required = false,
                                 default = nil)
  if valid_600880 != nil:
    section.add "X-Amz-Security-Token", valid_600880
  var valid_600881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600881 = validateParameter(valid_600881, JString, required = false,
                                 default = nil)
  if valid_600881 != nil:
    section.add "X-Amz-Content-Sha256", valid_600881
  var valid_600882 = header.getOrDefault("X-Amz-Algorithm")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Algorithm", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Signature")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Signature", valid_600883
  var valid_600884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-SignedHeaders", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Credential")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Credential", valid_600885
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600886: Call_GetDescribeDBParameters_600869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600886.validator(path, query, header, formData, body)
  let scheme = call_600886.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600886.url(scheme.get, call_600886.host, call_600886.base,
                         call_600886.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600886, url, valid)

proc call*(call_600887: Call_GetDescribeDBParameters_600869;
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
  var query_600888 = newJObject()
  add(query_600888, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600888.add "Filters", Filters
  add(query_600888, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600888, "Action", newJString(Action))
  add(query_600888, "Marker", newJString(Marker))
  add(query_600888, "Source", newJString(Source))
  add(query_600888, "Version", newJString(Version))
  result = call_600887.call(nil, query_600888, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_600869(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_600870, base: "/",
    url: url_GetDescribeDBParameters_600871, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_600929 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSecurityGroups_600931(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_600930(path: JsonNode; query: JsonNode;
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
  var valid_600932 = query.getOrDefault("Action")
  valid_600932 = validateParameter(valid_600932, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_600932 != nil:
    section.add "Action", valid_600932
  var valid_600933 = query.getOrDefault("Version")
  valid_600933 = validateParameter(valid_600933, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600933 != nil:
    section.add "Version", valid_600933
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600934 = header.getOrDefault("X-Amz-Date")
  valid_600934 = validateParameter(valid_600934, JString, required = false,
                                 default = nil)
  if valid_600934 != nil:
    section.add "X-Amz-Date", valid_600934
  var valid_600935 = header.getOrDefault("X-Amz-Security-Token")
  valid_600935 = validateParameter(valid_600935, JString, required = false,
                                 default = nil)
  if valid_600935 != nil:
    section.add "X-Amz-Security-Token", valid_600935
  var valid_600936 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600936 = validateParameter(valid_600936, JString, required = false,
                                 default = nil)
  if valid_600936 != nil:
    section.add "X-Amz-Content-Sha256", valid_600936
  var valid_600937 = header.getOrDefault("X-Amz-Algorithm")
  valid_600937 = validateParameter(valid_600937, JString, required = false,
                                 default = nil)
  if valid_600937 != nil:
    section.add "X-Amz-Algorithm", valid_600937
  var valid_600938 = header.getOrDefault("X-Amz-Signature")
  valid_600938 = validateParameter(valid_600938, JString, required = false,
                                 default = nil)
  if valid_600938 != nil:
    section.add "X-Amz-Signature", valid_600938
  var valid_600939 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600939 = validateParameter(valid_600939, JString, required = false,
                                 default = nil)
  if valid_600939 != nil:
    section.add "X-Amz-SignedHeaders", valid_600939
  var valid_600940 = header.getOrDefault("X-Amz-Credential")
  valid_600940 = validateParameter(valid_600940, JString, required = false,
                                 default = nil)
  if valid_600940 != nil:
    section.add "X-Amz-Credential", valid_600940
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600941 = formData.getOrDefault("DBSecurityGroupName")
  valid_600941 = validateParameter(valid_600941, JString, required = false,
                                 default = nil)
  if valid_600941 != nil:
    section.add "DBSecurityGroupName", valid_600941
  var valid_600942 = formData.getOrDefault("Marker")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "Marker", valid_600942
  var valid_600943 = formData.getOrDefault("Filters")
  valid_600943 = validateParameter(valid_600943, JArray, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "Filters", valid_600943
  var valid_600944 = formData.getOrDefault("MaxRecords")
  valid_600944 = validateParameter(valid_600944, JInt, required = false, default = nil)
  if valid_600944 != nil:
    section.add "MaxRecords", valid_600944
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600945: Call_PostDescribeDBSecurityGroups_600929; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600945.validator(path, query, header, formData, body)
  let scheme = call_600945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600945.url(scheme.get, call_600945.host, call_600945.base,
                         call_600945.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600945, url, valid)

proc call*(call_600946: Call_PostDescribeDBSecurityGroups_600929;
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
  var query_600947 = newJObject()
  var formData_600948 = newJObject()
  add(formData_600948, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_600948, "Marker", newJString(Marker))
  add(query_600947, "Action", newJString(Action))
  if Filters != nil:
    formData_600948.add "Filters", Filters
  add(formData_600948, "MaxRecords", newJInt(MaxRecords))
  add(query_600947, "Version", newJString(Version))
  result = call_600946.call(nil, query_600947, nil, formData_600948, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_600929(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_600930, base: "/",
    url: url_PostDescribeDBSecurityGroups_600931,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_600910 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSecurityGroups_600912(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_600911(path: JsonNode; query: JsonNode;
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
  var valid_600913 = query.getOrDefault("MaxRecords")
  valid_600913 = validateParameter(valid_600913, JInt, required = false, default = nil)
  if valid_600913 != nil:
    section.add "MaxRecords", valid_600913
  var valid_600914 = query.getOrDefault("DBSecurityGroupName")
  valid_600914 = validateParameter(valid_600914, JString, required = false,
                                 default = nil)
  if valid_600914 != nil:
    section.add "DBSecurityGroupName", valid_600914
  var valid_600915 = query.getOrDefault("Filters")
  valid_600915 = validateParameter(valid_600915, JArray, required = false,
                                 default = nil)
  if valid_600915 != nil:
    section.add "Filters", valid_600915
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600916 = query.getOrDefault("Action")
  valid_600916 = validateParameter(valid_600916, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_600916 != nil:
    section.add "Action", valid_600916
  var valid_600917 = query.getOrDefault("Marker")
  valid_600917 = validateParameter(valid_600917, JString, required = false,
                                 default = nil)
  if valid_600917 != nil:
    section.add "Marker", valid_600917
  var valid_600918 = query.getOrDefault("Version")
  valid_600918 = validateParameter(valid_600918, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600918 != nil:
    section.add "Version", valid_600918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600919 = header.getOrDefault("X-Amz-Date")
  valid_600919 = validateParameter(valid_600919, JString, required = false,
                                 default = nil)
  if valid_600919 != nil:
    section.add "X-Amz-Date", valid_600919
  var valid_600920 = header.getOrDefault("X-Amz-Security-Token")
  valid_600920 = validateParameter(valid_600920, JString, required = false,
                                 default = nil)
  if valid_600920 != nil:
    section.add "X-Amz-Security-Token", valid_600920
  var valid_600921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600921 = validateParameter(valid_600921, JString, required = false,
                                 default = nil)
  if valid_600921 != nil:
    section.add "X-Amz-Content-Sha256", valid_600921
  var valid_600922 = header.getOrDefault("X-Amz-Algorithm")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "X-Amz-Algorithm", valid_600922
  var valid_600923 = header.getOrDefault("X-Amz-Signature")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "X-Amz-Signature", valid_600923
  var valid_600924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600924 = validateParameter(valid_600924, JString, required = false,
                                 default = nil)
  if valid_600924 != nil:
    section.add "X-Amz-SignedHeaders", valid_600924
  var valid_600925 = header.getOrDefault("X-Amz-Credential")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "X-Amz-Credential", valid_600925
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_GetDescribeDBSecurityGroups_600910; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600926, url, valid)

proc call*(call_600927: Call_GetDescribeDBSecurityGroups_600910;
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
  var query_600928 = newJObject()
  add(query_600928, "MaxRecords", newJInt(MaxRecords))
  add(query_600928, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_600928.add "Filters", Filters
  add(query_600928, "Action", newJString(Action))
  add(query_600928, "Marker", newJString(Marker))
  add(query_600928, "Version", newJString(Version))
  result = call_600927.call(nil, query_600928, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_600910(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_600911, base: "/",
    url: url_GetDescribeDBSecurityGroups_600912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_600970 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSnapshots_600972(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_600971(path: JsonNode; query: JsonNode;
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
  var valid_600973 = query.getOrDefault("Action")
  valid_600973 = validateParameter(valid_600973, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_600973 != nil:
    section.add "Action", valid_600973
  var valid_600974 = query.getOrDefault("Version")
  valid_600974 = validateParameter(valid_600974, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600974 != nil:
    section.add "Version", valid_600974
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600975 = header.getOrDefault("X-Amz-Date")
  valid_600975 = validateParameter(valid_600975, JString, required = false,
                                 default = nil)
  if valid_600975 != nil:
    section.add "X-Amz-Date", valid_600975
  var valid_600976 = header.getOrDefault("X-Amz-Security-Token")
  valid_600976 = validateParameter(valid_600976, JString, required = false,
                                 default = nil)
  if valid_600976 != nil:
    section.add "X-Amz-Security-Token", valid_600976
  var valid_600977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600977 = validateParameter(valid_600977, JString, required = false,
                                 default = nil)
  if valid_600977 != nil:
    section.add "X-Amz-Content-Sha256", valid_600977
  var valid_600978 = header.getOrDefault("X-Amz-Algorithm")
  valid_600978 = validateParameter(valid_600978, JString, required = false,
                                 default = nil)
  if valid_600978 != nil:
    section.add "X-Amz-Algorithm", valid_600978
  var valid_600979 = header.getOrDefault("X-Amz-Signature")
  valid_600979 = validateParameter(valid_600979, JString, required = false,
                                 default = nil)
  if valid_600979 != nil:
    section.add "X-Amz-Signature", valid_600979
  var valid_600980 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600980 = validateParameter(valid_600980, JString, required = false,
                                 default = nil)
  if valid_600980 != nil:
    section.add "X-Amz-SignedHeaders", valid_600980
  var valid_600981 = header.getOrDefault("X-Amz-Credential")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Credential", valid_600981
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600982 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "DBInstanceIdentifier", valid_600982
  var valid_600983 = formData.getOrDefault("SnapshotType")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "SnapshotType", valid_600983
  var valid_600984 = formData.getOrDefault("Marker")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "Marker", valid_600984
  var valid_600985 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "DBSnapshotIdentifier", valid_600985
  var valid_600986 = formData.getOrDefault("Filters")
  valid_600986 = validateParameter(valid_600986, JArray, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "Filters", valid_600986
  var valid_600987 = formData.getOrDefault("MaxRecords")
  valid_600987 = validateParameter(valid_600987, JInt, required = false, default = nil)
  if valid_600987 != nil:
    section.add "MaxRecords", valid_600987
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600988: Call_PostDescribeDBSnapshots_600970; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600988.validator(path, query, header, formData, body)
  let scheme = call_600988.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600988.url(scheme.get, call_600988.host, call_600988.base,
                         call_600988.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600988, url, valid)

proc call*(call_600989: Call_PostDescribeDBSnapshots_600970;
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
  var query_600990 = newJObject()
  var formData_600991 = newJObject()
  add(formData_600991, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600991, "SnapshotType", newJString(SnapshotType))
  add(formData_600991, "Marker", newJString(Marker))
  add(formData_600991, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600990, "Action", newJString(Action))
  if Filters != nil:
    formData_600991.add "Filters", Filters
  add(formData_600991, "MaxRecords", newJInt(MaxRecords))
  add(query_600990, "Version", newJString(Version))
  result = call_600989.call(nil, query_600990, nil, formData_600991, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_600970(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_600971, base: "/",
    url: url_PostDescribeDBSnapshots_600972, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_600949 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSnapshots_600951(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_600950(path: JsonNode; query: JsonNode;
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
  var valid_600952 = query.getOrDefault("MaxRecords")
  valid_600952 = validateParameter(valid_600952, JInt, required = false, default = nil)
  if valid_600952 != nil:
    section.add "MaxRecords", valid_600952
  var valid_600953 = query.getOrDefault("Filters")
  valid_600953 = validateParameter(valid_600953, JArray, required = false,
                                 default = nil)
  if valid_600953 != nil:
    section.add "Filters", valid_600953
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600954 = query.getOrDefault("Action")
  valid_600954 = validateParameter(valid_600954, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_600954 != nil:
    section.add "Action", valid_600954
  var valid_600955 = query.getOrDefault("Marker")
  valid_600955 = validateParameter(valid_600955, JString, required = false,
                                 default = nil)
  if valid_600955 != nil:
    section.add "Marker", valid_600955
  var valid_600956 = query.getOrDefault("SnapshotType")
  valid_600956 = validateParameter(valid_600956, JString, required = false,
                                 default = nil)
  if valid_600956 != nil:
    section.add "SnapshotType", valid_600956
  var valid_600957 = query.getOrDefault("Version")
  valid_600957 = validateParameter(valid_600957, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_600957 != nil:
    section.add "Version", valid_600957
  var valid_600958 = query.getOrDefault("DBInstanceIdentifier")
  valid_600958 = validateParameter(valid_600958, JString, required = false,
                                 default = nil)
  if valid_600958 != nil:
    section.add "DBInstanceIdentifier", valid_600958
  var valid_600959 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600959 = validateParameter(valid_600959, JString, required = false,
                                 default = nil)
  if valid_600959 != nil:
    section.add "DBSnapshotIdentifier", valid_600959
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600960 = header.getOrDefault("X-Amz-Date")
  valid_600960 = validateParameter(valid_600960, JString, required = false,
                                 default = nil)
  if valid_600960 != nil:
    section.add "X-Amz-Date", valid_600960
  var valid_600961 = header.getOrDefault("X-Amz-Security-Token")
  valid_600961 = validateParameter(valid_600961, JString, required = false,
                                 default = nil)
  if valid_600961 != nil:
    section.add "X-Amz-Security-Token", valid_600961
  var valid_600962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600962 = validateParameter(valid_600962, JString, required = false,
                                 default = nil)
  if valid_600962 != nil:
    section.add "X-Amz-Content-Sha256", valid_600962
  var valid_600963 = header.getOrDefault("X-Amz-Algorithm")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "X-Amz-Algorithm", valid_600963
  var valid_600964 = header.getOrDefault("X-Amz-Signature")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "X-Amz-Signature", valid_600964
  var valid_600965 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600965 = validateParameter(valid_600965, JString, required = false,
                                 default = nil)
  if valid_600965 != nil:
    section.add "X-Amz-SignedHeaders", valid_600965
  var valid_600966 = header.getOrDefault("X-Amz-Credential")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Credential", valid_600966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600967: Call_GetDescribeDBSnapshots_600949; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600967.validator(path, query, header, formData, body)
  let scheme = call_600967.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600967.url(scheme.get, call_600967.host, call_600967.base,
                         call_600967.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600967, url, valid)

proc call*(call_600968: Call_GetDescribeDBSnapshots_600949; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSnapshots";
          Marker: string = ""; SnapshotType: string = "";
          Version: string = "2013-09-09"; DBInstanceIdentifier: string = "";
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
  var query_600969 = newJObject()
  add(query_600969, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_600969.add "Filters", Filters
  add(query_600969, "Action", newJString(Action))
  add(query_600969, "Marker", newJString(Marker))
  add(query_600969, "SnapshotType", newJString(SnapshotType))
  add(query_600969, "Version", newJString(Version))
  add(query_600969, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600969, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600968.call(nil, query_600969, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_600949(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_600950, base: "/",
    url: url_GetDescribeDBSnapshots_600951, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_601011 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSubnetGroups_601013(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_601012(path: JsonNode; query: JsonNode;
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
  var valid_601014 = query.getOrDefault("Action")
  valid_601014 = validateParameter(valid_601014, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_601014 != nil:
    section.add "Action", valid_601014
  var valid_601015 = query.getOrDefault("Version")
  valid_601015 = validateParameter(valid_601015, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601015 != nil:
    section.add "Version", valid_601015
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601016 = header.getOrDefault("X-Amz-Date")
  valid_601016 = validateParameter(valid_601016, JString, required = false,
                                 default = nil)
  if valid_601016 != nil:
    section.add "X-Amz-Date", valid_601016
  var valid_601017 = header.getOrDefault("X-Amz-Security-Token")
  valid_601017 = validateParameter(valid_601017, JString, required = false,
                                 default = nil)
  if valid_601017 != nil:
    section.add "X-Amz-Security-Token", valid_601017
  var valid_601018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-Content-Sha256", valid_601018
  var valid_601019 = header.getOrDefault("X-Amz-Algorithm")
  valid_601019 = validateParameter(valid_601019, JString, required = false,
                                 default = nil)
  if valid_601019 != nil:
    section.add "X-Amz-Algorithm", valid_601019
  var valid_601020 = header.getOrDefault("X-Amz-Signature")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-Signature", valid_601020
  var valid_601021 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601021 = validateParameter(valid_601021, JString, required = false,
                                 default = nil)
  if valid_601021 != nil:
    section.add "X-Amz-SignedHeaders", valid_601021
  var valid_601022 = header.getOrDefault("X-Amz-Credential")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "X-Amz-Credential", valid_601022
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601023 = formData.getOrDefault("DBSubnetGroupName")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "DBSubnetGroupName", valid_601023
  var valid_601024 = formData.getOrDefault("Marker")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "Marker", valid_601024
  var valid_601025 = formData.getOrDefault("Filters")
  valid_601025 = validateParameter(valid_601025, JArray, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "Filters", valid_601025
  var valid_601026 = formData.getOrDefault("MaxRecords")
  valid_601026 = validateParameter(valid_601026, JInt, required = false, default = nil)
  if valid_601026 != nil:
    section.add "MaxRecords", valid_601026
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601027: Call_PostDescribeDBSubnetGroups_601011; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601027.validator(path, query, header, formData, body)
  let scheme = call_601027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601027.url(scheme.get, call_601027.host, call_601027.base,
                         call_601027.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601027, url, valid)

proc call*(call_601028: Call_PostDescribeDBSubnetGroups_601011;
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
  var query_601029 = newJObject()
  var formData_601030 = newJObject()
  add(formData_601030, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601030, "Marker", newJString(Marker))
  add(query_601029, "Action", newJString(Action))
  if Filters != nil:
    formData_601030.add "Filters", Filters
  add(formData_601030, "MaxRecords", newJInt(MaxRecords))
  add(query_601029, "Version", newJString(Version))
  result = call_601028.call(nil, query_601029, nil, formData_601030, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_601011(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_601012, base: "/",
    url: url_PostDescribeDBSubnetGroups_601013,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_600992 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSubnetGroups_600994(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_600993(path: JsonNode; query: JsonNode;
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
  var valid_600995 = query.getOrDefault("MaxRecords")
  valid_600995 = validateParameter(valid_600995, JInt, required = false, default = nil)
  if valid_600995 != nil:
    section.add "MaxRecords", valid_600995
  var valid_600996 = query.getOrDefault("Filters")
  valid_600996 = validateParameter(valid_600996, JArray, required = false,
                                 default = nil)
  if valid_600996 != nil:
    section.add "Filters", valid_600996
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600997 = query.getOrDefault("Action")
  valid_600997 = validateParameter(valid_600997, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_600997 != nil:
    section.add "Action", valid_600997
  var valid_600998 = query.getOrDefault("Marker")
  valid_600998 = validateParameter(valid_600998, JString, required = false,
                                 default = nil)
  if valid_600998 != nil:
    section.add "Marker", valid_600998
  var valid_600999 = query.getOrDefault("DBSubnetGroupName")
  valid_600999 = validateParameter(valid_600999, JString, required = false,
                                 default = nil)
  if valid_600999 != nil:
    section.add "DBSubnetGroupName", valid_600999
  var valid_601000 = query.getOrDefault("Version")
  valid_601000 = validateParameter(valid_601000, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601000 != nil:
    section.add "Version", valid_601000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601001 = header.getOrDefault("X-Amz-Date")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "X-Amz-Date", valid_601001
  var valid_601002 = header.getOrDefault("X-Amz-Security-Token")
  valid_601002 = validateParameter(valid_601002, JString, required = false,
                                 default = nil)
  if valid_601002 != nil:
    section.add "X-Amz-Security-Token", valid_601002
  var valid_601003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "X-Amz-Content-Sha256", valid_601003
  var valid_601004 = header.getOrDefault("X-Amz-Algorithm")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "X-Amz-Algorithm", valid_601004
  var valid_601005 = header.getOrDefault("X-Amz-Signature")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "X-Amz-Signature", valid_601005
  var valid_601006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "X-Amz-SignedHeaders", valid_601006
  var valid_601007 = header.getOrDefault("X-Amz-Credential")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Credential", valid_601007
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601008: Call_GetDescribeDBSubnetGroups_600992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601008.validator(path, query, header, formData, body)
  let scheme = call_601008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601008.url(scheme.get, call_601008.host, call_601008.base,
                         call_601008.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601008, url, valid)

proc call*(call_601009: Call_GetDescribeDBSubnetGroups_600992; MaxRecords: int = 0;
          Filters: JsonNode = nil; Action: string = "DescribeDBSubnetGroups";
          Marker: string = ""; DBSubnetGroupName: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_601010 = newJObject()
  add(query_601010, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601010.add "Filters", Filters
  add(query_601010, "Action", newJString(Action))
  add(query_601010, "Marker", newJString(Marker))
  add(query_601010, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601010, "Version", newJString(Version))
  result = call_601009.call(nil, query_601010, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_600992(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_600993, base: "/",
    url: url_GetDescribeDBSubnetGroups_600994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_601050 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEngineDefaultParameters_601052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_601051(path: JsonNode;
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
  var valid_601053 = query.getOrDefault("Action")
  valid_601053 = validateParameter(valid_601053, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_601053 != nil:
    section.add "Action", valid_601053
  var valid_601054 = query.getOrDefault("Version")
  valid_601054 = validateParameter(valid_601054, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601054 != nil:
    section.add "Version", valid_601054
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Content-Sha256", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Algorithm")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Algorithm", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Signature")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Signature", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-SignedHeaders", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-Credential")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-Credential", valid_601061
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601062 = formData.getOrDefault("Marker")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "Marker", valid_601062
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_601063 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = nil)
  if valid_601063 != nil:
    section.add "DBParameterGroupFamily", valid_601063
  var valid_601064 = formData.getOrDefault("Filters")
  valid_601064 = validateParameter(valid_601064, JArray, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "Filters", valid_601064
  var valid_601065 = formData.getOrDefault("MaxRecords")
  valid_601065 = validateParameter(valid_601065, JInt, required = false, default = nil)
  if valid_601065 != nil:
    section.add "MaxRecords", valid_601065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601066: Call_PostDescribeEngineDefaultParameters_601050;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601066.validator(path, query, header, formData, body)
  let scheme = call_601066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601066.url(scheme.get, call_601066.host, call_601066.base,
                         call_601066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601066, url, valid)

proc call*(call_601067: Call_PostDescribeEngineDefaultParameters_601050;
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
  var query_601068 = newJObject()
  var formData_601069 = newJObject()
  add(formData_601069, "Marker", newJString(Marker))
  add(query_601068, "Action", newJString(Action))
  add(formData_601069, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601069.add "Filters", Filters
  add(formData_601069, "MaxRecords", newJInt(MaxRecords))
  add(query_601068, "Version", newJString(Version))
  result = call_601067.call(nil, query_601068, nil, formData_601069, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_601050(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_601051, base: "/",
    url: url_PostDescribeEngineDefaultParameters_601052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_601031 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEngineDefaultParameters_601033(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_601032(path: JsonNode;
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
  var valid_601034 = query.getOrDefault("MaxRecords")
  valid_601034 = validateParameter(valid_601034, JInt, required = false, default = nil)
  if valid_601034 != nil:
    section.add "MaxRecords", valid_601034
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_601035 = query.getOrDefault("DBParameterGroupFamily")
  valid_601035 = validateParameter(valid_601035, JString, required = true,
                                 default = nil)
  if valid_601035 != nil:
    section.add "DBParameterGroupFamily", valid_601035
  var valid_601036 = query.getOrDefault("Filters")
  valid_601036 = validateParameter(valid_601036, JArray, required = false,
                                 default = nil)
  if valid_601036 != nil:
    section.add "Filters", valid_601036
  var valid_601037 = query.getOrDefault("Action")
  valid_601037 = validateParameter(valid_601037, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_601037 != nil:
    section.add "Action", valid_601037
  var valid_601038 = query.getOrDefault("Marker")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "Marker", valid_601038
  var valid_601039 = query.getOrDefault("Version")
  valid_601039 = validateParameter(valid_601039, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601039 != nil:
    section.add "Version", valid_601039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601047: Call_GetDescribeEngineDefaultParameters_601031;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601047.validator(path, query, header, formData, body)
  let scheme = call_601047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601047.url(scheme.get, call_601047.host, call_601047.base,
                         call_601047.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601047, url, valid)

proc call*(call_601048: Call_GetDescribeEngineDefaultParameters_601031;
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
  var query_601049 = newJObject()
  add(query_601049, "MaxRecords", newJInt(MaxRecords))
  add(query_601049, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601049.add "Filters", Filters
  add(query_601049, "Action", newJString(Action))
  add(query_601049, "Marker", newJString(Marker))
  add(query_601049, "Version", newJString(Version))
  result = call_601048.call(nil, query_601049, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_601031(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_601032, base: "/",
    url: url_GetDescribeEngineDefaultParameters_601033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_601087 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEventCategories_601089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_601088(path: JsonNode; query: JsonNode;
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
  var valid_601090 = query.getOrDefault("Action")
  valid_601090 = validateParameter(valid_601090, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601090 != nil:
    section.add "Action", valid_601090
  var valid_601091 = query.getOrDefault("Version")
  valid_601091 = validateParameter(valid_601091, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601091 != nil:
    section.add "Version", valid_601091
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601092 = header.getOrDefault("X-Amz-Date")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Date", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-Security-Token")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-Security-Token", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Content-Sha256", valid_601094
  var valid_601095 = header.getOrDefault("X-Amz-Algorithm")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "X-Amz-Algorithm", valid_601095
  var valid_601096 = header.getOrDefault("X-Amz-Signature")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Signature", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-SignedHeaders", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Credential")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Credential", valid_601098
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_601099 = formData.getOrDefault("Filters")
  valid_601099 = validateParameter(valid_601099, JArray, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "Filters", valid_601099
  var valid_601100 = formData.getOrDefault("SourceType")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "SourceType", valid_601100
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601101: Call_PostDescribeEventCategories_601087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601101.validator(path, query, header, formData, body)
  let scheme = call_601101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601101.url(scheme.get, call_601101.host, call_601101.base,
                         call_601101.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601101, url, valid)

proc call*(call_601102: Call_PostDescribeEventCategories_601087;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_601103 = newJObject()
  var formData_601104 = newJObject()
  add(query_601103, "Action", newJString(Action))
  if Filters != nil:
    formData_601104.add "Filters", Filters
  add(query_601103, "Version", newJString(Version))
  add(formData_601104, "SourceType", newJString(SourceType))
  result = call_601102.call(nil, query_601103, nil, formData_601104, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_601087(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_601088, base: "/",
    url: url_PostDescribeEventCategories_601089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_601070 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEventCategories_601072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_601071(path: JsonNode; query: JsonNode;
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
  var valid_601073 = query.getOrDefault("SourceType")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "SourceType", valid_601073
  var valid_601074 = query.getOrDefault("Filters")
  valid_601074 = validateParameter(valid_601074, JArray, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "Filters", valid_601074
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601075 = query.getOrDefault("Action")
  valid_601075 = validateParameter(valid_601075, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601075 != nil:
    section.add "Action", valid_601075
  var valid_601076 = query.getOrDefault("Version")
  valid_601076 = validateParameter(valid_601076, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601076 != nil:
    section.add "Version", valid_601076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601077 = header.getOrDefault("X-Amz-Date")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Date", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-Security-Token")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-Security-Token", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Content-Sha256", valid_601079
  var valid_601080 = header.getOrDefault("X-Amz-Algorithm")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "X-Amz-Algorithm", valid_601080
  var valid_601081 = header.getOrDefault("X-Amz-Signature")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "X-Amz-Signature", valid_601081
  var valid_601082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-SignedHeaders", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Credential")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Credential", valid_601083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601084: Call_GetDescribeEventCategories_601070; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601084.validator(path, query, header, formData, body)
  let scheme = call_601084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601084.url(scheme.get, call_601084.host, call_601084.base,
                         call_601084.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601084, url, valid)

proc call*(call_601085: Call_GetDescribeEventCategories_601070;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601086 = newJObject()
  add(query_601086, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_601086.add "Filters", Filters
  add(query_601086, "Action", newJString(Action))
  add(query_601086, "Version", newJString(Version))
  result = call_601085.call(nil, query_601086, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_601070(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_601071, base: "/",
    url: url_GetDescribeEventCategories_601072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_601124 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEventSubscriptions_601126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_601125(path: JsonNode;
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
  var valid_601127 = query.getOrDefault("Action")
  valid_601127 = validateParameter(valid_601127, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_601127 != nil:
    section.add "Action", valid_601127
  var valid_601128 = query.getOrDefault("Version")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601128 != nil:
    section.add "Version", valid_601128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601129 = header.getOrDefault("X-Amz-Date")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Date", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Security-Token")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Security-Token", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Content-Sha256", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Algorithm")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Algorithm", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Signature")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Signature", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-SignedHeaders", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Credential")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Credential", valid_601135
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601136 = formData.getOrDefault("Marker")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "Marker", valid_601136
  var valid_601137 = formData.getOrDefault("SubscriptionName")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "SubscriptionName", valid_601137
  var valid_601138 = formData.getOrDefault("Filters")
  valid_601138 = validateParameter(valid_601138, JArray, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "Filters", valid_601138
  var valid_601139 = formData.getOrDefault("MaxRecords")
  valid_601139 = validateParameter(valid_601139, JInt, required = false, default = nil)
  if valid_601139 != nil:
    section.add "MaxRecords", valid_601139
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601140: Call_PostDescribeEventSubscriptions_601124; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601140.validator(path, query, header, formData, body)
  let scheme = call_601140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601140.url(scheme.get, call_601140.host, call_601140.base,
                         call_601140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601140, url, valid)

proc call*(call_601141: Call_PostDescribeEventSubscriptions_601124;
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
  var query_601142 = newJObject()
  var formData_601143 = newJObject()
  add(formData_601143, "Marker", newJString(Marker))
  add(formData_601143, "SubscriptionName", newJString(SubscriptionName))
  add(query_601142, "Action", newJString(Action))
  if Filters != nil:
    formData_601143.add "Filters", Filters
  add(formData_601143, "MaxRecords", newJInt(MaxRecords))
  add(query_601142, "Version", newJString(Version))
  result = call_601141.call(nil, query_601142, nil, formData_601143, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_601124(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_601125, base: "/",
    url: url_PostDescribeEventSubscriptions_601126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_601105 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEventSubscriptions_601107(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_601106(path: JsonNode; query: JsonNode;
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
  var valid_601108 = query.getOrDefault("MaxRecords")
  valid_601108 = validateParameter(valid_601108, JInt, required = false, default = nil)
  if valid_601108 != nil:
    section.add "MaxRecords", valid_601108
  var valid_601109 = query.getOrDefault("Filters")
  valid_601109 = validateParameter(valid_601109, JArray, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "Filters", valid_601109
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601110 = query.getOrDefault("Action")
  valid_601110 = validateParameter(valid_601110, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_601110 != nil:
    section.add "Action", valid_601110
  var valid_601111 = query.getOrDefault("Marker")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "Marker", valid_601111
  var valid_601112 = query.getOrDefault("SubscriptionName")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "SubscriptionName", valid_601112
  var valid_601113 = query.getOrDefault("Version")
  valid_601113 = validateParameter(valid_601113, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601113 != nil:
    section.add "Version", valid_601113
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601114 = header.getOrDefault("X-Amz-Date")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Date", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Security-Token")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Security-Token", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Content-Sha256", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Algorithm")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Algorithm", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Signature")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Signature", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-SignedHeaders", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Credential")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Credential", valid_601120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601121: Call_GetDescribeEventSubscriptions_601105; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601121.validator(path, query, header, formData, body)
  let scheme = call_601121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601121.url(scheme.get, call_601121.host, call_601121.base,
                         call_601121.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601121, url, valid)

proc call*(call_601122: Call_GetDescribeEventSubscriptions_601105;
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
  var query_601123 = newJObject()
  add(query_601123, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601123.add "Filters", Filters
  add(query_601123, "Action", newJString(Action))
  add(query_601123, "Marker", newJString(Marker))
  add(query_601123, "SubscriptionName", newJString(SubscriptionName))
  add(query_601123, "Version", newJString(Version))
  result = call_601122.call(nil, query_601123, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_601105(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_601106, base: "/",
    url: url_GetDescribeEventSubscriptions_601107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_601168 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEvents_601170(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_601169(path: JsonNode; query: JsonNode;
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
  var valid_601171 = query.getOrDefault("Action")
  valid_601171 = validateParameter(valid_601171, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601171 != nil:
    section.add "Action", valid_601171
  var valid_601172 = query.getOrDefault("Version")
  valid_601172 = validateParameter(valid_601172, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601172 != nil:
    section.add "Version", valid_601172
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601173 = header.getOrDefault("X-Amz-Date")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "X-Amz-Date", valid_601173
  var valid_601174 = header.getOrDefault("X-Amz-Security-Token")
  valid_601174 = validateParameter(valid_601174, JString, required = false,
                                 default = nil)
  if valid_601174 != nil:
    section.add "X-Amz-Security-Token", valid_601174
  var valid_601175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Content-Sha256", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Algorithm")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Algorithm", valid_601176
  var valid_601177 = header.getOrDefault("X-Amz-Signature")
  valid_601177 = validateParameter(valid_601177, JString, required = false,
                                 default = nil)
  if valid_601177 != nil:
    section.add "X-Amz-Signature", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-SignedHeaders", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Credential")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Credential", valid_601179
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
  var valid_601180 = formData.getOrDefault("SourceIdentifier")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "SourceIdentifier", valid_601180
  var valid_601181 = formData.getOrDefault("EventCategories")
  valid_601181 = validateParameter(valid_601181, JArray, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "EventCategories", valid_601181
  var valid_601182 = formData.getOrDefault("Marker")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "Marker", valid_601182
  var valid_601183 = formData.getOrDefault("StartTime")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "StartTime", valid_601183
  var valid_601184 = formData.getOrDefault("Duration")
  valid_601184 = validateParameter(valid_601184, JInt, required = false, default = nil)
  if valid_601184 != nil:
    section.add "Duration", valid_601184
  var valid_601185 = formData.getOrDefault("Filters")
  valid_601185 = validateParameter(valid_601185, JArray, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "Filters", valid_601185
  var valid_601186 = formData.getOrDefault("EndTime")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "EndTime", valid_601186
  var valid_601187 = formData.getOrDefault("MaxRecords")
  valid_601187 = validateParameter(valid_601187, JInt, required = false, default = nil)
  if valid_601187 != nil:
    section.add "MaxRecords", valid_601187
  var valid_601188 = formData.getOrDefault("SourceType")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_601188 != nil:
    section.add "SourceType", valid_601188
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601189: Call_PostDescribeEvents_601168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601189.validator(path, query, header, formData, body)
  let scheme = call_601189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601189.url(scheme.get, call_601189.host, call_601189.base,
                         call_601189.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601189, url, valid)

proc call*(call_601190: Call_PostDescribeEvents_601168;
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
  var query_601191 = newJObject()
  var formData_601192 = newJObject()
  add(formData_601192, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_601192.add "EventCategories", EventCategories
  add(formData_601192, "Marker", newJString(Marker))
  add(formData_601192, "StartTime", newJString(StartTime))
  add(query_601191, "Action", newJString(Action))
  add(formData_601192, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_601192.add "Filters", Filters
  add(formData_601192, "EndTime", newJString(EndTime))
  add(formData_601192, "MaxRecords", newJInt(MaxRecords))
  add(query_601191, "Version", newJString(Version))
  add(formData_601192, "SourceType", newJString(SourceType))
  result = call_601190.call(nil, query_601191, nil, formData_601192, nil)

var postDescribeEvents* = Call_PostDescribeEvents_601168(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_601169, base: "/",
    url: url_PostDescribeEvents_601170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_601144 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEvents_601146(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_601145(path: JsonNode; query: JsonNode;
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
  var valid_601147 = query.getOrDefault("SourceType")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_601147 != nil:
    section.add "SourceType", valid_601147
  var valid_601148 = query.getOrDefault("MaxRecords")
  valid_601148 = validateParameter(valid_601148, JInt, required = false, default = nil)
  if valid_601148 != nil:
    section.add "MaxRecords", valid_601148
  var valid_601149 = query.getOrDefault("StartTime")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "StartTime", valid_601149
  var valid_601150 = query.getOrDefault("Filters")
  valid_601150 = validateParameter(valid_601150, JArray, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "Filters", valid_601150
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601151 = query.getOrDefault("Action")
  valid_601151 = validateParameter(valid_601151, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601151 != nil:
    section.add "Action", valid_601151
  var valid_601152 = query.getOrDefault("SourceIdentifier")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "SourceIdentifier", valid_601152
  var valid_601153 = query.getOrDefault("Marker")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "Marker", valid_601153
  var valid_601154 = query.getOrDefault("EventCategories")
  valid_601154 = validateParameter(valid_601154, JArray, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "EventCategories", valid_601154
  var valid_601155 = query.getOrDefault("Duration")
  valid_601155 = validateParameter(valid_601155, JInt, required = false, default = nil)
  if valid_601155 != nil:
    section.add "Duration", valid_601155
  var valid_601156 = query.getOrDefault("EndTime")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "EndTime", valid_601156
  var valid_601157 = query.getOrDefault("Version")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601157 != nil:
    section.add "Version", valid_601157
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601158 = header.getOrDefault("X-Amz-Date")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Date", valid_601158
  var valid_601159 = header.getOrDefault("X-Amz-Security-Token")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Security-Token", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Content-Sha256", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Algorithm")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Algorithm", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Signature")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Signature", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-SignedHeaders", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Credential")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Credential", valid_601164
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601165: Call_GetDescribeEvents_601144; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601165.validator(path, query, header, formData, body)
  let scheme = call_601165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601165.url(scheme.get, call_601165.host, call_601165.base,
                         call_601165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601165, url, valid)

proc call*(call_601166: Call_GetDescribeEvents_601144;
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
  var query_601167 = newJObject()
  add(query_601167, "SourceType", newJString(SourceType))
  add(query_601167, "MaxRecords", newJInt(MaxRecords))
  add(query_601167, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_601167.add "Filters", Filters
  add(query_601167, "Action", newJString(Action))
  add(query_601167, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601167, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_601167.add "EventCategories", EventCategories
  add(query_601167, "Duration", newJInt(Duration))
  add(query_601167, "EndTime", newJString(EndTime))
  add(query_601167, "Version", newJString(Version))
  result = call_601166.call(nil, query_601167, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_601144(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_601145,
    base: "/", url: url_GetDescribeEvents_601146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_601213 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOptionGroupOptions_601215(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_601214(path: JsonNode;
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
  var valid_601216 = query.getOrDefault("Action")
  valid_601216 = validateParameter(valid_601216, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_601216 != nil:
    section.add "Action", valid_601216
  var valid_601217 = query.getOrDefault("Version")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601217 != nil:
    section.add "Version", valid_601217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601218 = header.getOrDefault("X-Amz-Date")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-Date", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Security-Token")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Security-Token", valid_601219
  var valid_601220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Content-Sha256", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Algorithm")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Algorithm", valid_601221
  var valid_601222 = header.getOrDefault("X-Amz-Signature")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Signature", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-SignedHeaders", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Credential")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Credential", valid_601224
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601225 = formData.getOrDefault("MajorEngineVersion")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "MajorEngineVersion", valid_601225
  var valid_601226 = formData.getOrDefault("Marker")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "Marker", valid_601226
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_601227 = formData.getOrDefault("EngineName")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = nil)
  if valid_601227 != nil:
    section.add "EngineName", valid_601227
  var valid_601228 = formData.getOrDefault("Filters")
  valid_601228 = validateParameter(valid_601228, JArray, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "Filters", valid_601228
  var valid_601229 = formData.getOrDefault("MaxRecords")
  valid_601229 = validateParameter(valid_601229, JInt, required = false, default = nil)
  if valid_601229 != nil:
    section.add "MaxRecords", valid_601229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601230: Call_PostDescribeOptionGroupOptions_601213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601230.validator(path, query, header, formData, body)
  let scheme = call_601230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601230.url(scheme.get, call_601230.host, call_601230.base,
                         call_601230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601230, url, valid)

proc call*(call_601231: Call_PostDescribeOptionGroupOptions_601213;
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
  var query_601232 = newJObject()
  var formData_601233 = newJObject()
  add(formData_601233, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601233, "Marker", newJString(Marker))
  add(query_601232, "Action", newJString(Action))
  add(formData_601233, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_601233.add "Filters", Filters
  add(formData_601233, "MaxRecords", newJInt(MaxRecords))
  add(query_601232, "Version", newJString(Version))
  result = call_601231.call(nil, query_601232, nil, formData_601233, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_601213(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_601214, base: "/",
    url: url_PostDescribeOptionGroupOptions_601215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_601193 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOptionGroupOptions_601195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_601194(path: JsonNode; query: JsonNode;
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
  var valid_601196 = query.getOrDefault("MaxRecords")
  valid_601196 = validateParameter(valid_601196, JInt, required = false, default = nil)
  if valid_601196 != nil:
    section.add "MaxRecords", valid_601196
  var valid_601197 = query.getOrDefault("Filters")
  valid_601197 = validateParameter(valid_601197, JArray, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "Filters", valid_601197
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601198 = query.getOrDefault("Action")
  valid_601198 = validateParameter(valid_601198, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_601198 != nil:
    section.add "Action", valid_601198
  var valid_601199 = query.getOrDefault("Marker")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "Marker", valid_601199
  var valid_601200 = query.getOrDefault("Version")
  valid_601200 = validateParameter(valid_601200, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601200 != nil:
    section.add "Version", valid_601200
  var valid_601201 = query.getOrDefault("EngineName")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "EngineName", valid_601201
  var valid_601202 = query.getOrDefault("MajorEngineVersion")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "MajorEngineVersion", valid_601202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601203 = header.getOrDefault("X-Amz-Date")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Date", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Security-Token")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Security-Token", valid_601204
  var valid_601205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Content-Sha256", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Algorithm")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Algorithm", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Signature")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Signature", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-SignedHeaders", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Credential")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Credential", valid_601209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601210: Call_GetDescribeOptionGroupOptions_601193; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601210.validator(path, query, header, formData, body)
  let scheme = call_601210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601210.url(scheme.get, call_601210.host, call_601210.base,
                         call_601210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601210, url, valid)

proc call*(call_601211: Call_GetDescribeOptionGroupOptions_601193;
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
  var query_601212 = newJObject()
  add(query_601212, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601212.add "Filters", Filters
  add(query_601212, "Action", newJString(Action))
  add(query_601212, "Marker", newJString(Marker))
  add(query_601212, "Version", newJString(Version))
  add(query_601212, "EngineName", newJString(EngineName))
  add(query_601212, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601211.call(nil, query_601212, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_601193(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_601194, base: "/",
    url: url_GetDescribeOptionGroupOptions_601195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_601255 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOptionGroups_601257(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_601256(path: JsonNode; query: JsonNode;
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
  var valid_601258 = query.getOrDefault("Action")
  valid_601258 = validateParameter(valid_601258, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_601258 != nil:
    section.add "Action", valid_601258
  var valid_601259 = query.getOrDefault("Version")
  valid_601259 = validateParameter(valid_601259, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601259 != nil:
    section.add "Version", valid_601259
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601260 = header.getOrDefault("X-Amz-Date")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Date", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Security-Token")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Security-Token", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Content-Sha256", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Algorithm")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Algorithm", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Signature")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Signature", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-SignedHeaders", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Credential")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Credential", valid_601266
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601267 = formData.getOrDefault("MajorEngineVersion")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "MajorEngineVersion", valid_601267
  var valid_601268 = formData.getOrDefault("OptionGroupName")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "OptionGroupName", valid_601268
  var valid_601269 = formData.getOrDefault("Marker")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "Marker", valid_601269
  var valid_601270 = formData.getOrDefault("EngineName")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "EngineName", valid_601270
  var valid_601271 = formData.getOrDefault("Filters")
  valid_601271 = validateParameter(valid_601271, JArray, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "Filters", valid_601271
  var valid_601272 = formData.getOrDefault("MaxRecords")
  valid_601272 = validateParameter(valid_601272, JInt, required = false, default = nil)
  if valid_601272 != nil:
    section.add "MaxRecords", valid_601272
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601273: Call_PostDescribeOptionGroups_601255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601273.validator(path, query, header, formData, body)
  let scheme = call_601273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601273.url(scheme.get, call_601273.host, call_601273.base,
                         call_601273.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601273, url, valid)

proc call*(call_601274: Call_PostDescribeOptionGroups_601255;
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
  var query_601275 = newJObject()
  var formData_601276 = newJObject()
  add(formData_601276, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601276, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601276, "Marker", newJString(Marker))
  add(query_601275, "Action", newJString(Action))
  add(formData_601276, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_601276.add "Filters", Filters
  add(formData_601276, "MaxRecords", newJInt(MaxRecords))
  add(query_601275, "Version", newJString(Version))
  result = call_601274.call(nil, query_601275, nil, formData_601276, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_601255(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_601256, base: "/",
    url: url_PostDescribeOptionGroups_601257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_601234 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOptionGroups_601236(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_601235(path: JsonNode; query: JsonNode;
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
  var valid_601237 = query.getOrDefault("MaxRecords")
  valid_601237 = validateParameter(valid_601237, JInt, required = false, default = nil)
  if valid_601237 != nil:
    section.add "MaxRecords", valid_601237
  var valid_601238 = query.getOrDefault("OptionGroupName")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "OptionGroupName", valid_601238
  var valid_601239 = query.getOrDefault("Filters")
  valid_601239 = validateParameter(valid_601239, JArray, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "Filters", valid_601239
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601240 = query.getOrDefault("Action")
  valid_601240 = validateParameter(valid_601240, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_601240 != nil:
    section.add "Action", valid_601240
  var valid_601241 = query.getOrDefault("Marker")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "Marker", valid_601241
  var valid_601242 = query.getOrDefault("Version")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601242 != nil:
    section.add "Version", valid_601242
  var valid_601243 = query.getOrDefault("EngineName")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "EngineName", valid_601243
  var valid_601244 = query.getOrDefault("MajorEngineVersion")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "MajorEngineVersion", valid_601244
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601245 = header.getOrDefault("X-Amz-Date")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Date", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Security-Token")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Security-Token", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Content-Sha256", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Algorithm")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Algorithm", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Signature")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Signature", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-SignedHeaders", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Credential")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Credential", valid_601251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601252: Call_GetDescribeOptionGroups_601234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601252.validator(path, query, header, formData, body)
  let scheme = call_601252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601252.url(scheme.get, call_601252.host, call_601252.base,
                         call_601252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601252, url, valid)

proc call*(call_601253: Call_GetDescribeOptionGroups_601234; MaxRecords: int = 0;
          OptionGroupName: string = ""; Filters: JsonNode = nil;
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
  var query_601254 = newJObject()
  add(query_601254, "MaxRecords", newJInt(MaxRecords))
  add(query_601254, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_601254.add "Filters", Filters
  add(query_601254, "Action", newJString(Action))
  add(query_601254, "Marker", newJString(Marker))
  add(query_601254, "Version", newJString(Version))
  add(query_601254, "EngineName", newJString(EngineName))
  add(query_601254, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601253.call(nil, query_601254, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_601234(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_601235, base: "/",
    url: url_GetDescribeOptionGroups_601236, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_601300 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOrderableDBInstanceOptions_601302(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_601301(path: JsonNode;
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
  var valid_601303 = query.getOrDefault("Action")
  valid_601303 = validateParameter(valid_601303, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_601303 != nil:
    section.add "Action", valid_601303
  var valid_601304 = query.getOrDefault("Version")
  valid_601304 = validateParameter(valid_601304, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601304 != nil:
    section.add "Version", valid_601304
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601305 = header.getOrDefault("X-Amz-Date")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Date", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Security-Token")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Security-Token", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Content-Sha256", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Algorithm")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Algorithm", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Signature")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Signature", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-SignedHeaders", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Credential")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Credential", valid_601311
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
  var valid_601312 = formData.getOrDefault("Engine")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = nil)
  if valid_601312 != nil:
    section.add "Engine", valid_601312
  var valid_601313 = formData.getOrDefault("Marker")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "Marker", valid_601313
  var valid_601314 = formData.getOrDefault("Vpc")
  valid_601314 = validateParameter(valid_601314, JBool, required = false, default = nil)
  if valid_601314 != nil:
    section.add "Vpc", valid_601314
  var valid_601315 = formData.getOrDefault("DBInstanceClass")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "DBInstanceClass", valid_601315
  var valid_601316 = formData.getOrDefault("Filters")
  valid_601316 = validateParameter(valid_601316, JArray, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "Filters", valid_601316
  var valid_601317 = formData.getOrDefault("LicenseModel")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "LicenseModel", valid_601317
  var valid_601318 = formData.getOrDefault("MaxRecords")
  valid_601318 = validateParameter(valid_601318, JInt, required = false, default = nil)
  if valid_601318 != nil:
    section.add "MaxRecords", valid_601318
  var valid_601319 = formData.getOrDefault("EngineVersion")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "EngineVersion", valid_601319
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601320: Call_PostDescribeOrderableDBInstanceOptions_601300;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601320.validator(path, query, header, formData, body)
  let scheme = call_601320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601320.url(scheme.get, call_601320.host, call_601320.base,
                         call_601320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601320, url, valid)

proc call*(call_601321: Call_PostDescribeOrderableDBInstanceOptions_601300;
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
  var query_601322 = newJObject()
  var formData_601323 = newJObject()
  add(formData_601323, "Engine", newJString(Engine))
  add(formData_601323, "Marker", newJString(Marker))
  add(query_601322, "Action", newJString(Action))
  add(formData_601323, "Vpc", newJBool(Vpc))
  add(formData_601323, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_601323.add "Filters", Filters
  add(formData_601323, "LicenseModel", newJString(LicenseModel))
  add(formData_601323, "MaxRecords", newJInt(MaxRecords))
  add(formData_601323, "EngineVersion", newJString(EngineVersion))
  add(query_601322, "Version", newJString(Version))
  result = call_601321.call(nil, query_601322, nil, formData_601323, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_601300(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_601301, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_601302,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_601277 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOrderableDBInstanceOptions_601279(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_601278(path: JsonNode;
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
  var valid_601280 = query.getOrDefault("Engine")
  valid_601280 = validateParameter(valid_601280, JString, required = true,
                                 default = nil)
  if valid_601280 != nil:
    section.add "Engine", valid_601280
  var valid_601281 = query.getOrDefault("MaxRecords")
  valid_601281 = validateParameter(valid_601281, JInt, required = false, default = nil)
  if valid_601281 != nil:
    section.add "MaxRecords", valid_601281
  var valid_601282 = query.getOrDefault("Filters")
  valid_601282 = validateParameter(valid_601282, JArray, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "Filters", valid_601282
  var valid_601283 = query.getOrDefault("LicenseModel")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "LicenseModel", valid_601283
  var valid_601284 = query.getOrDefault("Vpc")
  valid_601284 = validateParameter(valid_601284, JBool, required = false, default = nil)
  if valid_601284 != nil:
    section.add "Vpc", valid_601284
  var valid_601285 = query.getOrDefault("DBInstanceClass")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "DBInstanceClass", valid_601285
  var valid_601286 = query.getOrDefault("Action")
  valid_601286 = validateParameter(valid_601286, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_601286 != nil:
    section.add "Action", valid_601286
  var valid_601287 = query.getOrDefault("Marker")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "Marker", valid_601287
  var valid_601288 = query.getOrDefault("EngineVersion")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "EngineVersion", valid_601288
  var valid_601289 = query.getOrDefault("Version")
  valid_601289 = validateParameter(valid_601289, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601289 != nil:
    section.add "Version", valid_601289
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601290 = header.getOrDefault("X-Amz-Date")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Date", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Security-Token")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Security-Token", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Content-Sha256", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Algorithm")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Algorithm", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Signature")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Signature", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-SignedHeaders", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Credential")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Credential", valid_601296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601297: Call_GetDescribeOrderableDBInstanceOptions_601277;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601297.validator(path, query, header, formData, body)
  let scheme = call_601297.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601297.url(scheme.get, call_601297.host, call_601297.base,
                         call_601297.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601297, url, valid)

proc call*(call_601298: Call_GetDescribeOrderableDBInstanceOptions_601277;
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
  var query_601299 = newJObject()
  add(query_601299, "Engine", newJString(Engine))
  add(query_601299, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601299.add "Filters", Filters
  add(query_601299, "LicenseModel", newJString(LicenseModel))
  add(query_601299, "Vpc", newJBool(Vpc))
  add(query_601299, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601299, "Action", newJString(Action))
  add(query_601299, "Marker", newJString(Marker))
  add(query_601299, "EngineVersion", newJString(EngineVersion))
  add(query_601299, "Version", newJString(Version))
  result = call_601298.call(nil, query_601299, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_601277(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_601278, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_601279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_601349 = ref object of OpenApiRestCall_599352
proc url_PostDescribeReservedDBInstances_601351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_601350(path: JsonNode;
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
  var valid_601352 = query.getOrDefault("Action")
  valid_601352 = validateParameter(valid_601352, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_601352 != nil:
    section.add "Action", valid_601352
  var valid_601353 = query.getOrDefault("Version")
  valid_601353 = validateParameter(valid_601353, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601353 != nil:
    section.add "Version", valid_601353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601354 = header.getOrDefault("X-Amz-Date")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Date", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Security-Token")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Security-Token", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Content-Sha256", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Algorithm")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Algorithm", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Signature")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Signature", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-SignedHeaders", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Credential")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Credential", valid_601360
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
  var valid_601361 = formData.getOrDefault("OfferingType")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "OfferingType", valid_601361
  var valid_601362 = formData.getOrDefault("ReservedDBInstanceId")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "ReservedDBInstanceId", valid_601362
  var valid_601363 = formData.getOrDefault("Marker")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "Marker", valid_601363
  var valid_601364 = formData.getOrDefault("MultiAZ")
  valid_601364 = validateParameter(valid_601364, JBool, required = false, default = nil)
  if valid_601364 != nil:
    section.add "MultiAZ", valid_601364
  var valid_601365 = formData.getOrDefault("Duration")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "Duration", valid_601365
  var valid_601366 = formData.getOrDefault("DBInstanceClass")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "DBInstanceClass", valid_601366
  var valid_601367 = formData.getOrDefault("Filters")
  valid_601367 = validateParameter(valid_601367, JArray, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "Filters", valid_601367
  var valid_601368 = formData.getOrDefault("ProductDescription")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "ProductDescription", valid_601368
  var valid_601369 = formData.getOrDefault("MaxRecords")
  valid_601369 = validateParameter(valid_601369, JInt, required = false, default = nil)
  if valid_601369 != nil:
    section.add "MaxRecords", valid_601369
  var valid_601370 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601370
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601371: Call_PostDescribeReservedDBInstances_601349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601371.validator(path, query, header, formData, body)
  let scheme = call_601371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601371.url(scheme.get, call_601371.host, call_601371.base,
                         call_601371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601371, url, valid)

proc call*(call_601372: Call_PostDescribeReservedDBInstances_601349;
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
  var query_601373 = newJObject()
  var formData_601374 = newJObject()
  add(formData_601374, "OfferingType", newJString(OfferingType))
  add(formData_601374, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_601374, "Marker", newJString(Marker))
  add(formData_601374, "MultiAZ", newJBool(MultiAZ))
  add(query_601373, "Action", newJString(Action))
  add(formData_601374, "Duration", newJString(Duration))
  add(formData_601374, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_601374.add "Filters", Filters
  add(formData_601374, "ProductDescription", newJString(ProductDescription))
  add(formData_601374, "MaxRecords", newJInt(MaxRecords))
  add(formData_601374, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601373, "Version", newJString(Version))
  result = call_601372.call(nil, query_601373, nil, formData_601374, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_601349(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_601350, base: "/",
    url: url_PostDescribeReservedDBInstances_601351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_601324 = ref object of OpenApiRestCall_599352
proc url_GetDescribeReservedDBInstances_601326(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_601325(path: JsonNode;
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
  var valid_601327 = query.getOrDefault("ProductDescription")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "ProductDescription", valid_601327
  var valid_601328 = query.getOrDefault("MaxRecords")
  valid_601328 = validateParameter(valid_601328, JInt, required = false, default = nil)
  if valid_601328 != nil:
    section.add "MaxRecords", valid_601328
  var valid_601329 = query.getOrDefault("OfferingType")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "OfferingType", valid_601329
  var valid_601330 = query.getOrDefault("Filters")
  valid_601330 = validateParameter(valid_601330, JArray, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "Filters", valid_601330
  var valid_601331 = query.getOrDefault("MultiAZ")
  valid_601331 = validateParameter(valid_601331, JBool, required = false, default = nil)
  if valid_601331 != nil:
    section.add "MultiAZ", valid_601331
  var valid_601332 = query.getOrDefault("ReservedDBInstanceId")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "ReservedDBInstanceId", valid_601332
  var valid_601333 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601333
  var valid_601334 = query.getOrDefault("DBInstanceClass")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "DBInstanceClass", valid_601334
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601335 = query.getOrDefault("Action")
  valid_601335 = validateParameter(valid_601335, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_601335 != nil:
    section.add "Action", valid_601335
  var valid_601336 = query.getOrDefault("Marker")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "Marker", valid_601336
  var valid_601337 = query.getOrDefault("Duration")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "Duration", valid_601337
  var valid_601338 = query.getOrDefault("Version")
  valid_601338 = validateParameter(valid_601338, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601338 != nil:
    section.add "Version", valid_601338
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601339 = header.getOrDefault("X-Amz-Date")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Date", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Security-Token")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Security-Token", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Content-Sha256", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Algorithm")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Algorithm", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Signature")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Signature", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-SignedHeaders", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Credential")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Credential", valid_601345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601346: Call_GetDescribeReservedDBInstances_601324; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601346.validator(path, query, header, formData, body)
  let scheme = call_601346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601346.url(scheme.get, call_601346.host, call_601346.base,
                         call_601346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601346, url, valid)

proc call*(call_601347: Call_GetDescribeReservedDBInstances_601324;
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
  var query_601348 = newJObject()
  add(query_601348, "ProductDescription", newJString(ProductDescription))
  add(query_601348, "MaxRecords", newJInt(MaxRecords))
  add(query_601348, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_601348.add "Filters", Filters
  add(query_601348, "MultiAZ", newJBool(MultiAZ))
  add(query_601348, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_601348, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601348, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601348, "Action", newJString(Action))
  add(query_601348, "Marker", newJString(Marker))
  add(query_601348, "Duration", newJString(Duration))
  add(query_601348, "Version", newJString(Version))
  result = call_601347.call(nil, query_601348, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_601324(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_601325, base: "/",
    url: url_GetDescribeReservedDBInstances_601326,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_601399 = ref object of OpenApiRestCall_599352
proc url_PostDescribeReservedDBInstancesOfferings_601401(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_601400(path: JsonNode;
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
  var valid_601402 = query.getOrDefault("Action")
  valid_601402 = validateParameter(valid_601402, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_601402 != nil:
    section.add "Action", valid_601402
  var valid_601403 = query.getOrDefault("Version")
  valid_601403 = validateParameter(valid_601403, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601403 != nil:
    section.add "Version", valid_601403
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601404 = header.getOrDefault("X-Amz-Date")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Date", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Security-Token")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Security-Token", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-Content-Sha256", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Algorithm")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Algorithm", valid_601407
  var valid_601408 = header.getOrDefault("X-Amz-Signature")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Signature", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-SignedHeaders", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Credential")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Credential", valid_601410
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
  var valid_601411 = formData.getOrDefault("OfferingType")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "OfferingType", valid_601411
  var valid_601412 = formData.getOrDefault("Marker")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "Marker", valid_601412
  var valid_601413 = formData.getOrDefault("MultiAZ")
  valid_601413 = validateParameter(valid_601413, JBool, required = false, default = nil)
  if valid_601413 != nil:
    section.add "MultiAZ", valid_601413
  var valid_601414 = formData.getOrDefault("Duration")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "Duration", valid_601414
  var valid_601415 = formData.getOrDefault("DBInstanceClass")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "DBInstanceClass", valid_601415
  var valid_601416 = formData.getOrDefault("Filters")
  valid_601416 = validateParameter(valid_601416, JArray, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "Filters", valid_601416
  var valid_601417 = formData.getOrDefault("ProductDescription")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "ProductDescription", valid_601417
  var valid_601418 = formData.getOrDefault("MaxRecords")
  valid_601418 = validateParameter(valid_601418, JInt, required = false, default = nil)
  if valid_601418 != nil:
    section.add "MaxRecords", valid_601418
  var valid_601419 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601419
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601420: Call_PostDescribeReservedDBInstancesOfferings_601399;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601420.validator(path, query, header, formData, body)
  let scheme = call_601420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601420.url(scheme.get, call_601420.host, call_601420.base,
                         call_601420.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601420, url, valid)

proc call*(call_601421: Call_PostDescribeReservedDBInstancesOfferings_601399;
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
  var query_601422 = newJObject()
  var formData_601423 = newJObject()
  add(formData_601423, "OfferingType", newJString(OfferingType))
  add(formData_601423, "Marker", newJString(Marker))
  add(formData_601423, "MultiAZ", newJBool(MultiAZ))
  add(query_601422, "Action", newJString(Action))
  add(formData_601423, "Duration", newJString(Duration))
  add(formData_601423, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_601423.add "Filters", Filters
  add(formData_601423, "ProductDescription", newJString(ProductDescription))
  add(formData_601423, "MaxRecords", newJInt(MaxRecords))
  add(formData_601423, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601422, "Version", newJString(Version))
  result = call_601421.call(nil, query_601422, nil, formData_601423, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_601399(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_601400,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_601401,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_601375 = ref object of OpenApiRestCall_599352
proc url_GetDescribeReservedDBInstancesOfferings_601377(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_601376(path: JsonNode;
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
  var valid_601378 = query.getOrDefault("ProductDescription")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "ProductDescription", valid_601378
  var valid_601379 = query.getOrDefault("MaxRecords")
  valid_601379 = validateParameter(valid_601379, JInt, required = false, default = nil)
  if valid_601379 != nil:
    section.add "MaxRecords", valid_601379
  var valid_601380 = query.getOrDefault("OfferingType")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "OfferingType", valid_601380
  var valid_601381 = query.getOrDefault("Filters")
  valid_601381 = validateParameter(valid_601381, JArray, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "Filters", valid_601381
  var valid_601382 = query.getOrDefault("MultiAZ")
  valid_601382 = validateParameter(valid_601382, JBool, required = false, default = nil)
  if valid_601382 != nil:
    section.add "MultiAZ", valid_601382
  var valid_601383 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601383
  var valid_601384 = query.getOrDefault("DBInstanceClass")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "DBInstanceClass", valid_601384
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601385 = query.getOrDefault("Action")
  valid_601385 = validateParameter(valid_601385, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_601385 != nil:
    section.add "Action", valid_601385
  var valid_601386 = query.getOrDefault("Marker")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "Marker", valid_601386
  var valid_601387 = query.getOrDefault("Duration")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "Duration", valid_601387
  var valid_601388 = query.getOrDefault("Version")
  valid_601388 = validateParameter(valid_601388, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601388 != nil:
    section.add "Version", valid_601388
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601389 = header.getOrDefault("X-Amz-Date")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Date", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Security-Token")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Security-Token", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Content-Sha256", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Algorithm")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Algorithm", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Signature")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Signature", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-SignedHeaders", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Credential")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Credential", valid_601395
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601396: Call_GetDescribeReservedDBInstancesOfferings_601375;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601396.validator(path, query, header, formData, body)
  let scheme = call_601396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601396.url(scheme.get, call_601396.host, call_601396.base,
                         call_601396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601396, url, valid)

proc call*(call_601397: Call_GetDescribeReservedDBInstancesOfferings_601375;
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
  var query_601398 = newJObject()
  add(query_601398, "ProductDescription", newJString(ProductDescription))
  add(query_601398, "MaxRecords", newJInt(MaxRecords))
  add(query_601398, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_601398.add "Filters", Filters
  add(query_601398, "MultiAZ", newJBool(MultiAZ))
  add(query_601398, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601398, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601398, "Action", newJString(Action))
  add(query_601398, "Marker", newJString(Marker))
  add(query_601398, "Duration", newJString(Duration))
  add(query_601398, "Version", newJString(Version))
  result = call_601397.call(nil, query_601398, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_601375(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_601376, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_601377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_601443 = ref object of OpenApiRestCall_599352
proc url_PostDownloadDBLogFilePortion_601445(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_601444(path: JsonNode; query: JsonNode;
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
  var valid_601446 = query.getOrDefault("Action")
  valid_601446 = validateParameter(valid_601446, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_601446 != nil:
    section.add "Action", valid_601446
  var valid_601447 = query.getOrDefault("Version")
  valid_601447 = validateParameter(valid_601447, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601447 != nil:
    section.add "Version", valid_601447
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601448 = header.getOrDefault("X-Amz-Date")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Date", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Security-Token")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Security-Token", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Content-Sha256", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Algorithm")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Algorithm", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Signature")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Signature", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-SignedHeaders", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Credential")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Credential", valid_601454
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_601455 = formData.getOrDefault("NumberOfLines")
  valid_601455 = validateParameter(valid_601455, JInt, required = false, default = nil)
  if valid_601455 != nil:
    section.add "NumberOfLines", valid_601455
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601456 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601456 = validateParameter(valid_601456, JString, required = true,
                                 default = nil)
  if valid_601456 != nil:
    section.add "DBInstanceIdentifier", valid_601456
  var valid_601457 = formData.getOrDefault("Marker")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "Marker", valid_601457
  var valid_601458 = formData.getOrDefault("LogFileName")
  valid_601458 = validateParameter(valid_601458, JString, required = true,
                                 default = nil)
  if valid_601458 != nil:
    section.add "LogFileName", valid_601458
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601459: Call_PostDownloadDBLogFilePortion_601443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601459.validator(path, query, header, formData, body)
  let scheme = call_601459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601459.url(scheme.get, call_601459.host, call_601459.base,
                         call_601459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601459, url, valid)

proc call*(call_601460: Call_PostDownloadDBLogFilePortion_601443;
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
  var query_601461 = newJObject()
  var formData_601462 = newJObject()
  add(formData_601462, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_601462, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601462, "Marker", newJString(Marker))
  add(query_601461, "Action", newJString(Action))
  add(formData_601462, "LogFileName", newJString(LogFileName))
  add(query_601461, "Version", newJString(Version))
  result = call_601460.call(nil, query_601461, nil, formData_601462, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_601443(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_601444, base: "/",
    url: url_PostDownloadDBLogFilePortion_601445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_601424 = ref object of OpenApiRestCall_599352
proc url_GetDownloadDBLogFilePortion_601426(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_601425(path: JsonNode; query: JsonNode;
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
  var valid_601427 = query.getOrDefault("NumberOfLines")
  valid_601427 = validateParameter(valid_601427, JInt, required = false, default = nil)
  if valid_601427 != nil:
    section.add "NumberOfLines", valid_601427
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_601428 = query.getOrDefault("LogFileName")
  valid_601428 = validateParameter(valid_601428, JString, required = true,
                                 default = nil)
  if valid_601428 != nil:
    section.add "LogFileName", valid_601428
  var valid_601429 = query.getOrDefault("Action")
  valid_601429 = validateParameter(valid_601429, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_601429 != nil:
    section.add "Action", valid_601429
  var valid_601430 = query.getOrDefault("Marker")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "Marker", valid_601430
  var valid_601431 = query.getOrDefault("Version")
  valid_601431 = validateParameter(valid_601431, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601431 != nil:
    section.add "Version", valid_601431
  var valid_601432 = query.getOrDefault("DBInstanceIdentifier")
  valid_601432 = validateParameter(valid_601432, JString, required = true,
                                 default = nil)
  if valid_601432 != nil:
    section.add "DBInstanceIdentifier", valid_601432
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601433 = header.getOrDefault("X-Amz-Date")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Date", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Security-Token")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Security-Token", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Content-Sha256", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Algorithm")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Algorithm", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Signature")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Signature", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-SignedHeaders", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Credential")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Credential", valid_601439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601440: Call_GetDownloadDBLogFilePortion_601424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601440.validator(path, query, header, formData, body)
  let scheme = call_601440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601440.url(scheme.get, call_601440.host, call_601440.base,
                         call_601440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601440, url, valid)

proc call*(call_601441: Call_GetDownloadDBLogFilePortion_601424;
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
  var query_601442 = newJObject()
  add(query_601442, "NumberOfLines", newJInt(NumberOfLines))
  add(query_601442, "LogFileName", newJString(LogFileName))
  add(query_601442, "Action", newJString(Action))
  add(query_601442, "Marker", newJString(Marker))
  add(query_601442, "Version", newJString(Version))
  add(query_601442, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601441.call(nil, query_601442, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_601424(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_601425, base: "/",
    url: url_GetDownloadDBLogFilePortion_601426,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_601480 = ref object of OpenApiRestCall_599352
proc url_PostListTagsForResource_601482(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_601481(path: JsonNode; query: JsonNode;
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
  var valid_601483 = query.getOrDefault("Action")
  valid_601483 = validateParameter(valid_601483, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601483 != nil:
    section.add "Action", valid_601483
  var valid_601484 = query.getOrDefault("Version")
  valid_601484 = validateParameter(valid_601484, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601484 != nil:
    section.add "Version", valid_601484
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601485 = header.getOrDefault("X-Amz-Date")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Date", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Security-Token")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Security-Token", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Content-Sha256", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Algorithm")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Algorithm", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Signature")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Signature", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-SignedHeaders", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-Credential")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-Credential", valid_601491
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_601492 = formData.getOrDefault("Filters")
  valid_601492 = validateParameter(valid_601492, JArray, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "Filters", valid_601492
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_601493 = formData.getOrDefault("ResourceName")
  valid_601493 = validateParameter(valid_601493, JString, required = true,
                                 default = nil)
  if valid_601493 != nil:
    section.add "ResourceName", valid_601493
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601494: Call_PostListTagsForResource_601480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601494.validator(path, query, header, formData, body)
  let scheme = call_601494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601494.url(scheme.get, call_601494.host, call_601494.base,
                         call_601494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601494, url, valid)

proc call*(call_601495: Call_PostListTagsForResource_601480; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601496 = newJObject()
  var formData_601497 = newJObject()
  add(query_601496, "Action", newJString(Action))
  if Filters != nil:
    formData_601497.add "Filters", Filters
  add(formData_601497, "ResourceName", newJString(ResourceName))
  add(query_601496, "Version", newJString(Version))
  result = call_601495.call(nil, query_601496, nil, formData_601497, nil)

var postListTagsForResource* = Call_PostListTagsForResource_601480(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_601481, base: "/",
    url: url_PostListTagsForResource_601482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_601463 = ref object of OpenApiRestCall_599352
proc url_GetListTagsForResource_601465(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_601464(path: JsonNode; query: JsonNode;
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
  var valid_601466 = query.getOrDefault("Filters")
  valid_601466 = validateParameter(valid_601466, JArray, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "Filters", valid_601466
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_601467 = query.getOrDefault("ResourceName")
  valid_601467 = validateParameter(valid_601467, JString, required = true,
                                 default = nil)
  if valid_601467 != nil:
    section.add "ResourceName", valid_601467
  var valid_601468 = query.getOrDefault("Action")
  valid_601468 = validateParameter(valid_601468, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601468 != nil:
    section.add "Action", valid_601468
  var valid_601469 = query.getOrDefault("Version")
  valid_601469 = validateParameter(valid_601469, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601469 != nil:
    section.add "Version", valid_601469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601470 = header.getOrDefault("X-Amz-Date")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Date", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Security-Token")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Security-Token", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Content-Sha256", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Algorithm")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Algorithm", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Signature")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Signature", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-SignedHeaders", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Credential")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Credential", valid_601476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601477: Call_GetListTagsForResource_601463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601477.validator(path, query, header, formData, body)
  let scheme = call_601477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601477.url(scheme.get, call_601477.host, call_601477.base,
                         call_601477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601477, url, valid)

proc call*(call_601478: Call_GetListTagsForResource_601463; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601479 = newJObject()
  if Filters != nil:
    query_601479.add "Filters", Filters
  add(query_601479, "ResourceName", newJString(ResourceName))
  add(query_601479, "Action", newJString(Action))
  add(query_601479, "Version", newJString(Version))
  result = call_601478.call(nil, query_601479, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_601463(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_601464, base: "/",
    url: url_GetListTagsForResource_601465, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_601531 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBInstance_601533(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_601532(path: JsonNode; query: JsonNode;
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
  var valid_601534 = query.getOrDefault("Action")
  valid_601534 = validateParameter(valid_601534, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601534 != nil:
    section.add "Action", valid_601534
  var valid_601535 = query.getOrDefault("Version")
  valid_601535 = validateParameter(valid_601535, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601535 != nil:
    section.add "Version", valid_601535
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601536 = header.getOrDefault("X-Amz-Date")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Date", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Security-Token")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Security-Token", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Content-Sha256", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Algorithm")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Algorithm", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Signature")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Signature", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-SignedHeaders", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Credential")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Credential", valid_601542
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
  var valid_601543 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "PreferredMaintenanceWindow", valid_601543
  var valid_601544 = formData.getOrDefault("DBSecurityGroups")
  valid_601544 = validateParameter(valid_601544, JArray, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "DBSecurityGroups", valid_601544
  var valid_601545 = formData.getOrDefault("ApplyImmediately")
  valid_601545 = validateParameter(valid_601545, JBool, required = false, default = nil)
  if valid_601545 != nil:
    section.add "ApplyImmediately", valid_601545
  var valid_601546 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601546 = validateParameter(valid_601546, JArray, required = false,
                                 default = nil)
  if valid_601546 != nil:
    section.add "VpcSecurityGroupIds", valid_601546
  var valid_601547 = formData.getOrDefault("Iops")
  valid_601547 = validateParameter(valid_601547, JInt, required = false, default = nil)
  if valid_601547 != nil:
    section.add "Iops", valid_601547
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601548 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601548 = validateParameter(valid_601548, JString, required = true,
                                 default = nil)
  if valid_601548 != nil:
    section.add "DBInstanceIdentifier", valid_601548
  var valid_601549 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601549 = validateParameter(valid_601549, JInt, required = false, default = nil)
  if valid_601549 != nil:
    section.add "BackupRetentionPeriod", valid_601549
  var valid_601550 = formData.getOrDefault("DBParameterGroupName")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "DBParameterGroupName", valid_601550
  var valid_601551 = formData.getOrDefault("OptionGroupName")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "OptionGroupName", valid_601551
  var valid_601552 = formData.getOrDefault("MasterUserPassword")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "MasterUserPassword", valid_601552
  var valid_601553 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "NewDBInstanceIdentifier", valid_601553
  var valid_601554 = formData.getOrDefault("MultiAZ")
  valid_601554 = validateParameter(valid_601554, JBool, required = false, default = nil)
  if valid_601554 != nil:
    section.add "MultiAZ", valid_601554
  var valid_601555 = formData.getOrDefault("AllocatedStorage")
  valid_601555 = validateParameter(valid_601555, JInt, required = false, default = nil)
  if valid_601555 != nil:
    section.add "AllocatedStorage", valid_601555
  var valid_601556 = formData.getOrDefault("DBInstanceClass")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "DBInstanceClass", valid_601556
  var valid_601557 = formData.getOrDefault("PreferredBackupWindow")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "PreferredBackupWindow", valid_601557
  var valid_601558 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601558 = validateParameter(valid_601558, JBool, required = false, default = nil)
  if valid_601558 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601558
  var valid_601559 = formData.getOrDefault("EngineVersion")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "EngineVersion", valid_601559
  var valid_601560 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_601560 = validateParameter(valid_601560, JBool, required = false, default = nil)
  if valid_601560 != nil:
    section.add "AllowMajorVersionUpgrade", valid_601560
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601561: Call_PostModifyDBInstance_601531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601561.validator(path, query, header, formData, body)
  let scheme = call_601561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601561.url(scheme.get, call_601561.host, call_601561.base,
                         call_601561.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601561, url, valid)

proc call*(call_601562: Call_PostModifyDBInstance_601531;
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
  var query_601563 = newJObject()
  var formData_601564 = newJObject()
  add(formData_601564, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_601564.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601564, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_601564.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601564, "Iops", newJInt(Iops))
  add(formData_601564, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601564, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601564, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601564, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601564, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601564, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_601564, "MultiAZ", newJBool(MultiAZ))
  add(query_601563, "Action", newJString(Action))
  add(formData_601564, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601564, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601564, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601564, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601564, "EngineVersion", newJString(EngineVersion))
  add(query_601563, "Version", newJString(Version))
  add(formData_601564, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_601562.call(nil, query_601563, nil, formData_601564, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_601531(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_601532, base: "/",
    url: url_PostModifyDBInstance_601533, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_601498 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBInstance_601500(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_601499(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_601501 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "PreferredMaintenanceWindow", valid_601501
  var valid_601502 = query.getOrDefault("AllocatedStorage")
  valid_601502 = validateParameter(valid_601502, JInt, required = false, default = nil)
  if valid_601502 != nil:
    section.add "AllocatedStorage", valid_601502
  var valid_601503 = query.getOrDefault("OptionGroupName")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "OptionGroupName", valid_601503
  var valid_601504 = query.getOrDefault("DBSecurityGroups")
  valid_601504 = validateParameter(valid_601504, JArray, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "DBSecurityGroups", valid_601504
  var valid_601505 = query.getOrDefault("MasterUserPassword")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "MasterUserPassword", valid_601505
  var valid_601506 = query.getOrDefault("Iops")
  valid_601506 = validateParameter(valid_601506, JInt, required = false, default = nil)
  if valid_601506 != nil:
    section.add "Iops", valid_601506
  var valid_601507 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601507 = validateParameter(valid_601507, JArray, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "VpcSecurityGroupIds", valid_601507
  var valid_601508 = query.getOrDefault("MultiAZ")
  valid_601508 = validateParameter(valid_601508, JBool, required = false, default = nil)
  if valid_601508 != nil:
    section.add "MultiAZ", valid_601508
  var valid_601509 = query.getOrDefault("BackupRetentionPeriod")
  valid_601509 = validateParameter(valid_601509, JInt, required = false, default = nil)
  if valid_601509 != nil:
    section.add "BackupRetentionPeriod", valid_601509
  var valid_601510 = query.getOrDefault("DBParameterGroupName")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "DBParameterGroupName", valid_601510
  var valid_601511 = query.getOrDefault("DBInstanceClass")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "DBInstanceClass", valid_601511
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601512 = query.getOrDefault("Action")
  valid_601512 = validateParameter(valid_601512, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601512 != nil:
    section.add "Action", valid_601512
  var valid_601513 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_601513 = validateParameter(valid_601513, JBool, required = false, default = nil)
  if valid_601513 != nil:
    section.add "AllowMajorVersionUpgrade", valid_601513
  var valid_601514 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "NewDBInstanceIdentifier", valid_601514
  var valid_601515 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601515 = validateParameter(valid_601515, JBool, required = false, default = nil)
  if valid_601515 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601515
  var valid_601516 = query.getOrDefault("EngineVersion")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "EngineVersion", valid_601516
  var valid_601517 = query.getOrDefault("PreferredBackupWindow")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "PreferredBackupWindow", valid_601517
  var valid_601518 = query.getOrDefault("Version")
  valid_601518 = validateParameter(valid_601518, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601518 != nil:
    section.add "Version", valid_601518
  var valid_601519 = query.getOrDefault("DBInstanceIdentifier")
  valid_601519 = validateParameter(valid_601519, JString, required = true,
                                 default = nil)
  if valid_601519 != nil:
    section.add "DBInstanceIdentifier", valid_601519
  var valid_601520 = query.getOrDefault("ApplyImmediately")
  valid_601520 = validateParameter(valid_601520, JBool, required = false, default = nil)
  if valid_601520 != nil:
    section.add "ApplyImmediately", valid_601520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601521 = header.getOrDefault("X-Amz-Date")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Date", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Security-Token")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Security-Token", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-Content-Sha256", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Algorithm")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Algorithm", valid_601524
  var valid_601525 = header.getOrDefault("X-Amz-Signature")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Signature", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-SignedHeaders", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Credential")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Credential", valid_601527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601528: Call_GetModifyDBInstance_601498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601528.validator(path, query, header, formData, body)
  let scheme = call_601528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601528.url(scheme.get, call_601528.host, call_601528.base,
                         call_601528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601528, url, valid)

proc call*(call_601529: Call_GetModifyDBInstance_601498;
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
  var query_601530 = newJObject()
  add(query_601530, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601530, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601530, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601530.add "DBSecurityGroups", DBSecurityGroups
  add(query_601530, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601530, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601530.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601530, "MultiAZ", newJBool(MultiAZ))
  add(query_601530, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601530, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601530, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601530, "Action", newJString(Action))
  add(query_601530, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_601530, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_601530, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601530, "EngineVersion", newJString(EngineVersion))
  add(query_601530, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601530, "Version", newJString(Version))
  add(query_601530, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601530, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_601529.call(nil, query_601530, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_601498(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_601499, base: "/",
    url: url_GetModifyDBInstance_601500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_601582 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBParameterGroup_601584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_601583(path: JsonNode; query: JsonNode;
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
  var valid_601585 = query.getOrDefault("Action")
  valid_601585 = validateParameter(valid_601585, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_601585 != nil:
    section.add "Action", valid_601585
  var valid_601586 = query.getOrDefault("Version")
  valid_601586 = validateParameter(valid_601586, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601586 != nil:
    section.add "Version", valid_601586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601587 = header.getOrDefault("X-Amz-Date")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Date", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Security-Token")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Security-Token", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Content-Sha256", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-Algorithm")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-Algorithm", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Signature")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Signature", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-SignedHeaders", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Credential")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Credential", valid_601593
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601594 = formData.getOrDefault("DBParameterGroupName")
  valid_601594 = validateParameter(valid_601594, JString, required = true,
                                 default = nil)
  if valid_601594 != nil:
    section.add "DBParameterGroupName", valid_601594
  var valid_601595 = formData.getOrDefault("Parameters")
  valid_601595 = validateParameter(valid_601595, JArray, required = true, default = nil)
  if valid_601595 != nil:
    section.add "Parameters", valid_601595
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601596: Call_PostModifyDBParameterGroup_601582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601596.validator(path, query, header, formData, body)
  let scheme = call_601596.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601596.url(scheme.get, call_601596.host, call_601596.base,
                         call_601596.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601596, url, valid)

proc call*(call_601597: Call_PostModifyDBParameterGroup_601582;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601598 = newJObject()
  var formData_601599 = newJObject()
  add(formData_601599, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_601599.add "Parameters", Parameters
  add(query_601598, "Action", newJString(Action))
  add(query_601598, "Version", newJString(Version))
  result = call_601597.call(nil, query_601598, nil, formData_601599, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_601582(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_601583, base: "/",
    url: url_PostModifyDBParameterGroup_601584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_601565 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBParameterGroup_601567(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_601566(path: JsonNode; query: JsonNode;
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
  var valid_601568 = query.getOrDefault("DBParameterGroupName")
  valid_601568 = validateParameter(valid_601568, JString, required = true,
                                 default = nil)
  if valid_601568 != nil:
    section.add "DBParameterGroupName", valid_601568
  var valid_601569 = query.getOrDefault("Parameters")
  valid_601569 = validateParameter(valid_601569, JArray, required = true, default = nil)
  if valid_601569 != nil:
    section.add "Parameters", valid_601569
  var valid_601570 = query.getOrDefault("Action")
  valid_601570 = validateParameter(valid_601570, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_601570 != nil:
    section.add "Action", valid_601570
  var valid_601571 = query.getOrDefault("Version")
  valid_601571 = validateParameter(valid_601571, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601571 != nil:
    section.add "Version", valid_601571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601572 = header.getOrDefault("X-Amz-Date")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Date", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Security-Token")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Security-Token", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Content-Sha256", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-Algorithm")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-Algorithm", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Signature")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Signature", valid_601576
  var valid_601577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601577 = validateParameter(valid_601577, JString, required = false,
                                 default = nil)
  if valid_601577 != nil:
    section.add "X-Amz-SignedHeaders", valid_601577
  var valid_601578 = header.getOrDefault("X-Amz-Credential")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Credential", valid_601578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601579: Call_GetModifyDBParameterGroup_601565; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601579.validator(path, query, header, formData, body)
  let scheme = call_601579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601579.url(scheme.get, call_601579.host, call_601579.base,
                         call_601579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601579, url, valid)

proc call*(call_601580: Call_GetModifyDBParameterGroup_601565;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601581 = newJObject()
  add(query_601581, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_601581.add "Parameters", Parameters
  add(query_601581, "Action", newJString(Action))
  add(query_601581, "Version", newJString(Version))
  result = call_601580.call(nil, query_601581, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_601565(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_601566, base: "/",
    url: url_GetModifyDBParameterGroup_601567,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_601618 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBSubnetGroup_601620(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_601619(path: JsonNode; query: JsonNode;
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
  var valid_601621 = query.getOrDefault("Action")
  valid_601621 = validateParameter(valid_601621, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601621 != nil:
    section.add "Action", valid_601621
  var valid_601622 = query.getOrDefault("Version")
  valid_601622 = validateParameter(valid_601622, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601622 != nil:
    section.add "Version", valid_601622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601623 = header.getOrDefault("X-Amz-Date")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Date", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Security-Token")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Security-Token", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Content-Sha256", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Algorithm")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Algorithm", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Signature")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Signature", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-SignedHeaders", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-Credential")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-Credential", valid_601629
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601630 = formData.getOrDefault("DBSubnetGroupName")
  valid_601630 = validateParameter(valid_601630, JString, required = true,
                                 default = nil)
  if valid_601630 != nil:
    section.add "DBSubnetGroupName", valid_601630
  var valid_601631 = formData.getOrDefault("SubnetIds")
  valid_601631 = validateParameter(valid_601631, JArray, required = true, default = nil)
  if valid_601631 != nil:
    section.add "SubnetIds", valid_601631
  var valid_601632 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "DBSubnetGroupDescription", valid_601632
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601633: Call_PostModifyDBSubnetGroup_601618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601633.validator(path, query, header, formData, body)
  let scheme = call_601633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601633.url(scheme.get, call_601633.host, call_601633.base,
                         call_601633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601633, url, valid)

proc call*(call_601634: Call_PostModifyDBSubnetGroup_601618;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_601635 = newJObject()
  var formData_601636 = newJObject()
  add(formData_601636, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601636.add "SubnetIds", SubnetIds
  add(query_601635, "Action", newJString(Action))
  add(formData_601636, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601635, "Version", newJString(Version))
  result = call_601634.call(nil, query_601635, nil, formData_601636, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_601618(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_601619, base: "/",
    url: url_PostModifyDBSubnetGroup_601620, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_601600 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBSubnetGroup_601602(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_601601(path: JsonNode; query: JsonNode;
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
  var valid_601603 = query.getOrDefault("Action")
  valid_601603 = validateParameter(valid_601603, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601603 != nil:
    section.add "Action", valid_601603
  var valid_601604 = query.getOrDefault("DBSubnetGroupName")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = nil)
  if valid_601604 != nil:
    section.add "DBSubnetGroupName", valid_601604
  var valid_601605 = query.getOrDefault("SubnetIds")
  valid_601605 = validateParameter(valid_601605, JArray, required = true, default = nil)
  if valid_601605 != nil:
    section.add "SubnetIds", valid_601605
  var valid_601606 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "DBSubnetGroupDescription", valid_601606
  var valid_601607 = query.getOrDefault("Version")
  valid_601607 = validateParameter(valid_601607, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601607 != nil:
    section.add "Version", valid_601607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601608 = header.getOrDefault("X-Amz-Date")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Date", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Security-Token")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Security-Token", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Content-Sha256", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Algorithm")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Algorithm", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Signature")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Signature", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-SignedHeaders", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-Credential")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-Credential", valid_601614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601615: Call_GetModifyDBSubnetGroup_601600; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601615.validator(path, query, header, formData, body)
  let scheme = call_601615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601615.url(scheme.get, call_601615.host, call_601615.base,
                         call_601615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601615, url, valid)

proc call*(call_601616: Call_GetModifyDBSubnetGroup_601600;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_601617 = newJObject()
  add(query_601617, "Action", newJString(Action))
  add(query_601617, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601617.add "SubnetIds", SubnetIds
  add(query_601617, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601617, "Version", newJString(Version))
  result = call_601616.call(nil, query_601617, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_601600(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_601601, base: "/",
    url: url_GetModifyDBSubnetGroup_601602, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_601657 = ref object of OpenApiRestCall_599352
proc url_PostModifyEventSubscription_601659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_601658(path: JsonNode; query: JsonNode;
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
  var valid_601660 = query.getOrDefault("Action")
  valid_601660 = validateParameter(valid_601660, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_601660 != nil:
    section.add "Action", valid_601660
  var valid_601661 = query.getOrDefault("Version")
  valid_601661 = validateParameter(valid_601661, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601661 != nil:
    section.add "Version", valid_601661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601662 = header.getOrDefault("X-Amz-Date")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Date", valid_601662
  var valid_601663 = header.getOrDefault("X-Amz-Security-Token")
  valid_601663 = validateParameter(valid_601663, JString, required = false,
                                 default = nil)
  if valid_601663 != nil:
    section.add "X-Amz-Security-Token", valid_601663
  var valid_601664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601664 = validateParameter(valid_601664, JString, required = false,
                                 default = nil)
  if valid_601664 != nil:
    section.add "X-Amz-Content-Sha256", valid_601664
  var valid_601665 = header.getOrDefault("X-Amz-Algorithm")
  valid_601665 = validateParameter(valid_601665, JString, required = false,
                                 default = nil)
  if valid_601665 != nil:
    section.add "X-Amz-Algorithm", valid_601665
  var valid_601666 = header.getOrDefault("X-Amz-Signature")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "X-Amz-Signature", valid_601666
  var valid_601667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-SignedHeaders", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Credential")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Credential", valid_601668
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_601669 = formData.getOrDefault("Enabled")
  valid_601669 = validateParameter(valid_601669, JBool, required = false, default = nil)
  if valid_601669 != nil:
    section.add "Enabled", valid_601669
  var valid_601670 = formData.getOrDefault("EventCategories")
  valid_601670 = validateParameter(valid_601670, JArray, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "EventCategories", valid_601670
  var valid_601671 = formData.getOrDefault("SnsTopicArn")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "SnsTopicArn", valid_601671
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601672 = formData.getOrDefault("SubscriptionName")
  valid_601672 = validateParameter(valid_601672, JString, required = true,
                                 default = nil)
  if valid_601672 != nil:
    section.add "SubscriptionName", valid_601672
  var valid_601673 = formData.getOrDefault("SourceType")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "SourceType", valid_601673
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601674: Call_PostModifyEventSubscription_601657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601674.validator(path, query, header, formData, body)
  let scheme = call_601674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601674.url(scheme.get, call_601674.host, call_601674.base,
                         call_601674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601674, url, valid)

proc call*(call_601675: Call_PostModifyEventSubscription_601657;
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
  var query_601676 = newJObject()
  var formData_601677 = newJObject()
  add(formData_601677, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601677.add "EventCategories", EventCategories
  add(formData_601677, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_601677, "SubscriptionName", newJString(SubscriptionName))
  add(query_601676, "Action", newJString(Action))
  add(query_601676, "Version", newJString(Version))
  add(formData_601677, "SourceType", newJString(SourceType))
  result = call_601675.call(nil, query_601676, nil, formData_601677, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_601657(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_601658, base: "/",
    url: url_PostModifyEventSubscription_601659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_601637 = ref object of OpenApiRestCall_599352
proc url_GetModifyEventSubscription_601639(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_601638(path: JsonNode; query: JsonNode;
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
  var valid_601640 = query.getOrDefault("SourceType")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "SourceType", valid_601640
  var valid_601641 = query.getOrDefault("Enabled")
  valid_601641 = validateParameter(valid_601641, JBool, required = false, default = nil)
  if valid_601641 != nil:
    section.add "Enabled", valid_601641
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601642 = query.getOrDefault("Action")
  valid_601642 = validateParameter(valid_601642, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_601642 != nil:
    section.add "Action", valid_601642
  var valid_601643 = query.getOrDefault("SnsTopicArn")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "SnsTopicArn", valid_601643
  var valid_601644 = query.getOrDefault("EventCategories")
  valid_601644 = validateParameter(valid_601644, JArray, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "EventCategories", valid_601644
  var valid_601645 = query.getOrDefault("SubscriptionName")
  valid_601645 = validateParameter(valid_601645, JString, required = true,
                                 default = nil)
  if valid_601645 != nil:
    section.add "SubscriptionName", valid_601645
  var valid_601646 = query.getOrDefault("Version")
  valid_601646 = validateParameter(valid_601646, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601646 != nil:
    section.add "Version", valid_601646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601647 = header.getOrDefault("X-Amz-Date")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Date", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Security-Token")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Security-Token", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Content-Sha256", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Algorithm")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Algorithm", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Signature")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Signature", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-SignedHeaders", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Credential")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Credential", valid_601653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601654: Call_GetModifyEventSubscription_601637; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601654.validator(path, query, header, formData, body)
  let scheme = call_601654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601654.url(scheme.get, call_601654.host, call_601654.base,
                         call_601654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601654, url, valid)

proc call*(call_601655: Call_GetModifyEventSubscription_601637;
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
  var query_601656 = newJObject()
  add(query_601656, "SourceType", newJString(SourceType))
  add(query_601656, "Enabled", newJBool(Enabled))
  add(query_601656, "Action", newJString(Action))
  add(query_601656, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601656.add "EventCategories", EventCategories
  add(query_601656, "SubscriptionName", newJString(SubscriptionName))
  add(query_601656, "Version", newJString(Version))
  result = call_601655.call(nil, query_601656, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_601637(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_601638, base: "/",
    url: url_GetModifyEventSubscription_601639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_601697 = ref object of OpenApiRestCall_599352
proc url_PostModifyOptionGroup_601699(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_601698(path: JsonNode; query: JsonNode;
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
  var valid_601700 = query.getOrDefault("Action")
  valid_601700 = validateParameter(valid_601700, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_601700 != nil:
    section.add "Action", valid_601700
  var valid_601701 = query.getOrDefault("Version")
  valid_601701 = validateParameter(valid_601701, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601701 != nil:
    section.add "Version", valid_601701
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601702 = header.getOrDefault("X-Amz-Date")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Date", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Security-Token")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Security-Token", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Content-Sha256", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Algorithm")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Algorithm", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Signature")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Signature", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-SignedHeaders", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Credential")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Credential", valid_601708
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_601709 = formData.getOrDefault("OptionsToRemove")
  valid_601709 = validateParameter(valid_601709, JArray, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "OptionsToRemove", valid_601709
  var valid_601710 = formData.getOrDefault("ApplyImmediately")
  valid_601710 = validateParameter(valid_601710, JBool, required = false, default = nil)
  if valid_601710 != nil:
    section.add "ApplyImmediately", valid_601710
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601711 = formData.getOrDefault("OptionGroupName")
  valid_601711 = validateParameter(valid_601711, JString, required = true,
                                 default = nil)
  if valid_601711 != nil:
    section.add "OptionGroupName", valid_601711
  var valid_601712 = formData.getOrDefault("OptionsToInclude")
  valid_601712 = validateParameter(valid_601712, JArray, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "OptionsToInclude", valid_601712
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601713: Call_PostModifyOptionGroup_601697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601713.validator(path, query, header, formData, body)
  let scheme = call_601713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601713.url(scheme.get, call_601713.host, call_601713.base,
                         call_601713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601713, url, valid)

proc call*(call_601714: Call_PostModifyOptionGroup_601697; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601715 = newJObject()
  var formData_601716 = newJObject()
  if OptionsToRemove != nil:
    formData_601716.add "OptionsToRemove", OptionsToRemove
  add(formData_601716, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_601716, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_601716.add "OptionsToInclude", OptionsToInclude
  add(query_601715, "Action", newJString(Action))
  add(query_601715, "Version", newJString(Version))
  result = call_601714.call(nil, query_601715, nil, formData_601716, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_601697(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_601698, base: "/",
    url: url_PostModifyOptionGroup_601699, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_601678 = ref object of OpenApiRestCall_599352
proc url_GetModifyOptionGroup_601680(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_601679(path: JsonNode; query: JsonNode;
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
  var valid_601681 = query.getOrDefault("OptionGroupName")
  valid_601681 = validateParameter(valid_601681, JString, required = true,
                                 default = nil)
  if valid_601681 != nil:
    section.add "OptionGroupName", valid_601681
  var valid_601682 = query.getOrDefault("OptionsToRemove")
  valid_601682 = validateParameter(valid_601682, JArray, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "OptionsToRemove", valid_601682
  var valid_601683 = query.getOrDefault("Action")
  valid_601683 = validateParameter(valid_601683, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_601683 != nil:
    section.add "Action", valid_601683
  var valid_601684 = query.getOrDefault("Version")
  valid_601684 = validateParameter(valid_601684, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601684 != nil:
    section.add "Version", valid_601684
  var valid_601685 = query.getOrDefault("ApplyImmediately")
  valid_601685 = validateParameter(valid_601685, JBool, required = false, default = nil)
  if valid_601685 != nil:
    section.add "ApplyImmediately", valid_601685
  var valid_601686 = query.getOrDefault("OptionsToInclude")
  valid_601686 = validateParameter(valid_601686, JArray, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "OptionsToInclude", valid_601686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601687 = header.getOrDefault("X-Amz-Date")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Date", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Security-Token")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Security-Token", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Content-Sha256", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Algorithm")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Algorithm", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Signature")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Signature", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-SignedHeaders", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Credential")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Credential", valid_601693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601694: Call_GetModifyOptionGroup_601678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601694.validator(path, query, header, formData, body)
  let scheme = call_601694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601694.url(scheme.get, call_601694.host, call_601694.base,
                         call_601694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601694, url, valid)

proc call*(call_601695: Call_GetModifyOptionGroup_601678; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-09-09"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_601696 = newJObject()
  add(query_601696, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_601696.add "OptionsToRemove", OptionsToRemove
  add(query_601696, "Action", newJString(Action))
  add(query_601696, "Version", newJString(Version))
  add(query_601696, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_601696.add "OptionsToInclude", OptionsToInclude
  result = call_601695.call(nil, query_601696, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_601678(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_601679, base: "/",
    url: url_GetModifyOptionGroup_601680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_601735 = ref object of OpenApiRestCall_599352
proc url_PostPromoteReadReplica_601737(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_601736(path: JsonNode; query: JsonNode;
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
  var valid_601738 = query.getOrDefault("Action")
  valid_601738 = validateParameter(valid_601738, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_601738 != nil:
    section.add "Action", valid_601738
  var valid_601739 = query.getOrDefault("Version")
  valid_601739 = validateParameter(valid_601739, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601739 != nil:
    section.add "Version", valid_601739
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601740 = header.getOrDefault("X-Amz-Date")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Date", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Security-Token")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Security-Token", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Content-Sha256", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Algorithm")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Algorithm", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Signature")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Signature", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-SignedHeaders", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Credential")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Credential", valid_601746
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601747 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601747 = validateParameter(valid_601747, JString, required = true,
                                 default = nil)
  if valid_601747 != nil:
    section.add "DBInstanceIdentifier", valid_601747
  var valid_601748 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601748 = validateParameter(valid_601748, JInt, required = false, default = nil)
  if valid_601748 != nil:
    section.add "BackupRetentionPeriod", valid_601748
  var valid_601749 = formData.getOrDefault("PreferredBackupWindow")
  valid_601749 = validateParameter(valid_601749, JString, required = false,
                                 default = nil)
  if valid_601749 != nil:
    section.add "PreferredBackupWindow", valid_601749
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601750: Call_PostPromoteReadReplica_601735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601750.validator(path, query, header, formData, body)
  let scheme = call_601750.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601750.url(scheme.get, call_601750.host, call_601750.base,
                         call_601750.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601750, url, valid)

proc call*(call_601751: Call_PostPromoteReadReplica_601735;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_601752 = newJObject()
  var formData_601753 = newJObject()
  add(formData_601753, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601753, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601752, "Action", newJString(Action))
  add(formData_601753, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601752, "Version", newJString(Version))
  result = call_601751.call(nil, query_601752, nil, formData_601753, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_601735(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_601736, base: "/",
    url: url_PostPromoteReadReplica_601737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_601717 = ref object of OpenApiRestCall_599352
proc url_GetPromoteReadReplica_601719(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_601718(path: JsonNode; query: JsonNode;
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
  var valid_601720 = query.getOrDefault("BackupRetentionPeriod")
  valid_601720 = validateParameter(valid_601720, JInt, required = false, default = nil)
  if valid_601720 != nil:
    section.add "BackupRetentionPeriod", valid_601720
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601721 = query.getOrDefault("Action")
  valid_601721 = validateParameter(valid_601721, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_601721 != nil:
    section.add "Action", valid_601721
  var valid_601722 = query.getOrDefault("PreferredBackupWindow")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "PreferredBackupWindow", valid_601722
  var valid_601723 = query.getOrDefault("Version")
  valid_601723 = validateParameter(valid_601723, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601723 != nil:
    section.add "Version", valid_601723
  var valid_601724 = query.getOrDefault("DBInstanceIdentifier")
  valid_601724 = validateParameter(valid_601724, JString, required = true,
                                 default = nil)
  if valid_601724 != nil:
    section.add "DBInstanceIdentifier", valid_601724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601725 = header.getOrDefault("X-Amz-Date")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Date", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Security-Token")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Security-Token", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Content-Sha256", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Algorithm")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Algorithm", valid_601728
  var valid_601729 = header.getOrDefault("X-Amz-Signature")
  valid_601729 = validateParameter(valid_601729, JString, required = false,
                                 default = nil)
  if valid_601729 != nil:
    section.add "X-Amz-Signature", valid_601729
  var valid_601730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-SignedHeaders", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Credential")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Credential", valid_601731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601732: Call_GetPromoteReadReplica_601717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601732.validator(path, query, header, formData, body)
  let scheme = call_601732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601732.url(scheme.get, call_601732.host, call_601732.base,
                         call_601732.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601732, url, valid)

proc call*(call_601733: Call_GetPromoteReadReplica_601717;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601734 = newJObject()
  add(query_601734, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601734, "Action", newJString(Action))
  add(query_601734, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601734, "Version", newJString(Version))
  add(query_601734, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601733.call(nil, query_601734, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_601717(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_601718, base: "/",
    url: url_GetPromoteReadReplica_601719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_601773 = ref object of OpenApiRestCall_599352
proc url_PostPurchaseReservedDBInstancesOffering_601775(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_601774(path: JsonNode;
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
  var valid_601776 = query.getOrDefault("Action")
  valid_601776 = validateParameter(valid_601776, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_601776 != nil:
    section.add "Action", valid_601776
  var valid_601777 = query.getOrDefault("Version")
  valid_601777 = validateParameter(valid_601777, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601777 != nil:
    section.add "Version", valid_601777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601778 = header.getOrDefault("X-Amz-Date")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Date", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Security-Token")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Security-Token", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Content-Sha256", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Algorithm")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Algorithm", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-Signature")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-Signature", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-SignedHeaders", valid_601783
  var valid_601784 = header.getOrDefault("X-Amz-Credential")
  valid_601784 = validateParameter(valid_601784, JString, required = false,
                                 default = nil)
  if valid_601784 != nil:
    section.add "X-Amz-Credential", valid_601784
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_601785 = formData.getOrDefault("ReservedDBInstanceId")
  valid_601785 = validateParameter(valid_601785, JString, required = false,
                                 default = nil)
  if valid_601785 != nil:
    section.add "ReservedDBInstanceId", valid_601785
  var valid_601786 = formData.getOrDefault("Tags")
  valid_601786 = validateParameter(valid_601786, JArray, required = false,
                                 default = nil)
  if valid_601786 != nil:
    section.add "Tags", valid_601786
  var valid_601787 = formData.getOrDefault("DBInstanceCount")
  valid_601787 = validateParameter(valid_601787, JInt, required = false, default = nil)
  if valid_601787 != nil:
    section.add "DBInstanceCount", valid_601787
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_601788 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601788 = validateParameter(valid_601788, JString, required = true,
                                 default = nil)
  if valid_601788 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601788
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601789: Call_PostPurchaseReservedDBInstancesOffering_601773;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601789.validator(path, query, header, formData, body)
  let scheme = call_601789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601789.url(scheme.get, call_601789.host, call_601789.base,
                         call_601789.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601789, url, valid)

proc call*(call_601790: Call_PostPurchaseReservedDBInstancesOffering_601773;
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
  var query_601791 = newJObject()
  var formData_601792 = newJObject()
  add(formData_601792, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_601792.add "Tags", Tags
  add(formData_601792, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_601791, "Action", newJString(Action))
  add(formData_601792, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601791, "Version", newJString(Version))
  result = call_601790.call(nil, query_601791, nil, formData_601792, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_601773(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_601774, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_601775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_601754 = ref object of OpenApiRestCall_599352
proc url_GetPurchaseReservedDBInstancesOffering_601756(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_601755(path: JsonNode;
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
  var valid_601757 = query.getOrDefault("DBInstanceCount")
  valid_601757 = validateParameter(valid_601757, JInt, required = false, default = nil)
  if valid_601757 != nil:
    section.add "DBInstanceCount", valid_601757
  var valid_601758 = query.getOrDefault("Tags")
  valid_601758 = validateParameter(valid_601758, JArray, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "Tags", valid_601758
  var valid_601759 = query.getOrDefault("ReservedDBInstanceId")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "ReservedDBInstanceId", valid_601759
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_601760 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601760 = validateParameter(valid_601760, JString, required = true,
                                 default = nil)
  if valid_601760 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601760
  var valid_601761 = query.getOrDefault("Action")
  valid_601761 = validateParameter(valid_601761, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_601761 != nil:
    section.add "Action", valid_601761
  var valid_601762 = query.getOrDefault("Version")
  valid_601762 = validateParameter(valid_601762, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601762 != nil:
    section.add "Version", valid_601762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601763 = header.getOrDefault("X-Amz-Date")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Date", valid_601763
  var valid_601764 = header.getOrDefault("X-Amz-Security-Token")
  valid_601764 = validateParameter(valid_601764, JString, required = false,
                                 default = nil)
  if valid_601764 != nil:
    section.add "X-Amz-Security-Token", valid_601764
  var valid_601765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "X-Amz-Content-Sha256", valid_601765
  var valid_601766 = header.getOrDefault("X-Amz-Algorithm")
  valid_601766 = validateParameter(valid_601766, JString, required = false,
                                 default = nil)
  if valid_601766 != nil:
    section.add "X-Amz-Algorithm", valid_601766
  var valid_601767 = header.getOrDefault("X-Amz-Signature")
  valid_601767 = validateParameter(valid_601767, JString, required = false,
                                 default = nil)
  if valid_601767 != nil:
    section.add "X-Amz-Signature", valid_601767
  var valid_601768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "X-Amz-SignedHeaders", valid_601768
  var valid_601769 = header.getOrDefault("X-Amz-Credential")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "X-Amz-Credential", valid_601769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601770: Call_GetPurchaseReservedDBInstancesOffering_601754;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601770.validator(path, query, header, formData, body)
  let scheme = call_601770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601770.url(scheme.get, call_601770.host, call_601770.base,
                         call_601770.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601770, url, valid)

proc call*(call_601771: Call_GetPurchaseReservedDBInstancesOffering_601754;
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
  var query_601772 = newJObject()
  add(query_601772, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_601772.add "Tags", Tags
  add(query_601772, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_601772, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601772, "Action", newJString(Action))
  add(query_601772, "Version", newJString(Version))
  result = call_601771.call(nil, query_601772, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_601754(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_601755, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_601756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_601810 = ref object of OpenApiRestCall_599352
proc url_PostRebootDBInstance_601812(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_601811(path: JsonNode; query: JsonNode;
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
  var valid_601813 = query.getOrDefault("Action")
  valid_601813 = validateParameter(valid_601813, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601813 != nil:
    section.add "Action", valid_601813
  var valid_601814 = query.getOrDefault("Version")
  valid_601814 = validateParameter(valid_601814, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601814 != nil:
    section.add "Version", valid_601814
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601815 = header.getOrDefault("X-Amz-Date")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Date", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-Security-Token")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Security-Token", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-Content-Sha256", valid_601817
  var valid_601818 = header.getOrDefault("X-Amz-Algorithm")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Algorithm", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Signature")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Signature", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-SignedHeaders", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Credential")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Credential", valid_601821
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601822 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601822 = validateParameter(valid_601822, JString, required = true,
                                 default = nil)
  if valid_601822 != nil:
    section.add "DBInstanceIdentifier", valid_601822
  var valid_601823 = formData.getOrDefault("ForceFailover")
  valid_601823 = validateParameter(valid_601823, JBool, required = false, default = nil)
  if valid_601823 != nil:
    section.add "ForceFailover", valid_601823
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601824: Call_PostRebootDBInstance_601810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601824.validator(path, query, header, formData, body)
  let scheme = call_601824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601824.url(scheme.get, call_601824.host, call_601824.base,
                         call_601824.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601824, url, valid)

proc call*(call_601825: Call_PostRebootDBInstance_601810;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_601826 = newJObject()
  var formData_601827 = newJObject()
  add(formData_601827, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601826, "Action", newJString(Action))
  add(formData_601827, "ForceFailover", newJBool(ForceFailover))
  add(query_601826, "Version", newJString(Version))
  result = call_601825.call(nil, query_601826, nil, formData_601827, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_601810(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_601811, base: "/",
    url: url_PostRebootDBInstance_601812, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_601793 = ref object of OpenApiRestCall_599352
proc url_GetRebootDBInstance_601795(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_601794(path: JsonNode; query: JsonNode;
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
  var valid_601796 = query.getOrDefault("Action")
  valid_601796 = validateParameter(valid_601796, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601796 != nil:
    section.add "Action", valid_601796
  var valid_601797 = query.getOrDefault("ForceFailover")
  valid_601797 = validateParameter(valid_601797, JBool, required = false, default = nil)
  if valid_601797 != nil:
    section.add "ForceFailover", valid_601797
  var valid_601798 = query.getOrDefault("Version")
  valid_601798 = validateParameter(valid_601798, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601798 != nil:
    section.add "Version", valid_601798
  var valid_601799 = query.getOrDefault("DBInstanceIdentifier")
  valid_601799 = validateParameter(valid_601799, JString, required = true,
                                 default = nil)
  if valid_601799 != nil:
    section.add "DBInstanceIdentifier", valid_601799
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601800 = header.getOrDefault("X-Amz-Date")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-Date", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Security-Token")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Security-Token", valid_601801
  var valid_601802 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601802 = validateParameter(valid_601802, JString, required = false,
                                 default = nil)
  if valid_601802 != nil:
    section.add "X-Amz-Content-Sha256", valid_601802
  var valid_601803 = header.getOrDefault("X-Amz-Algorithm")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-Algorithm", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Signature")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Signature", valid_601804
  var valid_601805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-SignedHeaders", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-Credential")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Credential", valid_601806
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601807: Call_GetRebootDBInstance_601793; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601807.validator(path, query, header, formData, body)
  let scheme = call_601807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601807.url(scheme.get, call_601807.host, call_601807.base,
                         call_601807.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601807, url, valid)

proc call*(call_601808: Call_GetRebootDBInstance_601793;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601809 = newJObject()
  add(query_601809, "Action", newJString(Action))
  add(query_601809, "ForceFailover", newJBool(ForceFailover))
  add(query_601809, "Version", newJString(Version))
  add(query_601809, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601808.call(nil, query_601809, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_601793(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_601794, base: "/",
    url: url_GetRebootDBInstance_601795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_601845 = ref object of OpenApiRestCall_599352
proc url_PostRemoveSourceIdentifierFromSubscription_601847(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_601846(path: JsonNode;
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
  var valid_601848 = query.getOrDefault("Action")
  valid_601848 = validateParameter(valid_601848, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_601848 != nil:
    section.add "Action", valid_601848
  var valid_601849 = query.getOrDefault("Version")
  valid_601849 = validateParameter(valid_601849, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601849 != nil:
    section.add "Version", valid_601849
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601850 = header.getOrDefault("X-Amz-Date")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Date", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Security-Token")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Security-Token", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Content-Sha256", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Algorithm")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Algorithm", valid_601853
  var valid_601854 = header.getOrDefault("X-Amz-Signature")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "X-Amz-Signature", valid_601854
  var valid_601855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "X-Amz-SignedHeaders", valid_601855
  var valid_601856 = header.getOrDefault("X-Amz-Credential")
  valid_601856 = validateParameter(valid_601856, JString, required = false,
                                 default = nil)
  if valid_601856 != nil:
    section.add "X-Amz-Credential", valid_601856
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_601857 = formData.getOrDefault("SourceIdentifier")
  valid_601857 = validateParameter(valid_601857, JString, required = true,
                                 default = nil)
  if valid_601857 != nil:
    section.add "SourceIdentifier", valid_601857
  var valid_601858 = formData.getOrDefault("SubscriptionName")
  valid_601858 = validateParameter(valid_601858, JString, required = true,
                                 default = nil)
  if valid_601858 != nil:
    section.add "SubscriptionName", valid_601858
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601859: Call_PostRemoveSourceIdentifierFromSubscription_601845;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601859.validator(path, query, header, formData, body)
  let scheme = call_601859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601859.url(scheme.get, call_601859.host, call_601859.base,
                         call_601859.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601859, url, valid)

proc call*(call_601860: Call_PostRemoveSourceIdentifierFromSubscription_601845;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601861 = newJObject()
  var formData_601862 = newJObject()
  add(formData_601862, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_601862, "SubscriptionName", newJString(SubscriptionName))
  add(query_601861, "Action", newJString(Action))
  add(query_601861, "Version", newJString(Version))
  result = call_601860.call(nil, query_601861, nil, formData_601862, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_601845(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_601846,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_601847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_601828 = ref object of OpenApiRestCall_599352
proc url_GetRemoveSourceIdentifierFromSubscription_601830(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_601829(path: JsonNode;
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
  var valid_601831 = query.getOrDefault("Action")
  valid_601831 = validateParameter(valid_601831, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_601831 != nil:
    section.add "Action", valid_601831
  var valid_601832 = query.getOrDefault("SourceIdentifier")
  valid_601832 = validateParameter(valid_601832, JString, required = true,
                                 default = nil)
  if valid_601832 != nil:
    section.add "SourceIdentifier", valid_601832
  var valid_601833 = query.getOrDefault("SubscriptionName")
  valid_601833 = validateParameter(valid_601833, JString, required = true,
                                 default = nil)
  if valid_601833 != nil:
    section.add "SubscriptionName", valid_601833
  var valid_601834 = query.getOrDefault("Version")
  valid_601834 = validateParameter(valid_601834, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601834 != nil:
    section.add "Version", valid_601834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601835 = header.getOrDefault("X-Amz-Date")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Date", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Security-Token")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Security-Token", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Content-Sha256", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Algorithm")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Algorithm", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Signature")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Signature", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-SignedHeaders", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-Credential")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-Credential", valid_601841
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601842: Call_GetRemoveSourceIdentifierFromSubscription_601828;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601842.validator(path, query, header, formData, body)
  let scheme = call_601842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601842.url(scheme.get, call_601842.host, call_601842.base,
                         call_601842.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601842, url, valid)

proc call*(call_601843: Call_GetRemoveSourceIdentifierFromSubscription_601828;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601844 = newJObject()
  add(query_601844, "Action", newJString(Action))
  add(query_601844, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601844, "SubscriptionName", newJString(SubscriptionName))
  add(query_601844, "Version", newJString(Version))
  result = call_601843.call(nil, query_601844, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_601828(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_601829,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_601830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_601880 = ref object of OpenApiRestCall_599352
proc url_PostRemoveTagsFromResource_601882(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_601881(path: JsonNode; query: JsonNode;
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
  var valid_601883 = query.getOrDefault("Action")
  valid_601883 = validateParameter(valid_601883, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601883 != nil:
    section.add "Action", valid_601883
  var valid_601884 = query.getOrDefault("Version")
  valid_601884 = validateParameter(valid_601884, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601884 != nil:
    section.add "Version", valid_601884
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601885 = header.getOrDefault("X-Amz-Date")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "X-Amz-Date", valid_601885
  var valid_601886 = header.getOrDefault("X-Amz-Security-Token")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "X-Amz-Security-Token", valid_601886
  var valid_601887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "X-Amz-Content-Sha256", valid_601887
  var valid_601888 = header.getOrDefault("X-Amz-Algorithm")
  valid_601888 = validateParameter(valid_601888, JString, required = false,
                                 default = nil)
  if valid_601888 != nil:
    section.add "X-Amz-Algorithm", valid_601888
  var valid_601889 = header.getOrDefault("X-Amz-Signature")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "X-Amz-Signature", valid_601889
  var valid_601890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-SignedHeaders", valid_601890
  var valid_601891 = header.getOrDefault("X-Amz-Credential")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "X-Amz-Credential", valid_601891
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_601892 = formData.getOrDefault("TagKeys")
  valid_601892 = validateParameter(valid_601892, JArray, required = true, default = nil)
  if valid_601892 != nil:
    section.add "TagKeys", valid_601892
  var valid_601893 = formData.getOrDefault("ResourceName")
  valid_601893 = validateParameter(valid_601893, JString, required = true,
                                 default = nil)
  if valid_601893 != nil:
    section.add "ResourceName", valid_601893
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601894: Call_PostRemoveTagsFromResource_601880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601894.validator(path, query, header, formData, body)
  let scheme = call_601894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601894.url(scheme.get, call_601894.host, call_601894.base,
                         call_601894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601894, url, valid)

proc call*(call_601895: Call_PostRemoveTagsFromResource_601880; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601896 = newJObject()
  var formData_601897 = newJObject()
  add(query_601896, "Action", newJString(Action))
  if TagKeys != nil:
    formData_601897.add "TagKeys", TagKeys
  add(formData_601897, "ResourceName", newJString(ResourceName))
  add(query_601896, "Version", newJString(Version))
  result = call_601895.call(nil, query_601896, nil, formData_601897, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_601880(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_601881, base: "/",
    url: url_PostRemoveTagsFromResource_601882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_601863 = ref object of OpenApiRestCall_599352
proc url_GetRemoveTagsFromResource_601865(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_601864(path: JsonNode; query: JsonNode;
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
  var valid_601866 = query.getOrDefault("ResourceName")
  valid_601866 = validateParameter(valid_601866, JString, required = true,
                                 default = nil)
  if valid_601866 != nil:
    section.add "ResourceName", valid_601866
  var valid_601867 = query.getOrDefault("Action")
  valid_601867 = validateParameter(valid_601867, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601867 != nil:
    section.add "Action", valid_601867
  var valid_601868 = query.getOrDefault("TagKeys")
  valid_601868 = validateParameter(valid_601868, JArray, required = true, default = nil)
  if valid_601868 != nil:
    section.add "TagKeys", valid_601868
  var valid_601869 = query.getOrDefault("Version")
  valid_601869 = validateParameter(valid_601869, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601877: Call_GetRemoveTagsFromResource_601863; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601877.validator(path, query, header, formData, body)
  let scheme = call_601877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601877.url(scheme.get, call_601877.host, call_601877.base,
                         call_601877.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601877, url, valid)

proc call*(call_601878: Call_GetRemoveTagsFromResource_601863;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_601879 = newJObject()
  add(query_601879, "ResourceName", newJString(ResourceName))
  add(query_601879, "Action", newJString(Action))
  if TagKeys != nil:
    query_601879.add "TagKeys", TagKeys
  add(query_601879, "Version", newJString(Version))
  result = call_601878.call(nil, query_601879, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_601863(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_601864, base: "/",
    url: url_GetRemoveTagsFromResource_601865,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_601916 = ref object of OpenApiRestCall_599352
proc url_PostResetDBParameterGroup_601918(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_601917(path: JsonNode; query: JsonNode;
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
  var valid_601919 = query.getOrDefault("Action")
  valid_601919 = validateParameter(valid_601919, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_601919 != nil:
    section.add "Action", valid_601919
  var valid_601920 = query.getOrDefault("Version")
  valid_601920 = validateParameter(valid_601920, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601920 != nil:
    section.add "Version", valid_601920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601921 = header.getOrDefault("X-Amz-Date")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Date", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-Security-Token")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-Security-Token", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Content-Sha256", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-Algorithm")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-Algorithm", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Signature")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Signature", valid_601925
  var valid_601926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "X-Amz-SignedHeaders", valid_601926
  var valid_601927 = header.getOrDefault("X-Amz-Credential")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "X-Amz-Credential", valid_601927
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601928 = formData.getOrDefault("DBParameterGroupName")
  valid_601928 = validateParameter(valid_601928, JString, required = true,
                                 default = nil)
  if valid_601928 != nil:
    section.add "DBParameterGroupName", valid_601928
  var valid_601929 = formData.getOrDefault("Parameters")
  valid_601929 = validateParameter(valid_601929, JArray, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "Parameters", valid_601929
  var valid_601930 = formData.getOrDefault("ResetAllParameters")
  valid_601930 = validateParameter(valid_601930, JBool, required = false, default = nil)
  if valid_601930 != nil:
    section.add "ResetAllParameters", valid_601930
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601931: Call_PostResetDBParameterGroup_601916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601931.validator(path, query, header, formData, body)
  let scheme = call_601931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601931.url(scheme.get, call_601931.host, call_601931.base,
                         call_601931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601931, url, valid)

proc call*(call_601932: Call_PostResetDBParameterGroup_601916;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_601933 = newJObject()
  var formData_601934 = newJObject()
  add(formData_601934, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_601934.add "Parameters", Parameters
  add(query_601933, "Action", newJString(Action))
  add(formData_601934, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_601933, "Version", newJString(Version))
  result = call_601932.call(nil, query_601933, nil, formData_601934, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_601916(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_601917, base: "/",
    url: url_PostResetDBParameterGroup_601918,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_601898 = ref object of OpenApiRestCall_599352
proc url_GetResetDBParameterGroup_601900(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_601899(path: JsonNode; query: JsonNode;
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
  var valid_601901 = query.getOrDefault("DBParameterGroupName")
  valid_601901 = validateParameter(valid_601901, JString, required = true,
                                 default = nil)
  if valid_601901 != nil:
    section.add "DBParameterGroupName", valid_601901
  var valid_601902 = query.getOrDefault("Parameters")
  valid_601902 = validateParameter(valid_601902, JArray, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "Parameters", valid_601902
  var valid_601903 = query.getOrDefault("Action")
  valid_601903 = validateParameter(valid_601903, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_601903 != nil:
    section.add "Action", valid_601903
  var valid_601904 = query.getOrDefault("ResetAllParameters")
  valid_601904 = validateParameter(valid_601904, JBool, required = false, default = nil)
  if valid_601904 != nil:
    section.add "ResetAllParameters", valid_601904
  var valid_601905 = query.getOrDefault("Version")
  valid_601905 = validateParameter(valid_601905, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601905 != nil:
    section.add "Version", valid_601905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601906 = header.getOrDefault("X-Amz-Date")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Date", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-Security-Token")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-Security-Token", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Content-Sha256", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-Algorithm")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Algorithm", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Signature")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Signature", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-SignedHeaders", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Credential")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Credential", valid_601912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601913: Call_GetResetDBParameterGroup_601898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601913.validator(path, query, header, formData, body)
  let scheme = call_601913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601913.url(scheme.get, call_601913.host, call_601913.base,
                         call_601913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601913, url, valid)

proc call*(call_601914: Call_GetResetDBParameterGroup_601898;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_601915 = newJObject()
  add(query_601915, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_601915.add "Parameters", Parameters
  add(query_601915, "Action", newJString(Action))
  add(query_601915, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_601915, "Version", newJString(Version))
  result = call_601914.call(nil, query_601915, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_601898(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_601899, base: "/",
    url: url_GetResetDBParameterGroup_601900, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_601965 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBInstanceFromDBSnapshot_601967(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_601966(path: JsonNode;
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
  var valid_601968 = query.getOrDefault("Action")
  valid_601968 = validateParameter(valid_601968, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_601968 != nil:
    section.add "Action", valid_601968
  var valid_601969 = query.getOrDefault("Version")
  valid_601969 = validateParameter(valid_601969, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601969 != nil:
    section.add "Version", valid_601969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601970 = header.getOrDefault("X-Amz-Date")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-Date", valid_601970
  var valid_601971 = header.getOrDefault("X-Amz-Security-Token")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-Security-Token", valid_601971
  var valid_601972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Content-Sha256", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Algorithm")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Algorithm", valid_601973
  var valid_601974 = header.getOrDefault("X-Amz-Signature")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-Signature", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-SignedHeaders", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Credential")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Credential", valid_601976
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
  var valid_601977 = formData.getOrDefault("Port")
  valid_601977 = validateParameter(valid_601977, JInt, required = false, default = nil)
  if valid_601977 != nil:
    section.add "Port", valid_601977
  var valid_601978 = formData.getOrDefault("Engine")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "Engine", valid_601978
  var valid_601979 = formData.getOrDefault("Iops")
  valid_601979 = validateParameter(valid_601979, JInt, required = false, default = nil)
  if valid_601979 != nil:
    section.add "Iops", valid_601979
  var valid_601980 = formData.getOrDefault("DBName")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "DBName", valid_601980
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601981 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601981 = validateParameter(valid_601981, JString, required = true,
                                 default = nil)
  if valid_601981 != nil:
    section.add "DBInstanceIdentifier", valid_601981
  var valid_601982 = formData.getOrDefault("OptionGroupName")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "OptionGroupName", valid_601982
  var valid_601983 = formData.getOrDefault("Tags")
  valid_601983 = validateParameter(valid_601983, JArray, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "Tags", valid_601983
  var valid_601984 = formData.getOrDefault("DBSubnetGroupName")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "DBSubnetGroupName", valid_601984
  var valid_601985 = formData.getOrDefault("AvailabilityZone")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "AvailabilityZone", valid_601985
  var valid_601986 = formData.getOrDefault("MultiAZ")
  valid_601986 = validateParameter(valid_601986, JBool, required = false, default = nil)
  if valid_601986 != nil:
    section.add "MultiAZ", valid_601986
  var valid_601987 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = nil)
  if valid_601987 != nil:
    section.add "DBSnapshotIdentifier", valid_601987
  var valid_601988 = formData.getOrDefault("PubliclyAccessible")
  valid_601988 = validateParameter(valid_601988, JBool, required = false, default = nil)
  if valid_601988 != nil:
    section.add "PubliclyAccessible", valid_601988
  var valid_601989 = formData.getOrDefault("DBInstanceClass")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "DBInstanceClass", valid_601989
  var valid_601990 = formData.getOrDefault("LicenseModel")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "LicenseModel", valid_601990
  var valid_601991 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601991 = validateParameter(valid_601991, JBool, required = false, default = nil)
  if valid_601991 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601991
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601992: Call_PostRestoreDBInstanceFromDBSnapshot_601965;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601992.validator(path, query, header, formData, body)
  let scheme = call_601992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601992.url(scheme.get, call_601992.host, call_601992.base,
                         call_601992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601992, url, valid)

proc call*(call_601993: Call_PostRestoreDBInstanceFromDBSnapshot_601965;
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
  var query_601994 = newJObject()
  var formData_601995 = newJObject()
  add(formData_601995, "Port", newJInt(Port))
  add(formData_601995, "Engine", newJString(Engine))
  add(formData_601995, "Iops", newJInt(Iops))
  add(formData_601995, "DBName", newJString(DBName))
  add(formData_601995, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601995, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601995.add "Tags", Tags
  add(formData_601995, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601995, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601995, "MultiAZ", newJBool(MultiAZ))
  add(formData_601995, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601994, "Action", newJString(Action))
  add(formData_601995, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601995, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601995, "LicenseModel", newJString(LicenseModel))
  add(formData_601995, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601994, "Version", newJString(Version))
  result = call_601993.call(nil, query_601994, nil, formData_601995, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_601965(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_601966, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_601967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_601935 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBInstanceFromDBSnapshot_601937(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_601936(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601938 = query.getOrDefault("Engine")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "Engine", valid_601938
  var valid_601939 = query.getOrDefault("OptionGroupName")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "OptionGroupName", valid_601939
  var valid_601940 = query.getOrDefault("AvailabilityZone")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "AvailabilityZone", valid_601940
  var valid_601941 = query.getOrDefault("Iops")
  valid_601941 = validateParameter(valid_601941, JInt, required = false, default = nil)
  if valid_601941 != nil:
    section.add "Iops", valid_601941
  var valid_601942 = query.getOrDefault("MultiAZ")
  valid_601942 = validateParameter(valid_601942, JBool, required = false, default = nil)
  if valid_601942 != nil:
    section.add "MultiAZ", valid_601942
  var valid_601943 = query.getOrDefault("LicenseModel")
  valid_601943 = validateParameter(valid_601943, JString, required = false,
                                 default = nil)
  if valid_601943 != nil:
    section.add "LicenseModel", valid_601943
  var valid_601944 = query.getOrDefault("Tags")
  valid_601944 = validateParameter(valid_601944, JArray, required = false,
                                 default = nil)
  if valid_601944 != nil:
    section.add "Tags", valid_601944
  var valid_601945 = query.getOrDefault("DBName")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "DBName", valid_601945
  var valid_601946 = query.getOrDefault("DBInstanceClass")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "DBInstanceClass", valid_601946
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601947 = query.getOrDefault("Action")
  valid_601947 = validateParameter(valid_601947, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_601947 != nil:
    section.add "Action", valid_601947
  var valid_601948 = query.getOrDefault("DBSubnetGroupName")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "DBSubnetGroupName", valid_601948
  var valid_601949 = query.getOrDefault("PubliclyAccessible")
  valid_601949 = validateParameter(valid_601949, JBool, required = false, default = nil)
  if valid_601949 != nil:
    section.add "PubliclyAccessible", valid_601949
  var valid_601950 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601950 = validateParameter(valid_601950, JBool, required = false, default = nil)
  if valid_601950 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601950
  var valid_601951 = query.getOrDefault("Port")
  valid_601951 = validateParameter(valid_601951, JInt, required = false, default = nil)
  if valid_601951 != nil:
    section.add "Port", valid_601951
  var valid_601952 = query.getOrDefault("Version")
  valid_601952 = validateParameter(valid_601952, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601952 != nil:
    section.add "Version", valid_601952
  var valid_601953 = query.getOrDefault("DBInstanceIdentifier")
  valid_601953 = validateParameter(valid_601953, JString, required = true,
                                 default = nil)
  if valid_601953 != nil:
    section.add "DBInstanceIdentifier", valid_601953
  var valid_601954 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601954 = validateParameter(valid_601954, JString, required = true,
                                 default = nil)
  if valid_601954 != nil:
    section.add "DBSnapshotIdentifier", valid_601954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601955 = header.getOrDefault("X-Amz-Date")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Date", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-Security-Token")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-Security-Token", valid_601956
  var valid_601957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Content-Sha256", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Algorithm")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Algorithm", valid_601958
  var valid_601959 = header.getOrDefault("X-Amz-Signature")
  valid_601959 = validateParameter(valid_601959, JString, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "X-Amz-Signature", valid_601959
  var valid_601960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-SignedHeaders", valid_601960
  var valid_601961 = header.getOrDefault("X-Amz-Credential")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Credential", valid_601961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601962: Call_GetRestoreDBInstanceFromDBSnapshot_601935;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601962.validator(path, query, header, formData, body)
  let scheme = call_601962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601962.url(scheme.get, call_601962.host, call_601962.base,
                         call_601962.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601962, url, valid)

proc call*(call_601963: Call_GetRestoreDBInstanceFromDBSnapshot_601935;
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
  var query_601964 = newJObject()
  add(query_601964, "Engine", newJString(Engine))
  add(query_601964, "OptionGroupName", newJString(OptionGroupName))
  add(query_601964, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601964, "Iops", newJInt(Iops))
  add(query_601964, "MultiAZ", newJBool(MultiAZ))
  add(query_601964, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_601964.add "Tags", Tags
  add(query_601964, "DBName", newJString(DBName))
  add(query_601964, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601964, "Action", newJString(Action))
  add(query_601964, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601964, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601964, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601964, "Port", newJInt(Port))
  add(query_601964, "Version", newJString(Version))
  add(query_601964, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601964, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601963.call(nil, query_601964, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_601935(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_601936, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_601937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_602028 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBInstanceToPointInTime_602030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_602029(path: JsonNode;
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
  var valid_602031 = query.getOrDefault("Action")
  valid_602031 = validateParameter(valid_602031, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_602031 != nil:
    section.add "Action", valid_602031
  var valid_602032 = query.getOrDefault("Version")
  valid_602032 = validateParameter(valid_602032, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602032 != nil:
    section.add "Version", valid_602032
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602033 = header.getOrDefault("X-Amz-Date")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Date", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Security-Token")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Security-Token", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Content-Sha256", valid_602035
  var valid_602036 = header.getOrDefault("X-Amz-Algorithm")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "X-Amz-Algorithm", valid_602036
  var valid_602037 = header.getOrDefault("X-Amz-Signature")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "X-Amz-Signature", valid_602037
  var valid_602038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-SignedHeaders", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Credential")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Credential", valid_602039
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
  var valid_602040 = formData.getOrDefault("UseLatestRestorableTime")
  valid_602040 = validateParameter(valid_602040, JBool, required = false, default = nil)
  if valid_602040 != nil:
    section.add "UseLatestRestorableTime", valid_602040
  var valid_602041 = formData.getOrDefault("Port")
  valid_602041 = validateParameter(valid_602041, JInt, required = false, default = nil)
  if valid_602041 != nil:
    section.add "Port", valid_602041
  var valid_602042 = formData.getOrDefault("Engine")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "Engine", valid_602042
  var valid_602043 = formData.getOrDefault("Iops")
  valid_602043 = validateParameter(valid_602043, JInt, required = false, default = nil)
  if valid_602043 != nil:
    section.add "Iops", valid_602043
  var valid_602044 = formData.getOrDefault("DBName")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "DBName", valid_602044
  var valid_602045 = formData.getOrDefault("OptionGroupName")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "OptionGroupName", valid_602045
  var valid_602046 = formData.getOrDefault("Tags")
  valid_602046 = validateParameter(valid_602046, JArray, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "Tags", valid_602046
  var valid_602047 = formData.getOrDefault("DBSubnetGroupName")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "DBSubnetGroupName", valid_602047
  var valid_602048 = formData.getOrDefault("AvailabilityZone")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "AvailabilityZone", valid_602048
  var valid_602049 = formData.getOrDefault("MultiAZ")
  valid_602049 = validateParameter(valid_602049, JBool, required = false, default = nil)
  if valid_602049 != nil:
    section.add "MultiAZ", valid_602049
  var valid_602050 = formData.getOrDefault("RestoreTime")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "RestoreTime", valid_602050
  var valid_602051 = formData.getOrDefault("PubliclyAccessible")
  valid_602051 = validateParameter(valid_602051, JBool, required = false, default = nil)
  if valid_602051 != nil:
    section.add "PubliclyAccessible", valid_602051
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_602052 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_602052 = validateParameter(valid_602052, JString, required = true,
                                 default = nil)
  if valid_602052 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602052
  var valid_602053 = formData.getOrDefault("DBInstanceClass")
  valid_602053 = validateParameter(valid_602053, JString, required = false,
                                 default = nil)
  if valid_602053 != nil:
    section.add "DBInstanceClass", valid_602053
  var valid_602054 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_602054 = validateParameter(valid_602054, JString, required = true,
                                 default = nil)
  if valid_602054 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602054
  var valid_602055 = formData.getOrDefault("LicenseModel")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "LicenseModel", valid_602055
  var valid_602056 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602056 = validateParameter(valid_602056, JBool, required = false, default = nil)
  if valid_602056 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602057: Call_PostRestoreDBInstanceToPointInTime_602028;
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

proc call*(call_602058: Call_PostRestoreDBInstanceToPointInTime_602028;
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
  var query_602059 = newJObject()
  var formData_602060 = newJObject()
  add(formData_602060, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_602060, "Port", newJInt(Port))
  add(formData_602060, "Engine", newJString(Engine))
  add(formData_602060, "Iops", newJInt(Iops))
  add(formData_602060, "DBName", newJString(DBName))
  add(formData_602060, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_602060.add "Tags", Tags
  add(formData_602060, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602060, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602060, "MultiAZ", newJBool(MultiAZ))
  add(query_602059, "Action", newJString(Action))
  add(formData_602060, "RestoreTime", newJString(RestoreTime))
  add(formData_602060, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_602060, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_602060, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602060, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_602060, "LicenseModel", newJString(LicenseModel))
  add(formData_602060, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_602059, "Version", newJString(Version))
  result = call_602058.call(nil, query_602059, nil, formData_602060, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_602028(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_602029, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_602030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_601996 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBInstanceToPointInTime_601998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_601997(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601999 = query.getOrDefault("Engine")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "Engine", valid_601999
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_602000 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = nil)
  if valid_602000 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602000
  var valid_602001 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_602001 = validateParameter(valid_602001, JString, required = true,
                                 default = nil)
  if valid_602001 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602001
  var valid_602002 = query.getOrDefault("AvailabilityZone")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "AvailabilityZone", valid_602002
  var valid_602003 = query.getOrDefault("Iops")
  valid_602003 = validateParameter(valid_602003, JInt, required = false, default = nil)
  if valid_602003 != nil:
    section.add "Iops", valid_602003
  var valid_602004 = query.getOrDefault("OptionGroupName")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "OptionGroupName", valid_602004
  var valid_602005 = query.getOrDefault("RestoreTime")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "RestoreTime", valid_602005
  var valid_602006 = query.getOrDefault("MultiAZ")
  valid_602006 = validateParameter(valid_602006, JBool, required = false, default = nil)
  if valid_602006 != nil:
    section.add "MultiAZ", valid_602006
  var valid_602007 = query.getOrDefault("LicenseModel")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "LicenseModel", valid_602007
  var valid_602008 = query.getOrDefault("Tags")
  valid_602008 = validateParameter(valid_602008, JArray, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "Tags", valid_602008
  var valid_602009 = query.getOrDefault("DBName")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "DBName", valid_602009
  var valid_602010 = query.getOrDefault("DBInstanceClass")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "DBInstanceClass", valid_602010
  var valid_602011 = query.getOrDefault("Action")
  valid_602011 = validateParameter(valid_602011, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_602011 != nil:
    section.add "Action", valid_602011
  var valid_602012 = query.getOrDefault("UseLatestRestorableTime")
  valid_602012 = validateParameter(valid_602012, JBool, required = false, default = nil)
  if valid_602012 != nil:
    section.add "UseLatestRestorableTime", valid_602012
  var valid_602013 = query.getOrDefault("DBSubnetGroupName")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "DBSubnetGroupName", valid_602013
  var valid_602014 = query.getOrDefault("PubliclyAccessible")
  valid_602014 = validateParameter(valid_602014, JBool, required = false, default = nil)
  if valid_602014 != nil:
    section.add "PubliclyAccessible", valid_602014
  var valid_602015 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602015 = validateParameter(valid_602015, JBool, required = false, default = nil)
  if valid_602015 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602015
  var valid_602016 = query.getOrDefault("Port")
  valid_602016 = validateParameter(valid_602016, JInt, required = false, default = nil)
  if valid_602016 != nil:
    section.add "Port", valid_602016
  var valid_602017 = query.getOrDefault("Version")
  valid_602017 = validateParameter(valid_602017, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602017 != nil:
    section.add "Version", valid_602017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602018 = header.getOrDefault("X-Amz-Date")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "X-Amz-Date", valid_602018
  var valid_602019 = header.getOrDefault("X-Amz-Security-Token")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "X-Amz-Security-Token", valid_602019
  var valid_602020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602020 = validateParameter(valid_602020, JString, required = false,
                                 default = nil)
  if valid_602020 != nil:
    section.add "X-Amz-Content-Sha256", valid_602020
  var valid_602021 = header.getOrDefault("X-Amz-Algorithm")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "X-Amz-Algorithm", valid_602021
  var valid_602022 = header.getOrDefault("X-Amz-Signature")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Signature", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-SignedHeaders", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Credential")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Credential", valid_602024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602025: Call_GetRestoreDBInstanceToPointInTime_601996;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602025.validator(path, query, header, formData, body)
  let scheme = call_602025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602025.url(scheme.get, call_602025.host, call_602025.base,
                         call_602025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602025, url, valid)

proc call*(call_602026: Call_GetRestoreDBInstanceToPointInTime_601996;
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
  var query_602027 = newJObject()
  add(query_602027, "Engine", newJString(Engine))
  add(query_602027, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_602027, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_602027, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602027, "Iops", newJInt(Iops))
  add(query_602027, "OptionGroupName", newJString(OptionGroupName))
  add(query_602027, "RestoreTime", newJString(RestoreTime))
  add(query_602027, "MultiAZ", newJBool(MultiAZ))
  add(query_602027, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_602027.add "Tags", Tags
  add(query_602027, "DBName", newJString(DBName))
  add(query_602027, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602027, "Action", newJString(Action))
  add(query_602027, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_602027, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602027, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602027, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602027, "Port", newJInt(Port))
  add(query_602027, "Version", newJString(Version))
  result = call_602026.call(nil, query_602027, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_601996(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_601997, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_601998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_602081 = ref object of OpenApiRestCall_599352
proc url_PostRevokeDBSecurityGroupIngress_602083(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_602082(path: JsonNode;
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
  var valid_602084 = query.getOrDefault("Action")
  valid_602084 = validateParameter(valid_602084, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_602084 != nil:
    section.add "Action", valid_602084
  var valid_602085 = query.getOrDefault("Version")
  valid_602085 = validateParameter(valid_602085, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602085 != nil:
    section.add "Version", valid_602085
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602086 = header.getOrDefault("X-Amz-Date")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Date", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Security-Token")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Security-Token", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Content-Sha256", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Algorithm")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Algorithm", valid_602089
  var valid_602090 = header.getOrDefault("X-Amz-Signature")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "X-Amz-Signature", valid_602090
  var valid_602091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "X-Amz-SignedHeaders", valid_602091
  var valid_602092 = header.getOrDefault("X-Amz-Credential")
  valid_602092 = validateParameter(valid_602092, JString, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "X-Amz-Credential", valid_602092
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602093 = formData.getOrDefault("DBSecurityGroupName")
  valid_602093 = validateParameter(valid_602093, JString, required = true,
                                 default = nil)
  if valid_602093 != nil:
    section.add "DBSecurityGroupName", valid_602093
  var valid_602094 = formData.getOrDefault("EC2SecurityGroupName")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "EC2SecurityGroupName", valid_602094
  var valid_602095 = formData.getOrDefault("EC2SecurityGroupId")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "EC2SecurityGroupId", valid_602095
  var valid_602096 = formData.getOrDefault("CIDRIP")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "CIDRIP", valid_602096
  var valid_602097 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602098: Call_PostRevokeDBSecurityGroupIngress_602081;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602098.validator(path, query, header, formData, body)
  let scheme = call_602098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602098.url(scheme.get, call_602098.host, call_602098.base,
                         call_602098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602098, url, valid)

proc call*(call_602099: Call_PostRevokeDBSecurityGroupIngress_602081;
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
  var query_602100 = newJObject()
  var formData_602101 = newJObject()
  add(formData_602101, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602100, "Action", newJString(Action))
  add(formData_602101, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_602101, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_602101, "CIDRIP", newJString(CIDRIP))
  add(query_602100, "Version", newJString(Version))
  add(formData_602101, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_602099.call(nil, query_602100, nil, formData_602101, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_602081(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_602082, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_602083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_602061 = ref object of OpenApiRestCall_599352
proc url_GetRevokeDBSecurityGroupIngress_602063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_602062(path: JsonNode;
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
  var valid_602064 = query.getOrDefault("EC2SecurityGroupId")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "EC2SecurityGroupId", valid_602064
  var valid_602065 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602065
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602066 = query.getOrDefault("DBSecurityGroupName")
  valid_602066 = validateParameter(valid_602066, JString, required = true,
                                 default = nil)
  if valid_602066 != nil:
    section.add "DBSecurityGroupName", valid_602066
  var valid_602067 = query.getOrDefault("Action")
  valid_602067 = validateParameter(valid_602067, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_602067 != nil:
    section.add "Action", valid_602067
  var valid_602068 = query.getOrDefault("CIDRIP")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "CIDRIP", valid_602068
  var valid_602069 = query.getOrDefault("EC2SecurityGroupName")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "EC2SecurityGroupName", valid_602069
  var valid_602070 = query.getOrDefault("Version")
  valid_602070 = validateParameter(valid_602070, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602070 != nil:
    section.add "Version", valid_602070
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602071 = header.getOrDefault("X-Amz-Date")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Date", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Security-Token")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Security-Token", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Content-Sha256", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Algorithm")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Algorithm", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Signature")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Signature", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-SignedHeaders", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Credential")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Credential", valid_602077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602078: Call_GetRevokeDBSecurityGroupIngress_602061;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602078.validator(path, query, header, formData, body)
  let scheme = call_602078.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602078.url(scheme.get, call_602078.host, call_602078.base,
                         call_602078.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602078, url, valid)

proc call*(call_602079: Call_GetRevokeDBSecurityGroupIngress_602061;
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
  var query_602080 = newJObject()
  add(query_602080, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_602080, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_602080, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602080, "Action", newJString(Action))
  add(query_602080, "CIDRIP", newJString(CIDRIP))
  add(query_602080, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_602080, "Version", newJString(Version))
  result = call_602079.call(nil, query_602080, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_602061(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_602062, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_602063,
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

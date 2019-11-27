
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          CIDRIP: string = ""; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
  Call_PostCopyDBSnapshot_600072 = ref object of OpenApiRestCall_599352
proc url_PostCopyDBSnapshot_600074(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_600073(path: JsonNode; query: JsonNode;
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
  var valid_600075 = query.getOrDefault("Action")
  valid_600075 = validateParameter(valid_600075, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_600075 != nil:
    section.add "Action", valid_600075
  var valid_600076 = query.getOrDefault("Version")
  valid_600076 = validateParameter(valid_600076, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600076 != nil:
    section.add "Version", valid_600076
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600077 = header.getOrDefault("X-Amz-Date")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-Date", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Security-Token")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Security-Token", valid_600078
  var valid_600079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Content-Sha256", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Algorithm")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Algorithm", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Signature")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Signature", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-SignedHeaders", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Credential")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Credential", valid_600083
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_600084 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_600084 = validateParameter(valid_600084, JString, required = true,
                                 default = nil)
  if valid_600084 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_600084
  var valid_600085 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = nil)
  if valid_600085 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_600085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600086: Call_PostCopyDBSnapshot_600072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600086.validator(path, query, header, formData, body)
  let scheme = call_600086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600086.url(scheme.get, call_600086.host, call_600086.base,
                         call_600086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600086, url, valid)

proc call*(call_600087: Call_PostCopyDBSnapshot_600072;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_600088 = newJObject()
  var formData_600089 = newJObject()
  add(formData_600089, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_600088, "Action", newJString(Action))
  add(formData_600089, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_600088, "Version", newJString(Version))
  result = call_600087.call(nil, query_600088, nil, formData_600089, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_600072(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_600073, base: "/",
    url: url_PostCopyDBSnapshot_600074, schemes: {Scheme.Https, Scheme.Http})
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
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_600058 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_600058 = validateParameter(valid_600058, JString, required = true,
                                 default = nil)
  if valid_600058 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_600058
  var valid_600059 = query.getOrDefault("Action")
  valid_600059 = validateParameter(valid_600059, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_600059 != nil:
    section.add "Action", valid_600059
  var valid_600060 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_600060 = validateParameter(valid_600060, JString, required = true,
                                 default = nil)
  if valid_600060 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_600060
  var valid_600061 = query.getOrDefault("Version")
  valid_600061 = validateParameter(valid_600061, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600061 != nil:
    section.add "Version", valid_600061
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600062 = header.getOrDefault("X-Amz-Date")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Date", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Security-Token")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Security-Token", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Content-Sha256", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Algorithm")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Algorithm", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-Signature")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-Signature", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-SignedHeaders", valid_600067
  var valid_600068 = header.getOrDefault("X-Amz-Credential")
  valid_600068 = validateParameter(valid_600068, JString, required = false,
                                 default = nil)
  if valid_600068 != nil:
    section.add "X-Amz-Credential", valid_600068
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_GetCopyDBSnapshot_600055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_GetCopyDBSnapshot_600055;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_600071 = newJObject()
  add(query_600071, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_600071, "Action", newJString(Action))
  add(query_600071, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_600071, "Version", newJString(Version))
  result = call_600070.call(nil, query_600071, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_600055(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_600056,
    base: "/", url: url_GetCopyDBSnapshot_600057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_600129 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBInstance_600131(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_600130(path: JsonNode; query: JsonNode;
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
  var valid_600132 = query.getOrDefault("Action")
  valid_600132 = validateParameter(valid_600132, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600132 != nil:
    section.add "Action", valid_600132
  var valid_600133 = query.getOrDefault("Version")
  valid_600133 = validateParameter(valid_600133, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600133 != nil:
    section.add "Version", valid_600133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600134 = header.getOrDefault("X-Amz-Date")
  valid_600134 = validateParameter(valid_600134, JString, required = false,
                                 default = nil)
  if valid_600134 != nil:
    section.add "X-Amz-Date", valid_600134
  var valid_600135 = header.getOrDefault("X-Amz-Security-Token")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "X-Amz-Security-Token", valid_600135
  var valid_600136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Content-Sha256", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Algorithm")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Algorithm", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Signature")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Signature", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-SignedHeaders", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Credential")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Credential", valid_600140
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
  var valid_600141 = formData.getOrDefault("DBSecurityGroups")
  valid_600141 = validateParameter(valid_600141, JArray, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "DBSecurityGroups", valid_600141
  var valid_600142 = formData.getOrDefault("Port")
  valid_600142 = validateParameter(valid_600142, JInt, required = false, default = nil)
  if valid_600142 != nil:
    section.add "Port", valid_600142
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_600143 = formData.getOrDefault("Engine")
  valid_600143 = validateParameter(valid_600143, JString, required = true,
                                 default = nil)
  if valid_600143 != nil:
    section.add "Engine", valid_600143
  var valid_600144 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_600144 = validateParameter(valid_600144, JArray, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "VpcSecurityGroupIds", valid_600144
  var valid_600145 = formData.getOrDefault("Iops")
  valid_600145 = validateParameter(valid_600145, JInt, required = false, default = nil)
  if valid_600145 != nil:
    section.add "Iops", valid_600145
  var valid_600146 = formData.getOrDefault("DBName")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "DBName", valid_600146
  var valid_600147 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600147 = validateParameter(valid_600147, JString, required = true,
                                 default = nil)
  if valid_600147 != nil:
    section.add "DBInstanceIdentifier", valid_600147
  var valid_600148 = formData.getOrDefault("BackupRetentionPeriod")
  valid_600148 = validateParameter(valid_600148, JInt, required = false, default = nil)
  if valid_600148 != nil:
    section.add "BackupRetentionPeriod", valid_600148
  var valid_600149 = formData.getOrDefault("DBParameterGroupName")
  valid_600149 = validateParameter(valid_600149, JString, required = false,
                                 default = nil)
  if valid_600149 != nil:
    section.add "DBParameterGroupName", valid_600149
  var valid_600150 = formData.getOrDefault("OptionGroupName")
  valid_600150 = validateParameter(valid_600150, JString, required = false,
                                 default = nil)
  if valid_600150 != nil:
    section.add "OptionGroupName", valid_600150
  var valid_600151 = formData.getOrDefault("MasterUserPassword")
  valid_600151 = validateParameter(valid_600151, JString, required = true,
                                 default = nil)
  if valid_600151 != nil:
    section.add "MasterUserPassword", valid_600151
  var valid_600152 = formData.getOrDefault("DBSubnetGroupName")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "DBSubnetGroupName", valid_600152
  var valid_600153 = formData.getOrDefault("AvailabilityZone")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "AvailabilityZone", valid_600153
  var valid_600154 = formData.getOrDefault("MultiAZ")
  valid_600154 = validateParameter(valid_600154, JBool, required = false, default = nil)
  if valid_600154 != nil:
    section.add "MultiAZ", valid_600154
  var valid_600155 = formData.getOrDefault("AllocatedStorage")
  valid_600155 = validateParameter(valid_600155, JInt, required = true, default = nil)
  if valid_600155 != nil:
    section.add "AllocatedStorage", valid_600155
  var valid_600156 = formData.getOrDefault("PubliclyAccessible")
  valid_600156 = validateParameter(valid_600156, JBool, required = false, default = nil)
  if valid_600156 != nil:
    section.add "PubliclyAccessible", valid_600156
  var valid_600157 = formData.getOrDefault("MasterUsername")
  valid_600157 = validateParameter(valid_600157, JString, required = true,
                                 default = nil)
  if valid_600157 != nil:
    section.add "MasterUsername", valid_600157
  var valid_600158 = formData.getOrDefault("DBInstanceClass")
  valid_600158 = validateParameter(valid_600158, JString, required = true,
                                 default = nil)
  if valid_600158 != nil:
    section.add "DBInstanceClass", valid_600158
  var valid_600159 = formData.getOrDefault("CharacterSetName")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "CharacterSetName", valid_600159
  var valid_600160 = formData.getOrDefault("PreferredBackupWindow")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "PreferredBackupWindow", valid_600160
  var valid_600161 = formData.getOrDefault("LicenseModel")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "LicenseModel", valid_600161
  var valid_600162 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_600162 = validateParameter(valid_600162, JBool, required = false, default = nil)
  if valid_600162 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600162
  var valid_600163 = formData.getOrDefault("EngineVersion")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "EngineVersion", valid_600163
  var valid_600164 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_600164 = validateParameter(valid_600164, JString, required = false,
                                 default = nil)
  if valid_600164 != nil:
    section.add "PreferredMaintenanceWindow", valid_600164
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600165: Call_PostCreateDBInstance_600129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600165.validator(path, query, header, formData, body)
  let scheme = call_600165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600165.url(scheme.get, call_600165.host, call_600165.base,
                         call_600165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600165, url, valid)

proc call*(call_600166: Call_PostCreateDBInstance_600129; Engine: string;
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
          EngineVersion: string = ""; Version: string = "2013-02-12";
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
  var query_600167 = newJObject()
  var formData_600168 = newJObject()
  if DBSecurityGroups != nil:
    formData_600168.add "DBSecurityGroups", DBSecurityGroups
  add(formData_600168, "Port", newJInt(Port))
  add(formData_600168, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_600168.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_600168, "Iops", newJInt(Iops))
  add(formData_600168, "DBName", newJString(DBName))
  add(formData_600168, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600168, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_600168, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600168, "OptionGroupName", newJString(OptionGroupName))
  add(formData_600168, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_600168, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_600168, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_600168, "MultiAZ", newJBool(MultiAZ))
  add(query_600167, "Action", newJString(Action))
  add(formData_600168, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_600168, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_600168, "MasterUsername", newJString(MasterUsername))
  add(formData_600168, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_600168, "CharacterSetName", newJString(CharacterSetName))
  add(formData_600168, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_600168, "LicenseModel", newJString(LicenseModel))
  add(formData_600168, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_600168, "EngineVersion", newJString(EngineVersion))
  add(query_600167, "Version", newJString(Version))
  add(formData_600168, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_600166.call(nil, query_600167, nil, formData_600168, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_600129(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_600130, base: "/",
    url: url_PostCreateDBInstance_600131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_600090 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBInstance_600092(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_600091(path: JsonNode; query: JsonNode;
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
  var valid_600093 = query.getOrDefault("Engine")
  valid_600093 = validateParameter(valid_600093, JString, required = true,
                                 default = nil)
  if valid_600093 != nil:
    section.add "Engine", valid_600093
  var valid_600094 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "PreferredMaintenanceWindow", valid_600094
  var valid_600095 = query.getOrDefault("AllocatedStorage")
  valid_600095 = validateParameter(valid_600095, JInt, required = true, default = nil)
  if valid_600095 != nil:
    section.add "AllocatedStorage", valid_600095
  var valid_600096 = query.getOrDefault("OptionGroupName")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "OptionGroupName", valid_600096
  var valid_600097 = query.getOrDefault("DBSecurityGroups")
  valid_600097 = validateParameter(valid_600097, JArray, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "DBSecurityGroups", valid_600097
  var valid_600098 = query.getOrDefault("MasterUserPassword")
  valid_600098 = validateParameter(valid_600098, JString, required = true,
                                 default = nil)
  if valid_600098 != nil:
    section.add "MasterUserPassword", valid_600098
  var valid_600099 = query.getOrDefault("AvailabilityZone")
  valid_600099 = validateParameter(valid_600099, JString, required = false,
                                 default = nil)
  if valid_600099 != nil:
    section.add "AvailabilityZone", valid_600099
  var valid_600100 = query.getOrDefault("Iops")
  valid_600100 = validateParameter(valid_600100, JInt, required = false, default = nil)
  if valid_600100 != nil:
    section.add "Iops", valid_600100
  var valid_600101 = query.getOrDefault("VpcSecurityGroupIds")
  valid_600101 = validateParameter(valid_600101, JArray, required = false,
                                 default = nil)
  if valid_600101 != nil:
    section.add "VpcSecurityGroupIds", valid_600101
  var valid_600102 = query.getOrDefault("MultiAZ")
  valid_600102 = validateParameter(valid_600102, JBool, required = false, default = nil)
  if valid_600102 != nil:
    section.add "MultiAZ", valid_600102
  var valid_600103 = query.getOrDefault("LicenseModel")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "LicenseModel", valid_600103
  var valid_600104 = query.getOrDefault("BackupRetentionPeriod")
  valid_600104 = validateParameter(valid_600104, JInt, required = false, default = nil)
  if valid_600104 != nil:
    section.add "BackupRetentionPeriod", valid_600104
  var valid_600105 = query.getOrDefault("DBName")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "DBName", valid_600105
  var valid_600106 = query.getOrDefault("DBParameterGroupName")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "DBParameterGroupName", valid_600106
  var valid_600107 = query.getOrDefault("DBInstanceClass")
  valid_600107 = validateParameter(valid_600107, JString, required = true,
                                 default = nil)
  if valid_600107 != nil:
    section.add "DBInstanceClass", valid_600107
  var valid_600108 = query.getOrDefault("Action")
  valid_600108 = validateParameter(valid_600108, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_600108 != nil:
    section.add "Action", valid_600108
  var valid_600109 = query.getOrDefault("DBSubnetGroupName")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "DBSubnetGroupName", valid_600109
  var valid_600110 = query.getOrDefault("CharacterSetName")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "CharacterSetName", valid_600110
  var valid_600111 = query.getOrDefault("PubliclyAccessible")
  valid_600111 = validateParameter(valid_600111, JBool, required = false, default = nil)
  if valid_600111 != nil:
    section.add "PubliclyAccessible", valid_600111
  var valid_600112 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_600112 = validateParameter(valid_600112, JBool, required = false, default = nil)
  if valid_600112 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600112
  var valid_600113 = query.getOrDefault("EngineVersion")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "EngineVersion", valid_600113
  var valid_600114 = query.getOrDefault("Port")
  valid_600114 = validateParameter(valid_600114, JInt, required = false, default = nil)
  if valid_600114 != nil:
    section.add "Port", valid_600114
  var valid_600115 = query.getOrDefault("PreferredBackupWindow")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "PreferredBackupWindow", valid_600115
  var valid_600116 = query.getOrDefault("Version")
  valid_600116 = validateParameter(valid_600116, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600116 != nil:
    section.add "Version", valid_600116
  var valid_600117 = query.getOrDefault("DBInstanceIdentifier")
  valid_600117 = validateParameter(valid_600117, JString, required = true,
                                 default = nil)
  if valid_600117 != nil:
    section.add "DBInstanceIdentifier", valid_600117
  var valid_600118 = query.getOrDefault("MasterUsername")
  valid_600118 = validateParameter(valid_600118, JString, required = true,
                                 default = nil)
  if valid_600118 != nil:
    section.add "MasterUsername", valid_600118
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600119 = header.getOrDefault("X-Amz-Date")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Date", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Security-Token")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Security-Token", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Content-Sha256", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-Algorithm")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-Algorithm", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Signature")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Signature", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-SignedHeaders", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Credential")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Credential", valid_600125
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600126: Call_GetCreateDBInstance_600090; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600126.validator(path, query, header, formData, body)
  let scheme = call_600126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600126.url(scheme.get, call_600126.host, call_600126.base,
                         call_600126.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600126, url, valid)

proc call*(call_600127: Call_GetCreateDBInstance_600090; Engine: string;
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
          Version: string = "2013-02-12"): Recallable =
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
  var query_600128 = newJObject()
  add(query_600128, "Engine", newJString(Engine))
  add(query_600128, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_600128, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_600128, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_600128.add "DBSecurityGroups", DBSecurityGroups
  add(query_600128, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_600128, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600128, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_600128.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_600128, "MultiAZ", newJBool(MultiAZ))
  add(query_600128, "LicenseModel", newJString(LicenseModel))
  add(query_600128, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_600128, "DBName", newJString(DBName))
  add(query_600128, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600128, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_600128, "Action", newJString(Action))
  add(query_600128, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600128, "CharacterSetName", newJString(CharacterSetName))
  add(query_600128, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_600128, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_600128, "EngineVersion", newJString(EngineVersion))
  add(query_600128, "Port", newJInt(Port))
  add(query_600128, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_600128, "Version", newJString(Version))
  add(query_600128, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600128, "MasterUsername", newJString(MasterUsername))
  result = call_600127.call(nil, query_600128, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_600090(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_600091, base: "/",
    url: url_GetCreateDBInstance_600092, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_600193 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBInstanceReadReplica_600195(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_600194(path: JsonNode;
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
  var valid_600196 = query.getOrDefault("Action")
  valid_600196 = validateParameter(valid_600196, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_600196 != nil:
    section.add "Action", valid_600196
  var valid_600197 = query.getOrDefault("Version")
  valid_600197 = validateParameter(valid_600197, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600197 != nil:
    section.add "Version", valid_600197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600198 = header.getOrDefault("X-Amz-Date")
  valid_600198 = validateParameter(valid_600198, JString, required = false,
                                 default = nil)
  if valid_600198 != nil:
    section.add "X-Amz-Date", valid_600198
  var valid_600199 = header.getOrDefault("X-Amz-Security-Token")
  valid_600199 = validateParameter(valid_600199, JString, required = false,
                                 default = nil)
  if valid_600199 != nil:
    section.add "X-Amz-Security-Token", valid_600199
  var valid_600200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Content-Sha256", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Algorithm")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Algorithm", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Signature")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Signature", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-SignedHeaders", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Credential")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Credential", valid_600204
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
  var valid_600205 = formData.getOrDefault("Port")
  valid_600205 = validateParameter(valid_600205, JInt, required = false, default = nil)
  if valid_600205 != nil:
    section.add "Port", valid_600205
  var valid_600206 = formData.getOrDefault("Iops")
  valid_600206 = validateParameter(valid_600206, JInt, required = false, default = nil)
  if valid_600206 != nil:
    section.add "Iops", valid_600206
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600207 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600207 = validateParameter(valid_600207, JString, required = true,
                                 default = nil)
  if valid_600207 != nil:
    section.add "DBInstanceIdentifier", valid_600207
  var valid_600208 = formData.getOrDefault("OptionGroupName")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "OptionGroupName", valid_600208
  var valid_600209 = formData.getOrDefault("AvailabilityZone")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "AvailabilityZone", valid_600209
  var valid_600210 = formData.getOrDefault("PubliclyAccessible")
  valid_600210 = validateParameter(valid_600210, JBool, required = false, default = nil)
  if valid_600210 != nil:
    section.add "PubliclyAccessible", valid_600210
  var valid_600211 = formData.getOrDefault("DBInstanceClass")
  valid_600211 = validateParameter(valid_600211, JString, required = false,
                                 default = nil)
  if valid_600211 != nil:
    section.add "DBInstanceClass", valid_600211
  var valid_600212 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_600212 = validateParameter(valid_600212, JString, required = true,
                                 default = nil)
  if valid_600212 != nil:
    section.add "SourceDBInstanceIdentifier", valid_600212
  var valid_600213 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_600213 = validateParameter(valid_600213, JBool, required = false, default = nil)
  if valid_600213 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600213
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600214: Call_PostCreateDBInstanceReadReplica_600193;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600214.validator(path, query, header, formData, body)
  let scheme = call_600214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600214.url(scheme.get, call_600214.host, call_600214.base,
                         call_600214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600214, url, valid)

proc call*(call_600215: Call_PostCreateDBInstanceReadReplica_600193;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = "";
          AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-02-12"): Recallable =
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
  var query_600216 = newJObject()
  var formData_600217 = newJObject()
  add(formData_600217, "Port", newJInt(Port))
  add(formData_600217, "Iops", newJInt(Iops))
  add(formData_600217, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600217, "OptionGroupName", newJString(OptionGroupName))
  add(formData_600217, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600216, "Action", newJString(Action))
  add(formData_600217, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_600217, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_600217, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_600217, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_600216, "Version", newJString(Version))
  result = call_600215.call(nil, query_600216, nil, formData_600217, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_600193(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_600194, base: "/",
    url: url_PostCreateDBInstanceReadReplica_600195,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_600169 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBInstanceReadReplica_600171(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_600170(path: JsonNode;
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
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_600172 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_600172 = validateParameter(valid_600172, JString, required = true,
                                 default = nil)
  if valid_600172 != nil:
    section.add "SourceDBInstanceIdentifier", valid_600172
  var valid_600173 = query.getOrDefault("OptionGroupName")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "OptionGroupName", valid_600173
  var valid_600174 = query.getOrDefault("AvailabilityZone")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "AvailabilityZone", valid_600174
  var valid_600175 = query.getOrDefault("Iops")
  valid_600175 = validateParameter(valid_600175, JInt, required = false, default = nil)
  if valid_600175 != nil:
    section.add "Iops", valid_600175
  var valid_600176 = query.getOrDefault("DBInstanceClass")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "DBInstanceClass", valid_600176
  var valid_600177 = query.getOrDefault("Action")
  valid_600177 = validateParameter(valid_600177, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_600177 != nil:
    section.add "Action", valid_600177
  var valid_600178 = query.getOrDefault("PubliclyAccessible")
  valid_600178 = validateParameter(valid_600178, JBool, required = false, default = nil)
  if valid_600178 != nil:
    section.add "PubliclyAccessible", valid_600178
  var valid_600179 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_600179 = validateParameter(valid_600179, JBool, required = false, default = nil)
  if valid_600179 != nil:
    section.add "AutoMinorVersionUpgrade", valid_600179
  var valid_600180 = query.getOrDefault("Port")
  valid_600180 = validateParameter(valid_600180, JInt, required = false, default = nil)
  if valid_600180 != nil:
    section.add "Port", valid_600180
  var valid_600181 = query.getOrDefault("Version")
  valid_600181 = validateParameter(valid_600181, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600181 != nil:
    section.add "Version", valid_600181
  var valid_600182 = query.getOrDefault("DBInstanceIdentifier")
  valid_600182 = validateParameter(valid_600182, JString, required = true,
                                 default = nil)
  if valid_600182 != nil:
    section.add "DBInstanceIdentifier", valid_600182
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600183 = header.getOrDefault("X-Amz-Date")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Date", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Security-Token")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Security-Token", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Content-Sha256", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Algorithm")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Algorithm", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Signature")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Signature", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-SignedHeaders", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Credential")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Credential", valid_600189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600190: Call_GetCreateDBInstanceReadReplica_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600190.validator(path, query, header, formData, body)
  let scheme = call_600190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600190.url(scheme.get, call_600190.host, call_600190.base,
                         call_600190.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600190, url, valid)

proc call*(call_600191: Call_GetCreateDBInstanceReadReplica_600169;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          OptionGroupName: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-02-12"): Recallable =
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
  var query_600192 = newJObject()
  add(query_600192, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_600192, "OptionGroupName", newJString(OptionGroupName))
  add(query_600192, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_600192, "Iops", newJInt(Iops))
  add(query_600192, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_600192, "Action", newJString(Action))
  add(query_600192, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_600192, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_600192, "Port", newJInt(Port))
  add(query_600192, "Version", newJString(Version))
  add(query_600192, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600191.call(nil, query_600192, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_600169(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_600170, base: "/",
    url: url_GetCreateDBInstanceReadReplica_600171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_600236 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBParameterGroup_600238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_600237(path: JsonNode; query: JsonNode;
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
  var valid_600239 = query.getOrDefault("Action")
  valid_600239 = validateParameter(valid_600239, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_600239 != nil:
    section.add "Action", valid_600239
  var valid_600240 = query.getOrDefault("Version")
  valid_600240 = validateParameter(valid_600240, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600240 != nil:
    section.add "Version", valid_600240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600241 = header.getOrDefault("X-Amz-Date")
  valid_600241 = validateParameter(valid_600241, JString, required = false,
                                 default = nil)
  if valid_600241 != nil:
    section.add "X-Amz-Date", valid_600241
  var valid_600242 = header.getOrDefault("X-Amz-Security-Token")
  valid_600242 = validateParameter(valid_600242, JString, required = false,
                                 default = nil)
  if valid_600242 != nil:
    section.add "X-Amz-Security-Token", valid_600242
  var valid_600243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600243 = validateParameter(valid_600243, JString, required = false,
                                 default = nil)
  if valid_600243 != nil:
    section.add "X-Amz-Content-Sha256", valid_600243
  var valid_600244 = header.getOrDefault("X-Amz-Algorithm")
  valid_600244 = validateParameter(valid_600244, JString, required = false,
                                 default = nil)
  if valid_600244 != nil:
    section.add "X-Amz-Algorithm", valid_600244
  var valid_600245 = header.getOrDefault("X-Amz-Signature")
  valid_600245 = validateParameter(valid_600245, JString, required = false,
                                 default = nil)
  if valid_600245 != nil:
    section.add "X-Amz-Signature", valid_600245
  var valid_600246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600246 = validateParameter(valid_600246, JString, required = false,
                                 default = nil)
  if valid_600246 != nil:
    section.add "X-Amz-SignedHeaders", valid_600246
  var valid_600247 = header.getOrDefault("X-Amz-Credential")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Credential", valid_600247
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600248 = formData.getOrDefault("DBParameterGroupName")
  valid_600248 = validateParameter(valid_600248, JString, required = true,
                                 default = nil)
  if valid_600248 != nil:
    section.add "DBParameterGroupName", valid_600248
  var valid_600249 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600249 = validateParameter(valid_600249, JString, required = true,
                                 default = nil)
  if valid_600249 != nil:
    section.add "DBParameterGroupFamily", valid_600249
  var valid_600250 = formData.getOrDefault("Description")
  valid_600250 = validateParameter(valid_600250, JString, required = true,
                                 default = nil)
  if valid_600250 != nil:
    section.add "Description", valid_600250
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600251: Call_PostCreateDBParameterGroup_600236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600251.validator(path, query, header, formData, body)
  let scheme = call_600251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600251.url(scheme.get, call_600251.host, call_600251.base,
                         call_600251.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600251, url, valid)

proc call*(call_600252: Call_PostCreateDBParameterGroup_600236;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_600253 = newJObject()
  var formData_600254 = newJObject()
  add(formData_600254, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600253, "Action", newJString(Action))
  add(formData_600254, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_600253, "Version", newJString(Version))
  add(formData_600254, "Description", newJString(Description))
  result = call_600252.call(nil, query_600253, nil, formData_600254, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_600236(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_600237, base: "/",
    url: url_PostCreateDBParameterGroup_600238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_600218 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBParameterGroup_600220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_600219(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600221 = query.getOrDefault("Description")
  valid_600221 = validateParameter(valid_600221, JString, required = true,
                                 default = nil)
  if valid_600221 != nil:
    section.add "Description", valid_600221
  var valid_600222 = query.getOrDefault("DBParameterGroupFamily")
  valid_600222 = validateParameter(valid_600222, JString, required = true,
                                 default = nil)
  if valid_600222 != nil:
    section.add "DBParameterGroupFamily", valid_600222
  var valid_600223 = query.getOrDefault("DBParameterGroupName")
  valid_600223 = validateParameter(valid_600223, JString, required = true,
                                 default = nil)
  if valid_600223 != nil:
    section.add "DBParameterGroupName", valid_600223
  var valid_600224 = query.getOrDefault("Action")
  valid_600224 = validateParameter(valid_600224, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_600224 != nil:
    section.add "Action", valid_600224
  var valid_600225 = query.getOrDefault("Version")
  valid_600225 = validateParameter(valid_600225, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600225 != nil:
    section.add "Version", valid_600225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600226 = header.getOrDefault("X-Amz-Date")
  valid_600226 = validateParameter(valid_600226, JString, required = false,
                                 default = nil)
  if valid_600226 != nil:
    section.add "X-Amz-Date", valid_600226
  var valid_600227 = header.getOrDefault("X-Amz-Security-Token")
  valid_600227 = validateParameter(valid_600227, JString, required = false,
                                 default = nil)
  if valid_600227 != nil:
    section.add "X-Amz-Security-Token", valid_600227
  var valid_600228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600228 = validateParameter(valid_600228, JString, required = false,
                                 default = nil)
  if valid_600228 != nil:
    section.add "X-Amz-Content-Sha256", valid_600228
  var valid_600229 = header.getOrDefault("X-Amz-Algorithm")
  valid_600229 = validateParameter(valid_600229, JString, required = false,
                                 default = nil)
  if valid_600229 != nil:
    section.add "X-Amz-Algorithm", valid_600229
  var valid_600230 = header.getOrDefault("X-Amz-Signature")
  valid_600230 = validateParameter(valid_600230, JString, required = false,
                                 default = nil)
  if valid_600230 != nil:
    section.add "X-Amz-Signature", valid_600230
  var valid_600231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600231 = validateParameter(valid_600231, JString, required = false,
                                 default = nil)
  if valid_600231 != nil:
    section.add "X-Amz-SignedHeaders", valid_600231
  var valid_600232 = header.getOrDefault("X-Amz-Credential")
  valid_600232 = validateParameter(valid_600232, JString, required = false,
                                 default = nil)
  if valid_600232 != nil:
    section.add "X-Amz-Credential", valid_600232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600233: Call_GetCreateDBParameterGroup_600218; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600233.validator(path, query, header, formData, body)
  let scheme = call_600233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600233.url(scheme.get, call_600233.host, call_600233.base,
                         call_600233.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600233, url, valid)

proc call*(call_600234: Call_GetCreateDBParameterGroup_600218; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600235 = newJObject()
  add(query_600235, "Description", newJString(Description))
  add(query_600235, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_600235, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600235, "Action", newJString(Action))
  add(query_600235, "Version", newJString(Version))
  result = call_600234.call(nil, query_600235, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_600218(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_600219, base: "/",
    url: url_GetCreateDBParameterGroup_600220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_600272 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSecurityGroup_600274(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_600273(path: JsonNode; query: JsonNode;
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
  var valid_600275 = query.getOrDefault("Action")
  valid_600275 = validateParameter(valid_600275, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_600275 != nil:
    section.add "Action", valid_600275
  var valid_600276 = query.getOrDefault("Version")
  valid_600276 = validateParameter(valid_600276, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600276 != nil:
    section.add "Version", valid_600276
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Content-Sha256", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Algorithm")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Algorithm", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Signature")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Signature", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-SignedHeaders", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Credential")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Credential", valid_600283
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600284 = formData.getOrDefault("DBSecurityGroupName")
  valid_600284 = validateParameter(valid_600284, JString, required = true,
                                 default = nil)
  if valid_600284 != nil:
    section.add "DBSecurityGroupName", valid_600284
  var valid_600285 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_600285 = validateParameter(valid_600285, JString, required = true,
                                 default = nil)
  if valid_600285 != nil:
    section.add "DBSecurityGroupDescription", valid_600285
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600286: Call_PostCreateDBSecurityGroup_600272; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600286.validator(path, query, header, formData, body)
  let scheme = call_600286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600286.url(scheme.get, call_600286.host, call_600286.base,
                         call_600286.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600286, url, valid)

proc call*(call_600287: Call_PostCreateDBSecurityGroup_600272;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_600288 = newJObject()
  var formData_600289 = newJObject()
  add(formData_600289, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600288, "Action", newJString(Action))
  add(formData_600289, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_600288, "Version", newJString(Version))
  result = call_600287.call(nil, query_600288, nil, formData_600289, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_600272(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_600273, base: "/",
    url: url_PostCreateDBSecurityGroup_600274,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_600255 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSecurityGroup_600257(protocol: Scheme; host: string;
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

proc validate_GetCreateDBSecurityGroup_600256(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600258 = query.getOrDefault("DBSecurityGroupName")
  valid_600258 = validateParameter(valid_600258, JString, required = true,
                                 default = nil)
  if valid_600258 != nil:
    section.add "DBSecurityGroupName", valid_600258
  var valid_600259 = query.getOrDefault("DBSecurityGroupDescription")
  valid_600259 = validateParameter(valid_600259, JString, required = true,
                                 default = nil)
  if valid_600259 != nil:
    section.add "DBSecurityGroupDescription", valid_600259
  var valid_600260 = query.getOrDefault("Action")
  valid_600260 = validateParameter(valid_600260, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_600260 != nil:
    section.add "Action", valid_600260
  var valid_600261 = query.getOrDefault("Version")
  valid_600261 = validateParameter(valid_600261, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600261 != nil:
    section.add "Version", valid_600261
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600262 = header.getOrDefault("X-Amz-Date")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Date", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Security-Token")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Security-Token", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Content-Sha256", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Algorithm")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Algorithm", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-Signature")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-Signature", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-SignedHeaders", valid_600267
  var valid_600268 = header.getOrDefault("X-Amz-Credential")
  valid_600268 = validateParameter(valid_600268, JString, required = false,
                                 default = nil)
  if valid_600268 != nil:
    section.add "X-Amz-Credential", valid_600268
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_GetCreateDBSecurityGroup_600255; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_GetCreateDBSecurityGroup_600255;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600271 = newJObject()
  add(query_600271, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600271, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_600271, "Action", newJString(Action))
  add(query_600271, "Version", newJString(Version))
  result = call_600270.call(nil, query_600271, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_600255(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_600256, base: "/",
    url: url_GetCreateDBSecurityGroup_600257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_600307 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSnapshot_600309(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_600308(path: JsonNode; query: JsonNode;
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
  var valid_600310 = query.getOrDefault("Action")
  valid_600310 = validateParameter(valid_600310, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_600310 != nil:
    section.add "Action", valid_600310
  var valid_600311 = query.getOrDefault("Version")
  valid_600311 = validateParameter(valid_600311, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600311 != nil:
    section.add "Version", valid_600311
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600312 = header.getOrDefault("X-Amz-Date")
  valid_600312 = validateParameter(valid_600312, JString, required = false,
                                 default = nil)
  if valid_600312 != nil:
    section.add "X-Amz-Date", valid_600312
  var valid_600313 = header.getOrDefault("X-Amz-Security-Token")
  valid_600313 = validateParameter(valid_600313, JString, required = false,
                                 default = nil)
  if valid_600313 != nil:
    section.add "X-Amz-Security-Token", valid_600313
  var valid_600314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600314 = validateParameter(valid_600314, JString, required = false,
                                 default = nil)
  if valid_600314 != nil:
    section.add "X-Amz-Content-Sha256", valid_600314
  var valid_600315 = header.getOrDefault("X-Amz-Algorithm")
  valid_600315 = validateParameter(valid_600315, JString, required = false,
                                 default = nil)
  if valid_600315 != nil:
    section.add "X-Amz-Algorithm", valid_600315
  var valid_600316 = header.getOrDefault("X-Amz-Signature")
  valid_600316 = validateParameter(valid_600316, JString, required = false,
                                 default = nil)
  if valid_600316 != nil:
    section.add "X-Amz-Signature", valid_600316
  var valid_600317 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600317 = validateParameter(valid_600317, JString, required = false,
                                 default = nil)
  if valid_600317 != nil:
    section.add "X-Amz-SignedHeaders", valid_600317
  var valid_600318 = header.getOrDefault("X-Amz-Credential")
  valid_600318 = validateParameter(valid_600318, JString, required = false,
                                 default = nil)
  if valid_600318 != nil:
    section.add "X-Amz-Credential", valid_600318
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600319 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600319 = validateParameter(valid_600319, JString, required = true,
                                 default = nil)
  if valid_600319 != nil:
    section.add "DBInstanceIdentifier", valid_600319
  var valid_600320 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600320 = validateParameter(valid_600320, JString, required = true,
                                 default = nil)
  if valid_600320 != nil:
    section.add "DBSnapshotIdentifier", valid_600320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600321: Call_PostCreateDBSnapshot_600307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600321.validator(path, query, header, formData, body)
  let scheme = call_600321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600321.url(scheme.get, call_600321.host, call_600321.base,
                         call_600321.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600321, url, valid)

proc call*(call_600322: Call_PostCreateDBSnapshot_600307;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600323 = newJObject()
  var formData_600324 = newJObject()
  add(formData_600324, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600324, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600323, "Action", newJString(Action))
  add(query_600323, "Version", newJString(Version))
  result = call_600322.call(nil, query_600323, nil, formData_600324, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_600307(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_600308, base: "/",
    url: url_PostCreateDBSnapshot_600309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_600290 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSnapshot_600292(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_600291(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600293 = query.getOrDefault("Action")
  valid_600293 = validateParameter(valid_600293, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_600293 != nil:
    section.add "Action", valid_600293
  var valid_600294 = query.getOrDefault("Version")
  valid_600294 = validateParameter(valid_600294, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600294 != nil:
    section.add "Version", valid_600294
  var valid_600295 = query.getOrDefault("DBInstanceIdentifier")
  valid_600295 = validateParameter(valid_600295, JString, required = true,
                                 default = nil)
  if valid_600295 != nil:
    section.add "DBInstanceIdentifier", valid_600295
  var valid_600296 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600296 = validateParameter(valid_600296, JString, required = true,
                                 default = nil)
  if valid_600296 != nil:
    section.add "DBSnapshotIdentifier", valid_600296
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600297 = header.getOrDefault("X-Amz-Date")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Date", valid_600297
  var valid_600298 = header.getOrDefault("X-Amz-Security-Token")
  valid_600298 = validateParameter(valid_600298, JString, required = false,
                                 default = nil)
  if valid_600298 != nil:
    section.add "X-Amz-Security-Token", valid_600298
  var valid_600299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600299 = validateParameter(valid_600299, JString, required = false,
                                 default = nil)
  if valid_600299 != nil:
    section.add "X-Amz-Content-Sha256", valid_600299
  var valid_600300 = header.getOrDefault("X-Amz-Algorithm")
  valid_600300 = validateParameter(valid_600300, JString, required = false,
                                 default = nil)
  if valid_600300 != nil:
    section.add "X-Amz-Algorithm", valid_600300
  var valid_600301 = header.getOrDefault("X-Amz-Signature")
  valid_600301 = validateParameter(valid_600301, JString, required = false,
                                 default = nil)
  if valid_600301 != nil:
    section.add "X-Amz-Signature", valid_600301
  var valid_600302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600302 = validateParameter(valid_600302, JString, required = false,
                                 default = nil)
  if valid_600302 != nil:
    section.add "X-Amz-SignedHeaders", valid_600302
  var valid_600303 = header.getOrDefault("X-Amz-Credential")
  valid_600303 = validateParameter(valid_600303, JString, required = false,
                                 default = nil)
  if valid_600303 != nil:
    section.add "X-Amz-Credential", valid_600303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600304: Call_GetCreateDBSnapshot_600290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600304.validator(path, query, header, formData, body)
  let scheme = call_600304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600304.url(scheme.get, call_600304.host, call_600304.base,
                         call_600304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600304, url, valid)

proc call*(call_600305: Call_GetCreateDBSnapshot_600290;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_600306 = newJObject()
  add(query_600306, "Action", newJString(Action))
  add(query_600306, "Version", newJString(Version))
  add(query_600306, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600306, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600305.call(nil, query_600306, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_600290(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_600291, base: "/",
    url: url_GetCreateDBSnapshot_600292, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_600343 = ref object of OpenApiRestCall_599352
proc url_PostCreateDBSubnetGroup_600345(protocol: Scheme; host: string; base: string;
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

proc validate_PostCreateDBSubnetGroup_600344(path: JsonNode; query: JsonNode;
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
  var valid_600346 = query.getOrDefault("Action")
  valid_600346 = validateParameter(valid_600346, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600346 != nil:
    section.add "Action", valid_600346
  var valid_600347 = query.getOrDefault("Version")
  valid_600347 = validateParameter(valid_600347, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600355 = formData.getOrDefault("DBSubnetGroupName")
  valid_600355 = validateParameter(valid_600355, JString, required = true,
                                 default = nil)
  if valid_600355 != nil:
    section.add "DBSubnetGroupName", valid_600355
  var valid_600356 = formData.getOrDefault("SubnetIds")
  valid_600356 = validateParameter(valid_600356, JArray, required = true, default = nil)
  if valid_600356 != nil:
    section.add "SubnetIds", valid_600356
  var valid_600357 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_600357 = validateParameter(valid_600357, JString, required = true,
                                 default = nil)
  if valid_600357 != nil:
    section.add "DBSubnetGroupDescription", valid_600357
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600358: Call_PostCreateDBSubnetGroup_600343; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600358.validator(path, query, header, formData, body)
  let scheme = call_600358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600358.url(scheme.get, call_600358.host, call_600358.base,
                         call_600358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600358, url, valid)

proc call*(call_600359: Call_PostCreateDBSubnetGroup_600343;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_600360 = newJObject()
  var formData_600361 = newJObject()
  add(formData_600361, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_600361.add "SubnetIds", SubnetIds
  add(query_600360, "Action", newJString(Action))
  add(formData_600361, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600360, "Version", newJString(Version))
  result = call_600359.call(nil, query_600360, nil, formData_600361, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_600343(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_600344, base: "/",
    url: url_PostCreateDBSubnetGroup_600345, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_600325 = ref object of OpenApiRestCall_599352
proc url_GetCreateDBSubnetGroup_600327(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_600326(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600328 = query.getOrDefault("Action")
  valid_600328 = validateParameter(valid_600328, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_600328 != nil:
    section.add "Action", valid_600328
  var valid_600329 = query.getOrDefault("DBSubnetGroupName")
  valid_600329 = validateParameter(valid_600329, JString, required = true,
                                 default = nil)
  if valid_600329 != nil:
    section.add "DBSubnetGroupName", valid_600329
  var valid_600330 = query.getOrDefault("SubnetIds")
  valid_600330 = validateParameter(valid_600330, JArray, required = true, default = nil)
  if valid_600330 != nil:
    section.add "SubnetIds", valid_600330
  var valid_600331 = query.getOrDefault("DBSubnetGroupDescription")
  valid_600331 = validateParameter(valid_600331, JString, required = true,
                                 default = nil)
  if valid_600331 != nil:
    section.add "DBSubnetGroupDescription", valid_600331
  var valid_600332 = query.getOrDefault("Version")
  valid_600332 = validateParameter(valid_600332, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600332 != nil:
    section.add "Version", valid_600332
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600333 = header.getOrDefault("X-Amz-Date")
  valid_600333 = validateParameter(valid_600333, JString, required = false,
                                 default = nil)
  if valid_600333 != nil:
    section.add "X-Amz-Date", valid_600333
  var valid_600334 = header.getOrDefault("X-Amz-Security-Token")
  valid_600334 = validateParameter(valid_600334, JString, required = false,
                                 default = nil)
  if valid_600334 != nil:
    section.add "X-Amz-Security-Token", valid_600334
  var valid_600335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Content-Sha256", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Algorithm")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Algorithm", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Signature")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Signature", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-SignedHeaders", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Credential")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Credential", valid_600339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600340: Call_GetCreateDBSubnetGroup_600325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600340.validator(path, query, header, formData, body)
  let scheme = call_600340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600340.url(scheme.get, call_600340.host, call_600340.base,
                         call_600340.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600340, url, valid)

proc call*(call_600341: Call_GetCreateDBSubnetGroup_600325;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_600342 = newJObject()
  add(query_600342, "Action", newJString(Action))
  add(query_600342, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_600342.add "SubnetIds", SubnetIds
  add(query_600342, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_600342, "Version", newJString(Version))
  result = call_600341.call(nil, query_600342, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_600325(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_600326, base: "/",
    url: url_GetCreateDBSubnetGroup_600327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_600383 = ref object of OpenApiRestCall_599352
proc url_PostCreateEventSubscription_600385(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_600384(path: JsonNode; query: JsonNode;
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
  var valid_600386 = query.getOrDefault("Action")
  valid_600386 = validateParameter(valid_600386, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_600386 != nil:
    section.add "Action", valid_600386
  var valid_600387 = query.getOrDefault("Version")
  valid_600387 = validateParameter(valid_600387, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600387 != nil:
    section.add "Version", valid_600387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600388 = header.getOrDefault("X-Amz-Date")
  valid_600388 = validateParameter(valid_600388, JString, required = false,
                                 default = nil)
  if valid_600388 != nil:
    section.add "X-Amz-Date", valid_600388
  var valid_600389 = header.getOrDefault("X-Amz-Security-Token")
  valid_600389 = validateParameter(valid_600389, JString, required = false,
                                 default = nil)
  if valid_600389 != nil:
    section.add "X-Amz-Security-Token", valid_600389
  var valid_600390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600390 = validateParameter(valid_600390, JString, required = false,
                                 default = nil)
  if valid_600390 != nil:
    section.add "X-Amz-Content-Sha256", valid_600390
  var valid_600391 = header.getOrDefault("X-Amz-Algorithm")
  valid_600391 = validateParameter(valid_600391, JString, required = false,
                                 default = nil)
  if valid_600391 != nil:
    section.add "X-Amz-Algorithm", valid_600391
  var valid_600392 = header.getOrDefault("X-Amz-Signature")
  valid_600392 = validateParameter(valid_600392, JString, required = false,
                                 default = nil)
  if valid_600392 != nil:
    section.add "X-Amz-Signature", valid_600392
  var valid_600393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600393 = validateParameter(valid_600393, JString, required = false,
                                 default = nil)
  if valid_600393 != nil:
    section.add "X-Amz-SignedHeaders", valid_600393
  var valid_600394 = header.getOrDefault("X-Amz-Credential")
  valid_600394 = validateParameter(valid_600394, JString, required = false,
                                 default = nil)
  if valid_600394 != nil:
    section.add "X-Amz-Credential", valid_600394
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_600395 = formData.getOrDefault("Enabled")
  valid_600395 = validateParameter(valid_600395, JBool, required = false, default = nil)
  if valid_600395 != nil:
    section.add "Enabled", valid_600395
  var valid_600396 = formData.getOrDefault("EventCategories")
  valid_600396 = validateParameter(valid_600396, JArray, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "EventCategories", valid_600396
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_600397 = formData.getOrDefault("SnsTopicArn")
  valid_600397 = validateParameter(valid_600397, JString, required = true,
                                 default = nil)
  if valid_600397 != nil:
    section.add "SnsTopicArn", valid_600397
  var valid_600398 = formData.getOrDefault("SourceIds")
  valid_600398 = validateParameter(valid_600398, JArray, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "SourceIds", valid_600398
  var valid_600399 = formData.getOrDefault("SubscriptionName")
  valid_600399 = validateParameter(valid_600399, JString, required = true,
                                 default = nil)
  if valid_600399 != nil:
    section.add "SubscriptionName", valid_600399
  var valid_600400 = formData.getOrDefault("SourceType")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "SourceType", valid_600400
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600401: Call_PostCreateEventSubscription_600383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600401.validator(path, query, header, formData, body)
  let scheme = call_600401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600401.url(scheme.get, call_600401.host, call_600401.base,
                         call_600401.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600401, url, valid)

proc call*(call_600402: Call_PostCreateEventSubscription_600383;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postCreateEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_600403 = newJObject()
  var formData_600404 = newJObject()
  add(formData_600404, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_600404.add "EventCategories", EventCategories
  add(formData_600404, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_600404.add "SourceIds", SourceIds
  add(formData_600404, "SubscriptionName", newJString(SubscriptionName))
  add(query_600403, "Action", newJString(Action))
  add(query_600403, "Version", newJString(Version))
  add(formData_600404, "SourceType", newJString(SourceType))
  result = call_600402.call(nil, query_600403, nil, formData_600404, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_600383(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_600384, base: "/",
    url: url_PostCreateEventSubscription_600385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_600362 = ref object of OpenApiRestCall_599352
proc url_GetCreateEventSubscription_600364(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_600363(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600365 = query.getOrDefault("SourceType")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "SourceType", valid_600365
  var valid_600366 = query.getOrDefault("SourceIds")
  valid_600366 = validateParameter(valid_600366, JArray, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "SourceIds", valid_600366
  var valid_600367 = query.getOrDefault("Enabled")
  valid_600367 = validateParameter(valid_600367, JBool, required = false, default = nil)
  if valid_600367 != nil:
    section.add "Enabled", valid_600367
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600368 = query.getOrDefault("Action")
  valid_600368 = validateParameter(valid_600368, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_600368 != nil:
    section.add "Action", valid_600368
  var valid_600369 = query.getOrDefault("SnsTopicArn")
  valid_600369 = validateParameter(valid_600369, JString, required = true,
                                 default = nil)
  if valid_600369 != nil:
    section.add "SnsTopicArn", valid_600369
  var valid_600370 = query.getOrDefault("EventCategories")
  valid_600370 = validateParameter(valid_600370, JArray, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "EventCategories", valid_600370
  var valid_600371 = query.getOrDefault("SubscriptionName")
  valid_600371 = validateParameter(valid_600371, JString, required = true,
                                 default = nil)
  if valid_600371 != nil:
    section.add "SubscriptionName", valid_600371
  var valid_600372 = query.getOrDefault("Version")
  valid_600372 = validateParameter(valid_600372, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600372 != nil:
    section.add "Version", valid_600372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600373 = header.getOrDefault("X-Amz-Date")
  valid_600373 = validateParameter(valid_600373, JString, required = false,
                                 default = nil)
  if valid_600373 != nil:
    section.add "X-Amz-Date", valid_600373
  var valid_600374 = header.getOrDefault("X-Amz-Security-Token")
  valid_600374 = validateParameter(valid_600374, JString, required = false,
                                 default = nil)
  if valid_600374 != nil:
    section.add "X-Amz-Security-Token", valid_600374
  var valid_600375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600375 = validateParameter(valid_600375, JString, required = false,
                                 default = nil)
  if valid_600375 != nil:
    section.add "X-Amz-Content-Sha256", valid_600375
  var valid_600376 = header.getOrDefault("X-Amz-Algorithm")
  valid_600376 = validateParameter(valid_600376, JString, required = false,
                                 default = nil)
  if valid_600376 != nil:
    section.add "X-Amz-Algorithm", valid_600376
  var valid_600377 = header.getOrDefault("X-Amz-Signature")
  valid_600377 = validateParameter(valid_600377, JString, required = false,
                                 default = nil)
  if valid_600377 != nil:
    section.add "X-Amz-Signature", valid_600377
  var valid_600378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600378 = validateParameter(valid_600378, JString, required = false,
                                 default = nil)
  if valid_600378 != nil:
    section.add "X-Amz-SignedHeaders", valid_600378
  var valid_600379 = header.getOrDefault("X-Amz-Credential")
  valid_600379 = validateParameter(valid_600379, JString, required = false,
                                 default = nil)
  if valid_600379 != nil:
    section.add "X-Amz-Credential", valid_600379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600380: Call_GetCreateEventSubscription_600362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600380.validator(path, query, header, formData, body)
  let scheme = call_600380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600380.url(scheme.get, call_600380.host, call_600380.base,
                         call_600380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600380, url, valid)

proc call*(call_600381: Call_GetCreateEventSubscription_600362;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2013-02-12"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_600382 = newJObject()
  add(query_600382, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_600382.add "SourceIds", SourceIds
  add(query_600382, "Enabled", newJBool(Enabled))
  add(query_600382, "Action", newJString(Action))
  add(query_600382, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_600382.add "EventCategories", EventCategories
  add(query_600382, "SubscriptionName", newJString(SubscriptionName))
  add(query_600382, "Version", newJString(Version))
  result = call_600381.call(nil, query_600382, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_600362(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_600363, base: "/",
    url: url_GetCreateEventSubscription_600364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_600424 = ref object of OpenApiRestCall_599352
proc url_PostCreateOptionGroup_600426(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_600425(path: JsonNode; query: JsonNode;
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
  var valid_600427 = query.getOrDefault("Action")
  valid_600427 = validateParameter(valid_600427, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_600427 != nil:
    section.add "Action", valid_600427
  var valid_600428 = query.getOrDefault("Version")
  valid_600428 = validateParameter(valid_600428, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600428 != nil:
    section.add "Version", valid_600428
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600429 = header.getOrDefault("X-Amz-Date")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Date", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Security-Token")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Security-Token", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-Content-Sha256", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Algorithm")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Algorithm", valid_600432
  var valid_600433 = header.getOrDefault("X-Amz-Signature")
  valid_600433 = validateParameter(valid_600433, JString, required = false,
                                 default = nil)
  if valid_600433 != nil:
    section.add "X-Amz-Signature", valid_600433
  var valid_600434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600434 = validateParameter(valid_600434, JString, required = false,
                                 default = nil)
  if valid_600434 != nil:
    section.add "X-Amz-SignedHeaders", valid_600434
  var valid_600435 = header.getOrDefault("X-Amz-Credential")
  valid_600435 = validateParameter(valid_600435, JString, required = false,
                                 default = nil)
  if valid_600435 != nil:
    section.add "X-Amz-Credential", valid_600435
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_600436 = formData.getOrDefault("MajorEngineVersion")
  valid_600436 = validateParameter(valid_600436, JString, required = true,
                                 default = nil)
  if valid_600436 != nil:
    section.add "MajorEngineVersion", valid_600436
  var valid_600437 = formData.getOrDefault("OptionGroupName")
  valid_600437 = validateParameter(valid_600437, JString, required = true,
                                 default = nil)
  if valid_600437 != nil:
    section.add "OptionGroupName", valid_600437
  var valid_600438 = formData.getOrDefault("EngineName")
  valid_600438 = validateParameter(valid_600438, JString, required = true,
                                 default = nil)
  if valid_600438 != nil:
    section.add "EngineName", valid_600438
  var valid_600439 = formData.getOrDefault("OptionGroupDescription")
  valid_600439 = validateParameter(valid_600439, JString, required = true,
                                 default = nil)
  if valid_600439 != nil:
    section.add "OptionGroupDescription", valid_600439
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600440: Call_PostCreateOptionGroup_600424; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600440.validator(path, query, header, formData, body)
  let scheme = call_600440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600440.url(scheme.get, call_600440.host, call_600440.base,
                         call_600440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600440, url, valid)

proc call*(call_600441: Call_PostCreateOptionGroup_600424;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_600442 = newJObject()
  var formData_600443 = newJObject()
  add(formData_600443, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_600443, "OptionGroupName", newJString(OptionGroupName))
  add(query_600442, "Action", newJString(Action))
  add(formData_600443, "EngineName", newJString(EngineName))
  add(formData_600443, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_600442, "Version", newJString(Version))
  result = call_600441.call(nil, query_600442, nil, formData_600443, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_600424(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_600425, base: "/",
    url: url_PostCreateOptionGroup_600426, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_600405 = ref object of OpenApiRestCall_599352
proc url_GetCreateOptionGroup_600407(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_600406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600408 = query.getOrDefault("OptionGroupName")
  valid_600408 = validateParameter(valid_600408, JString, required = true,
                                 default = nil)
  if valid_600408 != nil:
    section.add "OptionGroupName", valid_600408
  var valid_600409 = query.getOrDefault("OptionGroupDescription")
  valid_600409 = validateParameter(valid_600409, JString, required = true,
                                 default = nil)
  if valid_600409 != nil:
    section.add "OptionGroupDescription", valid_600409
  var valid_600410 = query.getOrDefault("Action")
  valid_600410 = validateParameter(valid_600410, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_600410 != nil:
    section.add "Action", valid_600410
  var valid_600411 = query.getOrDefault("Version")
  valid_600411 = validateParameter(valid_600411, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600411 != nil:
    section.add "Version", valid_600411
  var valid_600412 = query.getOrDefault("EngineName")
  valid_600412 = validateParameter(valid_600412, JString, required = true,
                                 default = nil)
  if valid_600412 != nil:
    section.add "EngineName", valid_600412
  var valid_600413 = query.getOrDefault("MajorEngineVersion")
  valid_600413 = validateParameter(valid_600413, JString, required = true,
                                 default = nil)
  if valid_600413 != nil:
    section.add "MajorEngineVersion", valid_600413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600414 = header.getOrDefault("X-Amz-Date")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Date", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Security-Token")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Security-Token", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Content-Sha256", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-Algorithm")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-Algorithm", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Signature")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Signature", valid_600418
  var valid_600419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600419 = validateParameter(valid_600419, JString, required = false,
                                 default = nil)
  if valid_600419 != nil:
    section.add "X-Amz-SignedHeaders", valid_600419
  var valid_600420 = header.getOrDefault("X-Amz-Credential")
  valid_600420 = validateParameter(valid_600420, JString, required = false,
                                 default = nil)
  if valid_600420 != nil:
    section.add "X-Amz-Credential", valid_600420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600421: Call_GetCreateOptionGroup_600405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600421.validator(path, query, header, formData, body)
  let scheme = call_600421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600421.url(scheme.get, call_600421.host, call_600421.base,
                         call_600421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600421, url, valid)

proc call*(call_600422: Call_GetCreateOptionGroup_600405; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_600423 = newJObject()
  add(query_600423, "OptionGroupName", newJString(OptionGroupName))
  add(query_600423, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_600423, "Action", newJString(Action))
  add(query_600423, "Version", newJString(Version))
  add(query_600423, "EngineName", newJString(EngineName))
  add(query_600423, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_600422.call(nil, query_600423, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_600405(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_600406, base: "/",
    url: url_GetCreateOptionGroup_600407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_600462 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBInstance_600464(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_600463(path: JsonNode; query: JsonNode;
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
  var valid_600465 = query.getOrDefault("Action")
  valid_600465 = validateParameter(valid_600465, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600465 != nil:
    section.add "Action", valid_600465
  var valid_600466 = query.getOrDefault("Version")
  valid_600466 = validateParameter(valid_600466, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600466 != nil:
    section.add "Version", valid_600466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600467 = header.getOrDefault("X-Amz-Date")
  valid_600467 = validateParameter(valid_600467, JString, required = false,
                                 default = nil)
  if valid_600467 != nil:
    section.add "X-Amz-Date", valid_600467
  var valid_600468 = header.getOrDefault("X-Amz-Security-Token")
  valid_600468 = validateParameter(valid_600468, JString, required = false,
                                 default = nil)
  if valid_600468 != nil:
    section.add "X-Amz-Security-Token", valid_600468
  var valid_600469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600469 = validateParameter(valid_600469, JString, required = false,
                                 default = nil)
  if valid_600469 != nil:
    section.add "X-Amz-Content-Sha256", valid_600469
  var valid_600470 = header.getOrDefault("X-Amz-Algorithm")
  valid_600470 = validateParameter(valid_600470, JString, required = false,
                                 default = nil)
  if valid_600470 != nil:
    section.add "X-Amz-Algorithm", valid_600470
  var valid_600471 = header.getOrDefault("X-Amz-Signature")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Signature", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-SignedHeaders", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Credential")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Credential", valid_600473
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600474 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600474 = validateParameter(valid_600474, JString, required = true,
                                 default = nil)
  if valid_600474 != nil:
    section.add "DBInstanceIdentifier", valid_600474
  var valid_600475 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600475
  var valid_600476 = formData.getOrDefault("SkipFinalSnapshot")
  valid_600476 = validateParameter(valid_600476, JBool, required = false, default = nil)
  if valid_600476 != nil:
    section.add "SkipFinalSnapshot", valid_600476
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600477: Call_PostDeleteDBInstance_600462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600477.validator(path, query, header, formData, body)
  let scheme = call_600477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600477.url(scheme.get, call_600477.host, call_600477.base,
                         call_600477.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600477, url, valid)

proc call*(call_600478: Call_PostDeleteDBInstance_600462;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_600479 = newJObject()
  var formData_600480 = newJObject()
  add(formData_600480, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600480, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600479, "Action", newJString(Action))
  add(query_600479, "Version", newJString(Version))
  add(formData_600480, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_600478.call(nil, query_600479, nil, formData_600480, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_600462(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_600463, base: "/",
    url: url_PostDeleteDBInstance_600464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_600444 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBInstance_600446(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_600445(path: JsonNode; query: JsonNode;
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
  var valid_600447 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_600447 = validateParameter(valid_600447, JString, required = false,
                                 default = nil)
  if valid_600447 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_600447
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600448 = query.getOrDefault("Action")
  valid_600448 = validateParameter(valid_600448, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_600448 != nil:
    section.add "Action", valid_600448
  var valid_600449 = query.getOrDefault("SkipFinalSnapshot")
  valid_600449 = validateParameter(valid_600449, JBool, required = false, default = nil)
  if valid_600449 != nil:
    section.add "SkipFinalSnapshot", valid_600449
  var valid_600450 = query.getOrDefault("Version")
  valid_600450 = validateParameter(valid_600450, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600450 != nil:
    section.add "Version", valid_600450
  var valid_600451 = query.getOrDefault("DBInstanceIdentifier")
  valid_600451 = validateParameter(valid_600451, JString, required = true,
                                 default = nil)
  if valid_600451 != nil:
    section.add "DBInstanceIdentifier", valid_600451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600452 = header.getOrDefault("X-Amz-Date")
  valid_600452 = validateParameter(valid_600452, JString, required = false,
                                 default = nil)
  if valid_600452 != nil:
    section.add "X-Amz-Date", valid_600452
  var valid_600453 = header.getOrDefault("X-Amz-Security-Token")
  valid_600453 = validateParameter(valid_600453, JString, required = false,
                                 default = nil)
  if valid_600453 != nil:
    section.add "X-Amz-Security-Token", valid_600453
  var valid_600454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600454 = validateParameter(valid_600454, JString, required = false,
                                 default = nil)
  if valid_600454 != nil:
    section.add "X-Amz-Content-Sha256", valid_600454
  var valid_600455 = header.getOrDefault("X-Amz-Algorithm")
  valid_600455 = validateParameter(valid_600455, JString, required = false,
                                 default = nil)
  if valid_600455 != nil:
    section.add "X-Amz-Algorithm", valid_600455
  var valid_600456 = header.getOrDefault("X-Amz-Signature")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Signature", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-SignedHeaders", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Credential")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Credential", valid_600458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600459: Call_GetDeleteDBInstance_600444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600459.validator(path, query, header, formData, body)
  let scheme = call_600459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600459.url(scheme.get, call_600459.host, call_600459.base,
                         call_600459.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600459, url, valid)

proc call*(call_600460: Call_GetDeleteDBInstance_600444;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_600461 = newJObject()
  add(query_600461, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_600461, "Action", newJString(Action))
  add(query_600461, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_600461, "Version", newJString(Version))
  add(query_600461, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600460.call(nil, query_600461, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_600444(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_600445, base: "/",
    url: url_GetDeleteDBInstance_600446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_600497 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBParameterGroup_600499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_600498(path: JsonNode; query: JsonNode;
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
  var valid_600500 = query.getOrDefault("Action")
  valid_600500 = validateParameter(valid_600500, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_600500 != nil:
    section.add "Action", valid_600500
  var valid_600501 = query.getOrDefault("Version")
  valid_600501 = validateParameter(valid_600501, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600501 != nil:
    section.add "Version", valid_600501
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600502 = header.getOrDefault("X-Amz-Date")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "X-Amz-Date", valid_600502
  var valid_600503 = header.getOrDefault("X-Amz-Security-Token")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "X-Amz-Security-Token", valid_600503
  var valid_600504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "X-Amz-Content-Sha256", valid_600504
  var valid_600505 = header.getOrDefault("X-Amz-Algorithm")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "X-Amz-Algorithm", valid_600505
  var valid_600506 = header.getOrDefault("X-Amz-Signature")
  valid_600506 = validateParameter(valid_600506, JString, required = false,
                                 default = nil)
  if valid_600506 != nil:
    section.add "X-Amz-Signature", valid_600506
  var valid_600507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "X-Amz-SignedHeaders", valid_600507
  var valid_600508 = header.getOrDefault("X-Amz-Credential")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "X-Amz-Credential", valid_600508
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600509 = formData.getOrDefault("DBParameterGroupName")
  valid_600509 = validateParameter(valid_600509, JString, required = true,
                                 default = nil)
  if valid_600509 != nil:
    section.add "DBParameterGroupName", valid_600509
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600510: Call_PostDeleteDBParameterGroup_600497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600510.validator(path, query, header, formData, body)
  let scheme = call_600510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600510.url(scheme.get, call_600510.host, call_600510.base,
                         call_600510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600510, url, valid)

proc call*(call_600511: Call_PostDeleteDBParameterGroup_600497;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600512 = newJObject()
  var formData_600513 = newJObject()
  add(formData_600513, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600512, "Action", newJString(Action))
  add(query_600512, "Version", newJString(Version))
  result = call_600511.call(nil, query_600512, nil, formData_600513, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_600497(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_600498, base: "/",
    url: url_PostDeleteDBParameterGroup_600499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_600481 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBParameterGroup_600483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_600482(path: JsonNode; query: JsonNode;
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
  var valid_600484 = query.getOrDefault("DBParameterGroupName")
  valid_600484 = validateParameter(valid_600484, JString, required = true,
                                 default = nil)
  if valid_600484 != nil:
    section.add "DBParameterGroupName", valid_600484
  var valid_600485 = query.getOrDefault("Action")
  valid_600485 = validateParameter(valid_600485, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_600485 != nil:
    section.add "Action", valid_600485
  var valid_600486 = query.getOrDefault("Version")
  valid_600486 = validateParameter(valid_600486, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600494: Call_GetDeleteDBParameterGroup_600481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600494.validator(path, query, header, formData, body)
  let scheme = call_600494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600494.url(scheme.get, call_600494.host, call_600494.base,
                         call_600494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600494, url, valid)

proc call*(call_600495: Call_GetDeleteDBParameterGroup_600481;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600496 = newJObject()
  add(query_600496, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600496, "Action", newJString(Action))
  add(query_600496, "Version", newJString(Version))
  result = call_600495.call(nil, query_600496, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_600481(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_600482, base: "/",
    url: url_GetDeleteDBParameterGroup_600483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_600530 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSecurityGroup_600532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_600531(path: JsonNode; query: JsonNode;
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
  var valid_600533 = query.getOrDefault("Action")
  valid_600533 = validateParameter(valid_600533, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_600533 != nil:
    section.add "Action", valid_600533
  var valid_600534 = query.getOrDefault("Version")
  valid_600534 = validateParameter(valid_600534, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600534 != nil:
    section.add "Version", valid_600534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600535 = header.getOrDefault("X-Amz-Date")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "X-Amz-Date", valid_600535
  var valid_600536 = header.getOrDefault("X-Amz-Security-Token")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "X-Amz-Security-Token", valid_600536
  var valid_600537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "X-Amz-Content-Sha256", valid_600537
  var valid_600538 = header.getOrDefault("X-Amz-Algorithm")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Algorithm", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Signature")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Signature", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-SignedHeaders", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Credential")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Credential", valid_600541
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_600542 = formData.getOrDefault("DBSecurityGroupName")
  valid_600542 = validateParameter(valid_600542, JString, required = true,
                                 default = nil)
  if valid_600542 != nil:
    section.add "DBSecurityGroupName", valid_600542
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600543: Call_PostDeleteDBSecurityGroup_600530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600543.validator(path, query, header, formData, body)
  let scheme = call_600543.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600543.url(scheme.get, call_600543.host, call_600543.base,
                         call_600543.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600543, url, valid)

proc call*(call_600544: Call_PostDeleteDBSecurityGroup_600530;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600545 = newJObject()
  var formData_600546 = newJObject()
  add(formData_600546, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600545, "Action", newJString(Action))
  add(query_600545, "Version", newJString(Version))
  result = call_600544.call(nil, query_600545, nil, formData_600546, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_600530(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_600531, base: "/",
    url: url_PostDeleteDBSecurityGroup_600532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_600514 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSecurityGroup_600516(protocol: Scheme; host: string;
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

proc validate_GetDeleteDBSecurityGroup_600515(path: JsonNode; query: JsonNode;
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
  var valid_600517 = query.getOrDefault("DBSecurityGroupName")
  valid_600517 = validateParameter(valid_600517, JString, required = true,
                                 default = nil)
  if valid_600517 != nil:
    section.add "DBSecurityGroupName", valid_600517
  var valid_600518 = query.getOrDefault("Action")
  valid_600518 = validateParameter(valid_600518, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_600518 != nil:
    section.add "Action", valid_600518
  var valid_600519 = query.getOrDefault("Version")
  valid_600519 = validateParameter(valid_600519, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600519 != nil:
    section.add "Version", valid_600519
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600520 = header.getOrDefault("X-Amz-Date")
  valid_600520 = validateParameter(valid_600520, JString, required = false,
                                 default = nil)
  if valid_600520 != nil:
    section.add "X-Amz-Date", valid_600520
  var valid_600521 = header.getOrDefault("X-Amz-Security-Token")
  valid_600521 = validateParameter(valid_600521, JString, required = false,
                                 default = nil)
  if valid_600521 != nil:
    section.add "X-Amz-Security-Token", valid_600521
  var valid_600522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600522 = validateParameter(valid_600522, JString, required = false,
                                 default = nil)
  if valid_600522 != nil:
    section.add "X-Amz-Content-Sha256", valid_600522
  var valid_600523 = header.getOrDefault("X-Amz-Algorithm")
  valid_600523 = validateParameter(valid_600523, JString, required = false,
                                 default = nil)
  if valid_600523 != nil:
    section.add "X-Amz-Algorithm", valid_600523
  var valid_600524 = header.getOrDefault("X-Amz-Signature")
  valid_600524 = validateParameter(valid_600524, JString, required = false,
                                 default = nil)
  if valid_600524 != nil:
    section.add "X-Amz-Signature", valid_600524
  var valid_600525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600525 = validateParameter(valid_600525, JString, required = false,
                                 default = nil)
  if valid_600525 != nil:
    section.add "X-Amz-SignedHeaders", valid_600525
  var valid_600526 = header.getOrDefault("X-Amz-Credential")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "X-Amz-Credential", valid_600526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600527: Call_GetDeleteDBSecurityGroup_600514; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600527.validator(path, query, header, formData, body)
  let scheme = call_600527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600527.url(scheme.get, call_600527.host, call_600527.base,
                         call_600527.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600527, url, valid)

proc call*(call_600528: Call_GetDeleteDBSecurityGroup_600514;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600529 = newJObject()
  add(query_600529, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600529, "Action", newJString(Action))
  add(query_600529, "Version", newJString(Version))
  result = call_600528.call(nil, query_600529, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_600514(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_600515, base: "/",
    url: url_GetDeleteDBSecurityGroup_600516, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_600563 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSnapshot_600565(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_600564(path: JsonNode; query: JsonNode;
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
  var valid_600566 = query.getOrDefault("Action")
  valid_600566 = validateParameter(valid_600566, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_600566 != nil:
    section.add "Action", valid_600566
  var valid_600567 = query.getOrDefault("Version")
  valid_600567 = validateParameter(valid_600567, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600567 != nil:
    section.add "Version", valid_600567
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600568 = header.getOrDefault("X-Amz-Date")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Date", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Security-Token")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Security-Token", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Content-Sha256", valid_600570
  var valid_600571 = header.getOrDefault("X-Amz-Algorithm")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Algorithm", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Signature")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Signature", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-SignedHeaders", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Credential")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Credential", valid_600574
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_600575 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600575 = validateParameter(valid_600575, JString, required = true,
                                 default = nil)
  if valid_600575 != nil:
    section.add "DBSnapshotIdentifier", valid_600575
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600576: Call_PostDeleteDBSnapshot_600563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600576.validator(path, query, header, formData, body)
  let scheme = call_600576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600576.url(scheme.get, call_600576.host, call_600576.base,
                         call_600576.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600576, url, valid)

proc call*(call_600577: Call_PostDeleteDBSnapshot_600563;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600578 = newJObject()
  var formData_600579 = newJObject()
  add(formData_600579, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600578, "Action", newJString(Action))
  add(query_600578, "Version", newJString(Version))
  result = call_600577.call(nil, query_600578, nil, formData_600579, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_600563(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_600564, base: "/",
    url: url_PostDeleteDBSnapshot_600565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_600547 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSnapshot_600549(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_600548(path: JsonNode; query: JsonNode;
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
  var valid_600550 = query.getOrDefault("Action")
  valid_600550 = validateParameter(valid_600550, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_600550 != nil:
    section.add "Action", valid_600550
  var valid_600551 = query.getOrDefault("Version")
  valid_600551 = validateParameter(valid_600551, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600551 != nil:
    section.add "Version", valid_600551
  var valid_600552 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600552 = validateParameter(valid_600552, JString, required = true,
                                 default = nil)
  if valid_600552 != nil:
    section.add "DBSnapshotIdentifier", valid_600552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600553 = header.getOrDefault("X-Amz-Date")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Date", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Security-Token")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Security-Token", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Content-Sha256", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Algorithm")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Algorithm", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-Signature")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-Signature", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-SignedHeaders", valid_600558
  var valid_600559 = header.getOrDefault("X-Amz-Credential")
  valid_600559 = validateParameter(valid_600559, JString, required = false,
                                 default = nil)
  if valid_600559 != nil:
    section.add "X-Amz-Credential", valid_600559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600560: Call_GetDeleteDBSnapshot_600547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600560.validator(path, query, header, formData, body)
  let scheme = call_600560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600560.url(scheme.get, call_600560.host, call_600560.base,
                         call_600560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600560, url, valid)

proc call*(call_600561: Call_GetDeleteDBSnapshot_600547;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_600562 = newJObject()
  add(query_600562, "Action", newJString(Action))
  add(query_600562, "Version", newJString(Version))
  add(query_600562, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600561.call(nil, query_600562, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_600547(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_600548, base: "/",
    url: url_GetDeleteDBSnapshot_600549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_600596 = ref object of OpenApiRestCall_599352
proc url_PostDeleteDBSubnetGroup_600598(protocol: Scheme; host: string; base: string;
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

proc validate_PostDeleteDBSubnetGroup_600597(path: JsonNode; query: JsonNode;
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
  var valid_600599 = query.getOrDefault("Action")
  valid_600599 = validateParameter(valid_600599, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600599 != nil:
    section.add "Action", valid_600599
  var valid_600600 = query.getOrDefault("Version")
  valid_600600 = validateParameter(valid_600600, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600600 != nil:
    section.add "Version", valid_600600
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600601 = header.getOrDefault("X-Amz-Date")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-Date", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Security-Token")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Security-Token", valid_600602
  var valid_600603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600603 = validateParameter(valid_600603, JString, required = false,
                                 default = nil)
  if valid_600603 != nil:
    section.add "X-Amz-Content-Sha256", valid_600603
  var valid_600604 = header.getOrDefault("X-Amz-Algorithm")
  valid_600604 = validateParameter(valid_600604, JString, required = false,
                                 default = nil)
  if valid_600604 != nil:
    section.add "X-Amz-Algorithm", valid_600604
  var valid_600605 = header.getOrDefault("X-Amz-Signature")
  valid_600605 = validateParameter(valid_600605, JString, required = false,
                                 default = nil)
  if valid_600605 != nil:
    section.add "X-Amz-Signature", valid_600605
  var valid_600606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600606 = validateParameter(valid_600606, JString, required = false,
                                 default = nil)
  if valid_600606 != nil:
    section.add "X-Amz-SignedHeaders", valid_600606
  var valid_600607 = header.getOrDefault("X-Amz-Credential")
  valid_600607 = validateParameter(valid_600607, JString, required = false,
                                 default = nil)
  if valid_600607 != nil:
    section.add "X-Amz-Credential", valid_600607
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_600608 = formData.getOrDefault("DBSubnetGroupName")
  valid_600608 = validateParameter(valid_600608, JString, required = true,
                                 default = nil)
  if valid_600608 != nil:
    section.add "DBSubnetGroupName", valid_600608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600609: Call_PostDeleteDBSubnetGroup_600596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600609.validator(path, query, header, formData, body)
  let scheme = call_600609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600609.url(scheme.get, call_600609.host, call_600609.base,
                         call_600609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600609, url, valid)

proc call*(call_600610: Call_PostDeleteDBSubnetGroup_600596;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600611 = newJObject()
  var formData_600612 = newJObject()
  add(formData_600612, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600611, "Action", newJString(Action))
  add(query_600611, "Version", newJString(Version))
  result = call_600610.call(nil, query_600611, nil, formData_600612, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_600596(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_600597, base: "/",
    url: url_PostDeleteDBSubnetGroup_600598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_600580 = ref object of OpenApiRestCall_599352
proc url_GetDeleteDBSubnetGroup_600582(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_600581(path: JsonNode; query: JsonNode;
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
  var valid_600583 = query.getOrDefault("Action")
  valid_600583 = validateParameter(valid_600583, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_600583 != nil:
    section.add "Action", valid_600583
  var valid_600584 = query.getOrDefault("DBSubnetGroupName")
  valid_600584 = validateParameter(valid_600584, JString, required = true,
                                 default = nil)
  if valid_600584 != nil:
    section.add "DBSubnetGroupName", valid_600584
  var valid_600585 = query.getOrDefault("Version")
  valid_600585 = validateParameter(valid_600585, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600585 != nil:
    section.add "Version", valid_600585
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600586 = header.getOrDefault("X-Amz-Date")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Date", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-Security-Token")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-Security-Token", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Content-Sha256", valid_600588
  var valid_600589 = header.getOrDefault("X-Amz-Algorithm")
  valid_600589 = validateParameter(valid_600589, JString, required = false,
                                 default = nil)
  if valid_600589 != nil:
    section.add "X-Amz-Algorithm", valid_600589
  var valid_600590 = header.getOrDefault("X-Amz-Signature")
  valid_600590 = validateParameter(valid_600590, JString, required = false,
                                 default = nil)
  if valid_600590 != nil:
    section.add "X-Amz-Signature", valid_600590
  var valid_600591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600591 = validateParameter(valid_600591, JString, required = false,
                                 default = nil)
  if valid_600591 != nil:
    section.add "X-Amz-SignedHeaders", valid_600591
  var valid_600592 = header.getOrDefault("X-Amz-Credential")
  valid_600592 = validateParameter(valid_600592, JString, required = false,
                                 default = nil)
  if valid_600592 != nil:
    section.add "X-Amz-Credential", valid_600592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600593: Call_GetDeleteDBSubnetGroup_600580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600593.validator(path, query, header, formData, body)
  let scheme = call_600593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600593.url(scheme.get, call_600593.host, call_600593.base,
                         call_600593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600593, url, valid)

proc call*(call_600594: Call_GetDeleteDBSubnetGroup_600580;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_600595 = newJObject()
  add(query_600595, "Action", newJString(Action))
  add(query_600595, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600595, "Version", newJString(Version))
  result = call_600594.call(nil, query_600595, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_600580(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_600581, base: "/",
    url: url_GetDeleteDBSubnetGroup_600582, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_600629 = ref object of OpenApiRestCall_599352
proc url_PostDeleteEventSubscription_600631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_600630(path: JsonNode; query: JsonNode;
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
  var valid_600632 = query.getOrDefault("Action")
  valid_600632 = validateParameter(valid_600632, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_600632 != nil:
    section.add "Action", valid_600632
  var valid_600633 = query.getOrDefault("Version")
  valid_600633 = validateParameter(valid_600633, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600633 != nil:
    section.add "Version", valid_600633
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600634 = header.getOrDefault("X-Amz-Date")
  valid_600634 = validateParameter(valid_600634, JString, required = false,
                                 default = nil)
  if valid_600634 != nil:
    section.add "X-Amz-Date", valid_600634
  var valid_600635 = header.getOrDefault("X-Amz-Security-Token")
  valid_600635 = validateParameter(valid_600635, JString, required = false,
                                 default = nil)
  if valid_600635 != nil:
    section.add "X-Amz-Security-Token", valid_600635
  var valid_600636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600636 = validateParameter(valid_600636, JString, required = false,
                                 default = nil)
  if valid_600636 != nil:
    section.add "X-Amz-Content-Sha256", valid_600636
  var valid_600637 = header.getOrDefault("X-Amz-Algorithm")
  valid_600637 = validateParameter(valid_600637, JString, required = false,
                                 default = nil)
  if valid_600637 != nil:
    section.add "X-Amz-Algorithm", valid_600637
  var valid_600638 = header.getOrDefault("X-Amz-Signature")
  valid_600638 = validateParameter(valid_600638, JString, required = false,
                                 default = nil)
  if valid_600638 != nil:
    section.add "X-Amz-Signature", valid_600638
  var valid_600639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600639 = validateParameter(valid_600639, JString, required = false,
                                 default = nil)
  if valid_600639 != nil:
    section.add "X-Amz-SignedHeaders", valid_600639
  var valid_600640 = header.getOrDefault("X-Amz-Credential")
  valid_600640 = validateParameter(valid_600640, JString, required = false,
                                 default = nil)
  if valid_600640 != nil:
    section.add "X-Amz-Credential", valid_600640
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_600641 = formData.getOrDefault("SubscriptionName")
  valid_600641 = validateParameter(valid_600641, JString, required = true,
                                 default = nil)
  if valid_600641 != nil:
    section.add "SubscriptionName", valid_600641
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600642: Call_PostDeleteEventSubscription_600629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600642.validator(path, query, header, formData, body)
  let scheme = call_600642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600642.url(scheme.get, call_600642.host, call_600642.base,
                         call_600642.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600642, url, valid)

proc call*(call_600643: Call_PostDeleteEventSubscription_600629;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600644 = newJObject()
  var formData_600645 = newJObject()
  add(formData_600645, "SubscriptionName", newJString(SubscriptionName))
  add(query_600644, "Action", newJString(Action))
  add(query_600644, "Version", newJString(Version))
  result = call_600643.call(nil, query_600644, nil, formData_600645, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_600629(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_600630, base: "/",
    url: url_PostDeleteEventSubscription_600631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_600613 = ref object of OpenApiRestCall_599352
proc url_GetDeleteEventSubscription_600615(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_600614(path: JsonNode; query: JsonNode;
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
  var valid_600616 = query.getOrDefault("Action")
  valid_600616 = validateParameter(valid_600616, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_600616 != nil:
    section.add "Action", valid_600616
  var valid_600617 = query.getOrDefault("SubscriptionName")
  valid_600617 = validateParameter(valid_600617, JString, required = true,
                                 default = nil)
  if valid_600617 != nil:
    section.add "SubscriptionName", valid_600617
  var valid_600618 = query.getOrDefault("Version")
  valid_600618 = validateParameter(valid_600618, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600618 != nil:
    section.add "Version", valid_600618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600619 = header.getOrDefault("X-Amz-Date")
  valid_600619 = validateParameter(valid_600619, JString, required = false,
                                 default = nil)
  if valid_600619 != nil:
    section.add "X-Amz-Date", valid_600619
  var valid_600620 = header.getOrDefault("X-Amz-Security-Token")
  valid_600620 = validateParameter(valid_600620, JString, required = false,
                                 default = nil)
  if valid_600620 != nil:
    section.add "X-Amz-Security-Token", valid_600620
  var valid_600621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600621 = validateParameter(valid_600621, JString, required = false,
                                 default = nil)
  if valid_600621 != nil:
    section.add "X-Amz-Content-Sha256", valid_600621
  var valid_600622 = header.getOrDefault("X-Amz-Algorithm")
  valid_600622 = validateParameter(valid_600622, JString, required = false,
                                 default = nil)
  if valid_600622 != nil:
    section.add "X-Amz-Algorithm", valid_600622
  var valid_600623 = header.getOrDefault("X-Amz-Signature")
  valid_600623 = validateParameter(valid_600623, JString, required = false,
                                 default = nil)
  if valid_600623 != nil:
    section.add "X-Amz-Signature", valid_600623
  var valid_600624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-SignedHeaders", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Credential")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Credential", valid_600625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600626: Call_GetDeleteEventSubscription_600613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600626.validator(path, query, header, formData, body)
  let scheme = call_600626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600626.url(scheme.get, call_600626.host, call_600626.base,
                         call_600626.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600626, url, valid)

proc call*(call_600627: Call_GetDeleteEventSubscription_600613;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_600628 = newJObject()
  add(query_600628, "Action", newJString(Action))
  add(query_600628, "SubscriptionName", newJString(SubscriptionName))
  add(query_600628, "Version", newJString(Version))
  result = call_600627.call(nil, query_600628, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_600613(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_600614, base: "/",
    url: url_GetDeleteEventSubscription_600615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_600662 = ref object of OpenApiRestCall_599352
proc url_PostDeleteOptionGroup_600664(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_600663(path: JsonNode; query: JsonNode;
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
  var valid_600665 = query.getOrDefault("Action")
  valid_600665 = validateParameter(valid_600665, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_600665 != nil:
    section.add "Action", valid_600665
  var valid_600666 = query.getOrDefault("Version")
  valid_600666 = validateParameter(valid_600666, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600666 != nil:
    section.add "Version", valid_600666
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600667 = header.getOrDefault("X-Amz-Date")
  valid_600667 = validateParameter(valid_600667, JString, required = false,
                                 default = nil)
  if valid_600667 != nil:
    section.add "X-Amz-Date", valid_600667
  var valid_600668 = header.getOrDefault("X-Amz-Security-Token")
  valid_600668 = validateParameter(valid_600668, JString, required = false,
                                 default = nil)
  if valid_600668 != nil:
    section.add "X-Amz-Security-Token", valid_600668
  var valid_600669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600669 = validateParameter(valid_600669, JString, required = false,
                                 default = nil)
  if valid_600669 != nil:
    section.add "X-Amz-Content-Sha256", valid_600669
  var valid_600670 = header.getOrDefault("X-Amz-Algorithm")
  valid_600670 = validateParameter(valid_600670, JString, required = false,
                                 default = nil)
  if valid_600670 != nil:
    section.add "X-Amz-Algorithm", valid_600670
  var valid_600671 = header.getOrDefault("X-Amz-Signature")
  valid_600671 = validateParameter(valid_600671, JString, required = false,
                                 default = nil)
  if valid_600671 != nil:
    section.add "X-Amz-Signature", valid_600671
  var valid_600672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600672 = validateParameter(valid_600672, JString, required = false,
                                 default = nil)
  if valid_600672 != nil:
    section.add "X-Amz-SignedHeaders", valid_600672
  var valid_600673 = header.getOrDefault("X-Amz-Credential")
  valid_600673 = validateParameter(valid_600673, JString, required = false,
                                 default = nil)
  if valid_600673 != nil:
    section.add "X-Amz-Credential", valid_600673
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_600674 = formData.getOrDefault("OptionGroupName")
  valid_600674 = validateParameter(valid_600674, JString, required = true,
                                 default = nil)
  if valid_600674 != nil:
    section.add "OptionGroupName", valid_600674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600675: Call_PostDeleteOptionGroup_600662; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600675.validator(path, query, header, formData, body)
  let scheme = call_600675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600675.url(scheme.get, call_600675.host, call_600675.base,
                         call_600675.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600675, url, valid)

proc call*(call_600676: Call_PostDeleteOptionGroup_600662; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600677 = newJObject()
  var formData_600678 = newJObject()
  add(formData_600678, "OptionGroupName", newJString(OptionGroupName))
  add(query_600677, "Action", newJString(Action))
  add(query_600677, "Version", newJString(Version))
  result = call_600676.call(nil, query_600677, nil, formData_600678, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_600662(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_600663, base: "/",
    url: url_PostDeleteOptionGroup_600664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_600646 = ref object of OpenApiRestCall_599352
proc url_GetDeleteOptionGroup_600648(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_600647(path: JsonNode; query: JsonNode;
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
  var valid_600649 = query.getOrDefault("OptionGroupName")
  valid_600649 = validateParameter(valid_600649, JString, required = true,
                                 default = nil)
  if valid_600649 != nil:
    section.add "OptionGroupName", valid_600649
  var valid_600650 = query.getOrDefault("Action")
  valid_600650 = validateParameter(valid_600650, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_600650 != nil:
    section.add "Action", valid_600650
  var valid_600651 = query.getOrDefault("Version")
  valid_600651 = validateParameter(valid_600651, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600651 != nil:
    section.add "Version", valid_600651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600652 = header.getOrDefault("X-Amz-Date")
  valid_600652 = validateParameter(valid_600652, JString, required = false,
                                 default = nil)
  if valid_600652 != nil:
    section.add "X-Amz-Date", valid_600652
  var valid_600653 = header.getOrDefault("X-Amz-Security-Token")
  valid_600653 = validateParameter(valid_600653, JString, required = false,
                                 default = nil)
  if valid_600653 != nil:
    section.add "X-Amz-Security-Token", valid_600653
  var valid_600654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600654 = validateParameter(valid_600654, JString, required = false,
                                 default = nil)
  if valid_600654 != nil:
    section.add "X-Amz-Content-Sha256", valid_600654
  var valid_600655 = header.getOrDefault("X-Amz-Algorithm")
  valid_600655 = validateParameter(valid_600655, JString, required = false,
                                 default = nil)
  if valid_600655 != nil:
    section.add "X-Amz-Algorithm", valid_600655
  var valid_600656 = header.getOrDefault("X-Amz-Signature")
  valid_600656 = validateParameter(valid_600656, JString, required = false,
                                 default = nil)
  if valid_600656 != nil:
    section.add "X-Amz-Signature", valid_600656
  var valid_600657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600657 = validateParameter(valid_600657, JString, required = false,
                                 default = nil)
  if valid_600657 != nil:
    section.add "X-Amz-SignedHeaders", valid_600657
  var valid_600658 = header.getOrDefault("X-Amz-Credential")
  valid_600658 = validateParameter(valid_600658, JString, required = false,
                                 default = nil)
  if valid_600658 != nil:
    section.add "X-Amz-Credential", valid_600658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600659: Call_GetDeleteOptionGroup_600646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600659.validator(path, query, header, formData, body)
  let scheme = call_600659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600659.url(scheme.get, call_600659.host, call_600659.base,
                         call_600659.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600659, url, valid)

proc call*(call_600660: Call_GetDeleteOptionGroup_600646; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_600661 = newJObject()
  add(query_600661, "OptionGroupName", newJString(OptionGroupName))
  add(query_600661, "Action", newJString(Action))
  add(query_600661, "Version", newJString(Version))
  result = call_600660.call(nil, query_600661, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_600646(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_600647, base: "/",
    url: url_GetDeleteOptionGroup_600648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_600701 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBEngineVersions_600703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_600702(path: JsonNode; query: JsonNode;
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
  var valid_600704 = query.getOrDefault("Action")
  valid_600704 = validateParameter(valid_600704, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600704 != nil:
    section.add "Action", valid_600704
  var valid_600705 = query.getOrDefault("Version")
  valid_600705 = validateParameter(valid_600705, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600705 != nil:
    section.add "Version", valid_600705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600706 = header.getOrDefault("X-Amz-Date")
  valid_600706 = validateParameter(valid_600706, JString, required = false,
                                 default = nil)
  if valid_600706 != nil:
    section.add "X-Amz-Date", valid_600706
  var valid_600707 = header.getOrDefault("X-Amz-Security-Token")
  valid_600707 = validateParameter(valid_600707, JString, required = false,
                                 default = nil)
  if valid_600707 != nil:
    section.add "X-Amz-Security-Token", valid_600707
  var valid_600708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600708 = validateParameter(valid_600708, JString, required = false,
                                 default = nil)
  if valid_600708 != nil:
    section.add "X-Amz-Content-Sha256", valid_600708
  var valid_600709 = header.getOrDefault("X-Amz-Algorithm")
  valid_600709 = validateParameter(valid_600709, JString, required = false,
                                 default = nil)
  if valid_600709 != nil:
    section.add "X-Amz-Algorithm", valid_600709
  var valid_600710 = header.getOrDefault("X-Amz-Signature")
  valid_600710 = validateParameter(valid_600710, JString, required = false,
                                 default = nil)
  if valid_600710 != nil:
    section.add "X-Amz-Signature", valid_600710
  var valid_600711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600711 = validateParameter(valid_600711, JString, required = false,
                                 default = nil)
  if valid_600711 != nil:
    section.add "X-Amz-SignedHeaders", valid_600711
  var valid_600712 = header.getOrDefault("X-Amz-Credential")
  valid_600712 = validateParameter(valid_600712, JString, required = false,
                                 default = nil)
  if valid_600712 != nil:
    section.add "X-Amz-Credential", valid_600712
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
  var valid_600713 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_600713 = validateParameter(valid_600713, JBool, required = false, default = nil)
  if valid_600713 != nil:
    section.add "ListSupportedCharacterSets", valid_600713
  var valid_600714 = formData.getOrDefault("Engine")
  valid_600714 = validateParameter(valid_600714, JString, required = false,
                                 default = nil)
  if valid_600714 != nil:
    section.add "Engine", valid_600714
  var valid_600715 = formData.getOrDefault("Marker")
  valid_600715 = validateParameter(valid_600715, JString, required = false,
                                 default = nil)
  if valid_600715 != nil:
    section.add "Marker", valid_600715
  var valid_600716 = formData.getOrDefault("DBParameterGroupFamily")
  valid_600716 = validateParameter(valid_600716, JString, required = false,
                                 default = nil)
  if valid_600716 != nil:
    section.add "DBParameterGroupFamily", valid_600716
  var valid_600717 = formData.getOrDefault("MaxRecords")
  valid_600717 = validateParameter(valid_600717, JInt, required = false, default = nil)
  if valid_600717 != nil:
    section.add "MaxRecords", valid_600717
  var valid_600718 = formData.getOrDefault("EngineVersion")
  valid_600718 = validateParameter(valid_600718, JString, required = false,
                                 default = nil)
  if valid_600718 != nil:
    section.add "EngineVersion", valid_600718
  var valid_600719 = formData.getOrDefault("DefaultOnly")
  valid_600719 = validateParameter(valid_600719, JBool, required = false, default = nil)
  if valid_600719 != nil:
    section.add "DefaultOnly", valid_600719
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600720: Call_PostDescribeDBEngineVersions_600701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600720.validator(path, query, header, formData, body)
  let scheme = call_600720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600720.url(scheme.get, call_600720.host, call_600720.base,
                         call_600720.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600720, url, valid)

proc call*(call_600721: Call_PostDescribeDBEngineVersions_600701;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-02-12";
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
  var query_600722 = newJObject()
  var formData_600723 = newJObject()
  add(formData_600723, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_600723, "Engine", newJString(Engine))
  add(formData_600723, "Marker", newJString(Marker))
  add(query_600722, "Action", newJString(Action))
  add(formData_600723, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_600723, "MaxRecords", newJInt(MaxRecords))
  add(formData_600723, "EngineVersion", newJString(EngineVersion))
  add(query_600722, "Version", newJString(Version))
  add(formData_600723, "DefaultOnly", newJBool(DefaultOnly))
  result = call_600721.call(nil, query_600722, nil, formData_600723, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_600701(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_600702, base: "/",
    url: url_PostDescribeDBEngineVersions_600703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_600679 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBEngineVersions_600681(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_600680(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  ##   Version: JString (required)
  section = newJObject()
  var valid_600682 = query.getOrDefault("Engine")
  valid_600682 = validateParameter(valid_600682, JString, required = false,
                                 default = nil)
  if valid_600682 != nil:
    section.add "Engine", valid_600682
  var valid_600683 = query.getOrDefault("ListSupportedCharacterSets")
  valid_600683 = validateParameter(valid_600683, JBool, required = false, default = nil)
  if valid_600683 != nil:
    section.add "ListSupportedCharacterSets", valid_600683
  var valid_600684 = query.getOrDefault("MaxRecords")
  valid_600684 = validateParameter(valid_600684, JInt, required = false, default = nil)
  if valid_600684 != nil:
    section.add "MaxRecords", valid_600684
  var valid_600685 = query.getOrDefault("DBParameterGroupFamily")
  valid_600685 = validateParameter(valid_600685, JString, required = false,
                                 default = nil)
  if valid_600685 != nil:
    section.add "DBParameterGroupFamily", valid_600685
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600686 = query.getOrDefault("Action")
  valid_600686 = validateParameter(valid_600686, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_600686 != nil:
    section.add "Action", valid_600686
  var valid_600687 = query.getOrDefault("Marker")
  valid_600687 = validateParameter(valid_600687, JString, required = false,
                                 default = nil)
  if valid_600687 != nil:
    section.add "Marker", valid_600687
  var valid_600688 = query.getOrDefault("EngineVersion")
  valid_600688 = validateParameter(valid_600688, JString, required = false,
                                 default = nil)
  if valid_600688 != nil:
    section.add "EngineVersion", valid_600688
  var valid_600689 = query.getOrDefault("DefaultOnly")
  valid_600689 = validateParameter(valid_600689, JBool, required = false, default = nil)
  if valid_600689 != nil:
    section.add "DefaultOnly", valid_600689
  var valid_600690 = query.getOrDefault("Version")
  valid_600690 = validateParameter(valid_600690, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600690 != nil:
    section.add "Version", valid_600690
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600691 = header.getOrDefault("X-Amz-Date")
  valid_600691 = validateParameter(valid_600691, JString, required = false,
                                 default = nil)
  if valid_600691 != nil:
    section.add "X-Amz-Date", valid_600691
  var valid_600692 = header.getOrDefault("X-Amz-Security-Token")
  valid_600692 = validateParameter(valid_600692, JString, required = false,
                                 default = nil)
  if valid_600692 != nil:
    section.add "X-Amz-Security-Token", valid_600692
  var valid_600693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600693 = validateParameter(valid_600693, JString, required = false,
                                 default = nil)
  if valid_600693 != nil:
    section.add "X-Amz-Content-Sha256", valid_600693
  var valid_600694 = header.getOrDefault("X-Amz-Algorithm")
  valid_600694 = validateParameter(valid_600694, JString, required = false,
                                 default = nil)
  if valid_600694 != nil:
    section.add "X-Amz-Algorithm", valid_600694
  var valid_600695 = header.getOrDefault("X-Amz-Signature")
  valid_600695 = validateParameter(valid_600695, JString, required = false,
                                 default = nil)
  if valid_600695 != nil:
    section.add "X-Amz-Signature", valid_600695
  var valid_600696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600696 = validateParameter(valid_600696, JString, required = false,
                                 default = nil)
  if valid_600696 != nil:
    section.add "X-Amz-SignedHeaders", valid_600696
  var valid_600697 = header.getOrDefault("X-Amz-Credential")
  valid_600697 = validateParameter(valid_600697, JString, required = false,
                                 default = nil)
  if valid_600697 != nil:
    section.add "X-Amz-Credential", valid_600697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600698: Call_GetDescribeDBEngineVersions_600679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600698.validator(path, query, header, formData, body)
  let scheme = call_600698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600698.url(scheme.get, call_600698.host, call_600698.base,
                         call_600698.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600698, url, valid)

proc call*(call_600699: Call_GetDescribeDBEngineVersions_600679;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Action: string = "DescribeDBEngineVersions"; Marker: string = "";
          EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2013-02-12"): Recallable =
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
  var query_600700 = newJObject()
  add(query_600700, "Engine", newJString(Engine))
  add(query_600700, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_600700, "MaxRecords", newJInt(MaxRecords))
  add(query_600700, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_600700, "Action", newJString(Action))
  add(query_600700, "Marker", newJString(Marker))
  add(query_600700, "EngineVersion", newJString(EngineVersion))
  add(query_600700, "DefaultOnly", newJBool(DefaultOnly))
  add(query_600700, "Version", newJString(Version))
  result = call_600699.call(nil, query_600700, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_600679(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_600680, base: "/",
    url: url_GetDescribeDBEngineVersions_600681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_600742 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBInstances_600744(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBInstances_600743(path: JsonNode; query: JsonNode;
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
  var valid_600745 = query.getOrDefault("Action")
  valid_600745 = validateParameter(valid_600745, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600745 != nil:
    section.add "Action", valid_600745
  var valid_600746 = query.getOrDefault("Version")
  valid_600746 = validateParameter(valid_600746, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600746 != nil:
    section.add "Version", valid_600746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600747 = header.getOrDefault("X-Amz-Date")
  valid_600747 = validateParameter(valid_600747, JString, required = false,
                                 default = nil)
  if valid_600747 != nil:
    section.add "X-Amz-Date", valid_600747
  var valid_600748 = header.getOrDefault("X-Amz-Security-Token")
  valid_600748 = validateParameter(valid_600748, JString, required = false,
                                 default = nil)
  if valid_600748 != nil:
    section.add "X-Amz-Security-Token", valid_600748
  var valid_600749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600749 = validateParameter(valid_600749, JString, required = false,
                                 default = nil)
  if valid_600749 != nil:
    section.add "X-Amz-Content-Sha256", valid_600749
  var valid_600750 = header.getOrDefault("X-Amz-Algorithm")
  valid_600750 = validateParameter(valid_600750, JString, required = false,
                                 default = nil)
  if valid_600750 != nil:
    section.add "X-Amz-Algorithm", valid_600750
  var valid_600751 = header.getOrDefault("X-Amz-Signature")
  valid_600751 = validateParameter(valid_600751, JString, required = false,
                                 default = nil)
  if valid_600751 != nil:
    section.add "X-Amz-Signature", valid_600751
  var valid_600752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600752 = validateParameter(valid_600752, JString, required = false,
                                 default = nil)
  if valid_600752 != nil:
    section.add "X-Amz-SignedHeaders", valid_600752
  var valid_600753 = header.getOrDefault("X-Amz-Credential")
  valid_600753 = validateParameter(valid_600753, JString, required = false,
                                 default = nil)
  if valid_600753 != nil:
    section.add "X-Amz-Credential", valid_600753
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600754 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600754 = validateParameter(valid_600754, JString, required = false,
                                 default = nil)
  if valid_600754 != nil:
    section.add "DBInstanceIdentifier", valid_600754
  var valid_600755 = formData.getOrDefault("Marker")
  valid_600755 = validateParameter(valid_600755, JString, required = false,
                                 default = nil)
  if valid_600755 != nil:
    section.add "Marker", valid_600755
  var valid_600756 = formData.getOrDefault("MaxRecords")
  valid_600756 = validateParameter(valid_600756, JInt, required = false, default = nil)
  if valid_600756 != nil:
    section.add "MaxRecords", valid_600756
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600757: Call_PostDescribeDBInstances_600742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600757.validator(path, query, header, formData, body)
  let scheme = call_600757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600757.url(scheme.get, call_600757.host, call_600757.base,
                         call_600757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600757, url, valid)

proc call*(call_600758: Call_PostDescribeDBInstances_600742;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_600759 = newJObject()
  var formData_600760 = newJObject()
  add(formData_600760, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600760, "Marker", newJString(Marker))
  add(query_600759, "Action", newJString(Action))
  add(formData_600760, "MaxRecords", newJInt(MaxRecords))
  add(query_600759, "Version", newJString(Version))
  result = call_600758.call(nil, query_600759, nil, formData_600760, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_600742(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_600743, base: "/",
    url: url_PostDescribeDBInstances_600744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_600724 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBInstances_600726(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_600725(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600727 = query.getOrDefault("MaxRecords")
  valid_600727 = validateParameter(valid_600727, JInt, required = false, default = nil)
  if valid_600727 != nil:
    section.add "MaxRecords", valid_600727
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600728 = query.getOrDefault("Action")
  valid_600728 = validateParameter(valid_600728, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_600728 != nil:
    section.add "Action", valid_600728
  var valid_600729 = query.getOrDefault("Marker")
  valid_600729 = validateParameter(valid_600729, JString, required = false,
                                 default = nil)
  if valid_600729 != nil:
    section.add "Marker", valid_600729
  var valid_600730 = query.getOrDefault("Version")
  valid_600730 = validateParameter(valid_600730, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600730 != nil:
    section.add "Version", valid_600730
  var valid_600731 = query.getOrDefault("DBInstanceIdentifier")
  valid_600731 = validateParameter(valid_600731, JString, required = false,
                                 default = nil)
  if valid_600731 != nil:
    section.add "DBInstanceIdentifier", valid_600731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600732 = header.getOrDefault("X-Amz-Date")
  valid_600732 = validateParameter(valid_600732, JString, required = false,
                                 default = nil)
  if valid_600732 != nil:
    section.add "X-Amz-Date", valid_600732
  var valid_600733 = header.getOrDefault("X-Amz-Security-Token")
  valid_600733 = validateParameter(valid_600733, JString, required = false,
                                 default = nil)
  if valid_600733 != nil:
    section.add "X-Amz-Security-Token", valid_600733
  var valid_600734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600734 = validateParameter(valid_600734, JString, required = false,
                                 default = nil)
  if valid_600734 != nil:
    section.add "X-Amz-Content-Sha256", valid_600734
  var valid_600735 = header.getOrDefault("X-Amz-Algorithm")
  valid_600735 = validateParameter(valid_600735, JString, required = false,
                                 default = nil)
  if valid_600735 != nil:
    section.add "X-Amz-Algorithm", valid_600735
  var valid_600736 = header.getOrDefault("X-Amz-Signature")
  valid_600736 = validateParameter(valid_600736, JString, required = false,
                                 default = nil)
  if valid_600736 != nil:
    section.add "X-Amz-Signature", valid_600736
  var valid_600737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600737 = validateParameter(valid_600737, JString, required = false,
                                 default = nil)
  if valid_600737 != nil:
    section.add "X-Amz-SignedHeaders", valid_600737
  var valid_600738 = header.getOrDefault("X-Amz-Credential")
  valid_600738 = validateParameter(valid_600738, JString, required = false,
                                 default = nil)
  if valid_600738 != nil:
    section.add "X-Amz-Credential", valid_600738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600739: Call_GetDescribeDBInstances_600724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600739.validator(path, query, header, formData, body)
  let scheme = call_600739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600739.url(scheme.get, call_600739.host, call_600739.base,
                         call_600739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600739, url, valid)

proc call*(call_600740: Call_GetDescribeDBInstances_600724; MaxRecords: int = 0;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-02-12"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_600741 = newJObject()
  add(query_600741, "MaxRecords", newJInt(MaxRecords))
  add(query_600741, "Action", newJString(Action))
  add(query_600741, "Marker", newJString(Marker))
  add(query_600741, "Version", newJString(Version))
  add(query_600741, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600740.call(nil, query_600741, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_600724(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_600725, base: "/",
    url: url_GetDescribeDBInstances_600726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_600782 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBLogFiles_600784(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_600783(path: JsonNode; query: JsonNode;
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
  var valid_600785 = query.getOrDefault("Action")
  valid_600785 = validateParameter(valid_600785, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_600785 != nil:
    section.add "Action", valid_600785
  var valid_600786 = query.getOrDefault("Version")
  valid_600786 = validateParameter(valid_600786, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600786 != nil:
    section.add "Version", valid_600786
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600787 = header.getOrDefault("X-Amz-Date")
  valid_600787 = validateParameter(valid_600787, JString, required = false,
                                 default = nil)
  if valid_600787 != nil:
    section.add "X-Amz-Date", valid_600787
  var valid_600788 = header.getOrDefault("X-Amz-Security-Token")
  valid_600788 = validateParameter(valid_600788, JString, required = false,
                                 default = nil)
  if valid_600788 != nil:
    section.add "X-Amz-Security-Token", valid_600788
  var valid_600789 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600789 = validateParameter(valid_600789, JString, required = false,
                                 default = nil)
  if valid_600789 != nil:
    section.add "X-Amz-Content-Sha256", valid_600789
  var valid_600790 = header.getOrDefault("X-Amz-Algorithm")
  valid_600790 = validateParameter(valid_600790, JString, required = false,
                                 default = nil)
  if valid_600790 != nil:
    section.add "X-Amz-Algorithm", valid_600790
  var valid_600791 = header.getOrDefault("X-Amz-Signature")
  valid_600791 = validateParameter(valid_600791, JString, required = false,
                                 default = nil)
  if valid_600791 != nil:
    section.add "X-Amz-Signature", valid_600791
  var valid_600792 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600792 = validateParameter(valid_600792, JString, required = false,
                                 default = nil)
  if valid_600792 != nil:
    section.add "X-Amz-SignedHeaders", valid_600792
  var valid_600793 = header.getOrDefault("X-Amz-Credential")
  valid_600793 = validateParameter(valid_600793, JString, required = false,
                                 default = nil)
  if valid_600793 != nil:
    section.add "X-Amz-Credential", valid_600793
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_600794 = formData.getOrDefault("FilenameContains")
  valid_600794 = validateParameter(valid_600794, JString, required = false,
                                 default = nil)
  if valid_600794 != nil:
    section.add "FilenameContains", valid_600794
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_600795 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600795 = validateParameter(valid_600795, JString, required = true,
                                 default = nil)
  if valid_600795 != nil:
    section.add "DBInstanceIdentifier", valid_600795
  var valid_600796 = formData.getOrDefault("FileSize")
  valid_600796 = validateParameter(valid_600796, JInt, required = false, default = nil)
  if valid_600796 != nil:
    section.add "FileSize", valid_600796
  var valid_600797 = formData.getOrDefault("Marker")
  valid_600797 = validateParameter(valid_600797, JString, required = false,
                                 default = nil)
  if valid_600797 != nil:
    section.add "Marker", valid_600797
  var valid_600798 = formData.getOrDefault("MaxRecords")
  valid_600798 = validateParameter(valid_600798, JInt, required = false, default = nil)
  if valid_600798 != nil:
    section.add "MaxRecords", valid_600798
  var valid_600799 = formData.getOrDefault("FileLastWritten")
  valid_600799 = validateParameter(valid_600799, JInt, required = false, default = nil)
  if valid_600799 != nil:
    section.add "FileLastWritten", valid_600799
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600800: Call_PostDescribeDBLogFiles_600782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600800.validator(path, query, header, formData, body)
  let scheme = call_600800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600800.url(scheme.get, call_600800.host, call_600800.base,
                         call_600800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600800, url, valid)

proc call*(call_600801: Call_PostDescribeDBLogFiles_600782;
          DBInstanceIdentifier: string; FilenameContains: string = "";
          FileSize: int = 0; Marker: string = ""; Action: string = "DescribeDBLogFiles";
          MaxRecords: int = 0; FileLastWritten: int = 0; Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBLogFiles
  ##   FilenameContains: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileSize: int
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   FileLastWritten: int
  ##   Version: string (required)
  var query_600802 = newJObject()
  var formData_600803 = newJObject()
  add(formData_600803, "FilenameContains", newJString(FilenameContains))
  add(formData_600803, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600803, "FileSize", newJInt(FileSize))
  add(formData_600803, "Marker", newJString(Marker))
  add(query_600802, "Action", newJString(Action))
  add(formData_600803, "MaxRecords", newJInt(MaxRecords))
  add(formData_600803, "FileLastWritten", newJInt(FileLastWritten))
  add(query_600802, "Version", newJString(Version))
  result = call_600801.call(nil, query_600802, nil, formData_600803, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_600782(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_600783, base: "/",
    url: url_PostDescribeDBLogFiles_600784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_600761 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBLogFiles_600763(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_600762(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_600764 = query.getOrDefault("FileLastWritten")
  valid_600764 = validateParameter(valid_600764, JInt, required = false, default = nil)
  if valid_600764 != nil:
    section.add "FileLastWritten", valid_600764
  var valid_600765 = query.getOrDefault("MaxRecords")
  valid_600765 = validateParameter(valid_600765, JInt, required = false, default = nil)
  if valid_600765 != nil:
    section.add "MaxRecords", valid_600765
  var valid_600766 = query.getOrDefault("FilenameContains")
  valid_600766 = validateParameter(valid_600766, JString, required = false,
                                 default = nil)
  if valid_600766 != nil:
    section.add "FilenameContains", valid_600766
  var valid_600767 = query.getOrDefault("FileSize")
  valid_600767 = validateParameter(valid_600767, JInt, required = false, default = nil)
  if valid_600767 != nil:
    section.add "FileSize", valid_600767
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600768 = query.getOrDefault("Action")
  valid_600768 = validateParameter(valid_600768, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_600768 != nil:
    section.add "Action", valid_600768
  var valid_600769 = query.getOrDefault("Marker")
  valid_600769 = validateParameter(valid_600769, JString, required = false,
                                 default = nil)
  if valid_600769 != nil:
    section.add "Marker", valid_600769
  var valid_600770 = query.getOrDefault("Version")
  valid_600770 = validateParameter(valid_600770, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600770 != nil:
    section.add "Version", valid_600770
  var valid_600771 = query.getOrDefault("DBInstanceIdentifier")
  valid_600771 = validateParameter(valid_600771, JString, required = true,
                                 default = nil)
  if valid_600771 != nil:
    section.add "DBInstanceIdentifier", valid_600771
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600772 = header.getOrDefault("X-Amz-Date")
  valid_600772 = validateParameter(valid_600772, JString, required = false,
                                 default = nil)
  if valid_600772 != nil:
    section.add "X-Amz-Date", valid_600772
  var valid_600773 = header.getOrDefault("X-Amz-Security-Token")
  valid_600773 = validateParameter(valid_600773, JString, required = false,
                                 default = nil)
  if valid_600773 != nil:
    section.add "X-Amz-Security-Token", valid_600773
  var valid_600774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600774 = validateParameter(valid_600774, JString, required = false,
                                 default = nil)
  if valid_600774 != nil:
    section.add "X-Amz-Content-Sha256", valid_600774
  var valid_600775 = header.getOrDefault("X-Amz-Algorithm")
  valid_600775 = validateParameter(valid_600775, JString, required = false,
                                 default = nil)
  if valid_600775 != nil:
    section.add "X-Amz-Algorithm", valid_600775
  var valid_600776 = header.getOrDefault("X-Amz-Signature")
  valid_600776 = validateParameter(valid_600776, JString, required = false,
                                 default = nil)
  if valid_600776 != nil:
    section.add "X-Amz-Signature", valid_600776
  var valid_600777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600777 = validateParameter(valid_600777, JString, required = false,
                                 default = nil)
  if valid_600777 != nil:
    section.add "X-Amz-SignedHeaders", valid_600777
  var valid_600778 = header.getOrDefault("X-Amz-Credential")
  valid_600778 = validateParameter(valid_600778, JString, required = false,
                                 default = nil)
  if valid_600778 != nil:
    section.add "X-Amz-Credential", valid_600778
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600779: Call_GetDescribeDBLogFiles_600761; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600779.validator(path, query, header, formData, body)
  let scheme = call_600779.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600779.url(scheme.get, call_600779.host, call_600779.base,
                         call_600779.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600779, url, valid)

proc call*(call_600780: Call_GetDescribeDBLogFiles_600761;
          DBInstanceIdentifier: string; FileLastWritten: int = 0; MaxRecords: int = 0;
          FilenameContains: string = ""; FileSize: int = 0;
          Action: string = "DescribeDBLogFiles"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBLogFiles
  ##   FileLastWritten: int
  ##   MaxRecords: int
  ##   FilenameContains: string
  ##   FileSize: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_600781 = newJObject()
  add(query_600781, "FileLastWritten", newJInt(FileLastWritten))
  add(query_600781, "MaxRecords", newJInt(MaxRecords))
  add(query_600781, "FilenameContains", newJString(FilenameContains))
  add(query_600781, "FileSize", newJInt(FileSize))
  add(query_600781, "Action", newJString(Action))
  add(query_600781, "Marker", newJString(Marker))
  add(query_600781, "Version", newJString(Version))
  add(query_600781, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_600780.call(nil, query_600781, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_600761(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_600762, base: "/",
    url: url_GetDescribeDBLogFiles_600763, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_600822 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBParameterGroups_600824(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_600823(path: JsonNode; query: JsonNode;
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
  var valid_600825 = query.getOrDefault("Action")
  valid_600825 = validateParameter(valid_600825, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_600825 != nil:
    section.add "Action", valid_600825
  var valid_600826 = query.getOrDefault("Version")
  valid_600826 = validateParameter(valid_600826, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600826 != nil:
    section.add "Version", valid_600826
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600827 = header.getOrDefault("X-Amz-Date")
  valid_600827 = validateParameter(valid_600827, JString, required = false,
                                 default = nil)
  if valid_600827 != nil:
    section.add "X-Amz-Date", valid_600827
  var valid_600828 = header.getOrDefault("X-Amz-Security-Token")
  valid_600828 = validateParameter(valid_600828, JString, required = false,
                                 default = nil)
  if valid_600828 != nil:
    section.add "X-Amz-Security-Token", valid_600828
  var valid_600829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600829 = validateParameter(valid_600829, JString, required = false,
                                 default = nil)
  if valid_600829 != nil:
    section.add "X-Amz-Content-Sha256", valid_600829
  var valid_600830 = header.getOrDefault("X-Amz-Algorithm")
  valid_600830 = validateParameter(valid_600830, JString, required = false,
                                 default = nil)
  if valid_600830 != nil:
    section.add "X-Amz-Algorithm", valid_600830
  var valid_600831 = header.getOrDefault("X-Amz-Signature")
  valid_600831 = validateParameter(valid_600831, JString, required = false,
                                 default = nil)
  if valid_600831 != nil:
    section.add "X-Amz-Signature", valid_600831
  var valid_600832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600832 = validateParameter(valid_600832, JString, required = false,
                                 default = nil)
  if valid_600832 != nil:
    section.add "X-Amz-SignedHeaders", valid_600832
  var valid_600833 = header.getOrDefault("X-Amz-Credential")
  valid_600833 = validateParameter(valid_600833, JString, required = false,
                                 default = nil)
  if valid_600833 != nil:
    section.add "X-Amz-Credential", valid_600833
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600834 = formData.getOrDefault("DBParameterGroupName")
  valid_600834 = validateParameter(valid_600834, JString, required = false,
                                 default = nil)
  if valid_600834 != nil:
    section.add "DBParameterGroupName", valid_600834
  var valid_600835 = formData.getOrDefault("Marker")
  valid_600835 = validateParameter(valid_600835, JString, required = false,
                                 default = nil)
  if valid_600835 != nil:
    section.add "Marker", valid_600835
  var valid_600836 = formData.getOrDefault("MaxRecords")
  valid_600836 = validateParameter(valid_600836, JInt, required = false, default = nil)
  if valid_600836 != nil:
    section.add "MaxRecords", valid_600836
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600837: Call_PostDescribeDBParameterGroups_600822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600837.validator(path, query, header, formData, body)
  let scheme = call_600837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600837.url(scheme.get, call_600837.host, call_600837.base,
                         call_600837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600837, url, valid)

proc call*(call_600838: Call_PostDescribeDBParameterGroups_600822;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_600839 = newJObject()
  var formData_600840 = newJObject()
  add(formData_600840, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600840, "Marker", newJString(Marker))
  add(query_600839, "Action", newJString(Action))
  add(formData_600840, "MaxRecords", newJInt(MaxRecords))
  add(query_600839, "Version", newJString(Version))
  result = call_600838.call(nil, query_600839, nil, formData_600840, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_600822(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_600823, base: "/",
    url: url_PostDescribeDBParameterGroups_600824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_600804 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBParameterGroups_600806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_600805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600807 = query.getOrDefault("MaxRecords")
  valid_600807 = validateParameter(valid_600807, JInt, required = false, default = nil)
  if valid_600807 != nil:
    section.add "MaxRecords", valid_600807
  var valid_600808 = query.getOrDefault("DBParameterGroupName")
  valid_600808 = validateParameter(valid_600808, JString, required = false,
                                 default = nil)
  if valid_600808 != nil:
    section.add "DBParameterGroupName", valid_600808
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600809 = query.getOrDefault("Action")
  valid_600809 = validateParameter(valid_600809, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_600809 != nil:
    section.add "Action", valid_600809
  var valid_600810 = query.getOrDefault("Marker")
  valid_600810 = validateParameter(valid_600810, JString, required = false,
                                 default = nil)
  if valid_600810 != nil:
    section.add "Marker", valid_600810
  var valid_600811 = query.getOrDefault("Version")
  valid_600811 = validateParameter(valid_600811, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600819: Call_GetDescribeDBParameterGroups_600804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600819.validator(path, query, header, formData, body)
  let scheme = call_600819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600819.url(scheme.get, call_600819.host, call_600819.base,
                         call_600819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600819, url, valid)

proc call*(call_600820: Call_GetDescribeDBParameterGroups_600804;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_600821 = newJObject()
  add(query_600821, "MaxRecords", newJInt(MaxRecords))
  add(query_600821, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600821, "Action", newJString(Action))
  add(query_600821, "Marker", newJString(Marker))
  add(query_600821, "Version", newJString(Version))
  result = call_600820.call(nil, query_600821, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_600804(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_600805, base: "/",
    url: url_GetDescribeDBParameterGroups_600806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_600860 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBParameters_600862(protocol: Scheme; host: string;
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

proc validate_PostDescribeDBParameters_600861(path: JsonNode; query: JsonNode;
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
  var valid_600863 = query.getOrDefault("Action")
  valid_600863 = validateParameter(valid_600863, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_600863 != nil:
    section.add "Action", valid_600863
  var valid_600864 = query.getOrDefault("Version")
  valid_600864 = validateParameter(valid_600864, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600864 != nil:
    section.add "Version", valid_600864
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600865 = header.getOrDefault("X-Amz-Date")
  valid_600865 = validateParameter(valid_600865, JString, required = false,
                                 default = nil)
  if valid_600865 != nil:
    section.add "X-Amz-Date", valid_600865
  var valid_600866 = header.getOrDefault("X-Amz-Security-Token")
  valid_600866 = validateParameter(valid_600866, JString, required = false,
                                 default = nil)
  if valid_600866 != nil:
    section.add "X-Amz-Security-Token", valid_600866
  var valid_600867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600867 = validateParameter(valid_600867, JString, required = false,
                                 default = nil)
  if valid_600867 != nil:
    section.add "X-Amz-Content-Sha256", valid_600867
  var valid_600868 = header.getOrDefault("X-Amz-Algorithm")
  valid_600868 = validateParameter(valid_600868, JString, required = false,
                                 default = nil)
  if valid_600868 != nil:
    section.add "X-Amz-Algorithm", valid_600868
  var valid_600869 = header.getOrDefault("X-Amz-Signature")
  valid_600869 = validateParameter(valid_600869, JString, required = false,
                                 default = nil)
  if valid_600869 != nil:
    section.add "X-Amz-Signature", valid_600869
  var valid_600870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600870 = validateParameter(valid_600870, JString, required = false,
                                 default = nil)
  if valid_600870 != nil:
    section.add "X-Amz-SignedHeaders", valid_600870
  var valid_600871 = header.getOrDefault("X-Amz-Credential")
  valid_600871 = validateParameter(valid_600871, JString, required = false,
                                 default = nil)
  if valid_600871 != nil:
    section.add "X-Amz-Credential", valid_600871
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_600872 = formData.getOrDefault("DBParameterGroupName")
  valid_600872 = validateParameter(valid_600872, JString, required = true,
                                 default = nil)
  if valid_600872 != nil:
    section.add "DBParameterGroupName", valid_600872
  var valid_600873 = formData.getOrDefault("Marker")
  valid_600873 = validateParameter(valid_600873, JString, required = false,
                                 default = nil)
  if valid_600873 != nil:
    section.add "Marker", valid_600873
  var valid_600874 = formData.getOrDefault("MaxRecords")
  valid_600874 = validateParameter(valid_600874, JInt, required = false, default = nil)
  if valid_600874 != nil:
    section.add "MaxRecords", valid_600874
  var valid_600875 = formData.getOrDefault("Source")
  valid_600875 = validateParameter(valid_600875, JString, required = false,
                                 default = nil)
  if valid_600875 != nil:
    section.add "Source", valid_600875
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600876: Call_PostDescribeDBParameters_600860; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600876.validator(path, query, header, formData, body)
  let scheme = call_600876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600876.url(scheme.get, call_600876.host, call_600876.base,
                         call_600876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600876, url, valid)

proc call*(call_600877: Call_PostDescribeDBParameters_600860;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_600878 = newJObject()
  var formData_600879 = newJObject()
  add(formData_600879, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_600879, "Marker", newJString(Marker))
  add(query_600878, "Action", newJString(Action))
  add(formData_600879, "MaxRecords", newJInt(MaxRecords))
  add(query_600878, "Version", newJString(Version))
  add(formData_600879, "Source", newJString(Source))
  result = call_600877.call(nil, query_600878, nil, formData_600879, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_600860(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_600861, base: "/",
    url: url_PostDescribeDBParameters_600862, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_600841 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBParameters_600843(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeDBParameters_600842(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600844 = query.getOrDefault("MaxRecords")
  valid_600844 = validateParameter(valid_600844, JInt, required = false, default = nil)
  if valid_600844 != nil:
    section.add "MaxRecords", valid_600844
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_600845 = query.getOrDefault("DBParameterGroupName")
  valid_600845 = validateParameter(valid_600845, JString, required = true,
                                 default = nil)
  if valid_600845 != nil:
    section.add "DBParameterGroupName", valid_600845
  var valid_600846 = query.getOrDefault("Action")
  valid_600846 = validateParameter(valid_600846, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_600846 != nil:
    section.add "Action", valid_600846
  var valid_600847 = query.getOrDefault("Marker")
  valid_600847 = validateParameter(valid_600847, JString, required = false,
                                 default = nil)
  if valid_600847 != nil:
    section.add "Marker", valid_600847
  var valid_600848 = query.getOrDefault("Source")
  valid_600848 = validateParameter(valid_600848, JString, required = false,
                                 default = nil)
  if valid_600848 != nil:
    section.add "Source", valid_600848
  var valid_600849 = query.getOrDefault("Version")
  valid_600849 = validateParameter(valid_600849, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600849 != nil:
    section.add "Version", valid_600849
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600850 = header.getOrDefault("X-Amz-Date")
  valid_600850 = validateParameter(valid_600850, JString, required = false,
                                 default = nil)
  if valid_600850 != nil:
    section.add "X-Amz-Date", valid_600850
  var valid_600851 = header.getOrDefault("X-Amz-Security-Token")
  valid_600851 = validateParameter(valid_600851, JString, required = false,
                                 default = nil)
  if valid_600851 != nil:
    section.add "X-Amz-Security-Token", valid_600851
  var valid_600852 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600852 = validateParameter(valid_600852, JString, required = false,
                                 default = nil)
  if valid_600852 != nil:
    section.add "X-Amz-Content-Sha256", valid_600852
  var valid_600853 = header.getOrDefault("X-Amz-Algorithm")
  valid_600853 = validateParameter(valid_600853, JString, required = false,
                                 default = nil)
  if valid_600853 != nil:
    section.add "X-Amz-Algorithm", valid_600853
  var valid_600854 = header.getOrDefault("X-Amz-Signature")
  valid_600854 = validateParameter(valid_600854, JString, required = false,
                                 default = nil)
  if valid_600854 != nil:
    section.add "X-Amz-Signature", valid_600854
  var valid_600855 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600855 = validateParameter(valid_600855, JString, required = false,
                                 default = nil)
  if valid_600855 != nil:
    section.add "X-Amz-SignedHeaders", valid_600855
  var valid_600856 = header.getOrDefault("X-Amz-Credential")
  valid_600856 = validateParameter(valid_600856, JString, required = false,
                                 default = nil)
  if valid_600856 != nil:
    section.add "X-Amz-Credential", valid_600856
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600857: Call_GetDescribeDBParameters_600841; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600857.validator(path, query, header, formData, body)
  let scheme = call_600857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600857.url(scheme.get, call_600857.host, call_600857.base,
                         call_600857.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600857, url, valid)

proc call*(call_600858: Call_GetDescribeDBParameters_600841;
          DBParameterGroupName: string; MaxRecords: int = 0;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_600859 = newJObject()
  add(query_600859, "MaxRecords", newJInt(MaxRecords))
  add(query_600859, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_600859, "Action", newJString(Action))
  add(query_600859, "Marker", newJString(Marker))
  add(query_600859, "Source", newJString(Source))
  add(query_600859, "Version", newJString(Version))
  result = call_600858.call(nil, query_600859, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_600841(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_600842, base: "/",
    url: url_GetDescribeDBParameters_600843, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_600898 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSecurityGroups_600900(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_600899(path: JsonNode; query: JsonNode;
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
  var valid_600901 = query.getOrDefault("Action")
  valid_600901 = validateParameter(valid_600901, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_600901 != nil:
    section.add "Action", valid_600901
  var valid_600902 = query.getOrDefault("Version")
  valid_600902 = validateParameter(valid_600902, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600902 != nil:
    section.add "Version", valid_600902
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600903 = header.getOrDefault("X-Amz-Date")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-Date", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Security-Token")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Security-Token", valid_600904
  var valid_600905 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600905 = validateParameter(valid_600905, JString, required = false,
                                 default = nil)
  if valid_600905 != nil:
    section.add "X-Amz-Content-Sha256", valid_600905
  var valid_600906 = header.getOrDefault("X-Amz-Algorithm")
  valid_600906 = validateParameter(valid_600906, JString, required = false,
                                 default = nil)
  if valid_600906 != nil:
    section.add "X-Amz-Algorithm", valid_600906
  var valid_600907 = header.getOrDefault("X-Amz-Signature")
  valid_600907 = validateParameter(valid_600907, JString, required = false,
                                 default = nil)
  if valid_600907 != nil:
    section.add "X-Amz-Signature", valid_600907
  var valid_600908 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600908 = validateParameter(valid_600908, JString, required = false,
                                 default = nil)
  if valid_600908 != nil:
    section.add "X-Amz-SignedHeaders", valid_600908
  var valid_600909 = header.getOrDefault("X-Amz-Credential")
  valid_600909 = validateParameter(valid_600909, JString, required = false,
                                 default = nil)
  if valid_600909 != nil:
    section.add "X-Amz-Credential", valid_600909
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600910 = formData.getOrDefault("DBSecurityGroupName")
  valid_600910 = validateParameter(valid_600910, JString, required = false,
                                 default = nil)
  if valid_600910 != nil:
    section.add "DBSecurityGroupName", valid_600910
  var valid_600911 = formData.getOrDefault("Marker")
  valid_600911 = validateParameter(valid_600911, JString, required = false,
                                 default = nil)
  if valid_600911 != nil:
    section.add "Marker", valid_600911
  var valid_600912 = formData.getOrDefault("MaxRecords")
  valid_600912 = validateParameter(valid_600912, JInt, required = false, default = nil)
  if valid_600912 != nil:
    section.add "MaxRecords", valid_600912
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600913: Call_PostDescribeDBSecurityGroups_600898; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600913.validator(path, query, header, formData, body)
  let scheme = call_600913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600913.url(scheme.get, call_600913.host, call_600913.base,
                         call_600913.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600913, url, valid)

proc call*(call_600914: Call_PostDescribeDBSecurityGroups_600898;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_600915 = newJObject()
  var formData_600916 = newJObject()
  add(formData_600916, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_600916, "Marker", newJString(Marker))
  add(query_600915, "Action", newJString(Action))
  add(formData_600916, "MaxRecords", newJInt(MaxRecords))
  add(query_600915, "Version", newJString(Version))
  result = call_600914.call(nil, query_600915, nil, formData_600916, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_600898(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_600899, base: "/",
    url: url_PostDescribeDBSecurityGroups_600900,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_600880 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSecurityGroups_600882(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_600881(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600883 = query.getOrDefault("MaxRecords")
  valid_600883 = validateParameter(valid_600883, JInt, required = false, default = nil)
  if valid_600883 != nil:
    section.add "MaxRecords", valid_600883
  var valid_600884 = query.getOrDefault("DBSecurityGroupName")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "DBSecurityGroupName", valid_600884
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600885 = query.getOrDefault("Action")
  valid_600885 = validateParameter(valid_600885, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_600885 != nil:
    section.add "Action", valid_600885
  var valid_600886 = query.getOrDefault("Marker")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "Marker", valid_600886
  var valid_600887 = query.getOrDefault("Version")
  valid_600887 = validateParameter(valid_600887, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600887 != nil:
    section.add "Version", valid_600887
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600888 = header.getOrDefault("X-Amz-Date")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Date", valid_600888
  var valid_600889 = header.getOrDefault("X-Amz-Security-Token")
  valid_600889 = validateParameter(valid_600889, JString, required = false,
                                 default = nil)
  if valid_600889 != nil:
    section.add "X-Amz-Security-Token", valid_600889
  var valid_600890 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600890 = validateParameter(valid_600890, JString, required = false,
                                 default = nil)
  if valid_600890 != nil:
    section.add "X-Amz-Content-Sha256", valid_600890
  var valid_600891 = header.getOrDefault("X-Amz-Algorithm")
  valid_600891 = validateParameter(valid_600891, JString, required = false,
                                 default = nil)
  if valid_600891 != nil:
    section.add "X-Amz-Algorithm", valid_600891
  var valid_600892 = header.getOrDefault("X-Amz-Signature")
  valid_600892 = validateParameter(valid_600892, JString, required = false,
                                 default = nil)
  if valid_600892 != nil:
    section.add "X-Amz-Signature", valid_600892
  var valid_600893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600893 = validateParameter(valid_600893, JString, required = false,
                                 default = nil)
  if valid_600893 != nil:
    section.add "X-Amz-SignedHeaders", valid_600893
  var valid_600894 = header.getOrDefault("X-Amz-Credential")
  valid_600894 = validateParameter(valid_600894, JString, required = false,
                                 default = nil)
  if valid_600894 != nil:
    section.add "X-Amz-Credential", valid_600894
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600895: Call_GetDescribeDBSecurityGroups_600880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600895.validator(path, query, header, formData, body)
  let scheme = call_600895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600895.url(scheme.get, call_600895.host, call_600895.base,
                         call_600895.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600895, url, valid)

proc call*(call_600896: Call_GetDescribeDBSecurityGroups_600880;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_600897 = newJObject()
  add(query_600897, "MaxRecords", newJInt(MaxRecords))
  add(query_600897, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_600897, "Action", newJString(Action))
  add(query_600897, "Marker", newJString(Marker))
  add(query_600897, "Version", newJString(Version))
  result = call_600896.call(nil, query_600897, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_600880(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_600881, base: "/",
    url: url_GetDescribeDBSecurityGroups_600882,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_600937 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSnapshots_600939(protocol: Scheme; host: string; base: string;
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

proc validate_PostDescribeDBSnapshots_600938(path: JsonNode; query: JsonNode;
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
  var valid_600940 = query.getOrDefault("Action")
  valid_600940 = validateParameter(valid_600940, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_600940 != nil:
    section.add "Action", valid_600940
  var valid_600941 = query.getOrDefault("Version")
  valid_600941 = validateParameter(valid_600941, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600941 != nil:
    section.add "Version", valid_600941
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600942 = header.getOrDefault("X-Amz-Date")
  valid_600942 = validateParameter(valid_600942, JString, required = false,
                                 default = nil)
  if valid_600942 != nil:
    section.add "X-Amz-Date", valid_600942
  var valid_600943 = header.getOrDefault("X-Amz-Security-Token")
  valid_600943 = validateParameter(valid_600943, JString, required = false,
                                 default = nil)
  if valid_600943 != nil:
    section.add "X-Amz-Security-Token", valid_600943
  var valid_600944 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600944 = validateParameter(valid_600944, JString, required = false,
                                 default = nil)
  if valid_600944 != nil:
    section.add "X-Amz-Content-Sha256", valid_600944
  var valid_600945 = header.getOrDefault("X-Amz-Algorithm")
  valid_600945 = validateParameter(valid_600945, JString, required = false,
                                 default = nil)
  if valid_600945 != nil:
    section.add "X-Amz-Algorithm", valid_600945
  var valid_600946 = header.getOrDefault("X-Amz-Signature")
  valid_600946 = validateParameter(valid_600946, JString, required = false,
                                 default = nil)
  if valid_600946 != nil:
    section.add "X-Amz-Signature", valid_600946
  var valid_600947 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600947 = validateParameter(valid_600947, JString, required = false,
                                 default = nil)
  if valid_600947 != nil:
    section.add "X-Amz-SignedHeaders", valid_600947
  var valid_600948 = header.getOrDefault("X-Amz-Credential")
  valid_600948 = validateParameter(valid_600948, JString, required = false,
                                 default = nil)
  if valid_600948 != nil:
    section.add "X-Amz-Credential", valid_600948
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600949 = formData.getOrDefault("DBInstanceIdentifier")
  valid_600949 = validateParameter(valid_600949, JString, required = false,
                                 default = nil)
  if valid_600949 != nil:
    section.add "DBInstanceIdentifier", valid_600949
  var valid_600950 = formData.getOrDefault("SnapshotType")
  valid_600950 = validateParameter(valid_600950, JString, required = false,
                                 default = nil)
  if valid_600950 != nil:
    section.add "SnapshotType", valid_600950
  var valid_600951 = formData.getOrDefault("Marker")
  valid_600951 = validateParameter(valid_600951, JString, required = false,
                                 default = nil)
  if valid_600951 != nil:
    section.add "Marker", valid_600951
  var valid_600952 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_600952 = validateParameter(valid_600952, JString, required = false,
                                 default = nil)
  if valid_600952 != nil:
    section.add "DBSnapshotIdentifier", valid_600952
  var valid_600953 = formData.getOrDefault("MaxRecords")
  valid_600953 = validateParameter(valid_600953, JInt, required = false, default = nil)
  if valid_600953 != nil:
    section.add "MaxRecords", valid_600953
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600954: Call_PostDescribeDBSnapshots_600937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600954.validator(path, query, header, formData, body)
  let scheme = call_600954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600954.url(scheme.get, call_600954.host, call_600954.base,
                         call_600954.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600954, url, valid)

proc call*(call_600955: Call_PostDescribeDBSnapshots_600937;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_600956 = newJObject()
  var formData_600957 = newJObject()
  add(formData_600957, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_600957, "SnapshotType", newJString(SnapshotType))
  add(formData_600957, "Marker", newJString(Marker))
  add(formData_600957, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_600956, "Action", newJString(Action))
  add(formData_600957, "MaxRecords", newJInt(MaxRecords))
  add(query_600956, "Version", newJString(Version))
  result = call_600955.call(nil, query_600956, nil, formData_600957, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_600937(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_600938, base: "/",
    url: url_PostDescribeDBSnapshots_600939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_600917 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSnapshots_600919(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_600918(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600920 = query.getOrDefault("MaxRecords")
  valid_600920 = validateParameter(valid_600920, JInt, required = false, default = nil)
  if valid_600920 != nil:
    section.add "MaxRecords", valid_600920
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600921 = query.getOrDefault("Action")
  valid_600921 = validateParameter(valid_600921, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_600921 != nil:
    section.add "Action", valid_600921
  var valid_600922 = query.getOrDefault("Marker")
  valid_600922 = validateParameter(valid_600922, JString, required = false,
                                 default = nil)
  if valid_600922 != nil:
    section.add "Marker", valid_600922
  var valid_600923 = query.getOrDefault("SnapshotType")
  valid_600923 = validateParameter(valid_600923, JString, required = false,
                                 default = nil)
  if valid_600923 != nil:
    section.add "SnapshotType", valid_600923
  var valid_600924 = query.getOrDefault("Version")
  valid_600924 = validateParameter(valid_600924, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600924 != nil:
    section.add "Version", valid_600924
  var valid_600925 = query.getOrDefault("DBInstanceIdentifier")
  valid_600925 = validateParameter(valid_600925, JString, required = false,
                                 default = nil)
  if valid_600925 != nil:
    section.add "DBInstanceIdentifier", valid_600925
  var valid_600926 = query.getOrDefault("DBSnapshotIdentifier")
  valid_600926 = validateParameter(valid_600926, JString, required = false,
                                 default = nil)
  if valid_600926 != nil:
    section.add "DBSnapshotIdentifier", valid_600926
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600927 = header.getOrDefault("X-Amz-Date")
  valid_600927 = validateParameter(valid_600927, JString, required = false,
                                 default = nil)
  if valid_600927 != nil:
    section.add "X-Amz-Date", valid_600927
  var valid_600928 = header.getOrDefault("X-Amz-Security-Token")
  valid_600928 = validateParameter(valid_600928, JString, required = false,
                                 default = nil)
  if valid_600928 != nil:
    section.add "X-Amz-Security-Token", valid_600928
  var valid_600929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600929 = validateParameter(valid_600929, JString, required = false,
                                 default = nil)
  if valid_600929 != nil:
    section.add "X-Amz-Content-Sha256", valid_600929
  var valid_600930 = header.getOrDefault("X-Amz-Algorithm")
  valid_600930 = validateParameter(valid_600930, JString, required = false,
                                 default = nil)
  if valid_600930 != nil:
    section.add "X-Amz-Algorithm", valid_600930
  var valid_600931 = header.getOrDefault("X-Amz-Signature")
  valid_600931 = validateParameter(valid_600931, JString, required = false,
                                 default = nil)
  if valid_600931 != nil:
    section.add "X-Amz-Signature", valid_600931
  var valid_600932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600932 = validateParameter(valid_600932, JString, required = false,
                                 default = nil)
  if valid_600932 != nil:
    section.add "X-Amz-SignedHeaders", valid_600932
  var valid_600933 = header.getOrDefault("X-Amz-Credential")
  valid_600933 = validateParameter(valid_600933, JString, required = false,
                                 default = nil)
  if valid_600933 != nil:
    section.add "X-Amz-Credential", valid_600933
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600934: Call_GetDescribeDBSnapshots_600917; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600934.validator(path, query, header, formData, body)
  let scheme = call_600934.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600934.url(scheme.get, call_600934.host, call_600934.base,
                         call_600934.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600934, url, valid)

proc call*(call_600935: Call_GetDescribeDBSnapshots_600917; MaxRecords: int = 0;
          Action: string = "DescribeDBSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2013-02-12";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_600936 = newJObject()
  add(query_600936, "MaxRecords", newJInt(MaxRecords))
  add(query_600936, "Action", newJString(Action))
  add(query_600936, "Marker", newJString(Marker))
  add(query_600936, "SnapshotType", newJString(SnapshotType))
  add(query_600936, "Version", newJString(Version))
  add(query_600936, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_600936, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_600935.call(nil, query_600936, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_600917(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_600918, base: "/",
    url: url_GetDescribeDBSnapshots_600919, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_600976 = ref object of OpenApiRestCall_599352
proc url_PostDescribeDBSubnetGroups_600978(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_600977(path: JsonNode; query: JsonNode;
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
  var valid_600979 = query.getOrDefault("Action")
  valid_600979 = validateParameter(valid_600979, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_600979 != nil:
    section.add "Action", valid_600979
  var valid_600980 = query.getOrDefault("Version")
  valid_600980 = validateParameter(valid_600980, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600980 != nil:
    section.add "Version", valid_600980
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600981 = header.getOrDefault("X-Amz-Date")
  valid_600981 = validateParameter(valid_600981, JString, required = false,
                                 default = nil)
  if valid_600981 != nil:
    section.add "X-Amz-Date", valid_600981
  var valid_600982 = header.getOrDefault("X-Amz-Security-Token")
  valid_600982 = validateParameter(valid_600982, JString, required = false,
                                 default = nil)
  if valid_600982 != nil:
    section.add "X-Amz-Security-Token", valid_600982
  var valid_600983 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600983 = validateParameter(valid_600983, JString, required = false,
                                 default = nil)
  if valid_600983 != nil:
    section.add "X-Amz-Content-Sha256", valid_600983
  var valid_600984 = header.getOrDefault("X-Amz-Algorithm")
  valid_600984 = validateParameter(valid_600984, JString, required = false,
                                 default = nil)
  if valid_600984 != nil:
    section.add "X-Amz-Algorithm", valid_600984
  var valid_600985 = header.getOrDefault("X-Amz-Signature")
  valid_600985 = validateParameter(valid_600985, JString, required = false,
                                 default = nil)
  if valid_600985 != nil:
    section.add "X-Amz-Signature", valid_600985
  var valid_600986 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600986 = validateParameter(valid_600986, JString, required = false,
                                 default = nil)
  if valid_600986 != nil:
    section.add "X-Amz-SignedHeaders", valid_600986
  var valid_600987 = header.getOrDefault("X-Amz-Credential")
  valid_600987 = validateParameter(valid_600987, JString, required = false,
                                 default = nil)
  if valid_600987 != nil:
    section.add "X-Amz-Credential", valid_600987
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_600988 = formData.getOrDefault("DBSubnetGroupName")
  valid_600988 = validateParameter(valid_600988, JString, required = false,
                                 default = nil)
  if valid_600988 != nil:
    section.add "DBSubnetGroupName", valid_600988
  var valid_600989 = formData.getOrDefault("Marker")
  valid_600989 = validateParameter(valid_600989, JString, required = false,
                                 default = nil)
  if valid_600989 != nil:
    section.add "Marker", valid_600989
  var valid_600990 = formData.getOrDefault("MaxRecords")
  valid_600990 = validateParameter(valid_600990, JInt, required = false, default = nil)
  if valid_600990 != nil:
    section.add "MaxRecords", valid_600990
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600991: Call_PostDescribeDBSubnetGroups_600976; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600991.validator(path, query, header, formData, body)
  let scheme = call_600991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600991.url(scheme.get, call_600991.host, call_600991.base,
                         call_600991.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600991, url, valid)

proc call*(call_600992: Call_PostDescribeDBSubnetGroups_600976;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_600993 = newJObject()
  var formData_600994 = newJObject()
  add(formData_600994, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_600994, "Marker", newJString(Marker))
  add(query_600993, "Action", newJString(Action))
  add(formData_600994, "MaxRecords", newJInt(MaxRecords))
  add(query_600993, "Version", newJString(Version))
  result = call_600992.call(nil, query_600993, nil, formData_600994, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_600976(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_600977, base: "/",
    url: url_PostDescribeDBSubnetGroups_600978,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_600958 = ref object of OpenApiRestCall_599352
proc url_GetDescribeDBSubnetGroups_600960(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_600959(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600961 = query.getOrDefault("MaxRecords")
  valid_600961 = validateParameter(valid_600961, JInt, required = false, default = nil)
  if valid_600961 != nil:
    section.add "MaxRecords", valid_600961
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_600962 = query.getOrDefault("Action")
  valid_600962 = validateParameter(valid_600962, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_600962 != nil:
    section.add "Action", valid_600962
  var valid_600963 = query.getOrDefault("Marker")
  valid_600963 = validateParameter(valid_600963, JString, required = false,
                                 default = nil)
  if valid_600963 != nil:
    section.add "Marker", valid_600963
  var valid_600964 = query.getOrDefault("DBSubnetGroupName")
  valid_600964 = validateParameter(valid_600964, JString, required = false,
                                 default = nil)
  if valid_600964 != nil:
    section.add "DBSubnetGroupName", valid_600964
  var valid_600965 = query.getOrDefault("Version")
  valid_600965 = validateParameter(valid_600965, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_600965 != nil:
    section.add "Version", valid_600965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600966 = header.getOrDefault("X-Amz-Date")
  valid_600966 = validateParameter(valid_600966, JString, required = false,
                                 default = nil)
  if valid_600966 != nil:
    section.add "X-Amz-Date", valid_600966
  var valid_600967 = header.getOrDefault("X-Amz-Security-Token")
  valid_600967 = validateParameter(valid_600967, JString, required = false,
                                 default = nil)
  if valid_600967 != nil:
    section.add "X-Amz-Security-Token", valid_600967
  var valid_600968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600968 = validateParameter(valid_600968, JString, required = false,
                                 default = nil)
  if valid_600968 != nil:
    section.add "X-Amz-Content-Sha256", valid_600968
  var valid_600969 = header.getOrDefault("X-Amz-Algorithm")
  valid_600969 = validateParameter(valid_600969, JString, required = false,
                                 default = nil)
  if valid_600969 != nil:
    section.add "X-Amz-Algorithm", valid_600969
  var valid_600970 = header.getOrDefault("X-Amz-Signature")
  valid_600970 = validateParameter(valid_600970, JString, required = false,
                                 default = nil)
  if valid_600970 != nil:
    section.add "X-Amz-Signature", valid_600970
  var valid_600971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600971 = validateParameter(valid_600971, JString, required = false,
                                 default = nil)
  if valid_600971 != nil:
    section.add "X-Amz-SignedHeaders", valid_600971
  var valid_600972 = header.getOrDefault("X-Amz-Credential")
  valid_600972 = validateParameter(valid_600972, JString, required = false,
                                 default = nil)
  if valid_600972 != nil:
    section.add "X-Amz-Credential", valid_600972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600973: Call_GetDescribeDBSubnetGroups_600958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_600973.validator(path, query, header, formData, body)
  let scheme = call_600973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600973.url(scheme.get, call_600973.host, call_600973.base,
                         call_600973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600973, url, valid)

proc call*(call_600974: Call_GetDescribeDBSubnetGroups_600958; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_600975 = newJObject()
  add(query_600975, "MaxRecords", newJInt(MaxRecords))
  add(query_600975, "Action", newJString(Action))
  add(query_600975, "Marker", newJString(Marker))
  add(query_600975, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_600975, "Version", newJString(Version))
  result = call_600974.call(nil, query_600975, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_600958(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_600959, base: "/",
    url: url_GetDescribeDBSubnetGroups_600960,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_601013 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEngineDefaultParameters_601015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_601014(path: JsonNode;
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
  var valid_601016 = query.getOrDefault("Action")
  valid_601016 = validateParameter(valid_601016, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_601016 != nil:
    section.add "Action", valid_601016
  var valid_601017 = query.getOrDefault("Version")
  valid_601017 = validateParameter(valid_601017, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601017 != nil:
    section.add "Version", valid_601017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601018 = header.getOrDefault("X-Amz-Date")
  valid_601018 = validateParameter(valid_601018, JString, required = false,
                                 default = nil)
  if valid_601018 != nil:
    section.add "X-Amz-Date", valid_601018
  var valid_601019 = header.getOrDefault("X-Amz-Security-Token")
  valid_601019 = validateParameter(valid_601019, JString, required = false,
                                 default = nil)
  if valid_601019 != nil:
    section.add "X-Amz-Security-Token", valid_601019
  var valid_601020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601020 = validateParameter(valid_601020, JString, required = false,
                                 default = nil)
  if valid_601020 != nil:
    section.add "X-Amz-Content-Sha256", valid_601020
  var valid_601021 = header.getOrDefault("X-Amz-Algorithm")
  valid_601021 = validateParameter(valid_601021, JString, required = false,
                                 default = nil)
  if valid_601021 != nil:
    section.add "X-Amz-Algorithm", valid_601021
  var valid_601022 = header.getOrDefault("X-Amz-Signature")
  valid_601022 = validateParameter(valid_601022, JString, required = false,
                                 default = nil)
  if valid_601022 != nil:
    section.add "X-Amz-Signature", valid_601022
  var valid_601023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601023 = validateParameter(valid_601023, JString, required = false,
                                 default = nil)
  if valid_601023 != nil:
    section.add "X-Amz-SignedHeaders", valid_601023
  var valid_601024 = header.getOrDefault("X-Amz-Credential")
  valid_601024 = validateParameter(valid_601024, JString, required = false,
                                 default = nil)
  if valid_601024 != nil:
    section.add "X-Amz-Credential", valid_601024
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601025 = formData.getOrDefault("Marker")
  valid_601025 = validateParameter(valid_601025, JString, required = false,
                                 default = nil)
  if valid_601025 != nil:
    section.add "Marker", valid_601025
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_601026 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601026 = validateParameter(valid_601026, JString, required = true,
                                 default = nil)
  if valid_601026 != nil:
    section.add "DBParameterGroupFamily", valid_601026
  var valid_601027 = formData.getOrDefault("MaxRecords")
  valid_601027 = validateParameter(valid_601027, JInt, required = false, default = nil)
  if valid_601027 != nil:
    section.add "MaxRecords", valid_601027
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601028: Call_PostDescribeEngineDefaultParameters_601013;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601028.validator(path, query, header, formData, body)
  let scheme = call_601028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601028.url(scheme.get, call_601028.host, call_601028.base,
                         call_601028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601028, url, valid)

proc call*(call_601029: Call_PostDescribeEngineDefaultParameters_601013;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601030 = newJObject()
  var formData_601031 = newJObject()
  add(formData_601031, "Marker", newJString(Marker))
  add(query_601030, "Action", newJString(Action))
  add(formData_601031, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_601031, "MaxRecords", newJInt(MaxRecords))
  add(query_601030, "Version", newJString(Version))
  result = call_601029.call(nil, query_601030, nil, formData_601031, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_601013(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_601014, base: "/",
    url: url_PostDescribeEngineDefaultParameters_601015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_600995 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEngineDefaultParameters_600997(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_600996(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600998 = query.getOrDefault("MaxRecords")
  valid_600998 = validateParameter(valid_600998, JInt, required = false, default = nil)
  if valid_600998 != nil:
    section.add "MaxRecords", valid_600998
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_600999 = query.getOrDefault("DBParameterGroupFamily")
  valid_600999 = validateParameter(valid_600999, JString, required = true,
                                 default = nil)
  if valid_600999 != nil:
    section.add "DBParameterGroupFamily", valid_600999
  var valid_601000 = query.getOrDefault("Action")
  valid_601000 = validateParameter(valid_601000, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_601000 != nil:
    section.add "Action", valid_601000
  var valid_601001 = query.getOrDefault("Marker")
  valid_601001 = validateParameter(valid_601001, JString, required = false,
                                 default = nil)
  if valid_601001 != nil:
    section.add "Marker", valid_601001
  var valid_601002 = query.getOrDefault("Version")
  valid_601002 = validateParameter(valid_601002, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601002 != nil:
    section.add "Version", valid_601002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601003 = header.getOrDefault("X-Amz-Date")
  valid_601003 = validateParameter(valid_601003, JString, required = false,
                                 default = nil)
  if valid_601003 != nil:
    section.add "X-Amz-Date", valid_601003
  var valid_601004 = header.getOrDefault("X-Amz-Security-Token")
  valid_601004 = validateParameter(valid_601004, JString, required = false,
                                 default = nil)
  if valid_601004 != nil:
    section.add "X-Amz-Security-Token", valid_601004
  var valid_601005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601005 = validateParameter(valid_601005, JString, required = false,
                                 default = nil)
  if valid_601005 != nil:
    section.add "X-Amz-Content-Sha256", valid_601005
  var valid_601006 = header.getOrDefault("X-Amz-Algorithm")
  valid_601006 = validateParameter(valid_601006, JString, required = false,
                                 default = nil)
  if valid_601006 != nil:
    section.add "X-Amz-Algorithm", valid_601006
  var valid_601007 = header.getOrDefault("X-Amz-Signature")
  valid_601007 = validateParameter(valid_601007, JString, required = false,
                                 default = nil)
  if valid_601007 != nil:
    section.add "X-Amz-Signature", valid_601007
  var valid_601008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601008 = validateParameter(valid_601008, JString, required = false,
                                 default = nil)
  if valid_601008 != nil:
    section.add "X-Amz-SignedHeaders", valid_601008
  var valid_601009 = header.getOrDefault("X-Amz-Credential")
  valid_601009 = validateParameter(valid_601009, JString, required = false,
                                 default = nil)
  if valid_601009 != nil:
    section.add "X-Amz-Credential", valid_601009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601010: Call_GetDescribeEngineDefaultParameters_600995;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601010.validator(path, query, header, formData, body)
  let scheme = call_601010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601010.url(scheme.get, call_601010.host, call_601010.base,
                         call_601010.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601010, url, valid)

proc call*(call_601011: Call_GetDescribeEngineDefaultParameters_600995;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_601012 = newJObject()
  add(query_601012, "MaxRecords", newJInt(MaxRecords))
  add(query_601012, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_601012, "Action", newJString(Action))
  add(query_601012, "Marker", newJString(Marker))
  add(query_601012, "Version", newJString(Version))
  result = call_601011.call(nil, query_601012, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_600995(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_600996, base: "/",
    url: url_GetDescribeEngineDefaultParameters_600997,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_601048 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEventCategories_601050(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_601049(path: JsonNode; query: JsonNode;
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
  var valid_601051 = query.getOrDefault("Action")
  valid_601051 = validateParameter(valid_601051, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601051 != nil:
    section.add "Action", valid_601051
  var valid_601052 = query.getOrDefault("Version")
  valid_601052 = validateParameter(valid_601052, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601052 != nil:
    section.add "Version", valid_601052
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601053 = header.getOrDefault("X-Amz-Date")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Date", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-Security-Token")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Security-Token", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Content-Sha256", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Algorithm")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Algorithm", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Signature")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Signature", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-SignedHeaders", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Credential")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Credential", valid_601059
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_601060 = formData.getOrDefault("SourceType")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "SourceType", valid_601060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601061: Call_PostDescribeEventCategories_601048; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601061.validator(path, query, header, formData, body)
  let scheme = call_601061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601061.url(scheme.get, call_601061.host, call_601061.base,
                         call_601061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601061, url, valid)

proc call*(call_601062: Call_PostDescribeEventCategories_601048;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_601063 = newJObject()
  var formData_601064 = newJObject()
  add(query_601063, "Action", newJString(Action))
  add(query_601063, "Version", newJString(Version))
  add(formData_601064, "SourceType", newJString(SourceType))
  result = call_601062.call(nil, query_601063, nil, formData_601064, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_601048(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_601049, base: "/",
    url: url_PostDescribeEventCategories_601050,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_601032 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEventCategories_601034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_601033(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601035 = query.getOrDefault("SourceType")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "SourceType", valid_601035
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601036 = query.getOrDefault("Action")
  valid_601036 = validateParameter(valid_601036, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_601036 != nil:
    section.add "Action", valid_601036
  var valid_601037 = query.getOrDefault("Version")
  valid_601037 = validateParameter(valid_601037, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601037 != nil:
    section.add "Version", valid_601037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601038 = header.getOrDefault("X-Amz-Date")
  valid_601038 = validateParameter(valid_601038, JString, required = false,
                                 default = nil)
  if valid_601038 != nil:
    section.add "X-Amz-Date", valid_601038
  var valid_601039 = header.getOrDefault("X-Amz-Security-Token")
  valid_601039 = validateParameter(valid_601039, JString, required = false,
                                 default = nil)
  if valid_601039 != nil:
    section.add "X-Amz-Security-Token", valid_601039
  var valid_601040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Content-Sha256", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Algorithm")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Algorithm", valid_601041
  var valid_601042 = header.getOrDefault("X-Amz-Signature")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Signature", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-SignedHeaders", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Credential")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Credential", valid_601044
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601045: Call_GetDescribeEventCategories_601032; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601045.validator(path, query, header, formData, body)
  let scheme = call_601045.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601045.url(scheme.get, call_601045.host, call_601045.base,
                         call_601045.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601045, url, valid)

proc call*(call_601046: Call_GetDescribeEventCategories_601032;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601047 = newJObject()
  add(query_601047, "SourceType", newJString(SourceType))
  add(query_601047, "Action", newJString(Action))
  add(query_601047, "Version", newJString(Version))
  result = call_601046.call(nil, query_601047, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_601032(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_601033, base: "/",
    url: url_GetDescribeEventCategories_601034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_601083 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEventSubscriptions_601085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_601084(path: JsonNode;
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
  var valid_601086 = query.getOrDefault("Action")
  valid_601086 = validateParameter(valid_601086, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_601086 != nil:
    section.add "Action", valid_601086
  var valid_601087 = query.getOrDefault("Version")
  valid_601087 = validateParameter(valid_601087, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601087 != nil:
    section.add "Version", valid_601087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601088 = header.getOrDefault("X-Amz-Date")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Date", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Security-Token")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Security-Token", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Content-Sha256", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-Algorithm")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-Algorithm", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Signature")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Signature", valid_601092
  var valid_601093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "X-Amz-SignedHeaders", valid_601093
  var valid_601094 = header.getOrDefault("X-Amz-Credential")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "X-Amz-Credential", valid_601094
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601095 = formData.getOrDefault("Marker")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "Marker", valid_601095
  var valid_601096 = formData.getOrDefault("SubscriptionName")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "SubscriptionName", valid_601096
  var valid_601097 = formData.getOrDefault("MaxRecords")
  valid_601097 = validateParameter(valid_601097, JInt, required = false, default = nil)
  if valid_601097 != nil:
    section.add "MaxRecords", valid_601097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601098: Call_PostDescribeEventSubscriptions_601083; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601098.validator(path, query, header, formData, body)
  let scheme = call_601098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601098.url(scheme.get, call_601098.host, call_601098.base,
                         call_601098.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601098, url, valid)

proc call*(call_601099: Call_PostDescribeEventSubscriptions_601083;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601100 = newJObject()
  var formData_601101 = newJObject()
  add(formData_601101, "Marker", newJString(Marker))
  add(formData_601101, "SubscriptionName", newJString(SubscriptionName))
  add(query_601100, "Action", newJString(Action))
  add(formData_601101, "MaxRecords", newJInt(MaxRecords))
  add(query_601100, "Version", newJString(Version))
  result = call_601099.call(nil, query_601100, nil, formData_601101, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_601083(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_601084, base: "/",
    url: url_PostDescribeEventSubscriptions_601085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_601065 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEventSubscriptions_601067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_601066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601068 = query.getOrDefault("MaxRecords")
  valid_601068 = validateParameter(valid_601068, JInt, required = false, default = nil)
  if valid_601068 != nil:
    section.add "MaxRecords", valid_601068
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601069 = query.getOrDefault("Action")
  valid_601069 = validateParameter(valid_601069, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_601069 != nil:
    section.add "Action", valid_601069
  var valid_601070 = query.getOrDefault("Marker")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "Marker", valid_601070
  var valid_601071 = query.getOrDefault("SubscriptionName")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "SubscriptionName", valid_601071
  var valid_601072 = query.getOrDefault("Version")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601072 != nil:
    section.add "Version", valid_601072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601073 = header.getOrDefault("X-Amz-Date")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Date", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Security-Token")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Security-Token", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Content-Sha256", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-Algorithm")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-Algorithm", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Signature")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Signature", valid_601077
  var valid_601078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601078 = validateParameter(valid_601078, JString, required = false,
                                 default = nil)
  if valid_601078 != nil:
    section.add "X-Amz-SignedHeaders", valid_601078
  var valid_601079 = header.getOrDefault("X-Amz-Credential")
  valid_601079 = validateParameter(valid_601079, JString, required = false,
                                 default = nil)
  if valid_601079 != nil:
    section.add "X-Amz-Credential", valid_601079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601080: Call_GetDescribeEventSubscriptions_601065; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601080.validator(path, query, header, formData, body)
  let scheme = call_601080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601080.url(scheme.get, call_601080.host, call_601080.base,
                         call_601080.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601080, url, valid)

proc call*(call_601081: Call_GetDescribeEventSubscriptions_601065;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_601082 = newJObject()
  add(query_601082, "MaxRecords", newJInt(MaxRecords))
  add(query_601082, "Action", newJString(Action))
  add(query_601082, "Marker", newJString(Marker))
  add(query_601082, "SubscriptionName", newJString(SubscriptionName))
  add(query_601082, "Version", newJString(Version))
  result = call_601081.call(nil, query_601082, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_601065(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_601066, base: "/",
    url: url_GetDescribeEventSubscriptions_601067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_601125 = ref object of OpenApiRestCall_599352
proc url_PostDescribeEvents_601127(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_601126(path: JsonNode; query: JsonNode;
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
  var valid_601128 = query.getOrDefault("Action")
  valid_601128 = validateParameter(valid_601128, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601128 != nil:
    section.add "Action", valid_601128
  var valid_601129 = query.getOrDefault("Version")
  valid_601129 = validateParameter(valid_601129, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601129 != nil:
    section.add "Version", valid_601129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-Content-Sha256", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Algorithm")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Algorithm", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Signature")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Signature", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-SignedHeaders", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-Credential")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-Credential", valid_601136
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
  var valid_601137 = formData.getOrDefault("SourceIdentifier")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "SourceIdentifier", valid_601137
  var valid_601138 = formData.getOrDefault("EventCategories")
  valid_601138 = validateParameter(valid_601138, JArray, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "EventCategories", valid_601138
  var valid_601139 = formData.getOrDefault("Marker")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "Marker", valid_601139
  var valid_601140 = formData.getOrDefault("StartTime")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "StartTime", valid_601140
  var valid_601141 = formData.getOrDefault("Duration")
  valid_601141 = validateParameter(valid_601141, JInt, required = false, default = nil)
  if valid_601141 != nil:
    section.add "Duration", valid_601141
  var valid_601142 = formData.getOrDefault("EndTime")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "EndTime", valid_601142
  var valid_601143 = formData.getOrDefault("MaxRecords")
  valid_601143 = validateParameter(valid_601143, JInt, required = false, default = nil)
  if valid_601143 != nil:
    section.add "MaxRecords", valid_601143
  var valid_601144 = formData.getOrDefault("SourceType")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_601144 != nil:
    section.add "SourceType", valid_601144
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601145: Call_PostDescribeEvents_601125; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601145.validator(path, query, header, formData, body)
  let scheme = call_601145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601145.url(scheme.get, call_601145.host, call_601145.base,
                         call_601145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601145, url, valid)

proc call*(call_601146: Call_PostDescribeEvents_601125;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; EndTime: string = "";
          MaxRecords: int = 0; Version: string = "2013-02-12";
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
  var query_601147 = newJObject()
  var formData_601148 = newJObject()
  add(formData_601148, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_601148.add "EventCategories", EventCategories
  add(formData_601148, "Marker", newJString(Marker))
  add(formData_601148, "StartTime", newJString(StartTime))
  add(query_601147, "Action", newJString(Action))
  add(formData_601148, "Duration", newJInt(Duration))
  add(formData_601148, "EndTime", newJString(EndTime))
  add(formData_601148, "MaxRecords", newJInt(MaxRecords))
  add(query_601147, "Version", newJString(Version))
  add(formData_601148, "SourceType", newJString(SourceType))
  result = call_601146.call(nil, query_601147, nil, formData_601148, nil)

var postDescribeEvents* = Call_PostDescribeEvents_601125(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_601126, base: "/",
    url: url_PostDescribeEvents_601127, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_601102 = ref object of OpenApiRestCall_599352
proc url_GetDescribeEvents_601104(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_601103(path: JsonNode; query: JsonNode;
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
  ##   Action: JString (required)
  ##   SourceIdentifier: JString
  ##   Marker: JString
  ##   EventCategories: JArray
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_601105 = query.getOrDefault("SourceType")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_601105 != nil:
    section.add "SourceType", valid_601105
  var valid_601106 = query.getOrDefault("MaxRecords")
  valid_601106 = validateParameter(valid_601106, JInt, required = false, default = nil)
  if valid_601106 != nil:
    section.add "MaxRecords", valid_601106
  var valid_601107 = query.getOrDefault("StartTime")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "StartTime", valid_601107
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601108 = query.getOrDefault("Action")
  valid_601108 = validateParameter(valid_601108, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_601108 != nil:
    section.add "Action", valid_601108
  var valid_601109 = query.getOrDefault("SourceIdentifier")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "SourceIdentifier", valid_601109
  var valid_601110 = query.getOrDefault("Marker")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "Marker", valid_601110
  var valid_601111 = query.getOrDefault("EventCategories")
  valid_601111 = validateParameter(valid_601111, JArray, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "EventCategories", valid_601111
  var valid_601112 = query.getOrDefault("Duration")
  valid_601112 = validateParameter(valid_601112, JInt, required = false, default = nil)
  if valid_601112 != nil:
    section.add "Duration", valid_601112
  var valid_601113 = query.getOrDefault("EndTime")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "EndTime", valid_601113
  var valid_601114 = query.getOrDefault("Version")
  valid_601114 = validateParameter(valid_601114, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601114 != nil:
    section.add "Version", valid_601114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  var valid_601117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601117 = validateParameter(valid_601117, JString, required = false,
                                 default = nil)
  if valid_601117 != nil:
    section.add "X-Amz-Content-Sha256", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Algorithm")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Algorithm", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Signature")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Signature", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-SignedHeaders", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-Credential")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-Credential", valid_601121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601122: Call_GetDescribeEvents_601102; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601122.validator(path, query, header, formData, body)
  let scheme = call_601122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601122.url(scheme.get, call_601122.host, call_601122.base,
                         call_601122.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601122, url, valid)

proc call*(call_601123: Call_GetDescribeEvents_601102;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Action: string = "DescribeEvents";
          SourceIdentifier: string = ""; Marker: string = "";
          EventCategories: JsonNode = nil; Duration: int = 0; EndTime: string = "";
          Version: string = "2013-02-12"): Recallable =
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
  var query_601124 = newJObject()
  add(query_601124, "SourceType", newJString(SourceType))
  add(query_601124, "MaxRecords", newJInt(MaxRecords))
  add(query_601124, "StartTime", newJString(StartTime))
  add(query_601124, "Action", newJString(Action))
  add(query_601124, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601124, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_601124.add "EventCategories", EventCategories
  add(query_601124, "Duration", newJInt(Duration))
  add(query_601124, "EndTime", newJString(EndTime))
  add(query_601124, "Version", newJString(Version))
  result = call_601123.call(nil, query_601124, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_601102(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_601103,
    base: "/", url: url_GetDescribeEvents_601104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_601168 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOptionGroupOptions_601170(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_601169(path: JsonNode;
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
  var valid_601171 = query.getOrDefault("Action")
  valid_601171 = validateParameter(valid_601171, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_601171 != nil:
    section.add "Action", valid_601171
  var valid_601172 = query.getOrDefault("Version")
  valid_601172 = validateParameter(valid_601172, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601180 = formData.getOrDefault("MajorEngineVersion")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "MajorEngineVersion", valid_601180
  var valid_601181 = formData.getOrDefault("Marker")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "Marker", valid_601181
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_601182 = formData.getOrDefault("EngineName")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = nil)
  if valid_601182 != nil:
    section.add "EngineName", valid_601182
  var valid_601183 = formData.getOrDefault("MaxRecords")
  valid_601183 = validateParameter(valid_601183, JInt, required = false, default = nil)
  if valid_601183 != nil:
    section.add "MaxRecords", valid_601183
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_PostDescribeOptionGroupOptions_601168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601184, url, valid)

proc call*(call_601185: Call_PostDescribeOptionGroupOptions_601168;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601186 = newJObject()
  var formData_601187 = newJObject()
  add(formData_601187, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601187, "Marker", newJString(Marker))
  add(query_601186, "Action", newJString(Action))
  add(formData_601187, "EngineName", newJString(EngineName))
  add(formData_601187, "MaxRecords", newJInt(MaxRecords))
  add(query_601186, "Version", newJString(Version))
  result = call_601185.call(nil, query_601186, nil, formData_601187, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_601168(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_601169, base: "/",
    url: url_PostDescribeOptionGroupOptions_601170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_601149 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOptionGroupOptions_601151(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_601150(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601152 = query.getOrDefault("MaxRecords")
  valid_601152 = validateParameter(valid_601152, JInt, required = false, default = nil)
  if valid_601152 != nil:
    section.add "MaxRecords", valid_601152
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601153 = query.getOrDefault("Action")
  valid_601153 = validateParameter(valid_601153, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_601153 != nil:
    section.add "Action", valid_601153
  var valid_601154 = query.getOrDefault("Marker")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "Marker", valid_601154
  var valid_601155 = query.getOrDefault("Version")
  valid_601155 = validateParameter(valid_601155, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601155 != nil:
    section.add "Version", valid_601155
  var valid_601156 = query.getOrDefault("EngineName")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = nil)
  if valid_601156 != nil:
    section.add "EngineName", valid_601156
  var valid_601157 = query.getOrDefault("MajorEngineVersion")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "MajorEngineVersion", valid_601157
  result.add "query", section
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

proc call*(call_601165: Call_GetDescribeOptionGroupOptions_601149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601165.validator(path, query, header, formData, body)
  let scheme = call_601165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601165.url(scheme.get, call_601165.host, call_601165.base,
                         call_601165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601165, url, valid)

proc call*(call_601166: Call_GetDescribeOptionGroupOptions_601149;
          EngineName: string; MaxRecords: int = 0;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2013-02-12"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_601167 = newJObject()
  add(query_601167, "MaxRecords", newJInt(MaxRecords))
  add(query_601167, "Action", newJString(Action))
  add(query_601167, "Marker", newJString(Marker))
  add(query_601167, "Version", newJString(Version))
  add(query_601167, "EngineName", newJString(EngineName))
  add(query_601167, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601166.call(nil, query_601167, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_601149(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_601150, base: "/",
    url: url_GetDescribeOptionGroupOptions_601151,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_601208 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOptionGroups_601210(protocol: Scheme; host: string;
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

proc validate_PostDescribeOptionGroups_601209(path: JsonNode; query: JsonNode;
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
  var valid_601211 = query.getOrDefault("Action")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_601211 != nil:
    section.add "Action", valid_601211
  var valid_601212 = query.getOrDefault("Version")
  valid_601212 = validateParameter(valid_601212, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601212 != nil:
    section.add "Version", valid_601212
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601213 = header.getOrDefault("X-Amz-Date")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Date", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Security-Token")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Security-Token", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Content-Sha256", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Algorithm")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Algorithm", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Signature")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Signature", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-SignedHeaders", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Credential")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Credential", valid_601219
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601220 = formData.getOrDefault("MajorEngineVersion")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "MajorEngineVersion", valid_601220
  var valid_601221 = formData.getOrDefault("OptionGroupName")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "OptionGroupName", valid_601221
  var valid_601222 = formData.getOrDefault("Marker")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "Marker", valid_601222
  var valid_601223 = formData.getOrDefault("EngineName")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "EngineName", valid_601223
  var valid_601224 = formData.getOrDefault("MaxRecords")
  valid_601224 = validateParameter(valid_601224, JInt, required = false, default = nil)
  if valid_601224 != nil:
    section.add "MaxRecords", valid_601224
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601225: Call_PostDescribeOptionGroups_601208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601225.validator(path, query, header, formData, body)
  let scheme = call_601225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601225.url(scheme.get, call_601225.host, call_601225.base,
                         call_601225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601225, url, valid)

proc call*(call_601226: Call_PostDescribeOptionGroups_601208;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; MaxRecords: int = 0; Version: string = "2013-02-12"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601227 = newJObject()
  var formData_601228 = newJObject()
  add(formData_601228, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601228, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601228, "Marker", newJString(Marker))
  add(query_601227, "Action", newJString(Action))
  add(formData_601228, "EngineName", newJString(EngineName))
  add(formData_601228, "MaxRecords", newJInt(MaxRecords))
  add(query_601227, "Version", newJString(Version))
  result = call_601226.call(nil, query_601227, nil, formData_601228, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_601208(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_601209, base: "/",
    url: url_PostDescribeOptionGroups_601210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_601188 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOptionGroups_601190(protocol: Scheme; host: string; base: string;
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

proc validate_GetDescribeOptionGroups_601189(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601191 = query.getOrDefault("MaxRecords")
  valid_601191 = validateParameter(valid_601191, JInt, required = false, default = nil)
  if valid_601191 != nil:
    section.add "MaxRecords", valid_601191
  var valid_601192 = query.getOrDefault("OptionGroupName")
  valid_601192 = validateParameter(valid_601192, JString, required = false,
                                 default = nil)
  if valid_601192 != nil:
    section.add "OptionGroupName", valid_601192
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601193 = query.getOrDefault("Action")
  valid_601193 = validateParameter(valid_601193, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_601193 != nil:
    section.add "Action", valid_601193
  var valid_601194 = query.getOrDefault("Marker")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "Marker", valid_601194
  var valid_601195 = query.getOrDefault("Version")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601195 != nil:
    section.add "Version", valid_601195
  var valid_601196 = query.getOrDefault("EngineName")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "EngineName", valid_601196
  var valid_601197 = query.getOrDefault("MajorEngineVersion")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "MajorEngineVersion", valid_601197
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601198 = header.getOrDefault("X-Amz-Date")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Date", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Security-Token")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Security-Token", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Content-Sha256", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Algorithm")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Algorithm", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-Signature")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-Signature", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-SignedHeaders", valid_601203
  var valid_601204 = header.getOrDefault("X-Amz-Credential")
  valid_601204 = validateParameter(valid_601204, JString, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "X-Amz-Credential", valid_601204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601205: Call_GetDescribeOptionGroups_601188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601205.validator(path, query, header, formData, body)
  let scheme = call_601205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601205.url(scheme.get, call_601205.host, call_601205.base,
                         call_601205.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601205, url, valid)

proc call*(call_601206: Call_GetDescribeOptionGroups_601188; MaxRecords: int = 0;
          OptionGroupName: string = ""; Action: string = "DescribeOptionGroups";
          Marker: string = ""; Version: string = "2013-02-12"; EngineName: string = "";
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_601207 = newJObject()
  add(query_601207, "MaxRecords", newJInt(MaxRecords))
  add(query_601207, "OptionGroupName", newJString(OptionGroupName))
  add(query_601207, "Action", newJString(Action))
  add(query_601207, "Marker", newJString(Marker))
  add(query_601207, "Version", newJString(Version))
  add(query_601207, "EngineName", newJString(EngineName))
  add(query_601207, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601206.call(nil, query_601207, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_601188(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_601189, base: "/",
    url: url_GetDescribeOptionGroups_601190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_601251 = ref object of OpenApiRestCall_599352
proc url_PostDescribeOrderableDBInstanceOptions_601253(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_601252(path: JsonNode;
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
  var valid_601254 = query.getOrDefault("Action")
  valid_601254 = validateParameter(valid_601254, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_601254 != nil:
    section.add "Action", valid_601254
  var valid_601255 = query.getOrDefault("Version")
  valid_601255 = validateParameter(valid_601255, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601255 != nil:
    section.add "Version", valid_601255
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601256 = header.getOrDefault("X-Amz-Date")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Date", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Security-Token")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Security-Token", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Content-Sha256", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Algorithm")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Algorithm", valid_601259
  var valid_601260 = header.getOrDefault("X-Amz-Signature")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "X-Amz-Signature", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-SignedHeaders", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Credential")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Credential", valid_601262
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
  var valid_601263 = formData.getOrDefault("Engine")
  valid_601263 = validateParameter(valid_601263, JString, required = true,
                                 default = nil)
  if valid_601263 != nil:
    section.add "Engine", valid_601263
  var valid_601264 = formData.getOrDefault("Marker")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "Marker", valid_601264
  var valid_601265 = formData.getOrDefault("Vpc")
  valid_601265 = validateParameter(valid_601265, JBool, required = false, default = nil)
  if valid_601265 != nil:
    section.add "Vpc", valid_601265
  var valid_601266 = formData.getOrDefault("DBInstanceClass")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "DBInstanceClass", valid_601266
  var valid_601267 = formData.getOrDefault("LicenseModel")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "LicenseModel", valid_601267
  var valid_601268 = formData.getOrDefault("MaxRecords")
  valid_601268 = validateParameter(valid_601268, JInt, required = false, default = nil)
  if valid_601268 != nil:
    section.add "MaxRecords", valid_601268
  var valid_601269 = formData.getOrDefault("EngineVersion")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "EngineVersion", valid_601269
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_PostDescribeOrderableDBInstanceOptions_601251;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601270, url, valid)

proc call*(call_601271: Call_PostDescribeOrderableDBInstanceOptions_601251;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = ""; MaxRecords: int = 0;
          EngineVersion: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_601272 = newJObject()
  var formData_601273 = newJObject()
  add(formData_601273, "Engine", newJString(Engine))
  add(formData_601273, "Marker", newJString(Marker))
  add(query_601272, "Action", newJString(Action))
  add(formData_601273, "Vpc", newJBool(Vpc))
  add(formData_601273, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601273, "LicenseModel", newJString(LicenseModel))
  add(formData_601273, "MaxRecords", newJInt(MaxRecords))
  add(formData_601273, "EngineVersion", newJString(EngineVersion))
  add(query_601272, "Version", newJString(Version))
  result = call_601271.call(nil, query_601272, nil, formData_601273, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_601251(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_601252, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_601253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_601229 = ref object of OpenApiRestCall_599352
proc url_GetDescribeOrderableDBInstanceOptions_601231(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_601230(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601232 = query.getOrDefault("Engine")
  valid_601232 = validateParameter(valid_601232, JString, required = true,
                                 default = nil)
  if valid_601232 != nil:
    section.add "Engine", valid_601232
  var valid_601233 = query.getOrDefault("MaxRecords")
  valid_601233 = validateParameter(valid_601233, JInt, required = false, default = nil)
  if valid_601233 != nil:
    section.add "MaxRecords", valid_601233
  var valid_601234 = query.getOrDefault("LicenseModel")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "LicenseModel", valid_601234
  var valid_601235 = query.getOrDefault("Vpc")
  valid_601235 = validateParameter(valid_601235, JBool, required = false, default = nil)
  if valid_601235 != nil:
    section.add "Vpc", valid_601235
  var valid_601236 = query.getOrDefault("DBInstanceClass")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "DBInstanceClass", valid_601236
  var valid_601237 = query.getOrDefault("Action")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_601237 != nil:
    section.add "Action", valid_601237
  var valid_601238 = query.getOrDefault("Marker")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "Marker", valid_601238
  var valid_601239 = query.getOrDefault("EngineVersion")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "EngineVersion", valid_601239
  var valid_601240 = query.getOrDefault("Version")
  valid_601240 = validateParameter(valid_601240, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601240 != nil:
    section.add "Version", valid_601240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  var valid_601243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "X-Amz-Content-Sha256", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Algorithm")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Algorithm", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Signature")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Signature", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-SignedHeaders", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Credential")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Credential", valid_601247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601248: Call_GetDescribeOrderableDBInstanceOptions_601229;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601248.validator(path, query, header, formData, body)
  let scheme = call_601248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601248.url(scheme.get, call_601248.host, call_601248.base,
                         call_601248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601248, url, valid)

proc call*(call_601249: Call_GetDescribeOrderableDBInstanceOptions_601229;
          Engine: string; MaxRecords: int = 0; LicenseModel: string = "";
          Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2013-02-12"): Recallable =
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
  var query_601250 = newJObject()
  add(query_601250, "Engine", newJString(Engine))
  add(query_601250, "MaxRecords", newJInt(MaxRecords))
  add(query_601250, "LicenseModel", newJString(LicenseModel))
  add(query_601250, "Vpc", newJBool(Vpc))
  add(query_601250, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601250, "Action", newJString(Action))
  add(query_601250, "Marker", newJString(Marker))
  add(query_601250, "EngineVersion", newJString(EngineVersion))
  add(query_601250, "Version", newJString(Version))
  result = call_601249.call(nil, query_601250, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_601229(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_601230, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_601231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_601298 = ref object of OpenApiRestCall_599352
proc url_PostDescribeReservedDBInstances_601300(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_601299(path: JsonNode;
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
  var valid_601301 = query.getOrDefault("Action")
  valid_601301 = validateParameter(valid_601301, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_601301 != nil:
    section.add "Action", valid_601301
  var valid_601302 = query.getOrDefault("Version")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601302 != nil:
    section.add "Version", valid_601302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601303 = header.getOrDefault("X-Amz-Date")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-Date", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Security-Token")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Security-Token", valid_601304
  var valid_601305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601305 = validateParameter(valid_601305, JString, required = false,
                                 default = nil)
  if valid_601305 != nil:
    section.add "X-Amz-Content-Sha256", valid_601305
  var valid_601306 = header.getOrDefault("X-Amz-Algorithm")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Algorithm", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Signature")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Signature", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-SignedHeaders", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Credential")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Credential", valid_601309
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
  var valid_601310 = formData.getOrDefault("OfferingType")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "OfferingType", valid_601310
  var valid_601311 = formData.getOrDefault("ReservedDBInstanceId")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "ReservedDBInstanceId", valid_601311
  var valid_601312 = formData.getOrDefault("Marker")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "Marker", valid_601312
  var valid_601313 = formData.getOrDefault("MultiAZ")
  valid_601313 = validateParameter(valid_601313, JBool, required = false, default = nil)
  if valid_601313 != nil:
    section.add "MultiAZ", valid_601313
  var valid_601314 = formData.getOrDefault("Duration")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "Duration", valid_601314
  var valid_601315 = formData.getOrDefault("DBInstanceClass")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "DBInstanceClass", valid_601315
  var valid_601316 = formData.getOrDefault("ProductDescription")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "ProductDescription", valid_601316
  var valid_601317 = formData.getOrDefault("MaxRecords")
  valid_601317 = validateParameter(valid_601317, JInt, required = false, default = nil)
  if valid_601317 != nil:
    section.add "MaxRecords", valid_601317
  var valid_601318 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_PostDescribeReservedDBInstances_601298;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601319, url, valid)

proc call*(call_601320: Call_PostDescribeReservedDBInstances_601298;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; ProductDescription: string = "";
          MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
          Version: string = "2013-02-12"): Recallable =
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
  var query_601321 = newJObject()
  var formData_601322 = newJObject()
  add(formData_601322, "OfferingType", newJString(OfferingType))
  add(formData_601322, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_601322, "Marker", newJString(Marker))
  add(formData_601322, "MultiAZ", newJBool(MultiAZ))
  add(query_601321, "Action", newJString(Action))
  add(formData_601322, "Duration", newJString(Duration))
  add(formData_601322, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601322, "ProductDescription", newJString(ProductDescription))
  add(formData_601322, "MaxRecords", newJInt(MaxRecords))
  add(formData_601322, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601321, "Version", newJString(Version))
  result = call_601320.call(nil, query_601321, nil, formData_601322, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_601298(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_601299, base: "/",
    url: url_PostDescribeReservedDBInstances_601300,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_601274 = ref object of OpenApiRestCall_599352
proc url_GetDescribeReservedDBInstances_601276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_601275(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601277 = query.getOrDefault("ProductDescription")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "ProductDescription", valid_601277
  var valid_601278 = query.getOrDefault("MaxRecords")
  valid_601278 = validateParameter(valid_601278, JInt, required = false, default = nil)
  if valid_601278 != nil:
    section.add "MaxRecords", valid_601278
  var valid_601279 = query.getOrDefault("OfferingType")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "OfferingType", valid_601279
  var valid_601280 = query.getOrDefault("MultiAZ")
  valid_601280 = validateParameter(valid_601280, JBool, required = false, default = nil)
  if valid_601280 != nil:
    section.add "MultiAZ", valid_601280
  var valid_601281 = query.getOrDefault("ReservedDBInstanceId")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "ReservedDBInstanceId", valid_601281
  var valid_601282 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601282
  var valid_601283 = query.getOrDefault("DBInstanceClass")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "DBInstanceClass", valid_601283
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601284 = query.getOrDefault("Action")
  valid_601284 = validateParameter(valid_601284, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_601284 != nil:
    section.add "Action", valid_601284
  var valid_601285 = query.getOrDefault("Marker")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "Marker", valid_601285
  var valid_601286 = query.getOrDefault("Duration")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "Duration", valid_601286
  var valid_601287 = query.getOrDefault("Version")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601287 != nil:
    section.add "Version", valid_601287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601288 = header.getOrDefault("X-Amz-Date")
  valid_601288 = validateParameter(valid_601288, JString, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "X-Amz-Date", valid_601288
  var valid_601289 = header.getOrDefault("X-Amz-Security-Token")
  valid_601289 = validateParameter(valid_601289, JString, required = false,
                                 default = nil)
  if valid_601289 != nil:
    section.add "X-Amz-Security-Token", valid_601289
  var valid_601290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601290 = validateParameter(valid_601290, JString, required = false,
                                 default = nil)
  if valid_601290 != nil:
    section.add "X-Amz-Content-Sha256", valid_601290
  var valid_601291 = header.getOrDefault("X-Amz-Algorithm")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "X-Amz-Algorithm", valid_601291
  var valid_601292 = header.getOrDefault("X-Amz-Signature")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Signature", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-SignedHeaders", valid_601293
  var valid_601294 = header.getOrDefault("X-Amz-Credential")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Credential", valid_601294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601295: Call_GetDescribeReservedDBInstances_601274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601295.validator(path, query, header, formData, body)
  let scheme = call_601295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601295.url(scheme.get, call_601295.host, call_601295.base,
                         call_601295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601295, url, valid)

proc call*(call_601296: Call_GetDescribeReservedDBInstances_601274;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_601297 = newJObject()
  add(query_601297, "ProductDescription", newJString(ProductDescription))
  add(query_601297, "MaxRecords", newJInt(MaxRecords))
  add(query_601297, "OfferingType", newJString(OfferingType))
  add(query_601297, "MultiAZ", newJBool(MultiAZ))
  add(query_601297, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_601297, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601297, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601297, "Action", newJString(Action))
  add(query_601297, "Marker", newJString(Marker))
  add(query_601297, "Duration", newJString(Duration))
  add(query_601297, "Version", newJString(Version))
  result = call_601296.call(nil, query_601297, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_601274(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_601275, base: "/",
    url: url_GetDescribeReservedDBInstances_601276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_601346 = ref object of OpenApiRestCall_599352
proc url_PostDescribeReservedDBInstancesOfferings_601348(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_601347(path: JsonNode;
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
  var valid_601349 = query.getOrDefault("Action")
  valid_601349 = validateParameter(valid_601349, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_601349 != nil:
    section.add "Action", valid_601349
  var valid_601350 = query.getOrDefault("Version")
  valid_601350 = validateParameter(valid_601350, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601350 != nil:
    section.add "Version", valid_601350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601351 = header.getOrDefault("X-Amz-Date")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Date", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-Security-Token")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Security-Token", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Content-Sha256", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Algorithm")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Algorithm", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Signature")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Signature", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-SignedHeaders", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-Credential")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Credential", valid_601357
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
  var valid_601358 = formData.getOrDefault("OfferingType")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "OfferingType", valid_601358
  var valid_601359 = formData.getOrDefault("Marker")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "Marker", valid_601359
  var valid_601360 = formData.getOrDefault("MultiAZ")
  valid_601360 = validateParameter(valid_601360, JBool, required = false, default = nil)
  if valid_601360 != nil:
    section.add "MultiAZ", valid_601360
  var valid_601361 = formData.getOrDefault("Duration")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "Duration", valid_601361
  var valid_601362 = formData.getOrDefault("DBInstanceClass")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "DBInstanceClass", valid_601362
  var valid_601363 = formData.getOrDefault("ProductDescription")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "ProductDescription", valid_601363
  var valid_601364 = formData.getOrDefault("MaxRecords")
  valid_601364 = validateParameter(valid_601364, JInt, required = false, default = nil)
  if valid_601364 != nil:
    section.add "MaxRecords", valid_601364
  var valid_601365 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601365
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601366: Call_PostDescribeReservedDBInstancesOfferings_601346;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601366.validator(path, query, header, formData, body)
  let scheme = call_601366.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601366.url(scheme.get, call_601366.host, call_601366.base,
                         call_601366.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601366, url, valid)

proc call*(call_601367: Call_PostDescribeReservedDBInstancesOfferings_601346;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = "";
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_601368 = newJObject()
  var formData_601369 = newJObject()
  add(formData_601369, "OfferingType", newJString(OfferingType))
  add(formData_601369, "Marker", newJString(Marker))
  add(formData_601369, "MultiAZ", newJBool(MultiAZ))
  add(query_601368, "Action", newJString(Action))
  add(formData_601369, "Duration", newJString(Duration))
  add(formData_601369, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601369, "ProductDescription", newJString(ProductDescription))
  add(formData_601369, "MaxRecords", newJInt(MaxRecords))
  add(formData_601369, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601368, "Version", newJString(Version))
  result = call_601367.call(nil, query_601368, nil, formData_601369, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_601346(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_601347,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_601348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_601323 = ref object of OpenApiRestCall_599352
proc url_GetDescribeReservedDBInstancesOfferings_601325(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_601324(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601326 = query.getOrDefault("ProductDescription")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "ProductDescription", valid_601326
  var valid_601327 = query.getOrDefault("MaxRecords")
  valid_601327 = validateParameter(valid_601327, JInt, required = false, default = nil)
  if valid_601327 != nil:
    section.add "MaxRecords", valid_601327
  var valid_601328 = query.getOrDefault("OfferingType")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "OfferingType", valid_601328
  var valid_601329 = query.getOrDefault("MultiAZ")
  valid_601329 = validateParameter(valid_601329, JBool, required = false, default = nil)
  if valid_601329 != nil:
    section.add "MultiAZ", valid_601329
  var valid_601330 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601330
  var valid_601331 = query.getOrDefault("DBInstanceClass")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "DBInstanceClass", valid_601331
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601332 = query.getOrDefault("Action")
  valid_601332 = validateParameter(valid_601332, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_601332 != nil:
    section.add "Action", valid_601332
  var valid_601333 = query.getOrDefault("Marker")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "Marker", valid_601333
  var valid_601334 = query.getOrDefault("Duration")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "Duration", valid_601334
  var valid_601335 = query.getOrDefault("Version")
  valid_601335 = validateParameter(valid_601335, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601335 != nil:
    section.add "Version", valid_601335
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601336 = header.getOrDefault("X-Amz-Date")
  valid_601336 = validateParameter(valid_601336, JString, required = false,
                                 default = nil)
  if valid_601336 != nil:
    section.add "X-Amz-Date", valid_601336
  var valid_601337 = header.getOrDefault("X-Amz-Security-Token")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Security-Token", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Content-Sha256", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Algorithm")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Algorithm", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Signature")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Signature", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-SignedHeaders", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Credential")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Credential", valid_601342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601343: Call_GetDescribeReservedDBInstancesOfferings_601323;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601343.validator(path, query, header, formData, body)
  let scheme = call_601343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601343.url(scheme.get, call_601343.host, call_601343.base,
                         call_601343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601343, url, valid)

proc call*(call_601344: Call_GetDescribeReservedDBInstancesOfferings_601323;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2013-02-12"): Recallable =
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
  var query_601345 = newJObject()
  add(query_601345, "ProductDescription", newJString(ProductDescription))
  add(query_601345, "MaxRecords", newJInt(MaxRecords))
  add(query_601345, "OfferingType", newJString(OfferingType))
  add(query_601345, "MultiAZ", newJBool(MultiAZ))
  add(query_601345, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601345, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601345, "Action", newJString(Action))
  add(query_601345, "Marker", newJString(Marker))
  add(query_601345, "Duration", newJString(Duration))
  add(query_601345, "Version", newJString(Version))
  result = call_601344.call(nil, query_601345, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_601323(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_601324, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_601325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_601389 = ref object of OpenApiRestCall_599352
proc url_PostDownloadDBLogFilePortion_601391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_601390(path: JsonNode; query: JsonNode;
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
  var valid_601392 = query.getOrDefault("Action")
  valid_601392 = validateParameter(valid_601392, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_601392 != nil:
    section.add "Action", valid_601392
  var valid_601393 = query.getOrDefault("Version")
  valid_601393 = validateParameter(valid_601393, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601393 != nil:
    section.add "Version", valid_601393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601394 = header.getOrDefault("X-Amz-Date")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Date", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Security-Token")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Security-Token", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Content-Sha256", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Algorithm")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Algorithm", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Signature")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Signature", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-SignedHeaders", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Credential")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Credential", valid_601400
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_601401 = formData.getOrDefault("NumberOfLines")
  valid_601401 = validateParameter(valid_601401, JInt, required = false, default = nil)
  if valid_601401 != nil:
    section.add "NumberOfLines", valid_601401
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601402 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601402 = validateParameter(valid_601402, JString, required = true,
                                 default = nil)
  if valid_601402 != nil:
    section.add "DBInstanceIdentifier", valid_601402
  var valid_601403 = formData.getOrDefault("Marker")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "Marker", valid_601403
  var valid_601404 = formData.getOrDefault("LogFileName")
  valid_601404 = validateParameter(valid_601404, JString, required = true,
                                 default = nil)
  if valid_601404 != nil:
    section.add "LogFileName", valid_601404
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601405: Call_PostDownloadDBLogFilePortion_601389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601405.validator(path, query, header, formData, body)
  let scheme = call_601405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601405.url(scheme.get, call_601405.host, call_601405.base,
                         call_601405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601405, url, valid)

proc call*(call_601406: Call_PostDownloadDBLogFilePortion_601389;
          DBInstanceIdentifier: string; LogFileName: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-02-12"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_601407 = newJObject()
  var formData_601408 = newJObject()
  add(formData_601408, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_601408, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601408, "Marker", newJString(Marker))
  add(query_601407, "Action", newJString(Action))
  add(formData_601408, "LogFileName", newJString(LogFileName))
  add(query_601407, "Version", newJString(Version))
  result = call_601406.call(nil, query_601407, nil, formData_601408, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_601389(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_601390, base: "/",
    url: url_PostDownloadDBLogFilePortion_601391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_601370 = ref object of OpenApiRestCall_599352
proc url_GetDownloadDBLogFilePortion_601372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_601371(path: JsonNode; query: JsonNode;
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
  var valid_601373 = query.getOrDefault("NumberOfLines")
  valid_601373 = validateParameter(valid_601373, JInt, required = false, default = nil)
  if valid_601373 != nil:
    section.add "NumberOfLines", valid_601373
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_601374 = query.getOrDefault("LogFileName")
  valid_601374 = validateParameter(valid_601374, JString, required = true,
                                 default = nil)
  if valid_601374 != nil:
    section.add "LogFileName", valid_601374
  var valid_601375 = query.getOrDefault("Action")
  valid_601375 = validateParameter(valid_601375, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_601375 != nil:
    section.add "Action", valid_601375
  var valid_601376 = query.getOrDefault("Marker")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "Marker", valid_601376
  var valid_601377 = query.getOrDefault("Version")
  valid_601377 = validateParameter(valid_601377, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601377 != nil:
    section.add "Version", valid_601377
  var valid_601378 = query.getOrDefault("DBInstanceIdentifier")
  valid_601378 = validateParameter(valid_601378, JString, required = true,
                                 default = nil)
  if valid_601378 != nil:
    section.add "DBInstanceIdentifier", valid_601378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601379 = header.getOrDefault("X-Amz-Date")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Date", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Security-Token")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Security-Token", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Content-Sha256", valid_601381
  var valid_601382 = header.getOrDefault("X-Amz-Algorithm")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Algorithm", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Signature")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Signature", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-SignedHeaders", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Credential")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Credential", valid_601385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601386: Call_GetDownloadDBLogFilePortion_601370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601386.validator(path, query, header, formData, body)
  let scheme = call_601386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601386.url(scheme.get, call_601386.host, call_601386.base,
                         call_601386.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601386, url, valid)

proc call*(call_601387: Call_GetDownloadDBLogFilePortion_601370;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Action: string = "DownloadDBLogFilePortion"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   LogFileName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601388 = newJObject()
  add(query_601388, "NumberOfLines", newJInt(NumberOfLines))
  add(query_601388, "LogFileName", newJString(LogFileName))
  add(query_601388, "Action", newJString(Action))
  add(query_601388, "Marker", newJString(Marker))
  add(query_601388, "Version", newJString(Version))
  add(query_601388, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601387.call(nil, query_601388, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_601370(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_601371, base: "/",
    url: url_GetDownloadDBLogFilePortion_601372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_601425 = ref object of OpenApiRestCall_599352
proc url_PostListTagsForResource_601427(protocol: Scheme; host: string; base: string;
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

proc validate_PostListTagsForResource_601426(path: JsonNode; query: JsonNode;
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
  var valid_601428 = query.getOrDefault("Action")
  valid_601428 = validateParameter(valid_601428, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601428 != nil:
    section.add "Action", valid_601428
  var valid_601429 = query.getOrDefault("Version")
  valid_601429 = validateParameter(valid_601429, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601429 != nil:
    section.add "Version", valid_601429
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601430 = header.getOrDefault("X-Amz-Date")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Date", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Security-Token")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Security-Token", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Content-Sha256", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Algorithm")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Algorithm", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Signature")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Signature", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-SignedHeaders", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-Credential")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Credential", valid_601436
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_601437 = formData.getOrDefault("ResourceName")
  valid_601437 = validateParameter(valid_601437, JString, required = true,
                                 default = nil)
  if valid_601437 != nil:
    section.add "ResourceName", valid_601437
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601438: Call_PostListTagsForResource_601425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601438.validator(path, query, header, formData, body)
  let scheme = call_601438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601438.url(scheme.get, call_601438.host, call_601438.base,
                         call_601438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601438, url, valid)

proc call*(call_601439: Call_PostListTagsForResource_601425; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601440 = newJObject()
  var formData_601441 = newJObject()
  add(query_601440, "Action", newJString(Action))
  add(formData_601441, "ResourceName", newJString(ResourceName))
  add(query_601440, "Version", newJString(Version))
  result = call_601439.call(nil, query_601440, nil, formData_601441, nil)

var postListTagsForResource* = Call_PostListTagsForResource_601425(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_601426, base: "/",
    url: url_PostListTagsForResource_601427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_601409 = ref object of OpenApiRestCall_599352
proc url_GetListTagsForResource_601411(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_601410(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601412 = query.getOrDefault("ResourceName")
  valid_601412 = validateParameter(valid_601412, JString, required = true,
                                 default = nil)
  if valid_601412 != nil:
    section.add "ResourceName", valid_601412
  var valid_601413 = query.getOrDefault("Action")
  valid_601413 = validateParameter(valid_601413, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_601413 != nil:
    section.add "Action", valid_601413
  var valid_601414 = query.getOrDefault("Version")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601414 != nil:
    section.add "Version", valid_601414
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601415 = header.getOrDefault("X-Amz-Date")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Date", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Security-Token")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Security-Token", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Content-Sha256", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Algorithm")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Algorithm", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Signature")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Signature", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-SignedHeaders", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Credential")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Credential", valid_601421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601422: Call_GetListTagsForResource_601409; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601422.validator(path, query, header, formData, body)
  let scheme = call_601422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601422.url(scheme.get, call_601422.host, call_601422.base,
                         call_601422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601422, url, valid)

proc call*(call_601423: Call_GetListTagsForResource_601409; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601424 = newJObject()
  add(query_601424, "ResourceName", newJString(ResourceName))
  add(query_601424, "Action", newJString(Action))
  add(query_601424, "Version", newJString(Version))
  result = call_601423.call(nil, query_601424, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_601409(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_601410, base: "/",
    url: url_GetListTagsForResource_601411, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_601475 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBInstance_601477(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_601476(path: JsonNode; query: JsonNode;
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
  var valid_601478 = query.getOrDefault("Action")
  valid_601478 = validateParameter(valid_601478, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601478 != nil:
    section.add "Action", valid_601478
  var valid_601479 = query.getOrDefault("Version")
  valid_601479 = validateParameter(valid_601479, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601479 != nil:
    section.add "Version", valid_601479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601480 = header.getOrDefault("X-Amz-Date")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Date", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Security-Token")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Security-Token", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Content-Sha256", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Algorithm")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Algorithm", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Signature")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Signature", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-SignedHeaders", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Credential")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Credential", valid_601486
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
  var valid_601487 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "PreferredMaintenanceWindow", valid_601487
  var valid_601488 = formData.getOrDefault("DBSecurityGroups")
  valid_601488 = validateParameter(valid_601488, JArray, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "DBSecurityGroups", valid_601488
  var valid_601489 = formData.getOrDefault("ApplyImmediately")
  valid_601489 = validateParameter(valid_601489, JBool, required = false, default = nil)
  if valid_601489 != nil:
    section.add "ApplyImmediately", valid_601489
  var valid_601490 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601490 = validateParameter(valid_601490, JArray, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "VpcSecurityGroupIds", valid_601490
  var valid_601491 = formData.getOrDefault("Iops")
  valid_601491 = validateParameter(valid_601491, JInt, required = false, default = nil)
  if valid_601491 != nil:
    section.add "Iops", valid_601491
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601492 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601492 = validateParameter(valid_601492, JString, required = true,
                                 default = nil)
  if valid_601492 != nil:
    section.add "DBInstanceIdentifier", valid_601492
  var valid_601493 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601493 = validateParameter(valid_601493, JInt, required = false, default = nil)
  if valid_601493 != nil:
    section.add "BackupRetentionPeriod", valid_601493
  var valid_601494 = formData.getOrDefault("DBParameterGroupName")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "DBParameterGroupName", valid_601494
  var valid_601495 = formData.getOrDefault("OptionGroupName")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "OptionGroupName", valid_601495
  var valid_601496 = formData.getOrDefault("MasterUserPassword")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "MasterUserPassword", valid_601496
  var valid_601497 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "NewDBInstanceIdentifier", valid_601497
  var valid_601498 = formData.getOrDefault("MultiAZ")
  valid_601498 = validateParameter(valid_601498, JBool, required = false, default = nil)
  if valid_601498 != nil:
    section.add "MultiAZ", valid_601498
  var valid_601499 = formData.getOrDefault("AllocatedStorage")
  valid_601499 = validateParameter(valid_601499, JInt, required = false, default = nil)
  if valid_601499 != nil:
    section.add "AllocatedStorage", valid_601499
  var valid_601500 = formData.getOrDefault("DBInstanceClass")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "DBInstanceClass", valid_601500
  var valid_601501 = formData.getOrDefault("PreferredBackupWindow")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "PreferredBackupWindow", valid_601501
  var valid_601502 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601502 = validateParameter(valid_601502, JBool, required = false, default = nil)
  if valid_601502 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601502
  var valid_601503 = formData.getOrDefault("EngineVersion")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "EngineVersion", valid_601503
  var valid_601504 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_601504 = validateParameter(valid_601504, JBool, required = false, default = nil)
  if valid_601504 != nil:
    section.add "AllowMajorVersionUpgrade", valid_601504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601505: Call_PostModifyDBInstance_601475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601505.validator(path, query, header, formData, body)
  let scheme = call_601505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601505.url(scheme.get, call_601505.host, call_601505.base,
                         call_601505.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601505, url, valid)

proc call*(call_601506: Call_PostModifyDBInstance_601475;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-02-12"; AllowMajorVersionUpgrade: bool = false): Recallable =
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
  var query_601507 = newJObject()
  var formData_601508 = newJObject()
  add(formData_601508, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_601508.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601508, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_601508.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601508, "Iops", newJInt(Iops))
  add(formData_601508, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601508, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601508, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601508, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601508, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601508, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_601508, "MultiAZ", newJBool(MultiAZ))
  add(query_601507, "Action", newJString(Action))
  add(formData_601508, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601508, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601508, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601508, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601508, "EngineVersion", newJString(EngineVersion))
  add(query_601507, "Version", newJString(Version))
  add(formData_601508, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_601506.call(nil, query_601507, nil, formData_601508, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_601475(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_601476, base: "/",
    url: url_PostModifyDBInstance_601477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_601442 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBInstance_601444(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_601443(path: JsonNode; query: JsonNode;
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
  var valid_601445 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "PreferredMaintenanceWindow", valid_601445
  var valid_601446 = query.getOrDefault("AllocatedStorage")
  valid_601446 = validateParameter(valid_601446, JInt, required = false, default = nil)
  if valid_601446 != nil:
    section.add "AllocatedStorage", valid_601446
  var valid_601447 = query.getOrDefault("OptionGroupName")
  valid_601447 = validateParameter(valid_601447, JString, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "OptionGroupName", valid_601447
  var valid_601448 = query.getOrDefault("DBSecurityGroups")
  valid_601448 = validateParameter(valid_601448, JArray, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "DBSecurityGroups", valid_601448
  var valid_601449 = query.getOrDefault("MasterUserPassword")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "MasterUserPassword", valid_601449
  var valid_601450 = query.getOrDefault("Iops")
  valid_601450 = validateParameter(valid_601450, JInt, required = false, default = nil)
  if valid_601450 != nil:
    section.add "Iops", valid_601450
  var valid_601451 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601451 = validateParameter(valid_601451, JArray, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "VpcSecurityGroupIds", valid_601451
  var valid_601452 = query.getOrDefault("MultiAZ")
  valid_601452 = validateParameter(valid_601452, JBool, required = false, default = nil)
  if valid_601452 != nil:
    section.add "MultiAZ", valid_601452
  var valid_601453 = query.getOrDefault("BackupRetentionPeriod")
  valid_601453 = validateParameter(valid_601453, JInt, required = false, default = nil)
  if valid_601453 != nil:
    section.add "BackupRetentionPeriod", valid_601453
  var valid_601454 = query.getOrDefault("DBParameterGroupName")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "DBParameterGroupName", valid_601454
  var valid_601455 = query.getOrDefault("DBInstanceClass")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "DBInstanceClass", valid_601455
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601456 = query.getOrDefault("Action")
  valid_601456 = validateParameter(valid_601456, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_601456 != nil:
    section.add "Action", valid_601456
  var valid_601457 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_601457 = validateParameter(valid_601457, JBool, required = false, default = nil)
  if valid_601457 != nil:
    section.add "AllowMajorVersionUpgrade", valid_601457
  var valid_601458 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "NewDBInstanceIdentifier", valid_601458
  var valid_601459 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601459 = validateParameter(valid_601459, JBool, required = false, default = nil)
  if valid_601459 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601459
  var valid_601460 = query.getOrDefault("EngineVersion")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "EngineVersion", valid_601460
  var valid_601461 = query.getOrDefault("PreferredBackupWindow")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "PreferredBackupWindow", valid_601461
  var valid_601462 = query.getOrDefault("Version")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601462 != nil:
    section.add "Version", valid_601462
  var valid_601463 = query.getOrDefault("DBInstanceIdentifier")
  valid_601463 = validateParameter(valid_601463, JString, required = true,
                                 default = nil)
  if valid_601463 != nil:
    section.add "DBInstanceIdentifier", valid_601463
  var valid_601464 = query.getOrDefault("ApplyImmediately")
  valid_601464 = validateParameter(valid_601464, JBool, required = false, default = nil)
  if valid_601464 != nil:
    section.add "ApplyImmediately", valid_601464
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601465 = header.getOrDefault("X-Amz-Date")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Date", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Security-Token")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Security-Token", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Content-Sha256", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Algorithm")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Algorithm", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Signature")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Signature", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-SignedHeaders", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Credential")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Credential", valid_601471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601472: Call_GetModifyDBInstance_601442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601472.validator(path, query, header, formData, body)
  let scheme = call_601472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601472.url(scheme.get, call_601472.host, call_601472.base,
                         call_601472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601472, url, valid)

proc call*(call_601473: Call_GetModifyDBInstance_601442;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; MasterUserPassword: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2013-02-12";
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
  var query_601474 = newJObject()
  add(query_601474, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601474, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601474, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601474.add "DBSecurityGroups", DBSecurityGroups
  add(query_601474, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601474, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601474.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601474, "MultiAZ", newJBool(MultiAZ))
  add(query_601474, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601474, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601474, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601474, "Action", newJString(Action))
  add(query_601474, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_601474, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_601474, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601474, "EngineVersion", newJString(EngineVersion))
  add(query_601474, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601474, "Version", newJString(Version))
  add(query_601474, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601474, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_601473.call(nil, query_601474, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_601442(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_601443, base: "/",
    url: url_GetModifyDBInstance_601444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_601526 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBParameterGroup_601528(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_601527(path: JsonNode; query: JsonNode;
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
  var valid_601529 = query.getOrDefault("Action")
  valid_601529 = validateParameter(valid_601529, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_601529 != nil:
    section.add "Action", valid_601529
  var valid_601530 = query.getOrDefault("Version")
  valid_601530 = validateParameter(valid_601530, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601530 != nil:
    section.add "Version", valid_601530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601531 = header.getOrDefault("X-Amz-Date")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Date", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Security-Token")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Security-Token", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Content-Sha256", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Algorithm")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Algorithm", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-Signature")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Signature", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-SignedHeaders", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Credential")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Credential", valid_601537
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601538 = formData.getOrDefault("DBParameterGroupName")
  valid_601538 = validateParameter(valid_601538, JString, required = true,
                                 default = nil)
  if valid_601538 != nil:
    section.add "DBParameterGroupName", valid_601538
  var valid_601539 = formData.getOrDefault("Parameters")
  valid_601539 = validateParameter(valid_601539, JArray, required = true, default = nil)
  if valid_601539 != nil:
    section.add "Parameters", valid_601539
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601540: Call_PostModifyDBParameterGroup_601526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601540.validator(path, query, header, formData, body)
  let scheme = call_601540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601540.url(scheme.get, call_601540.host, call_601540.base,
                         call_601540.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601540, url, valid)

proc call*(call_601541: Call_PostModifyDBParameterGroup_601526;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601542 = newJObject()
  var formData_601543 = newJObject()
  add(formData_601543, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_601543.add "Parameters", Parameters
  add(query_601542, "Action", newJString(Action))
  add(query_601542, "Version", newJString(Version))
  result = call_601541.call(nil, query_601542, nil, formData_601543, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_601526(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_601527, base: "/",
    url: url_PostModifyDBParameterGroup_601528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_601509 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBParameterGroup_601511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_601510(path: JsonNode; query: JsonNode;
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
  var valid_601512 = query.getOrDefault("DBParameterGroupName")
  valid_601512 = validateParameter(valid_601512, JString, required = true,
                                 default = nil)
  if valid_601512 != nil:
    section.add "DBParameterGroupName", valid_601512
  var valid_601513 = query.getOrDefault("Parameters")
  valid_601513 = validateParameter(valid_601513, JArray, required = true, default = nil)
  if valid_601513 != nil:
    section.add "Parameters", valid_601513
  var valid_601514 = query.getOrDefault("Action")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_601514 != nil:
    section.add "Action", valid_601514
  var valid_601515 = query.getOrDefault("Version")
  valid_601515 = validateParameter(valid_601515, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601515 != nil:
    section.add "Version", valid_601515
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601516 = header.getOrDefault("X-Amz-Date")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Date", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Security-Token")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Security-Token", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Content-Sha256", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Algorithm")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Algorithm", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Signature")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Signature", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-SignedHeaders", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Credential")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Credential", valid_601522
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601523: Call_GetModifyDBParameterGroup_601509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601523.validator(path, query, header, formData, body)
  let scheme = call_601523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601523.url(scheme.get, call_601523.host, call_601523.base,
                         call_601523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601523, url, valid)

proc call*(call_601524: Call_GetModifyDBParameterGroup_601509;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601525 = newJObject()
  add(query_601525, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_601525.add "Parameters", Parameters
  add(query_601525, "Action", newJString(Action))
  add(query_601525, "Version", newJString(Version))
  result = call_601524.call(nil, query_601525, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_601509(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_601510, base: "/",
    url: url_GetModifyDBParameterGroup_601511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_601562 = ref object of OpenApiRestCall_599352
proc url_PostModifyDBSubnetGroup_601564(protocol: Scheme; host: string; base: string;
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

proc validate_PostModifyDBSubnetGroup_601563(path: JsonNode; query: JsonNode;
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
  var valid_601565 = query.getOrDefault("Action")
  valid_601565 = validateParameter(valid_601565, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601565 != nil:
    section.add "Action", valid_601565
  var valid_601566 = query.getOrDefault("Version")
  valid_601566 = validateParameter(valid_601566, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601566 != nil:
    section.add "Version", valid_601566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601567 = header.getOrDefault("X-Amz-Date")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Date", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Security-Token")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Security-Token", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Content-Sha256", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Algorithm")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Algorithm", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Signature")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Signature", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-SignedHeaders", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Credential")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Credential", valid_601573
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601574 = formData.getOrDefault("DBSubnetGroupName")
  valid_601574 = validateParameter(valid_601574, JString, required = true,
                                 default = nil)
  if valid_601574 != nil:
    section.add "DBSubnetGroupName", valid_601574
  var valid_601575 = formData.getOrDefault("SubnetIds")
  valid_601575 = validateParameter(valid_601575, JArray, required = true, default = nil)
  if valid_601575 != nil:
    section.add "SubnetIds", valid_601575
  var valid_601576 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "DBSubnetGroupDescription", valid_601576
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601577: Call_PostModifyDBSubnetGroup_601562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601577.validator(path, query, header, formData, body)
  let scheme = call_601577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601577.url(scheme.get, call_601577.host, call_601577.base,
                         call_601577.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601577, url, valid)

proc call*(call_601578: Call_PostModifyDBSubnetGroup_601562;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_601579 = newJObject()
  var formData_601580 = newJObject()
  add(formData_601580, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601580.add "SubnetIds", SubnetIds
  add(query_601579, "Action", newJString(Action))
  add(formData_601580, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601579, "Version", newJString(Version))
  result = call_601578.call(nil, query_601579, nil, formData_601580, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_601562(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_601563, base: "/",
    url: url_PostModifyDBSubnetGroup_601564, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_601544 = ref object of OpenApiRestCall_599352
proc url_GetModifyDBSubnetGroup_601546(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_601545(path: JsonNode; query: JsonNode;
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
  var valid_601547 = query.getOrDefault("Action")
  valid_601547 = validateParameter(valid_601547, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_601547 != nil:
    section.add "Action", valid_601547
  var valid_601548 = query.getOrDefault("DBSubnetGroupName")
  valid_601548 = validateParameter(valid_601548, JString, required = true,
                                 default = nil)
  if valid_601548 != nil:
    section.add "DBSubnetGroupName", valid_601548
  var valid_601549 = query.getOrDefault("SubnetIds")
  valid_601549 = validateParameter(valid_601549, JArray, required = true, default = nil)
  if valid_601549 != nil:
    section.add "SubnetIds", valid_601549
  var valid_601550 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "DBSubnetGroupDescription", valid_601550
  var valid_601551 = query.getOrDefault("Version")
  valid_601551 = validateParameter(valid_601551, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601551 != nil:
    section.add "Version", valid_601551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601552 = header.getOrDefault("X-Amz-Date")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Date", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Security-Token")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Security-Token", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Content-Sha256", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Algorithm")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Algorithm", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Signature")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Signature", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-SignedHeaders", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Credential")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Credential", valid_601558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601559: Call_GetModifyDBSubnetGroup_601544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601559.validator(path, query, header, formData, body)
  let scheme = call_601559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601559.url(scheme.get, call_601559.host, call_601559.base,
                         call_601559.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601559, url, valid)

proc call*(call_601560: Call_GetModifyDBSubnetGroup_601544;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_601561 = newJObject()
  add(query_601561, "Action", newJString(Action))
  add(query_601561, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601561.add "SubnetIds", SubnetIds
  add(query_601561, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601561, "Version", newJString(Version))
  result = call_601560.call(nil, query_601561, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_601544(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_601545, base: "/",
    url: url_GetModifyDBSubnetGroup_601546, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_601601 = ref object of OpenApiRestCall_599352
proc url_PostModifyEventSubscription_601603(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_601602(path: JsonNode; query: JsonNode;
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
  var valid_601604 = query.getOrDefault("Action")
  valid_601604 = validateParameter(valid_601604, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_601604 != nil:
    section.add "Action", valid_601604
  var valid_601605 = query.getOrDefault("Version")
  valid_601605 = validateParameter(valid_601605, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601605 != nil:
    section.add "Version", valid_601605
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601606 = header.getOrDefault("X-Amz-Date")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Date", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Security-Token")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Security-Token", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Content-Sha256", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Algorithm")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Algorithm", valid_601609
  var valid_601610 = header.getOrDefault("X-Amz-Signature")
  valid_601610 = validateParameter(valid_601610, JString, required = false,
                                 default = nil)
  if valid_601610 != nil:
    section.add "X-Amz-Signature", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-SignedHeaders", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Credential")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Credential", valid_601612
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_601613 = formData.getOrDefault("Enabled")
  valid_601613 = validateParameter(valid_601613, JBool, required = false, default = nil)
  if valid_601613 != nil:
    section.add "Enabled", valid_601613
  var valid_601614 = formData.getOrDefault("EventCategories")
  valid_601614 = validateParameter(valid_601614, JArray, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "EventCategories", valid_601614
  var valid_601615 = formData.getOrDefault("SnsTopicArn")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "SnsTopicArn", valid_601615
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601616 = formData.getOrDefault("SubscriptionName")
  valid_601616 = validateParameter(valid_601616, JString, required = true,
                                 default = nil)
  if valid_601616 != nil:
    section.add "SubscriptionName", valid_601616
  var valid_601617 = formData.getOrDefault("SourceType")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "SourceType", valid_601617
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601618: Call_PostModifyEventSubscription_601601; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601618.validator(path, query, header, formData, body)
  let scheme = call_601618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601618.url(scheme.get, call_601618.host, call_601618.base,
                         call_601618.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601618, url, valid)

proc call*(call_601619: Call_PostModifyEventSubscription_601601;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_601620 = newJObject()
  var formData_601621 = newJObject()
  add(formData_601621, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601621.add "EventCategories", EventCategories
  add(formData_601621, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_601621, "SubscriptionName", newJString(SubscriptionName))
  add(query_601620, "Action", newJString(Action))
  add(query_601620, "Version", newJString(Version))
  add(formData_601621, "SourceType", newJString(SourceType))
  result = call_601619.call(nil, query_601620, nil, formData_601621, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_601601(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_601602, base: "/",
    url: url_PostModifyEventSubscription_601603,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_601581 = ref object of OpenApiRestCall_599352
proc url_GetModifyEventSubscription_601583(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_601582(path: JsonNode; query: JsonNode;
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
  var valid_601584 = query.getOrDefault("SourceType")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "SourceType", valid_601584
  var valid_601585 = query.getOrDefault("Enabled")
  valid_601585 = validateParameter(valid_601585, JBool, required = false, default = nil)
  if valid_601585 != nil:
    section.add "Enabled", valid_601585
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601586 = query.getOrDefault("Action")
  valid_601586 = validateParameter(valid_601586, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_601586 != nil:
    section.add "Action", valid_601586
  var valid_601587 = query.getOrDefault("SnsTopicArn")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "SnsTopicArn", valid_601587
  var valid_601588 = query.getOrDefault("EventCategories")
  valid_601588 = validateParameter(valid_601588, JArray, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "EventCategories", valid_601588
  var valid_601589 = query.getOrDefault("SubscriptionName")
  valid_601589 = validateParameter(valid_601589, JString, required = true,
                                 default = nil)
  if valid_601589 != nil:
    section.add "SubscriptionName", valid_601589
  var valid_601590 = query.getOrDefault("Version")
  valid_601590 = validateParameter(valid_601590, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601590 != nil:
    section.add "Version", valid_601590
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601591 = header.getOrDefault("X-Amz-Date")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Date", valid_601591
  var valid_601592 = header.getOrDefault("X-Amz-Security-Token")
  valid_601592 = validateParameter(valid_601592, JString, required = false,
                                 default = nil)
  if valid_601592 != nil:
    section.add "X-Amz-Security-Token", valid_601592
  var valid_601593 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Content-Sha256", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Algorithm")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Algorithm", valid_601594
  var valid_601595 = header.getOrDefault("X-Amz-Signature")
  valid_601595 = validateParameter(valid_601595, JString, required = false,
                                 default = nil)
  if valid_601595 != nil:
    section.add "X-Amz-Signature", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-SignedHeaders", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Credential")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Credential", valid_601597
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601598: Call_GetModifyEventSubscription_601581; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601598.validator(path, query, header, formData, body)
  let scheme = call_601598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601598.url(scheme.get, call_601598.host, call_601598.base,
                         call_601598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601598, url, valid)

proc call*(call_601599: Call_GetModifyEventSubscription_601581;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2013-02-12"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601600 = newJObject()
  add(query_601600, "SourceType", newJString(SourceType))
  add(query_601600, "Enabled", newJBool(Enabled))
  add(query_601600, "Action", newJString(Action))
  add(query_601600, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601600.add "EventCategories", EventCategories
  add(query_601600, "SubscriptionName", newJString(SubscriptionName))
  add(query_601600, "Version", newJString(Version))
  result = call_601599.call(nil, query_601600, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_601581(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_601582, base: "/",
    url: url_GetModifyEventSubscription_601583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_601641 = ref object of OpenApiRestCall_599352
proc url_PostModifyOptionGroup_601643(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_601642(path: JsonNode; query: JsonNode;
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
  var valid_601644 = query.getOrDefault("Action")
  valid_601644 = validateParameter(valid_601644, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_601644 != nil:
    section.add "Action", valid_601644
  var valid_601645 = query.getOrDefault("Version")
  valid_601645 = validateParameter(valid_601645, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601645 != nil:
    section.add "Version", valid_601645
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601646 = header.getOrDefault("X-Amz-Date")
  valid_601646 = validateParameter(valid_601646, JString, required = false,
                                 default = nil)
  if valid_601646 != nil:
    section.add "X-Amz-Date", valid_601646
  var valid_601647 = header.getOrDefault("X-Amz-Security-Token")
  valid_601647 = validateParameter(valid_601647, JString, required = false,
                                 default = nil)
  if valid_601647 != nil:
    section.add "X-Amz-Security-Token", valid_601647
  var valid_601648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601648 = validateParameter(valid_601648, JString, required = false,
                                 default = nil)
  if valid_601648 != nil:
    section.add "X-Amz-Content-Sha256", valid_601648
  var valid_601649 = header.getOrDefault("X-Amz-Algorithm")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Algorithm", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Signature")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Signature", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-SignedHeaders", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Credential")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Credential", valid_601652
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_601653 = formData.getOrDefault("OptionsToRemove")
  valid_601653 = validateParameter(valid_601653, JArray, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "OptionsToRemove", valid_601653
  var valid_601654 = formData.getOrDefault("ApplyImmediately")
  valid_601654 = validateParameter(valid_601654, JBool, required = false, default = nil)
  if valid_601654 != nil:
    section.add "ApplyImmediately", valid_601654
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601655 = formData.getOrDefault("OptionGroupName")
  valid_601655 = validateParameter(valid_601655, JString, required = true,
                                 default = nil)
  if valid_601655 != nil:
    section.add "OptionGroupName", valid_601655
  var valid_601656 = formData.getOrDefault("OptionsToInclude")
  valid_601656 = validateParameter(valid_601656, JArray, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "OptionsToInclude", valid_601656
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601657: Call_PostModifyOptionGroup_601641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601657.validator(path, query, header, formData, body)
  let scheme = call_601657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601657.url(scheme.get, call_601657.host, call_601657.base,
                         call_601657.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601657, url, valid)

proc call*(call_601658: Call_PostModifyOptionGroup_601641; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601659 = newJObject()
  var formData_601660 = newJObject()
  if OptionsToRemove != nil:
    formData_601660.add "OptionsToRemove", OptionsToRemove
  add(formData_601660, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_601660, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_601660.add "OptionsToInclude", OptionsToInclude
  add(query_601659, "Action", newJString(Action))
  add(query_601659, "Version", newJString(Version))
  result = call_601658.call(nil, query_601659, nil, formData_601660, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_601641(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_601642, base: "/",
    url: url_PostModifyOptionGroup_601643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_601622 = ref object of OpenApiRestCall_599352
proc url_GetModifyOptionGroup_601624(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_601623(path: JsonNode; query: JsonNode;
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
  var valid_601625 = query.getOrDefault("OptionGroupName")
  valid_601625 = validateParameter(valid_601625, JString, required = true,
                                 default = nil)
  if valid_601625 != nil:
    section.add "OptionGroupName", valid_601625
  var valid_601626 = query.getOrDefault("OptionsToRemove")
  valid_601626 = validateParameter(valid_601626, JArray, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "OptionsToRemove", valid_601626
  var valid_601627 = query.getOrDefault("Action")
  valid_601627 = validateParameter(valid_601627, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_601627 != nil:
    section.add "Action", valid_601627
  var valid_601628 = query.getOrDefault("Version")
  valid_601628 = validateParameter(valid_601628, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601628 != nil:
    section.add "Version", valid_601628
  var valid_601629 = query.getOrDefault("ApplyImmediately")
  valid_601629 = validateParameter(valid_601629, JBool, required = false, default = nil)
  if valid_601629 != nil:
    section.add "ApplyImmediately", valid_601629
  var valid_601630 = query.getOrDefault("OptionsToInclude")
  valid_601630 = validateParameter(valid_601630, JArray, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "OptionsToInclude", valid_601630
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601631 = header.getOrDefault("X-Amz-Date")
  valid_601631 = validateParameter(valid_601631, JString, required = false,
                                 default = nil)
  if valid_601631 != nil:
    section.add "X-Amz-Date", valid_601631
  var valid_601632 = header.getOrDefault("X-Amz-Security-Token")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Security-Token", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Content-Sha256", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Algorithm")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Algorithm", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Signature")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Signature", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-SignedHeaders", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Credential")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Credential", valid_601637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601638: Call_GetModifyOptionGroup_601622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601638.validator(path, query, header, formData, body)
  let scheme = call_601638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601638.url(scheme.get, call_601638.host, call_601638.base,
                         call_601638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601638, url, valid)

proc call*(call_601639: Call_GetModifyOptionGroup_601622; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-02-12"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_601640 = newJObject()
  add(query_601640, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_601640.add "OptionsToRemove", OptionsToRemove
  add(query_601640, "Action", newJString(Action))
  add(query_601640, "Version", newJString(Version))
  add(query_601640, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_601640.add "OptionsToInclude", OptionsToInclude
  result = call_601639.call(nil, query_601640, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_601622(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_601623, base: "/",
    url: url_GetModifyOptionGroup_601624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_601679 = ref object of OpenApiRestCall_599352
proc url_PostPromoteReadReplica_601681(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_601680(path: JsonNode; query: JsonNode;
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
  var valid_601682 = query.getOrDefault("Action")
  valid_601682 = validateParameter(valid_601682, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_601682 != nil:
    section.add "Action", valid_601682
  var valid_601683 = query.getOrDefault("Version")
  valid_601683 = validateParameter(valid_601683, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601683 != nil:
    section.add "Version", valid_601683
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601684 = header.getOrDefault("X-Amz-Date")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Date", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Security-Token")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Security-Token", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Content-Sha256", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-Algorithm")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Algorithm", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Signature")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Signature", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-SignedHeaders", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Credential")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Credential", valid_601690
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601691 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601691 = validateParameter(valid_601691, JString, required = true,
                                 default = nil)
  if valid_601691 != nil:
    section.add "DBInstanceIdentifier", valid_601691
  var valid_601692 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601692 = validateParameter(valid_601692, JInt, required = false, default = nil)
  if valid_601692 != nil:
    section.add "BackupRetentionPeriod", valid_601692
  var valid_601693 = formData.getOrDefault("PreferredBackupWindow")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "PreferredBackupWindow", valid_601693
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601694: Call_PostPromoteReadReplica_601679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601694.validator(path, query, header, formData, body)
  let scheme = call_601694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601694.url(scheme.get, call_601694.host, call_601694.base,
                         call_601694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601694, url, valid)

proc call*(call_601695: Call_PostPromoteReadReplica_601679;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_601696 = newJObject()
  var formData_601697 = newJObject()
  add(formData_601697, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601697, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601696, "Action", newJString(Action))
  add(formData_601697, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601696, "Version", newJString(Version))
  result = call_601695.call(nil, query_601696, nil, formData_601697, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_601679(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_601680, base: "/",
    url: url_PostPromoteReadReplica_601681, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_601661 = ref object of OpenApiRestCall_599352
proc url_GetPromoteReadReplica_601663(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_601662(path: JsonNode; query: JsonNode;
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
  var valid_601664 = query.getOrDefault("BackupRetentionPeriod")
  valid_601664 = validateParameter(valid_601664, JInt, required = false, default = nil)
  if valid_601664 != nil:
    section.add "BackupRetentionPeriod", valid_601664
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601665 = query.getOrDefault("Action")
  valid_601665 = validateParameter(valid_601665, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_601665 != nil:
    section.add "Action", valid_601665
  var valid_601666 = query.getOrDefault("PreferredBackupWindow")
  valid_601666 = validateParameter(valid_601666, JString, required = false,
                                 default = nil)
  if valid_601666 != nil:
    section.add "PreferredBackupWindow", valid_601666
  var valid_601667 = query.getOrDefault("Version")
  valid_601667 = validateParameter(valid_601667, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601667 != nil:
    section.add "Version", valid_601667
  var valid_601668 = query.getOrDefault("DBInstanceIdentifier")
  valid_601668 = validateParameter(valid_601668, JString, required = true,
                                 default = nil)
  if valid_601668 != nil:
    section.add "DBInstanceIdentifier", valid_601668
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601669 = header.getOrDefault("X-Amz-Date")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Date", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Security-Token")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Security-Token", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Content-Sha256", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Algorithm")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Algorithm", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Signature")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Signature", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-SignedHeaders", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-Credential")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Credential", valid_601675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601676: Call_GetPromoteReadReplica_601661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601676.validator(path, query, header, formData, body)
  let scheme = call_601676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601676.url(scheme.get, call_601676.host, call_601676.base,
                         call_601676.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601676, url, valid)

proc call*(call_601677: Call_GetPromoteReadReplica_601661;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601678 = newJObject()
  add(query_601678, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601678, "Action", newJString(Action))
  add(query_601678, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601678, "Version", newJString(Version))
  add(query_601678, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601677.call(nil, query_601678, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_601661(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_601662, base: "/",
    url: url_GetPromoteReadReplica_601663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_601716 = ref object of OpenApiRestCall_599352
proc url_PostPurchaseReservedDBInstancesOffering_601718(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_601717(path: JsonNode;
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
  var valid_601719 = query.getOrDefault("Action")
  valid_601719 = validateParameter(valid_601719, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_601719 != nil:
    section.add "Action", valid_601719
  var valid_601720 = query.getOrDefault("Version")
  valid_601720 = validateParameter(valid_601720, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601720 != nil:
    section.add "Version", valid_601720
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601721 = header.getOrDefault("X-Amz-Date")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Date", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-Security-Token")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Security-Token", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Content-Sha256", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Algorithm")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Algorithm", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Signature")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Signature", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-SignedHeaders", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-Credential")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-Credential", valid_601727
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_601728 = formData.getOrDefault("ReservedDBInstanceId")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "ReservedDBInstanceId", valid_601728
  var valid_601729 = formData.getOrDefault("DBInstanceCount")
  valid_601729 = validateParameter(valid_601729, JInt, required = false, default = nil)
  if valid_601729 != nil:
    section.add "DBInstanceCount", valid_601729
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_601730 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601730 = validateParameter(valid_601730, JString, required = true,
                                 default = nil)
  if valid_601730 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601730
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601731: Call_PostPurchaseReservedDBInstancesOffering_601716;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601731.validator(path, query, header, formData, body)
  let scheme = call_601731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601731.url(scheme.get, call_601731.host, call_601731.base,
                         call_601731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601731, url, valid)

proc call*(call_601732: Call_PostPurchaseReservedDBInstancesOffering_601716;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_601733 = newJObject()
  var formData_601734 = newJObject()
  add(formData_601734, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_601734, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_601733, "Action", newJString(Action))
  add(formData_601734, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601733, "Version", newJString(Version))
  result = call_601732.call(nil, query_601733, nil, formData_601734, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_601716(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_601717, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_601718,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_601698 = ref object of OpenApiRestCall_599352
proc url_GetPurchaseReservedDBInstancesOffering_601700(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_601699(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_601701 = query.getOrDefault("DBInstanceCount")
  valid_601701 = validateParameter(valid_601701, JInt, required = false, default = nil)
  if valid_601701 != nil:
    section.add "DBInstanceCount", valid_601701
  var valid_601702 = query.getOrDefault("ReservedDBInstanceId")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "ReservedDBInstanceId", valid_601702
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_601703 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_601703 = validateParameter(valid_601703, JString, required = true,
                                 default = nil)
  if valid_601703 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_601703
  var valid_601704 = query.getOrDefault("Action")
  valid_601704 = validateParameter(valid_601704, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_601704 != nil:
    section.add "Action", valid_601704
  var valid_601705 = query.getOrDefault("Version")
  valid_601705 = validateParameter(valid_601705, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601705 != nil:
    section.add "Version", valid_601705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601706 = header.getOrDefault("X-Amz-Date")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Date", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Security-Token")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Security-Token", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Content-Sha256", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-Algorithm")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-Algorithm", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Signature")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Signature", valid_601710
  var valid_601711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601711 = validateParameter(valid_601711, JString, required = false,
                                 default = nil)
  if valid_601711 != nil:
    section.add "X-Amz-SignedHeaders", valid_601711
  var valid_601712 = header.getOrDefault("X-Amz-Credential")
  valid_601712 = validateParameter(valid_601712, JString, required = false,
                                 default = nil)
  if valid_601712 != nil:
    section.add "X-Amz-Credential", valid_601712
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601713: Call_GetPurchaseReservedDBInstancesOffering_601698;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601713.validator(path, query, header, formData, body)
  let scheme = call_601713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601713.url(scheme.get, call_601713.host, call_601713.base,
                         call_601713.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601713, url, valid)

proc call*(call_601714: Call_GetPurchaseReservedDBInstancesOffering_601698;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-02-12"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601715 = newJObject()
  add(query_601715, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_601715, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_601715, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_601715, "Action", newJString(Action))
  add(query_601715, "Version", newJString(Version))
  result = call_601714.call(nil, query_601715, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_601698(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_601699, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_601700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_601752 = ref object of OpenApiRestCall_599352
proc url_PostRebootDBInstance_601754(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_601753(path: JsonNode; query: JsonNode;
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
  var valid_601755 = query.getOrDefault("Action")
  valid_601755 = validateParameter(valid_601755, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601755 != nil:
    section.add "Action", valid_601755
  var valid_601756 = query.getOrDefault("Version")
  valid_601756 = validateParameter(valid_601756, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601756 != nil:
    section.add "Version", valid_601756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601757 = header.getOrDefault("X-Amz-Date")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Date", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Security-Token")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Security-Token", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Content-Sha256", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Algorithm")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Algorithm", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Signature")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Signature", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-SignedHeaders", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Credential")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Credential", valid_601763
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601764 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601764 = validateParameter(valid_601764, JString, required = true,
                                 default = nil)
  if valid_601764 != nil:
    section.add "DBInstanceIdentifier", valid_601764
  var valid_601765 = formData.getOrDefault("ForceFailover")
  valid_601765 = validateParameter(valid_601765, JBool, required = false, default = nil)
  if valid_601765 != nil:
    section.add "ForceFailover", valid_601765
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601766: Call_PostRebootDBInstance_601752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601766.validator(path, query, header, formData, body)
  let scheme = call_601766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601766.url(scheme.get, call_601766.host, call_601766.base,
                         call_601766.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601766, url, valid)

proc call*(call_601767: Call_PostRebootDBInstance_601752;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_601768 = newJObject()
  var formData_601769 = newJObject()
  add(formData_601769, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601768, "Action", newJString(Action))
  add(formData_601769, "ForceFailover", newJBool(ForceFailover))
  add(query_601768, "Version", newJString(Version))
  result = call_601767.call(nil, query_601768, nil, formData_601769, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_601752(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_601753, base: "/",
    url: url_PostRebootDBInstance_601754, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_601735 = ref object of OpenApiRestCall_599352
proc url_GetRebootDBInstance_601737(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_601736(path: JsonNode; query: JsonNode;
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
  var valid_601738 = query.getOrDefault("Action")
  valid_601738 = validateParameter(valid_601738, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_601738 != nil:
    section.add "Action", valid_601738
  var valid_601739 = query.getOrDefault("ForceFailover")
  valid_601739 = validateParameter(valid_601739, JBool, required = false, default = nil)
  if valid_601739 != nil:
    section.add "ForceFailover", valid_601739
  var valid_601740 = query.getOrDefault("Version")
  valid_601740 = validateParameter(valid_601740, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601740 != nil:
    section.add "Version", valid_601740
  var valid_601741 = query.getOrDefault("DBInstanceIdentifier")
  valid_601741 = validateParameter(valid_601741, JString, required = true,
                                 default = nil)
  if valid_601741 != nil:
    section.add "DBInstanceIdentifier", valid_601741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601742 = header.getOrDefault("X-Amz-Date")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-Date", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Security-Token")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Security-Token", valid_601743
  var valid_601744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601744 = validateParameter(valid_601744, JString, required = false,
                                 default = nil)
  if valid_601744 != nil:
    section.add "X-Amz-Content-Sha256", valid_601744
  var valid_601745 = header.getOrDefault("X-Amz-Algorithm")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "X-Amz-Algorithm", valid_601745
  var valid_601746 = header.getOrDefault("X-Amz-Signature")
  valid_601746 = validateParameter(valid_601746, JString, required = false,
                                 default = nil)
  if valid_601746 != nil:
    section.add "X-Amz-Signature", valid_601746
  var valid_601747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601747 = validateParameter(valid_601747, JString, required = false,
                                 default = nil)
  if valid_601747 != nil:
    section.add "X-Amz-SignedHeaders", valid_601747
  var valid_601748 = header.getOrDefault("X-Amz-Credential")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "X-Amz-Credential", valid_601748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601749: Call_GetRebootDBInstance_601735; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601749.validator(path, query, header, formData, body)
  let scheme = call_601749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601749.url(scheme.get, call_601749.host, call_601749.base,
                         call_601749.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601749, url, valid)

proc call*(call_601750: Call_GetRebootDBInstance_601735;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601751 = newJObject()
  add(query_601751, "Action", newJString(Action))
  add(query_601751, "ForceFailover", newJBool(ForceFailover))
  add(query_601751, "Version", newJString(Version))
  add(query_601751, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601750.call(nil, query_601751, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_601735(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_601736, base: "/",
    url: url_GetRebootDBInstance_601737, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_601787 = ref object of OpenApiRestCall_599352
proc url_PostRemoveSourceIdentifierFromSubscription_601789(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_601788(path: JsonNode;
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
  var valid_601790 = query.getOrDefault("Action")
  valid_601790 = validateParameter(valid_601790, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_601790 != nil:
    section.add "Action", valid_601790
  var valid_601791 = query.getOrDefault("Version")
  valid_601791 = validateParameter(valid_601791, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601791 != nil:
    section.add "Version", valid_601791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601792 = header.getOrDefault("X-Amz-Date")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Date", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Security-Token")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Security-Token", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Content-Sha256", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-Algorithm")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Algorithm", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Signature")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Signature", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-SignedHeaders", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Credential")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Credential", valid_601798
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_601799 = formData.getOrDefault("SourceIdentifier")
  valid_601799 = validateParameter(valid_601799, JString, required = true,
                                 default = nil)
  if valid_601799 != nil:
    section.add "SourceIdentifier", valid_601799
  var valid_601800 = formData.getOrDefault("SubscriptionName")
  valid_601800 = validateParameter(valid_601800, JString, required = true,
                                 default = nil)
  if valid_601800 != nil:
    section.add "SubscriptionName", valid_601800
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601801: Call_PostRemoveSourceIdentifierFromSubscription_601787;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601801.validator(path, query, header, formData, body)
  let scheme = call_601801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601801.url(scheme.get, call_601801.host, call_601801.base,
                         call_601801.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601801, url, valid)

proc call*(call_601802: Call_PostRemoveSourceIdentifierFromSubscription_601787;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601803 = newJObject()
  var formData_601804 = newJObject()
  add(formData_601804, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_601804, "SubscriptionName", newJString(SubscriptionName))
  add(query_601803, "Action", newJString(Action))
  add(query_601803, "Version", newJString(Version))
  result = call_601802.call(nil, query_601803, nil, formData_601804, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_601787(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_601788,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_601789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_601770 = ref object of OpenApiRestCall_599352
proc url_GetRemoveSourceIdentifierFromSubscription_601772(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_601771(path: JsonNode;
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
  var valid_601773 = query.getOrDefault("Action")
  valid_601773 = validateParameter(valid_601773, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_601773 != nil:
    section.add "Action", valid_601773
  var valid_601774 = query.getOrDefault("SourceIdentifier")
  valid_601774 = validateParameter(valid_601774, JString, required = true,
                                 default = nil)
  if valid_601774 != nil:
    section.add "SourceIdentifier", valid_601774
  var valid_601775 = query.getOrDefault("SubscriptionName")
  valid_601775 = validateParameter(valid_601775, JString, required = true,
                                 default = nil)
  if valid_601775 != nil:
    section.add "SubscriptionName", valid_601775
  var valid_601776 = query.getOrDefault("Version")
  valid_601776 = validateParameter(valid_601776, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601776 != nil:
    section.add "Version", valid_601776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601777 = header.getOrDefault("X-Amz-Date")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Date", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Security-Token")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Security-Token", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Content-Sha256", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-Algorithm")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-Algorithm", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Signature")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Signature", valid_601781
  var valid_601782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601782 = validateParameter(valid_601782, JString, required = false,
                                 default = nil)
  if valid_601782 != nil:
    section.add "X-Amz-SignedHeaders", valid_601782
  var valid_601783 = header.getOrDefault("X-Amz-Credential")
  valid_601783 = validateParameter(valid_601783, JString, required = false,
                                 default = nil)
  if valid_601783 != nil:
    section.add "X-Amz-Credential", valid_601783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601784: Call_GetRemoveSourceIdentifierFromSubscription_601770;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601784.validator(path, query, header, formData, body)
  let scheme = call_601784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601784.url(scheme.get, call_601784.host, call_601784.base,
                         call_601784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601784, url, valid)

proc call*(call_601785: Call_GetRemoveSourceIdentifierFromSubscription_601770;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601786 = newJObject()
  add(query_601786, "Action", newJString(Action))
  add(query_601786, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_601786, "SubscriptionName", newJString(SubscriptionName))
  add(query_601786, "Version", newJString(Version))
  result = call_601785.call(nil, query_601786, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_601770(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_601771,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_601772,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_601822 = ref object of OpenApiRestCall_599352
proc url_PostRemoveTagsFromResource_601824(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_601823(path: JsonNode; query: JsonNode;
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
  var valid_601825 = query.getOrDefault("Action")
  valid_601825 = validateParameter(valid_601825, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601825 != nil:
    section.add "Action", valid_601825
  var valid_601826 = query.getOrDefault("Version")
  valid_601826 = validateParameter(valid_601826, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601826 != nil:
    section.add "Version", valid_601826
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601827 = header.getOrDefault("X-Amz-Date")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Date", valid_601827
  var valid_601828 = header.getOrDefault("X-Amz-Security-Token")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "X-Amz-Security-Token", valid_601828
  var valid_601829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "X-Amz-Content-Sha256", valid_601829
  var valid_601830 = header.getOrDefault("X-Amz-Algorithm")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "X-Amz-Algorithm", valid_601830
  var valid_601831 = header.getOrDefault("X-Amz-Signature")
  valid_601831 = validateParameter(valid_601831, JString, required = false,
                                 default = nil)
  if valid_601831 != nil:
    section.add "X-Amz-Signature", valid_601831
  var valid_601832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "X-Amz-SignedHeaders", valid_601832
  var valid_601833 = header.getOrDefault("X-Amz-Credential")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Credential", valid_601833
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_601834 = formData.getOrDefault("TagKeys")
  valid_601834 = validateParameter(valid_601834, JArray, required = true, default = nil)
  if valid_601834 != nil:
    section.add "TagKeys", valid_601834
  var valid_601835 = formData.getOrDefault("ResourceName")
  valid_601835 = validateParameter(valid_601835, JString, required = true,
                                 default = nil)
  if valid_601835 != nil:
    section.add "ResourceName", valid_601835
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601836: Call_PostRemoveTagsFromResource_601822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601836.validator(path, query, header, formData, body)
  let scheme = call_601836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601836.url(scheme.get, call_601836.host, call_601836.base,
                         call_601836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601836, url, valid)

proc call*(call_601837: Call_PostRemoveTagsFromResource_601822; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601838 = newJObject()
  var formData_601839 = newJObject()
  add(query_601838, "Action", newJString(Action))
  if TagKeys != nil:
    formData_601839.add "TagKeys", TagKeys
  add(formData_601839, "ResourceName", newJString(ResourceName))
  add(query_601838, "Version", newJString(Version))
  result = call_601837.call(nil, query_601838, nil, formData_601839, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_601822(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_601823, base: "/",
    url: url_PostRemoveTagsFromResource_601824,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_601805 = ref object of OpenApiRestCall_599352
proc url_GetRemoveTagsFromResource_601807(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_601806(path: JsonNode; query: JsonNode;
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
  var valid_601808 = query.getOrDefault("ResourceName")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = nil)
  if valid_601808 != nil:
    section.add "ResourceName", valid_601808
  var valid_601809 = query.getOrDefault("Action")
  valid_601809 = validateParameter(valid_601809, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_601809 != nil:
    section.add "Action", valid_601809
  var valid_601810 = query.getOrDefault("TagKeys")
  valid_601810 = validateParameter(valid_601810, JArray, required = true, default = nil)
  if valid_601810 != nil:
    section.add "TagKeys", valid_601810
  var valid_601811 = query.getOrDefault("Version")
  valid_601811 = validateParameter(valid_601811, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601811 != nil:
    section.add "Version", valid_601811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601812 = header.getOrDefault("X-Amz-Date")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Date", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Security-Token")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Security-Token", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Content-Sha256", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-Algorithm")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-Algorithm", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-Signature")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Signature", valid_601816
  var valid_601817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "X-Amz-SignedHeaders", valid_601817
  var valid_601818 = header.getOrDefault("X-Amz-Credential")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Credential", valid_601818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601819: Call_GetRemoveTagsFromResource_601805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601819.validator(path, query, header, formData, body)
  let scheme = call_601819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601819.url(scheme.get, call_601819.host, call_601819.base,
                         call_601819.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601819, url, valid)

proc call*(call_601820: Call_GetRemoveTagsFromResource_601805;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_601821 = newJObject()
  add(query_601821, "ResourceName", newJString(ResourceName))
  add(query_601821, "Action", newJString(Action))
  if TagKeys != nil:
    query_601821.add "TagKeys", TagKeys
  add(query_601821, "Version", newJString(Version))
  result = call_601820.call(nil, query_601821, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_601805(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_601806, base: "/",
    url: url_GetRemoveTagsFromResource_601807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_601858 = ref object of OpenApiRestCall_599352
proc url_PostResetDBParameterGroup_601860(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_601859(path: JsonNode; query: JsonNode;
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
  var valid_601861 = query.getOrDefault("Action")
  valid_601861 = validateParameter(valid_601861, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_601861 != nil:
    section.add "Action", valid_601861
  var valid_601862 = query.getOrDefault("Version")
  valid_601862 = validateParameter(valid_601862, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601862 != nil:
    section.add "Version", valid_601862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601863 = header.getOrDefault("X-Amz-Date")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Date", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Security-Token")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Security-Token", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Content-Sha256", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-Algorithm")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Algorithm", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-Signature")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Signature", valid_601867
  var valid_601868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "X-Amz-SignedHeaders", valid_601868
  var valid_601869 = header.getOrDefault("X-Amz-Credential")
  valid_601869 = validateParameter(valid_601869, JString, required = false,
                                 default = nil)
  if valid_601869 != nil:
    section.add "X-Amz-Credential", valid_601869
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601870 = formData.getOrDefault("DBParameterGroupName")
  valid_601870 = validateParameter(valid_601870, JString, required = true,
                                 default = nil)
  if valid_601870 != nil:
    section.add "DBParameterGroupName", valid_601870
  var valid_601871 = formData.getOrDefault("Parameters")
  valid_601871 = validateParameter(valid_601871, JArray, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "Parameters", valid_601871
  var valid_601872 = formData.getOrDefault("ResetAllParameters")
  valid_601872 = validateParameter(valid_601872, JBool, required = false, default = nil)
  if valid_601872 != nil:
    section.add "ResetAllParameters", valid_601872
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601873: Call_PostResetDBParameterGroup_601858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601873.validator(path, query, header, formData, body)
  let scheme = call_601873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601873.url(scheme.get, call_601873.host, call_601873.base,
                         call_601873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601873, url, valid)

proc call*(call_601874: Call_PostResetDBParameterGroup_601858;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_601875 = newJObject()
  var formData_601876 = newJObject()
  add(formData_601876, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_601876.add "Parameters", Parameters
  add(query_601875, "Action", newJString(Action))
  add(formData_601876, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_601875, "Version", newJString(Version))
  result = call_601874.call(nil, query_601875, nil, formData_601876, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_601858(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_601859, base: "/",
    url: url_PostResetDBParameterGroup_601860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_601840 = ref object of OpenApiRestCall_599352
proc url_GetResetDBParameterGroup_601842(protocol: Scheme; host: string;
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

proc validate_GetResetDBParameterGroup_601841(path: JsonNode; query: JsonNode;
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
  var valid_601843 = query.getOrDefault("DBParameterGroupName")
  valid_601843 = validateParameter(valid_601843, JString, required = true,
                                 default = nil)
  if valid_601843 != nil:
    section.add "DBParameterGroupName", valid_601843
  var valid_601844 = query.getOrDefault("Parameters")
  valid_601844 = validateParameter(valid_601844, JArray, required = false,
                                 default = nil)
  if valid_601844 != nil:
    section.add "Parameters", valid_601844
  var valid_601845 = query.getOrDefault("Action")
  valid_601845 = validateParameter(valid_601845, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_601845 != nil:
    section.add "Action", valid_601845
  var valid_601846 = query.getOrDefault("ResetAllParameters")
  valid_601846 = validateParameter(valid_601846, JBool, required = false, default = nil)
  if valid_601846 != nil:
    section.add "ResetAllParameters", valid_601846
  var valid_601847 = query.getOrDefault("Version")
  valid_601847 = validateParameter(valid_601847, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601847 != nil:
    section.add "Version", valid_601847
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601848 = header.getOrDefault("X-Amz-Date")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Date", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Security-Token")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Security-Token", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Content-Sha256", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Algorithm")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Algorithm", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-Signature")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-Signature", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-SignedHeaders", valid_601853
  var valid_601854 = header.getOrDefault("X-Amz-Credential")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "X-Amz-Credential", valid_601854
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601855: Call_GetResetDBParameterGroup_601840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601855.validator(path, query, header, formData, body)
  let scheme = call_601855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601855.url(scheme.get, call_601855.host, call_601855.base,
                         call_601855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601855, url, valid)

proc call*(call_601856: Call_GetResetDBParameterGroup_601840;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_601857 = newJObject()
  add(query_601857, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_601857.add "Parameters", Parameters
  add(query_601857, "Action", newJString(Action))
  add(query_601857, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_601857, "Version", newJString(Version))
  result = call_601856.call(nil, query_601857, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_601840(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_601841, base: "/",
    url: url_GetResetDBParameterGroup_601842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_601906 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBInstanceFromDBSnapshot_601908(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_601907(path: JsonNode;
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
  var valid_601909 = query.getOrDefault("Action")
  valid_601909 = validateParameter(valid_601909, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_601909 != nil:
    section.add "Action", valid_601909
  var valid_601910 = query.getOrDefault("Version")
  valid_601910 = validateParameter(valid_601910, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601910 != nil:
    section.add "Version", valid_601910
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601911 = header.getOrDefault("X-Amz-Date")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Date", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Security-Token")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Security-Token", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Content-Sha256", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Algorithm")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Algorithm", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Signature")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Signature", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-SignedHeaders", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Credential")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Credential", valid_601917
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
  var valid_601918 = formData.getOrDefault("Port")
  valid_601918 = validateParameter(valid_601918, JInt, required = false, default = nil)
  if valid_601918 != nil:
    section.add "Port", valid_601918
  var valid_601919 = formData.getOrDefault("Engine")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "Engine", valid_601919
  var valid_601920 = formData.getOrDefault("Iops")
  valid_601920 = validateParameter(valid_601920, JInt, required = false, default = nil)
  if valid_601920 != nil:
    section.add "Iops", valid_601920
  var valid_601921 = formData.getOrDefault("DBName")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "DBName", valid_601921
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601922 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601922 = validateParameter(valid_601922, JString, required = true,
                                 default = nil)
  if valid_601922 != nil:
    section.add "DBInstanceIdentifier", valid_601922
  var valid_601923 = formData.getOrDefault("OptionGroupName")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "OptionGroupName", valid_601923
  var valid_601924 = formData.getOrDefault("DBSubnetGroupName")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "DBSubnetGroupName", valid_601924
  var valid_601925 = formData.getOrDefault("AvailabilityZone")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "AvailabilityZone", valid_601925
  var valid_601926 = formData.getOrDefault("MultiAZ")
  valid_601926 = validateParameter(valid_601926, JBool, required = false, default = nil)
  if valid_601926 != nil:
    section.add "MultiAZ", valid_601926
  var valid_601927 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601927 = validateParameter(valid_601927, JString, required = true,
                                 default = nil)
  if valid_601927 != nil:
    section.add "DBSnapshotIdentifier", valid_601927
  var valid_601928 = formData.getOrDefault("PubliclyAccessible")
  valid_601928 = validateParameter(valid_601928, JBool, required = false, default = nil)
  if valid_601928 != nil:
    section.add "PubliclyAccessible", valid_601928
  var valid_601929 = formData.getOrDefault("DBInstanceClass")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "DBInstanceClass", valid_601929
  var valid_601930 = formData.getOrDefault("LicenseModel")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "LicenseModel", valid_601930
  var valid_601931 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601931 = validateParameter(valid_601931, JBool, required = false, default = nil)
  if valid_601931 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601931
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601932: Call_PostRestoreDBInstanceFromDBSnapshot_601906;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601932.validator(path, query, header, formData, body)
  let scheme = call_601932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601932.url(scheme.get, call_601932.host, call_601932.base,
                         call_601932.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601932, url, valid)

proc call*(call_601933: Call_PostRestoreDBInstanceFromDBSnapshot_601906;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2013-02-12"): Recallable =
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
  var query_601934 = newJObject()
  var formData_601935 = newJObject()
  add(formData_601935, "Port", newJInt(Port))
  add(formData_601935, "Engine", newJString(Engine))
  add(formData_601935, "Iops", newJInt(Iops))
  add(formData_601935, "DBName", newJString(DBName))
  add(formData_601935, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601935, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601935, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601935, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601935, "MultiAZ", newJBool(MultiAZ))
  add(formData_601935, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601934, "Action", newJString(Action))
  add(formData_601935, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601935, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601935, "LicenseModel", newJString(LicenseModel))
  add(formData_601935, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601934, "Version", newJString(Version))
  result = call_601933.call(nil, query_601934, nil, formData_601935, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_601906(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_601907, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_601908,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_601877 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBInstanceFromDBSnapshot_601879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_601878(path: JsonNode;
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
  var valid_601880 = query.getOrDefault("Engine")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "Engine", valid_601880
  var valid_601881 = query.getOrDefault("OptionGroupName")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "OptionGroupName", valid_601881
  var valid_601882 = query.getOrDefault("AvailabilityZone")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "AvailabilityZone", valid_601882
  var valid_601883 = query.getOrDefault("Iops")
  valid_601883 = validateParameter(valid_601883, JInt, required = false, default = nil)
  if valid_601883 != nil:
    section.add "Iops", valid_601883
  var valid_601884 = query.getOrDefault("MultiAZ")
  valid_601884 = validateParameter(valid_601884, JBool, required = false, default = nil)
  if valid_601884 != nil:
    section.add "MultiAZ", valid_601884
  var valid_601885 = query.getOrDefault("LicenseModel")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "LicenseModel", valid_601885
  var valid_601886 = query.getOrDefault("DBName")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "DBName", valid_601886
  var valid_601887 = query.getOrDefault("DBInstanceClass")
  valid_601887 = validateParameter(valid_601887, JString, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "DBInstanceClass", valid_601887
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601888 = query.getOrDefault("Action")
  valid_601888 = validateParameter(valid_601888, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_601888 != nil:
    section.add "Action", valid_601888
  var valid_601889 = query.getOrDefault("DBSubnetGroupName")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "DBSubnetGroupName", valid_601889
  var valid_601890 = query.getOrDefault("PubliclyAccessible")
  valid_601890 = validateParameter(valid_601890, JBool, required = false, default = nil)
  if valid_601890 != nil:
    section.add "PubliclyAccessible", valid_601890
  var valid_601891 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601891 = validateParameter(valid_601891, JBool, required = false, default = nil)
  if valid_601891 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601891
  var valid_601892 = query.getOrDefault("Port")
  valid_601892 = validateParameter(valid_601892, JInt, required = false, default = nil)
  if valid_601892 != nil:
    section.add "Port", valid_601892
  var valid_601893 = query.getOrDefault("Version")
  valid_601893 = validateParameter(valid_601893, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601893 != nil:
    section.add "Version", valid_601893
  var valid_601894 = query.getOrDefault("DBInstanceIdentifier")
  valid_601894 = validateParameter(valid_601894, JString, required = true,
                                 default = nil)
  if valid_601894 != nil:
    section.add "DBInstanceIdentifier", valid_601894
  var valid_601895 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601895 = validateParameter(valid_601895, JString, required = true,
                                 default = nil)
  if valid_601895 != nil:
    section.add "DBSnapshotIdentifier", valid_601895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601896 = header.getOrDefault("X-Amz-Date")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "X-Amz-Date", valid_601896
  var valid_601897 = header.getOrDefault("X-Amz-Security-Token")
  valid_601897 = validateParameter(valid_601897, JString, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "X-Amz-Security-Token", valid_601897
  var valid_601898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "X-Amz-Content-Sha256", valid_601898
  var valid_601899 = header.getOrDefault("X-Amz-Algorithm")
  valid_601899 = validateParameter(valid_601899, JString, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "X-Amz-Algorithm", valid_601899
  var valid_601900 = header.getOrDefault("X-Amz-Signature")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "X-Amz-Signature", valid_601900
  var valid_601901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "X-Amz-SignedHeaders", valid_601901
  var valid_601902 = header.getOrDefault("X-Amz-Credential")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Credential", valid_601902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601903: Call_GetRestoreDBInstanceFromDBSnapshot_601877;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601903.validator(path, query, header, formData, body)
  let scheme = call_601903.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601903.url(scheme.get, call_601903.host, call_601903.base,
                         call_601903.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601903, url, valid)

proc call*(call_601904: Call_GetRestoreDBInstanceFromDBSnapshot_601877;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-02-12"): Recallable =
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
  var query_601905 = newJObject()
  add(query_601905, "Engine", newJString(Engine))
  add(query_601905, "OptionGroupName", newJString(OptionGroupName))
  add(query_601905, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601905, "Iops", newJInt(Iops))
  add(query_601905, "MultiAZ", newJBool(MultiAZ))
  add(query_601905, "LicenseModel", newJString(LicenseModel))
  add(query_601905, "DBName", newJString(DBName))
  add(query_601905, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601905, "Action", newJString(Action))
  add(query_601905, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601905, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601905, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601905, "Port", newJInt(Port))
  add(query_601905, "Version", newJString(Version))
  add(query_601905, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601905, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601904.call(nil, query_601905, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_601877(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_601878, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_601879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_601967 = ref object of OpenApiRestCall_599352
proc url_PostRestoreDBInstanceToPointInTime_601969(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_601968(path: JsonNode;
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
  var valid_601970 = query.getOrDefault("Action")
  valid_601970 = validateParameter(valid_601970, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_601970 != nil:
    section.add "Action", valid_601970
  var valid_601971 = query.getOrDefault("Version")
  valid_601971 = validateParameter(valid_601971, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601971 != nil:
    section.add "Version", valid_601971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601972 = header.getOrDefault("X-Amz-Date")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Date", valid_601972
  var valid_601973 = header.getOrDefault("X-Amz-Security-Token")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "X-Amz-Security-Token", valid_601973
  var valid_601974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "X-Amz-Content-Sha256", valid_601974
  var valid_601975 = header.getOrDefault("X-Amz-Algorithm")
  valid_601975 = validateParameter(valid_601975, JString, required = false,
                                 default = nil)
  if valid_601975 != nil:
    section.add "X-Amz-Algorithm", valid_601975
  var valid_601976 = header.getOrDefault("X-Amz-Signature")
  valid_601976 = validateParameter(valid_601976, JString, required = false,
                                 default = nil)
  if valid_601976 != nil:
    section.add "X-Amz-Signature", valid_601976
  var valid_601977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "X-Amz-SignedHeaders", valid_601977
  var valid_601978 = header.getOrDefault("X-Amz-Credential")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Credential", valid_601978
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
  var valid_601979 = formData.getOrDefault("UseLatestRestorableTime")
  valid_601979 = validateParameter(valid_601979, JBool, required = false, default = nil)
  if valid_601979 != nil:
    section.add "UseLatestRestorableTime", valid_601979
  var valid_601980 = formData.getOrDefault("Port")
  valid_601980 = validateParameter(valid_601980, JInt, required = false, default = nil)
  if valid_601980 != nil:
    section.add "Port", valid_601980
  var valid_601981 = formData.getOrDefault("Engine")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "Engine", valid_601981
  var valid_601982 = formData.getOrDefault("Iops")
  valid_601982 = validateParameter(valid_601982, JInt, required = false, default = nil)
  if valid_601982 != nil:
    section.add "Iops", valid_601982
  var valid_601983 = formData.getOrDefault("DBName")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "DBName", valid_601983
  var valid_601984 = formData.getOrDefault("OptionGroupName")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "OptionGroupName", valid_601984
  var valid_601985 = formData.getOrDefault("DBSubnetGroupName")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "DBSubnetGroupName", valid_601985
  var valid_601986 = formData.getOrDefault("AvailabilityZone")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "AvailabilityZone", valid_601986
  var valid_601987 = formData.getOrDefault("MultiAZ")
  valid_601987 = validateParameter(valid_601987, JBool, required = false, default = nil)
  if valid_601987 != nil:
    section.add "MultiAZ", valid_601987
  var valid_601988 = formData.getOrDefault("RestoreTime")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "RestoreTime", valid_601988
  var valid_601989 = formData.getOrDefault("PubliclyAccessible")
  valid_601989 = validateParameter(valid_601989, JBool, required = false, default = nil)
  if valid_601989 != nil:
    section.add "PubliclyAccessible", valid_601989
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_601990 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_601990 = validateParameter(valid_601990, JString, required = true,
                                 default = nil)
  if valid_601990 != nil:
    section.add "TargetDBInstanceIdentifier", valid_601990
  var valid_601991 = formData.getOrDefault("DBInstanceClass")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "DBInstanceClass", valid_601991
  var valid_601992 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_601992 = validateParameter(valid_601992, JString, required = true,
                                 default = nil)
  if valid_601992 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601992
  var valid_601993 = formData.getOrDefault("LicenseModel")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "LicenseModel", valid_601993
  var valid_601994 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601994 = validateParameter(valid_601994, JBool, required = false, default = nil)
  if valid_601994 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601994
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_PostRestoreDBInstanceToPointInTime_601967;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601995, url, valid)

proc call*(call_601996: Call_PostRestoreDBInstanceToPointInTime_601967;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-02-12"): Recallable =
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
  var query_601997 = newJObject()
  var formData_601998 = newJObject()
  add(formData_601998, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_601998, "Port", newJInt(Port))
  add(formData_601998, "Engine", newJString(Engine))
  add(formData_601998, "Iops", newJInt(Iops))
  add(formData_601998, "DBName", newJString(DBName))
  add(formData_601998, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601998, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601998, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601998, "MultiAZ", newJBool(MultiAZ))
  add(query_601997, "Action", newJString(Action))
  add(formData_601998, "RestoreTime", newJString(RestoreTime))
  add(formData_601998, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601998, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_601998, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601998, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_601998, "LicenseModel", newJString(LicenseModel))
  add(formData_601998, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601997, "Version", newJString(Version))
  result = call_601996.call(nil, query_601997, nil, formData_601998, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_601967(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_601968, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_601969,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_601936 = ref object of OpenApiRestCall_599352
proc url_GetRestoreDBInstanceToPointInTime_601938(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_601937(path: JsonNode;
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
  var valid_601939 = query.getOrDefault("Engine")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "Engine", valid_601939
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_601940 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_601940 = validateParameter(valid_601940, JString, required = true,
                                 default = nil)
  if valid_601940 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601940
  var valid_601941 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_601941 = validateParameter(valid_601941, JString, required = true,
                                 default = nil)
  if valid_601941 != nil:
    section.add "TargetDBInstanceIdentifier", valid_601941
  var valid_601942 = query.getOrDefault("AvailabilityZone")
  valid_601942 = validateParameter(valid_601942, JString, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "AvailabilityZone", valid_601942
  var valid_601943 = query.getOrDefault("Iops")
  valid_601943 = validateParameter(valid_601943, JInt, required = false, default = nil)
  if valid_601943 != nil:
    section.add "Iops", valid_601943
  var valid_601944 = query.getOrDefault("OptionGroupName")
  valid_601944 = validateParameter(valid_601944, JString, required = false,
                                 default = nil)
  if valid_601944 != nil:
    section.add "OptionGroupName", valid_601944
  var valid_601945 = query.getOrDefault("RestoreTime")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "RestoreTime", valid_601945
  var valid_601946 = query.getOrDefault("MultiAZ")
  valid_601946 = validateParameter(valid_601946, JBool, required = false, default = nil)
  if valid_601946 != nil:
    section.add "MultiAZ", valid_601946
  var valid_601947 = query.getOrDefault("LicenseModel")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "LicenseModel", valid_601947
  var valid_601948 = query.getOrDefault("DBName")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "DBName", valid_601948
  var valid_601949 = query.getOrDefault("DBInstanceClass")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "DBInstanceClass", valid_601949
  var valid_601950 = query.getOrDefault("Action")
  valid_601950 = validateParameter(valid_601950, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_601950 != nil:
    section.add "Action", valid_601950
  var valid_601951 = query.getOrDefault("UseLatestRestorableTime")
  valid_601951 = validateParameter(valid_601951, JBool, required = false, default = nil)
  if valid_601951 != nil:
    section.add "UseLatestRestorableTime", valid_601951
  var valid_601952 = query.getOrDefault("DBSubnetGroupName")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "DBSubnetGroupName", valid_601952
  var valid_601953 = query.getOrDefault("PubliclyAccessible")
  valid_601953 = validateParameter(valid_601953, JBool, required = false, default = nil)
  if valid_601953 != nil:
    section.add "PubliclyAccessible", valid_601953
  var valid_601954 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601954 = validateParameter(valid_601954, JBool, required = false, default = nil)
  if valid_601954 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601954
  var valid_601955 = query.getOrDefault("Port")
  valid_601955 = validateParameter(valid_601955, JInt, required = false, default = nil)
  if valid_601955 != nil:
    section.add "Port", valid_601955
  var valid_601956 = query.getOrDefault("Version")
  valid_601956 = validateParameter(valid_601956, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601956 != nil:
    section.add "Version", valid_601956
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601957 = header.getOrDefault("X-Amz-Date")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Date", valid_601957
  var valid_601958 = header.getOrDefault("X-Amz-Security-Token")
  valid_601958 = validateParameter(valid_601958, JString, required = false,
                                 default = nil)
  if valid_601958 != nil:
    section.add "X-Amz-Security-Token", valid_601958
  var valid_601959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601959 = validateParameter(valid_601959, JString, required = false,
                                 default = nil)
  if valid_601959 != nil:
    section.add "X-Amz-Content-Sha256", valid_601959
  var valid_601960 = header.getOrDefault("X-Amz-Algorithm")
  valid_601960 = validateParameter(valid_601960, JString, required = false,
                                 default = nil)
  if valid_601960 != nil:
    section.add "X-Amz-Algorithm", valid_601960
  var valid_601961 = header.getOrDefault("X-Amz-Signature")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Signature", valid_601961
  var valid_601962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-SignedHeaders", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Credential")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Credential", valid_601963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601964: Call_GetRestoreDBInstanceToPointInTime_601936;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601964.validator(path, query, header, formData, body)
  let scheme = call_601964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601964.url(scheme.get, call_601964.host, call_601964.base,
                         call_601964.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601964, url, valid)

proc call*(call_601965: Call_GetRestoreDBInstanceToPointInTime_601936;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          OptionGroupName: string = ""; RestoreTime: string = ""; MultiAZ: bool = false;
          LicenseModel: string = ""; DBName: string = ""; DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-02-12"): Recallable =
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
  var query_601966 = newJObject()
  add(query_601966, "Engine", newJString(Engine))
  add(query_601966, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_601966, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_601966, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601966, "Iops", newJInt(Iops))
  add(query_601966, "OptionGroupName", newJString(OptionGroupName))
  add(query_601966, "RestoreTime", newJString(RestoreTime))
  add(query_601966, "MultiAZ", newJBool(MultiAZ))
  add(query_601966, "LicenseModel", newJString(LicenseModel))
  add(query_601966, "DBName", newJString(DBName))
  add(query_601966, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601966, "Action", newJString(Action))
  add(query_601966, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_601966, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601966, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601966, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601966, "Port", newJInt(Port))
  add(query_601966, "Version", newJString(Version))
  result = call_601965.call(nil, query_601966, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_601936(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_601937, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_601938,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_602019 = ref object of OpenApiRestCall_599352
proc url_PostRevokeDBSecurityGroupIngress_602021(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_602020(path: JsonNode;
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
  var valid_602022 = query.getOrDefault("Action")
  valid_602022 = validateParameter(valid_602022, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_602022 != nil:
    section.add "Action", valid_602022
  var valid_602023 = query.getOrDefault("Version")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602023 != nil:
    section.add "Version", valid_602023
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602024 = header.getOrDefault("X-Amz-Date")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Date", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Security-Token")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Security-Token", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Content-Sha256", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Algorithm")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Algorithm", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Signature")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Signature", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-SignedHeaders", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Credential")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Credential", valid_602030
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602031 = formData.getOrDefault("DBSecurityGroupName")
  valid_602031 = validateParameter(valid_602031, JString, required = true,
                                 default = nil)
  if valid_602031 != nil:
    section.add "DBSecurityGroupName", valid_602031
  var valid_602032 = formData.getOrDefault("EC2SecurityGroupName")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "EC2SecurityGroupName", valid_602032
  var valid_602033 = formData.getOrDefault("EC2SecurityGroupId")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "EC2SecurityGroupId", valid_602033
  var valid_602034 = formData.getOrDefault("CIDRIP")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "CIDRIP", valid_602034
  var valid_602035 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602035
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602036: Call_PostRevokeDBSecurityGroupIngress_602019;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602036.validator(path, query, header, formData, body)
  let scheme = call_602036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602036.url(scheme.get, call_602036.host, call_602036.base,
                         call_602036.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602036, url, valid)

proc call*(call_602037: Call_PostRevokeDBSecurityGroupIngress_602019;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-02-12";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_602038 = newJObject()
  var formData_602039 = newJObject()
  add(formData_602039, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602038, "Action", newJString(Action))
  add(formData_602039, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_602039, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_602039, "CIDRIP", newJString(CIDRIP))
  add(query_602038, "Version", newJString(Version))
  add(formData_602039, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_602037.call(nil, query_602038, nil, formData_602039, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_602019(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_602020, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_602021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_601999 = ref object of OpenApiRestCall_599352
proc url_GetRevokeDBSecurityGroupIngress_602001(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_602000(path: JsonNode;
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
  var valid_602002 = query.getOrDefault("EC2SecurityGroupId")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "EC2SecurityGroupId", valid_602002
  var valid_602003 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602003
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602004 = query.getOrDefault("DBSecurityGroupName")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = nil)
  if valid_602004 != nil:
    section.add "DBSecurityGroupName", valid_602004
  var valid_602005 = query.getOrDefault("Action")
  valid_602005 = validateParameter(valid_602005, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_602005 != nil:
    section.add "Action", valid_602005
  var valid_602006 = query.getOrDefault("CIDRIP")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "CIDRIP", valid_602006
  var valid_602007 = query.getOrDefault("EC2SecurityGroupName")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "EC2SecurityGroupName", valid_602007
  var valid_602008 = query.getOrDefault("Version")
  valid_602008 = validateParameter(valid_602008, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602008 != nil:
    section.add "Version", valid_602008
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602009 = header.getOrDefault("X-Amz-Date")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Date", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Security-Token")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Security-Token", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Content-Sha256", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Algorithm")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Algorithm", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Signature")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Signature", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-SignedHeaders", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-Credential")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-Credential", valid_602015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602016: Call_GetRevokeDBSecurityGroupIngress_601999;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602016.validator(path, query, header, formData, body)
  let scheme = call_602016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602016.url(scheme.get, call_602016.host, call_602016.base,
                         call_602016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602016, url, valid)

proc call*(call_602017: Call_GetRevokeDBSecurityGroupIngress_601999;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_602018 = newJObject()
  add(query_602018, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_602018, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_602018, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602018, "Action", newJString(Action))
  add(query_602018, "CIDRIP", newJString(CIDRIP))
  add(query_602018, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_602018, "Version", newJString(Version))
  result = call_602017.call(nil, query_602018, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_601999(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_602000, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_602001,
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

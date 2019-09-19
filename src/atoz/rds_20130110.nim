
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600410 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600410](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600410): Option[Scheme] {.used.} =
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
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_601024 = ref object of OpenApiRestCall_600410
proc url_PostAddSourceIdentifierToSubscription_601026(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddSourceIdentifierToSubscription_601025(path: JsonNode;
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
  var valid_601027 = query.getOrDefault("Action")
  valid_601027 = validateParameter(valid_601027, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_601027 != nil:
    section.add "Action", valid_601027
  var valid_601028 = query.getOrDefault("Version")
  valid_601028 = validateParameter(valid_601028, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601028 != nil:
    section.add "Version", valid_601028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601029 = header.getOrDefault("X-Amz-Date")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Date", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Security-Token")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Security-Token", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-Content-Sha256", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Algorithm")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Algorithm", valid_601032
  var valid_601033 = header.getOrDefault("X-Amz-Signature")
  valid_601033 = validateParameter(valid_601033, JString, required = false,
                                 default = nil)
  if valid_601033 != nil:
    section.add "X-Amz-Signature", valid_601033
  var valid_601034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601034 = validateParameter(valid_601034, JString, required = false,
                                 default = nil)
  if valid_601034 != nil:
    section.add "X-Amz-SignedHeaders", valid_601034
  var valid_601035 = header.getOrDefault("X-Amz-Credential")
  valid_601035 = validateParameter(valid_601035, JString, required = false,
                                 default = nil)
  if valid_601035 != nil:
    section.add "X-Amz-Credential", valid_601035
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_601036 = formData.getOrDefault("SourceIdentifier")
  valid_601036 = validateParameter(valid_601036, JString, required = true,
                                 default = nil)
  if valid_601036 != nil:
    section.add "SourceIdentifier", valid_601036
  var valid_601037 = formData.getOrDefault("SubscriptionName")
  valid_601037 = validateParameter(valid_601037, JString, required = true,
                                 default = nil)
  if valid_601037 != nil:
    section.add "SubscriptionName", valid_601037
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601038: Call_PostAddSourceIdentifierToSubscription_601024;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601038.validator(path, query, header, formData, body)
  let scheme = call_601038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601038.url(scheme.get, call_601038.host, call_601038.base,
                         call_601038.route, valid.getOrDefault("path"))
  result = hook(call_601038, url, valid)

proc call*(call_601039: Call_PostAddSourceIdentifierToSubscription_601024;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601040 = newJObject()
  var formData_601041 = newJObject()
  add(formData_601041, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_601041, "SubscriptionName", newJString(SubscriptionName))
  add(query_601040, "Action", newJString(Action))
  add(query_601040, "Version", newJString(Version))
  result = call_601039.call(nil, query_601040, nil, formData_601041, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_601024(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_601025, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_601026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_600752 = ref object of OpenApiRestCall_600410
proc url_GetAddSourceIdentifierToSubscription_600754(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddSourceIdentifierToSubscription_600753(path: JsonNode;
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
  var valid_600879 = query.getOrDefault("Action")
  valid_600879 = validateParameter(valid_600879, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_600879 != nil:
    section.add "Action", valid_600879
  var valid_600880 = query.getOrDefault("SourceIdentifier")
  valid_600880 = validateParameter(valid_600880, JString, required = true,
                                 default = nil)
  if valid_600880 != nil:
    section.add "SourceIdentifier", valid_600880
  var valid_600881 = query.getOrDefault("SubscriptionName")
  valid_600881 = validateParameter(valid_600881, JString, required = true,
                                 default = nil)
  if valid_600881 != nil:
    section.add "SubscriptionName", valid_600881
  var valid_600882 = query.getOrDefault("Version")
  valid_600882 = validateParameter(valid_600882, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_600882 != nil:
    section.add "Version", valid_600882
  result.add "query", section
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

proc call*(call_600912: Call_GetAddSourceIdentifierToSubscription_600752;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_GetAddSourceIdentifierToSubscription_600752;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_600984 = newJObject()
  add(query_600984, "Action", newJString(Action))
  add(query_600984, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_600984, "SubscriptionName", newJString(SubscriptionName))
  add(query_600984, "Version", newJString(Version))
  result = call_600983.call(nil, query_600984, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_600752(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_600753, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_600754,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_601059 = ref object of OpenApiRestCall_600410
proc url_PostAddTagsToResource_601061(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTagsToResource_601060(path: JsonNode; query: JsonNode;
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
  var valid_601062 = query.getOrDefault("Action")
  valid_601062 = validateParameter(valid_601062, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601062 != nil:
    section.add "Action", valid_601062
  var valid_601063 = query.getOrDefault("Version")
  valid_601063 = validateParameter(valid_601063, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601063 != nil:
    section.add "Version", valid_601063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601064 = header.getOrDefault("X-Amz-Date")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "X-Amz-Date", valid_601064
  var valid_601065 = header.getOrDefault("X-Amz-Security-Token")
  valid_601065 = validateParameter(valid_601065, JString, required = false,
                                 default = nil)
  if valid_601065 != nil:
    section.add "X-Amz-Security-Token", valid_601065
  var valid_601066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601066 = validateParameter(valid_601066, JString, required = false,
                                 default = nil)
  if valid_601066 != nil:
    section.add "X-Amz-Content-Sha256", valid_601066
  var valid_601067 = header.getOrDefault("X-Amz-Algorithm")
  valid_601067 = validateParameter(valid_601067, JString, required = false,
                                 default = nil)
  if valid_601067 != nil:
    section.add "X-Amz-Algorithm", valid_601067
  var valid_601068 = header.getOrDefault("X-Amz-Signature")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Signature", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-SignedHeaders", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Credential")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Credential", valid_601070
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_601071 = formData.getOrDefault("Tags")
  valid_601071 = validateParameter(valid_601071, JArray, required = true, default = nil)
  if valid_601071 != nil:
    section.add "Tags", valid_601071
  var valid_601072 = formData.getOrDefault("ResourceName")
  valid_601072 = validateParameter(valid_601072, JString, required = true,
                                 default = nil)
  if valid_601072 != nil:
    section.add "ResourceName", valid_601072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601073: Call_PostAddTagsToResource_601059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601073.validator(path, query, header, formData, body)
  let scheme = call_601073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601073.url(scheme.get, call_601073.host, call_601073.base,
                         call_601073.route, valid.getOrDefault("path"))
  result = hook(call_601073, url, valid)

proc call*(call_601074: Call_PostAddTagsToResource_601059; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_601075 = newJObject()
  var formData_601076 = newJObject()
  if Tags != nil:
    formData_601076.add "Tags", Tags
  add(query_601075, "Action", newJString(Action))
  add(formData_601076, "ResourceName", newJString(ResourceName))
  add(query_601075, "Version", newJString(Version))
  result = call_601074.call(nil, query_601075, nil, formData_601076, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_601059(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_601060, base: "/",
    url: url_PostAddTagsToResource_601061, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_601042 = ref object of OpenApiRestCall_600410
proc url_GetAddTagsToResource_601044(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTagsToResource_601043(path: JsonNode; query: JsonNode;
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
  var valid_601045 = query.getOrDefault("Tags")
  valid_601045 = validateParameter(valid_601045, JArray, required = true, default = nil)
  if valid_601045 != nil:
    section.add "Tags", valid_601045
  var valid_601046 = query.getOrDefault("ResourceName")
  valid_601046 = validateParameter(valid_601046, JString, required = true,
                                 default = nil)
  if valid_601046 != nil:
    section.add "ResourceName", valid_601046
  var valid_601047 = query.getOrDefault("Action")
  valid_601047 = validateParameter(valid_601047, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_601047 != nil:
    section.add "Action", valid_601047
  var valid_601048 = query.getOrDefault("Version")
  valid_601048 = validateParameter(valid_601048, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601048 != nil:
    section.add "Version", valid_601048
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601049 = header.getOrDefault("X-Amz-Date")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-Date", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Security-Token")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Security-Token", valid_601050
  var valid_601051 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601051 = validateParameter(valid_601051, JString, required = false,
                                 default = nil)
  if valid_601051 != nil:
    section.add "X-Amz-Content-Sha256", valid_601051
  var valid_601052 = header.getOrDefault("X-Amz-Algorithm")
  valid_601052 = validateParameter(valid_601052, JString, required = false,
                                 default = nil)
  if valid_601052 != nil:
    section.add "X-Amz-Algorithm", valid_601052
  var valid_601053 = header.getOrDefault("X-Amz-Signature")
  valid_601053 = validateParameter(valid_601053, JString, required = false,
                                 default = nil)
  if valid_601053 != nil:
    section.add "X-Amz-Signature", valid_601053
  var valid_601054 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-SignedHeaders", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Credential")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Credential", valid_601055
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601056: Call_GetAddTagsToResource_601042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601056.validator(path, query, header, formData, body)
  let scheme = call_601056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601056.url(scheme.get, call_601056.host, call_601056.base,
                         call_601056.route, valid.getOrDefault("path"))
  result = hook(call_601056, url, valid)

proc call*(call_601057: Call_GetAddTagsToResource_601042; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601058 = newJObject()
  if Tags != nil:
    query_601058.add "Tags", Tags
  add(query_601058, "ResourceName", newJString(ResourceName))
  add(query_601058, "Action", newJString(Action))
  add(query_601058, "Version", newJString(Version))
  result = call_601057.call(nil, query_601058, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_601042(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_601043, base: "/",
    url: url_GetAddTagsToResource_601044, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_601097 = ref object of OpenApiRestCall_600410
proc url_PostAuthorizeDBSecurityGroupIngress_601099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_601098(path: JsonNode;
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
  var valid_601100 = query.getOrDefault("Action")
  valid_601100 = validateParameter(valid_601100, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_601100 != nil:
    section.add "Action", valid_601100
  var valid_601101 = query.getOrDefault("Version")
  valid_601101 = validateParameter(valid_601101, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601109 = formData.getOrDefault("DBSecurityGroupName")
  valid_601109 = validateParameter(valid_601109, JString, required = true,
                                 default = nil)
  if valid_601109 != nil:
    section.add "DBSecurityGroupName", valid_601109
  var valid_601110 = formData.getOrDefault("EC2SecurityGroupName")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "EC2SecurityGroupName", valid_601110
  var valid_601111 = formData.getOrDefault("EC2SecurityGroupId")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "EC2SecurityGroupId", valid_601111
  var valid_601112 = formData.getOrDefault("CIDRIP")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "CIDRIP", valid_601112
  var valid_601113 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_601113
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601114: Call_PostAuthorizeDBSecurityGroupIngress_601097;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601114.validator(path, query, header, formData, body)
  let scheme = call_601114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601114.url(scheme.get, call_601114.host, call_601114.base,
                         call_601114.route, valid.getOrDefault("path"))
  result = hook(call_601114, url, valid)

proc call*(call_601115: Call_PostAuthorizeDBSecurityGroupIngress_601097;
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
  var query_601116 = newJObject()
  var formData_601117 = newJObject()
  add(formData_601117, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601116, "Action", newJString(Action))
  add(formData_601117, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_601117, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_601117, "CIDRIP", newJString(CIDRIP))
  add(query_601116, "Version", newJString(Version))
  add(formData_601117, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_601115.call(nil, query_601116, nil, formData_601117, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_601097(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_601098, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_601077 = ref object of OpenApiRestCall_600410
proc url_GetAuthorizeDBSecurityGroupIngress_601079(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_601078(path: JsonNode;
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
  var valid_601080 = query.getOrDefault("EC2SecurityGroupId")
  valid_601080 = validateParameter(valid_601080, JString, required = false,
                                 default = nil)
  if valid_601080 != nil:
    section.add "EC2SecurityGroupId", valid_601080
  var valid_601081 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_601081 = validateParameter(valid_601081, JString, required = false,
                                 default = nil)
  if valid_601081 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_601081
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601082 = query.getOrDefault("DBSecurityGroupName")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = nil)
  if valid_601082 != nil:
    section.add "DBSecurityGroupName", valid_601082
  var valid_601083 = query.getOrDefault("Action")
  valid_601083 = validateParameter(valid_601083, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_601083 != nil:
    section.add "Action", valid_601083
  var valid_601084 = query.getOrDefault("CIDRIP")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "CIDRIP", valid_601084
  var valid_601085 = query.getOrDefault("EC2SecurityGroupName")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "EC2SecurityGroupName", valid_601085
  var valid_601086 = query.getOrDefault("Version")
  valid_601086 = validateParameter(valid_601086, JString, required = true,
                                 default = newJString("2013-01-10"))
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

proc call*(call_601094: Call_GetAuthorizeDBSecurityGroupIngress_601077;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_GetAuthorizeDBSecurityGroupIngress_601077;
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
  var query_601096 = newJObject()
  add(query_601096, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_601096, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_601096, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601096, "Action", newJString(Action))
  add(query_601096, "CIDRIP", newJString(CIDRIP))
  add(query_601096, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_601096, "Version", newJString(Version))
  result = call_601095.call(nil, query_601096, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_601077(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_601078, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_601079,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_601135 = ref object of OpenApiRestCall_600410
proc url_PostCopyDBSnapshot_601137(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_601136(path: JsonNode; query: JsonNode;
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
  var valid_601138 = query.getOrDefault("Action")
  valid_601138 = validateParameter(valid_601138, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601138 != nil:
    section.add "Action", valid_601138
  var valid_601139 = query.getOrDefault("Version")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601139 != nil:
    section.add "Version", valid_601139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601140 = header.getOrDefault("X-Amz-Date")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Date", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Security-Token")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Security-Token", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Content-Sha256", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Algorithm")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Algorithm", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Signature")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Signature", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-SignedHeaders", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Credential")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Credential", valid_601146
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601147 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601147 = validateParameter(valid_601147, JString, required = true,
                                 default = nil)
  if valid_601147 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601147
  var valid_601148 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601148 = validateParameter(valid_601148, JString, required = true,
                                 default = nil)
  if valid_601148 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601148
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601149: Call_PostCopyDBSnapshot_601135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601149.validator(path, query, header, formData, body)
  let scheme = call_601149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601149.url(scheme.get, call_601149.host, call_601149.base,
                         call_601149.route, valid.getOrDefault("path"))
  result = hook(call_601149, url, valid)

proc call*(call_601150: Call_PostCopyDBSnapshot_601135;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601151 = newJObject()
  var formData_601152 = newJObject()
  add(formData_601152, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601151, "Action", newJString(Action))
  add(formData_601152, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601151, "Version", newJString(Version))
  result = call_601150.call(nil, query_601151, nil, formData_601152, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_601135(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_601136, base: "/",
    url: url_PostCopyDBSnapshot_601137, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_601118 = ref object of OpenApiRestCall_600410
proc url_GetCopyDBSnapshot_601120(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBSnapshot_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601121 = validateParameter(valid_601121, JString, required = true,
                                 default = nil)
  if valid_601121 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601121
  var valid_601122 = query.getOrDefault("Action")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601122 != nil:
    section.add "Action", valid_601122
  var valid_601123 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601123
  var valid_601124 = query.getOrDefault("Version")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601124 != nil:
    section.add "Version", valid_601124
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601125 = header.getOrDefault("X-Amz-Date")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Date", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Security-Token")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Security-Token", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Content-Sha256", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Algorithm")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Algorithm", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Signature")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Signature", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-SignedHeaders", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Credential")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Credential", valid_601131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_GetCopyDBSnapshot_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_GetCopyDBSnapshot_601118;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601134 = newJObject()
  add(query_601134, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601134, "Action", newJString(Action))
  add(query_601134, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601134, "Version", newJString(Version))
  result = call_601133.call(nil, query_601134, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_601118(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_601119,
    base: "/", url: url_GetCopyDBSnapshot_601120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_601192 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBInstance_601194(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_601193(path: JsonNode; query: JsonNode;
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
  var valid_601195 = query.getOrDefault("Action")
  valid_601195 = validateParameter(valid_601195, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601195 != nil:
    section.add "Action", valid_601195
  var valid_601196 = query.getOrDefault("Version")
  valid_601196 = validateParameter(valid_601196, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601196 != nil:
    section.add "Version", valid_601196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601197 = header.getOrDefault("X-Amz-Date")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Date", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Security-Token")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Security-Token", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Content-Sha256", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Algorithm")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Algorithm", valid_601200
  var valid_601201 = header.getOrDefault("X-Amz-Signature")
  valid_601201 = validateParameter(valid_601201, JString, required = false,
                                 default = nil)
  if valid_601201 != nil:
    section.add "X-Amz-Signature", valid_601201
  var valid_601202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601202 = validateParameter(valid_601202, JString, required = false,
                                 default = nil)
  if valid_601202 != nil:
    section.add "X-Amz-SignedHeaders", valid_601202
  var valid_601203 = header.getOrDefault("X-Amz-Credential")
  valid_601203 = validateParameter(valid_601203, JString, required = false,
                                 default = nil)
  if valid_601203 != nil:
    section.add "X-Amz-Credential", valid_601203
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
  var valid_601204 = formData.getOrDefault("DBSecurityGroups")
  valid_601204 = validateParameter(valid_601204, JArray, required = false,
                                 default = nil)
  if valid_601204 != nil:
    section.add "DBSecurityGroups", valid_601204
  var valid_601205 = formData.getOrDefault("Port")
  valid_601205 = validateParameter(valid_601205, JInt, required = false, default = nil)
  if valid_601205 != nil:
    section.add "Port", valid_601205
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601206 = formData.getOrDefault("Engine")
  valid_601206 = validateParameter(valid_601206, JString, required = true,
                                 default = nil)
  if valid_601206 != nil:
    section.add "Engine", valid_601206
  var valid_601207 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601207 = validateParameter(valid_601207, JArray, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "VpcSecurityGroupIds", valid_601207
  var valid_601208 = formData.getOrDefault("Iops")
  valid_601208 = validateParameter(valid_601208, JInt, required = false, default = nil)
  if valid_601208 != nil:
    section.add "Iops", valid_601208
  var valid_601209 = formData.getOrDefault("DBName")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "DBName", valid_601209
  var valid_601210 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601210 = validateParameter(valid_601210, JString, required = true,
                                 default = nil)
  if valid_601210 != nil:
    section.add "DBInstanceIdentifier", valid_601210
  var valid_601211 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601211 = validateParameter(valid_601211, JInt, required = false, default = nil)
  if valid_601211 != nil:
    section.add "BackupRetentionPeriod", valid_601211
  var valid_601212 = formData.getOrDefault("DBParameterGroupName")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "DBParameterGroupName", valid_601212
  var valid_601213 = formData.getOrDefault("OptionGroupName")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "OptionGroupName", valid_601213
  var valid_601214 = formData.getOrDefault("MasterUserPassword")
  valid_601214 = validateParameter(valid_601214, JString, required = true,
                                 default = nil)
  if valid_601214 != nil:
    section.add "MasterUserPassword", valid_601214
  var valid_601215 = formData.getOrDefault("DBSubnetGroupName")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "DBSubnetGroupName", valid_601215
  var valid_601216 = formData.getOrDefault("AvailabilityZone")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "AvailabilityZone", valid_601216
  var valid_601217 = formData.getOrDefault("MultiAZ")
  valid_601217 = validateParameter(valid_601217, JBool, required = false, default = nil)
  if valid_601217 != nil:
    section.add "MultiAZ", valid_601217
  var valid_601218 = formData.getOrDefault("AllocatedStorage")
  valid_601218 = validateParameter(valid_601218, JInt, required = true, default = nil)
  if valid_601218 != nil:
    section.add "AllocatedStorage", valid_601218
  var valid_601219 = formData.getOrDefault("PubliclyAccessible")
  valid_601219 = validateParameter(valid_601219, JBool, required = false, default = nil)
  if valid_601219 != nil:
    section.add "PubliclyAccessible", valid_601219
  var valid_601220 = formData.getOrDefault("MasterUsername")
  valid_601220 = validateParameter(valid_601220, JString, required = true,
                                 default = nil)
  if valid_601220 != nil:
    section.add "MasterUsername", valid_601220
  var valid_601221 = formData.getOrDefault("DBInstanceClass")
  valid_601221 = validateParameter(valid_601221, JString, required = true,
                                 default = nil)
  if valid_601221 != nil:
    section.add "DBInstanceClass", valid_601221
  var valid_601222 = formData.getOrDefault("CharacterSetName")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "CharacterSetName", valid_601222
  var valid_601223 = formData.getOrDefault("PreferredBackupWindow")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "PreferredBackupWindow", valid_601223
  var valid_601224 = formData.getOrDefault("LicenseModel")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "LicenseModel", valid_601224
  var valid_601225 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601225 = validateParameter(valid_601225, JBool, required = false, default = nil)
  if valid_601225 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601225
  var valid_601226 = formData.getOrDefault("EngineVersion")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "EngineVersion", valid_601226
  var valid_601227 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "PreferredMaintenanceWindow", valid_601227
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601228: Call_PostCreateDBInstance_601192; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601228.validator(path, query, header, formData, body)
  let scheme = call_601228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601228.url(scheme.get, call_601228.host, call_601228.base,
                         call_601228.route, valid.getOrDefault("path"))
  result = hook(call_601228, url, valid)

proc call*(call_601229: Call_PostCreateDBInstance_601192; Engine: string;
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
  var query_601230 = newJObject()
  var formData_601231 = newJObject()
  if DBSecurityGroups != nil:
    formData_601231.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601231, "Port", newJInt(Port))
  add(formData_601231, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_601231.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601231, "Iops", newJInt(Iops))
  add(formData_601231, "DBName", newJString(DBName))
  add(formData_601231, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601231, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601231, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601231, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601231, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601231, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601231, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601231, "MultiAZ", newJBool(MultiAZ))
  add(query_601230, "Action", newJString(Action))
  add(formData_601231, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601231, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601231, "MasterUsername", newJString(MasterUsername))
  add(formData_601231, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601231, "CharacterSetName", newJString(CharacterSetName))
  add(formData_601231, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601231, "LicenseModel", newJString(LicenseModel))
  add(formData_601231, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601231, "EngineVersion", newJString(EngineVersion))
  add(query_601230, "Version", newJString(Version))
  add(formData_601231, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601229.call(nil, query_601230, nil, formData_601231, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_601192(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_601193, base: "/",
    url: url_PostCreateDBInstance_601194, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_601153 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBInstance_601155(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_601154(path: JsonNode; query: JsonNode;
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
  var valid_601156 = query.getOrDefault("Engine")
  valid_601156 = validateParameter(valid_601156, JString, required = true,
                                 default = nil)
  if valid_601156 != nil:
    section.add "Engine", valid_601156
  var valid_601157 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "PreferredMaintenanceWindow", valid_601157
  var valid_601158 = query.getOrDefault("AllocatedStorage")
  valid_601158 = validateParameter(valid_601158, JInt, required = true, default = nil)
  if valid_601158 != nil:
    section.add "AllocatedStorage", valid_601158
  var valid_601159 = query.getOrDefault("OptionGroupName")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "OptionGroupName", valid_601159
  var valid_601160 = query.getOrDefault("DBSecurityGroups")
  valid_601160 = validateParameter(valid_601160, JArray, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "DBSecurityGroups", valid_601160
  var valid_601161 = query.getOrDefault("MasterUserPassword")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "MasterUserPassword", valid_601161
  var valid_601162 = query.getOrDefault("AvailabilityZone")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "AvailabilityZone", valid_601162
  var valid_601163 = query.getOrDefault("Iops")
  valid_601163 = validateParameter(valid_601163, JInt, required = false, default = nil)
  if valid_601163 != nil:
    section.add "Iops", valid_601163
  var valid_601164 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601164 = validateParameter(valid_601164, JArray, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "VpcSecurityGroupIds", valid_601164
  var valid_601165 = query.getOrDefault("MultiAZ")
  valid_601165 = validateParameter(valid_601165, JBool, required = false, default = nil)
  if valid_601165 != nil:
    section.add "MultiAZ", valid_601165
  var valid_601166 = query.getOrDefault("LicenseModel")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "LicenseModel", valid_601166
  var valid_601167 = query.getOrDefault("BackupRetentionPeriod")
  valid_601167 = validateParameter(valid_601167, JInt, required = false, default = nil)
  if valid_601167 != nil:
    section.add "BackupRetentionPeriod", valid_601167
  var valid_601168 = query.getOrDefault("DBName")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "DBName", valid_601168
  var valid_601169 = query.getOrDefault("DBParameterGroupName")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "DBParameterGroupName", valid_601169
  var valid_601170 = query.getOrDefault("DBInstanceClass")
  valid_601170 = validateParameter(valid_601170, JString, required = true,
                                 default = nil)
  if valid_601170 != nil:
    section.add "DBInstanceClass", valid_601170
  var valid_601171 = query.getOrDefault("Action")
  valid_601171 = validateParameter(valid_601171, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601171 != nil:
    section.add "Action", valid_601171
  var valid_601172 = query.getOrDefault("DBSubnetGroupName")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "DBSubnetGroupName", valid_601172
  var valid_601173 = query.getOrDefault("CharacterSetName")
  valid_601173 = validateParameter(valid_601173, JString, required = false,
                                 default = nil)
  if valid_601173 != nil:
    section.add "CharacterSetName", valid_601173
  var valid_601174 = query.getOrDefault("PubliclyAccessible")
  valid_601174 = validateParameter(valid_601174, JBool, required = false, default = nil)
  if valid_601174 != nil:
    section.add "PubliclyAccessible", valid_601174
  var valid_601175 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601175 = validateParameter(valid_601175, JBool, required = false, default = nil)
  if valid_601175 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601175
  var valid_601176 = query.getOrDefault("EngineVersion")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "EngineVersion", valid_601176
  var valid_601177 = query.getOrDefault("Port")
  valid_601177 = validateParameter(valid_601177, JInt, required = false, default = nil)
  if valid_601177 != nil:
    section.add "Port", valid_601177
  var valid_601178 = query.getOrDefault("PreferredBackupWindow")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "PreferredBackupWindow", valid_601178
  var valid_601179 = query.getOrDefault("Version")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601179 != nil:
    section.add "Version", valid_601179
  var valid_601180 = query.getOrDefault("DBInstanceIdentifier")
  valid_601180 = validateParameter(valid_601180, JString, required = true,
                                 default = nil)
  if valid_601180 != nil:
    section.add "DBInstanceIdentifier", valid_601180
  var valid_601181 = query.getOrDefault("MasterUsername")
  valid_601181 = validateParameter(valid_601181, JString, required = true,
                                 default = nil)
  if valid_601181 != nil:
    section.add "MasterUsername", valid_601181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601182 = header.getOrDefault("X-Amz-Date")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Date", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Security-Token")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Security-Token", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Content-Sha256", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-Algorithm")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Algorithm", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Signature")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Signature", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-SignedHeaders", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Credential")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Credential", valid_601188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601189: Call_GetCreateDBInstance_601153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601189.validator(path, query, header, formData, body)
  let scheme = call_601189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601189.url(scheme.get, call_601189.host, call_601189.base,
                         call_601189.route, valid.getOrDefault("path"))
  result = hook(call_601189, url, valid)

proc call*(call_601190: Call_GetCreateDBInstance_601153; Engine: string;
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
  var query_601191 = newJObject()
  add(query_601191, "Engine", newJString(Engine))
  add(query_601191, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601191, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601191, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601191.add "DBSecurityGroups", DBSecurityGroups
  add(query_601191, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601191, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601191, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601191.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601191, "MultiAZ", newJBool(MultiAZ))
  add(query_601191, "LicenseModel", newJString(LicenseModel))
  add(query_601191, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601191, "DBName", newJString(DBName))
  add(query_601191, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601191, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601191, "Action", newJString(Action))
  add(query_601191, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601191, "CharacterSetName", newJString(CharacterSetName))
  add(query_601191, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601191, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601191, "EngineVersion", newJString(EngineVersion))
  add(query_601191, "Port", newJInt(Port))
  add(query_601191, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601191, "Version", newJString(Version))
  add(query_601191, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601191, "MasterUsername", newJString(MasterUsername))
  result = call_601190.call(nil, query_601191, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_601153(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_601154, base: "/",
    url: url_GetCreateDBInstance_601155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_601256 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBInstanceReadReplica_601258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_601257(path: JsonNode;
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
  var valid_601259 = query.getOrDefault("Action")
  valid_601259 = validateParameter(valid_601259, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601259 != nil:
    section.add "Action", valid_601259
  var valid_601260 = query.getOrDefault("Version")
  valid_601260 = validateParameter(valid_601260, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601260 != nil:
    section.add "Version", valid_601260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601261 = header.getOrDefault("X-Amz-Date")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Date", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Security-Token")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Security-Token", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Content-Sha256", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Algorithm")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Algorithm", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Signature")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Signature", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-SignedHeaders", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Credential")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Credential", valid_601267
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
  var valid_601268 = formData.getOrDefault("Port")
  valid_601268 = validateParameter(valid_601268, JInt, required = false, default = nil)
  if valid_601268 != nil:
    section.add "Port", valid_601268
  var valid_601269 = formData.getOrDefault("Iops")
  valid_601269 = validateParameter(valid_601269, JInt, required = false, default = nil)
  if valid_601269 != nil:
    section.add "Iops", valid_601269
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601270 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601270 = validateParameter(valid_601270, JString, required = true,
                                 default = nil)
  if valid_601270 != nil:
    section.add "DBInstanceIdentifier", valid_601270
  var valid_601271 = formData.getOrDefault("OptionGroupName")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "OptionGroupName", valid_601271
  var valid_601272 = formData.getOrDefault("AvailabilityZone")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "AvailabilityZone", valid_601272
  var valid_601273 = formData.getOrDefault("PubliclyAccessible")
  valid_601273 = validateParameter(valid_601273, JBool, required = false, default = nil)
  if valid_601273 != nil:
    section.add "PubliclyAccessible", valid_601273
  var valid_601274 = formData.getOrDefault("DBInstanceClass")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "DBInstanceClass", valid_601274
  var valid_601275 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_601275 = validateParameter(valid_601275, JString, required = true,
                                 default = nil)
  if valid_601275 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601275
  var valid_601276 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601276 = validateParameter(valid_601276, JBool, required = false, default = nil)
  if valid_601276 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601276
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601277: Call_PostCreateDBInstanceReadReplica_601256;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601277.validator(path, query, header, formData, body)
  let scheme = call_601277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601277.url(scheme.get, call_601277.host, call_601277.base,
                         call_601277.route, valid.getOrDefault("path"))
  result = hook(call_601277, url, valid)

proc call*(call_601278: Call_PostCreateDBInstanceReadReplica_601256;
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
  var query_601279 = newJObject()
  var formData_601280 = newJObject()
  add(formData_601280, "Port", newJInt(Port))
  add(formData_601280, "Iops", newJInt(Iops))
  add(formData_601280, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601280, "OptionGroupName", newJString(OptionGroupName))
  add(formData_601280, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601279, "Action", newJString(Action))
  add(formData_601280, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601280, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601280, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_601280, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601279, "Version", newJString(Version))
  result = call_601278.call(nil, query_601279, nil, formData_601280, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_601256(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_601257, base: "/",
    url: url_PostCreateDBInstanceReadReplica_601258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_601232 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBInstanceReadReplica_601234(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_601233(path: JsonNode;
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
  var valid_601235 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_601235 = validateParameter(valid_601235, JString, required = true,
                                 default = nil)
  if valid_601235 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601235
  var valid_601236 = query.getOrDefault("OptionGroupName")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "OptionGroupName", valid_601236
  var valid_601237 = query.getOrDefault("AvailabilityZone")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "AvailabilityZone", valid_601237
  var valid_601238 = query.getOrDefault("Iops")
  valid_601238 = validateParameter(valid_601238, JInt, required = false, default = nil)
  if valid_601238 != nil:
    section.add "Iops", valid_601238
  var valid_601239 = query.getOrDefault("DBInstanceClass")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "DBInstanceClass", valid_601239
  var valid_601240 = query.getOrDefault("Action")
  valid_601240 = validateParameter(valid_601240, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601240 != nil:
    section.add "Action", valid_601240
  var valid_601241 = query.getOrDefault("PubliclyAccessible")
  valid_601241 = validateParameter(valid_601241, JBool, required = false, default = nil)
  if valid_601241 != nil:
    section.add "PubliclyAccessible", valid_601241
  var valid_601242 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601242 = validateParameter(valid_601242, JBool, required = false, default = nil)
  if valid_601242 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601242
  var valid_601243 = query.getOrDefault("Port")
  valid_601243 = validateParameter(valid_601243, JInt, required = false, default = nil)
  if valid_601243 != nil:
    section.add "Port", valid_601243
  var valid_601244 = query.getOrDefault("Version")
  valid_601244 = validateParameter(valid_601244, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601244 != nil:
    section.add "Version", valid_601244
  var valid_601245 = query.getOrDefault("DBInstanceIdentifier")
  valid_601245 = validateParameter(valid_601245, JString, required = true,
                                 default = nil)
  if valid_601245 != nil:
    section.add "DBInstanceIdentifier", valid_601245
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601246 = header.getOrDefault("X-Amz-Date")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Date", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-Security-Token")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Security-Token", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Content-Sha256", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Algorithm")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Algorithm", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Signature")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Signature", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-SignedHeaders", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-Credential")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Credential", valid_601252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601253: Call_GetCreateDBInstanceReadReplica_601232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601253.validator(path, query, header, formData, body)
  let scheme = call_601253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601253.url(scheme.get, call_601253.host, call_601253.base,
                         call_601253.route, valid.getOrDefault("path"))
  result = hook(call_601253, url, valid)

proc call*(call_601254: Call_GetCreateDBInstanceReadReplica_601232;
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
  var query_601255 = newJObject()
  add(query_601255, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_601255, "OptionGroupName", newJString(OptionGroupName))
  add(query_601255, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601255, "Iops", newJInt(Iops))
  add(query_601255, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601255, "Action", newJString(Action))
  add(query_601255, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601255, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601255, "Port", newJInt(Port))
  add(query_601255, "Version", newJString(Version))
  add(query_601255, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601254.call(nil, query_601255, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_601232(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_601233, base: "/",
    url: url_GetCreateDBInstanceReadReplica_601234,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_601299 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBParameterGroup_601301(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_601300(path: JsonNode; query: JsonNode;
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
  var valid_601302 = query.getOrDefault("Action")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601302 != nil:
    section.add "Action", valid_601302
  var valid_601303 = query.getOrDefault("Version")
  valid_601303 = validateParameter(valid_601303, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601311 = formData.getOrDefault("DBParameterGroupName")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = nil)
  if valid_601311 != nil:
    section.add "DBParameterGroupName", valid_601311
  var valid_601312 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = nil)
  if valid_601312 != nil:
    section.add "DBParameterGroupFamily", valid_601312
  var valid_601313 = formData.getOrDefault("Description")
  valid_601313 = validateParameter(valid_601313, JString, required = true,
                                 default = nil)
  if valid_601313 != nil:
    section.add "Description", valid_601313
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601314: Call_PostCreateDBParameterGroup_601299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601314.validator(path, query, header, formData, body)
  let scheme = call_601314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601314.url(scheme.get, call_601314.host, call_601314.base,
                         call_601314.route, valid.getOrDefault("path"))
  result = hook(call_601314, url, valid)

proc call*(call_601315: Call_PostCreateDBParameterGroup_601299;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_601316 = newJObject()
  var formData_601317 = newJObject()
  add(formData_601317, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601316, "Action", newJString(Action))
  add(formData_601317, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_601316, "Version", newJString(Version))
  add(formData_601317, "Description", newJString(Description))
  result = call_601315.call(nil, query_601316, nil, formData_601317, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_601299(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_601300, base: "/",
    url: url_PostCreateDBParameterGroup_601301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_601281 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBParameterGroup_601283(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_601282(path: JsonNode; query: JsonNode;
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
  var valid_601284 = query.getOrDefault("Description")
  valid_601284 = validateParameter(valid_601284, JString, required = true,
                                 default = nil)
  if valid_601284 != nil:
    section.add "Description", valid_601284
  var valid_601285 = query.getOrDefault("DBParameterGroupFamily")
  valid_601285 = validateParameter(valid_601285, JString, required = true,
                                 default = nil)
  if valid_601285 != nil:
    section.add "DBParameterGroupFamily", valid_601285
  var valid_601286 = query.getOrDefault("DBParameterGroupName")
  valid_601286 = validateParameter(valid_601286, JString, required = true,
                                 default = nil)
  if valid_601286 != nil:
    section.add "DBParameterGroupName", valid_601286
  var valid_601287 = query.getOrDefault("Action")
  valid_601287 = validateParameter(valid_601287, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601287 != nil:
    section.add "Action", valid_601287
  var valid_601288 = query.getOrDefault("Version")
  valid_601288 = validateParameter(valid_601288, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601288 != nil:
    section.add "Version", valid_601288
  result.add "query", section
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

proc call*(call_601296: Call_GetCreateDBParameterGroup_601281; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601296.validator(path, query, header, formData, body)
  let scheme = call_601296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601296.url(scheme.get, call_601296.host, call_601296.base,
                         call_601296.route, valid.getOrDefault("path"))
  result = hook(call_601296, url, valid)

proc call*(call_601297: Call_GetCreateDBParameterGroup_601281; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601298 = newJObject()
  add(query_601298, "Description", newJString(Description))
  add(query_601298, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_601298, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601298, "Action", newJString(Action))
  add(query_601298, "Version", newJString(Version))
  result = call_601297.call(nil, query_601298, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_601281(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_601282, base: "/",
    url: url_GetCreateDBParameterGroup_601283,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_601335 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSecurityGroup_601337(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_601336(path: JsonNode; query: JsonNode;
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
  var valid_601338 = query.getOrDefault("Action")
  valid_601338 = validateParameter(valid_601338, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601338 != nil:
    section.add "Action", valid_601338
  var valid_601339 = query.getOrDefault("Version")
  valid_601339 = validateParameter(valid_601339, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601339 != nil:
    section.add "Version", valid_601339
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Content-Sha256", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Algorithm")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Algorithm", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Signature")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Signature", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-SignedHeaders", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Credential")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Credential", valid_601346
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601347 = formData.getOrDefault("DBSecurityGroupName")
  valid_601347 = validateParameter(valid_601347, JString, required = true,
                                 default = nil)
  if valid_601347 != nil:
    section.add "DBSecurityGroupName", valid_601347
  var valid_601348 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_601348 = validateParameter(valid_601348, JString, required = true,
                                 default = nil)
  if valid_601348 != nil:
    section.add "DBSecurityGroupDescription", valid_601348
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_PostCreateDBSecurityGroup_601335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_PostCreateDBSecurityGroup_601335;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_601351 = newJObject()
  var formData_601352 = newJObject()
  add(formData_601352, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601351, "Action", newJString(Action))
  add(formData_601352, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601351, "Version", newJString(Version))
  result = call_601350.call(nil, query_601351, nil, formData_601352, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_601335(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_601336, base: "/",
    url: url_PostCreateDBSecurityGroup_601337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_601318 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSecurityGroup_601320(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_601319(path: JsonNode; query: JsonNode;
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
  var valid_601321 = query.getOrDefault("DBSecurityGroupName")
  valid_601321 = validateParameter(valid_601321, JString, required = true,
                                 default = nil)
  if valid_601321 != nil:
    section.add "DBSecurityGroupName", valid_601321
  var valid_601322 = query.getOrDefault("DBSecurityGroupDescription")
  valid_601322 = validateParameter(valid_601322, JString, required = true,
                                 default = nil)
  if valid_601322 != nil:
    section.add "DBSecurityGroupDescription", valid_601322
  var valid_601323 = query.getOrDefault("Action")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601323 != nil:
    section.add "Action", valid_601323
  var valid_601324 = query.getOrDefault("Version")
  valid_601324 = validateParameter(valid_601324, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601324 != nil:
    section.add "Version", valid_601324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601325 = header.getOrDefault("X-Amz-Date")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Date", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Security-Token")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Security-Token", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-Content-Sha256", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Algorithm")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Algorithm", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Signature")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Signature", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-SignedHeaders", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Credential")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Credential", valid_601331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601332: Call_GetCreateDBSecurityGroup_601318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601332.validator(path, query, header, formData, body)
  let scheme = call_601332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601332.url(scheme.get, call_601332.host, call_601332.base,
                         call_601332.route, valid.getOrDefault("path"))
  result = hook(call_601332, url, valid)

proc call*(call_601333: Call_GetCreateDBSecurityGroup_601318;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601334 = newJObject()
  add(query_601334, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601334, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601334, "Action", newJString(Action))
  add(query_601334, "Version", newJString(Version))
  result = call_601333.call(nil, query_601334, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_601318(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_601319, base: "/",
    url: url_GetCreateDBSecurityGroup_601320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_601370 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSnapshot_601372(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_601371(path: JsonNode; query: JsonNode;
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
  var valid_601373 = query.getOrDefault("Action")
  valid_601373 = validateParameter(valid_601373, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601373 != nil:
    section.add "Action", valid_601373
  var valid_601374 = query.getOrDefault("Version")
  valid_601374 = validateParameter(valid_601374, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601374 != nil:
    section.add "Version", valid_601374
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601375 = header.getOrDefault("X-Amz-Date")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Date", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Security-Token")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Security-Token", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Content-Sha256", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Algorithm")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Algorithm", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Signature")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Signature", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-SignedHeaders", valid_601380
  var valid_601381 = header.getOrDefault("X-Amz-Credential")
  valid_601381 = validateParameter(valid_601381, JString, required = false,
                                 default = nil)
  if valid_601381 != nil:
    section.add "X-Amz-Credential", valid_601381
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601382 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601382 = validateParameter(valid_601382, JString, required = true,
                                 default = nil)
  if valid_601382 != nil:
    section.add "DBInstanceIdentifier", valid_601382
  var valid_601383 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601383 = validateParameter(valid_601383, JString, required = true,
                                 default = nil)
  if valid_601383 != nil:
    section.add "DBSnapshotIdentifier", valid_601383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601384: Call_PostCreateDBSnapshot_601370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601384.validator(path, query, header, formData, body)
  let scheme = call_601384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601384.url(scheme.get, call_601384.host, call_601384.base,
                         call_601384.route, valid.getOrDefault("path"))
  result = hook(call_601384, url, valid)

proc call*(call_601385: Call_PostCreateDBSnapshot_601370;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601386 = newJObject()
  var formData_601387 = newJObject()
  add(formData_601387, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601387, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601386, "Action", newJString(Action))
  add(query_601386, "Version", newJString(Version))
  result = call_601385.call(nil, query_601386, nil, formData_601387, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_601370(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_601371, base: "/",
    url: url_PostCreateDBSnapshot_601372, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_601353 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSnapshot_601355(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_601354(path: JsonNode; query: JsonNode;
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
  var valid_601356 = query.getOrDefault("Action")
  valid_601356 = validateParameter(valid_601356, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601356 != nil:
    section.add "Action", valid_601356
  var valid_601357 = query.getOrDefault("Version")
  valid_601357 = validateParameter(valid_601357, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601357 != nil:
    section.add "Version", valid_601357
  var valid_601358 = query.getOrDefault("DBInstanceIdentifier")
  valid_601358 = validateParameter(valid_601358, JString, required = true,
                                 default = nil)
  if valid_601358 != nil:
    section.add "DBInstanceIdentifier", valid_601358
  var valid_601359 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601359 = validateParameter(valid_601359, JString, required = true,
                                 default = nil)
  if valid_601359 != nil:
    section.add "DBSnapshotIdentifier", valid_601359
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601360 = header.getOrDefault("X-Amz-Date")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Date", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Security-Token")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Security-Token", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Content-Sha256", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Algorithm")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Algorithm", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Signature")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Signature", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-SignedHeaders", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Credential")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Credential", valid_601366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601367: Call_GetCreateDBSnapshot_601353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601367.validator(path, query, header, formData, body)
  let scheme = call_601367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601367.url(scheme.get, call_601367.host, call_601367.base,
                         call_601367.route, valid.getOrDefault("path"))
  result = hook(call_601367, url, valid)

proc call*(call_601368: Call_GetCreateDBSnapshot_601353;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601369 = newJObject()
  add(query_601369, "Action", newJString(Action))
  add(query_601369, "Version", newJString(Version))
  add(query_601369, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601369, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601368.call(nil, query_601369, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_601353(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_601354, base: "/",
    url: url_GetCreateDBSnapshot_601355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_601406 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSubnetGroup_601408(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_601407(path: JsonNode; query: JsonNode;
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
  var valid_601409 = query.getOrDefault("Action")
  valid_601409 = validateParameter(valid_601409, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601409 != nil:
    section.add "Action", valid_601409
  var valid_601410 = query.getOrDefault("Version")
  valid_601410 = validateParameter(valid_601410, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601410 != nil:
    section.add "Version", valid_601410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601411 = header.getOrDefault("X-Amz-Date")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Date", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Security-Token")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Security-Token", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-Content-Sha256", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Algorithm")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Algorithm", valid_601414
  var valid_601415 = header.getOrDefault("X-Amz-Signature")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Signature", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-SignedHeaders", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Credential")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Credential", valid_601417
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601418 = formData.getOrDefault("DBSubnetGroupName")
  valid_601418 = validateParameter(valid_601418, JString, required = true,
                                 default = nil)
  if valid_601418 != nil:
    section.add "DBSubnetGroupName", valid_601418
  var valid_601419 = formData.getOrDefault("SubnetIds")
  valid_601419 = validateParameter(valid_601419, JArray, required = true, default = nil)
  if valid_601419 != nil:
    section.add "SubnetIds", valid_601419
  var valid_601420 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601420 = validateParameter(valid_601420, JString, required = true,
                                 default = nil)
  if valid_601420 != nil:
    section.add "DBSubnetGroupDescription", valid_601420
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601421: Call_PostCreateDBSubnetGroup_601406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601421.validator(path, query, header, formData, body)
  let scheme = call_601421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601421.url(scheme.get, call_601421.host, call_601421.base,
                         call_601421.route, valid.getOrDefault("path"))
  result = hook(call_601421, url, valid)

proc call*(call_601422: Call_PostCreateDBSubnetGroup_601406;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_601423 = newJObject()
  var formData_601424 = newJObject()
  add(formData_601424, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601424.add "SubnetIds", SubnetIds
  add(query_601423, "Action", newJString(Action))
  add(formData_601424, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601423, "Version", newJString(Version))
  result = call_601422.call(nil, query_601423, nil, formData_601424, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_601406(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_601407, base: "/",
    url: url_PostCreateDBSubnetGroup_601408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_601388 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSubnetGroup_601390(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_601389(path: JsonNode; query: JsonNode;
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
  var valid_601391 = query.getOrDefault("Action")
  valid_601391 = validateParameter(valid_601391, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601391 != nil:
    section.add "Action", valid_601391
  var valid_601392 = query.getOrDefault("DBSubnetGroupName")
  valid_601392 = validateParameter(valid_601392, JString, required = true,
                                 default = nil)
  if valid_601392 != nil:
    section.add "DBSubnetGroupName", valid_601392
  var valid_601393 = query.getOrDefault("SubnetIds")
  valid_601393 = validateParameter(valid_601393, JArray, required = true, default = nil)
  if valid_601393 != nil:
    section.add "SubnetIds", valid_601393
  var valid_601394 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601394 = validateParameter(valid_601394, JString, required = true,
                                 default = nil)
  if valid_601394 != nil:
    section.add "DBSubnetGroupDescription", valid_601394
  var valid_601395 = query.getOrDefault("Version")
  valid_601395 = validateParameter(valid_601395, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601395 != nil:
    section.add "Version", valid_601395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601396 = header.getOrDefault("X-Amz-Date")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-Date", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Security-Token")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Security-Token", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Content-Sha256", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Algorithm")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Algorithm", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Signature")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Signature", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-SignedHeaders", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Credential")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Credential", valid_601402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601403: Call_GetCreateDBSubnetGroup_601388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601403.validator(path, query, header, formData, body)
  let scheme = call_601403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601403.url(scheme.get, call_601403.host, call_601403.base,
                         call_601403.route, valid.getOrDefault("path"))
  result = hook(call_601403, url, valid)

proc call*(call_601404: Call_GetCreateDBSubnetGroup_601388;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_601405 = newJObject()
  add(query_601405, "Action", newJString(Action))
  add(query_601405, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601405.add "SubnetIds", SubnetIds
  add(query_601405, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601405, "Version", newJString(Version))
  result = call_601404.call(nil, query_601405, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_601388(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_601389, base: "/",
    url: url_GetCreateDBSubnetGroup_601390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_601446 = ref object of OpenApiRestCall_600410
proc url_PostCreateEventSubscription_601448(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_601447(path: JsonNode; query: JsonNode;
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
  var valid_601449 = query.getOrDefault("Action")
  valid_601449 = validateParameter(valid_601449, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601449 != nil:
    section.add "Action", valid_601449
  var valid_601450 = query.getOrDefault("Version")
  valid_601450 = validateParameter(valid_601450, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601450 != nil:
    section.add "Version", valid_601450
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601451 = header.getOrDefault("X-Amz-Date")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Date", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Security-Token")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Security-Token", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Content-Sha256", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Algorithm")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Algorithm", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Signature")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Signature", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-SignedHeaders", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Credential")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Credential", valid_601457
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_601458 = formData.getOrDefault("Enabled")
  valid_601458 = validateParameter(valid_601458, JBool, required = false, default = nil)
  if valid_601458 != nil:
    section.add "Enabled", valid_601458
  var valid_601459 = formData.getOrDefault("EventCategories")
  valid_601459 = validateParameter(valid_601459, JArray, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "EventCategories", valid_601459
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_601460 = formData.getOrDefault("SnsTopicArn")
  valid_601460 = validateParameter(valid_601460, JString, required = true,
                                 default = nil)
  if valid_601460 != nil:
    section.add "SnsTopicArn", valid_601460
  var valid_601461 = formData.getOrDefault("SourceIds")
  valid_601461 = validateParameter(valid_601461, JArray, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "SourceIds", valid_601461
  var valid_601462 = formData.getOrDefault("SubscriptionName")
  valid_601462 = validateParameter(valid_601462, JString, required = true,
                                 default = nil)
  if valid_601462 != nil:
    section.add "SubscriptionName", valid_601462
  var valid_601463 = formData.getOrDefault("SourceType")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "SourceType", valid_601463
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601464: Call_PostCreateEventSubscription_601446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601464.validator(path, query, header, formData, body)
  let scheme = call_601464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601464.url(scheme.get, call_601464.host, call_601464.base,
                         call_601464.route, valid.getOrDefault("path"))
  result = hook(call_601464, url, valid)

proc call*(call_601465: Call_PostCreateEventSubscription_601446;
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
  var query_601466 = newJObject()
  var formData_601467 = newJObject()
  add(formData_601467, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601467.add "EventCategories", EventCategories
  add(formData_601467, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_601467.add "SourceIds", SourceIds
  add(formData_601467, "SubscriptionName", newJString(SubscriptionName))
  add(query_601466, "Action", newJString(Action))
  add(query_601466, "Version", newJString(Version))
  add(formData_601467, "SourceType", newJString(SourceType))
  result = call_601465.call(nil, query_601466, nil, formData_601467, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_601446(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_601447, base: "/",
    url: url_PostCreateEventSubscription_601448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_601425 = ref object of OpenApiRestCall_600410
proc url_GetCreateEventSubscription_601427(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_601426(path: JsonNode; query: JsonNode;
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
  var valid_601428 = query.getOrDefault("SourceType")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "SourceType", valid_601428
  var valid_601429 = query.getOrDefault("SourceIds")
  valid_601429 = validateParameter(valid_601429, JArray, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "SourceIds", valid_601429
  var valid_601430 = query.getOrDefault("Enabled")
  valid_601430 = validateParameter(valid_601430, JBool, required = false, default = nil)
  if valid_601430 != nil:
    section.add "Enabled", valid_601430
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601431 = query.getOrDefault("Action")
  valid_601431 = validateParameter(valid_601431, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601431 != nil:
    section.add "Action", valid_601431
  var valid_601432 = query.getOrDefault("SnsTopicArn")
  valid_601432 = validateParameter(valid_601432, JString, required = true,
                                 default = nil)
  if valid_601432 != nil:
    section.add "SnsTopicArn", valid_601432
  var valid_601433 = query.getOrDefault("EventCategories")
  valid_601433 = validateParameter(valid_601433, JArray, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "EventCategories", valid_601433
  var valid_601434 = query.getOrDefault("SubscriptionName")
  valid_601434 = validateParameter(valid_601434, JString, required = true,
                                 default = nil)
  if valid_601434 != nil:
    section.add "SubscriptionName", valid_601434
  var valid_601435 = query.getOrDefault("Version")
  valid_601435 = validateParameter(valid_601435, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601435 != nil:
    section.add "Version", valid_601435
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601436 = header.getOrDefault("X-Amz-Date")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-Date", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Security-Token")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Security-Token", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Content-Sha256", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Algorithm")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Algorithm", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Signature")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Signature", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-SignedHeaders", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Credential")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Credential", valid_601442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601443: Call_GetCreateEventSubscription_601425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601443.validator(path, query, header, formData, body)
  let scheme = call_601443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601443.url(scheme.get, call_601443.host, call_601443.base,
                         call_601443.route, valid.getOrDefault("path"))
  result = hook(call_601443, url, valid)

proc call*(call_601444: Call_GetCreateEventSubscription_601425;
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
  var query_601445 = newJObject()
  add(query_601445, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_601445.add "SourceIds", SourceIds
  add(query_601445, "Enabled", newJBool(Enabled))
  add(query_601445, "Action", newJString(Action))
  add(query_601445, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601445.add "EventCategories", EventCategories
  add(query_601445, "SubscriptionName", newJString(SubscriptionName))
  add(query_601445, "Version", newJString(Version))
  result = call_601444.call(nil, query_601445, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_601425(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_601426, base: "/",
    url: url_GetCreateEventSubscription_601427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_601487 = ref object of OpenApiRestCall_600410
proc url_PostCreateOptionGroup_601489(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_601488(path: JsonNode; query: JsonNode;
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
  var valid_601490 = query.getOrDefault("Action")
  valid_601490 = validateParameter(valid_601490, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601490 != nil:
    section.add "Action", valid_601490
  var valid_601491 = query.getOrDefault("Version")
  valid_601491 = validateParameter(valid_601491, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601491 != nil:
    section.add "Version", valid_601491
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601492 = header.getOrDefault("X-Amz-Date")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Date", valid_601492
  var valid_601493 = header.getOrDefault("X-Amz-Security-Token")
  valid_601493 = validateParameter(valid_601493, JString, required = false,
                                 default = nil)
  if valid_601493 != nil:
    section.add "X-Amz-Security-Token", valid_601493
  var valid_601494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601494 = validateParameter(valid_601494, JString, required = false,
                                 default = nil)
  if valid_601494 != nil:
    section.add "X-Amz-Content-Sha256", valid_601494
  var valid_601495 = header.getOrDefault("X-Amz-Algorithm")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Algorithm", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Signature")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Signature", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-SignedHeaders", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Credential")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Credential", valid_601498
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_601499 = formData.getOrDefault("MajorEngineVersion")
  valid_601499 = validateParameter(valid_601499, JString, required = true,
                                 default = nil)
  if valid_601499 != nil:
    section.add "MajorEngineVersion", valid_601499
  var valid_601500 = formData.getOrDefault("OptionGroupName")
  valid_601500 = validateParameter(valid_601500, JString, required = true,
                                 default = nil)
  if valid_601500 != nil:
    section.add "OptionGroupName", valid_601500
  var valid_601501 = formData.getOrDefault("EngineName")
  valid_601501 = validateParameter(valid_601501, JString, required = true,
                                 default = nil)
  if valid_601501 != nil:
    section.add "EngineName", valid_601501
  var valid_601502 = formData.getOrDefault("OptionGroupDescription")
  valid_601502 = validateParameter(valid_601502, JString, required = true,
                                 default = nil)
  if valid_601502 != nil:
    section.add "OptionGroupDescription", valid_601502
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601503: Call_PostCreateOptionGroup_601487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601503.validator(path, query, header, formData, body)
  let scheme = call_601503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601503.url(scheme.get, call_601503.host, call_601503.base,
                         call_601503.route, valid.getOrDefault("path"))
  result = hook(call_601503, url, valid)

proc call*(call_601504: Call_PostCreateOptionGroup_601487;
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
  var query_601505 = newJObject()
  var formData_601506 = newJObject()
  add(formData_601506, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601506, "OptionGroupName", newJString(OptionGroupName))
  add(query_601505, "Action", newJString(Action))
  add(formData_601506, "EngineName", newJString(EngineName))
  add(formData_601506, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_601505, "Version", newJString(Version))
  result = call_601504.call(nil, query_601505, nil, formData_601506, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_601487(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_601488, base: "/",
    url: url_PostCreateOptionGroup_601489, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_601468 = ref object of OpenApiRestCall_600410
proc url_GetCreateOptionGroup_601470(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_601469(path: JsonNode; query: JsonNode;
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
  var valid_601471 = query.getOrDefault("OptionGroupName")
  valid_601471 = validateParameter(valid_601471, JString, required = true,
                                 default = nil)
  if valid_601471 != nil:
    section.add "OptionGroupName", valid_601471
  var valid_601472 = query.getOrDefault("OptionGroupDescription")
  valid_601472 = validateParameter(valid_601472, JString, required = true,
                                 default = nil)
  if valid_601472 != nil:
    section.add "OptionGroupDescription", valid_601472
  var valid_601473 = query.getOrDefault("Action")
  valid_601473 = validateParameter(valid_601473, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601473 != nil:
    section.add "Action", valid_601473
  var valid_601474 = query.getOrDefault("Version")
  valid_601474 = validateParameter(valid_601474, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601474 != nil:
    section.add "Version", valid_601474
  var valid_601475 = query.getOrDefault("EngineName")
  valid_601475 = validateParameter(valid_601475, JString, required = true,
                                 default = nil)
  if valid_601475 != nil:
    section.add "EngineName", valid_601475
  var valid_601476 = query.getOrDefault("MajorEngineVersion")
  valid_601476 = validateParameter(valid_601476, JString, required = true,
                                 default = nil)
  if valid_601476 != nil:
    section.add "MajorEngineVersion", valid_601476
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601477 = header.getOrDefault("X-Amz-Date")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Date", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Security-Token")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Security-Token", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-Content-Sha256", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Algorithm")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Algorithm", valid_601480
  var valid_601481 = header.getOrDefault("X-Amz-Signature")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Signature", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-SignedHeaders", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Credential")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Credential", valid_601483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601484: Call_GetCreateOptionGroup_601468; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601484.validator(path, query, header, formData, body)
  let scheme = call_601484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601484.url(scheme.get, call_601484.host, call_601484.base,
                         call_601484.route, valid.getOrDefault("path"))
  result = hook(call_601484, url, valid)

proc call*(call_601485: Call_GetCreateOptionGroup_601468; OptionGroupName: string;
          OptionGroupDescription: string; EngineName: string;
          MajorEngineVersion: string; Action: string = "CreateOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_601486 = newJObject()
  add(query_601486, "OptionGroupName", newJString(OptionGroupName))
  add(query_601486, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_601486, "Action", newJString(Action))
  add(query_601486, "Version", newJString(Version))
  add(query_601486, "EngineName", newJString(EngineName))
  add(query_601486, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601485.call(nil, query_601486, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_601468(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_601469, base: "/",
    url: url_GetCreateOptionGroup_601470, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_601525 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBInstance_601527(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_601526(path: JsonNode; query: JsonNode;
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
  var valid_601528 = query.getOrDefault("Action")
  valid_601528 = validateParameter(valid_601528, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601528 != nil:
    section.add "Action", valid_601528
  var valid_601529 = query.getOrDefault("Version")
  valid_601529 = validateParameter(valid_601529, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601529 != nil:
    section.add "Version", valid_601529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601530 = header.getOrDefault("X-Amz-Date")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Date", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Security-Token")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Security-Token", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Content-Sha256", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Algorithm")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Algorithm", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Signature")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Signature", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-SignedHeaders", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Credential")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Credential", valid_601536
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601537 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601537 = validateParameter(valid_601537, JString, required = true,
                                 default = nil)
  if valid_601537 != nil:
    section.add "DBInstanceIdentifier", valid_601537
  var valid_601538 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601538
  var valid_601539 = formData.getOrDefault("SkipFinalSnapshot")
  valid_601539 = validateParameter(valid_601539, JBool, required = false, default = nil)
  if valid_601539 != nil:
    section.add "SkipFinalSnapshot", valid_601539
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601540: Call_PostDeleteDBInstance_601525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601540.validator(path, query, header, formData, body)
  let scheme = call_601540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601540.url(scheme.get, call_601540.host, call_601540.base,
                         call_601540.route, valid.getOrDefault("path"))
  result = hook(call_601540, url, valid)

proc call*(call_601541: Call_PostDeleteDBInstance_601525;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_601542 = newJObject()
  var formData_601543 = newJObject()
  add(formData_601543, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601543, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601542, "Action", newJString(Action))
  add(query_601542, "Version", newJString(Version))
  add(formData_601543, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_601541.call(nil, query_601542, nil, formData_601543, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_601525(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_601526, base: "/",
    url: url_PostDeleteDBInstance_601527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_601507 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBInstance_601509(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_601508(path: JsonNode; query: JsonNode;
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
  var valid_601510 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601510 = validateParameter(valid_601510, JString, required = false,
                                 default = nil)
  if valid_601510 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601510
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601511 = query.getOrDefault("Action")
  valid_601511 = validateParameter(valid_601511, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601511 != nil:
    section.add "Action", valid_601511
  var valid_601512 = query.getOrDefault("SkipFinalSnapshot")
  valid_601512 = validateParameter(valid_601512, JBool, required = false, default = nil)
  if valid_601512 != nil:
    section.add "SkipFinalSnapshot", valid_601512
  var valid_601513 = query.getOrDefault("Version")
  valid_601513 = validateParameter(valid_601513, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601513 != nil:
    section.add "Version", valid_601513
  var valid_601514 = query.getOrDefault("DBInstanceIdentifier")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = nil)
  if valid_601514 != nil:
    section.add "DBInstanceIdentifier", valid_601514
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601515 = header.getOrDefault("X-Amz-Date")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Date", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Security-Token")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Security-Token", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Content-Sha256", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Algorithm")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Algorithm", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Signature")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Signature", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-SignedHeaders", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Credential")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Credential", valid_601521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601522: Call_GetDeleteDBInstance_601507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601522.validator(path, query, header, formData, body)
  let scheme = call_601522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601522.url(scheme.get, call_601522.host, call_601522.base,
                         call_601522.route, valid.getOrDefault("path"))
  result = hook(call_601522, url, valid)

proc call*(call_601523: Call_GetDeleteDBInstance_601507;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601524 = newJObject()
  add(query_601524, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601524, "Action", newJString(Action))
  add(query_601524, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_601524, "Version", newJString(Version))
  add(query_601524, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601523.call(nil, query_601524, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_601507(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_601508, base: "/",
    url: url_GetDeleteDBInstance_601509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_601560 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBParameterGroup_601562(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_601561(path: JsonNode; query: JsonNode;
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
  var valid_601563 = query.getOrDefault("Action")
  valid_601563 = validateParameter(valid_601563, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601563 != nil:
    section.add "Action", valid_601563
  var valid_601564 = query.getOrDefault("Version")
  valid_601564 = validateParameter(valid_601564, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601564 != nil:
    section.add "Version", valid_601564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601565 = header.getOrDefault("X-Amz-Date")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Date", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Security-Token")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Security-Token", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Content-Sha256", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Algorithm")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Algorithm", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Signature")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Signature", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-SignedHeaders", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Credential")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Credential", valid_601571
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601572 = formData.getOrDefault("DBParameterGroupName")
  valid_601572 = validateParameter(valid_601572, JString, required = true,
                                 default = nil)
  if valid_601572 != nil:
    section.add "DBParameterGroupName", valid_601572
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601573: Call_PostDeleteDBParameterGroup_601560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601573.validator(path, query, header, formData, body)
  let scheme = call_601573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601573.url(scheme.get, call_601573.host, call_601573.base,
                         call_601573.route, valid.getOrDefault("path"))
  result = hook(call_601573, url, valid)

proc call*(call_601574: Call_PostDeleteDBParameterGroup_601560;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601575 = newJObject()
  var formData_601576 = newJObject()
  add(formData_601576, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601575, "Action", newJString(Action))
  add(query_601575, "Version", newJString(Version))
  result = call_601574.call(nil, query_601575, nil, formData_601576, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_601560(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_601561, base: "/",
    url: url_PostDeleteDBParameterGroup_601562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_601544 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBParameterGroup_601546(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_601545(path: JsonNode; query: JsonNode;
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
  var valid_601547 = query.getOrDefault("DBParameterGroupName")
  valid_601547 = validateParameter(valid_601547, JString, required = true,
                                 default = nil)
  if valid_601547 != nil:
    section.add "DBParameterGroupName", valid_601547
  var valid_601548 = query.getOrDefault("Action")
  valid_601548 = validateParameter(valid_601548, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601548 != nil:
    section.add "Action", valid_601548
  var valid_601549 = query.getOrDefault("Version")
  valid_601549 = validateParameter(valid_601549, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601549 != nil:
    section.add "Version", valid_601549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601550 = header.getOrDefault("X-Amz-Date")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Date", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Security-Token")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Security-Token", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Content-Sha256", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Algorithm")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Algorithm", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Signature")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Signature", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-SignedHeaders", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Credential")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Credential", valid_601556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601557: Call_GetDeleteDBParameterGroup_601544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601557.validator(path, query, header, formData, body)
  let scheme = call_601557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601557.url(scheme.get, call_601557.host, call_601557.base,
                         call_601557.route, valid.getOrDefault("path"))
  result = hook(call_601557, url, valid)

proc call*(call_601558: Call_GetDeleteDBParameterGroup_601544;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601559 = newJObject()
  add(query_601559, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601559, "Action", newJString(Action))
  add(query_601559, "Version", newJString(Version))
  result = call_601558.call(nil, query_601559, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_601544(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_601545, base: "/",
    url: url_GetDeleteDBParameterGroup_601546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_601593 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSecurityGroup_601595(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_601594(path: JsonNode; query: JsonNode;
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
  var valid_601596 = query.getOrDefault("Action")
  valid_601596 = validateParameter(valid_601596, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601596 != nil:
    section.add "Action", valid_601596
  var valid_601597 = query.getOrDefault("Version")
  valid_601597 = validateParameter(valid_601597, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601597 != nil:
    section.add "Version", valid_601597
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601598 = header.getOrDefault("X-Amz-Date")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Date", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Security-Token")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Security-Token", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Content-Sha256", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Algorithm")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Algorithm", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-Signature")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-Signature", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-SignedHeaders", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Credential")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Credential", valid_601604
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601605 = formData.getOrDefault("DBSecurityGroupName")
  valid_601605 = validateParameter(valid_601605, JString, required = true,
                                 default = nil)
  if valid_601605 != nil:
    section.add "DBSecurityGroupName", valid_601605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601606: Call_PostDeleteDBSecurityGroup_601593; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601606.validator(path, query, header, formData, body)
  let scheme = call_601606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601606.url(scheme.get, call_601606.host, call_601606.base,
                         call_601606.route, valid.getOrDefault("path"))
  result = hook(call_601606, url, valid)

proc call*(call_601607: Call_PostDeleteDBSecurityGroup_601593;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601608 = newJObject()
  var formData_601609 = newJObject()
  add(formData_601609, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601608, "Action", newJString(Action))
  add(query_601608, "Version", newJString(Version))
  result = call_601607.call(nil, query_601608, nil, formData_601609, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_601593(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_601594, base: "/",
    url: url_PostDeleteDBSecurityGroup_601595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_601577 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSecurityGroup_601579(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_601578(path: JsonNode; query: JsonNode;
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
  var valid_601580 = query.getOrDefault("DBSecurityGroupName")
  valid_601580 = validateParameter(valid_601580, JString, required = true,
                                 default = nil)
  if valid_601580 != nil:
    section.add "DBSecurityGroupName", valid_601580
  var valid_601581 = query.getOrDefault("Action")
  valid_601581 = validateParameter(valid_601581, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601581 != nil:
    section.add "Action", valid_601581
  var valid_601582 = query.getOrDefault("Version")
  valid_601582 = validateParameter(valid_601582, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601582 != nil:
    section.add "Version", valid_601582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601583 = header.getOrDefault("X-Amz-Date")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Date", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Security-Token")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Security-Token", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Content-Sha256", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Algorithm")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Algorithm", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Signature")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Signature", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-SignedHeaders", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Credential")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Credential", valid_601589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601590: Call_GetDeleteDBSecurityGroup_601577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601590.validator(path, query, header, formData, body)
  let scheme = call_601590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601590.url(scheme.get, call_601590.host, call_601590.base,
                         call_601590.route, valid.getOrDefault("path"))
  result = hook(call_601590, url, valid)

proc call*(call_601591: Call_GetDeleteDBSecurityGroup_601577;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601592 = newJObject()
  add(query_601592, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601592, "Action", newJString(Action))
  add(query_601592, "Version", newJString(Version))
  result = call_601591.call(nil, query_601592, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_601577(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_601578, base: "/",
    url: url_GetDeleteDBSecurityGroup_601579, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_601626 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSnapshot_601628(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_601627(path: JsonNode; query: JsonNode;
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
  var valid_601629 = query.getOrDefault("Action")
  valid_601629 = validateParameter(valid_601629, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601629 != nil:
    section.add "Action", valid_601629
  var valid_601630 = query.getOrDefault("Version")
  valid_601630 = validateParameter(valid_601630, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601630 != nil:
    section.add "Version", valid_601630
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_601638 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601638 = validateParameter(valid_601638, JString, required = true,
                                 default = nil)
  if valid_601638 != nil:
    section.add "DBSnapshotIdentifier", valid_601638
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601639: Call_PostDeleteDBSnapshot_601626; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601639.validator(path, query, header, formData, body)
  let scheme = call_601639.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601639.url(scheme.get, call_601639.host, call_601639.base,
                         call_601639.route, valid.getOrDefault("path"))
  result = hook(call_601639, url, valid)

proc call*(call_601640: Call_PostDeleteDBSnapshot_601626;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601641 = newJObject()
  var formData_601642 = newJObject()
  add(formData_601642, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601641, "Action", newJString(Action))
  add(query_601641, "Version", newJString(Version))
  result = call_601640.call(nil, query_601641, nil, formData_601642, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_601626(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_601627, base: "/",
    url: url_PostDeleteDBSnapshot_601628, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_601610 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSnapshot_601612(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_601611(path: JsonNode; query: JsonNode;
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
  var valid_601613 = query.getOrDefault("Action")
  valid_601613 = validateParameter(valid_601613, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601613 != nil:
    section.add "Action", valid_601613
  var valid_601614 = query.getOrDefault("Version")
  valid_601614 = validateParameter(valid_601614, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601614 != nil:
    section.add "Version", valid_601614
  var valid_601615 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601615 = validateParameter(valid_601615, JString, required = true,
                                 default = nil)
  if valid_601615 != nil:
    section.add "DBSnapshotIdentifier", valid_601615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601616 = header.getOrDefault("X-Amz-Date")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "X-Amz-Date", valid_601616
  var valid_601617 = header.getOrDefault("X-Amz-Security-Token")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Security-Token", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Content-Sha256", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Algorithm")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Algorithm", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Signature")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Signature", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-SignedHeaders", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Credential")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Credential", valid_601622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601623: Call_GetDeleteDBSnapshot_601610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601623.validator(path, query, header, formData, body)
  let scheme = call_601623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601623.url(scheme.get, call_601623.host, call_601623.base,
                         call_601623.route, valid.getOrDefault("path"))
  result = hook(call_601623, url, valid)

proc call*(call_601624: Call_GetDeleteDBSnapshot_601610;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601625 = newJObject()
  add(query_601625, "Action", newJString(Action))
  add(query_601625, "Version", newJString(Version))
  add(query_601625, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601624.call(nil, query_601625, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_601610(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_601611, base: "/",
    url: url_GetDeleteDBSnapshot_601612, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_601659 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSubnetGroup_601661(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_601660(path: JsonNode; query: JsonNode;
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
  var valid_601662 = query.getOrDefault("Action")
  valid_601662 = validateParameter(valid_601662, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601662 != nil:
    section.add "Action", valid_601662
  var valid_601663 = query.getOrDefault("Version")
  valid_601663 = validateParameter(valid_601663, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601671 = formData.getOrDefault("DBSubnetGroupName")
  valid_601671 = validateParameter(valid_601671, JString, required = true,
                                 default = nil)
  if valid_601671 != nil:
    section.add "DBSubnetGroupName", valid_601671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601672: Call_PostDeleteDBSubnetGroup_601659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601672.validator(path, query, header, formData, body)
  let scheme = call_601672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601672.url(scheme.get, call_601672.host, call_601672.base,
                         call_601672.route, valid.getOrDefault("path"))
  result = hook(call_601672, url, valid)

proc call*(call_601673: Call_PostDeleteDBSubnetGroup_601659;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601674 = newJObject()
  var formData_601675 = newJObject()
  add(formData_601675, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601674, "Action", newJString(Action))
  add(query_601674, "Version", newJString(Version))
  result = call_601673.call(nil, query_601674, nil, formData_601675, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_601659(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_601660, base: "/",
    url: url_PostDeleteDBSubnetGroup_601661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_601643 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSubnetGroup_601645(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_601644(path: JsonNode; query: JsonNode;
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
  var valid_601646 = query.getOrDefault("Action")
  valid_601646 = validateParameter(valid_601646, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601646 != nil:
    section.add "Action", valid_601646
  var valid_601647 = query.getOrDefault("DBSubnetGroupName")
  valid_601647 = validateParameter(valid_601647, JString, required = true,
                                 default = nil)
  if valid_601647 != nil:
    section.add "DBSubnetGroupName", valid_601647
  var valid_601648 = query.getOrDefault("Version")
  valid_601648 = validateParameter(valid_601648, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601648 != nil:
    section.add "Version", valid_601648
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601649 = header.getOrDefault("X-Amz-Date")
  valid_601649 = validateParameter(valid_601649, JString, required = false,
                                 default = nil)
  if valid_601649 != nil:
    section.add "X-Amz-Date", valid_601649
  var valid_601650 = header.getOrDefault("X-Amz-Security-Token")
  valid_601650 = validateParameter(valid_601650, JString, required = false,
                                 default = nil)
  if valid_601650 != nil:
    section.add "X-Amz-Security-Token", valid_601650
  var valid_601651 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Content-Sha256", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Algorithm")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Algorithm", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Signature")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Signature", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-SignedHeaders", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Credential")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Credential", valid_601655
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601656: Call_GetDeleteDBSubnetGroup_601643; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601656.validator(path, query, header, formData, body)
  let scheme = call_601656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601656.url(scheme.get, call_601656.host, call_601656.base,
                         call_601656.route, valid.getOrDefault("path"))
  result = hook(call_601656, url, valid)

proc call*(call_601657: Call_GetDeleteDBSubnetGroup_601643;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_601658 = newJObject()
  add(query_601658, "Action", newJString(Action))
  add(query_601658, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601658, "Version", newJString(Version))
  result = call_601657.call(nil, query_601658, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_601643(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_601644, base: "/",
    url: url_GetDeleteDBSubnetGroup_601645, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_601692 = ref object of OpenApiRestCall_600410
proc url_PostDeleteEventSubscription_601694(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_601693(path: JsonNode; query: JsonNode;
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
  var valid_601695 = query.getOrDefault("Action")
  valid_601695 = validateParameter(valid_601695, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601695 != nil:
    section.add "Action", valid_601695
  var valid_601696 = query.getOrDefault("Version")
  valid_601696 = validateParameter(valid_601696, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601696 != nil:
    section.add "Version", valid_601696
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601697 = header.getOrDefault("X-Amz-Date")
  valid_601697 = validateParameter(valid_601697, JString, required = false,
                                 default = nil)
  if valid_601697 != nil:
    section.add "X-Amz-Date", valid_601697
  var valid_601698 = header.getOrDefault("X-Amz-Security-Token")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Security-Token", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Content-Sha256", valid_601699
  var valid_601700 = header.getOrDefault("X-Amz-Algorithm")
  valid_601700 = validateParameter(valid_601700, JString, required = false,
                                 default = nil)
  if valid_601700 != nil:
    section.add "X-Amz-Algorithm", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Signature")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Signature", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-SignedHeaders", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Credential")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Credential", valid_601703
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601704 = formData.getOrDefault("SubscriptionName")
  valid_601704 = validateParameter(valid_601704, JString, required = true,
                                 default = nil)
  if valid_601704 != nil:
    section.add "SubscriptionName", valid_601704
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601705: Call_PostDeleteEventSubscription_601692; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601705.validator(path, query, header, formData, body)
  let scheme = call_601705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601705.url(scheme.get, call_601705.host, call_601705.base,
                         call_601705.route, valid.getOrDefault("path"))
  result = hook(call_601705, url, valid)

proc call*(call_601706: Call_PostDeleteEventSubscription_601692;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601707 = newJObject()
  var formData_601708 = newJObject()
  add(formData_601708, "SubscriptionName", newJString(SubscriptionName))
  add(query_601707, "Action", newJString(Action))
  add(query_601707, "Version", newJString(Version))
  result = call_601706.call(nil, query_601707, nil, formData_601708, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_601692(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_601693, base: "/",
    url: url_PostDeleteEventSubscription_601694,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_601676 = ref object of OpenApiRestCall_600410
proc url_GetDeleteEventSubscription_601678(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_601677(path: JsonNode; query: JsonNode;
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
  var valid_601679 = query.getOrDefault("Action")
  valid_601679 = validateParameter(valid_601679, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601679 != nil:
    section.add "Action", valid_601679
  var valid_601680 = query.getOrDefault("SubscriptionName")
  valid_601680 = validateParameter(valid_601680, JString, required = true,
                                 default = nil)
  if valid_601680 != nil:
    section.add "SubscriptionName", valid_601680
  var valid_601681 = query.getOrDefault("Version")
  valid_601681 = validateParameter(valid_601681, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601681 != nil:
    section.add "Version", valid_601681
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601682 = header.getOrDefault("X-Amz-Date")
  valid_601682 = validateParameter(valid_601682, JString, required = false,
                                 default = nil)
  if valid_601682 != nil:
    section.add "X-Amz-Date", valid_601682
  var valid_601683 = header.getOrDefault("X-Amz-Security-Token")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Security-Token", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Content-Sha256", valid_601684
  var valid_601685 = header.getOrDefault("X-Amz-Algorithm")
  valid_601685 = validateParameter(valid_601685, JString, required = false,
                                 default = nil)
  if valid_601685 != nil:
    section.add "X-Amz-Algorithm", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-Signature")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Signature", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-SignedHeaders", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Credential")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Credential", valid_601688
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601689: Call_GetDeleteEventSubscription_601676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601689.validator(path, query, header, formData, body)
  let scheme = call_601689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601689.url(scheme.get, call_601689.host, call_601689.base,
                         call_601689.route, valid.getOrDefault("path"))
  result = hook(call_601689, url, valid)

proc call*(call_601690: Call_GetDeleteEventSubscription_601676;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601691 = newJObject()
  add(query_601691, "Action", newJString(Action))
  add(query_601691, "SubscriptionName", newJString(SubscriptionName))
  add(query_601691, "Version", newJString(Version))
  result = call_601690.call(nil, query_601691, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_601676(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_601677, base: "/",
    url: url_GetDeleteEventSubscription_601678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_601725 = ref object of OpenApiRestCall_600410
proc url_PostDeleteOptionGroup_601727(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_601726(path: JsonNode; query: JsonNode;
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
  var valid_601728 = query.getOrDefault("Action")
  valid_601728 = validateParameter(valid_601728, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601728 != nil:
    section.add "Action", valid_601728
  var valid_601729 = query.getOrDefault("Version")
  valid_601729 = validateParameter(valid_601729, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601729 != nil:
    section.add "Version", valid_601729
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601730 = header.getOrDefault("X-Amz-Date")
  valid_601730 = validateParameter(valid_601730, JString, required = false,
                                 default = nil)
  if valid_601730 != nil:
    section.add "X-Amz-Date", valid_601730
  var valid_601731 = header.getOrDefault("X-Amz-Security-Token")
  valid_601731 = validateParameter(valid_601731, JString, required = false,
                                 default = nil)
  if valid_601731 != nil:
    section.add "X-Amz-Security-Token", valid_601731
  var valid_601732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601732 = validateParameter(valid_601732, JString, required = false,
                                 default = nil)
  if valid_601732 != nil:
    section.add "X-Amz-Content-Sha256", valid_601732
  var valid_601733 = header.getOrDefault("X-Amz-Algorithm")
  valid_601733 = validateParameter(valid_601733, JString, required = false,
                                 default = nil)
  if valid_601733 != nil:
    section.add "X-Amz-Algorithm", valid_601733
  var valid_601734 = header.getOrDefault("X-Amz-Signature")
  valid_601734 = validateParameter(valid_601734, JString, required = false,
                                 default = nil)
  if valid_601734 != nil:
    section.add "X-Amz-Signature", valid_601734
  var valid_601735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-SignedHeaders", valid_601735
  var valid_601736 = header.getOrDefault("X-Amz-Credential")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Credential", valid_601736
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601737 = formData.getOrDefault("OptionGroupName")
  valid_601737 = validateParameter(valid_601737, JString, required = true,
                                 default = nil)
  if valid_601737 != nil:
    section.add "OptionGroupName", valid_601737
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601738: Call_PostDeleteOptionGroup_601725; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601738.validator(path, query, header, formData, body)
  let scheme = call_601738.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601738.url(scheme.get, call_601738.host, call_601738.base,
                         call_601738.route, valid.getOrDefault("path"))
  result = hook(call_601738, url, valid)

proc call*(call_601739: Call_PostDeleteOptionGroup_601725; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601740 = newJObject()
  var formData_601741 = newJObject()
  add(formData_601741, "OptionGroupName", newJString(OptionGroupName))
  add(query_601740, "Action", newJString(Action))
  add(query_601740, "Version", newJString(Version))
  result = call_601739.call(nil, query_601740, nil, formData_601741, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_601725(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_601726, base: "/",
    url: url_PostDeleteOptionGroup_601727, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_601709 = ref object of OpenApiRestCall_600410
proc url_GetDeleteOptionGroup_601711(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_601710(path: JsonNode; query: JsonNode;
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
  var valid_601712 = query.getOrDefault("OptionGroupName")
  valid_601712 = validateParameter(valid_601712, JString, required = true,
                                 default = nil)
  if valid_601712 != nil:
    section.add "OptionGroupName", valid_601712
  var valid_601713 = query.getOrDefault("Action")
  valid_601713 = validateParameter(valid_601713, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601713 != nil:
    section.add "Action", valid_601713
  var valid_601714 = query.getOrDefault("Version")
  valid_601714 = validateParameter(valid_601714, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601722: Call_GetDeleteOptionGroup_601709; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601722.validator(path, query, header, formData, body)
  let scheme = call_601722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601722.url(scheme.get, call_601722.host, call_601722.base,
                         call_601722.route, valid.getOrDefault("path"))
  result = hook(call_601722, url, valid)

proc call*(call_601723: Call_GetDeleteOptionGroup_601709; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601724 = newJObject()
  add(query_601724, "OptionGroupName", newJString(OptionGroupName))
  add(query_601724, "Action", newJString(Action))
  add(query_601724, "Version", newJString(Version))
  result = call_601723.call(nil, query_601724, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_601709(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_601710, base: "/",
    url: url_GetDeleteOptionGroup_601711, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_601764 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBEngineVersions_601766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_601765(path: JsonNode; query: JsonNode;
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
  var valid_601767 = query.getOrDefault("Action")
  valid_601767 = validateParameter(valid_601767, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601767 != nil:
    section.add "Action", valid_601767
  var valid_601768 = query.getOrDefault("Version")
  valid_601768 = validateParameter(valid_601768, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601768 != nil:
    section.add "Version", valid_601768
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601769 = header.getOrDefault("X-Amz-Date")
  valid_601769 = validateParameter(valid_601769, JString, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "X-Amz-Date", valid_601769
  var valid_601770 = header.getOrDefault("X-Amz-Security-Token")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "X-Amz-Security-Token", valid_601770
  var valid_601771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-Content-Sha256", valid_601771
  var valid_601772 = header.getOrDefault("X-Amz-Algorithm")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "X-Amz-Algorithm", valid_601772
  var valid_601773 = header.getOrDefault("X-Amz-Signature")
  valid_601773 = validateParameter(valid_601773, JString, required = false,
                                 default = nil)
  if valid_601773 != nil:
    section.add "X-Amz-Signature", valid_601773
  var valid_601774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-SignedHeaders", valid_601774
  var valid_601775 = header.getOrDefault("X-Amz-Credential")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Credential", valid_601775
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
  var valid_601776 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_601776 = validateParameter(valid_601776, JBool, required = false, default = nil)
  if valid_601776 != nil:
    section.add "ListSupportedCharacterSets", valid_601776
  var valid_601777 = formData.getOrDefault("Engine")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "Engine", valid_601777
  var valid_601778 = formData.getOrDefault("Marker")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "Marker", valid_601778
  var valid_601779 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "DBParameterGroupFamily", valid_601779
  var valid_601780 = formData.getOrDefault("MaxRecords")
  valid_601780 = validateParameter(valid_601780, JInt, required = false, default = nil)
  if valid_601780 != nil:
    section.add "MaxRecords", valid_601780
  var valid_601781 = formData.getOrDefault("EngineVersion")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "EngineVersion", valid_601781
  var valid_601782 = formData.getOrDefault("DefaultOnly")
  valid_601782 = validateParameter(valid_601782, JBool, required = false, default = nil)
  if valid_601782 != nil:
    section.add "DefaultOnly", valid_601782
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601783: Call_PostDescribeDBEngineVersions_601764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601783.validator(path, query, header, formData, body)
  let scheme = call_601783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601783.url(scheme.get, call_601783.host, call_601783.base,
                         call_601783.route, valid.getOrDefault("path"))
  result = hook(call_601783, url, valid)

proc call*(call_601784: Call_PostDescribeDBEngineVersions_601764;
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
  var query_601785 = newJObject()
  var formData_601786 = newJObject()
  add(formData_601786, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_601786, "Engine", newJString(Engine))
  add(formData_601786, "Marker", newJString(Marker))
  add(query_601785, "Action", newJString(Action))
  add(formData_601786, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_601786, "MaxRecords", newJInt(MaxRecords))
  add(formData_601786, "EngineVersion", newJString(EngineVersion))
  add(query_601785, "Version", newJString(Version))
  add(formData_601786, "DefaultOnly", newJBool(DefaultOnly))
  result = call_601784.call(nil, query_601785, nil, formData_601786, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_601764(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_601765, base: "/",
    url: url_PostDescribeDBEngineVersions_601766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_601742 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBEngineVersions_601744(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_601743(path: JsonNode; query: JsonNode;
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
  var valid_601745 = query.getOrDefault("Engine")
  valid_601745 = validateParameter(valid_601745, JString, required = false,
                                 default = nil)
  if valid_601745 != nil:
    section.add "Engine", valid_601745
  var valid_601746 = query.getOrDefault("ListSupportedCharacterSets")
  valid_601746 = validateParameter(valid_601746, JBool, required = false, default = nil)
  if valid_601746 != nil:
    section.add "ListSupportedCharacterSets", valid_601746
  var valid_601747 = query.getOrDefault("MaxRecords")
  valid_601747 = validateParameter(valid_601747, JInt, required = false, default = nil)
  if valid_601747 != nil:
    section.add "MaxRecords", valid_601747
  var valid_601748 = query.getOrDefault("DBParameterGroupFamily")
  valid_601748 = validateParameter(valid_601748, JString, required = false,
                                 default = nil)
  if valid_601748 != nil:
    section.add "DBParameterGroupFamily", valid_601748
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601749 = query.getOrDefault("Action")
  valid_601749 = validateParameter(valid_601749, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601749 != nil:
    section.add "Action", valid_601749
  var valid_601750 = query.getOrDefault("Marker")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "Marker", valid_601750
  var valid_601751 = query.getOrDefault("EngineVersion")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "EngineVersion", valid_601751
  var valid_601752 = query.getOrDefault("DefaultOnly")
  valid_601752 = validateParameter(valid_601752, JBool, required = false, default = nil)
  if valid_601752 != nil:
    section.add "DefaultOnly", valid_601752
  var valid_601753 = query.getOrDefault("Version")
  valid_601753 = validateParameter(valid_601753, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601761: Call_GetDescribeDBEngineVersions_601742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601761.validator(path, query, header, formData, body)
  let scheme = call_601761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601761.url(scheme.get, call_601761.host, call_601761.base,
                         call_601761.route, valid.getOrDefault("path"))
  result = hook(call_601761, url, valid)

proc call*(call_601762: Call_GetDescribeDBEngineVersions_601742;
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
  var query_601763 = newJObject()
  add(query_601763, "Engine", newJString(Engine))
  add(query_601763, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_601763, "MaxRecords", newJInt(MaxRecords))
  add(query_601763, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_601763, "Action", newJString(Action))
  add(query_601763, "Marker", newJString(Marker))
  add(query_601763, "EngineVersion", newJString(EngineVersion))
  add(query_601763, "DefaultOnly", newJBool(DefaultOnly))
  add(query_601763, "Version", newJString(Version))
  result = call_601762.call(nil, query_601763, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_601742(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_601743, base: "/",
    url: url_GetDescribeDBEngineVersions_601744,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_601805 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBInstances_601807(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_601806(path: JsonNode; query: JsonNode;
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
  var valid_601808 = query.getOrDefault("Action")
  valid_601808 = validateParameter(valid_601808, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601808 != nil:
    section.add "Action", valid_601808
  var valid_601809 = query.getOrDefault("Version")
  valid_601809 = validateParameter(valid_601809, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601809 != nil:
    section.add "Version", valid_601809
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601810 = header.getOrDefault("X-Amz-Date")
  valid_601810 = validateParameter(valid_601810, JString, required = false,
                                 default = nil)
  if valid_601810 != nil:
    section.add "X-Amz-Date", valid_601810
  var valid_601811 = header.getOrDefault("X-Amz-Security-Token")
  valid_601811 = validateParameter(valid_601811, JString, required = false,
                                 default = nil)
  if valid_601811 != nil:
    section.add "X-Amz-Security-Token", valid_601811
  var valid_601812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601812 = validateParameter(valid_601812, JString, required = false,
                                 default = nil)
  if valid_601812 != nil:
    section.add "X-Amz-Content-Sha256", valid_601812
  var valid_601813 = header.getOrDefault("X-Amz-Algorithm")
  valid_601813 = validateParameter(valid_601813, JString, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "X-Amz-Algorithm", valid_601813
  var valid_601814 = header.getOrDefault("X-Amz-Signature")
  valid_601814 = validateParameter(valid_601814, JString, required = false,
                                 default = nil)
  if valid_601814 != nil:
    section.add "X-Amz-Signature", valid_601814
  var valid_601815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "X-Amz-SignedHeaders", valid_601815
  var valid_601816 = header.getOrDefault("X-Amz-Credential")
  valid_601816 = validateParameter(valid_601816, JString, required = false,
                                 default = nil)
  if valid_601816 != nil:
    section.add "X-Amz-Credential", valid_601816
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601817 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "DBInstanceIdentifier", valid_601817
  var valid_601818 = formData.getOrDefault("Marker")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "Marker", valid_601818
  var valid_601819 = formData.getOrDefault("MaxRecords")
  valid_601819 = validateParameter(valid_601819, JInt, required = false, default = nil)
  if valid_601819 != nil:
    section.add "MaxRecords", valid_601819
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601820: Call_PostDescribeDBInstances_601805; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601820.validator(path, query, header, formData, body)
  let scheme = call_601820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601820.url(scheme.get, call_601820.host, call_601820.base,
                         call_601820.route, valid.getOrDefault("path"))
  result = hook(call_601820, url, valid)

proc call*(call_601821: Call_PostDescribeDBInstances_601805;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601822 = newJObject()
  var formData_601823 = newJObject()
  add(formData_601823, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601823, "Marker", newJString(Marker))
  add(query_601822, "Action", newJString(Action))
  add(formData_601823, "MaxRecords", newJInt(MaxRecords))
  add(query_601822, "Version", newJString(Version))
  result = call_601821.call(nil, query_601822, nil, formData_601823, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_601805(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_601806, base: "/",
    url: url_PostDescribeDBInstances_601807, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_601787 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBInstances_601789(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_601788(path: JsonNode; query: JsonNode;
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
  var valid_601790 = query.getOrDefault("MaxRecords")
  valid_601790 = validateParameter(valid_601790, JInt, required = false, default = nil)
  if valid_601790 != nil:
    section.add "MaxRecords", valid_601790
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601791 = query.getOrDefault("Action")
  valid_601791 = validateParameter(valid_601791, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601791 != nil:
    section.add "Action", valid_601791
  var valid_601792 = query.getOrDefault("Marker")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "Marker", valid_601792
  var valid_601793 = query.getOrDefault("Version")
  valid_601793 = validateParameter(valid_601793, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601793 != nil:
    section.add "Version", valid_601793
  var valid_601794 = query.getOrDefault("DBInstanceIdentifier")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "DBInstanceIdentifier", valid_601794
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601795 = header.getOrDefault("X-Amz-Date")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-Date", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Security-Token")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Security-Token", valid_601796
  var valid_601797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601797 = validateParameter(valid_601797, JString, required = false,
                                 default = nil)
  if valid_601797 != nil:
    section.add "X-Amz-Content-Sha256", valid_601797
  var valid_601798 = header.getOrDefault("X-Amz-Algorithm")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "X-Amz-Algorithm", valid_601798
  var valid_601799 = header.getOrDefault("X-Amz-Signature")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "X-Amz-Signature", valid_601799
  var valid_601800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "X-Amz-SignedHeaders", valid_601800
  var valid_601801 = header.getOrDefault("X-Amz-Credential")
  valid_601801 = validateParameter(valid_601801, JString, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "X-Amz-Credential", valid_601801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601802: Call_GetDescribeDBInstances_601787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601802.validator(path, query, header, formData, body)
  let scheme = call_601802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601802.url(scheme.get, call_601802.host, call_601802.base,
                         call_601802.route, valid.getOrDefault("path"))
  result = hook(call_601802, url, valid)

proc call*(call_601803: Call_GetDescribeDBInstances_601787; MaxRecords: int = 0;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-01-10"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_601804 = newJObject()
  add(query_601804, "MaxRecords", newJInt(MaxRecords))
  add(query_601804, "Action", newJString(Action))
  add(query_601804, "Marker", newJString(Marker))
  add(query_601804, "Version", newJString(Version))
  add(query_601804, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601803.call(nil, query_601804, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_601787(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_601788, base: "/",
    url: url_GetDescribeDBInstances_601789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_601842 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameterGroups_601844(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_601843(path: JsonNode; query: JsonNode;
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
  var valid_601845 = query.getOrDefault("Action")
  valid_601845 = validateParameter(valid_601845, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601845 != nil:
    section.add "Action", valid_601845
  var valid_601846 = query.getOrDefault("Version")
  valid_601846 = validateParameter(valid_601846, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601846 != nil:
    section.add "Version", valid_601846
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601847 = header.getOrDefault("X-Amz-Date")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Date", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Security-Token")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Security-Token", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Content-Sha256", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Algorithm")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Algorithm", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Signature")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Signature", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-SignedHeaders", valid_601852
  var valid_601853 = header.getOrDefault("X-Amz-Credential")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "X-Amz-Credential", valid_601853
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601854 = formData.getOrDefault("DBParameterGroupName")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "DBParameterGroupName", valid_601854
  var valid_601855 = formData.getOrDefault("Marker")
  valid_601855 = validateParameter(valid_601855, JString, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "Marker", valid_601855
  var valid_601856 = formData.getOrDefault("MaxRecords")
  valid_601856 = validateParameter(valid_601856, JInt, required = false, default = nil)
  if valid_601856 != nil:
    section.add "MaxRecords", valid_601856
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601857: Call_PostDescribeDBParameterGroups_601842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601857.validator(path, query, header, formData, body)
  let scheme = call_601857.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601857.url(scheme.get, call_601857.host, call_601857.base,
                         call_601857.route, valid.getOrDefault("path"))
  result = hook(call_601857, url, valid)

proc call*(call_601858: Call_PostDescribeDBParameterGroups_601842;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601859 = newJObject()
  var formData_601860 = newJObject()
  add(formData_601860, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601860, "Marker", newJString(Marker))
  add(query_601859, "Action", newJString(Action))
  add(formData_601860, "MaxRecords", newJInt(MaxRecords))
  add(query_601859, "Version", newJString(Version))
  result = call_601858.call(nil, query_601859, nil, formData_601860, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_601842(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_601843, base: "/",
    url: url_PostDescribeDBParameterGroups_601844,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_601824 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameterGroups_601826(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_601825(path: JsonNode; query: JsonNode;
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
  var valid_601827 = query.getOrDefault("MaxRecords")
  valid_601827 = validateParameter(valid_601827, JInt, required = false, default = nil)
  if valid_601827 != nil:
    section.add "MaxRecords", valid_601827
  var valid_601828 = query.getOrDefault("DBParameterGroupName")
  valid_601828 = validateParameter(valid_601828, JString, required = false,
                                 default = nil)
  if valid_601828 != nil:
    section.add "DBParameterGroupName", valid_601828
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601829 = query.getOrDefault("Action")
  valid_601829 = validateParameter(valid_601829, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601829 != nil:
    section.add "Action", valid_601829
  var valid_601830 = query.getOrDefault("Marker")
  valid_601830 = validateParameter(valid_601830, JString, required = false,
                                 default = nil)
  if valid_601830 != nil:
    section.add "Marker", valid_601830
  var valid_601831 = query.getOrDefault("Version")
  valid_601831 = validateParameter(valid_601831, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601839: Call_GetDescribeDBParameterGroups_601824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601839.validator(path, query, header, formData, body)
  let scheme = call_601839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601839.url(scheme.get, call_601839.host, call_601839.base,
                         call_601839.route, valid.getOrDefault("path"))
  result = hook(call_601839, url, valid)

proc call*(call_601840: Call_GetDescribeDBParameterGroups_601824;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_601841 = newJObject()
  add(query_601841, "MaxRecords", newJInt(MaxRecords))
  add(query_601841, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601841, "Action", newJString(Action))
  add(query_601841, "Marker", newJString(Marker))
  add(query_601841, "Version", newJString(Version))
  result = call_601840.call(nil, query_601841, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_601824(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_601825, base: "/",
    url: url_GetDescribeDBParameterGroups_601826,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_601880 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameters_601882(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_601881(path: JsonNode; query: JsonNode;
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
                                 default = newJString("DescribeDBParameters"))
  if valid_601883 != nil:
    section.add "Action", valid_601883
  var valid_601884 = query.getOrDefault("Version")
  valid_601884 = validateParameter(valid_601884, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601892 = formData.getOrDefault("DBParameterGroupName")
  valid_601892 = validateParameter(valid_601892, JString, required = true,
                                 default = nil)
  if valid_601892 != nil:
    section.add "DBParameterGroupName", valid_601892
  var valid_601893 = formData.getOrDefault("Marker")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "Marker", valid_601893
  var valid_601894 = formData.getOrDefault("MaxRecords")
  valid_601894 = validateParameter(valid_601894, JInt, required = false, default = nil)
  if valid_601894 != nil:
    section.add "MaxRecords", valid_601894
  var valid_601895 = formData.getOrDefault("Source")
  valid_601895 = validateParameter(valid_601895, JString, required = false,
                                 default = nil)
  if valid_601895 != nil:
    section.add "Source", valid_601895
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601896: Call_PostDescribeDBParameters_601880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601896.validator(path, query, header, formData, body)
  let scheme = call_601896.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601896.url(scheme.get, call_601896.host, call_601896.base,
                         call_601896.route, valid.getOrDefault("path"))
  result = hook(call_601896, url, valid)

proc call*(call_601897: Call_PostDescribeDBParameters_601880;
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
  var query_601898 = newJObject()
  var formData_601899 = newJObject()
  add(formData_601899, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601899, "Marker", newJString(Marker))
  add(query_601898, "Action", newJString(Action))
  add(formData_601899, "MaxRecords", newJInt(MaxRecords))
  add(query_601898, "Version", newJString(Version))
  add(formData_601899, "Source", newJString(Source))
  result = call_601897.call(nil, query_601898, nil, formData_601899, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_601880(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_601881, base: "/",
    url: url_PostDescribeDBParameters_601882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_601861 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameters_601863(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_601862(path: JsonNode; query: JsonNode;
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
  var valid_601864 = query.getOrDefault("MaxRecords")
  valid_601864 = validateParameter(valid_601864, JInt, required = false, default = nil)
  if valid_601864 != nil:
    section.add "MaxRecords", valid_601864
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_601865 = query.getOrDefault("DBParameterGroupName")
  valid_601865 = validateParameter(valid_601865, JString, required = true,
                                 default = nil)
  if valid_601865 != nil:
    section.add "DBParameterGroupName", valid_601865
  var valid_601866 = query.getOrDefault("Action")
  valid_601866 = validateParameter(valid_601866, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601866 != nil:
    section.add "Action", valid_601866
  var valid_601867 = query.getOrDefault("Marker")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "Marker", valid_601867
  var valid_601868 = query.getOrDefault("Source")
  valid_601868 = validateParameter(valid_601868, JString, required = false,
                                 default = nil)
  if valid_601868 != nil:
    section.add "Source", valid_601868
  var valid_601869 = query.getOrDefault("Version")
  valid_601869 = validateParameter(valid_601869, JString, required = true,
                                 default = newJString("2013-01-10"))
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

proc call*(call_601877: Call_GetDescribeDBParameters_601861; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601877.validator(path, query, header, formData, body)
  let scheme = call_601877.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601877.url(scheme.get, call_601877.host, call_601877.base,
                         call_601877.route, valid.getOrDefault("path"))
  result = hook(call_601877, url, valid)

proc call*(call_601878: Call_GetDescribeDBParameters_601861;
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
  var query_601879 = newJObject()
  add(query_601879, "MaxRecords", newJInt(MaxRecords))
  add(query_601879, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601879, "Action", newJString(Action))
  add(query_601879, "Marker", newJString(Marker))
  add(query_601879, "Source", newJString(Source))
  add(query_601879, "Version", newJString(Version))
  result = call_601878.call(nil, query_601879, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_601861(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_601862, base: "/",
    url: url_GetDescribeDBParameters_601863, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_601918 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSecurityGroups_601920(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_601919(path: JsonNode; query: JsonNode;
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
  var valid_601921 = query.getOrDefault("Action")
  valid_601921 = validateParameter(valid_601921, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601921 != nil:
    section.add "Action", valid_601921
  var valid_601922 = query.getOrDefault("Version")
  valid_601922 = validateParameter(valid_601922, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601922 != nil:
    section.add "Version", valid_601922
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601923 = header.getOrDefault("X-Amz-Date")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Date", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-Security-Token")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-Security-Token", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Content-Sha256", valid_601925
  var valid_601926 = header.getOrDefault("X-Amz-Algorithm")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "X-Amz-Algorithm", valid_601926
  var valid_601927 = header.getOrDefault("X-Amz-Signature")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "X-Amz-Signature", valid_601927
  var valid_601928 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-SignedHeaders", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-Credential")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-Credential", valid_601929
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601930 = formData.getOrDefault("DBSecurityGroupName")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "DBSecurityGroupName", valid_601930
  var valid_601931 = formData.getOrDefault("Marker")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "Marker", valid_601931
  var valid_601932 = formData.getOrDefault("MaxRecords")
  valid_601932 = validateParameter(valid_601932, JInt, required = false, default = nil)
  if valid_601932 != nil:
    section.add "MaxRecords", valid_601932
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601933: Call_PostDescribeDBSecurityGroups_601918; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601933.validator(path, query, header, formData, body)
  let scheme = call_601933.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601933.url(scheme.get, call_601933.host, call_601933.base,
                         call_601933.route, valid.getOrDefault("path"))
  result = hook(call_601933, url, valid)

proc call*(call_601934: Call_PostDescribeDBSecurityGroups_601918;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601935 = newJObject()
  var formData_601936 = newJObject()
  add(formData_601936, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_601936, "Marker", newJString(Marker))
  add(query_601935, "Action", newJString(Action))
  add(formData_601936, "MaxRecords", newJInt(MaxRecords))
  add(query_601935, "Version", newJString(Version))
  result = call_601934.call(nil, query_601935, nil, formData_601936, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_601918(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_601919, base: "/",
    url: url_PostDescribeDBSecurityGroups_601920,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_601900 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSecurityGroups_601902(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_601901(path: JsonNode; query: JsonNode;
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
  var valid_601903 = query.getOrDefault("MaxRecords")
  valid_601903 = validateParameter(valid_601903, JInt, required = false, default = nil)
  if valid_601903 != nil:
    section.add "MaxRecords", valid_601903
  var valid_601904 = query.getOrDefault("DBSecurityGroupName")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "DBSecurityGroupName", valid_601904
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601905 = query.getOrDefault("Action")
  valid_601905 = validateParameter(valid_601905, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601905 != nil:
    section.add "Action", valid_601905
  var valid_601906 = query.getOrDefault("Marker")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "Marker", valid_601906
  var valid_601907 = query.getOrDefault("Version")
  valid_601907 = validateParameter(valid_601907, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601907 != nil:
    section.add "Version", valid_601907
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601908 = header.getOrDefault("X-Amz-Date")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Date", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-Security-Token")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-Security-Token", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Content-Sha256", valid_601910
  var valid_601911 = header.getOrDefault("X-Amz-Algorithm")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "X-Amz-Algorithm", valid_601911
  var valid_601912 = header.getOrDefault("X-Amz-Signature")
  valid_601912 = validateParameter(valid_601912, JString, required = false,
                                 default = nil)
  if valid_601912 != nil:
    section.add "X-Amz-Signature", valid_601912
  var valid_601913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-SignedHeaders", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Credential")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Credential", valid_601914
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601915: Call_GetDescribeDBSecurityGroups_601900; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601915.validator(path, query, header, formData, body)
  let scheme = call_601915.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601915.url(scheme.get, call_601915.host, call_601915.base,
                         call_601915.route, valid.getOrDefault("path"))
  result = hook(call_601915, url, valid)

proc call*(call_601916: Call_GetDescribeDBSecurityGroups_601900;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_601917 = newJObject()
  add(query_601917, "MaxRecords", newJInt(MaxRecords))
  add(query_601917, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601917, "Action", newJString(Action))
  add(query_601917, "Marker", newJString(Marker))
  add(query_601917, "Version", newJString(Version))
  result = call_601916.call(nil, query_601917, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_601900(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_601901, base: "/",
    url: url_GetDescribeDBSecurityGroups_601902,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_601957 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSnapshots_601959(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_601958(path: JsonNode; query: JsonNode;
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
  var valid_601960 = query.getOrDefault("Action")
  valid_601960 = validateParameter(valid_601960, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_601960 != nil:
    section.add "Action", valid_601960
  var valid_601961 = query.getOrDefault("Version")
  valid_601961 = validateParameter(valid_601961, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601969 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "DBInstanceIdentifier", valid_601969
  var valid_601970 = formData.getOrDefault("SnapshotType")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "SnapshotType", valid_601970
  var valid_601971 = formData.getOrDefault("Marker")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "Marker", valid_601971
  var valid_601972 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "DBSnapshotIdentifier", valid_601972
  var valid_601973 = formData.getOrDefault("MaxRecords")
  valid_601973 = validateParameter(valid_601973, JInt, required = false, default = nil)
  if valid_601973 != nil:
    section.add "MaxRecords", valid_601973
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601974: Call_PostDescribeDBSnapshots_601957; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601974.validator(path, query, header, formData, body)
  let scheme = call_601974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601974.url(scheme.get, call_601974.host, call_601974.base,
                         call_601974.route, valid.getOrDefault("path"))
  result = hook(call_601974, url, valid)

proc call*(call_601975: Call_PostDescribeDBSnapshots_601957;
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
  var query_601976 = newJObject()
  var formData_601977 = newJObject()
  add(formData_601977, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601977, "SnapshotType", newJString(SnapshotType))
  add(formData_601977, "Marker", newJString(Marker))
  add(formData_601977, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601976, "Action", newJString(Action))
  add(formData_601977, "MaxRecords", newJInt(MaxRecords))
  add(query_601976, "Version", newJString(Version))
  result = call_601975.call(nil, query_601976, nil, formData_601977, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_601957(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_601958, base: "/",
    url: url_PostDescribeDBSnapshots_601959, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_601937 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSnapshots_601939(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_601938(path: JsonNode; query: JsonNode;
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
  var valid_601940 = query.getOrDefault("MaxRecords")
  valid_601940 = validateParameter(valid_601940, JInt, required = false, default = nil)
  if valid_601940 != nil:
    section.add "MaxRecords", valid_601940
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601941 = query.getOrDefault("Action")
  valid_601941 = validateParameter(valid_601941, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_601941 != nil:
    section.add "Action", valid_601941
  var valid_601942 = query.getOrDefault("Marker")
  valid_601942 = validateParameter(valid_601942, JString, required = false,
                                 default = nil)
  if valid_601942 != nil:
    section.add "Marker", valid_601942
  var valid_601943 = query.getOrDefault("SnapshotType")
  valid_601943 = validateParameter(valid_601943, JString, required = false,
                                 default = nil)
  if valid_601943 != nil:
    section.add "SnapshotType", valid_601943
  var valid_601944 = query.getOrDefault("Version")
  valid_601944 = validateParameter(valid_601944, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601944 != nil:
    section.add "Version", valid_601944
  var valid_601945 = query.getOrDefault("DBInstanceIdentifier")
  valid_601945 = validateParameter(valid_601945, JString, required = false,
                                 default = nil)
  if valid_601945 != nil:
    section.add "DBInstanceIdentifier", valid_601945
  var valid_601946 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "DBSnapshotIdentifier", valid_601946
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601947 = header.getOrDefault("X-Amz-Date")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "X-Amz-Date", valid_601947
  var valid_601948 = header.getOrDefault("X-Amz-Security-Token")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Security-Token", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Content-Sha256", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Algorithm")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Algorithm", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-Signature")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Signature", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-SignedHeaders", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Credential")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Credential", valid_601953
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601954: Call_GetDescribeDBSnapshots_601937; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601954.validator(path, query, header, formData, body)
  let scheme = call_601954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601954.url(scheme.get, call_601954.host, call_601954.base,
                         call_601954.route, valid.getOrDefault("path"))
  result = hook(call_601954, url, valid)

proc call*(call_601955: Call_GetDescribeDBSnapshots_601937; MaxRecords: int = 0;
          Action: string = "DescribeDBSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2013-01-10";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_601956 = newJObject()
  add(query_601956, "MaxRecords", newJInt(MaxRecords))
  add(query_601956, "Action", newJString(Action))
  add(query_601956, "Marker", newJString(Marker))
  add(query_601956, "SnapshotType", newJString(SnapshotType))
  add(query_601956, "Version", newJString(Version))
  add(query_601956, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601956, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601955.call(nil, query_601956, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_601937(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_601938, base: "/",
    url: url_GetDescribeDBSnapshots_601939, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_601996 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSubnetGroups_601998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_601997(path: JsonNode; query: JsonNode;
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
  var valid_601999 = query.getOrDefault("Action")
  valid_601999 = validateParameter(valid_601999, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_601999 != nil:
    section.add "Action", valid_601999
  var valid_602000 = query.getOrDefault("Version")
  valid_602000 = validateParameter(valid_602000, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602000 != nil:
    section.add "Version", valid_602000
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602001 = header.getOrDefault("X-Amz-Date")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Date", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-Security-Token")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-Security-Token", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Content-Sha256", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Algorithm")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Algorithm", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Signature")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Signature", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-SignedHeaders", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Credential")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Credential", valid_602007
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602008 = formData.getOrDefault("DBSubnetGroupName")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "DBSubnetGroupName", valid_602008
  var valid_602009 = formData.getOrDefault("Marker")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "Marker", valid_602009
  var valid_602010 = formData.getOrDefault("MaxRecords")
  valid_602010 = validateParameter(valid_602010, JInt, required = false, default = nil)
  if valid_602010 != nil:
    section.add "MaxRecords", valid_602010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602011: Call_PostDescribeDBSubnetGroups_601996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602011.validator(path, query, header, formData, body)
  let scheme = call_602011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602011.url(scheme.get, call_602011.host, call_602011.base,
                         call_602011.route, valid.getOrDefault("path"))
  result = hook(call_602011, url, valid)

proc call*(call_602012: Call_PostDescribeDBSubnetGroups_601996;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602013 = newJObject()
  var formData_602014 = newJObject()
  add(formData_602014, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602014, "Marker", newJString(Marker))
  add(query_602013, "Action", newJString(Action))
  add(formData_602014, "MaxRecords", newJInt(MaxRecords))
  add(query_602013, "Version", newJString(Version))
  result = call_602012.call(nil, query_602013, nil, formData_602014, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_601996(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_601997, base: "/",
    url: url_PostDescribeDBSubnetGroups_601998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_601978 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSubnetGroups_601980(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_601979(path: JsonNode; query: JsonNode;
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
  var valid_601981 = query.getOrDefault("MaxRecords")
  valid_601981 = validateParameter(valid_601981, JInt, required = false, default = nil)
  if valid_601981 != nil:
    section.add "MaxRecords", valid_601981
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601982 = query.getOrDefault("Action")
  valid_601982 = validateParameter(valid_601982, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_601982 != nil:
    section.add "Action", valid_601982
  var valid_601983 = query.getOrDefault("Marker")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "Marker", valid_601983
  var valid_601984 = query.getOrDefault("DBSubnetGroupName")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "DBSubnetGroupName", valid_601984
  var valid_601985 = query.getOrDefault("Version")
  valid_601985 = validateParameter(valid_601985, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_601985 != nil:
    section.add "Version", valid_601985
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601986 = header.getOrDefault("X-Amz-Date")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Date", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-Security-Token")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-Security-Token", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Content-Sha256", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Algorithm")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Algorithm", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Signature")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Signature", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-SignedHeaders", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Credential")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Credential", valid_601992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601993: Call_GetDescribeDBSubnetGroups_601978; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601993.validator(path, query, header, formData, body)
  let scheme = call_601993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601993.url(scheme.get, call_601993.host, call_601993.base,
                         call_601993.route, valid.getOrDefault("path"))
  result = hook(call_601993, url, valid)

proc call*(call_601994: Call_GetDescribeDBSubnetGroups_601978; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_601995 = newJObject()
  add(query_601995, "MaxRecords", newJInt(MaxRecords))
  add(query_601995, "Action", newJString(Action))
  add(query_601995, "Marker", newJString(Marker))
  add(query_601995, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601995, "Version", newJString(Version))
  result = call_601994.call(nil, query_601995, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_601978(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_601979, base: "/",
    url: url_GetDescribeDBSubnetGroups_601980,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602033 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEngineDefaultParameters_602035(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_602034(path: JsonNode;
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
  var valid_602036 = query.getOrDefault("Action")
  valid_602036 = validateParameter(valid_602036, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602036 != nil:
    section.add "Action", valid_602036
  var valid_602037 = query.getOrDefault("Version")
  valid_602037 = validateParameter(valid_602037, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602037 != nil:
    section.add "Version", valid_602037
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602038 = header.getOrDefault("X-Amz-Date")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "X-Amz-Date", valid_602038
  var valid_602039 = header.getOrDefault("X-Amz-Security-Token")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Security-Token", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Algorithm")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Algorithm", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Signature")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Signature", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-SignedHeaders", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602045 = formData.getOrDefault("Marker")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "Marker", valid_602045
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602046 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602046 = validateParameter(valid_602046, JString, required = true,
                                 default = nil)
  if valid_602046 != nil:
    section.add "DBParameterGroupFamily", valid_602046
  var valid_602047 = formData.getOrDefault("MaxRecords")
  valid_602047 = validateParameter(valid_602047, JInt, required = false, default = nil)
  if valid_602047 != nil:
    section.add "MaxRecords", valid_602047
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602048: Call_PostDescribeEngineDefaultParameters_602033;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602048.validator(path, query, header, formData, body)
  let scheme = call_602048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602048.url(scheme.get, call_602048.host, call_602048.base,
                         call_602048.route, valid.getOrDefault("path"))
  result = hook(call_602048, url, valid)

proc call*(call_602049: Call_PostDescribeEngineDefaultParameters_602033;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602050 = newJObject()
  var formData_602051 = newJObject()
  add(formData_602051, "Marker", newJString(Marker))
  add(query_602050, "Action", newJString(Action))
  add(formData_602051, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_602051, "MaxRecords", newJInt(MaxRecords))
  add(query_602050, "Version", newJString(Version))
  result = call_602049.call(nil, query_602050, nil, formData_602051, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602033(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602034, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602035,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602015 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEngineDefaultParameters_602017(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_602016(path: JsonNode;
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
  var valid_602018 = query.getOrDefault("MaxRecords")
  valid_602018 = validateParameter(valid_602018, JInt, required = false, default = nil)
  if valid_602018 != nil:
    section.add "MaxRecords", valid_602018
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602019 = query.getOrDefault("DBParameterGroupFamily")
  valid_602019 = validateParameter(valid_602019, JString, required = true,
                                 default = nil)
  if valid_602019 != nil:
    section.add "DBParameterGroupFamily", valid_602019
  var valid_602020 = query.getOrDefault("Action")
  valid_602020 = validateParameter(valid_602020, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602020 != nil:
    section.add "Action", valid_602020
  var valid_602021 = query.getOrDefault("Marker")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "Marker", valid_602021
  var valid_602022 = query.getOrDefault("Version")
  valid_602022 = validateParameter(valid_602022, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602022 != nil:
    section.add "Version", valid_602022
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602023 = header.getOrDefault("X-Amz-Date")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Date", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Security-Token")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Security-Token", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Content-Sha256", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Algorithm")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Algorithm", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Signature")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Signature", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-SignedHeaders", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Credential")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Credential", valid_602029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602030: Call_GetDescribeEngineDefaultParameters_602015;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602030.validator(path, query, header, formData, body)
  let scheme = call_602030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602030.url(scheme.get, call_602030.host, call_602030.base,
                         call_602030.route, valid.getOrDefault("path"))
  result = hook(call_602030, url, valid)

proc call*(call_602031: Call_GetDescribeEngineDefaultParameters_602015;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_602032 = newJObject()
  add(query_602032, "MaxRecords", newJInt(MaxRecords))
  add(query_602032, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602032, "Action", newJString(Action))
  add(query_602032, "Marker", newJString(Marker))
  add(query_602032, "Version", newJString(Version))
  result = call_602031.call(nil, query_602032, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602015(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602016, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602017,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602068 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventCategories_602070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_602069(path: JsonNode; query: JsonNode;
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
  var valid_602071 = query.getOrDefault("Action")
  valid_602071 = validateParameter(valid_602071, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602071 != nil:
    section.add "Action", valid_602071
  var valid_602072 = query.getOrDefault("Version")
  valid_602072 = validateParameter(valid_602072, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602072 != nil:
    section.add "Version", valid_602072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602073 = header.getOrDefault("X-Amz-Date")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-Date", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Security-Token")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Security-Token", valid_602074
  var valid_602075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602075 = validateParameter(valid_602075, JString, required = false,
                                 default = nil)
  if valid_602075 != nil:
    section.add "X-Amz-Content-Sha256", valid_602075
  var valid_602076 = header.getOrDefault("X-Amz-Algorithm")
  valid_602076 = validateParameter(valid_602076, JString, required = false,
                                 default = nil)
  if valid_602076 != nil:
    section.add "X-Amz-Algorithm", valid_602076
  var valid_602077 = header.getOrDefault("X-Amz-Signature")
  valid_602077 = validateParameter(valid_602077, JString, required = false,
                                 default = nil)
  if valid_602077 != nil:
    section.add "X-Amz-Signature", valid_602077
  var valid_602078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602078 = validateParameter(valid_602078, JString, required = false,
                                 default = nil)
  if valid_602078 != nil:
    section.add "X-Amz-SignedHeaders", valid_602078
  var valid_602079 = header.getOrDefault("X-Amz-Credential")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Credential", valid_602079
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_602080 = formData.getOrDefault("SourceType")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "SourceType", valid_602080
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602081: Call_PostDescribeEventCategories_602068; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602081.validator(path, query, header, formData, body)
  let scheme = call_602081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602081.url(scheme.get, call_602081.host, call_602081.base,
                         call_602081.route, valid.getOrDefault("path"))
  result = hook(call_602081, url, valid)

proc call*(call_602082: Call_PostDescribeEventCategories_602068;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_602083 = newJObject()
  var formData_602084 = newJObject()
  add(query_602083, "Action", newJString(Action))
  add(query_602083, "Version", newJString(Version))
  add(formData_602084, "SourceType", newJString(SourceType))
  result = call_602082.call(nil, query_602083, nil, formData_602084, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602068(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602069, base: "/",
    url: url_PostDescribeEventCategories_602070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602052 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventCategories_602054(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_602053(path: JsonNode; query: JsonNode;
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
  var valid_602055 = query.getOrDefault("SourceType")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "SourceType", valid_602055
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602056 = query.getOrDefault("Action")
  valid_602056 = validateParameter(valid_602056, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602056 != nil:
    section.add "Action", valid_602056
  var valid_602057 = query.getOrDefault("Version")
  valid_602057 = validateParameter(valid_602057, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602057 != nil:
    section.add "Version", valid_602057
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602058 = header.getOrDefault("X-Amz-Date")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Date", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Security-Token")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Security-Token", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-Content-Sha256", valid_602060
  var valid_602061 = header.getOrDefault("X-Amz-Algorithm")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "X-Amz-Algorithm", valid_602061
  var valid_602062 = header.getOrDefault("X-Amz-Signature")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "X-Amz-Signature", valid_602062
  var valid_602063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "X-Amz-SignedHeaders", valid_602063
  var valid_602064 = header.getOrDefault("X-Amz-Credential")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Credential", valid_602064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602065: Call_GetDescribeEventCategories_602052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602065.validator(path, query, header, formData, body)
  let scheme = call_602065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602065.url(scheme.get, call_602065.host, call_602065.base,
                         call_602065.route, valid.getOrDefault("path"))
  result = hook(call_602065, url, valid)

proc call*(call_602066: Call_GetDescribeEventCategories_602052;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602067 = newJObject()
  add(query_602067, "SourceType", newJString(SourceType))
  add(query_602067, "Action", newJString(Action))
  add(query_602067, "Version", newJString(Version))
  result = call_602066.call(nil, query_602067, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602052(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602053, base: "/",
    url: url_GetDescribeEventCategories_602054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_602103 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventSubscriptions_602105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_602104(path: JsonNode;
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
  var valid_602106 = query.getOrDefault("Action")
  valid_602106 = validateParameter(valid_602106, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602106 != nil:
    section.add "Action", valid_602106
  var valid_602107 = query.getOrDefault("Version")
  valid_602107 = validateParameter(valid_602107, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602107 != nil:
    section.add "Version", valid_602107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602108 = header.getOrDefault("X-Amz-Date")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-Date", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Security-Token")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Security-Token", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Content-Sha256", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Algorithm")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Algorithm", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Signature")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Signature", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-SignedHeaders", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Credential")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Credential", valid_602114
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602115 = formData.getOrDefault("Marker")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "Marker", valid_602115
  var valid_602116 = formData.getOrDefault("SubscriptionName")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "SubscriptionName", valid_602116
  var valid_602117 = formData.getOrDefault("MaxRecords")
  valid_602117 = validateParameter(valid_602117, JInt, required = false, default = nil)
  if valid_602117 != nil:
    section.add "MaxRecords", valid_602117
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602118: Call_PostDescribeEventSubscriptions_602103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602118.validator(path, query, header, formData, body)
  let scheme = call_602118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602118.url(scheme.get, call_602118.host, call_602118.base,
                         call_602118.route, valid.getOrDefault("path"))
  result = hook(call_602118, url, valid)

proc call*(call_602119: Call_PostDescribeEventSubscriptions_602103;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602120 = newJObject()
  var formData_602121 = newJObject()
  add(formData_602121, "Marker", newJString(Marker))
  add(formData_602121, "SubscriptionName", newJString(SubscriptionName))
  add(query_602120, "Action", newJString(Action))
  add(formData_602121, "MaxRecords", newJInt(MaxRecords))
  add(query_602120, "Version", newJString(Version))
  result = call_602119.call(nil, query_602120, nil, formData_602121, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_602103(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_602104, base: "/",
    url: url_PostDescribeEventSubscriptions_602105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_602085 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventSubscriptions_602087(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_602086(path: JsonNode; query: JsonNode;
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
  var valid_602088 = query.getOrDefault("MaxRecords")
  valid_602088 = validateParameter(valid_602088, JInt, required = false, default = nil)
  if valid_602088 != nil:
    section.add "MaxRecords", valid_602088
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602089 = query.getOrDefault("Action")
  valid_602089 = validateParameter(valid_602089, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602089 != nil:
    section.add "Action", valid_602089
  var valid_602090 = query.getOrDefault("Marker")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "Marker", valid_602090
  var valid_602091 = query.getOrDefault("SubscriptionName")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "SubscriptionName", valid_602091
  var valid_602092 = query.getOrDefault("Version")
  valid_602092 = validateParameter(valid_602092, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602092 != nil:
    section.add "Version", valid_602092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602093 = header.getOrDefault("X-Amz-Date")
  valid_602093 = validateParameter(valid_602093, JString, required = false,
                                 default = nil)
  if valid_602093 != nil:
    section.add "X-Amz-Date", valid_602093
  var valid_602094 = header.getOrDefault("X-Amz-Security-Token")
  valid_602094 = validateParameter(valid_602094, JString, required = false,
                                 default = nil)
  if valid_602094 != nil:
    section.add "X-Amz-Security-Token", valid_602094
  var valid_602095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602095 = validateParameter(valid_602095, JString, required = false,
                                 default = nil)
  if valid_602095 != nil:
    section.add "X-Amz-Content-Sha256", valid_602095
  var valid_602096 = header.getOrDefault("X-Amz-Algorithm")
  valid_602096 = validateParameter(valid_602096, JString, required = false,
                                 default = nil)
  if valid_602096 != nil:
    section.add "X-Amz-Algorithm", valid_602096
  var valid_602097 = header.getOrDefault("X-Amz-Signature")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Signature", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-SignedHeaders", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Credential")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Credential", valid_602099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602100: Call_GetDescribeEventSubscriptions_602085; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602100.validator(path, query, header, formData, body)
  let scheme = call_602100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602100.url(scheme.get, call_602100.host, call_602100.base,
                         call_602100.route, valid.getOrDefault("path"))
  result = hook(call_602100, url, valid)

proc call*(call_602101: Call_GetDescribeEventSubscriptions_602085;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_602102 = newJObject()
  add(query_602102, "MaxRecords", newJInt(MaxRecords))
  add(query_602102, "Action", newJString(Action))
  add(query_602102, "Marker", newJString(Marker))
  add(query_602102, "SubscriptionName", newJString(SubscriptionName))
  add(query_602102, "Version", newJString(Version))
  result = call_602101.call(nil, query_602102, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_602085(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_602086, base: "/",
    url: url_GetDescribeEventSubscriptions_602087,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602145 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEvents_602147(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_602146(path: JsonNode; query: JsonNode;
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
  var valid_602148 = query.getOrDefault("Action")
  valid_602148 = validateParameter(valid_602148, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602148 != nil:
    section.add "Action", valid_602148
  var valid_602149 = query.getOrDefault("Version")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602149 != nil:
    section.add "Version", valid_602149
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602150 = header.getOrDefault("X-Amz-Date")
  valid_602150 = validateParameter(valid_602150, JString, required = false,
                                 default = nil)
  if valid_602150 != nil:
    section.add "X-Amz-Date", valid_602150
  var valid_602151 = header.getOrDefault("X-Amz-Security-Token")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Security-Token", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Content-Sha256", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Algorithm")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Algorithm", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Signature")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Signature", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-SignedHeaders", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Credential")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Credential", valid_602156
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
  var valid_602157 = formData.getOrDefault("SourceIdentifier")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "SourceIdentifier", valid_602157
  var valid_602158 = formData.getOrDefault("EventCategories")
  valid_602158 = validateParameter(valid_602158, JArray, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "EventCategories", valid_602158
  var valid_602159 = formData.getOrDefault("Marker")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "Marker", valid_602159
  var valid_602160 = formData.getOrDefault("StartTime")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "StartTime", valid_602160
  var valid_602161 = formData.getOrDefault("Duration")
  valid_602161 = validateParameter(valid_602161, JInt, required = false, default = nil)
  if valid_602161 != nil:
    section.add "Duration", valid_602161
  var valid_602162 = formData.getOrDefault("EndTime")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "EndTime", valid_602162
  var valid_602163 = formData.getOrDefault("MaxRecords")
  valid_602163 = validateParameter(valid_602163, JInt, required = false, default = nil)
  if valid_602163 != nil:
    section.add "MaxRecords", valid_602163
  var valid_602164 = formData.getOrDefault("SourceType")
  valid_602164 = validateParameter(valid_602164, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602164 != nil:
    section.add "SourceType", valid_602164
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602165: Call_PostDescribeEvents_602145; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602165.validator(path, query, header, formData, body)
  let scheme = call_602165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602165.url(scheme.get, call_602165.host, call_602165.base,
                         call_602165.route, valid.getOrDefault("path"))
  result = hook(call_602165, url, valid)

proc call*(call_602166: Call_PostDescribeEvents_602145;
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
  var query_602167 = newJObject()
  var formData_602168 = newJObject()
  add(formData_602168, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602168.add "EventCategories", EventCategories
  add(formData_602168, "Marker", newJString(Marker))
  add(formData_602168, "StartTime", newJString(StartTime))
  add(query_602167, "Action", newJString(Action))
  add(formData_602168, "Duration", newJInt(Duration))
  add(formData_602168, "EndTime", newJString(EndTime))
  add(formData_602168, "MaxRecords", newJInt(MaxRecords))
  add(query_602167, "Version", newJString(Version))
  add(formData_602168, "SourceType", newJString(SourceType))
  result = call_602166.call(nil, query_602167, nil, formData_602168, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602145(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602146, base: "/",
    url: url_PostDescribeEvents_602147, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602122 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEvents_602124(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_602123(path: JsonNode; query: JsonNode;
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
  var valid_602125 = query.getOrDefault("SourceType")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602125 != nil:
    section.add "SourceType", valid_602125
  var valid_602126 = query.getOrDefault("MaxRecords")
  valid_602126 = validateParameter(valid_602126, JInt, required = false, default = nil)
  if valid_602126 != nil:
    section.add "MaxRecords", valid_602126
  var valid_602127 = query.getOrDefault("StartTime")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "StartTime", valid_602127
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602128 = query.getOrDefault("Action")
  valid_602128 = validateParameter(valid_602128, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602128 != nil:
    section.add "Action", valid_602128
  var valid_602129 = query.getOrDefault("SourceIdentifier")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "SourceIdentifier", valid_602129
  var valid_602130 = query.getOrDefault("Marker")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "Marker", valid_602130
  var valid_602131 = query.getOrDefault("EventCategories")
  valid_602131 = validateParameter(valid_602131, JArray, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "EventCategories", valid_602131
  var valid_602132 = query.getOrDefault("Duration")
  valid_602132 = validateParameter(valid_602132, JInt, required = false, default = nil)
  if valid_602132 != nil:
    section.add "Duration", valid_602132
  var valid_602133 = query.getOrDefault("EndTime")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "EndTime", valid_602133
  var valid_602134 = query.getOrDefault("Version")
  valid_602134 = validateParameter(valid_602134, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602134 != nil:
    section.add "Version", valid_602134
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602135 = header.getOrDefault("X-Amz-Date")
  valid_602135 = validateParameter(valid_602135, JString, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "X-Amz-Date", valid_602135
  var valid_602136 = header.getOrDefault("X-Amz-Security-Token")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Security-Token", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Content-Sha256", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Algorithm")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Algorithm", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Signature")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Signature", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-SignedHeaders", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Credential")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Credential", valid_602141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602142: Call_GetDescribeEvents_602122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602142.validator(path, query, header, formData, body)
  let scheme = call_602142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602142.url(scheme.get, call_602142.host, call_602142.base,
                         call_602142.route, valid.getOrDefault("path"))
  result = hook(call_602142, url, valid)

proc call*(call_602143: Call_GetDescribeEvents_602122;
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
  var query_602144 = newJObject()
  add(query_602144, "SourceType", newJString(SourceType))
  add(query_602144, "MaxRecords", newJInt(MaxRecords))
  add(query_602144, "StartTime", newJString(StartTime))
  add(query_602144, "Action", newJString(Action))
  add(query_602144, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602144, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_602144.add "EventCategories", EventCategories
  add(query_602144, "Duration", newJInt(Duration))
  add(query_602144, "EndTime", newJString(EndTime))
  add(query_602144, "Version", newJString(Version))
  result = call_602143.call(nil, query_602144, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602122(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602123,
    base: "/", url: url_GetDescribeEvents_602124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_602188 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroupOptions_602190(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_602189(path: JsonNode;
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
  var valid_602191 = query.getOrDefault("Action")
  valid_602191 = validateParameter(valid_602191, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602191 != nil:
    section.add "Action", valid_602191
  var valid_602192 = query.getOrDefault("Version")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602192 != nil:
    section.add "Version", valid_602192
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602193 = header.getOrDefault("X-Amz-Date")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Date", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Security-Token")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Security-Token", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Content-Sha256", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Algorithm")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Algorithm", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-Signature")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-Signature", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-SignedHeaders", valid_602198
  var valid_602199 = header.getOrDefault("X-Amz-Credential")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Credential", valid_602199
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602200 = formData.getOrDefault("MajorEngineVersion")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "MajorEngineVersion", valid_602200
  var valid_602201 = formData.getOrDefault("Marker")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "Marker", valid_602201
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_602202 = formData.getOrDefault("EngineName")
  valid_602202 = validateParameter(valid_602202, JString, required = true,
                                 default = nil)
  if valid_602202 != nil:
    section.add "EngineName", valid_602202
  var valid_602203 = formData.getOrDefault("MaxRecords")
  valid_602203 = validateParameter(valid_602203, JInt, required = false, default = nil)
  if valid_602203 != nil:
    section.add "MaxRecords", valid_602203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602204: Call_PostDescribeOptionGroupOptions_602188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602204.validator(path, query, header, formData, body)
  let scheme = call_602204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602204.url(scheme.get, call_602204.host, call_602204.base,
                         call_602204.route, valid.getOrDefault("path"))
  result = hook(call_602204, url, valid)

proc call*(call_602205: Call_PostDescribeOptionGroupOptions_602188;
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
  var query_602206 = newJObject()
  var formData_602207 = newJObject()
  add(formData_602207, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602207, "Marker", newJString(Marker))
  add(query_602206, "Action", newJString(Action))
  add(formData_602207, "EngineName", newJString(EngineName))
  add(formData_602207, "MaxRecords", newJInt(MaxRecords))
  add(query_602206, "Version", newJString(Version))
  result = call_602205.call(nil, query_602206, nil, formData_602207, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_602188(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_602189, base: "/",
    url: url_PostDescribeOptionGroupOptions_602190,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_602169 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroupOptions_602171(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_602170(path: JsonNode; query: JsonNode;
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
  var valid_602172 = query.getOrDefault("MaxRecords")
  valid_602172 = validateParameter(valid_602172, JInt, required = false, default = nil)
  if valid_602172 != nil:
    section.add "MaxRecords", valid_602172
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602173 = query.getOrDefault("Action")
  valid_602173 = validateParameter(valid_602173, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602173 != nil:
    section.add "Action", valid_602173
  var valid_602174 = query.getOrDefault("Marker")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Marker", valid_602174
  var valid_602175 = query.getOrDefault("Version")
  valid_602175 = validateParameter(valid_602175, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602175 != nil:
    section.add "Version", valid_602175
  var valid_602176 = query.getOrDefault("EngineName")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = nil)
  if valid_602176 != nil:
    section.add "EngineName", valid_602176
  var valid_602177 = query.getOrDefault("MajorEngineVersion")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "MajorEngineVersion", valid_602177
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602178 = header.getOrDefault("X-Amz-Date")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Date", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Security-Token")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Security-Token", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Content-Sha256", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Algorithm")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Algorithm", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-Signature")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-Signature", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-SignedHeaders", valid_602183
  var valid_602184 = header.getOrDefault("X-Amz-Credential")
  valid_602184 = validateParameter(valid_602184, JString, required = false,
                                 default = nil)
  if valid_602184 != nil:
    section.add "X-Amz-Credential", valid_602184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602185: Call_GetDescribeOptionGroupOptions_602169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"))
  result = hook(call_602185, url, valid)

proc call*(call_602186: Call_GetDescribeOptionGroupOptions_602169;
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
  var query_602187 = newJObject()
  add(query_602187, "MaxRecords", newJInt(MaxRecords))
  add(query_602187, "Action", newJString(Action))
  add(query_602187, "Marker", newJString(Marker))
  add(query_602187, "Version", newJString(Version))
  add(query_602187, "EngineName", newJString(EngineName))
  add(query_602187, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602186.call(nil, query_602187, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_602169(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_602170, base: "/",
    url: url_GetDescribeOptionGroupOptions_602171,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_602228 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroups_602230(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_602229(path: JsonNode; query: JsonNode;
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
  var valid_602231 = query.getOrDefault("Action")
  valid_602231 = validateParameter(valid_602231, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602231 != nil:
    section.add "Action", valid_602231
  var valid_602232 = query.getOrDefault("Version")
  valid_602232 = validateParameter(valid_602232, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602232 != nil:
    section.add "Version", valid_602232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602233 = header.getOrDefault("X-Amz-Date")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Date", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Security-Token")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Security-Token", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Content-Sha256", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-Algorithm")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Algorithm", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Signature")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Signature", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-SignedHeaders", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Credential")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Credential", valid_602239
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602240 = formData.getOrDefault("MajorEngineVersion")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "MajorEngineVersion", valid_602240
  var valid_602241 = formData.getOrDefault("OptionGroupName")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "OptionGroupName", valid_602241
  var valid_602242 = formData.getOrDefault("Marker")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "Marker", valid_602242
  var valid_602243 = formData.getOrDefault("EngineName")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "EngineName", valid_602243
  var valid_602244 = formData.getOrDefault("MaxRecords")
  valid_602244 = validateParameter(valid_602244, JInt, required = false, default = nil)
  if valid_602244 != nil:
    section.add "MaxRecords", valid_602244
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602245: Call_PostDescribeOptionGroups_602228; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602245.validator(path, query, header, formData, body)
  let scheme = call_602245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602245.url(scheme.get, call_602245.host, call_602245.base,
                         call_602245.route, valid.getOrDefault("path"))
  result = hook(call_602245, url, valid)

proc call*(call_602246: Call_PostDescribeOptionGroups_602228;
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
  var query_602247 = newJObject()
  var formData_602248 = newJObject()
  add(formData_602248, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602248, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602248, "Marker", newJString(Marker))
  add(query_602247, "Action", newJString(Action))
  add(formData_602248, "EngineName", newJString(EngineName))
  add(formData_602248, "MaxRecords", newJInt(MaxRecords))
  add(query_602247, "Version", newJString(Version))
  result = call_602246.call(nil, query_602247, nil, formData_602248, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_602228(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_602229, base: "/",
    url: url_PostDescribeOptionGroups_602230, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_602208 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroups_602210(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_602209(path: JsonNode; query: JsonNode;
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
  var valid_602211 = query.getOrDefault("MaxRecords")
  valid_602211 = validateParameter(valid_602211, JInt, required = false, default = nil)
  if valid_602211 != nil:
    section.add "MaxRecords", valid_602211
  var valid_602212 = query.getOrDefault("OptionGroupName")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "OptionGroupName", valid_602212
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602213 = query.getOrDefault("Action")
  valid_602213 = validateParameter(valid_602213, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602213 != nil:
    section.add "Action", valid_602213
  var valid_602214 = query.getOrDefault("Marker")
  valid_602214 = validateParameter(valid_602214, JString, required = false,
                                 default = nil)
  if valid_602214 != nil:
    section.add "Marker", valid_602214
  var valid_602215 = query.getOrDefault("Version")
  valid_602215 = validateParameter(valid_602215, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602215 != nil:
    section.add "Version", valid_602215
  var valid_602216 = query.getOrDefault("EngineName")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "EngineName", valid_602216
  var valid_602217 = query.getOrDefault("MajorEngineVersion")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "MajorEngineVersion", valid_602217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602218 = header.getOrDefault("X-Amz-Date")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Date", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Security-Token")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Security-Token", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Content-Sha256", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-Algorithm")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Algorithm", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Signature")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Signature", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-SignedHeaders", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Credential")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Credential", valid_602224
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602225: Call_GetDescribeOptionGroups_602208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602225.validator(path, query, header, formData, body)
  let scheme = call_602225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602225.url(scheme.get, call_602225.host, call_602225.base,
                         call_602225.route, valid.getOrDefault("path"))
  result = hook(call_602225, url, valid)

proc call*(call_602226: Call_GetDescribeOptionGroups_602208; MaxRecords: int = 0;
          OptionGroupName: string = ""; Action: string = "DescribeOptionGroups";
          Marker: string = ""; Version: string = "2013-01-10"; EngineName: string = "";
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_602227 = newJObject()
  add(query_602227, "MaxRecords", newJInt(MaxRecords))
  add(query_602227, "OptionGroupName", newJString(OptionGroupName))
  add(query_602227, "Action", newJString(Action))
  add(query_602227, "Marker", newJString(Marker))
  add(query_602227, "Version", newJString(Version))
  add(query_602227, "EngineName", newJString(EngineName))
  add(query_602227, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602226.call(nil, query_602227, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_602208(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_602209, base: "/",
    url: url_GetDescribeOptionGroups_602210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602271 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOrderableDBInstanceOptions_602273(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602272(path: JsonNode;
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
  var valid_602274 = query.getOrDefault("Action")
  valid_602274 = validateParameter(valid_602274, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602274 != nil:
    section.add "Action", valid_602274
  var valid_602275 = query.getOrDefault("Version")
  valid_602275 = validateParameter(valid_602275, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602275 != nil:
    section.add "Version", valid_602275
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602276 = header.getOrDefault("X-Amz-Date")
  valid_602276 = validateParameter(valid_602276, JString, required = false,
                                 default = nil)
  if valid_602276 != nil:
    section.add "X-Amz-Date", valid_602276
  var valid_602277 = header.getOrDefault("X-Amz-Security-Token")
  valid_602277 = validateParameter(valid_602277, JString, required = false,
                                 default = nil)
  if valid_602277 != nil:
    section.add "X-Amz-Security-Token", valid_602277
  var valid_602278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Content-Sha256", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Algorithm")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Algorithm", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Signature")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Signature", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-SignedHeaders", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Credential")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Credential", valid_602282
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
  var valid_602283 = formData.getOrDefault("Engine")
  valid_602283 = validateParameter(valid_602283, JString, required = true,
                                 default = nil)
  if valid_602283 != nil:
    section.add "Engine", valid_602283
  var valid_602284 = formData.getOrDefault("Marker")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "Marker", valid_602284
  var valid_602285 = formData.getOrDefault("Vpc")
  valid_602285 = validateParameter(valid_602285, JBool, required = false, default = nil)
  if valid_602285 != nil:
    section.add "Vpc", valid_602285
  var valid_602286 = formData.getOrDefault("DBInstanceClass")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "DBInstanceClass", valid_602286
  var valid_602287 = formData.getOrDefault("LicenseModel")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "LicenseModel", valid_602287
  var valid_602288 = formData.getOrDefault("MaxRecords")
  valid_602288 = validateParameter(valid_602288, JInt, required = false, default = nil)
  if valid_602288 != nil:
    section.add "MaxRecords", valid_602288
  var valid_602289 = formData.getOrDefault("EngineVersion")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "EngineVersion", valid_602289
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602290: Call_PostDescribeOrderableDBInstanceOptions_602271;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602290.validator(path, query, header, formData, body)
  let scheme = call_602290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602290.url(scheme.get, call_602290.host, call_602290.base,
                         call_602290.route, valid.getOrDefault("path"))
  result = hook(call_602290, url, valid)

proc call*(call_602291: Call_PostDescribeOrderableDBInstanceOptions_602271;
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
  var query_602292 = newJObject()
  var formData_602293 = newJObject()
  add(formData_602293, "Engine", newJString(Engine))
  add(formData_602293, "Marker", newJString(Marker))
  add(query_602292, "Action", newJString(Action))
  add(formData_602293, "Vpc", newJBool(Vpc))
  add(formData_602293, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602293, "LicenseModel", newJString(LicenseModel))
  add(formData_602293, "MaxRecords", newJInt(MaxRecords))
  add(formData_602293, "EngineVersion", newJString(EngineVersion))
  add(query_602292, "Version", newJString(Version))
  result = call_602291.call(nil, query_602292, nil, formData_602293, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602271(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602272, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602249 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOrderableDBInstanceOptions_602251(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602250(path: JsonNode;
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
  var valid_602252 = query.getOrDefault("Engine")
  valid_602252 = validateParameter(valid_602252, JString, required = true,
                                 default = nil)
  if valid_602252 != nil:
    section.add "Engine", valid_602252
  var valid_602253 = query.getOrDefault("MaxRecords")
  valid_602253 = validateParameter(valid_602253, JInt, required = false, default = nil)
  if valid_602253 != nil:
    section.add "MaxRecords", valid_602253
  var valid_602254 = query.getOrDefault("LicenseModel")
  valid_602254 = validateParameter(valid_602254, JString, required = false,
                                 default = nil)
  if valid_602254 != nil:
    section.add "LicenseModel", valid_602254
  var valid_602255 = query.getOrDefault("Vpc")
  valid_602255 = validateParameter(valid_602255, JBool, required = false, default = nil)
  if valid_602255 != nil:
    section.add "Vpc", valid_602255
  var valid_602256 = query.getOrDefault("DBInstanceClass")
  valid_602256 = validateParameter(valid_602256, JString, required = false,
                                 default = nil)
  if valid_602256 != nil:
    section.add "DBInstanceClass", valid_602256
  var valid_602257 = query.getOrDefault("Action")
  valid_602257 = validateParameter(valid_602257, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602257 != nil:
    section.add "Action", valid_602257
  var valid_602258 = query.getOrDefault("Marker")
  valid_602258 = validateParameter(valid_602258, JString, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "Marker", valid_602258
  var valid_602259 = query.getOrDefault("EngineVersion")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "EngineVersion", valid_602259
  var valid_602260 = query.getOrDefault("Version")
  valid_602260 = validateParameter(valid_602260, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602260 != nil:
    section.add "Version", valid_602260
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602261 = header.getOrDefault("X-Amz-Date")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "X-Amz-Date", valid_602261
  var valid_602262 = header.getOrDefault("X-Amz-Security-Token")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "X-Amz-Security-Token", valid_602262
  var valid_602263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Content-Sha256", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Algorithm")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Algorithm", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Signature")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Signature", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-SignedHeaders", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Credential")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Credential", valid_602267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602268: Call_GetDescribeOrderableDBInstanceOptions_602249;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602268.validator(path, query, header, formData, body)
  let scheme = call_602268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602268.url(scheme.get, call_602268.host, call_602268.base,
                         call_602268.route, valid.getOrDefault("path"))
  result = hook(call_602268, url, valid)

proc call*(call_602269: Call_GetDescribeOrderableDBInstanceOptions_602249;
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
  var query_602270 = newJObject()
  add(query_602270, "Engine", newJString(Engine))
  add(query_602270, "MaxRecords", newJInt(MaxRecords))
  add(query_602270, "LicenseModel", newJString(LicenseModel))
  add(query_602270, "Vpc", newJBool(Vpc))
  add(query_602270, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602270, "Action", newJString(Action))
  add(query_602270, "Marker", newJString(Marker))
  add(query_602270, "EngineVersion", newJString(EngineVersion))
  add(query_602270, "Version", newJString(Version))
  result = call_602269.call(nil, query_602270, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602249(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602250, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_602318 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstances_602320(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_602319(path: JsonNode;
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
  var valid_602321 = query.getOrDefault("Action")
  valid_602321 = validateParameter(valid_602321, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602321 != nil:
    section.add "Action", valid_602321
  var valid_602322 = query.getOrDefault("Version")
  valid_602322 = validateParameter(valid_602322, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602322 != nil:
    section.add "Version", valid_602322
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602323 = header.getOrDefault("X-Amz-Date")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Date", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Security-Token")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Security-Token", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Content-Sha256", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Algorithm")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Algorithm", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-Signature")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-Signature", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-SignedHeaders", valid_602328
  var valid_602329 = header.getOrDefault("X-Amz-Credential")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "X-Amz-Credential", valid_602329
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
  var valid_602330 = formData.getOrDefault("OfferingType")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "OfferingType", valid_602330
  var valid_602331 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "ReservedDBInstanceId", valid_602331
  var valid_602332 = formData.getOrDefault("Marker")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "Marker", valid_602332
  var valid_602333 = formData.getOrDefault("MultiAZ")
  valid_602333 = validateParameter(valid_602333, JBool, required = false, default = nil)
  if valid_602333 != nil:
    section.add "MultiAZ", valid_602333
  var valid_602334 = formData.getOrDefault("Duration")
  valid_602334 = validateParameter(valid_602334, JString, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "Duration", valid_602334
  var valid_602335 = formData.getOrDefault("DBInstanceClass")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "DBInstanceClass", valid_602335
  var valid_602336 = formData.getOrDefault("ProductDescription")
  valid_602336 = validateParameter(valid_602336, JString, required = false,
                                 default = nil)
  if valid_602336 != nil:
    section.add "ProductDescription", valid_602336
  var valid_602337 = formData.getOrDefault("MaxRecords")
  valid_602337 = validateParameter(valid_602337, JInt, required = false, default = nil)
  if valid_602337 != nil:
    section.add "MaxRecords", valid_602337
  var valid_602338 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602338 = validateParameter(valid_602338, JString, required = false,
                                 default = nil)
  if valid_602338 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602338
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602339: Call_PostDescribeReservedDBInstances_602318;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602339.validator(path, query, header, formData, body)
  let scheme = call_602339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602339.url(scheme.get, call_602339.host, call_602339.base,
                         call_602339.route, valid.getOrDefault("path"))
  result = hook(call_602339, url, valid)

proc call*(call_602340: Call_PostDescribeReservedDBInstances_602318;
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
  var query_602341 = newJObject()
  var formData_602342 = newJObject()
  add(formData_602342, "OfferingType", newJString(OfferingType))
  add(formData_602342, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602342, "Marker", newJString(Marker))
  add(formData_602342, "MultiAZ", newJBool(MultiAZ))
  add(query_602341, "Action", newJString(Action))
  add(formData_602342, "Duration", newJString(Duration))
  add(formData_602342, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602342, "ProductDescription", newJString(ProductDescription))
  add(formData_602342, "MaxRecords", newJInt(MaxRecords))
  add(formData_602342, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602341, "Version", newJString(Version))
  result = call_602340.call(nil, query_602341, nil, formData_602342, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_602318(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_602319, base: "/",
    url: url_PostDescribeReservedDBInstances_602320,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_602294 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstances_602296(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_602295(path: JsonNode;
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
  var valid_602297 = query.getOrDefault("ProductDescription")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "ProductDescription", valid_602297
  var valid_602298 = query.getOrDefault("MaxRecords")
  valid_602298 = validateParameter(valid_602298, JInt, required = false, default = nil)
  if valid_602298 != nil:
    section.add "MaxRecords", valid_602298
  var valid_602299 = query.getOrDefault("OfferingType")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "OfferingType", valid_602299
  var valid_602300 = query.getOrDefault("MultiAZ")
  valid_602300 = validateParameter(valid_602300, JBool, required = false, default = nil)
  if valid_602300 != nil:
    section.add "MultiAZ", valid_602300
  var valid_602301 = query.getOrDefault("ReservedDBInstanceId")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "ReservedDBInstanceId", valid_602301
  var valid_602302 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602302
  var valid_602303 = query.getOrDefault("DBInstanceClass")
  valid_602303 = validateParameter(valid_602303, JString, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "DBInstanceClass", valid_602303
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602304 = query.getOrDefault("Action")
  valid_602304 = validateParameter(valid_602304, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602304 != nil:
    section.add "Action", valid_602304
  var valid_602305 = query.getOrDefault("Marker")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "Marker", valid_602305
  var valid_602306 = query.getOrDefault("Duration")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "Duration", valid_602306
  var valid_602307 = query.getOrDefault("Version")
  valid_602307 = validateParameter(valid_602307, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602307 != nil:
    section.add "Version", valid_602307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602308 = header.getOrDefault("X-Amz-Date")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Date", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Security-Token")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Security-Token", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Content-Sha256", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Algorithm")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Algorithm", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-Signature")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-Signature", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-SignedHeaders", valid_602313
  var valid_602314 = header.getOrDefault("X-Amz-Credential")
  valid_602314 = validateParameter(valid_602314, JString, required = false,
                                 default = nil)
  if valid_602314 != nil:
    section.add "X-Amz-Credential", valid_602314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602315: Call_GetDescribeReservedDBInstances_602294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602315.validator(path, query, header, formData, body)
  let scheme = call_602315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602315.url(scheme.get, call_602315.host, call_602315.base,
                         call_602315.route, valid.getOrDefault("path"))
  result = hook(call_602315, url, valid)

proc call*(call_602316: Call_GetDescribeReservedDBInstances_602294;
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
  var query_602317 = newJObject()
  add(query_602317, "ProductDescription", newJString(ProductDescription))
  add(query_602317, "MaxRecords", newJInt(MaxRecords))
  add(query_602317, "OfferingType", newJString(OfferingType))
  add(query_602317, "MultiAZ", newJBool(MultiAZ))
  add(query_602317, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602317, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602317, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602317, "Action", newJString(Action))
  add(query_602317, "Marker", newJString(Marker))
  add(query_602317, "Duration", newJString(Duration))
  add(query_602317, "Version", newJString(Version))
  result = call_602316.call(nil, query_602317, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_602294(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_602295, base: "/",
    url: url_GetDescribeReservedDBInstances_602296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_602366 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstancesOfferings_602368(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_602367(path: JsonNode;
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
  var valid_602369 = query.getOrDefault("Action")
  valid_602369 = validateParameter(valid_602369, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602369 != nil:
    section.add "Action", valid_602369
  var valid_602370 = query.getOrDefault("Version")
  valid_602370 = validateParameter(valid_602370, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602370 != nil:
    section.add "Version", valid_602370
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602371 = header.getOrDefault("X-Amz-Date")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Date", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Security-Token")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Security-Token", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Content-Sha256", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Algorithm")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Algorithm", valid_602374
  var valid_602375 = header.getOrDefault("X-Amz-Signature")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "X-Amz-Signature", valid_602375
  var valid_602376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "X-Amz-SignedHeaders", valid_602376
  var valid_602377 = header.getOrDefault("X-Amz-Credential")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "X-Amz-Credential", valid_602377
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
  var valid_602378 = formData.getOrDefault("OfferingType")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "OfferingType", valid_602378
  var valid_602379 = formData.getOrDefault("Marker")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "Marker", valid_602379
  var valid_602380 = formData.getOrDefault("MultiAZ")
  valid_602380 = validateParameter(valid_602380, JBool, required = false, default = nil)
  if valid_602380 != nil:
    section.add "MultiAZ", valid_602380
  var valid_602381 = formData.getOrDefault("Duration")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "Duration", valid_602381
  var valid_602382 = formData.getOrDefault("DBInstanceClass")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "DBInstanceClass", valid_602382
  var valid_602383 = formData.getOrDefault("ProductDescription")
  valid_602383 = validateParameter(valid_602383, JString, required = false,
                                 default = nil)
  if valid_602383 != nil:
    section.add "ProductDescription", valid_602383
  var valid_602384 = formData.getOrDefault("MaxRecords")
  valid_602384 = validateParameter(valid_602384, JInt, required = false, default = nil)
  if valid_602384 != nil:
    section.add "MaxRecords", valid_602384
  var valid_602385 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602385 = validateParameter(valid_602385, JString, required = false,
                                 default = nil)
  if valid_602385 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602385
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602386: Call_PostDescribeReservedDBInstancesOfferings_602366;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602386.validator(path, query, header, formData, body)
  let scheme = call_602386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602386.url(scheme.get, call_602386.host, call_602386.base,
                         call_602386.route, valid.getOrDefault("path"))
  result = hook(call_602386, url, valid)

proc call*(call_602387: Call_PostDescribeReservedDBInstancesOfferings_602366;
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
  var query_602388 = newJObject()
  var formData_602389 = newJObject()
  add(formData_602389, "OfferingType", newJString(OfferingType))
  add(formData_602389, "Marker", newJString(Marker))
  add(formData_602389, "MultiAZ", newJBool(MultiAZ))
  add(query_602388, "Action", newJString(Action))
  add(formData_602389, "Duration", newJString(Duration))
  add(formData_602389, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602389, "ProductDescription", newJString(ProductDescription))
  add(formData_602389, "MaxRecords", newJInt(MaxRecords))
  add(formData_602389, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602388, "Version", newJString(Version))
  result = call_602387.call(nil, query_602388, nil, formData_602389, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_602366(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_602367,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_602368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_602343 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstancesOfferings_602345(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_602344(path: JsonNode;
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
  var valid_602346 = query.getOrDefault("ProductDescription")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "ProductDescription", valid_602346
  var valid_602347 = query.getOrDefault("MaxRecords")
  valid_602347 = validateParameter(valid_602347, JInt, required = false, default = nil)
  if valid_602347 != nil:
    section.add "MaxRecords", valid_602347
  var valid_602348 = query.getOrDefault("OfferingType")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "OfferingType", valid_602348
  var valid_602349 = query.getOrDefault("MultiAZ")
  valid_602349 = validateParameter(valid_602349, JBool, required = false, default = nil)
  if valid_602349 != nil:
    section.add "MultiAZ", valid_602349
  var valid_602350 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602350
  var valid_602351 = query.getOrDefault("DBInstanceClass")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "DBInstanceClass", valid_602351
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602352 = query.getOrDefault("Action")
  valid_602352 = validateParameter(valid_602352, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602352 != nil:
    section.add "Action", valid_602352
  var valid_602353 = query.getOrDefault("Marker")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "Marker", valid_602353
  var valid_602354 = query.getOrDefault("Duration")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "Duration", valid_602354
  var valid_602355 = query.getOrDefault("Version")
  valid_602355 = validateParameter(valid_602355, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602355 != nil:
    section.add "Version", valid_602355
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602356 = header.getOrDefault("X-Amz-Date")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Date", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Security-Token")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Security-Token", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Content-Sha256", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Algorithm")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Algorithm", valid_602359
  var valid_602360 = header.getOrDefault("X-Amz-Signature")
  valid_602360 = validateParameter(valid_602360, JString, required = false,
                                 default = nil)
  if valid_602360 != nil:
    section.add "X-Amz-Signature", valid_602360
  var valid_602361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602361 = validateParameter(valid_602361, JString, required = false,
                                 default = nil)
  if valid_602361 != nil:
    section.add "X-Amz-SignedHeaders", valid_602361
  var valid_602362 = header.getOrDefault("X-Amz-Credential")
  valid_602362 = validateParameter(valid_602362, JString, required = false,
                                 default = nil)
  if valid_602362 != nil:
    section.add "X-Amz-Credential", valid_602362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602363: Call_GetDescribeReservedDBInstancesOfferings_602343;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602363.validator(path, query, header, formData, body)
  let scheme = call_602363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602363.url(scheme.get, call_602363.host, call_602363.base,
                         call_602363.route, valid.getOrDefault("path"))
  result = hook(call_602363, url, valid)

proc call*(call_602364: Call_GetDescribeReservedDBInstancesOfferings_602343;
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
  var query_602365 = newJObject()
  add(query_602365, "ProductDescription", newJString(ProductDescription))
  add(query_602365, "MaxRecords", newJInt(MaxRecords))
  add(query_602365, "OfferingType", newJString(OfferingType))
  add(query_602365, "MultiAZ", newJBool(MultiAZ))
  add(query_602365, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602365, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602365, "Action", newJString(Action))
  add(query_602365, "Marker", newJString(Marker))
  add(query_602365, "Duration", newJString(Duration))
  add(query_602365, "Version", newJString(Version))
  result = call_602364.call(nil, query_602365, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_602343(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_602344, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_602345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602406 = ref object of OpenApiRestCall_600410
proc url_PostListTagsForResource_602408(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_602407(path: JsonNode; query: JsonNode;
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
  var valid_602409 = query.getOrDefault("Action")
  valid_602409 = validateParameter(valid_602409, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602409 != nil:
    section.add "Action", valid_602409
  var valid_602410 = query.getOrDefault("Version")
  valid_602410 = validateParameter(valid_602410, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602410 != nil:
    section.add "Version", valid_602410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602411 = header.getOrDefault("X-Amz-Date")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Date", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Security-Token")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Security-Token", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Content-Sha256", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-Algorithm")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Algorithm", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Signature")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Signature", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-SignedHeaders", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Credential")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Credential", valid_602417
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602418 = formData.getOrDefault("ResourceName")
  valid_602418 = validateParameter(valid_602418, JString, required = true,
                                 default = nil)
  if valid_602418 != nil:
    section.add "ResourceName", valid_602418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602419: Call_PostListTagsForResource_602406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602419.validator(path, query, header, formData, body)
  let scheme = call_602419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602419.url(scheme.get, call_602419.host, call_602419.base,
                         call_602419.route, valid.getOrDefault("path"))
  result = hook(call_602419, url, valid)

proc call*(call_602420: Call_PostListTagsForResource_602406; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602421 = newJObject()
  var formData_602422 = newJObject()
  add(query_602421, "Action", newJString(Action))
  add(formData_602422, "ResourceName", newJString(ResourceName))
  add(query_602421, "Version", newJString(Version))
  result = call_602420.call(nil, query_602421, nil, formData_602422, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602406(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602407, base: "/",
    url: url_PostListTagsForResource_602408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602390 = ref object of OpenApiRestCall_600410
proc url_GetListTagsForResource_602392(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_602391(path: JsonNode; query: JsonNode;
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
  var valid_602393 = query.getOrDefault("ResourceName")
  valid_602393 = validateParameter(valid_602393, JString, required = true,
                                 default = nil)
  if valid_602393 != nil:
    section.add "ResourceName", valid_602393
  var valid_602394 = query.getOrDefault("Action")
  valid_602394 = validateParameter(valid_602394, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602394 != nil:
    section.add "Action", valid_602394
  var valid_602395 = query.getOrDefault("Version")
  valid_602395 = validateParameter(valid_602395, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602395 != nil:
    section.add "Version", valid_602395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602396 = header.getOrDefault("X-Amz-Date")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Date", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Security-Token")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Security-Token", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Content-Sha256", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-Algorithm")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Algorithm", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Signature")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Signature", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-SignedHeaders", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Credential")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Credential", valid_602402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602403: Call_GetListTagsForResource_602390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602403.validator(path, query, header, formData, body)
  let scheme = call_602403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602403.url(scheme.get, call_602403.host, call_602403.base,
                         call_602403.route, valid.getOrDefault("path"))
  result = hook(call_602403, url, valid)

proc call*(call_602404: Call_GetListTagsForResource_602390; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602405 = newJObject()
  add(query_602405, "ResourceName", newJString(ResourceName))
  add(query_602405, "Action", newJString(Action))
  add(query_602405, "Version", newJString(Version))
  result = call_602404.call(nil, query_602405, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602390(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602391, base: "/",
    url: url_GetListTagsForResource_602392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602456 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBInstance_602458(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_602457(path: JsonNode; query: JsonNode;
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
  var valid_602459 = query.getOrDefault("Action")
  valid_602459 = validateParameter(valid_602459, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602459 != nil:
    section.add "Action", valid_602459
  var valid_602460 = query.getOrDefault("Version")
  valid_602460 = validateParameter(valid_602460, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602460 != nil:
    section.add "Version", valid_602460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602461 = header.getOrDefault("X-Amz-Date")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Date", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-Security-Token")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-Security-Token", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Content-Sha256", valid_602463
  var valid_602464 = header.getOrDefault("X-Amz-Algorithm")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "X-Amz-Algorithm", valid_602464
  var valid_602465 = header.getOrDefault("X-Amz-Signature")
  valid_602465 = validateParameter(valid_602465, JString, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "X-Amz-Signature", valid_602465
  var valid_602466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "X-Amz-SignedHeaders", valid_602466
  var valid_602467 = header.getOrDefault("X-Amz-Credential")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Credential", valid_602467
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
  var valid_602468 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "PreferredMaintenanceWindow", valid_602468
  var valid_602469 = formData.getOrDefault("DBSecurityGroups")
  valid_602469 = validateParameter(valid_602469, JArray, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "DBSecurityGroups", valid_602469
  var valid_602470 = formData.getOrDefault("ApplyImmediately")
  valid_602470 = validateParameter(valid_602470, JBool, required = false, default = nil)
  if valid_602470 != nil:
    section.add "ApplyImmediately", valid_602470
  var valid_602471 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602471 = validateParameter(valid_602471, JArray, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "VpcSecurityGroupIds", valid_602471
  var valid_602472 = formData.getOrDefault("Iops")
  valid_602472 = validateParameter(valid_602472, JInt, required = false, default = nil)
  if valid_602472 != nil:
    section.add "Iops", valid_602472
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602473 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602473 = validateParameter(valid_602473, JString, required = true,
                                 default = nil)
  if valid_602473 != nil:
    section.add "DBInstanceIdentifier", valid_602473
  var valid_602474 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602474 = validateParameter(valid_602474, JInt, required = false, default = nil)
  if valid_602474 != nil:
    section.add "BackupRetentionPeriod", valid_602474
  var valid_602475 = formData.getOrDefault("DBParameterGroupName")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "DBParameterGroupName", valid_602475
  var valid_602476 = formData.getOrDefault("OptionGroupName")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "OptionGroupName", valid_602476
  var valid_602477 = formData.getOrDefault("MasterUserPassword")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "MasterUserPassword", valid_602477
  var valid_602478 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "NewDBInstanceIdentifier", valid_602478
  var valid_602479 = formData.getOrDefault("MultiAZ")
  valid_602479 = validateParameter(valid_602479, JBool, required = false, default = nil)
  if valid_602479 != nil:
    section.add "MultiAZ", valid_602479
  var valid_602480 = formData.getOrDefault("AllocatedStorage")
  valid_602480 = validateParameter(valid_602480, JInt, required = false, default = nil)
  if valid_602480 != nil:
    section.add "AllocatedStorage", valid_602480
  var valid_602481 = formData.getOrDefault("DBInstanceClass")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "DBInstanceClass", valid_602481
  var valid_602482 = formData.getOrDefault("PreferredBackupWindow")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "PreferredBackupWindow", valid_602482
  var valid_602483 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602483 = validateParameter(valid_602483, JBool, required = false, default = nil)
  if valid_602483 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602483
  var valid_602484 = formData.getOrDefault("EngineVersion")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "EngineVersion", valid_602484
  var valid_602485 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_602485 = validateParameter(valid_602485, JBool, required = false, default = nil)
  if valid_602485 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602485
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602486: Call_PostModifyDBInstance_602456; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602486.validator(path, query, header, formData, body)
  let scheme = call_602486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602486.url(scheme.get, call_602486.host, call_602486.base,
                         call_602486.route, valid.getOrDefault("path"))
  result = hook(call_602486, url, valid)

proc call*(call_602487: Call_PostModifyDBInstance_602456;
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
  var query_602488 = newJObject()
  var formData_602489 = newJObject()
  add(formData_602489, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_602489.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602489, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_602489.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602489, "Iops", newJInt(Iops))
  add(formData_602489, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602489, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602489, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602489, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602489, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602489, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_602489, "MultiAZ", newJBool(MultiAZ))
  add(query_602488, "Action", newJString(Action))
  add(formData_602489, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_602489, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602489, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602489, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602489, "EngineVersion", newJString(EngineVersion))
  add(query_602488, "Version", newJString(Version))
  add(formData_602489, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_602487.call(nil, query_602488, nil, formData_602489, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602456(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602457, base: "/",
    url: url_PostModifyDBInstance_602458, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602423 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBInstance_602425(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_602424(path: JsonNode; query: JsonNode;
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
  var valid_602426 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "PreferredMaintenanceWindow", valid_602426
  var valid_602427 = query.getOrDefault("AllocatedStorage")
  valid_602427 = validateParameter(valid_602427, JInt, required = false, default = nil)
  if valid_602427 != nil:
    section.add "AllocatedStorage", valid_602427
  var valid_602428 = query.getOrDefault("OptionGroupName")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "OptionGroupName", valid_602428
  var valid_602429 = query.getOrDefault("DBSecurityGroups")
  valid_602429 = validateParameter(valid_602429, JArray, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "DBSecurityGroups", valid_602429
  var valid_602430 = query.getOrDefault("MasterUserPassword")
  valid_602430 = validateParameter(valid_602430, JString, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "MasterUserPassword", valid_602430
  var valid_602431 = query.getOrDefault("Iops")
  valid_602431 = validateParameter(valid_602431, JInt, required = false, default = nil)
  if valid_602431 != nil:
    section.add "Iops", valid_602431
  var valid_602432 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602432 = validateParameter(valid_602432, JArray, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "VpcSecurityGroupIds", valid_602432
  var valid_602433 = query.getOrDefault("MultiAZ")
  valid_602433 = validateParameter(valid_602433, JBool, required = false, default = nil)
  if valid_602433 != nil:
    section.add "MultiAZ", valid_602433
  var valid_602434 = query.getOrDefault("BackupRetentionPeriod")
  valid_602434 = validateParameter(valid_602434, JInt, required = false, default = nil)
  if valid_602434 != nil:
    section.add "BackupRetentionPeriod", valid_602434
  var valid_602435 = query.getOrDefault("DBParameterGroupName")
  valid_602435 = validateParameter(valid_602435, JString, required = false,
                                 default = nil)
  if valid_602435 != nil:
    section.add "DBParameterGroupName", valid_602435
  var valid_602436 = query.getOrDefault("DBInstanceClass")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "DBInstanceClass", valid_602436
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602437 = query.getOrDefault("Action")
  valid_602437 = validateParameter(valid_602437, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602437 != nil:
    section.add "Action", valid_602437
  var valid_602438 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_602438 = validateParameter(valid_602438, JBool, required = false, default = nil)
  if valid_602438 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602438
  var valid_602439 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "NewDBInstanceIdentifier", valid_602439
  var valid_602440 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602440 = validateParameter(valid_602440, JBool, required = false, default = nil)
  if valid_602440 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602440
  var valid_602441 = query.getOrDefault("EngineVersion")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "EngineVersion", valid_602441
  var valid_602442 = query.getOrDefault("PreferredBackupWindow")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "PreferredBackupWindow", valid_602442
  var valid_602443 = query.getOrDefault("Version")
  valid_602443 = validateParameter(valid_602443, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602443 != nil:
    section.add "Version", valid_602443
  var valid_602444 = query.getOrDefault("DBInstanceIdentifier")
  valid_602444 = validateParameter(valid_602444, JString, required = true,
                                 default = nil)
  if valid_602444 != nil:
    section.add "DBInstanceIdentifier", valid_602444
  var valid_602445 = query.getOrDefault("ApplyImmediately")
  valid_602445 = validateParameter(valid_602445, JBool, required = false, default = nil)
  if valid_602445 != nil:
    section.add "ApplyImmediately", valid_602445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602446 = header.getOrDefault("X-Amz-Date")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Date", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-Security-Token")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-Security-Token", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Content-Sha256", valid_602448
  var valid_602449 = header.getOrDefault("X-Amz-Algorithm")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "X-Amz-Algorithm", valid_602449
  var valid_602450 = header.getOrDefault("X-Amz-Signature")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "X-Amz-Signature", valid_602450
  var valid_602451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602451 = validateParameter(valid_602451, JString, required = false,
                                 default = nil)
  if valid_602451 != nil:
    section.add "X-Amz-SignedHeaders", valid_602451
  var valid_602452 = header.getOrDefault("X-Amz-Credential")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Credential", valid_602452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602453: Call_GetModifyDBInstance_602423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602453.validator(path, query, header, formData, body)
  let scheme = call_602453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602453.url(scheme.get, call_602453.host, call_602453.base,
                         call_602453.route, valid.getOrDefault("path"))
  result = hook(call_602453, url, valid)

proc call*(call_602454: Call_GetModifyDBInstance_602423;
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
  var query_602455 = newJObject()
  add(query_602455, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602455, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602455, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_602455.add "DBSecurityGroups", DBSecurityGroups
  add(query_602455, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602455, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_602455.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602455, "MultiAZ", newJBool(MultiAZ))
  add(query_602455, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602455, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602455, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602455, "Action", newJString(Action))
  add(query_602455, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_602455, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602455, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602455, "EngineVersion", newJString(EngineVersion))
  add(query_602455, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602455, "Version", newJString(Version))
  add(query_602455, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602455, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602454.call(nil, query_602455, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602423(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602424, base: "/",
    url: url_GetModifyDBInstance_602425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_602507 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBParameterGroup_602509(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_602508(path: JsonNode; query: JsonNode;
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
  var valid_602510 = query.getOrDefault("Action")
  valid_602510 = validateParameter(valid_602510, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602510 != nil:
    section.add "Action", valid_602510
  var valid_602511 = query.getOrDefault("Version")
  valid_602511 = validateParameter(valid_602511, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602511 != nil:
    section.add "Version", valid_602511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602512 = header.getOrDefault("X-Amz-Date")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Date", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Security-Token")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Security-Token", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Content-Sha256", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Algorithm")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Algorithm", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-Signature")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-Signature", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-SignedHeaders", valid_602517
  var valid_602518 = header.getOrDefault("X-Amz-Credential")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "X-Amz-Credential", valid_602518
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602519 = formData.getOrDefault("DBParameterGroupName")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = nil)
  if valid_602519 != nil:
    section.add "DBParameterGroupName", valid_602519
  var valid_602520 = formData.getOrDefault("Parameters")
  valid_602520 = validateParameter(valid_602520, JArray, required = true, default = nil)
  if valid_602520 != nil:
    section.add "Parameters", valid_602520
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602521: Call_PostModifyDBParameterGroup_602507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602521.validator(path, query, header, formData, body)
  let scheme = call_602521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602521.url(scheme.get, call_602521.host, call_602521.base,
                         call_602521.route, valid.getOrDefault("path"))
  result = hook(call_602521, url, valid)

proc call*(call_602522: Call_PostModifyDBParameterGroup_602507;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602523 = newJObject()
  var formData_602524 = newJObject()
  add(formData_602524, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602524.add "Parameters", Parameters
  add(query_602523, "Action", newJString(Action))
  add(query_602523, "Version", newJString(Version))
  result = call_602522.call(nil, query_602523, nil, formData_602524, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_602507(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_602508, base: "/",
    url: url_PostModifyDBParameterGroup_602509,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_602490 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBParameterGroup_602492(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_602491(path: JsonNode; query: JsonNode;
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
  var valid_602493 = query.getOrDefault("DBParameterGroupName")
  valid_602493 = validateParameter(valid_602493, JString, required = true,
                                 default = nil)
  if valid_602493 != nil:
    section.add "DBParameterGroupName", valid_602493
  var valid_602494 = query.getOrDefault("Parameters")
  valid_602494 = validateParameter(valid_602494, JArray, required = true, default = nil)
  if valid_602494 != nil:
    section.add "Parameters", valid_602494
  var valid_602495 = query.getOrDefault("Action")
  valid_602495 = validateParameter(valid_602495, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602495 != nil:
    section.add "Action", valid_602495
  var valid_602496 = query.getOrDefault("Version")
  valid_602496 = validateParameter(valid_602496, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602496 != nil:
    section.add "Version", valid_602496
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602497 = header.getOrDefault("X-Amz-Date")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Date", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Security-Token")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Security-Token", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Content-Sha256", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Algorithm")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Algorithm", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-Signature")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-Signature", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-SignedHeaders", valid_602502
  var valid_602503 = header.getOrDefault("X-Amz-Credential")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Credential", valid_602503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602504: Call_GetModifyDBParameterGroup_602490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602504.validator(path, query, header, formData, body)
  let scheme = call_602504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602504.url(scheme.get, call_602504.host, call_602504.base,
                         call_602504.route, valid.getOrDefault("path"))
  result = hook(call_602504, url, valid)

proc call*(call_602505: Call_GetModifyDBParameterGroup_602490;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602506 = newJObject()
  add(query_602506, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602506.add "Parameters", Parameters
  add(query_602506, "Action", newJString(Action))
  add(query_602506, "Version", newJString(Version))
  result = call_602505.call(nil, query_602506, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_602490(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_602491, base: "/",
    url: url_GetModifyDBParameterGroup_602492,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602543 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBSubnetGroup_602545(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_602544(path: JsonNode; query: JsonNode;
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
  var valid_602546 = query.getOrDefault("Action")
  valid_602546 = validateParameter(valid_602546, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602546 != nil:
    section.add "Action", valid_602546
  var valid_602547 = query.getOrDefault("Version")
  valid_602547 = validateParameter(valid_602547, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602547 != nil:
    section.add "Version", valid_602547
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602548 = header.getOrDefault("X-Amz-Date")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-Date", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Security-Token")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Security-Token", valid_602549
  var valid_602550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "X-Amz-Content-Sha256", valid_602550
  var valid_602551 = header.getOrDefault("X-Amz-Algorithm")
  valid_602551 = validateParameter(valid_602551, JString, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "X-Amz-Algorithm", valid_602551
  var valid_602552 = header.getOrDefault("X-Amz-Signature")
  valid_602552 = validateParameter(valid_602552, JString, required = false,
                                 default = nil)
  if valid_602552 != nil:
    section.add "X-Amz-Signature", valid_602552
  var valid_602553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-SignedHeaders", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Credential")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Credential", valid_602554
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602555 = formData.getOrDefault("DBSubnetGroupName")
  valid_602555 = validateParameter(valid_602555, JString, required = true,
                                 default = nil)
  if valid_602555 != nil:
    section.add "DBSubnetGroupName", valid_602555
  var valid_602556 = formData.getOrDefault("SubnetIds")
  valid_602556 = validateParameter(valid_602556, JArray, required = true, default = nil)
  if valid_602556 != nil:
    section.add "SubnetIds", valid_602556
  var valid_602557 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "DBSubnetGroupDescription", valid_602557
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602558: Call_PostModifyDBSubnetGroup_602543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602558.validator(path, query, header, formData, body)
  let scheme = call_602558.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602558.url(scheme.get, call_602558.host, call_602558.base,
                         call_602558.route, valid.getOrDefault("path"))
  result = hook(call_602558, url, valid)

proc call*(call_602559: Call_PostModifyDBSubnetGroup_602543;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602560 = newJObject()
  var formData_602561 = newJObject()
  add(formData_602561, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602561.add "SubnetIds", SubnetIds
  add(query_602560, "Action", newJString(Action))
  add(formData_602561, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602560, "Version", newJString(Version))
  result = call_602559.call(nil, query_602560, nil, formData_602561, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602543(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602544, base: "/",
    url: url_PostModifyDBSubnetGroup_602545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602525 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBSubnetGroup_602527(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_602526(path: JsonNode; query: JsonNode;
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
  var valid_602528 = query.getOrDefault("Action")
  valid_602528 = validateParameter(valid_602528, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602528 != nil:
    section.add "Action", valid_602528
  var valid_602529 = query.getOrDefault("DBSubnetGroupName")
  valid_602529 = validateParameter(valid_602529, JString, required = true,
                                 default = nil)
  if valid_602529 != nil:
    section.add "DBSubnetGroupName", valid_602529
  var valid_602530 = query.getOrDefault("SubnetIds")
  valid_602530 = validateParameter(valid_602530, JArray, required = true, default = nil)
  if valid_602530 != nil:
    section.add "SubnetIds", valid_602530
  var valid_602531 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "DBSubnetGroupDescription", valid_602531
  var valid_602532 = query.getOrDefault("Version")
  valid_602532 = validateParameter(valid_602532, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602532 != nil:
    section.add "Version", valid_602532
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602533 = header.getOrDefault("X-Amz-Date")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-Date", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Security-Token")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Security-Token", valid_602534
  var valid_602535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "X-Amz-Content-Sha256", valid_602535
  var valid_602536 = header.getOrDefault("X-Amz-Algorithm")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "X-Amz-Algorithm", valid_602536
  var valid_602537 = header.getOrDefault("X-Amz-Signature")
  valid_602537 = validateParameter(valid_602537, JString, required = false,
                                 default = nil)
  if valid_602537 != nil:
    section.add "X-Amz-Signature", valid_602537
  var valid_602538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-SignedHeaders", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Credential")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Credential", valid_602539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602540: Call_GetModifyDBSubnetGroup_602525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602540.validator(path, query, header, formData, body)
  let scheme = call_602540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602540.url(scheme.get, call_602540.host, call_602540.base,
                         call_602540.route, valid.getOrDefault("path"))
  result = hook(call_602540, url, valid)

proc call*(call_602541: Call_GetModifyDBSubnetGroup_602525;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602542 = newJObject()
  add(query_602542, "Action", newJString(Action))
  add(query_602542, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602542.add "SubnetIds", SubnetIds
  add(query_602542, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602542, "Version", newJString(Version))
  result = call_602541.call(nil, query_602542, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602525(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602526, base: "/",
    url: url_GetModifyDBSubnetGroup_602527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_602582 = ref object of OpenApiRestCall_600410
proc url_PostModifyEventSubscription_602584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_602583(path: JsonNode; query: JsonNode;
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
  var valid_602585 = query.getOrDefault("Action")
  valid_602585 = validateParameter(valid_602585, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602585 != nil:
    section.add "Action", valid_602585
  var valid_602586 = query.getOrDefault("Version")
  valid_602586 = validateParameter(valid_602586, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602586 != nil:
    section.add "Version", valid_602586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602587 = header.getOrDefault("X-Amz-Date")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Date", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Security-Token")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Security-Token", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-Content-Sha256", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Algorithm")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Algorithm", valid_602590
  var valid_602591 = header.getOrDefault("X-Amz-Signature")
  valid_602591 = validateParameter(valid_602591, JString, required = false,
                                 default = nil)
  if valid_602591 != nil:
    section.add "X-Amz-Signature", valid_602591
  var valid_602592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602592 = validateParameter(valid_602592, JString, required = false,
                                 default = nil)
  if valid_602592 != nil:
    section.add "X-Amz-SignedHeaders", valid_602592
  var valid_602593 = header.getOrDefault("X-Amz-Credential")
  valid_602593 = validateParameter(valid_602593, JString, required = false,
                                 default = nil)
  if valid_602593 != nil:
    section.add "X-Amz-Credential", valid_602593
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_602594 = formData.getOrDefault("Enabled")
  valid_602594 = validateParameter(valid_602594, JBool, required = false, default = nil)
  if valid_602594 != nil:
    section.add "Enabled", valid_602594
  var valid_602595 = formData.getOrDefault("EventCategories")
  valid_602595 = validateParameter(valid_602595, JArray, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "EventCategories", valid_602595
  var valid_602596 = formData.getOrDefault("SnsTopicArn")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "SnsTopicArn", valid_602596
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602597 = formData.getOrDefault("SubscriptionName")
  valid_602597 = validateParameter(valid_602597, JString, required = true,
                                 default = nil)
  if valid_602597 != nil:
    section.add "SubscriptionName", valid_602597
  var valid_602598 = formData.getOrDefault("SourceType")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "SourceType", valid_602598
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602599: Call_PostModifyEventSubscription_602582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602599.validator(path, query, header, formData, body)
  let scheme = call_602599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602599.url(scheme.get, call_602599.host, call_602599.base,
                         call_602599.route, valid.getOrDefault("path"))
  result = hook(call_602599, url, valid)

proc call*(call_602600: Call_PostModifyEventSubscription_602582;
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
  var query_602601 = newJObject()
  var formData_602602 = newJObject()
  add(formData_602602, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_602602.add "EventCategories", EventCategories
  add(formData_602602, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602602, "SubscriptionName", newJString(SubscriptionName))
  add(query_602601, "Action", newJString(Action))
  add(query_602601, "Version", newJString(Version))
  add(formData_602602, "SourceType", newJString(SourceType))
  result = call_602600.call(nil, query_602601, nil, formData_602602, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_602582(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_602583, base: "/",
    url: url_PostModifyEventSubscription_602584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_602562 = ref object of OpenApiRestCall_600410
proc url_GetModifyEventSubscription_602564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_602563(path: JsonNode; query: JsonNode;
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
  var valid_602565 = query.getOrDefault("SourceType")
  valid_602565 = validateParameter(valid_602565, JString, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "SourceType", valid_602565
  var valid_602566 = query.getOrDefault("Enabled")
  valid_602566 = validateParameter(valid_602566, JBool, required = false, default = nil)
  if valid_602566 != nil:
    section.add "Enabled", valid_602566
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602567 = query.getOrDefault("Action")
  valid_602567 = validateParameter(valid_602567, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602567 != nil:
    section.add "Action", valid_602567
  var valid_602568 = query.getOrDefault("SnsTopicArn")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "SnsTopicArn", valid_602568
  var valid_602569 = query.getOrDefault("EventCategories")
  valid_602569 = validateParameter(valid_602569, JArray, required = false,
                                 default = nil)
  if valid_602569 != nil:
    section.add "EventCategories", valid_602569
  var valid_602570 = query.getOrDefault("SubscriptionName")
  valid_602570 = validateParameter(valid_602570, JString, required = true,
                                 default = nil)
  if valid_602570 != nil:
    section.add "SubscriptionName", valid_602570
  var valid_602571 = query.getOrDefault("Version")
  valid_602571 = validateParameter(valid_602571, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602571 != nil:
    section.add "Version", valid_602571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602572 = header.getOrDefault("X-Amz-Date")
  valid_602572 = validateParameter(valid_602572, JString, required = false,
                                 default = nil)
  if valid_602572 != nil:
    section.add "X-Amz-Date", valid_602572
  var valid_602573 = header.getOrDefault("X-Amz-Security-Token")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "X-Amz-Security-Token", valid_602573
  var valid_602574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "X-Amz-Content-Sha256", valid_602574
  var valid_602575 = header.getOrDefault("X-Amz-Algorithm")
  valid_602575 = validateParameter(valid_602575, JString, required = false,
                                 default = nil)
  if valid_602575 != nil:
    section.add "X-Amz-Algorithm", valid_602575
  var valid_602576 = header.getOrDefault("X-Amz-Signature")
  valid_602576 = validateParameter(valid_602576, JString, required = false,
                                 default = nil)
  if valid_602576 != nil:
    section.add "X-Amz-Signature", valid_602576
  var valid_602577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "X-Amz-SignedHeaders", valid_602577
  var valid_602578 = header.getOrDefault("X-Amz-Credential")
  valid_602578 = validateParameter(valid_602578, JString, required = false,
                                 default = nil)
  if valid_602578 != nil:
    section.add "X-Amz-Credential", valid_602578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602579: Call_GetModifyEventSubscription_602562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602579.validator(path, query, header, formData, body)
  let scheme = call_602579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602579.url(scheme.get, call_602579.host, call_602579.base,
                         call_602579.route, valid.getOrDefault("path"))
  result = hook(call_602579, url, valid)

proc call*(call_602580: Call_GetModifyEventSubscription_602562;
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
  var query_602581 = newJObject()
  add(query_602581, "SourceType", newJString(SourceType))
  add(query_602581, "Enabled", newJBool(Enabled))
  add(query_602581, "Action", newJString(Action))
  add(query_602581, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_602581.add "EventCategories", EventCategories
  add(query_602581, "SubscriptionName", newJString(SubscriptionName))
  add(query_602581, "Version", newJString(Version))
  result = call_602580.call(nil, query_602581, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_602562(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_602563, base: "/",
    url: url_GetModifyEventSubscription_602564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_602622 = ref object of OpenApiRestCall_600410
proc url_PostModifyOptionGroup_602624(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_602623(path: JsonNode; query: JsonNode;
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
  var valid_602625 = query.getOrDefault("Action")
  valid_602625 = validateParameter(valid_602625, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602625 != nil:
    section.add "Action", valid_602625
  var valid_602626 = query.getOrDefault("Version")
  valid_602626 = validateParameter(valid_602626, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602626 != nil:
    section.add "Version", valid_602626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602627 = header.getOrDefault("X-Amz-Date")
  valid_602627 = validateParameter(valid_602627, JString, required = false,
                                 default = nil)
  if valid_602627 != nil:
    section.add "X-Amz-Date", valid_602627
  var valid_602628 = header.getOrDefault("X-Amz-Security-Token")
  valid_602628 = validateParameter(valid_602628, JString, required = false,
                                 default = nil)
  if valid_602628 != nil:
    section.add "X-Amz-Security-Token", valid_602628
  var valid_602629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602629 = validateParameter(valid_602629, JString, required = false,
                                 default = nil)
  if valid_602629 != nil:
    section.add "X-Amz-Content-Sha256", valid_602629
  var valid_602630 = header.getOrDefault("X-Amz-Algorithm")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Algorithm", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Signature")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Signature", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-SignedHeaders", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Credential")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Credential", valid_602633
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_602634 = formData.getOrDefault("OptionsToRemove")
  valid_602634 = validateParameter(valid_602634, JArray, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "OptionsToRemove", valid_602634
  var valid_602635 = formData.getOrDefault("ApplyImmediately")
  valid_602635 = validateParameter(valid_602635, JBool, required = false, default = nil)
  if valid_602635 != nil:
    section.add "ApplyImmediately", valid_602635
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602636 = formData.getOrDefault("OptionGroupName")
  valid_602636 = validateParameter(valid_602636, JString, required = true,
                                 default = nil)
  if valid_602636 != nil:
    section.add "OptionGroupName", valid_602636
  var valid_602637 = formData.getOrDefault("OptionsToInclude")
  valid_602637 = validateParameter(valid_602637, JArray, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "OptionsToInclude", valid_602637
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602638: Call_PostModifyOptionGroup_602622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602638.validator(path, query, header, formData, body)
  let scheme = call_602638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602638.url(scheme.get, call_602638.host, call_602638.base,
                         call_602638.route, valid.getOrDefault("path"))
  result = hook(call_602638, url, valid)

proc call*(call_602639: Call_PostModifyOptionGroup_602622; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602640 = newJObject()
  var formData_602641 = newJObject()
  if OptionsToRemove != nil:
    formData_602641.add "OptionsToRemove", OptionsToRemove
  add(formData_602641, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602641, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_602641.add "OptionsToInclude", OptionsToInclude
  add(query_602640, "Action", newJString(Action))
  add(query_602640, "Version", newJString(Version))
  result = call_602639.call(nil, query_602640, nil, formData_602641, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_602622(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_602623, base: "/",
    url: url_PostModifyOptionGroup_602624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_602603 = ref object of OpenApiRestCall_600410
proc url_GetModifyOptionGroup_602605(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_602604(path: JsonNode; query: JsonNode;
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
  var valid_602606 = query.getOrDefault("OptionGroupName")
  valid_602606 = validateParameter(valid_602606, JString, required = true,
                                 default = nil)
  if valid_602606 != nil:
    section.add "OptionGroupName", valid_602606
  var valid_602607 = query.getOrDefault("OptionsToRemove")
  valid_602607 = validateParameter(valid_602607, JArray, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "OptionsToRemove", valid_602607
  var valid_602608 = query.getOrDefault("Action")
  valid_602608 = validateParameter(valid_602608, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602608 != nil:
    section.add "Action", valid_602608
  var valid_602609 = query.getOrDefault("Version")
  valid_602609 = validateParameter(valid_602609, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602609 != nil:
    section.add "Version", valid_602609
  var valid_602610 = query.getOrDefault("ApplyImmediately")
  valid_602610 = validateParameter(valid_602610, JBool, required = false, default = nil)
  if valid_602610 != nil:
    section.add "ApplyImmediately", valid_602610
  var valid_602611 = query.getOrDefault("OptionsToInclude")
  valid_602611 = validateParameter(valid_602611, JArray, required = false,
                                 default = nil)
  if valid_602611 != nil:
    section.add "OptionsToInclude", valid_602611
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602612 = header.getOrDefault("X-Amz-Date")
  valid_602612 = validateParameter(valid_602612, JString, required = false,
                                 default = nil)
  if valid_602612 != nil:
    section.add "X-Amz-Date", valid_602612
  var valid_602613 = header.getOrDefault("X-Amz-Security-Token")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "X-Amz-Security-Token", valid_602613
  var valid_602614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "X-Amz-Content-Sha256", valid_602614
  var valid_602615 = header.getOrDefault("X-Amz-Algorithm")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Algorithm", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Signature")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Signature", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-SignedHeaders", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Credential")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Credential", valid_602618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602619: Call_GetModifyOptionGroup_602603; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602619.validator(path, query, header, formData, body)
  let scheme = call_602619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602619.url(scheme.get, call_602619.host, call_602619.base,
                         call_602619.route, valid.getOrDefault("path"))
  result = hook(call_602619, url, valid)

proc call*(call_602620: Call_GetModifyOptionGroup_602603; OptionGroupName: string;
          OptionsToRemove: JsonNode = nil; Action: string = "ModifyOptionGroup";
          Version: string = "2013-01-10"; ApplyImmediately: bool = false;
          OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_602621 = newJObject()
  add(query_602621, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_602621.add "OptionsToRemove", OptionsToRemove
  add(query_602621, "Action", newJString(Action))
  add(query_602621, "Version", newJString(Version))
  add(query_602621, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_602621.add "OptionsToInclude", OptionsToInclude
  result = call_602620.call(nil, query_602621, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_602603(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_602604, base: "/",
    url: url_GetModifyOptionGroup_602605, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_602660 = ref object of OpenApiRestCall_600410
proc url_PostPromoteReadReplica_602662(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_602661(path: JsonNode; query: JsonNode;
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
  var valid_602663 = query.getOrDefault("Action")
  valid_602663 = validateParameter(valid_602663, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602663 != nil:
    section.add "Action", valid_602663
  var valid_602664 = query.getOrDefault("Version")
  valid_602664 = validateParameter(valid_602664, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602664 != nil:
    section.add "Version", valid_602664
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602665 = header.getOrDefault("X-Amz-Date")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "X-Amz-Date", valid_602665
  var valid_602666 = header.getOrDefault("X-Amz-Security-Token")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "X-Amz-Security-Token", valid_602666
  var valid_602667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602667 = validateParameter(valid_602667, JString, required = false,
                                 default = nil)
  if valid_602667 != nil:
    section.add "X-Amz-Content-Sha256", valid_602667
  var valid_602668 = header.getOrDefault("X-Amz-Algorithm")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "X-Amz-Algorithm", valid_602668
  var valid_602669 = header.getOrDefault("X-Amz-Signature")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Signature", valid_602669
  var valid_602670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "X-Amz-SignedHeaders", valid_602670
  var valid_602671 = header.getOrDefault("X-Amz-Credential")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Credential", valid_602671
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602672 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602672 = validateParameter(valid_602672, JString, required = true,
                                 default = nil)
  if valid_602672 != nil:
    section.add "DBInstanceIdentifier", valid_602672
  var valid_602673 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602673 = validateParameter(valid_602673, JInt, required = false, default = nil)
  if valid_602673 != nil:
    section.add "BackupRetentionPeriod", valid_602673
  var valid_602674 = formData.getOrDefault("PreferredBackupWindow")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "PreferredBackupWindow", valid_602674
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602675: Call_PostPromoteReadReplica_602660; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602675.validator(path, query, header, formData, body)
  let scheme = call_602675.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602675.url(scheme.get, call_602675.host, call_602675.base,
                         call_602675.route, valid.getOrDefault("path"))
  result = hook(call_602675, url, valid)

proc call*(call_602676: Call_PostPromoteReadReplica_602660;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_602677 = newJObject()
  var formData_602678 = newJObject()
  add(formData_602678, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602678, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602677, "Action", newJString(Action))
  add(formData_602678, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602677, "Version", newJString(Version))
  result = call_602676.call(nil, query_602677, nil, formData_602678, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_602660(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_602661, base: "/",
    url: url_PostPromoteReadReplica_602662, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_602642 = ref object of OpenApiRestCall_600410
proc url_GetPromoteReadReplica_602644(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_602643(path: JsonNode; query: JsonNode;
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
  var valid_602645 = query.getOrDefault("BackupRetentionPeriod")
  valid_602645 = validateParameter(valid_602645, JInt, required = false, default = nil)
  if valid_602645 != nil:
    section.add "BackupRetentionPeriod", valid_602645
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602646 = query.getOrDefault("Action")
  valid_602646 = validateParameter(valid_602646, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602646 != nil:
    section.add "Action", valid_602646
  var valid_602647 = query.getOrDefault("PreferredBackupWindow")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "PreferredBackupWindow", valid_602647
  var valid_602648 = query.getOrDefault("Version")
  valid_602648 = validateParameter(valid_602648, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602648 != nil:
    section.add "Version", valid_602648
  var valid_602649 = query.getOrDefault("DBInstanceIdentifier")
  valid_602649 = validateParameter(valid_602649, JString, required = true,
                                 default = nil)
  if valid_602649 != nil:
    section.add "DBInstanceIdentifier", valid_602649
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602650 = header.getOrDefault("X-Amz-Date")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "X-Amz-Date", valid_602650
  var valid_602651 = header.getOrDefault("X-Amz-Security-Token")
  valid_602651 = validateParameter(valid_602651, JString, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "X-Amz-Security-Token", valid_602651
  var valid_602652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "X-Amz-Content-Sha256", valid_602652
  var valid_602653 = header.getOrDefault("X-Amz-Algorithm")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "X-Amz-Algorithm", valid_602653
  var valid_602654 = header.getOrDefault("X-Amz-Signature")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Signature", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-SignedHeaders", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Credential")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Credential", valid_602656
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602657: Call_GetPromoteReadReplica_602642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602657.validator(path, query, header, formData, body)
  let scheme = call_602657.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602657.url(scheme.get, call_602657.host, call_602657.base,
                         call_602657.route, valid.getOrDefault("path"))
  result = hook(call_602657, url, valid)

proc call*(call_602658: Call_GetPromoteReadReplica_602642;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602659 = newJObject()
  add(query_602659, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602659, "Action", newJString(Action))
  add(query_602659, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602659, "Version", newJString(Version))
  add(query_602659, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602658.call(nil, query_602659, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_602642(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_602643, base: "/",
    url: url_GetPromoteReadReplica_602644, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_602697 = ref object of OpenApiRestCall_600410
proc url_PostPurchaseReservedDBInstancesOffering_602699(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_602698(path: JsonNode;
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
  var valid_602700 = query.getOrDefault("Action")
  valid_602700 = validateParameter(valid_602700, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602700 != nil:
    section.add "Action", valid_602700
  var valid_602701 = query.getOrDefault("Version")
  valid_602701 = validateParameter(valid_602701, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602701 != nil:
    section.add "Version", valid_602701
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602702 = header.getOrDefault("X-Amz-Date")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "X-Amz-Date", valid_602702
  var valid_602703 = header.getOrDefault("X-Amz-Security-Token")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "X-Amz-Security-Token", valid_602703
  var valid_602704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "X-Amz-Content-Sha256", valid_602704
  var valid_602705 = header.getOrDefault("X-Amz-Algorithm")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "X-Amz-Algorithm", valid_602705
  var valid_602706 = header.getOrDefault("X-Amz-Signature")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "X-Amz-Signature", valid_602706
  var valid_602707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "X-Amz-SignedHeaders", valid_602707
  var valid_602708 = header.getOrDefault("X-Amz-Credential")
  valid_602708 = validateParameter(valid_602708, JString, required = false,
                                 default = nil)
  if valid_602708 != nil:
    section.add "X-Amz-Credential", valid_602708
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_602709 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "ReservedDBInstanceId", valid_602709
  var valid_602710 = formData.getOrDefault("DBInstanceCount")
  valid_602710 = validateParameter(valid_602710, JInt, required = false, default = nil)
  if valid_602710 != nil:
    section.add "DBInstanceCount", valid_602710
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602711 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602711 = validateParameter(valid_602711, JString, required = true,
                                 default = nil)
  if valid_602711 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602711
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602712: Call_PostPurchaseReservedDBInstancesOffering_602697;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602712.validator(path, query, header, formData, body)
  let scheme = call_602712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602712.url(scheme.get, call_602712.host, call_602712.base,
                         call_602712.route, valid.getOrDefault("path"))
  result = hook(call_602712, url, valid)

proc call*(call_602713: Call_PostPurchaseReservedDBInstancesOffering_602697;
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
  var query_602714 = newJObject()
  var formData_602715 = newJObject()
  add(formData_602715, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602715, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602714, "Action", newJString(Action))
  add(formData_602715, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602714, "Version", newJString(Version))
  result = call_602713.call(nil, query_602714, nil, formData_602715, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_602697(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_602698, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_602699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_602679 = ref object of OpenApiRestCall_600410
proc url_GetPurchaseReservedDBInstancesOffering_602681(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_602680(path: JsonNode;
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
  var valid_602682 = query.getOrDefault("DBInstanceCount")
  valid_602682 = validateParameter(valid_602682, JInt, required = false, default = nil)
  if valid_602682 != nil:
    section.add "DBInstanceCount", valid_602682
  var valid_602683 = query.getOrDefault("ReservedDBInstanceId")
  valid_602683 = validateParameter(valid_602683, JString, required = false,
                                 default = nil)
  if valid_602683 != nil:
    section.add "ReservedDBInstanceId", valid_602683
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602684 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602684 = validateParameter(valid_602684, JString, required = true,
                                 default = nil)
  if valid_602684 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602684
  var valid_602685 = query.getOrDefault("Action")
  valid_602685 = validateParameter(valid_602685, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602685 != nil:
    section.add "Action", valid_602685
  var valid_602686 = query.getOrDefault("Version")
  valid_602686 = validateParameter(valid_602686, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602686 != nil:
    section.add "Version", valid_602686
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602687 = header.getOrDefault("X-Amz-Date")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Date", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Security-Token")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Security-Token", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Content-Sha256", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Algorithm")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Algorithm", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Signature")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Signature", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-SignedHeaders", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-Credential")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-Credential", valid_602693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602694: Call_GetPurchaseReservedDBInstancesOffering_602679;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602694.validator(path, query, header, formData, body)
  let scheme = call_602694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602694.url(scheme.get, call_602694.host, call_602694.base,
                         call_602694.route, valid.getOrDefault("path"))
  result = hook(call_602694, url, valid)

proc call*(call_602695: Call_GetPurchaseReservedDBInstancesOffering_602679;
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
  var query_602696 = newJObject()
  add(query_602696, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602696, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602696, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602696, "Action", newJString(Action))
  add(query_602696, "Version", newJString(Version))
  result = call_602695.call(nil, query_602696, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_602679(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_602680, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_602681,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602733 = ref object of OpenApiRestCall_600410
proc url_PostRebootDBInstance_602735(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_602734(path: JsonNode; query: JsonNode;
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
  var valid_602736 = query.getOrDefault("Action")
  valid_602736 = validateParameter(valid_602736, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602736 != nil:
    section.add "Action", valid_602736
  var valid_602737 = query.getOrDefault("Version")
  valid_602737 = validateParameter(valid_602737, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602737 != nil:
    section.add "Version", valid_602737
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602738 = header.getOrDefault("X-Amz-Date")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Date", valid_602738
  var valid_602739 = header.getOrDefault("X-Amz-Security-Token")
  valid_602739 = validateParameter(valid_602739, JString, required = false,
                                 default = nil)
  if valid_602739 != nil:
    section.add "X-Amz-Security-Token", valid_602739
  var valid_602740 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602740 = validateParameter(valid_602740, JString, required = false,
                                 default = nil)
  if valid_602740 != nil:
    section.add "X-Amz-Content-Sha256", valid_602740
  var valid_602741 = header.getOrDefault("X-Amz-Algorithm")
  valid_602741 = validateParameter(valid_602741, JString, required = false,
                                 default = nil)
  if valid_602741 != nil:
    section.add "X-Amz-Algorithm", valid_602741
  var valid_602742 = header.getOrDefault("X-Amz-Signature")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Signature", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-SignedHeaders", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Credential")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Credential", valid_602744
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602745 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602745 = validateParameter(valid_602745, JString, required = true,
                                 default = nil)
  if valid_602745 != nil:
    section.add "DBInstanceIdentifier", valid_602745
  var valid_602746 = formData.getOrDefault("ForceFailover")
  valid_602746 = validateParameter(valid_602746, JBool, required = false, default = nil)
  if valid_602746 != nil:
    section.add "ForceFailover", valid_602746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602747: Call_PostRebootDBInstance_602733; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602747.validator(path, query, header, formData, body)
  let scheme = call_602747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602747.url(scheme.get, call_602747.host, call_602747.base,
                         call_602747.route, valid.getOrDefault("path"))
  result = hook(call_602747, url, valid)

proc call*(call_602748: Call_PostRebootDBInstance_602733;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_602749 = newJObject()
  var formData_602750 = newJObject()
  add(formData_602750, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602749, "Action", newJString(Action))
  add(formData_602750, "ForceFailover", newJBool(ForceFailover))
  add(query_602749, "Version", newJString(Version))
  result = call_602748.call(nil, query_602749, nil, formData_602750, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602733(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602734, base: "/",
    url: url_PostRebootDBInstance_602735, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602716 = ref object of OpenApiRestCall_600410
proc url_GetRebootDBInstance_602718(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_602717(path: JsonNode; query: JsonNode;
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
  var valid_602719 = query.getOrDefault("Action")
  valid_602719 = validateParameter(valid_602719, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602719 != nil:
    section.add "Action", valid_602719
  var valid_602720 = query.getOrDefault("ForceFailover")
  valid_602720 = validateParameter(valid_602720, JBool, required = false, default = nil)
  if valid_602720 != nil:
    section.add "ForceFailover", valid_602720
  var valid_602721 = query.getOrDefault("Version")
  valid_602721 = validateParameter(valid_602721, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602721 != nil:
    section.add "Version", valid_602721
  var valid_602722 = query.getOrDefault("DBInstanceIdentifier")
  valid_602722 = validateParameter(valid_602722, JString, required = true,
                                 default = nil)
  if valid_602722 != nil:
    section.add "DBInstanceIdentifier", valid_602722
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602723 = header.getOrDefault("X-Amz-Date")
  valid_602723 = validateParameter(valid_602723, JString, required = false,
                                 default = nil)
  if valid_602723 != nil:
    section.add "X-Amz-Date", valid_602723
  var valid_602724 = header.getOrDefault("X-Amz-Security-Token")
  valid_602724 = validateParameter(valid_602724, JString, required = false,
                                 default = nil)
  if valid_602724 != nil:
    section.add "X-Amz-Security-Token", valid_602724
  var valid_602725 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Content-Sha256", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Algorithm")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Algorithm", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Signature")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Signature", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-SignedHeaders", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Credential")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Credential", valid_602729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602730: Call_GetRebootDBInstance_602716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602730.validator(path, query, header, formData, body)
  let scheme = call_602730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602730.url(scheme.get, call_602730.host, call_602730.base,
                         call_602730.route, valid.getOrDefault("path"))
  result = hook(call_602730, url, valid)

proc call*(call_602731: Call_GetRebootDBInstance_602716;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602732 = newJObject()
  add(query_602732, "Action", newJString(Action))
  add(query_602732, "ForceFailover", newJBool(ForceFailover))
  add(query_602732, "Version", newJString(Version))
  add(query_602732, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602731.call(nil, query_602732, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602716(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602717, base: "/",
    url: url_GetRebootDBInstance_602718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_602768 = ref object of OpenApiRestCall_600410
proc url_PostRemoveSourceIdentifierFromSubscription_602770(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_602769(path: JsonNode;
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
  var valid_602771 = query.getOrDefault("Action")
  valid_602771 = validateParameter(valid_602771, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602771 != nil:
    section.add "Action", valid_602771
  var valid_602772 = query.getOrDefault("Version")
  valid_602772 = validateParameter(valid_602772, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602772 != nil:
    section.add "Version", valid_602772
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602773 = header.getOrDefault("X-Amz-Date")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Date", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-Security-Token")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-Security-Token", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Content-Sha256", valid_602775
  var valid_602776 = header.getOrDefault("X-Amz-Algorithm")
  valid_602776 = validateParameter(valid_602776, JString, required = false,
                                 default = nil)
  if valid_602776 != nil:
    section.add "X-Amz-Algorithm", valid_602776
  var valid_602777 = header.getOrDefault("X-Amz-Signature")
  valid_602777 = validateParameter(valid_602777, JString, required = false,
                                 default = nil)
  if valid_602777 != nil:
    section.add "X-Amz-Signature", valid_602777
  var valid_602778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-SignedHeaders", valid_602778
  var valid_602779 = header.getOrDefault("X-Amz-Credential")
  valid_602779 = validateParameter(valid_602779, JString, required = false,
                                 default = nil)
  if valid_602779 != nil:
    section.add "X-Amz-Credential", valid_602779
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_602780 = formData.getOrDefault("SourceIdentifier")
  valid_602780 = validateParameter(valid_602780, JString, required = true,
                                 default = nil)
  if valid_602780 != nil:
    section.add "SourceIdentifier", valid_602780
  var valid_602781 = formData.getOrDefault("SubscriptionName")
  valid_602781 = validateParameter(valid_602781, JString, required = true,
                                 default = nil)
  if valid_602781 != nil:
    section.add "SubscriptionName", valid_602781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602782: Call_PostRemoveSourceIdentifierFromSubscription_602768;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602782.validator(path, query, header, formData, body)
  let scheme = call_602782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602782.url(scheme.get, call_602782.host, call_602782.base,
                         call_602782.route, valid.getOrDefault("path"))
  result = hook(call_602782, url, valid)

proc call*(call_602783: Call_PostRemoveSourceIdentifierFromSubscription_602768;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602784 = newJObject()
  var formData_602785 = newJObject()
  add(formData_602785, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_602785, "SubscriptionName", newJString(SubscriptionName))
  add(query_602784, "Action", newJString(Action))
  add(query_602784, "Version", newJString(Version))
  result = call_602783.call(nil, query_602784, nil, formData_602785, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_602768(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_602769,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_602770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_602751 = ref object of OpenApiRestCall_600410
proc url_GetRemoveSourceIdentifierFromSubscription_602753(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_602752(path: JsonNode;
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
  var valid_602754 = query.getOrDefault("Action")
  valid_602754 = validateParameter(valid_602754, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602754 != nil:
    section.add "Action", valid_602754
  var valid_602755 = query.getOrDefault("SourceIdentifier")
  valid_602755 = validateParameter(valid_602755, JString, required = true,
                                 default = nil)
  if valid_602755 != nil:
    section.add "SourceIdentifier", valid_602755
  var valid_602756 = query.getOrDefault("SubscriptionName")
  valid_602756 = validateParameter(valid_602756, JString, required = true,
                                 default = nil)
  if valid_602756 != nil:
    section.add "SubscriptionName", valid_602756
  var valid_602757 = query.getOrDefault("Version")
  valid_602757 = validateParameter(valid_602757, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602757 != nil:
    section.add "Version", valid_602757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602758 = header.getOrDefault("X-Amz-Date")
  valid_602758 = validateParameter(valid_602758, JString, required = false,
                                 default = nil)
  if valid_602758 != nil:
    section.add "X-Amz-Date", valid_602758
  var valid_602759 = header.getOrDefault("X-Amz-Security-Token")
  valid_602759 = validateParameter(valid_602759, JString, required = false,
                                 default = nil)
  if valid_602759 != nil:
    section.add "X-Amz-Security-Token", valid_602759
  var valid_602760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602760 = validateParameter(valid_602760, JString, required = false,
                                 default = nil)
  if valid_602760 != nil:
    section.add "X-Amz-Content-Sha256", valid_602760
  var valid_602761 = header.getOrDefault("X-Amz-Algorithm")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "X-Amz-Algorithm", valid_602761
  var valid_602762 = header.getOrDefault("X-Amz-Signature")
  valid_602762 = validateParameter(valid_602762, JString, required = false,
                                 default = nil)
  if valid_602762 != nil:
    section.add "X-Amz-Signature", valid_602762
  var valid_602763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-SignedHeaders", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Credential")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Credential", valid_602764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602765: Call_GetRemoveSourceIdentifierFromSubscription_602751;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602765.validator(path, query, header, formData, body)
  let scheme = call_602765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602765.url(scheme.get, call_602765.host, call_602765.base,
                         call_602765.route, valid.getOrDefault("path"))
  result = hook(call_602765, url, valid)

proc call*(call_602766: Call_GetRemoveSourceIdentifierFromSubscription_602751;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602767 = newJObject()
  add(query_602767, "Action", newJString(Action))
  add(query_602767, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602767, "SubscriptionName", newJString(SubscriptionName))
  add(query_602767, "Version", newJString(Version))
  result = call_602766.call(nil, query_602767, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_602751(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_602752,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_602753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_602803 = ref object of OpenApiRestCall_600410
proc url_PostRemoveTagsFromResource_602805(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_602804(path: JsonNode; query: JsonNode;
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
  var valid_602806 = query.getOrDefault("Action")
  valid_602806 = validateParameter(valid_602806, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602806 != nil:
    section.add "Action", valid_602806
  var valid_602807 = query.getOrDefault("Version")
  valid_602807 = validateParameter(valid_602807, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602807 != nil:
    section.add "Version", valid_602807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602808 = header.getOrDefault("X-Amz-Date")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Date", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-Security-Token")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Security-Token", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-Content-Sha256", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Algorithm")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Algorithm", valid_602811
  var valid_602812 = header.getOrDefault("X-Amz-Signature")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "X-Amz-Signature", valid_602812
  var valid_602813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602813 = validateParameter(valid_602813, JString, required = false,
                                 default = nil)
  if valid_602813 != nil:
    section.add "X-Amz-SignedHeaders", valid_602813
  var valid_602814 = header.getOrDefault("X-Amz-Credential")
  valid_602814 = validateParameter(valid_602814, JString, required = false,
                                 default = nil)
  if valid_602814 != nil:
    section.add "X-Amz-Credential", valid_602814
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_602815 = formData.getOrDefault("TagKeys")
  valid_602815 = validateParameter(valid_602815, JArray, required = true, default = nil)
  if valid_602815 != nil:
    section.add "TagKeys", valid_602815
  var valid_602816 = formData.getOrDefault("ResourceName")
  valid_602816 = validateParameter(valid_602816, JString, required = true,
                                 default = nil)
  if valid_602816 != nil:
    section.add "ResourceName", valid_602816
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602817: Call_PostRemoveTagsFromResource_602803; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602817.validator(path, query, header, formData, body)
  let scheme = call_602817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602817.url(scheme.get, call_602817.host, call_602817.base,
                         call_602817.route, valid.getOrDefault("path"))
  result = hook(call_602817, url, valid)

proc call*(call_602818: Call_PostRemoveTagsFromResource_602803; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602819 = newJObject()
  var formData_602820 = newJObject()
  add(query_602819, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602820.add "TagKeys", TagKeys
  add(formData_602820, "ResourceName", newJString(ResourceName))
  add(query_602819, "Version", newJString(Version))
  result = call_602818.call(nil, query_602819, nil, formData_602820, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_602803(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_602804, base: "/",
    url: url_PostRemoveTagsFromResource_602805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_602786 = ref object of OpenApiRestCall_600410
proc url_GetRemoveTagsFromResource_602788(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_602787(path: JsonNode; query: JsonNode;
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
  var valid_602789 = query.getOrDefault("ResourceName")
  valid_602789 = validateParameter(valid_602789, JString, required = true,
                                 default = nil)
  if valid_602789 != nil:
    section.add "ResourceName", valid_602789
  var valid_602790 = query.getOrDefault("Action")
  valid_602790 = validateParameter(valid_602790, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602790 != nil:
    section.add "Action", valid_602790
  var valid_602791 = query.getOrDefault("TagKeys")
  valid_602791 = validateParameter(valid_602791, JArray, required = true, default = nil)
  if valid_602791 != nil:
    section.add "TagKeys", valid_602791
  var valid_602792 = query.getOrDefault("Version")
  valid_602792 = validateParameter(valid_602792, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602792 != nil:
    section.add "Version", valid_602792
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602793 = header.getOrDefault("X-Amz-Date")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "X-Amz-Date", valid_602793
  var valid_602794 = header.getOrDefault("X-Amz-Security-Token")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Security-Token", valid_602794
  var valid_602795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "X-Amz-Content-Sha256", valid_602795
  var valid_602796 = header.getOrDefault("X-Amz-Algorithm")
  valid_602796 = validateParameter(valid_602796, JString, required = false,
                                 default = nil)
  if valid_602796 != nil:
    section.add "X-Amz-Algorithm", valid_602796
  var valid_602797 = header.getOrDefault("X-Amz-Signature")
  valid_602797 = validateParameter(valid_602797, JString, required = false,
                                 default = nil)
  if valid_602797 != nil:
    section.add "X-Amz-Signature", valid_602797
  var valid_602798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "X-Amz-SignedHeaders", valid_602798
  var valid_602799 = header.getOrDefault("X-Amz-Credential")
  valid_602799 = validateParameter(valid_602799, JString, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "X-Amz-Credential", valid_602799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602800: Call_GetRemoveTagsFromResource_602786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602800.validator(path, query, header, formData, body)
  let scheme = call_602800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602800.url(scheme.get, call_602800.host, call_602800.base,
                         call_602800.route, valid.getOrDefault("path"))
  result = hook(call_602800, url, valid)

proc call*(call_602801: Call_GetRemoveTagsFromResource_602786;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_602802 = newJObject()
  add(query_602802, "ResourceName", newJString(ResourceName))
  add(query_602802, "Action", newJString(Action))
  if TagKeys != nil:
    query_602802.add "TagKeys", TagKeys
  add(query_602802, "Version", newJString(Version))
  result = call_602801.call(nil, query_602802, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_602786(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_602787, base: "/",
    url: url_GetRemoveTagsFromResource_602788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_602839 = ref object of OpenApiRestCall_600410
proc url_PostResetDBParameterGroup_602841(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_602840(path: JsonNode; query: JsonNode;
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
  var valid_602842 = query.getOrDefault("Action")
  valid_602842 = validateParameter(valid_602842, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602842 != nil:
    section.add "Action", valid_602842
  var valid_602843 = query.getOrDefault("Version")
  valid_602843 = validateParameter(valid_602843, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602843 != nil:
    section.add "Version", valid_602843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602844 = header.getOrDefault("X-Amz-Date")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Date", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Security-Token")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Security-Token", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Content-Sha256", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Algorithm")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Algorithm", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Signature")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Signature", valid_602848
  var valid_602849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602849 = validateParameter(valid_602849, JString, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "X-Amz-SignedHeaders", valid_602849
  var valid_602850 = header.getOrDefault("X-Amz-Credential")
  valid_602850 = validateParameter(valid_602850, JString, required = false,
                                 default = nil)
  if valid_602850 != nil:
    section.add "X-Amz-Credential", valid_602850
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602851 = formData.getOrDefault("DBParameterGroupName")
  valid_602851 = validateParameter(valid_602851, JString, required = true,
                                 default = nil)
  if valid_602851 != nil:
    section.add "DBParameterGroupName", valid_602851
  var valid_602852 = formData.getOrDefault("Parameters")
  valid_602852 = validateParameter(valid_602852, JArray, required = false,
                                 default = nil)
  if valid_602852 != nil:
    section.add "Parameters", valid_602852
  var valid_602853 = formData.getOrDefault("ResetAllParameters")
  valid_602853 = validateParameter(valid_602853, JBool, required = false, default = nil)
  if valid_602853 != nil:
    section.add "ResetAllParameters", valid_602853
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602854: Call_PostResetDBParameterGroup_602839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602854.validator(path, query, header, formData, body)
  let scheme = call_602854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602854.url(scheme.get, call_602854.host, call_602854.base,
                         call_602854.route, valid.getOrDefault("path"))
  result = hook(call_602854, url, valid)

proc call*(call_602855: Call_PostResetDBParameterGroup_602839;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602856 = newJObject()
  var formData_602857 = newJObject()
  add(formData_602857, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602857.add "Parameters", Parameters
  add(query_602856, "Action", newJString(Action))
  add(formData_602857, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602856, "Version", newJString(Version))
  result = call_602855.call(nil, query_602856, nil, formData_602857, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_602839(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_602840, base: "/",
    url: url_PostResetDBParameterGroup_602841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_602821 = ref object of OpenApiRestCall_600410
proc url_GetResetDBParameterGroup_602823(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_602822(path: JsonNode; query: JsonNode;
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
  var valid_602824 = query.getOrDefault("DBParameterGroupName")
  valid_602824 = validateParameter(valid_602824, JString, required = true,
                                 default = nil)
  if valid_602824 != nil:
    section.add "DBParameterGroupName", valid_602824
  var valid_602825 = query.getOrDefault("Parameters")
  valid_602825 = validateParameter(valid_602825, JArray, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "Parameters", valid_602825
  var valid_602826 = query.getOrDefault("Action")
  valid_602826 = validateParameter(valid_602826, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602826 != nil:
    section.add "Action", valid_602826
  var valid_602827 = query.getOrDefault("ResetAllParameters")
  valid_602827 = validateParameter(valid_602827, JBool, required = false, default = nil)
  if valid_602827 != nil:
    section.add "ResetAllParameters", valid_602827
  var valid_602828 = query.getOrDefault("Version")
  valid_602828 = validateParameter(valid_602828, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602828 != nil:
    section.add "Version", valid_602828
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602829 = header.getOrDefault("X-Amz-Date")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Date", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Security-Token")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Security-Token", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-Content-Sha256", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Algorithm")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Algorithm", valid_602832
  var valid_602833 = header.getOrDefault("X-Amz-Signature")
  valid_602833 = validateParameter(valid_602833, JString, required = false,
                                 default = nil)
  if valid_602833 != nil:
    section.add "X-Amz-Signature", valid_602833
  var valid_602834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602834 = validateParameter(valid_602834, JString, required = false,
                                 default = nil)
  if valid_602834 != nil:
    section.add "X-Amz-SignedHeaders", valid_602834
  var valid_602835 = header.getOrDefault("X-Amz-Credential")
  valid_602835 = validateParameter(valid_602835, JString, required = false,
                                 default = nil)
  if valid_602835 != nil:
    section.add "X-Amz-Credential", valid_602835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602836: Call_GetResetDBParameterGroup_602821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602836.validator(path, query, header, formData, body)
  let scheme = call_602836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602836.url(scheme.get, call_602836.host, call_602836.base,
                         call_602836.route, valid.getOrDefault("path"))
  result = hook(call_602836, url, valid)

proc call*(call_602837: Call_GetResetDBParameterGroup_602821;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602838 = newJObject()
  add(query_602838, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602838.add "Parameters", Parameters
  add(query_602838, "Action", newJString(Action))
  add(query_602838, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602838, "Version", newJString(Version))
  result = call_602837.call(nil, query_602838, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_602821(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_602822, base: "/",
    url: url_GetResetDBParameterGroup_602823, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_602887 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceFromDBSnapshot_602889(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_602888(path: JsonNode;
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
  var valid_602890 = query.getOrDefault("Action")
  valid_602890 = validateParameter(valid_602890, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602890 != nil:
    section.add "Action", valid_602890
  var valid_602891 = query.getOrDefault("Version")
  valid_602891 = validateParameter(valid_602891, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602891 != nil:
    section.add "Version", valid_602891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602892 = header.getOrDefault("X-Amz-Date")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Date", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Security-Token")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Security-Token", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Content-Sha256", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-Algorithm")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Algorithm", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Signature")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Signature", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-SignedHeaders", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Credential")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Credential", valid_602898
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
  var valid_602899 = formData.getOrDefault("Port")
  valid_602899 = validateParameter(valid_602899, JInt, required = false, default = nil)
  if valid_602899 != nil:
    section.add "Port", valid_602899
  var valid_602900 = formData.getOrDefault("Engine")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "Engine", valid_602900
  var valid_602901 = formData.getOrDefault("Iops")
  valid_602901 = validateParameter(valid_602901, JInt, required = false, default = nil)
  if valid_602901 != nil:
    section.add "Iops", valid_602901
  var valid_602902 = formData.getOrDefault("DBName")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "DBName", valid_602902
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602903 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602903 = validateParameter(valid_602903, JString, required = true,
                                 default = nil)
  if valid_602903 != nil:
    section.add "DBInstanceIdentifier", valid_602903
  var valid_602904 = formData.getOrDefault("OptionGroupName")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "OptionGroupName", valid_602904
  var valid_602905 = formData.getOrDefault("DBSubnetGroupName")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "DBSubnetGroupName", valid_602905
  var valid_602906 = formData.getOrDefault("AvailabilityZone")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "AvailabilityZone", valid_602906
  var valid_602907 = formData.getOrDefault("MultiAZ")
  valid_602907 = validateParameter(valid_602907, JBool, required = false, default = nil)
  if valid_602907 != nil:
    section.add "MultiAZ", valid_602907
  var valid_602908 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602908 = validateParameter(valid_602908, JString, required = true,
                                 default = nil)
  if valid_602908 != nil:
    section.add "DBSnapshotIdentifier", valid_602908
  var valid_602909 = formData.getOrDefault("PubliclyAccessible")
  valid_602909 = validateParameter(valid_602909, JBool, required = false, default = nil)
  if valid_602909 != nil:
    section.add "PubliclyAccessible", valid_602909
  var valid_602910 = formData.getOrDefault("DBInstanceClass")
  valid_602910 = validateParameter(valid_602910, JString, required = false,
                                 default = nil)
  if valid_602910 != nil:
    section.add "DBInstanceClass", valid_602910
  var valid_602911 = formData.getOrDefault("LicenseModel")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "LicenseModel", valid_602911
  var valid_602912 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602912 = validateParameter(valid_602912, JBool, required = false, default = nil)
  if valid_602912 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602912
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602913: Call_PostRestoreDBInstanceFromDBSnapshot_602887;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602913.validator(path, query, header, formData, body)
  let scheme = call_602913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602913.url(scheme.get, call_602913.host, call_602913.base,
                         call_602913.route, valid.getOrDefault("path"))
  result = hook(call_602913, url, valid)

proc call*(call_602914: Call_PostRestoreDBInstanceFromDBSnapshot_602887;
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
  var query_602915 = newJObject()
  var formData_602916 = newJObject()
  add(formData_602916, "Port", newJInt(Port))
  add(formData_602916, "Engine", newJString(Engine))
  add(formData_602916, "Iops", newJInt(Iops))
  add(formData_602916, "DBName", newJString(DBName))
  add(formData_602916, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602916, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602916, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602916, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602916, "MultiAZ", newJBool(MultiAZ))
  add(formData_602916, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602915, "Action", newJString(Action))
  add(formData_602916, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_602916, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602916, "LicenseModel", newJString(LicenseModel))
  add(formData_602916, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_602915, "Version", newJString(Version))
  result = call_602914.call(nil, query_602915, nil, formData_602916, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_602887(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_602888, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_602889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_602858 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceFromDBSnapshot_602860(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_602859(path: JsonNode;
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
  var valid_602861 = query.getOrDefault("Engine")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "Engine", valid_602861
  var valid_602862 = query.getOrDefault("OptionGroupName")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "OptionGroupName", valid_602862
  var valid_602863 = query.getOrDefault("AvailabilityZone")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "AvailabilityZone", valid_602863
  var valid_602864 = query.getOrDefault("Iops")
  valid_602864 = validateParameter(valid_602864, JInt, required = false, default = nil)
  if valid_602864 != nil:
    section.add "Iops", valid_602864
  var valid_602865 = query.getOrDefault("MultiAZ")
  valid_602865 = validateParameter(valid_602865, JBool, required = false, default = nil)
  if valid_602865 != nil:
    section.add "MultiAZ", valid_602865
  var valid_602866 = query.getOrDefault("LicenseModel")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "LicenseModel", valid_602866
  var valid_602867 = query.getOrDefault("DBName")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "DBName", valid_602867
  var valid_602868 = query.getOrDefault("DBInstanceClass")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "DBInstanceClass", valid_602868
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602869 = query.getOrDefault("Action")
  valid_602869 = validateParameter(valid_602869, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602869 != nil:
    section.add "Action", valid_602869
  var valid_602870 = query.getOrDefault("DBSubnetGroupName")
  valid_602870 = validateParameter(valid_602870, JString, required = false,
                                 default = nil)
  if valid_602870 != nil:
    section.add "DBSubnetGroupName", valid_602870
  var valid_602871 = query.getOrDefault("PubliclyAccessible")
  valid_602871 = validateParameter(valid_602871, JBool, required = false, default = nil)
  if valid_602871 != nil:
    section.add "PubliclyAccessible", valid_602871
  var valid_602872 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602872 = validateParameter(valid_602872, JBool, required = false, default = nil)
  if valid_602872 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602872
  var valid_602873 = query.getOrDefault("Port")
  valid_602873 = validateParameter(valid_602873, JInt, required = false, default = nil)
  if valid_602873 != nil:
    section.add "Port", valid_602873
  var valid_602874 = query.getOrDefault("Version")
  valid_602874 = validateParameter(valid_602874, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602874 != nil:
    section.add "Version", valid_602874
  var valid_602875 = query.getOrDefault("DBInstanceIdentifier")
  valid_602875 = validateParameter(valid_602875, JString, required = true,
                                 default = nil)
  if valid_602875 != nil:
    section.add "DBInstanceIdentifier", valid_602875
  var valid_602876 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602876 = validateParameter(valid_602876, JString, required = true,
                                 default = nil)
  if valid_602876 != nil:
    section.add "DBSnapshotIdentifier", valid_602876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602877 = header.getOrDefault("X-Amz-Date")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Date", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Security-Token")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Security-Token", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Content-Sha256", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-Algorithm")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Algorithm", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Signature")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Signature", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-SignedHeaders", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-Credential")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Credential", valid_602883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602884: Call_GetRestoreDBInstanceFromDBSnapshot_602858;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602884.validator(path, query, header, formData, body)
  let scheme = call_602884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602884.url(scheme.get, call_602884.host, call_602884.base,
                         call_602884.route, valid.getOrDefault("path"))
  result = hook(call_602884, url, valid)

proc call*(call_602885: Call_GetRestoreDBInstanceFromDBSnapshot_602858;
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
  var query_602886 = newJObject()
  add(query_602886, "Engine", newJString(Engine))
  add(query_602886, "OptionGroupName", newJString(OptionGroupName))
  add(query_602886, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602886, "Iops", newJInt(Iops))
  add(query_602886, "MultiAZ", newJBool(MultiAZ))
  add(query_602886, "LicenseModel", newJString(LicenseModel))
  add(query_602886, "DBName", newJString(DBName))
  add(query_602886, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602886, "Action", newJString(Action))
  add(query_602886, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602886, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602886, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602886, "Port", newJInt(Port))
  add(query_602886, "Version", newJString(Version))
  add(query_602886, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602886, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602885.call(nil, query_602886, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_602858(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_602859, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_602860,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_602948 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceToPointInTime_602950(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_602949(path: JsonNode;
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
  var valid_602951 = query.getOrDefault("Action")
  valid_602951 = validateParameter(valid_602951, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_602951 != nil:
    section.add "Action", valid_602951
  var valid_602952 = query.getOrDefault("Version")
  valid_602952 = validateParameter(valid_602952, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602952 != nil:
    section.add "Version", valid_602952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602953 = header.getOrDefault("X-Amz-Date")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-Date", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Security-Token")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Security-Token", valid_602954
  var valid_602955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Content-Sha256", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-Algorithm")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Algorithm", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-Signature")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Signature", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-SignedHeaders", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-Credential")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Credential", valid_602959
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
  var valid_602960 = formData.getOrDefault("UseLatestRestorableTime")
  valid_602960 = validateParameter(valid_602960, JBool, required = false, default = nil)
  if valid_602960 != nil:
    section.add "UseLatestRestorableTime", valid_602960
  var valid_602961 = formData.getOrDefault("Port")
  valid_602961 = validateParameter(valid_602961, JInt, required = false, default = nil)
  if valid_602961 != nil:
    section.add "Port", valid_602961
  var valid_602962 = formData.getOrDefault("Engine")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "Engine", valid_602962
  var valid_602963 = formData.getOrDefault("Iops")
  valid_602963 = validateParameter(valid_602963, JInt, required = false, default = nil)
  if valid_602963 != nil:
    section.add "Iops", valid_602963
  var valid_602964 = formData.getOrDefault("DBName")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "DBName", valid_602964
  var valid_602965 = formData.getOrDefault("OptionGroupName")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "OptionGroupName", valid_602965
  var valid_602966 = formData.getOrDefault("DBSubnetGroupName")
  valid_602966 = validateParameter(valid_602966, JString, required = false,
                                 default = nil)
  if valid_602966 != nil:
    section.add "DBSubnetGroupName", valid_602966
  var valid_602967 = formData.getOrDefault("AvailabilityZone")
  valid_602967 = validateParameter(valid_602967, JString, required = false,
                                 default = nil)
  if valid_602967 != nil:
    section.add "AvailabilityZone", valid_602967
  var valid_602968 = formData.getOrDefault("MultiAZ")
  valid_602968 = validateParameter(valid_602968, JBool, required = false, default = nil)
  if valid_602968 != nil:
    section.add "MultiAZ", valid_602968
  var valid_602969 = formData.getOrDefault("RestoreTime")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "RestoreTime", valid_602969
  var valid_602970 = formData.getOrDefault("PubliclyAccessible")
  valid_602970 = validateParameter(valid_602970, JBool, required = false, default = nil)
  if valid_602970 != nil:
    section.add "PubliclyAccessible", valid_602970
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_602971 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_602971 = validateParameter(valid_602971, JString, required = true,
                                 default = nil)
  if valid_602971 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602971
  var valid_602972 = formData.getOrDefault("DBInstanceClass")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "DBInstanceClass", valid_602972
  var valid_602973 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_602973 = validateParameter(valid_602973, JString, required = true,
                                 default = nil)
  if valid_602973 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602973
  var valid_602974 = formData.getOrDefault("LicenseModel")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "LicenseModel", valid_602974
  var valid_602975 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602975 = validateParameter(valid_602975, JBool, required = false, default = nil)
  if valid_602975 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602975
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602976: Call_PostRestoreDBInstanceToPointInTime_602948;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602976.validator(path, query, header, formData, body)
  let scheme = call_602976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602976.url(scheme.get, call_602976.host, call_602976.base,
                         call_602976.route, valid.getOrDefault("path"))
  result = hook(call_602976, url, valid)

proc call*(call_602977: Call_PostRestoreDBInstanceToPointInTime_602948;
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
  var query_602978 = newJObject()
  var formData_602979 = newJObject()
  add(formData_602979, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_602979, "Port", newJInt(Port))
  add(formData_602979, "Engine", newJString(Engine))
  add(formData_602979, "Iops", newJInt(Iops))
  add(formData_602979, "DBName", newJString(DBName))
  add(formData_602979, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602979, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602979, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602979, "MultiAZ", newJBool(MultiAZ))
  add(query_602978, "Action", newJString(Action))
  add(formData_602979, "RestoreTime", newJString(RestoreTime))
  add(formData_602979, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_602979, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_602979, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602979, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_602979, "LicenseModel", newJString(LicenseModel))
  add(formData_602979, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_602978, "Version", newJString(Version))
  result = call_602977.call(nil, query_602978, nil, formData_602979, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_602948(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_602949, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_602950,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_602917 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceToPointInTime_602919(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_602918(path: JsonNode;
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
  var valid_602920 = query.getOrDefault("Engine")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "Engine", valid_602920
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_602921 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_602921 = validateParameter(valid_602921, JString, required = true,
                                 default = nil)
  if valid_602921 != nil:
    section.add "SourceDBInstanceIdentifier", valid_602921
  var valid_602922 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_602922 = validateParameter(valid_602922, JString, required = true,
                                 default = nil)
  if valid_602922 != nil:
    section.add "TargetDBInstanceIdentifier", valid_602922
  var valid_602923 = query.getOrDefault("AvailabilityZone")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "AvailabilityZone", valid_602923
  var valid_602924 = query.getOrDefault("Iops")
  valid_602924 = validateParameter(valid_602924, JInt, required = false, default = nil)
  if valid_602924 != nil:
    section.add "Iops", valid_602924
  var valid_602925 = query.getOrDefault("OptionGroupName")
  valid_602925 = validateParameter(valid_602925, JString, required = false,
                                 default = nil)
  if valid_602925 != nil:
    section.add "OptionGroupName", valid_602925
  var valid_602926 = query.getOrDefault("RestoreTime")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "RestoreTime", valid_602926
  var valid_602927 = query.getOrDefault("MultiAZ")
  valid_602927 = validateParameter(valid_602927, JBool, required = false, default = nil)
  if valid_602927 != nil:
    section.add "MultiAZ", valid_602927
  var valid_602928 = query.getOrDefault("LicenseModel")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "LicenseModel", valid_602928
  var valid_602929 = query.getOrDefault("DBName")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "DBName", valid_602929
  var valid_602930 = query.getOrDefault("DBInstanceClass")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "DBInstanceClass", valid_602930
  var valid_602931 = query.getOrDefault("Action")
  valid_602931 = validateParameter(valid_602931, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_602931 != nil:
    section.add "Action", valid_602931
  var valid_602932 = query.getOrDefault("UseLatestRestorableTime")
  valid_602932 = validateParameter(valid_602932, JBool, required = false, default = nil)
  if valid_602932 != nil:
    section.add "UseLatestRestorableTime", valid_602932
  var valid_602933 = query.getOrDefault("DBSubnetGroupName")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "DBSubnetGroupName", valid_602933
  var valid_602934 = query.getOrDefault("PubliclyAccessible")
  valid_602934 = validateParameter(valid_602934, JBool, required = false, default = nil)
  if valid_602934 != nil:
    section.add "PubliclyAccessible", valid_602934
  var valid_602935 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602935 = validateParameter(valid_602935, JBool, required = false, default = nil)
  if valid_602935 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602935
  var valid_602936 = query.getOrDefault("Port")
  valid_602936 = validateParameter(valid_602936, JInt, required = false, default = nil)
  if valid_602936 != nil:
    section.add "Port", valid_602936
  var valid_602937 = query.getOrDefault("Version")
  valid_602937 = validateParameter(valid_602937, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602937 != nil:
    section.add "Version", valid_602937
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602938 = header.getOrDefault("X-Amz-Date")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-Date", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Security-Token")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Security-Token", valid_602939
  var valid_602940 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "X-Amz-Content-Sha256", valid_602940
  var valid_602941 = header.getOrDefault("X-Amz-Algorithm")
  valid_602941 = validateParameter(valid_602941, JString, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "X-Amz-Algorithm", valid_602941
  var valid_602942 = header.getOrDefault("X-Amz-Signature")
  valid_602942 = validateParameter(valid_602942, JString, required = false,
                                 default = nil)
  if valid_602942 != nil:
    section.add "X-Amz-Signature", valid_602942
  var valid_602943 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "X-Amz-SignedHeaders", valid_602943
  var valid_602944 = header.getOrDefault("X-Amz-Credential")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "X-Amz-Credential", valid_602944
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602945: Call_GetRestoreDBInstanceToPointInTime_602917;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602945.validator(path, query, header, formData, body)
  let scheme = call_602945.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602945.url(scheme.get, call_602945.host, call_602945.base,
                         call_602945.route, valid.getOrDefault("path"))
  result = hook(call_602945, url, valid)

proc call*(call_602946: Call_GetRestoreDBInstanceToPointInTime_602917;
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
  var query_602947 = newJObject()
  add(query_602947, "Engine", newJString(Engine))
  add(query_602947, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_602947, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_602947, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602947, "Iops", newJInt(Iops))
  add(query_602947, "OptionGroupName", newJString(OptionGroupName))
  add(query_602947, "RestoreTime", newJString(RestoreTime))
  add(query_602947, "MultiAZ", newJBool(MultiAZ))
  add(query_602947, "LicenseModel", newJString(LicenseModel))
  add(query_602947, "DBName", newJString(DBName))
  add(query_602947, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602947, "Action", newJString(Action))
  add(query_602947, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_602947, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602947, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602947, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602947, "Port", newJInt(Port))
  add(query_602947, "Version", newJString(Version))
  result = call_602946.call(nil, query_602947, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_602917(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_602918, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_602919,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603000 = ref object of OpenApiRestCall_600410
proc url_PostRevokeDBSecurityGroupIngress_603002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_603001(path: JsonNode;
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
  var valid_603003 = query.getOrDefault("Action")
  valid_603003 = validateParameter(valid_603003, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603003 != nil:
    section.add "Action", valid_603003
  var valid_603004 = query.getOrDefault("Version")
  valid_603004 = validateParameter(valid_603004, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603004 != nil:
    section.add "Version", valid_603004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603005 = header.getOrDefault("X-Amz-Date")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "X-Amz-Date", valid_603005
  var valid_603006 = header.getOrDefault("X-Amz-Security-Token")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "X-Amz-Security-Token", valid_603006
  var valid_603007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "X-Amz-Content-Sha256", valid_603007
  var valid_603008 = header.getOrDefault("X-Amz-Algorithm")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "X-Amz-Algorithm", valid_603008
  var valid_603009 = header.getOrDefault("X-Amz-Signature")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "X-Amz-Signature", valid_603009
  var valid_603010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "X-Amz-SignedHeaders", valid_603010
  var valid_603011 = header.getOrDefault("X-Amz-Credential")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "X-Amz-Credential", valid_603011
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603012 = formData.getOrDefault("DBSecurityGroupName")
  valid_603012 = validateParameter(valid_603012, JString, required = true,
                                 default = nil)
  if valid_603012 != nil:
    section.add "DBSecurityGroupName", valid_603012
  var valid_603013 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603013 = validateParameter(valid_603013, JString, required = false,
                                 default = nil)
  if valid_603013 != nil:
    section.add "EC2SecurityGroupName", valid_603013
  var valid_603014 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603014 = validateParameter(valid_603014, JString, required = false,
                                 default = nil)
  if valid_603014 != nil:
    section.add "EC2SecurityGroupId", valid_603014
  var valid_603015 = formData.getOrDefault("CIDRIP")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "CIDRIP", valid_603015
  var valid_603016 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603016 = validateParameter(valid_603016, JString, required = false,
                                 default = nil)
  if valid_603016 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603017: Call_PostRevokeDBSecurityGroupIngress_603000;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603017.validator(path, query, header, formData, body)
  let scheme = call_603017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603017.url(scheme.get, call_603017.host, call_603017.base,
                         call_603017.route, valid.getOrDefault("path"))
  result = hook(call_603017, url, valid)

proc call*(call_603018: Call_PostRevokeDBSecurityGroupIngress_603000;
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
  var query_603019 = newJObject()
  var formData_603020 = newJObject()
  add(formData_603020, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603019, "Action", newJString(Action))
  add(formData_603020, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603020, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603020, "CIDRIP", newJString(CIDRIP))
  add(query_603019, "Version", newJString(Version))
  add(formData_603020, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603018.call(nil, query_603019, nil, formData_603020, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603000(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603001, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_602980 = ref object of OpenApiRestCall_600410
proc url_GetRevokeDBSecurityGroupIngress_602982(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_602981(path: JsonNode;
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
  var valid_602983 = query.getOrDefault("EC2SecurityGroupId")
  valid_602983 = validateParameter(valid_602983, JString, required = false,
                                 default = nil)
  if valid_602983 != nil:
    section.add "EC2SecurityGroupId", valid_602983
  var valid_602984 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_602984
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_602985 = query.getOrDefault("DBSecurityGroupName")
  valid_602985 = validateParameter(valid_602985, JString, required = true,
                                 default = nil)
  if valid_602985 != nil:
    section.add "DBSecurityGroupName", valid_602985
  var valid_602986 = query.getOrDefault("Action")
  valid_602986 = validateParameter(valid_602986, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_602986 != nil:
    section.add "Action", valid_602986
  var valid_602987 = query.getOrDefault("CIDRIP")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "CIDRIP", valid_602987
  var valid_602988 = query.getOrDefault("EC2SecurityGroupName")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "EC2SecurityGroupName", valid_602988
  var valid_602989 = query.getOrDefault("Version")
  valid_602989 = validateParameter(valid_602989, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_602989 != nil:
    section.add "Version", valid_602989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602990 = header.getOrDefault("X-Amz-Date")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Date", valid_602990
  var valid_602991 = header.getOrDefault("X-Amz-Security-Token")
  valid_602991 = validateParameter(valid_602991, JString, required = false,
                                 default = nil)
  if valid_602991 != nil:
    section.add "X-Amz-Security-Token", valid_602991
  var valid_602992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "X-Amz-Content-Sha256", valid_602992
  var valid_602993 = header.getOrDefault("X-Amz-Algorithm")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "X-Amz-Algorithm", valid_602993
  var valid_602994 = header.getOrDefault("X-Amz-Signature")
  valid_602994 = validateParameter(valid_602994, JString, required = false,
                                 default = nil)
  if valid_602994 != nil:
    section.add "X-Amz-Signature", valid_602994
  var valid_602995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602995 = validateParameter(valid_602995, JString, required = false,
                                 default = nil)
  if valid_602995 != nil:
    section.add "X-Amz-SignedHeaders", valid_602995
  var valid_602996 = header.getOrDefault("X-Amz-Credential")
  valid_602996 = validateParameter(valid_602996, JString, required = false,
                                 default = nil)
  if valid_602996 != nil:
    section.add "X-Amz-Credential", valid_602996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602997: Call_GetRevokeDBSecurityGroupIngress_602980;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602997.validator(path, query, header, formData, body)
  let scheme = call_602997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602997.url(scheme.get, call_602997.host, call_602997.base,
                         call_602997.route, valid.getOrDefault("path"))
  result = hook(call_602997, url, valid)

proc call*(call_602998: Call_GetRevokeDBSecurityGroupIngress_602980;
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
  var query_602999 = newJObject()
  add(query_602999, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_602999, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_602999, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_602999, "Action", newJString(Action))
  add(query_602999, "CIDRIP", newJString(CIDRIP))
  add(query_602999, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_602999, "Version", newJString(Version))
  result = call_602998.call(nil, query_602999, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_602980(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_602981, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_602982,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

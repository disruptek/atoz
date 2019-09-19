
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
                                 default = newJString("2013-09-09"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
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
  Call_PostCopyDBSnapshot_601136 = ref object of OpenApiRestCall_600410
proc url_PostCopyDBSnapshot_601138(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_601137(path: JsonNode; query: JsonNode;
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
  var valid_601139 = query.getOrDefault("Action")
  valid_601139 = validateParameter(valid_601139, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601139 != nil:
    section.add "Action", valid_601139
  var valid_601140 = query.getOrDefault("Version")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601148 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601148 = validateParameter(valid_601148, JString, required = true,
                                 default = nil)
  if valid_601148 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601148
  var valid_601149 = formData.getOrDefault("Tags")
  valid_601149 = validateParameter(valid_601149, JArray, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "Tags", valid_601149
  var valid_601150 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601150 = validateParameter(valid_601150, JString, required = true,
                                 default = nil)
  if valid_601150 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601151: Call_PostCopyDBSnapshot_601136; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601151.validator(path, query, header, formData, body)
  let scheme = call_601151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601151.url(scheme.get, call_601151.host, call_601151.base,
                         call_601151.route, valid.getOrDefault("path"))
  result = hook(call_601151, url, valid)

proc call*(call_601152: Call_PostCopyDBSnapshot_601136;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601153 = newJObject()
  var formData_601154 = newJObject()
  add(formData_601154, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_601154.add "Tags", Tags
  add(query_601153, "Action", newJString(Action))
  add(formData_601154, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601153, "Version", newJString(Version))
  result = call_601152.call(nil, query_601153, nil, formData_601154, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_601136(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_601137, base: "/",
    url: url_PostCopyDBSnapshot_601138, schemes: {Scheme.Https, Scheme.Http})
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
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_601121 = query.getOrDefault("Tags")
  valid_601121 = validateParameter(valid_601121, JArray, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "Tags", valid_601121
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601122 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = nil)
  if valid_601122 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601122
  var valid_601123 = query.getOrDefault("Action")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601123 != nil:
    section.add "Action", valid_601123
  var valid_601124 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = nil)
  if valid_601124 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601124
  var valid_601125 = query.getOrDefault("Version")
  valid_601125 = validateParameter(valid_601125, JString, required = true,
                                 default = newJString("2013-09-09"))
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

proc call*(call_601133: Call_GetCopyDBSnapshot_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601133.validator(path, query, header, formData, body)
  let scheme = call_601133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601133.url(scheme.get, call_601133.host, call_601133.base,
                         call_601133.route, valid.getOrDefault("path"))
  result = hook(call_601133, url, valid)

proc call*(call_601134: Call_GetCopyDBSnapshot_601118;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601135 = newJObject()
  if Tags != nil:
    query_601135.add "Tags", Tags
  add(query_601135, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601135, "Action", newJString(Action))
  add(query_601135, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601135, "Version", newJString(Version))
  result = call_601134.call(nil, query_601135, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_601118(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_601119,
    base: "/", url: url_GetCopyDBSnapshot_601120,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_601195 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBInstance_601197(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_601196(path: JsonNode; query: JsonNode;
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
  var valid_601198 = query.getOrDefault("Action")
  valid_601198 = validateParameter(valid_601198, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601198 != nil:
    section.add "Action", valid_601198
  var valid_601199 = query.getOrDefault("Version")
  valid_601199 = validateParameter(valid_601199, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  var valid_601207 = formData.getOrDefault("DBSecurityGroups")
  valid_601207 = validateParameter(valid_601207, JArray, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "DBSecurityGroups", valid_601207
  var valid_601208 = formData.getOrDefault("Port")
  valid_601208 = validateParameter(valid_601208, JInt, required = false, default = nil)
  if valid_601208 != nil:
    section.add "Port", valid_601208
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601209 = formData.getOrDefault("Engine")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = nil)
  if valid_601209 != nil:
    section.add "Engine", valid_601209
  var valid_601210 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601210 = validateParameter(valid_601210, JArray, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "VpcSecurityGroupIds", valid_601210
  var valid_601211 = formData.getOrDefault("Iops")
  valid_601211 = validateParameter(valid_601211, JInt, required = false, default = nil)
  if valid_601211 != nil:
    section.add "Iops", valid_601211
  var valid_601212 = formData.getOrDefault("DBName")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "DBName", valid_601212
  var valid_601213 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601213 = validateParameter(valid_601213, JString, required = true,
                                 default = nil)
  if valid_601213 != nil:
    section.add "DBInstanceIdentifier", valid_601213
  var valid_601214 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601214 = validateParameter(valid_601214, JInt, required = false, default = nil)
  if valid_601214 != nil:
    section.add "BackupRetentionPeriod", valid_601214
  var valid_601215 = formData.getOrDefault("DBParameterGroupName")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "DBParameterGroupName", valid_601215
  var valid_601216 = formData.getOrDefault("OptionGroupName")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "OptionGroupName", valid_601216
  var valid_601217 = formData.getOrDefault("Tags")
  valid_601217 = validateParameter(valid_601217, JArray, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "Tags", valid_601217
  var valid_601218 = formData.getOrDefault("MasterUserPassword")
  valid_601218 = validateParameter(valid_601218, JString, required = true,
                                 default = nil)
  if valid_601218 != nil:
    section.add "MasterUserPassword", valid_601218
  var valid_601219 = formData.getOrDefault("DBSubnetGroupName")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "DBSubnetGroupName", valid_601219
  var valid_601220 = formData.getOrDefault("AvailabilityZone")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "AvailabilityZone", valid_601220
  var valid_601221 = formData.getOrDefault("MultiAZ")
  valid_601221 = validateParameter(valid_601221, JBool, required = false, default = nil)
  if valid_601221 != nil:
    section.add "MultiAZ", valid_601221
  var valid_601222 = formData.getOrDefault("AllocatedStorage")
  valid_601222 = validateParameter(valid_601222, JInt, required = true, default = nil)
  if valid_601222 != nil:
    section.add "AllocatedStorage", valid_601222
  var valid_601223 = formData.getOrDefault("PubliclyAccessible")
  valid_601223 = validateParameter(valid_601223, JBool, required = false, default = nil)
  if valid_601223 != nil:
    section.add "PubliclyAccessible", valid_601223
  var valid_601224 = formData.getOrDefault("MasterUsername")
  valid_601224 = validateParameter(valid_601224, JString, required = true,
                                 default = nil)
  if valid_601224 != nil:
    section.add "MasterUsername", valid_601224
  var valid_601225 = formData.getOrDefault("DBInstanceClass")
  valid_601225 = validateParameter(valid_601225, JString, required = true,
                                 default = nil)
  if valid_601225 != nil:
    section.add "DBInstanceClass", valid_601225
  var valid_601226 = formData.getOrDefault("CharacterSetName")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "CharacterSetName", valid_601226
  var valid_601227 = formData.getOrDefault("PreferredBackupWindow")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "PreferredBackupWindow", valid_601227
  var valid_601228 = formData.getOrDefault("LicenseModel")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "LicenseModel", valid_601228
  var valid_601229 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601229 = validateParameter(valid_601229, JBool, required = false, default = nil)
  if valid_601229 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601229
  var valid_601230 = formData.getOrDefault("EngineVersion")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "EngineVersion", valid_601230
  var valid_601231 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "PreferredMaintenanceWindow", valid_601231
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601232: Call_PostCreateDBInstance_601195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601232.validator(path, query, header, formData, body)
  let scheme = call_601232.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601232.url(scheme.get, call_601232.host, call_601232.base,
                         call_601232.route, valid.getOrDefault("path"))
  result = hook(call_601232, url, valid)

proc call*(call_601233: Call_PostCreateDBInstance_601195; Engine: string;
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
  var query_601234 = newJObject()
  var formData_601235 = newJObject()
  if DBSecurityGroups != nil:
    formData_601235.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601235, "Port", newJInt(Port))
  add(formData_601235, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_601235.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601235, "Iops", newJInt(Iops))
  add(formData_601235, "DBName", newJString(DBName))
  add(formData_601235, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601235, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601235, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601235, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601235.add "Tags", Tags
  add(formData_601235, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601235, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601235, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601235, "MultiAZ", newJBool(MultiAZ))
  add(query_601234, "Action", newJString(Action))
  add(formData_601235, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601235, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601235, "MasterUsername", newJString(MasterUsername))
  add(formData_601235, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601235, "CharacterSetName", newJString(CharacterSetName))
  add(formData_601235, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601235, "LicenseModel", newJString(LicenseModel))
  add(formData_601235, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601235, "EngineVersion", newJString(EngineVersion))
  add(query_601234, "Version", newJString(Version))
  add(formData_601235, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601233.call(nil, query_601234, nil, formData_601235, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_601195(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_601196, base: "/",
    url: url_PostCreateDBInstance_601197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_601155 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBInstance_601157(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_601156(path: JsonNode; query: JsonNode;
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
  var valid_601158 = query.getOrDefault("Engine")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = nil)
  if valid_601158 != nil:
    section.add "Engine", valid_601158
  var valid_601159 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "PreferredMaintenanceWindow", valid_601159
  var valid_601160 = query.getOrDefault("AllocatedStorage")
  valid_601160 = validateParameter(valid_601160, JInt, required = true, default = nil)
  if valid_601160 != nil:
    section.add "AllocatedStorage", valid_601160
  var valid_601161 = query.getOrDefault("OptionGroupName")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "OptionGroupName", valid_601161
  var valid_601162 = query.getOrDefault("DBSecurityGroups")
  valid_601162 = validateParameter(valid_601162, JArray, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "DBSecurityGroups", valid_601162
  var valid_601163 = query.getOrDefault("MasterUserPassword")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "MasterUserPassword", valid_601163
  var valid_601164 = query.getOrDefault("AvailabilityZone")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "AvailabilityZone", valid_601164
  var valid_601165 = query.getOrDefault("Iops")
  valid_601165 = validateParameter(valid_601165, JInt, required = false, default = nil)
  if valid_601165 != nil:
    section.add "Iops", valid_601165
  var valid_601166 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601166 = validateParameter(valid_601166, JArray, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "VpcSecurityGroupIds", valid_601166
  var valid_601167 = query.getOrDefault("MultiAZ")
  valid_601167 = validateParameter(valid_601167, JBool, required = false, default = nil)
  if valid_601167 != nil:
    section.add "MultiAZ", valid_601167
  var valid_601168 = query.getOrDefault("LicenseModel")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "LicenseModel", valid_601168
  var valid_601169 = query.getOrDefault("BackupRetentionPeriod")
  valid_601169 = validateParameter(valid_601169, JInt, required = false, default = nil)
  if valid_601169 != nil:
    section.add "BackupRetentionPeriod", valid_601169
  var valid_601170 = query.getOrDefault("DBName")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "DBName", valid_601170
  var valid_601171 = query.getOrDefault("DBParameterGroupName")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "DBParameterGroupName", valid_601171
  var valid_601172 = query.getOrDefault("Tags")
  valid_601172 = validateParameter(valid_601172, JArray, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "Tags", valid_601172
  var valid_601173 = query.getOrDefault("DBInstanceClass")
  valid_601173 = validateParameter(valid_601173, JString, required = true,
                                 default = nil)
  if valid_601173 != nil:
    section.add "DBInstanceClass", valid_601173
  var valid_601174 = query.getOrDefault("Action")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601174 != nil:
    section.add "Action", valid_601174
  var valid_601175 = query.getOrDefault("DBSubnetGroupName")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "DBSubnetGroupName", valid_601175
  var valid_601176 = query.getOrDefault("CharacterSetName")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "CharacterSetName", valid_601176
  var valid_601177 = query.getOrDefault("PubliclyAccessible")
  valid_601177 = validateParameter(valid_601177, JBool, required = false, default = nil)
  if valid_601177 != nil:
    section.add "PubliclyAccessible", valid_601177
  var valid_601178 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601178 = validateParameter(valid_601178, JBool, required = false, default = nil)
  if valid_601178 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601178
  var valid_601179 = query.getOrDefault("EngineVersion")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "EngineVersion", valid_601179
  var valid_601180 = query.getOrDefault("Port")
  valid_601180 = validateParameter(valid_601180, JInt, required = false, default = nil)
  if valid_601180 != nil:
    section.add "Port", valid_601180
  var valid_601181 = query.getOrDefault("PreferredBackupWindow")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "PreferredBackupWindow", valid_601181
  var valid_601182 = query.getOrDefault("Version")
  valid_601182 = validateParameter(valid_601182, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601182 != nil:
    section.add "Version", valid_601182
  var valid_601183 = query.getOrDefault("DBInstanceIdentifier")
  valid_601183 = validateParameter(valid_601183, JString, required = true,
                                 default = nil)
  if valid_601183 != nil:
    section.add "DBInstanceIdentifier", valid_601183
  var valid_601184 = query.getOrDefault("MasterUsername")
  valid_601184 = validateParameter(valid_601184, JString, required = true,
                                 default = nil)
  if valid_601184 != nil:
    section.add "MasterUsername", valid_601184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601185 = header.getOrDefault("X-Amz-Date")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-Date", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Security-Token")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Security-Token", valid_601186
  var valid_601187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601187 = validateParameter(valid_601187, JString, required = false,
                                 default = nil)
  if valid_601187 != nil:
    section.add "X-Amz-Content-Sha256", valid_601187
  var valid_601188 = header.getOrDefault("X-Amz-Algorithm")
  valid_601188 = validateParameter(valid_601188, JString, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "X-Amz-Algorithm", valid_601188
  var valid_601189 = header.getOrDefault("X-Amz-Signature")
  valid_601189 = validateParameter(valid_601189, JString, required = false,
                                 default = nil)
  if valid_601189 != nil:
    section.add "X-Amz-Signature", valid_601189
  var valid_601190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-SignedHeaders", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Credential")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Credential", valid_601191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601192: Call_GetCreateDBInstance_601155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601192.validator(path, query, header, formData, body)
  let scheme = call_601192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601192.url(scheme.get, call_601192.host, call_601192.base,
                         call_601192.route, valid.getOrDefault("path"))
  result = hook(call_601192, url, valid)

proc call*(call_601193: Call_GetCreateDBInstance_601155; Engine: string;
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
  var query_601194 = newJObject()
  add(query_601194, "Engine", newJString(Engine))
  add(query_601194, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601194, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601194, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601194.add "DBSecurityGroups", DBSecurityGroups
  add(query_601194, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601194, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601194, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601194.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601194, "MultiAZ", newJBool(MultiAZ))
  add(query_601194, "LicenseModel", newJString(LicenseModel))
  add(query_601194, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601194, "DBName", newJString(DBName))
  add(query_601194, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_601194.add "Tags", Tags
  add(query_601194, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601194, "Action", newJString(Action))
  add(query_601194, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601194, "CharacterSetName", newJString(CharacterSetName))
  add(query_601194, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601194, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601194, "EngineVersion", newJString(EngineVersion))
  add(query_601194, "Port", newJInt(Port))
  add(query_601194, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601194, "Version", newJString(Version))
  add(query_601194, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601194, "MasterUsername", newJString(MasterUsername))
  result = call_601193.call(nil, query_601194, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_601155(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_601156, base: "/",
    url: url_GetCreateDBInstance_601157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_601262 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBInstanceReadReplica_601264(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_601263(path: JsonNode;
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
  var valid_601265 = query.getOrDefault("Action")
  valid_601265 = validateParameter(valid_601265, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601265 != nil:
    section.add "Action", valid_601265
  var valid_601266 = query.getOrDefault("Version")
  valid_601266 = validateParameter(valid_601266, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601266 != nil:
    section.add "Version", valid_601266
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601267 = header.getOrDefault("X-Amz-Date")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Date", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Security-Token")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Security-Token", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Content-Sha256", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Algorithm")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Algorithm", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-Signature")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-Signature", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-SignedHeaders", valid_601272
  var valid_601273 = header.getOrDefault("X-Amz-Credential")
  valid_601273 = validateParameter(valid_601273, JString, required = false,
                                 default = nil)
  if valid_601273 != nil:
    section.add "X-Amz-Credential", valid_601273
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
  var valid_601274 = formData.getOrDefault("Port")
  valid_601274 = validateParameter(valid_601274, JInt, required = false, default = nil)
  if valid_601274 != nil:
    section.add "Port", valid_601274
  var valid_601275 = formData.getOrDefault("Iops")
  valid_601275 = validateParameter(valid_601275, JInt, required = false, default = nil)
  if valid_601275 != nil:
    section.add "Iops", valid_601275
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601276 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601276 = validateParameter(valid_601276, JString, required = true,
                                 default = nil)
  if valid_601276 != nil:
    section.add "DBInstanceIdentifier", valid_601276
  var valid_601277 = formData.getOrDefault("OptionGroupName")
  valid_601277 = validateParameter(valid_601277, JString, required = false,
                                 default = nil)
  if valid_601277 != nil:
    section.add "OptionGroupName", valid_601277
  var valid_601278 = formData.getOrDefault("Tags")
  valid_601278 = validateParameter(valid_601278, JArray, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "Tags", valid_601278
  var valid_601279 = formData.getOrDefault("DBSubnetGroupName")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "DBSubnetGroupName", valid_601279
  var valid_601280 = formData.getOrDefault("AvailabilityZone")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "AvailabilityZone", valid_601280
  var valid_601281 = formData.getOrDefault("PubliclyAccessible")
  valid_601281 = validateParameter(valid_601281, JBool, required = false, default = nil)
  if valid_601281 != nil:
    section.add "PubliclyAccessible", valid_601281
  var valid_601282 = formData.getOrDefault("DBInstanceClass")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "DBInstanceClass", valid_601282
  var valid_601283 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_601283 = validateParameter(valid_601283, JString, required = true,
                                 default = nil)
  if valid_601283 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601283
  var valid_601284 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601284 = validateParameter(valid_601284, JBool, required = false, default = nil)
  if valid_601284 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601284
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601285: Call_PostCreateDBInstanceReadReplica_601262;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601285.validator(path, query, header, formData, body)
  let scheme = call_601285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601285.url(scheme.get, call_601285.host, call_601285.base,
                         call_601285.route, valid.getOrDefault("path"))
  result = hook(call_601285, url, valid)

proc call*(call_601286: Call_PostCreateDBInstanceReadReplica_601262;
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
  var query_601287 = newJObject()
  var formData_601288 = newJObject()
  add(formData_601288, "Port", newJInt(Port))
  add(formData_601288, "Iops", newJInt(Iops))
  add(formData_601288, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601288, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601288.add "Tags", Tags
  add(formData_601288, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601288, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601287, "Action", newJString(Action))
  add(formData_601288, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601288, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601288, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_601288, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601287, "Version", newJString(Version))
  result = call_601286.call(nil, query_601287, nil, formData_601288, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_601262(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_601263, base: "/",
    url: url_PostCreateDBInstanceReadReplica_601264,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_601236 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBInstanceReadReplica_601238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_601237(path: JsonNode;
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
  var valid_601239 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_601239 = validateParameter(valid_601239, JString, required = true,
                                 default = nil)
  if valid_601239 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601239
  var valid_601240 = query.getOrDefault("OptionGroupName")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "OptionGroupName", valid_601240
  var valid_601241 = query.getOrDefault("AvailabilityZone")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "AvailabilityZone", valid_601241
  var valid_601242 = query.getOrDefault("Iops")
  valid_601242 = validateParameter(valid_601242, JInt, required = false, default = nil)
  if valid_601242 != nil:
    section.add "Iops", valid_601242
  var valid_601243 = query.getOrDefault("Tags")
  valid_601243 = validateParameter(valid_601243, JArray, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "Tags", valid_601243
  var valid_601244 = query.getOrDefault("DBInstanceClass")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "DBInstanceClass", valid_601244
  var valid_601245 = query.getOrDefault("Action")
  valid_601245 = validateParameter(valid_601245, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601245 != nil:
    section.add "Action", valid_601245
  var valid_601246 = query.getOrDefault("DBSubnetGroupName")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "DBSubnetGroupName", valid_601246
  var valid_601247 = query.getOrDefault("PubliclyAccessible")
  valid_601247 = validateParameter(valid_601247, JBool, required = false, default = nil)
  if valid_601247 != nil:
    section.add "PubliclyAccessible", valid_601247
  var valid_601248 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601248 = validateParameter(valid_601248, JBool, required = false, default = nil)
  if valid_601248 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601248
  var valid_601249 = query.getOrDefault("Port")
  valid_601249 = validateParameter(valid_601249, JInt, required = false, default = nil)
  if valid_601249 != nil:
    section.add "Port", valid_601249
  var valid_601250 = query.getOrDefault("Version")
  valid_601250 = validateParameter(valid_601250, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601250 != nil:
    section.add "Version", valid_601250
  var valid_601251 = query.getOrDefault("DBInstanceIdentifier")
  valid_601251 = validateParameter(valid_601251, JString, required = true,
                                 default = nil)
  if valid_601251 != nil:
    section.add "DBInstanceIdentifier", valid_601251
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601252 = header.getOrDefault("X-Amz-Date")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Date", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Security-Token")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Security-Token", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Content-Sha256", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Algorithm")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Algorithm", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Signature")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Signature", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-SignedHeaders", valid_601257
  var valid_601258 = header.getOrDefault("X-Amz-Credential")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Credential", valid_601258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_GetCreateDBInstanceReadReplica_601236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_GetCreateDBInstanceReadReplica_601236;
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
  var query_601261 = newJObject()
  add(query_601261, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_601261, "OptionGroupName", newJString(OptionGroupName))
  add(query_601261, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601261, "Iops", newJInt(Iops))
  if Tags != nil:
    query_601261.add "Tags", Tags
  add(query_601261, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601261, "Action", newJString(Action))
  add(query_601261, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601261, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601261, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601261, "Port", newJInt(Port))
  add(query_601261, "Version", newJString(Version))
  add(query_601261, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601260.call(nil, query_601261, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_601236(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_601237, base: "/",
    url: url_GetCreateDBInstanceReadReplica_601238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_601308 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBParameterGroup_601310(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_601309(path: JsonNode; query: JsonNode;
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
  var valid_601311 = query.getOrDefault("Action")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601311 != nil:
    section.add "Action", valid_601311
  var valid_601312 = query.getOrDefault("Version")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601312 != nil:
    section.add "Version", valid_601312
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601313 = header.getOrDefault("X-Amz-Date")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Date", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Security-Token")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Security-Token", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Content-Sha256", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Algorithm")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Algorithm", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Signature")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Signature", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-SignedHeaders", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Credential")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Credential", valid_601319
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601320 = formData.getOrDefault("DBParameterGroupName")
  valid_601320 = validateParameter(valid_601320, JString, required = true,
                                 default = nil)
  if valid_601320 != nil:
    section.add "DBParameterGroupName", valid_601320
  var valid_601321 = formData.getOrDefault("Tags")
  valid_601321 = validateParameter(valid_601321, JArray, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "Tags", valid_601321
  var valid_601322 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601322 = validateParameter(valid_601322, JString, required = true,
                                 default = nil)
  if valid_601322 != nil:
    section.add "DBParameterGroupFamily", valid_601322
  var valid_601323 = formData.getOrDefault("Description")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = nil)
  if valid_601323 != nil:
    section.add "Description", valid_601323
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601324: Call_PostCreateDBParameterGroup_601308; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601324.validator(path, query, header, formData, body)
  let scheme = call_601324.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601324.url(scheme.get, call_601324.host, call_601324.base,
                         call_601324.route, valid.getOrDefault("path"))
  result = hook(call_601324, url, valid)

proc call*(call_601325: Call_PostCreateDBParameterGroup_601308;
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
  var query_601326 = newJObject()
  var formData_601327 = newJObject()
  add(formData_601327, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_601327.add "Tags", Tags
  add(query_601326, "Action", newJString(Action))
  add(formData_601327, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_601326, "Version", newJString(Version))
  add(formData_601327, "Description", newJString(Description))
  result = call_601325.call(nil, query_601326, nil, formData_601327, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_601308(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_601309, base: "/",
    url: url_PostCreateDBParameterGroup_601310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_601289 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBParameterGroup_601291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_601290(path: JsonNode; query: JsonNode;
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
  var valid_601292 = query.getOrDefault("Description")
  valid_601292 = validateParameter(valid_601292, JString, required = true,
                                 default = nil)
  if valid_601292 != nil:
    section.add "Description", valid_601292
  var valid_601293 = query.getOrDefault("DBParameterGroupFamily")
  valid_601293 = validateParameter(valid_601293, JString, required = true,
                                 default = nil)
  if valid_601293 != nil:
    section.add "DBParameterGroupFamily", valid_601293
  var valid_601294 = query.getOrDefault("Tags")
  valid_601294 = validateParameter(valid_601294, JArray, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "Tags", valid_601294
  var valid_601295 = query.getOrDefault("DBParameterGroupName")
  valid_601295 = validateParameter(valid_601295, JString, required = true,
                                 default = nil)
  if valid_601295 != nil:
    section.add "DBParameterGroupName", valid_601295
  var valid_601296 = query.getOrDefault("Action")
  valid_601296 = validateParameter(valid_601296, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601296 != nil:
    section.add "Action", valid_601296
  var valid_601297 = query.getOrDefault("Version")
  valid_601297 = validateParameter(valid_601297, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601297 != nil:
    section.add "Version", valid_601297
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601298 = header.getOrDefault("X-Amz-Date")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Date", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Security-Token")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Security-Token", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Content-Sha256", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Algorithm")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Algorithm", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Signature")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Signature", valid_601302
  var valid_601303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "X-Amz-SignedHeaders", valid_601303
  var valid_601304 = header.getOrDefault("X-Amz-Credential")
  valid_601304 = validateParameter(valid_601304, JString, required = false,
                                 default = nil)
  if valid_601304 != nil:
    section.add "X-Amz-Credential", valid_601304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601305: Call_GetCreateDBParameterGroup_601289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601305.validator(path, query, header, formData, body)
  let scheme = call_601305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601305.url(scheme.get, call_601305.host, call_601305.base,
                         call_601305.route, valid.getOrDefault("path"))
  result = hook(call_601305, url, valid)

proc call*(call_601306: Call_GetCreateDBParameterGroup_601289; Description: string;
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
  var query_601307 = newJObject()
  add(query_601307, "Description", newJString(Description))
  add(query_601307, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_601307.add "Tags", Tags
  add(query_601307, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601307, "Action", newJString(Action))
  add(query_601307, "Version", newJString(Version))
  result = call_601306.call(nil, query_601307, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_601289(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_601290, base: "/",
    url: url_GetCreateDBParameterGroup_601291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_601346 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSecurityGroup_601348(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_601347(path: JsonNode; query: JsonNode;
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
  var valid_601349 = query.getOrDefault("Action")
  valid_601349 = validateParameter(valid_601349, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601349 != nil:
    section.add "Action", valid_601349
  var valid_601350 = query.getOrDefault("Version")
  valid_601350 = validateParameter(valid_601350, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601358 = formData.getOrDefault("DBSecurityGroupName")
  valid_601358 = validateParameter(valid_601358, JString, required = true,
                                 default = nil)
  if valid_601358 != nil:
    section.add "DBSecurityGroupName", valid_601358
  var valid_601359 = formData.getOrDefault("Tags")
  valid_601359 = validateParameter(valid_601359, JArray, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "Tags", valid_601359
  var valid_601360 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_601360 = validateParameter(valid_601360, JString, required = true,
                                 default = nil)
  if valid_601360 != nil:
    section.add "DBSecurityGroupDescription", valid_601360
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601361: Call_PostCreateDBSecurityGroup_601346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601361.validator(path, query, header, formData, body)
  let scheme = call_601361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601361.url(scheme.get, call_601361.host, call_601361.base,
                         call_601361.route, valid.getOrDefault("path"))
  result = hook(call_601361, url, valid)

proc call*(call_601362: Call_PostCreateDBSecurityGroup_601346;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_601363 = newJObject()
  var formData_601364 = newJObject()
  add(formData_601364, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_601364.add "Tags", Tags
  add(query_601363, "Action", newJString(Action))
  add(formData_601364, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601363, "Version", newJString(Version))
  result = call_601362.call(nil, query_601363, nil, formData_601364, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_601346(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_601347, base: "/",
    url: url_PostCreateDBSecurityGroup_601348,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_601328 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSecurityGroup_601330(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_601329(path: JsonNode; query: JsonNode;
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
  var valid_601331 = query.getOrDefault("DBSecurityGroupName")
  valid_601331 = validateParameter(valid_601331, JString, required = true,
                                 default = nil)
  if valid_601331 != nil:
    section.add "DBSecurityGroupName", valid_601331
  var valid_601332 = query.getOrDefault("DBSecurityGroupDescription")
  valid_601332 = validateParameter(valid_601332, JString, required = true,
                                 default = nil)
  if valid_601332 != nil:
    section.add "DBSecurityGroupDescription", valid_601332
  var valid_601333 = query.getOrDefault("Tags")
  valid_601333 = validateParameter(valid_601333, JArray, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "Tags", valid_601333
  var valid_601334 = query.getOrDefault("Action")
  valid_601334 = validateParameter(valid_601334, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601334 != nil:
    section.add "Action", valid_601334
  var valid_601335 = query.getOrDefault("Version")
  valid_601335 = validateParameter(valid_601335, JString, required = true,
                                 default = newJString("2013-09-09"))
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

proc call*(call_601343: Call_GetCreateDBSecurityGroup_601328; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601343.validator(path, query, header, formData, body)
  let scheme = call_601343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601343.url(scheme.get, call_601343.host, call_601343.base,
                         call_601343.route, valid.getOrDefault("path"))
  result = hook(call_601343, url, valid)

proc call*(call_601344: Call_GetCreateDBSecurityGroup_601328;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601345 = newJObject()
  add(query_601345, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601345, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_601345.add "Tags", Tags
  add(query_601345, "Action", newJString(Action))
  add(query_601345, "Version", newJString(Version))
  result = call_601344.call(nil, query_601345, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_601328(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_601329, base: "/",
    url: url_GetCreateDBSecurityGroup_601330, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_601383 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSnapshot_601385(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_601384(path: JsonNode; query: JsonNode;
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
  var valid_601386 = query.getOrDefault("Action")
  valid_601386 = validateParameter(valid_601386, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601386 != nil:
    section.add "Action", valid_601386
  var valid_601387 = query.getOrDefault("Version")
  valid_601387 = validateParameter(valid_601387, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601387 != nil:
    section.add "Version", valid_601387
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601388 = header.getOrDefault("X-Amz-Date")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Date", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Security-Token")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Security-Token", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Content-Sha256", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-Algorithm")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Algorithm", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Signature")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Signature", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-SignedHeaders", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Credential")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Credential", valid_601394
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601395 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601395 = validateParameter(valid_601395, JString, required = true,
                                 default = nil)
  if valid_601395 != nil:
    section.add "DBInstanceIdentifier", valid_601395
  var valid_601396 = formData.getOrDefault("Tags")
  valid_601396 = validateParameter(valid_601396, JArray, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "Tags", valid_601396
  var valid_601397 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601397 = validateParameter(valid_601397, JString, required = true,
                                 default = nil)
  if valid_601397 != nil:
    section.add "DBSnapshotIdentifier", valid_601397
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601398: Call_PostCreateDBSnapshot_601383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601398.validator(path, query, header, formData, body)
  let scheme = call_601398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601398.url(scheme.get, call_601398.host, call_601398.base,
                         call_601398.route, valid.getOrDefault("path"))
  result = hook(call_601398, url, valid)

proc call*(call_601399: Call_PostCreateDBSnapshot_601383;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601400 = newJObject()
  var formData_601401 = newJObject()
  add(formData_601401, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_601401.add "Tags", Tags
  add(formData_601401, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601400, "Action", newJString(Action))
  add(query_601400, "Version", newJString(Version))
  result = call_601399.call(nil, query_601400, nil, formData_601401, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_601383(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_601384, base: "/",
    url: url_PostCreateDBSnapshot_601385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_601365 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSnapshot_601367(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_601366(path: JsonNode; query: JsonNode;
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
  var valid_601368 = query.getOrDefault("Tags")
  valid_601368 = validateParameter(valid_601368, JArray, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "Tags", valid_601368
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601369 = query.getOrDefault("Action")
  valid_601369 = validateParameter(valid_601369, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601369 != nil:
    section.add "Action", valid_601369
  var valid_601370 = query.getOrDefault("Version")
  valid_601370 = validateParameter(valid_601370, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601370 != nil:
    section.add "Version", valid_601370
  var valid_601371 = query.getOrDefault("DBInstanceIdentifier")
  valid_601371 = validateParameter(valid_601371, JString, required = true,
                                 default = nil)
  if valid_601371 != nil:
    section.add "DBInstanceIdentifier", valid_601371
  var valid_601372 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601372 = validateParameter(valid_601372, JString, required = true,
                                 default = nil)
  if valid_601372 != nil:
    section.add "DBSnapshotIdentifier", valid_601372
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601373 = header.getOrDefault("X-Amz-Date")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Date", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Security-Token")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Security-Token", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Content-Sha256", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Algorithm")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Algorithm", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Signature")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Signature", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-SignedHeaders", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-Credential")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-Credential", valid_601379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601380: Call_GetCreateDBSnapshot_601365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601380.validator(path, query, header, formData, body)
  let scheme = call_601380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601380.url(scheme.get, call_601380.host, call_601380.base,
                         call_601380.route, valid.getOrDefault("path"))
  result = hook(call_601380, url, valid)

proc call*(call_601381: Call_GetCreateDBSnapshot_601365;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601382 = newJObject()
  if Tags != nil:
    query_601382.add "Tags", Tags
  add(query_601382, "Action", newJString(Action))
  add(query_601382, "Version", newJString(Version))
  add(query_601382, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601382, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601381.call(nil, query_601382, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_601365(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_601366, base: "/",
    url: url_GetCreateDBSnapshot_601367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_601421 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSubnetGroup_601423(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_601422(path: JsonNode; query: JsonNode;
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
  var valid_601424 = query.getOrDefault("Action")
  valid_601424 = validateParameter(valid_601424, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601424 != nil:
    section.add "Action", valid_601424
  var valid_601425 = query.getOrDefault("Version")
  valid_601425 = validateParameter(valid_601425, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601425 != nil:
    section.add "Version", valid_601425
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601426 = header.getOrDefault("X-Amz-Date")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Date", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-Security-Token")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-Security-Token", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Content-Sha256", valid_601428
  var valid_601429 = header.getOrDefault("X-Amz-Algorithm")
  valid_601429 = validateParameter(valid_601429, JString, required = false,
                                 default = nil)
  if valid_601429 != nil:
    section.add "X-Amz-Algorithm", valid_601429
  var valid_601430 = header.getOrDefault("X-Amz-Signature")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Signature", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-SignedHeaders", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Credential")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Credential", valid_601432
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_601433 = formData.getOrDefault("Tags")
  valid_601433 = validateParameter(valid_601433, JArray, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "Tags", valid_601433
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601434 = formData.getOrDefault("DBSubnetGroupName")
  valid_601434 = validateParameter(valid_601434, JString, required = true,
                                 default = nil)
  if valid_601434 != nil:
    section.add "DBSubnetGroupName", valid_601434
  var valid_601435 = formData.getOrDefault("SubnetIds")
  valid_601435 = validateParameter(valid_601435, JArray, required = true, default = nil)
  if valid_601435 != nil:
    section.add "SubnetIds", valid_601435
  var valid_601436 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601436 = validateParameter(valid_601436, JString, required = true,
                                 default = nil)
  if valid_601436 != nil:
    section.add "DBSubnetGroupDescription", valid_601436
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601437: Call_PostCreateDBSubnetGroup_601421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601437.validator(path, query, header, formData, body)
  let scheme = call_601437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601437.url(scheme.get, call_601437.host, call_601437.base,
                         call_601437.route, valid.getOrDefault("path"))
  result = hook(call_601437, url, valid)

proc call*(call_601438: Call_PostCreateDBSubnetGroup_601421;
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
  var query_601439 = newJObject()
  var formData_601440 = newJObject()
  if Tags != nil:
    formData_601440.add "Tags", Tags
  add(formData_601440, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601440.add "SubnetIds", SubnetIds
  add(query_601439, "Action", newJString(Action))
  add(formData_601440, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601439, "Version", newJString(Version))
  result = call_601438.call(nil, query_601439, nil, formData_601440, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_601421(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_601422, base: "/",
    url: url_PostCreateDBSubnetGroup_601423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_601402 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSubnetGroup_601404(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_601403(path: JsonNode; query: JsonNode;
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
  var valid_601405 = query.getOrDefault("Tags")
  valid_601405 = validateParameter(valid_601405, JArray, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "Tags", valid_601405
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601406 = query.getOrDefault("Action")
  valid_601406 = validateParameter(valid_601406, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601406 != nil:
    section.add "Action", valid_601406
  var valid_601407 = query.getOrDefault("DBSubnetGroupName")
  valid_601407 = validateParameter(valid_601407, JString, required = true,
                                 default = nil)
  if valid_601407 != nil:
    section.add "DBSubnetGroupName", valid_601407
  var valid_601408 = query.getOrDefault("SubnetIds")
  valid_601408 = validateParameter(valid_601408, JArray, required = true, default = nil)
  if valid_601408 != nil:
    section.add "SubnetIds", valid_601408
  var valid_601409 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601409 = validateParameter(valid_601409, JString, required = true,
                                 default = nil)
  if valid_601409 != nil:
    section.add "DBSubnetGroupDescription", valid_601409
  var valid_601410 = query.getOrDefault("Version")
  valid_601410 = validateParameter(valid_601410, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601418: Call_GetCreateDBSubnetGroup_601402; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601418.validator(path, query, header, formData, body)
  let scheme = call_601418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601418.url(scheme.get, call_601418.host, call_601418.base,
                         call_601418.route, valid.getOrDefault("path"))
  result = hook(call_601418, url, valid)

proc call*(call_601419: Call_GetCreateDBSubnetGroup_601402;
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
  var query_601420 = newJObject()
  if Tags != nil:
    query_601420.add "Tags", Tags
  add(query_601420, "Action", newJString(Action))
  add(query_601420, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601420.add "SubnetIds", SubnetIds
  add(query_601420, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601420, "Version", newJString(Version))
  result = call_601419.call(nil, query_601420, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_601402(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_601403, base: "/",
    url: url_GetCreateDBSubnetGroup_601404, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_601463 = ref object of OpenApiRestCall_600410
proc url_PostCreateEventSubscription_601465(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_601464(path: JsonNode; query: JsonNode;
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
  var valid_601466 = query.getOrDefault("Action")
  valid_601466 = validateParameter(valid_601466, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601466 != nil:
    section.add "Action", valid_601466
  var valid_601467 = query.getOrDefault("Version")
  valid_601467 = validateParameter(valid_601467, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601467 != nil:
    section.add "Version", valid_601467
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601468 = header.getOrDefault("X-Amz-Date")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Date", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Security-Token")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Security-Token", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Content-Sha256", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Algorithm")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Algorithm", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Signature")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Signature", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-SignedHeaders", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-Credential")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Credential", valid_601474
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
  var valid_601475 = formData.getOrDefault("Enabled")
  valid_601475 = validateParameter(valid_601475, JBool, required = false, default = nil)
  if valid_601475 != nil:
    section.add "Enabled", valid_601475
  var valid_601476 = formData.getOrDefault("EventCategories")
  valid_601476 = validateParameter(valid_601476, JArray, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "EventCategories", valid_601476
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_601477 = formData.getOrDefault("SnsTopicArn")
  valid_601477 = validateParameter(valid_601477, JString, required = true,
                                 default = nil)
  if valid_601477 != nil:
    section.add "SnsTopicArn", valid_601477
  var valid_601478 = formData.getOrDefault("SourceIds")
  valid_601478 = validateParameter(valid_601478, JArray, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "SourceIds", valid_601478
  var valid_601479 = formData.getOrDefault("Tags")
  valid_601479 = validateParameter(valid_601479, JArray, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "Tags", valid_601479
  var valid_601480 = formData.getOrDefault("SubscriptionName")
  valid_601480 = validateParameter(valid_601480, JString, required = true,
                                 default = nil)
  if valid_601480 != nil:
    section.add "SubscriptionName", valid_601480
  var valid_601481 = formData.getOrDefault("SourceType")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "SourceType", valid_601481
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601482: Call_PostCreateEventSubscription_601463; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601482.validator(path, query, header, formData, body)
  let scheme = call_601482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601482.url(scheme.get, call_601482.host, call_601482.base,
                         call_601482.route, valid.getOrDefault("path"))
  result = hook(call_601482, url, valid)

proc call*(call_601483: Call_PostCreateEventSubscription_601463;
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
  var query_601484 = newJObject()
  var formData_601485 = newJObject()
  add(formData_601485, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601485.add "EventCategories", EventCategories
  add(formData_601485, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_601485.add "SourceIds", SourceIds
  if Tags != nil:
    formData_601485.add "Tags", Tags
  add(formData_601485, "SubscriptionName", newJString(SubscriptionName))
  add(query_601484, "Action", newJString(Action))
  add(query_601484, "Version", newJString(Version))
  add(formData_601485, "SourceType", newJString(SourceType))
  result = call_601483.call(nil, query_601484, nil, formData_601485, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_601463(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_601464, base: "/",
    url: url_PostCreateEventSubscription_601465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_601441 = ref object of OpenApiRestCall_600410
proc url_GetCreateEventSubscription_601443(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_601442(path: JsonNode; query: JsonNode;
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
  var valid_601444 = query.getOrDefault("SourceType")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "SourceType", valid_601444
  var valid_601445 = query.getOrDefault("SourceIds")
  valid_601445 = validateParameter(valid_601445, JArray, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "SourceIds", valid_601445
  var valid_601446 = query.getOrDefault("Enabled")
  valid_601446 = validateParameter(valid_601446, JBool, required = false, default = nil)
  if valid_601446 != nil:
    section.add "Enabled", valid_601446
  var valid_601447 = query.getOrDefault("Tags")
  valid_601447 = validateParameter(valid_601447, JArray, required = false,
                                 default = nil)
  if valid_601447 != nil:
    section.add "Tags", valid_601447
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601448 = query.getOrDefault("Action")
  valid_601448 = validateParameter(valid_601448, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601448 != nil:
    section.add "Action", valid_601448
  var valid_601449 = query.getOrDefault("SnsTopicArn")
  valid_601449 = validateParameter(valid_601449, JString, required = true,
                                 default = nil)
  if valid_601449 != nil:
    section.add "SnsTopicArn", valid_601449
  var valid_601450 = query.getOrDefault("EventCategories")
  valid_601450 = validateParameter(valid_601450, JArray, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "EventCategories", valid_601450
  var valid_601451 = query.getOrDefault("SubscriptionName")
  valid_601451 = validateParameter(valid_601451, JString, required = true,
                                 default = nil)
  if valid_601451 != nil:
    section.add "SubscriptionName", valid_601451
  var valid_601452 = query.getOrDefault("Version")
  valid_601452 = validateParameter(valid_601452, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601452 != nil:
    section.add "Version", valid_601452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601453 = header.getOrDefault("X-Amz-Date")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Date", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Security-Token")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Security-Token", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Content-Sha256", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Algorithm")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Algorithm", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-Signature")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-Signature", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-SignedHeaders", valid_601458
  var valid_601459 = header.getOrDefault("X-Amz-Credential")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Credential", valid_601459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601460: Call_GetCreateEventSubscription_601441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601460.validator(path, query, header, formData, body)
  let scheme = call_601460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601460.url(scheme.get, call_601460.host, call_601460.base,
                         call_601460.route, valid.getOrDefault("path"))
  result = hook(call_601460, url, valid)

proc call*(call_601461: Call_GetCreateEventSubscription_601441;
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
  var query_601462 = newJObject()
  add(query_601462, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_601462.add "SourceIds", SourceIds
  add(query_601462, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_601462.add "Tags", Tags
  add(query_601462, "Action", newJString(Action))
  add(query_601462, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601462.add "EventCategories", EventCategories
  add(query_601462, "SubscriptionName", newJString(SubscriptionName))
  add(query_601462, "Version", newJString(Version))
  result = call_601461.call(nil, query_601462, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_601441(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_601442, base: "/",
    url: url_GetCreateEventSubscription_601443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_601506 = ref object of OpenApiRestCall_600410
proc url_PostCreateOptionGroup_601508(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_601507(path: JsonNode; query: JsonNode;
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
  var valid_601509 = query.getOrDefault("Action")
  valid_601509 = validateParameter(valid_601509, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601509 != nil:
    section.add "Action", valid_601509
  var valid_601510 = query.getOrDefault("Version")
  valid_601510 = validateParameter(valid_601510, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601510 != nil:
    section.add "Version", valid_601510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601511 = header.getOrDefault("X-Amz-Date")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Date", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Security-Token")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Security-Token", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Content-Sha256", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Algorithm")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Algorithm", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Signature")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Signature", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-SignedHeaders", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Credential")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Credential", valid_601517
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_601518 = formData.getOrDefault("MajorEngineVersion")
  valid_601518 = validateParameter(valid_601518, JString, required = true,
                                 default = nil)
  if valid_601518 != nil:
    section.add "MajorEngineVersion", valid_601518
  var valid_601519 = formData.getOrDefault("OptionGroupName")
  valid_601519 = validateParameter(valid_601519, JString, required = true,
                                 default = nil)
  if valid_601519 != nil:
    section.add "OptionGroupName", valid_601519
  var valid_601520 = formData.getOrDefault("Tags")
  valid_601520 = validateParameter(valid_601520, JArray, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "Tags", valid_601520
  var valid_601521 = formData.getOrDefault("EngineName")
  valid_601521 = validateParameter(valid_601521, JString, required = true,
                                 default = nil)
  if valid_601521 != nil:
    section.add "EngineName", valid_601521
  var valid_601522 = formData.getOrDefault("OptionGroupDescription")
  valid_601522 = validateParameter(valid_601522, JString, required = true,
                                 default = nil)
  if valid_601522 != nil:
    section.add "OptionGroupDescription", valid_601522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601523: Call_PostCreateOptionGroup_601506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601523.validator(path, query, header, formData, body)
  let scheme = call_601523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601523.url(scheme.get, call_601523.host, call_601523.base,
                         call_601523.route, valid.getOrDefault("path"))
  result = hook(call_601523, url, valid)

proc call*(call_601524: Call_PostCreateOptionGroup_601506;
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
  var query_601525 = newJObject()
  var formData_601526 = newJObject()
  add(formData_601526, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601526, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601526.add "Tags", Tags
  add(query_601525, "Action", newJString(Action))
  add(formData_601526, "EngineName", newJString(EngineName))
  add(formData_601526, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_601525, "Version", newJString(Version))
  result = call_601524.call(nil, query_601525, nil, formData_601526, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_601506(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_601507, base: "/",
    url: url_PostCreateOptionGroup_601508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_601486 = ref object of OpenApiRestCall_600410
proc url_GetCreateOptionGroup_601488(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_601487(path: JsonNode; query: JsonNode;
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
  var valid_601489 = query.getOrDefault("OptionGroupName")
  valid_601489 = validateParameter(valid_601489, JString, required = true,
                                 default = nil)
  if valid_601489 != nil:
    section.add "OptionGroupName", valid_601489
  var valid_601490 = query.getOrDefault("Tags")
  valid_601490 = validateParameter(valid_601490, JArray, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "Tags", valid_601490
  var valid_601491 = query.getOrDefault("OptionGroupDescription")
  valid_601491 = validateParameter(valid_601491, JString, required = true,
                                 default = nil)
  if valid_601491 != nil:
    section.add "OptionGroupDescription", valid_601491
  var valid_601492 = query.getOrDefault("Action")
  valid_601492 = validateParameter(valid_601492, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601492 != nil:
    section.add "Action", valid_601492
  var valid_601493 = query.getOrDefault("Version")
  valid_601493 = validateParameter(valid_601493, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601493 != nil:
    section.add "Version", valid_601493
  var valid_601494 = query.getOrDefault("EngineName")
  valid_601494 = validateParameter(valid_601494, JString, required = true,
                                 default = nil)
  if valid_601494 != nil:
    section.add "EngineName", valid_601494
  var valid_601495 = query.getOrDefault("MajorEngineVersion")
  valid_601495 = validateParameter(valid_601495, JString, required = true,
                                 default = nil)
  if valid_601495 != nil:
    section.add "MajorEngineVersion", valid_601495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601496 = header.getOrDefault("X-Amz-Date")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Date", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Security-Token")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Security-Token", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Content-Sha256", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Algorithm")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Algorithm", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Signature")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Signature", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-SignedHeaders", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Credential")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Credential", valid_601502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601503: Call_GetCreateOptionGroup_601486; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601503.validator(path, query, header, formData, body)
  let scheme = call_601503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601503.url(scheme.get, call_601503.host, call_601503.base,
                         call_601503.route, valid.getOrDefault("path"))
  result = hook(call_601503, url, valid)

proc call*(call_601504: Call_GetCreateOptionGroup_601486; OptionGroupName: string;
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
  var query_601505 = newJObject()
  add(query_601505, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_601505.add "Tags", Tags
  add(query_601505, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_601505, "Action", newJString(Action))
  add(query_601505, "Version", newJString(Version))
  add(query_601505, "EngineName", newJString(EngineName))
  add(query_601505, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601504.call(nil, query_601505, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_601486(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_601487, base: "/",
    url: url_GetCreateOptionGroup_601488, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_601545 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBInstance_601547(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_601546(path: JsonNode; query: JsonNode;
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
  var valid_601548 = query.getOrDefault("Action")
  valid_601548 = validateParameter(valid_601548, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601548 != nil:
    section.add "Action", valid_601548
  var valid_601549 = query.getOrDefault("Version")
  valid_601549 = validateParameter(valid_601549, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601557 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601557 = validateParameter(valid_601557, JString, required = true,
                                 default = nil)
  if valid_601557 != nil:
    section.add "DBInstanceIdentifier", valid_601557
  var valid_601558 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601558
  var valid_601559 = formData.getOrDefault("SkipFinalSnapshot")
  valid_601559 = validateParameter(valid_601559, JBool, required = false, default = nil)
  if valid_601559 != nil:
    section.add "SkipFinalSnapshot", valid_601559
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601560: Call_PostDeleteDBInstance_601545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601560.validator(path, query, header, formData, body)
  let scheme = call_601560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601560.url(scheme.get, call_601560.host, call_601560.base,
                         call_601560.route, valid.getOrDefault("path"))
  result = hook(call_601560, url, valid)

proc call*(call_601561: Call_PostDeleteDBInstance_601545;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_601562 = newJObject()
  var formData_601563 = newJObject()
  add(formData_601563, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601563, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601562, "Action", newJString(Action))
  add(query_601562, "Version", newJString(Version))
  add(formData_601563, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_601561.call(nil, query_601562, nil, formData_601563, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_601545(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_601546, base: "/",
    url: url_PostDeleteDBInstance_601547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_601527 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBInstance_601529(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_601528(path: JsonNode; query: JsonNode;
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
  var valid_601530 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601530
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601531 = query.getOrDefault("Action")
  valid_601531 = validateParameter(valid_601531, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601531 != nil:
    section.add "Action", valid_601531
  var valid_601532 = query.getOrDefault("SkipFinalSnapshot")
  valid_601532 = validateParameter(valid_601532, JBool, required = false, default = nil)
  if valid_601532 != nil:
    section.add "SkipFinalSnapshot", valid_601532
  var valid_601533 = query.getOrDefault("Version")
  valid_601533 = validateParameter(valid_601533, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601533 != nil:
    section.add "Version", valid_601533
  var valid_601534 = query.getOrDefault("DBInstanceIdentifier")
  valid_601534 = validateParameter(valid_601534, JString, required = true,
                                 default = nil)
  if valid_601534 != nil:
    section.add "DBInstanceIdentifier", valid_601534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601535 = header.getOrDefault("X-Amz-Date")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-Date", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Security-Token")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Security-Token", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Content-Sha256", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Algorithm")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Algorithm", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-Signature")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Signature", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-SignedHeaders", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Credential")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Credential", valid_601541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601542: Call_GetDeleteDBInstance_601527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601542.validator(path, query, header, formData, body)
  let scheme = call_601542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601542.url(scheme.get, call_601542.host, call_601542.base,
                         call_601542.route, valid.getOrDefault("path"))
  result = hook(call_601542, url, valid)

proc call*(call_601543: Call_GetDeleteDBInstance_601527;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601544 = newJObject()
  add(query_601544, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601544, "Action", newJString(Action))
  add(query_601544, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_601544, "Version", newJString(Version))
  add(query_601544, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601543.call(nil, query_601544, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_601527(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_601528, base: "/",
    url: url_GetDeleteDBInstance_601529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_601580 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBParameterGroup_601582(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_601581(path: JsonNode; query: JsonNode;
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
  var valid_601583 = query.getOrDefault("Action")
  valid_601583 = validateParameter(valid_601583, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601583 != nil:
    section.add "Action", valid_601583
  var valid_601584 = query.getOrDefault("Version")
  valid_601584 = validateParameter(valid_601584, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601584 != nil:
    section.add "Version", valid_601584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601585 = header.getOrDefault("X-Amz-Date")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Date", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Security-Token")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Security-Token", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-Content-Sha256", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Algorithm")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Algorithm", valid_601588
  var valid_601589 = header.getOrDefault("X-Amz-Signature")
  valid_601589 = validateParameter(valid_601589, JString, required = false,
                                 default = nil)
  if valid_601589 != nil:
    section.add "X-Amz-Signature", valid_601589
  var valid_601590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601590 = validateParameter(valid_601590, JString, required = false,
                                 default = nil)
  if valid_601590 != nil:
    section.add "X-Amz-SignedHeaders", valid_601590
  var valid_601591 = header.getOrDefault("X-Amz-Credential")
  valid_601591 = validateParameter(valid_601591, JString, required = false,
                                 default = nil)
  if valid_601591 != nil:
    section.add "X-Amz-Credential", valid_601591
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601592 = formData.getOrDefault("DBParameterGroupName")
  valid_601592 = validateParameter(valid_601592, JString, required = true,
                                 default = nil)
  if valid_601592 != nil:
    section.add "DBParameterGroupName", valid_601592
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601593: Call_PostDeleteDBParameterGroup_601580; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601593.validator(path, query, header, formData, body)
  let scheme = call_601593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601593.url(scheme.get, call_601593.host, call_601593.base,
                         call_601593.route, valid.getOrDefault("path"))
  result = hook(call_601593, url, valid)

proc call*(call_601594: Call_PostDeleteDBParameterGroup_601580;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601595 = newJObject()
  var formData_601596 = newJObject()
  add(formData_601596, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601595, "Action", newJString(Action))
  add(query_601595, "Version", newJString(Version))
  result = call_601594.call(nil, query_601595, nil, formData_601596, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_601580(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_601581, base: "/",
    url: url_PostDeleteDBParameterGroup_601582,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_601564 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBParameterGroup_601566(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_601565(path: JsonNode; query: JsonNode;
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
  var valid_601567 = query.getOrDefault("DBParameterGroupName")
  valid_601567 = validateParameter(valid_601567, JString, required = true,
                                 default = nil)
  if valid_601567 != nil:
    section.add "DBParameterGroupName", valid_601567
  var valid_601568 = query.getOrDefault("Action")
  valid_601568 = validateParameter(valid_601568, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601568 != nil:
    section.add "Action", valid_601568
  var valid_601569 = query.getOrDefault("Version")
  valid_601569 = validateParameter(valid_601569, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601569 != nil:
    section.add "Version", valid_601569
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601570 = header.getOrDefault("X-Amz-Date")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Date", valid_601570
  var valid_601571 = header.getOrDefault("X-Amz-Security-Token")
  valid_601571 = validateParameter(valid_601571, JString, required = false,
                                 default = nil)
  if valid_601571 != nil:
    section.add "X-Amz-Security-Token", valid_601571
  var valid_601572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601572 = validateParameter(valid_601572, JString, required = false,
                                 default = nil)
  if valid_601572 != nil:
    section.add "X-Amz-Content-Sha256", valid_601572
  var valid_601573 = header.getOrDefault("X-Amz-Algorithm")
  valid_601573 = validateParameter(valid_601573, JString, required = false,
                                 default = nil)
  if valid_601573 != nil:
    section.add "X-Amz-Algorithm", valid_601573
  var valid_601574 = header.getOrDefault("X-Amz-Signature")
  valid_601574 = validateParameter(valid_601574, JString, required = false,
                                 default = nil)
  if valid_601574 != nil:
    section.add "X-Amz-Signature", valid_601574
  var valid_601575 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601575 = validateParameter(valid_601575, JString, required = false,
                                 default = nil)
  if valid_601575 != nil:
    section.add "X-Amz-SignedHeaders", valid_601575
  var valid_601576 = header.getOrDefault("X-Amz-Credential")
  valid_601576 = validateParameter(valid_601576, JString, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "X-Amz-Credential", valid_601576
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601577: Call_GetDeleteDBParameterGroup_601564; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601577.validator(path, query, header, formData, body)
  let scheme = call_601577.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601577.url(scheme.get, call_601577.host, call_601577.base,
                         call_601577.route, valid.getOrDefault("path"))
  result = hook(call_601577, url, valid)

proc call*(call_601578: Call_GetDeleteDBParameterGroup_601564;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601579 = newJObject()
  add(query_601579, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601579, "Action", newJString(Action))
  add(query_601579, "Version", newJString(Version))
  result = call_601578.call(nil, query_601579, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_601564(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_601565, base: "/",
    url: url_GetDeleteDBParameterGroup_601566,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_601613 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSecurityGroup_601615(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_601614(path: JsonNode; query: JsonNode;
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
  var valid_601616 = query.getOrDefault("Action")
  valid_601616 = validateParameter(valid_601616, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601616 != nil:
    section.add "Action", valid_601616
  var valid_601617 = query.getOrDefault("Version")
  valid_601617 = validateParameter(valid_601617, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601617 != nil:
    section.add "Version", valid_601617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601618 = header.getOrDefault("X-Amz-Date")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Date", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Security-Token")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Security-Token", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Content-Sha256", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Algorithm")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Algorithm", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Signature")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Signature", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-SignedHeaders", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Credential")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Credential", valid_601624
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601625 = formData.getOrDefault("DBSecurityGroupName")
  valid_601625 = validateParameter(valid_601625, JString, required = true,
                                 default = nil)
  if valid_601625 != nil:
    section.add "DBSecurityGroupName", valid_601625
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601626: Call_PostDeleteDBSecurityGroup_601613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601626.validator(path, query, header, formData, body)
  let scheme = call_601626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601626.url(scheme.get, call_601626.host, call_601626.base,
                         call_601626.route, valid.getOrDefault("path"))
  result = hook(call_601626, url, valid)

proc call*(call_601627: Call_PostDeleteDBSecurityGroup_601613;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601628 = newJObject()
  var formData_601629 = newJObject()
  add(formData_601629, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601628, "Action", newJString(Action))
  add(query_601628, "Version", newJString(Version))
  result = call_601627.call(nil, query_601628, nil, formData_601629, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_601613(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_601614, base: "/",
    url: url_PostDeleteDBSecurityGroup_601615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_601597 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSecurityGroup_601599(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_601598(path: JsonNode; query: JsonNode;
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
  var valid_601600 = query.getOrDefault("DBSecurityGroupName")
  valid_601600 = validateParameter(valid_601600, JString, required = true,
                                 default = nil)
  if valid_601600 != nil:
    section.add "DBSecurityGroupName", valid_601600
  var valid_601601 = query.getOrDefault("Action")
  valid_601601 = validateParameter(valid_601601, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601601 != nil:
    section.add "Action", valid_601601
  var valid_601602 = query.getOrDefault("Version")
  valid_601602 = validateParameter(valid_601602, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601602 != nil:
    section.add "Version", valid_601602
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601603 = header.getOrDefault("X-Amz-Date")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Date", valid_601603
  var valid_601604 = header.getOrDefault("X-Amz-Security-Token")
  valid_601604 = validateParameter(valid_601604, JString, required = false,
                                 default = nil)
  if valid_601604 != nil:
    section.add "X-Amz-Security-Token", valid_601604
  var valid_601605 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601605 = validateParameter(valid_601605, JString, required = false,
                                 default = nil)
  if valid_601605 != nil:
    section.add "X-Amz-Content-Sha256", valid_601605
  var valid_601606 = header.getOrDefault("X-Amz-Algorithm")
  valid_601606 = validateParameter(valid_601606, JString, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "X-Amz-Algorithm", valid_601606
  var valid_601607 = header.getOrDefault("X-Amz-Signature")
  valid_601607 = validateParameter(valid_601607, JString, required = false,
                                 default = nil)
  if valid_601607 != nil:
    section.add "X-Amz-Signature", valid_601607
  var valid_601608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-SignedHeaders", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Credential")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Credential", valid_601609
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601610: Call_GetDeleteDBSecurityGroup_601597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601610.validator(path, query, header, formData, body)
  let scheme = call_601610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601610.url(scheme.get, call_601610.host, call_601610.base,
                         call_601610.route, valid.getOrDefault("path"))
  result = hook(call_601610, url, valid)

proc call*(call_601611: Call_GetDeleteDBSecurityGroup_601597;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601612 = newJObject()
  add(query_601612, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601612, "Action", newJString(Action))
  add(query_601612, "Version", newJString(Version))
  result = call_601611.call(nil, query_601612, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_601597(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_601598, base: "/",
    url: url_GetDeleteDBSecurityGroup_601599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_601646 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSnapshot_601648(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_601647(path: JsonNode; query: JsonNode;
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
  var valid_601649 = query.getOrDefault("Action")
  valid_601649 = validateParameter(valid_601649, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601649 != nil:
    section.add "Action", valid_601649
  var valid_601650 = query.getOrDefault("Version")
  valid_601650 = validateParameter(valid_601650, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601650 != nil:
    section.add "Version", valid_601650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601651 = header.getOrDefault("X-Amz-Date")
  valid_601651 = validateParameter(valid_601651, JString, required = false,
                                 default = nil)
  if valid_601651 != nil:
    section.add "X-Amz-Date", valid_601651
  var valid_601652 = header.getOrDefault("X-Amz-Security-Token")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Security-Token", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Content-Sha256", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Algorithm")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Algorithm", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Signature")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Signature", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-SignedHeaders", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Credential")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Credential", valid_601657
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_601658 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601658 = validateParameter(valid_601658, JString, required = true,
                                 default = nil)
  if valid_601658 != nil:
    section.add "DBSnapshotIdentifier", valid_601658
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601659: Call_PostDeleteDBSnapshot_601646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601659.validator(path, query, header, formData, body)
  let scheme = call_601659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601659.url(scheme.get, call_601659.host, call_601659.base,
                         call_601659.route, valid.getOrDefault("path"))
  result = hook(call_601659, url, valid)

proc call*(call_601660: Call_PostDeleteDBSnapshot_601646;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601661 = newJObject()
  var formData_601662 = newJObject()
  add(formData_601662, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601661, "Action", newJString(Action))
  add(query_601661, "Version", newJString(Version))
  result = call_601660.call(nil, query_601661, nil, formData_601662, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_601646(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_601647, base: "/",
    url: url_PostDeleteDBSnapshot_601648, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_601630 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSnapshot_601632(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_601631(path: JsonNode; query: JsonNode;
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
  var valid_601633 = query.getOrDefault("Action")
  valid_601633 = validateParameter(valid_601633, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601633 != nil:
    section.add "Action", valid_601633
  var valid_601634 = query.getOrDefault("Version")
  valid_601634 = validateParameter(valid_601634, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601634 != nil:
    section.add "Version", valid_601634
  var valid_601635 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601635 = validateParameter(valid_601635, JString, required = true,
                                 default = nil)
  if valid_601635 != nil:
    section.add "DBSnapshotIdentifier", valid_601635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601636 = header.getOrDefault("X-Amz-Date")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Date", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-Security-Token")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-Security-Token", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Content-Sha256", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Algorithm")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Algorithm", valid_601639
  var valid_601640 = header.getOrDefault("X-Amz-Signature")
  valid_601640 = validateParameter(valid_601640, JString, required = false,
                                 default = nil)
  if valid_601640 != nil:
    section.add "X-Amz-Signature", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-SignedHeaders", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Credential")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Credential", valid_601642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601643: Call_GetDeleteDBSnapshot_601630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601643.validator(path, query, header, formData, body)
  let scheme = call_601643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601643.url(scheme.get, call_601643.host, call_601643.base,
                         call_601643.route, valid.getOrDefault("path"))
  result = hook(call_601643, url, valid)

proc call*(call_601644: Call_GetDeleteDBSnapshot_601630;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601645 = newJObject()
  add(query_601645, "Action", newJString(Action))
  add(query_601645, "Version", newJString(Version))
  add(query_601645, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601644.call(nil, query_601645, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_601630(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_601631, base: "/",
    url: url_GetDeleteDBSnapshot_601632, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_601679 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSubnetGroup_601681(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_601680(path: JsonNode; query: JsonNode;
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
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601682 != nil:
    section.add "Action", valid_601682
  var valid_601683 = query.getOrDefault("Version")
  valid_601683 = validateParameter(valid_601683, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601691 = formData.getOrDefault("DBSubnetGroupName")
  valid_601691 = validateParameter(valid_601691, JString, required = true,
                                 default = nil)
  if valid_601691 != nil:
    section.add "DBSubnetGroupName", valid_601691
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601692: Call_PostDeleteDBSubnetGroup_601679; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601692.validator(path, query, header, formData, body)
  let scheme = call_601692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601692.url(scheme.get, call_601692.host, call_601692.base,
                         call_601692.route, valid.getOrDefault("path"))
  result = hook(call_601692, url, valid)

proc call*(call_601693: Call_PostDeleteDBSubnetGroup_601679;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601694 = newJObject()
  var formData_601695 = newJObject()
  add(formData_601695, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601694, "Action", newJString(Action))
  add(query_601694, "Version", newJString(Version))
  result = call_601693.call(nil, query_601694, nil, formData_601695, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_601679(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_601680, base: "/",
    url: url_PostDeleteDBSubnetGroup_601681, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_601663 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSubnetGroup_601665(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_601664(path: JsonNode; query: JsonNode;
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
  var valid_601666 = query.getOrDefault("Action")
  valid_601666 = validateParameter(valid_601666, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601666 != nil:
    section.add "Action", valid_601666
  var valid_601667 = query.getOrDefault("DBSubnetGroupName")
  valid_601667 = validateParameter(valid_601667, JString, required = true,
                                 default = nil)
  if valid_601667 != nil:
    section.add "DBSubnetGroupName", valid_601667
  var valid_601668 = query.getOrDefault("Version")
  valid_601668 = validateParameter(valid_601668, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601668 != nil:
    section.add "Version", valid_601668
  result.add "query", section
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

proc call*(call_601676: Call_GetDeleteDBSubnetGroup_601663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601676.validator(path, query, header, formData, body)
  let scheme = call_601676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601676.url(scheme.get, call_601676.host, call_601676.base,
                         call_601676.route, valid.getOrDefault("path"))
  result = hook(call_601676, url, valid)

proc call*(call_601677: Call_GetDeleteDBSubnetGroup_601663;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_601678 = newJObject()
  add(query_601678, "Action", newJString(Action))
  add(query_601678, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601678, "Version", newJString(Version))
  result = call_601677.call(nil, query_601678, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_601663(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_601664, base: "/",
    url: url_GetDeleteDBSubnetGroup_601665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_601712 = ref object of OpenApiRestCall_600410
proc url_PostDeleteEventSubscription_601714(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_601713(path: JsonNode; query: JsonNode;
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
  var valid_601715 = query.getOrDefault("Action")
  valid_601715 = validateParameter(valid_601715, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601715 != nil:
    section.add "Action", valid_601715
  var valid_601716 = query.getOrDefault("Version")
  valid_601716 = validateParameter(valid_601716, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601716 != nil:
    section.add "Version", valid_601716
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601717 = header.getOrDefault("X-Amz-Date")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Date", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Security-Token")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Security-Token", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-Content-Sha256", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-Algorithm")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Algorithm", valid_601720
  var valid_601721 = header.getOrDefault("X-Amz-Signature")
  valid_601721 = validateParameter(valid_601721, JString, required = false,
                                 default = nil)
  if valid_601721 != nil:
    section.add "X-Amz-Signature", valid_601721
  var valid_601722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-SignedHeaders", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Credential")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Credential", valid_601723
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601724 = formData.getOrDefault("SubscriptionName")
  valid_601724 = validateParameter(valid_601724, JString, required = true,
                                 default = nil)
  if valid_601724 != nil:
    section.add "SubscriptionName", valid_601724
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601725: Call_PostDeleteEventSubscription_601712; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601725.validator(path, query, header, formData, body)
  let scheme = call_601725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601725.url(scheme.get, call_601725.host, call_601725.base,
                         call_601725.route, valid.getOrDefault("path"))
  result = hook(call_601725, url, valid)

proc call*(call_601726: Call_PostDeleteEventSubscription_601712;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601727 = newJObject()
  var formData_601728 = newJObject()
  add(formData_601728, "SubscriptionName", newJString(SubscriptionName))
  add(query_601727, "Action", newJString(Action))
  add(query_601727, "Version", newJString(Version))
  result = call_601726.call(nil, query_601727, nil, formData_601728, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_601712(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_601713, base: "/",
    url: url_PostDeleteEventSubscription_601714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_601696 = ref object of OpenApiRestCall_600410
proc url_GetDeleteEventSubscription_601698(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_601697(path: JsonNode; query: JsonNode;
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
  var valid_601699 = query.getOrDefault("Action")
  valid_601699 = validateParameter(valid_601699, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601699 != nil:
    section.add "Action", valid_601699
  var valid_601700 = query.getOrDefault("SubscriptionName")
  valid_601700 = validateParameter(valid_601700, JString, required = true,
                                 default = nil)
  if valid_601700 != nil:
    section.add "SubscriptionName", valid_601700
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601709: Call_GetDeleteEventSubscription_601696; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601709.validator(path, query, header, formData, body)
  let scheme = call_601709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601709.url(scheme.get, call_601709.host, call_601709.base,
                         call_601709.route, valid.getOrDefault("path"))
  result = hook(call_601709, url, valid)

proc call*(call_601710: Call_GetDeleteEventSubscription_601696;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601711 = newJObject()
  add(query_601711, "Action", newJString(Action))
  add(query_601711, "SubscriptionName", newJString(SubscriptionName))
  add(query_601711, "Version", newJString(Version))
  result = call_601710.call(nil, query_601711, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_601696(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_601697, base: "/",
    url: url_GetDeleteEventSubscription_601698,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_601745 = ref object of OpenApiRestCall_600410
proc url_PostDeleteOptionGroup_601747(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_601746(path: JsonNode; query: JsonNode;
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
  var valid_601748 = query.getOrDefault("Action")
  valid_601748 = validateParameter(valid_601748, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601748 != nil:
    section.add "Action", valid_601748
  var valid_601749 = query.getOrDefault("Version")
  valid_601749 = validateParameter(valid_601749, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601749 != nil:
    section.add "Version", valid_601749
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601750 = header.getOrDefault("X-Amz-Date")
  valid_601750 = validateParameter(valid_601750, JString, required = false,
                                 default = nil)
  if valid_601750 != nil:
    section.add "X-Amz-Date", valid_601750
  var valid_601751 = header.getOrDefault("X-Amz-Security-Token")
  valid_601751 = validateParameter(valid_601751, JString, required = false,
                                 default = nil)
  if valid_601751 != nil:
    section.add "X-Amz-Security-Token", valid_601751
  var valid_601752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601752 = validateParameter(valid_601752, JString, required = false,
                                 default = nil)
  if valid_601752 != nil:
    section.add "X-Amz-Content-Sha256", valid_601752
  var valid_601753 = header.getOrDefault("X-Amz-Algorithm")
  valid_601753 = validateParameter(valid_601753, JString, required = false,
                                 default = nil)
  if valid_601753 != nil:
    section.add "X-Amz-Algorithm", valid_601753
  var valid_601754 = header.getOrDefault("X-Amz-Signature")
  valid_601754 = validateParameter(valid_601754, JString, required = false,
                                 default = nil)
  if valid_601754 != nil:
    section.add "X-Amz-Signature", valid_601754
  var valid_601755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-SignedHeaders", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-Credential")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Credential", valid_601756
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601757 = formData.getOrDefault("OptionGroupName")
  valid_601757 = validateParameter(valid_601757, JString, required = true,
                                 default = nil)
  if valid_601757 != nil:
    section.add "OptionGroupName", valid_601757
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601758: Call_PostDeleteOptionGroup_601745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601758.validator(path, query, header, formData, body)
  let scheme = call_601758.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601758.url(scheme.get, call_601758.host, call_601758.base,
                         call_601758.route, valid.getOrDefault("path"))
  result = hook(call_601758, url, valid)

proc call*(call_601759: Call_PostDeleteOptionGroup_601745; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601760 = newJObject()
  var formData_601761 = newJObject()
  add(formData_601761, "OptionGroupName", newJString(OptionGroupName))
  add(query_601760, "Action", newJString(Action))
  add(query_601760, "Version", newJString(Version))
  result = call_601759.call(nil, query_601760, nil, formData_601761, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_601745(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_601746, base: "/",
    url: url_PostDeleteOptionGroup_601747, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_601729 = ref object of OpenApiRestCall_600410
proc url_GetDeleteOptionGroup_601731(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_601730(path: JsonNode; query: JsonNode;
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
  var valid_601732 = query.getOrDefault("OptionGroupName")
  valid_601732 = validateParameter(valid_601732, JString, required = true,
                                 default = nil)
  if valid_601732 != nil:
    section.add "OptionGroupName", valid_601732
  var valid_601733 = query.getOrDefault("Action")
  valid_601733 = validateParameter(valid_601733, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601733 != nil:
    section.add "Action", valid_601733
  var valid_601734 = query.getOrDefault("Version")
  valid_601734 = validateParameter(valid_601734, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601734 != nil:
    section.add "Version", valid_601734
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601735 = header.getOrDefault("X-Amz-Date")
  valid_601735 = validateParameter(valid_601735, JString, required = false,
                                 default = nil)
  if valid_601735 != nil:
    section.add "X-Amz-Date", valid_601735
  var valid_601736 = header.getOrDefault("X-Amz-Security-Token")
  valid_601736 = validateParameter(valid_601736, JString, required = false,
                                 default = nil)
  if valid_601736 != nil:
    section.add "X-Amz-Security-Token", valid_601736
  var valid_601737 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Content-Sha256", valid_601737
  var valid_601738 = header.getOrDefault("X-Amz-Algorithm")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-Algorithm", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Signature")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Signature", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-SignedHeaders", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Credential")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Credential", valid_601741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601742: Call_GetDeleteOptionGroup_601729; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601742.validator(path, query, header, formData, body)
  let scheme = call_601742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601742.url(scheme.get, call_601742.host, call_601742.base,
                         call_601742.route, valid.getOrDefault("path"))
  result = hook(call_601742, url, valid)

proc call*(call_601743: Call_GetDeleteOptionGroup_601729; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601744 = newJObject()
  add(query_601744, "OptionGroupName", newJString(OptionGroupName))
  add(query_601744, "Action", newJString(Action))
  add(query_601744, "Version", newJString(Version))
  result = call_601743.call(nil, query_601744, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_601729(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_601730, base: "/",
    url: url_GetDeleteOptionGroup_601731, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_601785 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBEngineVersions_601787(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_601786(path: JsonNode; query: JsonNode;
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
  var valid_601788 = query.getOrDefault("Action")
  valid_601788 = validateParameter(valid_601788, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601788 != nil:
    section.add "Action", valid_601788
  var valid_601789 = query.getOrDefault("Version")
  valid_601789 = validateParameter(valid_601789, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601789 != nil:
    section.add "Version", valid_601789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601790 = header.getOrDefault("X-Amz-Date")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-Date", valid_601790
  var valid_601791 = header.getOrDefault("X-Amz-Security-Token")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Security-Token", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Content-Sha256", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-Algorithm")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-Algorithm", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Signature")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Signature", valid_601794
  var valid_601795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601795 = validateParameter(valid_601795, JString, required = false,
                                 default = nil)
  if valid_601795 != nil:
    section.add "X-Amz-SignedHeaders", valid_601795
  var valid_601796 = header.getOrDefault("X-Amz-Credential")
  valid_601796 = validateParameter(valid_601796, JString, required = false,
                                 default = nil)
  if valid_601796 != nil:
    section.add "X-Amz-Credential", valid_601796
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
  var valid_601797 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_601797 = validateParameter(valid_601797, JBool, required = false, default = nil)
  if valid_601797 != nil:
    section.add "ListSupportedCharacterSets", valid_601797
  var valid_601798 = formData.getOrDefault("Engine")
  valid_601798 = validateParameter(valid_601798, JString, required = false,
                                 default = nil)
  if valid_601798 != nil:
    section.add "Engine", valid_601798
  var valid_601799 = formData.getOrDefault("Marker")
  valid_601799 = validateParameter(valid_601799, JString, required = false,
                                 default = nil)
  if valid_601799 != nil:
    section.add "Marker", valid_601799
  var valid_601800 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601800 = validateParameter(valid_601800, JString, required = false,
                                 default = nil)
  if valid_601800 != nil:
    section.add "DBParameterGroupFamily", valid_601800
  var valid_601801 = formData.getOrDefault("Filters")
  valid_601801 = validateParameter(valid_601801, JArray, required = false,
                                 default = nil)
  if valid_601801 != nil:
    section.add "Filters", valid_601801
  var valid_601802 = formData.getOrDefault("MaxRecords")
  valid_601802 = validateParameter(valid_601802, JInt, required = false, default = nil)
  if valid_601802 != nil:
    section.add "MaxRecords", valid_601802
  var valid_601803 = formData.getOrDefault("EngineVersion")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "EngineVersion", valid_601803
  var valid_601804 = formData.getOrDefault("DefaultOnly")
  valid_601804 = validateParameter(valid_601804, JBool, required = false, default = nil)
  if valid_601804 != nil:
    section.add "DefaultOnly", valid_601804
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601805: Call_PostDescribeDBEngineVersions_601785; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601805.validator(path, query, header, formData, body)
  let scheme = call_601805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601805.url(scheme.get, call_601805.host, call_601805.base,
                         call_601805.route, valid.getOrDefault("path"))
  result = hook(call_601805, url, valid)

proc call*(call_601806: Call_PostDescribeDBEngineVersions_601785;
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
  var query_601807 = newJObject()
  var formData_601808 = newJObject()
  add(formData_601808, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_601808, "Engine", newJString(Engine))
  add(formData_601808, "Marker", newJString(Marker))
  add(query_601807, "Action", newJString(Action))
  add(formData_601808, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601808.add "Filters", Filters
  add(formData_601808, "MaxRecords", newJInt(MaxRecords))
  add(formData_601808, "EngineVersion", newJString(EngineVersion))
  add(query_601807, "Version", newJString(Version))
  add(formData_601808, "DefaultOnly", newJBool(DefaultOnly))
  result = call_601806.call(nil, query_601807, nil, formData_601808, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_601785(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_601786, base: "/",
    url: url_PostDescribeDBEngineVersions_601787,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_601762 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBEngineVersions_601764(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_601763(path: JsonNode; query: JsonNode;
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
  var valid_601765 = query.getOrDefault("Engine")
  valid_601765 = validateParameter(valid_601765, JString, required = false,
                                 default = nil)
  if valid_601765 != nil:
    section.add "Engine", valid_601765
  var valid_601766 = query.getOrDefault("ListSupportedCharacterSets")
  valid_601766 = validateParameter(valid_601766, JBool, required = false, default = nil)
  if valid_601766 != nil:
    section.add "ListSupportedCharacterSets", valid_601766
  var valid_601767 = query.getOrDefault("MaxRecords")
  valid_601767 = validateParameter(valid_601767, JInt, required = false, default = nil)
  if valid_601767 != nil:
    section.add "MaxRecords", valid_601767
  var valid_601768 = query.getOrDefault("DBParameterGroupFamily")
  valid_601768 = validateParameter(valid_601768, JString, required = false,
                                 default = nil)
  if valid_601768 != nil:
    section.add "DBParameterGroupFamily", valid_601768
  var valid_601769 = query.getOrDefault("Filters")
  valid_601769 = validateParameter(valid_601769, JArray, required = false,
                                 default = nil)
  if valid_601769 != nil:
    section.add "Filters", valid_601769
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601770 = query.getOrDefault("Action")
  valid_601770 = validateParameter(valid_601770, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601770 != nil:
    section.add "Action", valid_601770
  var valid_601771 = query.getOrDefault("Marker")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "Marker", valid_601771
  var valid_601772 = query.getOrDefault("EngineVersion")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "EngineVersion", valid_601772
  var valid_601773 = query.getOrDefault("DefaultOnly")
  valid_601773 = validateParameter(valid_601773, JBool, required = false, default = nil)
  if valid_601773 != nil:
    section.add "DefaultOnly", valid_601773
  var valid_601774 = query.getOrDefault("Version")
  valid_601774 = validateParameter(valid_601774, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601774 != nil:
    section.add "Version", valid_601774
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601775 = header.getOrDefault("X-Amz-Date")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Date", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Security-Token")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Security-Token", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-Content-Sha256", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Algorithm")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Algorithm", valid_601778
  var valid_601779 = header.getOrDefault("X-Amz-Signature")
  valid_601779 = validateParameter(valid_601779, JString, required = false,
                                 default = nil)
  if valid_601779 != nil:
    section.add "X-Amz-Signature", valid_601779
  var valid_601780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601780 = validateParameter(valid_601780, JString, required = false,
                                 default = nil)
  if valid_601780 != nil:
    section.add "X-Amz-SignedHeaders", valid_601780
  var valid_601781 = header.getOrDefault("X-Amz-Credential")
  valid_601781 = validateParameter(valid_601781, JString, required = false,
                                 default = nil)
  if valid_601781 != nil:
    section.add "X-Amz-Credential", valid_601781
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601782: Call_GetDescribeDBEngineVersions_601762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601782.validator(path, query, header, formData, body)
  let scheme = call_601782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601782.url(scheme.get, call_601782.host, call_601782.base,
                         call_601782.route, valid.getOrDefault("path"))
  result = hook(call_601782, url, valid)

proc call*(call_601783: Call_GetDescribeDBEngineVersions_601762;
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
  var query_601784 = newJObject()
  add(query_601784, "Engine", newJString(Engine))
  add(query_601784, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_601784, "MaxRecords", newJInt(MaxRecords))
  add(query_601784, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601784.add "Filters", Filters
  add(query_601784, "Action", newJString(Action))
  add(query_601784, "Marker", newJString(Marker))
  add(query_601784, "EngineVersion", newJString(EngineVersion))
  add(query_601784, "DefaultOnly", newJBool(DefaultOnly))
  add(query_601784, "Version", newJString(Version))
  result = call_601783.call(nil, query_601784, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_601762(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_601763, base: "/",
    url: url_GetDescribeDBEngineVersions_601764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_601828 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBInstances_601830(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_601829(path: JsonNode; query: JsonNode;
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
  var valid_601831 = query.getOrDefault("Action")
  valid_601831 = validateParameter(valid_601831, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601831 != nil:
    section.add "Action", valid_601831
  var valid_601832 = query.getOrDefault("Version")
  valid_601832 = validateParameter(valid_601832, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601832 != nil:
    section.add "Version", valid_601832
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601833 = header.getOrDefault("X-Amz-Date")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "X-Amz-Date", valid_601833
  var valid_601834 = header.getOrDefault("X-Amz-Security-Token")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Security-Token", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Content-Sha256", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Algorithm")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Algorithm", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Signature")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Signature", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-SignedHeaders", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Credential")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Credential", valid_601839
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601840 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "DBInstanceIdentifier", valid_601840
  var valid_601841 = formData.getOrDefault("Marker")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "Marker", valid_601841
  var valid_601842 = formData.getOrDefault("Filters")
  valid_601842 = validateParameter(valid_601842, JArray, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "Filters", valid_601842
  var valid_601843 = formData.getOrDefault("MaxRecords")
  valid_601843 = validateParameter(valid_601843, JInt, required = false, default = nil)
  if valid_601843 != nil:
    section.add "MaxRecords", valid_601843
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601844: Call_PostDescribeDBInstances_601828; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601844.validator(path, query, header, formData, body)
  let scheme = call_601844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601844.url(scheme.get, call_601844.host, call_601844.base,
                         call_601844.route, valid.getOrDefault("path"))
  result = hook(call_601844, url, valid)

proc call*(call_601845: Call_PostDescribeDBInstances_601828;
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
  var query_601846 = newJObject()
  var formData_601847 = newJObject()
  add(formData_601847, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601847, "Marker", newJString(Marker))
  add(query_601846, "Action", newJString(Action))
  if Filters != nil:
    formData_601847.add "Filters", Filters
  add(formData_601847, "MaxRecords", newJInt(MaxRecords))
  add(query_601846, "Version", newJString(Version))
  result = call_601845.call(nil, query_601846, nil, formData_601847, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_601828(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_601829, base: "/",
    url: url_PostDescribeDBInstances_601830, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_601809 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBInstances_601811(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_601810(path: JsonNode; query: JsonNode;
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
  var valid_601812 = query.getOrDefault("MaxRecords")
  valid_601812 = validateParameter(valid_601812, JInt, required = false, default = nil)
  if valid_601812 != nil:
    section.add "MaxRecords", valid_601812
  var valid_601813 = query.getOrDefault("Filters")
  valid_601813 = validateParameter(valid_601813, JArray, required = false,
                                 default = nil)
  if valid_601813 != nil:
    section.add "Filters", valid_601813
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601814 = query.getOrDefault("Action")
  valid_601814 = validateParameter(valid_601814, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601814 != nil:
    section.add "Action", valid_601814
  var valid_601815 = query.getOrDefault("Marker")
  valid_601815 = validateParameter(valid_601815, JString, required = false,
                                 default = nil)
  if valid_601815 != nil:
    section.add "Marker", valid_601815
  var valid_601816 = query.getOrDefault("Version")
  valid_601816 = validateParameter(valid_601816, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601816 != nil:
    section.add "Version", valid_601816
  var valid_601817 = query.getOrDefault("DBInstanceIdentifier")
  valid_601817 = validateParameter(valid_601817, JString, required = false,
                                 default = nil)
  if valid_601817 != nil:
    section.add "DBInstanceIdentifier", valid_601817
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601818 = header.getOrDefault("X-Amz-Date")
  valid_601818 = validateParameter(valid_601818, JString, required = false,
                                 default = nil)
  if valid_601818 != nil:
    section.add "X-Amz-Date", valid_601818
  var valid_601819 = header.getOrDefault("X-Amz-Security-Token")
  valid_601819 = validateParameter(valid_601819, JString, required = false,
                                 default = nil)
  if valid_601819 != nil:
    section.add "X-Amz-Security-Token", valid_601819
  var valid_601820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601820 = validateParameter(valid_601820, JString, required = false,
                                 default = nil)
  if valid_601820 != nil:
    section.add "X-Amz-Content-Sha256", valid_601820
  var valid_601821 = header.getOrDefault("X-Amz-Algorithm")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Algorithm", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-Signature")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Signature", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-SignedHeaders", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-Credential")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Credential", valid_601824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601825: Call_GetDescribeDBInstances_601809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601825.validator(path, query, header, formData, body)
  let scheme = call_601825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601825.url(scheme.get, call_601825.host, call_601825.base,
                         call_601825.route, valid.getOrDefault("path"))
  result = hook(call_601825, url, valid)

proc call*(call_601826: Call_GetDescribeDBInstances_601809; MaxRecords: int = 0;
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
  var query_601827 = newJObject()
  add(query_601827, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601827.add "Filters", Filters
  add(query_601827, "Action", newJString(Action))
  add(query_601827, "Marker", newJString(Marker))
  add(query_601827, "Version", newJString(Version))
  add(query_601827, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601826.call(nil, query_601827, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_601809(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_601810, base: "/",
    url: url_GetDescribeDBInstances_601811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_601870 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBLogFiles_601872(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_601871(path: JsonNode; query: JsonNode;
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
  var valid_601873 = query.getOrDefault("Action")
  valid_601873 = validateParameter(valid_601873, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601873 != nil:
    section.add "Action", valid_601873
  var valid_601874 = query.getOrDefault("Version")
  valid_601874 = validateParameter(valid_601874, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601874 != nil:
    section.add "Version", valid_601874
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601875 = header.getOrDefault("X-Amz-Date")
  valid_601875 = validateParameter(valid_601875, JString, required = false,
                                 default = nil)
  if valid_601875 != nil:
    section.add "X-Amz-Date", valid_601875
  var valid_601876 = header.getOrDefault("X-Amz-Security-Token")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Security-Token", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Content-Sha256", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Algorithm")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Algorithm", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-Signature")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-Signature", valid_601879
  var valid_601880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-SignedHeaders", valid_601880
  var valid_601881 = header.getOrDefault("X-Amz-Credential")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-Credential", valid_601881
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
  var valid_601882 = formData.getOrDefault("FilenameContains")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "FilenameContains", valid_601882
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601883 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601883 = validateParameter(valid_601883, JString, required = true,
                                 default = nil)
  if valid_601883 != nil:
    section.add "DBInstanceIdentifier", valid_601883
  var valid_601884 = formData.getOrDefault("FileSize")
  valid_601884 = validateParameter(valid_601884, JInt, required = false, default = nil)
  if valid_601884 != nil:
    section.add "FileSize", valid_601884
  var valid_601885 = formData.getOrDefault("Marker")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "Marker", valid_601885
  var valid_601886 = formData.getOrDefault("Filters")
  valid_601886 = validateParameter(valid_601886, JArray, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "Filters", valid_601886
  var valid_601887 = formData.getOrDefault("MaxRecords")
  valid_601887 = validateParameter(valid_601887, JInt, required = false, default = nil)
  if valid_601887 != nil:
    section.add "MaxRecords", valid_601887
  var valid_601888 = formData.getOrDefault("FileLastWritten")
  valid_601888 = validateParameter(valid_601888, JInt, required = false, default = nil)
  if valid_601888 != nil:
    section.add "FileLastWritten", valid_601888
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601889: Call_PostDescribeDBLogFiles_601870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601889.validator(path, query, header, formData, body)
  let scheme = call_601889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601889.url(scheme.get, call_601889.host, call_601889.base,
                         call_601889.route, valid.getOrDefault("path"))
  result = hook(call_601889, url, valid)

proc call*(call_601890: Call_PostDescribeDBLogFiles_601870;
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
  var query_601891 = newJObject()
  var formData_601892 = newJObject()
  add(formData_601892, "FilenameContains", newJString(FilenameContains))
  add(formData_601892, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601892, "FileSize", newJInt(FileSize))
  add(formData_601892, "Marker", newJString(Marker))
  add(query_601891, "Action", newJString(Action))
  if Filters != nil:
    formData_601892.add "Filters", Filters
  add(formData_601892, "MaxRecords", newJInt(MaxRecords))
  add(formData_601892, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601891, "Version", newJString(Version))
  result = call_601890.call(nil, query_601891, nil, formData_601892, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_601870(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_601871, base: "/",
    url: url_PostDescribeDBLogFiles_601872, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_601848 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBLogFiles_601850(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_601849(path: JsonNode; query: JsonNode;
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
  var valid_601851 = query.getOrDefault("FileLastWritten")
  valid_601851 = validateParameter(valid_601851, JInt, required = false, default = nil)
  if valid_601851 != nil:
    section.add "FileLastWritten", valid_601851
  var valid_601852 = query.getOrDefault("MaxRecords")
  valid_601852 = validateParameter(valid_601852, JInt, required = false, default = nil)
  if valid_601852 != nil:
    section.add "MaxRecords", valid_601852
  var valid_601853 = query.getOrDefault("FilenameContains")
  valid_601853 = validateParameter(valid_601853, JString, required = false,
                                 default = nil)
  if valid_601853 != nil:
    section.add "FilenameContains", valid_601853
  var valid_601854 = query.getOrDefault("FileSize")
  valid_601854 = validateParameter(valid_601854, JInt, required = false, default = nil)
  if valid_601854 != nil:
    section.add "FileSize", valid_601854
  var valid_601855 = query.getOrDefault("Filters")
  valid_601855 = validateParameter(valid_601855, JArray, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "Filters", valid_601855
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601856 = query.getOrDefault("Action")
  valid_601856 = validateParameter(valid_601856, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601856 != nil:
    section.add "Action", valid_601856
  var valid_601857 = query.getOrDefault("Marker")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "Marker", valid_601857
  var valid_601858 = query.getOrDefault("Version")
  valid_601858 = validateParameter(valid_601858, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601858 != nil:
    section.add "Version", valid_601858
  var valid_601859 = query.getOrDefault("DBInstanceIdentifier")
  valid_601859 = validateParameter(valid_601859, JString, required = true,
                                 default = nil)
  if valid_601859 != nil:
    section.add "DBInstanceIdentifier", valid_601859
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601860 = header.getOrDefault("X-Amz-Date")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "X-Amz-Date", valid_601860
  var valid_601861 = header.getOrDefault("X-Amz-Security-Token")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Security-Token", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Content-Sha256", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Algorithm")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Algorithm", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Signature")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Signature", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-SignedHeaders", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-Credential")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-Credential", valid_601866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601867: Call_GetDescribeDBLogFiles_601848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601867.validator(path, query, header, formData, body)
  let scheme = call_601867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601867.url(scheme.get, call_601867.host, call_601867.base,
                         call_601867.route, valid.getOrDefault("path"))
  result = hook(call_601867, url, valid)

proc call*(call_601868: Call_GetDescribeDBLogFiles_601848;
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
  var query_601869 = newJObject()
  add(query_601869, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601869, "MaxRecords", newJInt(MaxRecords))
  add(query_601869, "FilenameContains", newJString(FilenameContains))
  add(query_601869, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_601869.add "Filters", Filters
  add(query_601869, "Action", newJString(Action))
  add(query_601869, "Marker", newJString(Marker))
  add(query_601869, "Version", newJString(Version))
  add(query_601869, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601868.call(nil, query_601869, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_601848(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_601849, base: "/",
    url: url_GetDescribeDBLogFiles_601850, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_601912 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameterGroups_601914(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_601913(path: JsonNode; query: JsonNode;
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
  var valid_601915 = query.getOrDefault("Action")
  valid_601915 = validateParameter(valid_601915, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601915 != nil:
    section.add "Action", valid_601915
  var valid_601916 = query.getOrDefault("Version")
  valid_601916 = validateParameter(valid_601916, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601916 != nil:
    section.add "Version", valid_601916
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601917 = header.getOrDefault("X-Amz-Date")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Date", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-Security-Token")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-Security-Token", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Content-Sha256", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Algorithm")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Algorithm", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Signature")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Signature", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-SignedHeaders", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Credential")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Credential", valid_601923
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601924 = formData.getOrDefault("DBParameterGroupName")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "DBParameterGroupName", valid_601924
  var valid_601925 = formData.getOrDefault("Marker")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "Marker", valid_601925
  var valid_601926 = formData.getOrDefault("Filters")
  valid_601926 = validateParameter(valid_601926, JArray, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "Filters", valid_601926
  var valid_601927 = formData.getOrDefault("MaxRecords")
  valid_601927 = validateParameter(valid_601927, JInt, required = false, default = nil)
  if valid_601927 != nil:
    section.add "MaxRecords", valid_601927
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601928: Call_PostDescribeDBParameterGroups_601912; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601928.validator(path, query, header, formData, body)
  let scheme = call_601928.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601928.url(scheme.get, call_601928.host, call_601928.base,
                         call_601928.route, valid.getOrDefault("path"))
  result = hook(call_601928, url, valid)

proc call*(call_601929: Call_PostDescribeDBParameterGroups_601912;
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
  var query_601930 = newJObject()
  var formData_601931 = newJObject()
  add(formData_601931, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601931, "Marker", newJString(Marker))
  add(query_601930, "Action", newJString(Action))
  if Filters != nil:
    formData_601931.add "Filters", Filters
  add(formData_601931, "MaxRecords", newJInt(MaxRecords))
  add(query_601930, "Version", newJString(Version))
  result = call_601929.call(nil, query_601930, nil, formData_601931, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_601912(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_601913, base: "/",
    url: url_PostDescribeDBParameterGroups_601914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_601893 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameterGroups_601895(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_601894(path: JsonNode; query: JsonNode;
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
  var valid_601896 = query.getOrDefault("MaxRecords")
  valid_601896 = validateParameter(valid_601896, JInt, required = false, default = nil)
  if valid_601896 != nil:
    section.add "MaxRecords", valid_601896
  var valid_601897 = query.getOrDefault("Filters")
  valid_601897 = validateParameter(valid_601897, JArray, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "Filters", valid_601897
  var valid_601898 = query.getOrDefault("DBParameterGroupName")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "DBParameterGroupName", valid_601898
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601899 = query.getOrDefault("Action")
  valid_601899 = validateParameter(valid_601899, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601899 != nil:
    section.add "Action", valid_601899
  var valid_601900 = query.getOrDefault("Marker")
  valid_601900 = validateParameter(valid_601900, JString, required = false,
                                 default = nil)
  if valid_601900 != nil:
    section.add "Marker", valid_601900
  var valid_601901 = query.getOrDefault("Version")
  valid_601901 = validateParameter(valid_601901, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601901 != nil:
    section.add "Version", valid_601901
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601902 = header.getOrDefault("X-Amz-Date")
  valid_601902 = validateParameter(valid_601902, JString, required = false,
                                 default = nil)
  if valid_601902 != nil:
    section.add "X-Amz-Date", valid_601902
  var valid_601903 = header.getOrDefault("X-Amz-Security-Token")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "X-Amz-Security-Token", valid_601903
  var valid_601904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Content-Sha256", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Algorithm")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Algorithm", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Signature")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Signature", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-SignedHeaders", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-Credential")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Credential", valid_601908
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601909: Call_GetDescribeDBParameterGroups_601893; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601909.validator(path, query, header, formData, body)
  let scheme = call_601909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601909.url(scheme.get, call_601909.host, call_601909.base,
                         call_601909.route, valid.getOrDefault("path"))
  result = hook(call_601909, url, valid)

proc call*(call_601910: Call_GetDescribeDBParameterGroups_601893;
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
  var query_601911 = newJObject()
  add(query_601911, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601911.add "Filters", Filters
  add(query_601911, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601911, "Action", newJString(Action))
  add(query_601911, "Marker", newJString(Marker))
  add(query_601911, "Version", newJString(Version))
  result = call_601910.call(nil, query_601911, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_601893(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_601894, base: "/",
    url: url_GetDescribeDBParameterGroups_601895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_601952 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameters_601954(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_601953(path: JsonNode; query: JsonNode;
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
  var valid_601955 = query.getOrDefault("Action")
  valid_601955 = validateParameter(valid_601955, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601955 != nil:
    section.add "Action", valid_601955
  var valid_601956 = query.getOrDefault("Version")
  valid_601956 = validateParameter(valid_601956, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601964 = formData.getOrDefault("DBParameterGroupName")
  valid_601964 = validateParameter(valid_601964, JString, required = true,
                                 default = nil)
  if valid_601964 != nil:
    section.add "DBParameterGroupName", valid_601964
  var valid_601965 = formData.getOrDefault("Marker")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "Marker", valid_601965
  var valid_601966 = formData.getOrDefault("Filters")
  valid_601966 = validateParameter(valid_601966, JArray, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "Filters", valid_601966
  var valid_601967 = formData.getOrDefault("MaxRecords")
  valid_601967 = validateParameter(valid_601967, JInt, required = false, default = nil)
  if valid_601967 != nil:
    section.add "MaxRecords", valid_601967
  var valid_601968 = formData.getOrDefault("Source")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "Source", valid_601968
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601969: Call_PostDescribeDBParameters_601952; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601969.validator(path, query, header, formData, body)
  let scheme = call_601969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601969.url(scheme.get, call_601969.host, call_601969.base,
                         call_601969.route, valid.getOrDefault("path"))
  result = hook(call_601969, url, valid)

proc call*(call_601970: Call_PostDescribeDBParameters_601952;
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
  var query_601971 = newJObject()
  var formData_601972 = newJObject()
  add(formData_601972, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601972, "Marker", newJString(Marker))
  add(query_601971, "Action", newJString(Action))
  if Filters != nil:
    formData_601972.add "Filters", Filters
  add(formData_601972, "MaxRecords", newJInt(MaxRecords))
  add(query_601971, "Version", newJString(Version))
  add(formData_601972, "Source", newJString(Source))
  result = call_601970.call(nil, query_601971, nil, formData_601972, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_601952(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_601953, base: "/",
    url: url_PostDescribeDBParameters_601954, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_601932 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameters_601934(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_601933(path: JsonNode; query: JsonNode;
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
  var valid_601935 = query.getOrDefault("MaxRecords")
  valid_601935 = validateParameter(valid_601935, JInt, required = false, default = nil)
  if valid_601935 != nil:
    section.add "MaxRecords", valid_601935
  var valid_601936 = query.getOrDefault("Filters")
  valid_601936 = validateParameter(valid_601936, JArray, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "Filters", valid_601936
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_601937 = query.getOrDefault("DBParameterGroupName")
  valid_601937 = validateParameter(valid_601937, JString, required = true,
                                 default = nil)
  if valid_601937 != nil:
    section.add "DBParameterGroupName", valid_601937
  var valid_601938 = query.getOrDefault("Action")
  valid_601938 = validateParameter(valid_601938, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601938 != nil:
    section.add "Action", valid_601938
  var valid_601939 = query.getOrDefault("Marker")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "Marker", valid_601939
  var valid_601940 = query.getOrDefault("Source")
  valid_601940 = validateParameter(valid_601940, JString, required = false,
                                 default = nil)
  if valid_601940 != nil:
    section.add "Source", valid_601940
  var valid_601941 = query.getOrDefault("Version")
  valid_601941 = validateParameter(valid_601941, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601949: Call_GetDescribeDBParameters_601932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601949.validator(path, query, header, formData, body)
  let scheme = call_601949.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601949.url(scheme.get, call_601949.host, call_601949.base,
                         call_601949.route, valid.getOrDefault("path"))
  result = hook(call_601949, url, valid)

proc call*(call_601950: Call_GetDescribeDBParameters_601932;
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
  var query_601951 = newJObject()
  add(query_601951, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601951.add "Filters", Filters
  add(query_601951, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601951, "Action", newJString(Action))
  add(query_601951, "Marker", newJString(Marker))
  add(query_601951, "Source", newJString(Source))
  add(query_601951, "Version", newJString(Version))
  result = call_601950.call(nil, query_601951, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_601932(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_601933, base: "/",
    url: url_GetDescribeDBParameters_601934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_601992 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSecurityGroups_601994(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_601993(path: JsonNode; query: JsonNode;
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
  var valid_601995 = query.getOrDefault("Action")
  valid_601995 = validateParameter(valid_601995, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601995 != nil:
    section.add "Action", valid_601995
  var valid_601996 = query.getOrDefault("Version")
  valid_601996 = validateParameter(valid_601996, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601996 != nil:
    section.add "Version", valid_601996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601997 = header.getOrDefault("X-Amz-Date")
  valid_601997 = validateParameter(valid_601997, JString, required = false,
                                 default = nil)
  if valid_601997 != nil:
    section.add "X-Amz-Date", valid_601997
  var valid_601998 = header.getOrDefault("X-Amz-Security-Token")
  valid_601998 = validateParameter(valid_601998, JString, required = false,
                                 default = nil)
  if valid_601998 != nil:
    section.add "X-Amz-Security-Token", valid_601998
  var valid_601999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601999 = validateParameter(valid_601999, JString, required = false,
                                 default = nil)
  if valid_601999 != nil:
    section.add "X-Amz-Content-Sha256", valid_601999
  var valid_602000 = header.getOrDefault("X-Amz-Algorithm")
  valid_602000 = validateParameter(valid_602000, JString, required = false,
                                 default = nil)
  if valid_602000 != nil:
    section.add "X-Amz-Algorithm", valid_602000
  var valid_602001 = header.getOrDefault("X-Amz-Signature")
  valid_602001 = validateParameter(valid_602001, JString, required = false,
                                 default = nil)
  if valid_602001 != nil:
    section.add "X-Amz-Signature", valid_602001
  var valid_602002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602002 = validateParameter(valid_602002, JString, required = false,
                                 default = nil)
  if valid_602002 != nil:
    section.add "X-Amz-SignedHeaders", valid_602002
  var valid_602003 = header.getOrDefault("X-Amz-Credential")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Credential", valid_602003
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602004 = formData.getOrDefault("DBSecurityGroupName")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "DBSecurityGroupName", valid_602004
  var valid_602005 = formData.getOrDefault("Marker")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "Marker", valid_602005
  var valid_602006 = formData.getOrDefault("Filters")
  valid_602006 = validateParameter(valid_602006, JArray, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "Filters", valid_602006
  var valid_602007 = formData.getOrDefault("MaxRecords")
  valid_602007 = validateParameter(valid_602007, JInt, required = false, default = nil)
  if valid_602007 != nil:
    section.add "MaxRecords", valid_602007
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602008: Call_PostDescribeDBSecurityGroups_601992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602008.validator(path, query, header, formData, body)
  let scheme = call_602008.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602008.url(scheme.get, call_602008.host, call_602008.base,
                         call_602008.route, valid.getOrDefault("path"))
  result = hook(call_602008, url, valid)

proc call*(call_602009: Call_PostDescribeDBSecurityGroups_601992;
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
  var query_602010 = newJObject()
  var formData_602011 = newJObject()
  add(formData_602011, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602011, "Marker", newJString(Marker))
  add(query_602010, "Action", newJString(Action))
  if Filters != nil:
    formData_602011.add "Filters", Filters
  add(formData_602011, "MaxRecords", newJInt(MaxRecords))
  add(query_602010, "Version", newJString(Version))
  result = call_602009.call(nil, query_602010, nil, formData_602011, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_601992(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_601993, base: "/",
    url: url_PostDescribeDBSecurityGroups_601994,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_601973 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSecurityGroups_601975(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_601974(path: JsonNode; query: JsonNode;
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
  var valid_601976 = query.getOrDefault("MaxRecords")
  valid_601976 = validateParameter(valid_601976, JInt, required = false, default = nil)
  if valid_601976 != nil:
    section.add "MaxRecords", valid_601976
  var valid_601977 = query.getOrDefault("DBSecurityGroupName")
  valid_601977 = validateParameter(valid_601977, JString, required = false,
                                 default = nil)
  if valid_601977 != nil:
    section.add "DBSecurityGroupName", valid_601977
  var valid_601978 = query.getOrDefault("Filters")
  valid_601978 = validateParameter(valid_601978, JArray, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "Filters", valid_601978
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601979 = query.getOrDefault("Action")
  valid_601979 = validateParameter(valid_601979, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601979 != nil:
    section.add "Action", valid_601979
  var valid_601980 = query.getOrDefault("Marker")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "Marker", valid_601980
  var valid_601981 = query.getOrDefault("Version")
  valid_601981 = validateParameter(valid_601981, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_601981 != nil:
    section.add "Version", valid_601981
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601982 = header.getOrDefault("X-Amz-Date")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Date", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Security-Token")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Security-Token", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-Content-Sha256", valid_601984
  var valid_601985 = header.getOrDefault("X-Amz-Algorithm")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "X-Amz-Algorithm", valid_601985
  var valid_601986 = header.getOrDefault("X-Amz-Signature")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "X-Amz-Signature", valid_601986
  var valid_601987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601987 = validateParameter(valid_601987, JString, required = false,
                                 default = nil)
  if valid_601987 != nil:
    section.add "X-Amz-SignedHeaders", valid_601987
  var valid_601988 = header.getOrDefault("X-Amz-Credential")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Credential", valid_601988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601989: Call_GetDescribeDBSecurityGroups_601973; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601989.validator(path, query, header, formData, body)
  let scheme = call_601989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601989.url(scheme.get, call_601989.host, call_601989.base,
                         call_601989.route, valid.getOrDefault("path"))
  result = hook(call_601989, url, valid)

proc call*(call_601990: Call_GetDescribeDBSecurityGroups_601973;
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
  var query_601991 = newJObject()
  add(query_601991, "MaxRecords", newJInt(MaxRecords))
  add(query_601991, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_601991.add "Filters", Filters
  add(query_601991, "Action", newJString(Action))
  add(query_601991, "Marker", newJString(Marker))
  add(query_601991, "Version", newJString(Version))
  result = call_601990.call(nil, query_601991, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_601973(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_601974, base: "/",
    url: url_GetDescribeDBSecurityGroups_601975,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602033 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSnapshots_602035(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_602034(path: JsonNode; query: JsonNode;
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
  var valid_602036 = query.getOrDefault("Action")
  valid_602036 = validateParameter(valid_602036, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602036 != nil:
    section.add "Action", valid_602036
  var valid_602037 = query.getOrDefault("Version")
  valid_602037 = validateParameter(valid_602037, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602045 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "DBInstanceIdentifier", valid_602045
  var valid_602046 = formData.getOrDefault("SnapshotType")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "SnapshotType", valid_602046
  var valid_602047 = formData.getOrDefault("Marker")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "Marker", valid_602047
  var valid_602048 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "DBSnapshotIdentifier", valid_602048
  var valid_602049 = formData.getOrDefault("Filters")
  valid_602049 = validateParameter(valid_602049, JArray, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "Filters", valid_602049
  var valid_602050 = formData.getOrDefault("MaxRecords")
  valid_602050 = validateParameter(valid_602050, JInt, required = false, default = nil)
  if valid_602050 != nil:
    section.add "MaxRecords", valid_602050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602051: Call_PostDescribeDBSnapshots_602033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602051.validator(path, query, header, formData, body)
  let scheme = call_602051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602051.url(scheme.get, call_602051.host, call_602051.base,
                         call_602051.route, valid.getOrDefault("path"))
  result = hook(call_602051, url, valid)

proc call*(call_602052: Call_PostDescribeDBSnapshots_602033;
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
  var query_602053 = newJObject()
  var formData_602054 = newJObject()
  add(formData_602054, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602054, "SnapshotType", newJString(SnapshotType))
  add(formData_602054, "Marker", newJString(Marker))
  add(formData_602054, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602053, "Action", newJString(Action))
  if Filters != nil:
    formData_602054.add "Filters", Filters
  add(formData_602054, "MaxRecords", newJInt(MaxRecords))
  add(query_602053, "Version", newJString(Version))
  result = call_602052.call(nil, query_602053, nil, formData_602054, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602033(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602034, base: "/",
    url: url_PostDescribeDBSnapshots_602035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_602012 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSnapshots_602014(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_602013(path: JsonNode; query: JsonNode;
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
  var valid_602015 = query.getOrDefault("MaxRecords")
  valid_602015 = validateParameter(valid_602015, JInt, required = false, default = nil)
  if valid_602015 != nil:
    section.add "MaxRecords", valid_602015
  var valid_602016 = query.getOrDefault("Filters")
  valid_602016 = validateParameter(valid_602016, JArray, required = false,
                                 default = nil)
  if valid_602016 != nil:
    section.add "Filters", valid_602016
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602017 = query.getOrDefault("Action")
  valid_602017 = validateParameter(valid_602017, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602017 != nil:
    section.add "Action", valid_602017
  var valid_602018 = query.getOrDefault("Marker")
  valid_602018 = validateParameter(valid_602018, JString, required = false,
                                 default = nil)
  if valid_602018 != nil:
    section.add "Marker", valid_602018
  var valid_602019 = query.getOrDefault("SnapshotType")
  valid_602019 = validateParameter(valid_602019, JString, required = false,
                                 default = nil)
  if valid_602019 != nil:
    section.add "SnapshotType", valid_602019
  var valid_602020 = query.getOrDefault("Version")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602020 != nil:
    section.add "Version", valid_602020
  var valid_602021 = query.getOrDefault("DBInstanceIdentifier")
  valid_602021 = validateParameter(valid_602021, JString, required = false,
                                 default = nil)
  if valid_602021 != nil:
    section.add "DBInstanceIdentifier", valid_602021
  var valid_602022 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "DBSnapshotIdentifier", valid_602022
  result.add "query", section
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

proc call*(call_602030: Call_GetDescribeDBSnapshots_602012; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602030.validator(path, query, header, formData, body)
  let scheme = call_602030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602030.url(scheme.get, call_602030.host, call_602030.base,
                         call_602030.route, valid.getOrDefault("path"))
  result = hook(call_602030, url, valid)

proc call*(call_602031: Call_GetDescribeDBSnapshots_602012; MaxRecords: int = 0;
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
  var query_602032 = newJObject()
  add(query_602032, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602032.add "Filters", Filters
  add(query_602032, "Action", newJString(Action))
  add(query_602032, "Marker", newJString(Marker))
  add(query_602032, "SnapshotType", newJString(SnapshotType))
  add(query_602032, "Version", newJString(Version))
  add(query_602032, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602032, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602031.call(nil, query_602032, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_602012(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_602013, base: "/",
    url: url_GetDescribeDBSnapshots_602014, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602074 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSubnetGroups_602076(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_602075(path: JsonNode; query: JsonNode;
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
  var valid_602077 = query.getOrDefault("Action")
  valid_602077 = validateParameter(valid_602077, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602077 != nil:
    section.add "Action", valid_602077
  var valid_602078 = query.getOrDefault("Version")
  valid_602078 = validateParameter(valid_602078, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602078 != nil:
    section.add "Version", valid_602078
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602079 = header.getOrDefault("X-Amz-Date")
  valid_602079 = validateParameter(valid_602079, JString, required = false,
                                 default = nil)
  if valid_602079 != nil:
    section.add "X-Amz-Date", valid_602079
  var valid_602080 = header.getOrDefault("X-Amz-Security-Token")
  valid_602080 = validateParameter(valid_602080, JString, required = false,
                                 default = nil)
  if valid_602080 != nil:
    section.add "X-Amz-Security-Token", valid_602080
  var valid_602081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Content-Sha256", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Algorithm")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Algorithm", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Signature")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Signature", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-SignedHeaders", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Credential")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Credential", valid_602085
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602086 = formData.getOrDefault("DBSubnetGroupName")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "DBSubnetGroupName", valid_602086
  var valid_602087 = formData.getOrDefault("Marker")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "Marker", valid_602087
  var valid_602088 = formData.getOrDefault("Filters")
  valid_602088 = validateParameter(valid_602088, JArray, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "Filters", valid_602088
  var valid_602089 = formData.getOrDefault("MaxRecords")
  valid_602089 = validateParameter(valid_602089, JInt, required = false, default = nil)
  if valid_602089 != nil:
    section.add "MaxRecords", valid_602089
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602090: Call_PostDescribeDBSubnetGroups_602074; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602090.validator(path, query, header, formData, body)
  let scheme = call_602090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602090.url(scheme.get, call_602090.host, call_602090.base,
                         call_602090.route, valid.getOrDefault("path"))
  result = hook(call_602090, url, valid)

proc call*(call_602091: Call_PostDescribeDBSubnetGroups_602074;
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
  var query_602092 = newJObject()
  var formData_602093 = newJObject()
  add(formData_602093, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602093, "Marker", newJString(Marker))
  add(query_602092, "Action", newJString(Action))
  if Filters != nil:
    formData_602093.add "Filters", Filters
  add(formData_602093, "MaxRecords", newJInt(MaxRecords))
  add(query_602092, "Version", newJString(Version))
  result = call_602091.call(nil, query_602092, nil, formData_602093, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602074(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602075, base: "/",
    url: url_PostDescribeDBSubnetGroups_602076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602055 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSubnetGroups_602057(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_602056(path: JsonNode; query: JsonNode;
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
  var valid_602058 = query.getOrDefault("MaxRecords")
  valid_602058 = validateParameter(valid_602058, JInt, required = false, default = nil)
  if valid_602058 != nil:
    section.add "MaxRecords", valid_602058
  var valid_602059 = query.getOrDefault("Filters")
  valid_602059 = validateParameter(valid_602059, JArray, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "Filters", valid_602059
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602060 = query.getOrDefault("Action")
  valid_602060 = validateParameter(valid_602060, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602060 != nil:
    section.add "Action", valid_602060
  var valid_602061 = query.getOrDefault("Marker")
  valid_602061 = validateParameter(valid_602061, JString, required = false,
                                 default = nil)
  if valid_602061 != nil:
    section.add "Marker", valid_602061
  var valid_602062 = query.getOrDefault("DBSubnetGroupName")
  valid_602062 = validateParameter(valid_602062, JString, required = false,
                                 default = nil)
  if valid_602062 != nil:
    section.add "DBSubnetGroupName", valid_602062
  var valid_602063 = query.getOrDefault("Version")
  valid_602063 = validateParameter(valid_602063, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602063 != nil:
    section.add "Version", valid_602063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602064 = header.getOrDefault("X-Amz-Date")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "X-Amz-Date", valid_602064
  var valid_602065 = header.getOrDefault("X-Amz-Security-Token")
  valid_602065 = validateParameter(valid_602065, JString, required = false,
                                 default = nil)
  if valid_602065 != nil:
    section.add "X-Amz-Security-Token", valid_602065
  var valid_602066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Content-Sha256", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Algorithm")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Algorithm", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Signature")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Signature", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-SignedHeaders", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Credential")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Credential", valid_602070
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602071: Call_GetDescribeDBSubnetGroups_602055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602071.validator(path, query, header, formData, body)
  let scheme = call_602071.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602071.url(scheme.get, call_602071.host, call_602071.base,
                         call_602071.route, valid.getOrDefault("path"))
  result = hook(call_602071, url, valid)

proc call*(call_602072: Call_GetDescribeDBSubnetGroups_602055; MaxRecords: int = 0;
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
  var query_602073 = newJObject()
  add(query_602073, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602073.add "Filters", Filters
  add(query_602073, "Action", newJString(Action))
  add(query_602073, "Marker", newJString(Marker))
  add(query_602073, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602073, "Version", newJString(Version))
  result = call_602072.call(nil, query_602073, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602055(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602056, base: "/",
    url: url_GetDescribeDBSubnetGroups_602057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602113 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEngineDefaultParameters_602115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_602114(path: JsonNode;
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
  var valid_602116 = query.getOrDefault("Action")
  valid_602116 = validateParameter(valid_602116, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602116 != nil:
    section.add "Action", valid_602116
  var valid_602117 = query.getOrDefault("Version")
  valid_602117 = validateParameter(valid_602117, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602117 != nil:
    section.add "Version", valid_602117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602118 = header.getOrDefault("X-Amz-Date")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Date", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Security-Token")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Security-Token", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Content-Sha256", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-Algorithm")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-Algorithm", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Signature")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Signature", valid_602122
  var valid_602123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "X-Amz-SignedHeaders", valid_602123
  var valid_602124 = header.getOrDefault("X-Amz-Credential")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Credential", valid_602124
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602125 = formData.getOrDefault("Marker")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "Marker", valid_602125
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602126 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602126 = validateParameter(valid_602126, JString, required = true,
                                 default = nil)
  if valid_602126 != nil:
    section.add "DBParameterGroupFamily", valid_602126
  var valid_602127 = formData.getOrDefault("Filters")
  valid_602127 = validateParameter(valid_602127, JArray, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "Filters", valid_602127
  var valid_602128 = formData.getOrDefault("MaxRecords")
  valid_602128 = validateParameter(valid_602128, JInt, required = false, default = nil)
  if valid_602128 != nil:
    section.add "MaxRecords", valid_602128
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602129: Call_PostDescribeEngineDefaultParameters_602113;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602129.validator(path, query, header, formData, body)
  let scheme = call_602129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602129.url(scheme.get, call_602129.host, call_602129.base,
                         call_602129.route, valid.getOrDefault("path"))
  result = hook(call_602129, url, valid)

proc call*(call_602130: Call_PostDescribeEngineDefaultParameters_602113;
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
  var query_602131 = newJObject()
  var formData_602132 = newJObject()
  add(formData_602132, "Marker", newJString(Marker))
  add(query_602131, "Action", newJString(Action))
  add(formData_602132, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_602132.add "Filters", Filters
  add(formData_602132, "MaxRecords", newJInt(MaxRecords))
  add(query_602131, "Version", newJString(Version))
  result = call_602130.call(nil, query_602131, nil, formData_602132, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602113(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602114, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602094 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEngineDefaultParameters_602096(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_602095(path: JsonNode;
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
  var valid_602097 = query.getOrDefault("MaxRecords")
  valid_602097 = validateParameter(valid_602097, JInt, required = false, default = nil)
  if valid_602097 != nil:
    section.add "MaxRecords", valid_602097
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602098 = query.getOrDefault("DBParameterGroupFamily")
  valid_602098 = validateParameter(valid_602098, JString, required = true,
                                 default = nil)
  if valid_602098 != nil:
    section.add "DBParameterGroupFamily", valid_602098
  var valid_602099 = query.getOrDefault("Filters")
  valid_602099 = validateParameter(valid_602099, JArray, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "Filters", valid_602099
  var valid_602100 = query.getOrDefault("Action")
  valid_602100 = validateParameter(valid_602100, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602100 != nil:
    section.add "Action", valid_602100
  var valid_602101 = query.getOrDefault("Marker")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "Marker", valid_602101
  var valid_602102 = query.getOrDefault("Version")
  valid_602102 = validateParameter(valid_602102, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602102 != nil:
    section.add "Version", valid_602102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602103 = header.getOrDefault("X-Amz-Date")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Date", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Security-Token")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Security-Token", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Content-Sha256", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-Algorithm")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-Algorithm", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Signature")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Signature", valid_602107
  var valid_602108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "X-Amz-SignedHeaders", valid_602108
  var valid_602109 = header.getOrDefault("X-Amz-Credential")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Credential", valid_602109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602110: Call_GetDescribeEngineDefaultParameters_602094;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602110.validator(path, query, header, formData, body)
  let scheme = call_602110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602110.url(scheme.get, call_602110.host, call_602110.base,
                         call_602110.route, valid.getOrDefault("path"))
  result = hook(call_602110, url, valid)

proc call*(call_602111: Call_GetDescribeEngineDefaultParameters_602094;
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
  var query_602112 = newJObject()
  add(query_602112, "MaxRecords", newJInt(MaxRecords))
  add(query_602112, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_602112.add "Filters", Filters
  add(query_602112, "Action", newJString(Action))
  add(query_602112, "Marker", newJString(Marker))
  add(query_602112, "Version", newJString(Version))
  result = call_602111.call(nil, query_602112, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602094(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602095, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602096,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602150 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventCategories_602152(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_602151(path: JsonNode; query: JsonNode;
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
  var valid_602153 = query.getOrDefault("Action")
  valid_602153 = validateParameter(valid_602153, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602153 != nil:
    section.add "Action", valid_602153
  var valid_602154 = query.getOrDefault("Version")
  valid_602154 = validateParameter(valid_602154, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602154 != nil:
    section.add "Version", valid_602154
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602155 = header.getOrDefault("X-Amz-Date")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Date", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-Security-Token")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-Security-Token", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Content-Sha256", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Algorithm")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Algorithm", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Signature")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Signature", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-SignedHeaders", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Credential")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Credential", valid_602161
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_602162 = formData.getOrDefault("Filters")
  valid_602162 = validateParameter(valid_602162, JArray, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "Filters", valid_602162
  var valid_602163 = formData.getOrDefault("SourceType")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "SourceType", valid_602163
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602164: Call_PostDescribeEventCategories_602150; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602164.validator(path, query, header, formData, body)
  let scheme = call_602164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602164.url(scheme.get, call_602164.host, call_602164.base,
                         call_602164.route, valid.getOrDefault("path"))
  result = hook(call_602164, url, valid)

proc call*(call_602165: Call_PostDescribeEventCategories_602150;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_602166 = newJObject()
  var formData_602167 = newJObject()
  add(query_602166, "Action", newJString(Action))
  if Filters != nil:
    formData_602167.add "Filters", Filters
  add(query_602166, "Version", newJString(Version))
  add(formData_602167, "SourceType", newJString(SourceType))
  result = call_602165.call(nil, query_602166, nil, formData_602167, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602150(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602151, base: "/",
    url: url_PostDescribeEventCategories_602152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602133 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventCategories_602135(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_602134(path: JsonNode; query: JsonNode;
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
  var valid_602136 = query.getOrDefault("SourceType")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "SourceType", valid_602136
  var valid_602137 = query.getOrDefault("Filters")
  valid_602137 = validateParameter(valid_602137, JArray, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "Filters", valid_602137
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602138 = query.getOrDefault("Action")
  valid_602138 = validateParameter(valid_602138, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602138 != nil:
    section.add "Action", valid_602138
  var valid_602139 = query.getOrDefault("Version")
  valid_602139 = validateParameter(valid_602139, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602139 != nil:
    section.add "Version", valid_602139
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602140 = header.getOrDefault("X-Amz-Date")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Date", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-Security-Token")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Security-Token", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Content-Sha256", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Algorithm")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Algorithm", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Signature")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Signature", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-SignedHeaders", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Credential")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Credential", valid_602146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602147: Call_GetDescribeEventCategories_602133; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602147.validator(path, query, header, formData, body)
  let scheme = call_602147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602147.url(scheme.get, call_602147.host, call_602147.base,
                         call_602147.route, valid.getOrDefault("path"))
  result = hook(call_602147, url, valid)

proc call*(call_602148: Call_GetDescribeEventCategories_602133;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602149 = newJObject()
  add(query_602149, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_602149.add "Filters", Filters
  add(query_602149, "Action", newJString(Action))
  add(query_602149, "Version", newJString(Version))
  result = call_602148.call(nil, query_602149, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602133(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602134, base: "/",
    url: url_GetDescribeEventCategories_602135,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_602187 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventSubscriptions_602189(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_602188(path: JsonNode;
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
  var valid_602190 = query.getOrDefault("Action")
  valid_602190 = validateParameter(valid_602190, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602190 != nil:
    section.add "Action", valid_602190
  var valid_602191 = query.getOrDefault("Version")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602191 != nil:
    section.add "Version", valid_602191
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602192 = header.getOrDefault("X-Amz-Date")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Date", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Security-Token")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Security-Token", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-Content-Sha256", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Algorithm")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Algorithm", valid_602195
  var valid_602196 = header.getOrDefault("X-Amz-Signature")
  valid_602196 = validateParameter(valid_602196, JString, required = false,
                                 default = nil)
  if valid_602196 != nil:
    section.add "X-Amz-Signature", valid_602196
  var valid_602197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602197 = validateParameter(valid_602197, JString, required = false,
                                 default = nil)
  if valid_602197 != nil:
    section.add "X-Amz-SignedHeaders", valid_602197
  var valid_602198 = header.getOrDefault("X-Amz-Credential")
  valid_602198 = validateParameter(valid_602198, JString, required = false,
                                 default = nil)
  if valid_602198 != nil:
    section.add "X-Amz-Credential", valid_602198
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602199 = formData.getOrDefault("Marker")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "Marker", valid_602199
  var valid_602200 = formData.getOrDefault("SubscriptionName")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "SubscriptionName", valid_602200
  var valid_602201 = formData.getOrDefault("Filters")
  valid_602201 = validateParameter(valid_602201, JArray, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "Filters", valid_602201
  var valid_602202 = formData.getOrDefault("MaxRecords")
  valid_602202 = validateParameter(valid_602202, JInt, required = false, default = nil)
  if valid_602202 != nil:
    section.add "MaxRecords", valid_602202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602203: Call_PostDescribeEventSubscriptions_602187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602203.validator(path, query, header, formData, body)
  let scheme = call_602203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602203.url(scheme.get, call_602203.host, call_602203.base,
                         call_602203.route, valid.getOrDefault("path"))
  result = hook(call_602203, url, valid)

proc call*(call_602204: Call_PostDescribeEventSubscriptions_602187;
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
  var query_602205 = newJObject()
  var formData_602206 = newJObject()
  add(formData_602206, "Marker", newJString(Marker))
  add(formData_602206, "SubscriptionName", newJString(SubscriptionName))
  add(query_602205, "Action", newJString(Action))
  if Filters != nil:
    formData_602206.add "Filters", Filters
  add(formData_602206, "MaxRecords", newJInt(MaxRecords))
  add(query_602205, "Version", newJString(Version))
  result = call_602204.call(nil, query_602205, nil, formData_602206, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_602187(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_602188, base: "/",
    url: url_PostDescribeEventSubscriptions_602189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_602168 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventSubscriptions_602170(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_602169(path: JsonNode; query: JsonNode;
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
  var valid_602171 = query.getOrDefault("MaxRecords")
  valid_602171 = validateParameter(valid_602171, JInt, required = false, default = nil)
  if valid_602171 != nil:
    section.add "MaxRecords", valid_602171
  var valid_602172 = query.getOrDefault("Filters")
  valid_602172 = validateParameter(valid_602172, JArray, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "Filters", valid_602172
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602173 = query.getOrDefault("Action")
  valid_602173 = validateParameter(valid_602173, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602173 != nil:
    section.add "Action", valid_602173
  var valid_602174 = query.getOrDefault("Marker")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Marker", valid_602174
  var valid_602175 = query.getOrDefault("SubscriptionName")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "SubscriptionName", valid_602175
  var valid_602176 = query.getOrDefault("Version")
  valid_602176 = validateParameter(valid_602176, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602176 != nil:
    section.add "Version", valid_602176
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602177 = header.getOrDefault("X-Amz-Date")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-Date", valid_602177
  var valid_602178 = header.getOrDefault("X-Amz-Security-Token")
  valid_602178 = validateParameter(valid_602178, JString, required = false,
                                 default = nil)
  if valid_602178 != nil:
    section.add "X-Amz-Security-Token", valid_602178
  var valid_602179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602179 = validateParameter(valid_602179, JString, required = false,
                                 default = nil)
  if valid_602179 != nil:
    section.add "X-Amz-Content-Sha256", valid_602179
  var valid_602180 = header.getOrDefault("X-Amz-Algorithm")
  valid_602180 = validateParameter(valid_602180, JString, required = false,
                                 default = nil)
  if valid_602180 != nil:
    section.add "X-Amz-Algorithm", valid_602180
  var valid_602181 = header.getOrDefault("X-Amz-Signature")
  valid_602181 = validateParameter(valid_602181, JString, required = false,
                                 default = nil)
  if valid_602181 != nil:
    section.add "X-Amz-Signature", valid_602181
  var valid_602182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602182 = validateParameter(valid_602182, JString, required = false,
                                 default = nil)
  if valid_602182 != nil:
    section.add "X-Amz-SignedHeaders", valid_602182
  var valid_602183 = header.getOrDefault("X-Amz-Credential")
  valid_602183 = validateParameter(valid_602183, JString, required = false,
                                 default = nil)
  if valid_602183 != nil:
    section.add "X-Amz-Credential", valid_602183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602184: Call_GetDescribeEventSubscriptions_602168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602184.validator(path, query, header, formData, body)
  let scheme = call_602184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602184.url(scheme.get, call_602184.host, call_602184.base,
                         call_602184.route, valid.getOrDefault("path"))
  result = hook(call_602184, url, valid)

proc call*(call_602185: Call_GetDescribeEventSubscriptions_602168;
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
  var query_602186 = newJObject()
  add(query_602186, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602186.add "Filters", Filters
  add(query_602186, "Action", newJString(Action))
  add(query_602186, "Marker", newJString(Marker))
  add(query_602186, "SubscriptionName", newJString(SubscriptionName))
  add(query_602186, "Version", newJString(Version))
  result = call_602185.call(nil, query_602186, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_602168(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_602169, base: "/",
    url: url_GetDescribeEventSubscriptions_602170,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602231 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEvents_602233(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_602232(path: JsonNode; query: JsonNode;
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
  var valid_602234 = query.getOrDefault("Action")
  valid_602234 = validateParameter(valid_602234, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602234 != nil:
    section.add "Action", valid_602234
  var valid_602235 = query.getOrDefault("Version")
  valid_602235 = validateParameter(valid_602235, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602235 != nil:
    section.add "Version", valid_602235
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602236 = header.getOrDefault("X-Amz-Date")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-Date", valid_602236
  var valid_602237 = header.getOrDefault("X-Amz-Security-Token")
  valid_602237 = validateParameter(valid_602237, JString, required = false,
                                 default = nil)
  if valid_602237 != nil:
    section.add "X-Amz-Security-Token", valid_602237
  var valid_602238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602238 = validateParameter(valid_602238, JString, required = false,
                                 default = nil)
  if valid_602238 != nil:
    section.add "X-Amz-Content-Sha256", valid_602238
  var valid_602239 = header.getOrDefault("X-Amz-Algorithm")
  valid_602239 = validateParameter(valid_602239, JString, required = false,
                                 default = nil)
  if valid_602239 != nil:
    section.add "X-Amz-Algorithm", valid_602239
  var valid_602240 = header.getOrDefault("X-Amz-Signature")
  valid_602240 = validateParameter(valid_602240, JString, required = false,
                                 default = nil)
  if valid_602240 != nil:
    section.add "X-Amz-Signature", valid_602240
  var valid_602241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-SignedHeaders", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Credential")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Credential", valid_602242
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
  var valid_602243 = formData.getOrDefault("SourceIdentifier")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "SourceIdentifier", valid_602243
  var valid_602244 = formData.getOrDefault("EventCategories")
  valid_602244 = validateParameter(valid_602244, JArray, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "EventCategories", valid_602244
  var valid_602245 = formData.getOrDefault("Marker")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "Marker", valid_602245
  var valid_602246 = formData.getOrDefault("StartTime")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "StartTime", valid_602246
  var valid_602247 = formData.getOrDefault("Duration")
  valid_602247 = validateParameter(valid_602247, JInt, required = false, default = nil)
  if valid_602247 != nil:
    section.add "Duration", valid_602247
  var valid_602248 = formData.getOrDefault("Filters")
  valid_602248 = validateParameter(valid_602248, JArray, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "Filters", valid_602248
  var valid_602249 = formData.getOrDefault("EndTime")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "EndTime", valid_602249
  var valid_602250 = formData.getOrDefault("MaxRecords")
  valid_602250 = validateParameter(valid_602250, JInt, required = false, default = nil)
  if valid_602250 != nil:
    section.add "MaxRecords", valid_602250
  var valid_602251 = formData.getOrDefault("SourceType")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602251 != nil:
    section.add "SourceType", valid_602251
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602252: Call_PostDescribeEvents_602231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602252.validator(path, query, header, formData, body)
  let scheme = call_602252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602252.url(scheme.get, call_602252.host, call_602252.base,
                         call_602252.route, valid.getOrDefault("path"))
  result = hook(call_602252, url, valid)

proc call*(call_602253: Call_PostDescribeEvents_602231;
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
  var query_602254 = newJObject()
  var formData_602255 = newJObject()
  add(formData_602255, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602255.add "EventCategories", EventCategories
  add(formData_602255, "Marker", newJString(Marker))
  add(formData_602255, "StartTime", newJString(StartTime))
  add(query_602254, "Action", newJString(Action))
  add(formData_602255, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_602255.add "Filters", Filters
  add(formData_602255, "EndTime", newJString(EndTime))
  add(formData_602255, "MaxRecords", newJInt(MaxRecords))
  add(query_602254, "Version", newJString(Version))
  add(formData_602255, "SourceType", newJString(SourceType))
  result = call_602253.call(nil, query_602254, nil, formData_602255, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602231(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602232, base: "/",
    url: url_PostDescribeEvents_602233, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602207 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEvents_602209(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_602208(path: JsonNode; query: JsonNode;
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
  var valid_602210 = query.getOrDefault("SourceType")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602210 != nil:
    section.add "SourceType", valid_602210
  var valid_602211 = query.getOrDefault("MaxRecords")
  valid_602211 = validateParameter(valid_602211, JInt, required = false, default = nil)
  if valid_602211 != nil:
    section.add "MaxRecords", valid_602211
  var valid_602212 = query.getOrDefault("StartTime")
  valid_602212 = validateParameter(valid_602212, JString, required = false,
                                 default = nil)
  if valid_602212 != nil:
    section.add "StartTime", valid_602212
  var valid_602213 = query.getOrDefault("Filters")
  valid_602213 = validateParameter(valid_602213, JArray, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "Filters", valid_602213
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602214 = query.getOrDefault("Action")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602214 != nil:
    section.add "Action", valid_602214
  var valid_602215 = query.getOrDefault("SourceIdentifier")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "SourceIdentifier", valid_602215
  var valid_602216 = query.getOrDefault("Marker")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "Marker", valid_602216
  var valid_602217 = query.getOrDefault("EventCategories")
  valid_602217 = validateParameter(valid_602217, JArray, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "EventCategories", valid_602217
  var valid_602218 = query.getOrDefault("Duration")
  valid_602218 = validateParameter(valid_602218, JInt, required = false, default = nil)
  if valid_602218 != nil:
    section.add "Duration", valid_602218
  var valid_602219 = query.getOrDefault("EndTime")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "EndTime", valid_602219
  var valid_602220 = query.getOrDefault("Version")
  valid_602220 = validateParameter(valid_602220, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602220 != nil:
    section.add "Version", valid_602220
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602221 = header.getOrDefault("X-Amz-Date")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-Date", valid_602221
  var valid_602222 = header.getOrDefault("X-Amz-Security-Token")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "X-Amz-Security-Token", valid_602222
  var valid_602223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602223 = validateParameter(valid_602223, JString, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "X-Amz-Content-Sha256", valid_602223
  var valid_602224 = header.getOrDefault("X-Amz-Algorithm")
  valid_602224 = validateParameter(valid_602224, JString, required = false,
                                 default = nil)
  if valid_602224 != nil:
    section.add "X-Amz-Algorithm", valid_602224
  var valid_602225 = header.getOrDefault("X-Amz-Signature")
  valid_602225 = validateParameter(valid_602225, JString, required = false,
                                 default = nil)
  if valid_602225 != nil:
    section.add "X-Amz-Signature", valid_602225
  var valid_602226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-SignedHeaders", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Credential")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Credential", valid_602227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602228: Call_GetDescribeEvents_602207; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602228.validator(path, query, header, formData, body)
  let scheme = call_602228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602228.url(scheme.get, call_602228.host, call_602228.base,
                         call_602228.route, valid.getOrDefault("path"))
  result = hook(call_602228, url, valid)

proc call*(call_602229: Call_GetDescribeEvents_602207;
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
  var query_602230 = newJObject()
  add(query_602230, "SourceType", newJString(SourceType))
  add(query_602230, "MaxRecords", newJInt(MaxRecords))
  add(query_602230, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_602230.add "Filters", Filters
  add(query_602230, "Action", newJString(Action))
  add(query_602230, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602230, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_602230.add "EventCategories", EventCategories
  add(query_602230, "Duration", newJInt(Duration))
  add(query_602230, "EndTime", newJString(EndTime))
  add(query_602230, "Version", newJString(Version))
  result = call_602229.call(nil, query_602230, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602207(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602208,
    base: "/", url: url_GetDescribeEvents_602209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_602276 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroupOptions_602278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_602277(path: JsonNode;
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
  var valid_602279 = query.getOrDefault("Action")
  valid_602279 = validateParameter(valid_602279, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602279 != nil:
    section.add "Action", valid_602279
  var valid_602280 = query.getOrDefault("Version")
  valid_602280 = validateParameter(valid_602280, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602280 != nil:
    section.add "Version", valid_602280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602281 = header.getOrDefault("X-Amz-Date")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Date", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Security-Token")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Security-Token", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-Content-Sha256", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Algorithm")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Algorithm", valid_602284
  var valid_602285 = header.getOrDefault("X-Amz-Signature")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "X-Amz-Signature", valid_602285
  var valid_602286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "X-Amz-SignedHeaders", valid_602286
  var valid_602287 = header.getOrDefault("X-Amz-Credential")
  valid_602287 = validateParameter(valid_602287, JString, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "X-Amz-Credential", valid_602287
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602288 = formData.getOrDefault("MajorEngineVersion")
  valid_602288 = validateParameter(valid_602288, JString, required = false,
                                 default = nil)
  if valid_602288 != nil:
    section.add "MajorEngineVersion", valid_602288
  var valid_602289 = formData.getOrDefault("Marker")
  valid_602289 = validateParameter(valid_602289, JString, required = false,
                                 default = nil)
  if valid_602289 != nil:
    section.add "Marker", valid_602289
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_602290 = formData.getOrDefault("EngineName")
  valid_602290 = validateParameter(valid_602290, JString, required = true,
                                 default = nil)
  if valid_602290 != nil:
    section.add "EngineName", valid_602290
  var valid_602291 = formData.getOrDefault("Filters")
  valid_602291 = validateParameter(valid_602291, JArray, required = false,
                                 default = nil)
  if valid_602291 != nil:
    section.add "Filters", valid_602291
  var valid_602292 = formData.getOrDefault("MaxRecords")
  valid_602292 = validateParameter(valid_602292, JInt, required = false, default = nil)
  if valid_602292 != nil:
    section.add "MaxRecords", valid_602292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602293: Call_PostDescribeOptionGroupOptions_602276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602293.validator(path, query, header, formData, body)
  let scheme = call_602293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602293.url(scheme.get, call_602293.host, call_602293.base,
                         call_602293.route, valid.getOrDefault("path"))
  result = hook(call_602293, url, valid)

proc call*(call_602294: Call_PostDescribeOptionGroupOptions_602276;
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
  var query_602295 = newJObject()
  var formData_602296 = newJObject()
  add(formData_602296, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602296, "Marker", newJString(Marker))
  add(query_602295, "Action", newJString(Action))
  add(formData_602296, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602296.add "Filters", Filters
  add(formData_602296, "MaxRecords", newJInt(MaxRecords))
  add(query_602295, "Version", newJString(Version))
  result = call_602294.call(nil, query_602295, nil, formData_602296, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_602276(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_602277, base: "/",
    url: url_PostDescribeOptionGroupOptions_602278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_602256 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroupOptions_602258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_602257(path: JsonNode; query: JsonNode;
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
  var valid_602259 = query.getOrDefault("MaxRecords")
  valid_602259 = validateParameter(valid_602259, JInt, required = false, default = nil)
  if valid_602259 != nil:
    section.add "MaxRecords", valid_602259
  var valid_602260 = query.getOrDefault("Filters")
  valid_602260 = validateParameter(valid_602260, JArray, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "Filters", valid_602260
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602261 = query.getOrDefault("Action")
  valid_602261 = validateParameter(valid_602261, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602261 != nil:
    section.add "Action", valid_602261
  var valid_602262 = query.getOrDefault("Marker")
  valid_602262 = validateParameter(valid_602262, JString, required = false,
                                 default = nil)
  if valid_602262 != nil:
    section.add "Marker", valid_602262
  var valid_602263 = query.getOrDefault("Version")
  valid_602263 = validateParameter(valid_602263, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602263 != nil:
    section.add "Version", valid_602263
  var valid_602264 = query.getOrDefault("EngineName")
  valid_602264 = validateParameter(valid_602264, JString, required = true,
                                 default = nil)
  if valid_602264 != nil:
    section.add "EngineName", valid_602264
  var valid_602265 = query.getOrDefault("MajorEngineVersion")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "MajorEngineVersion", valid_602265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602266 = header.getOrDefault("X-Amz-Date")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Date", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Security-Token")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Security-Token", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-Content-Sha256", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Algorithm")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Algorithm", valid_602269
  var valid_602270 = header.getOrDefault("X-Amz-Signature")
  valid_602270 = validateParameter(valid_602270, JString, required = false,
                                 default = nil)
  if valid_602270 != nil:
    section.add "X-Amz-Signature", valid_602270
  var valid_602271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602271 = validateParameter(valid_602271, JString, required = false,
                                 default = nil)
  if valid_602271 != nil:
    section.add "X-Amz-SignedHeaders", valid_602271
  var valid_602272 = header.getOrDefault("X-Amz-Credential")
  valid_602272 = validateParameter(valid_602272, JString, required = false,
                                 default = nil)
  if valid_602272 != nil:
    section.add "X-Amz-Credential", valid_602272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602273: Call_GetDescribeOptionGroupOptions_602256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602273.validator(path, query, header, formData, body)
  let scheme = call_602273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602273.url(scheme.get, call_602273.host, call_602273.base,
                         call_602273.route, valid.getOrDefault("path"))
  result = hook(call_602273, url, valid)

proc call*(call_602274: Call_GetDescribeOptionGroupOptions_602256;
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
  var query_602275 = newJObject()
  add(query_602275, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602275.add "Filters", Filters
  add(query_602275, "Action", newJString(Action))
  add(query_602275, "Marker", newJString(Marker))
  add(query_602275, "Version", newJString(Version))
  add(query_602275, "EngineName", newJString(EngineName))
  add(query_602275, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602274.call(nil, query_602275, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_602256(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_602257, base: "/",
    url: url_GetDescribeOptionGroupOptions_602258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_602318 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroups_602320(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_602319(path: JsonNode; query: JsonNode;
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
  var valid_602321 = query.getOrDefault("Action")
  valid_602321 = validateParameter(valid_602321, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602321 != nil:
    section.add "Action", valid_602321
  var valid_602322 = query.getOrDefault("Version")
  valid_602322 = validateParameter(valid_602322, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602330 = formData.getOrDefault("MajorEngineVersion")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "MajorEngineVersion", valid_602330
  var valid_602331 = formData.getOrDefault("OptionGroupName")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "OptionGroupName", valid_602331
  var valid_602332 = formData.getOrDefault("Marker")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "Marker", valid_602332
  var valid_602333 = formData.getOrDefault("EngineName")
  valid_602333 = validateParameter(valid_602333, JString, required = false,
                                 default = nil)
  if valid_602333 != nil:
    section.add "EngineName", valid_602333
  var valid_602334 = formData.getOrDefault("Filters")
  valid_602334 = validateParameter(valid_602334, JArray, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "Filters", valid_602334
  var valid_602335 = formData.getOrDefault("MaxRecords")
  valid_602335 = validateParameter(valid_602335, JInt, required = false, default = nil)
  if valid_602335 != nil:
    section.add "MaxRecords", valid_602335
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602336: Call_PostDescribeOptionGroups_602318; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602336.validator(path, query, header, formData, body)
  let scheme = call_602336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602336.url(scheme.get, call_602336.host, call_602336.base,
                         call_602336.route, valid.getOrDefault("path"))
  result = hook(call_602336, url, valid)

proc call*(call_602337: Call_PostDescribeOptionGroups_602318;
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
  var query_602338 = newJObject()
  var formData_602339 = newJObject()
  add(formData_602339, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602339, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602339, "Marker", newJString(Marker))
  add(query_602338, "Action", newJString(Action))
  add(formData_602339, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602339.add "Filters", Filters
  add(formData_602339, "MaxRecords", newJInt(MaxRecords))
  add(query_602338, "Version", newJString(Version))
  result = call_602337.call(nil, query_602338, nil, formData_602339, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_602318(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_602319, base: "/",
    url: url_PostDescribeOptionGroups_602320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_602297 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroups_602299(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_602298(path: JsonNode; query: JsonNode;
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
  var valid_602300 = query.getOrDefault("MaxRecords")
  valid_602300 = validateParameter(valid_602300, JInt, required = false, default = nil)
  if valid_602300 != nil:
    section.add "MaxRecords", valid_602300
  var valid_602301 = query.getOrDefault("OptionGroupName")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "OptionGroupName", valid_602301
  var valid_602302 = query.getOrDefault("Filters")
  valid_602302 = validateParameter(valid_602302, JArray, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "Filters", valid_602302
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602303 = query.getOrDefault("Action")
  valid_602303 = validateParameter(valid_602303, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602303 != nil:
    section.add "Action", valid_602303
  var valid_602304 = query.getOrDefault("Marker")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "Marker", valid_602304
  var valid_602305 = query.getOrDefault("Version")
  valid_602305 = validateParameter(valid_602305, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602305 != nil:
    section.add "Version", valid_602305
  var valid_602306 = query.getOrDefault("EngineName")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "EngineName", valid_602306
  var valid_602307 = query.getOrDefault("MajorEngineVersion")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "MajorEngineVersion", valid_602307
  result.add "query", section
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

proc call*(call_602315: Call_GetDescribeOptionGroups_602297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602315.validator(path, query, header, formData, body)
  let scheme = call_602315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602315.url(scheme.get, call_602315.host, call_602315.base,
                         call_602315.route, valid.getOrDefault("path"))
  result = hook(call_602315, url, valid)

proc call*(call_602316: Call_GetDescribeOptionGroups_602297; MaxRecords: int = 0;
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
  var query_602317 = newJObject()
  add(query_602317, "MaxRecords", newJInt(MaxRecords))
  add(query_602317, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_602317.add "Filters", Filters
  add(query_602317, "Action", newJString(Action))
  add(query_602317, "Marker", newJString(Marker))
  add(query_602317, "Version", newJString(Version))
  add(query_602317, "EngineName", newJString(EngineName))
  add(query_602317, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602316.call(nil, query_602317, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_602297(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_602298, base: "/",
    url: url_GetDescribeOptionGroups_602299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602363 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOrderableDBInstanceOptions_602365(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602364(path: JsonNode;
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
  var valid_602366 = query.getOrDefault("Action")
  valid_602366 = validateParameter(valid_602366, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602366 != nil:
    section.add "Action", valid_602366
  var valid_602367 = query.getOrDefault("Version")
  valid_602367 = validateParameter(valid_602367, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602367 != nil:
    section.add "Version", valid_602367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602368 = header.getOrDefault("X-Amz-Date")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Date", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Security-Token")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Security-Token", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Content-Sha256", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Algorithm")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Algorithm", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Signature")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Signature", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-SignedHeaders", valid_602373
  var valid_602374 = header.getOrDefault("X-Amz-Credential")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "X-Amz-Credential", valid_602374
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
  var valid_602375 = formData.getOrDefault("Engine")
  valid_602375 = validateParameter(valid_602375, JString, required = true,
                                 default = nil)
  if valid_602375 != nil:
    section.add "Engine", valid_602375
  var valid_602376 = formData.getOrDefault("Marker")
  valid_602376 = validateParameter(valid_602376, JString, required = false,
                                 default = nil)
  if valid_602376 != nil:
    section.add "Marker", valid_602376
  var valid_602377 = formData.getOrDefault("Vpc")
  valid_602377 = validateParameter(valid_602377, JBool, required = false, default = nil)
  if valid_602377 != nil:
    section.add "Vpc", valid_602377
  var valid_602378 = formData.getOrDefault("DBInstanceClass")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "DBInstanceClass", valid_602378
  var valid_602379 = formData.getOrDefault("Filters")
  valid_602379 = validateParameter(valid_602379, JArray, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "Filters", valid_602379
  var valid_602380 = formData.getOrDefault("LicenseModel")
  valid_602380 = validateParameter(valid_602380, JString, required = false,
                                 default = nil)
  if valid_602380 != nil:
    section.add "LicenseModel", valid_602380
  var valid_602381 = formData.getOrDefault("MaxRecords")
  valid_602381 = validateParameter(valid_602381, JInt, required = false, default = nil)
  if valid_602381 != nil:
    section.add "MaxRecords", valid_602381
  var valid_602382 = formData.getOrDefault("EngineVersion")
  valid_602382 = validateParameter(valid_602382, JString, required = false,
                                 default = nil)
  if valid_602382 != nil:
    section.add "EngineVersion", valid_602382
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602383: Call_PostDescribeOrderableDBInstanceOptions_602363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602383.validator(path, query, header, formData, body)
  let scheme = call_602383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602383.url(scheme.get, call_602383.host, call_602383.base,
                         call_602383.route, valid.getOrDefault("path"))
  result = hook(call_602383, url, valid)

proc call*(call_602384: Call_PostDescribeOrderableDBInstanceOptions_602363;
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
  var query_602385 = newJObject()
  var formData_602386 = newJObject()
  add(formData_602386, "Engine", newJString(Engine))
  add(formData_602386, "Marker", newJString(Marker))
  add(query_602385, "Action", newJString(Action))
  add(formData_602386, "Vpc", newJBool(Vpc))
  add(formData_602386, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602386.add "Filters", Filters
  add(formData_602386, "LicenseModel", newJString(LicenseModel))
  add(formData_602386, "MaxRecords", newJInt(MaxRecords))
  add(formData_602386, "EngineVersion", newJString(EngineVersion))
  add(query_602385, "Version", newJString(Version))
  result = call_602384.call(nil, query_602385, nil, formData_602386, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602363(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602364, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602340 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOrderableDBInstanceOptions_602342(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602341(path: JsonNode;
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
  var valid_602343 = query.getOrDefault("Engine")
  valid_602343 = validateParameter(valid_602343, JString, required = true,
                                 default = nil)
  if valid_602343 != nil:
    section.add "Engine", valid_602343
  var valid_602344 = query.getOrDefault("MaxRecords")
  valid_602344 = validateParameter(valid_602344, JInt, required = false, default = nil)
  if valid_602344 != nil:
    section.add "MaxRecords", valid_602344
  var valid_602345 = query.getOrDefault("Filters")
  valid_602345 = validateParameter(valid_602345, JArray, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "Filters", valid_602345
  var valid_602346 = query.getOrDefault("LicenseModel")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "LicenseModel", valid_602346
  var valid_602347 = query.getOrDefault("Vpc")
  valid_602347 = validateParameter(valid_602347, JBool, required = false, default = nil)
  if valid_602347 != nil:
    section.add "Vpc", valid_602347
  var valid_602348 = query.getOrDefault("DBInstanceClass")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "DBInstanceClass", valid_602348
  var valid_602349 = query.getOrDefault("Action")
  valid_602349 = validateParameter(valid_602349, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602349 != nil:
    section.add "Action", valid_602349
  var valid_602350 = query.getOrDefault("Marker")
  valid_602350 = validateParameter(valid_602350, JString, required = false,
                                 default = nil)
  if valid_602350 != nil:
    section.add "Marker", valid_602350
  var valid_602351 = query.getOrDefault("EngineVersion")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "EngineVersion", valid_602351
  var valid_602352 = query.getOrDefault("Version")
  valid_602352 = validateParameter(valid_602352, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602352 != nil:
    section.add "Version", valid_602352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602353 = header.getOrDefault("X-Amz-Date")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Date", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Security-Token")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Security-Token", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Content-Sha256", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Algorithm")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Algorithm", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Signature")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Signature", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-SignedHeaders", valid_602358
  var valid_602359 = header.getOrDefault("X-Amz-Credential")
  valid_602359 = validateParameter(valid_602359, JString, required = false,
                                 default = nil)
  if valid_602359 != nil:
    section.add "X-Amz-Credential", valid_602359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602360: Call_GetDescribeOrderableDBInstanceOptions_602340;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602360.validator(path, query, header, formData, body)
  let scheme = call_602360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602360.url(scheme.get, call_602360.host, call_602360.base,
                         call_602360.route, valid.getOrDefault("path"))
  result = hook(call_602360, url, valid)

proc call*(call_602361: Call_GetDescribeOrderableDBInstanceOptions_602340;
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
  var query_602362 = newJObject()
  add(query_602362, "Engine", newJString(Engine))
  add(query_602362, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602362.add "Filters", Filters
  add(query_602362, "LicenseModel", newJString(LicenseModel))
  add(query_602362, "Vpc", newJBool(Vpc))
  add(query_602362, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602362, "Action", newJString(Action))
  add(query_602362, "Marker", newJString(Marker))
  add(query_602362, "EngineVersion", newJString(EngineVersion))
  add(query_602362, "Version", newJString(Version))
  result = call_602361.call(nil, query_602362, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602340(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602341, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602342,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_602412 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstances_602414(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_602413(path: JsonNode;
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
  var valid_602415 = query.getOrDefault("Action")
  valid_602415 = validateParameter(valid_602415, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602415 != nil:
    section.add "Action", valid_602415
  var valid_602416 = query.getOrDefault("Version")
  valid_602416 = validateParameter(valid_602416, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602416 != nil:
    section.add "Version", valid_602416
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602417 = header.getOrDefault("X-Amz-Date")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Date", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Security-Token")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Security-Token", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-Content-Sha256", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Algorithm")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Algorithm", valid_602420
  var valid_602421 = header.getOrDefault("X-Amz-Signature")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "X-Amz-Signature", valid_602421
  var valid_602422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "X-Amz-SignedHeaders", valid_602422
  var valid_602423 = header.getOrDefault("X-Amz-Credential")
  valid_602423 = validateParameter(valid_602423, JString, required = false,
                                 default = nil)
  if valid_602423 != nil:
    section.add "X-Amz-Credential", valid_602423
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
  var valid_602424 = formData.getOrDefault("OfferingType")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "OfferingType", valid_602424
  var valid_602425 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "ReservedDBInstanceId", valid_602425
  var valid_602426 = formData.getOrDefault("Marker")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "Marker", valid_602426
  var valid_602427 = formData.getOrDefault("MultiAZ")
  valid_602427 = validateParameter(valid_602427, JBool, required = false, default = nil)
  if valid_602427 != nil:
    section.add "MultiAZ", valid_602427
  var valid_602428 = formData.getOrDefault("Duration")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "Duration", valid_602428
  var valid_602429 = formData.getOrDefault("DBInstanceClass")
  valid_602429 = validateParameter(valid_602429, JString, required = false,
                                 default = nil)
  if valid_602429 != nil:
    section.add "DBInstanceClass", valid_602429
  var valid_602430 = formData.getOrDefault("Filters")
  valid_602430 = validateParameter(valid_602430, JArray, required = false,
                                 default = nil)
  if valid_602430 != nil:
    section.add "Filters", valid_602430
  var valid_602431 = formData.getOrDefault("ProductDescription")
  valid_602431 = validateParameter(valid_602431, JString, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "ProductDescription", valid_602431
  var valid_602432 = formData.getOrDefault("MaxRecords")
  valid_602432 = validateParameter(valid_602432, JInt, required = false, default = nil)
  if valid_602432 != nil:
    section.add "MaxRecords", valid_602432
  var valid_602433 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602433 = validateParameter(valid_602433, JString, required = false,
                                 default = nil)
  if valid_602433 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602433
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602434: Call_PostDescribeReservedDBInstances_602412;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602434.validator(path, query, header, formData, body)
  let scheme = call_602434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602434.url(scheme.get, call_602434.host, call_602434.base,
                         call_602434.route, valid.getOrDefault("path"))
  result = hook(call_602434, url, valid)

proc call*(call_602435: Call_PostDescribeReservedDBInstances_602412;
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
  var query_602436 = newJObject()
  var formData_602437 = newJObject()
  add(formData_602437, "OfferingType", newJString(OfferingType))
  add(formData_602437, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602437, "Marker", newJString(Marker))
  add(formData_602437, "MultiAZ", newJBool(MultiAZ))
  add(query_602436, "Action", newJString(Action))
  add(formData_602437, "Duration", newJString(Duration))
  add(formData_602437, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602437.add "Filters", Filters
  add(formData_602437, "ProductDescription", newJString(ProductDescription))
  add(formData_602437, "MaxRecords", newJInt(MaxRecords))
  add(formData_602437, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602436, "Version", newJString(Version))
  result = call_602435.call(nil, query_602436, nil, formData_602437, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_602412(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_602413, base: "/",
    url: url_PostDescribeReservedDBInstances_602414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_602387 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstances_602389(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_602388(path: JsonNode;
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
  var valid_602390 = query.getOrDefault("ProductDescription")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "ProductDescription", valid_602390
  var valid_602391 = query.getOrDefault("MaxRecords")
  valid_602391 = validateParameter(valid_602391, JInt, required = false, default = nil)
  if valid_602391 != nil:
    section.add "MaxRecords", valid_602391
  var valid_602392 = query.getOrDefault("OfferingType")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "OfferingType", valid_602392
  var valid_602393 = query.getOrDefault("Filters")
  valid_602393 = validateParameter(valid_602393, JArray, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "Filters", valid_602393
  var valid_602394 = query.getOrDefault("MultiAZ")
  valid_602394 = validateParameter(valid_602394, JBool, required = false, default = nil)
  if valid_602394 != nil:
    section.add "MultiAZ", valid_602394
  var valid_602395 = query.getOrDefault("ReservedDBInstanceId")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "ReservedDBInstanceId", valid_602395
  var valid_602396 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602396
  var valid_602397 = query.getOrDefault("DBInstanceClass")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "DBInstanceClass", valid_602397
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602398 = query.getOrDefault("Action")
  valid_602398 = validateParameter(valid_602398, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602398 != nil:
    section.add "Action", valid_602398
  var valid_602399 = query.getOrDefault("Marker")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "Marker", valid_602399
  var valid_602400 = query.getOrDefault("Duration")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "Duration", valid_602400
  var valid_602401 = query.getOrDefault("Version")
  valid_602401 = validateParameter(valid_602401, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602401 != nil:
    section.add "Version", valid_602401
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602402 = header.getOrDefault("X-Amz-Date")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Date", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Security-Token")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Security-Token", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-Content-Sha256", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Algorithm")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Algorithm", valid_602405
  var valid_602406 = header.getOrDefault("X-Amz-Signature")
  valid_602406 = validateParameter(valid_602406, JString, required = false,
                                 default = nil)
  if valid_602406 != nil:
    section.add "X-Amz-Signature", valid_602406
  var valid_602407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602407 = validateParameter(valid_602407, JString, required = false,
                                 default = nil)
  if valid_602407 != nil:
    section.add "X-Amz-SignedHeaders", valid_602407
  var valid_602408 = header.getOrDefault("X-Amz-Credential")
  valid_602408 = validateParameter(valid_602408, JString, required = false,
                                 default = nil)
  if valid_602408 != nil:
    section.add "X-Amz-Credential", valid_602408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602409: Call_GetDescribeReservedDBInstances_602387; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602409.validator(path, query, header, formData, body)
  let scheme = call_602409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602409.url(scheme.get, call_602409.host, call_602409.base,
                         call_602409.route, valid.getOrDefault("path"))
  result = hook(call_602409, url, valid)

proc call*(call_602410: Call_GetDescribeReservedDBInstances_602387;
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
  var query_602411 = newJObject()
  add(query_602411, "ProductDescription", newJString(ProductDescription))
  add(query_602411, "MaxRecords", newJInt(MaxRecords))
  add(query_602411, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602411.add "Filters", Filters
  add(query_602411, "MultiAZ", newJBool(MultiAZ))
  add(query_602411, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602411, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602411, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602411, "Action", newJString(Action))
  add(query_602411, "Marker", newJString(Marker))
  add(query_602411, "Duration", newJString(Duration))
  add(query_602411, "Version", newJString(Version))
  result = call_602410.call(nil, query_602411, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_602387(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_602388, base: "/",
    url: url_GetDescribeReservedDBInstances_602389,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_602462 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstancesOfferings_602464(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_602463(path: JsonNode;
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
  var valid_602465 = query.getOrDefault("Action")
  valid_602465 = validateParameter(valid_602465, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602465 != nil:
    section.add "Action", valid_602465
  var valid_602466 = query.getOrDefault("Version")
  valid_602466 = validateParameter(valid_602466, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602466 != nil:
    section.add "Version", valid_602466
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602467 = header.getOrDefault("X-Amz-Date")
  valid_602467 = validateParameter(valid_602467, JString, required = false,
                                 default = nil)
  if valid_602467 != nil:
    section.add "X-Amz-Date", valid_602467
  var valid_602468 = header.getOrDefault("X-Amz-Security-Token")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "X-Amz-Security-Token", valid_602468
  var valid_602469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602469 = validateParameter(valid_602469, JString, required = false,
                                 default = nil)
  if valid_602469 != nil:
    section.add "X-Amz-Content-Sha256", valid_602469
  var valid_602470 = header.getOrDefault("X-Amz-Algorithm")
  valid_602470 = validateParameter(valid_602470, JString, required = false,
                                 default = nil)
  if valid_602470 != nil:
    section.add "X-Amz-Algorithm", valid_602470
  var valid_602471 = header.getOrDefault("X-Amz-Signature")
  valid_602471 = validateParameter(valid_602471, JString, required = false,
                                 default = nil)
  if valid_602471 != nil:
    section.add "X-Amz-Signature", valid_602471
  var valid_602472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602472 = validateParameter(valid_602472, JString, required = false,
                                 default = nil)
  if valid_602472 != nil:
    section.add "X-Amz-SignedHeaders", valid_602472
  var valid_602473 = header.getOrDefault("X-Amz-Credential")
  valid_602473 = validateParameter(valid_602473, JString, required = false,
                                 default = nil)
  if valid_602473 != nil:
    section.add "X-Amz-Credential", valid_602473
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
  var valid_602474 = formData.getOrDefault("OfferingType")
  valid_602474 = validateParameter(valid_602474, JString, required = false,
                                 default = nil)
  if valid_602474 != nil:
    section.add "OfferingType", valid_602474
  var valid_602475 = formData.getOrDefault("Marker")
  valid_602475 = validateParameter(valid_602475, JString, required = false,
                                 default = nil)
  if valid_602475 != nil:
    section.add "Marker", valid_602475
  var valid_602476 = formData.getOrDefault("MultiAZ")
  valid_602476 = validateParameter(valid_602476, JBool, required = false, default = nil)
  if valid_602476 != nil:
    section.add "MultiAZ", valid_602476
  var valid_602477 = formData.getOrDefault("Duration")
  valid_602477 = validateParameter(valid_602477, JString, required = false,
                                 default = nil)
  if valid_602477 != nil:
    section.add "Duration", valid_602477
  var valid_602478 = formData.getOrDefault("DBInstanceClass")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "DBInstanceClass", valid_602478
  var valid_602479 = formData.getOrDefault("Filters")
  valid_602479 = validateParameter(valid_602479, JArray, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "Filters", valid_602479
  var valid_602480 = formData.getOrDefault("ProductDescription")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "ProductDescription", valid_602480
  var valid_602481 = formData.getOrDefault("MaxRecords")
  valid_602481 = validateParameter(valid_602481, JInt, required = false, default = nil)
  if valid_602481 != nil:
    section.add "MaxRecords", valid_602481
  var valid_602482 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602482
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602483: Call_PostDescribeReservedDBInstancesOfferings_602462;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602483.validator(path, query, header, formData, body)
  let scheme = call_602483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602483.url(scheme.get, call_602483.host, call_602483.base,
                         call_602483.route, valid.getOrDefault("path"))
  result = hook(call_602483, url, valid)

proc call*(call_602484: Call_PostDescribeReservedDBInstancesOfferings_602462;
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
  var query_602485 = newJObject()
  var formData_602486 = newJObject()
  add(formData_602486, "OfferingType", newJString(OfferingType))
  add(formData_602486, "Marker", newJString(Marker))
  add(formData_602486, "MultiAZ", newJBool(MultiAZ))
  add(query_602485, "Action", newJString(Action))
  add(formData_602486, "Duration", newJString(Duration))
  add(formData_602486, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602486.add "Filters", Filters
  add(formData_602486, "ProductDescription", newJString(ProductDescription))
  add(formData_602486, "MaxRecords", newJInt(MaxRecords))
  add(formData_602486, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602485, "Version", newJString(Version))
  result = call_602484.call(nil, query_602485, nil, formData_602486, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_602462(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_602463,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_602464,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_602438 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstancesOfferings_602440(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_602439(path: JsonNode;
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
  var valid_602441 = query.getOrDefault("ProductDescription")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "ProductDescription", valid_602441
  var valid_602442 = query.getOrDefault("MaxRecords")
  valid_602442 = validateParameter(valid_602442, JInt, required = false, default = nil)
  if valid_602442 != nil:
    section.add "MaxRecords", valid_602442
  var valid_602443 = query.getOrDefault("OfferingType")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "OfferingType", valid_602443
  var valid_602444 = query.getOrDefault("Filters")
  valid_602444 = validateParameter(valid_602444, JArray, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "Filters", valid_602444
  var valid_602445 = query.getOrDefault("MultiAZ")
  valid_602445 = validateParameter(valid_602445, JBool, required = false, default = nil)
  if valid_602445 != nil:
    section.add "MultiAZ", valid_602445
  var valid_602446 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602446
  var valid_602447 = query.getOrDefault("DBInstanceClass")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "DBInstanceClass", valid_602447
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602448 = query.getOrDefault("Action")
  valid_602448 = validateParameter(valid_602448, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602448 != nil:
    section.add "Action", valid_602448
  var valid_602449 = query.getOrDefault("Marker")
  valid_602449 = validateParameter(valid_602449, JString, required = false,
                                 default = nil)
  if valid_602449 != nil:
    section.add "Marker", valid_602449
  var valid_602450 = query.getOrDefault("Duration")
  valid_602450 = validateParameter(valid_602450, JString, required = false,
                                 default = nil)
  if valid_602450 != nil:
    section.add "Duration", valid_602450
  var valid_602451 = query.getOrDefault("Version")
  valid_602451 = validateParameter(valid_602451, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602451 != nil:
    section.add "Version", valid_602451
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602452 = header.getOrDefault("X-Amz-Date")
  valid_602452 = validateParameter(valid_602452, JString, required = false,
                                 default = nil)
  if valid_602452 != nil:
    section.add "X-Amz-Date", valid_602452
  var valid_602453 = header.getOrDefault("X-Amz-Security-Token")
  valid_602453 = validateParameter(valid_602453, JString, required = false,
                                 default = nil)
  if valid_602453 != nil:
    section.add "X-Amz-Security-Token", valid_602453
  var valid_602454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Content-Sha256", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Algorithm")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Algorithm", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Signature")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Signature", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-SignedHeaders", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Credential")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Credential", valid_602458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602459: Call_GetDescribeReservedDBInstancesOfferings_602438;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602459.validator(path, query, header, formData, body)
  let scheme = call_602459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602459.url(scheme.get, call_602459.host, call_602459.base,
                         call_602459.route, valid.getOrDefault("path"))
  result = hook(call_602459, url, valid)

proc call*(call_602460: Call_GetDescribeReservedDBInstancesOfferings_602438;
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
  var query_602461 = newJObject()
  add(query_602461, "ProductDescription", newJString(ProductDescription))
  add(query_602461, "MaxRecords", newJInt(MaxRecords))
  add(query_602461, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602461.add "Filters", Filters
  add(query_602461, "MultiAZ", newJBool(MultiAZ))
  add(query_602461, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602461, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602461, "Action", newJString(Action))
  add(query_602461, "Marker", newJString(Marker))
  add(query_602461, "Duration", newJString(Duration))
  add(query_602461, "Version", newJString(Version))
  result = call_602460.call(nil, query_602461, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_602438(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_602439, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_602440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_602506 = ref object of OpenApiRestCall_600410
proc url_PostDownloadDBLogFilePortion_602508(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_602507(path: JsonNode; query: JsonNode;
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
  var valid_602509 = query.getOrDefault("Action")
  valid_602509 = validateParameter(valid_602509, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602509 != nil:
    section.add "Action", valid_602509
  var valid_602510 = query.getOrDefault("Version")
  valid_602510 = validateParameter(valid_602510, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602510 != nil:
    section.add "Version", valid_602510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602511 = header.getOrDefault("X-Amz-Date")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "X-Amz-Date", valid_602511
  var valid_602512 = header.getOrDefault("X-Amz-Security-Token")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "X-Amz-Security-Token", valid_602512
  var valid_602513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602513 = validateParameter(valid_602513, JString, required = false,
                                 default = nil)
  if valid_602513 != nil:
    section.add "X-Amz-Content-Sha256", valid_602513
  var valid_602514 = header.getOrDefault("X-Amz-Algorithm")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "X-Amz-Algorithm", valid_602514
  var valid_602515 = header.getOrDefault("X-Amz-Signature")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "X-Amz-Signature", valid_602515
  var valid_602516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602516 = validateParameter(valid_602516, JString, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "X-Amz-SignedHeaders", valid_602516
  var valid_602517 = header.getOrDefault("X-Amz-Credential")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "X-Amz-Credential", valid_602517
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_602518 = formData.getOrDefault("NumberOfLines")
  valid_602518 = validateParameter(valid_602518, JInt, required = false, default = nil)
  if valid_602518 != nil:
    section.add "NumberOfLines", valid_602518
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602519 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = nil)
  if valid_602519 != nil:
    section.add "DBInstanceIdentifier", valid_602519
  var valid_602520 = formData.getOrDefault("Marker")
  valid_602520 = validateParameter(valid_602520, JString, required = false,
                                 default = nil)
  if valid_602520 != nil:
    section.add "Marker", valid_602520
  var valid_602521 = formData.getOrDefault("LogFileName")
  valid_602521 = validateParameter(valid_602521, JString, required = true,
                                 default = nil)
  if valid_602521 != nil:
    section.add "LogFileName", valid_602521
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602522: Call_PostDownloadDBLogFilePortion_602506; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602522.validator(path, query, header, formData, body)
  let scheme = call_602522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602522.url(scheme.get, call_602522.host, call_602522.base,
                         call_602522.route, valid.getOrDefault("path"))
  result = hook(call_602522, url, valid)

proc call*(call_602523: Call_PostDownloadDBLogFilePortion_602506;
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
  var query_602524 = newJObject()
  var formData_602525 = newJObject()
  add(formData_602525, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_602525, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602525, "Marker", newJString(Marker))
  add(query_602524, "Action", newJString(Action))
  add(formData_602525, "LogFileName", newJString(LogFileName))
  add(query_602524, "Version", newJString(Version))
  result = call_602523.call(nil, query_602524, nil, formData_602525, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_602506(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_602507, base: "/",
    url: url_PostDownloadDBLogFilePortion_602508,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_602487 = ref object of OpenApiRestCall_600410
proc url_GetDownloadDBLogFilePortion_602489(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_602488(path: JsonNode; query: JsonNode;
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
  var valid_602490 = query.getOrDefault("NumberOfLines")
  valid_602490 = validateParameter(valid_602490, JInt, required = false, default = nil)
  if valid_602490 != nil:
    section.add "NumberOfLines", valid_602490
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_602491 = query.getOrDefault("LogFileName")
  valid_602491 = validateParameter(valid_602491, JString, required = true,
                                 default = nil)
  if valid_602491 != nil:
    section.add "LogFileName", valid_602491
  var valid_602492 = query.getOrDefault("Action")
  valid_602492 = validateParameter(valid_602492, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602492 != nil:
    section.add "Action", valid_602492
  var valid_602493 = query.getOrDefault("Marker")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "Marker", valid_602493
  var valid_602494 = query.getOrDefault("Version")
  valid_602494 = validateParameter(valid_602494, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602494 != nil:
    section.add "Version", valid_602494
  var valid_602495 = query.getOrDefault("DBInstanceIdentifier")
  valid_602495 = validateParameter(valid_602495, JString, required = true,
                                 default = nil)
  if valid_602495 != nil:
    section.add "DBInstanceIdentifier", valid_602495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602496 = header.getOrDefault("X-Amz-Date")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Date", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Security-Token")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Security-Token", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-Content-Sha256", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Algorithm")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Algorithm", valid_602499
  var valid_602500 = header.getOrDefault("X-Amz-Signature")
  valid_602500 = validateParameter(valid_602500, JString, required = false,
                                 default = nil)
  if valid_602500 != nil:
    section.add "X-Amz-Signature", valid_602500
  var valid_602501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602501 = validateParameter(valid_602501, JString, required = false,
                                 default = nil)
  if valid_602501 != nil:
    section.add "X-Amz-SignedHeaders", valid_602501
  var valid_602502 = header.getOrDefault("X-Amz-Credential")
  valid_602502 = validateParameter(valid_602502, JString, required = false,
                                 default = nil)
  if valid_602502 != nil:
    section.add "X-Amz-Credential", valid_602502
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602503: Call_GetDownloadDBLogFilePortion_602487; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602503.validator(path, query, header, formData, body)
  let scheme = call_602503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602503.url(scheme.get, call_602503.host, call_602503.base,
                         call_602503.route, valid.getOrDefault("path"))
  result = hook(call_602503, url, valid)

proc call*(call_602504: Call_GetDownloadDBLogFilePortion_602487;
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
  var query_602505 = newJObject()
  add(query_602505, "NumberOfLines", newJInt(NumberOfLines))
  add(query_602505, "LogFileName", newJString(LogFileName))
  add(query_602505, "Action", newJString(Action))
  add(query_602505, "Marker", newJString(Marker))
  add(query_602505, "Version", newJString(Version))
  add(query_602505, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602504.call(nil, query_602505, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_602487(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_602488, base: "/",
    url: url_GetDownloadDBLogFilePortion_602489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602543 = ref object of OpenApiRestCall_600410
proc url_PostListTagsForResource_602545(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_602544(path: JsonNode; query: JsonNode;
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
                                 default = newJString("ListTagsForResource"))
  if valid_602546 != nil:
    section.add "Action", valid_602546
  var valid_602547 = query.getOrDefault("Version")
  valid_602547 = validateParameter(valid_602547, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_602555 = formData.getOrDefault("Filters")
  valid_602555 = validateParameter(valid_602555, JArray, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "Filters", valid_602555
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602556 = formData.getOrDefault("ResourceName")
  valid_602556 = validateParameter(valid_602556, JString, required = true,
                                 default = nil)
  if valid_602556 != nil:
    section.add "ResourceName", valid_602556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602557: Call_PostListTagsForResource_602543; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602557.validator(path, query, header, formData, body)
  let scheme = call_602557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602557.url(scheme.get, call_602557.host, call_602557.base,
                         call_602557.route, valid.getOrDefault("path"))
  result = hook(call_602557, url, valid)

proc call*(call_602558: Call_PostListTagsForResource_602543; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602559 = newJObject()
  var formData_602560 = newJObject()
  add(query_602559, "Action", newJString(Action))
  if Filters != nil:
    formData_602560.add "Filters", Filters
  add(formData_602560, "ResourceName", newJString(ResourceName))
  add(query_602559, "Version", newJString(Version))
  result = call_602558.call(nil, query_602559, nil, formData_602560, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602543(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602544, base: "/",
    url: url_PostListTagsForResource_602545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602526 = ref object of OpenApiRestCall_600410
proc url_GetListTagsForResource_602528(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_602527(path: JsonNode; query: JsonNode;
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
  var valid_602529 = query.getOrDefault("Filters")
  valid_602529 = validateParameter(valid_602529, JArray, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "Filters", valid_602529
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_602530 = query.getOrDefault("ResourceName")
  valid_602530 = validateParameter(valid_602530, JString, required = true,
                                 default = nil)
  if valid_602530 != nil:
    section.add "ResourceName", valid_602530
  var valid_602531 = query.getOrDefault("Action")
  valid_602531 = validateParameter(valid_602531, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602531 != nil:
    section.add "Action", valid_602531
  var valid_602532 = query.getOrDefault("Version")
  valid_602532 = validateParameter(valid_602532, JString, required = true,
                                 default = newJString("2013-09-09"))
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

proc call*(call_602540: Call_GetListTagsForResource_602526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602540.validator(path, query, header, formData, body)
  let scheme = call_602540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602540.url(scheme.get, call_602540.host, call_602540.base,
                         call_602540.route, valid.getOrDefault("path"))
  result = hook(call_602540, url, valid)

proc call*(call_602541: Call_GetListTagsForResource_602526; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602542 = newJObject()
  if Filters != nil:
    query_602542.add "Filters", Filters
  add(query_602542, "ResourceName", newJString(ResourceName))
  add(query_602542, "Action", newJString(Action))
  add(query_602542, "Version", newJString(Version))
  result = call_602541.call(nil, query_602542, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602526(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602527, base: "/",
    url: url_GetListTagsForResource_602528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602594 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBInstance_602596(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_602595(path: JsonNode; query: JsonNode;
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
  var valid_602597 = query.getOrDefault("Action")
  valid_602597 = validateParameter(valid_602597, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602597 != nil:
    section.add "Action", valid_602597
  var valid_602598 = query.getOrDefault("Version")
  valid_602598 = validateParameter(valid_602598, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602598 != nil:
    section.add "Version", valid_602598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602599 = header.getOrDefault("X-Amz-Date")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Date", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Security-Token")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Security-Token", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Content-Sha256", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-Algorithm")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-Algorithm", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Signature")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Signature", valid_602603
  var valid_602604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602604 = validateParameter(valid_602604, JString, required = false,
                                 default = nil)
  if valid_602604 != nil:
    section.add "X-Amz-SignedHeaders", valid_602604
  var valid_602605 = header.getOrDefault("X-Amz-Credential")
  valid_602605 = validateParameter(valid_602605, JString, required = false,
                                 default = nil)
  if valid_602605 != nil:
    section.add "X-Amz-Credential", valid_602605
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
  var valid_602606 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "PreferredMaintenanceWindow", valid_602606
  var valid_602607 = formData.getOrDefault("DBSecurityGroups")
  valid_602607 = validateParameter(valid_602607, JArray, required = false,
                                 default = nil)
  if valid_602607 != nil:
    section.add "DBSecurityGroups", valid_602607
  var valid_602608 = formData.getOrDefault("ApplyImmediately")
  valid_602608 = validateParameter(valid_602608, JBool, required = false, default = nil)
  if valid_602608 != nil:
    section.add "ApplyImmediately", valid_602608
  var valid_602609 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602609 = validateParameter(valid_602609, JArray, required = false,
                                 default = nil)
  if valid_602609 != nil:
    section.add "VpcSecurityGroupIds", valid_602609
  var valid_602610 = formData.getOrDefault("Iops")
  valid_602610 = validateParameter(valid_602610, JInt, required = false, default = nil)
  if valid_602610 != nil:
    section.add "Iops", valid_602610
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602611 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602611 = validateParameter(valid_602611, JString, required = true,
                                 default = nil)
  if valid_602611 != nil:
    section.add "DBInstanceIdentifier", valid_602611
  var valid_602612 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602612 = validateParameter(valid_602612, JInt, required = false, default = nil)
  if valid_602612 != nil:
    section.add "BackupRetentionPeriod", valid_602612
  var valid_602613 = formData.getOrDefault("DBParameterGroupName")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "DBParameterGroupName", valid_602613
  var valid_602614 = formData.getOrDefault("OptionGroupName")
  valid_602614 = validateParameter(valid_602614, JString, required = false,
                                 default = nil)
  if valid_602614 != nil:
    section.add "OptionGroupName", valid_602614
  var valid_602615 = formData.getOrDefault("MasterUserPassword")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "MasterUserPassword", valid_602615
  var valid_602616 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "NewDBInstanceIdentifier", valid_602616
  var valid_602617 = formData.getOrDefault("MultiAZ")
  valid_602617 = validateParameter(valid_602617, JBool, required = false, default = nil)
  if valid_602617 != nil:
    section.add "MultiAZ", valid_602617
  var valid_602618 = formData.getOrDefault("AllocatedStorage")
  valid_602618 = validateParameter(valid_602618, JInt, required = false, default = nil)
  if valid_602618 != nil:
    section.add "AllocatedStorage", valid_602618
  var valid_602619 = formData.getOrDefault("DBInstanceClass")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "DBInstanceClass", valid_602619
  var valid_602620 = formData.getOrDefault("PreferredBackupWindow")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "PreferredBackupWindow", valid_602620
  var valid_602621 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602621 = validateParameter(valid_602621, JBool, required = false, default = nil)
  if valid_602621 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602621
  var valid_602622 = formData.getOrDefault("EngineVersion")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "EngineVersion", valid_602622
  var valid_602623 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_602623 = validateParameter(valid_602623, JBool, required = false, default = nil)
  if valid_602623 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602623
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602624: Call_PostModifyDBInstance_602594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602624.validator(path, query, header, formData, body)
  let scheme = call_602624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602624.url(scheme.get, call_602624.host, call_602624.base,
                         call_602624.route, valid.getOrDefault("path"))
  result = hook(call_602624, url, valid)

proc call*(call_602625: Call_PostModifyDBInstance_602594;
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
  var query_602626 = newJObject()
  var formData_602627 = newJObject()
  add(formData_602627, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_602627.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602627, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_602627.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602627, "Iops", newJInt(Iops))
  add(formData_602627, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602627, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602627, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602627, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602627, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602627, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_602627, "MultiAZ", newJBool(MultiAZ))
  add(query_602626, "Action", newJString(Action))
  add(formData_602627, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_602627, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602627, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602627, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602627, "EngineVersion", newJString(EngineVersion))
  add(query_602626, "Version", newJString(Version))
  add(formData_602627, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_602625.call(nil, query_602626, nil, formData_602627, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602594(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602595, base: "/",
    url: url_PostModifyDBInstance_602596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602561 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBInstance_602563(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_602562(path: JsonNode; query: JsonNode;
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
  var valid_602564 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "PreferredMaintenanceWindow", valid_602564
  var valid_602565 = query.getOrDefault("AllocatedStorage")
  valid_602565 = validateParameter(valid_602565, JInt, required = false, default = nil)
  if valid_602565 != nil:
    section.add "AllocatedStorage", valid_602565
  var valid_602566 = query.getOrDefault("OptionGroupName")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "OptionGroupName", valid_602566
  var valid_602567 = query.getOrDefault("DBSecurityGroups")
  valid_602567 = validateParameter(valid_602567, JArray, required = false,
                                 default = nil)
  if valid_602567 != nil:
    section.add "DBSecurityGroups", valid_602567
  var valid_602568 = query.getOrDefault("MasterUserPassword")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "MasterUserPassword", valid_602568
  var valid_602569 = query.getOrDefault("Iops")
  valid_602569 = validateParameter(valid_602569, JInt, required = false, default = nil)
  if valid_602569 != nil:
    section.add "Iops", valid_602569
  var valid_602570 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602570 = validateParameter(valid_602570, JArray, required = false,
                                 default = nil)
  if valid_602570 != nil:
    section.add "VpcSecurityGroupIds", valid_602570
  var valid_602571 = query.getOrDefault("MultiAZ")
  valid_602571 = validateParameter(valid_602571, JBool, required = false, default = nil)
  if valid_602571 != nil:
    section.add "MultiAZ", valid_602571
  var valid_602572 = query.getOrDefault("BackupRetentionPeriod")
  valid_602572 = validateParameter(valid_602572, JInt, required = false, default = nil)
  if valid_602572 != nil:
    section.add "BackupRetentionPeriod", valid_602572
  var valid_602573 = query.getOrDefault("DBParameterGroupName")
  valid_602573 = validateParameter(valid_602573, JString, required = false,
                                 default = nil)
  if valid_602573 != nil:
    section.add "DBParameterGroupName", valid_602573
  var valid_602574 = query.getOrDefault("DBInstanceClass")
  valid_602574 = validateParameter(valid_602574, JString, required = false,
                                 default = nil)
  if valid_602574 != nil:
    section.add "DBInstanceClass", valid_602574
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602575 = query.getOrDefault("Action")
  valid_602575 = validateParameter(valid_602575, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602575 != nil:
    section.add "Action", valid_602575
  var valid_602576 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_602576 = validateParameter(valid_602576, JBool, required = false, default = nil)
  if valid_602576 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602576
  var valid_602577 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602577 = validateParameter(valid_602577, JString, required = false,
                                 default = nil)
  if valid_602577 != nil:
    section.add "NewDBInstanceIdentifier", valid_602577
  var valid_602578 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602578 = validateParameter(valid_602578, JBool, required = false, default = nil)
  if valid_602578 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602578
  var valid_602579 = query.getOrDefault("EngineVersion")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "EngineVersion", valid_602579
  var valid_602580 = query.getOrDefault("PreferredBackupWindow")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "PreferredBackupWindow", valid_602580
  var valid_602581 = query.getOrDefault("Version")
  valid_602581 = validateParameter(valid_602581, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602581 != nil:
    section.add "Version", valid_602581
  var valid_602582 = query.getOrDefault("DBInstanceIdentifier")
  valid_602582 = validateParameter(valid_602582, JString, required = true,
                                 default = nil)
  if valid_602582 != nil:
    section.add "DBInstanceIdentifier", valid_602582
  var valid_602583 = query.getOrDefault("ApplyImmediately")
  valid_602583 = validateParameter(valid_602583, JBool, required = false, default = nil)
  if valid_602583 != nil:
    section.add "ApplyImmediately", valid_602583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602584 = header.getOrDefault("X-Amz-Date")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Date", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Security-Token")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Security-Token", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Content-Sha256", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-Algorithm")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-Algorithm", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Signature")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Signature", valid_602588
  var valid_602589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602589 = validateParameter(valid_602589, JString, required = false,
                                 default = nil)
  if valid_602589 != nil:
    section.add "X-Amz-SignedHeaders", valid_602589
  var valid_602590 = header.getOrDefault("X-Amz-Credential")
  valid_602590 = validateParameter(valid_602590, JString, required = false,
                                 default = nil)
  if valid_602590 != nil:
    section.add "X-Amz-Credential", valid_602590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602591: Call_GetModifyDBInstance_602561; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602591.validator(path, query, header, formData, body)
  let scheme = call_602591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602591.url(scheme.get, call_602591.host, call_602591.base,
                         call_602591.route, valid.getOrDefault("path"))
  result = hook(call_602591, url, valid)

proc call*(call_602592: Call_GetModifyDBInstance_602561;
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
  var query_602593 = newJObject()
  add(query_602593, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602593, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602593, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_602593.add "DBSecurityGroups", DBSecurityGroups
  add(query_602593, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602593, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_602593.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602593, "MultiAZ", newJBool(MultiAZ))
  add(query_602593, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602593, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602593, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602593, "Action", newJString(Action))
  add(query_602593, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_602593, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602593, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602593, "EngineVersion", newJString(EngineVersion))
  add(query_602593, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602593, "Version", newJString(Version))
  add(query_602593, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602593, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602592.call(nil, query_602593, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602561(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602562, base: "/",
    url: url_GetModifyDBInstance_602563, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_602645 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBParameterGroup_602647(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_602646(path: JsonNode; query: JsonNode;
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
  var valid_602648 = query.getOrDefault("Action")
  valid_602648 = validateParameter(valid_602648, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602648 != nil:
    section.add "Action", valid_602648
  var valid_602649 = query.getOrDefault("Version")
  valid_602649 = validateParameter(valid_602649, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602649 != nil:
    section.add "Version", valid_602649
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602657 = formData.getOrDefault("DBParameterGroupName")
  valid_602657 = validateParameter(valid_602657, JString, required = true,
                                 default = nil)
  if valid_602657 != nil:
    section.add "DBParameterGroupName", valid_602657
  var valid_602658 = formData.getOrDefault("Parameters")
  valid_602658 = validateParameter(valid_602658, JArray, required = true, default = nil)
  if valid_602658 != nil:
    section.add "Parameters", valid_602658
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602659: Call_PostModifyDBParameterGroup_602645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602659.validator(path, query, header, formData, body)
  let scheme = call_602659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602659.url(scheme.get, call_602659.host, call_602659.base,
                         call_602659.route, valid.getOrDefault("path"))
  result = hook(call_602659, url, valid)

proc call*(call_602660: Call_PostModifyDBParameterGroup_602645;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602661 = newJObject()
  var formData_602662 = newJObject()
  add(formData_602662, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602662.add "Parameters", Parameters
  add(query_602661, "Action", newJString(Action))
  add(query_602661, "Version", newJString(Version))
  result = call_602660.call(nil, query_602661, nil, formData_602662, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_602645(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_602646, base: "/",
    url: url_PostModifyDBParameterGroup_602647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_602628 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBParameterGroup_602630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_602629(path: JsonNode; query: JsonNode;
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
  var valid_602631 = query.getOrDefault("DBParameterGroupName")
  valid_602631 = validateParameter(valid_602631, JString, required = true,
                                 default = nil)
  if valid_602631 != nil:
    section.add "DBParameterGroupName", valid_602631
  var valid_602632 = query.getOrDefault("Parameters")
  valid_602632 = validateParameter(valid_602632, JArray, required = true, default = nil)
  if valid_602632 != nil:
    section.add "Parameters", valid_602632
  var valid_602633 = query.getOrDefault("Action")
  valid_602633 = validateParameter(valid_602633, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602633 != nil:
    section.add "Action", valid_602633
  var valid_602634 = query.getOrDefault("Version")
  valid_602634 = validateParameter(valid_602634, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602634 != nil:
    section.add "Version", valid_602634
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602635 = header.getOrDefault("X-Amz-Date")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Date", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-Security-Token")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Security-Token", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Content-Sha256", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Algorithm")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Algorithm", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-Signature")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-Signature", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-SignedHeaders", valid_602640
  var valid_602641 = header.getOrDefault("X-Amz-Credential")
  valid_602641 = validateParameter(valid_602641, JString, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "X-Amz-Credential", valid_602641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602642: Call_GetModifyDBParameterGroup_602628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602642.validator(path, query, header, formData, body)
  let scheme = call_602642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602642.url(scheme.get, call_602642.host, call_602642.base,
                         call_602642.route, valid.getOrDefault("path"))
  result = hook(call_602642, url, valid)

proc call*(call_602643: Call_GetModifyDBParameterGroup_602628;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602644 = newJObject()
  add(query_602644, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602644.add "Parameters", Parameters
  add(query_602644, "Action", newJString(Action))
  add(query_602644, "Version", newJString(Version))
  result = call_602643.call(nil, query_602644, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_602628(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_602629, base: "/",
    url: url_GetModifyDBParameterGroup_602630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602681 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBSubnetGroup_602683(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_602682(path: JsonNode; query: JsonNode;
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
  var valid_602684 = query.getOrDefault("Action")
  valid_602684 = validateParameter(valid_602684, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602684 != nil:
    section.add "Action", valid_602684
  var valid_602685 = query.getOrDefault("Version")
  valid_602685 = validateParameter(valid_602685, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602685 != nil:
    section.add "Version", valid_602685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602686 = header.getOrDefault("X-Amz-Date")
  valid_602686 = validateParameter(valid_602686, JString, required = false,
                                 default = nil)
  if valid_602686 != nil:
    section.add "X-Amz-Date", valid_602686
  var valid_602687 = header.getOrDefault("X-Amz-Security-Token")
  valid_602687 = validateParameter(valid_602687, JString, required = false,
                                 default = nil)
  if valid_602687 != nil:
    section.add "X-Amz-Security-Token", valid_602687
  var valid_602688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Content-Sha256", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Algorithm")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Algorithm", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Signature")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Signature", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-SignedHeaders", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Credential")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Credential", valid_602692
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602693 = formData.getOrDefault("DBSubnetGroupName")
  valid_602693 = validateParameter(valid_602693, JString, required = true,
                                 default = nil)
  if valid_602693 != nil:
    section.add "DBSubnetGroupName", valid_602693
  var valid_602694 = formData.getOrDefault("SubnetIds")
  valid_602694 = validateParameter(valid_602694, JArray, required = true, default = nil)
  if valid_602694 != nil:
    section.add "SubnetIds", valid_602694
  var valid_602695 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "DBSubnetGroupDescription", valid_602695
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602696: Call_PostModifyDBSubnetGroup_602681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602696.validator(path, query, header, formData, body)
  let scheme = call_602696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602696.url(scheme.get, call_602696.host, call_602696.base,
                         call_602696.route, valid.getOrDefault("path"))
  result = hook(call_602696, url, valid)

proc call*(call_602697: Call_PostModifyDBSubnetGroup_602681;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602698 = newJObject()
  var formData_602699 = newJObject()
  add(formData_602699, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602699.add "SubnetIds", SubnetIds
  add(query_602698, "Action", newJString(Action))
  add(formData_602699, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602698, "Version", newJString(Version))
  result = call_602697.call(nil, query_602698, nil, formData_602699, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602681(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602682, base: "/",
    url: url_PostModifyDBSubnetGroup_602683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602663 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBSubnetGroup_602665(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_602664(path: JsonNode; query: JsonNode;
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
  var valid_602666 = query.getOrDefault("Action")
  valid_602666 = validateParameter(valid_602666, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602666 != nil:
    section.add "Action", valid_602666
  var valid_602667 = query.getOrDefault("DBSubnetGroupName")
  valid_602667 = validateParameter(valid_602667, JString, required = true,
                                 default = nil)
  if valid_602667 != nil:
    section.add "DBSubnetGroupName", valid_602667
  var valid_602668 = query.getOrDefault("SubnetIds")
  valid_602668 = validateParameter(valid_602668, JArray, required = true, default = nil)
  if valid_602668 != nil:
    section.add "SubnetIds", valid_602668
  var valid_602669 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "DBSubnetGroupDescription", valid_602669
  var valid_602670 = query.getOrDefault("Version")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602670 != nil:
    section.add "Version", valid_602670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602671 = header.getOrDefault("X-Amz-Date")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Date", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Security-Token")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Security-Token", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Content-Sha256", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Algorithm")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Algorithm", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Signature")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Signature", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-SignedHeaders", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Credential")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Credential", valid_602677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602678: Call_GetModifyDBSubnetGroup_602663; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602678.validator(path, query, header, formData, body)
  let scheme = call_602678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602678.url(scheme.get, call_602678.host, call_602678.base,
                         call_602678.route, valid.getOrDefault("path"))
  result = hook(call_602678, url, valid)

proc call*(call_602679: Call_GetModifyDBSubnetGroup_602663;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602680 = newJObject()
  add(query_602680, "Action", newJString(Action))
  add(query_602680, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602680.add "SubnetIds", SubnetIds
  add(query_602680, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602680, "Version", newJString(Version))
  result = call_602679.call(nil, query_602680, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602663(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602664, base: "/",
    url: url_GetModifyDBSubnetGroup_602665, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_602720 = ref object of OpenApiRestCall_600410
proc url_PostModifyEventSubscription_602722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_602721(path: JsonNode; query: JsonNode;
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
  var valid_602723 = query.getOrDefault("Action")
  valid_602723 = validateParameter(valid_602723, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602723 != nil:
    section.add "Action", valid_602723
  var valid_602724 = query.getOrDefault("Version")
  valid_602724 = validateParameter(valid_602724, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602724 != nil:
    section.add "Version", valid_602724
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602725 = header.getOrDefault("X-Amz-Date")
  valid_602725 = validateParameter(valid_602725, JString, required = false,
                                 default = nil)
  if valid_602725 != nil:
    section.add "X-Amz-Date", valid_602725
  var valid_602726 = header.getOrDefault("X-Amz-Security-Token")
  valid_602726 = validateParameter(valid_602726, JString, required = false,
                                 default = nil)
  if valid_602726 != nil:
    section.add "X-Amz-Security-Token", valid_602726
  var valid_602727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Content-Sha256", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Algorithm")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Algorithm", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Signature")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Signature", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-SignedHeaders", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Credential")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Credential", valid_602731
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_602732 = formData.getOrDefault("Enabled")
  valid_602732 = validateParameter(valid_602732, JBool, required = false, default = nil)
  if valid_602732 != nil:
    section.add "Enabled", valid_602732
  var valid_602733 = formData.getOrDefault("EventCategories")
  valid_602733 = validateParameter(valid_602733, JArray, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "EventCategories", valid_602733
  var valid_602734 = formData.getOrDefault("SnsTopicArn")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "SnsTopicArn", valid_602734
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602735 = formData.getOrDefault("SubscriptionName")
  valid_602735 = validateParameter(valid_602735, JString, required = true,
                                 default = nil)
  if valid_602735 != nil:
    section.add "SubscriptionName", valid_602735
  var valid_602736 = formData.getOrDefault("SourceType")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "SourceType", valid_602736
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602737: Call_PostModifyEventSubscription_602720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602737.validator(path, query, header, formData, body)
  let scheme = call_602737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602737.url(scheme.get, call_602737.host, call_602737.base,
                         call_602737.route, valid.getOrDefault("path"))
  result = hook(call_602737, url, valid)

proc call*(call_602738: Call_PostModifyEventSubscription_602720;
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
  var query_602739 = newJObject()
  var formData_602740 = newJObject()
  add(formData_602740, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_602740.add "EventCategories", EventCategories
  add(formData_602740, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602740, "SubscriptionName", newJString(SubscriptionName))
  add(query_602739, "Action", newJString(Action))
  add(query_602739, "Version", newJString(Version))
  add(formData_602740, "SourceType", newJString(SourceType))
  result = call_602738.call(nil, query_602739, nil, formData_602740, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_602720(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_602721, base: "/",
    url: url_PostModifyEventSubscription_602722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_602700 = ref object of OpenApiRestCall_600410
proc url_GetModifyEventSubscription_602702(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_602701(path: JsonNode; query: JsonNode;
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
  var valid_602703 = query.getOrDefault("SourceType")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "SourceType", valid_602703
  var valid_602704 = query.getOrDefault("Enabled")
  valid_602704 = validateParameter(valid_602704, JBool, required = false, default = nil)
  if valid_602704 != nil:
    section.add "Enabled", valid_602704
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602705 = query.getOrDefault("Action")
  valid_602705 = validateParameter(valid_602705, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602705 != nil:
    section.add "Action", valid_602705
  var valid_602706 = query.getOrDefault("SnsTopicArn")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "SnsTopicArn", valid_602706
  var valid_602707 = query.getOrDefault("EventCategories")
  valid_602707 = validateParameter(valid_602707, JArray, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "EventCategories", valid_602707
  var valid_602708 = query.getOrDefault("SubscriptionName")
  valid_602708 = validateParameter(valid_602708, JString, required = true,
                                 default = nil)
  if valid_602708 != nil:
    section.add "SubscriptionName", valid_602708
  var valid_602709 = query.getOrDefault("Version")
  valid_602709 = validateParameter(valid_602709, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602709 != nil:
    section.add "Version", valid_602709
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602710 = header.getOrDefault("X-Amz-Date")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Date", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Security-Token")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Security-Token", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Content-Sha256", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Algorithm")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Algorithm", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-Signature")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-Signature", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-SignedHeaders", valid_602715
  var valid_602716 = header.getOrDefault("X-Amz-Credential")
  valid_602716 = validateParameter(valid_602716, JString, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "X-Amz-Credential", valid_602716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602717: Call_GetModifyEventSubscription_602700; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602717.validator(path, query, header, formData, body)
  let scheme = call_602717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602717.url(scheme.get, call_602717.host, call_602717.base,
                         call_602717.route, valid.getOrDefault("path"))
  result = hook(call_602717, url, valid)

proc call*(call_602718: Call_GetModifyEventSubscription_602700;
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
  var query_602719 = newJObject()
  add(query_602719, "SourceType", newJString(SourceType))
  add(query_602719, "Enabled", newJBool(Enabled))
  add(query_602719, "Action", newJString(Action))
  add(query_602719, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_602719.add "EventCategories", EventCategories
  add(query_602719, "SubscriptionName", newJString(SubscriptionName))
  add(query_602719, "Version", newJString(Version))
  result = call_602718.call(nil, query_602719, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_602700(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_602701, base: "/",
    url: url_GetModifyEventSubscription_602702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_602760 = ref object of OpenApiRestCall_600410
proc url_PostModifyOptionGroup_602762(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_602761(path: JsonNode; query: JsonNode;
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
  var valid_602763 = query.getOrDefault("Action")
  valid_602763 = validateParameter(valid_602763, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602763 != nil:
    section.add "Action", valid_602763
  var valid_602764 = query.getOrDefault("Version")
  valid_602764 = validateParameter(valid_602764, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602764 != nil:
    section.add "Version", valid_602764
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602765 = header.getOrDefault("X-Amz-Date")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-Date", valid_602765
  var valid_602766 = header.getOrDefault("X-Amz-Security-Token")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "X-Amz-Security-Token", valid_602766
  var valid_602767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "X-Amz-Content-Sha256", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-Algorithm")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-Algorithm", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Signature")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Signature", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-SignedHeaders", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Credential")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Credential", valid_602771
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_602772 = formData.getOrDefault("OptionsToRemove")
  valid_602772 = validateParameter(valid_602772, JArray, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "OptionsToRemove", valid_602772
  var valid_602773 = formData.getOrDefault("ApplyImmediately")
  valid_602773 = validateParameter(valid_602773, JBool, required = false, default = nil)
  if valid_602773 != nil:
    section.add "ApplyImmediately", valid_602773
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602774 = formData.getOrDefault("OptionGroupName")
  valid_602774 = validateParameter(valid_602774, JString, required = true,
                                 default = nil)
  if valid_602774 != nil:
    section.add "OptionGroupName", valid_602774
  var valid_602775 = formData.getOrDefault("OptionsToInclude")
  valid_602775 = validateParameter(valid_602775, JArray, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "OptionsToInclude", valid_602775
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602776: Call_PostModifyOptionGroup_602760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602776.validator(path, query, header, formData, body)
  let scheme = call_602776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602776.url(scheme.get, call_602776.host, call_602776.base,
                         call_602776.route, valid.getOrDefault("path"))
  result = hook(call_602776, url, valid)

proc call*(call_602777: Call_PostModifyOptionGroup_602760; OptionGroupName: string;
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
  var query_602778 = newJObject()
  var formData_602779 = newJObject()
  if OptionsToRemove != nil:
    formData_602779.add "OptionsToRemove", OptionsToRemove
  add(formData_602779, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602779, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_602779.add "OptionsToInclude", OptionsToInclude
  add(query_602778, "Action", newJString(Action))
  add(query_602778, "Version", newJString(Version))
  result = call_602777.call(nil, query_602778, nil, formData_602779, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_602760(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_602761, base: "/",
    url: url_PostModifyOptionGroup_602762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_602741 = ref object of OpenApiRestCall_600410
proc url_GetModifyOptionGroup_602743(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_602742(path: JsonNode; query: JsonNode;
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
  var valid_602744 = query.getOrDefault("OptionGroupName")
  valid_602744 = validateParameter(valid_602744, JString, required = true,
                                 default = nil)
  if valid_602744 != nil:
    section.add "OptionGroupName", valid_602744
  var valid_602745 = query.getOrDefault("OptionsToRemove")
  valid_602745 = validateParameter(valid_602745, JArray, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "OptionsToRemove", valid_602745
  var valid_602746 = query.getOrDefault("Action")
  valid_602746 = validateParameter(valid_602746, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602746 != nil:
    section.add "Action", valid_602746
  var valid_602747 = query.getOrDefault("Version")
  valid_602747 = validateParameter(valid_602747, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602747 != nil:
    section.add "Version", valid_602747
  var valid_602748 = query.getOrDefault("ApplyImmediately")
  valid_602748 = validateParameter(valid_602748, JBool, required = false, default = nil)
  if valid_602748 != nil:
    section.add "ApplyImmediately", valid_602748
  var valid_602749 = query.getOrDefault("OptionsToInclude")
  valid_602749 = validateParameter(valid_602749, JArray, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "OptionsToInclude", valid_602749
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602750 = header.getOrDefault("X-Amz-Date")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Date", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Security-Token")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Security-Token", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-Content-Sha256", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Algorithm")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Algorithm", valid_602753
  var valid_602754 = header.getOrDefault("X-Amz-Signature")
  valid_602754 = validateParameter(valid_602754, JString, required = false,
                                 default = nil)
  if valid_602754 != nil:
    section.add "X-Amz-Signature", valid_602754
  var valid_602755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602755 = validateParameter(valid_602755, JString, required = false,
                                 default = nil)
  if valid_602755 != nil:
    section.add "X-Amz-SignedHeaders", valid_602755
  var valid_602756 = header.getOrDefault("X-Amz-Credential")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "X-Amz-Credential", valid_602756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602757: Call_GetModifyOptionGroup_602741; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602757.validator(path, query, header, formData, body)
  let scheme = call_602757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602757.url(scheme.get, call_602757.host, call_602757.base,
                         call_602757.route, valid.getOrDefault("path"))
  result = hook(call_602757, url, valid)

proc call*(call_602758: Call_GetModifyOptionGroup_602741; OptionGroupName: string;
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
  var query_602759 = newJObject()
  add(query_602759, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_602759.add "OptionsToRemove", OptionsToRemove
  add(query_602759, "Action", newJString(Action))
  add(query_602759, "Version", newJString(Version))
  add(query_602759, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_602759.add "OptionsToInclude", OptionsToInclude
  result = call_602758.call(nil, query_602759, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_602741(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_602742, base: "/",
    url: url_GetModifyOptionGroup_602743, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_602798 = ref object of OpenApiRestCall_600410
proc url_PostPromoteReadReplica_602800(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_602799(path: JsonNode; query: JsonNode;
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
  var valid_602801 = query.getOrDefault("Action")
  valid_602801 = validateParameter(valid_602801, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602801 != nil:
    section.add "Action", valid_602801
  var valid_602802 = query.getOrDefault("Version")
  valid_602802 = validateParameter(valid_602802, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602802 != nil:
    section.add "Version", valid_602802
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602803 = header.getOrDefault("X-Amz-Date")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Date", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Security-Token")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Security-Token", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Content-Sha256", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-Algorithm")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Algorithm", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-Signature")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Signature", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-SignedHeaders", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-Credential")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Credential", valid_602809
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602810 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602810 = validateParameter(valid_602810, JString, required = true,
                                 default = nil)
  if valid_602810 != nil:
    section.add "DBInstanceIdentifier", valid_602810
  var valid_602811 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602811 = validateParameter(valid_602811, JInt, required = false, default = nil)
  if valid_602811 != nil:
    section.add "BackupRetentionPeriod", valid_602811
  var valid_602812 = formData.getOrDefault("PreferredBackupWindow")
  valid_602812 = validateParameter(valid_602812, JString, required = false,
                                 default = nil)
  if valid_602812 != nil:
    section.add "PreferredBackupWindow", valid_602812
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602813: Call_PostPromoteReadReplica_602798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602813.validator(path, query, header, formData, body)
  let scheme = call_602813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602813.url(scheme.get, call_602813.host, call_602813.base,
                         call_602813.route, valid.getOrDefault("path"))
  result = hook(call_602813, url, valid)

proc call*(call_602814: Call_PostPromoteReadReplica_602798;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_602815 = newJObject()
  var formData_602816 = newJObject()
  add(formData_602816, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602816, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602815, "Action", newJString(Action))
  add(formData_602816, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602815, "Version", newJString(Version))
  result = call_602814.call(nil, query_602815, nil, formData_602816, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_602798(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_602799, base: "/",
    url: url_PostPromoteReadReplica_602800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_602780 = ref object of OpenApiRestCall_600410
proc url_GetPromoteReadReplica_602782(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_602781(path: JsonNode; query: JsonNode;
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
  var valid_602783 = query.getOrDefault("BackupRetentionPeriod")
  valid_602783 = validateParameter(valid_602783, JInt, required = false, default = nil)
  if valid_602783 != nil:
    section.add "BackupRetentionPeriod", valid_602783
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602784 = query.getOrDefault("Action")
  valid_602784 = validateParameter(valid_602784, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602784 != nil:
    section.add "Action", valid_602784
  var valid_602785 = query.getOrDefault("PreferredBackupWindow")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "PreferredBackupWindow", valid_602785
  var valid_602786 = query.getOrDefault("Version")
  valid_602786 = validateParameter(valid_602786, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602786 != nil:
    section.add "Version", valid_602786
  var valid_602787 = query.getOrDefault("DBInstanceIdentifier")
  valid_602787 = validateParameter(valid_602787, JString, required = true,
                                 default = nil)
  if valid_602787 != nil:
    section.add "DBInstanceIdentifier", valid_602787
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602788 = header.getOrDefault("X-Amz-Date")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Date", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-Security-Token")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-Security-Token", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Content-Sha256", valid_602790
  var valid_602791 = header.getOrDefault("X-Amz-Algorithm")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "X-Amz-Algorithm", valid_602791
  var valid_602792 = header.getOrDefault("X-Amz-Signature")
  valid_602792 = validateParameter(valid_602792, JString, required = false,
                                 default = nil)
  if valid_602792 != nil:
    section.add "X-Amz-Signature", valid_602792
  var valid_602793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602793 = validateParameter(valid_602793, JString, required = false,
                                 default = nil)
  if valid_602793 != nil:
    section.add "X-Amz-SignedHeaders", valid_602793
  var valid_602794 = header.getOrDefault("X-Amz-Credential")
  valid_602794 = validateParameter(valid_602794, JString, required = false,
                                 default = nil)
  if valid_602794 != nil:
    section.add "X-Amz-Credential", valid_602794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602795: Call_GetPromoteReadReplica_602780; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602795.validator(path, query, header, formData, body)
  let scheme = call_602795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602795.url(scheme.get, call_602795.host, call_602795.base,
                         call_602795.route, valid.getOrDefault("path"))
  result = hook(call_602795, url, valid)

proc call*(call_602796: Call_GetPromoteReadReplica_602780;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602797 = newJObject()
  add(query_602797, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602797, "Action", newJString(Action))
  add(query_602797, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602797, "Version", newJString(Version))
  add(query_602797, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602796.call(nil, query_602797, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_602780(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_602781, base: "/",
    url: url_GetPromoteReadReplica_602782, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_602836 = ref object of OpenApiRestCall_600410
proc url_PostPurchaseReservedDBInstancesOffering_602838(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_602837(path: JsonNode;
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
  var valid_602839 = query.getOrDefault("Action")
  valid_602839 = validateParameter(valid_602839, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602839 != nil:
    section.add "Action", valid_602839
  var valid_602840 = query.getOrDefault("Version")
  valid_602840 = validateParameter(valid_602840, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602840 != nil:
    section.add "Version", valid_602840
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602841 = header.getOrDefault("X-Amz-Date")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "X-Amz-Date", valid_602841
  var valid_602842 = header.getOrDefault("X-Amz-Security-Token")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-Security-Token", valid_602842
  var valid_602843 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Content-Sha256", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Algorithm")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Algorithm", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Signature")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Signature", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-SignedHeaders", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-Credential")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-Credential", valid_602847
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_602848 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "ReservedDBInstanceId", valid_602848
  var valid_602849 = formData.getOrDefault("Tags")
  valid_602849 = validateParameter(valid_602849, JArray, required = false,
                                 default = nil)
  if valid_602849 != nil:
    section.add "Tags", valid_602849
  var valid_602850 = formData.getOrDefault("DBInstanceCount")
  valid_602850 = validateParameter(valid_602850, JInt, required = false, default = nil)
  if valid_602850 != nil:
    section.add "DBInstanceCount", valid_602850
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602851 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602851 = validateParameter(valid_602851, JString, required = true,
                                 default = nil)
  if valid_602851 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602851
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602852: Call_PostPurchaseReservedDBInstancesOffering_602836;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602852.validator(path, query, header, formData, body)
  let scheme = call_602852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602852.url(scheme.get, call_602852.host, call_602852.base,
                         call_602852.route, valid.getOrDefault("path"))
  result = hook(call_602852, url, valid)

proc call*(call_602853: Call_PostPurchaseReservedDBInstancesOffering_602836;
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
  var query_602854 = newJObject()
  var formData_602855 = newJObject()
  add(formData_602855, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_602855.add "Tags", Tags
  add(formData_602855, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602854, "Action", newJString(Action))
  add(formData_602855, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602854, "Version", newJString(Version))
  result = call_602853.call(nil, query_602854, nil, formData_602855, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_602836(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_602837, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_602838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_602817 = ref object of OpenApiRestCall_600410
proc url_GetPurchaseReservedDBInstancesOffering_602819(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_602818(path: JsonNode;
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
  var valid_602820 = query.getOrDefault("DBInstanceCount")
  valid_602820 = validateParameter(valid_602820, JInt, required = false, default = nil)
  if valid_602820 != nil:
    section.add "DBInstanceCount", valid_602820
  var valid_602821 = query.getOrDefault("Tags")
  valid_602821 = validateParameter(valid_602821, JArray, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "Tags", valid_602821
  var valid_602822 = query.getOrDefault("ReservedDBInstanceId")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "ReservedDBInstanceId", valid_602822
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602823 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602823 = validateParameter(valid_602823, JString, required = true,
                                 default = nil)
  if valid_602823 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602823
  var valid_602824 = query.getOrDefault("Action")
  valid_602824 = validateParameter(valid_602824, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602824 != nil:
    section.add "Action", valid_602824
  var valid_602825 = query.getOrDefault("Version")
  valid_602825 = validateParameter(valid_602825, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602825 != nil:
    section.add "Version", valid_602825
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602826 = header.getOrDefault("X-Amz-Date")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Date", valid_602826
  var valid_602827 = header.getOrDefault("X-Amz-Security-Token")
  valid_602827 = validateParameter(valid_602827, JString, required = false,
                                 default = nil)
  if valid_602827 != nil:
    section.add "X-Amz-Security-Token", valid_602827
  var valid_602828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "X-Amz-Content-Sha256", valid_602828
  var valid_602829 = header.getOrDefault("X-Amz-Algorithm")
  valid_602829 = validateParameter(valid_602829, JString, required = false,
                                 default = nil)
  if valid_602829 != nil:
    section.add "X-Amz-Algorithm", valid_602829
  var valid_602830 = header.getOrDefault("X-Amz-Signature")
  valid_602830 = validateParameter(valid_602830, JString, required = false,
                                 default = nil)
  if valid_602830 != nil:
    section.add "X-Amz-Signature", valid_602830
  var valid_602831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602831 = validateParameter(valid_602831, JString, required = false,
                                 default = nil)
  if valid_602831 != nil:
    section.add "X-Amz-SignedHeaders", valid_602831
  var valid_602832 = header.getOrDefault("X-Amz-Credential")
  valid_602832 = validateParameter(valid_602832, JString, required = false,
                                 default = nil)
  if valid_602832 != nil:
    section.add "X-Amz-Credential", valid_602832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602833: Call_GetPurchaseReservedDBInstancesOffering_602817;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602833.validator(path, query, header, formData, body)
  let scheme = call_602833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602833.url(scheme.get, call_602833.host, call_602833.base,
                         call_602833.route, valid.getOrDefault("path"))
  result = hook(call_602833, url, valid)

proc call*(call_602834: Call_GetPurchaseReservedDBInstancesOffering_602817;
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
  var query_602835 = newJObject()
  add(query_602835, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_602835.add "Tags", Tags
  add(query_602835, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602835, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602835, "Action", newJString(Action))
  add(query_602835, "Version", newJString(Version))
  result = call_602834.call(nil, query_602835, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_602817(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_602818, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_602819,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602873 = ref object of OpenApiRestCall_600410
proc url_PostRebootDBInstance_602875(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_602874(path: JsonNode; query: JsonNode;
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
  var valid_602876 = query.getOrDefault("Action")
  valid_602876 = validateParameter(valid_602876, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602876 != nil:
    section.add "Action", valid_602876
  var valid_602877 = query.getOrDefault("Version")
  valid_602877 = validateParameter(valid_602877, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602877 != nil:
    section.add "Version", valid_602877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602878 = header.getOrDefault("X-Amz-Date")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Date", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Security-Token")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Security-Token", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Content-Sha256", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Algorithm")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Algorithm", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-Signature")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Signature", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-SignedHeaders", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-Credential")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Credential", valid_602884
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602885 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602885 = validateParameter(valid_602885, JString, required = true,
                                 default = nil)
  if valid_602885 != nil:
    section.add "DBInstanceIdentifier", valid_602885
  var valid_602886 = formData.getOrDefault("ForceFailover")
  valid_602886 = validateParameter(valid_602886, JBool, required = false, default = nil)
  if valid_602886 != nil:
    section.add "ForceFailover", valid_602886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602887: Call_PostRebootDBInstance_602873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602887.validator(path, query, header, formData, body)
  let scheme = call_602887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602887.url(scheme.get, call_602887.host, call_602887.base,
                         call_602887.route, valid.getOrDefault("path"))
  result = hook(call_602887, url, valid)

proc call*(call_602888: Call_PostRebootDBInstance_602873;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_602889 = newJObject()
  var formData_602890 = newJObject()
  add(formData_602890, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602889, "Action", newJString(Action))
  add(formData_602890, "ForceFailover", newJBool(ForceFailover))
  add(query_602889, "Version", newJString(Version))
  result = call_602888.call(nil, query_602889, nil, formData_602890, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602873(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602874, base: "/",
    url: url_PostRebootDBInstance_602875, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602856 = ref object of OpenApiRestCall_600410
proc url_GetRebootDBInstance_602858(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_602857(path: JsonNode; query: JsonNode;
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
  var valid_602859 = query.getOrDefault("Action")
  valid_602859 = validateParameter(valid_602859, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602859 != nil:
    section.add "Action", valid_602859
  var valid_602860 = query.getOrDefault("ForceFailover")
  valid_602860 = validateParameter(valid_602860, JBool, required = false, default = nil)
  if valid_602860 != nil:
    section.add "ForceFailover", valid_602860
  var valid_602861 = query.getOrDefault("Version")
  valid_602861 = validateParameter(valid_602861, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602861 != nil:
    section.add "Version", valid_602861
  var valid_602862 = query.getOrDefault("DBInstanceIdentifier")
  valid_602862 = validateParameter(valid_602862, JString, required = true,
                                 default = nil)
  if valid_602862 != nil:
    section.add "DBInstanceIdentifier", valid_602862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602863 = header.getOrDefault("X-Amz-Date")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Date", valid_602863
  var valid_602864 = header.getOrDefault("X-Amz-Security-Token")
  valid_602864 = validateParameter(valid_602864, JString, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "X-Amz-Security-Token", valid_602864
  var valid_602865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602865 = validateParameter(valid_602865, JString, required = false,
                                 default = nil)
  if valid_602865 != nil:
    section.add "X-Amz-Content-Sha256", valid_602865
  var valid_602866 = header.getOrDefault("X-Amz-Algorithm")
  valid_602866 = validateParameter(valid_602866, JString, required = false,
                                 default = nil)
  if valid_602866 != nil:
    section.add "X-Amz-Algorithm", valid_602866
  var valid_602867 = header.getOrDefault("X-Amz-Signature")
  valid_602867 = validateParameter(valid_602867, JString, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "X-Amz-Signature", valid_602867
  var valid_602868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602868 = validateParameter(valid_602868, JString, required = false,
                                 default = nil)
  if valid_602868 != nil:
    section.add "X-Amz-SignedHeaders", valid_602868
  var valid_602869 = header.getOrDefault("X-Amz-Credential")
  valid_602869 = validateParameter(valid_602869, JString, required = false,
                                 default = nil)
  if valid_602869 != nil:
    section.add "X-Amz-Credential", valid_602869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602870: Call_GetRebootDBInstance_602856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602870.validator(path, query, header, formData, body)
  let scheme = call_602870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602870.url(scheme.get, call_602870.host, call_602870.base,
                         call_602870.route, valid.getOrDefault("path"))
  result = hook(call_602870, url, valid)

proc call*(call_602871: Call_GetRebootDBInstance_602856;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602872 = newJObject()
  add(query_602872, "Action", newJString(Action))
  add(query_602872, "ForceFailover", newJBool(ForceFailover))
  add(query_602872, "Version", newJString(Version))
  add(query_602872, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602871.call(nil, query_602872, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602856(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602857, base: "/",
    url: url_GetRebootDBInstance_602858, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_602908 = ref object of OpenApiRestCall_600410
proc url_PostRemoveSourceIdentifierFromSubscription_602910(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_602909(path: JsonNode;
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
  var valid_602911 = query.getOrDefault("Action")
  valid_602911 = validateParameter(valid_602911, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602911 != nil:
    section.add "Action", valid_602911
  var valid_602912 = query.getOrDefault("Version")
  valid_602912 = validateParameter(valid_602912, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602912 != nil:
    section.add "Version", valid_602912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602913 = header.getOrDefault("X-Amz-Date")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Date", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Security-Token")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Security-Token", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Content-Sha256", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-Algorithm")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-Algorithm", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Signature")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Signature", valid_602917
  var valid_602918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-SignedHeaders", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Credential")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Credential", valid_602919
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_602920 = formData.getOrDefault("SourceIdentifier")
  valid_602920 = validateParameter(valid_602920, JString, required = true,
                                 default = nil)
  if valid_602920 != nil:
    section.add "SourceIdentifier", valid_602920
  var valid_602921 = formData.getOrDefault("SubscriptionName")
  valid_602921 = validateParameter(valid_602921, JString, required = true,
                                 default = nil)
  if valid_602921 != nil:
    section.add "SubscriptionName", valid_602921
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602922: Call_PostRemoveSourceIdentifierFromSubscription_602908;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602922.validator(path, query, header, formData, body)
  let scheme = call_602922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602922.url(scheme.get, call_602922.host, call_602922.base,
                         call_602922.route, valid.getOrDefault("path"))
  result = hook(call_602922, url, valid)

proc call*(call_602923: Call_PostRemoveSourceIdentifierFromSubscription_602908;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602924 = newJObject()
  var formData_602925 = newJObject()
  add(formData_602925, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_602925, "SubscriptionName", newJString(SubscriptionName))
  add(query_602924, "Action", newJString(Action))
  add(query_602924, "Version", newJString(Version))
  result = call_602923.call(nil, query_602924, nil, formData_602925, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_602908(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_602909,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_602910,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_602891 = ref object of OpenApiRestCall_600410
proc url_GetRemoveSourceIdentifierFromSubscription_602893(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_602892(path: JsonNode;
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
  var valid_602894 = query.getOrDefault("Action")
  valid_602894 = validateParameter(valid_602894, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602894 != nil:
    section.add "Action", valid_602894
  var valid_602895 = query.getOrDefault("SourceIdentifier")
  valid_602895 = validateParameter(valid_602895, JString, required = true,
                                 default = nil)
  if valid_602895 != nil:
    section.add "SourceIdentifier", valid_602895
  var valid_602896 = query.getOrDefault("SubscriptionName")
  valid_602896 = validateParameter(valid_602896, JString, required = true,
                                 default = nil)
  if valid_602896 != nil:
    section.add "SubscriptionName", valid_602896
  var valid_602897 = query.getOrDefault("Version")
  valid_602897 = validateParameter(valid_602897, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602897 != nil:
    section.add "Version", valid_602897
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602898 = header.getOrDefault("X-Amz-Date")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Date", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-Security-Token")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-Security-Token", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Content-Sha256", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Algorithm")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Algorithm", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Signature")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Signature", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-SignedHeaders", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Credential")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Credential", valid_602904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602905: Call_GetRemoveSourceIdentifierFromSubscription_602891;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602905.validator(path, query, header, formData, body)
  let scheme = call_602905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602905.url(scheme.get, call_602905.host, call_602905.base,
                         call_602905.route, valid.getOrDefault("path"))
  result = hook(call_602905, url, valid)

proc call*(call_602906: Call_GetRemoveSourceIdentifierFromSubscription_602891;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602907 = newJObject()
  add(query_602907, "Action", newJString(Action))
  add(query_602907, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602907, "SubscriptionName", newJString(SubscriptionName))
  add(query_602907, "Version", newJString(Version))
  result = call_602906.call(nil, query_602907, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_602891(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_602892,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_602893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_602943 = ref object of OpenApiRestCall_600410
proc url_PostRemoveTagsFromResource_602945(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_602944(path: JsonNode; query: JsonNode;
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
  var valid_602946 = query.getOrDefault("Action")
  valid_602946 = validateParameter(valid_602946, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602946 != nil:
    section.add "Action", valid_602946
  var valid_602947 = query.getOrDefault("Version")
  valid_602947 = validateParameter(valid_602947, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602947 != nil:
    section.add "Version", valid_602947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602948 = header.getOrDefault("X-Amz-Date")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "X-Amz-Date", valid_602948
  var valid_602949 = header.getOrDefault("X-Amz-Security-Token")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "X-Amz-Security-Token", valid_602949
  var valid_602950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "X-Amz-Content-Sha256", valid_602950
  var valid_602951 = header.getOrDefault("X-Amz-Algorithm")
  valid_602951 = validateParameter(valid_602951, JString, required = false,
                                 default = nil)
  if valid_602951 != nil:
    section.add "X-Amz-Algorithm", valid_602951
  var valid_602952 = header.getOrDefault("X-Amz-Signature")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "X-Amz-Signature", valid_602952
  var valid_602953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602953 = validateParameter(valid_602953, JString, required = false,
                                 default = nil)
  if valid_602953 != nil:
    section.add "X-Amz-SignedHeaders", valid_602953
  var valid_602954 = header.getOrDefault("X-Amz-Credential")
  valid_602954 = validateParameter(valid_602954, JString, required = false,
                                 default = nil)
  if valid_602954 != nil:
    section.add "X-Amz-Credential", valid_602954
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_602955 = formData.getOrDefault("TagKeys")
  valid_602955 = validateParameter(valid_602955, JArray, required = true, default = nil)
  if valid_602955 != nil:
    section.add "TagKeys", valid_602955
  var valid_602956 = formData.getOrDefault("ResourceName")
  valid_602956 = validateParameter(valid_602956, JString, required = true,
                                 default = nil)
  if valid_602956 != nil:
    section.add "ResourceName", valid_602956
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602957: Call_PostRemoveTagsFromResource_602943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602957.validator(path, query, header, formData, body)
  let scheme = call_602957.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602957.url(scheme.get, call_602957.host, call_602957.base,
                         call_602957.route, valid.getOrDefault("path"))
  result = hook(call_602957, url, valid)

proc call*(call_602958: Call_PostRemoveTagsFromResource_602943; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602959 = newJObject()
  var formData_602960 = newJObject()
  add(query_602959, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602960.add "TagKeys", TagKeys
  add(formData_602960, "ResourceName", newJString(ResourceName))
  add(query_602959, "Version", newJString(Version))
  result = call_602958.call(nil, query_602959, nil, formData_602960, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_602943(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_602944, base: "/",
    url: url_PostRemoveTagsFromResource_602945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_602926 = ref object of OpenApiRestCall_600410
proc url_GetRemoveTagsFromResource_602928(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_602927(path: JsonNode; query: JsonNode;
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
  var valid_602929 = query.getOrDefault("ResourceName")
  valid_602929 = validateParameter(valid_602929, JString, required = true,
                                 default = nil)
  if valid_602929 != nil:
    section.add "ResourceName", valid_602929
  var valid_602930 = query.getOrDefault("Action")
  valid_602930 = validateParameter(valid_602930, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602930 != nil:
    section.add "Action", valid_602930
  var valid_602931 = query.getOrDefault("TagKeys")
  valid_602931 = validateParameter(valid_602931, JArray, required = true, default = nil)
  if valid_602931 != nil:
    section.add "TagKeys", valid_602931
  var valid_602932 = query.getOrDefault("Version")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602932 != nil:
    section.add "Version", valid_602932
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602933 = header.getOrDefault("X-Amz-Date")
  valid_602933 = validateParameter(valid_602933, JString, required = false,
                                 default = nil)
  if valid_602933 != nil:
    section.add "X-Amz-Date", valid_602933
  var valid_602934 = header.getOrDefault("X-Amz-Security-Token")
  valid_602934 = validateParameter(valid_602934, JString, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "X-Amz-Security-Token", valid_602934
  var valid_602935 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602935 = validateParameter(valid_602935, JString, required = false,
                                 default = nil)
  if valid_602935 != nil:
    section.add "X-Amz-Content-Sha256", valid_602935
  var valid_602936 = header.getOrDefault("X-Amz-Algorithm")
  valid_602936 = validateParameter(valid_602936, JString, required = false,
                                 default = nil)
  if valid_602936 != nil:
    section.add "X-Amz-Algorithm", valid_602936
  var valid_602937 = header.getOrDefault("X-Amz-Signature")
  valid_602937 = validateParameter(valid_602937, JString, required = false,
                                 default = nil)
  if valid_602937 != nil:
    section.add "X-Amz-Signature", valid_602937
  var valid_602938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602938 = validateParameter(valid_602938, JString, required = false,
                                 default = nil)
  if valid_602938 != nil:
    section.add "X-Amz-SignedHeaders", valid_602938
  var valid_602939 = header.getOrDefault("X-Amz-Credential")
  valid_602939 = validateParameter(valid_602939, JString, required = false,
                                 default = nil)
  if valid_602939 != nil:
    section.add "X-Amz-Credential", valid_602939
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602940: Call_GetRemoveTagsFromResource_602926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602940.validator(path, query, header, formData, body)
  let scheme = call_602940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602940.url(scheme.get, call_602940.host, call_602940.base,
                         call_602940.route, valid.getOrDefault("path"))
  result = hook(call_602940, url, valid)

proc call*(call_602941: Call_GetRemoveTagsFromResource_602926;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_602942 = newJObject()
  add(query_602942, "ResourceName", newJString(ResourceName))
  add(query_602942, "Action", newJString(Action))
  if TagKeys != nil:
    query_602942.add "TagKeys", TagKeys
  add(query_602942, "Version", newJString(Version))
  result = call_602941.call(nil, query_602942, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_602926(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_602927, base: "/",
    url: url_GetRemoveTagsFromResource_602928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_602979 = ref object of OpenApiRestCall_600410
proc url_PostResetDBParameterGroup_602981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_602980(path: JsonNode; query: JsonNode;
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
  var valid_602982 = query.getOrDefault("Action")
  valid_602982 = validateParameter(valid_602982, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602982 != nil:
    section.add "Action", valid_602982
  var valid_602983 = query.getOrDefault("Version")
  valid_602983 = validateParameter(valid_602983, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602983 != nil:
    section.add "Version", valid_602983
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602984 = header.getOrDefault("X-Amz-Date")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "X-Amz-Date", valid_602984
  var valid_602985 = header.getOrDefault("X-Amz-Security-Token")
  valid_602985 = validateParameter(valid_602985, JString, required = false,
                                 default = nil)
  if valid_602985 != nil:
    section.add "X-Amz-Security-Token", valid_602985
  var valid_602986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "X-Amz-Content-Sha256", valid_602986
  var valid_602987 = header.getOrDefault("X-Amz-Algorithm")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "X-Amz-Algorithm", valid_602987
  var valid_602988 = header.getOrDefault("X-Amz-Signature")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "X-Amz-Signature", valid_602988
  var valid_602989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602989 = validateParameter(valid_602989, JString, required = false,
                                 default = nil)
  if valid_602989 != nil:
    section.add "X-Amz-SignedHeaders", valid_602989
  var valid_602990 = header.getOrDefault("X-Amz-Credential")
  valid_602990 = validateParameter(valid_602990, JString, required = false,
                                 default = nil)
  if valid_602990 != nil:
    section.add "X-Amz-Credential", valid_602990
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602991 = formData.getOrDefault("DBParameterGroupName")
  valid_602991 = validateParameter(valid_602991, JString, required = true,
                                 default = nil)
  if valid_602991 != nil:
    section.add "DBParameterGroupName", valid_602991
  var valid_602992 = formData.getOrDefault("Parameters")
  valid_602992 = validateParameter(valid_602992, JArray, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "Parameters", valid_602992
  var valid_602993 = formData.getOrDefault("ResetAllParameters")
  valid_602993 = validateParameter(valid_602993, JBool, required = false, default = nil)
  if valid_602993 != nil:
    section.add "ResetAllParameters", valid_602993
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602994: Call_PostResetDBParameterGroup_602979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602994.validator(path, query, header, formData, body)
  let scheme = call_602994.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602994.url(scheme.get, call_602994.host, call_602994.base,
                         call_602994.route, valid.getOrDefault("path"))
  result = hook(call_602994, url, valid)

proc call*(call_602995: Call_PostResetDBParameterGroup_602979;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602996 = newJObject()
  var formData_602997 = newJObject()
  add(formData_602997, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602997.add "Parameters", Parameters
  add(query_602996, "Action", newJString(Action))
  add(formData_602997, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602996, "Version", newJString(Version))
  result = call_602995.call(nil, query_602996, nil, formData_602997, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_602979(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_602980, base: "/",
    url: url_PostResetDBParameterGroup_602981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_602961 = ref object of OpenApiRestCall_600410
proc url_GetResetDBParameterGroup_602963(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_602962(path: JsonNode; query: JsonNode;
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
  var valid_602964 = query.getOrDefault("DBParameterGroupName")
  valid_602964 = validateParameter(valid_602964, JString, required = true,
                                 default = nil)
  if valid_602964 != nil:
    section.add "DBParameterGroupName", valid_602964
  var valid_602965 = query.getOrDefault("Parameters")
  valid_602965 = validateParameter(valid_602965, JArray, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "Parameters", valid_602965
  var valid_602966 = query.getOrDefault("Action")
  valid_602966 = validateParameter(valid_602966, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602966 != nil:
    section.add "Action", valid_602966
  var valid_602967 = query.getOrDefault("ResetAllParameters")
  valid_602967 = validateParameter(valid_602967, JBool, required = false, default = nil)
  if valid_602967 != nil:
    section.add "ResetAllParameters", valid_602967
  var valid_602968 = query.getOrDefault("Version")
  valid_602968 = validateParameter(valid_602968, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_602968 != nil:
    section.add "Version", valid_602968
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602969 = header.getOrDefault("X-Amz-Date")
  valid_602969 = validateParameter(valid_602969, JString, required = false,
                                 default = nil)
  if valid_602969 != nil:
    section.add "X-Amz-Date", valid_602969
  var valid_602970 = header.getOrDefault("X-Amz-Security-Token")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-Security-Token", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-Content-Sha256", valid_602971
  var valid_602972 = header.getOrDefault("X-Amz-Algorithm")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "X-Amz-Algorithm", valid_602972
  var valid_602973 = header.getOrDefault("X-Amz-Signature")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-Signature", valid_602973
  var valid_602974 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-SignedHeaders", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Credential")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Credential", valid_602975
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602976: Call_GetResetDBParameterGroup_602961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602976.validator(path, query, header, formData, body)
  let scheme = call_602976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602976.url(scheme.get, call_602976.host, call_602976.base,
                         call_602976.route, valid.getOrDefault("path"))
  result = hook(call_602976, url, valid)

proc call*(call_602977: Call_GetResetDBParameterGroup_602961;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602978 = newJObject()
  add(query_602978, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602978.add "Parameters", Parameters
  add(query_602978, "Action", newJString(Action))
  add(query_602978, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602978, "Version", newJString(Version))
  result = call_602977.call(nil, query_602978, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_602961(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_602962, base: "/",
    url: url_GetResetDBParameterGroup_602963, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_603028 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceFromDBSnapshot_603030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_603029(path: JsonNode;
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
  var valid_603031 = query.getOrDefault("Action")
  valid_603031 = validateParameter(valid_603031, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603031 != nil:
    section.add "Action", valid_603031
  var valid_603032 = query.getOrDefault("Version")
  valid_603032 = validateParameter(valid_603032, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603032 != nil:
    section.add "Version", valid_603032
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603033 = header.getOrDefault("X-Amz-Date")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Date", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Security-Token")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Security-Token", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Content-Sha256", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Algorithm")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Algorithm", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Signature")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Signature", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-SignedHeaders", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Credential")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Credential", valid_603039
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
  var valid_603040 = formData.getOrDefault("Port")
  valid_603040 = validateParameter(valid_603040, JInt, required = false, default = nil)
  if valid_603040 != nil:
    section.add "Port", valid_603040
  var valid_603041 = formData.getOrDefault("Engine")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "Engine", valid_603041
  var valid_603042 = formData.getOrDefault("Iops")
  valid_603042 = validateParameter(valid_603042, JInt, required = false, default = nil)
  if valid_603042 != nil:
    section.add "Iops", valid_603042
  var valid_603043 = formData.getOrDefault("DBName")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "DBName", valid_603043
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603044 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603044 = validateParameter(valid_603044, JString, required = true,
                                 default = nil)
  if valid_603044 != nil:
    section.add "DBInstanceIdentifier", valid_603044
  var valid_603045 = formData.getOrDefault("OptionGroupName")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "OptionGroupName", valid_603045
  var valid_603046 = formData.getOrDefault("Tags")
  valid_603046 = validateParameter(valid_603046, JArray, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "Tags", valid_603046
  var valid_603047 = formData.getOrDefault("DBSubnetGroupName")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "DBSubnetGroupName", valid_603047
  var valid_603048 = formData.getOrDefault("AvailabilityZone")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "AvailabilityZone", valid_603048
  var valid_603049 = formData.getOrDefault("MultiAZ")
  valid_603049 = validateParameter(valid_603049, JBool, required = false, default = nil)
  if valid_603049 != nil:
    section.add "MultiAZ", valid_603049
  var valid_603050 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603050 = validateParameter(valid_603050, JString, required = true,
                                 default = nil)
  if valid_603050 != nil:
    section.add "DBSnapshotIdentifier", valid_603050
  var valid_603051 = formData.getOrDefault("PubliclyAccessible")
  valid_603051 = validateParameter(valid_603051, JBool, required = false, default = nil)
  if valid_603051 != nil:
    section.add "PubliclyAccessible", valid_603051
  var valid_603052 = formData.getOrDefault("DBInstanceClass")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "DBInstanceClass", valid_603052
  var valid_603053 = formData.getOrDefault("LicenseModel")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "LicenseModel", valid_603053
  var valid_603054 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603054 = validateParameter(valid_603054, JBool, required = false, default = nil)
  if valid_603054 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603055: Call_PostRestoreDBInstanceFromDBSnapshot_603028;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603055.validator(path, query, header, formData, body)
  let scheme = call_603055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603055.url(scheme.get, call_603055.host, call_603055.base,
                         call_603055.route, valid.getOrDefault("path"))
  result = hook(call_603055, url, valid)

proc call*(call_603056: Call_PostRestoreDBInstanceFromDBSnapshot_603028;
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
  var query_603057 = newJObject()
  var formData_603058 = newJObject()
  add(formData_603058, "Port", newJInt(Port))
  add(formData_603058, "Engine", newJString(Engine))
  add(formData_603058, "Iops", newJInt(Iops))
  add(formData_603058, "DBName", newJString(DBName))
  add(formData_603058, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603058, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603058.add "Tags", Tags
  add(formData_603058, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603058, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603058, "MultiAZ", newJBool(MultiAZ))
  add(formData_603058, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603057, "Action", newJString(Action))
  add(formData_603058, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603058, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603058, "LicenseModel", newJString(LicenseModel))
  add(formData_603058, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603057, "Version", newJString(Version))
  result = call_603056.call(nil, query_603057, nil, formData_603058, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_603028(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_603029, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_603030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_602998 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceFromDBSnapshot_603000(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_602999(path: JsonNode;
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
  var valid_603001 = query.getOrDefault("Engine")
  valid_603001 = validateParameter(valid_603001, JString, required = false,
                                 default = nil)
  if valid_603001 != nil:
    section.add "Engine", valid_603001
  var valid_603002 = query.getOrDefault("OptionGroupName")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "OptionGroupName", valid_603002
  var valid_603003 = query.getOrDefault("AvailabilityZone")
  valid_603003 = validateParameter(valid_603003, JString, required = false,
                                 default = nil)
  if valid_603003 != nil:
    section.add "AvailabilityZone", valid_603003
  var valid_603004 = query.getOrDefault("Iops")
  valid_603004 = validateParameter(valid_603004, JInt, required = false, default = nil)
  if valid_603004 != nil:
    section.add "Iops", valid_603004
  var valid_603005 = query.getOrDefault("MultiAZ")
  valid_603005 = validateParameter(valid_603005, JBool, required = false, default = nil)
  if valid_603005 != nil:
    section.add "MultiAZ", valid_603005
  var valid_603006 = query.getOrDefault("LicenseModel")
  valid_603006 = validateParameter(valid_603006, JString, required = false,
                                 default = nil)
  if valid_603006 != nil:
    section.add "LicenseModel", valid_603006
  var valid_603007 = query.getOrDefault("Tags")
  valid_603007 = validateParameter(valid_603007, JArray, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "Tags", valid_603007
  var valid_603008 = query.getOrDefault("DBName")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "DBName", valid_603008
  var valid_603009 = query.getOrDefault("DBInstanceClass")
  valid_603009 = validateParameter(valid_603009, JString, required = false,
                                 default = nil)
  if valid_603009 != nil:
    section.add "DBInstanceClass", valid_603009
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603010 = query.getOrDefault("Action")
  valid_603010 = validateParameter(valid_603010, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603010 != nil:
    section.add "Action", valid_603010
  var valid_603011 = query.getOrDefault("DBSubnetGroupName")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "DBSubnetGroupName", valid_603011
  var valid_603012 = query.getOrDefault("PubliclyAccessible")
  valid_603012 = validateParameter(valid_603012, JBool, required = false, default = nil)
  if valid_603012 != nil:
    section.add "PubliclyAccessible", valid_603012
  var valid_603013 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603013 = validateParameter(valid_603013, JBool, required = false, default = nil)
  if valid_603013 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603013
  var valid_603014 = query.getOrDefault("Port")
  valid_603014 = validateParameter(valid_603014, JInt, required = false, default = nil)
  if valid_603014 != nil:
    section.add "Port", valid_603014
  var valid_603015 = query.getOrDefault("Version")
  valid_603015 = validateParameter(valid_603015, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603015 != nil:
    section.add "Version", valid_603015
  var valid_603016 = query.getOrDefault("DBInstanceIdentifier")
  valid_603016 = validateParameter(valid_603016, JString, required = true,
                                 default = nil)
  if valid_603016 != nil:
    section.add "DBInstanceIdentifier", valid_603016
  var valid_603017 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603017 = validateParameter(valid_603017, JString, required = true,
                                 default = nil)
  if valid_603017 != nil:
    section.add "DBSnapshotIdentifier", valid_603017
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603018 = header.getOrDefault("X-Amz-Date")
  valid_603018 = validateParameter(valid_603018, JString, required = false,
                                 default = nil)
  if valid_603018 != nil:
    section.add "X-Amz-Date", valid_603018
  var valid_603019 = header.getOrDefault("X-Amz-Security-Token")
  valid_603019 = validateParameter(valid_603019, JString, required = false,
                                 default = nil)
  if valid_603019 != nil:
    section.add "X-Amz-Security-Token", valid_603019
  var valid_603020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Content-Sha256", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Algorithm")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Algorithm", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-Signature")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-Signature", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-SignedHeaders", valid_603023
  var valid_603024 = header.getOrDefault("X-Amz-Credential")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Credential", valid_603024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603025: Call_GetRestoreDBInstanceFromDBSnapshot_602998;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603025.validator(path, query, header, formData, body)
  let scheme = call_603025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603025.url(scheme.get, call_603025.host, call_603025.base,
                         call_603025.route, valid.getOrDefault("path"))
  result = hook(call_603025, url, valid)

proc call*(call_603026: Call_GetRestoreDBInstanceFromDBSnapshot_602998;
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
  var query_603027 = newJObject()
  add(query_603027, "Engine", newJString(Engine))
  add(query_603027, "OptionGroupName", newJString(OptionGroupName))
  add(query_603027, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603027, "Iops", newJInt(Iops))
  add(query_603027, "MultiAZ", newJBool(MultiAZ))
  add(query_603027, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603027.add "Tags", Tags
  add(query_603027, "DBName", newJString(DBName))
  add(query_603027, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603027, "Action", newJString(Action))
  add(query_603027, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603027, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603027, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603027, "Port", newJInt(Port))
  add(query_603027, "Version", newJString(Version))
  add(query_603027, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603027, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603026.call(nil, query_603027, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_602998(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_602999, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_603000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603091 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceToPointInTime_603093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_603092(path: JsonNode;
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
  var valid_603094 = query.getOrDefault("Action")
  valid_603094 = validateParameter(valid_603094, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603094 != nil:
    section.add "Action", valid_603094
  var valid_603095 = query.getOrDefault("Version")
  valid_603095 = validateParameter(valid_603095, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603095 != nil:
    section.add "Version", valid_603095
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603096 = header.getOrDefault("X-Amz-Date")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "X-Amz-Date", valid_603096
  var valid_603097 = header.getOrDefault("X-Amz-Security-Token")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "X-Amz-Security-Token", valid_603097
  var valid_603098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "X-Amz-Content-Sha256", valid_603098
  var valid_603099 = header.getOrDefault("X-Amz-Algorithm")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Algorithm", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Signature")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Signature", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-SignedHeaders", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Credential")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Credential", valid_603102
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
  var valid_603103 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603103 = validateParameter(valid_603103, JBool, required = false, default = nil)
  if valid_603103 != nil:
    section.add "UseLatestRestorableTime", valid_603103
  var valid_603104 = formData.getOrDefault("Port")
  valid_603104 = validateParameter(valid_603104, JInt, required = false, default = nil)
  if valid_603104 != nil:
    section.add "Port", valid_603104
  var valid_603105 = formData.getOrDefault("Engine")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "Engine", valid_603105
  var valid_603106 = formData.getOrDefault("Iops")
  valid_603106 = validateParameter(valid_603106, JInt, required = false, default = nil)
  if valid_603106 != nil:
    section.add "Iops", valid_603106
  var valid_603107 = formData.getOrDefault("DBName")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "DBName", valid_603107
  var valid_603108 = formData.getOrDefault("OptionGroupName")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "OptionGroupName", valid_603108
  var valid_603109 = formData.getOrDefault("Tags")
  valid_603109 = validateParameter(valid_603109, JArray, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "Tags", valid_603109
  var valid_603110 = formData.getOrDefault("DBSubnetGroupName")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "DBSubnetGroupName", valid_603110
  var valid_603111 = formData.getOrDefault("AvailabilityZone")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "AvailabilityZone", valid_603111
  var valid_603112 = formData.getOrDefault("MultiAZ")
  valid_603112 = validateParameter(valid_603112, JBool, required = false, default = nil)
  if valid_603112 != nil:
    section.add "MultiAZ", valid_603112
  var valid_603113 = formData.getOrDefault("RestoreTime")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "RestoreTime", valid_603113
  var valid_603114 = formData.getOrDefault("PubliclyAccessible")
  valid_603114 = validateParameter(valid_603114, JBool, required = false, default = nil)
  if valid_603114 != nil:
    section.add "PubliclyAccessible", valid_603114
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603115 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603115 = validateParameter(valid_603115, JString, required = true,
                                 default = nil)
  if valid_603115 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603115
  var valid_603116 = formData.getOrDefault("DBInstanceClass")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "DBInstanceClass", valid_603116
  var valid_603117 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = nil)
  if valid_603117 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603117
  var valid_603118 = formData.getOrDefault("LicenseModel")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "LicenseModel", valid_603118
  var valid_603119 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603119 = validateParameter(valid_603119, JBool, required = false, default = nil)
  if valid_603119 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603119
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603120: Call_PostRestoreDBInstanceToPointInTime_603091;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603120.validator(path, query, header, formData, body)
  let scheme = call_603120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603120.url(scheme.get, call_603120.host, call_603120.base,
                         call_603120.route, valid.getOrDefault("path"))
  result = hook(call_603120, url, valid)

proc call*(call_603121: Call_PostRestoreDBInstanceToPointInTime_603091;
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
  var query_603122 = newJObject()
  var formData_603123 = newJObject()
  add(formData_603123, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603123, "Port", newJInt(Port))
  add(formData_603123, "Engine", newJString(Engine))
  add(formData_603123, "Iops", newJInt(Iops))
  add(formData_603123, "DBName", newJString(DBName))
  add(formData_603123, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603123.add "Tags", Tags
  add(formData_603123, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603123, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603123, "MultiAZ", newJBool(MultiAZ))
  add(query_603122, "Action", newJString(Action))
  add(formData_603123, "RestoreTime", newJString(RestoreTime))
  add(formData_603123, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603123, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_603123, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603123, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603123, "LicenseModel", newJString(LicenseModel))
  add(formData_603123, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603122, "Version", newJString(Version))
  result = call_603121.call(nil, query_603122, nil, formData_603123, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603091(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603092, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_603059 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceToPointInTime_603061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_603060(path: JsonNode;
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
  var valid_603062 = query.getOrDefault("Engine")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "Engine", valid_603062
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_603063 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603063 = validateParameter(valid_603063, JString, required = true,
                                 default = nil)
  if valid_603063 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603063
  var valid_603064 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = nil)
  if valid_603064 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603064
  var valid_603065 = query.getOrDefault("AvailabilityZone")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "AvailabilityZone", valid_603065
  var valid_603066 = query.getOrDefault("Iops")
  valid_603066 = validateParameter(valid_603066, JInt, required = false, default = nil)
  if valid_603066 != nil:
    section.add "Iops", valid_603066
  var valid_603067 = query.getOrDefault("OptionGroupName")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "OptionGroupName", valid_603067
  var valid_603068 = query.getOrDefault("RestoreTime")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "RestoreTime", valid_603068
  var valid_603069 = query.getOrDefault("MultiAZ")
  valid_603069 = validateParameter(valid_603069, JBool, required = false, default = nil)
  if valid_603069 != nil:
    section.add "MultiAZ", valid_603069
  var valid_603070 = query.getOrDefault("LicenseModel")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "LicenseModel", valid_603070
  var valid_603071 = query.getOrDefault("Tags")
  valid_603071 = validateParameter(valid_603071, JArray, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "Tags", valid_603071
  var valid_603072 = query.getOrDefault("DBName")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "DBName", valid_603072
  var valid_603073 = query.getOrDefault("DBInstanceClass")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "DBInstanceClass", valid_603073
  var valid_603074 = query.getOrDefault("Action")
  valid_603074 = validateParameter(valid_603074, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603074 != nil:
    section.add "Action", valid_603074
  var valid_603075 = query.getOrDefault("UseLatestRestorableTime")
  valid_603075 = validateParameter(valid_603075, JBool, required = false, default = nil)
  if valid_603075 != nil:
    section.add "UseLatestRestorableTime", valid_603075
  var valid_603076 = query.getOrDefault("DBSubnetGroupName")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "DBSubnetGroupName", valid_603076
  var valid_603077 = query.getOrDefault("PubliclyAccessible")
  valid_603077 = validateParameter(valid_603077, JBool, required = false, default = nil)
  if valid_603077 != nil:
    section.add "PubliclyAccessible", valid_603077
  var valid_603078 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603078 = validateParameter(valid_603078, JBool, required = false, default = nil)
  if valid_603078 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603078
  var valid_603079 = query.getOrDefault("Port")
  valid_603079 = validateParameter(valid_603079, JInt, required = false, default = nil)
  if valid_603079 != nil:
    section.add "Port", valid_603079
  var valid_603080 = query.getOrDefault("Version")
  valid_603080 = validateParameter(valid_603080, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603080 != nil:
    section.add "Version", valid_603080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603081 = header.getOrDefault("X-Amz-Date")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-Date", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Security-Token")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Security-Token", valid_603082
  var valid_603083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "X-Amz-Content-Sha256", valid_603083
  var valid_603084 = header.getOrDefault("X-Amz-Algorithm")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Algorithm", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Signature")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Signature", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-SignedHeaders", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Credential")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Credential", valid_603087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603088: Call_GetRestoreDBInstanceToPointInTime_603059;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603088.validator(path, query, header, formData, body)
  let scheme = call_603088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603088.url(scheme.get, call_603088.host, call_603088.base,
                         call_603088.route, valid.getOrDefault("path"))
  result = hook(call_603088, url, valid)

proc call*(call_603089: Call_GetRestoreDBInstanceToPointInTime_603059;
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
  var query_603090 = newJObject()
  add(query_603090, "Engine", newJString(Engine))
  add(query_603090, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603090, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603090, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603090, "Iops", newJInt(Iops))
  add(query_603090, "OptionGroupName", newJString(OptionGroupName))
  add(query_603090, "RestoreTime", newJString(RestoreTime))
  add(query_603090, "MultiAZ", newJBool(MultiAZ))
  add(query_603090, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603090.add "Tags", Tags
  add(query_603090, "DBName", newJString(DBName))
  add(query_603090, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603090, "Action", newJString(Action))
  add(query_603090, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603090, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603090, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603090, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603090, "Port", newJInt(Port))
  add(query_603090, "Version", newJString(Version))
  result = call_603089.call(nil, query_603090, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_603059(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603060, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603144 = ref object of OpenApiRestCall_600410
proc url_PostRevokeDBSecurityGroupIngress_603146(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_603145(path: JsonNode;
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
  var valid_603147 = query.getOrDefault("Action")
  valid_603147 = validateParameter(valid_603147, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603147 != nil:
    section.add "Action", valid_603147
  var valid_603148 = query.getOrDefault("Version")
  valid_603148 = validateParameter(valid_603148, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603148 != nil:
    section.add "Version", valid_603148
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603149 = header.getOrDefault("X-Amz-Date")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Date", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Security-Token")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Security-Token", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-Content-Sha256", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Algorithm")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Algorithm", valid_603152
  var valid_603153 = header.getOrDefault("X-Amz-Signature")
  valid_603153 = validateParameter(valid_603153, JString, required = false,
                                 default = nil)
  if valid_603153 != nil:
    section.add "X-Amz-Signature", valid_603153
  var valid_603154 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603154 = validateParameter(valid_603154, JString, required = false,
                                 default = nil)
  if valid_603154 != nil:
    section.add "X-Amz-SignedHeaders", valid_603154
  var valid_603155 = header.getOrDefault("X-Amz-Credential")
  valid_603155 = validateParameter(valid_603155, JString, required = false,
                                 default = nil)
  if valid_603155 != nil:
    section.add "X-Amz-Credential", valid_603155
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603156 = formData.getOrDefault("DBSecurityGroupName")
  valid_603156 = validateParameter(valid_603156, JString, required = true,
                                 default = nil)
  if valid_603156 != nil:
    section.add "DBSecurityGroupName", valid_603156
  var valid_603157 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603157 = validateParameter(valid_603157, JString, required = false,
                                 default = nil)
  if valid_603157 != nil:
    section.add "EC2SecurityGroupName", valid_603157
  var valid_603158 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603158 = validateParameter(valid_603158, JString, required = false,
                                 default = nil)
  if valid_603158 != nil:
    section.add "EC2SecurityGroupId", valid_603158
  var valid_603159 = formData.getOrDefault("CIDRIP")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "CIDRIP", valid_603159
  var valid_603160 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603161: Call_PostRevokeDBSecurityGroupIngress_603144;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603161.validator(path, query, header, formData, body)
  let scheme = call_603161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603161.url(scheme.get, call_603161.host, call_603161.base,
                         call_603161.route, valid.getOrDefault("path"))
  result = hook(call_603161, url, valid)

proc call*(call_603162: Call_PostRevokeDBSecurityGroupIngress_603144;
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
  var query_603163 = newJObject()
  var formData_603164 = newJObject()
  add(formData_603164, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603163, "Action", newJString(Action))
  add(formData_603164, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603164, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603164, "CIDRIP", newJString(CIDRIP))
  add(query_603163, "Version", newJString(Version))
  add(formData_603164, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603162.call(nil, query_603163, nil, formData_603164, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603144(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603145, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603146,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_603124 = ref object of OpenApiRestCall_600410
proc url_GetRevokeDBSecurityGroupIngress_603126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_603125(path: JsonNode;
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
  var valid_603127 = query.getOrDefault("EC2SecurityGroupId")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "EC2SecurityGroupId", valid_603127
  var valid_603128 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603128
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603129 = query.getOrDefault("DBSecurityGroupName")
  valid_603129 = validateParameter(valid_603129, JString, required = true,
                                 default = nil)
  if valid_603129 != nil:
    section.add "DBSecurityGroupName", valid_603129
  var valid_603130 = query.getOrDefault("Action")
  valid_603130 = validateParameter(valid_603130, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603130 != nil:
    section.add "Action", valid_603130
  var valid_603131 = query.getOrDefault("CIDRIP")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "CIDRIP", valid_603131
  var valid_603132 = query.getOrDefault("EC2SecurityGroupName")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "EC2SecurityGroupName", valid_603132
  var valid_603133 = query.getOrDefault("Version")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603133 != nil:
    section.add "Version", valid_603133
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603134 = header.getOrDefault("X-Amz-Date")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Date", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Security-Token")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Security-Token", valid_603135
  var valid_603136 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "X-Amz-Content-Sha256", valid_603136
  var valid_603137 = header.getOrDefault("X-Amz-Algorithm")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Algorithm", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Signature")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Signature", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-SignedHeaders", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Credential")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Credential", valid_603140
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603141: Call_GetRevokeDBSecurityGroupIngress_603124;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603141.validator(path, query, header, formData, body)
  let scheme = call_603141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603141.url(scheme.get, call_603141.host, call_603141.base,
                         call_603141.route, valid.getOrDefault("path"))
  result = hook(call_603141, url, valid)

proc call*(call_603142: Call_GetRevokeDBSecurityGroupIngress_603124;
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
  var query_603143 = newJObject()
  add(query_603143, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603143, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603143, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603143, "Action", newJString(Action))
  add(query_603143, "CIDRIP", newJString(CIDRIP))
  add(query_603143, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603143, "Version", newJString(Version))
  result = call_603142.call(nil, query_603143, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_603124(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_603125, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_603126,
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

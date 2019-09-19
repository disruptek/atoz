
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
                                 default = newJString("2014-09-01"))
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
          Version: string = "2014-09-01"): Recallable =
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
          EC2SecurityGroupName: string = ""; Version: string = "2014-09-01"): Recallable =
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
  Call_PostCopyDBParameterGroup_601137 = ref object of OpenApiRestCall_600410
proc url_PostCopyDBParameterGroup_601139(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBParameterGroup_601138(path: JsonNode; query: JsonNode;
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
  var valid_601140 = query.getOrDefault("Action")
  valid_601140 = validateParameter(valid_601140, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_601140 != nil:
    section.add "Action", valid_601140
  var valid_601141 = query.getOrDefault("Version")
  valid_601141 = validateParameter(valid_601141, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601141 != nil:
    section.add "Version", valid_601141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601142 = header.getOrDefault("X-Amz-Date")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Date", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-Security-Token")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-Security-Token", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Content-Sha256", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Algorithm")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Algorithm", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Signature")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Signature", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-SignedHeaders", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Credential")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Credential", valid_601148
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_601149 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_601149 = validateParameter(valid_601149, JString, required = true,
                                 default = nil)
  if valid_601149 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_601149
  var valid_601150 = formData.getOrDefault("Tags")
  valid_601150 = validateParameter(valid_601150, JArray, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "Tags", valid_601150
  var valid_601151 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_601151 = validateParameter(valid_601151, JString, required = true,
                                 default = nil)
  if valid_601151 != nil:
    section.add "TargetDBParameterGroupDescription", valid_601151
  var valid_601152 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_601152 = validateParameter(valid_601152, JString, required = true,
                                 default = nil)
  if valid_601152 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_601152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601153: Call_PostCopyDBParameterGroup_601137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601153.validator(path, query, header, formData, body)
  let scheme = call_601153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601153.url(scheme.get, call_601153.host, call_601153.base,
                         call_601153.route, valid.getOrDefault("path"))
  result = hook(call_601153, url, valid)

proc call*(call_601154: Call_PostCopyDBParameterGroup_601137;
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
  var query_601155 = newJObject()
  var formData_601156 = newJObject()
  add(formData_601156, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_601156.add "Tags", Tags
  add(query_601155, "Action", newJString(Action))
  add(formData_601156, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_601156, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_601155, "Version", newJString(Version))
  result = call_601154.call(nil, query_601155, nil, formData_601156, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_601137(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_601138, base: "/",
    url: url_PostCopyDBParameterGroup_601139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_601118 = ref object of OpenApiRestCall_600410
proc url_GetCopyDBParameterGroup_601120(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBParameterGroup_601119(path: JsonNode; query: JsonNode;
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
  var valid_601121 = query.getOrDefault("Tags")
  valid_601121 = validateParameter(valid_601121, JArray, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "Tags", valid_601121
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601122 = query.getOrDefault("Action")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_601122 != nil:
    section.add "Action", valid_601122
  var valid_601123 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = nil)
  if valid_601123 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_601123
  var valid_601124 = query.getOrDefault("Version")
  valid_601124 = validateParameter(valid_601124, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601124 != nil:
    section.add "Version", valid_601124
  var valid_601125 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_601125 = validateParameter(valid_601125, JString, required = true,
                                 default = nil)
  if valid_601125 != nil:
    section.add "TargetDBParameterGroupDescription", valid_601125
  var valid_601126 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_601126 = validateParameter(valid_601126, JString, required = true,
                                 default = nil)
  if valid_601126 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_601126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601127 = header.getOrDefault("X-Amz-Date")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Date", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Security-Token")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Security-Token", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-Content-Sha256", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Algorithm")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Algorithm", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Signature")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Signature", valid_601131
  var valid_601132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "X-Amz-SignedHeaders", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Credential")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Credential", valid_601133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601134: Call_GetCopyDBParameterGroup_601118; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601134.validator(path, query, header, formData, body)
  let scheme = call_601134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601134.url(scheme.get, call_601134.host, call_601134.base,
                         call_601134.route, valid.getOrDefault("path"))
  result = hook(call_601134, url, valid)

proc call*(call_601135: Call_GetCopyDBParameterGroup_601118;
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
  var query_601136 = newJObject()
  if Tags != nil:
    query_601136.add "Tags", Tags
  add(query_601136, "Action", newJString(Action))
  add(query_601136, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_601136, "Version", newJString(Version))
  add(query_601136, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_601136, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_601135.call(nil, query_601136, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_601118(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_601119, base: "/",
    url: url_GetCopyDBParameterGroup_601120, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_601175 = ref object of OpenApiRestCall_600410
proc url_PostCopyDBSnapshot_601177(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_601176(path: JsonNode; query: JsonNode;
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
  var valid_601178 = query.getOrDefault("Action")
  valid_601178 = validateParameter(valid_601178, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601178 != nil:
    section.add "Action", valid_601178
  var valid_601179 = query.getOrDefault("Version")
  valid_601179 = validateParameter(valid_601179, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601179 != nil:
    section.add "Version", valid_601179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601187 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601187 = validateParameter(valid_601187, JString, required = true,
                                 default = nil)
  if valid_601187 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601187
  var valid_601188 = formData.getOrDefault("Tags")
  valid_601188 = validateParameter(valid_601188, JArray, required = false,
                                 default = nil)
  if valid_601188 != nil:
    section.add "Tags", valid_601188
  var valid_601189 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601189 = validateParameter(valid_601189, JString, required = true,
                                 default = nil)
  if valid_601189 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601189
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601190: Call_PostCopyDBSnapshot_601175; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601190.validator(path, query, header, formData, body)
  let scheme = call_601190.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601190.url(scheme.get, call_601190.host, call_601190.base,
                         call_601190.route, valid.getOrDefault("path"))
  result = hook(call_601190, url, valid)

proc call*(call_601191: Call_PostCopyDBSnapshot_601175;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601192 = newJObject()
  var formData_601193 = newJObject()
  add(formData_601193, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_601193.add "Tags", Tags
  add(query_601192, "Action", newJString(Action))
  add(formData_601193, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601192, "Version", newJString(Version))
  result = call_601191.call(nil, query_601192, nil, formData_601193, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_601175(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_601176, base: "/",
    url: url_PostCopyDBSnapshot_601177, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_601157 = ref object of OpenApiRestCall_600410
proc url_GetCopyDBSnapshot_601159(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBSnapshot_601158(path: JsonNode; query: JsonNode;
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
  var valid_601160 = query.getOrDefault("Tags")
  valid_601160 = validateParameter(valid_601160, JArray, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "Tags", valid_601160
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_601161 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_601161 = validateParameter(valid_601161, JString, required = true,
                                 default = nil)
  if valid_601161 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_601161
  var valid_601162 = query.getOrDefault("Action")
  valid_601162 = validateParameter(valid_601162, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_601162 != nil:
    section.add "Action", valid_601162
  var valid_601163 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_601163 = validateParameter(valid_601163, JString, required = true,
                                 default = nil)
  if valid_601163 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_601163
  var valid_601164 = query.getOrDefault("Version")
  valid_601164 = validateParameter(valid_601164, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601164 != nil:
    section.add "Version", valid_601164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601165 = header.getOrDefault("X-Amz-Date")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Date", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-Security-Token")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Security-Token", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Content-Sha256", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Algorithm")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Algorithm", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Signature")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Signature", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-SignedHeaders", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-Credential")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-Credential", valid_601171
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601172: Call_GetCopyDBSnapshot_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601172.validator(path, query, header, formData, body)
  let scheme = call_601172.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601172.url(scheme.get, call_601172.host, call_601172.base,
                         call_601172.route, valid.getOrDefault("path"))
  result = hook(call_601172, url, valid)

proc call*(call_601173: Call_GetCopyDBSnapshot_601157;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_601174 = newJObject()
  if Tags != nil:
    query_601174.add "Tags", Tags
  add(query_601174, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_601174, "Action", newJString(Action))
  add(query_601174, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_601174, "Version", newJString(Version))
  result = call_601173.call(nil, query_601174, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_601157(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_601158,
    base: "/", url: url_GetCopyDBSnapshot_601159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_601213 = ref object of OpenApiRestCall_600410
proc url_PostCopyOptionGroup_601215(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyOptionGroup_601214(path: JsonNode; query: JsonNode;
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
  var valid_601216 = query.getOrDefault("Action")
  valid_601216 = validateParameter(valid_601216, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_601216 != nil:
    section.add "Action", valid_601216
  var valid_601217 = query.getOrDefault("Version")
  valid_601217 = validateParameter(valid_601217, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_601225 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_601225 = validateParameter(valid_601225, JString, required = true,
                                 default = nil)
  if valid_601225 != nil:
    section.add "TargetOptionGroupDescription", valid_601225
  var valid_601226 = formData.getOrDefault("Tags")
  valid_601226 = validateParameter(valid_601226, JArray, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "Tags", valid_601226
  var valid_601227 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = nil)
  if valid_601227 != nil:
    section.add "SourceOptionGroupIdentifier", valid_601227
  var valid_601228 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_601228 = validateParameter(valid_601228, JString, required = true,
                                 default = nil)
  if valid_601228 != nil:
    section.add "TargetOptionGroupIdentifier", valid_601228
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_PostCopyOptionGroup_601213; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_PostCopyOptionGroup_601213;
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
  var query_601231 = newJObject()
  var formData_601232 = newJObject()
  add(formData_601232, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_601232.add "Tags", Tags
  add(formData_601232, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_601231, "Action", newJString(Action))
  add(formData_601232, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_601231, "Version", newJString(Version))
  result = call_601230.call(nil, query_601231, nil, formData_601232, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_601213(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_601214, base: "/",
    url: url_PostCopyOptionGroup_601215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_601194 = ref object of OpenApiRestCall_600410
proc url_GetCopyOptionGroup_601196(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyOptionGroup_601195(path: JsonNode; query: JsonNode;
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
  var valid_601197 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_601197 = validateParameter(valid_601197, JString, required = true,
                                 default = nil)
  if valid_601197 != nil:
    section.add "SourceOptionGroupIdentifier", valid_601197
  var valid_601198 = query.getOrDefault("Tags")
  valid_601198 = validateParameter(valid_601198, JArray, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "Tags", valid_601198
  var valid_601199 = query.getOrDefault("Action")
  valid_601199 = validateParameter(valid_601199, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_601199 != nil:
    section.add "Action", valid_601199
  var valid_601200 = query.getOrDefault("TargetOptionGroupDescription")
  valid_601200 = validateParameter(valid_601200, JString, required = true,
                                 default = nil)
  if valid_601200 != nil:
    section.add "TargetOptionGroupDescription", valid_601200
  var valid_601201 = query.getOrDefault("Version")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601201 != nil:
    section.add "Version", valid_601201
  var valid_601202 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_601202 = validateParameter(valid_601202, JString, required = true,
                                 default = nil)
  if valid_601202 != nil:
    section.add "TargetOptionGroupIdentifier", valid_601202
  result.add "query", section
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

proc call*(call_601210: Call_GetCopyOptionGroup_601194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601210.validator(path, query, header, formData, body)
  let scheme = call_601210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601210.url(scheme.get, call_601210.host, call_601210.base,
                         call_601210.route, valid.getOrDefault("path"))
  result = hook(call_601210, url, valid)

proc call*(call_601211: Call_GetCopyOptionGroup_601194;
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
  var query_601212 = newJObject()
  add(query_601212, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_601212.add "Tags", Tags
  add(query_601212, "Action", newJString(Action))
  add(query_601212, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_601212, "Version", newJString(Version))
  add(query_601212, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_601211.call(nil, query_601212, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_601194(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_601195,
    base: "/", url: url_GetCopyOptionGroup_601196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_601276 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBInstance_601278(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_601277(path: JsonNode; query: JsonNode;
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
  var valid_601279 = query.getOrDefault("Action")
  valid_601279 = validateParameter(valid_601279, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601279 != nil:
    section.add "Action", valid_601279
  var valid_601280 = query.getOrDefault("Version")
  valid_601280 = validateParameter(valid_601280, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601280 != nil:
    section.add "Version", valid_601280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601281 = header.getOrDefault("X-Amz-Date")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Date", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Security-Token")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Security-Token", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
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
  var valid_601288 = formData.getOrDefault("DBSecurityGroups")
  valid_601288 = validateParameter(valid_601288, JArray, required = false,
                                 default = nil)
  if valid_601288 != nil:
    section.add "DBSecurityGroups", valid_601288
  var valid_601289 = formData.getOrDefault("Port")
  valid_601289 = validateParameter(valid_601289, JInt, required = false, default = nil)
  if valid_601289 != nil:
    section.add "Port", valid_601289
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_601290 = formData.getOrDefault("Engine")
  valid_601290 = validateParameter(valid_601290, JString, required = true,
                                 default = nil)
  if valid_601290 != nil:
    section.add "Engine", valid_601290
  var valid_601291 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_601291 = validateParameter(valid_601291, JArray, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "VpcSecurityGroupIds", valid_601291
  var valid_601292 = formData.getOrDefault("Iops")
  valid_601292 = validateParameter(valid_601292, JInt, required = false, default = nil)
  if valid_601292 != nil:
    section.add "Iops", valid_601292
  var valid_601293 = formData.getOrDefault("DBName")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "DBName", valid_601293
  var valid_601294 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601294 = validateParameter(valid_601294, JString, required = true,
                                 default = nil)
  if valid_601294 != nil:
    section.add "DBInstanceIdentifier", valid_601294
  var valid_601295 = formData.getOrDefault("BackupRetentionPeriod")
  valid_601295 = validateParameter(valid_601295, JInt, required = false, default = nil)
  if valid_601295 != nil:
    section.add "BackupRetentionPeriod", valid_601295
  var valid_601296 = formData.getOrDefault("DBParameterGroupName")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "DBParameterGroupName", valid_601296
  var valid_601297 = formData.getOrDefault("OptionGroupName")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "OptionGroupName", valid_601297
  var valid_601298 = formData.getOrDefault("Tags")
  valid_601298 = validateParameter(valid_601298, JArray, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "Tags", valid_601298
  var valid_601299 = formData.getOrDefault("MasterUserPassword")
  valid_601299 = validateParameter(valid_601299, JString, required = true,
                                 default = nil)
  if valid_601299 != nil:
    section.add "MasterUserPassword", valid_601299
  var valid_601300 = formData.getOrDefault("TdeCredentialArn")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "TdeCredentialArn", valid_601300
  var valid_601301 = formData.getOrDefault("DBSubnetGroupName")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "DBSubnetGroupName", valid_601301
  var valid_601302 = formData.getOrDefault("TdeCredentialPassword")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "TdeCredentialPassword", valid_601302
  var valid_601303 = formData.getOrDefault("AvailabilityZone")
  valid_601303 = validateParameter(valid_601303, JString, required = false,
                                 default = nil)
  if valid_601303 != nil:
    section.add "AvailabilityZone", valid_601303
  var valid_601304 = formData.getOrDefault("MultiAZ")
  valid_601304 = validateParameter(valid_601304, JBool, required = false, default = nil)
  if valid_601304 != nil:
    section.add "MultiAZ", valid_601304
  var valid_601305 = formData.getOrDefault("AllocatedStorage")
  valid_601305 = validateParameter(valid_601305, JInt, required = true, default = nil)
  if valid_601305 != nil:
    section.add "AllocatedStorage", valid_601305
  var valid_601306 = formData.getOrDefault("PubliclyAccessible")
  valid_601306 = validateParameter(valid_601306, JBool, required = false, default = nil)
  if valid_601306 != nil:
    section.add "PubliclyAccessible", valid_601306
  var valid_601307 = formData.getOrDefault("MasterUsername")
  valid_601307 = validateParameter(valid_601307, JString, required = true,
                                 default = nil)
  if valid_601307 != nil:
    section.add "MasterUsername", valid_601307
  var valid_601308 = formData.getOrDefault("StorageType")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "StorageType", valid_601308
  var valid_601309 = formData.getOrDefault("DBInstanceClass")
  valid_601309 = validateParameter(valid_601309, JString, required = true,
                                 default = nil)
  if valid_601309 != nil:
    section.add "DBInstanceClass", valid_601309
  var valid_601310 = formData.getOrDefault("CharacterSetName")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "CharacterSetName", valid_601310
  var valid_601311 = formData.getOrDefault("PreferredBackupWindow")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "PreferredBackupWindow", valid_601311
  var valid_601312 = formData.getOrDefault("LicenseModel")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "LicenseModel", valid_601312
  var valid_601313 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601313 = validateParameter(valid_601313, JBool, required = false, default = nil)
  if valid_601313 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601313
  var valid_601314 = formData.getOrDefault("EngineVersion")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "EngineVersion", valid_601314
  var valid_601315 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "PreferredMaintenanceWindow", valid_601315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601316: Call_PostCreateDBInstance_601276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601316.validator(path, query, header, formData, body)
  let scheme = call_601316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601316.url(scheme.get, call_601316.host, call_601316.base,
                         call_601316.route, valid.getOrDefault("path"))
  result = hook(call_601316, url, valid)

proc call*(call_601317: Call_PostCreateDBInstance_601276; Engine: string;
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
  var query_601318 = newJObject()
  var formData_601319 = newJObject()
  if DBSecurityGroups != nil:
    formData_601319.add "DBSecurityGroups", DBSecurityGroups
  add(formData_601319, "Port", newJInt(Port))
  add(formData_601319, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_601319.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_601319, "Iops", newJInt(Iops))
  add(formData_601319, "DBName", newJString(DBName))
  add(formData_601319, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601319, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_601319, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601319, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601319.add "Tags", Tags
  add(formData_601319, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_601319, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_601319, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601319, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_601319, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_601319, "MultiAZ", newJBool(MultiAZ))
  add(query_601318, "Action", newJString(Action))
  add(formData_601319, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_601319, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601319, "MasterUsername", newJString(MasterUsername))
  add(formData_601319, "StorageType", newJString(StorageType))
  add(formData_601319, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601319, "CharacterSetName", newJString(CharacterSetName))
  add(formData_601319, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_601319, "LicenseModel", newJString(LicenseModel))
  add(formData_601319, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_601319, "EngineVersion", newJString(EngineVersion))
  add(query_601318, "Version", newJString(Version))
  add(formData_601319, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_601317.call(nil, query_601318, nil, formData_601319, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_601276(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_601277, base: "/",
    url: url_PostCreateDBInstance_601278, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_601233 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBInstance_601235(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_601234(path: JsonNode; query: JsonNode;
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
  var valid_601236 = query.getOrDefault("Engine")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = nil)
  if valid_601236 != nil:
    section.add "Engine", valid_601236
  var valid_601237 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "PreferredMaintenanceWindow", valid_601237
  var valid_601238 = query.getOrDefault("AllocatedStorage")
  valid_601238 = validateParameter(valid_601238, JInt, required = true, default = nil)
  if valid_601238 != nil:
    section.add "AllocatedStorage", valid_601238
  var valid_601239 = query.getOrDefault("StorageType")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "StorageType", valid_601239
  var valid_601240 = query.getOrDefault("OptionGroupName")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "OptionGroupName", valid_601240
  var valid_601241 = query.getOrDefault("DBSecurityGroups")
  valid_601241 = validateParameter(valid_601241, JArray, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "DBSecurityGroups", valid_601241
  var valid_601242 = query.getOrDefault("MasterUserPassword")
  valid_601242 = validateParameter(valid_601242, JString, required = true,
                                 default = nil)
  if valid_601242 != nil:
    section.add "MasterUserPassword", valid_601242
  var valid_601243 = query.getOrDefault("AvailabilityZone")
  valid_601243 = validateParameter(valid_601243, JString, required = false,
                                 default = nil)
  if valid_601243 != nil:
    section.add "AvailabilityZone", valid_601243
  var valid_601244 = query.getOrDefault("Iops")
  valid_601244 = validateParameter(valid_601244, JInt, required = false, default = nil)
  if valid_601244 != nil:
    section.add "Iops", valid_601244
  var valid_601245 = query.getOrDefault("VpcSecurityGroupIds")
  valid_601245 = validateParameter(valid_601245, JArray, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "VpcSecurityGroupIds", valid_601245
  var valid_601246 = query.getOrDefault("MultiAZ")
  valid_601246 = validateParameter(valid_601246, JBool, required = false, default = nil)
  if valid_601246 != nil:
    section.add "MultiAZ", valid_601246
  var valid_601247 = query.getOrDefault("TdeCredentialPassword")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "TdeCredentialPassword", valid_601247
  var valid_601248 = query.getOrDefault("LicenseModel")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "LicenseModel", valid_601248
  var valid_601249 = query.getOrDefault("BackupRetentionPeriod")
  valid_601249 = validateParameter(valid_601249, JInt, required = false, default = nil)
  if valid_601249 != nil:
    section.add "BackupRetentionPeriod", valid_601249
  var valid_601250 = query.getOrDefault("DBName")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "DBName", valid_601250
  var valid_601251 = query.getOrDefault("DBParameterGroupName")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "DBParameterGroupName", valid_601251
  var valid_601252 = query.getOrDefault("Tags")
  valid_601252 = validateParameter(valid_601252, JArray, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "Tags", valid_601252
  var valid_601253 = query.getOrDefault("DBInstanceClass")
  valid_601253 = validateParameter(valid_601253, JString, required = true,
                                 default = nil)
  if valid_601253 != nil:
    section.add "DBInstanceClass", valid_601253
  var valid_601254 = query.getOrDefault("Action")
  valid_601254 = validateParameter(valid_601254, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_601254 != nil:
    section.add "Action", valid_601254
  var valid_601255 = query.getOrDefault("DBSubnetGroupName")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "DBSubnetGroupName", valid_601255
  var valid_601256 = query.getOrDefault("CharacterSetName")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "CharacterSetName", valid_601256
  var valid_601257 = query.getOrDefault("TdeCredentialArn")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "TdeCredentialArn", valid_601257
  var valid_601258 = query.getOrDefault("PubliclyAccessible")
  valid_601258 = validateParameter(valid_601258, JBool, required = false, default = nil)
  if valid_601258 != nil:
    section.add "PubliclyAccessible", valid_601258
  var valid_601259 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601259 = validateParameter(valid_601259, JBool, required = false, default = nil)
  if valid_601259 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601259
  var valid_601260 = query.getOrDefault("EngineVersion")
  valid_601260 = validateParameter(valid_601260, JString, required = false,
                                 default = nil)
  if valid_601260 != nil:
    section.add "EngineVersion", valid_601260
  var valid_601261 = query.getOrDefault("Port")
  valid_601261 = validateParameter(valid_601261, JInt, required = false, default = nil)
  if valid_601261 != nil:
    section.add "Port", valid_601261
  var valid_601262 = query.getOrDefault("PreferredBackupWindow")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "PreferredBackupWindow", valid_601262
  var valid_601263 = query.getOrDefault("Version")
  valid_601263 = validateParameter(valid_601263, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601263 != nil:
    section.add "Version", valid_601263
  var valid_601264 = query.getOrDefault("DBInstanceIdentifier")
  valid_601264 = validateParameter(valid_601264, JString, required = true,
                                 default = nil)
  if valid_601264 != nil:
    section.add "DBInstanceIdentifier", valid_601264
  var valid_601265 = query.getOrDefault("MasterUsername")
  valid_601265 = validateParameter(valid_601265, JString, required = true,
                                 default = nil)
  if valid_601265 != nil:
    section.add "MasterUsername", valid_601265
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601266 = header.getOrDefault("X-Amz-Date")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Date", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Security-Token")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Security-Token", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601273: Call_GetCreateDBInstance_601233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601273.validator(path, query, header, formData, body)
  let scheme = call_601273.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601273.url(scheme.get, call_601273.host, call_601273.base,
                         call_601273.route, valid.getOrDefault("path"))
  result = hook(call_601273, url, valid)

proc call*(call_601274: Call_GetCreateDBInstance_601233; Engine: string;
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
  var query_601275 = newJObject()
  add(query_601275, "Engine", newJString(Engine))
  add(query_601275, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_601275, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_601275, "StorageType", newJString(StorageType))
  add(query_601275, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_601275.add "DBSecurityGroups", DBSecurityGroups
  add(query_601275, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_601275, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601275, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_601275.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_601275, "MultiAZ", newJBool(MultiAZ))
  add(query_601275, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_601275, "LicenseModel", newJString(LicenseModel))
  add(query_601275, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_601275, "DBName", newJString(DBName))
  add(query_601275, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_601275.add "Tags", Tags
  add(query_601275, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601275, "Action", newJString(Action))
  add(query_601275, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601275, "CharacterSetName", newJString(CharacterSetName))
  add(query_601275, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_601275, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601275, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601275, "EngineVersion", newJString(EngineVersion))
  add(query_601275, "Port", newJInt(Port))
  add(query_601275, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_601275, "Version", newJString(Version))
  add(query_601275, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601275, "MasterUsername", newJString(MasterUsername))
  result = call_601274.call(nil, query_601275, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_601233(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_601234, base: "/",
    url: url_GetCreateDBInstance_601235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_601347 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBInstanceReadReplica_601349(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_601348(path: JsonNode;
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
  var valid_601350 = query.getOrDefault("Action")
  valid_601350 = validateParameter(valid_601350, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601350 != nil:
    section.add "Action", valid_601350
  var valid_601351 = query.getOrDefault("Version")
  valid_601351 = validateParameter(valid_601351, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601351 != nil:
    section.add "Version", valid_601351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601352 = header.getOrDefault("X-Amz-Date")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-Date", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Security-Token")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Security-Token", valid_601353
  var valid_601354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601354 = validateParameter(valid_601354, JString, required = false,
                                 default = nil)
  if valid_601354 != nil:
    section.add "X-Amz-Content-Sha256", valid_601354
  var valid_601355 = header.getOrDefault("X-Amz-Algorithm")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Algorithm", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Signature")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Signature", valid_601356
  var valid_601357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-SignedHeaders", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Credential")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Credential", valid_601358
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
  var valid_601359 = formData.getOrDefault("Port")
  valid_601359 = validateParameter(valid_601359, JInt, required = false, default = nil)
  if valid_601359 != nil:
    section.add "Port", valid_601359
  var valid_601360 = formData.getOrDefault("Iops")
  valid_601360 = validateParameter(valid_601360, JInt, required = false, default = nil)
  if valid_601360 != nil:
    section.add "Iops", valid_601360
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601361 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601361 = validateParameter(valid_601361, JString, required = true,
                                 default = nil)
  if valid_601361 != nil:
    section.add "DBInstanceIdentifier", valid_601361
  var valid_601362 = formData.getOrDefault("OptionGroupName")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "OptionGroupName", valid_601362
  var valid_601363 = formData.getOrDefault("Tags")
  valid_601363 = validateParameter(valid_601363, JArray, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "Tags", valid_601363
  var valid_601364 = formData.getOrDefault("DBSubnetGroupName")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "DBSubnetGroupName", valid_601364
  var valid_601365 = formData.getOrDefault("AvailabilityZone")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "AvailabilityZone", valid_601365
  var valid_601366 = formData.getOrDefault("PubliclyAccessible")
  valid_601366 = validateParameter(valid_601366, JBool, required = false, default = nil)
  if valid_601366 != nil:
    section.add "PubliclyAccessible", valid_601366
  var valid_601367 = formData.getOrDefault("StorageType")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "StorageType", valid_601367
  var valid_601368 = formData.getOrDefault("DBInstanceClass")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "DBInstanceClass", valid_601368
  var valid_601369 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_601369 = validateParameter(valid_601369, JString, required = true,
                                 default = nil)
  if valid_601369 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601369
  var valid_601370 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_601370 = validateParameter(valid_601370, JBool, required = false, default = nil)
  if valid_601370 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601370
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601371: Call_PostCreateDBInstanceReadReplica_601347;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_601371.validator(path, query, header, formData, body)
  let scheme = call_601371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601371.url(scheme.get, call_601371.host, call_601371.base,
                         call_601371.route, valid.getOrDefault("path"))
  result = hook(call_601371, url, valid)

proc call*(call_601372: Call_PostCreateDBInstanceReadReplica_601347;
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
  var query_601373 = newJObject()
  var formData_601374 = newJObject()
  add(formData_601374, "Port", newJInt(Port))
  add(formData_601374, "Iops", newJInt(Iops))
  add(formData_601374, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601374, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601374.add "Tags", Tags
  add(formData_601374, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_601374, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601373, "Action", newJString(Action))
  add(formData_601374, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_601374, "StorageType", newJString(StorageType))
  add(formData_601374, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_601374, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_601374, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_601373, "Version", newJString(Version))
  result = call_601372.call(nil, query_601373, nil, formData_601374, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_601347(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_601348, base: "/",
    url: url_PostCreateDBInstanceReadReplica_601349,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_601320 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBInstanceReadReplica_601322(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_601321(path: JsonNode;
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
  var valid_601323 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_601323 = validateParameter(valid_601323, JString, required = true,
                                 default = nil)
  if valid_601323 != nil:
    section.add "SourceDBInstanceIdentifier", valid_601323
  var valid_601324 = query.getOrDefault("StorageType")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "StorageType", valid_601324
  var valid_601325 = query.getOrDefault("OptionGroupName")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "OptionGroupName", valid_601325
  var valid_601326 = query.getOrDefault("AvailabilityZone")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "AvailabilityZone", valid_601326
  var valid_601327 = query.getOrDefault("Iops")
  valid_601327 = validateParameter(valid_601327, JInt, required = false, default = nil)
  if valid_601327 != nil:
    section.add "Iops", valid_601327
  var valid_601328 = query.getOrDefault("Tags")
  valid_601328 = validateParameter(valid_601328, JArray, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "Tags", valid_601328
  var valid_601329 = query.getOrDefault("DBInstanceClass")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "DBInstanceClass", valid_601329
  var valid_601330 = query.getOrDefault("Action")
  valid_601330 = validateParameter(valid_601330, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_601330 != nil:
    section.add "Action", valid_601330
  var valid_601331 = query.getOrDefault("DBSubnetGroupName")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "DBSubnetGroupName", valid_601331
  var valid_601332 = query.getOrDefault("PubliclyAccessible")
  valid_601332 = validateParameter(valid_601332, JBool, required = false, default = nil)
  if valid_601332 != nil:
    section.add "PubliclyAccessible", valid_601332
  var valid_601333 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_601333 = validateParameter(valid_601333, JBool, required = false, default = nil)
  if valid_601333 != nil:
    section.add "AutoMinorVersionUpgrade", valid_601333
  var valid_601334 = query.getOrDefault("Port")
  valid_601334 = validateParameter(valid_601334, JInt, required = false, default = nil)
  if valid_601334 != nil:
    section.add "Port", valid_601334
  var valid_601335 = query.getOrDefault("Version")
  valid_601335 = validateParameter(valid_601335, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601335 != nil:
    section.add "Version", valid_601335
  var valid_601336 = query.getOrDefault("DBInstanceIdentifier")
  valid_601336 = validateParameter(valid_601336, JString, required = true,
                                 default = nil)
  if valid_601336 != nil:
    section.add "DBInstanceIdentifier", valid_601336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601337 = header.getOrDefault("X-Amz-Date")
  valid_601337 = validateParameter(valid_601337, JString, required = false,
                                 default = nil)
  if valid_601337 != nil:
    section.add "X-Amz-Date", valid_601337
  var valid_601338 = header.getOrDefault("X-Amz-Security-Token")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "X-Amz-Security-Token", valid_601338
  var valid_601339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "X-Amz-Content-Sha256", valid_601339
  var valid_601340 = header.getOrDefault("X-Amz-Algorithm")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Algorithm", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Signature")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Signature", valid_601341
  var valid_601342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-SignedHeaders", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Credential")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Credential", valid_601343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601344: Call_GetCreateDBInstanceReadReplica_601320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601344.validator(path, query, header, formData, body)
  let scheme = call_601344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601344.url(scheme.get, call_601344.host, call_601344.base,
                         call_601344.route, valid.getOrDefault("path"))
  result = hook(call_601344, url, valid)

proc call*(call_601345: Call_GetCreateDBInstanceReadReplica_601320;
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
  var query_601346 = newJObject()
  add(query_601346, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_601346, "StorageType", newJString(StorageType))
  add(query_601346, "OptionGroupName", newJString(OptionGroupName))
  add(query_601346, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_601346, "Iops", newJInt(Iops))
  if Tags != nil:
    query_601346.add "Tags", Tags
  add(query_601346, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_601346, "Action", newJString(Action))
  add(query_601346, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601346, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_601346, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_601346, "Port", newJInt(Port))
  add(query_601346, "Version", newJString(Version))
  add(query_601346, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601345.call(nil, query_601346, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_601320(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_601321, base: "/",
    url: url_GetCreateDBInstanceReadReplica_601322,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_601394 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBParameterGroup_601396(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_601395(path: JsonNode; query: JsonNode;
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
  var valid_601397 = query.getOrDefault("Action")
  valid_601397 = validateParameter(valid_601397, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601397 != nil:
    section.add "Action", valid_601397
  var valid_601398 = query.getOrDefault("Version")
  valid_601398 = validateParameter(valid_601398, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601398 != nil:
    section.add "Version", valid_601398
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601399 = header.getOrDefault("X-Amz-Date")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Date", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Security-Token")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Security-Token", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Content-Sha256", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-Algorithm")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-Algorithm", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Signature")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Signature", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-SignedHeaders", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Credential")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Credential", valid_601405
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601406 = formData.getOrDefault("DBParameterGroupName")
  valid_601406 = validateParameter(valid_601406, JString, required = true,
                                 default = nil)
  if valid_601406 != nil:
    section.add "DBParameterGroupName", valid_601406
  var valid_601407 = formData.getOrDefault("Tags")
  valid_601407 = validateParameter(valid_601407, JArray, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "Tags", valid_601407
  var valid_601408 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601408 = validateParameter(valid_601408, JString, required = true,
                                 default = nil)
  if valid_601408 != nil:
    section.add "DBParameterGroupFamily", valid_601408
  var valid_601409 = formData.getOrDefault("Description")
  valid_601409 = validateParameter(valid_601409, JString, required = true,
                                 default = nil)
  if valid_601409 != nil:
    section.add "Description", valid_601409
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601410: Call_PostCreateDBParameterGroup_601394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601410.validator(path, query, header, formData, body)
  let scheme = call_601410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601410.url(scheme.get, call_601410.host, call_601410.base,
                         call_601410.route, valid.getOrDefault("path"))
  result = hook(call_601410, url, valid)

proc call*(call_601411: Call_PostCreateDBParameterGroup_601394;
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
  var query_601412 = newJObject()
  var formData_601413 = newJObject()
  add(formData_601413, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_601413.add "Tags", Tags
  add(query_601412, "Action", newJString(Action))
  add(formData_601413, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_601412, "Version", newJString(Version))
  add(formData_601413, "Description", newJString(Description))
  result = call_601411.call(nil, query_601412, nil, formData_601413, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_601394(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_601395, base: "/",
    url: url_PostCreateDBParameterGroup_601396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_601375 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBParameterGroup_601377(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_601376(path: JsonNode; query: JsonNode;
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
  var valid_601378 = query.getOrDefault("Description")
  valid_601378 = validateParameter(valid_601378, JString, required = true,
                                 default = nil)
  if valid_601378 != nil:
    section.add "Description", valid_601378
  var valid_601379 = query.getOrDefault("DBParameterGroupFamily")
  valid_601379 = validateParameter(valid_601379, JString, required = true,
                                 default = nil)
  if valid_601379 != nil:
    section.add "DBParameterGroupFamily", valid_601379
  var valid_601380 = query.getOrDefault("Tags")
  valid_601380 = validateParameter(valid_601380, JArray, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "Tags", valid_601380
  var valid_601381 = query.getOrDefault("DBParameterGroupName")
  valid_601381 = validateParameter(valid_601381, JString, required = true,
                                 default = nil)
  if valid_601381 != nil:
    section.add "DBParameterGroupName", valid_601381
  var valid_601382 = query.getOrDefault("Action")
  valid_601382 = validateParameter(valid_601382, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_601382 != nil:
    section.add "Action", valid_601382
  var valid_601383 = query.getOrDefault("Version")
  valid_601383 = validateParameter(valid_601383, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601383 != nil:
    section.add "Version", valid_601383
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601384 = header.getOrDefault("X-Amz-Date")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Date", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Security-Token")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Security-Token", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Content-Sha256", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-Algorithm")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-Algorithm", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Signature")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Signature", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-SignedHeaders", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Credential")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Credential", valid_601390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601391: Call_GetCreateDBParameterGroup_601375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601391.validator(path, query, header, formData, body)
  let scheme = call_601391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601391.url(scheme.get, call_601391.host, call_601391.base,
                         call_601391.route, valid.getOrDefault("path"))
  result = hook(call_601391, url, valid)

proc call*(call_601392: Call_GetCreateDBParameterGroup_601375; Description: string;
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
  var query_601393 = newJObject()
  add(query_601393, "Description", newJString(Description))
  add(query_601393, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_601393.add "Tags", Tags
  add(query_601393, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601393, "Action", newJString(Action))
  add(query_601393, "Version", newJString(Version))
  result = call_601392.call(nil, query_601393, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_601375(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_601376, base: "/",
    url: url_GetCreateDBParameterGroup_601377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_601432 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSecurityGroup_601434(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_601433(path: JsonNode; query: JsonNode;
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
  var valid_601435 = query.getOrDefault("Action")
  valid_601435 = validateParameter(valid_601435, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601435 != nil:
    section.add "Action", valid_601435
  var valid_601436 = query.getOrDefault("Version")
  valid_601436 = validateParameter(valid_601436, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601436 != nil:
    section.add "Version", valid_601436
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601437 = header.getOrDefault("X-Amz-Date")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Date", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Security-Token")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Security-Token", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Content-Sha256", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Algorithm")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Algorithm", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Signature")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Signature", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-SignedHeaders", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-Credential")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-Credential", valid_601443
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601444 = formData.getOrDefault("DBSecurityGroupName")
  valid_601444 = validateParameter(valid_601444, JString, required = true,
                                 default = nil)
  if valid_601444 != nil:
    section.add "DBSecurityGroupName", valid_601444
  var valid_601445 = formData.getOrDefault("Tags")
  valid_601445 = validateParameter(valid_601445, JArray, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "Tags", valid_601445
  var valid_601446 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_601446 = validateParameter(valid_601446, JString, required = true,
                                 default = nil)
  if valid_601446 != nil:
    section.add "DBSecurityGroupDescription", valid_601446
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601447: Call_PostCreateDBSecurityGroup_601432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601447.validator(path, query, header, formData, body)
  let scheme = call_601447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601447.url(scheme.get, call_601447.host, call_601447.base,
                         call_601447.route, valid.getOrDefault("path"))
  result = hook(call_601447, url, valid)

proc call*(call_601448: Call_PostCreateDBSecurityGroup_601432;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_601449 = newJObject()
  var formData_601450 = newJObject()
  add(formData_601450, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_601450.add "Tags", Tags
  add(query_601449, "Action", newJString(Action))
  add(formData_601450, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_601449, "Version", newJString(Version))
  result = call_601448.call(nil, query_601449, nil, formData_601450, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_601432(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_601433, base: "/",
    url: url_PostCreateDBSecurityGroup_601434,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_601414 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSecurityGroup_601416(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_601415(path: JsonNode; query: JsonNode;
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
  var valid_601417 = query.getOrDefault("DBSecurityGroupName")
  valid_601417 = validateParameter(valid_601417, JString, required = true,
                                 default = nil)
  if valid_601417 != nil:
    section.add "DBSecurityGroupName", valid_601417
  var valid_601418 = query.getOrDefault("DBSecurityGroupDescription")
  valid_601418 = validateParameter(valid_601418, JString, required = true,
                                 default = nil)
  if valid_601418 != nil:
    section.add "DBSecurityGroupDescription", valid_601418
  var valid_601419 = query.getOrDefault("Tags")
  valid_601419 = validateParameter(valid_601419, JArray, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "Tags", valid_601419
  var valid_601420 = query.getOrDefault("Action")
  valid_601420 = validateParameter(valid_601420, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_601420 != nil:
    section.add "Action", valid_601420
  var valid_601421 = query.getOrDefault("Version")
  valid_601421 = validateParameter(valid_601421, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601421 != nil:
    section.add "Version", valid_601421
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601422 = header.getOrDefault("X-Amz-Date")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Date", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Security-Token")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Security-Token", valid_601423
  var valid_601424 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601424 = validateParameter(valid_601424, JString, required = false,
                                 default = nil)
  if valid_601424 != nil:
    section.add "X-Amz-Content-Sha256", valid_601424
  var valid_601425 = header.getOrDefault("X-Amz-Algorithm")
  valid_601425 = validateParameter(valid_601425, JString, required = false,
                                 default = nil)
  if valid_601425 != nil:
    section.add "X-Amz-Algorithm", valid_601425
  var valid_601426 = header.getOrDefault("X-Amz-Signature")
  valid_601426 = validateParameter(valid_601426, JString, required = false,
                                 default = nil)
  if valid_601426 != nil:
    section.add "X-Amz-Signature", valid_601426
  var valid_601427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601427 = validateParameter(valid_601427, JString, required = false,
                                 default = nil)
  if valid_601427 != nil:
    section.add "X-Amz-SignedHeaders", valid_601427
  var valid_601428 = header.getOrDefault("X-Amz-Credential")
  valid_601428 = validateParameter(valid_601428, JString, required = false,
                                 default = nil)
  if valid_601428 != nil:
    section.add "X-Amz-Credential", valid_601428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601429: Call_GetCreateDBSecurityGroup_601414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601429.validator(path, query, header, formData, body)
  let scheme = call_601429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601429.url(scheme.get, call_601429.host, call_601429.base,
                         call_601429.route, valid.getOrDefault("path"))
  result = hook(call_601429, url, valid)

proc call*(call_601430: Call_GetCreateDBSecurityGroup_601414;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601431 = newJObject()
  add(query_601431, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601431, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_601431.add "Tags", Tags
  add(query_601431, "Action", newJString(Action))
  add(query_601431, "Version", newJString(Version))
  result = call_601430.call(nil, query_601431, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_601414(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_601415, base: "/",
    url: url_GetCreateDBSecurityGroup_601416, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_601469 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSnapshot_601471(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_601470(path: JsonNode; query: JsonNode;
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
  var valid_601472 = query.getOrDefault("Action")
  valid_601472 = validateParameter(valid_601472, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601472 != nil:
    section.add "Action", valid_601472
  var valid_601473 = query.getOrDefault("Version")
  valid_601473 = validateParameter(valid_601473, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601473 != nil:
    section.add "Version", valid_601473
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601474 = header.getOrDefault("X-Amz-Date")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-Date", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Security-Token")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Security-Token", valid_601475
  var valid_601476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601476 = validateParameter(valid_601476, JString, required = false,
                                 default = nil)
  if valid_601476 != nil:
    section.add "X-Amz-Content-Sha256", valid_601476
  var valid_601477 = header.getOrDefault("X-Amz-Algorithm")
  valid_601477 = validateParameter(valid_601477, JString, required = false,
                                 default = nil)
  if valid_601477 != nil:
    section.add "X-Amz-Algorithm", valid_601477
  var valid_601478 = header.getOrDefault("X-Amz-Signature")
  valid_601478 = validateParameter(valid_601478, JString, required = false,
                                 default = nil)
  if valid_601478 != nil:
    section.add "X-Amz-Signature", valid_601478
  var valid_601479 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601479 = validateParameter(valid_601479, JString, required = false,
                                 default = nil)
  if valid_601479 != nil:
    section.add "X-Amz-SignedHeaders", valid_601479
  var valid_601480 = header.getOrDefault("X-Amz-Credential")
  valid_601480 = validateParameter(valid_601480, JString, required = false,
                                 default = nil)
  if valid_601480 != nil:
    section.add "X-Amz-Credential", valid_601480
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601481 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601481 = validateParameter(valid_601481, JString, required = true,
                                 default = nil)
  if valid_601481 != nil:
    section.add "DBInstanceIdentifier", valid_601481
  var valid_601482 = formData.getOrDefault("Tags")
  valid_601482 = validateParameter(valid_601482, JArray, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "Tags", valid_601482
  var valid_601483 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601483 = validateParameter(valid_601483, JString, required = true,
                                 default = nil)
  if valid_601483 != nil:
    section.add "DBSnapshotIdentifier", valid_601483
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601484: Call_PostCreateDBSnapshot_601469; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601484.validator(path, query, header, formData, body)
  let scheme = call_601484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601484.url(scheme.get, call_601484.host, call_601484.base,
                         call_601484.route, valid.getOrDefault("path"))
  result = hook(call_601484, url, valid)

proc call*(call_601485: Call_PostCreateDBSnapshot_601469;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601486 = newJObject()
  var formData_601487 = newJObject()
  add(formData_601487, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_601487.add "Tags", Tags
  add(formData_601487, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601486, "Action", newJString(Action))
  add(query_601486, "Version", newJString(Version))
  result = call_601485.call(nil, query_601486, nil, formData_601487, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_601469(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_601470, base: "/",
    url: url_PostCreateDBSnapshot_601471, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_601451 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSnapshot_601453(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_601452(path: JsonNode; query: JsonNode;
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
  var valid_601454 = query.getOrDefault("Tags")
  valid_601454 = validateParameter(valid_601454, JArray, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "Tags", valid_601454
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601455 = query.getOrDefault("Action")
  valid_601455 = validateParameter(valid_601455, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_601455 != nil:
    section.add "Action", valid_601455
  var valid_601456 = query.getOrDefault("Version")
  valid_601456 = validateParameter(valid_601456, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601456 != nil:
    section.add "Version", valid_601456
  var valid_601457 = query.getOrDefault("DBInstanceIdentifier")
  valid_601457 = validateParameter(valid_601457, JString, required = true,
                                 default = nil)
  if valid_601457 != nil:
    section.add "DBInstanceIdentifier", valid_601457
  var valid_601458 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601458 = validateParameter(valid_601458, JString, required = true,
                                 default = nil)
  if valid_601458 != nil:
    section.add "DBSnapshotIdentifier", valid_601458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601459 = header.getOrDefault("X-Amz-Date")
  valid_601459 = validateParameter(valid_601459, JString, required = false,
                                 default = nil)
  if valid_601459 != nil:
    section.add "X-Amz-Date", valid_601459
  var valid_601460 = header.getOrDefault("X-Amz-Security-Token")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Security-Token", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Content-Sha256", valid_601461
  var valid_601462 = header.getOrDefault("X-Amz-Algorithm")
  valid_601462 = validateParameter(valid_601462, JString, required = false,
                                 default = nil)
  if valid_601462 != nil:
    section.add "X-Amz-Algorithm", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Signature")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Signature", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-SignedHeaders", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Credential")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Credential", valid_601465
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601466: Call_GetCreateDBSnapshot_601451; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601466.validator(path, query, header, formData, body)
  let scheme = call_601466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601466.url(scheme.get, call_601466.host, call_601466.base,
                         call_601466.route, valid.getOrDefault("path"))
  result = hook(call_601466, url, valid)

proc call*(call_601467: Call_GetCreateDBSnapshot_601451;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601468 = newJObject()
  if Tags != nil:
    query_601468.add "Tags", Tags
  add(query_601468, "Action", newJString(Action))
  add(query_601468, "Version", newJString(Version))
  add(query_601468, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601468, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601467.call(nil, query_601468, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_601451(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_601452, base: "/",
    url: url_GetCreateDBSnapshot_601453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_601507 = ref object of OpenApiRestCall_600410
proc url_PostCreateDBSubnetGroup_601509(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_601508(path: JsonNode; query: JsonNode;
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
  var valid_601510 = query.getOrDefault("Action")
  valid_601510 = validateParameter(valid_601510, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601510 != nil:
    section.add "Action", valid_601510
  var valid_601511 = query.getOrDefault("Version")
  valid_601511 = validateParameter(valid_601511, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601511 != nil:
    section.add "Version", valid_601511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601512 = header.getOrDefault("X-Amz-Date")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Date", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Security-Token")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Security-Token", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Content-Sha256", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Algorithm")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Algorithm", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Signature")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Signature", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-SignedHeaders", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Credential")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Credential", valid_601518
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_601519 = formData.getOrDefault("Tags")
  valid_601519 = validateParameter(valid_601519, JArray, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "Tags", valid_601519
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601520 = formData.getOrDefault("DBSubnetGroupName")
  valid_601520 = validateParameter(valid_601520, JString, required = true,
                                 default = nil)
  if valid_601520 != nil:
    section.add "DBSubnetGroupName", valid_601520
  var valid_601521 = formData.getOrDefault("SubnetIds")
  valid_601521 = validateParameter(valid_601521, JArray, required = true, default = nil)
  if valid_601521 != nil:
    section.add "SubnetIds", valid_601521
  var valid_601522 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_601522 = validateParameter(valid_601522, JString, required = true,
                                 default = nil)
  if valid_601522 != nil:
    section.add "DBSubnetGroupDescription", valid_601522
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601523: Call_PostCreateDBSubnetGroup_601507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601523.validator(path, query, header, formData, body)
  let scheme = call_601523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601523.url(scheme.get, call_601523.host, call_601523.base,
                         call_601523.route, valid.getOrDefault("path"))
  result = hook(call_601523, url, valid)

proc call*(call_601524: Call_PostCreateDBSubnetGroup_601507;
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
  var query_601525 = newJObject()
  var formData_601526 = newJObject()
  if Tags != nil:
    formData_601526.add "Tags", Tags
  add(formData_601526, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_601526.add "SubnetIds", SubnetIds
  add(query_601525, "Action", newJString(Action))
  add(formData_601526, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601525, "Version", newJString(Version))
  result = call_601524.call(nil, query_601525, nil, formData_601526, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_601507(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_601508, base: "/",
    url: url_PostCreateDBSubnetGroup_601509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_601488 = ref object of OpenApiRestCall_600410
proc url_GetCreateDBSubnetGroup_601490(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_601489(path: JsonNode; query: JsonNode;
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
  var valid_601491 = query.getOrDefault("Tags")
  valid_601491 = validateParameter(valid_601491, JArray, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "Tags", valid_601491
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601492 = query.getOrDefault("Action")
  valid_601492 = validateParameter(valid_601492, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_601492 != nil:
    section.add "Action", valid_601492
  var valid_601493 = query.getOrDefault("DBSubnetGroupName")
  valid_601493 = validateParameter(valid_601493, JString, required = true,
                                 default = nil)
  if valid_601493 != nil:
    section.add "DBSubnetGroupName", valid_601493
  var valid_601494 = query.getOrDefault("SubnetIds")
  valid_601494 = validateParameter(valid_601494, JArray, required = true, default = nil)
  if valid_601494 != nil:
    section.add "SubnetIds", valid_601494
  var valid_601495 = query.getOrDefault("DBSubnetGroupDescription")
  valid_601495 = validateParameter(valid_601495, JString, required = true,
                                 default = nil)
  if valid_601495 != nil:
    section.add "DBSubnetGroupDescription", valid_601495
  var valid_601496 = query.getOrDefault("Version")
  valid_601496 = validateParameter(valid_601496, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601496 != nil:
    section.add "Version", valid_601496
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601497 = header.getOrDefault("X-Amz-Date")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Date", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Security-Token")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Security-Token", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Content-Sha256", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Algorithm")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Algorithm", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Signature")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Signature", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-SignedHeaders", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Credential")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Credential", valid_601503
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601504: Call_GetCreateDBSubnetGroup_601488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601504.validator(path, query, header, formData, body)
  let scheme = call_601504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601504.url(scheme.get, call_601504.host, call_601504.base,
                         call_601504.route, valid.getOrDefault("path"))
  result = hook(call_601504, url, valid)

proc call*(call_601505: Call_GetCreateDBSubnetGroup_601488;
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
  var query_601506 = newJObject()
  if Tags != nil:
    query_601506.add "Tags", Tags
  add(query_601506, "Action", newJString(Action))
  add(query_601506, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_601506.add "SubnetIds", SubnetIds
  add(query_601506, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_601506, "Version", newJString(Version))
  result = call_601505.call(nil, query_601506, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_601488(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_601489, base: "/",
    url: url_GetCreateDBSubnetGroup_601490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_601549 = ref object of OpenApiRestCall_600410
proc url_PostCreateEventSubscription_601551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_601550(path: JsonNode; query: JsonNode;
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
  var valid_601552 = query.getOrDefault("Action")
  valid_601552 = validateParameter(valid_601552, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601552 != nil:
    section.add "Action", valid_601552
  var valid_601553 = query.getOrDefault("Version")
  valid_601553 = validateParameter(valid_601553, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601553 != nil:
    section.add "Version", valid_601553
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601554 = header.getOrDefault("X-Amz-Date")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Date", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Security-Token")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Security-Token", valid_601555
  var valid_601556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601556 = validateParameter(valid_601556, JString, required = false,
                                 default = nil)
  if valid_601556 != nil:
    section.add "X-Amz-Content-Sha256", valid_601556
  var valid_601557 = header.getOrDefault("X-Amz-Algorithm")
  valid_601557 = validateParameter(valid_601557, JString, required = false,
                                 default = nil)
  if valid_601557 != nil:
    section.add "X-Amz-Algorithm", valid_601557
  var valid_601558 = header.getOrDefault("X-Amz-Signature")
  valid_601558 = validateParameter(valid_601558, JString, required = false,
                                 default = nil)
  if valid_601558 != nil:
    section.add "X-Amz-Signature", valid_601558
  var valid_601559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601559 = validateParameter(valid_601559, JString, required = false,
                                 default = nil)
  if valid_601559 != nil:
    section.add "X-Amz-SignedHeaders", valid_601559
  var valid_601560 = header.getOrDefault("X-Amz-Credential")
  valid_601560 = validateParameter(valid_601560, JString, required = false,
                                 default = nil)
  if valid_601560 != nil:
    section.add "X-Amz-Credential", valid_601560
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
  var valid_601561 = formData.getOrDefault("Enabled")
  valid_601561 = validateParameter(valid_601561, JBool, required = false, default = nil)
  if valid_601561 != nil:
    section.add "Enabled", valid_601561
  var valid_601562 = formData.getOrDefault("EventCategories")
  valid_601562 = validateParameter(valid_601562, JArray, required = false,
                                 default = nil)
  if valid_601562 != nil:
    section.add "EventCategories", valid_601562
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_601563 = formData.getOrDefault("SnsTopicArn")
  valid_601563 = validateParameter(valid_601563, JString, required = true,
                                 default = nil)
  if valid_601563 != nil:
    section.add "SnsTopicArn", valid_601563
  var valid_601564 = formData.getOrDefault("SourceIds")
  valid_601564 = validateParameter(valid_601564, JArray, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "SourceIds", valid_601564
  var valid_601565 = formData.getOrDefault("Tags")
  valid_601565 = validateParameter(valid_601565, JArray, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "Tags", valid_601565
  var valid_601566 = formData.getOrDefault("SubscriptionName")
  valid_601566 = validateParameter(valid_601566, JString, required = true,
                                 default = nil)
  if valid_601566 != nil:
    section.add "SubscriptionName", valid_601566
  var valid_601567 = formData.getOrDefault("SourceType")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "SourceType", valid_601567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601568: Call_PostCreateEventSubscription_601549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601568.validator(path, query, header, formData, body)
  let scheme = call_601568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601568.url(scheme.get, call_601568.host, call_601568.base,
                         call_601568.route, valid.getOrDefault("path"))
  result = hook(call_601568, url, valid)

proc call*(call_601569: Call_PostCreateEventSubscription_601549;
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
  var query_601570 = newJObject()
  var formData_601571 = newJObject()
  add(formData_601571, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_601571.add "EventCategories", EventCategories
  add(formData_601571, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_601571.add "SourceIds", SourceIds
  if Tags != nil:
    formData_601571.add "Tags", Tags
  add(formData_601571, "SubscriptionName", newJString(SubscriptionName))
  add(query_601570, "Action", newJString(Action))
  add(query_601570, "Version", newJString(Version))
  add(formData_601571, "SourceType", newJString(SourceType))
  result = call_601569.call(nil, query_601570, nil, formData_601571, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_601549(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_601550, base: "/",
    url: url_PostCreateEventSubscription_601551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_601527 = ref object of OpenApiRestCall_600410
proc url_GetCreateEventSubscription_601529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_601528(path: JsonNode; query: JsonNode;
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
  var valid_601530 = query.getOrDefault("SourceType")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "SourceType", valid_601530
  var valid_601531 = query.getOrDefault("SourceIds")
  valid_601531 = validateParameter(valid_601531, JArray, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "SourceIds", valid_601531
  var valid_601532 = query.getOrDefault("Enabled")
  valid_601532 = validateParameter(valid_601532, JBool, required = false, default = nil)
  if valid_601532 != nil:
    section.add "Enabled", valid_601532
  var valid_601533 = query.getOrDefault("Tags")
  valid_601533 = validateParameter(valid_601533, JArray, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "Tags", valid_601533
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601534 = query.getOrDefault("Action")
  valid_601534 = validateParameter(valid_601534, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_601534 != nil:
    section.add "Action", valid_601534
  var valid_601535 = query.getOrDefault("SnsTopicArn")
  valid_601535 = validateParameter(valid_601535, JString, required = true,
                                 default = nil)
  if valid_601535 != nil:
    section.add "SnsTopicArn", valid_601535
  var valid_601536 = query.getOrDefault("EventCategories")
  valid_601536 = validateParameter(valid_601536, JArray, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "EventCategories", valid_601536
  var valid_601537 = query.getOrDefault("SubscriptionName")
  valid_601537 = validateParameter(valid_601537, JString, required = true,
                                 default = nil)
  if valid_601537 != nil:
    section.add "SubscriptionName", valid_601537
  var valid_601538 = query.getOrDefault("Version")
  valid_601538 = validateParameter(valid_601538, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601538 != nil:
    section.add "Version", valid_601538
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601539 = header.getOrDefault("X-Amz-Date")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Date", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Security-Token")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Security-Token", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Content-Sha256", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Algorithm")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Algorithm", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Signature")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Signature", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-SignedHeaders", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Credential")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Credential", valid_601545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601546: Call_GetCreateEventSubscription_601527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601546.validator(path, query, header, formData, body)
  let scheme = call_601546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601546.url(scheme.get, call_601546.host, call_601546.base,
                         call_601546.route, valid.getOrDefault("path"))
  result = hook(call_601546, url, valid)

proc call*(call_601547: Call_GetCreateEventSubscription_601527;
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
  var query_601548 = newJObject()
  add(query_601548, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_601548.add "SourceIds", SourceIds
  add(query_601548, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_601548.add "Tags", Tags
  add(query_601548, "Action", newJString(Action))
  add(query_601548, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_601548.add "EventCategories", EventCategories
  add(query_601548, "SubscriptionName", newJString(SubscriptionName))
  add(query_601548, "Version", newJString(Version))
  result = call_601547.call(nil, query_601548, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_601527(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_601528, base: "/",
    url: url_GetCreateEventSubscription_601529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_601592 = ref object of OpenApiRestCall_600410
proc url_PostCreateOptionGroup_601594(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_601593(path: JsonNode; query: JsonNode;
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
  var valid_601595 = query.getOrDefault("Action")
  valid_601595 = validateParameter(valid_601595, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601595 != nil:
    section.add "Action", valid_601595
  var valid_601596 = query.getOrDefault("Version")
  valid_601596 = validateParameter(valid_601596, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601596 != nil:
    section.add "Version", valid_601596
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601597 = header.getOrDefault("X-Amz-Date")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Date", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Security-Token")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Security-Token", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Content-Sha256", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Algorithm")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Algorithm", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Signature")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Signature", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-SignedHeaders", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Credential")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Credential", valid_601603
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_601604 = formData.getOrDefault("MajorEngineVersion")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = nil)
  if valid_601604 != nil:
    section.add "MajorEngineVersion", valid_601604
  var valid_601605 = formData.getOrDefault("OptionGroupName")
  valid_601605 = validateParameter(valid_601605, JString, required = true,
                                 default = nil)
  if valid_601605 != nil:
    section.add "OptionGroupName", valid_601605
  var valid_601606 = formData.getOrDefault("Tags")
  valid_601606 = validateParameter(valid_601606, JArray, required = false,
                                 default = nil)
  if valid_601606 != nil:
    section.add "Tags", valid_601606
  var valid_601607 = formData.getOrDefault("EngineName")
  valid_601607 = validateParameter(valid_601607, JString, required = true,
                                 default = nil)
  if valid_601607 != nil:
    section.add "EngineName", valid_601607
  var valid_601608 = formData.getOrDefault("OptionGroupDescription")
  valid_601608 = validateParameter(valid_601608, JString, required = true,
                                 default = nil)
  if valid_601608 != nil:
    section.add "OptionGroupDescription", valid_601608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601609: Call_PostCreateOptionGroup_601592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601609.validator(path, query, header, formData, body)
  let scheme = call_601609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601609.url(scheme.get, call_601609.host, call_601609.base,
                         call_601609.route, valid.getOrDefault("path"))
  result = hook(call_601609, url, valid)

proc call*(call_601610: Call_PostCreateOptionGroup_601592;
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
  var query_601611 = newJObject()
  var formData_601612 = newJObject()
  add(formData_601612, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_601612, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_601612.add "Tags", Tags
  add(query_601611, "Action", newJString(Action))
  add(formData_601612, "EngineName", newJString(EngineName))
  add(formData_601612, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_601611, "Version", newJString(Version))
  result = call_601610.call(nil, query_601611, nil, formData_601612, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_601592(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_601593, base: "/",
    url: url_PostCreateOptionGroup_601594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_601572 = ref object of OpenApiRestCall_600410
proc url_GetCreateOptionGroup_601574(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_601573(path: JsonNode; query: JsonNode;
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
  var valid_601575 = query.getOrDefault("OptionGroupName")
  valid_601575 = validateParameter(valid_601575, JString, required = true,
                                 default = nil)
  if valid_601575 != nil:
    section.add "OptionGroupName", valid_601575
  var valid_601576 = query.getOrDefault("Tags")
  valid_601576 = validateParameter(valid_601576, JArray, required = false,
                                 default = nil)
  if valid_601576 != nil:
    section.add "Tags", valid_601576
  var valid_601577 = query.getOrDefault("OptionGroupDescription")
  valid_601577 = validateParameter(valid_601577, JString, required = true,
                                 default = nil)
  if valid_601577 != nil:
    section.add "OptionGroupDescription", valid_601577
  var valid_601578 = query.getOrDefault("Action")
  valid_601578 = validateParameter(valid_601578, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_601578 != nil:
    section.add "Action", valid_601578
  var valid_601579 = query.getOrDefault("Version")
  valid_601579 = validateParameter(valid_601579, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601579 != nil:
    section.add "Version", valid_601579
  var valid_601580 = query.getOrDefault("EngineName")
  valid_601580 = validateParameter(valid_601580, JString, required = true,
                                 default = nil)
  if valid_601580 != nil:
    section.add "EngineName", valid_601580
  var valid_601581 = query.getOrDefault("MajorEngineVersion")
  valid_601581 = validateParameter(valid_601581, JString, required = true,
                                 default = nil)
  if valid_601581 != nil:
    section.add "MajorEngineVersion", valid_601581
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601582 = header.getOrDefault("X-Amz-Date")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Date", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Security-Token")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Security-Token", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Content-Sha256", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Algorithm")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Algorithm", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Signature")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Signature", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-SignedHeaders", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Credential")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Credential", valid_601588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601589: Call_GetCreateOptionGroup_601572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601589.validator(path, query, header, formData, body)
  let scheme = call_601589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601589.url(scheme.get, call_601589.host, call_601589.base,
                         call_601589.route, valid.getOrDefault("path"))
  result = hook(call_601589, url, valid)

proc call*(call_601590: Call_GetCreateOptionGroup_601572; OptionGroupName: string;
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
  var query_601591 = newJObject()
  add(query_601591, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_601591.add "Tags", Tags
  add(query_601591, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_601591, "Action", newJString(Action))
  add(query_601591, "Version", newJString(Version))
  add(query_601591, "EngineName", newJString(EngineName))
  add(query_601591, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_601590.call(nil, query_601591, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_601572(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_601573, base: "/",
    url: url_GetCreateOptionGroup_601574, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_601631 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBInstance_601633(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_601632(path: JsonNode; query: JsonNode;
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
  var valid_601634 = query.getOrDefault("Action")
  valid_601634 = validateParameter(valid_601634, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601634 != nil:
    section.add "Action", valid_601634
  var valid_601635 = query.getOrDefault("Version")
  valid_601635 = validateParameter(valid_601635, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601635 != nil:
    section.add "Version", valid_601635
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601643 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601643 = validateParameter(valid_601643, JString, required = true,
                                 default = nil)
  if valid_601643 != nil:
    section.add "DBInstanceIdentifier", valid_601643
  var valid_601644 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601644
  var valid_601645 = formData.getOrDefault("SkipFinalSnapshot")
  valid_601645 = validateParameter(valid_601645, JBool, required = false, default = nil)
  if valid_601645 != nil:
    section.add "SkipFinalSnapshot", valid_601645
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601646: Call_PostDeleteDBInstance_601631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601646.validator(path, query, header, formData, body)
  let scheme = call_601646.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601646.url(scheme.get, call_601646.host, call_601646.base,
                         call_601646.route, valid.getOrDefault("path"))
  result = hook(call_601646, url, valid)

proc call*(call_601647: Call_PostDeleteDBInstance_601631;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_601648 = newJObject()
  var formData_601649 = newJObject()
  add(formData_601649, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601649, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601648, "Action", newJString(Action))
  add(query_601648, "Version", newJString(Version))
  add(formData_601649, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_601647.call(nil, query_601648, nil, formData_601649, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_601631(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_601632, base: "/",
    url: url_PostDeleteDBInstance_601633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_601613 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBInstance_601615(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_601614(path: JsonNode; query: JsonNode;
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
  var valid_601616 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_601616 = validateParameter(valid_601616, JString, required = false,
                                 default = nil)
  if valid_601616 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_601616
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601617 = query.getOrDefault("Action")
  valid_601617 = validateParameter(valid_601617, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_601617 != nil:
    section.add "Action", valid_601617
  var valid_601618 = query.getOrDefault("SkipFinalSnapshot")
  valid_601618 = validateParameter(valid_601618, JBool, required = false, default = nil)
  if valid_601618 != nil:
    section.add "SkipFinalSnapshot", valid_601618
  var valid_601619 = query.getOrDefault("Version")
  valid_601619 = validateParameter(valid_601619, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601619 != nil:
    section.add "Version", valid_601619
  var valid_601620 = query.getOrDefault("DBInstanceIdentifier")
  valid_601620 = validateParameter(valid_601620, JString, required = true,
                                 default = nil)
  if valid_601620 != nil:
    section.add "DBInstanceIdentifier", valid_601620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601621 = header.getOrDefault("X-Amz-Date")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Date", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-Security-Token")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-Security-Token", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Content-Sha256", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Algorithm")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Algorithm", valid_601624
  var valid_601625 = header.getOrDefault("X-Amz-Signature")
  valid_601625 = validateParameter(valid_601625, JString, required = false,
                                 default = nil)
  if valid_601625 != nil:
    section.add "X-Amz-Signature", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-SignedHeaders", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Credential")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Credential", valid_601627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601628: Call_GetDeleteDBInstance_601613; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601628.validator(path, query, header, formData, body)
  let scheme = call_601628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601628.url(scheme.get, call_601628.host, call_601628.base,
                         call_601628.route, valid.getOrDefault("path"))
  result = hook(call_601628, url, valid)

proc call*(call_601629: Call_GetDeleteDBInstance_601613;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_601630 = newJObject()
  add(query_601630, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_601630, "Action", newJString(Action))
  add(query_601630, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_601630, "Version", newJString(Version))
  add(query_601630, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601629.call(nil, query_601630, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_601613(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_601614, base: "/",
    url: url_GetDeleteDBInstance_601615, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_601666 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBParameterGroup_601668(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_601667(path: JsonNode; query: JsonNode;
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
  var valid_601669 = query.getOrDefault("Action")
  valid_601669 = validateParameter(valid_601669, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601669 != nil:
    section.add "Action", valid_601669
  var valid_601670 = query.getOrDefault("Version")
  valid_601670 = validateParameter(valid_601670, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601670 != nil:
    section.add "Version", valid_601670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601671 = header.getOrDefault("X-Amz-Date")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Date", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Security-Token")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Security-Token", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Content-Sha256", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-Algorithm")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-Algorithm", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-Signature")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Signature", valid_601675
  var valid_601676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601676 = validateParameter(valid_601676, JString, required = false,
                                 default = nil)
  if valid_601676 != nil:
    section.add "X-Amz-SignedHeaders", valid_601676
  var valid_601677 = header.getOrDefault("X-Amz-Credential")
  valid_601677 = validateParameter(valid_601677, JString, required = false,
                                 default = nil)
  if valid_601677 != nil:
    section.add "X-Amz-Credential", valid_601677
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601678 = formData.getOrDefault("DBParameterGroupName")
  valid_601678 = validateParameter(valid_601678, JString, required = true,
                                 default = nil)
  if valid_601678 != nil:
    section.add "DBParameterGroupName", valid_601678
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601679: Call_PostDeleteDBParameterGroup_601666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601679.validator(path, query, header, formData, body)
  let scheme = call_601679.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601679.url(scheme.get, call_601679.host, call_601679.base,
                         call_601679.route, valid.getOrDefault("path"))
  result = hook(call_601679, url, valid)

proc call*(call_601680: Call_PostDeleteDBParameterGroup_601666;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601681 = newJObject()
  var formData_601682 = newJObject()
  add(formData_601682, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601681, "Action", newJString(Action))
  add(query_601681, "Version", newJString(Version))
  result = call_601680.call(nil, query_601681, nil, formData_601682, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_601666(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_601667, base: "/",
    url: url_PostDeleteDBParameterGroup_601668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_601650 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBParameterGroup_601652(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_601651(path: JsonNode; query: JsonNode;
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
  var valid_601653 = query.getOrDefault("DBParameterGroupName")
  valid_601653 = validateParameter(valid_601653, JString, required = true,
                                 default = nil)
  if valid_601653 != nil:
    section.add "DBParameterGroupName", valid_601653
  var valid_601654 = query.getOrDefault("Action")
  valid_601654 = validateParameter(valid_601654, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_601654 != nil:
    section.add "Action", valid_601654
  var valid_601655 = query.getOrDefault("Version")
  valid_601655 = validateParameter(valid_601655, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601655 != nil:
    section.add "Version", valid_601655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601656 = header.getOrDefault("X-Amz-Date")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Date", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Security-Token")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Security-Token", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Content-Sha256", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-Algorithm")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-Algorithm", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-Signature")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-Signature", valid_601660
  var valid_601661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601661 = validateParameter(valid_601661, JString, required = false,
                                 default = nil)
  if valid_601661 != nil:
    section.add "X-Amz-SignedHeaders", valid_601661
  var valid_601662 = header.getOrDefault("X-Amz-Credential")
  valid_601662 = validateParameter(valid_601662, JString, required = false,
                                 default = nil)
  if valid_601662 != nil:
    section.add "X-Amz-Credential", valid_601662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601663: Call_GetDeleteDBParameterGroup_601650; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601663.validator(path, query, header, formData, body)
  let scheme = call_601663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601663.url(scheme.get, call_601663.host, call_601663.base,
                         call_601663.route, valid.getOrDefault("path"))
  result = hook(call_601663, url, valid)

proc call*(call_601664: Call_GetDeleteDBParameterGroup_601650;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601665 = newJObject()
  add(query_601665, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601665, "Action", newJString(Action))
  add(query_601665, "Version", newJString(Version))
  result = call_601664.call(nil, query_601665, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_601650(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_601651, base: "/",
    url: url_GetDeleteDBParameterGroup_601652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_601699 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSecurityGroup_601701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_601700(path: JsonNode; query: JsonNode;
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
  var valid_601702 = query.getOrDefault("Action")
  valid_601702 = validateParameter(valid_601702, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601702 != nil:
    section.add "Action", valid_601702
  var valid_601703 = query.getOrDefault("Version")
  valid_601703 = validateParameter(valid_601703, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601703 != nil:
    section.add "Version", valid_601703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601704 = header.getOrDefault("X-Amz-Date")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Date", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Security-Token")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Security-Token", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Content-Sha256", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-Algorithm")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-Algorithm", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Signature")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Signature", valid_601708
  var valid_601709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601709 = validateParameter(valid_601709, JString, required = false,
                                 default = nil)
  if valid_601709 != nil:
    section.add "X-Amz-SignedHeaders", valid_601709
  var valid_601710 = header.getOrDefault("X-Amz-Credential")
  valid_601710 = validateParameter(valid_601710, JString, required = false,
                                 default = nil)
  if valid_601710 != nil:
    section.add "X-Amz-Credential", valid_601710
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_601711 = formData.getOrDefault("DBSecurityGroupName")
  valid_601711 = validateParameter(valid_601711, JString, required = true,
                                 default = nil)
  if valid_601711 != nil:
    section.add "DBSecurityGroupName", valid_601711
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601712: Call_PostDeleteDBSecurityGroup_601699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601712.validator(path, query, header, formData, body)
  let scheme = call_601712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601712.url(scheme.get, call_601712.host, call_601712.base,
                         call_601712.route, valid.getOrDefault("path"))
  result = hook(call_601712, url, valid)

proc call*(call_601713: Call_PostDeleteDBSecurityGroup_601699;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601714 = newJObject()
  var formData_601715 = newJObject()
  add(formData_601715, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601714, "Action", newJString(Action))
  add(query_601714, "Version", newJString(Version))
  result = call_601713.call(nil, query_601714, nil, formData_601715, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_601699(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_601700, base: "/",
    url: url_PostDeleteDBSecurityGroup_601701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_601683 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSecurityGroup_601685(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_601684(path: JsonNode; query: JsonNode;
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
  var valid_601686 = query.getOrDefault("DBSecurityGroupName")
  valid_601686 = validateParameter(valid_601686, JString, required = true,
                                 default = nil)
  if valid_601686 != nil:
    section.add "DBSecurityGroupName", valid_601686
  var valid_601687 = query.getOrDefault("Action")
  valid_601687 = validateParameter(valid_601687, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_601687 != nil:
    section.add "Action", valid_601687
  var valid_601688 = query.getOrDefault("Version")
  valid_601688 = validateParameter(valid_601688, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601688 != nil:
    section.add "Version", valid_601688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601689 = header.getOrDefault("X-Amz-Date")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Date", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Security-Token")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Security-Token", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Content-Sha256", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-Algorithm")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-Algorithm", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Signature")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Signature", valid_601693
  var valid_601694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601694 = validateParameter(valid_601694, JString, required = false,
                                 default = nil)
  if valid_601694 != nil:
    section.add "X-Amz-SignedHeaders", valid_601694
  var valid_601695 = header.getOrDefault("X-Amz-Credential")
  valid_601695 = validateParameter(valid_601695, JString, required = false,
                                 default = nil)
  if valid_601695 != nil:
    section.add "X-Amz-Credential", valid_601695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601696: Call_GetDeleteDBSecurityGroup_601683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601696.validator(path, query, header, formData, body)
  let scheme = call_601696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601696.url(scheme.get, call_601696.host, call_601696.base,
                         call_601696.route, valid.getOrDefault("path"))
  result = hook(call_601696, url, valid)

proc call*(call_601697: Call_GetDeleteDBSecurityGroup_601683;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601698 = newJObject()
  add(query_601698, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601698, "Action", newJString(Action))
  add(query_601698, "Version", newJString(Version))
  result = call_601697.call(nil, query_601698, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_601683(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_601684, base: "/",
    url: url_GetDeleteDBSecurityGroup_601685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_601732 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSnapshot_601734(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_601733(path: JsonNode; query: JsonNode;
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
  var valid_601735 = query.getOrDefault("Action")
  valid_601735 = validateParameter(valid_601735, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601735 != nil:
    section.add "Action", valid_601735
  var valid_601736 = query.getOrDefault("Version")
  valid_601736 = validateParameter(valid_601736, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601736 != nil:
    section.add "Version", valid_601736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601737 = header.getOrDefault("X-Amz-Date")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Date", valid_601737
  var valid_601738 = header.getOrDefault("X-Amz-Security-Token")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-Security-Token", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Content-Sha256", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Algorithm")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Algorithm", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Signature")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Signature", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-SignedHeaders", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Credential")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Credential", valid_601743
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_601744 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_601744 = validateParameter(valid_601744, JString, required = true,
                                 default = nil)
  if valid_601744 != nil:
    section.add "DBSnapshotIdentifier", valid_601744
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601745: Call_PostDeleteDBSnapshot_601732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601745.validator(path, query, header, formData, body)
  let scheme = call_601745.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601745.url(scheme.get, call_601745.host, call_601745.base,
                         call_601745.route, valid.getOrDefault("path"))
  result = hook(call_601745, url, valid)

proc call*(call_601746: Call_PostDeleteDBSnapshot_601732;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601747 = newJObject()
  var formData_601748 = newJObject()
  add(formData_601748, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_601747, "Action", newJString(Action))
  add(query_601747, "Version", newJString(Version))
  result = call_601746.call(nil, query_601747, nil, formData_601748, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_601732(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_601733, base: "/",
    url: url_PostDeleteDBSnapshot_601734, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_601716 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSnapshot_601718(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_601717(path: JsonNode; query: JsonNode;
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
  var valid_601719 = query.getOrDefault("Action")
  valid_601719 = validateParameter(valid_601719, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_601719 != nil:
    section.add "Action", valid_601719
  var valid_601720 = query.getOrDefault("Version")
  valid_601720 = validateParameter(valid_601720, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601720 != nil:
    section.add "Version", valid_601720
  var valid_601721 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601721 = validateParameter(valid_601721, JString, required = true,
                                 default = nil)
  if valid_601721 != nil:
    section.add "DBSnapshotIdentifier", valid_601721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601722 = header.getOrDefault("X-Amz-Date")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Date", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Security-Token")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Security-Token", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Content-Sha256", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Algorithm")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Algorithm", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Signature")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Signature", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-SignedHeaders", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Credential")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Credential", valid_601728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601729: Call_GetDeleteDBSnapshot_601716; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601729.validator(path, query, header, formData, body)
  let scheme = call_601729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601729.url(scheme.get, call_601729.host, call_601729.base,
                         call_601729.route, valid.getOrDefault("path"))
  result = hook(call_601729, url, valid)

proc call*(call_601730: Call_GetDeleteDBSnapshot_601716;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_601731 = newJObject()
  add(query_601731, "Action", newJString(Action))
  add(query_601731, "Version", newJString(Version))
  add(query_601731, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601730.call(nil, query_601731, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_601716(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_601717, base: "/",
    url: url_GetDeleteDBSnapshot_601718, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_601765 = ref object of OpenApiRestCall_600410
proc url_PostDeleteDBSubnetGroup_601767(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_601766(path: JsonNode; query: JsonNode;
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
  var valid_601768 = query.getOrDefault("Action")
  valid_601768 = validateParameter(valid_601768, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601768 != nil:
    section.add "Action", valid_601768
  var valid_601769 = query.getOrDefault("Version")
  valid_601769 = validateParameter(valid_601769, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601769 != nil:
    section.add "Version", valid_601769
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601770 = header.getOrDefault("X-Amz-Date")
  valid_601770 = validateParameter(valid_601770, JString, required = false,
                                 default = nil)
  if valid_601770 != nil:
    section.add "X-Amz-Date", valid_601770
  var valid_601771 = header.getOrDefault("X-Amz-Security-Token")
  valid_601771 = validateParameter(valid_601771, JString, required = false,
                                 default = nil)
  if valid_601771 != nil:
    section.add "X-Amz-Security-Token", valid_601771
  var valid_601772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "X-Amz-Content-Sha256", valid_601772
  var valid_601773 = header.getOrDefault("X-Amz-Algorithm")
  valid_601773 = validateParameter(valid_601773, JString, required = false,
                                 default = nil)
  if valid_601773 != nil:
    section.add "X-Amz-Algorithm", valid_601773
  var valid_601774 = header.getOrDefault("X-Amz-Signature")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Signature", valid_601774
  var valid_601775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-SignedHeaders", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Credential")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Credential", valid_601776
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_601777 = formData.getOrDefault("DBSubnetGroupName")
  valid_601777 = validateParameter(valid_601777, JString, required = true,
                                 default = nil)
  if valid_601777 != nil:
    section.add "DBSubnetGroupName", valid_601777
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601778: Call_PostDeleteDBSubnetGroup_601765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601778.validator(path, query, header, formData, body)
  let scheme = call_601778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601778.url(scheme.get, call_601778.host, call_601778.base,
                         call_601778.route, valid.getOrDefault("path"))
  result = hook(call_601778, url, valid)

proc call*(call_601779: Call_PostDeleteDBSubnetGroup_601765;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601780 = newJObject()
  var formData_601781 = newJObject()
  add(formData_601781, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601780, "Action", newJString(Action))
  add(query_601780, "Version", newJString(Version))
  result = call_601779.call(nil, query_601780, nil, formData_601781, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_601765(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_601766, base: "/",
    url: url_PostDeleteDBSubnetGroup_601767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_601749 = ref object of OpenApiRestCall_600410
proc url_GetDeleteDBSubnetGroup_601751(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_601750(path: JsonNode; query: JsonNode;
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
  var valid_601752 = query.getOrDefault("Action")
  valid_601752 = validateParameter(valid_601752, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_601752 != nil:
    section.add "Action", valid_601752
  var valid_601753 = query.getOrDefault("DBSubnetGroupName")
  valid_601753 = validateParameter(valid_601753, JString, required = true,
                                 default = nil)
  if valid_601753 != nil:
    section.add "DBSubnetGroupName", valid_601753
  var valid_601754 = query.getOrDefault("Version")
  valid_601754 = validateParameter(valid_601754, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601754 != nil:
    section.add "Version", valid_601754
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601755 = header.getOrDefault("X-Amz-Date")
  valid_601755 = validateParameter(valid_601755, JString, required = false,
                                 default = nil)
  if valid_601755 != nil:
    section.add "X-Amz-Date", valid_601755
  var valid_601756 = header.getOrDefault("X-Amz-Security-Token")
  valid_601756 = validateParameter(valid_601756, JString, required = false,
                                 default = nil)
  if valid_601756 != nil:
    section.add "X-Amz-Security-Token", valid_601756
  var valid_601757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Content-Sha256", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Algorithm")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Algorithm", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Signature")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Signature", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-SignedHeaders", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Credential")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Credential", valid_601761
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601762: Call_GetDeleteDBSubnetGroup_601749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601762.validator(path, query, header, formData, body)
  let scheme = call_601762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601762.url(scheme.get, call_601762.host, call_601762.base,
                         call_601762.route, valid.getOrDefault("path"))
  result = hook(call_601762, url, valid)

proc call*(call_601763: Call_GetDeleteDBSubnetGroup_601749;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_601764 = newJObject()
  add(query_601764, "Action", newJString(Action))
  add(query_601764, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_601764, "Version", newJString(Version))
  result = call_601763.call(nil, query_601764, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_601749(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_601750, base: "/",
    url: url_GetDeleteDBSubnetGroup_601751, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_601798 = ref object of OpenApiRestCall_600410
proc url_PostDeleteEventSubscription_601800(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_601799(path: JsonNode; query: JsonNode;
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
  var valid_601801 = query.getOrDefault("Action")
  valid_601801 = validateParameter(valid_601801, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601801 != nil:
    section.add "Action", valid_601801
  var valid_601802 = query.getOrDefault("Version")
  valid_601802 = validateParameter(valid_601802, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601802 != nil:
    section.add "Version", valid_601802
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601803 = header.getOrDefault("X-Amz-Date")
  valid_601803 = validateParameter(valid_601803, JString, required = false,
                                 default = nil)
  if valid_601803 != nil:
    section.add "X-Amz-Date", valid_601803
  var valid_601804 = header.getOrDefault("X-Amz-Security-Token")
  valid_601804 = validateParameter(valid_601804, JString, required = false,
                                 default = nil)
  if valid_601804 != nil:
    section.add "X-Amz-Security-Token", valid_601804
  var valid_601805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601805 = validateParameter(valid_601805, JString, required = false,
                                 default = nil)
  if valid_601805 != nil:
    section.add "X-Amz-Content-Sha256", valid_601805
  var valid_601806 = header.getOrDefault("X-Amz-Algorithm")
  valid_601806 = validateParameter(valid_601806, JString, required = false,
                                 default = nil)
  if valid_601806 != nil:
    section.add "X-Amz-Algorithm", valid_601806
  var valid_601807 = header.getOrDefault("X-Amz-Signature")
  valid_601807 = validateParameter(valid_601807, JString, required = false,
                                 default = nil)
  if valid_601807 != nil:
    section.add "X-Amz-Signature", valid_601807
  var valid_601808 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601808 = validateParameter(valid_601808, JString, required = false,
                                 default = nil)
  if valid_601808 != nil:
    section.add "X-Amz-SignedHeaders", valid_601808
  var valid_601809 = header.getOrDefault("X-Amz-Credential")
  valid_601809 = validateParameter(valid_601809, JString, required = false,
                                 default = nil)
  if valid_601809 != nil:
    section.add "X-Amz-Credential", valid_601809
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_601810 = formData.getOrDefault("SubscriptionName")
  valid_601810 = validateParameter(valid_601810, JString, required = true,
                                 default = nil)
  if valid_601810 != nil:
    section.add "SubscriptionName", valid_601810
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601811: Call_PostDeleteEventSubscription_601798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601811.validator(path, query, header, formData, body)
  let scheme = call_601811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601811.url(scheme.get, call_601811.host, call_601811.base,
                         call_601811.route, valid.getOrDefault("path"))
  result = hook(call_601811, url, valid)

proc call*(call_601812: Call_PostDeleteEventSubscription_601798;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601813 = newJObject()
  var formData_601814 = newJObject()
  add(formData_601814, "SubscriptionName", newJString(SubscriptionName))
  add(query_601813, "Action", newJString(Action))
  add(query_601813, "Version", newJString(Version))
  result = call_601812.call(nil, query_601813, nil, formData_601814, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_601798(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_601799, base: "/",
    url: url_PostDeleteEventSubscription_601800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_601782 = ref object of OpenApiRestCall_600410
proc url_GetDeleteEventSubscription_601784(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_601783(path: JsonNode; query: JsonNode;
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
  var valid_601785 = query.getOrDefault("Action")
  valid_601785 = validateParameter(valid_601785, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_601785 != nil:
    section.add "Action", valid_601785
  var valid_601786 = query.getOrDefault("SubscriptionName")
  valid_601786 = validateParameter(valid_601786, JString, required = true,
                                 default = nil)
  if valid_601786 != nil:
    section.add "SubscriptionName", valid_601786
  var valid_601787 = query.getOrDefault("Version")
  valid_601787 = validateParameter(valid_601787, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601787 != nil:
    section.add "Version", valid_601787
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601788 = header.getOrDefault("X-Amz-Date")
  valid_601788 = validateParameter(valid_601788, JString, required = false,
                                 default = nil)
  if valid_601788 != nil:
    section.add "X-Amz-Date", valid_601788
  var valid_601789 = header.getOrDefault("X-Amz-Security-Token")
  valid_601789 = validateParameter(valid_601789, JString, required = false,
                                 default = nil)
  if valid_601789 != nil:
    section.add "X-Amz-Security-Token", valid_601789
  var valid_601790 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601790 = validateParameter(valid_601790, JString, required = false,
                                 default = nil)
  if valid_601790 != nil:
    section.add "X-Amz-Content-Sha256", valid_601790
  var valid_601791 = header.getOrDefault("X-Amz-Algorithm")
  valid_601791 = validateParameter(valid_601791, JString, required = false,
                                 default = nil)
  if valid_601791 != nil:
    section.add "X-Amz-Algorithm", valid_601791
  var valid_601792 = header.getOrDefault("X-Amz-Signature")
  valid_601792 = validateParameter(valid_601792, JString, required = false,
                                 default = nil)
  if valid_601792 != nil:
    section.add "X-Amz-Signature", valid_601792
  var valid_601793 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601793 = validateParameter(valid_601793, JString, required = false,
                                 default = nil)
  if valid_601793 != nil:
    section.add "X-Amz-SignedHeaders", valid_601793
  var valid_601794 = header.getOrDefault("X-Amz-Credential")
  valid_601794 = validateParameter(valid_601794, JString, required = false,
                                 default = nil)
  if valid_601794 != nil:
    section.add "X-Amz-Credential", valid_601794
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601795: Call_GetDeleteEventSubscription_601782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601795.validator(path, query, header, formData, body)
  let scheme = call_601795.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601795.url(scheme.get, call_601795.host, call_601795.base,
                         call_601795.route, valid.getOrDefault("path"))
  result = hook(call_601795, url, valid)

proc call*(call_601796: Call_GetDeleteEventSubscription_601782;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_601797 = newJObject()
  add(query_601797, "Action", newJString(Action))
  add(query_601797, "SubscriptionName", newJString(SubscriptionName))
  add(query_601797, "Version", newJString(Version))
  result = call_601796.call(nil, query_601797, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_601782(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_601783, base: "/",
    url: url_GetDeleteEventSubscription_601784,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_601831 = ref object of OpenApiRestCall_600410
proc url_PostDeleteOptionGroup_601833(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_601832(path: JsonNode; query: JsonNode;
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
  var valid_601834 = query.getOrDefault("Action")
  valid_601834 = validateParameter(valid_601834, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601834 != nil:
    section.add "Action", valid_601834
  var valid_601835 = query.getOrDefault("Version")
  valid_601835 = validateParameter(valid_601835, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601835 != nil:
    section.add "Version", valid_601835
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601836 = header.getOrDefault("X-Amz-Date")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Date", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Security-Token")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Security-Token", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Content-Sha256", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Algorithm")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Algorithm", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-Signature")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-Signature", valid_601840
  var valid_601841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "X-Amz-SignedHeaders", valid_601841
  var valid_601842 = header.getOrDefault("X-Amz-Credential")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "X-Amz-Credential", valid_601842
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_601843 = formData.getOrDefault("OptionGroupName")
  valid_601843 = validateParameter(valid_601843, JString, required = true,
                                 default = nil)
  if valid_601843 != nil:
    section.add "OptionGroupName", valid_601843
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601844: Call_PostDeleteOptionGroup_601831; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601844.validator(path, query, header, formData, body)
  let scheme = call_601844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601844.url(scheme.get, call_601844.host, call_601844.base,
                         call_601844.route, valid.getOrDefault("path"))
  result = hook(call_601844, url, valid)

proc call*(call_601845: Call_PostDeleteOptionGroup_601831; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601846 = newJObject()
  var formData_601847 = newJObject()
  add(formData_601847, "OptionGroupName", newJString(OptionGroupName))
  add(query_601846, "Action", newJString(Action))
  add(query_601846, "Version", newJString(Version))
  result = call_601845.call(nil, query_601846, nil, formData_601847, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_601831(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_601832, base: "/",
    url: url_PostDeleteOptionGroup_601833, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_601815 = ref object of OpenApiRestCall_600410
proc url_GetDeleteOptionGroup_601817(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_601816(path: JsonNode; query: JsonNode;
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
  var valid_601818 = query.getOrDefault("OptionGroupName")
  valid_601818 = validateParameter(valid_601818, JString, required = true,
                                 default = nil)
  if valid_601818 != nil:
    section.add "OptionGroupName", valid_601818
  var valid_601819 = query.getOrDefault("Action")
  valid_601819 = validateParameter(valid_601819, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_601819 != nil:
    section.add "Action", valid_601819
  var valid_601820 = query.getOrDefault("Version")
  valid_601820 = validateParameter(valid_601820, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601820 != nil:
    section.add "Version", valid_601820
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601821 = header.getOrDefault("X-Amz-Date")
  valid_601821 = validateParameter(valid_601821, JString, required = false,
                                 default = nil)
  if valid_601821 != nil:
    section.add "X-Amz-Date", valid_601821
  var valid_601822 = header.getOrDefault("X-Amz-Security-Token")
  valid_601822 = validateParameter(valid_601822, JString, required = false,
                                 default = nil)
  if valid_601822 != nil:
    section.add "X-Amz-Security-Token", valid_601822
  var valid_601823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601823 = validateParameter(valid_601823, JString, required = false,
                                 default = nil)
  if valid_601823 != nil:
    section.add "X-Amz-Content-Sha256", valid_601823
  var valid_601824 = header.getOrDefault("X-Amz-Algorithm")
  valid_601824 = validateParameter(valid_601824, JString, required = false,
                                 default = nil)
  if valid_601824 != nil:
    section.add "X-Amz-Algorithm", valid_601824
  var valid_601825 = header.getOrDefault("X-Amz-Signature")
  valid_601825 = validateParameter(valid_601825, JString, required = false,
                                 default = nil)
  if valid_601825 != nil:
    section.add "X-Amz-Signature", valid_601825
  var valid_601826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601826 = validateParameter(valid_601826, JString, required = false,
                                 default = nil)
  if valid_601826 != nil:
    section.add "X-Amz-SignedHeaders", valid_601826
  var valid_601827 = header.getOrDefault("X-Amz-Credential")
  valid_601827 = validateParameter(valid_601827, JString, required = false,
                                 default = nil)
  if valid_601827 != nil:
    section.add "X-Amz-Credential", valid_601827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601828: Call_GetDeleteOptionGroup_601815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601828.validator(path, query, header, formData, body)
  let scheme = call_601828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601828.url(scheme.get, call_601828.host, call_601828.base,
                         call_601828.route, valid.getOrDefault("path"))
  result = hook(call_601828, url, valid)

proc call*(call_601829: Call_GetDeleteOptionGroup_601815; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601830 = newJObject()
  add(query_601830, "OptionGroupName", newJString(OptionGroupName))
  add(query_601830, "Action", newJString(Action))
  add(query_601830, "Version", newJString(Version))
  result = call_601829.call(nil, query_601830, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_601815(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_601816, base: "/",
    url: url_GetDeleteOptionGroup_601817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_601871 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBEngineVersions_601873(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_601872(path: JsonNode; query: JsonNode;
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
  var valid_601874 = query.getOrDefault("Action")
  valid_601874 = validateParameter(valid_601874, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601874 != nil:
    section.add "Action", valid_601874
  var valid_601875 = query.getOrDefault("Version")
  valid_601875 = validateParameter(valid_601875, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601875 != nil:
    section.add "Version", valid_601875
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601876 = header.getOrDefault("X-Amz-Date")
  valid_601876 = validateParameter(valid_601876, JString, required = false,
                                 default = nil)
  if valid_601876 != nil:
    section.add "X-Amz-Date", valid_601876
  var valid_601877 = header.getOrDefault("X-Amz-Security-Token")
  valid_601877 = validateParameter(valid_601877, JString, required = false,
                                 default = nil)
  if valid_601877 != nil:
    section.add "X-Amz-Security-Token", valid_601877
  var valid_601878 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601878 = validateParameter(valid_601878, JString, required = false,
                                 default = nil)
  if valid_601878 != nil:
    section.add "X-Amz-Content-Sha256", valid_601878
  var valid_601879 = header.getOrDefault("X-Amz-Algorithm")
  valid_601879 = validateParameter(valid_601879, JString, required = false,
                                 default = nil)
  if valid_601879 != nil:
    section.add "X-Amz-Algorithm", valid_601879
  var valid_601880 = header.getOrDefault("X-Amz-Signature")
  valid_601880 = validateParameter(valid_601880, JString, required = false,
                                 default = nil)
  if valid_601880 != nil:
    section.add "X-Amz-Signature", valid_601880
  var valid_601881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601881 = validateParameter(valid_601881, JString, required = false,
                                 default = nil)
  if valid_601881 != nil:
    section.add "X-Amz-SignedHeaders", valid_601881
  var valid_601882 = header.getOrDefault("X-Amz-Credential")
  valid_601882 = validateParameter(valid_601882, JString, required = false,
                                 default = nil)
  if valid_601882 != nil:
    section.add "X-Amz-Credential", valid_601882
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
  var valid_601883 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_601883 = validateParameter(valid_601883, JBool, required = false, default = nil)
  if valid_601883 != nil:
    section.add "ListSupportedCharacterSets", valid_601883
  var valid_601884 = formData.getOrDefault("Engine")
  valid_601884 = validateParameter(valid_601884, JString, required = false,
                                 default = nil)
  if valid_601884 != nil:
    section.add "Engine", valid_601884
  var valid_601885 = formData.getOrDefault("Marker")
  valid_601885 = validateParameter(valid_601885, JString, required = false,
                                 default = nil)
  if valid_601885 != nil:
    section.add "Marker", valid_601885
  var valid_601886 = formData.getOrDefault("DBParameterGroupFamily")
  valid_601886 = validateParameter(valid_601886, JString, required = false,
                                 default = nil)
  if valid_601886 != nil:
    section.add "DBParameterGroupFamily", valid_601886
  var valid_601887 = formData.getOrDefault("Filters")
  valid_601887 = validateParameter(valid_601887, JArray, required = false,
                                 default = nil)
  if valid_601887 != nil:
    section.add "Filters", valid_601887
  var valid_601888 = formData.getOrDefault("MaxRecords")
  valid_601888 = validateParameter(valid_601888, JInt, required = false, default = nil)
  if valid_601888 != nil:
    section.add "MaxRecords", valid_601888
  var valid_601889 = formData.getOrDefault("EngineVersion")
  valid_601889 = validateParameter(valid_601889, JString, required = false,
                                 default = nil)
  if valid_601889 != nil:
    section.add "EngineVersion", valid_601889
  var valid_601890 = formData.getOrDefault("DefaultOnly")
  valid_601890 = validateParameter(valid_601890, JBool, required = false, default = nil)
  if valid_601890 != nil:
    section.add "DefaultOnly", valid_601890
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601891: Call_PostDescribeDBEngineVersions_601871; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601891.validator(path, query, header, formData, body)
  let scheme = call_601891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601891.url(scheme.get, call_601891.host, call_601891.base,
                         call_601891.route, valid.getOrDefault("path"))
  result = hook(call_601891, url, valid)

proc call*(call_601892: Call_PostDescribeDBEngineVersions_601871;
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
  var query_601893 = newJObject()
  var formData_601894 = newJObject()
  add(formData_601894, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_601894, "Engine", newJString(Engine))
  add(formData_601894, "Marker", newJString(Marker))
  add(query_601893, "Action", newJString(Action))
  add(formData_601894, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_601894.add "Filters", Filters
  add(formData_601894, "MaxRecords", newJInt(MaxRecords))
  add(formData_601894, "EngineVersion", newJString(EngineVersion))
  add(query_601893, "Version", newJString(Version))
  add(formData_601894, "DefaultOnly", newJBool(DefaultOnly))
  result = call_601892.call(nil, query_601893, nil, formData_601894, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_601871(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_601872, base: "/",
    url: url_PostDescribeDBEngineVersions_601873,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_601848 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBEngineVersions_601850(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_601849(path: JsonNode; query: JsonNode;
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
  var valid_601851 = query.getOrDefault("Engine")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "Engine", valid_601851
  var valid_601852 = query.getOrDefault("ListSupportedCharacterSets")
  valid_601852 = validateParameter(valid_601852, JBool, required = false, default = nil)
  if valid_601852 != nil:
    section.add "ListSupportedCharacterSets", valid_601852
  var valid_601853 = query.getOrDefault("MaxRecords")
  valid_601853 = validateParameter(valid_601853, JInt, required = false, default = nil)
  if valid_601853 != nil:
    section.add "MaxRecords", valid_601853
  var valid_601854 = query.getOrDefault("DBParameterGroupFamily")
  valid_601854 = validateParameter(valid_601854, JString, required = false,
                                 default = nil)
  if valid_601854 != nil:
    section.add "DBParameterGroupFamily", valid_601854
  var valid_601855 = query.getOrDefault("Filters")
  valid_601855 = validateParameter(valid_601855, JArray, required = false,
                                 default = nil)
  if valid_601855 != nil:
    section.add "Filters", valid_601855
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601856 = query.getOrDefault("Action")
  valid_601856 = validateParameter(valid_601856, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_601856 != nil:
    section.add "Action", valid_601856
  var valid_601857 = query.getOrDefault("Marker")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "Marker", valid_601857
  var valid_601858 = query.getOrDefault("EngineVersion")
  valid_601858 = validateParameter(valid_601858, JString, required = false,
                                 default = nil)
  if valid_601858 != nil:
    section.add "EngineVersion", valid_601858
  var valid_601859 = query.getOrDefault("DefaultOnly")
  valid_601859 = validateParameter(valid_601859, JBool, required = false, default = nil)
  if valid_601859 != nil:
    section.add "DefaultOnly", valid_601859
  var valid_601860 = query.getOrDefault("Version")
  valid_601860 = validateParameter(valid_601860, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601860 != nil:
    section.add "Version", valid_601860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601861 = header.getOrDefault("X-Amz-Date")
  valid_601861 = validateParameter(valid_601861, JString, required = false,
                                 default = nil)
  if valid_601861 != nil:
    section.add "X-Amz-Date", valid_601861
  var valid_601862 = header.getOrDefault("X-Amz-Security-Token")
  valid_601862 = validateParameter(valid_601862, JString, required = false,
                                 default = nil)
  if valid_601862 != nil:
    section.add "X-Amz-Security-Token", valid_601862
  var valid_601863 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601863 = validateParameter(valid_601863, JString, required = false,
                                 default = nil)
  if valid_601863 != nil:
    section.add "X-Amz-Content-Sha256", valid_601863
  var valid_601864 = header.getOrDefault("X-Amz-Algorithm")
  valid_601864 = validateParameter(valid_601864, JString, required = false,
                                 default = nil)
  if valid_601864 != nil:
    section.add "X-Amz-Algorithm", valid_601864
  var valid_601865 = header.getOrDefault("X-Amz-Signature")
  valid_601865 = validateParameter(valid_601865, JString, required = false,
                                 default = nil)
  if valid_601865 != nil:
    section.add "X-Amz-Signature", valid_601865
  var valid_601866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601866 = validateParameter(valid_601866, JString, required = false,
                                 default = nil)
  if valid_601866 != nil:
    section.add "X-Amz-SignedHeaders", valid_601866
  var valid_601867 = header.getOrDefault("X-Amz-Credential")
  valid_601867 = validateParameter(valid_601867, JString, required = false,
                                 default = nil)
  if valid_601867 != nil:
    section.add "X-Amz-Credential", valid_601867
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601868: Call_GetDescribeDBEngineVersions_601848; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601868.validator(path, query, header, formData, body)
  let scheme = call_601868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601868.url(scheme.get, call_601868.host, call_601868.base,
                         call_601868.route, valid.getOrDefault("path"))
  result = hook(call_601868, url, valid)

proc call*(call_601869: Call_GetDescribeDBEngineVersions_601848;
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
  var query_601870 = newJObject()
  add(query_601870, "Engine", newJString(Engine))
  add(query_601870, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_601870, "MaxRecords", newJInt(MaxRecords))
  add(query_601870, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_601870.add "Filters", Filters
  add(query_601870, "Action", newJString(Action))
  add(query_601870, "Marker", newJString(Marker))
  add(query_601870, "EngineVersion", newJString(EngineVersion))
  add(query_601870, "DefaultOnly", newJBool(DefaultOnly))
  add(query_601870, "Version", newJString(Version))
  result = call_601869.call(nil, query_601870, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_601848(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_601849, base: "/",
    url: url_GetDescribeDBEngineVersions_601850,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_601914 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBInstances_601916(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_601915(path: JsonNode; query: JsonNode;
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
  var valid_601917 = query.getOrDefault("Action")
  valid_601917 = validateParameter(valid_601917, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601917 != nil:
    section.add "Action", valid_601917
  var valid_601918 = query.getOrDefault("Version")
  valid_601918 = validateParameter(valid_601918, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601918 != nil:
    section.add "Version", valid_601918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601919 = header.getOrDefault("X-Amz-Date")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Date", valid_601919
  var valid_601920 = header.getOrDefault("X-Amz-Security-Token")
  valid_601920 = validateParameter(valid_601920, JString, required = false,
                                 default = nil)
  if valid_601920 != nil:
    section.add "X-Amz-Security-Token", valid_601920
  var valid_601921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601921 = validateParameter(valid_601921, JString, required = false,
                                 default = nil)
  if valid_601921 != nil:
    section.add "X-Amz-Content-Sha256", valid_601921
  var valid_601922 = header.getOrDefault("X-Amz-Algorithm")
  valid_601922 = validateParameter(valid_601922, JString, required = false,
                                 default = nil)
  if valid_601922 != nil:
    section.add "X-Amz-Algorithm", valid_601922
  var valid_601923 = header.getOrDefault("X-Amz-Signature")
  valid_601923 = validateParameter(valid_601923, JString, required = false,
                                 default = nil)
  if valid_601923 != nil:
    section.add "X-Amz-Signature", valid_601923
  var valid_601924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601924 = validateParameter(valid_601924, JString, required = false,
                                 default = nil)
  if valid_601924 != nil:
    section.add "X-Amz-SignedHeaders", valid_601924
  var valid_601925 = header.getOrDefault("X-Amz-Credential")
  valid_601925 = validateParameter(valid_601925, JString, required = false,
                                 default = nil)
  if valid_601925 != nil:
    section.add "X-Amz-Credential", valid_601925
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601926 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601926 = validateParameter(valid_601926, JString, required = false,
                                 default = nil)
  if valid_601926 != nil:
    section.add "DBInstanceIdentifier", valid_601926
  var valid_601927 = formData.getOrDefault("Marker")
  valid_601927 = validateParameter(valid_601927, JString, required = false,
                                 default = nil)
  if valid_601927 != nil:
    section.add "Marker", valid_601927
  var valid_601928 = formData.getOrDefault("Filters")
  valid_601928 = validateParameter(valid_601928, JArray, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "Filters", valid_601928
  var valid_601929 = formData.getOrDefault("MaxRecords")
  valid_601929 = validateParameter(valid_601929, JInt, required = false, default = nil)
  if valid_601929 != nil:
    section.add "MaxRecords", valid_601929
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601930: Call_PostDescribeDBInstances_601914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601930.validator(path, query, header, formData, body)
  let scheme = call_601930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601930.url(scheme.get, call_601930.host, call_601930.base,
                         call_601930.route, valid.getOrDefault("path"))
  result = hook(call_601930, url, valid)

proc call*(call_601931: Call_PostDescribeDBInstances_601914;
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
  var query_601932 = newJObject()
  var formData_601933 = newJObject()
  add(formData_601933, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601933, "Marker", newJString(Marker))
  add(query_601932, "Action", newJString(Action))
  if Filters != nil:
    formData_601933.add "Filters", Filters
  add(formData_601933, "MaxRecords", newJInt(MaxRecords))
  add(query_601932, "Version", newJString(Version))
  result = call_601931.call(nil, query_601932, nil, formData_601933, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_601914(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_601915, base: "/",
    url: url_PostDescribeDBInstances_601916, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_601895 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBInstances_601897(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_601896(path: JsonNode; query: JsonNode;
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
  var valid_601898 = query.getOrDefault("MaxRecords")
  valid_601898 = validateParameter(valid_601898, JInt, required = false, default = nil)
  if valid_601898 != nil:
    section.add "MaxRecords", valid_601898
  var valid_601899 = query.getOrDefault("Filters")
  valid_601899 = validateParameter(valid_601899, JArray, required = false,
                                 default = nil)
  if valid_601899 != nil:
    section.add "Filters", valid_601899
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601900 = query.getOrDefault("Action")
  valid_601900 = validateParameter(valid_601900, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_601900 != nil:
    section.add "Action", valid_601900
  var valid_601901 = query.getOrDefault("Marker")
  valid_601901 = validateParameter(valid_601901, JString, required = false,
                                 default = nil)
  if valid_601901 != nil:
    section.add "Marker", valid_601901
  var valid_601902 = query.getOrDefault("Version")
  valid_601902 = validateParameter(valid_601902, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601902 != nil:
    section.add "Version", valid_601902
  var valid_601903 = query.getOrDefault("DBInstanceIdentifier")
  valid_601903 = validateParameter(valid_601903, JString, required = false,
                                 default = nil)
  if valid_601903 != nil:
    section.add "DBInstanceIdentifier", valid_601903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601904 = header.getOrDefault("X-Amz-Date")
  valid_601904 = validateParameter(valid_601904, JString, required = false,
                                 default = nil)
  if valid_601904 != nil:
    section.add "X-Amz-Date", valid_601904
  var valid_601905 = header.getOrDefault("X-Amz-Security-Token")
  valid_601905 = validateParameter(valid_601905, JString, required = false,
                                 default = nil)
  if valid_601905 != nil:
    section.add "X-Amz-Security-Token", valid_601905
  var valid_601906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601906 = validateParameter(valid_601906, JString, required = false,
                                 default = nil)
  if valid_601906 != nil:
    section.add "X-Amz-Content-Sha256", valid_601906
  var valid_601907 = header.getOrDefault("X-Amz-Algorithm")
  valid_601907 = validateParameter(valid_601907, JString, required = false,
                                 default = nil)
  if valid_601907 != nil:
    section.add "X-Amz-Algorithm", valid_601907
  var valid_601908 = header.getOrDefault("X-Amz-Signature")
  valid_601908 = validateParameter(valid_601908, JString, required = false,
                                 default = nil)
  if valid_601908 != nil:
    section.add "X-Amz-Signature", valid_601908
  var valid_601909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601909 = validateParameter(valid_601909, JString, required = false,
                                 default = nil)
  if valid_601909 != nil:
    section.add "X-Amz-SignedHeaders", valid_601909
  var valid_601910 = header.getOrDefault("X-Amz-Credential")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "X-Amz-Credential", valid_601910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601911: Call_GetDescribeDBInstances_601895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601911.validator(path, query, header, formData, body)
  let scheme = call_601911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601911.url(scheme.get, call_601911.host, call_601911.base,
                         call_601911.route, valid.getOrDefault("path"))
  result = hook(call_601911, url, valid)

proc call*(call_601912: Call_GetDescribeDBInstances_601895; MaxRecords: int = 0;
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
  var query_601913 = newJObject()
  add(query_601913, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601913.add "Filters", Filters
  add(query_601913, "Action", newJString(Action))
  add(query_601913, "Marker", newJString(Marker))
  add(query_601913, "Version", newJString(Version))
  add(query_601913, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601912.call(nil, query_601913, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_601895(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_601896, base: "/",
    url: url_GetDescribeDBInstances_601897, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_601956 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBLogFiles_601958(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_601957(path: JsonNode; query: JsonNode;
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
  var valid_601959 = query.getOrDefault("Action")
  valid_601959 = validateParameter(valid_601959, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601959 != nil:
    section.add "Action", valid_601959
  var valid_601960 = query.getOrDefault("Version")
  valid_601960 = validateParameter(valid_601960, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601960 != nil:
    section.add "Version", valid_601960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601961 = header.getOrDefault("X-Amz-Date")
  valid_601961 = validateParameter(valid_601961, JString, required = false,
                                 default = nil)
  if valid_601961 != nil:
    section.add "X-Amz-Date", valid_601961
  var valid_601962 = header.getOrDefault("X-Amz-Security-Token")
  valid_601962 = validateParameter(valid_601962, JString, required = false,
                                 default = nil)
  if valid_601962 != nil:
    section.add "X-Amz-Security-Token", valid_601962
  var valid_601963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601963 = validateParameter(valid_601963, JString, required = false,
                                 default = nil)
  if valid_601963 != nil:
    section.add "X-Amz-Content-Sha256", valid_601963
  var valid_601964 = header.getOrDefault("X-Amz-Algorithm")
  valid_601964 = validateParameter(valid_601964, JString, required = false,
                                 default = nil)
  if valid_601964 != nil:
    section.add "X-Amz-Algorithm", valid_601964
  var valid_601965 = header.getOrDefault("X-Amz-Signature")
  valid_601965 = validateParameter(valid_601965, JString, required = false,
                                 default = nil)
  if valid_601965 != nil:
    section.add "X-Amz-Signature", valid_601965
  var valid_601966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-SignedHeaders", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Credential")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Credential", valid_601967
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
  var valid_601968 = formData.getOrDefault("FilenameContains")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "FilenameContains", valid_601968
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601969 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601969 = validateParameter(valid_601969, JString, required = true,
                                 default = nil)
  if valid_601969 != nil:
    section.add "DBInstanceIdentifier", valid_601969
  var valid_601970 = formData.getOrDefault("FileSize")
  valid_601970 = validateParameter(valid_601970, JInt, required = false, default = nil)
  if valid_601970 != nil:
    section.add "FileSize", valid_601970
  var valid_601971 = formData.getOrDefault("Marker")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "Marker", valid_601971
  var valid_601972 = formData.getOrDefault("Filters")
  valid_601972 = validateParameter(valid_601972, JArray, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "Filters", valid_601972
  var valid_601973 = formData.getOrDefault("MaxRecords")
  valid_601973 = validateParameter(valid_601973, JInt, required = false, default = nil)
  if valid_601973 != nil:
    section.add "MaxRecords", valid_601973
  var valid_601974 = formData.getOrDefault("FileLastWritten")
  valid_601974 = validateParameter(valid_601974, JInt, required = false, default = nil)
  if valid_601974 != nil:
    section.add "FileLastWritten", valid_601974
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601975: Call_PostDescribeDBLogFiles_601956; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601975.validator(path, query, header, formData, body)
  let scheme = call_601975.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601975.url(scheme.get, call_601975.host, call_601975.base,
                         call_601975.route, valid.getOrDefault("path"))
  result = hook(call_601975, url, valid)

proc call*(call_601976: Call_PostDescribeDBLogFiles_601956;
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
  var query_601977 = newJObject()
  var formData_601978 = newJObject()
  add(formData_601978, "FilenameContains", newJString(FilenameContains))
  add(formData_601978, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601978, "FileSize", newJInt(FileSize))
  add(formData_601978, "Marker", newJString(Marker))
  add(query_601977, "Action", newJString(Action))
  if Filters != nil:
    formData_601978.add "Filters", Filters
  add(formData_601978, "MaxRecords", newJInt(MaxRecords))
  add(formData_601978, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601977, "Version", newJString(Version))
  result = call_601976.call(nil, query_601977, nil, formData_601978, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_601956(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_601957, base: "/",
    url: url_PostDescribeDBLogFiles_601958, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_601934 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBLogFiles_601936(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_601935(path: JsonNode; query: JsonNode;
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
  var valid_601937 = query.getOrDefault("FileLastWritten")
  valid_601937 = validateParameter(valid_601937, JInt, required = false, default = nil)
  if valid_601937 != nil:
    section.add "FileLastWritten", valid_601937
  var valid_601938 = query.getOrDefault("MaxRecords")
  valid_601938 = validateParameter(valid_601938, JInt, required = false, default = nil)
  if valid_601938 != nil:
    section.add "MaxRecords", valid_601938
  var valid_601939 = query.getOrDefault("FilenameContains")
  valid_601939 = validateParameter(valid_601939, JString, required = false,
                                 default = nil)
  if valid_601939 != nil:
    section.add "FilenameContains", valid_601939
  var valid_601940 = query.getOrDefault("FileSize")
  valid_601940 = validateParameter(valid_601940, JInt, required = false, default = nil)
  if valid_601940 != nil:
    section.add "FileSize", valid_601940
  var valid_601941 = query.getOrDefault("Filters")
  valid_601941 = validateParameter(valid_601941, JArray, required = false,
                                 default = nil)
  if valid_601941 != nil:
    section.add "Filters", valid_601941
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601942 = query.getOrDefault("Action")
  valid_601942 = validateParameter(valid_601942, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601942 != nil:
    section.add "Action", valid_601942
  var valid_601943 = query.getOrDefault("Marker")
  valid_601943 = validateParameter(valid_601943, JString, required = false,
                                 default = nil)
  if valid_601943 != nil:
    section.add "Marker", valid_601943
  var valid_601944 = query.getOrDefault("Version")
  valid_601944 = validateParameter(valid_601944, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601944 != nil:
    section.add "Version", valid_601944
  var valid_601945 = query.getOrDefault("DBInstanceIdentifier")
  valid_601945 = validateParameter(valid_601945, JString, required = true,
                                 default = nil)
  if valid_601945 != nil:
    section.add "DBInstanceIdentifier", valid_601945
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601946 = header.getOrDefault("X-Amz-Date")
  valid_601946 = validateParameter(valid_601946, JString, required = false,
                                 default = nil)
  if valid_601946 != nil:
    section.add "X-Amz-Date", valid_601946
  var valid_601947 = header.getOrDefault("X-Amz-Security-Token")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "X-Amz-Security-Token", valid_601947
  var valid_601948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601948 = validateParameter(valid_601948, JString, required = false,
                                 default = nil)
  if valid_601948 != nil:
    section.add "X-Amz-Content-Sha256", valid_601948
  var valid_601949 = header.getOrDefault("X-Amz-Algorithm")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "X-Amz-Algorithm", valid_601949
  var valid_601950 = header.getOrDefault("X-Amz-Signature")
  valid_601950 = validateParameter(valid_601950, JString, required = false,
                                 default = nil)
  if valid_601950 != nil:
    section.add "X-Amz-Signature", valid_601950
  var valid_601951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-SignedHeaders", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Credential")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Credential", valid_601952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601953: Call_GetDescribeDBLogFiles_601934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601953.validator(path, query, header, formData, body)
  let scheme = call_601953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601953.url(scheme.get, call_601953.host, call_601953.base,
                         call_601953.route, valid.getOrDefault("path"))
  result = hook(call_601953, url, valid)

proc call*(call_601954: Call_GetDescribeDBLogFiles_601934;
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
  var query_601955 = newJObject()
  add(query_601955, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601955, "MaxRecords", newJInt(MaxRecords))
  add(query_601955, "FilenameContains", newJString(FilenameContains))
  add(query_601955, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_601955.add "Filters", Filters
  add(query_601955, "Action", newJString(Action))
  add(query_601955, "Marker", newJString(Marker))
  add(query_601955, "Version", newJString(Version))
  add(query_601955, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601954.call(nil, query_601955, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_601934(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_601935, base: "/",
    url: url_GetDescribeDBLogFiles_601936, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_601998 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameterGroups_602000(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_601999(path: JsonNode; query: JsonNode;
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
  var valid_602001 = query.getOrDefault("Action")
  valid_602001 = validateParameter(valid_602001, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_602001 != nil:
    section.add "Action", valid_602001
  var valid_602002 = query.getOrDefault("Version")
  valid_602002 = validateParameter(valid_602002, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602002 != nil:
    section.add "Version", valid_602002
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602003 = header.getOrDefault("X-Amz-Date")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "X-Amz-Date", valid_602003
  var valid_602004 = header.getOrDefault("X-Amz-Security-Token")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "X-Amz-Security-Token", valid_602004
  var valid_602005 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Content-Sha256", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Algorithm")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Algorithm", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Signature")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Signature", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-SignedHeaders", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Credential")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Credential", valid_602009
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602010 = formData.getOrDefault("DBParameterGroupName")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "DBParameterGroupName", valid_602010
  var valid_602011 = formData.getOrDefault("Marker")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "Marker", valid_602011
  var valid_602012 = formData.getOrDefault("Filters")
  valid_602012 = validateParameter(valid_602012, JArray, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "Filters", valid_602012
  var valid_602013 = formData.getOrDefault("MaxRecords")
  valid_602013 = validateParameter(valid_602013, JInt, required = false, default = nil)
  if valid_602013 != nil:
    section.add "MaxRecords", valid_602013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_PostDescribeDBParameterGroups_601998; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"))
  result = hook(call_602014, url, valid)

proc call*(call_602015: Call_PostDescribeDBParameterGroups_601998;
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
  var query_602016 = newJObject()
  var formData_602017 = newJObject()
  add(formData_602017, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602017, "Marker", newJString(Marker))
  add(query_602016, "Action", newJString(Action))
  if Filters != nil:
    formData_602017.add "Filters", Filters
  add(formData_602017, "MaxRecords", newJInt(MaxRecords))
  add(query_602016, "Version", newJString(Version))
  result = call_602015.call(nil, query_602016, nil, formData_602017, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_601998(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_601999, base: "/",
    url: url_PostDescribeDBParameterGroups_602000,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_601979 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameterGroups_601981(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_601980(path: JsonNode; query: JsonNode;
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
  var valid_601982 = query.getOrDefault("MaxRecords")
  valid_601982 = validateParameter(valid_601982, JInt, required = false, default = nil)
  if valid_601982 != nil:
    section.add "MaxRecords", valid_601982
  var valid_601983 = query.getOrDefault("Filters")
  valid_601983 = validateParameter(valid_601983, JArray, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "Filters", valid_601983
  var valid_601984 = query.getOrDefault("DBParameterGroupName")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "DBParameterGroupName", valid_601984
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601985 = query.getOrDefault("Action")
  valid_601985 = validateParameter(valid_601985, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601985 != nil:
    section.add "Action", valid_601985
  var valid_601986 = query.getOrDefault("Marker")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "Marker", valid_601986
  var valid_601987 = query.getOrDefault("Version")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_601987 != nil:
    section.add "Version", valid_601987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601988 = header.getOrDefault("X-Amz-Date")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "X-Amz-Date", valid_601988
  var valid_601989 = header.getOrDefault("X-Amz-Security-Token")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Security-Token", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Algorithm")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Algorithm", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Signature")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Signature", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-SignedHeaders", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Credential")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Credential", valid_601994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601995: Call_GetDescribeDBParameterGroups_601979; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601995.validator(path, query, header, formData, body)
  let scheme = call_601995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601995.url(scheme.get, call_601995.host, call_601995.base,
                         call_601995.route, valid.getOrDefault("path"))
  result = hook(call_601995, url, valid)

proc call*(call_601996: Call_GetDescribeDBParameterGroups_601979;
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
  var query_601997 = newJObject()
  add(query_601997, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_601997.add "Filters", Filters
  add(query_601997, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601997, "Action", newJString(Action))
  add(query_601997, "Marker", newJString(Marker))
  add(query_601997, "Version", newJString(Version))
  result = call_601996.call(nil, query_601997, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_601979(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_601980, base: "/",
    url: url_GetDescribeDBParameterGroups_601981,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_602038 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameters_602040(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_602039(path: JsonNode; query: JsonNode;
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
  var valid_602041 = query.getOrDefault("Action")
  valid_602041 = validateParameter(valid_602041, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602041 != nil:
    section.add "Action", valid_602041
  var valid_602042 = query.getOrDefault("Version")
  valid_602042 = validateParameter(valid_602042, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602042 != nil:
    section.add "Version", valid_602042
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602043 = header.getOrDefault("X-Amz-Date")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Date", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Security-Token")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Security-Token", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Content-Sha256", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Algorithm")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Algorithm", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Signature")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Signature", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-SignedHeaders", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-Credential")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-Credential", valid_602049
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602050 = formData.getOrDefault("DBParameterGroupName")
  valid_602050 = validateParameter(valid_602050, JString, required = true,
                                 default = nil)
  if valid_602050 != nil:
    section.add "DBParameterGroupName", valid_602050
  var valid_602051 = formData.getOrDefault("Marker")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "Marker", valid_602051
  var valid_602052 = formData.getOrDefault("Filters")
  valid_602052 = validateParameter(valid_602052, JArray, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "Filters", valid_602052
  var valid_602053 = formData.getOrDefault("MaxRecords")
  valid_602053 = validateParameter(valid_602053, JInt, required = false, default = nil)
  if valid_602053 != nil:
    section.add "MaxRecords", valid_602053
  var valid_602054 = formData.getOrDefault("Source")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "Source", valid_602054
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602055: Call_PostDescribeDBParameters_602038; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602055.validator(path, query, header, formData, body)
  let scheme = call_602055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602055.url(scheme.get, call_602055.host, call_602055.base,
                         call_602055.route, valid.getOrDefault("path"))
  result = hook(call_602055, url, valid)

proc call*(call_602056: Call_PostDescribeDBParameters_602038;
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
  var query_602057 = newJObject()
  var formData_602058 = newJObject()
  add(formData_602058, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602058, "Marker", newJString(Marker))
  add(query_602057, "Action", newJString(Action))
  if Filters != nil:
    formData_602058.add "Filters", Filters
  add(formData_602058, "MaxRecords", newJInt(MaxRecords))
  add(query_602057, "Version", newJString(Version))
  add(formData_602058, "Source", newJString(Source))
  result = call_602056.call(nil, query_602057, nil, formData_602058, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_602038(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_602039, base: "/",
    url: url_PostDescribeDBParameters_602040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_602018 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameters_602020(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_602019(path: JsonNode; query: JsonNode;
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
  var valid_602021 = query.getOrDefault("MaxRecords")
  valid_602021 = validateParameter(valid_602021, JInt, required = false, default = nil)
  if valid_602021 != nil:
    section.add "MaxRecords", valid_602021
  var valid_602022 = query.getOrDefault("Filters")
  valid_602022 = validateParameter(valid_602022, JArray, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "Filters", valid_602022
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_602023 = query.getOrDefault("DBParameterGroupName")
  valid_602023 = validateParameter(valid_602023, JString, required = true,
                                 default = nil)
  if valid_602023 != nil:
    section.add "DBParameterGroupName", valid_602023
  var valid_602024 = query.getOrDefault("Action")
  valid_602024 = validateParameter(valid_602024, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_602024 != nil:
    section.add "Action", valid_602024
  var valid_602025 = query.getOrDefault("Marker")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "Marker", valid_602025
  var valid_602026 = query.getOrDefault("Source")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "Source", valid_602026
  var valid_602027 = query.getOrDefault("Version")
  valid_602027 = validateParameter(valid_602027, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602027 != nil:
    section.add "Version", valid_602027
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602028 = header.getOrDefault("X-Amz-Date")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Date", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-Security-Token")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Security-Token", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Content-Sha256", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Algorithm")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Algorithm", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Signature")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Signature", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-SignedHeaders", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-Credential")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-Credential", valid_602034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602035: Call_GetDescribeDBParameters_602018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602035.validator(path, query, header, formData, body)
  let scheme = call_602035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602035.url(scheme.get, call_602035.host, call_602035.base,
                         call_602035.route, valid.getOrDefault("path"))
  result = hook(call_602035, url, valid)

proc call*(call_602036: Call_GetDescribeDBParameters_602018;
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
  var query_602037 = newJObject()
  add(query_602037, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602037.add "Filters", Filters
  add(query_602037, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602037, "Action", newJString(Action))
  add(query_602037, "Marker", newJString(Marker))
  add(query_602037, "Source", newJString(Source))
  add(query_602037, "Version", newJString(Version))
  result = call_602036.call(nil, query_602037, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_602018(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_602019, base: "/",
    url: url_GetDescribeDBParameters_602020, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_602078 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSecurityGroups_602080(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_602079(path: JsonNode; query: JsonNode;
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
  var valid_602081 = query.getOrDefault("Action")
  valid_602081 = validateParameter(valid_602081, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602081 != nil:
    section.add "Action", valid_602081
  var valid_602082 = query.getOrDefault("Version")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602082 != nil:
    section.add "Version", valid_602082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602083 = header.getOrDefault("X-Amz-Date")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Date", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Security-Token")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Security-Token", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Content-Sha256", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Algorithm")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Algorithm", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Signature")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Signature", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-SignedHeaders", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-Credential")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-Credential", valid_602089
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602090 = formData.getOrDefault("DBSecurityGroupName")
  valid_602090 = validateParameter(valid_602090, JString, required = false,
                                 default = nil)
  if valid_602090 != nil:
    section.add "DBSecurityGroupName", valid_602090
  var valid_602091 = formData.getOrDefault("Marker")
  valid_602091 = validateParameter(valid_602091, JString, required = false,
                                 default = nil)
  if valid_602091 != nil:
    section.add "Marker", valid_602091
  var valid_602092 = formData.getOrDefault("Filters")
  valid_602092 = validateParameter(valid_602092, JArray, required = false,
                                 default = nil)
  if valid_602092 != nil:
    section.add "Filters", valid_602092
  var valid_602093 = formData.getOrDefault("MaxRecords")
  valid_602093 = validateParameter(valid_602093, JInt, required = false, default = nil)
  if valid_602093 != nil:
    section.add "MaxRecords", valid_602093
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602094: Call_PostDescribeDBSecurityGroups_602078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602094.validator(path, query, header, formData, body)
  let scheme = call_602094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602094.url(scheme.get, call_602094.host, call_602094.base,
                         call_602094.route, valid.getOrDefault("path"))
  result = hook(call_602094, url, valid)

proc call*(call_602095: Call_PostDescribeDBSecurityGroups_602078;
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
  var query_602096 = newJObject()
  var formData_602097 = newJObject()
  add(formData_602097, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_602097, "Marker", newJString(Marker))
  add(query_602096, "Action", newJString(Action))
  if Filters != nil:
    formData_602097.add "Filters", Filters
  add(formData_602097, "MaxRecords", newJInt(MaxRecords))
  add(query_602096, "Version", newJString(Version))
  result = call_602095.call(nil, query_602096, nil, formData_602097, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_602078(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_602079, base: "/",
    url: url_PostDescribeDBSecurityGroups_602080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_602059 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSecurityGroups_602061(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_602060(path: JsonNode; query: JsonNode;
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
  var valid_602062 = query.getOrDefault("MaxRecords")
  valid_602062 = validateParameter(valid_602062, JInt, required = false, default = nil)
  if valid_602062 != nil:
    section.add "MaxRecords", valid_602062
  var valid_602063 = query.getOrDefault("DBSecurityGroupName")
  valid_602063 = validateParameter(valid_602063, JString, required = false,
                                 default = nil)
  if valid_602063 != nil:
    section.add "DBSecurityGroupName", valid_602063
  var valid_602064 = query.getOrDefault("Filters")
  valid_602064 = validateParameter(valid_602064, JArray, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "Filters", valid_602064
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602065 = query.getOrDefault("Action")
  valid_602065 = validateParameter(valid_602065, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_602065 != nil:
    section.add "Action", valid_602065
  var valid_602066 = query.getOrDefault("Marker")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "Marker", valid_602066
  var valid_602067 = query.getOrDefault("Version")
  valid_602067 = validateParameter(valid_602067, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602067 != nil:
    section.add "Version", valid_602067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602068 = header.getOrDefault("X-Amz-Date")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Date", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Security-Token")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Security-Token", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Content-Sha256", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-Algorithm")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-Algorithm", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Signature")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Signature", valid_602072
  var valid_602073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602073 = validateParameter(valid_602073, JString, required = false,
                                 default = nil)
  if valid_602073 != nil:
    section.add "X-Amz-SignedHeaders", valid_602073
  var valid_602074 = header.getOrDefault("X-Amz-Credential")
  valid_602074 = validateParameter(valid_602074, JString, required = false,
                                 default = nil)
  if valid_602074 != nil:
    section.add "X-Amz-Credential", valid_602074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602075: Call_GetDescribeDBSecurityGroups_602059; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602075.validator(path, query, header, formData, body)
  let scheme = call_602075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602075.url(scheme.get, call_602075.host, call_602075.base,
                         call_602075.route, valid.getOrDefault("path"))
  result = hook(call_602075, url, valid)

proc call*(call_602076: Call_GetDescribeDBSecurityGroups_602059;
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
  var query_602077 = newJObject()
  add(query_602077, "MaxRecords", newJInt(MaxRecords))
  add(query_602077, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_602077.add "Filters", Filters
  add(query_602077, "Action", newJString(Action))
  add(query_602077, "Marker", newJString(Marker))
  add(query_602077, "Version", newJString(Version))
  result = call_602076.call(nil, query_602077, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_602059(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_602060, base: "/",
    url: url_GetDescribeDBSecurityGroups_602061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602119 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSnapshots_602121(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_602120(path: JsonNode; query: JsonNode;
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
  var valid_602122 = query.getOrDefault("Action")
  valid_602122 = validateParameter(valid_602122, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602122 != nil:
    section.add "Action", valid_602122
  var valid_602123 = query.getOrDefault("Version")
  valid_602123 = validateParameter(valid_602123, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602123 != nil:
    section.add "Version", valid_602123
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602124 = header.getOrDefault("X-Amz-Date")
  valid_602124 = validateParameter(valid_602124, JString, required = false,
                                 default = nil)
  if valid_602124 != nil:
    section.add "X-Amz-Date", valid_602124
  var valid_602125 = header.getOrDefault("X-Amz-Security-Token")
  valid_602125 = validateParameter(valid_602125, JString, required = false,
                                 default = nil)
  if valid_602125 != nil:
    section.add "X-Amz-Security-Token", valid_602125
  var valid_602126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602126 = validateParameter(valid_602126, JString, required = false,
                                 default = nil)
  if valid_602126 != nil:
    section.add "X-Amz-Content-Sha256", valid_602126
  var valid_602127 = header.getOrDefault("X-Amz-Algorithm")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Algorithm", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Signature")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Signature", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-SignedHeaders", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602131 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "DBInstanceIdentifier", valid_602131
  var valid_602132 = formData.getOrDefault("SnapshotType")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "SnapshotType", valid_602132
  var valid_602133 = formData.getOrDefault("Marker")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "Marker", valid_602133
  var valid_602134 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "DBSnapshotIdentifier", valid_602134
  var valid_602135 = formData.getOrDefault("Filters")
  valid_602135 = validateParameter(valid_602135, JArray, required = false,
                                 default = nil)
  if valid_602135 != nil:
    section.add "Filters", valid_602135
  var valid_602136 = formData.getOrDefault("MaxRecords")
  valid_602136 = validateParameter(valid_602136, JInt, required = false, default = nil)
  if valid_602136 != nil:
    section.add "MaxRecords", valid_602136
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602137: Call_PostDescribeDBSnapshots_602119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602137.validator(path, query, header, formData, body)
  let scheme = call_602137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602137.url(scheme.get, call_602137.host, call_602137.base,
                         call_602137.route, valid.getOrDefault("path"))
  result = hook(call_602137, url, valid)

proc call*(call_602138: Call_PostDescribeDBSnapshots_602119;
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
  var query_602139 = newJObject()
  var formData_602140 = newJObject()
  add(formData_602140, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602140, "SnapshotType", newJString(SnapshotType))
  add(formData_602140, "Marker", newJString(Marker))
  add(formData_602140, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602139, "Action", newJString(Action))
  if Filters != nil:
    formData_602140.add "Filters", Filters
  add(formData_602140, "MaxRecords", newJInt(MaxRecords))
  add(query_602139, "Version", newJString(Version))
  result = call_602138.call(nil, query_602139, nil, formData_602140, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602119(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602120, base: "/",
    url: url_PostDescribeDBSnapshots_602121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_602098 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSnapshots_602100(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_602099(path: JsonNode; query: JsonNode;
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
  var valid_602101 = query.getOrDefault("MaxRecords")
  valid_602101 = validateParameter(valid_602101, JInt, required = false, default = nil)
  if valid_602101 != nil:
    section.add "MaxRecords", valid_602101
  var valid_602102 = query.getOrDefault("Filters")
  valid_602102 = validateParameter(valid_602102, JArray, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "Filters", valid_602102
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602103 = query.getOrDefault("Action")
  valid_602103 = validateParameter(valid_602103, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602103 != nil:
    section.add "Action", valid_602103
  var valid_602104 = query.getOrDefault("Marker")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "Marker", valid_602104
  var valid_602105 = query.getOrDefault("SnapshotType")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "SnapshotType", valid_602105
  var valid_602106 = query.getOrDefault("Version")
  valid_602106 = validateParameter(valid_602106, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602106 != nil:
    section.add "Version", valid_602106
  var valid_602107 = query.getOrDefault("DBInstanceIdentifier")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "DBInstanceIdentifier", valid_602107
  var valid_602108 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602108 = validateParameter(valid_602108, JString, required = false,
                                 default = nil)
  if valid_602108 != nil:
    section.add "DBSnapshotIdentifier", valid_602108
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602109 = header.getOrDefault("X-Amz-Date")
  valid_602109 = validateParameter(valid_602109, JString, required = false,
                                 default = nil)
  if valid_602109 != nil:
    section.add "X-Amz-Date", valid_602109
  var valid_602110 = header.getOrDefault("X-Amz-Security-Token")
  valid_602110 = validateParameter(valid_602110, JString, required = false,
                                 default = nil)
  if valid_602110 != nil:
    section.add "X-Amz-Security-Token", valid_602110
  var valid_602111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602111 = validateParameter(valid_602111, JString, required = false,
                                 default = nil)
  if valid_602111 != nil:
    section.add "X-Amz-Content-Sha256", valid_602111
  var valid_602112 = header.getOrDefault("X-Amz-Algorithm")
  valid_602112 = validateParameter(valid_602112, JString, required = false,
                                 default = nil)
  if valid_602112 != nil:
    section.add "X-Amz-Algorithm", valid_602112
  var valid_602113 = header.getOrDefault("X-Amz-Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Signature", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-SignedHeaders", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Credential")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Credential", valid_602115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602116: Call_GetDescribeDBSnapshots_602098; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602116.validator(path, query, header, formData, body)
  let scheme = call_602116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602116.url(scheme.get, call_602116.host, call_602116.base,
                         call_602116.route, valid.getOrDefault("path"))
  result = hook(call_602116, url, valid)

proc call*(call_602117: Call_GetDescribeDBSnapshots_602098; MaxRecords: int = 0;
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
  var query_602118 = newJObject()
  add(query_602118, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602118.add "Filters", Filters
  add(query_602118, "Action", newJString(Action))
  add(query_602118, "Marker", newJString(Marker))
  add(query_602118, "SnapshotType", newJString(SnapshotType))
  add(query_602118, "Version", newJString(Version))
  add(query_602118, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602118, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602117.call(nil, query_602118, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_602098(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_602099, base: "/",
    url: url_GetDescribeDBSnapshots_602100, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602160 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSubnetGroups_602162(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_602161(path: JsonNode; query: JsonNode;
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
  var valid_602163 = query.getOrDefault("Action")
  valid_602163 = validateParameter(valid_602163, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602163 != nil:
    section.add "Action", valid_602163
  var valid_602164 = query.getOrDefault("Version")
  valid_602164 = validateParameter(valid_602164, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602164 != nil:
    section.add "Version", valid_602164
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602165 = header.getOrDefault("X-Amz-Date")
  valid_602165 = validateParameter(valid_602165, JString, required = false,
                                 default = nil)
  if valid_602165 != nil:
    section.add "X-Amz-Date", valid_602165
  var valid_602166 = header.getOrDefault("X-Amz-Security-Token")
  valid_602166 = validateParameter(valid_602166, JString, required = false,
                                 default = nil)
  if valid_602166 != nil:
    section.add "X-Amz-Security-Token", valid_602166
  var valid_602167 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602167 = validateParameter(valid_602167, JString, required = false,
                                 default = nil)
  if valid_602167 != nil:
    section.add "X-Amz-Content-Sha256", valid_602167
  var valid_602168 = header.getOrDefault("X-Amz-Algorithm")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = nil)
  if valid_602168 != nil:
    section.add "X-Amz-Algorithm", valid_602168
  var valid_602169 = header.getOrDefault("X-Amz-Signature")
  valid_602169 = validateParameter(valid_602169, JString, required = false,
                                 default = nil)
  if valid_602169 != nil:
    section.add "X-Amz-Signature", valid_602169
  var valid_602170 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "X-Amz-SignedHeaders", valid_602170
  var valid_602171 = header.getOrDefault("X-Amz-Credential")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Credential", valid_602171
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602172 = formData.getOrDefault("DBSubnetGroupName")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "DBSubnetGroupName", valid_602172
  var valid_602173 = formData.getOrDefault("Marker")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "Marker", valid_602173
  var valid_602174 = formData.getOrDefault("Filters")
  valid_602174 = validateParameter(valid_602174, JArray, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "Filters", valid_602174
  var valid_602175 = formData.getOrDefault("MaxRecords")
  valid_602175 = validateParameter(valid_602175, JInt, required = false, default = nil)
  if valid_602175 != nil:
    section.add "MaxRecords", valid_602175
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602176: Call_PostDescribeDBSubnetGroups_602160; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602176.validator(path, query, header, formData, body)
  let scheme = call_602176.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602176.url(scheme.get, call_602176.host, call_602176.base,
                         call_602176.route, valid.getOrDefault("path"))
  result = hook(call_602176, url, valid)

proc call*(call_602177: Call_PostDescribeDBSubnetGroups_602160;
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
  var query_602178 = newJObject()
  var formData_602179 = newJObject()
  add(formData_602179, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602179, "Marker", newJString(Marker))
  add(query_602178, "Action", newJString(Action))
  if Filters != nil:
    formData_602179.add "Filters", Filters
  add(formData_602179, "MaxRecords", newJInt(MaxRecords))
  add(query_602178, "Version", newJString(Version))
  result = call_602177.call(nil, query_602178, nil, formData_602179, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602160(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602161, base: "/",
    url: url_PostDescribeDBSubnetGroups_602162,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602141 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSubnetGroups_602143(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_602142(path: JsonNode; query: JsonNode;
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
  var valid_602144 = query.getOrDefault("MaxRecords")
  valid_602144 = validateParameter(valid_602144, JInt, required = false, default = nil)
  if valid_602144 != nil:
    section.add "MaxRecords", valid_602144
  var valid_602145 = query.getOrDefault("Filters")
  valid_602145 = validateParameter(valid_602145, JArray, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "Filters", valid_602145
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602146 = query.getOrDefault("Action")
  valid_602146 = validateParameter(valid_602146, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602146 != nil:
    section.add "Action", valid_602146
  var valid_602147 = query.getOrDefault("Marker")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "Marker", valid_602147
  var valid_602148 = query.getOrDefault("DBSubnetGroupName")
  valid_602148 = validateParameter(valid_602148, JString, required = false,
                                 default = nil)
  if valid_602148 != nil:
    section.add "DBSubnetGroupName", valid_602148
  var valid_602149 = query.getOrDefault("Version")
  valid_602149 = validateParameter(valid_602149, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602157: Call_GetDescribeDBSubnetGroups_602141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602157.validator(path, query, header, formData, body)
  let scheme = call_602157.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602157.url(scheme.get, call_602157.host, call_602157.base,
                         call_602157.route, valid.getOrDefault("path"))
  result = hook(call_602157, url, valid)

proc call*(call_602158: Call_GetDescribeDBSubnetGroups_602141; MaxRecords: int = 0;
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
  var query_602159 = newJObject()
  add(query_602159, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602159.add "Filters", Filters
  add(query_602159, "Action", newJString(Action))
  add(query_602159, "Marker", newJString(Marker))
  add(query_602159, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602159, "Version", newJString(Version))
  result = call_602158.call(nil, query_602159, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602141(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602142, base: "/",
    url: url_GetDescribeDBSubnetGroups_602143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602199 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEngineDefaultParameters_602201(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_602200(path: JsonNode;
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
  var valid_602202 = query.getOrDefault("Action")
  valid_602202 = validateParameter(valid_602202, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602202 != nil:
    section.add "Action", valid_602202
  var valid_602203 = query.getOrDefault("Version")
  valid_602203 = validateParameter(valid_602203, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602203 != nil:
    section.add "Version", valid_602203
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602204 = header.getOrDefault("X-Amz-Date")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Date", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-Security-Token")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-Security-Token", valid_602205
  var valid_602206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602206 = validateParameter(valid_602206, JString, required = false,
                                 default = nil)
  if valid_602206 != nil:
    section.add "X-Amz-Content-Sha256", valid_602206
  var valid_602207 = header.getOrDefault("X-Amz-Algorithm")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = nil)
  if valid_602207 != nil:
    section.add "X-Amz-Algorithm", valid_602207
  var valid_602208 = header.getOrDefault("X-Amz-Signature")
  valid_602208 = validateParameter(valid_602208, JString, required = false,
                                 default = nil)
  if valid_602208 != nil:
    section.add "X-Amz-Signature", valid_602208
  var valid_602209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602209 = validateParameter(valid_602209, JString, required = false,
                                 default = nil)
  if valid_602209 != nil:
    section.add "X-Amz-SignedHeaders", valid_602209
  var valid_602210 = header.getOrDefault("X-Amz-Credential")
  valid_602210 = validateParameter(valid_602210, JString, required = false,
                                 default = nil)
  if valid_602210 != nil:
    section.add "X-Amz-Credential", valid_602210
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602211 = formData.getOrDefault("Marker")
  valid_602211 = validateParameter(valid_602211, JString, required = false,
                                 default = nil)
  if valid_602211 != nil:
    section.add "Marker", valid_602211
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602212 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602212 = validateParameter(valid_602212, JString, required = true,
                                 default = nil)
  if valid_602212 != nil:
    section.add "DBParameterGroupFamily", valid_602212
  var valid_602213 = formData.getOrDefault("Filters")
  valid_602213 = validateParameter(valid_602213, JArray, required = false,
                                 default = nil)
  if valid_602213 != nil:
    section.add "Filters", valid_602213
  var valid_602214 = formData.getOrDefault("MaxRecords")
  valid_602214 = validateParameter(valid_602214, JInt, required = false, default = nil)
  if valid_602214 != nil:
    section.add "MaxRecords", valid_602214
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602215: Call_PostDescribeEngineDefaultParameters_602199;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602215.validator(path, query, header, formData, body)
  let scheme = call_602215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602215.url(scheme.get, call_602215.host, call_602215.base,
                         call_602215.route, valid.getOrDefault("path"))
  result = hook(call_602215, url, valid)

proc call*(call_602216: Call_PostDescribeEngineDefaultParameters_602199;
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
  var query_602217 = newJObject()
  var formData_602218 = newJObject()
  add(formData_602218, "Marker", newJString(Marker))
  add(query_602217, "Action", newJString(Action))
  add(formData_602218, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_602218.add "Filters", Filters
  add(formData_602218, "MaxRecords", newJInt(MaxRecords))
  add(query_602217, "Version", newJString(Version))
  result = call_602216.call(nil, query_602217, nil, formData_602218, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602199(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602200, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602180 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEngineDefaultParameters_602182(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_602181(path: JsonNode;
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
  var valid_602183 = query.getOrDefault("MaxRecords")
  valid_602183 = validateParameter(valid_602183, JInt, required = false, default = nil)
  if valid_602183 != nil:
    section.add "MaxRecords", valid_602183
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602184 = query.getOrDefault("DBParameterGroupFamily")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "DBParameterGroupFamily", valid_602184
  var valid_602185 = query.getOrDefault("Filters")
  valid_602185 = validateParameter(valid_602185, JArray, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "Filters", valid_602185
  var valid_602186 = query.getOrDefault("Action")
  valid_602186 = validateParameter(valid_602186, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602186 != nil:
    section.add "Action", valid_602186
  var valid_602187 = query.getOrDefault("Marker")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "Marker", valid_602187
  var valid_602188 = query.getOrDefault("Version")
  valid_602188 = validateParameter(valid_602188, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602188 != nil:
    section.add "Version", valid_602188
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602189 = header.getOrDefault("X-Amz-Date")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Date", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Security-Token")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Security-Token", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-Content-Sha256", valid_602191
  var valid_602192 = header.getOrDefault("X-Amz-Algorithm")
  valid_602192 = validateParameter(valid_602192, JString, required = false,
                                 default = nil)
  if valid_602192 != nil:
    section.add "X-Amz-Algorithm", valid_602192
  var valid_602193 = header.getOrDefault("X-Amz-Signature")
  valid_602193 = validateParameter(valid_602193, JString, required = false,
                                 default = nil)
  if valid_602193 != nil:
    section.add "X-Amz-Signature", valid_602193
  var valid_602194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602194 = validateParameter(valid_602194, JString, required = false,
                                 default = nil)
  if valid_602194 != nil:
    section.add "X-Amz-SignedHeaders", valid_602194
  var valid_602195 = header.getOrDefault("X-Amz-Credential")
  valid_602195 = validateParameter(valid_602195, JString, required = false,
                                 default = nil)
  if valid_602195 != nil:
    section.add "X-Amz-Credential", valid_602195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602196: Call_GetDescribeEngineDefaultParameters_602180;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602196.validator(path, query, header, formData, body)
  let scheme = call_602196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602196.url(scheme.get, call_602196.host, call_602196.base,
                         call_602196.route, valid.getOrDefault("path"))
  result = hook(call_602196, url, valid)

proc call*(call_602197: Call_GetDescribeEngineDefaultParameters_602180;
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
  var query_602198 = newJObject()
  add(query_602198, "MaxRecords", newJInt(MaxRecords))
  add(query_602198, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_602198.add "Filters", Filters
  add(query_602198, "Action", newJString(Action))
  add(query_602198, "Marker", newJString(Marker))
  add(query_602198, "Version", newJString(Version))
  result = call_602197.call(nil, query_602198, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602180(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602181, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602182,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602236 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventCategories_602238(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_602237(path: JsonNode; query: JsonNode;
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
  var valid_602239 = query.getOrDefault("Action")
  valid_602239 = validateParameter(valid_602239, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602239 != nil:
    section.add "Action", valid_602239
  var valid_602240 = query.getOrDefault("Version")
  valid_602240 = validateParameter(valid_602240, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602240 != nil:
    section.add "Version", valid_602240
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602241 = header.getOrDefault("X-Amz-Date")
  valid_602241 = validateParameter(valid_602241, JString, required = false,
                                 default = nil)
  if valid_602241 != nil:
    section.add "X-Amz-Date", valid_602241
  var valid_602242 = header.getOrDefault("X-Amz-Security-Token")
  valid_602242 = validateParameter(valid_602242, JString, required = false,
                                 default = nil)
  if valid_602242 != nil:
    section.add "X-Amz-Security-Token", valid_602242
  var valid_602243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "X-Amz-Content-Sha256", valid_602243
  var valid_602244 = header.getOrDefault("X-Amz-Algorithm")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "X-Amz-Algorithm", valid_602244
  var valid_602245 = header.getOrDefault("X-Amz-Signature")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Signature", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-SignedHeaders", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Credential")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Credential", valid_602247
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_602248 = formData.getOrDefault("Filters")
  valid_602248 = validateParameter(valid_602248, JArray, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "Filters", valid_602248
  var valid_602249 = formData.getOrDefault("SourceType")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "SourceType", valid_602249
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602250: Call_PostDescribeEventCategories_602236; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602250.validator(path, query, header, formData, body)
  let scheme = call_602250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602250.url(scheme.get, call_602250.host, call_602250.base,
                         call_602250.route, valid.getOrDefault("path"))
  result = hook(call_602250, url, valid)

proc call*(call_602251: Call_PostDescribeEventCategories_602236;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_602252 = newJObject()
  var formData_602253 = newJObject()
  add(query_602252, "Action", newJString(Action))
  if Filters != nil:
    formData_602253.add "Filters", Filters
  add(query_602252, "Version", newJString(Version))
  add(formData_602253, "SourceType", newJString(SourceType))
  result = call_602251.call(nil, query_602252, nil, formData_602253, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602236(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602237, base: "/",
    url: url_PostDescribeEventCategories_602238,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602219 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventCategories_602221(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_602220(path: JsonNode; query: JsonNode;
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
  var valid_602222 = query.getOrDefault("SourceType")
  valid_602222 = validateParameter(valid_602222, JString, required = false,
                                 default = nil)
  if valid_602222 != nil:
    section.add "SourceType", valid_602222
  var valid_602223 = query.getOrDefault("Filters")
  valid_602223 = validateParameter(valid_602223, JArray, required = false,
                                 default = nil)
  if valid_602223 != nil:
    section.add "Filters", valid_602223
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602224 = query.getOrDefault("Action")
  valid_602224 = validateParameter(valid_602224, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602224 != nil:
    section.add "Action", valid_602224
  var valid_602225 = query.getOrDefault("Version")
  valid_602225 = validateParameter(valid_602225, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602225 != nil:
    section.add "Version", valid_602225
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602226 = header.getOrDefault("X-Amz-Date")
  valid_602226 = validateParameter(valid_602226, JString, required = false,
                                 default = nil)
  if valid_602226 != nil:
    section.add "X-Amz-Date", valid_602226
  var valid_602227 = header.getOrDefault("X-Amz-Security-Token")
  valid_602227 = validateParameter(valid_602227, JString, required = false,
                                 default = nil)
  if valid_602227 != nil:
    section.add "X-Amz-Security-Token", valid_602227
  var valid_602228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602228 = validateParameter(valid_602228, JString, required = false,
                                 default = nil)
  if valid_602228 != nil:
    section.add "X-Amz-Content-Sha256", valid_602228
  var valid_602229 = header.getOrDefault("X-Amz-Algorithm")
  valid_602229 = validateParameter(valid_602229, JString, required = false,
                                 default = nil)
  if valid_602229 != nil:
    section.add "X-Amz-Algorithm", valid_602229
  var valid_602230 = header.getOrDefault("X-Amz-Signature")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Signature", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-SignedHeaders", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Credential")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Credential", valid_602232
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602233: Call_GetDescribeEventCategories_602219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602233.validator(path, query, header, formData, body)
  let scheme = call_602233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602233.url(scheme.get, call_602233.host, call_602233.base,
                         call_602233.route, valid.getOrDefault("path"))
  result = hook(call_602233, url, valid)

proc call*(call_602234: Call_GetDescribeEventCategories_602219;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602235 = newJObject()
  add(query_602235, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_602235.add "Filters", Filters
  add(query_602235, "Action", newJString(Action))
  add(query_602235, "Version", newJString(Version))
  result = call_602234.call(nil, query_602235, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602219(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602220, base: "/",
    url: url_GetDescribeEventCategories_602221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_602273 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventSubscriptions_602275(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_602274(path: JsonNode;
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
  var valid_602276 = query.getOrDefault("Action")
  valid_602276 = validateParameter(valid_602276, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602276 != nil:
    section.add "Action", valid_602276
  var valid_602277 = query.getOrDefault("Version")
  valid_602277 = validateParameter(valid_602277, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602277 != nil:
    section.add "Version", valid_602277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602278 = header.getOrDefault("X-Amz-Date")
  valid_602278 = validateParameter(valid_602278, JString, required = false,
                                 default = nil)
  if valid_602278 != nil:
    section.add "X-Amz-Date", valid_602278
  var valid_602279 = header.getOrDefault("X-Amz-Security-Token")
  valid_602279 = validateParameter(valid_602279, JString, required = false,
                                 default = nil)
  if valid_602279 != nil:
    section.add "X-Amz-Security-Token", valid_602279
  var valid_602280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602280 = validateParameter(valid_602280, JString, required = false,
                                 default = nil)
  if valid_602280 != nil:
    section.add "X-Amz-Content-Sha256", valid_602280
  var valid_602281 = header.getOrDefault("X-Amz-Algorithm")
  valid_602281 = validateParameter(valid_602281, JString, required = false,
                                 default = nil)
  if valid_602281 != nil:
    section.add "X-Amz-Algorithm", valid_602281
  var valid_602282 = header.getOrDefault("X-Amz-Signature")
  valid_602282 = validateParameter(valid_602282, JString, required = false,
                                 default = nil)
  if valid_602282 != nil:
    section.add "X-Amz-Signature", valid_602282
  var valid_602283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "X-Amz-SignedHeaders", valid_602283
  var valid_602284 = header.getOrDefault("X-Amz-Credential")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "X-Amz-Credential", valid_602284
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602285 = formData.getOrDefault("Marker")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "Marker", valid_602285
  var valid_602286 = formData.getOrDefault("SubscriptionName")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "SubscriptionName", valid_602286
  var valid_602287 = formData.getOrDefault("Filters")
  valid_602287 = validateParameter(valid_602287, JArray, required = false,
                                 default = nil)
  if valid_602287 != nil:
    section.add "Filters", valid_602287
  var valid_602288 = formData.getOrDefault("MaxRecords")
  valid_602288 = validateParameter(valid_602288, JInt, required = false, default = nil)
  if valid_602288 != nil:
    section.add "MaxRecords", valid_602288
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602289: Call_PostDescribeEventSubscriptions_602273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602289.validator(path, query, header, formData, body)
  let scheme = call_602289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602289.url(scheme.get, call_602289.host, call_602289.base,
                         call_602289.route, valid.getOrDefault("path"))
  result = hook(call_602289, url, valid)

proc call*(call_602290: Call_PostDescribeEventSubscriptions_602273;
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
  var query_602291 = newJObject()
  var formData_602292 = newJObject()
  add(formData_602292, "Marker", newJString(Marker))
  add(formData_602292, "SubscriptionName", newJString(SubscriptionName))
  add(query_602291, "Action", newJString(Action))
  if Filters != nil:
    formData_602292.add "Filters", Filters
  add(formData_602292, "MaxRecords", newJInt(MaxRecords))
  add(query_602291, "Version", newJString(Version))
  result = call_602290.call(nil, query_602291, nil, formData_602292, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_602273(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_602274, base: "/",
    url: url_PostDescribeEventSubscriptions_602275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_602254 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventSubscriptions_602256(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_602255(path: JsonNode; query: JsonNode;
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
  var valid_602257 = query.getOrDefault("MaxRecords")
  valid_602257 = validateParameter(valid_602257, JInt, required = false, default = nil)
  if valid_602257 != nil:
    section.add "MaxRecords", valid_602257
  var valid_602258 = query.getOrDefault("Filters")
  valid_602258 = validateParameter(valid_602258, JArray, required = false,
                                 default = nil)
  if valid_602258 != nil:
    section.add "Filters", valid_602258
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602259 = query.getOrDefault("Action")
  valid_602259 = validateParameter(valid_602259, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602259 != nil:
    section.add "Action", valid_602259
  var valid_602260 = query.getOrDefault("Marker")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "Marker", valid_602260
  var valid_602261 = query.getOrDefault("SubscriptionName")
  valid_602261 = validateParameter(valid_602261, JString, required = false,
                                 default = nil)
  if valid_602261 != nil:
    section.add "SubscriptionName", valid_602261
  var valid_602262 = query.getOrDefault("Version")
  valid_602262 = validateParameter(valid_602262, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602262 != nil:
    section.add "Version", valid_602262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602263 = header.getOrDefault("X-Amz-Date")
  valid_602263 = validateParameter(valid_602263, JString, required = false,
                                 default = nil)
  if valid_602263 != nil:
    section.add "X-Amz-Date", valid_602263
  var valid_602264 = header.getOrDefault("X-Amz-Security-Token")
  valid_602264 = validateParameter(valid_602264, JString, required = false,
                                 default = nil)
  if valid_602264 != nil:
    section.add "X-Amz-Security-Token", valid_602264
  var valid_602265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602265 = validateParameter(valid_602265, JString, required = false,
                                 default = nil)
  if valid_602265 != nil:
    section.add "X-Amz-Content-Sha256", valid_602265
  var valid_602266 = header.getOrDefault("X-Amz-Algorithm")
  valid_602266 = validateParameter(valid_602266, JString, required = false,
                                 default = nil)
  if valid_602266 != nil:
    section.add "X-Amz-Algorithm", valid_602266
  var valid_602267 = header.getOrDefault("X-Amz-Signature")
  valid_602267 = validateParameter(valid_602267, JString, required = false,
                                 default = nil)
  if valid_602267 != nil:
    section.add "X-Amz-Signature", valid_602267
  var valid_602268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602268 = validateParameter(valid_602268, JString, required = false,
                                 default = nil)
  if valid_602268 != nil:
    section.add "X-Amz-SignedHeaders", valid_602268
  var valid_602269 = header.getOrDefault("X-Amz-Credential")
  valid_602269 = validateParameter(valid_602269, JString, required = false,
                                 default = nil)
  if valid_602269 != nil:
    section.add "X-Amz-Credential", valid_602269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602270: Call_GetDescribeEventSubscriptions_602254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602270.validator(path, query, header, formData, body)
  let scheme = call_602270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602270.url(scheme.get, call_602270.host, call_602270.base,
                         call_602270.route, valid.getOrDefault("path"))
  result = hook(call_602270, url, valid)

proc call*(call_602271: Call_GetDescribeEventSubscriptions_602254;
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
  var query_602272 = newJObject()
  add(query_602272, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602272.add "Filters", Filters
  add(query_602272, "Action", newJString(Action))
  add(query_602272, "Marker", newJString(Marker))
  add(query_602272, "SubscriptionName", newJString(SubscriptionName))
  add(query_602272, "Version", newJString(Version))
  result = call_602271.call(nil, query_602272, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_602254(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_602255, base: "/",
    url: url_GetDescribeEventSubscriptions_602256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602317 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEvents_602319(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_602318(path: JsonNode; query: JsonNode;
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
  var valid_602320 = query.getOrDefault("Action")
  valid_602320 = validateParameter(valid_602320, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602320 != nil:
    section.add "Action", valid_602320
  var valid_602321 = query.getOrDefault("Version")
  valid_602321 = validateParameter(valid_602321, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602321 != nil:
    section.add "Version", valid_602321
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602322 = header.getOrDefault("X-Amz-Date")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Date", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Security-Token")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Security-Token", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-Content-Sha256", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Algorithm")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Algorithm", valid_602325
  var valid_602326 = header.getOrDefault("X-Amz-Signature")
  valid_602326 = validateParameter(valid_602326, JString, required = false,
                                 default = nil)
  if valid_602326 != nil:
    section.add "X-Amz-Signature", valid_602326
  var valid_602327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "X-Amz-SignedHeaders", valid_602327
  var valid_602328 = header.getOrDefault("X-Amz-Credential")
  valid_602328 = validateParameter(valid_602328, JString, required = false,
                                 default = nil)
  if valid_602328 != nil:
    section.add "X-Amz-Credential", valid_602328
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
  var valid_602329 = formData.getOrDefault("SourceIdentifier")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "SourceIdentifier", valid_602329
  var valid_602330 = formData.getOrDefault("EventCategories")
  valid_602330 = validateParameter(valid_602330, JArray, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "EventCategories", valid_602330
  var valid_602331 = formData.getOrDefault("Marker")
  valid_602331 = validateParameter(valid_602331, JString, required = false,
                                 default = nil)
  if valid_602331 != nil:
    section.add "Marker", valid_602331
  var valid_602332 = formData.getOrDefault("StartTime")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "StartTime", valid_602332
  var valid_602333 = formData.getOrDefault("Duration")
  valid_602333 = validateParameter(valid_602333, JInt, required = false, default = nil)
  if valid_602333 != nil:
    section.add "Duration", valid_602333
  var valid_602334 = formData.getOrDefault("Filters")
  valid_602334 = validateParameter(valid_602334, JArray, required = false,
                                 default = nil)
  if valid_602334 != nil:
    section.add "Filters", valid_602334
  var valid_602335 = formData.getOrDefault("EndTime")
  valid_602335 = validateParameter(valid_602335, JString, required = false,
                                 default = nil)
  if valid_602335 != nil:
    section.add "EndTime", valid_602335
  var valid_602336 = formData.getOrDefault("MaxRecords")
  valid_602336 = validateParameter(valid_602336, JInt, required = false, default = nil)
  if valid_602336 != nil:
    section.add "MaxRecords", valid_602336
  var valid_602337 = formData.getOrDefault("SourceType")
  valid_602337 = validateParameter(valid_602337, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602337 != nil:
    section.add "SourceType", valid_602337
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602338: Call_PostDescribeEvents_602317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602338.validator(path, query, header, formData, body)
  let scheme = call_602338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602338.url(scheme.get, call_602338.host, call_602338.base,
                         call_602338.route, valid.getOrDefault("path"))
  result = hook(call_602338, url, valid)

proc call*(call_602339: Call_PostDescribeEvents_602317;
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
  var query_602340 = newJObject()
  var formData_602341 = newJObject()
  add(formData_602341, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602341.add "EventCategories", EventCategories
  add(formData_602341, "Marker", newJString(Marker))
  add(formData_602341, "StartTime", newJString(StartTime))
  add(query_602340, "Action", newJString(Action))
  add(formData_602341, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_602341.add "Filters", Filters
  add(formData_602341, "EndTime", newJString(EndTime))
  add(formData_602341, "MaxRecords", newJInt(MaxRecords))
  add(query_602340, "Version", newJString(Version))
  add(formData_602341, "SourceType", newJString(SourceType))
  result = call_602339.call(nil, query_602340, nil, formData_602341, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602317(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602318, base: "/",
    url: url_PostDescribeEvents_602319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602293 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEvents_602295(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_602294(path: JsonNode; query: JsonNode;
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
  var valid_602296 = query.getOrDefault("SourceType")
  valid_602296 = validateParameter(valid_602296, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602296 != nil:
    section.add "SourceType", valid_602296
  var valid_602297 = query.getOrDefault("MaxRecords")
  valid_602297 = validateParameter(valid_602297, JInt, required = false, default = nil)
  if valid_602297 != nil:
    section.add "MaxRecords", valid_602297
  var valid_602298 = query.getOrDefault("StartTime")
  valid_602298 = validateParameter(valid_602298, JString, required = false,
                                 default = nil)
  if valid_602298 != nil:
    section.add "StartTime", valid_602298
  var valid_602299 = query.getOrDefault("Filters")
  valid_602299 = validateParameter(valid_602299, JArray, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "Filters", valid_602299
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602300 = query.getOrDefault("Action")
  valid_602300 = validateParameter(valid_602300, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602300 != nil:
    section.add "Action", valid_602300
  var valid_602301 = query.getOrDefault("SourceIdentifier")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "SourceIdentifier", valid_602301
  var valid_602302 = query.getOrDefault("Marker")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "Marker", valid_602302
  var valid_602303 = query.getOrDefault("EventCategories")
  valid_602303 = validateParameter(valid_602303, JArray, required = false,
                                 default = nil)
  if valid_602303 != nil:
    section.add "EventCategories", valid_602303
  var valid_602304 = query.getOrDefault("Duration")
  valid_602304 = validateParameter(valid_602304, JInt, required = false, default = nil)
  if valid_602304 != nil:
    section.add "Duration", valid_602304
  var valid_602305 = query.getOrDefault("EndTime")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "EndTime", valid_602305
  var valid_602306 = query.getOrDefault("Version")
  valid_602306 = validateParameter(valid_602306, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602306 != nil:
    section.add "Version", valid_602306
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602307 = header.getOrDefault("X-Amz-Date")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Date", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Security-Token")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Security-Token", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-Content-Sha256", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Algorithm")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Algorithm", valid_602310
  var valid_602311 = header.getOrDefault("X-Amz-Signature")
  valid_602311 = validateParameter(valid_602311, JString, required = false,
                                 default = nil)
  if valid_602311 != nil:
    section.add "X-Amz-Signature", valid_602311
  var valid_602312 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602312 = validateParameter(valid_602312, JString, required = false,
                                 default = nil)
  if valid_602312 != nil:
    section.add "X-Amz-SignedHeaders", valid_602312
  var valid_602313 = header.getOrDefault("X-Amz-Credential")
  valid_602313 = validateParameter(valid_602313, JString, required = false,
                                 default = nil)
  if valid_602313 != nil:
    section.add "X-Amz-Credential", valid_602313
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602314: Call_GetDescribeEvents_602293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602314.validator(path, query, header, formData, body)
  let scheme = call_602314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602314.url(scheme.get, call_602314.host, call_602314.base,
                         call_602314.route, valid.getOrDefault("path"))
  result = hook(call_602314, url, valid)

proc call*(call_602315: Call_GetDescribeEvents_602293;
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
  var query_602316 = newJObject()
  add(query_602316, "SourceType", newJString(SourceType))
  add(query_602316, "MaxRecords", newJInt(MaxRecords))
  add(query_602316, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_602316.add "Filters", Filters
  add(query_602316, "Action", newJString(Action))
  add(query_602316, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602316, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_602316.add "EventCategories", EventCategories
  add(query_602316, "Duration", newJInt(Duration))
  add(query_602316, "EndTime", newJString(EndTime))
  add(query_602316, "Version", newJString(Version))
  result = call_602315.call(nil, query_602316, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602293(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602294,
    base: "/", url: url_GetDescribeEvents_602295,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_602362 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroupOptions_602364(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_602363(path: JsonNode;
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
  var valid_602365 = query.getOrDefault("Action")
  valid_602365 = validateParameter(valid_602365, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602365 != nil:
    section.add "Action", valid_602365
  var valid_602366 = query.getOrDefault("Version")
  valid_602366 = validateParameter(valid_602366, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602366 != nil:
    section.add "Version", valid_602366
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602367 = header.getOrDefault("X-Amz-Date")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Date", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Security-Token")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Security-Token", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Content-Sha256", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Algorithm")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Algorithm", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-Signature")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-Signature", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-SignedHeaders", valid_602372
  var valid_602373 = header.getOrDefault("X-Amz-Credential")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "X-Amz-Credential", valid_602373
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602374 = formData.getOrDefault("MajorEngineVersion")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "MajorEngineVersion", valid_602374
  var valid_602375 = formData.getOrDefault("Marker")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "Marker", valid_602375
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_602376 = formData.getOrDefault("EngineName")
  valid_602376 = validateParameter(valid_602376, JString, required = true,
                                 default = nil)
  if valid_602376 != nil:
    section.add "EngineName", valid_602376
  var valid_602377 = formData.getOrDefault("Filters")
  valid_602377 = validateParameter(valid_602377, JArray, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "Filters", valid_602377
  var valid_602378 = formData.getOrDefault("MaxRecords")
  valid_602378 = validateParameter(valid_602378, JInt, required = false, default = nil)
  if valid_602378 != nil:
    section.add "MaxRecords", valid_602378
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602379: Call_PostDescribeOptionGroupOptions_602362; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602379.validator(path, query, header, formData, body)
  let scheme = call_602379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602379.url(scheme.get, call_602379.host, call_602379.base,
                         call_602379.route, valid.getOrDefault("path"))
  result = hook(call_602379, url, valid)

proc call*(call_602380: Call_PostDescribeOptionGroupOptions_602362;
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
  var query_602381 = newJObject()
  var formData_602382 = newJObject()
  add(formData_602382, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602382, "Marker", newJString(Marker))
  add(query_602381, "Action", newJString(Action))
  add(formData_602382, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602382.add "Filters", Filters
  add(formData_602382, "MaxRecords", newJInt(MaxRecords))
  add(query_602381, "Version", newJString(Version))
  result = call_602380.call(nil, query_602381, nil, formData_602382, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_602362(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_602363, base: "/",
    url: url_PostDescribeOptionGroupOptions_602364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_602342 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroupOptions_602344(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_602343(path: JsonNode; query: JsonNode;
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
  var valid_602345 = query.getOrDefault("MaxRecords")
  valid_602345 = validateParameter(valid_602345, JInt, required = false, default = nil)
  if valid_602345 != nil:
    section.add "MaxRecords", valid_602345
  var valid_602346 = query.getOrDefault("Filters")
  valid_602346 = validateParameter(valid_602346, JArray, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "Filters", valid_602346
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602347 = query.getOrDefault("Action")
  valid_602347 = validateParameter(valid_602347, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602347 != nil:
    section.add "Action", valid_602347
  var valid_602348 = query.getOrDefault("Marker")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "Marker", valid_602348
  var valid_602349 = query.getOrDefault("Version")
  valid_602349 = validateParameter(valid_602349, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602349 != nil:
    section.add "Version", valid_602349
  var valid_602350 = query.getOrDefault("EngineName")
  valid_602350 = validateParameter(valid_602350, JString, required = true,
                                 default = nil)
  if valid_602350 != nil:
    section.add "EngineName", valid_602350
  var valid_602351 = query.getOrDefault("MajorEngineVersion")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "MajorEngineVersion", valid_602351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602352 = header.getOrDefault("X-Amz-Date")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Date", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Security-Token")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Security-Token", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Content-Sha256", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Algorithm")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Algorithm", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-Signature")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-Signature", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-SignedHeaders", valid_602357
  var valid_602358 = header.getOrDefault("X-Amz-Credential")
  valid_602358 = validateParameter(valid_602358, JString, required = false,
                                 default = nil)
  if valid_602358 != nil:
    section.add "X-Amz-Credential", valid_602358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602359: Call_GetDescribeOptionGroupOptions_602342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602359.validator(path, query, header, formData, body)
  let scheme = call_602359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602359.url(scheme.get, call_602359.host, call_602359.base,
                         call_602359.route, valid.getOrDefault("path"))
  result = hook(call_602359, url, valid)

proc call*(call_602360: Call_GetDescribeOptionGroupOptions_602342;
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
  var query_602361 = newJObject()
  add(query_602361, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602361.add "Filters", Filters
  add(query_602361, "Action", newJString(Action))
  add(query_602361, "Marker", newJString(Marker))
  add(query_602361, "Version", newJString(Version))
  add(query_602361, "EngineName", newJString(EngineName))
  add(query_602361, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602360.call(nil, query_602361, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_602342(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_602343, base: "/",
    url: url_GetDescribeOptionGroupOptions_602344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_602404 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroups_602406(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_602405(path: JsonNode; query: JsonNode;
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
  var valid_602407 = query.getOrDefault("Action")
  valid_602407 = validateParameter(valid_602407, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602407 != nil:
    section.add "Action", valid_602407
  var valid_602408 = query.getOrDefault("Version")
  valid_602408 = validateParameter(valid_602408, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602408 != nil:
    section.add "Version", valid_602408
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602409 = header.getOrDefault("X-Amz-Date")
  valid_602409 = validateParameter(valid_602409, JString, required = false,
                                 default = nil)
  if valid_602409 != nil:
    section.add "X-Amz-Date", valid_602409
  var valid_602410 = header.getOrDefault("X-Amz-Security-Token")
  valid_602410 = validateParameter(valid_602410, JString, required = false,
                                 default = nil)
  if valid_602410 != nil:
    section.add "X-Amz-Security-Token", valid_602410
  var valid_602411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602411 = validateParameter(valid_602411, JString, required = false,
                                 default = nil)
  if valid_602411 != nil:
    section.add "X-Amz-Content-Sha256", valid_602411
  var valid_602412 = header.getOrDefault("X-Amz-Algorithm")
  valid_602412 = validateParameter(valid_602412, JString, required = false,
                                 default = nil)
  if valid_602412 != nil:
    section.add "X-Amz-Algorithm", valid_602412
  var valid_602413 = header.getOrDefault("X-Amz-Signature")
  valid_602413 = validateParameter(valid_602413, JString, required = false,
                                 default = nil)
  if valid_602413 != nil:
    section.add "X-Amz-Signature", valid_602413
  var valid_602414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-SignedHeaders", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Credential")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Credential", valid_602415
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602416 = formData.getOrDefault("MajorEngineVersion")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "MajorEngineVersion", valid_602416
  var valid_602417 = formData.getOrDefault("OptionGroupName")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "OptionGroupName", valid_602417
  var valid_602418 = formData.getOrDefault("Marker")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "Marker", valid_602418
  var valid_602419 = formData.getOrDefault("EngineName")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "EngineName", valid_602419
  var valid_602420 = formData.getOrDefault("Filters")
  valid_602420 = validateParameter(valid_602420, JArray, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "Filters", valid_602420
  var valid_602421 = formData.getOrDefault("MaxRecords")
  valid_602421 = validateParameter(valid_602421, JInt, required = false, default = nil)
  if valid_602421 != nil:
    section.add "MaxRecords", valid_602421
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602422: Call_PostDescribeOptionGroups_602404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602422.validator(path, query, header, formData, body)
  let scheme = call_602422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602422.url(scheme.get, call_602422.host, call_602422.base,
                         call_602422.route, valid.getOrDefault("path"))
  result = hook(call_602422, url, valid)

proc call*(call_602423: Call_PostDescribeOptionGroups_602404;
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
  var query_602424 = newJObject()
  var formData_602425 = newJObject()
  add(formData_602425, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602425, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602425, "Marker", newJString(Marker))
  add(query_602424, "Action", newJString(Action))
  add(formData_602425, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_602425.add "Filters", Filters
  add(formData_602425, "MaxRecords", newJInt(MaxRecords))
  add(query_602424, "Version", newJString(Version))
  result = call_602423.call(nil, query_602424, nil, formData_602425, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_602404(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_602405, base: "/",
    url: url_PostDescribeOptionGroups_602406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_602383 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroups_602385(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_602384(path: JsonNode; query: JsonNode;
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
  var valid_602386 = query.getOrDefault("MaxRecords")
  valid_602386 = validateParameter(valid_602386, JInt, required = false, default = nil)
  if valid_602386 != nil:
    section.add "MaxRecords", valid_602386
  var valid_602387 = query.getOrDefault("OptionGroupName")
  valid_602387 = validateParameter(valid_602387, JString, required = false,
                                 default = nil)
  if valid_602387 != nil:
    section.add "OptionGroupName", valid_602387
  var valid_602388 = query.getOrDefault("Filters")
  valid_602388 = validateParameter(valid_602388, JArray, required = false,
                                 default = nil)
  if valid_602388 != nil:
    section.add "Filters", valid_602388
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602389 = query.getOrDefault("Action")
  valid_602389 = validateParameter(valid_602389, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602389 != nil:
    section.add "Action", valid_602389
  var valid_602390 = query.getOrDefault("Marker")
  valid_602390 = validateParameter(valid_602390, JString, required = false,
                                 default = nil)
  if valid_602390 != nil:
    section.add "Marker", valid_602390
  var valid_602391 = query.getOrDefault("Version")
  valid_602391 = validateParameter(valid_602391, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602391 != nil:
    section.add "Version", valid_602391
  var valid_602392 = query.getOrDefault("EngineName")
  valid_602392 = validateParameter(valid_602392, JString, required = false,
                                 default = nil)
  if valid_602392 != nil:
    section.add "EngineName", valid_602392
  var valid_602393 = query.getOrDefault("MajorEngineVersion")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "MajorEngineVersion", valid_602393
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602394 = header.getOrDefault("X-Amz-Date")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "X-Amz-Date", valid_602394
  var valid_602395 = header.getOrDefault("X-Amz-Security-Token")
  valid_602395 = validateParameter(valid_602395, JString, required = false,
                                 default = nil)
  if valid_602395 != nil:
    section.add "X-Amz-Security-Token", valid_602395
  var valid_602396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "X-Amz-Content-Sha256", valid_602396
  var valid_602397 = header.getOrDefault("X-Amz-Algorithm")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "X-Amz-Algorithm", valid_602397
  var valid_602398 = header.getOrDefault("X-Amz-Signature")
  valid_602398 = validateParameter(valid_602398, JString, required = false,
                                 default = nil)
  if valid_602398 != nil:
    section.add "X-Amz-Signature", valid_602398
  var valid_602399 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-SignedHeaders", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Credential")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Credential", valid_602400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602401: Call_GetDescribeOptionGroups_602383; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602401.validator(path, query, header, formData, body)
  let scheme = call_602401.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602401.url(scheme.get, call_602401.host, call_602401.base,
                         call_602401.route, valid.getOrDefault("path"))
  result = hook(call_602401, url, valid)

proc call*(call_602402: Call_GetDescribeOptionGroups_602383; MaxRecords: int = 0;
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
  var query_602403 = newJObject()
  add(query_602403, "MaxRecords", newJInt(MaxRecords))
  add(query_602403, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_602403.add "Filters", Filters
  add(query_602403, "Action", newJString(Action))
  add(query_602403, "Marker", newJString(Marker))
  add(query_602403, "Version", newJString(Version))
  add(query_602403, "EngineName", newJString(EngineName))
  add(query_602403, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602402.call(nil, query_602403, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_602383(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_602384, base: "/",
    url: url_GetDescribeOptionGroups_602385, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602449 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOrderableDBInstanceOptions_602451(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602450(path: JsonNode;
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
  var valid_602452 = query.getOrDefault("Action")
  valid_602452 = validateParameter(valid_602452, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602452 != nil:
    section.add "Action", valid_602452
  var valid_602453 = query.getOrDefault("Version")
  valid_602453 = validateParameter(valid_602453, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602453 != nil:
    section.add "Version", valid_602453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602454 = header.getOrDefault("X-Amz-Date")
  valid_602454 = validateParameter(valid_602454, JString, required = false,
                                 default = nil)
  if valid_602454 != nil:
    section.add "X-Amz-Date", valid_602454
  var valid_602455 = header.getOrDefault("X-Amz-Security-Token")
  valid_602455 = validateParameter(valid_602455, JString, required = false,
                                 default = nil)
  if valid_602455 != nil:
    section.add "X-Amz-Security-Token", valid_602455
  var valid_602456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602456 = validateParameter(valid_602456, JString, required = false,
                                 default = nil)
  if valid_602456 != nil:
    section.add "X-Amz-Content-Sha256", valid_602456
  var valid_602457 = header.getOrDefault("X-Amz-Algorithm")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Algorithm", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Signature")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Signature", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-SignedHeaders", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Credential")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Credential", valid_602460
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
  var valid_602461 = formData.getOrDefault("Engine")
  valid_602461 = validateParameter(valid_602461, JString, required = true,
                                 default = nil)
  if valid_602461 != nil:
    section.add "Engine", valid_602461
  var valid_602462 = formData.getOrDefault("Marker")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "Marker", valid_602462
  var valid_602463 = formData.getOrDefault("Vpc")
  valid_602463 = validateParameter(valid_602463, JBool, required = false, default = nil)
  if valid_602463 != nil:
    section.add "Vpc", valid_602463
  var valid_602464 = formData.getOrDefault("DBInstanceClass")
  valid_602464 = validateParameter(valid_602464, JString, required = false,
                                 default = nil)
  if valid_602464 != nil:
    section.add "DBInstanceClass", valid_602464
  var valid_602465 = formData.getOrDefault("Filters")
  valid_602465 = validateParameter(valid_602465, JArray, required = false,
                                 default = nil)
  if valid_602465 != nil:
    section.add "Filters", valid_602465
  var valid_602466 = formData.getOrDefault("LicenseModel")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "LicenseModel", valid_602466
  var valid_602467 = formData.getOrDefault("MaxRecords")
  valid_602467 = validateParameter(valid_602467, JInt, required = false, default = nil)
  if valid_602467 != nil:
    section.add "MaxRecords", valid_602467
  var valid_602468 = formData.getOrDefault("EngineVersion")
  valid_602468 = validateParameter(valid_602468, JString, required = false,
                                 default = nil)
  if valid_602468 != nil:
    section.add "EngineVersion", valid_602468
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602469: Call_PostDescribeOrderableDBInstanceOptions_602449;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602469.validator(path, query, header, formData, body)
  let scheme = call_602469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602469.url(scheme.get, call_602469.host, call_602469.base,
                         call_602469.route, valid.getOrDefault("path"))
  result = hook(call_602469, url, valid)

proc call*(call_602470: Call_PostDescribeOrderableDBInstanceOptions_602449;
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
  var query_602471 = newJObject()
  var formData_602472 = newJObject()
  add(formData_602472, "Engine", newJString(Engine))
  add(formData_602472, "Marker", newJString(Marker))
  add(query_602471, "Action", newJString(Action))
  add(formData_602472, "Vpc", newJBool(Vpc))
  add(formData_602472, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602472.add "Filters", Filters
  add(formData_602472, "LicenseModel", newJString(LicenseModel))
  add(formData_602472, "MaxRecords", newJInt(MaxRecords))
  add(formData_602472, "EngineVersion", newJString(EngineVersion))
  add(query_602471, "Version", newJString(Version))
  result = call_602470.call(nil, query_602471, nil, formData_602472, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602449(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602450, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602426 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOrderableDBInstanceOptions_602428(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602427(path: JsonNode;
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
  var valid_602429 = query.getOrDefault("Engine")
  valid_602429 = validateParameter(valid_602429, JString, required = true,
                                 default = nil)
  if valid_602429 != nil:
    section.add "Engine", valid_602429
  var valid_602430 = query.getOrDefault("MaxRecords")
  valid_602430 = validateParameter(valid_602430, JInt, required = false, default = nil)
  if valid_602430 != nil:
    section.add "MaxRecords", valid_602430
  var valid_602431 = query.getOrDefault("Filters")
  valid_602431 = validateParameter(valid_602431, JArray, required = false,
                                 default = nil)
  if valid_602431 != nil:
    section.add "Filters", valid_602431
  var valid_602432 = query.getOrDefault("LicenseModel")
  valid_602432 = validateParameter(valid_602432, JString, required = false,
                                 default = nil)
  if valid_602432 != nil:
    section.add "LicenseModel", valid_602432
  var valid_602433 = query.getOrDefault("Vpc")
  valid_602433 = validateParameter(valid_602433, JBool, required = false, default = nil)
  if valid_602433 != nil:
    section.add "Vpc", valid_602433
  var valid_602434 = query.getOrDefault("DBInstanceClass")
  valid_602434 = validateParameter(valid_602434, JString, required = false,
                                 default = nil)
  if valid_602434 != nil:
    section.add "DBInstanceClass", valid_602434
  var valid_602435 = query.getOrDefault("Action")
  valid_602435 = validateParameter(valid_602435, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602435 != nil:
    section.add "Action", valid_602435
  var valid_602436 = query.getOrDefault("Marker")
  valid_602436 = validateParameter(valid_602436, JString, required = false,
                                 default = nil)
  if valid_602436 != nil:
    section.add "Marker", valid_602436
  var valid_602437 = query.getOrDefault("EngineVersion")
  valid_602437 = validateParameter(valid_602437, JString, required = false,
                                 default = nil)
  if valid_602437 != nil:
    section.add "EngineVersion", valid_602437
  var valid_602438 = query.getOrDefault("Version")
  valid_602438 = validateParameter(valid_602438, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602438 != nil:
    section.add "Version", valid_602438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602439 = header.getOrDefault("X-Amz-Date")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "X-Amz-Date", valid_602439
  var valid_602440 = header.getOrDefault("X-Amz-Security-Token")
  valid_602440 = validateParameter(valid_602440, JString, required = false,
                                 default = nil)
  if valid_602440 != nil:
    section.add "X-Amz-Security-Token", valid_602440
  var valid_602441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602441 = validateParameter(valid_602441, JString, required = false,
                                 default = nil)
  if valid_602441 != nil:
    section.add "X-Amz-Content-Sha256", valid_602441
  var valid_602442 = header.getOrDefault("X-Amz-Algorithm")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Algorithm", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Signature")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Signature", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-SignedHeaders", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Credential")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Credential", valid_602445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602446: Call_GetDescribeOrderableDBInstanceOptions_602426;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602446.validator(path, query, header, formData, body)
  let scheme = call_602446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602446.url(scheme.get, call_602446.host, call_602446.base,
                         call_602446.route, valid.getOrDefault("path"))
  result = hook(call_602446, url, valid)

proc call*(call_602447: Call_GetDescribeOrderableDBInstanceOptions_602426;
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
  var query_602448 = newJObject()
  add(query_602448, "Engine", newJString(Engine))
  add(query_602448, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_602448.add "Filters", Filters
  add(query_602448, "LicenseModel", newJString(LicenseModel))
  add(query_602448, "Vpc", newJBool(Vpc))
  add(query_602448, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602448, "Action", newJString(Action))
  add(query_602448, "Marker", newJString(Marker))
  add(query_602448, "EngineVersion", newJString(EngineVersion))
  add(query_602448, "Version", newJString(Version))
  result = call_602447.call(nil, query_602448, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602426(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602427, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_602498 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstances_602500(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_602499(path: JsonNode;
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
  var valid_602501 = query.getOrDefault("Action")
  valid_602501 = validateParameter(valid_602501, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602501 != nil:
    section.add "Action", valid_602501
  var valid_602502 = query.getOrDefault("Version")
  valid_602502 = validateParameter(valid_602502, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602502 != nil:
    section.add "Version", valid_602502
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602503 = header.getOrDefault("X-Amz-Date")
  valid_602503 = validateParameter(valid_602503, JString, required = false,
                                 default = nil)
  if valid_602503 != nil:
    section.add "X-Amz-Date", valid_602503
  var valid_602504 = header.getOrDefault("X-Amz-Security-Token")
  valid_602504 = validateParameter(valid_602504, JString, required = false,
                                 default = nil)
  if valid_602504 != nil:
    section.add "X-Amz-Security-Token", valid_602504
  var valid_602505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602505 = validateParameter(valid_602505, JString, required = false,
                                 default = nil)
  if valid_602505 != nil:
    section.add "X-Amz-Content-Sha256", valid_602505
  var valid_602506 = header.getOrDefault("X-Amz-Algorithm")
  valid_602506 = validateParameter(valid_602506, JString, required = false,
                                 default = nil)
  if valid_602506 != nil:
    section.add "X-Amz-Algorithm", valid_602506
  var valid_602507 = header.getOrDefault("X-Amz-Signature")
  valid_602507 = validateParameter(valid_602507, JString, required = false,
                                 default = nil)
  if valid_602507 != nil:
    section.add "X-Amz-Signature", valid_602507
  var valid_602508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "X-Amz-SignedHeaders", valid_602508
  var valid_602509 = header.getOrDefault("X-Amz-Credential")
  valid_602509 = validateParameter(valid_602509, JString, required = false,
                                 default = nil)
  if valid_602509 != nil:
    section.add "X-Amz-Credential", valid_602509
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
  var valid_602510 = formData.getOrDefault("OfferingType")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "OfferingType", valid_602510
  var valid_602511 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602511 = validateParameter(valid_602511, JString, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "ReservedDBInstanceId", valid_602511
  var valid_602512 = formData.getOrDefault("Marker")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "Marker", valid_602512
  var valid_602513 = formData.getOrDefault("MultiAZ")
  valid_602513 = validateParameter(valid_602513, JBool, required = false, default = nil)
  if valid_602513 != nil:
    section.add "MultiAZ", valid_602513
  var valid_602514 = formData.getOrDefault("Duration")
  valid_602514 = validateParameter(valid_602514, JString, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "Duration", valid_602514
  var valid_602515 = formData.getOrDefault("DBInstanceClass")
  valid_602515 = validateParameter(valid_602515, JString, required = false,
                                 default = nil)
  if valid_602515 != nil:
    section.add "DBInstanceClass", valid_602515
  var valid_602516 = formData.getOrDefault("Filters")
  valid_602516 = validateParameter(valid_602516, JArray, required = false,
                                 default = nil)
  if valid_602516 != nil:
    section.add "Filters", valid_602516
  var valid_602517 = formData.getOrDefault("ProductDescription")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "ProductDescription", valid_602517
  var valid_602518 = formData.getOrDefault("MaxRecords")
  valid_602518 = validateParameter(valid_602518, JInt, required = false, default = nil)
  if valid_602518 != nil:
    section.add "MaxRecords", valid_602518
  var valid_602519 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602519 = validateParameter(valid_602519, JString, required = false,
                                 default = nil)
  if valid_602519 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602519
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602520: Call_PostDescribeReservedDBInstances_602498;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602520.validator(path, query, header, formData, body)
  let scheme = call_602520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602520.url(scheme.get, call_602520.host, call_602520.base,
                         call_602520.route, valid.getOrDefault("path"))
  result = hook(call_602520, url, valid)

proc call*(call_602521: Call_PostDescribeReservedDBInstances_602498;
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
  var query_602522 = newJObject()
  var formData_602523 = newJObject()
  add(formData_602523, "OfferingType", newJString(OfferingType))
  add(formData_602523, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602523, "Marker", newJString(Marker))
  add(formData_602523, "MultiAZ", newJBool(MultiAZ))
  add(query_602522, "Action", newJString(Action))
  add(formData_602523, "Duration", newJString(Duration))
  add(formData_602523, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602523.add "Filters", Filters
  add(formData_602523, "ProductDescription", newJString(ProductDescription))
  add(formData_602523, "MaxRecords", newJInt(MaxRecords))
  add(formData_602523, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602522, "Version", newJString(Version))
  result = call_602521.call(nil, query_602522, nil, formData_602523, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_602498(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_602499, base: "/",
    url: url_PostDescribeReservedDBInstances_602500,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_602473 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstances_602475(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_602474(path: JsonNode;
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
  var valid_602476 = query.getOrDefault("ProductDescription")
  valid_602476 = validateParameter(valid_602476, JString, required = false,
                                 default = nil)
  if valid_602476 != nil:
    section.add "ProductDescription", valid_602476
  var valid_602477 = query.getOrDefault("MaxRecords")
  valid_602477 = validateParameter(valid_602477, JInt, required = false, default = nil)
  if valid_602477 != nil:
    section.add "MaxRecords", valid_602477
  var valid_602478 = query.getOrDefault("OfferingType")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "OfferingType", valid_602478
  var valid_602479 = query.getOrDefault("Filters")
  valid_602479 = validateParameter(valid_602479, JArray, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "Filters", valid_602479
  var valid_602480 = query.getOrDefault("MultiAZ")
  valid_602480 = validateParameter(valid_602480, JBool, required = false, default = nil)
  if valid_602480 != nil:
    section.add "MultiAZ", valid_602480
  var valid_602481 = query.getOrDefault("ReservedDBInstanceId")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "ReservedDBInstanceId", valid_602481
  var valid_602482 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602482
  var valid_602483 = query.getOrDefault("DBInstanceClass")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "DBInstanceClass", valid_602483
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602484 = query.getOrDefault("Action")
  valid_602484 = validateParameter(valid_602484, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602484 != nil:
    section.add "Action", valid_602484
  var valid_602485 = query.getOrDefault("Marker")
  valid_602485 = validateParameter(valid_602485, JString, required = false,
                                 default = nil)
  if valid_602485 != nil:
    section.add "Marker", valid_602485
  var valid_602486 = query.getOrDefault("Duration")
  valid_602486 = validateParameter(valid_602486, JString, required = false,
                                 default = nil)
  if valid_602486 != nil:
    section.add "Duration", valid_602486
  var valid_602487 = query.getOrDefault("Version")
  valid_602487 = validateParameter(valid_602487, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602487 != nil:
    section.add "Version", valid_602487
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602488 = header.getOrDefault("X-Amz-Date")
  valid_602488 = validateParameter(valid_602488, JString, required = false,
                                 default = nil)
  if valid_602488 != nil:
    section.add "X-Amz-Date", valid_602488
  var valid_602489 = header.getOrDefault("X-Amz-Security-Token")
  valid_602489 = validateParameter(valid_602489, JString, required = false,
                                 default = nil)
  if valid_602489 != nil:
    section.add "X-Amz-Security-Token", valid_602489
  var valid_602490 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602490 = validateParameter(valid_602490, JString, required = false,
                                 default = nil)
  if valid_602490 != nil:
    section.add "X-Amz-Content-Sha256", valid_602490
  var valid_602491 = header.getOrDefault("X-Amz-Algorithm")
  valid_602491 = validateParameter(valid_602491, JString, required = false,
                                 default = nil)
  if valid_602491 != nil:
    section.add "X-Amz-Algorithm", valid_602491
  var valid_602492 = header.getOrDefault("X-Amz-Signature")
  valid_602492 = validateParameter(valid_602492, JString, required = false,
                                 default = nil)
  if valid_602492 != nil:
    section.add "X-Amz-Signature", valid_602492
  var valid_602493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-SignedHeaders", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Credential")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Credential", valid_602494
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602495: Call_GetDescribeReservedDBInstances_602473; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602495.validator(path, query, header, formData, body)
  let scheme = call_602495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602495.url(scheme.get, call_602495.host, call_602495.base,
                         call_602495.route, valid.getOrDefault("path"))
  result = hook(call_602495, url, valid)

proc call*(call_602496: Call_GetDescribeReservedDBInstances_602473;
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
  var query_602497 = newJObject()
  add(query_602497, "ProductDescription", newJString(ProductDescription))
  add(query_602497, "MaxRecords", newJInt(MaxRecords))
  add(query_602497, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602497.add "Filters", Filters
  add(query_602497, "MultiAZ", newJBool(MultiAZ))
  add(query_602497, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602497, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602497, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602497, "Action", newJString(Action))
  add(query_602497, "Marker", newJString(Marker))
  add(query_602497, "Duration", newJString(Duration))
  add(query_602497, "Version", newJString(Version))
  result = call_602496.call(nil, query_602497, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_602473(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_602474, base: "/",
    url: url_GetDescribeReservedDBInstances_602475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_602548 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstancesOfferings_602550(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_602549(path: JsonNode;
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
  var valid_602551 = query.getOrDefault("Action")
  valid_602551 = validateParameter(valid_602551, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602551 != nil:
    section.add "Action", valid_602551
  var valid_602552 = query.getOrDefault("Version")
  valid_602552 = validateParameter(valid_602552, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602552 != nil:
    section.add "Version", valid_602552
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602553 = header.getOrDefault("X-Amz-Date")
  valid_602553 = validateParameter(valid_602553, JString, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "X-Amz-Date", valid_602553
  var valid_602554 = header.getOrDefault("X-Amz-Security-Token")
  valid_602554 = validateParameter(valid_602554, JString, required = false,
                                 default = nil)
  if valid_602554 != nil:
    section.add "X-Amz-Security-Token", valid_602554
  var valid_602555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602555 = validateParameter(valid_602555, JString, required = false,
                                 default = nil)
  if valid_602555 != nil:
    section.add "X-Amz-Content-Sha256", valid_602555
  var valid_602556 = header.getOrDefault("X-Amz-Algorithm")
  valid_602556 = validateParameter(valid_602556, JString, required = false,
                                 default = nil)
  if valid_602556 != nil:
    section.add "X-Amz-Algorithm", valid_602556
  var valid_602557 = header.getOrDefault("X-Amz-Signature")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "X-Amz-Signature", valid_602557
  var valid_602558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "X-Amz-SignedHeaders", valid_602558
  var valid_602559 = header.getOrDefault("X-Amz-Credential")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "X-Amz-Credential", valid_602559
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
  var valid_602560 = formData.getOrDefault("OfferingType")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "OfferingType", valid_602560
  var valid_602561 = formData.getOrDefault("Marker")
  valid_602561 = validateParameter(valid_602561, JString, required = false,
                                 default = nil)
  if valid_602561 != nil:
    section.add "Marker", valid_602561
  var valid_602562 = formData.getOrDefault("MultiAZ")
  valid_602562 = validateParameter(valid_602562, JBool, required = false, default = nil)
  if valid_602562 != nil:
    section.add "MultiAZ", valid_602562
  var valid_602563 = formData.getOrDefault("Duration")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "Duration", valid_602563
  var valid_602564 = formData.getOrDefault("DBInstanceClass")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "DBInstanceClass", valid_602564
  var valid_602565 = formData.getOrDefault("Filters")
  valid_602565 = validateParameter(valid_602565, JArray, required = false,
                                 default = nil)
  if valid_602565 != nil:
    section.add "Filters", valid_602565
  var valid_602566 = formData.getOrDefault("ProductDescription")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "ProductDescription", valid_602566
  var valid_602567 = formData.getOrDefault("MaxRecords")
  valid_602567 = validateParameter(valid_602567, JInt, required = false, default = nil)
  if valid_602567 != nil:
    section.add "MaxRecords", valid_602567
  var valid_602568 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602568 = validateParameter(valid_602568, JString, required = false,
                                 default = nil)
  if valid_602568 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602568
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602569: Call_PostDescribeReservedDBInstancesOfferings_602548;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602569.validator(path, query, header, formData, body)
  let scheme = call_602569.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602569.url(scheme.get, call_602569.host, call_602569.base,
                         call_602569.route, valid.getOrDefault("path"))
  result = hook(call_602569, url, valid)

proc call*(call_602570: Call_PostDescribeReservedDBInstancesOfferings_602548;
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
  var query_602571 = newJObject()
  var formData_602572 = newJObject()
  add(formData_602572, "OfferingType", newJString(OfferingType))
  add(formData_602572, "Marker", newJString(Marker))
  add(formData_602572, "MultiAZ", newJBool(MultiAZ))
  add(query_602571, "Action", newJString(Action))
  add(formData_602572, "Duration", newJString(Duration))
  add(formData_602572, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_602572.add "Filters", Filters
  add(formData_602572, "ProductDescription", newJString(ProductDescription))
  add(formData_602572, "MaxRecords", newJInt(MaxRecords))
  add(formData_602572, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602571, "Version", newJString(Version))
  result = call_602570.call(nil, query_602571, nil, formData_602572, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_602548(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_602549,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_602550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_602524 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstancesOfferings_602526(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_602525(path: JsonNode;
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
  var valid_602527 = query.getOrDefault("ProductDescription")
  valid_602527 = validateParameter(valid_602527, JString, required = false,
                                 default = nil)
  if valid_602527 != nil:
    section.add "ProductDescription", valid_602527
  var valid_602528 = query.getOrDefault("MaxRecords")
  valid_602528 = validateParameter(valid_602528, JInt, required = false, default = nil)
  if valid_602528 != nil:
    section.add "MaxRecords", valid_602528
  var valid_602529 = query.getOrDefault("OfferingType")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "OfferingType", valid_602529
  var valid_602530 = query.getOrDefault("Filters")
  valid_602530 = validateParameter(valid_602530, JArray, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "Filters", valid_602530
  var valid_602531 = query.getOrDefault("MultiAZ")
  valid_602531 = validateParameter(valid_602531, JBool, required = false, default = nil)
  if valid_602531 != nil:
    section.add "MultiAZ", valid_602531
  var valid_602532 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602532
  var valid_602533 = query.getOrDefault("DBInstanceClass")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "DBInstanceClass", valid_602533
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602534 = query.getOrDefault("Action")
  valid_602534 = validateParameter(valid_602534, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602534 != nil:
    section.add "Action", valid_602534
  var valid_602535 = query.getOrDefault("Marker")
  valid_602535 = validateParameter(valid_602535, JString, required = false,
                                 default = nil)
  if valid_602535 != nil:
    section.add "Marker", valid_602535
  var valid_602536 = query.getOrDefault("Duration")
  valid_602536 = validateParameter(valid_602536, JString, required = false,
                                 default = nil)
  if valid_602536 != nil:
    section.add "Duration", valid_602536
  var valid_602537 = query.getOrDefault("Version")
  valid_602537 = validateParameter(valid_602537, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602537 != nil:
    section.add "Version", valid_602537
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602538 = header.getOrDefault("X-Amz-Date")
  valid_602538 = validateParameter(valid_602538, JString, required = false,
                                 default = nil)
  if valid_602538 != nil:
    section.add "X-Amz-Date", valid_602538
  var valid_602539 = header.getOrDefault("X-Amz-Security-Token")
  valid_602539 = validateParameter(valid_602539, JString, required = false,
                                 default = nil)
  if valid_602539 != nil:
    section.add "X-Amz-Security-Token", valid_602539
  var valid_602540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602540 = validateParameter(valid_602540, JString, required = false,
                                 default = nil)
  if valid_602540 != nil:
    section.add "X-Amz-Content-Sha256", valid_602540
  var valid_602541 = header.getOrDefault("X-Amz-Algorithm")
  valid_602541 = validateParameter(valid_602541, JString, required = false,
                                 default = nil)
  if valid_602541 != nil:
    section.add "X-Amz-Algorithm", valid_602541
  var valid_602542 = header.getOrDefault("X-Amz-Signature")
  valid_602542 = validateParameter(valid_602542, JString, required = false,
                                 default = nil)
  if valid_602542 != nil:
    section.add "X-Amz-Signature", valid_602542
  var valid_602543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-SignedHeaders", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Credential")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Credential", valid_602544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602545: Call_GetDescribeReservedDBInstancesOfferings_602524;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602545.validator(path, query, header, formData, body)
  let scheme = call_602545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602545.url(scheme.get, call_602545.host, call_602545.base,
                         call_602545.route, valid.getOrDefault("path"))
  result = hook(call_602545, url, valid)

proc call*(call_602546: Call_GetDescribeReservedDBInstancesOfferings_602524;
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
  var query_602547 = newJObject()
  add(query_602547, "ProductDescription", newJString(ProductDescription))
  add(query_602547, "MaxRecords", newJInt(MaxRecords))
  add(query_602547, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_602547.add "Filters", Filters
  add(query_602547, "MultiAZ", newJBool(MultiAZ))
  add(query_602547, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602547, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602547, "Action", newJString(Action))
  add(query_602547, "Marker", newJString(Marker))
  add(query_602547, "Duration", newJString(Duration))
  add(query_602547, "Version", newJString(Version))
  result = call_602546.call(nil, query_602547, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_602524(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_602525, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_602526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_602592 = ref object of OpenApiRestCall_600410
proc url_PostDownloadDBLogFilePortion_602594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_602593(path: JsonNode; query: JsonNode;
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
  var valid_602595 = query.getOrDefault("Action")
  valid_602595 = validateParameter(valid_602595, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602595 != nil:
    section.add "Action", valid_602595
  var valid_602596 = query.getOrDefault("Version")
  valid_602596 = validateParameter(valid_602596, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602596 != nil:
    section.add "Version", valid_602596
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602597 = header.getOrDefault("X-Amz-Date")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Date", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Security-Token")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Security-Token", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-Content-Sha256", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Algorithm")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Algorithm", valid_602600
  var valid_602601 = header.getOrDefault("X-Amz-Signature")
  valid_602601 = validateParameter(valid_602601, JString, required = false,
                                 default = nil)
  if valid_602601 != nil:
    section.add "X-Amz-Signature", valid_602601
  var valid_602602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602602 = validateParameter(valid_602602, JString, required = false,
                                 default = nil)
  if valid_602602 != nil:
    section.add "X-Amz-SignedHeaders", valid_602602
  var valid_602603 = header.getOrDefault("X-Amz-Credential")
  valid_602603 = validateParameter(valid_602603, JString, required = false,
                                 default = nil)
  if valid_602603 != nil:
    section.add "X-Amz-Credential", valid_602603
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_602604 = formData.getOrDefault("NumberOfLines")
  valid_602604 = validateParameter(valid_602604, JInt, required = false, default = nil)
  if valid_602604 != nil:
    section.add "NumberOfLines", valid_602604
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602605 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602605 = validateParameter(valid_602605, JString, required = true,
                                 default = nil)
  if valid_602605 != nil:
    section.add "DBInstanceIdentifier", valid_602605
  var valid_602606 = formData.getOrDefault("Marker")
  valid_602606 = validateParameter(valid_602606, JString, required = false,
                                 default = nil)
  if valid_602606 != nil:
    section.add "Marker", valid_602606
  var valid_602607 = formData.getOrDefault("LogFileName")
  valid_602607 = validateParameter(valid_602607, JString, required = true,
                                 default = nil)
  if valid_602607 != nil:
    section.add "LogFileName", valid_602607
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602608: Call_PostDownloadDBLogFilePortion_602592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602608.validator(path, query, header, formData, body)
  let scheme = call_602608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602608.url(scheme.get, call_602608.host, call_602608.base,
                         call_602608.route, valid.getOrDefault("path"))
  result = hook(call_602608, url, valid)

proc call*(call_602609: Call_PostDownloadDBLogFilePortion_602592;
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
  var query_602610 = newJObject()
  var formData_602611 = newJObject()
  add(formData_602611, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_602611, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602611, "Marker", newJString(Marker))
  add(query_602610, "Action", newJString(Action))
  add(formData_602611, "LogFileName", newJString(LogFileName))
  add(query_602610, "Version", newJString(Version))
  result = call_602609.call(nil, query_602610, nil, formData_602611, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_602592(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_602593, base: "/",
    url: url_PostDownloadDBLogFilePortion_602594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_602573 = ref object of OpenApiRestCall_600410
proc url_GetDownloadDBLogFilePortion_602575(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_602574(path: JsonNode; query: JsonNode;
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
  var valid_602576 = query.getOrDefault("NumberOfLines")
  valid_602576 = validateParameter(valid_602576, JInt, required = false, default = nil)
  if valid_602576 != nil:
    section.add "NumberOfLines", valid_602576
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_602577 = query.getOrDefault("LogFileName")
  valid_602577 = validateParameter(valid_602577, JString, required = true,
                                 default = nil)
  if valid_602577 != nil:
    section.add "LogFileName", valid_602577
  var valid_602578 = query.getOrDefault("Action")
  valid_602578 = validateParameter(valid_602578, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602578 != nil:
    section.add "Action", valid_602578
  var valid_602579 = query.getOrDefault("Marker")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "Marker", valid_602579
  var valid_602580 = query.getOrDefault("Version")
  valid_602580 = validateParameter(valid_602580, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602580 != nil:
    section.add "Version", valid_602580
  var valid_602581 = query.getOrDefault("DBInstanceIdentifier")
  valid_602581 = validateParameter(valid_602581, JString, required = true,
                                 default = nil)
  if valid_602581 != nil:
    section.add "DBInstanceIdentifier", valid_602581
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602582 = header.getOrDefault("X-Amz-Date")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Date", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Security-Token")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Security-Token", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-Content-Sha256", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Algorithm")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Algorithm", valid_602585
  var valid_602586 = header.getOrDefault("X-Amz-Signature")
  valid_602586 = validateParameter(valid_602586, JString, required = false,
                                 default = nil)
  if valid_602586 != nil:
    section.add "X-Amz-Signature", valid_602586
  var valid_602587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602587 = validateParameter(valid_602587, JString, required = false,
                                 default = nil)
  if valid_602587 != nil:
    section.add "X-Amz-SignedHeaders", valid_602587
  var valid_602588 = header.getOrDefault("X-Amz-Credential")
  valid_602588 = validateParameter(valid_602588, JString, required = false,
                                 default = nil)
  if valid_602588 != nil:
    section.add "X-Amz-Credential", valid_602588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602589: Call_GetDownloadDBLogFilePortion_602573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602589.validator(path, query, header, formData, body)
  let scheme = call_602589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602589.url(scheme.get, call_602589.host, call_602589.base,
                         call_602589.route, valid.getOrDefault("path"))
  result = hook(call_602589, url, valid)

proc call*(call_602590: Call_GetDownloadDBLogFilePortion_602573;
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
  var query_602591 = newJObject()
  add(query_602591, "NumberOfLines", newJInt(NumberOfLines))
  add(query_602591, "LogFileName", newJString(LogFileName))
  add(query_602591, "Action", newJString(Action))
  add(query_602591, "Marker", newJString(Marker))
  add(query_602591, "Version", newJString(Version))
  add(query_602591, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602590.call(nil, query_602591, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_602573(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_602574, base: "/",
    url: url_GetDownloadDBLogFilePortion_602575,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602629 = ref object of OpenApiRestCall_600410
proc url_PostListTagsForResource_602631(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_602630(path: JsonNode; query: JsonNode;
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
  var valid_602632 = query.getOrDefault("Action")
  valid_602632 = validateParameter(valid_602632, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602632 != nil:
    section.add "Action", valid_602632
  var valid_602633 = query.getOrDefault("Version")
  valid_602633 = validateParameter(valid_602633, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602633 != nil:
    section.add "Version", valid_602633
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602634 = header.getOrDefault("X-Amz-Date")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Date", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-Security-Token")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-Security-Token", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Content-Sha256", valid_602636
  var valid_602637 = header.getOrDefault("X-Amz-Algorithm")
  valid_602637 = validateParameter(valid_602637, JString, required = false,
                                 default = nil)
  if valid_602637 != nil:
    section.add "X-Amz-Algorithm", valid_602637
  var valid_602638 = header.getOrDefault("X-Amz-Signature")
  valid_602638 = validateParameter(valid_602638, JString, required = false,
                                 default = nil)
  if valid_602638 != nil:
    section.add "X-Amz-Signature", valid_602638
  var valid_602639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "X-Amz-SignedHeaders", valid_602639
  var valid_602640 = header.getOrDefault("X-Amz-Credential")
  valid_602640 = validateParameter(valid_602640, JString, required = false,
                                 default = nil)
  if valid_602640 != nil:
    section.add "X-Amz-Credential", valid_602640
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_602641 = formData.getOrDefault("Filters")
  valid_602641 = validateParameter(valid_602641, JArray, required = false,
                                 default = nil)
  if valid_602641 != nil:
    section.add "Filters", valid_602641
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602642 = formData.getOrDefault("ResourceName")
  valid_602642 = validateParameter(valid_602642, JString, required = true,
                                 default = nil)
  if valid_602642 != nil:
    section.add "ResourceName", valid_602642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602643: Call_PostListTagsForResource_602629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602643.validator(path, query, header, formData, body)
  let scheme = call_602643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602643.url(scheme.get, call_602643.host, call_602643.base,
                         call_602643.route, valid.getOrDefault("path"))
  result = hook(call_602643, url, valid)

proc call*(call_602644: Call_PostListTagsForResource_602629; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602645 = newJObject()
  var formData_602646 = newJObject()
  add(query_602645, "Action", newJString(Action))
  if Filters != nil:
    formData_602646.add "Filters", Filters
  add(formData_602646, "ResourceName", newJString(ResourceName))
  add(query_602645, "Version", newJString(Version))
  result = call_602644.call(nil, query_602645, nil, formData_602646, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602629(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602630, base: "/",
    url: url_PostListTagsForResource_602631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602612 = ref object of OpenApiRestCall_600410
proc url_GetListTagsForResource_602614(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_602613(path: JsonNode; query: JsonNode;
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
  var valid_602615 = query.getOrDefault("Filters")
  valid_602615 = validateParameter(valid_602615, JArray, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "Filters", valid_602615
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_602616 = query.getOrDefault("ResourceName")
  valid_602616 = validateParameter(valid_602616, JString, required = true,
                                 default = nil)
  if valid_602616 != nil:
    section.add "ResourceName", valid_602616
  var valid_602617 = query.getOrDefault("Action")
  valid_602617 = validateParameter(valid_602617, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602617 != nil:
    section.add "Action", valid_602617
  var valid_602618 = query.getOrDefault("Version")
  valid_602618 = validateParameter(valid_602618, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602618 != nil:
    section.add "Version", valid_602618
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602619 = header.getOrDefault("X-Amz-Date")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Date", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-Security-Token")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-Security-Token", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Content-Sha256", valid_602621
  var valid_602622 = header.getOrDefault("X-Amz-Algorithm")
  valid_602622 = validateParameter(valid_602622, JString, required = false,
                                 default = nil)
  if valid_602622 != nil:
    section.add "X-Amz-Algorithm", valid_602622
  var valid_602623 = header.getOrDefault("X-Amz-Signature")
  valid_602623 = validateParameter(valid_602623, JString, required = false,
                                 default = nil)
  if valid_602623 != nil:
    section.add "X-Amz-Signature", valid_602623
  var valid_602624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602624 = validateParameter(valid_602624, JString, required = false,
                                 default = nil)
  if valid_602624 != nil:
    section.add "X-Amz-SignedHeaders", valid_602624
  var valid_602625 = header.getOrDefault("X-Amz-Credential")
  valid_602625 = validateParameter(valid_602625, JString, required = false,
                                 default = nil)
  if valid_602625 != nil:
    section.add "X-Amz-Credential", valid_602625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602626: Call_GetListTagsForResource_602612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602626.validator(path, query, header, formData, body)
  let scheme = call_602626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602626.url(scheme.get, call_602626.host, call_602626.base,
                         call_602626.route, valid.getOrDefault("path"))
  result = hook(call_602626, url, valid)

proc call*(call_602627: Call_GetListTagsForResource_602612; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602628 = newJObject()
  if Filters != nil:
    query_602628.add "Filters", Filters
  add(query_602628, "ResourceName", newJString(ResourceName))
  add(query_602628, "Action", newJString(Action))
  add(query_602628, "Version", newJString(Version))
  result = call_602627.call(nil, query_602628, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602612(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602613, base: "/",
    url: url_GetListTagsForResource_602614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602683 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBInstance_602685(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_602684(path: JsonNode; query: JsonNode;
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
  var valid_602686 = query.getOrDefault("Action")
  valid_602686 = validateParameter(valid_602686, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602686 != nil:
    section.add "Action", valid_602686
  var valid_602687 = query.getOrDefault("Version")
  valid_602687 = validateParameter(valid_602687, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602687 != nil:
    section.add "Version", valid_602687
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602688 = header.getOrDefault("X-Amz-Date")
  valid_602688 = validateParameter(valid_602688, JString, required = false,
                                 default = nil)
  if valid_602688 != nil:
    section.add "X-Amz-Date", valid_602688
  var valid_602689 = header.getOrDefault("X-Amz-Security-Token")
  valid_602689 = validateParameter(valid_602689, JString, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "X-Amz-Security-Token", valid_602689
  var valid_602690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602690 = validateParameter(valid_602690, JString, required = false,
                                 default = nil)
  if valid_602690 != nil:
    section.add "X-Amz-Content-Sha256", valid_602690
  var valid_602691 = header.getOrDefault("X-Amz-Algorithm")
  valid_602691 = validateParameter(valid_602691, JString, required = false,
                                 default = nil)
  if valid_602691 != nil:
    section.add "X-Amz-Algorithm", valid_602691
  var valid_602692 = header.getOrDefault("X-Amz-Signature")
  valid_602692 = validateParameter(valid_602692, JString, required = false,
                                 default = nil)
  if valid_602692 != nil:
    section.add "X-Amz-Signature", valid_602692
  var valid_602693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602693 = validateParameter(valid_602693, JString, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "X-Amz-SignedHeaders", valid_602693
  var valid_602694 = header.getOrDefault("X-Amz-Credential")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Credential", valid_602694
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
  var valid_602695 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "PreferredMaintenanceWindow", valid_602695
  var valid_602696 = formData.getOrDefault("DBSecurityGroups")
  valid_602696 = validateParameter(valid_602696, JArray, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "DBSecurityGroups", valid_602696
  var valid_602697 = formData.getOrDefault("ApplyImmediately")
  valid_602697 = validateParameter(valid_602697, JBool, required = false, default = nil)
  if valid_602697 != nil:
    section.add "ApplyImmediately", valid_602697
  var valid_602698 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602698 = validateParameter(valid_602698, JArray, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "VpcSecurityGroupIds", valid_602698
  var valid_602699 = formData.getOrDefault("Iops")
  valid_602699 = validateParameter(valid_602699, JInt, required = false, default = nil)
  if valid_602699 != nil:
    section.add "Iops", valid_602699
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602700 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602700 = validateParameter(valid_602700, JString, required = true,
                                 default = nil)
  if valid_602700 != nil:
    section.add "DBInstanceIdentifier", valid_602700
  var valid_602701 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602701 = validateParameter(valid_602701, JInt, required = false, default = nil)
  if valid_602701 != nil:
    section.add "BackupRetentionPeriod", valid_602701
  var valid_602702 = formData.getOrDefault("DBParameterGroupName")
  valid_602702 = validateParameter(valid_602702, JString, required = false,
                                 default = nil)
  if valid_602702 != nil:
    section.add "DBParameterGroupName", valid_602702
  var valid_602703 = formData.getOrDefault("OptionGroupName")
  valid_602703 = validateParameter(valid_602703, JString, required = false,
                                 default = nil)
  if valid_602703 != nil:
    section.add "OptionGroupName", valid_602703
  var valid_602704 = formData.getOrDefault("MasterUserPassword")
  valid_602704 = validateParameter(valid_602704, JString, required = false,
                                 default = nil)
  if valid_602704 != nil:
    section.add "MasterUserPassword", valid_602704
  var valid_602705 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602705 = validateParameter(valid_602705, JString, required = false,
                                 default = nil)
  if valid_602705 != nil:
    section.add "NewDBInstanceIdentifier", valid_602705
  var valid_602706 = formData.getOrDefault("TdeCredentialArn")
  valid_602706 = validateParameter(valid_602706, JString, required = false,
                                 default = nil)
  if valid_602706 != nil:
    section.add "TdeCredentialArn", valid_602706
  var valid_602707 = formData.getOrDefault("TdeCredentialPassword")
  valid_602707 = validateParameter(valid_602707, JString, required = false,
                                 default = nil)
  if valid_602707 != nil:
    section.add "TdeCredentialPassword", valid_602707
  var valid_602708 = formData.getOrDefault("MultiAZ")
  valid_602708 = validateParameter(valid_602708, JBool, required = false, default = nil)
  if valid_602708 != nil:
    section.add "MultiAZ", valid_602708
  var valid_602709 = formData.getOrDefault("AllocatedStorage")
  valid_602709 = validateParameter(valid_602709, JInt, required = false, default = nil)
  if valid_602709 != nil:
    section.add "AllocatedStorage", valid_602709
  var valid_602710 = formData.getOrDefault("StorageType")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "StorageType", valid_602710
  var valid_602711 = formData.getOrDefault("DBInstanceClass")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "DBInstanceClass", valid_602711
  var valid_602712 = formData.getOrDefault("PreferredBackupWindow")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "PreferredBackupWindow", valid_602712
  var valid_602713 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602713 = validateParameter(valid_602713, JBool, required = false, default = nil)
  if valid_602713 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602713
  var valid_602714 = formData.getOrDefault("EngineVersion")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "EngineVersion", valid_602714
  var valid_602715 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_602715 = validateParameter(valid_602715, JBool, required = false, default = nil)
  if valid_602715 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602715
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602716: Call_PostModifyDBInstance_602683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602716.validator(path, query, header, formData, body)
  let scheme = call_602716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602716.url(scheme.get, call_602716.host, call_602716.base,
                         call_602716.route, valid.getOrDefault("path"))
  result = hook(call_602716, url, valid)

proc call*(call_602717: Call_PostModifyDBInstance_602683;
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
  var query_602718 = newJObject()
  var formData_602719 = newJObject()
  add(formData_602719, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_602719.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602719, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_602719.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602719, "Iops", newJInt(Iops))
  add(formData_602719, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602719, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602719, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602719, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602719, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602719, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_602719, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_602719, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_602719, "MultiAZ", newJBool(MultiAZ))
  add(query_602718, "Action", newJString(Action))
  add(formData_602719, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_602719, "StorageType", newJString(StorageType))
  add(formData_602719, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602719, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602719, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602719, "EngineVersion", newJString(EngineVersion))
  add(query_602718, "Version", newJString(Version))
  add(formData_602719, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_602717.call(nil, query_602718, nil, formData_602719, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602683(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602684, base: "/",
    url: url_PostModifyDBInstance_602685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602647 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBInstance_602649(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_602648(path: JsonNode; query: JsonNode;
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
  var valid_602650 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "PreferredMaintenanceWindow", valid_602650
  var valid_602651 = query.getOrDefault("AllocatedStorage")
  valid_602651 = validateParameter(valid_602651, JInt, required = false, default = nil)
  if valid_602651 != nil:
    section.add "AllocatedStorage", valid_602651
  var valid_602652 = query.getOrDefault("StorageType")
  valid_602652 = validateParameter(valid_602652, JString, required = false,
                                 default = nil)
  if valid_602652 != nil:
    section.add "StorageType", valid_602652
  var valid_602653 = query.getOrDefault("OptionGroupName")
  valid_602653 = validateParameter(valid_602653, JString, required = false,
                                 default = nil)
  if valid_602653 != nil:
    section.add "OptionGroupName", valid_602653
  var valid_602654 = query.getOrDefault("DBSecurityGroups")
  valid_602654 = validateParameter(valid_602654, JArray, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "DBSecurityGroups", valid_602654
  var valid_602655 = query.getOrDefault("MasterUserPassword")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "MasterUserPassword", valid_602655
  var valid_602656 = query.getOrDefault("Iops")
  valid_602656 = validateParameter(valid_602656, JInt, required = false, default = nil)
  if valid_602656 != nil:
    section.add "Iops", valid_602656
  var valid_602657 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602657 = validateParameter(valid_602657, JArray, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "VpcSecurityGroupIds", valid_602657
  var valid_602658 = query.getOrDefault("MultiAZ")
  valid_602658 = validateParameter(valid_602658, JBool, required = false, default = nil)
  if valid_602658 != nil:
    section.add "MultiAZ", valid_602658
  var valid_602659 = query.getOrDefault("TdeCredentialPassword")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "TdeCredentialPassword", valid_602659
  var valid_602660 = query.getOrDefault("BackupRetentionPeriod")
  valid_602660 = validateParameter(valid_602660, JInt, required = false, default = nil)
  if valid_602660 != nil:
    section.add "BackupRetentionPeriod", valid_602660
  var valid_602661 = query.getOrDefault("DBParameterGroupName")
  valid_602661 = validateParameter(valid_602661, JString, required = false,
                                 default = nil)
  if valid_602661 != nil:
    section.add "DBParameterGroupName", valid_602661
  var valid_602662 = query.getOrDefault("DBInstanceClass")
  valid_602662 = validateParameter(valid_602662, JString, required = false,
                                 default = nil)
  if valid_602662 != nil:
    section.add "DBInstanceClass", valid_602662
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602663 = query.getOrDefault("Action")
  valid_602663 = validateParameter(valid_602663, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602663 != nil:
    section.add "Action", valid_602663
  var valid_602664 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_602664 = validateParameter(valid_602664, JBool, required = false, default = nil)
  if valid_602664 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602664
  var valid_602665 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602665 = validateParameter(valid_602665, JString, required = false,
                                 default = nil)
  if valid_602665 != nil:
    section.add "NewDBInstanceIdentifier", valid_602665
  var valid_602666 = query.getOrDefault("TdeCredentialArn")
  valid_602666 = validateParameter(valid_602666, JString, required = false,
                                 default = nil)
  if valid_602666 != nil:
    section.add "TdeCredentialArn", valid_602666
  var valid_602667 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602667 = validateParameter(valid_602667, JBool, required = false, default = nil)
  if valid_602667 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602667
  var valid_602668 = query.getOrDefault("EngineVersion")
  valid_602668 = validateParameter(valid_602668, JString, required = false,
                                 default = nil)
  if valid_602668 != nil:
    section.add "EngineVersion", valid_602668
  var valid_602669 = query.getOrDefault("PreferredBackupWindow")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "PreferredBackupWindow", valid_602669
  var valid_602670 = query.getOrDefault("Version")
  valid_602670 = validateParameter(valid_602670, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602670 != nil:
    section.add "Version", valid_602670
  var valid_602671 = query.getOrDefault("DBInstanceIdentifier")
  valid_602671 = validateParameter(valid_602671, JString, required = true,
                                 default = nil)
  if valid_602671 != nil:
    section.add "DBInstanceIdentifier", valid_602671
  var valid_602672 = query.getOrDefault("ApplyImmediately")
  valid_602672 = validateParameter(valid_602672, JBool, required = false, default = nil)
  if valid_602672 != nil:
    section.add "ApplyImmediately", valid_602672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602673 = header.getOrDefault("X-Amz-Date")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Date", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-Security-Token")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-Security-Token", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Content-Sha256", valid_602675
  var valid_602676 = header.getOrDefault("X-Amz-Algorithm")
  valid_602676 = validateParameter(valid_602676, JString, required = false,
                                 default = nil)
  if valid_602676 != nil:
    section.add "X-Amz-Algorithm", valid_602676
  var valid_602677 = header.getOrDefault("X-Amz-Signature")
  valid_602677 = validateParameter(valid_602677, JString, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "X-Amz-Signature", valid_602677
  var valid_602678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "X-Amz-SignedHeaders", valid_602678
  var valid_602679 = header.getOrDefault("X-Amz-Credential")
  valid_602679 = validateParameter(valid_602679, JString, required = false,
                                 default = nil)
  if valid_602679 != nil:
    section.add "X-Amz-Credential", valid_602679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602680: Call_GetModifyDBInstance_602647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602680.validator(path, query, header, formData, body)
  let scheme = call_602680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602680.url(scheme.get, call_602680.host, call_602680.base,
                         call_602680.route, valid.getOrDefault("path"))
  result = hook(call_602680, url, valid)

proc call*(call_602681: Call_GetModifyDBInstance_602647;
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
  var query_602682 = newJObject()
  add(query_602682, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602682, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602682, "StorageType", newJString(StorageType))
  add(query_602682, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_602682.add "DBSecurityGroups", DBSecurityGroups
  add(query_602682, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602682, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_602682.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602682, "MultiAZ", newJBool(MultiAZ))
  add(query_602682, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_602682, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602682, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602682, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602682, "Action", newJString(Action))
  add(query_602682, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_602682, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602682, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_602682, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602682, "EngineVersion", newJString(EngineVersion))
  add(query_602682, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602682, "Version", newJString(Version))
  add(query_602682, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602682, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602681.call(nil, query_602682, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602647(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602648, base: "/",
    url: url_GetModifyDBInstance_602649, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_602737 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBParameterGroup_602739(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_602738(path: JsonNode; query: JsonNode;
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
  var valid_602740 = query.getOrDefault("Action")
  valid_602740 = validateParameter(valid_602740, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602740 != nil:
    section.add "Action", valid_602740
  var valid_602741 = query.getOrDefault("Version")
  valid_602741 = validateParameter(valid_602741, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602741 != nil:
    section.add "Version", valid_602741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602742 = header.getOrDefault("X-Amz-Date")
  valid_602742 = validateParameter(valid_602742, JString, required = false,
                                 default = nil)
  if valid_602742 != nil:
    section.add "X-Amz-Date", valid_602742
  var valid_602743 = header.getOrDefault("X-Amz-Security-Token")
  valid_602743 = validateParameter(valid_602743, JString, required = false,
                                 default = nil)
  if valid_602743 != nil:
    section.add "X-Amz-Security-Token", valid_602743
  var valid_602744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602744 = validateParameter(valid_602744, JString, required = false,
                                 default = nil)
  if valid_602744 != nil:
    section.add "X-Amz-Content-Sha256", valid_602744
  var valid_602745 = header.getOrDefault("X-Amz-Algorithm")
  valid_602745 = validateParameter(valid_602745, JString, required = false,
                                 default = nil)
  if valid_602745 != nil:
    section.add "X-Amz-Algorithm", valid_602745
  var valid_602746 = header.getOrDefault("X-Amz-Signature")
  valid_602746 = validateParameter(valid_602746, JString, required = false,
                                 default = nil)
  if valid_602746 != nil:
    section.add "X-Amz-Signature", valid_602746
  var valid_602747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-SignedHeaders", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Credential")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Credential", valid_602748
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602749 = formData.getOrDefault("DBParameterGroupName")
  valid_602749 = validateParameter(valid_602749, JString, required = true,
                                 default = nil)
  if valid_602749 != nil:
    section.add "DBParameterGroupName", valid_602749
  var valid_602750 = formData.getOrDefault("Parameters")
  valid_602750 = validateParameter(valid_602750, JArray, required = true, default = nil)
  if valid_602750 != nil:
    section.add "Parameters", valid_602750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602751: Call_PostModifyDBParameterGroup_602737; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602751.validator(path, query, header, formData, body)
  let scheme = call_602751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602751.url(scheme.get, call_602751.host, call_602751.base,
                         call_602751.route, valid.getOrDefault("path"))
  result = hook(call_602751, url, valid)

proc call*(call_602752: Call_PostModifyDBParameterGroup_602737;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602753 = newJObject()
  var formData_602754 = newJObject()
  add(formData_602754, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602754.add "Parameters", Parameters
  add(query_602753, "Action", newJString(Action))
  add(query_602753, "Version", newJString(Version))
  result = call_602752.call(nil, query_602753, nil, formData_602754, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_602737(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_602738, base: "/",
    url: url_PostModifyDBParameterGroup_602739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_602720 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBParameterGroup_602722(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_602721(path: JsonNode; query: JsonNode;
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
  var valid_602723 = query.getOrDefault("DBParameterGroupName")
  valid_602723 = validateParameter(valid_602723, JString, required = true,
                                 default = nil)
  if valid_602723 != nil:
    section.add "DBParameterGroupName", valid_602723
  var valid_602724 = query.getOrDefault("Parameters")
  valid_602724 = validateParameter(valid_602724, JArray, required = true, default = nil)
  if valid_602724 != nil:
    section.add "Parameters", valid_602724
  var valid_602725 = query.getOrDefault("Action")
  valid_602725 = validateParameter(valid_602725, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602725 != nil:
    section.add "Action", valid_602725
  var valid_602726 = query.getOrDefault("Version")
  valid_602726 = validateParameter(valid_602726, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602726 != nil:
    section.add "Version", valid_602726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602727 = header.getOrDefault("X-Amz-Date")
  valid_602727 = validateParameter(valid_602727, JString, required = false,
                                 default = nil)
  if valid_602727 != nil:
    section.add "X-Amz-Date", valid_602727
  var valid_602728 = header.getOrDefault("X-Amz-Security-Token")
  valid_602728 = validateParameter(valid_602728, JString, required = false,
                                 default = nil)
  if valid_602728 != nil:
    section.add "X-Amz-Security-Token", valid_602728
  var valid_602729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "X-Amz-Content-Sha256", valid_602729
  var valid_602730 = header.getOrDefault("X-Amz-Algorithm")
  valid_602730 = validateParameter(valid_602730, JString, required = false,
                                 default = nil)
  if valid_602730 != nil:
    section.add "X-Amz-Algorithm", valid_602730
  var valid_602731 = header.getOrDefault("X-Amz-Signature")
  valid_602731 = validateParameter(valid_602731, JString, required = false,
                                 default = nil)
  if valid_602731 != nil:
    section.add "X-Amz-Signature", valid_602731
  var valid_602732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-SignedHeaders", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Credential")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Credential", valid_602733
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602734: Call_GetModifyDBParameterGroup_602720; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602734.validator(path, query, header, formData, body)
  let scheme = call_602734.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602734.url(scheme.get, call_602734.host, call_602734.base,
                         call_602734.route, valid.getOrDefault("path"))
  result = hook(call_602734, url, valid)

proc call*(call_602735: Call_GetModifyDBParameterGroup_602720;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602736 = newJObject()
  add(query_602736, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602736.add "Parameters", Parameters
  add(query_602736, "Action", newJString(Action))
  add(query_602736, "Version", newJString(Version))
  result = call_602735.call(nil, query_602736, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_602720(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_602721, base: "/",
    url: url_GetModifyDBParameterGroup_602722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602773 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBSubnetGroup_602775(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_602774(path: JsonNode; query: JsonNode;
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
  var valid_602776 = query.getOrDefault("Action")
  valid_602776 = validateParameter(valid_602776, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602776 != nil:
    section.add "Action", valid_602776
  var valid_602777 = query.getOrDefault("Version")
  valid_602777 = validateParameter(valid_602777, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602777 != nil:
    section.add "Version", valid_602777
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602778 = header.getOrDefault("X-Amz-Date")
  valid_602778 = validateParameter(valid_602778, JString, required = false,
                                 default = nil)
  if valid_602778 != nil:
    section.add "X-Amz-Date", valid_602778
  var valid_602779 = header.getOrDefault("X-Amz-Security-Token")
  valid_602779 = validateParameter(valid_602779, JString, required = false,
                                 default = nil)
  if valid_602779 != nil:
    section.add "X-Amz-Security-Token", valid_602779
  var valid_602780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602780 = validateParameter(valid_602780, JString, required = false,
                                 default = nil)
  if valid_602780 != nil:
    section.add "X-Amz-Content-Sha256", valid_602780
  var valid_602781 = header.getOrDefault("X-Amz-Algorithm")
  valid_602781 = validateParameter(valid_602781, JString, required = false,
                                 default = nil)
  if valid_602781 != nil:
    section.add "X-Amz-Algorithm", valid_602781
  var valid_602782 = header.getOrDefault("X-Amz-Signature")
  valid_602782 = validateParameter(valid_602782, JString, required = false,
                                 default = nil)
  if valid_602782 != nil:
    section.add "X-Amz-Signature", valid_602782
  var valid_602783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602783 = validateParameter(valid_602783, JString, required = false,
                                 default = nil)
  if valid_602783 != nil:
    section.add "X-Amz-SignedHeaders", valid_602783
  var valid_602784 = header.getOrDefault("X-Amz-Credential")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Credential", valid_602784
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602785 = formData.getOrDefault("DBSubnetGroupName")
  valid_602785 = validateParameter(valid_602785, JString, required = true,
                                 default = nil)
  if valid_602785 != nil:
    section.add "DBSubnetGroupName", valid_602785
  var valid_602786 = formData.getOrDefault("SubnetIds")
  valid_602786 = validateParameter(valid_602786, JArray, required = true, default = nil)
  if valid_602786 != nil:
    section.add "SubnetIds", valid_602786
  var valid_602787 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "DBSubnetGroupDescription", valid_602787
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602788: Call_PostModifyDBSubnetGroup_602773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602788.validator(path, query, header, formData, body)
  let scheme = call_602788.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602788.url(scheme.get, call_602788.host, call_602788.base,
                         call_602788.route, valid.getOrDefault("path"))
  result = hook(call_602788, url, valid)

proc call*(call_602789: Call_PostModifyDBSubnetGroup_602773;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602790 = newJObject()
  var formData_602791 = newJObject()
  add(formData_602791, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602791.add "SubnetIds", SubnetIds
  add(query_602790, "Action", newJString(Action))
  add(formData_602791, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602790, "Version", newJString(Version))
  result = call_602789.call(nil, query_602790, nil, formData_602791, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602773(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602774, base: "/",
    url: url_PostModifyDBSubnetGroup_602775, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602755 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBSubnetGroup_602757(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_602756(path: JsonNode; query: JsonNode;
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
  var valid_602758 = query.getOrDefault("Action")
  valid_602758 = validateParameter(valid_602758, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602758 != nil:
    section.add "Action", valid_602758
  var valid_602759 = query.getOrDefault("DBSubnetGroupName")
  valid_602759 = validateParameter(valid_602759, JString, required = true,
                                 default = nil)
  if valid_602759 != nil:
    section.add "DBSubnetGroupName", valid_602759
  var valid_602760 = query.getOrDefault("SubnetIds")
  valid_602760 = validateParameter(valid_602760, JArray, required = true, default = nil)
  if valid_602760 != nil:
    section.add "SubnetIds", valid_602760
  var valid_602761 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602761 = validateParameter(valid_602761, JString, required = false,
                                 default = nil)
  if valid_602761 != nil:
    section.add "DBSubnetGroupDescription", valid_602761
  var valid_602762 = query.getOrDefault("Version")
  valid_602762 = validateParameter(valid_602762, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602762 != nil:
    section.add "Version", valid_602762
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602763 = header.getOrDefault("X-Amz-Date")
  valid_602763 = validateParameter(valid_602763, JString, required = false,
                                 default = nil)
  if valid_602763 != nil:
    section.add "X-Amz-Date", valid_602763
  var valid_602764 = header.getOrDefault("X-Amz-Security-Token")
  valid_602764 = validateParameter(valid_602764, JString, required = false,
                                 default = nil)
  if valid_602764 != nil:
    section.add "X-Amz-Security-Token", valid_602764
  var valid_602765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "X-Amz-Content-Sha256", valid_602765
  var valid_602766 = header.getOrDefault("X-Amz-Algorithm")
  valid_602766 = validateParameter(valid_602766, JString, required = false,
                                 default = nil)
  if valid_602766 != nil:
    section.add "X-Amz-Algorithm", valid_602766
  var valid_602767 = header.getOrDefault("X-Amz-Signature")
  valid_602767 = validateParameter(valid_602767, JString, required = false,
                                 default = nil)
  if valid_602767 != nil:
    section.add "X-Amz-Signature", valid_602767
  var valid_602768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602768 = validateParameter(valid_602768, JString, required = false,
                                 default = nil)
  if valid_602768 != nil:
    section.add "X-Amz-SignedHeaders", valid_602768
  var valid_602769 = header.getOrDefault("X-Amz-Credential")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Credential", valid_602769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602770: Call_GetModifyDBSubnetGroup_602755; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602770.validator(path, query, header, formData, body)
  let scheme = call_602770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602770.url(scheme.get, call_602770.host, call_602770.base,
                         call_602770.route, valid.getOrDefault("path"))
  result = hook(call_602770, url, valid)

proc call*(call_602771: Call_GetModifyDBSubnetGroup_602755;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602772 = newJObject()
  add(query_602772, "Action", newJString(Action))
  add(query_602772, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602772.add "SubnetIds", SubnetIds
  add(query_602772, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602772, "Version", newJString(Version))
  result = call_602771.call(nil, query_602772, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602755(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602756, base: "/",
    url: url_GetModifyDBSubnetGroup_602757, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_602812 = ref object of OpenApiRestCall_600410
proc url_PostModifyEventSubscription_602814(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_602813(path: JsonNode; query: JsonNode;
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
  var valid_602815 = query.getOrDefault("Action")
  valid_602815 = validateParameter(valid_602815, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602815 != nil:
    section.add "Action", valid_602815
  var valid_602816 = query.getOrDefault("Version")
  valid_602816 = validateParameter(valid_602816, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602816 != nil:
    section.add "Version", valid_602816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602817 = header.getOrDefault("X-Amz-Date")
  valid_602817 = validateParameter(valid_602817, JString, required = false,
                                 default = nil)
  if valid_602817 != nil:
    section.add "X-Amz-Date", valid_602817
  var valid_602818 = header.getOrDefault("X-Amz-Security-Token")
  valid_602818 = validateParameter(valid_602818, JString, required = false,
                                 default = nil)
  if valid_602818 != nil:
    section.add "X-Amz-Security-Token", valid_602818
  var valid_602819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602819 = validateParameter(valid_602819, JString, required = false,
                                 default = nil)
  if valid_602819 != nil:
    section.add "X-Amz-Content-Sha256", valid_602819
  var valid_602820 = header.getOrDefault("X-Amz-Algorithm")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Algorithm", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Signature")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Signature", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-SignedHeaders", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Credential")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Credential", valid_602823
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_602824 = formData.getOrDefault("Enabled")
  valid_602824 = validateParameter(valid_602824, JBool, required = false, default = nil)
  if valid_602824 != nil:
    section.add "Enabled", valid_602824
  var valid_602825 = formData.getOrDefault("EventCategories")
  valid_602825 = validateParameter(valid_602825, JArray, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "EventCategories", valid_602825
  var valid_602826 = formData.getOrDefault("SnsTopicArn")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "SnsTopicArn", valid_602826
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602827 = formData.getOrDefault("SubscriptionName")
  valid_602827 = validateParameter(valid_602827, JString, required = true,
                                 default = nil)
  if valid_602827 != nil:
    section.add "SubscriptionName", valid_602827
  var valid_602828 = formData.getOrDefault("SourceType")
  valid_602828 = validateParameter(valid_602828, JString, required = false,
                                 default = nil)
  if valid_602828 != nil:
    section.add "SourceType", valid_602828
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602829: Call_PostModifyEventSubscription_602812; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602829.validator(path, query, header, formData, body)
  let scheme = call_602829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602829.url(scheme.get, call_602829.host, call_602829.base,
                         call_602829.route, valid.getOrDefault("path"))
  result = hook(call_602829, url, valid)

proc call*(call_602830: Call_PostModifyEventSubscription_602812;
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
  var query_602831 = newJObject()
  var formData_602832 = newJObject()
  add(formData_602832, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_602832.add "EventCategories", EventCategories
  add(formData_602832, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602832, "SubscriptionName", newJString(SubscriptionName))
  add(query_602831, "Action", newJString(Action))
  add(query_602831, "Version", newJString(Version))
  add(formData_602832, "SourceType", newJString(SourceType))
  result = call_602830.call(nil, query_602831, nil, formData_602832, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_602812(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_602813, base: "/",
    url: url_PostModifyEventSubscription_602814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_602792 = ref object of OpenApiRestCall_600410
proc url_GetModifyEventSubscription_602794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_602793(path: JsonNode; query: JsonNode;
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
  var valid_602795 = query.getOrDefault("SourceType")
  valid_602795 = validateParameter(valid_602795, JString, required = false,
                                 default = nil)
  if valid_602795 != nil:
    section.add "SourceType", valid_602795
  var valid_602796 = query.getOrDefault("Enabled")
  valid_602796 = validateParameter(valid_602796, JBool, required = false, default = nil)
  if valid_602796 != nil:
    section.add "Enabled", valid_602796
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602797 = query.getOrDefault("Action")
  valid_602797 = validateParameter(valid_602797, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602797 != nil:
    section.add "Action", valid_602797
  var valid_602798 = query.getOrDefault("SnsTopicArn")
  valid_602798 = validateParameter(valid_602798, JString, required = false,
                                 default = nil)
  if valid_602798 != nil:
    section.add "SnsTopicArn", valid_602798
  var valid_602799 = query.getOrDefault("EventCategories")
  valid_602799 = validateParameter(valid_602799, JArray, required = false,
                                 default = nil)
  if valid_602799 != nil:
    section.add "EventCategories", valid_602799
  var valid_602800 = query.getOrDefault("SubscriptionName")
  valid_602800 = validateParameter(valid_602800, JString, required = true,
                                 default = nil)
  if valid_602800 != nil:
    section.add "SubscriptionName", valid_602800
  var valid_602801 = query.getOrDefault("Version")
  valid_602801 = validateParameter(valid_602801, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602801 != nil:
    section.add "Version", valid_602801
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602802 = header.getOrDefault("X-Amz-Date")
  valid_602802 = validateParameter(valid_602802, JString, required = false,
                                 default = nil)
  if valid_602802 != nil:
    section.add "X-Amz-Date", valid_602802
  var valid_602803 = header.getOrDefault("X-Amz-Security-Token")
  valid_602803 = validateParameter(valid_602803, JString, required = false,
                                 default = nil)
  if valid_602803 != nil:
    section.add "X-Amz-Security-Token", valid_602803
  var valid_602804 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602804 = validateParameter(valid_602804, JString, required = false,
                                 default = nil)
  if valid_602804 != nil:
    section.add "X-Amz-Content-Sha256", valid_602804
  var valid_602805 = header.getOrDefault("X-Amz-Algorithm")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Algorithm", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-Signature")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Signature", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-SignedHeaders", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-Credential")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Credential", valid_602808
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602809: Call_GetModifyEventSubscription_602792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602809.validator(path, query, header, formData, body)
  let scheme = call_602809.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602809.url(scheme.get, call_602809.host, call_602809.base,
                         call_602809.route, valid.getOrDefault("path"))
  result = hook(call_602809, url, valid)

proc call*(call_602810: Call_GetModifyEventSubscription_602792;
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
  var query_602811 = newJObject()
  add(query_602811, "SourceType", newJString(SourceType))
  add(query_602811, "Enabled", newJBool(Enabled))
  add(query_602811, "Action", newJString(Action))
  add(query_602811, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_602811.add "EventCategories", EventCategories
  add(query_602811, "SubscriptionName", newJString(SubscriptionName))
  add(query_602811, "Version", newJString(Version))
  result = call_602810.call(nil, query_602811, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_602792(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_602793, base: "/",
    url: url_GetModifyEventSubscription_602794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_602852 = ref object of OpenApiRestCall_600410
proc url_PostModifyOptionGroup_602854(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_602853(path: JsonNode; query: JsonNode;
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
  var valid_602855 = query.getOrDefault("Action")
  valid_602855 = validateParameter(valid_602855, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602855 != nil:
    section.add "Action", valid_602855
  var valid_602856 = query.getOrDefault("Version")
  valid_602856 = validateParameter(valid_602856, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602856 != nil:
    section.add "Version", valid_602856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602857 = header.getOrDefault("X-Amz-Date")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Date", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Security-Token")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Security-Token", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Content-Sha256", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-Algorithm")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-Algorithm", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Signature")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Signature", valid_602861
  var valid_602862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602862 = validateParameter(valid_602862, JString, required = false,
                                 default = nil)
  if valid_602862 != nil:
    section.add "X-Amz-SignedHeaders", valid_602862
  var valid_602863 = header.getOrDefault("X-Amz-Credential")
  valid_602863 = validateParameter(valid_602863, JString, required = false,
                                 default = nil)
  if valid_602863 != nil:
    section.add "X-Amz-Credential", valid_602863
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_602864 = formData.getOrDefault("OptionsToRemove")
  valid_602864 = validateParameter(valid_602864, JArray, required = false,
                                 default = nil)
  if valid_602864 != nil:
    section.add "OptionsToRemove", valid_602864
  var valid_602865 = formData.getOrDefault("ApplyImmediately")
  valid_602865 = validateParameter(valid_602865, JBool, required = false, default = nil)
  if valid_602865 != nil:
    section.add "ApplyImmediately", valid_602865
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602866 = formData.getOrDefault("OptionGroupName")
  valid_602866 = validateParameter(valid_602866, JString, required = true,
                                 default = nil)
  if valid_602866 != nil:
    section.add "OptionGroupName", valid_602866
  var valid_602867 = formData.getOrDefault("OptionsToInclude")
  valid_602867 = validateParameter(valid_602867, JArray, required = false,
                                 default = nil)
  if valid_602867 != nil:
    section.add "OptionsToInclude", valid_602867
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602868: Call_PostModifyOptionGroup_602852; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602868.validator(path, query, header, formData, body)
  let scheme = call_602868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602868.url(scheme.get, call_602868.host, call_602868.base,
                         call_602868.route, valid.getOrDefault("path"))
  result = hook(call_602868, url, valid)

proc call*(call_602869: Call_PostModifyOptionGroup_602852; OptionGroupName: string;
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
  var query_602870 = newJObject()
  var formData_602871 = newJObject()
  if OptionsToRemove != nil:
    formData_602871.add "OptionsToRemove", OptionsToRemove
  add(formData_602871, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602871, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_602871.add "OptionsToInclude", OptionsToInclude
  add(query_602870, "Action", newJString(Action))
  add(query_602870, "Version", newJString(Version))
  result = call_602869.call(nil, query_602870, nil, formData_602871, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_602852(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_602853, base: "/",
    url: url_PostModifyOptionGroup_602854, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_602833 = ref object of OpenApiRestCall_600410
proc url_GetModifyOptionGroup_602835(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_602834(path: JsonNode; query: JsonNode;
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
  var valid_602836 = query.getOrDefault("OptionGroupName")
  valid_602836 = validateParameter(valid_602836, JString, required = true,
                                 default = nil)
  if valid_602836 != nil:
    section.add "OptionGroupName", valid_602836
  var valid_602837 = query.getOrDefault("OptionsToRemove")
  valid_602837 = validateParameter(valid_602837, JArray, required = false,
                                 default = nil)
  if valid_602837 != nil:
    section.add "OptionsToRemove", valid_602837
  var valid_602838 = query.getOrDefault("Action")
  valid_602838 = validateParameter(valid_602838, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602838 != nil:
    section.add "Action", valid_602838
  var valid_602839 = query.getOrDefault("Version")
  valid_602839 = validateParameter(valid_602839, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602839 != nil:
    section.add "Version", valid_602839
  var valid_602840 = query.getOrDefault("ApplyImmediately")
  valid_602840 = validateParameter(valid_602840, JBool, required = false, default = nil)
  if valid_602840 != nil:
    section.add "ApplyImmediately", valid_602840
  var valid_602841 = query.getOrDefault("OptionsToInclude")
  valid_602841 = validateParameter(valid_602841, JArray, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "OptionsToInclude", valid_602841
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602842 = header.getOrDefault("X-Amz-Date")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-Date", valid_602842
  var valid_602843 = header.getOrDefault("X-Amz-Security-Token")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Security-Token", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Content-Sha256", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-Algorithm")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-Algorithm", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Signature")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Signature", valid_602846
  var valid_602847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602847 = validateParameter(valid_602847, JString, required = false,
                                 default = nil)
  if valid_602847 != nil:
    section.add "X-Amz-SignedHeaders", valid_602847
  var valid_602848 = header.getOrDefault("X-Amz-Credential")
  valid_602848 = validateParameter(valid_602848, JString, required = false,
                                 default = nil)
  if valid_602848 != nil:
    section.add "X-Amz-Credential", valid_602848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602849: Call_GetModifyOptionGroup_602833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602849.validator(path, query, header, formData, body)
  let scheme = call_602849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602849.url(scheme.get, call_602849.host, call_602849.base,
                         call_602849.route, valid.getOrDefault("path"))
  result = hook(call_602849, url, valid)

proc call*(call_602850: Call_GetModifyOptionGroup_602833; OptionGroupName: string;
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
  var query_602851 = newJObject()
  add(query_602851, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_602851.add "OptionsToRemove", OptionsToRemove
  add(query_602851, "Action", newJString(Action))
  add(query_602851, "Version", newJString(Version))
  add(query_602851, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_602851.add "OptionsToInclude", OptionsToInclude
  result = call_602850.call(nil, query_602851, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_602833(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_602834, base: "/",
    url: url_GetModifyOptionGroup_602835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_602890 = ref object of OpenApiRestCall_600410
proc url_PostPromoteReadReplica_602892(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_602891(path: JsonNode; query: JsonNode;
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
  var valid_602893 = query.getOrDefault("Action")
  valid_602893 = validateParameter(valid_602893, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602893 != nil:
    section.add "Action", valid_602893
  var valid_602894 = query.getOrDefault("Version")
  valid_602894 = validateParameter(valid_602894, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602894 != nil:
    section.add "Version", valid_602894
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602895 = header.getOrDefault("X-Amz-Date")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-Date", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Security-Token")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Security-Token", valid_602896
  var valid_602897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602897 = validateParameter(valid_602897, JString, required = false,
                                 default = nil)
  if valid_602897 != nil:
    section.add "X-Amz-Content-Sha256", valid_602897
  var valid_602898 = header.getOrDefault("X-Amz-Algorithm")
  valid_602898 = validateParameter(valid_602898, JString, required = false,
                                 default = nil)
  if valid_602898 != nil:
    section.add "X-Amz-Algorithm", valid_602898
  var valid_602899 = header.getOrDefault("X-Amz-Signature")
  valid_602899 = validateParameter(valid_602899, JString, required = false,
                                 default = nil)
  if valid_602899 != nil:
    section.add "X-Amz-Signature", valid_602899
  var valid_602900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-SignedHeaders", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Credential")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Credential", valid_602901
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602902 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602902 = validateParameter(valid_602902, JString, required = true,
                                 default = nil)
  if valid_602902 != nil:
    section.add "DBInstanceIdentifier", valid_602902
  var valid_602903 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602903 = validateParameter(valid_602903, JInt, required = false, default = nil)
  if valid_602903 != nil:
    section.add "BackupRetentionPeriod", valid_602903
  var valid_602904 = formData.getOrDefault("PreferredBackupWindow")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "PreferredBackupWindow", valid_602904
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602905: Call_PostPromoteReadReplica_602890; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602905.validator(path, query, header, formData, body)
  let scheme = call_602905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602905.url(scheme.get, call_602905.host, call_602905.base,
                         call_602905.route, valid.getOrDefault("path"))
  result = hook(call_602905, url, valid)

proc call*(call_602906: Call_PostPromoteReadReplica_602890;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_602907 = newJObject()
  var formData_602908 = newJObject()
  add(formData_602908, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602908, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602907, "Action", newJString(Action))
  add(formData_602908, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602907, "Version", newJString(Version))
  result = call_602906.call(nil, query_602907, nil, formData_602908, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_602890(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_602891, base: "/",
    url: url_PostPromoteReadReplica_602892, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_602872 = ref object of OpenApiRestCall_600410
proc url_GetPromoteReadReplica_602874(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_602873(path: JsonNode; query: JsonNode;
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
  var valid_602875 = query.getOrDefault("BackupRetentionPeriod")
  valid_602875 = validateParameter(valid_602875, JInt, required = false, default = nil)
  if valid_602875 != nil:
    section.add "BackupRetentionPeriod", valid_602875
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602876 = query.getOrDefault("Action")
  valid_602876 = validateParameter(valid_602876, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602876 != nil:
    section.add "Action", valid_602876
  var valid_602877 = query.getOrDefault("PreferredBackupWindow")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "PreferredBackupWindow", valid_602877
  var valid_602878 = query.getOrDefault("Version")
  valid_602878 = validateParameter(valid_602878, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602878 != nil:
    section.add "Version", valid_602878
  var valid_602879 = query.getOrDefault("DBInstanceIdentifier")
  valid_602879 = validateParameter(valid_602879, JString, required = true,
                                 default = nil)
  if valid_602879 != nil:
    section.add "DBInstanceIdentifier", valid_602879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602880 = header.getOrDefault("X-Amz-Date")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-Date", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Security-Token")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Security-Token", valid_602881
  var valid_602882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602882 = validateParameter(valid_602882, JString, required = false,
                                 default = nil)
  if valid_602882 != nil:
    section.add "X-Amz-Content-Sha256", valid_602882
  var valid_602883 = header.getOrDefault("X-Amz-Algorithm")
  valid_602883 = validateParameter(valid_602883, JString, required = false,
                                 default = nil)
  if valid_602883 != nil:
    section.add "X-Amz-Algorithm", valid_602883
  var valid_602884 = header.getOrDefault("X-Amz-Signature")
  valid_602884 = validateParameter(valid_602884, JString, required = false,
                                 default = nil)
  if valid_602884 != nil:
    section.add "X-Amz-Signature", valid_602884
  var valid_602885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-SignedHeaders", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Credential")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Credential", valid_602886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602887: Call_GetPromoteReadReplica_602872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602887.validator(path, query, header, formData, body)
  let scheme = call_602887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602887.url(scheme.get, call_602887.host, call_602887.base,
                         call_602887.route, valid.getOrDefault("path"))
  result = hook(call_602887, url, valid)

proc call*(call_602888: Call_GetPromoteReadReplica_602872;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602889 = newJObject()
  add(query_602889, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602889, "Action", newJString(Action))
  add(query_602889, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602889, "Version", newJString(Version))
  add(query_602889, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602888.call(nil, query_602889, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_602872(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_602873, base: "/",
    url: url_GetPromoteReadReplica_602874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_602928 = ref object of OpenApiRestCall_600410
proc url_PostPurchaseReservedDBInstancesOffering_602930(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_602929(path: JsonNode;
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
  var valid_602931 = query.getOrDefault("Action")
  valid_602931 = validateParameter(valid_602931, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602931 != nil:
    section.add "Action", valid_602931
  var valid_602932 = query.getOrDefault("Version")
  valid_602932 = validateParameter(valid_602932, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_602940 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602940 = validateParameter(valid_602940, JString, required = false,
                                 default = nil)
  if valid_602940 != nil:
    section.add "ReservedDBInstanceId", valid_602940
  var valid_602941 = formData.getOrDefault("Tags")
  valid_602941 = validateParameter(valid_602941, JArray, required = false,
                                 default = nil)
  if valid_602941 != nil:
    section.add "Tags", valid_602941
  var valid_602942 = formData.getOrDefault("DBInstanceCount")
  valid_602942 = validateParameter(valid_602942, JInt, required = false, default = nil)
  if valid_602942 != nil:
    section.add "DBInstanceCount", valid_602942
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602943 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602943 = validateParameter(valid_602943, JString, required = true,
                                 default = nil)
  if valid_602943 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602943
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602944: Call_PostPurchaseReservedDBInstancesOffering_602928;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602944.validator(path, query, header, formData, body)
  let scheme = call_602944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602944.url(scheme.get, call_602944.host, call_602944.base,
                         call_602944.route, valid.getOrDefault("path"))
  result = hook(call_602944, url, valid)

proc call*(call_602945: Call_PostPurchaseReservedDBInstancesOffering_602928;
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
  var query_602946 = newJObject()
  var formData_602947 = newJObject()
  add(formData_602947, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_602947.add "Tags", Tags
  add(formData_602947, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602946, "Action", newJString(Action))
  add(formData_602947, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602946, "Version", newJString(Version))
  result = call_602945.call(nil, query_602946, nil, formData_602947, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_602928(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_602929, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_602930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_602909 = ref object of OpenApiRestCall_600410
proc url_GetPurchaseReservedDBInstancesOffering_602911(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_602910(path: JsonNode;
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
  var valid_602912 = query.getOrDefault("DBInstanceCount")
  valid_602912 = validateParameter(valid_602912, JInt, required = false, default = nil)
  if valid_602912 != nil:
    section.add "DBInstanceCount", valid_602912
  var valid_602913 = query.getOrDefault("Tags")
  valid_602913 = validateParameter(valid_602913, JArray, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "Tags", valid_602913
  var valid_602914 = query.getOrDefault("ReservedDBInstanceId")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "ReservedDBInstanceId", valid_602914
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602915 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602915 = validateParameter(valid_602915, JString, required = true,
                                 default = nil)
  if valid_602915 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602915
  var valid_602916 = query.getOrDefault("Action")
  valid_602916 = validateParameter(valid_602916, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602916 != nil:
    section.add "Action", valid_602916
  var valid_602917 = query.getOrDefault("Version")
  valid_602917 = validateParameter(valid_602917, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602917 != nil:
    section.add "Version", valid_602917
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602918 = header.getOrDefault("X-Amz-Date")
  valid_602918 = validateParameter(valid_602918, JString, required = false,
                                 default = nil)
  if valid_602918 != nil:
    section.add "X-Amz-Date", valid_602918
  var valid_602919 = header.getOrDefault("X-Amz-Security-Token")
  valid_602919 = validateParameter(valid_602919, JString, required = false,
                                 default = nil)
  if valid_602919 != nil:
    section.add "X-Amz-Security-Token", valid_602919
  var valid_602920 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602920 = validateParameter(valid_602920, JString, required = false,
                                 default = nil)
  if valid_602920 != nil:
    section.add "X-Amz-Content-Sha256", valid_602920
  var valid_602921 = header.getOrDefault("X-Amz-Algorithm")
  valid_602921 = validateParameter(valid_602921, JString, required = false,
                                 default = nil)
  if valid_602921 != nil:
    section.add "X-Amz-Algorithm", valid_602921
  var valid_602922 = header.getOrDefault("X-Amz-Signature")
  valid_602922 = validateParameter(valid_602922, JString, required = false,
                                 default = nil)
  if valid_602922 != nil:
    section.add "X-Amz-Signature", valid_602922
  var valid_602923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602923 = validateParameter(valid_602923, JString, required = false,
                                 default = nil)
  if valid_602923 != nil:
    section.add "X-Amz-SignedHeaders", valid_602923
  var valid_602924 = header.getOrDefault("X-Amz-Credential")
  valid_602924 = validateParameter(valid_602924, JString, required = false,
                                 default = nil)
  if valid_602924 != nil:
    section.add "X-Amz-Credential", valid_602924
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602925: Call_GetPurchaseReservedDBInstancesOffering_602909;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602925.validator(path, query, header, formData, body)
  let scheme = call_602925.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602925.url(scheme.get, call_602925.host, call_602925.base,
                         call_602925.route, valid.getOrDefault("path"))
  result = hook(call_602925, url, valid)

proc call*(call_602926: Call_GetPurchaseReservedDBInstancesOffering_602909;
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
  var query_602927 = newJObject()
  add(query_602927, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_602927.add "Tags", Tags
  add(query_602927, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602927, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602927, "Action", newJString(Action))
  add(query_602927, "Version", newJString(Version))
  result = call_602926.call(nil, query_602927, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_602909(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_602910, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_602911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602965 = ref object of OpenApiRestCall_600410
proc url_PostRebootDBInstance_602967(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_602966(path: JsonNode; query: JsonNode;
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
  var valid_602968 = query.getOrDefault("Action")
  valid_602968 = validateParameter(valid_602968, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602968 != nil:
    section.add "Action", valid_602968
  var valid_602969 = query.getOrDefault("Version")
  valid_602969 = validateParameter(valid_602969, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602969 != nil:
    section.add "Version", valid_602969
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602970 = header.getOrDefault("X-Amz-Date")
  valid_602970 = validateParameter(valid_602970, JString, required = false,
                                 default = nil)
  if valid_602970 != nil:
    section.add "X-Amz-Date", valid_602970
  var valid_602971 = header.getOrDefault("X-Amz-Security-Token")
  valid_602971 = validateParameter(valid_602971, JString, required = false,
                                 default = nil)
  if valid_602971 != nil:
    section.add "X-Amz-Security-Token", valid_602971
  var valid_602972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602972 = validateParameter(valid_602972, JString, required = false,
                                 default = nil)
  if valid_602972 != nil:
    section.add "X-Amz-Content-Sha256", valid_602972
  var valid_602973 = header.getOrDefault("X-Amz-Algorithm")
  valid_602973 = validateParameter(valid_602973, JString, required = false,
                                 default = nil)
  if valid_602973 != nil:
    section.add "X-Amz-Algorithm", valid_602973
  var valid_602974 = header.getOrDefault("X-Amz-Signature")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-Signature", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-SignedHeaders", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Credential")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Credential", valid_602976
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602977 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602977 = validateParameter(valid_602977, JString, required = true,
                                 default = nil)
  if valid_602977 != nil:
    section.add "DBInstanceIdentifier", valid_602977
  var valid_602978 = formData.getOrDefault("ForceFailover")
  valid_602978 = validateParameter(valid_602978, JBool, required = false, default = nil)
  if valid_602978 != nil:
    section.add "ForceFailover", valid_602978
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602979: Call_PostRebootDBInstance_602965; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602979.validator(path, query, header, formData, body)
  let scheme = call_602979.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602979.url(scheme.get, call_602979.host, call_602979.base,
                         call_602979.route, valid.getOrDefault("path"))
  result = hook(call_602979, url, valid)

proc call*(call_602980: Call_PostRebootDBInstance_602965;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_602981 = newJObject()
  var formData_602982 = newJObject()
  add(formData_602982, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602981, "Action", newJString(Action))
  add(formData_602982, "ForceFailover", newJBool(ForceFailover))
  add(query_602981, "Version", newJString(Version))
  result = call_602980.call(nil, query_602981, nil, formData_602982, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602965(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602966, base: "/",
    url: url_PostRebootDBInstance_602967, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602948 = ref object of OpenApiRestCall_600410
proc url_GetRebootDBInstance_602950(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_602949(path: JsonNode; query: JsonNode;
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
  var valid_602951 = query.getOrDefault("Action")
  valid_602951 = validateParameter(valid_602951, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602951 != nil:
    section.add "Action", valid_602951
  var valid_602952 = query.getOrDefault("ForceFailover")
  valid_602952 = validateParameter(valid_602952, JBool, required = false, default = nil)
  if valid_602952 != nil:
    section.add "ForceFailover", valid_602952
  var valid_602953 = query.getOrDefault("Version")
  valid_602953 = validateParameter(valid_602953, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602953 != nil:
    section.add "Version", valid_602953
  var valid_602954 = query.getOrDefault("DBInstanceIdentifier")
  valid_602954 = validateParameter(valid_602954, JString, required = true,
                                 default = nil)
  if valid_602954 != nil:
    section.add "DBInstanceIdentifier", valid_602954
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602955 = header.getOrDefault("X-Amz-Date")
  valid_602955 = validateParameter(valid_602955, JString, required = false,
                                 default = nil)
  if valid_602955 != nil:
    section.add "X-Amz-Date", valid_602955
  var valid_602956 = header.getOrDefault("X-Amz-Security-Token")
  valid_602956 = validateParameter(valid_602956, JString, required = false,
                                 default = nil)
  if valid_602956 != nil:
    section.add "X-Amz-Security-Token", valid_602956
  var valid_602957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602957 = validateParameter(valid_602957, JString, required = false,
                                 default = nil)
  if valid_602957 != nil:
    section.add "X-Amz-Content-Sha256", valid_602957
  var valid_602958 = header.getOrDefault("X-Amz-Algorithm")
  valid_602958 = validateParameter(valid_602958, JString, required = false,
                                 default = nil)
  if valid_602958 != nil:
    section.add "X-Amz-Algorithm", valid_602958
  var valid_602959 = header.getOrDefault("X-Amz-Signature")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Signature", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-SignedHeaders", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Credential")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Credential", valid_602961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602962: Call_GetRebootDBInstance_602948; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602962.validator(path, query, header, formData, body)
  let scheme = call_602962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602962.url(scheme.get, call_602962.host, call_602962.base,
                         call_602962.route, valid.getOrDefault("path"))
  result = hook(call_602962, url, valid)

proc call*(call_602963: Call_GetRebootDBInstance_602948;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602964 = newJObject()
  add(query_602964, "Action", newJString(Action))
  add(query_602964, "ForceFailover", newJBool(ForceFailover))
  add(query_602964, "Version", newJString(Version))
  add(query_602964, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602963.call(nil, query_602964, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602948(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602949, base: "/",
    url: url_GetRebootDBInstance_602950, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_603000 = ref object of OpenApiRestCall_600410
proc url_PostRemoveSourceIdentifierFromSubscription_603002(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_603001(path: JsonNode;
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
      "RemoveSourceIdentifierFromSubscription"))
  if valid_603003 != nil:
    section.add "Action", valid_603003
  var valid_603004 = query.getOrDefault("Version")
  valid_603004 = validateParameter(valid_603004, JString, required = true,
                                 default = newJString("2014-09-01"))
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
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_603012 = formData.getOrDefault("SourceIdentifier")
  valid_603012 = validateParameter(valid_603012, JString, required = true,
                                 default = nil)
  if valid_603012 != nil:
    section.add "SourceIdentifier", valid_603012
  var valid_603013 = formData.getOrDefault("SubscriptionName")
  valid_603013 = validateParameter(valid_603013, JString, required = true,
                                 default = nil)
  if valid_603013 != nil:
    section.add "SubscriptionName", valid_603013
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603014: Call_PostRemoveSourceIdentifierFromSubscription_603000;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603014.validator(path, query, header, formData, body)
  let scheme = call_603014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603014.url(scheme.get, call_603014.host, call_603014.base,
                         call_603014.route, valid.getOrDefault("path"))
  result = hook(call_603014, url, valid)

proc call*(call_603015: Call_PostRemoveSourceIdentifierFromSubscription_603000;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603016 = newJObject()
  var formData_603017 = newJObject()
  add(formData_603017, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603017, "SubscriptionName", newJString(SubscriptionName))
  add(query_603016, "Action", newJString(Action))
  add(query_603016, "Version", newJString(Version))
  result = call_603015.call(nil, query_603016, nil, formData_603017, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_603000(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_603001,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_603002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_602983 = ref object of OpenApiRestCall_600410
proc url_GetRemoveSourceIdentifierFromSubscription_602985(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_602984(path: JsonNode;
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
  var valid_602986 = query.getOrDefault("Action")
  valid_602986 = validateParameter(valid_602986, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602986 != nil:
    section.add "Action", valid_602986
  var valid_602987 = query.getOrDefault("SourceIdentifier")
  valid_602987 = validateParameter(valid_602987, JString, required = true,
                                 default = nil)
  if valid_602987 != nil:
    section.add "SourceIdentifier", valid_602987
  var valid_602988 = query.getOrDefault("SubscriptionName")
  valid_602988 = validateParameter(valid_602988, JString, required = true,
                                 default = nil)
  if valid_602988 != nil:
    section.add "SubscriptionName", valid_602988
  var valid_602989 = query.getOrDefault("Version")
  valid_602989 = validateParameter(valid_602989, JString, required = true,
                                 default = newJString("2014-09-01"))
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

proc call*(call_602997: Call_GetRemoveSourceIdentifierFromSubscription_602983;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602997.validator(path, query, header, formData, body)
  let scheme = call_602997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602997.url(scheme.get, call_602997.host, call_602997.base,
                         call_602997.route, valid.getOrDefault("path"))
  result = hook(call_602997, url, valid)

proc call*(call_602998: Call_GetRemoveSourceIdentifierFromSubscription_602983;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602999 = newJObject()
  add(query_602999, "Action", newJString(Action))
  add(query_602999, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602999, "SubscriptionName", newJString(SubscriptionName))
  add(query_602999, "Version", newJString(Version))
  result = call_602998.call(nil, query_602999, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_602983(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_602984,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_602985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_603035 = ref object of OpenApiRestCall_600410
proc url_PostRemoveTagsFromResource_603037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_603036(path: JsonNode; query: JsonNode;
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
  var valid_603038 = query.getOrDefault("Action")
  valid_603038 = validateParameter(valid_603038, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603038 != nil:
    section.add "Action", valid_603038
  var valid_603039 = query.getOrDefault("Version")
  valid_603039 = validateParameter(valid_603039, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603039 != nil:
    section.add "Version", valid_603039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603040 = header.getOrDefault("X-Amz-Date")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-Date", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Security-Token")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Security-Token", valid_603041
  var valid_603042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603042 = validateParameter(valid_603042, JString, required = false,
                                 default = nil)
  if valid_603042 != nil:
    section.add "X-Amz-Content-Sha256", valid_603042
  var valid_603043 = header.getOrDefault("X-Amz-Algorithm")
  valid_603043 = validateParameter(valid_603043, JString, required = false,
                                 default = nil)
  if valid_603043 != nil:
    section.add "X-Amz-Algorithm", valid_603043
  var valid_603044 = header.getOrDefault("X-Amz-Signature")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "X-Amz-Signature", valid_603044
  var valid_603045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603045 = validateParameter(valid_603045, JString, required = false,
                                 default = nil)
  if valid_603045 != nil:
    section.add "X-Amz-SignedHeaders", valid_603045
  var valid_603046 = header.getOrDefault("X-Amz-Credential")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Credential", valid_603046
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_603047 = formData.getOrDefault("TagKeys")
  valid_603047 = validateParameter(valid_603047, JArray, required = true, default = nil)
  if valid_603047 != nil:
    section.add "TagKeys", valid_603047
  var valid_603048 = formData.getOrDefault("ResourceName")
  valid_603048 = validateParameter(valid_603048, JString, required = true,
                                 default = nil)
  if valid_603048 != nil:
    section.add "ResourceName", valid_603048
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603049: Call_PostRemoveTagsFromResource_603035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603049.validator(path, query, header, formData, body)
  let scheme = call_603049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603049.url(scheme.get, call_603049.host, call_603049.base,
                         call_603049.route, valid.getOrDefault("path"))
  result = hook(call_603049, url, valid)

proc call*(call_603050: Call_PostRemoveTagsFromResource_603035; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_603051 = newJObject()
  var formData_603052 = newJObject()
  add(query_603051, "Action", newJString(Action))
  if TagKeys != nil:
    formData_603052.add "TagKeys", TagKeys
  add(formData_603052, "ResourceName", newJString(ResourceName))
  add(query_603051, "Version", newJString(Version))
  result = call_603050.call(nil, query_603051, nil, formData_603052, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_603035(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_603036, base: "/",
    url: url_PostRemoveTagsFromResource_603037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_603018 = ref object of OpenApiRestCall_600410
proc url_GetRemoveTagsFromResource_603020(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_603019(path: JsonNode; query: JsonNode;
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
  var valid_603021 = query.getOrDefault("ResourceName")
  valid_603021 = validateParameter(valid_603021, JString, required = true,
                                 default = nil)
  if valid_603021 != nil:
    section.add "ResourceName", valid_603021
  var valid_603022 = query.getOrDefault("Action")
  valid_603022 = validateParameter(valid_603022, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_603022 != nil:
    section.add "Action", valid_603022
  var valid_603023 = query.getOrDefault("TagKeys")
  valid_603023 = validateParameter(valid_603023, JArray, required = true, default = nil)
  if valid_603023 != nil:
    section.add "TagKeys", valid_603023
  var valid_603024 = query.getOrDefault("Version")
  valid_603024 = validateParameter(valid_603024, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603024 != nil:
    section.add "Version", valid_603024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603025 = header.getOrDefault("X-Amz-Date")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-Date", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Security-Token")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Security-Token", valid_603026
  var valid_603027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603027 = validateParameter(valid_603027, JString, required = false,
                                 default = nil)
  if valid_603027 != nil:
    section.add "X-Amz-Content-Sha256", valid_603027
  var valid_603028 = header.getOrDefault("X-Amz-Algorithm")
  valid_603028 = validateParameter(valid_603028, JString, required = false,
                                 default = nil)
  if valid_603028 != nil:
    section.add "X-Amz-Algorithm", valid_603028
  var valid_603029 = header.getOrDefault("X-Amz-Signature")
  valid_603029 = validateParameter(valid_603029, JString, required = false,
                                 default = nil)
  if valid_603029 != nil:
    section.add "X-Amz-Signature", valid_603029
  var valid_603030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603030 = validateParameter(valid_603030, JString, required = false,
                                 default = nil)
  if valid_603030 != nil:
    section.add "X-Amz-SignedHeaders", valid_603030
  var valid_603031 = header.getOrDefault("X-Amz-Credential")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Credential", valid_603031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603032: Call_GetRemoveTagsFromResource_603018; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603032.validator(path, query, header, formData, body)
  let scheme = call_603032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603032.url(scheme.get, call_603032.host, call_603032.base,
                         call_603032.route, valid.getOrDefault("path"))
  result = hook(call_603032, url, valid)

proc call*(call_603033: Call_GetRemoveTagsFromResource_603018;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_603034 = newJObject()
  add(query_603034, "ResourceName", newJString(ResourceName))
  add(query_603034, "Action", newJString(Action))
  if TagKeys != nil:
    query_603034.add "TagKeys", TagKeys
  add(query_603034, "Version", newJString(Version))
  result = call_603033.call(nil, query_603034, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_603018(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_603019, base: "/",
    url: url_GetRemoveTagsFromResource_603020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_603071 = ref object of OpenApiRestCall_600410
proc url_PostResetDBParameterGroup_603073(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_603072(path: JsonNode; query: JsonNode;
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
  var valid_603074 = query.getOrDefault("Action")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603074 != nil:
    section.add "Action", valid_603074
  var valid_603075 = query.getOrDefault("Version")
  valid_603075 = validateParameter(valid_603075, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603075 != nil:
    section.add "Version", valid_603075
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603076 = header.getOrDefault("X-Amz-Date")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Date", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-Security-Token")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-Security-Token", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Content-Sha256", valid_603078
  var valid_603079 = header.getOrDefault("X-Amz-Algorithm")
  valid_603079 = validateParameter(valid_603079, JString, required = false,
                                 default = nil)
  if valid_603079 != nil:
    section.add "X-Amz-Algorithm", valid_603079
  var valid_603080 = header.getOrDefault("X-Amz-Signature")
  valid_603080 = validateParameter(valid_603080, JString, required = false,
                                 default = nil)
  if valid_603080 != nil:
    section.add "X-Amz-Signature", valid_603080
  var valid_603081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603081 = validateParameter(valid_603081, JString, required = false,
                                 default = nil)
  if valid_603081 != nil:
    section.add "X-Amz-SignedHeaders", valid_603081
  var valid_603082 = header.getOrDefault("X-Amz-Credential")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "X-Amz-Credential", valid_603082
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603083 = formData.getOrDefault("DBParameterGroupName")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = nil)
  if valid_603083 != nil:
    section.add "DBParameterGroupName", valid_603083
  var valid_603084 = formData.getOrDefault("Parameters")
  valid_603084 = validateParameter(valid_603084, JArray, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "Parameters", valid_603084
  var valid_603085 = formData.getOrDefault("ResetAllParameters")
  valid_603085 = validateParameter(valid_603085, JBool, required = false, default = nil)
  if valid_603085 != nil:
    section.add "ResetAllParameters", valid_603085
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603086: Call_PostResetDBParameterGroup_603071; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603086.validator(path, query, header, formData, body)
  let scheme = call_603086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603086.url(scheme.get, call_603086.host, call_603086.base,
                         call_603086.route, valid.getOrDefault("path"))
  result = hook(call_603086, url, valid)

proc call*(call_603087: Call_PostResetDBParameterGroup_603071;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_603088 = newJObject()
  var formData_603089 = newJObject()
  add(formData_603089, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_603089.add "Parameters", Parameters
  add(query_603088, "Action", newJString(Action))
  add(formData_603089, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603088, "Version", newJString(Version))
  result = call_603087.call(nil, query_603088, nil, formData_603089, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_603071(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_603072, base: "/",
    url: url_PostResetDBParameterGroup_603073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_603053 = ref object of OpenApiRestCall_600410
proc url_GetResetDBParameterGroup_603055(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_603054(path: JsonNode; query: JsonNode;
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
  var valid_603056 = query.getOrDefault("DBParameterGroupName")
  valid_603056 = validateParameter(valid_603056, JString, required = true,
                                 default = nil)
  if valid_603056 != nil:
    section.add "DBParameterGroupName", valid_603056
  var valid_603057 = query.getOrDefault("Parameters")
  valid_603057 = validateParameter(valid_603057, JArray, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "Parameters", valid_603057
  var valid_603058 = query.getOrDefault("Action")
  valid_603058 = validateParameter(valid_603058, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_603058 != nil:
    section.add "Action", valid_603058
  var valid_603059 = query.getOrDefault("ResetAllParameters")
  valid_603059 = validateParameter(valid_603059, JBool, required = false, default = nil)
  if valid_603059 != nil:
    section.add "ResetAllParameters", valid_603059
  var valid_603060 = query.getOrDefault("Version")
  valid_603060 = validateParameter(valid_603060, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603060 != nil:
    section.add "Version", valid_603060
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603061 = header.getOrDefault("X-Amz-Date")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "X-Amz-Date", valid_603061
  var valid_603062 = header.getOrDefault("X-Amz-Security-Token")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "X-Amz-Security-Token", valid_603062
  var valid_603063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "X-Amz-Content-Sha256", valid_603063
  var valid_603064 = header.getOrDefault("X-Amz-Algorithm")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Algorithm", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Signature")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Signature", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-SignedHeaders", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Credential")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Credential", valid_603067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603068: Call_GetResetDBParameterGroup_603053; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603068.validator(path, query, header, formData, body)
  let scheme = call_603068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603068.url(scheme.get, call_603068.host, call_603068.base,
                         call_603068.route, valid.getOrDefault("path"))
  result = hook(call_603068, url, valid)

proc call*(call_603069: Call_GetResetDBParameterGroup_603053;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_603070 = newJObject()
  add(query_603070, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_603070.add "Parameters", Parameters
  add(query_603070, "Action", newJString(Action))
  add(query_603070, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_603070, "Version", newJString(Version))
  result = call_603069.call(nil, query_603070, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_603053(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_603054, base: "/",
    url: url_GetResetDBParameterGroup_603055, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_603123 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceFromDBSnapshot_603125(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_603124(path: JsonNode;
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
  var valid_603126 = query.getOrDefault("Action")
  valid_603126 = validateParameter(valid_603126, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603126 != nil:
    section.add "Action", valid_603126
  var valid_603127 = query.getOrDefault("Version")
  valid_603127 = validateParameter(valid_603127, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603127 != nil:
    section.add "Version", valid_603127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603128 = header.getOrDefault("X-Amz-Date")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Date", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Security-Token")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Security-Token", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Content-Sha256", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Algorithm")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Algorithm", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Signature")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Signature", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-SignedHeaders", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-Credential")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-Credential", valid_603134
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
  var valid_603135 = formData.getOrDefault("Port")
  valid_603135 = validateParameter(valid_603135, JInt, required = false, default = nil)
  if valid_603135 != nil:
    section.add "Port", valid_603135
  var valid_603136 = formData.getOrDefault("Engine")
  valid_603136 = validateParameter(valid_603136, JString, required = false,
                                 default = nil)
  if valid_603136 != nil:
    section.add "Engine", valid_603136
  var valid_603137 = formData.getOrDefault("Iops")
  valid_603137 = validateParameter(valid_603137, JInt, required = false, default = nil)
  if valid_603137 != nil:
    section.add "Iops", valid_603137
  var valid_603138 = formData.getOrDefault("DBName")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "DBName", valid_603138
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603139 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603139 = validateParameter(valid_603139, JString, required = true,
                                 default = nil)
  if valid_603139 != nil:
    section.add "DBInstanceIdentifier", valid_603139
  var valid_603140 = formData.getOrDefault("OptionGroupName")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "OptionGroupName", valid_603140
  var valid_603141 = formData.getOrDefault("Tags")
  valid_603141 = validateParameter(valid_603141, JArray, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "Tags", valid_603141
  var valid_603142 = formData.getOrDefault("TdeCredentialArn")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "TdeCredentialArn", valid_603142
  var valid_603143 = formData.getOrDefault("DBSubnetGroupName")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "DBSubnetGroupName", valid_603143
  var valid_603144 = formData.getOrDefault("TdeCredentialPassword")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "TdeCredentialPassword", valid_603144
  var valid_603145 = formData.getOrDefault("AvailabilityZone")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "AvailabilityZone", valid_603145
  var valid_603146 = formData.getOrDefault("MultiAZ")
  valid_603146 = validateParameter(valid_603146, JBool, required = false, default = nil)
  if valid_603146 != nil:
    section.add "MultiAZ", valid_603146
  var valid_603147 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603147 = validateParameter(valid_603147, JString, required = true,
                                 default = nil)
  if valid_603147 != nil:
    section.add "DBSnapshotIdentifier", valid_603147
  var valid_603148 = formData.getOrDefault("PubliclyAccessible")
  valid_603148 = validateParameter(valid_603148, JBool, required = false, default = nil)
  if valid_603148 != nil:
    section.add "PubliclyAccessible", valid_603148
  var valid_603149 = formData.getOrDefault("StorageType")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "StorageType", valid_603149
  var valid_603150 = formData.getOrDefault("DBInstanceClass")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "DBInstanceClass", valid_603150
  var valid_603151 = formData.getOrDefault("LicenseModel")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "LicenseModel", valid_603151
  var valid_603152 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603152 = validateParameter(valid_603152, JBool, required = false, default = nil)
  if valid_603152 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603153: Call_PostRestoreDBInstanceFromDBSnapshot_603123;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603153.validator(path, query, header, formData, body)
  let scheme = call_603153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603153.url(scheme.get, call_603153.host, call_603153.base,
                         call_603153.route, valid.getOrDefault("path"))
  result = hook(call_603153, url, valid)

proc call*(call_603154: Call_PostRestoreDBInstanceFromDBSnapshot_603123;
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
  var query_603155 = newJObject()
  var formData_603156 = newJObject()
  add(formData_603156, "Port", newJInt(Port))
  add(formData_603156, "Engine", newJString(Engine))
  add(formData_603156, "Iops", newJInt(Iops))
  add(formData_603156, "DBName", newJString(DBName))
  add(formData_603156, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603156, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603156.add "Tags", Tags
  add(formData_603156, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_603156, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603156, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_603156, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603156, "MultiAZ", newJBool(MultiAZ))
  add(formData_603156, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603155, "Action", newJString(Action))
  add(formData_603156, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603156, "StorageType", newJString(StorageType))
  add(formData_603156, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603156, "LicenseModel", newJString(LicenseModel))
  add(formData_603156, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603155, "Version", newJString(Version))
  result = call_603154.call(nil, query_603155, nil, formData_603156, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_603123(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_603124, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_603125,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_603090 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceFromDBSnapshot_603092(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_603091(path: JsonNode;
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
  var valid_603093 = query.getOrDefault("Engine")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "Engine", valid_603093
  var valid_603094 = query.getOrDefault("StorageType")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "StorageType", valid_603094
  var valid_603095 = query.getOrDefault("OptionGroupName")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "OptionGroupName", valid_603095
  var valid_603096 = query.getOrDefault("AvailabilityZone")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "AvailabilityZone", valid_603096
  var valid_603097 = query.getOrDefault("Iops")
  valid_603097 = validateParameter(valid_603097, JInt, required = false, default = nil)
  if valid_603097 != nil:
    section.add "Iops", valid_603097
  var valid_603098 = query.getOrDefault("MultiAZ")
  valid_603098 = validateParameter(valid_603098, JBool, required = false, default = nil)
  if valid_603098 != nil:
    section.add "MultiAZ", valid_603098
  var valid_603099 = query.getOrDefault("TdeCredentialPassword")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "TdeCredentialPassword", valid_603099
  var valid_603100 = query.getOrDefault("LicenseModel")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "LicenseModel", valid_603100
  var valid_603101 = query.getOrDefault("Tags")
  valid_603101 = validateParameter(valid_603101, JArray, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "Tags", valid_603101
  var valid_603102 = query.getOrDefault("DBName")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "DBName", valid_603102
  var valid_603103 = query.getOrDefault("DBInstanceClass")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "DBInstanceClass", valid_603103
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603104 = query.getOrDefault("Action")
  valid_603104 = validateParameter(valid_603104, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_603104 != nil:
    section.add "Action", valid_603104
  var valid_603105 = query.getOrDefault("DBSubnetGroupName")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "DBSubnetGroupName", valid_603105
  var valid_603106 = query.getOrDefault("TdeCredentialArn")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "TdeCredentialArn", valid_603106
  var valid_603107 = query.getOrDefault("PubliclyAccessible")
  valid_603107 = validateParameter(valid_603107, JBool, required = false, default = nil)
  if valid_603107 != nil:
    section.add "PubliclyAccessible", valid_603107
  var valid_603108 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603108 = validateParameter(valid_603108, JBool, required = false, default = nil)
  if valid_603108 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603108
  var valid_603109 = query.getOrDefault("Port")
  valid_603109 = validateParameter(valid_603109, JInt, required = false, default = nil)
  if valid_603109 != nil:
    section.add "Port", valid_603109
  var valid_603110 = query.getOrDefault("Version")
  valid_603110 = validateParameter(valid_603110, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603110 != nil:
    section.add "Version", valid_603110
  var valid_603111 = query.getOrDefault("DBInstanceIdentifier")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "DBInstanceIdentifier", valid_603111
  var valid_603112 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603112 = validateParameter(valid_603112, JString, required = true,
                                 default = nil)
  if valid_603112 != nil:
    section.add "DBSnapshotIdentifier", valid_603112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603113 = header.getOrDefault("X-Amz-Date")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Date", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Security-Token")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Security-Token", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Content-Sha256", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-Algorithm")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-Algorithm", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Signature")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Signature", valid_603117
  var valid_603118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603118 = validateParameter(valid_603118, JString, required = false,
                                 default = nil)
  if valid_603118 != nil:
    section.add "X-Amz-SignedHeaders", valid_603118
  var valid_603119 = header.getOrDefault("X-Amz-Credential")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "X-Amz-Credential", valid_603119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603120: Call_GetRestoreDBInstanceFromDBSnapshot_603090;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603120.validator(path, query, header, formData, body)
  let scheme = call_603120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603120.url(scheme.get, call_603120.host, call_603120.base,
                         call_603120.route, valid.getOrDefault("path"))
  result = hook(call_603120, url, valid)

proc call*(call_603121: Call_GetRestoreDBInstanceFromDBSnapshot_603090;
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
  var query_603122 = newJObject()
  add(query_603122, "Engine", newJString(Engine))
  add(query_603122, "StorageType", newJString(StorageType))
  add(query_603122, "OptionGroupName", newJString(OptionGroupName))
  add(query_603122, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603122, "Iops", newJInt(Iops))
  add(query_603122, "MultiAZ", newJBool(MultiAZ))
  add(query_603122, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_603122, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603122.add "Tags", Tags
  add(query_603122, "DBName", newJString(DBName))
  add(query_603122, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603122, "Action", newJString(Action))
  add(query_603122, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603122, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603122, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603122, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603122, "Port", newJInt(Port))
  add(query_603122, "Version", newJString(Version))
  add(query_603122, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603122, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603121.call(nil, query_603122, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_603090(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_603091, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_603092,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603192 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceToPointInTime_603194(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_603193(path: JsonNode;
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
  var valid_603195 = query.getOrDefault("Action")
  valid_603195 = validateParameter(valid_603195, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603195 != nil:
    section.add "Action", valid_603195
  var valid_603196 = query.getOrDefault("Version")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603196 != nil:
    section.add "Version", valid_603196
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603197 = header.getOrDefault("X-Amz-Date")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Date", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Security-Token")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Security-Token", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Content-Sha256", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Algorithm")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Algorithm", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Signature")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Signature", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-SignedHeaders", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Credential")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Credential", valid_603203
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
  var valid_603204 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603204 = validateParameter(valid_603204, JBool, required = false, default = nil)
  if valid_603204 != nil:
    section.add "UseLatestRestorableTime", valid_603204
  var valid_603205 = formData.getOrDefault("Port")
  valid_603205 = validateParameter(valid_603205, JInt, required = false, default = nil)
  if valid_603205 != nil:
    section.add "Port", valid_603205
  var valid_603206 = formData.getOrDefault("Engine")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "Engine", valid_603206
  var valid_603207 = formData.getOrDefault("Iops")
  valid_603207 = validateParameter(valid_603207, JInt, required = false, default = nil)
  if valid_603207 != nil:
    section.add "Iops", valid_603207
  var valid_603208 = formData.getOrDefault("DBName")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "DBName", valid_603208
  var valid_603209 = formData.getOrDefault("OptionGroupName")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "OptionGroupName", valid_603209
  var valid_603210 = formData.getOrDefault("Tags")
  valid_603210 = validateParameter(valid_603210, JArray, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "Tags", valid_603210
  var valid_603211 = formData.getOrDefault("TdeCredentialArn")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "TdeCredentialArn", valid_603211
  var valid_603212 = formData.getOrDefault("DBSubnetGroupName")
  valid_603212 = validateParameter(valid_603212, JString, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "DBSubnetGroupName", valid_603212
  var valid_603213 = formData.getOrDefault("TdeCredentialPassword")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "TdeCredentialPassword", valid_603213
  var valid_603214 = formData.getOrDefault("AvailabilityZone")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "AvailabilityZone", valid_603214
  var valid_603215 = formData.getOrDefault("MultiAZ")
  valid_603215 = validateParameter(valid_603215, JBool, required = false, default = nil)
  if valid_603215 != nil:
    section.add "MultiAZ", valid_603215
  var valid_603216 = formData.getOrDefault("RestoreTime")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "RestoreTime", valid_603216
  var valid_603217 = formData.getOrDefault("PubliclyAccessible")
  valid_603217 = validateParameter(valid_603217, JBool, required = false, default = nil)
  if valid_603217 != nil:
    section.add "PubliclyAccessible", valid_603217
  var valid_603218 = formData.getOrDefault("StorageType")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "StorageType", valid_603218
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603219 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = nil)
  if valid_603219 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603219
  var valid_603220 = formData.getOrDefault("DBInstanceClass")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "DBInstanceClass", valid_603220
  var valid_603221 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603221 = validateParameter(valid_603221, JString, required = true,
                                 default = nil)
  if valid_603221 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603221
  var valid_603222 = formData.getOrDefault("LicenseModel")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "LicenseModel", valid_603222
  var valid_603223 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603223 = validateParameter(valid_603223, JBool, required = false, default = nil)
  if valid_603223 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603223
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603224: Call_PostRestoreDBInstanceToPointInTime_603192;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603224.validator(path, query, header, formData, body)
  let scheme = call_603224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603224.url(scheme.get, call_603224.host, call_603224.base,
                         call_603224.route, valid.getOrDefault("path"))
  result = hook(call_603224, url, valid)

proc call*(call_603225: Call_PostRestoreDBInstanceToPointInTime_603192;
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
  var query_603226 = newJObject()
  var formData_603227 = newJObject()
  add(formData_603227, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603227, "Port", newJInt(Port))
  add(formData_603227, "Engine", newJString(Engine))
  add(formData_603227, "Iops", newJInt(Iops))
  add(formData_603227, "DBName", newJString(DBName))
  add(formData_603227, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603227.add "Tags", Tags
  add(formData_603227, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_603227, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603227, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_603227, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603227, "MultiAZ", newJBool(MultiAZ))
  add(query_603226, "Action", newJString(Action))
  add(formData_603227, "RestoreTime", newJString(RestoreTime))
  add(formData_603227, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603227, "StorageType", newJString(StorageType))
  add(formData_603227, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_603227, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603227, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603227, "LicenseModel", newJString(LicenseModel))
  add(formData_603227, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603226, "Version", newJString(Version))
  result = call_603225.call(nil, query_603226, nil, formData_603227, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603192(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603193, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603194,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_603157 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceToPointInTime_603159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_603158(path: JsonNode;
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
  var valid_603160 = query.getOrDefault("Engine")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "Engine", valid_603160
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_603161 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603161 = validateParameter(valid_603161, JString, required = true,
                                 default = nil)
  if valid_603161 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603161
  var valid_603162 = query.getOrDefault("StorageType")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "StorageType", valid_603162
  var valid_603163 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603163
  var valid_603164 = query.getOrDefault("AvailabilityZone")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "AvailabilityZone", valid_603164
  var valid_603165 = query.getOrDefault("Iops")
  valid_603165 = validateParameter(valid_603165, JInt, required = false, default = nil)
  if valid_603165 != nil:
    section.add "Iops", valid_603165
  var valid_603166 = query.getOrDefault("OptionGroupName")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "OptionGroupName", valid_603166
  var valid_603167 = query.getOrDefault("RestoreTime")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "RestoreTime", valid_603167
  var valid_603168 = query.getOrDefault("MultiAZ")
  valid_603168 = validateParameter(valid_603168, JBool, required = false, default = nil)
  if valid_603168 != nil:
    section.add "MultiAZ", valid_603168
  var valid_603169 = query.getOrDefault("TdeCredentialPassword")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "TdeCredentialPassword", valid_603169
  var valid_603170 = query.getOrDefault("LicenseModel")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "LicenseModel", valid_603170
  var valid_603171 = query.getOrDefault("Tags")
  valid_603171 = validateParameter(valid_603171, JArray, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "Tags", valid_603171
  var valid_603172 = query.getOrDefault("DBName")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "DBName", valid_603172
  var valid_603173 = query.getOrDefault("DBInstanceClass")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "DBInstanceClass", valid_603173
  var valid_603174 = query.getOrDefault("Action")
  valid_603174 = validateParameter(valid_603174, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603174 != nil:
    section.add "Action", valid_603174
  var valid_603175 = query.getOrDefault("UseLatestRestorableTime")
  valid_603175 = validateParameter(valid_603175, JBool, required = false, default = nil)
  if valid_603175 != nil:
    section.add "UseLatestRestorableTime", valid_603175
  var valid_603176 = query.getOrDefault("DBSubnetGroupName")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "DBSubnetGroupName", valid_603176
  var valid_603177 = query.getOrDefault("TdeCredentialArn")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "TdeCredentialArn", valid_603177
  var valid_603178 = query.getOrDefault("PubliclyAccessible")
  valid_603178 = validateParameter(valid_603178, JBool, required = false, default = nil)
  if valid_603178 != nil:
    section.add "PubliclyAccessible", valid_603178
  var valid_603179 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603179 = validateParameter(valid_603179, JBool, required = false, default = nil)
  if valid_603179 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603179
  var valid_603180 = query.getOrDefault("Port")
  valid_603180 = validateParameter(valid_603180, JInt, required = false, default = nil)
  if valid_603180 != nil:
    section.add "Port", valid_603180
  var valid_603181 = query.getOrDefault("Version")
  valid_603181 = validateParameter(valid_603181, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603181 != nil:
    section.add "Version", valid_603181
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603182 = header.getOrDefault("X-Amz-Date")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Date", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Security-Token")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Security-Token", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Content-Sha256", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Algorithm")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Algorithm", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Signature")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Signature", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-SignedHeaders", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Credential")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Credential", valid_603188
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603189: Call_GetRestoreDBInstanceToPointInTime_603157;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603189.validator(path, query, header, formData, body)
  let scheme = call_603189.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603189.url(scheme.get, call_603189.host, call_603189.base,
                         call_603189.route, valid.getOrDefault("path"))
  result = hook(call_603189, url, valid)

proc call*(call_603190: Call_GetRestoreDBInstanceToPointInTime_603157;
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
  var query_603191 = newJObject()
  add(query_603191, "Engine", newJString(Engine))
  add(query_603191, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603191, "StorageType", newJString(StorageType))
  add(query_603191, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603191, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603191, "Iops", newJInt(Iops))
  add(query_603191, "OptionGroupName", newJString(OptionGroupName))
  add(query_603191, "RestoreTime", newJString(RestoreTime))
  add(query_603191, "MultiAZ", newJBool(MultiAZ))
  add(query_603191, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_603191, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_603191.add "Tags", Tags
  add(query_603191, "DBName", newJString(DBName))
  add(query_603191, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603191, "Action", newJString(Action))
  add(query_603191, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603191, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603191, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603191, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603191, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603191, "Port", newJInt(Port))
  add(query_603191, "Version", newJString(Version))
  result = call_603190.call(nil, query_603191, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_603157(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603158, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603248 = ref object of OpenApiRestCall_600410
proc url_PostRevokeDBSecurityGroupIngress_603250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_603249(path: JsonNode;
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
  var valid_603251 = query.getOrDefault("Action")
  valid_603251 = validateParameter(valid_603251, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603251 != nil:
    section.add "Action", valid_603251
  var valid_603252 = query.getOrDefault("Version")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603252 != nil:
    section.add "Version", valid_603252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603253 = header.getOrDefault("X-Amz-Date")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Date", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Security-Token")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Security-Token", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Content-Sha256", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Algorithm")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Algorithm", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Signature")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Signature", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-SignedHeaders", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-Credential")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-Credential", valid_603259
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603260 = formData.getOrDefault("DBSecurityGroupName")
  valid_603260 = validateParameter(valid_603260, JString, required = true,
                                 default = nil)
  if valid_603260 != nil:
    section.add "DBSecurityGroupName", valid_603260
  var valid_603261 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "EC2SecurityGroupName", valid_603261
  var valid_603262 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "EC2SecurityGroupId", valid_603262
  var valid_603263 = formData.getOrDefault("CIDRIP")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "CIDRIP", valid_603263
  var valid_603264 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603264
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603265: Call_PostRevokeDBSecurityGroupIngress_603248;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603265.validator(path, query, header, formData, body)
  let scheme = call_603265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603265.url(scheme.get, call_603265.host, call_603265.base,
                         call_603265.route, valid.getOrDefault("path"))
  result = hook(call_603265, url, valid)

proc call*(call_603266: Call_PostRevokeDBSecurityGroupIngress_603248;
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
  var query_603267 = newJObject()
  var formData_603268 = newJObject()
  add(formData_603268, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603267, "Action", newJString(Action))
  add(formData_603268, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603268, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603268, "CIDRIP", newJString(CIDRIP))
  add(query_603267, "Version", newJString(Version))
  add(formData_603268, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603266.call(nil, query_603267, nil, formData_603268, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603248(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603249, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_603228 = ref object of OpenApiRestCall_600410
proc url_GetRevokeDBSecurityGroupIngress_603230(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_603229(path: JsonNode;
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
  var valid_603231 = query.getOrDefault("EC2SecurityGroupId")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "EC2SecurityGroupId", valid_603231
  var valid_603232 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603232
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603233 = query.getOrDefault("DBSecurityGroupName")
  valid_603233 = validateParameter(valid_603233, JString, required = true,
                                 default = nil)
  if valid_603233 != nil:
    section.add "DBSecurityGroupName", valid_603233
  var valid_603234 = query.getOrDefault("Action")
  valid_603234 = validateParameter(valid_603234, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603234 != nil:
    section.add "Action", valid_603234
  var valid_603235 = query.getOrDefault("CIDRIP")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "CIDRIP", valid_603235
  var valid_603236 = query.getOrDefault("EC2SecurityGroupName")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "EC2SecurityGroupName", valid_603236
  var valid_603237 = query.getOrDefault("Version")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603237 != nil:
    section.add "Version", valid_603237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603238 = header.getOrDefault("X-Amz-Date")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Date", valid_603238
  var valid_603239 = header.getOrDefault("X-Amz-Security-Token")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "X-Amz-Security-Token", valid_603239
  var valid_603240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603240 = validateParameter(valid_603240, JString, required = false,
                                 default = nil)
  if valid_603240 != nil:
    section.add "X-Amz-Content-Sha256", valid_603240
  var valid_603241 = header.getOrDefault("X-Amz-Algorithm")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "X-Amz-Algorithm", valid_603241
  var valid_603242 = header.getOrDefault("X-Amz-Signature")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "X-Amz-Signature", valid_603242
  var valid_603243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "X-Amz-SignedHeaders", valid_603243
  var valid_603244 = header.getOrDefault("X-Amz-Credential")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "X-Amz-Credential", valid_603244
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603245: Call_GetRevokeDBSecurityGroupIngress_603228;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603245.validator(path, query, header, formData, body)
  let scheme = call_603245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603245.url(scheme.get, call_603245.host, call_603245.base,
                         call_603245.route, valid.getOrDefault("path"))
  result = hook(call_603245, url, valid)

proc call*(call_603246: Call_GetRevokeDBSecurityGroupIngress_603228;
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
  var query_603247 = newJObject()
  add(query_603247, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603247, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603247, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603247, "Action", newJString(Action))
  add(query_603247, "CIDRIP", newJString(CIDRIP))
  add(query_603247, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603247, "Version", newJString(Version))
  result = call_603246.call(nil, query_603247, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_603228(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_603229, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_603230,
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

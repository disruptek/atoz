
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"; DBInstanceIdentifier: string = ""): Recallable =
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
  Call_PostDescribeDBLogFiles_601845 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBLogFiles_601847(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_601846(path: JsonNode; query: JsonNode;
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
  var valid_601848 = query.getOrDefault("Action")
  valid_601848 = validateParameter(valid_601848, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601848 != nil:
    section.add "Action", valid_601848
  var valid_601849 = query.getOrDefault("Version")
  valid_601849 = validateParameter(valid_601849, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_601857 = formData.getOrDefault("FilenameContains")
  valid_601857 = validateParameter(valid_601857, JString, required = false,
                                 default = nil)
  if valid_601857 != nil:
    section.add "FilenameContains", valid_601857
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_601858 = formData.getOrDefault("DBInstanceIdentifier")
  valid_601858 = validateParameter(valid_601858, JString, required = true,
                                 default = nil)
  if valid_601858 != nil:
    section.add "DBInstanceIdentifier", valid_601858
  var valid_601859 = formData.getOrDefault("FileSize")
  valid_601859 = validateParameter(valid_601859, JInt, required = false, default = nil)
  if valid_601859 != nil:
    section.add "FileSize", valid_601859
  var valid_601860 = formData.getOrDefault("Marker")
  valid_601860 = validateParameter(valid_601860, JString, required = false,
                                 default = nil)
  if valid_601860 != nil:
    section.add "Marker", valid_601860
  var valid_601861 = formData.getOrDefault("MaxRecords")
  valid_601861 = validateParameter(valid_601861, JInt, required = false, default = nil)
  if valid_601861 != nil:
    section.add "MaxRecords", valid_601861
  var valid_601862 = formData.getOrDefault("FileLastWritten")
  valid_601862 = validateParameter(valid_601862, JInt, required = false, default = nil)
  if valid_601862 != nil:
    section.add "FileLastWritten", valid_601862
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601863: Call_PostDescribeDBLogFiles_601845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601863.validator(path, query, header, formData, body)
  let scheme = call_601863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601863.url(scheme.get, call_601863.host, call_601863.base,
                         call_601863.route, valid.getOrDefault("path"))
  result = hook(call_601863, url, valid)

proc call*(call_601864: Call_PostDescribeDBLogFiles_601845;
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
  var query_601865 = newJObject()
  var formData_601866 = newJObject()
  add(formData_601866, "FilenameContains", newJString(FilenameContains))
  add(formData_601866, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_601866, "FileSize", newJInt(FileSize))
  add(formData_601866, "Marker", newJString(Marker))
  add(query_601865, "Action", newJString(Action))
  add(formData_601866, "MaxRecords", newJInt(MaxRecords))
  add(formData_601866, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601865, "Version", newJString(Version))
  result = call_601864.call(nil, query_601865, nil, formData_601866, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_601845(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_601846, base: "/",
    url: url_PostDescribeDBLogFiles_601847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_601824 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBLogFiles_601826(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_601825(path: JsonNode; query: JsonNode;
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
  var valid_601827 = query.getOrDefault("FileLastWritten")
  valid_601827 = validateParameter(valid_601827, JInt, required = false, default = nil)
  if valid_601827 != nil:
    section.add "FileLastWritten", valid_601827
  var valid_601828 = query.getOrDefault("MaxRecords")
  valid_601828 = validateParameter(valid_601828, JInt, required = false, default = nil)
  if valid_601828 != nil:
    section.add "MaxRecords", valid_601828
  var valid_601829 = query.getOrDefault("FilenameContains")
  valid_601829 = validateParameter(valid_601829, JString, required = false,
                                 default = nil)
  if valid_601829 != nil:
    section.add "FilenameContains", valid_601829
  var valid_601830 = query.getOrDefault("FileSize")
  valid_601830 = validateParameter(valid_601830, JInt, required = false, default = nil)
  if valid_601830 != nil:
    section.add "FileSize", valid_601830
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601831 = query.getOrDefault("Action")
  valid_601831 = validateParameter(valid_601831, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_601831 != nil:
    section.add "Action", valid_601831
  var valid_601832 = query.getOrDefault("Marker")
  valid_601832 = validateParameter(valid_601832, JString, required = false,
                                 default = nil)
  if valid_601832 != nil:
    section.add "Marker", valid_601832
  var valid_601833 = query.getOrDefault("Version")
  valid_601833 = validateParameter(valid_601833, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601833 != nil:
    section.add "Version", valid_601833
  var valid_601834 = query.getOrDefault("DBInstanceIdentifier")
  valid_601834 = validateParameter(valid_601834, JString, required = true,
                                 default = nil)
  if valid_601834 != nil:
    section.add "DBInstanceIdentifier", valid_601834
  result.add "query", section
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

proc call*(call_601842: Call_GetDescribeDBLogFiles_601824; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601842.validator(path, query, header, formData, body)
  let scheme = call_601842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601842.url(scheme.get, call_601842.host, call_601842.base,
                         call_601842.route, valid.getOrDefault("path"))
  result = hook(call_601842, url, valid)

proc call*(call_601843: Call_GetDescribeDBLogFiles_601824;
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
  var query_601844 = newJObject()
  add(query_601844, "FileLastWritten", newJInt(FileLastWritten))
  add(query_601844, "MaxRecords", newJInt(MaxRecords))
  add(query_601844, "FilenameContains", newJString(FilenameContains))
  add(query_601844, "FileSize", newJInt(FileSize))
  add(query_601844, "Action", newJString(Action))
  add(query_601844, "Marker", newJString(Marker))
  add(query_601844, "Version", newJString(Version))
  add(query_601844, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_601843.call(nil, query_601844, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_601824(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_601825, base: "/",
    url: url_GetDescribeDBLogFiles_601826, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_601885 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameterGroups_601887(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_601886(path: JsonNode; query: JsonNode;
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
  var valid_601888 = query.getOrDefault("Action")
  valid_601888 = validateParameter(valid_601888, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601888 != nil:
    section.add "Action", valid_601888
  var valid_601889 = query.getOrDefault("Version")
  valid_601889 = validateParameter(valid_601889, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601889 != nil:
    section.add "Version", valid_601889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601890 = header.getOrDefault("X-Amz-Date")
  valid_601890 = validateParameter(valid_601890, JString, required = false,
                                 default = nil)
  if valid_601890 != nil:
    section.add "X-Amz-Date", valid_601890
  var valid_601891 = header.getOrDefault("X-Amz-Security-Token")
  valid_601891 = validateParameter(valid_601891, JString, required = false,
                                 default = nil)
  if valid_601891 != nil:
    section.add "X-Amz-Security-Token", valid_601891
  var valid_601892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601892 = validateParameter(valid_601892, JString, required = false,
                                 default = nil)
  if valid_601892 != nil:
    section.add "X-Amz-Content-Sha256", valid_601892
  var valid_601893 = header.getOrDefault("X-Amz-Algorithm")
  valid_601893 = validateParameter(valid_601893, JString, required = false,
                                 default = nil)
  if valid_601893 != nil:
    section.add "X-Amz-Algorithm", valid_601893
  var valid_601894 = header.getOrDefault("X-Amz-Signature")
  valid_601894 = validateParameter(valid_601894, JString, required = false,
                                 default = nil)
  if valid_601894 != nil:
    section.add "X-Amz-Signature", valid_601894
  var valid_601895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601895 = validateParameter(valid_601895, JString, required = false,
                                 default = nil)
  if valid_601895 != nil:
    section.add "X-Amz-SignedHeaders", valid_601895
  var valid_601896 = header.getOrDefault("X-Amz-Credential")
  valid_601896 = validateParameter(valid_601896, JString, required = false,
                                 default = nil)
  if valid_601896 != nil:
    section.add "X-Amz-Credential", valid_601896
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601897 = formData.getOrDefault("DBParameterGroupName")
  valid_601897 = validateParameter(valid_601897, JString, required = false,
                                 default = nil)
  if valid_601897 != nil:
    section.add "DBParameterGroupName", valid_601897
  var valid_601898 = formData.getOrDefault("Marker")
  valid_601898 = validateParameter(valid_601898, JString, required = false,
                                 default = nil)
  if valid_601898 != nil:
    section.add "Marker", valid_601898
  var valid_601899 = formData.getOrDefault("MaxRecords")
  valid_601899 = validateParameter(valid_601899, JInt, required = false, default = nil)
  if valid_601899 != nil:
    section.add "MaxRecords", valid_601899
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601900: Call_PostDescribeDBParameterGroups_601885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601900.validator(path, query, header, formData, body)
  let scheme = call_601900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601900.url(scheme.get, call_601900.host, call_601900.base,
                         call_601900.route, valid.getOrDefault("path"))
  result = hook(call_601900, url, valid)

proc call*(call_601901: Call_PostDescribeDBParameterGroups_601885;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601902 = newJObject()
  var formData_601903 = newJObject()
  add(formData_601903, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601903, "Marker", newJString(Marker))
  add(query_601902, "Action", newJString(Action))
  add(formData_601903, "MaxRecords", newJInt(MaxRecords))
  add(query_601902, "Version", newJString(Version))
  result = call_601901.call(nil, query_601902, nil, formData_601903, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_601885(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_601886, base: "/",
    url: url_PostDescribeDBParameterGroups_601887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_601867 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameterGroups_601869(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_601868(path: JsonNode; query: JsonNode;
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
  var valid_601870 = query.getOrDefault("MaxRecords")
  valid_601870 = validateParameter(valid_601870, JInt, required = false, default = nil)
  if valid_601870 != nil:
    section.add "MaxRecords", valid_601870
  var valid_601871 = query.getOrDefault("DBParameterGroupName")
  valid_601871 = validateParameter(valid_601871, JString, required = false,
                                 default = nil)
  if valid_601871 != nil:
    section.add "DBParameterGroupName", valid_601871
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601872 = query.getOrDefault("Action")
  valid_601872 = validateParameter(valid_601872, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_601872 != nil:
    section.add "Action", valid_601872
  var valid_601873 = query.getOrDefault("Marker")
  valid_601873 = validateParameter(valid_601873, JString, required = false,
                                 default = nil)
  if valid_601873 != nil:
    section.add "Marker", valid_601873
  var valid_601874 = query.getOrDefault("Version")
  valid_601874 = validateParameter(valid_601874, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601882: Call_GetDescribeDBParameterGroups_601867; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601882.validator(path, query, header, formData, body)
  let scheme = call_601882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601882.url(scheme.get, call_601882.host, call_601882.base,
                         call_601882.route, valid.getOrDefault("path"))
  result = hook(call_601882, url, valid)

proc call*(call_601883: Call_GetDescribeDBParameterGroups_601867;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_601884 = newJObject()
  add(query_601884, "MaxRecords", newJInt(MaxRecords))
  add(query_601884, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601884, "Action", newJString(Action))
  add(query_601884, "Marker", newJString(Marker))
  add(query_601884, "Version", newJString(Version))
  result = call_601883.call(nil, query_601884, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_601867(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_601868, base: "/",
    url: url_GetDescribeDBParameterGroups_601869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_601923 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBParameters_601925(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_601924(path: JsonNode; query: JsonNode;
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
  var valid_601926 = query.getOrDefault("Action")
  valid_601926 = validateParameter(valid_601926, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601926 != nil:
    section.add "Action", valid_601926
  var valid_601927 = query.getOrDefault("Version")
  valid_601927 = validateParameter(valid_601927, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601927 != nil:
    section.add "Version", valid_601927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601928 = header.getOrDefault("X-Amz-Date")
  valid_601928 = validateParameter(valid_601928, JString, required = false,
                                 default = nil)
  if valid_601928 != nil:
    section.add "X-Amz-Date", valid_601928
  var valid_601929 = header.getOrDefault("X-Amz-Security-Token")
  valid_601929 = validateParameter(valid_601929, JString, required = false,
                                 default = nil)
  if valid_601929 != nil:
    section.add "X-Amz-Security-Token", valid_601929
  var valid_601930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601930 = validateParameter(valid_601930, JString, required = false,
                                 default = nil)
  if valid_601930 != nil:
    section.add "X-Amz-Content-Sha256", valid_601930
  var valid_601931 = header.getOrDefault("X-Amz-Algorithm")
  valid_601931 = validateParameter(valid_601931, JString, required = false,
                                 default = nil)
  if valid_601931 != nil:
    section.add "X-Amz-Algorithm", valid_601931
  var valid_601932 = header.getOrDefault("X-Amz-Signature")
  valid_601932 = validateParameter(valid_601932, JString, required = false,
                                 default = nil)
  if valid_601932 != nil:
    section.add "X-Amz-Signature", valid_601932
  var valid_601933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601933 = validateParameter(valid_601933, JString, required = false,
                                 default = nil)
  if valid_601933 != nil:
    section.add "X-Amz-SignedHeaders", valid_601933
  var valid_601934 = header.getOrDefault("X-Amz-Credential")
  valid_601934 = validateParameter(valid_601934, JString, required = false,
                                 default = nil)
  if valid_601934 != nil:
    section.add "X-Amz-Credential", valid_601934
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_601935 = formData.getOrDefault("DBParameterGroupName")
  valid_601935 = validateParameter(valid_601935, JString, required = true,
                                 default = nil)
  if valid_601935 != nil:
    section.add "DBParameterGroupName", valid_601935
  var valid_601936 = formData.getOrDefault("Marker")
  valid_601936 = validateParameter(valid_601936, JString, required = false,
                                 default = nil)
  if valid_601936 != nil:
    section.add "Marker", valid_601936
  var valid_601937 = formData.getOrDefault("MaxRecords")
  valid_601937 = validateParameter(valid_601937, JInt, required = false, default = nil)
  if valid_601937 != nil:
    section.add "MaxRecords", valid_601937
  var valid_601938 = formData.getOrDefault("Source")
  valid_601938 = validateParameter(valid_601938, JString, required = false,
                                 default = nil)
  if valid_601938 != nil:
    section.add "Source", valid_601938
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601939: Call_PostDescribeDBParameters_601923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601939.validator(path, query, header, formData, body)
  let scheme = call_601939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601939.url(scheme.get, call_601939.host, call_601939.base,
                         call_601939.route, valid.getOrDefault("path"))
  result = hook(call_601939, url, valid)

proc call*(call_601940: Call_PostDescribeDBParameters_601923;
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
  var query_601941 = newJObject()
  var formData_601942 = newJObject()
  add(formData_601942, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_601942, "Marker", newJString(Marker))
  add(query_601941, "Action", newJString(Action))
  add(formData_601942, "MaxRecords", newJInt(MaxRecords))
  add(query_601941, "Version", newJString(Version))
  add(formData_601942, "Source", newJString(Source))
  result = call_601940.call(nil, query_601941, nil, formData_601942, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_601923(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_601924, base: "/",
    url: url_PostDescribeDBParameters_601925, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_601904 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBParameters_601906(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_601905(path: JsonNode; query: JsonNode;
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
  var valid_601907 = query.getOrDefault("MaxRecords")
  valid_601907 = validateParameter(valid_601907, JInt, required = false, default = nil)
  if valid_601907 != nil:
    section.add "MaxRecords", valid_601907
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_601908 = query.getOrDefault("DBParameterGroupName")
  valid_601908 = validateParameter(valid_601908, JString, required = true,
                                 default = nil)
  if valid_601908 != nil:
    section.add "DBParameterGroupName", valid_601908
  var valid_601909 = query.getOrDefault("Action")
  valid_601909 = validateParameter(valid_601909, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_601909 != nil:
    section.add "Action", valid_601909
  var valid_601910 = query.getOrDefault("Marker")
  valid_601910 = validateParameter(valid_601910, JString, required = false,
                                 default = nil)
  if valid_601910 != nil:
    section.add "Marker", valid_601910
  var valid_601911 = query.getOrDefault("Source")
  valid_601911 = validateParameter(valid_601911, JString, required = false,
                                 default = nil)
  if valid_601911 != nil:
    section.add "Source", valid_601911
  var valid_601912 = query.getOrDefault("Version")
  valid_601912 = validateParameter(valid_601912, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601912 != nil:
    section.add "Version", valid_601912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601913 = header.getOrDefault("X-Amz-Date")
  valid_601913 = validateParameter(valid_601913, JString, required = false,
                                 default = nil)
  if valid_601913 != nil:
    section.add "X-Amz-Date", valid_601913
  var valid_601914 = header.getOrDefault("X-Amz-Security-Token")
  valid_601914 = validateParameter(valid_601914, JString, required = false,
                                 default = nil)
  if valid_601914 != nil:
    section.add "X-Amz-Security-Token", valid_601914
  var valid_601915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601915 = validateParameter(valid_601915, JString, required = false,
                                 default = nil)
  if valid_601915 != nil:
    section.add "X-Amz-Content-Sha256", valid_601915
  var valid_601916 = header.getOrDefault("X-Amz-Algorithm")
  valid_601916 = validateParameter(valid_601916, JString, required = false,
                                 default = nil)
  if valid_601916 != nil:
    section.add "X-Amz-Algorithm", valid_601916
  var valid_601917 = header.getOrDefault("X-Amz-Signature")
  valid_601917 = validateParameter(valid_601917, JString, required = false,
                                 default = nil)
  if valid_601917 != nil:
    section.add "X-Amz-Signature", valid_601917
  var valid_601918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601918 = validateParameter(valid_601918, JString, required = false,
                                 default = nil)
  if valid_601918 != nil:
    section.add "X-Amz-SignedHeaders", valid_601918
  var valid_601919 = header.getOrDefault("X-Amz-Credential")
  valid_601919 = validateParameter(valid_601919, JString, required = false,
                                 default = nil)
  if valid_601919 != nil:
    section.add "X-Amz-Credential", valid_601919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601920: Call_GetDescribeDBParameters_601904; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601920.validator(path, query, header, formData, body)
  let scheme = call_601920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601920.url(scheme.get, call_601920.host, call_601920.base,
                         call_601920.route, valid.getOrDefault("path"))
  result = hook(call_601920, url, valid)

proc call*(call_601921: Call_GetDescribeDBParameters_601904;
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
  var query_601922 = newJObject()
  add(query_601922, "MaxRecords", newJInt(MaxRecords))
  add(query_601922, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_601922, "Action", newJString(Action))
  add(query_601922, "Marker", newJString(Marker))
  add(query_601922, "Source", newJString(Source))
  add(query_601922, "Version", newJString(Version))
  result = call_601921.call(nil, query_601922, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_601904(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_601905, base: "/",
    url: url_GetDescribeDBParameters_601906, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_601961 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSecurityGroups_601963(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_601962(path: JsonNode; query: JsonNode;
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
  var valid_601964 = query.getOrDefault("Action")
  valid_601964 = validateParameter(valid_601964, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601964 != nil:
    section.add "Action", valid_601964
  var valid_601965 = query.getOrDefault("Version")
  valid_601965 = validateParameter(valid_601965, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601965 != nil:
    section.add "Version", valid_601965
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601966 = header.getOrDefault("X-Amz-Date")
  valid_601966 = validateParameter(valid_601966, JString, required = false,
                                 default = nil)
  if valid_601966 != nil:
    section.add "X-Amz-Date", valid_601966
  var valid_601967 = header.getOrDefault("X-Amz-Security-Token")
  valid_601967 = validateParameter(valid_601967, JString, required = false,
                                 default = nil)
  if valid_601967 != nil:
    section.add "X-Amz-Security-Token", valid_601967
  var valid_601968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601968 = validateParameter(valid_601968, JString, required = false,
                                 default = nil)
  if valid_601968 != nil:
    section.add "X-Amz-Content-Sha256", valid_601968
  var valid_601969 = header.getOrDefault("X-Amz-Algorithm")
  valid_601969 = validateParameter(valid_601969, JString, required = false,
                                 default = nil)
  if valid_601969 != nil:
    section.add "X-Amz-Algorithm", valid_601969
  var valid_601970 = header.getOrDefault("X-Amz-Signature")
  valid_601970 = validateParameter(valid_601970, JString, required = false,
                                 default = nil)
  if valid_601970 != nil:
    section.add "X-Amz-Signature", valid_601970
  var valid_601971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601971 = validateParameter(valid_601971, JString, required = false,
                                 default = nil)
  if valid_601971 != nil:
    section.add "X-Amz-SignedHeaders", valid_601971
  var valid_601972 = header.getOrDefault("X-Amz-Credential")
  valid_601972 = validateParameter(valid_601972, JString, required = false,
                                 default = nil)
  if valid_601972 != nil:
    section.add "X-Amz-Credential", valid_601972
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_601973 = formData.getOrDefault("DBSecurityGroupName")
  valid_601973 = validateParameter(valid_601973, JString, required = false,
                                 default = nil)
  if valid_601973 != nil:
    section.add "DBSecurityGroupName", valid_601973
  var valid_601974 = formData.getOrDefault("Marker")
  valid_601974 = validateParameter(valid_601974, JString, required = false,
                                 default = nil)
  if valid_601974 != nil:
    section.add "Marker", valid_601974
  var valid_601975 = formData.getOrDefault("MaxRecords")
  valid_601975 = validateParameter(valid_601975, JInt, required = false, default = nil)
  if valid_601975 != nil:
    section.add "MaxRecords", valid_601975
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601976: Call_PostDescribeDBSecurityGroups_601961; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601976.validator(path, query, header, formData, body)
  let scheme = call_601976.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601976.url(scheme.get, call_601976.host, call_601976.base,
                         call_601976.route, valid.getOrDefault("path"))
  result = hook(call_601976, url, valid)

proc call*(call_601977: Call_PostDescribeDBSecurityGroups_601961;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_601978 = newJObject()
  var formData_601979 = newJObject()
  add(formData_601979, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_601979, "Marker", newJString(Marker))
  add(query_601978, "Action", newJString(Action))
  add(formData_601979, "MaxRecords", newJInt(MaxRecords))
  add(query_601978, "Version", newJString(Version))
  result = call_601977.call(nil, query_601978, nil, formData_601979, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_601961(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_601962, base: "/",
    url: url_PostDescribeDBSecurityGroups_601963,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_601943 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSecurityGroups_601945(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_601944(path: JsonNode; query: JsonNode;
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
  var valid_601946 = query.getOrDefault("MaxRecords")
  valid_601946 = validateParameter(valid_601946, JInt, required = false, default = nil)
  if valid_601946 != nil:
    section.add "MaxRecords", valid_601946
  var valid_601947 = query.getOrDefault("DBSecurityGroupName")
  valid_601947 = validateParameter(valid_601947, JString, required = false,
                                 default = nil)
  if valid_601947 != nil:
    section.add "DBSecurityGroupName", valid_601947
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601948 = query.getOrDefault("Action")
  valid_601948 = validateParameter(valid_601948, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_601948 != nil:
    section.add "Action", valid_601948
  var valid_601949 = query.getOrDefault("Marker")
  valid_601949 = validateParameter(valid_601949, JString, required = false,
                                 default = nil)
  if valid_601949 != nil:
    section.add "Marker", valid_601949
  var valid_601950 = query.getOrDefault("Version")
  valid_601950 = validateParameter(valid_601950, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601950 != nil:
    section.add "Version", valid_601950
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601951 = header.getOrDefault("X-Amz-Date")
  valid_601951 = validateParameter(valid_601951, JString, required = false,
                                 default = nil)
  if valid_601951 != nil:
    section.add "X-Amz-Date", valid_601951
  var valid_601952 = header.getOrDefault("X-Amz-Security-Token")
  valid_601952 = validateParameter(valid_601952, JString, required = false,
                                 default = nil)
  if valid_601952 != nil:
    section.add "X-Amz-Security-Token", valid_601952
  var valid_601953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601953 = validateParameter(valid_601953, JString, required = false,
                                 default = nil)
  if valid_601953 != nil:
    section.add "X-Amz-Content-Sha256", valid_601953
  var valid_601954 = header.getOrDefault("X-Amz-Algorithm")
  valid_601954 = validateParameter(valid_601954, JString, required = false,
                                 default = nil)
  if valid_601954 != nil:
    section.add "X-Amz-Algorithm", valid_601954
  var valid_601955 = header.getOrDefault("X-Amz-Signature")
  valid_601955 = validateParameter(valid_601955, JString, required = false,
                                 default = nil)
  if valid_601955 != nil:
    section.add "X-Amz-Signature", valid_601955
  var valid_601956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601956 = validateParameter(valid_601956, JString, required = false,
                                 default = nil)
  if valid_601956 != nil:
    section.add "X-Amz-SignedHeaders", valid_601956
  var valid_601957 = header.getOrDefault("X-Amz-Credential")
  valid_601957 = validateParameter(valid_601957, JString, required = false,
                                 default = nil)
  if valid_601957 != nil:
    section.add "X-Amz-Credential", valid_601957
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601958: Call_GetDescribeDBSecurityGroups_601943; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601958.validator(path, query, header, formData, body)
  let scheme = call_601958.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601958.url(scheme.get, call_601958.host, call_601958.base,
                         call_601958.route, valid.getOrDefault("path"))
  result = hook(call_601958, url, valid)

proc call*(call_601959: Call_GetDescribeDBSecurityGroups_601943;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_601960 = newJObject()
  add(query_601960, "MaxRecords", newJInt(MaxRecords))
  add(query_601960, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_601960, "Action", newJString(Action))
  add(query_601960, "Marker", newJString(Marker))
  add(query_601960, "Version", newJString(Version))
  result = call_601959.call(nil, query_601960, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_601943(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_601944, base: "/",
    url: url_GetDescribeDBSecurityGroups_601945,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_602000 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSnapshots_602002(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_602001(path: JsonNode; query: JsonNode;
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
  var valid_602003 = query.getOrDefault("Action")
  valid_602003 = validateParameter(valid_602003, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_602003 != nil:
    section.add "Action", valid_602003
  var valid_602004 = query.getOrDefault("Version")
  valid_602004 = validateParameter(valid_602004, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602004 != nil:
    section.add "Version", valid_602004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602005 = header.getOrDefault("X-Amz-Date")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "X-Amz-Date", valid_602005
  var valid_602006 = header.getOrDefault("X-Amz-Security-Token")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "X-Amz-Security-Token", valid_602006
  var valid_602007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Content-Sha256", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Algorithm")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Algorithm", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Signature")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Signature", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-SignedHeaders", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Credential")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Credential", valid_602011
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602012 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "DBInstanceIdentifier", valid_602012
  var valid_602013 = formData.getOrDefault("SnapshotType")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "SnapshotType", valid_602013
  var valid_602014 = formData.getOrDefault("Marker")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "Marker", valid_602014
  var valid_602015 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "DBSnapshotIdentifier", valid_602015
  var valid_602016 = formData.getOrDefault("MaxRecords")
  valid_602016 = validateParameter(valid_602016, JInt, required = false, default = nil)
  if valid_602016 != nil:
    section.add "MaxRecords", valid_602016
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602017: Call_PostDescribeDBSnapshots_602000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602017.validator(path, query, header, formData, body)
  let scheme = call_602017.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602017.url(scheme.get, call_602017.host, call_602017.base,
                         call_602017.route, valid.getOrDefault("path"))
  result = hook(call_602017, url, valid)

proc call*(call_602018: Call_PostDescribeDBSnapshots_602000;
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
  var query_602019 = newJObject()
  var formData_602020 = newJObject()
  add(formData_602020, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602020, "SnapshotType", newJString(SnapshotType))
  add(formData_602020, "Marker", newJString(Marker))
  add(formData_602020, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602019, "Action", newJString(Action))
  add(formData_602020, "MaxRecords", newJInt(MaxRecords))
  add(query_602019, "Version", newJString(Version))
  result = call_602018.call(nil, query_602019, nil, formData_602020, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_602000(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_602001, base: "/",
    url: url_PostDescribeDBSnapshots_602002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_601980 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSnapshots_601982(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_601981(path: JsonNode; query: JsonNode;
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
  var valid_601983 = query.getOrDefault("MaxRecords")
  valid_601983 = validateParameter(valid_601983, JInt, required = false, default = nil)
  if valid_601983 != nil:
    section.add "MaxRecords", valid_601983
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601984 = query.getOrDefault("Action")
  valid_601984 = validateParameter(valid_601984, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_601984 != nil:
    section.add "Action", valid_601984
  var valid_601985 = query.getOrDefault("Marker")
  valid_601985 = validateParameter(valid_601985, JString, required = false,
                                 default = nil)
  if valid_601985 != nil:
    section.add "Marker", valid_601985
  var valid_601986 = query.getOrDefault("SnapshotType")
  valid_601986 = validateParameter(valid_601986, JString, required = false,
                                 default = nil)
  if valid_601986 != nil:
    section.add "SnapshotType", valid_601986
  var valid_601987 = query.getOrDefault("Version")
  valid_601987 = validateParameter(valid_601987, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_601987 != nil:
    section.add "Version", valid_601987
  var valid_601988 = query.getOrDefault("DBInstanceIdentifier")
  valid_601988 = validateParameter(valid_601988, JString, required = false,
                                 default = nil)
  if valid_601988 != nil:
    section.add "DBInstanceIdentifier", valid_601988
  var valid_601989 = query.getOrDefault("DBSnapshotIdentifier")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "DBSnapshotIdentifier", valid_601989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601990 = header.getOrDefault("X-Amz-Date")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Date", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Security-Token")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Security-Token", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Content-Sha256", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Algorithm")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Algorithm", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Signature")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Signature", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  var valid_601996 = header.getOrDefault("X-Amz-Credential")
  valid_601996 = validateParameter(valid_601996, JString, required = false,
                                 default = nil)
  if valid_601996 != nil:
    section.add "X-Amz-Credential", valid_601996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_GetDescribeDBSnapshots_601980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"))
  result = hook(call_601997, url, valid)

proc call*(call_601998: Call_GetDescribeDBSnapshots_601980; MaxRecords: int = 0;
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
  var query_601999 = newJObject()
  add(query_601999, "MaxRecords", newJInt(MaxRecords))
  add(query_601999, "Action", newJString(Action))
  add(query_601999, "Marker", newJString(Marker))
  add(query_601999, "SnapshotType", newJString(SnapshotType))
  add(query_601999, "Version", newJString(Version))
  add(query_601999, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_601999, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_601998.call(nil, query_601999, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_601980(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_601981, base: "/",
    url: url_GetDescribeDBSnapshots_601982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_602039 = ref object of OpenApiRestCall_600410
proc url_PostDescribeDBSubnetGroups_602041(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_602040(path: JsonNode; query: JsonNode;
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
  var valid_602042 = query.getOrDefault("Action")
  valid_602042 = validateParameter(valid_602042, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602042 != nil:
    section.add "Action", valid_602042
  var valid_602043 = query.getOrDefault("Version")
  valid_602043 = validateParameter(valid_602043, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602043 != nil:
    section.add "Version", valid_602043
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602044 = header.getOrDefault("X-Amz-Date")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Date", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Content-Sha256", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-Algorithm")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-Algorithm", valid_602047
  var valid_602048 = header.getOrDefault("X-Amz-Signature")
  valid_602048 = validateParameter(valid_602048, JString, required = false,
                                 default = nil)
  if valid_602048 != nil:
    section.add "X-Amz-Signature", valid_602048
  var valid_602049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602049 = validateParameter(valid_602049, JString, required = false,
                                 default = nil)
  if valid_602049 != nil:
    section.add "X-Amz-SignedHeaders", valid_602049
  var valid_602050 = header.getOrDefault("X-Amz-Credential")
  valid_602050 = validateParameter(valid_602050, JString, required = false,
                                 default = nil)
  if valid_602050 != nil:
    section.add "X-Amz-Credential", valid_602050
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602051 = formData.getOrDefault("DBSubnetGroupName")
  valid_602051 = validateParameter(valid_602051, JString, required = false,
                                 default = nil)
  if valid_602051 != nil:
    section.add "DBSubnetGroupName", valid_602051
  var valid_602052 = formData.getOrDefault("Marker")
  valid_602052 = validateParameter(valid_602052, JString, required = false,
                                 default = nil)
  if valid_602052 != nil:
    section.add "Marker", valid_602052
  var valid_602053 = formData.getOrDefault("MaxRecords")
  valid_602053 = validateParameter(valid_602053, JInt, required = false, default = nil)
  if valid_602053 != nil:
    section.add "MaxRecords", valid_602053
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602054: Call_PostDescribeDBSubnetGroups_602039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602054.validator(path, query, header, formData, body)
  let scheme = call_602054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602054.url(scheme.get, call_602054.host, call_602054.base,
                         call_602054.route, valid.getOrDefault("path"))
  result = hook(call_602054, url, valid)

proc call*(call_602055: Call_PostDescribeDBSubnetGroups_602039;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602056 = newJObject()
  var formData_602057 = newJObject()
  add(formData_602057, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602057, "Marker", newJString(Marker))
  add(query_602056, "Action", newJString(Action))
  add(formData_602057, "MaxRecords", newJInt(MaxRecords))
  add(query_602056, "Version", newJString(Version))
  result = call_602055.call(nil, query_602056, nil, formData_602057, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_602039(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_602040, base: "/",
    url: url_PostDescribeDBSubnetGroups_602041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_602021 = ref object of OpenApiRestCall_600410
proc url_GetDescribeDBSubnetGroups_602023(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_602022(path: JsonNode; query: JsonNode;
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
  var valid_602024 = query.getOrDefault("MaxRecords")
  valid_602024 = validateParameter(valid_602024, JInt, required = false, default = nil)
  if valid_602024 != nil:
    section.add "MaxRecords", valid_602024
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602025 = query.getOrDefault("Action")
  valid_602025 = validateParameter(valid_602025, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_602025 != nil:
    section.add "Action", valid_602025
  var valid_602026 = query.getOrDefault("Marker")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "Marker", valid_602026
  var valid_602027 = query.getOrDefault("DBSubnetGroupName")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "DBSubnetGroupName", valid_602027
  var valid_602028 = query.getOrDefault("Version")
  valid_602028 = validateParameter(valid_602028, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602028 != nil:
    section.add "Version", valid_602028
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602029 = header.getOrDefault("X-Amz-Date")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-Date", valid_602029
  var valid_602030 = header.getOrDefault("X-Amz-Security-Token")
  valid_602030 = validateParameter(valid_602030, JString, required = false,
                                 default = nil)
  if valid_602030 != nil:
    section.add "X-Amz-Security-Token", valid_602030
  var valid_602031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602031 = validateParameter(valid_602031, JString, required = false,
                                 default = nil)
  if valid_602031 != nil:
    section.add "X-Amz-Content-Sha256", valid_602031
  var valid_602032 = header.getOrDefault("X-Amz-Algorithm")
  valid_602032 = validateParameter(valid_602032, JString, required = false,
                                 default = nil)
  if valid_602032 != nil:
    section.add "X-Amz-Algorithm", valid_602032
  var valid_602033 = header.getOrDefault("X-Amz-Signature")
  valid_602033 = validateParameter(valid_602033, JString, required = false,
                                 default = nil)
  if valid_602033 != nil:
    section.add "X-Amz-Signature", valid_602033
  var valid_602034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602034 = validateParameter(valid_602034, JString, required = false,
                                 default = nil)
  if valid_602034 != nil:
    section.add "X-Amz-SignedHeaders", valid_602034
  var valid_602035 = header.getOrDefault("X-Amz-Credential")
  valid_602035 = validateParameter(valid_602035, JString, required = false,
                                 default = nil)
  if valid_602035 != nil:
    section.add "X-Amz-Credential", valid_602035
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602036: Call_GetDescribeDBSubnetGroups_602021; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602036.validator(path, query, header, formData, body)
  let scheme = call_602036.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602036.url(scheme.get, call_602036.host, call_602036.base,
                         call_602036.route, valid.getOrDefault("path"))
  result = hook(call_602036, url, valid)

proc call*(call_602037: Call_GetDescribeDBSubnetGroups_602021; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_602038 = newJObject()
  add(query_602038, "MaxRecords", newJInt(MaxRecords))
  add(query_602038, "Action", newJString(Action))
  add(query_602038, "Marker", newJString(Marker))
  add(query_602038, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602038, "Version", newJString(Version))
  result = call_602037.call(nil, query_602038, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_602021(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_602022, base: "/",
    url: url_GetDescribeDBSubnetGroups_602023,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_602076 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEngineDefaultParameters_602078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_602077(path: JsonNode;
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
  var valid_602079 = query.getOrDefault("Action")
  valid_602079 = validateParameter(valid_602079, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602079 != nil:
    section.add "Action", valid_602079
  var valid_602080 = query.getOrDefault("Version")
  valid_602080 = validateParameter(valid_602080, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602080 != nil:
    section.add "Version", valid_602080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602081 = header.getOrDefault("X-Amz-Date")
  valid_602081 = validateParameter(valid_602081, JString, required = false,
                                 default = nil)
  if valid_602081 != nil:
    section.add "X-Amz-Date", valid_602081
  var valid_602082 = header.getOrDefault("X-Amz-Security-Token")
  valid_602082 = validateParameter(valid_602082, JString, required = false,
                                 default = nil)
  if valid_602082 != nil:
    section.add "X-Amz-Security-Token", valid_602082
  var valid_602083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Content-Sha256", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Algorithm")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Algorithm", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Signature")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Signature", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-SignedHeaders", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Credential")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Credential", valid_602087
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602088 = formData.getOrDefault("Marker")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "Marker", valid_602088
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602089 = formData.getOrDefault("DBParameterGroupFamily")
  valid_602089 = validateParameter(valid_602089, JString, required = true,
                                 default = nil)
  if valid_602089 != nil:
    section.add "DBParameterGroupFamily", valid_602089
  var valid_602090 = formData.getOrDefault("MaxRecords")
  valid_602090 = validateParameter(valid_602090, JInt, required = false, default = nil)
  if valid_602090 != nil:
    section.add "MaxRecords", valid_602090
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602091: Call_PostDescribeEngineDefaultParameters_602076;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602091.validator(path, query, header, formData, body)
  let scheme = call_602091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602091.url(scheme.get, call_602091.host, call_602091.base,
                         call_602091.route, valid.getOrDefault("path"))
  result = hook(call_602091, url, valid)

proc call*(call_602092: Call_PostDescribeEngineDefaultParameters_602076;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602093 = newJObject()
  var formData_602094 = newJObject()
  add(formData_602094, "Marker", newJString(Marker))
  add(query_602093, "Action", newJString(Action))
  add(formData_602094, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_602094, "MaxRecords", newJInt(MaxRecords))
  add(query_602093, "Version", newJString(Version))
  result = call_602092.call(nil, query_602093, nil, formData_602094, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_602076(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_602077, base: "/",
    url: url_PostDescribeEngineDefaultParameters_602078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_602058 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEngineDefaultParameters_602060(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_602059(path: JsonNode;
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
  var valid_602061 = query.getOrDefault("MaxRecords")
  valid_602061 = validateParameter(valid_602061, JInt, required = false, default = nil)
  if valid_602061 != nil:
    section.add "MaxRecords", valid_602061
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_602062 = query.getOrDefault("DBParameterGroupFamily")
  valid_602062 = validateParameter(valid_602062, JString, required = true,
                                 default = nil)
  if valid_602062 != nil:
    section.add "DBParameterGroupFamily", valid_602062
  var valid_602063 = query.getOrDefault("Action")
  valid_602063 = validateParameter(valid_602063, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_602063 != nil:
    section.add "Action", valid_602063
  var valid_602064 = query.getOrDefault("Marker")
  valid_602064 = validateParameter(valid_602064, JString, required = false,
                                 default = nil)
  if valid_602064 != nil:
    section.add "Marker", valid_602064
  var valid_602065 = query.getOrDefault("Version")
  valid_602065 = validateParameter(valid_602065, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602065 != nil:
    section.add "Version", valid_602065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602066 = header.getOrDefault("X-Amz-Date")
  valid_602066 = validateParameter(valid_602066, JString, required = false,
                                 default = nil)
  if valid_602066 != nil:
    section.add "X-Amz-Date", valid_602066
  var valid_602067 = header.getOrDefault("X-Amz-Security-Token")
  valid_602067 = validateParameter(valid_602067, JString, required = false,
                                 default = nil)
  if valid_602067 != nil:
    section.add "X-Amz-Security-Token", valid_602067
  var valid_602068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602068 = validateParameter(valid_602068, JString, required = false,
                                 default = nil)
  if valid_602068 != nil:
    section.add "X-Amz-Content-Sha256", valid_602068
  var valid_602069 = header.getOrDefault("X-Amz-Algorithm")
  valid_602069 = validateParameter(valid_602069, JString, required = false,
                                 default = nil)
  if valid_602069 != nil:
    section.add "X-Amz-Algorithm", valid_602069
  var valid_602070 = header.getOrDefault("X-Amz-Signature")
  valid_602070 = validateParameter(valid_602070, JString, required = false,
                                 default = nil)
  if valid_602070 != nil:
    section.add "X-Amz-Signature", valid_602070
  var valid_602071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602071 = validateParameter(valid_602071, JString, required = false,
                                 default = nil)
  if valid_602071 != nil:
    section.add "X-Amz-SignedHeaders", valid_602071
  var valid_602072 = header.getOrDefault("X-Amz-Credential")
  valid_602072 = validateParameter(valid_602072, JString, required = false,
                                 default = nil)
  if valid_602072 != nil:
    section.add "X-Amz-Credential", valid_602072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602073: Call_GetDescribeEngineDefaultParameters_602058;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602073.validator(path, query, header, formData, body)
  let scheme = call_602073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602073.url(scheme.get, call_602073.host, call_602073.base,
                         call_602073.route, valid.getOrDefault("path"))
  result = hook(call_602073, url, valid)

proc call*(call_602074: Call_GetDescribeEngineDefaultParameters_602058;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_602075 = newJObject()
  add(query_602075, "MaxRecords", newJInt(MaxRecords))
  add(query_602075, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_602075, "Action", newJString(Action))
  add(query_602075, "Marker", newJString(Marker))
  add(query_602075, "Version", newJString(Version))
  result = call_602074.call(nil, query_602075, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_602058(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_602059, base: "/",
    url: url_GetDescribeEngineDefaultParameters_602060,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_602111 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventCategories_602113(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_602112(path: JsonNode; query: JsonNode;
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
  var valid_602114 = query.getOrDefault("Action")
  valid_602114 = validateParameter(valid_602114, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602114 != nil:
    section.add "Action", valid_602114
  var valid_602115 = query.getOrDefault("Version")
  valid_602115 = validateParameter(valid_602115, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602115 != nil:
    section.add "Version", valid_602115
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602116 = header.getOrDefault("X-Amz-Date")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Date", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Security-Token")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Security-Token", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Content-Sha256", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-Algorithm")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-Algorithm", valid_602119
  var valid_602120 = header.getOrDefault("X-Amz-Signature")
  valid_602120 = validateParameter(valid_602120, JString, required = false,
                                 default = nil)
  if valid_602120 != nil:
    section.add "X-Amz-Signature", valid_602120
  var valid_602121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602121 = validateParameter(valid_602121, JString, required = false,
                                 default = nil)
  if valid_602121 != nil:
    section.add "X-Amz-SignedHeaders", valid_602121
  var valid_602122 = header.getOrDefault("X-Amz-Credential")
  valid_602122 = validateParameter(valid_602122, JString, required = false,
                                 default = nil)
  if valid_602122 != nil:
    section.add "X-Amz-Credential", valid_602122
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_602123 = formData.getOrDefault("SourceType")
  valid_602123 = validateParameter(valid_602123, JString, required = false,
                                 default = nil)
  if valid_602123 != nil:
    section.add "SourceType", valid_602123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602124: Call_PostDescribeEventCategories_602111; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602124.validator(path, query, header, formData, body)
  let scheme = call_602124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602124.url(scheme.get, call_602124.host, call_602124.base,
                         call_602124.route, valid.getOrDefault("path"))
  result = hook(call_602124, url, valid)

proc call*(call_602125: Call_PostDescribeEventCategories_602111;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_602126 = newJObject()
  var formData_602127 = newJObject()
  add(query_602126, "Action", newJString(Action))
  add(query_602126, "Version", newJString(Version))
  add(formData_602127, "SourceType", newJString(SourceType))
  result = call_602125.call(nil, query_602126, nil, formData_602127, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_602111(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_602112, base: "/",
    url: url_PostDescribeEventCategories_602113,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_602095 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventCategories_602097(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_602096(path: JsonNode; query: JsonNode;
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
  var valid_602098 = query.getOrDefault("SourceType")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "SourceType", valid_602098
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602099 = query.getOrDefault("Action")
  valid_602099 = validateParameter(valid_602099, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_602099 != nil:
    section.add "Action", valid_602099
  var valid_602100 = query.getOrDefault("Version")
  valid_602100 = validateParameter(valid_602100, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602100 != nil:
    section.add "Version", valid_602100
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602101 = header.getOrDefault("X-Amz-Date")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Date", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Security-Token")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Security-Token", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-Content-Sha256", valid_602103
  var valid_602104 = header.getOrDefault("X-Amz-Algorithm")
  valid_602104 = validateParameter(valid_602104, JString, required = false,
                                 default = nil)
  if valid_602104 != nil:
    section.add "X-Amz-Algorithm", valid_602104
  var valid_602105 = header.getOrDefault("X-Amz-Signature")
  valid_602105 = validateParameter(valid_602105, JString, required = false,
                                 default = nil)
  if valid_602105 != nil:
    section.add "X-Amz-Signature", valid_602105
  var valid_602106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602106 = validateParameter(valid_602106, JString, required = false,
                                 default = nil)
  if valid_602106 != nil:
    section.add "X-Amz-SignedHeaders", valid_602106
  var valid_602107 = header.getOrDefault("X-Amz-Credential")
  valid_602107 = validateParameter(valid_602107, JString, required = false,
                                 default = nil)
  if valid_602107 != nil:
    section.add "X-Amz-Credential", valid_602107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602108: Call_GetDescribeEventCategories_602095; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602108.validator(path, query, header, formData, body)
  let scheme = call_602108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602108.url(scheme.get, call_602108.host, call_602108.base,
                         call_602108.route, valid.getOrDefault("path"))
  result = hook(call_602108, url, valid)

proc call*(call_602109: Call_GetDescribeEventCategories_602095;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602110 = newJObject()
  add(query_602110, "SourceType", newJString(SourceType))
  add(query_602110, "Action", newJString(Action))
  add(query_602110, "Version", newJString(Version))
  result = call_602109.call(nil, query_602110, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_602095(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_602096, base: "/",
    url: url_GetDescribeEventCategories_602097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_602146 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEventSubscriptions_602148(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_602147(path: JsonNode;
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
  var valid_602149 = query.getOrDefault("Action")
  valid_602149 = validateParameter(valid_602149, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602149 != nil:
    section.add "Action", valid_602149
  var valid_602150 = query.getOrDefault("Version")
  valid_602150 = validateParameter(valid_602150, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602150 != nil:
    section.add "Version", valid_602150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602151 = header.getOrDefault("X-Amz-Date")
  valid_602151 = validateParameter(valid_602151, JString, required = false,
                                 default = nil)
  if valid_602151 != nil:
    section.add "X-Amz-Date", valid_602151
  var valid_602152 = header.getOrDefault("X-Amz-Security-Token")
  valid_602152 = validateParameter(valid_602152, JString, required = false,
                                 default = nil)
  if valid_602152 != nil:
    section.add "X-Amz-Security-Token", valid_602152
  var valid_602153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602153 = validateParameter(valid_602153, JString, required = false,
                                 default = nil)
  if valid_602153 != nil:
    section.add "X-Amz-Content-Sha256", valid_602153
  var valid_602154 = header.getOrDefault("X-Amz-Algorithm")
  valid_602154 = validateParameter(valid_602154, JString, required = false,
                                 default = nil)
  if valid_602154 != nil:
    section.add "X-Amz-Algorithm", valid_602154
  var valid_602155 = header.getOrDefault("X-Amz-Signature")
  valid_602155 = validateParameter(valid_602155, JString, required = false,
                                 default = nil)
  if valid_602155 != nil:
    section.add "X-Amz-Signature", valid_602155
  var valid_602156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602156 = validateParameter(valid_602156, JString, required = false,
                                 default = nil)
  if valid_602156 != nil:
    section.add "X-Amz-SignedHeaders", valid_602156
  var valid_602157 = header.getOrDefault("X-Amz-Credential")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Credential", valid_602157
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602158 = formData.getOrDefault("Marker")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "Marker", valid_602158
  var valid_602159 = formData.getOrDefault("SubscriptionName")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "SubscriptionName", valid_602159
  var valid_602160 = formData.getOrDefault("MaxRecords")
  valid_602160 = validateParameter(valid_602160, JInt, required = false, default = nil)
  if valid_602160 != nil:
    section.add "MaxRecords", valid_602160
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602161: Call_PostDescribeEventSubscriptions_602146; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602161.validator(path, query, header, formData, body)
  let scheme = call_602161.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602161.url(scheme.get, call_602161.host, call_602161.base,
                         call_602161.route, valid.getOrDefault("path"))
  result = hook(call_602161, url, valid)

proc call*(call_602162: Call_PostDescribeEventSubscriptions_602146;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_602163 = newJObject()
  var formData_602164 = newJObject()
  add(formData_602164, "Marker", newJString(Marker))
  add(formData_602164, "SubscriptionName", newJString(SubscriptionName))
  add(query_602163, "Action", newJString(Action))
  add(formData_602164, "MaxRecords", newJInt(MaxRecords))
  add(query_602163, "Version", newJString(Version))
  result = call_602162.call(nil, query_602163, nil, formData_602164, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_602146(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_602147, base: "/",
    url: url_PostDescribeEventSubscriptions_602148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_602128 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEventSubscriptions_602130(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_602129(path: JsonNode; query: JsonNode;
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
  var valid_602131 = query.getOrDefault("MaxRecords")
  valid_602131 = validateParameter(valid_602131, JInt, required = false, default = nil)
  if valid_602131 != nil:
    section.add "MaxRecords", valid_602131
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602132 = query.getOrDefault("Action")
  valid_602132 = validateParameter(valid_602132, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_602132 != nil:
    section.add "Action", valid_602132
  var valid_602133 = query.getOrDefault("Marker")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "Marker", valid_602133
  var valid_602134 = query.getOrDefault("SubscriptionName")
  valid_602134 = validateParameter(valid_602134, JString, required = false,
                                 default = nil)
  if valid_602134 != nil:
    section.add "SubscriptionName", valid_602134
  var valid_602135 = query.getOrDefault("Version")
  valid_602135 = validateParameter(valid_602135, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602135 != nil:
    section.add "Version", valid_602135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602136 = header.getOrDefault("X-Amz-Date")
  valid_602136 = validateParameter(valid_602136, JString, required = false,
                                 default = nil)
  if valid_602136 != nil:
    section.add "X-Amz-Date", valid_602136
  var valid_602137 = header.getOrDefault("X-Amz-Security-Token")
  valid_602137 = validateParameter(valid_602137, JString, required = false,
                                 default = nil)
  if valid_602137 != nil:
    section.add "X-Amz-Security-Token", valid_602137
  var valid_602138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602138 = validateParameter(valid_602138, JString, required = false,
                                 default = nil)
  if valid_602138 != nil:
    section.add "X-Amz-Content-Sha256", valid_602138
  var valid_602139 = header.getOrDefault("X-Amz-Algorithm")
  valid_602139 = validateParameter(valid_602139, JString, required = false,
                                 default = nil)
  if valid_602139 != nil:
    section.add "X-Amz-Algorithm", valid_602139
  var valid_602140 = header.getOrDefault("X-Amz-Signature")
  valid_602140 = validateParameter(valid_602140, JString, required = false,
                                 default = nil)
  if valid_602140 != nil:
    section.add "X-Amz-Signature", valid_602140
  var valid_602141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-SignedHeaders", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Credential")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Credential", valid_602142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602143: Call_GetDescribeEventSubscriptions_602128; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602143.validator(path, query, header, formData, body)
  let scheme = call_602143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602143.url(scheme.get, call_602143.host, call_602143.base,
                         call_602143.route, valid.getOrDefault("path"))
  result = hook(call_602143, url, valid)

proc call*(call_602144: Call_GetDescribeEventSubscriptions_602128;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_602145 = newJObject()
  add(query_602145, "MaxRecords", newJInt(MaxRecords))
  add(query_602145, "Action", newJString(Action))
  add(query_602145, "Marker", newJString(Marker))
  add(query_602145, "SubscriptionName", newJString(SubscriptionName))
  add(query_602145, "Version", newJString(Version))
  result = call_602144.call(nil, query_602145, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_602128(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_602129, base: "/",
    url: url_GetDescribeEventSubscriptions_602130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_602188 = ref object of OpenApiRestCall_600410
proc url_PostDescribeEvents_602190(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_602189(path: JsonNode; query: JsonNode;
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
  var valid_602191 = query.getOrDefault("Action")
  valid_602191 = validateParameter(valid_602191, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602191 != nil:
    section.add "Action", valid_602191
  var valid_602192 = query.getOrDefault("Version")
  valid_602192 = validateParameter(valid_602192, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_602200 = formData.getOrDefault("SourceIdentifier")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "SourceIdentifier", valid_602200
  var valid_602201 = formData.getOrDefault("EventCategories")
  valid_602201 = validateParameter(valid_602201, JArray, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "EventCategories", valid_602201
  var valid_602202 = formData.getOrDefault("Marker")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "Marker", valid_602202
  var valid_602203 = formData.getOrDefault("StartTime")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "StartTime", valid_602203
  var valid_602204 = formData.getOrDefault("Duration")
  valid_602204 = validateParameter(valid_602204, JInt, required = false, default = nil)
  if valid_602204 != nil:
    section.add "Duration", valid_602204
  var valid_602205 = formData.getOrDefault("EndTime")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "EndTime", valid_602205
  var valid_602206 = formData.getOrDefault("MaxRecords")
  valid_602206 = validateParameter(valid_602206, JInt, required = false, default = nil)
  if valid_602206 != nil:
    section.add "MaxRecords", valid_602206
  var valid_602207 = formData.getOrDefault("SourceType")
  valid_602207 = validateParameter(valid_602207, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602207 != nil:
    section.add "SourceType", valid_602207
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602208: Call_PostDescribeEvents_602188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602208.validator(path, query, header, formData, body)
  let scheme = call_602208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602208.url(scheme.get, call_602208.host, call_602208.base,
                         call_602208.route, valid.getOrDefault("path"))
  result = hook(call_602208, url, valid)

proc call*(call_602209: Call_PostDescribeEvents_602188;
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
  var query_602210 = newJObject()
  var formData_602211 = newJObject()
  add(formData_602211, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_602211.add "EventCategories", EventCategories
  add(formData_602211, "Marker", newJString(Marker))
  add(formData_602211, "StartTime", newJString(StartTime))
  add(query_602210, "Action", newJString(Action))
  add(formData_602211, "Duration", newJInt(Duration))
  add(formData_602211, "EndTime", newJString(EndTime))
  add(formData_602211, "MaxRecords", newJInt(MaxRecords))
  add(query_602210, "Version", newJString(Version))
  add(formData_602211, "SourceType", newJString(SourceType))
  result = call_602209.call(nil, query_602210, nil, formData_602211, nil)

var postDescribeEvents* = Call_PostDescribeEvents_602188(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_602189, base: "/",
    url: url_PostDescribeEvents_602190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_602165 = ref object of OpenApiRestCall_600410
proc url_GetDescribeEvents_602167(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_602166(path: JsonNode; query: JsonNode;
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
  var valid_602168 = query.getOrDefault("SourceType")
  valid_602168 = validateParameter(valid_602168, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_602168 != nil:
    section.add "SourceType", valid_602168
  var valid_602169 = query.getOrDefault("MaxRecords")
  valid_602169 = validateParameter(valid_602169, JInt, required = false, default = nil)
  if valid_602169 != nil:
    section.add "MaxRecords", valid_602169
  var valid_602170 = query.getOrDefault("StartTime")
  valid_602170 = validateParameter(valid_602170, JString, required = false,
                                 default = nil)
  if valid_602170 != nil:
    section.add "StartTime", valid_602170
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602171 = query.getOrDefault("Action")
  valid_602171 = validateParameter(valid_602171, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_602171 != nil:
    section.add "Action", valid_602171
  var valid_602172 = query.getOrDefault("SourceIdentifier")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "SourceIdentifier", valid_602172
  var valid_602173 = query.getOrDefault("Marker")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "Marker", valid_602173
  var valid_602174 = query.getOrDefault("EventCategories")
  valid_602174 = validateParameter(valid_602174, JArray, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "EventCategories", valid_602174
  var valid_602175 = query.getOrDefault("Duration")
  valid_602175 = validateParameter(valid_602175, JInt, required = false, default = nil)
  if valid_602175 != nil:
    section.add "Duration", valid_602175
  var valid_602176 = query.getOrDefault("EndTime")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "EndTime", valid_602176
  var valid_602177 = query.getOrDefault("Version")
  valid_602177 = validateParameter(valid_602177, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602177 != nil:
    section.add "Version", valid_602177
  result.add "query", section
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

proc call*(call_602185: Call_GetDescribeEvents_602165; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602185.validator(path, query, header, formData, body)
  let scheme = call_602185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602185.url(scheme.get, call_602185.host, call_602185.base,
                         call_602185.route, valid.getOrDefault("path"))
  result = hook(call_602185, url, valid)

proc call*(call_602186: Call_GetDescribeEvents_602165;
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
  var query_602187 = newJObject()
  add(query_602187, "SourceType", newJString(SourceType))
  add(query_602187, "MaxRecords", newJInt(MaxRecords))
  add(query_602187, "StartTime", newJString(StartTime))
  add(query_602187, "Action", newJString(Action))
  add(query_602187, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602187, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_602187.add "EventCategories", EventCategories
  add(query_602187, "Duration", newJInt(Duration))
  add(query_602187, "EndTime", newJString(EndTime))
  add(query_602187, "Version", newJString(Version))
  result = call_602186.call(nil, query_602187, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_602165(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_602166,
    base: "/", url: url_GetDescribeEvents_602167,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_602231 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroupOptions_602233(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_602232(path: JsonNode;
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
  var valid_602234 = query.getOrDefault("Action")
  valid_602234 = validateParameter(valid_602234, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602234 != nil:
    section.add "Action", valid_602234
  var valid_602235 = query.getOrDefault("Version")
  valid_602235 = validateParameter(valid_602235, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602243 = formData.getOrDefault("MajorEngineVersion")
  valid_602243 = validateParameter(valid_602243, JString, required = false,
                                 default = nil)
  if valid_602243 != nil:
    section.add "MajorEngineVersion", valid_602243
  var valid_602244 = formData.getOrDefault("Marker")
  valid_602244 = validateParameter(valid_602244, JString, required = false,
                                 default = nil)
  if valid_602244 != nil:
    section.add "Marker", valid_602244
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_602245 = formData.getOrDefault("EngineName")
  valid_602245 = validateParameter(valid_602245, JString, required = true,
                                 default = nil)
  if valid_602245 != nil:
    section.add "EngineName", valid_602245
  var valid_602246 = formData.getOrDefault("MaxRecords")
  valid_602246 = validateParameter(valid_602246, JInt, required = false, default = nil)
  if valid_602246 != nil:
    section.add "MaxRecords", valid_602246
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602247: Call_PostDescribeOptionGroupOptions_602231; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602247.validator(path, query, header, formData, body)
  let scheme = call_602247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602247.url(scheme.get, call_602247.host, call_602247.base,
                         call_602247.route, valid.getOrDefault("path"))
  result = hook(call_602247, url, valid)

proc call*(call_602248: Call_PostDescribeOptionGroupOptions_602231;
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
  var query_602249 = newJObject()
  var formData_602250 = newJObject()
  add(formData_602250, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602250, "Marker", newJString(Marker))
  add(query_602249, "Action", newJString(Action))
  add(formData_602250, "EngineName", newJString(EngineName))
  add(formData_602250, "MaxRecords", newJInt(MaxRecords))
  add(query_602249, "Version", newJString(Version))
  result = call_602248.call(nil, query_602249, nil, formData_602250, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_602231(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_602232, base: "/",
    url: url_PostDescribeOptionGroupOptions_602233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_602212 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroupOptions_602214(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_602213(path: JsonNode; query: JsonNode;
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
  var valid_602215 = query.getOrDefault("MaxRecords")
  valid_602215 = validateParameter(valid_602215, JInt, required = false, default = nil)
  if valid_602215 != nil:
    section.add "MaxRecords", valid_602215
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602216 = query.getOrDefault("Action")
  valid_602216 = validateParameter(valid_602216, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_602216 != nil:
    section.add "Action", valid_602216
  var valid_602217 = query.getOrDefault("Marker")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "Marker", valid_602217
  var valid_602218 = query.getOrDefault("Version")
  valid_602218 = validateParameter(valid_602218, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602218 != nil:
    section.add "Version", valid_602218
  var valid_602219 = query.getOrDefault("EngineName")
  valid_602219 = validateParameter(valid_602219, JString, required = true,
                                 default = nil)
  if valid_602219 != nil:
    section.add "EngineName", valid_602219
  var valid_602220 = query.getOrDefault("MajorEngineVersion")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "MajorEngineVersion", valid_602220
  result.add "query", section
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

proc call*(call_602228: Call_GetDescribeOptionGroupOptions_602212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602228.validator(path, query, header, formData, body)
  let scheme = call_602228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602228.url(scheme.get, call_602228.host, call_602228.base,
                         call_602228.route, valid.getOrDefault("path"))
  result = hook(call_602228, url, valid)

proc call*(call_602229: Call_GetDescribeOptionGroupOptions_602212;
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
  var query_602230 = newJObject()
  add(query_602230, "MaxRecords", newJInt(MaxRecords))
  add(query_602230, "Action", newJString(Action))
  add(query_602230, "Marker", newJString(Marker))
  add(query_602230, "Version", newJString(Version))
  add(query_602230, "EngineName", newJString(EngineName))
  add(query_602230, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602229.call(nil, query_602230, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_602212(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_602213, base: "/",
    url: url_GetDescribeOptionGroupOptions_602214,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_602271 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOptionGroups_602273(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_602272(path: JsonNode; query: JsonNode;
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
  var valid_602274 = query.getOrDefault("Action")
  valid_602274 = validateParameter(valid_602274, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602274 != nil:
    section.add "Action", valid_602274
  var valid_602275 = query.getOrDefault("Version")
  valid_602275 = validateParameter(valid_602275, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_602283 = formData.getOrDefault("MajorEngineVersion")
  valid_602283 = validateParameter(valid_602283, JString, required = false,
                                 default = nil)
  if valid_602283 != nil:
    section.add "MajorEngineVersion", valid_602283
  var valid_602284 = formData.getOrDefault("OptionGroupName")
  valid_602284 = validateParameter(valid_602284, JString, required = false,
                                 default = nil)
  if valid_602284 != nil:
    section.add "OptionGroupName", valid_602284
  var valid_602285 = formData.getOrDefault("Marker")
  valid_602285 = validateParameter(valid_602285, JString, required = false,
                                 default = nil)
  if valid_602285 != nil:
    section.add "Marker", valid_602285
  var valid_602286 = formData.getOrDefault("EngineName")
  valid_602286 = validateParameter(valid_602286, JString, required = false,
                                 default = nil)
  if valid_602286 != nil:
    section.add "EngineName", valid_602286
  var valid_602287 = formData.getOrDefault("MaxRecords")
  valid_602287 = validateParameter(valid_602287, JInt, required = false, default = nil)
  if valid_602287 != nil:
    section.add "MaxRecords", valid_602287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602288: Call_PostDescribeOptionGroups_602271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602288.validator(path, query, header, formData, body)
  let scheme = call_602288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602288.url(scheme.get, call_602288.host, call_602288.base,
                         call_602288.route, valid.getOrDefault("path"))
  result = hook(call_602288, url, valid)

proc call*(call_602289: Call_PostDescribeOptionGroups_602271;
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
  var query_602290 = newJObject()
  var formData_602291 = newJObject()
  add(formData_602291, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_602291, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602291, "Marker", newJString(Marker))
  add(query_602290, "Action", newJString(Action))
  add(formData_602291, "EngineName", newJString(EngineName))
  add(formData_602291, "MaxRecords", newJInt(MaxRecords))
  add(query_602290, "Version", newJString(Version))
  result = call_602289.call(nil, query_602290, nil, formData_602291, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_602271(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_602272, base: "/",
    url: url_PostDescribeOptionGroups_602273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_602251 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOptionGroups_602253(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_602252(path: JsonNode; query: JsonNode;
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
  var valid_602254 = query.getOrDefault("MaxRecords")
  valid_602254 = validateParameter(valid_602254, JInt, required = false, default = nil)
  if valid_602254 != nil:
    section.add "MaxRecords", valid_602254
  var valid_602255 = query.getOrDefault("OptionGroupName")
  valid_602255 = validateParameter(valid_602255, JString, required = false,
                                 default = nil)
  if valid_602255 != nil:
    section.add "OptionGroupName", valid_602255
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602256 = query.getOrDefault("Action")
  valid_602256 = validateParameter(valid_602256, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_602256 != nil:
    section.add "Action", valid_602256
  var valid_602257 = query.getOrDefault("Marker")
  valid_602257 = validateParameter(valid_602257, JString, required = false,
                                 default = nil)
  if valid_602257 != nil:
    section.add "Marker", valid_602257
  var valid_602258 = query.getOrDefault("Version")
  valid_602258 = validateParameter(valid_602258, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602258 != nil:
    section.add "Version", valid_602258
  var valid_602259 = query.getOrDefault("EngineName")
  valid_602259 = validateParameter(valid_602259, JString, required = false,
                                 default = nil)
  if valid_602259 != nil:
    section.add "EngineName", valid_602259
  var valid_602260 = query.getOrDefault("MajorEngineVersion")
  valid_602260 = validateParameter(valid_602260, JString, required = false,
                                 default = nil)
  if valid_602260 != nil:
    section.add "MajorEngineVersion", valid_602260
  result.add "query", section
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

proc call*(call_602268: Call_GetDescribeOptionGroups_602251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602268.validator(path, query, header, formData, body)
  let scheme = call_602268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602268.url(scheme.get, call_602268.host, call_602268.base,
                         call_602268.route, valid.getOrDefault("path"))
  result = hook(call_602268, url, valid)

proc call*(call_602269: Call_GetDescribeOptionGroups_602251; MaxRecords: int = 0;
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
  var query_602270 = newJObject()
  add(query_602270, "MaxRecords", newJInt(MaxRecords))
  add(query_602270, "OptionGroupName", newJString(OptionGroupName))
  add(query_602270, "Action", newJString(Action))
  add(query_602270, "Marker", newJString(Marker))
  add(query_602270, "Version", newJString(Version))
  add(query_602270, "EngineName", newJString(EngineName))
  add(query_602270, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_602269.call(nil, query_602270, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_602251(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_602252, base: "/",
    url: url_GetDescribeOptionGroups_602253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_602314 = ref object of OpenApiRestCall_600410
proc url_PostDescribeOrderableDBInstanceOptions_602316(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_602315(path: JsonNode;
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
  var valid_602317 = query.getOrDefault("Action")
  valid_602317 = validateParameter(valid_602317, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602317 != nil:
    section.add "Action", valid_602317
  var valid_602318 = query.getOrDefault("Version")
  valid_602318 = validateParameter(valid_602318, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602318 != nil:
    section.add "Version", valid_602318
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602319 = header.getOrDefault("X-Amz-Date")
  valid_602319 = validateParameter(valid_602319, JString, required = false,
                                 default = nil)
  if valid_602319 != nil:
    section.add "X-Amz-Date", valid_602319
  var valid_602320 = header.getOrDefault("X-Amz-Security-Token")
  valid_602320 = validateParameter(valid_602320, JString, required = false,
                                 default = nil)
  if valid_602320 != nil:
    section.add "X-Amz-Security-Token", valid_602320
  var valid_602321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602321 = validateParameter(valid_602321, JString, required = false,
                                 default = nil)
  if valid_602321 != nil:
    section.add "X-Amz-Content-Sha256", valid_602321
  var valid_602322 = header.getOrDefault("X-Amz-Algorithm")
  valid_602322 = validateParameter(valid_602322, JString, required = false,
                                 default = nil)
  if valid_602322 != nil:
    section.add "X-Amz-Algorithm", valid_602322
  var valid_602323 = header.getOrDefault("X-Amz-Signature")
  valid_602323 = validateParameter(valid_602323, JString, required = false,
                                 default = nil)
  if valid_602323 != nil:
    section.add "X-Amz-Signature", valid_602323
  var valid_602324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602324 = validateParameter(valid_602324, JString, required = false,
                                 default = nil)
  if valid_602324 != nil:
    section.add "X-Amz-SignedHeaders", valid_602324
  var valid_602325 = header.getOrDefault("X-Amz-Credential")
  valid_602325 = validateParameter(valid_602325, JString, required = false,
                                 default = nil)
  if valid_602325 != nil:
    section.add "X-Amz-Credential", valid_602325
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
  var valid_602326 = formData.getOrDefault("Engine")
  valid_602326 = validateParameter(valid_602326, JString, required = true,
                                 default = nil)
  if valid_602326 != nil:
    section.add "Engine", valid_602326
  var valid_602327 = formData.getOrDefault("Marker")
  valid_602327 = validateParameter(valid_602327, JString, required = false,
                                 default = nil)
  if valid_602327 != nil:
    section.add "Marker", valid_602327
  var valid_602328 = formData.getOrDefault("Vpc")
  valid_602328 = validateParameter(valid_602328, JBool, required = false, default = nil)
  if valid_602328 != nil:
    section.add "Vpc", valid_602328
  var valid_602329 = formData.getOrDefault("DBInstanceClass")
  valid_602329 = validateParameter(valid_602329, JString, required = false,
                                 default = nil)
  if valid_602329 != nil:
    section.add "DBInstanceClass", valid_602329
  var valid_602330 = formData.getOrDefault("LicenseModel")
  valid_602330 = validateParameter(valid_602330, JString, required = false,
                                 default = nil)
  if valid_602330 != nil:
    section.add "LicenseModel", valid_602330
  var valid_602331 = formData.getOrDefault("MaxRecords")
  valid_602331 = validateParameter(valid_602331, JInt, required = false, default = nil)
  if valid_602331 != nil:
    section.add "MaxRecords", valid_602331
  var valid_602332 = formData.getOrDefault("EngineVersion")
  valid_602332 = validateParameter(valid_602332, JString, required = false,
                                 default = nil)
  if valid_602332 != nil:
    section.add "EngineVersion", valid_602332
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602333: Call_PostDescribeOrderableDBInstanceOptions_602314;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602333.validator(path, query, header, formData, body)
  let scheme = call_602333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602333.url(scheme.get, call_602333.host, call_602333.base,
                         call_602333.route, valid.getOrDefault("path"))
  result = hook(call_602333, url, valid)

proc call*(call_602334: Call_PostDescribeOrderableDBInstanceOptions_602314;
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
  var query_602335 = newJObject()
  var formData_602336 = newJObject()
  add(formData_602336, "Engine", newJString(Engine))
  add(formData_602336, "Marker", newJString(Marker))
  add(query_602335, "Action", newJString(Action))
  add(formData_602336, "Vpc", newJBool(Vpc))
  add(formData_602336, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602336, "LicenseModel", newJString(LicenseModel))
  add(formData_602336, "MaxRecords", newJInt(MaxRecords))
  add(formData_602336, "EngineVersion", newJString(EngineVersion))
  add(query_602335, "Version", newJString(Version))
  result = call_602334.call(nil, query_602335, nil, formData_602336, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_602314(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_602315, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_602316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_602292 = ref object of OpenApiRestCall_600410
proc url_GetDescribeOrderableDBInstanceOptions_602294(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_602293(path: JsonNode;
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
  var valid_602295 = query.getOrDefault("Engine")
  valid_602295 = validateParameter(valid_602295, JString, required = true,
                                 default = nil)
  if valid_602295 != nil:
    section.add "Engine", valid_602295
  var valid_602296 = query.getOrDefault("MaxRecords")
  valid_602296 = validateParameter(valid_602296, JInt, required = false, default = nil)
  if valid_602296 != nil:
    section.add "MaxRecords", valid_602296
  var valid_602297 = query.getOrDefault("LicenseModel")
  valid_602297 = validateParameter(valid_602297, JString, required = false,
                                 default = nil)
  if valid_602297 != nil:
    section.add "LicenseModel", valid_602297
  var valid_602298 = query.getOrDefault("Vpc")
  valid_602298 = validateParameter(valid_602298, JBool, required = false, default = nil)
  if valid_602298 != nil:
    section.add "Vpc", valid_602298
  var valid_602299 = query.getOrDefault("DBInstanceClass")
  valid_602299 = validateParameter(valid_602299, JString, required = false,
                                 default = nil)
  if valid_602299 != nil:
    section.add "DBInstanceClass", valid_602299
  var valid_602300 = query.getOrDefault("Action")
  valid_602300 = validateParameter(valid_602300, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_602300 != nil:
    section.add "Action", valid_602300
  var valid_602301 = query.getOrDefault("Marker")
  valid_602301 = validateParameter(valid_602301, JString, required = false,
                                 default = nil)
  if valid_602301 != nil:
    section.add "Marker", valid_602301
  var valid_602302 = query.getOrDefault("EngineVersion")
  valid_602302 = validateParameter(valid_602302, JString, required = false,
                                 default = nil)
  if valid_602302 != nil:
    section.add "EngineVersion", valid_602302
  var valid_602303 = query.getOrDefault("Version")
  valid_602303 = validateParameter(valid_602303, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602303 != nil:
    section.add "Version", valid_602303
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602304 = header.getOrDefault("X-Amz-Date")
  valid_602304 = validateParameter(valid_602304, JString, required = false,
                                 default = nil)
  if valid_602304 != nil:
    section.add "X-Amz-Date", valid_602304
  var valid_602305 = header.getOrDefault("X-Amz-Security-Token")
  valid_602305 = validateParameter(valid_602305, JString, required = false,
                                 default = nil)
  if valid_602305 != nil:
    section.add "X-Amz-Security-Token", valid_602305
  var valid_602306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602306 = validateParameter(valid_602306, JString, required = false,
                                 default = nil)
  if valid_602306 != nil:
    section.add "X-Amz-Content-Sha256", valid_602306
  var valid_602307 = header.getOrDefault("X-Amz-Algorithm")
  valid_602307 = validateParameter(valid_602307, JString, required = false,
                                 default = nil)
  if valid_602307 != nil:
    section.add "X-Amz-Algorithm", valid_602307
  var valid_602308 = header.getOrDefault("X-Amz-Signature")
  valid_602308 = validateParameter(valid_602308, JString, required = false,
                                 default = nil)
  if valid_602308 != nil:
    section.add "X-Amz-Signature", valid_602308
  var valid_602309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602309 = validateParameter(valid_602309, JString, required = false,
                                 default = nil)
  if valid_602309 != nil:
    section.add "X-Amz-SignedHeaders", valid_602309
  var valid_602310 = header.getOrDefault("X-Amz-Credential")
  valid_602310 = validateParameter(valid_602310, JString, required = false,
                                 default = nil)
  if valid_602310 != nil:
    section.add "X-Amz-Credential", valid_602310
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602311: Call_GetDescribeOrderableDBInstanceOptions_602292;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602311.validator(path, query, header, formData, body)
  let scheme = call_602311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602311.url(scheme.get, call_602311.host, call_602311.base,
                         call_602311.route, valid.getOrDefault("path"))
  result = hook(call_602311, url, valid)

proc call*(call_602312: Call_GetDescribeOrderableDBInstanceOptions_602292;
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
  var query_602313 = newJObject()
  add(query_602313, "Engine", newJString(Engine))
  add(query_602313, "MaxRecords", newJInt(MaxRecords))
  add(query_602313, "LicenseModel", newJString(LicenseModel))
  add(query_602313, "Vpc", newJBool(Vpc))
  add(query_602313, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602313, "Action", newJString(Action))
  add(query_602313, "Marker", newJString(Marker))
  add(query_602313, "EngineVersion", newJString(EngineVersion))
  add(query_602313, "Version", newJString(Version))
  result = call_602312.call(nil, query_602313, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_602292(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_602293, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_602294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_602361 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstances_602363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_602362(path: JsonNode;
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
  var valid_602364 = query.getOrDefault("Action")
  valid_602364 = validateParameter(valid_602364, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602364 != nil:
    section.add "Action", valid_602364
  var valid_602365 = query.getOrDefault("Version")
  valid_602365 = validateParameter(valid_602365, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602365 != nil:
    section.add "Version", valid_602365
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602366 = header.getOrDefault("X-Amz-Date")
  valid_602366 = validateParameter(valid_602366, JString, required = false,
                                 default = nil)
  if valid_602366 != nil:
    section.add "X-Amz-Date", valid_602366
  var valid_602367 = header.getOrDefault("X-Amz-Security-Token")
  valid_602367 = validateParameter(valid_602367, JString, required = false,
                                 default = nil)
  if valid_602367 != nil:
    section.add "X-Amz-Security-Token", valid_602367
  var valid_602368 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602368 = validateParameter(valid_602368, JString, required = false,
                                 default = nil)
  if valid_602368 != nil:
    section.add "X-Amz-Content-Sha256", valid_602368
  var valid_602369 = header.getOrDefault("X-Amz-Algorithm")
  valid_602369 = validateParameter(valid_602369, JString, required = false,
                                 default = nil)
  if valid_602369 != nil:
    section.add "X-Amz-Algorithm", valid_602369
  var valid_602370 = header.getOrDefault("X-Amz-Signature")
  valid_602370 = validateParameter(valid_602370, JString, required = false,
                                 default = nil)
  if valid_602370 != nil:
    section.add "X-Amz-Signature", valid_602370
  var valid_602371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602371 = validateParameter(valid_602371, JString, required = false,
                                 default = nil)
  if valid_602371 != nil:
    section.add "X-Amz-SignedHeaders", valid_602371
  var valid_602372 = header.getOrDefault("X-Amz-Credential")
  valid_602372 = validateParameter(valid_602372, JString, required = false,
                                 default = nil)
  if valid_602372 != nil:
    section.add "X-Amz-Credential", valid_602372
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
  var valid_602373 = formData.getOrDefault("OfferingType")
  valid_602373 = validateParameter(valid_602373, JString, required = false,
                                 default = nil)
  if valid_602373 != nil:
    section.add "OfferingType", valid_602373
  var valid_602374 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602374 = validateParameter(valid_602374, JString, required = false,
                                 default = nil)
  if valid_602374 != nil:
    section.add "ReservedDBInstanceId", valid_602374
  var valid_602375 = formData.getOrDefault("Marker")
  valid_602375 = validateParameter(valid_602375, JString, required = false,
                                 default = nil)
  if valid_602375 != nil:
    section.add "Marker", valid_602375
  var valid_602376 = formData.getOrDefault("MultiAZ")
  valid_602376 = validateParameter(valid_602376, JBool, required = false, default = nil)
  if valid_602376 != nil:
    section.add "MultiAZ", valid_602376
  var valid_602377 = formData.getOrDefault("Duration")
  valid_602377 = validateParameter(valid_602377, JString, required = false,
                                 default = nil)
  if valid_602377 != nil:
    section.add "Duration", valid_602377
  var valid_602378 = formData.getOrDefault("DBInstanceClass")
  valid_602378 = validateParameter(valid_602378, JString, required = false,
                                 default = nil)
  if valid_602378 != nil:
    section.add "DBInstanceClass", valid_602378
  var valid_602379 = formData.getOrDefault("ProductDescription")
  valid_602379 = validateParameter(valid_602379, JString, required = false,
                                 default = nil)
  if valid_602379 != nil:
    section.add "ProductDescription", valid_602379
  var valid_602380 = formData.getOrDefault("MaxRecords")
  valid_602380 = validateParameter(valid_602380, JInt, required = false, default = nil)
  if valid_602380 != nil:
    section.add "MaxRecords", valid_602380
  var valid_602381 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602381 = validateParameter(valid_602381, JString, required = false,
                                 default = nil)
  if valid_602381 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602381
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602382: Call_PostDescribeReservedDBInstances_602361;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602382.validator(path, query, header, formData, body)
  let scheme = call_602382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602382.url(scheme.get, call_602382.host, call_602382.base,
                         call_602382.route, valid.getOrDefault("path"))
  result = hook(call_602382, url, valid)

proc call*(call_602383: Call_PostDescribeReservedDBInstances_602361;
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
  var query_602384 = newJObject()
  var formData_602385 = newJObject()
  add(formData_602385, "OfferingType", newJString(OfferingType))
  add(formData_602385, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602385, "Marker", newJString(Marker))
  add(formData_602385, "MultiAZ", newJBool(MultiAZ))
  add(query_602384, "Action", newJString(Action))
  add(formData_602385, "Duration", newJString(Duration))
  add(formData_602385, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602385, "ProductDescription", newJString(ProductDescription))
  add(formData_602385, "MaxRecords", newJInt(MaxRecords))
  add(formData_602385, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602384, "Version", newJString(Version))
  result = call_602383.call(nil, query_602384, nil, formData_602385, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_602361(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_602362, base: "/",
    url: url_PostDescribeReservedDBInstances_602363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_602337 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstances_602339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_602338(path: JsonNode;
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
  var valid_602340 = query.getOrDefault("ProductDescription")
  valid_602340 = validateParameter(valid_602340, JString, required = false,
                                 default = nil)
  if valid_602340 != nil:
    section.add "ProductDescription", valid_602340
  var valid_602341 = query.getOrDefault("MaxRecords")
  valid_602341 = validateParameter(valid_602341, JInt, required = false, default = nil)
  if valid_602341 != nil:
    section.add "MaxRecords", valid_602341
  var valid_602342 = query.getOrDefault("OfferingType")
  valid_602342 = validateParameter(valid_602342, JString, required = false,
                                 default = nil)
  if valid_602342 != nil:
    section.add "OfferingType", valid_602342
  var valid_602343 = query.getOrDefault("MultiAZ")
  valid_602343 = validateParameter(valid_602343, JBool, required = false, default = nil)
  if valid_602343 != nil:
    section.add "MultiAZ", valid_602343
  var valid_602344 = query.getOrDefault("ReservedDBInstanceId")
  valid_602344 = validateParameter(valid_602344, JString, required = false,
                                 default = nil)
  if valid_602344 != nil:
    section.add "ReservedDBInstanceId", valid_602344
  var valid_602345 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602345 = validateParameter(valid_602345, JString, required = false,
                                 default = nil)
  if valid_602345 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602345
  var valid_602346 = query.getOrDefault("DBInstanceClass")
  valid_602346 = validateParameter(valid_602346, JString, required = false,
                                 default = nil)
  if valid_602346 != nil:
    section.add "DBInstanceClass", valid_602346
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602347 = query.getOrDefault("Action")
  valid_602347 = validateParameter(valid_602347, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_602347 != nil:
    section.add "Action", valid_602347
  var valid_602348 = query.getOrDefault("Marker")
  valid_602348 = validateParameter(valid_602348, JString, required = false,
                                 default = nil)
  if valid_602348 != nil:
    section.add "Marker", valid_602348
  var valid_602349 = query.getOrDefault("Duration")
  valid_602349 = validateParameter(valid_602349, JString, required = false,
                                 default = nil)
  if valid_602349 != nil:
    section.add "Duration", valid_602349
  var valid_602350 = query.getOrDefault("Version")
  valid_602350 = validateParameter(valid_602350, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602350 != nil:
    section.add "Version", valid_602350
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602351 = header.getOrDefault("X-Amz-Date")
  valid_602351 = validateParameter(valid_602351, JString, required = false,
                                 default = nil)
  if valid_602351 != nil:
    section.add "X-Amz-Date", valid_602351
  var valid_602352 = header.getOrDefault("X-Amz-Security-Token")
  valid_602352 = validateParameter(valid_602352, JString, required = false,
                                 default = nil)
  if valid_602352 != nil:
    section.add "X-Amz-Security-Token", valid_602352
  var valid_602353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602353 = validateParameter(valid_602353, JString, required = false,
                                 default = nil)
  if valid_602353 != nil:
    section.add "X-Amz-Content-Sha256", valid_602353
  var valid_602354 = header.getOrDefault("X-Amz-Algorithm")
  valid_602354 = validateParameter(valid_602354, JString, required = false,
                                 default = nil)
  if valid_602354 != nil:
    section.add "X-Amz-Algorithm", valid_602354
  var valid_602355 = header.getOrDefault("X-Amz-Signature")
  valid_602355 = validateParameter(valid_602355, JString, required = false,
                                 default = nil)
  if valid_602355 != nil:
    section.add "X-Amz-Signature", valid_602355
  var valid_602356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602356 = validateParameter(valid_602356, JString, required = false,
                                 default = nil)
  if valid_602356 != nil:
    section.add "X-Amz-SignedHeaders", valid_602356
  var valid_602357 = header.getOrDefault("X-Amz-Credential")
  valid_602357 = validateParameter(valid_602357, JString, required = false,
                                 default = nil)
  if valid_602357 != nil:
    section.add "X-Amz-Credential", valid_602357
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602358: Call_GetDescribeReservedDBInstances_602337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602358.validator(path, query, header, formData, body)
  let scheme = call_602358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602358.url(scheme.get, call_602358.host, call_602358.base,
                         call_602358.route, valid.getOrDefault("path"))
  result = hook(call_602358, url, valid)

proc call*(call_602359: Call_GetDescribeReservedDBInstances_602337;
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
  var query_602360 = newJObject()
  add(query_602360, "ProductDescription", newJString(ProductDescription))
  add(query_602360, "MaxRecords", newJInt(MaxRecords))
  add(query_602360, "OfferingType", newJString(OfferingType))
  add(query_602360, "MultiAZ", newJBool(MultiAZ))
  add(query_602360, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602360, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602360, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602360, "Action", newJString(Action))
  add(query_602360, "Marker", newJString(Marker))
  add(query_602360, "Duration", newJString(Duration))
  add(query_602360, "Version", newJString(Version))
  result = call_602359.call(nil, query_602360, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_602337(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_602338, base: "/",
    url: url_GetDescribeReservedDBInstances_602339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_602409 = ref object of OpenApiRestCall_600410
proc url_PostDescribeReservedDBInstancesOfferings_602411(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_602410(path: JsonNode;
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
  var valid_602412 = query.getOrDefault("Action")
  valid_602412 = validateParameter(valid_602412, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602412 != nil:
    section.add "Action", valid_602412
  var valid_602413 = query.getOrDefault("Version")
  valid_602413 = validateParameter(valid_602413, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602413 != nil:
    section.add "Version", valid_602413
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602414 = header.getOrDefault("X-Amz-Date")
  valid_602414 = validateParameter(valid_602414, JString, required = false,
                                 default = nil)
  if valid_602414 != nil:
    section.add "X-Amz-Date", valid_602414
  var valid_602415 = header.getOrDefault("X-Amz-Security-Token")
  valid_602415 = validateParameter(valid_602415, JString, required = false,
                                 default = nil)
  if valid_602415 != nil:
    section.add "X-Amz-Security-Token", valid_602415
  var valid_602416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602416 = validateParameter(valid_602416, JString, required = false,
                                 default = nil)
  if valid_602416 != nil:
    section.add "X-Amz-Content-Sha256", valid_602416
  var valid_602417 = header.getOrDefault("X-Amz-Algorithm")
  valid_602417 = validateParameter(valid_602417, JString, required = false,
                                 default = nil)
  if valid_602417 != nil:
    section.add "X-Amz-Algorithm", valid_602417
  var valid_602418 = header.getOrDefault("X-Amz-Signature")
  valid_602418 = validateParameter(valid_602418, JString, required = false,
                                 default = nil)
  if valid_602418 != nil:
    section.add "X-Amz-Signature", valid_602418
  var valid_602419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602419 = validateParameter(valid_602419, JString, required = false,
                                 default = nil)
  if valid_602419 != nil:
    section.add "X-Amz-SignedHeaders", valid_602419
  var valid_602420 = header.getOrDefault("X-Amz-Credential")
  valid_602420 = validateParameter(valid_602420, JString, required = false,
                                 default = nil)
  if valid_602420 != nil:
    section.add "X-Amz-Credential", valid_602420
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
  var valid_602421 = formData.getOrDefault("OfferingType")
  valid_602421 = validateParameter(valid_602421, JString, required = false,
                                 default = nil)
  if valid_602421 != nil:
    section.add "OfferingType", valid_602421
  var valid_602422 = formData.getOrDefault("Marker")
  valid_602422 = validateParameter(valid_602422, JString, required = false,
                                 default = nil)
  if valid_602422 != nil:
    section.add "Marker", valid_602422
  var valid_602423 = formData.getOrDefault("MultiAZ")
  valid_602423 = validateParameter(valid_602423, JBool, required = false, default = nil)
  if valid_602423 != nil:
    section.add "MultiAZ", valid_602423
  var valid_602424 = formData.getOrDefault("Duration")
  valid_602424 = validateParameter(valid_602424, JString, required = false,
                                 default = nil)
  if valid_602424 != nil:
    section.add "Duration", valid_602424
  var valid_602425 = formData.getOrDefault("DBInstanceClass")
  valid_602425 = validateParameter(valid_602425, JString, required = false,
                                 default = nil)
  if valid_602425 != nil:
    section.add "DBInstanceClass", valid_602425
  var valid_602426 = formData.getOrDefault("ProductDescription")
  valid_602426 = validateParameter(valid_602426, JString, required = false,
                                 default = nil)
  if valid_602426 != nil:
    section.add "ProductDescription", valid_602426
  var valid_602427 = formData.getOrDefault("MaxRecords")
  valid_602427 = validateParameter(valid_602427, JInt, required = false, default = nil)
  if valid_602427 != nil:
    section.add "MaxRecords", valid_602427
  var valid_602428 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602428 = validateParameter(valid_602428, JString, required = false,
                                 default = nil)
  if valid_602428 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602428
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602429: Call_PostDescribeReservedDBInstancesOfferings_602409;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602429.validator(path, query, header, formData, body)
  let scheme = call_602429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602429.url(scheme.get, call_602429.host, call_602429.base,
                         call_602429.route, valid.getOrDefault("path"))
  result = hook(call_602429, url, valid)

proc call*(call_602430: Call_PostDescribeReservedDBInstancesOfferings_602409;
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
  var query_602431 = newJObject()
  var formData_602432 = newJObject()
  add(formData_602432, "OfferingType", newJString(OfferingType))
  add(formData_602432, "Marker", newJString(Marker))
  add(formData_602432, "MultiAZ", newJBool(MultiAZ))
  add(query_602431, "Action", newJString(Action))
  add(formData_602432, "Duration", newJString(Duration))
  add(formData_602432, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602432, "ProductDescription", newJString(ProductDescription))
  add(formData_602432, "MaxRecords", newJInt(MaxRecords))
  add(formData_602432, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602431, "Version", newJString(Version))
  result = call_602430.call(nil, query_602431, nil, formData_602432, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_602409(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_602410,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_602411,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_602386 = ref object of OpenApiRestCall_600410
proc url_GetDescribeReservedDBInstancesOfferings_602388(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_602387(path: JsonNode;
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
  var valid_602389 = query.getOrDefault("ProductDescription")
  valid_602389 = validateParameter(valid_602389, JString, required = false,
                                 default = nil)
  if valid_602389 != nil:
    section.add "ProductDescription", valid_602389
  var valid_602390 = query.getOrDefault("MaxRecords")
  valid_602390 = validateParameter(valid_602390, JInt, required = false, default = nil)
  if valid_602390 != nil:
    section.add "MaxRecords", valid_602390
  var valid_602391 = query.getOrDefault("OfferingType")
  valid_602391 = validateParameter(valid_602391, JString, required = false,
                                 default = nil)
  if valid_602391 != nil:
    section.add "OfferingType", valid_602391
  var valid_602392 = query.getOrDefault("MultiAZ")
  valid_602392 = validateParameter(valid_602392, JBool, required = false, default = nil)
  if valid_602392 != nil:
    section.add "MultiAZ", valid_602392
  var valid_602393 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602393 = validateParameter(valid_602393, JString, required = false,
                                 default = nil)
  if valid_602393 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602393
  var valid_602394 = query.getOrDefault("DBInstanceClass")
  valid_602394 = validateParameter(valid_602394, JString, required = false,
                                 default = nil)
  if valid_602394 != nil:
    section.add "DBInstanceClass", valid_602394
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602395 = query.getOrDefault("Action")
  valid_602395 = validateParameter(valid_602395, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_602395 != nil:
    section.add "Action", valid_602395
  var valid_602396 = query.getOrDefault("Marker")
  valid_602396 = validateParameter(valid_602396, JString, required = false,
                                 default = nil)
  if valid_602396 != nil:
    section.add "Marker", valid_602396
  var valid_602397 = query.getOrDefault("Duration")
  valid_602397 = validateParameter(valid_602397, JString, required = false,
                                 default = nil)
  if valid_602397 != nil:
    section.add "Duration", valid_602397
  var valid_602398 = query.getOrDefault("Version")
  valid_602398 = validateParameter(valid_602398, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602398 != nil:
    section.add "Version", valid_602398
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602399 = header.getOrDefault("X-Amz-Date")
  valid_602399 = validateParameter(valid_602399, JString, required = false,
                                 default = nil)
  if valid_602399 != nil:
    section.add "X-Amz-Date", valid_602399
  var valid_602400 = header.getOrDefault("X-Amz-Security-Token")
  valid_602400 = validateParameter(valid_602400, JString, required = false,
                                 default = nil)
  if valid_602400 != nil:
    section.add "X-Amz-Security-Token", valid_602400
  var valid_602401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602401 = validateParameter(valid_602401, JString, required = false,
                                 default = nil)
  if valid_602401 != nil:
    section.add "X-Amz-Content-Sha256", valid_602401
  var valid_602402 = header.getOrDefault("X-Amz-Algorithm")
  valid_602402 = validateParameter(valid_602402, JString, required = false,
                                 default = nil)
  if valid_602402 != nil:
    section.add "X-Amz-Algorithm", valid_602402
  var valid_602403 = header.getOrDefault("X-Amz-Signature")
  valid_602403 = validateParameter(valid_602403, JString, required = false,
                                 default = nil)
  if valid_602403 != nil:
    section.add "X-Amz-Signature", valid_602403
  var valid_602404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602404 = validateParameter(valid_602404, JString, required = false,
                                 default = nil)
  if valid_602404 != nil:
    section.add "X-Amz-SignedHeaders", valid_602404
  var valid_602405 = header.getOrDefault("X-Amz-Credential")
  valid_602405 = validateParameter(valid_602405, JString, required = false,
                                 default = nil)
  if valid_602405 != nil:
    section.add "X-Amz-Credential", valid_602405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602406: Call_GetDescribeReservedDBInstancesOfferings_602386;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602406.validator(path, query, header, formData, body)
  let scheme = call_602406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602406.url(scheme.get, call_602406.host, call_602406.base,
                         call_602406.route, valid.getOrDefault("path"))
  result = hook(call_602406, url, valid)

proc call*(call_602407: Call_GetDescribeReservedDBInstancesOfferings_602386;
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
  var query_602408 = newJObject()
  add(query_602408, "ProductDescription", newJString(ProductDescription))
  add(query_602408, "MaxRecords", newJInt(MaxRecords))
  add(query_602408, "OfferingType", newJString(OfferingType))
  add(query_602408, "MultiAZ", newJBool(MultiAZ))
  add(query_602408, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602408, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602408, "Action", newJString(Action))
  add(query_602408, "Marker", newJString(Marker))
  add(query_602408, "Duration", newJString(Duration))
  add(query_602408, "Version", newJString(Version))
  result = call_602407.call(nil, query_602408, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_602386(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_602387, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_602388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_602452 = ref object of OpenApiRestCall_600410
proc url_PostDownloadDBLogFilePortion_602454(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_602453(path: JsonNode; query: JsonNode;
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
  var valid_602455 = query.getOrDefault("Action")
  valid_602455 = validateParameter(valid_602455, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602455 != nil:
    section.add "Action", valid_602455
  var valid_602456 = query.getOrDefault("Version")
  valid_602456 = validateParameter(valid_602456, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602456 != nil:
    section.add "Version", valid_602456
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602457 = header.getOrDefault("X-Amz-Date")
  valid_602457 = validateParameter(valid_602457, JString, required = false,
                                 default = nil)
  if valid_602457 != nil:
    section.add "X-Amz-Date", valid_602457
  var valid_602458 = header.getOrDefault("X-Amz-Security-Token")
  valid_602458 = validateParameter(valid_602458, JString, required = false,
                                 default = nil)
  if valid_602458 != nil:
    section.add "X-Amz-Security-Token", valid_602458
  var valid_602459 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602459 = validateParameter(valid_602459, JString, required = false,
                                 default = nil)
  if valid_602459 != nil:
    section.add "X-Amz-Content-Sha256", valid_602459
  var valid_602460 = header.getOrDefault("X-Amz-Algorithm")
  valid_602460 = validateParameter(valid_602460, JString, required = false,
                                 default = nil)
  if valid_602460 != nil:
    section.add "X-Amz-Algorithm", valid_602460
  var valid_602461 = header.getOrDefault("X-Amz-Signature")
  valid_602461 = validateParameter(valid_602461, JString, required = false,
                                 default = nil)
  if valid_602461 != nil:
    section.add "X-Amz-Signature", valid_602461
  var valid_602462 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602462 = validateParameter(valid_602462, JString, required = false,
                                 default = nil)
  if valid_602462 != nil:
    section.add "X-Amz-SignedHeaders", valid_602462
  var valid_602463 = header.getOrDefault("X-Amz-Credential")
  valid_602463 = validateParameter(valid_602463, JString, required = false,
                                 default = nil)
  if valid_602463 != nil:
    section.add "X-Amz-Credential", valid_602463
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_602464 = formData.getOrDefault("NumberOfLines")
  valid_602464 = validateParameter(valid_602464, JInt, required = false, default = nil)
  if valid_602464 != nil:
    section.add "NumberOfLines", valid_602464
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602465 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602465 = validateParameter(valid_602465, JString, required = true,
                                 default = nil)
  if valid_602465 != nil:
    section.add "DBInstanceIdentifier", valid_602465
  var valid_602466 = formData.getOrDefault("Marker")
  valid_602466 = validateParameter(valid_602466, JString, required = false,
                                 default = nil)
  if valid_602466 != nil:
    section.add "Marker", valid_602466
  var valid_602467 = formData.getOrDefault("LogFileName")
  valid_602467 = validateParameter(valid_602467, JString, required = true,
                                 default = nil)
  if valid_602467 != nil:
    section.add "LogFileName", valid_602467
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602468: Call_PostDownloadDBLogFilePortion_602452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602468.validator(path, query, header, formData, body)
  let scheme = call_602468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602468.url(scheme.get, call_602468.host, call_602468.base,
                         call_602468.route, valid.getOrDefault("path"))
  result = hook(call_602468, url, valid)

proc call*(call_602469: Call_PostDownloadDBLogFilePortion_602452;
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
  var query_602470 = newJObject()
  var formData_602471 = newJObject()
  add(formData_602471, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_602471, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602471, "Marker", newJString(Marker))
  add(query_602470, "Action", newJString(Action))
  add(formData_602471, "LogFileName", newJString(LogFileName))
  add(query_602470, "Version", newJString(Version))
  result = call_602469.call(nil, query_602470, nil, formData_602471, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_602452(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_602453, base: "/",
    url: url_PostDownloadDBLogFilePortion_602454,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_602433 = ref object of OpenApiRestCall_600410
proc url_GetDownloadDBLogFilePortion_602435(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_602434(path: JsonNode; query: JsonNode;
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
  var valid_602436 = query.getOrDefault("NumberOfLines")
  valid_602436 = validateParameter(valid_602436, JInt, required = false, default = nil)
  if valid_602436 != nil:
    section.add "NumberOfLines", valid_602436
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_602437 = query.getOrDefault("LogFileName")
  valid_602437 = validateParameter(valid_602437, JString, required = true,
                                 default = nil)
  if valid_602437 != nil:
    section.add "LogFileName", valid_602437
  var valid_602438 = query.getOrDefault("Action")
  valid_602438 = validateParameter(valid_602438, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_602438 != nil:
    section.add "Action", valid_602438
  var valid_602439 = query.getOrDefault("Marker")
  valid_602439 = validateParameter(valid_602439, JString, required = false,
                                 default = nil)
  if valid_602439 != nil:
    section.add "Marker", valid_602439
  var valid_602440 = query.getOrDefault("Version")
  valid_602440 = validateParameter(valid_602440, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602440 != nil:
    section.add "Version", valid_602440
  var valid_602441 = query.getOrDefault("DBInstanceIdentifier")
  valid_602441 = validateParameter(valid_602441, JString, required = true,
                                 default = nil)
  if valid_602441 != nil:
    section.add "DBInstanceIdentifier", valid_602441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602442 = header.getOrDefault("X-Amz-Date")
  valid_602442 = validateParameter(valid_602442, JString, required = false,
                                 default = nil)
  if valid_602442 != nil:
    section.add "X-Amz-Date", valid_602442
  var valid_602443 = header.getOrDefault("X-Amz-Security-Token")
  valid_602443 = validateParameter(valid_602443, JString, required = false,
                                 default = nil)
  if valid_602443 != nil:
    section.add "X-Amz-Security-Token", valid_602443
  var valid_602444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602444 = validateParameter(valid_602444, JString, required = false,
                                 default = nil)
  if valid_602444 != nil:
    section.add "X-Amz-Content-Sha256", valid_602444
  var valid_602445 = header.getOrDefault("X-Amz-Algorithm")
  valid_602445 = validateParameter(valid_602445, JString, required = false,
                                 default = nil)
  if valid_602445 != nil:
    section.add "X-Amz-Algorithm", valid_602445
  var valid_602446 = header.getOrDefault("X-Amz-Signature")
  valid_602446 = validateParameter(valid_602446, JString, required = false,
                                 default = nil)
  if valid_602446 != nil:
    section.add "X-Amz-Signature", valid_602446
  var valid_602447 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602447 = validateParameter(valid_602447, JString, required = false,
                                 default = nil)
  if valid_602447 != nil:
    section.add "X-Amz-SignedHeaders", valid_602447
  var valid_602448 = header.getOrDefault("X-Amz-Credential")
  valid_602448 = validateParameter(valid_602448, JString, required = false,
                                 default = nil)
  if valid_602448 != nil:
    section.add "X-Amz-Credential", valid_602448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602449: Call_GetDownloadDBLogFilePortion_602433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602449.validator(path, query, header, formData, body)
  let scheme = call_602449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602449.url(scheme.get, call_602449.host, call_602449.base,
                         call_602449.route, valid.getOrDefault("path"))
  result = hook(call_602449, url, valid)

proc call*(call_602450: Call_GetDownloadDBLogFilePortion_602433;
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
  var query_602451 = newJObject()
  add(query_602451, "NumberOfLines", newJInt(NumberOfLines))
  add(query_602451, "LogFileName", newJString(LogFileName))
  add(query_602451, "Action", newJString(Action))
  add(query_602451, "Marker", newJString(Marker))
  add(query_602451, "Version", newJString(Version))
  add(query_602451, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602450.call(nil, query_602451, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_602433(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_602434, base: "/",
    url: url_GetDownloadDBLogFilePortion_602435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_602488 = ref object of OpenApiRestCall_600410
proc url_PostListTagsForResource_602490(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_602489(path: JsonNode; query: JsonNode;
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
  var valid_602491 = query.getOrDefault("Action")
  valid_602491 = validateParameter(valid_602491, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602491 != nil:
    section.add "Action", valid_602491
  var valid_602492 = query.getOrDefault("Version")
  valid_602492 = validateParameter(valid_602492, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602492 != nil:
    section.add "Version", valid_602492
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602493 = header.getOrDefault("X-Amz-Date")
  valid_602493 = validateParameter(valid_602493, JString, required = false,
                                 default = nil)
  if valid_602493 != nil:
    section.add "X-Amz-Date", valid_602493
  var valid_602494 = header.getOrDefault("X-Amz-Security-Token")
  valid_602494 = validateParameter(valid_602494, JString, required = false,
                                 default = nil)
  if valid_602494 != nil:
    section.add "X-Amz-Security-Token", valid_602494
  var valid_602495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602495 = validateParameter(valid_602495, JString, required = false,
                                 default = nil)
  if valid_602495 != nil:
    section.add "X-Amz-Content-Sha256", valid_602495
  var valid_602496 = header.getOrDefault("X-Amz-Algorithm")
  valid_602496 = validateParameter(valid_602496, JString, required = false,
                                 default = nil)
  if valid_602496 != nil:
    section.add "X-Amz-Algorithm", valid_602496
  var valid_602497 = header.getOrDefault("X-Amz-Signature")
  valid_602497 = validateParameter(valid_602497, JString, required = false,
                                 default = nil)
  if valid_602497 != nil:
    section.add "X-Amz-Signature", valid_602497
  var valid_602498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602498 = validateParameter(valid_602498, JString, required = false,
                                 default = nil)
  if valid_602498 != nil:
    section.add "X-Amz-SignedHeaders", valid_602498
  var valid_602499 = header.getOrDefault("X-Amz-Credential")
  valid_602499 = validateParameter(valid_602499, JString, required = false,
                                 default = nil)
  if valid_602499 != nil:
    section.add "X-Amz-Credential", valid_602499
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_602500 = formData.getOrDefault("ResourceName")
  valid_602500 = validateParameter(valid_602500, JString, required = true,
                                 default = nil)
  if valid_602500 != nil:
    section.add "ResourceName", valid_602500
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602501: Call_PostListTagsForResource_602488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602501.validator(path, query, header, formData, body)
  let scheme = call_602501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602501.url(scheme.get, call_602501.host, call_602501.base,
                         call_602501.route, valid.getOrDefault("path"))
  result = hook(call_602501, url, valid)

proc call*(call_602502: Call_PostListTagsForResource_602488; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602503 = newJObject()
  var formData_602504 = newJObject()
  add(query_602503, "Action", newJString(Action))
  add(formData_602504, "ResourceName", newJString(ResourceName))
  add(query_602503, "Version", newJString(Version))
  result = call_602502.call(nil, query_602503, nil, formData_602504, nil)

var postListTagsForResource* = Call_PostListTagsForResource_602488(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_602489, base: "/",
    url: url_PostListTagsForResource_602490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_602472 = ref object of OpenApiRestCall_600410
proc url_GetListTagsForResource_602474(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_602473(path: JsonNode; query: JsonNode;
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
  var valid_602475 = query.getOrDefault("ResourceName")
  valid_602475 = validateParameter(valid_602475, JString, required = true,
                                 default = nil)
  if valid_602475 != nil:
    section.add "ResourceName", valid_602475
  var valid_602476 = query.getOrDefault("Action")
  valid_602476 = validateParameter(valid_602476, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_602476 != nil:
    section.add "Action", valid_602476
  var valid_602477 = query.getOrDefault("Version")
  valid_602477 = validateParameter(valid_602477, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602477 != nil:
    section.add "Version", valid_602477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602478 = header.getOrDefault("X-Amz-Date")
  valid_602478 = validateParameter(valid_602478, JString, required = false,
                                 default = nil)
  if valid_602478 != nil:
    section.add "X-Amz-Date", valid_602478
  var valid_602479 = header.getOrDefault("X-Amz-Security-Token")
  valid_602479 = validateParameter(valid_602479, JString, required = false,
                                 default = nil)
  if valid_602479 != nil:
    section.add "X-Amz-Security-Token", valid_602479
  var valid_602480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602480 = validateParameter(valid_602480, JString, required = false,
                                 default = nil)
  if valid_602480 != nil:
    section.add "X-Amz-Content-Sha256", valid_602480
  var valid_602481 = header.getOrDefault("X-Amz-Algorithm")
  valid_602481 = validateParameter(valid_602481, JString, required = false,
                                 default = nil)
  if valid_602481 != nil:
    section.add "X-Amz-Algorithm", valid_602481
  var valid_602482 = header.getOrDefault("X-Amz-Signature")
  valid_602482 = validateParameter(valid_602482, JString, required = false,
                                 default = nil)
  if valid_602482 != nil:
    section.add "X-Amz-Signature", valid_602482
  var valid_602483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602483 = validateParameter(valid_602483, JString, required = false,
                                 default = nil)
  if valid_602483 != nil:
    section.add "X-Amz-SignedHeaders", valid_602483
  var valid_602484 = header.getOrDefault("X-Amz-Credential")
  valid_602484 = validateParameter(valid_602484, JString, required = false,
                                 default = nil)
  if valid_602484 != nil:
    section.add "X-Amz-Credential", valid_602484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602485: Call_GetListTagsForResource_602472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602485.validator(path, query, header, formData, body)
  let scheme = call_602485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602485.url(scheme.get, call_602485.host, call_602485.base,
                         call_602485.route, valid.getOrDefault("path"))
  result = hook(call_602485, url, valid)

proc call*(call_602486: Call_GetListTagsForResource_602472; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602487 = newJObject()
  add(query_602487, "ResourceName", newJString(ResourceName))
  add(query_602487, "Action", newJString(Action))
  add(query_602487, "Version", newJString(Version))
  result = call_602486.call(nil, query_602487, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_602472(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_602473, base: "/",
    url: url_GetListTagsForResource_602474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_602538 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBInstance_602540(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_602539(path: JsonNode; query: JsonNode;
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
  var valid_602541 = query.getOrDefault("Action")
  valid_602541 = validateParameter(valid_602541, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602541 != nil:
    section.add "Action", valid_602541
  var valid_602542 = query.getOrDefault("Version")
  valid_602542 = validateParameter(valid_602542, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602542 != nil:
    section.add "Version", valid_602542
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602543 = header.getOrDefault("X-Amz-Date")
  valid_602543 = validateParameter(valid_602543, JString, required = false,
                                 default = nil)
  if valid_602543 != nil:
    section.add "X-Amz-Date", valid_602543
  var valid_602544 = header.getOrDefault("X-Amz-Security-Token")
  valid_602544 = validateParameter(valid_602544, JString, required = false,
                                 default = nil)
  if valid_602544 != nil:
    section.add "X-Amz-Security-Token", valid_602544
  var valid_602545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602545 = validateParameter(valid_602545, JString, required = false,
                                 default = nil)
  if valid_602545 != nil:
    section.add "X-Amz-Content-Sha256", valid_602545
  var valid_602546 = header.getOrDefault("X-Amz-Algorithm")
  valid_602546 = validateParameter(valid_602546, JString, required = false,
                                 default = nil)
  if valid_602546 != nil:
    section.add "X-Amz-Algorithm", valid_602546
  var valid_602547 = header.getOrDefault("X-Amz-Signature")
  valid_602547 = validateParameter(valid_602547, JString, required = false,
                                 default = nil)
  if valid_602547 != nil:
    section.add "X-Amz-Signature", valid_602547
  var valid_602548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602548 = validateParameter(valid_602548, JString, required = false,
                                 default = nil)
  if valid_602548 != nil:
    section.add "X-Amz-SignedHeaders", valid_602548
  var valid_602549 = header.getOrDefault("X-Amz-Credential")
  valid_602549 = validateParameter(valid_602549, JString, required = false,
                                 default = nil)
  if valid_602549 != nil:
    section.add "X-Amz-Credential", valid_602549
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
  var valid_602550 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_602550 = validateParameter(valid_602550, JString, required = false,
                                 default = nil)
  if valid_602550 != nil:
    section.add "PreferredMaintenanceWindow", valid_602550
  var valid_602551 = formData.getOrDefault("DBSecurityGroups")
  valid_602551 = validateParameter(valid_602551, JArray, required = false,
                                 default = nil)
  if valid_602551 != nil:
    section.add "DBSecurityGroups", valid_602551
  var valid_602552 = formData.getOrDefault("ApplyImmediately")
  valid_602552 = validateParameter(valid_602552, JBool, required = false, default = nil)
  if valid_602552 != nil:
    section.add "ApplyImmediately", valid_602552
  var valid_602553 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_602553 = validateParameter(valid_602553, JArray, required = false,
                                 default = nil)
  if valid_602553 != nil:
    section.add "VpcSecurityGroupIds", valid_602553
  var valid_602554 = formData.getOrDefault("Iops")
  valid_602554 = validateParameter(valid_602554, JInt, required = false, default = nil)
  if valid_602554 != nil:
    section.add "Iops", valid_602554
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602555 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602555 = validateParameter(valid_602555, JString, required = true,
                                 default = nil)
  if valid_602555 != nil:
    section.add "DBInstanceIdentifier", valid_602555
  var valid_602556 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602556 = validateParameter(valid_602556, JInt, required = false, default = nil)
  if valid_602556 != nil:
    section.add "BackupRetentionPeriod", valid_602556
  var valid_602557 = formData.getOrDefault("DBParameterGroupName")
  valid_602557 = validateParameter(valid_602557, JString, required = false,
                                 default = nil)
  if valid_602557 != nil:
    section.add "DBParameterGroupName", valid_602557
  var valid_602558 = formData.getOrDefault("OptionGroupName")
  valid_602558 = validateParameter(valid_602558, JString, required = false,
                                 default = nil)
  if valid_602558 != nil:
    section.add "OptionGroupName", valid_602558
  var valid_602559 = formData.getOrDefault("MasterUserPassword")
  valid_602559 = validateParameter(valid_602559, JString, required = false,
                                 default = nil)
  if valid_602559 != nil:
    section.add "MasterUserPassword", valid_602559
  var valid_602560 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_602560 = validateParameter(valid_602560, JString, required = false,
                                 default = nil)
  if valid_602560 != nil:
    section.add "NewDBInstanceIdentifier", valid_602560
  var valid_602561 = formData.getOrDefault("MultiAZ")
  valid_602561 = validateParameter(valid_602561, JBool, required = false, default = nil)
  if valid_602561 != nil:
    section.add "MultiAZ", valid_602561
  var valid_602562 = formData.getOrDefault("AllocatedStorage")
  valid_602562 = validateParameter(valid_602562, JInt, required = false, default = nil)
  if valid_602562 != nil:
    section.add "AllocatedStorage", valid_602562
  var valid_602563 = formData.getOrDefault("DBInstanceClass")
  valid_602563 = validateParameter(valid_602563, JString, required = false,
                                 default = nil)
  if valid_602563 != nil:
    section.add "DBInstanceClass", valid_602563
  var valid_602564 = formData.getOrDefault("PreferredBackupWindow")
  valid_602564 = validateParameter(valid_602564, JString, required = false,
                                 default = nil)
  if valid_602564 != nil:
    section.add "PreferredBackupWindow", valid_602564
  var valid_602565 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602565 = validateParameter(valid_602565, JBool, required = false, default = nil)
  if valid_602565 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602565
  var valid_602566 = formData.getOrDefault("EngineVersion")
  valid_602566 = validateParameter(valid_602566, JString, required = false,
                                 default = nil)
  if valid_602566 != nil:
    section.add "EngineVersion", valid_602566
  var valid_602567 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_602567 = validateParameter(valid_602567, JBool, required = false, default = nil)
  if valid_602567 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602567
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602568: Call_PostModifyDBInstance_602538; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602568.validator(path, query, header, formData, body)
  let scheme = call_602568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602568.url(scheme.get, call_602568.host, call_602568.base,
                         call_602568.route, valid.getOrDefault("path"))
  result = hook(call_602568, url, valid)

proc call*(call_602569: Call_PostModifyDBInstance_602538;
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
  var query_602570 = newJObject()
  var formData_602571 = newJObject()
  add(formData_602571, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_602571.add "DBSecurityGroups", DBSecurityGroups
  add(formData_602571, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_602571.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_602571, "Iops", newJInt(Iops))
  add(formData_602571, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602571, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_602571, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_602571, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602571, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_602571, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_602571, "MultiAZ", newJBool(MultiAZ))
  add(query_602570, "Action", newJString(Action))
  add(formData_602571, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_602571, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602571, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_602571, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_602571, "EngineVersion", newJString(EngineVersion))
  add(query_602570, "Version", newJString(Version))
  add(formData_602571, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_602569.call(nil, query_602570, nil, formData_602571, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_602538(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_602539, base: "/",
    url: url_PostModifyDBInstance_602540, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_602505 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBInstance_602507(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_602506(path: JsonNode; query: JsonNode;
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
  var valid_602508 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_602508 = validateParameter(valid_602508, JString, required = false,
                                 default = nil)
  if valid_602508 != nil:
    section.add "PreferredMaintenanceWindow", valid_602508
  var valid_602509 = query.getOrDefault("AllocatedStorage")
  valid_602509 = validateParameter(valid_602509, JInt, required = false, default = nil)
  if valid_602509 != nil:
    section.add "AllocatedStorage", valid_602509
  var valid_602510 = query.getOrDefault("OptionGroupName")
  valid_602510 = validateParameter(valid_602510, JString, required = false,
                                 default = nil)
  if valid_602510 != nil:
    section.add "OptionGroupName", valid_602510
  var valid_602511 = query.getOrDefault("DBSecurityGroups")
  valid_602511 = validateParameter(valid_602511, JArray, required = false,
                                 default = nil)
  if valid_602511 != nil:
    section.add "DBSecurityGroups", valid_602511
  var valid_602512 = query.getOrDefault("MasterUserPassword")
  valid_602512 = validateParameter(valid_602512, JString, required = false,
                                 default = nil)
  if valid_602512 != nil:
    section.add "MasterUserPassword", valid_602512
  var valid_602513 = query.getOrDefault("Iops")
  valid_602513 = validateParameter(valid_602513, JInt, required = false, default = nil)
  if valid_602513 != nil:
    section.add "Iops", valid_602513
  var valid_602514 = query.getOrDefault("VpcSecurityGroupIds")
  valid_602514 = validateParameter(valid_602514, JArray, required = false,
                                 default = nil)
  if valid_602514 != nil:
    section.add "VpcSecurityGroupIds", valid_602514
  var valid_602515 = query.getOrDefault("MultiAZ")
  valid_602515 = validateParameter(valid_602515, JBool, required = false, default = nil)
  if valid_602515 != nil:
    section.add "MultiAZ", valid_602515
  var valid_602516 = query.getOrDefault("BackupRetentionPeriod")
  valid_602516 = validateParameter(valid_602516, JInt, required = false, default = nil)
  if valid_602516 != nil:
    section.add "BackupRetentionPeriod", valid_602516
  var valid_602517 = query.getOrDefault("DBParameterGroupName")
  valid_602517 = validateParameter(valid_602517, JString, required = false,
                                 default = nil)
  if valid_602517 != nil:
    section.add "DBParameterGroupName", valid_602517
  var valid_602518 = query.getOrDefault("DBInstanceClass")
  valid_602518 = validateParameter(valid_602518, JString, required = false,
                                 default = nil)
  if valid_602518 != nil:
    section.add "DBInstanceClass", valid_602518
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602519 = query.getOrDefault("Action")
  valid_602519 = validateParameter(valid_602519, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_602519 != nil:
    section.add "Action", valid_602519
  var valid_602520 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_602520 = validateParameter(valid_602520, JBool, required = false, default = nil)
  if valid_602520 != nil:
    section.add "AllowMajorVersionUpgrade", valid_602520
  var valid_602521 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_602521 = validateParameter(valid_602521, JString, required = false,
                                 default = nil)
  if valid_602521 != nil:
    section.add "NewDBInstanceIdentifier", valid_602521
  var valid_602522 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602522 = validateParameter(valid_602522, JBool, required = false, default = nil)
  if valid_602522 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602522
  var valid_602523 = query.getOrDefault("EngineVersion")
  valid_602523 = validateParameter(valid_602523, JString, required = false,
                                 default = nil)
  if valid_602523 != nil:
    section.add "EngineVersion", valid_602523
  var valid_602524 = query.getOrDefault("PreferredBackupWindow")
  valid_602524 = validateParameter(valid_602524, JString, required = false,
                                 default = nil)
  if valid_602524 != nil:
    section.add "PreferredBackupWindow", valid_602524
  var valid_602525 = query.getOrDefault("Version")
  valid_602525 = validateParameter(valid_602525, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602525 != nil:
    section.add "Version", valid_602525
  var valid_602526 = query.getOrDefault("DBInstanceIdentifier")
  valid_602526 = validateParameter(valid_602526, JString, required = true,
                                 default = nil)
  if valid_602526 != nil:
    section.add "DBInstanceIdentifier", valid_602526
  var valid_602527 = query.getOrDefault("ApplyImmediately")
  valid_602527 = validateParameter(valid_602527, JBool, required = false, default = nil)
  if valid_602527 != nil:
    section.add "ApplyImmediately", valid_602527
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602528 = header.getOrDefault("X-Amz-Date")
  valid_602528 = validateParameter(valid_602528, JString, required = false,
                                 default = nil)
  if valid_602528 != nil:
    section.add "X-Amz-Date", valid_602528
  var valid_602529 = header.getOrDefault("X-Amz-Security-Token")
  valid_602529 = validateParameter(valid_602529, JString, required = false,
                                 default = nil)
  if valid_602529 != nil:
    section.add "X-Amz-Security-Token", valid_602529
  var valid_602530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602530 = validateParameter(valid_602530, JString, required = false,
                                 default = nil)
  if valid_602530 != nil:
    section.add "X-Amz-Content-Sha256", valid_602530
  var valid_602531 = header.getOrDefault("X-Amz-Algorithm")
  valid_602531 = validateParameter(valid_602531, JString, required = false,
                                 default = nil)
  if valid_602531 != nil:
    section.add "X-Amz-Algorithm", valid_602531
  var valid_602532 = header.getOrDefault("X-Amz-Signature")
  valid_602532 = validateParameter(valid_602532, JString, required = false,
                                 default = nil)
  if valid_602532 != nil:
    section.add "X-Amz-Signature", valid_602532
  var valid_602533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602533 = validateParameter(valid_602533, JString, required = false,
                                 default = nil)
  if valid_602533 != nil:
    section.add "X-Amz-SignedHeaders", valid_602533
  var valid_602534 = header.getOrDefault("X-Amz-Credential")
  valid_602534 = validateParameter(valid_602534, JString, required = false,
                                 default = nil)
  if valid_602534 != nil:
    section.add "X-Amz-Credential", valid_602534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602535: Call_GetModifyDBInstance_602505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602535.validator(path, query, header, formData, body)
  let scheme = call_602535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602535.url(scheme.get, call_602535.host, call_602535.base,
                         call_602535.route, valid.getOrDefault("path"))
  result = hook(call_602535, url, valid)

proc call*(call_602536: Call_GetModifyDBInstance_602505;
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
  var query_602537 = newJObject()
  add(query_602537, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_602537, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_602537, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_602537.add "DBSecurityGroups", DBSecurityGroups
  add(query_602537, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_602537, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_602537.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_602537, "MultiAZ", newJBool(MultiAZ))
  add(query_602537, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602537, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_602537, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602537, "Action", newJString(Action))
  add(query_602537, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_602537, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_602537, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602537, "EngineVersion", newJString(EngineVersion))
  add(query_602537, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602537, "Version", newJString(Version))
  add(query_602537, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602537, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_602536.call(nil, query_602537, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_602505(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_602506, base: "/",
    url: url_GetModifyDBInstance_602507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_602589 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBParameterGroup_602591(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_602590(path: JsonNode; query: JsonNode;
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
  var valid_602592 = query.getOrDefault("Action")
  valid_602592 = validateParameter(valid_602592, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602592 != nil:
    section.add "Action", valid_602592
  var valid_602593 = query.getOrDefault("Version")
  valid_602593 = validateParameter(valid_602593, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602593 != nil:
    section.add "Version", valid_602593
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602594 = header.getOrDefault("X-Amz-Date")
  valid_602594 = validateParameter(valid_602594, JString, required = false,
                                 default = nil)
  if valid_602594 != nil:
    section.add "X-Amz-Date", valid_602594
  var valid_602595 = header.getOrDefault("X-Amz-Security-Token")
  valid_602595 = validateParameter(valid_602595, JString, required = false,
                                 default = nil)
  if valid_602595 != nil:
    section.add "X-Amz-Security-Token", valid_602595
  var valid_602596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602596 = validateParameter(valid_602596, JString, required = false,
                                 default = nil)
  if valid_602596 != nil:
    section.add "X-Amz-Content-Sha256", valid_602596
  var valid_602597 = header.getOrDefault("X-Amz-Algorithm")
  valid_602597 = validateParameter(valid_602597, JString, required = false,
                                 default = nil)
  if valid_602597 != nil:
    section.add "X-Amz-Algorithm", valid_602597
  var valid_602598 = header.getOrDefault("X-Amz-Signature")
  valid_602598 = validateParameter(valid_602598, JString, required = false,
                                 default = nil)
  if valid_602598 != nil:
    section.add "X-Amz-Signature", valid_602598
  var valid_602599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602599 = validateParameter(valid_602599, JString, required = false,
                                 default = nil)
  if valid_602599 != nil:
    section.add "X-Amz-SignedHeaders", valid_602599
  var valid_602600 = header.getOrDefault("X-Amz-Credential")
  valid_602600 = validateParameter(valid_602600, JString, required = false,
                                 default = nil)
  if valid_602600 != nil:
    section.add "X-Amz-Credential", valid_602600
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602601 = formData.getOrDefault("DBParameterGroupName")
  valid_602601 = validateParameter(valid_602601, JString, required = true,
                                 default = nil)
  if valid_602601 != nil:
    section.add "DBParameterGroupName", valid_602601
  var valid_602602 = formData.getOrDefault("Parameters")
  valid_602602 = validateParameter(valid_602602, JArray, required = true, default = nil)
  if valid_602602 != nil:
    section.add "Parameters", valid_602602
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602603: Call_PostModifyDBParameterGroup_602589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602603.validator(path, query, header, formData, body)
  let scheme = call_602603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602603.url(scheme.get, call_602603.host, call_602603.base,
                         call_602603.route, valid.getOrDefault("path"))
  result = hook(call_602603, url, valid)

proc call*(call_602604: Call_PostModifyDBParameterGroup_602589;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602605 = newJObject()
  var formData_602606 = newJObject()
  add(formData_602606, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602606.add "Parameters", Parameters
  add(query_602605, "Action", newJString(Action))
  add(query_602605, "Version", newJString(Version))
  result = call_602604.call(nil, query_602605, nil, formData_602606, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_602589(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_602590, base: "/",
    url: url_PostModifyDBParameterGroup_602591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_602572 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBParameterGroup_602574(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_602573(path: JsonNode; query: JsonNode;
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
  var valid_602575 = query.getOrDefault("DBParameterGroupName")
  valid_602575 = validateParameter(valid_602575, JString, required = true,
                                 default = nil)
  if valid_602575 != nil:
    section.add "DBParameterGroupName", valid_602575
  var valid_602576 = query.getOrDefault("Parameters")
  valid_602576 = validateParameter(valid_602576, JArray, required = true, default = nil)
  if valid_602576 != nil:
    section.add "Parameters", valid_602576
  var valid_602577 = query.getOrDefault("Action")
  valid_602577 = validateParameter(valid_602577, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_602577 != nil:
    section.add "Action", valid_602577
  var valid_602578 = query.getOrDefault("Version")
  valid_602578 = validateParameter(valid_602578, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602578 != nil:
    section.add "Version", valid_602578
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602579 = header.getOrDefault("X-Amz-Date")
  valid_602579 = validateParameter(valid_602579, JString, required = false,
                                 default = nil)
  if valid_602579 != nil:
    section.add "X-Amz-Date", valid_602579
  var valid_602580 = header.getOrDefault("X-Amz-Security-Token")
  valid_602580 = validateParameter(valid_602580, JString, required = false,
                                 default = nil)
  if valid_602580 != nil:
    section.add "X-Amz-Security-Token", valid_602580
  var valid_602581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602581 = validateParameter(valid_602581, JString, required = false,
                                 default = nil)
  if valid_602581 != nil:
    section.add "X-Amz-Content-Sha256", valid_602581
  var valid_602582 = header.getOrDefault("X-Amz-Algorithm")
  valid_602582 = validateParameter(valid_602582, JString, required = false,
                                 default = nil)
  if valid_602582 != nil:
    section.add "X-Amz-Algorithm", valid_602582
  var valid_602583 = header.getOrDefault("X-Amz-Signature")
  valid_602583 = validateParameter(valid_602583, JString, required = false,
                                 default = nil)
  if valid_602583 != nil:
    section.add "X-Amz-Signature", valid_602583
  var valid_602584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602584 = validateParameter(valid_602584, JString, required = false,
                                 default = nil)
  if valid_602584 != nil:
    section.add "X-Amz-SignedHeaders", valid_602584
  var valid_602585 = header.getOrDefault("X-Amz-Credential")
  valid_602585 = validateParameter(valid_602585, JString, required = false,
                                 default = nil)
  if valid_602585 != nil:
    section.add "X-Amz-Credential", valid_602585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602586: Call_GetModifyDBParameterGroup_602572; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602586.validator(path, query, header, formData, body)
  let scheme = call_602586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602586.url(scheme.get, call_602586.host, call_602586.base,
                         call_602586.route, valid.getOrDefault("path"))
  result = hook(call_602586, url, valid)

proc call*(call_602587: Call_GetModifyDBParameterGroup_602572;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602588 = newJObject()
  add(query_602588, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602588.add "Parameters", Parameters
  add(query_602588, "Action", newJString(Action))
  add(query_602588, "Version", newJString(Version))
  result = call_602587.call(nil, query_602588, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_602572(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_602573, base: "/",
    url: url_GetModifyDBParameterGroup_602574,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_602625 = ref object of OpenApiRestCall_600410
proc url_PostModifyDBSubnetGroup_602627(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_602626(path: JsonNode; query: JsonNode;
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
  var valid_602628 = query.getOrDefault("Action")
  valid_602628 = validateParameter(valid_602628, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602628 != nil:
    section.add "Action", valid_602628
  var valid_602629 = query.getOrDefault("Version")
  valid_602629 = validateParameter(valid_602629, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602629 != nil:
    section.add "Version", valid_602629
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602630 = header.getOrDefault("X-Amz-Date")
  valid_602630 = validateParameter(valid_602630, JString, required = false,
                                 default = nil)
  if valid_602630 != nil:
    section.add "X-Amz-Date", valid_602630
  var valid_602631 = header.getOrDefault("X-Amz-Security-Token")
  valid_602631 = validateParameter(valid_602631, JString, required = false,
                                 default = nil)
  if valid_602631 != nil:
    section.add "X-Amz-Security-Token", valid_602631
  var valid_602632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602632 = validateParameter(valid_602632, JString, required = false,
                                 default = nil)
  if valid_602632 != nil:
    section.add "X-Amz-Content-Sha256", valid_602632
  var valid_602633 = header.getOrDefault("X-Amz-Algorithm")
  valid_602633 = validateParameter(valid_602633, JString, required = false,
                                 default = nil)
  if valid_602633 != nil:
    section.add "X-Amz-Algorithm", valid_602633
  var valid_602634 = header.getOrDefault("X-Amz-Signature")
  valid_602634 = validateParameter(valid_602634, JString, required = false,
                                 default = nil)
  if valid_602634 != nil:
    section.add "X-Amz-Signature", valid_602634
  var valid_602635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602635 = validateParameter(valid_602635, JString, required = false,
                                 default = nil)
  if valid_602635 != nil:
    section.add "X-Amz-SignedHeaders", valid_602635
  var valid_602636 = header.getOrDefault("X-Amz-Credential")
  valid_602636 = validateParameter(valid_602636, JString, required = false,
                                 default = nil)
  if valid_602636 != nil:
    section.add "X-Amz-Credential", valid_602636
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_602637 = formData.getOrDefault("DBSubnetGroupName")
  valid_602637 = validateParameter(valid_602637, JString, required = true,
                                 default = nil)
  if valid_602637 != nil:
    section.add "DBSubnetGroupName", valid_602637
  var valid_602638 = formData.getOrDefault("SubnetIds")
  valid_602638 = validateParameter(valid_602638, JArray, required = true, default = nil)
  if valid_602638 != nil:
    section.add "SubnetIds", valid_602638
  var valid_602639 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_602639 = validateParameter(valid_602639, JString, required = false,
                                 default = nil)
  if valid_602639 != nil:
    section.add "DBSubnetGroupDescription", valid_602639
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602640: Call_PostModifyDBSubnetGroup_602625; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602640.validator(path, query, header, formData, body)
  let scheme = call_602640.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602640.url(scheme.get, call_602640.host, call_602640.base,
                         call_602640.route, valid.getOrDefault("path"))
  result = hook(call_602640, url, valid)

proc call*(call_602641: Call_PostModifyDBSubnetGroup_602625;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602642 = newJObject()
  var formData_602643 = newJObject()
  add(formData_602643, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_602643.add "SubnetIds", SubnetIds
  add(query_602642, "Action", newJString(Action))
  add(formData_602643, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602642, "Version", newJString(Version))
  result = call_602641.call(nil, query_602642, nil, formData_602643, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_602625(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_602626, base: "/",
    url: url_PostModifyDBSubnetGroup_602627, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_602607 = ref object of OpenApiRestCall_600410
proc url_GetModifyDBSubnetGroup_602609(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_602608(path: JsonNode; query: JsonNode;
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
  var valid_602610 = query.getOrDefault("Action")
  valid_602610 = validateParameter(valid_602610, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_602610 != nil:
    section.add "Action", valid_602610
  var valid_602611 = query.getOrDefault("DBSubnetGroupName")
  valid_602611 = validateParameter(valid_602611, JString, required = true,
                                 default = nil)
  if valid_602611 != nil:
    section.add "DBSubnetGroupName", valid_602611
  var valid_602612 = query.getOrDefault("SubnetIds")
  valid_602612 = validateParameter(valid_602612, JArray, required = true, default = nil)
  if valid_602612 != nil:
    section.add "SubnetIds", valid_602612
  var valid_602613 = query.getOrDefault("DBSubnetGroupDescription")
  valid_602613 = validateParameter(valid_602613, JString, required = false,
                                 default = nil)
  if valid_602613 != nil:
    section.add "DBSubnetGroupDescription", valid_602613
  var valid_602614 = query.getOrDefault("Version")
  valid_602614 = validateParameter(valid_602614, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602614 != nil:
    section.add "Version", valid_602614
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602615 = header.getOrDefault("X-Amz-Date")
  valid_602615 = validateParameter(valid_602615, JString, required = false,
                                 default = nil)
  if valid_602615 != nil:
    section.add "X-Amz-Date", valid_602615
  var valid_602616 = header.getOrDefault("X-Amz-Security-Token")
  valid_602616 = validateParameter(valid_602616, JString, required = false,
                                 default = nil)
  if valid_602616 != nil:
    section.add "X-Amz-Security-Token", valid_602616
  var valid_602617 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602617 = validateParameter(valid_602617, JString, required = false,
                                 default = nil)
  if valid_602617 != nil:
    section.add "X-Amz-Content-Sha256", valid_602617
  var valid_602618 = header.getOrDefault("X-Amz-Algorithm")
  valid_602618 = validateParameter(valid_602618, JString, required = false,
                                 default = nil)
  if valid_602618 != nil:
    section.add "X-Amz-Algorithm", valid_602618
  var valid_602619 = header.getOrDefault("X-Amz-Signature")
  valid_602619 = validateParameter(valid_602619, JString, required = false,
                                 default = nil)
  if valid_602619 != nil:
    section.add "X-Amz-Signature", valid_602619
  var valid_602620 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602620 = validateParameter(valid_602620, JString, required = false,
                                 default = nil)
  if valid_602620 != nil:
    section.add "X-Amz-SignedHeaders", valid_602620
  var valid_602621 = header.getOrDefault("X-Amz-Credential")
  valid_602621 = validateParameter(valid_602621, JString, required = false,
                                 default = nil)
  if valid_602621 != nil:
    section.add "X-Amz-Credential", valid_602621
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602622: Call_GetModifyDBSubnetGroup_602607; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602622.validator(path, query, header, formData, body)
  let scheme = call_602622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602622.url(scheme.get, call_602622.host, call_602622.base,
                         call_602622.route, valid.getOrDefault("path"))
  result = hook(call_602622, url, valid)

proc call*(call_602623: Call_GetModifyDBSubnetGroup_602607;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_602624 = newJObject()
  add(query_602624, "Action", newJString(Action))
  add(query_602624, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_602624.add "SubnetIds", SubnetIds
  add(query_602624, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_602624, "Version", newJString(Version))
  result = call_602623.call(nil, query_602624, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_602607(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_602608, base: "/",
    url: url_GetModifyDBSubnetGroup_602609, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_602664 = ref object of OpenApiRestCall_600410
proc url_PostModifyEventSubscription_602666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_602665(path: JsonNode; query: JsonNode;
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
  var valid_602667 = query.getOrDefault("Action")
  valid_602667 = validateParameter(valid_602667, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602667 != nil:
    section.add "Action", valid_602667
  var valid_602668 = query.getOrDefault("Version")
  valid_602668 = validateParameter(valid_602668, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602668 != nil:
    section.add "Version", valid_602668
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602669 = header.getOrDefault("X-Amz-Date")
  valid_602669 = validateParameter(valid_602669, JString, required = false,
                                 default = nil)
  if valid_602669 != nil:
    section.add "X-Amz-Date", valid_602669
  var valid_602670 = header.getOrDefault("X-Amz-Security-Token")
  valid_602670 = validateParameter(valid_602670, JString, required = false,
                                 default = nil)
  if valid_602670 != nil:
    section.add "X-Amz-Security-Token", valid_602670
  var valid_602671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602671 = validateParameter(valid_602671, JString, required = false,
                                 default = nil)
  if valid_602671 != nil:
    section.add "X-Amz-Content-Sha256", valid_602671
  var valid_602672 = header.getOrDefault("X-Amz-Algorithm")
  valid_602672 = validateParameter(valid_602672, JString, required = false,
                                 default = nil)
  if valid_602672 != nil:
    section.add "X-Amz-Algorithm", valid_602672
  var valid_602673 = header.getOrDefault("X-Amz-Signature")
  valid_602673 = validateParameter(valid_602673, JString, required = false,
                                 default = nil)
  if valid_602673 != nil:
    section.add "X-Amz-Signature", valid_602673
  var valid_602674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602674 = validateParameter(valid_602674, JString, required = false,
                                 default = nil)
  if valid_602674 != nil:
    section.add "X-Amz-SignedHeaders", valid_602674
  var valid_602675 = header.getOrDefault("X-Amz-Credential")
  valid_602675 = validateParameter(valid_602675, JString, required = false,
                                 default = nil)
  if valid_602675 != nil:
    section.add "X-Amz-Credential", valid_602675
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_602676 = formData.getOrDefault("Enabled")
  valid_602676 = validateParameter(valid_602676, JBool, required = false, default = nil)
  if valid_602676 != nil:
    section.add "Enabled", valid_602676
  var valid_602677 = formData.getOrDefault("EventCategories")
  valid_602677 = validateParameter(valid_602677, JArray, required = false,
                                 default = nil)
  if valid_602677 != nil:
    section.add "EventCategories", valid_602677
  var valid_602678 = formData.getOrDefault("SnsTopicArn")
  valid_602678 = validateParameter(valid_602678, JString, required = false,
                                 default = nil)
  if valid_602678 != nil:
    section.add "SnsTopicArn", valid_602678
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_602679 = formData.getOrDefault("SubscriptionName")
  valid_602679 = validateParameter(valid_602679, JString, required = true,
                                 default = nil)
  if valid_602679 != nil:
    section.add "SubscriptionName", valid_602679
  var valid_602680 = formData.getOrDefault("SourceType")
  valid_602680 = validateParameter(valid_602680, JString, required = false,
                                 default = nil)
  if valid_602680 != nil:
    section.add "SourceType", valid_602680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602681: Call_PostModifyEventSubscription_602664; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602681.validator(path, query, header, formData, body)
  let scheme = call_602681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602681.url(scheme.get, call_602681.host, call_602681.base,
                         call_602681.route, valid.getOrDefault("path"))
  result = hook(call_602681, url, valid)

proc call*(call_602682: Call_PostModifyEventSubscription_602664;
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
  var query_602683 = newJObject()
  var formData_602684 = newJObject()
  add(formData_602684, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_602684.add "EventCategories", EventCategories
  add(formData_602684, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_602684, "SubscriptionName", newJString(SubscriptionName))
  add(query_602683, "Action", newJString(Action))
  add(query_602683, "Version", newJString(Version))
  add(formData_602684, "SourceType", newJString(SourceType))
  result = call_602682.call(nil, query_602683, nil, formData_602684, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_602664(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_602665, base: "/",
    url: url_PostModifyEventSubscription_602666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_602644 = ref object of OpenApiRestCall_600410
proc url_GetModifyEventSubscription_602646(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_602645(path: JsonNode; query: JsonNode;
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
  var valid_602647 = query.getOrDefault("SourceType")
  valid_602647 = validateParameter(valid_602647, JString, required = false,
                                 default = nil)
  if valid_602647 != nil:
    section.add "SourceType", valid_602647
  var valid_602648 = query.getOrDefault("Enabled")
  valid_602648 = validateParameter(valid_602648, JBool, required = false, default = nil)
  if valid_602648 != nil:
    section.add "Enabled", valid_602648
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602649 = query.getOrDefault("Action")
  valid_602649 = validateParameter(valid_602649, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_602649 != nil:
    section.add "Action", valid_602649
  var valid_602650 = query.getOrDefault("SnsTopicArn")
  valid_602650 = validateParameter(valid_602650, JString, required = false,
                                 default = nil)
  if valid_602650 != nil:
    section.add "SnsTopicArn", valid_602650
  var valid_602651 = query.getOrDefault("EventCategories")
  valid_602651 = validateParameter(valid_602651, JArray, required = false,
                                 default = nil)
  if valid_602651 != nil:
    section.add "EventCategories", valid_602651
  var valid_602652 = query.getOrDefault("SubscriptionName")
  valid_602652 = validateParameter(valid_602652, JString, required = true,
                                 default = nil)
  if valid_602652 != nil:
    section.add "SubscriptionName", valid_602652
  var valid_602653 = query.getOrDefault("Version")
  valid_602653 = validateParameter(valid_602653, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602653 != nil:
    section.add "Version", valid_602653
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602654 = header.getOrDefault("X-Amz-Date")
  valid_602654 = validateParameter(valid_602654, JString, required = false,
                                 default = nil)
  if valid_602654 != nil:
    section.add "X-Amz-Date", valid_602654
  var valid_602655 = header.getOrDefault("X-Amz-Security-Token")
  valid_602655 = validateParameter(valid_602655, JString, required = false,
                                 default = nil)
  if valid_602655 != nil:
    section.add "X-Amz-Security-Token", valid_602655
  var valid_602656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602656 = validateParameter(valid_602656, JString, required = false,
                                 default = nil)
  if valid_602656 != nil:
    section.add "X-Amz-Content-Sha256", valid_602656
  var valid_602657 = header.getOrDefault("X-Amz-Algorithm")
  valid_602657 = validateParameter(valid_602657, JString, required = false,
                                 default = nil)
  if valid_602657 != nil:
    section.add "X-Amz-Algorithm", valid_602657
  var valid_602658 = header.getOrDefault("X-Amz-Signature")
  valid_602658 = validateParameter(valid_602658, JString, required = false,
                                 default = nil)
  if valid_602658 != nil:
    section.add "X-Amz-Signature", valid_602658
  var valid_602659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602659 = validateParameter(valid_602659, JString, required = false,
                                 default = nil)
  if valid_602659 != nil:
    section.add "X-Amz-SignedHeaders", valid_602659
  var valid_602660 = header.getOrDefault("X-Amz-Credential")
  valid_602660 = validateParameter(valid_602660, JString, required = false,
                                 default = nil)
  if valid_602660 != nil:
    section.add "X-Amz-Credential", valid_602660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602661: Call_GetModifyEventSubscription_602644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602661.validator(path, query, header, formData, body)
  let scheme = call_602661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602661.url(scheme.get, call_602661.host, call_602661.base,
                         call_602661.route, valid.getOrDefault("path"))
  result = hook(call_602661, url, valid)

proc call*(call_602662: Call_GetModifyEventSubscription_602644;
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
  var query_602663 = newJObject()
  add(query_602663, "SourceType", newJString(SourceType))
  add(query_602663, "Enabled", newJBool(Enabled))
  add(query_602663, "Action", newJString(Action))
  add(query_602663, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_602663.add "EventCategories", EventCategories
  add(query_602663, "SubscriptionName", newJString(SubscriptionName))
  add(query_602663, "Version", newJString(Version))
  result = call_602662.call(nil, query_602663, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_602644(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_602645, base: "/",
    url: url_GetModifyEventSubscription_602646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_602704 = ref object of OpenApiRestCall_600410
proc url_PostModifyOptionGroup_602706(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_602705(path: JsonNode; query: JsonNode;
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
  var valid_602707 = query.getOrDefault("Action")
  valid_602707 = validateParameter(valid_602707, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602707 != nil:
    section.add "Action", valid_602707
  var valid_602708 = query.getOrDefault("Version")
  valid_602708 = validateParameter(valid_602708, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602708 != nil:
    section.add "Version", valid_602708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602709 = header.getOrDefault("X-Amz-Date")
  valid_602709 = validateParameter(valid_602709, JString, required = false,
                                 default = nil)
  if valid_602709 != nil:
    section.add "X-Amz-Date", valid_602709
  var valid_602710 = header.getOrDefault("X-Amz-Security-Token")
  valid_602710 = validateParameter(valid_602710, JString, required = false,
                                 default = nil)
  if valid_602710 != nil:
    section.add "X-Amz-Security-Token", valid_602710
  var valid_602711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602711 = validateParameter(valid_602711, JString, required = false,
                                 default = nil)
  if valid_602711 != nil:
    section.add "X-Amz-Content-Sha256", valid_602711
  var valid_602712 = header.getOrDefault("X-Amz-Algorithm")
  valid_602712 = validateParameter(valid_602712, JString, required = false,
                                 default = nil)
  if valid_602712 != nil:
    section.add "X-Amz-Algorithm", valid_602712
  var valid_602713 = header.getOrDefault("X-Amz-Signature")
  valid_602713 = validateParameter(valid_602713, JString, required = false,
                                 default = nil)
  if valid_602713 != nil:
    section.add "X-Amz-Signature", valid_602713
  var valid_602714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602714 = validateParameter(valid_602714, JString, required = false,
                                 default = nil)
  if valid_602714 != nil:
    section.add "X-Amz-SignedHeaders", valid_602714
  var valid_602715 = header.getOrDefault("X-Amz-Credential")
  valid_602715 = validateParameter(valid_602715, JString, required = false,
                                 default = nil)
  if valid_602715 != nil:
    section.add "X-Amz-Credential", valid_602715
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_602716 = formData.getOrDefault("OptionsToRemove")
  valid_602716 = validateParameter(valid_602716, JArray, required = false,
                                 default = nil)
  if valid_602716 != nil:
    section.add "OptionsToRemove", valid_602716
  var valid_602717 = formData.getOrDefault("ApplyImmediately")
  valid_602717 = validateParameter(valid_602717, JBool, required = false, default = nil)
  if valid_602717 != nil:
    section.add "ApplyImmediately", valid_602717
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_602718 = formData.getOrDefault("OptionGroupName")
  valid_602718 = validateParameter(valid_602718, JString, required = true,
                                 default = nil)
  if valid_602718 != nil:
    section.add "OptionGroupName", valid_602718
  var valid_602719 = formData.getOrDefault("OptionsToInclude")
  valid_602719 = validateParameter(valid_602719, JArray, required = false,
                                 default = nil)
  if valid_602719 != nil:
    section.add "OptionsToInclude", valid_602719
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602720: Call_PostModifyOptionGroup_602704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602720.validator(path, query, header, formData, body)
  let scheme = call_602720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602720.url(scheme.get, call_602720.host, call_602720.base,
                         call_602720.route, valid.getOrDefault("path"))
  result = hook(call_602720, url, valid)

proc call*(call_602721: Call_PostModifyOptionGroup_602704; OptionGroupName: string;
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
  var query_602722 = newJObject()
  var formData_602723 = newJObject()
  if OptionsToRemove != nil:
    formData_602723.add "OptionsToRemove", OptionsToRemove
  add(formData_602723, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_602723, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_602723.add "OptionsToInclude", OptionsToInclude
  add(query_602722, "Action", newJString(Action))
  add(query_602722, "Version", newJString(Version))
  result = call_602721.call(nil, query_602722, nil, formData_602723, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_602704(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_602705, base: "/",
    url: url_PostModifyOptionGroup_602706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_602685 = ref object of OpenApiRestCall_600410
proc url_GetModifyOptionGroup_602687(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_602686(path: JsonNode; query: JsonNode;
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
  var valid_602688 = query.getOrDefault("OptionGroupName")
  valid_602688 = validateParameter(valid_602688, JString, required = true,
                                 default = nil)
  if valid_602688 != nil:
    section.add "OptionGroupName", valid_602688
  var valid_602689 = query.getOrDefault("OptionsToRemove")
  valid_602689 = validateParameter(valid_602689, JArray, required = false,
                                 default = nil)
  if valid_602689 != nil:
    section.add "OptionsToRemove", valid_602689
  var valid_602690 = query.getOrDefault("Action")
  valid_602690 = validateParameter(valid_602690, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_602690 != nil:
    section.add "Action", valid_602690
  var valid_602691 = query.getOrDefault("Version")
  valid_602691 = validateParameter(valid_602691, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602691 != nil:
    section.add "Version", valid_602691
  var valid_602692 = query.getOrDefault("ApplyImmediately")
  valid_602692 = validateParameter(valid_602692, JBool, required = false, default = nil)
  if valid_602692 != nil:
    section.add "ApplyImmediately", valid_602692
  var valid_602693 = query.getOrDefault("OptionsToInclude")
  valid_602693 = validateParameter(valid_602693, JArray, required = false,
                                 default = nil)
  if valid_602693 != nil:
    section.add "OptionsToInclude", valid_602693
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602694 = header.getOrDefault("X-Amz-Date")
  valid_602694 = validateParameter(valid_602694, JString, required = false,
                                 default = nil)
  if valid_602694 != nil:
    section.add "X-Amz-Date", valid_602694
  var valid_602695 = header.getOrDefault("X-Amz-Security-Token")
  valid_602695 = validateParameter(valid_602695, JString, required = false,
                                 default = nil)
  if valid_602695 != nil:
    section.add "X-Amz-Security-Token", valid_602695
  var valid_602696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602696 = validateParameter(valid_602696, JString, required = false,
                                 default = nil)
  if valid_602696 != nil:
    section.add "X-Amz-Content-Sha256", valid_602696
  var valid_602697 = header.getOrDefault("X-Amz-Algorithm")
  valid_602697 = validateParameter(valid_602697, JString, required = false,
                                 default = nil)
  if valid_602697 != nil:
    section.add "X-Amz-Algorithm", valid_602697
  var valid_602698 = header.getOrDefault("X-Amz-Signature")
  valid_602698 = validateParameter(valid_602698, JString, required = false,
                                 default = nil)
  if valid_602698 != nil:
    section.add "X-Amz-Signature", valid_602698
  var valid_602699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602699 = validateParameter(valid_602699, JString, required = false,
                                 default = nil)
  if valid_602699 != nil:
    section.add "X-Amz-SignedHeaders", valid_602699
  var valid_602700 = header.getOrDefault("X-Amz-Credential")
  valid_602700 = validateParameter(valid_602700, JString, required = false,
                                 default = nil)
  if valid_602700 != nil:
    section.add "X-Amz-Credential", valid_602700
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602701: Call_GetModifyOptionGroup_602685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602701.validator(path, query, header, formData, body)
  let scheme = call_602701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602701.url(scheme.get, call_602701.host, call_602701.base,
                         call_602701.route, valid.getOrDefault("path"))
  result = hook(call_602701, url, valid)

proc call*(call_602702: Call_GetModifyOptionGroup_602685; OptionGroupName: string;
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
  var query_602703 = newJObject()
  add(query_602703, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_602703.add "OptionsToRemove", OptionsToRemove
  add(query_602703, "Action", newJString(Action))
  add(query_602703, "Version", newJString(Version))
  add(query_602703, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_602703.add "OptionsToInclude", OptionsToInclude
  result = call_602702.call(nil, query_602703, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_602685(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_602686, base: "/",
    url: url_GetModifyOptionGroup_602687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_602742 = ref object of OpenApiRestCall_600410
proc url_PostPromoteReadReplica_602744(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_602743(path: JsonNode; query: JsonNode;
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
  var valid_602745 = query.getOrDefault("Action")
  valid_602745 = validateParameter(valid_602745, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602745 != nil:
    section.add "Action", valid_602745
  var valid_602746 = query.getOrDefault("Version")
  valid_602746 = validateParameter(valid_602746, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602746 != nil:
    section.add "Version", valid_602746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602747 = header.getOrDefault("X-Amz-Date")
  valid_602747 = validateParameter(valid_602747, JString, required = false,
                                 default = nil)
  if valid_602747 != nil:
    section.add "X-Amz-Date", valid_602747
  var valid_602748 = header.getOrDefault("X-Amz-Security-Token")
  valid_602748 = validateParameter(valid_602748, JString, required = false,
                                 default = nil)
  if valid_602748 != nil:
    section.add "X-Amz-Security-Token", valid_602748
  var valid_602749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602749 = validateParameter(valid_602749, JString, required = false,
                                 default = nil)
  if valid_602749 != nil:
    section.add "X-Amz-Content-Sha256", valid_602749
  var valid_602750 = header.getOrDefault("X-Amz-Algorithm")
  valid_602750 = validateParameter(valid_602750, JString, required = false,
                                 default = nil)
  if valid_602750 != nil:
    section.add "X-Amz-Algorithm", valid_602750
  var valid_602751 = header.getOrDefault("X-Amz-Signature")
  valid_602751 = validateParameter(valid_602751, JString, required = false,
                                 default = nil)
  if valid_602751 != nil:
    section.add "X-Amz-Signature", valid_602751
  var valid_602752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602752 = validateParameter(valid_602752, JString, required = false,
                                 default = nil)
  if valid_602752 != nil:
    section.add "X-Amz-SignedHeaders", valid_602752
  var valid_602753 = header.getOrDefault("X-Amz-Credential")
  valid_602753 = validateParameter(valid_602753, JString, required = false,
                                 default = nil)
  if valid_602753 != nil:
    section.add "X-Amz-Credential", valid_602753
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602754 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602754 = validateParameter(valid_602754, JString, required = true,
                                 default = nil)
  if valid_602754 != nil:
    section.add "DBInstanceIdentifier", valid_602754
  var valid_602755 = formData.getOrDefault("BackupRetentionPeriod")
  valid_602755 = validateParameter(valid_602755, JInt, required = false, default = nil)
  if valid_602755 != nil:
    section.add "BackupRetentionPeriod", valid_602755
  var valid_602756 = formData.getOrDefault("PreferredBackupWindow")
  valid_602756 = validateParameter(valid_602756, JString, required = false,
                                 default = nil)
  if valid_602756 != nil:
    section.add "PreferredBackupWindow", valid_602756
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602757: Call_PostPromoteReadReplica_602742; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602757.validator(path, query, header, formData, body)
  let scheme = call_602757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602757.url(scheme.get, call_602757.host, call_602757.base,
                         call_602757.route, valid.getOrDefault("path"))
  result = hook(call_602757, url, valid)

proc call*(call_602758: Call_PostPromoteReadReplica_602742;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_602759 = newJObject()
  var formData_602760 = newJObject()
  add(formData_602760, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602760, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602759, "Action", newJString(Action))
  add(formData_602760, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602759, "Version", newJString(Version))
  result = call_602758.call(nil, query_602759, nil, formData_602760, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_602742(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_602743, base: "/",
    url: url_PostPromoteReadReplica_602744, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_602724 = ref object of OpenApiRestCall_600410
proc url_GetPromoteReadReplica_602726(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_602725(path: JsonNode; query: JsonNode;
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
  var valid_602727 = query.getOrDefault("BackupRetentionPeriod")
  valid_602727 = validateParameter(valid_602727, JInt, required = false, default = nil)
  if valid_602727 != nil:
    section.add "BackupRetentionPeriod", valid_602727
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602728 = query.getOrDefault("Action")
  valid_602728 = validateParameter(valid_602728, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_602728 != nil:
    section.add "Action", valid_602728
  var valid_602729 = query.getOrDefault("PreferredBackupWindow")
  valid_602729 = validateParameter(valid_602729, JString, required = false,
                                 default = nil)
  if valid_602729 != nil:
    section.add "PreferredBackupWindow", valid_602729
  var valid_602730 = query.getOrDefault("Version")
  valid_602730 = validateParameter(valid_602730, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602730 != nil:
    section.add "Version", valid_602730
  var valid_602731 = query.getOrDefault("DBInstanceIdentifier")
  valid_602731 = validateParameter(valid_602731, JString, required = true,
                                 default = nil)
  if valid_602731 != nil:
    section.add "DBInstanceIdentifier", valid_602731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602732 = header.getOrDefault("X-Amz-Date")
  valid_602732 = validateParameter(valid_602732, JString, required = false,
                                 default = nil)
  if valid_602732 != nil:
    section.add "X-Amz-Date", valid_602732
  var valid_602733 = header.getOrDefault("X-Amz-Security-Token")
  valid_602733 = validateParameter(valid_602733, JString, required = false,
                                 default = nil)
  if valid_602733 != nil:
    section.add "X-Amz-Security-Token", valid_602733
  var valid_602734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602734 = validateParameter(valid_602734, JString, required = false,
                                 default = nil)
  if valid_602734 != nil:
    section.add "X-Amz-Content-Sha256", valid_602734
  var valid_602735 = header.getOrDefault("X-Amz-Algorithm")
  valid_602735 = validateParameter(valid_602735, JString, required = false,
                                 default = nil)
  if valid_602735 != nil:
    section.add "X-Amz-Algorithm", valid_602735
  var valid_602736 = header.getOrDefault("X-Amz-Signature")
  valid_602736 = validateParameter(valid_602736, JString, required = false,
                                 default = nil)
  if valid_602736 != nil:
    section.add "X-Amz-Signature", valid_602736
  var valid_602737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602737 = validateParameter(valid_602737, JString, required = false,
                                 default = nil)
  if valid_602737 != nil:
    section.add "X-Amz-SignedHeaders", valid_602737
  var valid_602738 = header.getOrDefault("X-Amz-Credential")
  valid_602738 = validateParameter(valid_602738, JString, required = false,
                                 default = nil)
  if valid_602738 != nil:
    section.add "X-Amz-Credential", valid_602738
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602739: Call_GetPromoteReadReplica_602724; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602739.validator(path, query, header, formData, body)
  let scheme = call_602739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602739.url(scheme.get, call_602739.host, call_602739.base,
                         call_602739.route, valid.getOrDefault("path"))
  result = hook(call_602739, url, valid)

proc call*(call_602740: Call_GetPromoteReadReplica_602724;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602741 = newJObject()
  add(query_602741, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_602741, "Action", newJString(Action))
  add(query_602741, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_602741, "Version", newJString(Version))
  add(query_602741, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602740.call(nil, query_602741, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_602724(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_602725, base: "/",
    url: url_GetPromoteReadReplica_602726, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_602779 = ref object of OpenApiRestCall_600410
proc url_PostPurchaseReservedDBInstancesOffering_602781(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_602780(path: JsonNode;
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
  var valid_602782 = query.getOrDefault("Action")
  valid_602782 = validateParameter(valid_602782, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602782 != nil:
    section.add "Action", valid_602782
  var valid_602783 = query.getOrDefault("Version")
  valid_602783 = validateParameter(valid_602783, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602783 != nil:
    section.add "Version", valid_602783
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602784 = header.getOrDefault("X-Amz-Date")
  valid_602784 = validateParameter(valid_602784, JString, required = false,
                                 default = nil)
  if valid_602784 != nil:
    section.add "X-Amz-Date", valid_602784
  var valid_602785 = header.getOrDefault("X-Amz-Security-Token")
  valid_602785 = validateParameter(valid_602785, JString, required = false,
                                 default = nil)
  if valid_602785 != nil:
    section.add "X-Amz-Security-Token", valid_602785
  var valid_602786 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602786 = validateParameter(valid_602786, JString, required = false,
                                 default = nil)
  if valid_602786 != nil:
    section.add "X-Amz-Content-Sha256", valid_602786
  var valid_602787 = header.getOrDefault("X-Amz-Algorithm")
  valid_602787 = validateParameter(valid_602787, JString, required = false,
                                 default = nil)
  if valid_602787 != nil:
    section.add "X-Amz-Algorithm", valid_602787
  var valid_602788 = header.getOrDefault("X-Amz-Signature")
  valid_602788 = validateParameter(valid_602788, JString, required = false,
                                 default = nil)
  if valid_602788 != nil:
    section.add "X-Amz-Signature", valid_602788
  var valid_602789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602789 = validateParameter(valid_602789, JString, required = false,
                                 default = nil)
  if valid_602789 != nil:
    section.add "X-Amz-SignedHeaders", valid_602789
  var valid_602790 = header.getOrDefault("X-Amz-Credential")
  valid_602790 = validateParameter(valid_602790, JString, required = false,
                                 default = nil)
  if valid_602790 != nil:
    section.add "X-Amz-Credential", valid_602790
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_602791 = formData.getOrDefault("ReservedDBInstanceId")
  valid_602791 = validateParameter(valid_602791, JString, required = false,
                                 default = nil)
  if valid_602791 != nil:
    section.add "ReservedDBInstanceId", valid_602791
  var valid_602792 = formData.getOrDefault("DBInstanceCount")
  valid_602792 = validateParameter(valid_602792, JInt, required = false, default = nil)
  if valid_602792 != nil:
    section.add "DBInstanceCount", valid_602792
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602793 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602793 = validateParameter(valid_602793, JString, required = true,
                                 default = nil)
  if valid_602793 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602793
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602794: Call_PostPurchaseReservedDBInstancesOffering_602779;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602794.validator(path, query, header, formData, body)
  let scheme = call_602794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602794.url(scheme.get, call_602794.host, call_602794.base,
                         call_602794.route, valid.getOrDefault("path"))
  result = hook(call_602794, url, valid)

proc call*(call_602795: Call_PostPurchaseReservedDBInstancesOffering_602779;
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
  var query_602796 = newJObject()
  var formData_602797 = newJObject()
  add(formData_602797, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_602797, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602796, "Action", newJString(Action))
  add(formData_602797, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602796, "Version", newJString(Version))
  result = call_602795.call(nil, query_602796, nil, formData_602797, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_602779(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_602780, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_602781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_602761 = ref object of OpenApiRestCall_600410
proc url_GetPurchaseReservedDBInstancesOffering_602763(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_602762(path: JsonNode;
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
  var valid_602764 = query.getOrDefault("DBInstanceCount")
  valid_602764 = validateParameter(valid_602764, JInt, required = false, default = nil)
  if valid_602764 != nil:
    section.add "DBInstanceCount", valid_602764
  var valid_602765 = query.getOrDefault("ReservedDBInstanceId")
  valid_602765 = validateParameter(valid_602765, JString, required = false,
                                 default = nil)
  if valid_602765 != nil:
    section.add "ReservedDBInstanceId", valid_602765
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_602766 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_602766 = validateParameter(valid_602766, JString, required = true,
                                 default = nil)
  if valid_602766 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_602766
  var valid_602767 = query.getOrDefault("Action")
  valid_602767 = validateParameter(valid_602767, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_602767 != nil:
    section.add "Action", valid_602767
  var valid_602768 = query.getOrDefault("Version")
  valid_602768 = validateParameter(valid_602768, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602768 != nil:
    section.add "Version", valid_602768
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602769 = header.getOrDefault("X-Amz-Date")
  valid_602769 = validateParameter(valid_602769, JString, required = false,
                                 default = nil)
  if valid_602769 != nil:
    section.add "X-Amz-Date", valid_602769
  var valid_602770 = header.getOrDefault("X-Amz-Security-Token")
  valid_602770 = validateParameter(valid_602770, JString, required = false,
                                 default = nil)
  if valid_602770 != nil:
    section.add "X-Amz-Security-Token", valid_602770
  var valid_602771 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602771 = validateParameter(valid_602771, JString, required = false,
                                 default = nil)
  if valid_602771 != nil:
    section.add "X-Amz-Content-Sha256", valid_602771
  var valid_602772 = header.getOrDefault("X-Amz-Algorithm")
  valid_602772 = validateParameter(valid_602772, JString, required = false,
                                 default = nil)
  if valid_602772 != nil:
    section.add "X-Amz-Algorithm", valid_602772
  var valid_602773 = header.getOrDefault("X-Amz-Signature")
  valid_602773 = validateParameter(valid_602773, JString, required = false,
                                 default = nil)
  if valid_602773 != nil:
    section.add "X-Amz-Signature", valid_602773
  var valid_602774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602774 = validateParameter(valid_602774, JString, required = false,
                                 default = nil)
  if valid_602774 != nil:
    section.add "X-Amz-SignedHeaders", valid_602774
  var valid_602775 = header.getOrDefault("X-Amz-Credential")
  valid_602775 = validateParameter(valid_602775, JString, required = false,
                                 default = nil)
  if valid_602775 != nil:
    section.add "X-Amz-Credential", valid_602775
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602776: Call_GetPurchaseReservedDBInstancesOffering_602761;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602776.validator(path, query, header, formData, body)
  let scheme = call_602776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602776.url(scheme.get, call_602776.host, call_602776.base,
                         call_602776.route, valid.getOrDefault("path"))
  result = hook(call_602776, url, valid)

proc call*(call_602777: Call_GetPurchaseReservedDBInstancesOffering_602761;
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
  var query_602778 = newJObject()
  add(query_602778, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_602778, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_602778, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_602778, "Action", newJString(Action))
  add(query_602778, "Version", newJString(Version))
  result = call_602777.call(nil, query_602778, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_602761(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_602762, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_602763,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_602815 = ref object of OpenApiRestCall_600410
proc url_PostRebootDBInstance_602817(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_602816(path: JsonNode; query: JsonNode;
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
  var valid_602818 = query.getOrDefault("Action")
  valid_602818 = validateParameter(valid_602818, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602818 != nil:
    section.add "Action", valid_602818
  var valid_602819 = query.getOrDefault("Version")
  valid_602819 = validateParameter(valid_602819, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602819 != nil:
    section.add "Version", valid_602819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602820 = header.getOrDefault("X-Amz-Date")
  valid_602820 = validateParameter(valid_602820, JString, required = false,
                                 default = nil)
  if valid_602820 != nil:
    section.add "X-Amz-Date", valid_602820
  var valid_602821 = header.getOrDefault("X-Amz-Security-Token")
  valid_602821 = validateParameter(valid_602821, JString, required = false,
                                 default = nil)
  if valid_602821 != nil:
    section.add "X-Amz-Security-Token", valid_602821
  var valid_602822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602822 = validateParameter(valid_602822, JString, required = false,
                                 default = nil)
  if valid_602822 != nil:
    section.add "X-Amz-Content-Sha256", valid_602822
  var valid_602823 = header.getOrDefault("X-Amz-Algorithm")
  valid_602823 = validateParameter(valid_602823, JString, required = false,
                                 default = nil)
  if valid_602823 != nil:
    section.add "X-Amz-Algorithm", valid_602823
  var valid_602824 = header.getOrDefault("X-Amz-Signature")
  valid_602824 = validateParameter(valid_602824, JString, required = false,
                                 default = nil)
  if valid_602824 != nil:
    section.add "X-Amz-Signature", valid_602824
  var valid_602825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602825 = validateParameter(valid_602825, JString, required = false,
                                 default = nil)
  if valid_602825 != nil:
    section.add "X-Amz-SignedHeaders", valid_602825
  var valid_602826 = header.getOrDefault("X-Amz-Credential")
  valid_602826 = validateParameter(valid_602826, JString, required = false,
                                 default = nil)
  if valid_602826 != nil:
    section.add "X-Amz-Credential", valid_602826
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602827 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602827 = validateParameter(valid_602827, JString, required = true,
                                 default = nil)
  if valid_602827 != nil:
    section.add "DBInstanceIdentifier", valid_602827
  var valid_602828 = formData.getOrDefault("ForceFailover")
  valid_602828 = validateParameter(valid_602828, JBool, required = false, default = nil)
  if valid_602828 != nil:
    section.add "ForceFailover", valid_602828
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602829: Call_PostRebootDBInstance_602815; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602829.validator(path, query, header, formData, body)
  let scheme = call_602829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602829.url(scheme.get, call_602829.host, call_602829.base,
                         call_602829.route, valid.getOrDefault("path"))
  result = hook(call_602829, url, valid)

proc call*(call_602830: Call_PostRebootDBInstance_602815;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_602831 = newJObject()
  var formData_602832 = newJObject()
  add(formData_602832, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602831, "Action", newJString(Action))
  add(formData_602832, "ForceFailover", newJBool(ForceFailover))
  add(query_602831, "Version", newJString(Version))
  result = call_602830.call(nil, query_602831, nil, formData_602832, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_602815(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_602816, base: "/",
    url: url_PostRebootDBInstance_602817, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_602798 = ref object of OpenApiRestCall_600410
proc url_GetRebootDBInstance_602800(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_602799(path: JsonNode; query: JsonNode;
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
  var valid_602801 = query.getOrDefault("Action")
  valid_602801 = validateParameter(valid_602801, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_602801 != nil:
    section.add "Action", valid_602801
  var valid_602802 = query.getOrDefault("ForceFailover")
  valid_602802 = validateParameter(valid_602802, JBool, required = false, default = nil)
  if valid_602802 != nil:
    section.add "ForceFailover", valid_602802
  var valid_602803 = query.getOrDefault("Version")
  valid_602803 = validateParameter(valid_602803, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602803 != nil:
    section.add "Version", valid_602803
  var valid_602804 = query.getOrDefault("DBInstanceIdentifier")
  valid_602804 = validateParameter(valid_602804, JString, required = true,
                                 default = nil)
  if valid_602804 != nil:
    section.add "DBInstanceIdentifier", valid_602804
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602805 = header.getOrDefault("X-Amz-Date")
  valid_602805 = validateParameter(valid_602805, JString, required = false,
                                 default = nil)
  if valid_602805 != nil:
    section.add "X-Amz-Date", valid_602805
  var valid_602806 = header.getOrDefault("X-Amz-Security-Token")
  valid_602806 = validateParameter(valid_602806, JString, required = false,
                                 default = nil)
  if valid_602806 != nil:
    section.add "X-Amz-Security-Token", valid_602806
  var valid_602807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602807 = validateParameter(valid_602807, JString, required = false,
                                 default = nil)
  if valid_602807 != nil:
    section.add "X-Amz-Content-Sha256", valid_602807
  var valid_602808 = header.getOrDefault("X-Amz-Algorithm")
  valid_602808 = validateParameter(valid_602808, JString, required = false,
                                 default = nil)
  if valid_602808 != nil:
    section.add "X-Amz-Algorithm", valid_602808
  var valid_602809 = header.getOrDefault("X-Amz-Signature")
  valid_602809 = validateParameter(valid_602809, JString, required = false,
                                 default = nil)
  if valid_602809 != nil:
    section.add "X-Amz-Signature", valid_602809
  var valid_602810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602810 = validateParameter(valid_602810, JString, required = false,
                                 default = nil)
  if valid_602810 != nil:
    section.add "X-Amz-SignedHeaders", valid_602810
  var valid_602811 = header.getOrDefault("X-Amz-Credential")
  valid_602811 = validateParameter(valid_602811, JString, required = false,
                                 default = nil)
  if valid_602811 != nil:
    section.add "X-Amz-Credential", valid_602811
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602812: Call_GetRebootDBInstance_602798; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602812.validator(path, query, header, formData, body)
  let scheme = call_602812.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602812.url(scheme.get, call_602812.host, call_602812.base,
                         call_602812.route, valid.getOrDefault("path"))
  result = hook(call_602812, url, valid)

proc call*(call_602813: Call_GetRebootDBInstance_602798;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_602814 = newJObject()
  add(query_602814, "Action", newJString(Action))
  add(query_602814, "ForceFailover", newJBool(ForceFailover))
  add(query_602814, "Version", newJString(Version))
  add(query_602814, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_602813.call(nil, query_602814, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_602798(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_602799, base: "/",
    url: url_GetRebootDBInstance_602800, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_602850 = ref object of OpenApiRestCall_600410
proc url_PostRemoveSourceIdentifierFromSubscription_602852(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_602851(path: JsonNode;
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
  var valid_602853 = query.getOrDefault("Action")
  valid_602853 = validateParameter(valid_602853, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602853 != nil:
    section.add "Action", valid_602853
  var valid_602854 = query.getOrDefault("Version")
  valid_602854 = validateParameter(valid_602854, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602854 != nil:
    section.add "Version", valid_602854
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602855 = header.getOrDefault("X-Amz-Date")
  valid_602855 = validateParameter(valid_602855, JString, required = false,
                                 default = nil)
  if valid_602855 != nil:
    section.add "X-Amz-Date", valid_602855
  var valid_602856 = header.getOrDefault("X-Amz-Security-Token")
  valid_602856 = validateParameter(valid_602856, JString, required = false,
                                 default = nil)
  if valid_602856 != nil:
    section.add "X-Amz-Security-Token", valid_602856
  var valid_602857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602857 = validateParameter(valid_602857, JString, required = false,
                                 default = nil)
  if valid_602857 != nil:
    section.add "X-Amz-Content-Sha256", valid_602857
  var valid_602858 = header.getOrDefault("X-Amz-Algorithm")
  valid_602858 = validateParameter(valid_602858, JString, required = false,
                                 default = nil)
  if valid_602858 != nil:
    section.add "X-Amz-Algorithm", valid_602858
  var valid_602859 = header.getOrDefault("X-Amz-Signature")
  valid_602859 = validateParameter(valid_602859, JString, required = false,
                                 default = nil)
  if valid_602859 != nil:
    section.add "X-Amz-Signature", valid_602859
  var valid_602860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602860 = validateParameter(valid_602860, JString, required = false,
                                 default = nil)
  if valid_602860 != nil:
    section.add "X-Amz-SignedHeaders", valid_602860
  var valid_602861 = header.getOrDefault("X-Amz-Credential")
  valid_602861 = validateParameter(valid_602861, JString, required = false,
                                 default = nil)
  if valid_602861 != nil:
    section.add "X-Amz-Credential", valid_602861
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_602862 = formData.getOrDefault("SourceIdentifier")
  valid_602862 = validateParameter(valid_602862, JString, required = true,
                                 default = nil)
  if valid_602862 != nil:
    section.add "SourceIdentifier", valid_602862
  var valid_602863 = formData.getOrDefault("SubscriptionName")
  valid_602863 = validateParameter(valid_602863, JString, required = true,
                                 default = nil)
  if valid_602863 != nil:
    section.add "SubscriptionName", valid_602863
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602864: Call_PostRemoveSourceIdentifierFromSubscription_602850;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602864.validator(path, query, header, formData, body)
  let scheme = call_602864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602864.url(scheme.get, call_602864.host, call_602864.base,
                         call_602864.route, valid.getOrDefault("path"))
  result = hook(call_602864, url, valid)

proc call*(call_602865: Call_PostRemoveSourceIdentifierFromSubscription_602850;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_602866 = newJObject()
  var formData_602867 = newJObject()
  add(formData_602867, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_602867, "SubscriptionName", newJString(SubscriptionName))
  add(query_602866, "Action", newJString(Action))
  add(query_602866, "Version", newJString(Version))
  result = call_602865.call(nil, query_602866, nil, formData_602867, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_602850(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_602851,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_602852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_602833 = ref object of OpenApiRestCall_600410
proc url_GetRemoveSourceIdentifierFromSubscription_602835(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_602834(path: JsonNode;
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
  var valid_602836 = query.getOrDefault("Action")
  valid_602836 = validateParameter(valid_602836, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_602836 != nil:
    section.add "Action", valid_602836
  var valid_602837 = query.getOrDefault("SourceIdentifier")
  valid_602837 = validateParameter(valid_602837, JString, required = true,
                                 default = nil)
  if valid_602837 != nil:
    section.add "SourceIdentifier", valid_602837
  var valid_602838 = query.getOrDefault("SubscriptionName")
  valid_602838 = validateParameter(valid_602838, JString, required = true,
                                 default = nil)
  if valid_602838 != nil:
    section.add "SubscriptionName", valid_602838
  var valid_602839 = query.getOrDefault("Version")
  valid_602839 = validateParameter(valid_602839, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602839 != nil:
    section.add "Version", valid_602839
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602840 = header.getOrDefault("X-Amz-Date")
  valid_602840 = validateParameter(valid_602840, JString, required = false,
                                 default = nil)
  if valid_602840 != nil:
    section.add "X-Amz-Date", valid_602840
  var valid_602841 = header.getOrDefault("X-Amz-Security-Token")
  valid_602841 = validateParameter(valid_602841, JString, required = false,
                                 default = nil)
  if valid_602841 != nil:
    section.add "X-Amz-Security-Token", valid_602841
  var valid_602842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602842 = validateParameter(valid_602842, JString, required = false,
                                 default = nil)
  if valid_602842 != nil:
    section.add "X-Amz-Content-Sha256", valid_602842
  var valid_602843 = header.getOrDefault("X-Amz-Algorithm")
  valid_602843 = validateParameter(valid_602843, JString, required = false,
                                 default = nil)
  if valid_602843 != nil:
    section.add "X-Amz-Algorithm", valid_602843
  var valid_602844 = header.getOrDefault("X-Amz-Signature")
  valid_602844 = validateParameter(valid_602844, JString, required = false,
                                 default = nil)
  if valid_602844 != nil:
    section.add "X-Amz-Signature", valid_602844
  var valid_602845 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602845 = validateParameter(valid_602845, JString, required = false,
                                 default = nil)
  if valid_602845 != nil:
    section.add "X-Amz-SignedHeaders", valid_602845
  var valid_602846 = header.getOrDefault("X-Amz-Credential")
  valid_602846 = validateParameter(valid_602846, JString, required = false,
                                 default = nil)
  if valid_602846 != nil:
    section.add "X-Amz-Credential", valid_602846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602847: Call_GetRemoveSourceIdentifierFromSubscription_602833;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602847.validator(path, query, header, formData, body)
  let scheme = call_602847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602847.url(scheme.get, call_602847.host, call_602847.base,
                         call_602847.route, valid.getOrDefault("path"))
  result = hook(call_602847, url, valid)

proc call*(call_602848: Call_GetRemoveSourceIdentifierFromSubscription_602833;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602849 = newJObject()
  add(query_602849, "Action", newJString(Action))
  add(query_602849, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602849, "SubscriptionName", newJString(SubscriptionName))
  add(query_602849, "Version", newJString(Version))
  result = call_602848.call(nil, query_602849, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_602833(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_602834,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_602835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_602885 = ref object of OpenApiRestCall_600410
proc url_PostRemoveTagsFromResource_602887(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_602886(path: JsonNode; query: JsonNode;
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
  var valid_602888 = query.getOrDefault("Action")
  valid_602888 = validateParameter(valid_602888, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602888 != nil:
    section.add "Action", valid_602888
  var valid_602889 = query.getOrDefault("Version")
  valid_602889 = validateParameter(valid_602889, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602889 != nil:
    section.add "Version", valid_602889
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602890 = header.getOrDefault("X-Amz-Date")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-Date", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Security-Token")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Security-Token", valid_602891
  var valid_602892 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602892 = validateParameter(valid_602892, JString, required = false,
                                 default = nil)
  if valid_602892 != nil:
    section.add "X-Amz-Content-Sha256", valid_602892
  var valid_602893 = header.getOrDefault("X-Amz-Algorithm")
  valid_602893 = validateParameter(valid_602893, JString, required = false,
                                 default = nil)
  if valid_602893 != nil:
    section.add "X-Amz-Algorithm", valid_602893
  var valid_602894 = header.getOrDefault("X-Amz-Signature")
  valid_602894 = validateParameter(valid_602894, JString, required = false,
                                 default = nil)
  if valid_602894 != nil:
    section.add "X-Amz-Signature", valid_602894
  var valid_602895 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602895 = validateParameter(valid_602895, JString, required = false,
                                 default = nil)
  if valid_602895 != nil:
    section.add "X-Amz-SignedHeaders", valid_602895
  var valid_602896 = header.getOrDefault("X-Amz-Credential")
  valid_602896 = validateParameter(valid_602896, JString, required = false,
                                 default = nil)
  if valid_602896 != nil:
    section.add "X-Amz-Credential", valid_602896
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_602897 = formData.getOrDefault("TagKeys")
  valid_602897 = validateParameter(valid_602897, JArray, required = true, default = nil)
  if valid_602897 != nil:
    section.add "TagKeys", valid_602897
  var valid_602898 = formData.getOrDefault("ResourceName")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "ResourceName", valid_602898
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602899: Call_PostRemoveTagsFromResource_602885; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602899.validator(path, query, header, formData, body)
  let scheme = call_602899.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602899.url(scheme.get, call_602899.host, call_602899.base,
                         call_602899.route, valid.getOrDefault("path"))
  result = hook(call_602899, url, valid)

proc call*(call_602900: Call_PostRemoveTagsFromResource_602885; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_602901 = newJObject()
  var formData_602902 = newJObject()
  add(query_602901, "Action", newJString(Action))
  if TagKeys != nil:
    formData_602902.add "TagKeys", TagKeys
  add(formData_602902, "ResourceName", newJString(ResourceName))
  add(query_602901, "Version", newJString(Version))
  result = call_602900.call(nil, query_602901, nil, formData_602902, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_602885(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_602886, base: "/",
    url: url_PostRemoveTagsFromResource_602887,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_602868 = ref object of OpenApiRestCall_600410
proc url_GetRemoveTagsFromResource_602870(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_602869(path: JsonNode; query: JsonNode;
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
  var valid_602871 = query.getOrDefault("ResourceName")
  valid_602871 = validateParameter(valid_602871, JString, required = true,
                                 default = nil)
  if valid_602871 != nil:
    section.add "ResourceName", valid_602871
  var valid_602872 = query.getOrDefault("Action")
  valid_602872 = validateParameter(valid_602872, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_602872 != nil:
    section.add "Action", valid_602872
  var valid_602873 = query.getOrDefault("TagKeys")
  valid_602873 = validateParameter(valid_602873, JArray, required = true, default = nil)
  if valid_602873 != nil:
    section.add "TagKeys", valid_602873
  var valid_602874 = query.getOrDefault("Version")
  valid_602874 = validateParameter(valid_602874, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602874 != nil:
    section.add "Version", valid_602874
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602875 = header.getOrDefault("X-Amz-Date")
  valid_602875 = validateParameter(valid_602875, JString, required = false,
                                 default = nil)
  if valid_602875 != nil:
    section.add "X-Amz-Date", valid_602875
  var valid_602876 = header.getOrDefault("X-Amz-Security-Token")
  valid_602876 = validateParameter(valid_602876, JString, required = false,
                                 default = nil)
  if valid_602876 != nil:
    section.add "X-Amz-Security-Token", valid_602876
  var valid_602877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602877 = validateParameter(valid_602877, JString, required = false,
                                 default = nil)
  if valid_602877 != nil:
    section.add "X-Amz-Content-Sha256", valid_602877
  var valid_602878 = header.getOrDefault("X-Amz-Algorithm")
  valid_602878 = validateParameter(valid_602878, JString, required = false,
                                 default = nil)
  if valid_602878 != nil:
    section.add "X-Amz-Algorithm", valid_602878
  var valid_602879 = header.getOrDefault("X-Amz-Signature")
  valid_602879 = validateParameter(valid_602879, JString, required = false,
                                 default = nil)
  if valid_602879 != nil:
    section.add "X-Amz-Signature", valid_602879
  var valid_602880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602880 = validateParameter(valid_602880, JString, required = false,
                                 default = nil)
  if valid_602880 != nil:
    section.add "X-Amz-SignedHeaders", valid_602880
  var valid_602881 = header.getOrDefault("X-Amz-Credential")
  valid_602881 = validateParameter(valid_602881, JString, required = false,
                                 default = nil)
  if valid_602881 != nil:
    section.add "X-Amz-Credential", valid_602881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602882: Call_GetRemoveTagsFromResource_602868; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602882.validator(path, query, header, formData, body)
  let scheme = call_602882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602882.url(scheme.get, call_602882.host, call_602882.base,
                         call_602882.route, valid.getOrDefault("path"))
  result = hook(call_602882, url, valid)

proc call*(call_602883: Call_GetRemoveTagsFromResource_602868;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_602884 = newJObject()
  add(query_602884, "ResourceName", newJString(ResourceName))
  add(query_602884, "Action", newJString(Action))
  if TagKeys != nil:
    query_602884.add "TagKeys", TagKeys
  add(query_602884, "Version", newJString(Version))
  result = call_602883.call(nil, query_602884, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_602868(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_602869, base: "/",
    url: url_GetRemoveTagsFromResource_602870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_602921 = ref object of OpenApiRestCall_600410
proc url_PostResetDBParameterGroup_602923(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_602922(path: JsonNode; query: JsonNode;
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
  var valid_602924 = query.getOrDefault("Action")
  valid_602924 = validateParameter(valid_602924, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602924 != nil:
    section.add "Action", valid_602924
  var valid_602925 = query.getOrDefault("Version")
  valid_602925 = validateParameter(valid_602925, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602925 != nil:
    section.add "Version", valid_602925
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602926 = header.getOrDefault("X-Amz-Date")
  valid_602926 = validateParameter(valid_602926, JString, required = false,
                                 default = nil)
  if valid_602926 != nil:
    section.add "X-Amz-Date", valid_602926
  var valid_602927 = header.getOrDefault("X-Amz-Security-Token")
  valid_602927 = validateParameter(valid_602927, JString, required = false,
                                 default = nil)
  if valid_602927 != nil:
    section.add "X-Amz-Security-Token", valid_602927
  var valid_602928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602928 = validateParameter(valid_602928, JString, required = false,
                                 default = nil)
  if valid_602928 != nil:
    section.add "X-Amz-Content-Sha256", valid_602928
  var valid_602929 = header.getOrDefault("X-Amz-Algorithm")
  valid_602929 = validateParameter(valid_602929, JString, required = false,
                                 default = nil)
  if valid_602929 != nil:
    section.add "X-Amz-Algorithm", valid_602929
  var valid_602930 = header.getOrDefault("X-Amz-Signature")
  valid_602930 = validateParameter(valid_602930, JString, required = false,
                                 default = nil)
  if valid_602930 != nil:
    section.add "X-Amz-Signature", valid_602930
  var valid_602931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602931 = validateParameter(valid_602931, JString, required = false,
                                 default = nil)
  if valid_602931 != nil:
    section.add "X-Amz-SignedHeaders", valid_602931
  var valid_602932 = header.getOrDefault("X-Amz-Credential")
  valid_602932 = validateParameter(valid_602932, JString, required = false,
                                 default = nil)
  if valid_602932 != nil:
    section.add "X-Amz-Credential", valid_602932
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_602933 = formData.getOrDefault("DBParameterGroupName")
  valid_602933 = validateParameter(valid_602933, JString, required = true,
                                 default = nil)
  if valid_602933 != nil:
    section.add "DBParameterGroupName", valid_602933
  var valid_602934 = formData.getOrDefault("Parameters")
  valid_602934 = validateParameter(valid_602934, JArray, required = false,
                                 default = nil)
  if valid_602934 != nil:
    section.add "Parameters", valid_602934
  var valid_602935 = formData.getOrDefault("ResetAllParameters")
  valid_602935 = validateParameter(valid_602935, JBool, required = false, default = nil)
  if valid_602935 != nil:
    section.add "ResetAllParameters", valid_602935
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602936: Call_PostResetDBParameterGroup_602921; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602936.validator(path, query, header, formData, body)
  let scheme = call_602936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602936.url(scheme.get, call_602936.host, call_602936.base,
                         call_602936.route, valid.getOrDefault("path"))
  result = hook(call_602936, url, valid)

proc call*(call_602937: Call_PostResetDBParameterGroup_602921;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602938 = newJObject()
  var formData_602939 = newJObject()
  add(formData_602939, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_602939.add "Parameters", Parameters
  add(query_602938, "Action", newJString(Action))
  add(formData_602939, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602938, "Version", newJString(Version))
  result = call_602937.call(nil, query_602938, nil, formData_602939, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_602921(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_602922, base: "/",
    url: url_PostResetDBParameterGroup_602923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_602903 = ref object of OpenApiRestCall_600410
proc url_GetResetDBParameterGroup_602905(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_602904(path: JsonNode; query: JsonNode;
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
  var valid_602906 = query.getOrDefault("DBParameterGroupName")
  valid_602906 = validateParameter(valid_602906, JString, required = true,
                                 default = nil)
  if valid_602906 != nil:
    section.add "DBParameterGroupName", valid_602906
  var valid_602907 = query.getOrDefault("Parameters")
  valid_602907 = validateParameter(valid_602907, JArray, required = false,
                                 default = nil)
  if valid_602907 != nil:
    section.add "Parameters", valid_602907
  var valid_602908 = query.getOrDefault("Action")
  valid_602908 = validateParameter(valid_602908, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_602908 != nil:
    section.add "Action", valid_602908
  var valid_602909 = query.getOrDefault("ResetAllParameters")
  valid_602909 = validateParameter(valid_602909, JBool, required = false, default = nil)
  if valid_602909 != nil:
    section.add "ResetAllParameters", valid_602909
  var valid_602910 = query.getOrDefault("Version")
  valid_602910 = validateParameter(valid_602910, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602910 != nil:
    section.add "Version", valid_602910
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602911 = header.getOrDefault("X-Amz-Date")
  valid_602911 = validateParameter(valid_602911, JString, required = false,
                                 default = nil)
  if valid_602911 != nil:
    section.add "X-Amz-Date", valid_602911
  var valid_602912 = header.getOrDefault("X-Amz-Security-Token")
  valid_602912 = validateParameter(valid_602912, JString, required = false,
                                 default = nil)
  if valid_602912 != nil:
    section.add "X-Amz-Security-Token", valid_602912
  var valid_602913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602913 = validateParameter(valid_602913, JString, required = false,
                                 default = nil)
  if valid_602913 != nil:
    section.add "X-Amz-Content-Sha256", valid_602913
  var valid_602914 = header.getOrDefault("X-Amz-Algorithm")
  valid_602914 = validateParameter(valid_602914, JString, required = false,
                                 default = nil)
  if valid_602914 != nil:
    section.add "X-Amz-Algorithm", valid_602914
  var valid_602915 = header.getOrDefault("X-Amz-Signature")
  valid_602915 = validateParameter(valid_602915, JString, required = false,
                                 default = nil)
  if valid_602915 != nil:
    section.add "X-Amz-Signature", valid_602915
  var valid_602916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602916 = validateParameter(valid_602916, JString, required = false,
                                 default = nil)
  if valid_602916 != nil:
    section.add "X-Amz-SignedHeaders", valid_602916
  var valid_602917 = header.getOrDefault("X-Amz-Credential")
  valid_602917 = validateParameter(valid_602917, JString, required = false,
                                 default = nil)
  if valid_602917 != nil:
    section.add "X-Amz-Credential", valid_602917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602918: Call_GetResetDBParameterGroup_602903; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602918.validator(path, query, header, formData, body)
  let scheme = call_602918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602918.url(scheme.get, call_602918.host, call_602918.base,
                         call_602918.route, valid.getOrDefault("path"))
  result = hook(call_602918, url, valid)

proc call*(call_602919: Call_GetResetDBParameterGroup_602903;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_602920 = newJObject()
  add(query_602920, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_602920.add "Parameters", Parameters
  add(query_602920, "Action", newJString(Action))
  add(query_602920, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_602920, "Version", newJString(Version))
  result = call_602919.call(nil, query_602920, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_602903(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_602904, base: "/",
    url: url_GetResetDBParameterGroup_602905, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_602969 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceFromDBSnapshot_602971(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_602970(path: JsonNode;
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
  var valid_602972 = query.getOrDefault("Action")
  valid_602972 = validateParameter(valid_602972, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602972 != nil:
    section.add "Action", valid_602972
  var valid_602973 = query.getOrDefault("Version")
  valid_602973 = validateParameter(valid_602973, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602973 != nil:
    section.add "Version", valid_602973
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602974 = header.getOrDefault("X-Amz-Date")
  valid_602974 = validateParameter(valid_602974, JString, required = false,
                                 default = nil)
  if valid_602974 != nil:
    section.add "X-Amz-Date", valid_602974
  var valid_602975 = header.getOrDefault("X-Amz-Security-Token")
  valid_602975 = validateParameter(valid_602975, JString, required = false,
                                 default = nil)
  if valid_602975 != nil:
    section.add "X-Amz-Security-Token", valid_602975
  var valid_602976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602976 = validateParameter(valid_602976, JString, required = false,
                                 default = nil)
  if valid_602976 != nil:
    section.add "X-Amz-Content-Sha256", valid_602976
  var valid_602977 = header.getOrDefault("X-Amz-Algorithm")
  valid_602977 = validateParameter(valid_602977, JString, required = false,
                                 default = nil)
  if valid_602977 != nil:
    section.add "X-Amz-Algorithm", valid_602977
  var valid_602978 = header.getOrDefault("X-Amz-Signature")
  valid_602978 = validateParameter(valid_602978, JString, required = false,
                                 default = nil)
  if valid_602978 != nil:
    section.add "X-Amz-Signature", valid_602978
  var valid_602979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602979 = validateParameter(valid_602979, JString, required = false,
                                 default = nil)
  if valid_602979 != nil:
    section.add "X-Amz-SignedHeaders", valid_602979
  var valid_602980 = header.getOrDefault("X-Amz-Credential")
  valid_602980 = validateParameter(valid_602980, JString, required = false,
                                 default = nil)
  if valid_602980 != nil:
    section.add "X-Amz-Credential", valid_602980
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
  var valid_602981 = formData.getOrDefault("Port")
  valid_602981 = validateParameter(valid_602981, JInt, required = false, default = nil)
  if valid_602981 != nil:
    section.add "Port", valid_602981
  var valid_602982 = formData.getOrDefault("Engine")
  valid_602982 = validateParameter(valid_602982, JString, required = false,
                                 default = nil)
  if valid_602982 != nil:
    section.add "Engine", valid_602982
  var valid_602983 = formData.getOrDefault("Iops")
  valid_602983 = validateParameter(valid_602983, JInt, required = false, default = nil)
  if valid_602983 != nil:
    section.add "Iops", valid_602983
  var valid_602984 = formData.getOrDefault("DBName")
  valid_602984 = validateParameter(valid_602984, JString, required = false,
                                 default = nil)
  if valid_602984 != nil:
    section.add "DBName", valid_602984
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_602985 = formData.getOrDefault("DBInstanceIdentifier")
  valid_602985 = validateParameter(valid_602985, JString, required = true,
                                 default = nil)
  if valid_602985 != nil:
    section.add "DBInstanceIdentifier", valid_602985
  var valid_602986 = formData.getOrDefault("OptionGroupName")
  valid_602986 = validateParameter(valid_602986, JString, required = false,
                                 default = nil)
  if valid_602986 != nil:
    section.add "OptionGroupName", valid_602986
  var valid_602987 = formData.getOrDefault("DBSubnetGroupName")
  valid_602987 = validateParameter(valid_602987, JString, required = false,
                                 default = nil)
  if valid_602987 != nil:
    section.add "DBSubnetGroupName", valid_602987
  var valid_602988 = formData.getOrDefault("AvailabilityZone")
  valid_602988 = validateParameter(valid_602988, JString, required = false,
                                 default = nil)
  if valid_602988 != nil:
    section.add "AvailabilityZone", valid_602988
  var valid_602989 = formData.getOrDefault("MultiAZ")
  valid_602989 = validateParameter(valid_602989, JBool, required = false, default = nil)
  if valid_602989 != nil:
    section.add "MultiAZ", valid_602989
  var valid_602990 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_602990 = validateParameter(valid_602990, JString, required = true,
                                 default = nil)
  if valid_602990 != nil:
    section.add "DBSnapshotIdentifier", valid_602990
  var valid_602991 = formData.getOrDefault("PubliclyAccessible")
  valid_602991 = validateParameter(valid_602991, JBool, required = false, default = nil)
  if valid_602991 != nil:
    section.add "PubliclyAccessible", valid_602991
  var valid_602992 = formData.getOrDefault("DBInstanceClass")
  valid_602992 = validateParameter(valid_602992, JString, required = false,
                                 default = nil)
  if valid_602992 != nil:
    section.add "DBInstanceClass", valid_602992
  var valid_602993 = formData.getOrDefault("LicenseModel")
  valid_602993 = validateParameter(valid_602993, JString, required = false,
                                 default = nil)
  if valid_602993 != nil:
    section.add "LicenseModel", valid_602993
  var valid_602994 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_602994 = validateParameter(valid_602994, JBool, required = false, default = nil)
  if valid_602994 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602994
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602995: Call_PostRestoreDBInstanceFromDBSnapshot_602969;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602995.validator(path, query, header, formData, body)
  let scheme = call_602995.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602995.url(scheme.get, call_602995.host, call_602995.base,
                         call_602995.route, valid.getOrDefault("path"))
  result = hook(call_602995, url, valid)

proc call*(call_602996: Call_PostRestoreDBInstanceFromDBSnapshot_602969;
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
  var query_602997 = newJObject()
  var formData_602998 = newJObject()
  add(formData_602998, "Port", newJInt(Port))
  add(formData_602998, "Engine", newJString(Engine))
  add(formData_602998, "Iops", newJInt(Iops))
  add(formData_602998, "DBName", newJString(DBName))
  add(formData_602998, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_602998, "OptionGroupName", newJString(OptionGroupName))
  add(formData_602998, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_602998, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_602998, "MultiAZ", newJBool(MultiAZ))
  add(formData_602998, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_602997, "Action", newJString(Action))
  add(formData_602998, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_602998, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_602998, "LicenseModel", newJString(LicenseModel))
  add(formData_602998, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_602997, "Version", newJString(Version))
  result = call_602996.call(nil, query_602997, nil, formData_602998, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_602969(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_602970, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_602971,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_602940 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceFromDBSnapshot_602942(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_602941(path: JsonNode;
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
  var valid_602943 = query.getOrDefault("Engine")
  valid_602943 = validateParameter(valid_602943, JString, required = false,
                                 default = nil)
  if valid_602943 != nil:
    section.add "Engine", valid_602943
  var valid_602944 = query.getOrDefault("OptionGroupName")
  valid_602944 = validateParameter(valid_602944, JString, required = false,
                                 default = nil)
  if valid_602944 != nil:
    section.add "OptionGroupName", valid_602944
  var valid_602945 = query.getOrDefault("AvailabilityZone")
  valid_602945 = validateParameter(valid_602945, JString, required = false,
                                 default = nil)
  if valid_602945 != nil:
    section.add "AvailabilityZone", valid_602945
  var valid_602946 = query.getOrDefault("Iops")
  valid_602946 = validateParameter(valid_602946, JInt, required = false, default = nil)
  if valid_602946 != nil:
    section.add "Iops", valid_602946
  var valid_602947 = query.getOrDefault("MultiAZ")
  valid_602947 = validateParameter(valid_602947, JBool, required = false, default = nil)
  if valid_602947 != nil:
    section.add "MultiAZ", valid_602947
  var valid_602948 = query.getOrDefault("LicenseModel")
  valid_602948 = validateParameter(valid_602948, JString, required = false,
                                 default = nil)
  if valid_602948 != nil:
    section.add "LicenseModel", valid_602948
  var valid_602949 = query.getOrDefault("DBName")
  valid_602949 = validateParameter(valid_602949, JString, required = false,
                                 default = nil)
  if valid_602949 != nil:
    section.add "DBName", valid_602949
  var valid_602950 = query.getOrDefault("DBInstanceClass")
  valid_602950 = validateParameter(valid_602950, JString, required = false,
                                 default = nil)
  if valid_602950 != nil:
    section.add "DBInstanceClass", valid_602950
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_602951 = query.getOrDefault("Action")
  valid_602951 = validateParameter(valid_602951, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_602951 != nil:
    section.add "Action", valid_602951
  var valid_602952 = query.getOrDefault("DBSubnetGroupName")
  valid_602952 = validateParameter(valid_602952, JString, required = false,
                                 default = nil)
  if valid_602952 != nil:
    section.add "DBSubnetGroupName", valid_602952
  var valid_602953 = query.getOrDefault("PubliclyAccessible")
  valid_602953 = validateParameter(valid_602953, JBool, required = false, default = nil)
  if valid_602953 != nil:
    section.add "PubliclyAccessible", valid_602953
  var valid_602954 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_602954 = validateParameter(valid_602954, JBool, required = false, default = nil)
  if valid_602954 != nil:
    section.add "AutoMinorVersionUpgrade", valid_602954
  var valid_602955 = query.getOrDefault("Port")
  valid_602955 = validateParameter(valid_602955, JInt, required = false, default = nil)
  if valid_602955 != nil:
    section.add "Port", valid_602955
  var valid_602956 = query.getOrDefault("Version")
  valid_602956 = validateParameter(valid_602956, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_602956 != nil:
    section.add "Version", valid_602956
  var valid_602957 = query.getOrDefault("DBInstanceIdentifier")
  valid_602957 = validateParameter(valid_602957, JString, required = true,
                                 default = nil)
  if valid_602957 != nil:
    section.add "DBInstanceIdentifier", valid_602957
  var valid_602958 = query.getOrDefault("DBSnapshotIdentifier")
  valid_602958 = validateParameter(valid_602958, JString, required = true,
                                 default = nil)
  if valid_602958 != nil:
    section.add "DBSnapshotIdentifier", valid_602958
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602959 = header.getOrDefault("X-Amz-Date")
  valid_602959 = validateParameter(valid_602959, JString, required = false,
                                 default = nil)
  if valid_602959 != nil:
    section.add "X-Amz-Date", valid_602959
  var valid_602960 = header.getOrDefault("X-Amz-Security-Token")
  valid_602960 = validateParameter(valid_602960, JString, required = false,
                                 default = nil)
  if valid_602960 != nil:
    section.add "X-Amz-Security-Token", valid_602960
  var valid_602961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602961 = validateParameter(valid_602961, JString, required = false,
                                 default = nil)
  if valid_602961 != nil:
    section.add "X-Amz-Content-Sha256", valid_602961
  var valid_602962 = header.getOrDefault("X-Amz-Algorithm")
  valid_602962 = validateParameter(valid_602962, JString, required = false,
                                 default = nil)
  if valid_602962 != nil:
    section.add "X-Amz-Algorithm", valid_602962
  var valid_602963 = header.getOrDefault("X-Amz-Signature")
  valid_602963 = validateParameter(valid_602963, JString, required = false,
                                 default = nil)
  if valid_602963 != nil:
    section.add "X-Amz-Signature", valid_602963
  var valid_602964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602964 = validateParameter(valid_602964, JString, required = false,
                                 default = nil)
  if valid_602964 != nil:
    section.add "X-Amz-SignedHeaders", valid_602964
  var valid_602965 = header.getOrDefault("X-Amz-Credential")
  valid_602965 = validateParameter(valid_602965, JString, required = false,
                                 default = nil)
  if valid_602965 != nil:
    section.add "X-Amz-Credential", valid_602965
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602966: Call_GetRestoreDBInstanceFromDBSnapshot_602940;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602966.validator(path, query, header, formData, body)
  let scheme = call_602966.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602966.url(scheme.get, call_602966.host, call_602966.base,
                         call_602966.route, valid.getOrDefault("path"))
  result = hook(call_602966, url, valid)

proc call*(call_602967: Call_GetRestoreDBInstanceFromDBSnapshot_602940;
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
  var query_602968 = newJObject()
  add(query_602968, "Engine", newJString(Engine))
  add(query_602968, "OptionGroupName", newJString(OptionGroupName))
  add(query_602968, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_602968, "Iops", newJInt(Iops))
  add(query_602968, "MultiAZ", newJBool(MultiAZ))
  add(query_602968, "LicenseModel", newJString(LicenseModel))
  add(query_602968, "DBName", newJString(DBName))
  add(query_602968, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_602968, "Action", newJString(Action))
  add(query_602968, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_602968, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_602968, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_602968, "Port", newJInt(Port))
  add(query_602968, "Version", newJString(Version))
  add(query_602968, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_602968, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_602967.call(nil, query_602968, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_602940(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_602941, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_602942,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_603030 = ref object of OpenApiRestCall_600410
proc url_PostRestoreDBInstanceToPointInTime_603032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_603031(path: JsonNode;
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
  var valid_603033 = query.getOrDefault("Action")
  valid_603033 = validateParameter(valid_603033, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603033 != nil:
    section.add "Action", valid_603033
  var valid_603034 = query.getOrDefault("Version")
  valid_603034 = validateParameter(valid_603034, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603034 != nil:
    section.add "Version", valid_603034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603035 = header.getOrDefault("X-Amz-Date")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Date", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-Security-Token")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-Security-Token", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Content-Sha256", valid_603037
  var valid_603038 = header.getOrDefault("X-Amz-Algorithm")
  valid_603038 = validateParameter(valid_603038, JString, required = false,
                                 default = nil)
  if valid_603038 != nil:
    section.add "X-Amz-Algorithm", valid_603038
  var valid_603039 = header.getOrDefault("X-Amz-Signature")
  valid_603039 = validateParameter(valid_603039, JString, required = false,
                                 default = nil)
  if valid_603039 != nil:
    section.add "X-Amz-Signature", valid_603039
  var valid_603040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603040 = validateParameter(valid_603040, JString, required = false,
                                 default = nil)
  if valid_603040 != nil:
    section.add "X-Amz-SignedHeaders", valid_603040
  var valid_603041 = header.getOrDefault("X-Amz-Credential")
  valid_603041 = validateParameter(valid_603041, JString, required = false,
                                 default = nil)
  if valid_603041 != nil:
    section.add "X-Amz-Credential", valid_603041
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
  var valid_603042 = formData.getOrDefault("UseLatestRestorableTime")
  valid_603042 = validateParameter(valid_603042, JBool, required = false, default = nil)
  if valid_603042 != nil:
    section.add "UseLatestRestorableTime", valid_603042
  var valid_603043 = formData.getOrDefault("Port")
  valid_603043 = validateParameter(valid_603043, JInt, required = false, default = nil)
  if valid_603043 != nil:
    section.add "Port", valid_603043
  var valid_603044 = formData.getOrDefault("Engine")
  valid_603044 = validateParameter(valid_603044, JString, required = false,
                                 default = nil)
  if valid_603044 != nil:
    section.add "Engine", valid_603044
  var valid_603045 = formData.getOrDefault("Iops")
  valid_603045 = validateParameter(valid_603045, JInt, required = false, default = nil)
  if valid_603045 != nil:
    section.add "Iops", valid_603045
  var valid_603046 = formData.getOrDefault("DBName")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "DBName", valid_603046
  var valid_603047 = formData.getOrDefault("OptionGroupName")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "OptionGroupName", valid_603047
  var valid_603048 = formData.getOrDefault("DBSubnetGroupName")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "DBSubnetGroupName", valid_603048
  var valid_603049 = formData.getOrDefault("AvailabilityZone")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "AvailabilityZone", valid_603049
  var valid_603050 = formData.getOrDefault("MultiAZ")
  valid_603050 = validateParameter(valid_603050, JBool, required = false, default = nil)
  if valid_603050 != nil:
    section.add "MultiAZ", valid_603050
  var valid_603051 = formData.getOrDefault("RestoreTime")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "RestoreTime", valid_603051
  var valid_603052 = formData.getOrDefault("PubliclyAccessible")
  valid_603052 = validateParameter(valid_603052, JBool, required = false, default = nil)
  if valid_603052 != nil:
    section.add "PubliclyAccessible", valid_603052
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_603053 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_603053 = validateParameter(valid_603053, JString, required = true,
                                 default = nil)
  if valid_603053 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603053
  var valid_603054 = formData.getOrDefault("DBInstanceClass")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "DBInstanceClass", valid_603054
  var valid_603055 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603055 = validateParameter(valid_603055, JString, required = true,
                                 default = nil)
  if valid_603055 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603055
  var valid_603056 = formData.getOrDefault("LicenseModel")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "LicenseModel", valid_603056
  var valid_603057 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603057 = validateParameter(valid_603057, JBool, required = false, default = nil)
  if valid_603057 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603057
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_PostRestoreDBInstanceToPointInTime_603030;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"))
  result = hook(call_603058, url, valid)

proc call*(call_603059: Call_PostRestoreDBInstanceToPointInTime_603030;
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
  var query_603060 = newJObject()
  var formData_603061 = newJObject()
  add(formData_603061, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_603061, "Port", newJInt(Port))
  add(formData_603061, "Engine", newJString(Engine))
  add(formData_603061, "Iops", newJInt(Iops))
  add(formData_603061, "DBName", newJString(DBName))
  add(formData_603061, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603061, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603061, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603061, "MultiAZ", newJBool(MultiAZ))
  add(query_603060, "Action", newJString(Action))
  add(formData_603061, "RestoreTime", newJString(RestoreTime))
  add(formData_603061, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603061, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_603061, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603061, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603061, "LicenseModel", newJString(LicenseModel))
  add(formData_603061, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603060, "Version", newJString(Version))
  result = call_603059.call(nil, query_603060, nil, formData_603061, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_603030(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_603031, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_603032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_602999 = ref object of OpenApiRestCall_600410
proc url_GetRestoreDBInstanceToPointInTime_603001(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_603000(path: JsonNode;
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
  var valid_603002 = query.getOrDefault("Engine")
  valid_603002 = validateParameter(valid_603002, JString, required = false,
                                 default = nil)
  if valid_603002 != nil:
    section.add "Engine", valid_603002
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_603003 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603003 = validateParameter(valid_603003, JString, required = true,
                                 default = nil)
  if valid_603003 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603003
  var valid_603004 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_603004 = validateParameter(valid_603004, JString, required = true,
                                 default = nil)
  if valid_603004 != nil:
    section.add "TargetDBInstanceIdentifier", valid_603004
  var valid_603005 = query.getOrDefault("AvailabilityZone")
  valid_603005 = validateParameter(valid_603005, JString, required = false,
                                 default = nil)
  if valid_603005 != nil:
    section.add "AvailabilityZone", valid_603005
  var valid_603006 = query.getOrDefault("Iops")
  valid_603006 = validateParameter(valid_603006, JInt, required = false, default = nil)
  if valid_603006 != nil:
    section.add "Iops", valid_603006
  var valid_603007 = query.getOrDefault("OptionGroupName")
  valid_603007 = validateParameter(valid_603007, JString, required = false,
                                 default = nil)
  if valid_603007 != nil:
    section.add "OptionGroupName", valid_603007
  var valid_603008 = query.getOrDefault("RestoreTime")
  valid_603008 = validateParameter(valid_603008, JString, required = false,
                                 default = nil)
  if valid_603008 != nil:
    section.add "RestoreTime", valid_603008
  var valid_603009 = query.getOrDefault("MultiAZ")
  valid_603009 = validateParameter(valid_603009, JBool, required = false, default = nil)
  if valid_603009 != nil:
    section.add "MultiAZ", valid_603009
  var valid_603010 = query.getOrDefault("LicenseModel")
  valid_603010 = validateParameter(valid_603010, JString, required = false,
                                 default = nil)
  if valid_603010 != nil:
    section.add "LicenseModel", valid_603010
  var valid_603011 = query.getOrDefault("DBName")
  valid_603011 = validateParameter(valid_603011, JString, required = false,
                                 default = nil)
  if valid_603011 != nil:
    section.add "DBName", valid_603011
  var valid_603012 = query.getOrDefault("DBInstanceClass")
  valid_603012 = validateParameter(valid_603012, JString, required = false,
                                 default = nil)
  if valid_603012 != nil:
    section.add "DBInstanceClass", valid_603012
  var valid_603013 = query.getOrDefault("Action")
  valid_603013 = validateParameter(valid_603013, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_603013 != nil:
    section.add "Action", valid_603013
  var valid_603014 = query.getOrDefault("UseLatestRestorableTime")
  valid_603014 = validateParameter(valid_603014, JBool, required = false, default = nil)
  if valid_603014 != nil:
    section.add "UseLatestRestorableTime", valid_603014
  var valid_603015 = query.getOrDefault("DBSubnetGroupName")
  valid_603015 = validateParameter(valid_603015, JString, required = false,
                                 default = nil)
  if valid_603015 != nil:
    section.add "DBSubnetGroupName", valid_603015
  var valid_603016 = query.getOrDefault("PubliclyAccessible")
  valid_603016 = validateParameter(valid_603016, JBool, required = false, default = nil)
  if valid_603016 != nil:
    section.add "PubliclyAccessible", valid_603016
  var valid_603017 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603017 = validateParameter(valid_603017, JBool, required = false, default = nil)
  if valid_603017 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603017
  var valid_603018 = query.getOrDefault("Port")
  valid_603018 = validateParameter(valid_603018, JInt, required = false, default = nil)
  if valid_603018 != nil:
    section.add "Port", valid_603018
  var valid_603019 = query.getOrDefault("Version")
  valid_603019 = validateParameter(valid_603019, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603019 != nil:
    section.add "Version", valid_603019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603020 = header.getOrDefault("X-Amz-Date")
  valid_603020 = validateParameter(valid_603020, JString, required = false,
                                 default = nil)
  if valid_603020 != nil:
    section.add "X-Amz-Date", valid_603020
  var valid_603021 = header.getOrDefault("X-Amz-Security-Token")
  valid_603021 = validateParameter(valid_603021, JString, required = false,
                                 default = nil)
  if valid_603021 != nil:
    section.add "X-Amz-Security-Token", valid_603021
  var valid_603022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603022 = validateParameter(valid_603022, JString, required = false,
                                 default = nil)
  if valid_603022 != nil:
    section.add "X-Amz-Content-Sha256", valid_603022
  var valid_603023 = header.getOrDefault("X-Amz-Algorithm")
  valid_603023 = validateParameter(valid_603023, JString, required = false,
                                 default = nil)
  if valid_603023 != nil:
    section.add "X-Amz-Algorithm", valid_603023
  var valid_603024 = header.getOrDefault("X-Amz-Signature")
  valid_603024 = validateParameter(valid_603024, JString, required = false,
                                 default = nil)
  if valid_603024 != nil:
    section.add "X-Amz-Signature", valid_603024
  var valid_603025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603025 = validateParameter(valid_603025, JString, required = false,
                                 default = nil)
  if valid_603025 != nil:
    section.add "X-Amz-SignedHeaders", valid_603025
  var valid_603026 = header.getOrDefault("X-Amz-Credential")
  valid_603026 = validateParameter(valid_603026, JString, required = false,
                                 default = nil)
  if valid_603026 != nil:
    section.add "X-Amz-Credential", valid_603026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603027: Call_GetRestoreDBInstanceToPointInTime_602999;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603027.validator(path, query, header, formData, body)
  let scheme = call_603027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603027.url(scheme.get, call_603027.host, call_603027.base,
                         call_603027.route, valid.getOrDefault("path"))
  result = hook(call_603027, url, valid)

proc call*(call_603028: Call_GetRestoreDBInstanceToPointInTime_602999;
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
  var query_603029 = newJObject()
  add(query_603029, "Engine", newJString(Engine))
  add(query_603029, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603029, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_603029, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603029, "Iops", newJInt(Iops))
  add(query_603029, "OptionGroupName", newJString(OptionGroupName))
  add(query_603029, "RestoreTime", newJString(RestoreTime))
  add(query_603029, "MultiAZ", newJBool(MultiAZ))
  add(query_603029, "LicenseModel", newJString(LicenseModel))
  add(query_603029, "DBName", newJString(DBName))
  add(query_603029, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603029, "Action", newJString(Action))
  add(query_603029, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_603029, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603029, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603029, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603029, "Port", newJInt(Port))
  add(query_603029, "Version", newJString(Version))
  result = call_603028.call(nil, query_603029, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_602999(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_603000, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_603001,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_603082 = ref object of OpenApiRestCall_600410
proc url_PostRevokeDBSecurityGroupIngress_603084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_603083(path: JsonNode;
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
  var valid_603085 = query.getOrDefault("Action")
  valid_603085 = validateParameter(valid_603085, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603085 != nil:
    section.add "Action", valid_603085
  var valid_603086 = query.getOrDefault("Version")
  valid_603086 = validateParameter(valid_603086, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603086 != nil:
    section.add "Version", valid_603086
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603087 = header.getOrDefault("X-Amz-Date")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Date", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Security-Token")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Security-Token", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Content-Sha256", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Algorithm")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Algorithm", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Signature")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Signature", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-SignedHeaders", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Credential")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Credential", valid_603093
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603094 = formData.getOrDefault("DBSecurityGroupName")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = nil)
  if valid_603094 != nil:
    section.add "DBSecurityGroupName", valid_603094
  var valid_603095 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "EC2SecurityGroupName", valid_603095
  var valid_603096 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "EC2SecurityGroupId", valid_603096
  var valid_603097 = formData.getOrDefault("CIDRIP")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "CIDRIP", valid_603097
  var valid_603098 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603098 = validateParameter(valid_603098, JString, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603098
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_PostRevokeDBSecurityGroupIngress_603082;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_PostRevokeDBSecurityGroupIngress_603082;
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
  var query_603101 = newJObject()
  var formData_603102 = newJObject()
  add(formData_603102, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603101, "Action", newJString(Action))
  add(formData_603102, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603102, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603102, "CIDRIP", newJString(CIDRIP))
  add(query_603101, "Version", newJString(Version))
  add(formData_603102, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603100.call(nil, query_603101, nil, formData_603102, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_603082(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_603083, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_603084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_603062 = ref object of OpenApiRestCall_600410
proc url_GetRevokeDBSecurityGroupIngress_603064(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_603063(path: JsonNode;
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
  var valid_603065 = query.getOrDefault("EC2SecurityGroupId")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "EC2SecurityGroupId", valid_603065
  var valid_603066 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603066
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603067 = query.getOrDefault("DBSecurityGroupName")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = nil)
  if valid_603067 != nil:
    section.add "DBSecurityGroupName", valid_603067
  var valid_603068 = query.getOrDefault("Action")
  valid_603068 = validateParameter(valid_603068, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_603068 != nil:
    section.add "Action", valid_603068
  var valid_603069 = query.getOrDefault("CIDRIP")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "CIDRIP", valid_603069
  var valid_603070 = query.getOrDefault("EC2SecurityGroupName")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "EC2SecurityGroupName", valid_603070
  var valid_603071 = query.getOrDefault("Version")
  valid_603071 = validateParameter(valid_603071, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603071 != nil:
    section.add "Version", valid_603071
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603072 = header.getOrDefault("X-Amz-Date")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Date", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Security-Token")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Security-Token", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Content-Sha256", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-Algorithm")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-Algorithm", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Signature")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Signature", valid_603076
  var valid_603077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603077 = validateParameter(valid_603077, JString, required = false,
                                 default = nil)
  if valid_603077 != nil:
    section.add "X-Amz-SignedHeaders", valid_603077
  var valid_603078 = header.getOrDefault("X-Amz-Credential")
  valid_603078 = validateParameter(valid_603078, JString, required = false,
                                 default = nil)
  if valid_603078 != nil:
    section.add "X-Amz-Credential", valid_603078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603079: Call_GetRevokeDBSecurityGroupIngress_603062;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603079.validator(path, query, header, formData, body)
  let scheme = call_603079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603079.url(scheme.get, call_603079.host, call_603079.base,
                         call_603079.route, valid.getOrDefault("path"))
  result = hook(call_603079, url, valid)

proc call*(call_603080: Call_GetRevokeDBSecurityGroupIngress_603062;
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
  var query_603081 = newJObject()
  add(query_603081, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603081, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603081, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603081, "Action", newJString(Action))
  add(query_603081, "CIDRIP", newJString(CIDRIP))
  add(query_603081, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603081, "Version", newJString(Version))
  result = call_603080.call(nil, query_603081, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_603062(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_603063, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_603064,
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

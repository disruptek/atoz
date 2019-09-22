
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

  OpenApiRestCall_602417 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602417](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602417): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_603026 = ref object of OpenApiRestCall_602417
proc url_PostAddSourceIdentifierToSubscription_603028(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddSourceIdentifierToSubscription_603027(path: JsonNode;
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
  var valid_603029 = query.getOrDefault("Action")
  valid_603029 = validateParameter(valid_603029, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_603029 != nil:
    section.add "Action", valid_603029
  var valid_603030 = query.getOrDefault("Version")
  valid_603030 = validateParameter(valid_603030, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603030 != nil:
    section.add "Version", valid_603030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603031 = header.getOrDefault("X-Amz-Date")
  valid_603031 = validateParameter(valid_603031, JString, required = false,
                                 default = nil)
  if valid_603031 != nil:
    section.add "X-Amz-Date", valid_603031
  var valid_603032 = header.getOrDefault("X-Amz-Security-Token")
  valid_603032 = validateParameter(valid_603032, JString, required = false,
                                 default = nil)
  if valid_603032 != nil:
    section.add "X-Amz-Security-Token", valid_603032
  var valid_603033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603033 = validateParameter(valid_603033, JString, required = false,
                                 default = nil)
  if valid_603033 != nil:
    section.add "X-Amz-Content-Sha256", valid_603033
  var valid_603034 = header.getOrDefault("X-Amz-Algorithm")
  valid_603034 = validateParameter(valid_603034, JString, required = false,
                                 default = nil)
  if valid_603034 != nil:
    section.add "X-Amz-Algorithm", valid_603034
  var valid_603035 = header.getOrDefault("X-Amz-Signature")
  valid_603035 = validateParameter(valid_603035, JString, required = false,
                                 default = nil)
  if valid_603035 != nil:
    section.add "X-Amz-Signature", valid_603035
  var valid_603036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603036 = validateParameter(valid_603036, JString, required = false,
                                 default = nil)
  if valid_603036 != nil:
    section.add "X-Amz-SignedHeaders", valid_603036
  var valid_603037 = header.getOrDefault("X-Amz-Credential")
  valid_603037 = validateParameter(valid_603037, JString, required = false,
                                 default = nil)
  if valid_603037 != nil:
    section.add "X-Amz-Credential", valid_603037
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_603038 = formData.getOrDefault("SourceIdentifier")
  valid_603038 = validateParameter(valid_603038, JString, required = true,
                                 default = nil)
  if valid_603038 != nil:
    section.add "SourceIdentifier", valid_603038
  var valid_603039 = formData.getOrDefault("SubscriptionName")
  valid_603039 = validateParameter(valid_603039, JString, required = true,
                                 default = nil)
  if valid_603039 != nil:
    section.add "SubscriptionName", valid_603039
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603040: Call_PostAddSourceIdentifierToSubscription_603026;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603040.validator(path, query, header, formData, body)
  let scheme = call_603040.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603040.url(scheme.get, call_603040.host, call_603040.base,
                         call_603040.route, valid.getOrDefault("path"))
  result = hook(call_603040, url, valid)

proc call*(call_603041: Call_PostAddSourceIdentifierToSubscription_603026;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603042 = newJObject()
  var formData_603043 = newJObject()
  add(formData_603043, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603043, "SubscriptionName", newJString(SubscriptionName))
  add(query_603042, "Action", newJString(Action))
  add(query_603042, "Version", newJString(Version))
  result = call_603041.call(nil, query_603042, nil, formData_603043, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_603026(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_603027, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_603028,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_602754 = ref object of OpenApiRestCall_602417
proc url_GetAddSourceIdentifierToSubscription_602756(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddSourceIdentifierToSubscription_602755(path: JsonNode;
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
  var valid_602881 = query.getOrDefault("Action")
  valid_602881 = validateParameter(valid_602881, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_602881 != nil:
    section.add "Action", valid_602881
  var valid_602882 = query.getOrDefault("SourceIdentifier")
  valid_602882 = validateParameter(valid_602882, JString, required = true,
                                 default = nil)
  if valid_602882 != nil:
    section.add "SourceIdentifier", valid_602882
  var valid_602883 = query.getOrDefault("SubscriptionName")
  valid_602883 = validateParameter(valid_602883, JString, required = true,
                                 default = nil)
  if valid_602883 != nil:
    section.add "SubscriptionName", valid_602883
  var valid_602884 = query.getOrDefault("Version")
  valid_602884 = validateParameter(valid_602884, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_602884 != nil:
    section.add "Version", valid_602884
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_602885 = header.getOrDefault("X-Amz-Date")
  valid_602885 = validateParameter(valid_602885, JString, required = false,
                                 default = nil)
  if valid_602885 != nil:
    section.add "X-Amz-Date", valid_602885
  var valid_602886 = header.getOrDefault("X-Amz-Security-Token")
  valid_602886 = validateParameter(valid_602886, JString, required = false,
                                 default = nil)
  if valid_602886 != nil:
    section.add "X-Amz-Security-Token", valid_602886
  var valid_602887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602887 = validateParameter(valid_602887, JString, required = false,
                                 default = nil)
  if valid_602887 != nil:
    section.add "X-Amz-Content-Sha256", valid_602887
  var valid_602888 = header.getOrDefault("X-Amz-Algorithm")
  valid_602888 = validateParameter(valid_602888, JString, required = false,
                                 default = nil)
  if valid_602888 != nil:
    section.add "X-Amz-Algorithm", valid_602888
  var valid_602889 = header.getOrDefault("X-Amz-Signature")
  valid_602889 = validateParameter(valid_602889, JString, required = false,
                                 default = nil)
  if valid_602889 != nil:
    section.add "X-Amz-Signature", valid_602889
  var valid_602890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602890 = validateParameter(valid_602890, JString, required = false,
                                 default = nil)
  if valid_602890 != nil:
    section.add "X-Amz-SignedHeaders", valid_602890
  var valid_602891 = header.getOrDefault("X-Amz-Credential")
  valid_602891 = validateParameter(valid_602891, JString, required = false,
                                 default = nil)
  if valid_602891 != nil:
    section.add "X-Amz-Credential", valid_602891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602914: Call_GetAddSourceIdentifierToSubscription_602754;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602914.validator(path, query, header, formData, body)
  let scheme = call_602914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602914.url(scheme.get, call_602914.host, call_602914.base,
                         call_602914.route, valid.getOrDefault("path"))
  result = hook(call_602914, url, valid)

proc call*(call_602985: Call_GetAddSourceIdentifierToSubscription_602754;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_602986 = newJObject()
  add(query_602986, "Action", newJString(Action))
  add(query_602986, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_602986, "SubscriptionName", newJString(SubscriptionName))
  add(query_602986, "Version", newJString(Version))
  result = call_602985.call(nil, query_602986, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_602754(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_602755, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_602756,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_603061 = ref object of OpenApiRestCall_602417
proc url_PostAddTagsToResource_603063(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAddTagsToResource_603062(path: JsonNode; query: JsonNode;
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
  var valid_603064 = query.getOrDefault("Action")
  valid_603064 = validateParameter(valid_603064, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_603064 != nil:
    section.add "Action", valid_603064
  var valid_603065 = query.getOrDefault("Version")
  valid_603065 = validateParameter(valid_603065, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603065 != nil:
    section.add "Version", valid_603065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603066 = header.getOrDefault("X-Amz-Date")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Date", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Security-Token")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Security-Token", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Content-Sha256", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-Algorithm")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-Algorithm", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Signature")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Signature", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-SignedHeaders", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Credential")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Credential", valid_603072
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_603073 = formData.getOrDefault("Tags")
  valid_603073 = validateParameter(valid_603073, JArray, required = true, default = nil)
  if valid_603073 != nil:
    section.add "Tags", valid_603073
  var valid_603074 = formData.getOrDefault("ResourceName")
  valid_603074 = validateParameter(valid_603074, JString, required = true,
                                 default = nil)
  if valid_603074 != nil:
    section.add "ResourceName", valid_603074
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603075: Call_PostAddTagsToResource_603061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603075.validator(path, query, header, formData, body)
  let scheme = call_603075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603075.url(scheme.get, call_603075.host, call_603075.base,
                         call_603075.route, valid.getOrDefault("path"))
  result = hook(call_603075, url, valid)

proc call*(call_603076: Call_PostAddTagsToResource_603061; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_603077 = newJObject()
  var formData_603078 = newJObject()
  if Tags != nil:
    formData_603078.add "Tags", Tags
  add(query_603077, "Action", newJString(Action))
  add(formData_603078, "ResourceName", newJString(ResourceName))
  add(query_603077, "Version", newJString(Version))
  result = call_603076.call(nil, query_603077, nil, formData_603078, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_603061(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_603062, base: "/",
    url: url_PostAddTagsToResource_603063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_603044 = ref object of OpenApiRestCall_602417
proc url_GetAddTagsToResource_603046(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAddTagsToResource_603045(path: JsonNode; query: JsonNode;
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
  var valid_603047 = query.getOrDefault("Tags")
  valid_603047 = validateParameter(valid_603047, JArray, required = true, default = nil)
  if valid_603047 != nil:
    section.add "Tags", valid_603047
  var valid_603048 = query.getOrDefault("ResourceName")
  valid_603048 = validateParameter(valid_603048, JString, required = true,
                                 default = nil)
  if valid_603048 != nil:
    section.add "ResourceName", valid_603048
  var valid_603049 = query.getOrDefault("Action")
  valid_603049 = validateParameter(valid_603049, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_603049 != nil:
    section.add "Action", valid_603049
  var valid_603050 = query.getOrDefault("Version")
  valid_603050 = validateParameter(valid_603050, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603050 != nil:
    section.add "Version", valid_603050
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603051 = header.getOrDefault("X-Amz-Date")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-Date", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Security-Token")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Security-Token", valid_603052
  var valid_603053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603053 = validateParameter(valid_603053, JString, required = false,
                                 default = nil)
  if valid_603053 != nil:
    section.add "X-Amz-Content-Sha256", valid_603053
  var valid_603054 = header.getOrDefault("X-Amz-Algorithm")
  valid_603054 = validateParameter(valid_603054, JString, required = false,
                                 default = nil)
  if valid_603054 != nil:
    section.add "X-Amz-Algorithm", valid_603054
  var valid_603055 = header.getOrDefault("X-Amz-Signature")
  valid_603055 = validateParameter(valid_603055, JString, required = false,
                                 default = nil)
  if valid_603055 != nil:
    section.add "X-Amz-Signature", valid_603055
  var valid_603056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603056 = validateParameter(valid_603056, JString, required = false,
                                 default = nil)
  if valid_603056 != nil:
    section.add "X-Amz-SignedHeaders", valid_603056
  var valid_603057 = header.getOrDefault("X-Amz-Credential")
  valid_603057 = validateParameter(valid_603057, JString, required = false,
                                 default = nil)
  if valid_603057 != nil:
    section.add "X-Amz-Credential", valid_603057
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603058: Call_GetAddTagsToResource_603044; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603058.validator(path, query, header, formData, body)
  let scheme = call_603058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603058.url(scheme.get, call_603058.host, call_603058.base,
                         call_603058.route, valid.getOrDefault("path"))
  result = hook(call_603058, url, valid)

proc call*(call_603059: Call_GetAddTagsToResource_603044; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2014-09-01"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603060 = newJObject()
  if Tags != nil:
    query_603060.add "Tags", Tags
  add(query_603060, "ResourceName", newJString(ResourceName))
  add(query_603060, "Action", newJString(Action))
  add(query_603060, "Version", newJString(Version))
  result = call_603059.call(nil, query_603060, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_603044(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_603045, base: "/",
    url: url_GetAddTagsToResource_603046, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_603099 = ref object of OpenApiRestCall_602417
proc url_PostAuthorizeDBSecurityGroupIngress_603101(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_603100(path: JsonNode;
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
  var valid_603102 = query.getOrDefault("Action")
  valid_603102 = validateParameter(valid_603102, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_603102 != nil:
    section.add "Action", valid_603102
  var valid_603103 = query.getOrDefault("Version")
  valid_603103 = validateParameter(valid_603103, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603103 != nil:
    section.add "Version", valid_603103
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603104 = header.getOrDefault("X-Amz-Date")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-Date", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Security-Token")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Security-Token", valid_603105
  var valid_603106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603106 = validateParameter(valid_603106, JString, required = false,
                                 default = nil)
  if valid_603106 != nil:
    section.add "X-Amz-Content-Sha256", valid_603106
  var valid_603107 = header.getOrDefault("X-Amz-Algorithm")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "X-Amz-Algorithm", valid_603107
  var valid_603108 = header.getOrDefault("X-Amz-Signature")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "X-Amz-Signature", valid_603108
  var valid_603109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603109 = validateParameter(valid_603109, JString, required = false,
                                 default = nil)
  if valid_603109 != nil:
    section.add "X-Amz-SignedHeaders", valid_603109
  var valid_603110 = header.getOrDefault("X-Amz-Credential")
  valid_603110 = validateParameter(valid_603110, JString, required = false,
                                 default = nil)
  if valid_603110 != nil:
    section.add "X-Amz-Credential", valid_603110
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603111 = formData.getOrDefault("DBSecurityGroupName")
  valid_603111 = validateParameter(valid_603111, JString, required = true,
                                 default = nil)
  if valid_603111 != nil:
    section.add "DBSecurityGroupName", valid_603111
  var valid_603112 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "EC2SecurityGroupName", valid_603112
  var valid_603113 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "EC2SecurityGroupId", valid_603113
  var valid_603114 = formData.getOrDefault("CIDRIP")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "CIDRIP", valid_603114
  var valid_603115 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603116: Call_PostAuthorizeDBSecurityGroupIngress_603099;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603116.validator(path, query, header, formData, body)
  let scheme = call_603116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603116.url(scheme.get, call_603116.host, call_603116.base,
                         call_603116.route, valid.getOrDefault("path"))
  result = hook(call_603116, url, valid)

proc call*(call_603117: Call_PostAuthorizeDBSecurityGroupIngress_603099;
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
  var query_603118 = newJObject()
  var formData_603119 = newJObject()
  add(formData_603119, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603118, "Action", newJString(Action))
  add(formData_603119, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603119, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603119, "CIDRIP", newJString(CIDRIP))
  add(query_603118, "Version", newJString(Version))
  add(formData_603119, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603117.call(nil, query_603118, nil, formData_603119, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_603099(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_603100, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_603101,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_603079 = ref object of OpenApiRestCall_602417
proc url_GetAuthorizeDBSecurityGroupIngress_603081(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_603080(path: JsonNode;
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
  var valid_603082 = query.getOrDefault("EC2SecurityGroupId")
  valid_603082 = validateParameter(valid_603082, JString, required = false,
                                 default = nil)
  if valid_603082 != nil:
    section.add "EC2SecurityGroupId", valid_603082
  var valid_603083 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603083 = validateParameter(valid_603083, JString, required = false,
                                 default = nil)
  if valid_603083 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603083
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603084 = query.getOrDefault("DBSecurityGroupName")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = nil)
  if valid_603084 != nil:
    section.add "DBSecurityGroupName", valid_603084
  var valid_603085 = query.getOrDefault("Action")
  valid_603085 = validateParameter(valid_603085, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_603085 != nil:
    section.add "Action", valid_603085
  var valid_603086 = query.getOrDefault("CIDRIP")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "CIDRIP", valid_603086
  var valid_603087 = query.getOrDefault("EC2SecurityGroupName")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "EC2SecurityGroupName", valid_603087
  var valid_603088 = query.getOrDefault("Version")
  valid_603088 = validateParameter(valid_603088, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603088 != nil:
    section.add "Version", valid_603088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603089 = header.getOrDefault("X-Amz-Date")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Date", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Security-Token")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Security-Token", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Content-Sha256", valid_603091
  var valid_603092 = header.getOrDefault("X-Amz-Algorithm")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "X-Amz-Algorithm", valid_603092
  var valid_603093 = header.getOrDefault("X-Amz-Signature")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "X-Amz-Signature", valid_603093
  var valid_603094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603094 = validateParameter(valid_603094, JString, required = false,
                                 default = nil)
  if valid_603094 != nil:
    section.add "X-Amz-SignedHeaders", valid_603094
  var valid_603095 = header.getOrDefault("X-Amz-Credential")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "X-Amz-Credential", valid_603095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603096: Call_GetAuthorizeDBSecurityGroupIngress_603079;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603096.validator(path, query, header, formData, body)
  let scheme = call_603096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603096.url(scheme.get, call_603096.host, call_603096.base,
                         call_603096.route, valid.getOrDefault("path"))
  result = hook(call_603096, url, valid)

proc call*(call_603097: Call_GetAuthorizeDBSecurityGroupIngress_603079;
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
  var query_603098 = newJObject()
  add(query_603098, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603098, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603098, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603098, "Action", newJString(Action))
  add(query_603098, "CIDRIP", newJString(CIDRIP))
  add(query_603098, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603098, "Version", newJString(Version))
  result = call_603097.call(nil, query_603098, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_603079(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_603080, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_603081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBParameterGroup_603139 = ref object of OpenApiRestCall_602417
proc url_PostCopyDBParameterGroup_603141(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBParameterGroup_603140(path: JsonNode; query: JsonNode;
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
  var valid_603142 = query.getOrDefault("Action")
  valid_603142 = validateParameter(valid_603142, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_603142 != nil:
    section.add "Action", valid_603142
  var valid_603143 = query.getOrDefault("Version")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603143 != nil:
    section.add "Version", valid_603143
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603144 = header.getOrDefault("X-Amz-Date")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Date", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Security-Token")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Security-Token", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Content-Sha256", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Algorithm")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Algorithm", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Signature")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Signature", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-SignedHeaders", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Credential")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Credential", valid_603150
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   SourceDBParameterGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_603151 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_603151 = validateParameter(valid_603151, JString, required = true,
                                 default = nil)
  if valid_603151 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_603151
  var valid_603152 = formData.getOrDefault("Tags")
  valid_603152 = validateParameter(valid_603152, JArray, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "Tags", valid_603152
  var valid_603153 = formData.getOrDefault("TargetDBParameterGroupDescription")
  valid_603153 = validateParameter(valid_603153, JString, required = true,
                                 default = nil)
  if valid_603153 != nil:
    section.add "TargetDBParameterGroupDescription", valid_603153
  var valid_603154 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_603154 = validateParameter(valid_603154, JString, required = true,
                                 default = nil)
  if valid_603154 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_603154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603155: Call_PostCopyDBParameterGroup_603139; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603155.validator(path, query, header, formData, body)
  let scheme = call_603155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603155.url(scheme.get, call_603155.host, call_603155.base,
                         call_603155.route, valid.getOrDefault("path"))
  result = hook(call_603155, url, valid)

proc call*(call_603156: Call_PostCopyDBParameterGroup_603139;
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
  var query_603157 = newJObject()
  var formData_603158 = newJObject()
  add(formData_603158, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  if Tags != nil:
    formData_603158.add "Tags", Tags
  add(query_603157, "Action", newJString(Action))
  add(formData_603158, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(formData_603158, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_603157, "Version", newJString(Version))
  result = call_603156.call(nil, query_603157, nil, formData_603158, nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_603139(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_603140, base: "/",
    url: url_PostCopyDBParameterGroup_603141, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_603120 = ref object of OpenApiRestCall_602417
proc url_GetCopyDBParameterGroup_603122(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBParameterGroup_603121(path: JsonNode; query: JsonNode;
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
  var valid_603123 = query.getOrDefault("Tags")
  valid_603123 = validateParameter(valid_603123, JArray, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "Tags", valid_603123
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603124 = query.getOrDefault("Action")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = newJString("CopyDBParameterGroup"))
  if valid_603124 != nil:
    section.add "Action", valid_603124
  var valid_603125 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_603125
  var valid_603126 = query.getOrDefault("Version")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603126 != nil:
    section.add "Version", valid_603126
  var valid_603127 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_603127 = validateParameter(valid_603127, JString, required = true,
                                 default = nil)
  if valid_603127 != nil:
    section.add "TargetDBParameterGroupDescription", valid_603127
  var valid_603128 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_603128 = validateParameter(valid_603128, JString, required = true,
                                 default = nil)
  if valid_603128 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_603128
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603129 = header.getOrDefault("X-Amz-Date")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Date", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Security-Token")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Security-Token", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Content-Sha256", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Algorithm")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Algorithm", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Signature")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Signature", valid_603133
  var valid_603134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "X-Amz-SignedHeaders", valid_603134
  var valid_603135 = header.getOrDefault("X-Amz-Credential")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "X-Amz-Credential", valid_603135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603136: Call_GetCopyDBParameterGroup_603120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603136.validator(path, query, header, formData, body)
  let scheme = call_603136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603136.url(scheme.get, call_603136.host, call_603136.base,
                         call_603136.route, valid.getOrDefault("path"))
  result = hook(call_603136, url, valid)

proc call*(call_603137: Call_GetCopyDBParameterGroup_603120;
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
  var query_603138 = newJObject()
  if Tags != nil:
    query_603138.add "Tags", Tags
  add(query_603138, "Action", newJString(Action))
  add(query_603138, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_603138, "Version", newJString(Version))
  add(query_603138, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  add(query_603138, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  result = call_603137.call(nil, query_603138, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_603120(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_603121, base: "/",
    url: url_GetCopyDBParameterGroup_603122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_603177 = ref object of OpenApiRestCall_602417
proc url_PostCopyDBSnapshot_603179(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_603178(path: JsonNode; query: JsonNode;
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
  var valid_603180 = query.getOrDefault("Action")
  valid_603180 = validateParameter(valid_603180, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603180 != nil:
    section.add "Action", valid_603180
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
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603189 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603189 = validateParameter(valid_603189, JString, required = true,
                                 default = nil)
  if valid_603189 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603189
  var valid_603190 = formData.getOrDefault("Tags")
  valid_603190 = validateParameter(valid_603190, JArray, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "Tags", valid_603190
  var valid_603191 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = nil)
  if valid_603191 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603191
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603192: Call_PostCopyDBSnapshot_603177; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603192.validator(path, query, header, formData, body)
  let scheme = call_603192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603192.url(scheme.get, call_603192.host, call_603192.base,
                         call_603192.route, valid.getOrDefault("path"))
  result = hook(call_603192, url, valid)

proc call*(call_603193: Call_PostCopyDBSnapshot_603177;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603194 = newJObject()
  var formData_603195 = newJObject()
  add(formData_603195, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_603195.add "Tags", Tags
  add(query_603194, "Action", newJString(Action))
  add(formData_603195, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603194, "Version", newJString(Version))
  result = call_603193.call(nil, query_603194, nil, formData_603195, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_603177(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_603178, base: "/",
    url: url_PostCopyDBSnapshot_603179, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_603159 = ref object of OpenApiRestCall_602417
proc url_GetCopyDBSnapshot_603161(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBSnapshot_603160(path: JsonNode; query: JsonNode;
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
  var valid_603162 = query.getOrDefault("Tags")
  valid_603162 = validateParameter(valid_603162, JArray, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "Tags", valid_603162
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603163 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603163
  var valid_603164 = query.getOrDefault("Action")
  valid_603164 = validateParameter(valid_603164, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603164 != nil:
    section.add "Action", valid_603164
  var valid_603165 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603165 = validateParameter(valid_603165, JString, required = true,
                                 default = nil)
  if valid_603165 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603165
  var valid_603166 = query.getOrDefault("Version")
  valid_603166 = validateParameter(valid_603166, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603166 != nil:
    section.add "Version", valid_603166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603167 = header.getOrDefault("X-Amz-Date")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Date", valid_603167
  var valid_603168 = header.getOrDefault("X-Amz-Security-Token")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "X-Amz-Security-Token", valid_603168
  var valid_603169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603169 = validateParameter(valid_603169, JString, required = false,
                                 default = nil)
  if valid_603169 != nil:
    section.add "X-Amz-Content-Sha256", valid_603169
  var valid_603170 = header.getOrDefault("X-Amz-Algorithm")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "X-Amz-Algorithm", valid_603170
  var valid_603171 = header.getOrDefault("X-Amz-Signature")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "X-Amz-Signature", valid_603171
  var valid_603172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "X-Amz-SignedHeaders", valid_603172
  var valid_603173 = header.getOrDefault("X-Amz-Credential")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "X-Amz-Credential", valid_603173
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603174: Call_GetCopyDBSnapshot_603159; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603174.validator(path, query, header, formData, body)
  let scheme = call_603174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603174.url(scheme.get, call_603174.host, call_603174.base,
                         call_603174.route, valid.getOrDefault("path"))
  result = hook(call_603174, url, valid)

proc call*(call_603175: Call_GetCopyDBSnapshot_603159;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603176 = newJObject()
  if Tags != nil:
    query_603176.add "Tags", Tags
  add(query_603176, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603176, "Action", newJString(Action))
  add(query_603176, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603176, "Version", newJString(Version))
  result = call_603175.call(nil, query_603176, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_603159(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_603160,
    base: "/", url: url_GetCopyDBSnapshot_603161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_603215 = ref object of OpenApiRestCall_602417
proc url_PostCopyOptionGroup_603217(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyOptionGroup_603216(path: JsonNode; query: JsonNode;
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
  var valid_603218 = query.getOrDefault("Action")
  valid_603218 = validateParameter(valid_603218, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_603218 != nil:
    section.add "Action", valid_603218
  var valid_603219 = query.getOrDefault("Version")
  valid_603219 = validateParameter(valid_603219, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603219 != nil:
    section.add "Version", valid_603219
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603220 = header.getOrDefault("X-Amz-Date")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Date", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Security-Token")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Security-Token", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-Content-Sha256", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Algorithm")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Algorithm", valid_603223
  var valid_603224 = header.getOrDefault("X-Amz-Signature")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "X-Amz-Signature", valid_603224
  var valid_603225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "X-Amz-SignedHeaders", valid_603225
  var valid_603226 = header.getOrDefault("X-Amz-Credential")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "X-Amz-Credential", valid_603226
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupDescription: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   TargetOptionGroupIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupDescription` field"
  var valid_603227 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = nil)
  if valid_603227 != nil:
    section.add "TargetOptionGroupDescription", valid_603227
  var valid_603228 = formData.getOrDefault("Tags")
  valid_603228 = validateParameter(valid_603228, JArray, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "Tags", valid_603228
  var valid_603229 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_603229 = validateParameter(valid_603229, JString, required = true,
                                 default = nil)
  if valid_603229 != nil:
    section.add "SourceOptionGroupIdentifier", valid_603229
  var valid_603230 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_603230 = validateParameter(valid_603230, JString, required = true,
                                 default = nil)
  if valid_603230 != nil:
    section.add "TargetOptionGroupIdentifier", valid_603230
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603231: Call_PostCopyOptionGroup_603215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603231.validator(path, query, header, formData, body)
  let scheme = call_603231.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603231.url(scheme.get, call_603231.host, call_603231.base,
                         call_603231.route, valid.getOrDefault("path"))
  result = hook(call_603231, url, valid)

proc call*(call_603232: Call_PostCopyOptionGroup_603215;
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
  var query_603233 = newJObject()
  var formData_603234 = newJObject()
  add(formData_603234, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  if Tags != nil:
    formData_603234.add "Tags", Tags
  add(formData_603234, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_603233, "Action", newJString(Action))
  add(formData_603234, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_603233, "Version", newJString(Version))
  result = call_603232.call(nil, query_603233, nil, formData_603234, nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_603215(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_603216, base: "/",
    url: url_PostCopyOptionGroup_603217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_603196 = ref object of OpenApiRestCall_602417
proc url_GetCopyOptionGroup_603198(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyOptionGroup_603197(path: JsonNode; query: JsonNode;
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
  var valid_603199 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_603199 = validateParameter(valid_603199, JString, required = true,
                                 default = nil)
  if valid_603199 != nil:
    section.add "SourceOptionGroupIdentifier", valid_603199
  var valid_603200 = query.getOrDefault("Tags")
  valid_603200 = validateParameter(valid_603200, JArray, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "Tags", valid_603200
  var valid_603201 = query.getOrDefault("Action")
  valid_603201 = validateParameter(valid_603201, JString, required = true,
                                 default = newJString("CopyOptionGroup"))
  if valid_603201 != nil:
    section.add "Action", valid_603201
  var valid_603202 = query.getOrDefault("TargetOptionGroupDescription")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = nil)
  if valid_603202 != nil:
    section.add "TargetOptionGroupDescription", valid_603202
  var valid_603203 = query.getOrDefault("Version")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603203 != nil:
    section.add "Version", valid_603203
  var valid_603204 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_603204 = validateParameter(valid_603204, JString, required = true,
                                 default = nil)
  if valid_603204 != nil:
    section.add "TargetOptionGroupIdentifier", valid_603204
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603205 = header.getOrDefault("X-Amz-Date")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Date", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Security-Token")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Security-Token", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-Content-Sha256", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Algorithm")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Algorithm", valid_603208
  var valid_603209 = header.getOrDefault("X-Amz-Signature")
  valid_603209 = validateParameter(valid_603209, JString, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "X-Amz-Signature", valid_603209
  var valid_603210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603210 = validateParameter(valid_603210, JString, required = false,
                                 default = nil)
  if valid_603210 != nil:
    section.add "X-Amz-SignedHeaders", valid_603210
  var valid_603211 = header.getOrDefault("X-Amz-Credential")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "X-Amz-Credential", valid_603211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603212: Call_GetCopyOptionGroup_603196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603212.validator(path, query, header, formData, body)
  let scheme = call_603212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603212.url(scheme.get, call_603212.host, call_603212.base,
                         call_603212.route, valid.getOrDefault("path"))
  result = hook(call_603212, url, valid)

proc call*(call_603213: Call_GetCopyOptionGroup_603196;
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
  var query_603214 = newJObject()
  add(query_603214, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  if Tags != nil:
    query_603214.add "Tags", Tags
  add(query_603214, "Action", newJString(Action))
  add(query_603214, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  add(query_603214, "Version", newJString(Version))
  add(query_603214, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  result = call_603213.call(nil, query_603214, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_603196(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyOptionGroup", validator: validate_GetCopyOptionGroup_603197,
    base: "/", url: url_GetCopyOptionGroup_603198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603278 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBInstance_603280(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_603279(path: JsonNode; query: JsonNode;
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
  var valid_603281 = query.getOrDefault("Action")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603281 != nil:
    section.add "Action", valid_603281
  var valid_603282 = query.getOrDefault("Version")
  valid_603282 = validateParameter(valid_603282, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603282 != nil:
    section.add "Version", valid_603282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603283 = header.getOrDefault("X-Amz-Date")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Date", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Security-Token")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Security-Token", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Content-Sha256", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Algorithm")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Algorithm", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Signature")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Signature", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-SignedHeaders", valid_603288
  var valid_603289 = header.getOrDefault("X-Amz-Credential")
  valid_603289 = validateParameter(valid_603289, JString, required = false,
                                 default = nil)
  if valid_603289 != nil:
    section.add "X-Amz-Credential", valid_603289
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
  var valid_603290 = formData.getOrDefault("DBSecurityGroups")
  valid_603290 = validateParameter(valid_603290, JArray, required = false,
                                 default = nil)
  if valid_603290 != nil:
    section.add "DBSecurityGroups", valid_603290
  var valid_603291 = formData.getOrDefault("Port")
  valid_603291 = validateParameter(valid_603291, JInt, required = false, default = nil)
  if valid_603291 != nil:
    section.add "Port", valid_603291
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603292 = formData.getOrDefault("Engine")
  valid_603292 = validateParameter(valid_603292, JString, required = true,
                                 default = nil)
  if valid_603292 != nil:
    section.add "Engine", valid_603292
  var valid_603293 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603293 = validateParameter(valid_603293, JArray, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "VpcSecurityGroupIds", valid_603293
  var valid_603294 = formData.getOrDefault("Iops")
  valid_603294 = validateParameter(valid_603294, JInt, required = false, default = nil)
  if valid_603294 != nil:
    section.add "Iops", valid_603294
  var valid_603295 = formData.getOrDefault("DBName")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "DBName", valid_603295
  var valid_603296 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603296 = validateParameter(valid_603296, JString, required = true,
                                 default = nil)
  if valid_603296 != nil:
    section.add "DBInstanceIdentifier", valid_603296
  var valid_603297 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603297 = validateParameter(valid_603297, JInt, required = false, default = nil)
  if valid_603297 != nil:
    section.add "BackupRetentionPeriod", valid_603297
  var valid_603298 = formData.getOrDefault("DBParameterGroupName")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "DBParameterGroupName", valid_603298
  var valid_603299 = formData.getOrDefault("OptionGroupName")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "OptionGroupName", valid_603299
  var valid_603300 = formData.getOrDefault("Tags")
  valid_603300 = validateParameter(valid_603300, JArray, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "Tags", valid_603300
  var valid_603301 = formData.getOrDefault("MasterUserPassword")
  valid_603301 = validateParameter(valid_603301, JString, required = true,
                                 default = nil)
  if valid_603301 != nil:
    section.add "MasterUserPassword", valid_603301
  var valid_603302 = formData.getOrDefault("TdeCredentialArn")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "TdeCredentialArn", valid_603302
  var valid_603303 = formData.getOrDefault("DBSubnetGroupName")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "DBSubnetGroupName", valid_603303
  var valid_603304 = formData.getOrDefault("TdeCredentialPassword")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "TdeCredentialPassword", valid_603304
  var valid_603305 = formData.getOrDefault("AvailabilityZone")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "AvailabilityZone", valid_603305
  var valid_603306 = formData.getOrDefault("MultiAZ")
  valid_603306 = validateParameter(valid_603306, JBool, required = false, default = nil)
  if valid_603306 != nil:
    section.add "MultiAZ", valid_603306
  var valid_603307 = formData.getOrDefault("AllocatedStorage")
  valid_603307 = validateParameter(valid_603307, JInt, required = true, default = nil)
  if valid_603307 != nil:
    section.add "AllocatedStorage", valid_603307
  var valid_603308 = formData.getOrDefault("PubliclyAccessible")
  valid_603308 = validateParameter(valid_603308, JBool, required = false, default = nil)
  if valid_603308 != nil:
    section.add "PubliclyAccessible", valid_603308
  var valid_603309 = formData.getOrDefault("MasterUsername")
  valid_603309 = validateParameter(valid_603309, JString, required = true,
                                 default = nil)
  if valid_603309 != nil:
    section.add "MasterUsername", valid_603309
  var valid_603310 = formData.getOrDefault("StorageType")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "StorageType", valid_603310
  var valid_603311 = formData.getOrDefault("DBInstanceClass")
  valid_603311 = validateParameter(valid_603311, JString, required = true,
                                 default = nil)
  if valid_603311 != nil:
    section.add "DBInstanceClass", valid_603311
  var valid_603312 = formData.getOrDefault("CharacterSetName")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "CharacterSetName", valid_603312
  var valid_603313 = formData.getOrDefault("PreferredBackupWindow")
  valid_603313 = validateParameter(valid_603313, JString, required = false,
                                 default = nil)
  if valid_603313 != nil:
    section.add "PreferredBackupWindow", valid_603313
  var valid_603314 = formData.getOrDefault("LicenseModel")
  valid_603314 = validateParameter(valid_603314, JString, required = false,
                                 default = nil)
  if valid_603314 != nil:
    section.add "LicenseModel", valid_603314
  var valid_603315 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603315 = validateParameter(valid_603315, JBool, required = false, default = nil)
  if valid_603315 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603315
  var valid_603316 = formData.getOrDefault("EngineVersion")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "EngineVersion", valid_603316
  var valid_603317 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "PreferredMaintenanceWindow", valid_603317
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603318: Call_PostCreateDBInstance_603278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603318.validator(path, query, header, formData, body)
  let scheme = call_603318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603318.url(scheme.get, call_603318.host, call_603318.base,
                         call_603318.route, valid.getOrDefault("path"))
  result = hook(call_603318, url, valid)

proc call*(call_603319: Call_PostCreateDBInstance_603278; Engine: string;
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
  var query_603320 = newJObject()
  var formData_603321 = newJObject()
  if DBSecurityGroups != nil:
    formData_603321.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603321, "Port", newJInt(Port))
  add(formData_603321, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_603321.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603321, "Iops", newJInt(Iops))
  add(formData_603321, "DBName", newJString(DBName))
  add(formData_603321, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603321, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603321, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603321, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603321.add "Tags", Tags
  add(formData_603321, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603321, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_603321, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603321, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_603321, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603321, "MultiAZ", newJBool(MultiAZ))
  add(query_603320, "Action", newJString(Action))
  add(formData_603321, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_603321, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603321, "MasterUsername", newJString(MasterUsername))
  add(formData_603321, "StorageType", newJString(StorageType))
  add(formData_603321, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603321, "CharacterSetName", newJString(CharacterSetName))
  add(formData_603321, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603321, "LicenseModel", newJString(LicenseModel))
  add(formData_603321, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603321, "EngineVersion", newJString(EngineVersion))
  add(query_603320, "Version", newJString(Version))
  add(formData_603321, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603319.call(nil, query_603320, nil, formData_603321, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603278(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603279, base: "/",
    url: url_PostCreateDBInstance_603280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603235 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBInstance_603237(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_603236(path: JsonNode; query: JsonNode;
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
  var valid_603238 = query.getOrDefault("Engine")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = nil)
  if valid_603238 != nil:
    section.add "Engine", valid_603238
  var valid_603239 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "PreferredMaintenanceWindow", valid_603239
  var valid_603240 = query.getOrDefault("AllocatedStorage")
  valid_603240 = validateParameter(valid_603240, JInt, required = true, default = nil)
  if valid_603240 != nil:
    section.add "AllocatedStorage", valid_603240
  var valid_603241 = query.getOrDefault("StorageType")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "StorageType", valid_603241
  var valid_603242 = query.getOrDefault("OptionGroupName")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "OptionGroupName", valid_603242
  var valid_603243 = query.getOrDefault("DBSecurityGroups")
  valid_603243 = validateParameter(valid_603243, JArray, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "DBSecurityGroups", valid_603243
  var valid_603244 = query.getOrDefault("MasterUserPassword")
  valid_603244 = validateParameter(valid_603244, JString, required = true,
                                 default = nil)
  if valid_603244 != nil:
    section.add "MasterUserPassword", valid_603244
  var valid_603245 = query.getOrDefault("AvailabilityZone")
  valid_603245 = validateParameter(valid_603245, JString, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "AvailabilityZone", valid_603245
  var valid_603246 = query.getOrDefault("Iops")
  valid_603246 = validateParameter(valid_603246, JInt, required = false, default = nil)
  if valid_603246 != nil:
    section.add "Iops", valid_603246
  var valid_603247 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603247 = validateParameter(valid_603247, JArray, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "VpcSecurityGroupIds", valid_603247
  var valid_603248 = query.getOrDefault("MultiAZ")
  valid_603248 = validateParameter(valid_603248, JBool, required = false, default = nil)
  if valid_603248 != nil:
    section.add "MultiAZ", valid_603248
  var valid_603249 = query.getOrDefault("TdeCredentialPassword")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "TdeCredentialPassword", valid_603249
  var valid_603250 = query.getOrDefault("LicenseModel")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "LicenseModel", valid_603250
  var valid_603251 = query.getOrDefault("BackupRetentionPeriod")
  valid_603251 = validateParameter(valid_603251, JInt, required = false, default = nil)
  if valid_603251 != nil:
    section.add "BackupRetentionPeriod", valid_603251
  var valid_603252 = query.getOrDefault("DBName")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "DBName", valid_603252
  var valid_603253 = query.getOrDefault("DBParameterGroupName")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "DBParameterGroupName", valid_603253
  var valid_603254 = query.getOrDefault("Tags")
  valid_603254 = validateParameter(valid_603254, JArray, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "Tags", valid_603254
  var valid_603255 = query.getOrDefault("DBInstanceClass")
  valid_603255 = validateParameter(valid_603255, JString, required = true,
                                 default = nil)
  if valid_603255 != nil:
    section.add "DBInstanceClass", valid_603255
  var valid_603256 = query.getOrDefault("Action")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603256 != nil:
    section.add "Action", valid_603256
  var valid_603257 = query.getOrDefault("DBSubnetGroupName")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "DBSubnetGroupName", valid_603257
  var valid_603258 = query.getOrDefault("CharacterSetName")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "CharacterSetName", valid_603258
  var valid_603259 = query.getOrDefault("TdeCredentialArn")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "TdeCredentialArn", valid_603259
  var valid_603260 = query.getOrDefault("PubliclyAccessible")
  valid_603260 = validateParameter(valid_603260, JBool, required = false, default = nil)
  if valid_603260 != nil:
    section.add "PubliclyAccessible", valid_603260
  var valid_603261 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603261 = validateParameter(valid_603261, JBool, required = false, default = nil)
  if valid_603261 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603261
  var valid_603262 = query.getOrDefault("EngineVersion")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "EngineVersion", valid_603262
  var valid_603263 = query.getOrDefault("Port")
  valid_603263 = validateParameter(valid_603263, JInt, required = false, default = nil)
  if valid_603263 != nil:
    section.add "Port", valid_603263
  var valid_603264 = query.getOrDefault("PreferredBackupWindow")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "PreferredBackupWindow", valid_603264
  var valid_603265 = query.getOrDefault("Version")
  valid_603265 = validateParameter(valid_603265, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603265 != nil:
    section.add "Version", valid_603265
  var valid_603266 = query.getOrDefault("DBInstanceIdentifier")
  valid_603266 = validateParameter(valid_603266, JString, required = true,
                                 default = nil)
  if valid_603266 != nil:
    section.add "DBInstanceIdentifier", valid_603266
  var valid_603267 = query.getOrDefault("MasterUsername")
  valid_603267 = validateParameter(valid_603267, JString, required = true,
                                 default = nil)
  if valid_603267 != nil:
    section.add "MasterUsername", valid_603267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603268 = header.getOrDefault("X-Amz-Date")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Date", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Security-Token")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Security-Token", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Content-Sha256", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Algorithm")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Algorithm", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Signature")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Signature", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-SignedHeaders", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-Credential")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-Credential", valid_603274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603275: Call_GetCreateDBInstance_603235; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603275.validator(path, query, header, formData, body)
  let scheme = call_603275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603275.url(scheme.get, call_603275.host, call_603275.base,
                         call_603275.route, valid.getOrDefault("path"))
  result = hook(call_603275, url, valid)

proc call*(call_603276: Call_GetCreateDBInstance_603235; Engine: string;
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
  var query_603277 = newJObject()
  add(query_603277, "Engine", newJString(Engine))
  add(query_603277, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603277, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603277, "StorageType", newJString(StorageType))
  add(query_603277, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_603277.add "DBSecurityGroups", DBSecurityGroups
  add(query_603277, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603277, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603277, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_603277.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603277, "MultiAZ", newJBool(MultiAZ))
  add(query_603277, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_603277, "LicenseModel", newJString(LicenseModel))
  add(query_603277, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603277, "DBName", newJString(DBName))
  add(query_603277, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_603277.add "Tags", Tags
  add(query_603277, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603277, "Action", newJString(Action))
  add(query_603277, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603277, "CharacterSetName", newJString(CharacterSetName))
  add(query_603277, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_603277, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603277, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603277, "EngineVersion", newJString(EngineVersion))
  add(query_603277, "Port", newJInt(Port))
  add(query_603277, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603277, "Version", newJString(Version))
  add(query_603277, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603277, "MasterUsername", newJString(MasterUsername))
  result = call_603276.call(nil, query_603277, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603235(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603236, base: "/",
    url: url_GetCreateDBInstance_603237, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_603349 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBInstanceReadReplica_603351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_603350(path: JsonNode;
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
  var valid_603352 = query.getOrDefault("Action")
  valid_603352 = validateParameter(valid_603352, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603352 != nil:
    section.add "Action", valid_603352
  var valid_603353 = query.getOrDefault("Version")
  valid_603353 = validateParameter(valid_603353, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603353 != nil:
    section.add "Version", valid_603353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603354 = header.getOrDefault("X-Amz-Date")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Date", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Security-Token")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Security-Token", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Content-Sha256", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Algorithm")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Algorithm", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-Signature")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-Signature", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-SignedHeaders", valid_603359
  var valid_603360 = header.getOrDefault("X-Amz-Credential")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Credential", valid_603360
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
  var valid_603361 = formData.getOrDefault("Port")
  valid_603361 = validateParameter(valid_603361, JInt, required = false, default = nil)
  if valid_603361 != nil:
    section.add "Port", valid_603361
  var valid_603362 = formData.getOrDefault("Iops")
  valid_603362 = validateParameter(valid_603362, JInt, required = false, default = nil)
  if valid_603362 != nil:
    section.add "Iops", valid_603362
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603363 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = nil)
  if valid_603363 != nil:
    section.add "DBInstanceIdentifier", valid_603363
  var valid_603364 = formData.getOrDefault("OptionGroupName")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "OptionGroupName", valid_603364
  var valid_603365 = formData.getOrDefault("Tags")
  valid_603365 = validateParameter(valid_603365, JArray, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "Tags", valid_603365
  var valid_603366 = formData.getOrDefault("DBSubnetGroupName")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "DBSubnetGroupName", valid_603366
  var valid_603367 = formData.getOrDefault("AvailabilityZone")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "AvailabilityZone", valid_603367
  var valid_603368 = formData.getOrDefault("PubliclyAccessible")
  valid_603368 = validateParameter(valid_603368, JBool, required = false, default = nil)
  if valid_603368 != nil:
    section.add "PubliclyAccessible", valid_603368
  var valid_603369 = formData.getOrDefault("StorageType")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "StorageType", valid_603369
  var valid_603370 = formData.getOrDefault("DBInstanceClass")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "DBInstanceClass", valid_603370
  var valid_603371 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603371
  var valid_603372 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603372 = validateParameter(valid_603372, JBool, required = false, default = nil)
  if valid_603372 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603373: Call_PostCreateDBInstanceReadReplica_603349;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603373.validator(path, query, header, formData, body)
  let scheme = call_603373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603373.url(scheme.get, call_603373.host, call_603373.base,
                         call_603373.route, valid.getOrDefault("path"))
  result = hook(call_603373, url, valid)

proc call*(call_603374: Call_PostCreateDBInstanceReadReplica_603349;
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
  var query_603375 = newJObject()
  var formData_603376 = newJObject()
  add(formData_603376, "Port", newJInt(Port))
  add(formData_603376, "Iops", newJInt(Iops))
  add(formData_603376, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603376, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603376.add "Tags", Tags
  add(formData_603376, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603376, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603375, "Action", newJString(Action))
  add(formData_603376, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603376, "StorageType", newJString(StorageType))
  add(formData_603376, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603376, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603376, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603375, "Version", newJString(Version))
  result = call_603374.call(nil, query_603375, nil, formData_603376, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_603349(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_603350, base: "/",
    url: url_PostCreateDBInstanceReadReplica_603351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_603322 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBInstanceReadReplica_603324(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_603323(path: JsonNode;
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
  var valid_603325 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603325
  var valid_603326 = query.getOrDefault("StorageType")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "StorageType", valid_603326
  var valid_603327 = query.getOrDefault("OptionGroupName")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "OptionGroupName", valid_603327
  var valid_603328 = query.getOrDefault("AvailabilityZone")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "AvailabilityZone", valid_603328
  var valid_603329 = query.getOrDefault("Iops")
  valid_603329 = validateParameter(valid_603329, JInt, required = false, default = nil)
  if valid_603329 != nil:
    section.add "Iops", valid_603329
  var valid_603330 = query.getOrDefault("Tags")
  valid_603330 = validateParameter(valid_603330, JArray, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "Tags", valid_603330
  var valid_603331 = query.getOrDefault("DBInstanceClass")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "DBInstanceClass", valid_603331
  var valid_603332 = query.getOrDefault("Action")
  valid_603332 = validateParameter(valid_603332, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603332 != nil:
    section.add "Action", valid_603332
  var valid_603333 = query.getOrDefault("DBSubnetGroupName")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "DBSubnetGroupName", valid_603333
  var valid_603334 = query.getOrDefault("PubliclyAccessible")
  valid_603334 = validateParameter(valid_603334, JBool, required = false, default = nil)
  if valid_603334 != nil:
    section.add "PubliclyAccessible", valid_603334
  var valid_603335 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603335 = validateParameter(valid_603335, JBool, required = false, default = nil)
  if valid_603335 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603335
  var valid_603336 = query.getOrDefault("Port")
  valid_603336 = validateParameter(valid_603336, JInt, required = false, default = nil)
  if valid_603336 != nil:
    section.add "Port", valid_603336
  var valid_603337 = query.getOrDefault("Version")
  valid_603337 = validateParameter(valid_603337, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603337 != nil:
    section.add "Version", valid_603337
  var valid_603338 = query.getOrDefault("DBInstanceIdentifier")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = nil)
  if valid_603338 != nil:
    section.add "DBInstanceIdentifier", valid_603338
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603339 = header.getOrDefault("X-Amz-Date")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Date", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Security-Token")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Security-Token", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Content-Sha256", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Algorithm")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Algorithm", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Signature")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Signature", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-SignedHeaders", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Credential")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Credential", valid_603345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603346: Call_GetCreateDBInstanceReadReplica_603322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603346.validator(path, query, header, formData, body)
  let scheme = call_603346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603346.url(scheme.get, call_603346.host, call_603346.base,
                         call_603346.route, valid.getOrDefault("path"))
  result = hook(call_603346, url, valid)

proc call*(call_603347: Call_GetCreateDBInstanceReadReplica_603322;
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
  var query_603348 = newJObject()
  add(query_603348, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603348, "StorageType", newJString(StorageType))
  add(query_603348, "OptionGroupName", newJString(OptionGroupName))
  add(query_603348, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603348, "Iops", newJInt(Iops))
  if Tags != nil:
    query_603348.add "Tags", Tags
  add(query_603348, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603348, "Action", newJString(Action))
  add(query_603348, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603348, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603348, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603348, "Port", newJInt(Port))
  add(query_603348, "Version", newJString(Version))
  add(query_603348, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603347.call(nil, query_603348, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_603322(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_603323, base: "/",
    url: url_GetCreateDBInstanceReadReplica_603324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_603396 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBParameterGroup_603398(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_603397(path: JsonNode; query: JsonNode;
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
  var valid_603399 = query.getOrDefault("Action")
  valid_603399 = validateParameter(valid_603399, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603399 != nil:
    section.add "Action", valid_603399
  var valid_603400 = query.getOrDefault("Version")
  valid_603400 = validateParameter(valid_603400, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603400 != nil:
    section.add "Version", valid_603400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603401 = header.getOrDefault("X-Amz-Date")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Date", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Security-Token")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Security-Token", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Content-Sha256", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Algorithm")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Algorithm", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Signature")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Signature", valid_603405
  var valid_603406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603406 = validateParameter(valid_603406, JString, required = false,
                                 default = nil)
  if valid_603406 != nil:
    section.add "X-Amz-SignedHeaders", valid_603406
  var valid_603407 = header.getOrDefault("X-Amz-Credential")
  valid_603407 = validateParameter(valid_603407, JString, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "X-Amz-Credential", valid_603407
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603408 = formData.getOrDefault("DBParameterGroupName")
  valid_603408 = validateParameter(valid_603408, JString, required = true,
                                 default = nil)
  if valid_603408 != nil:
    section.add "DBParameterGroupName", valid_603408
  var valid_603409 = formData.getOrDefault("Tags")
  valid_603409 = validateParameter(valid_603409, JArray, required = false,
                                 default = nil)
  if valid_603409 != nil:
    section.add "Tags", valid_603409
  var valid_603410 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603410 = validateParameter(valid_603410, JString, required = true,
                                 default = nil)
  if valid_603410 != nil:
    section.add "DBParameterGroupFamily", valid_603410
  var valid_603411 = formData.getOrDefault("Description")
  valid_603411 = validateParameter(valid_603411, JString, required = true,
                                 default = nil)
  if valid_603411 != nil:
    section.add "Description", valid_603411
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603412: Call_PostCreateDBParameterGroup_603396; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603412.validator(path, query, header, formData, body)
  let scheme = call_603412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603412.url(scheme.get, call_603412.host, call_603412.base,
                         call_603412.route, valid.getOrDefault("path"))
  result = hook(call_603412, url, valid)

proc call*(call_603413: Call_PostCreateDBParameterGroup_603396;
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
  var query_603414 = newJObject()
  var formData_603415 = newJObject()
  add(formData_603415, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_603415.add "Tags", Tags
  add(query_603414, "Action", newJString(Action))
  add(formData_603415, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603414, "Version", newJString(Version))
  add(formData_603415, "Description", newJString(Description))
  result = call_603413.call(nil, query_603414, nil, formData_603415, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_603396(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_603397, base: "/",
    url: url_PostCreateDBParameterGroup_603398,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_603377 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBParameterGroup_603379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_603378(path: JsonNode; query: JsonNode;
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
  var valid_603380 = query.getOrDefault("Description")
  valid_603380 = validateParameter(valid_603380, JString, required = true,
                                 default = nil)
  if valid_603380 != nil:
    section.add "Description", valid_603380
  var valid_603381 = query.getOrDefault("DBParameterGroupFamily")
  valid_603381 = validateParameter(valid_603381, JString, required = true,
                                 default = nil)
  if valid_603381 != nil:
    section.add "DBParameterGroupFamily", valid_603381
  var valid_603382 = query.getOrDefault("Tags")
  valid_603382 = validateParameter(valid_603382, JArray, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "Tags", valid_603382
  var valid_603383 = query.getOrDefault("DBParameterGroupName")
  valid_603383 = validateParameter(valid_603383, JString, required = true,
                                 default = nil)
  if valid_603383 != nil:
    section.add "DBParameterGroupName", valid_603383
  var valid_603384 = query.getOrDefault("Action")
  valid_603384 = validateParameter(valid_603384, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603384 != nil:
    section.add "Action", valid_603384
  var valid_603385 = query.getOrDefault("Version")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603385 != nil:
    section.add "Version", valid_603385
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603386 = header.getOrDefault("X-Amz-Date")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Date", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Security-Token")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Security-Token", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Content-Sha256", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-Algorithm")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-Algorithm", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Signature")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Signature", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-SignedHeaders", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Credential")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Credential", valid_603392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603393: Call_GetCreateDBParameterGroup_603377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603393.validator(path, query, header, formData, body)
  let scheme = call_603393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603393.url(scheme.get, call_603393.host, call_603393.base,
                         call_603393.route, valid.getOrDefault("path"))
  result = hook(call_603393, url, valid)

proc call*(call_603394: Call_GetCreateDBParameterGroup_603377; Description: string;
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
  var query_603395 = newJObject()
  add(query_603395, "Description", newJString(Description))
  add(query_603395, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_603395.add "Tags", Tags
  add(query_603395, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603395, "Action", newJString(Action))
  add(query_603395, "Version", newJString(Version))
  result = call_603394.call(nil, query_603395, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_603377(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_603378, base: "/",
    url: url_GetCreateDBParameterGroup_603379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_603434 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSecurityGroup_603436(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_603435(path: JsonNode; query: JsonNode;
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
  var valid_603437 = query.getOrDefault("Action")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603437 != nil:
    section.add "Action", valid_603437
  var valid_603438 = query.getOrDefault("Version")
  valid_603438 = validateParameter(valid_603438, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603438 != nil:
    section.add "Version", valid_603438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603439 = header.getOrDefault("X-Amz-Date")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Date", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Security-Token")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Security-Token", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Content-Sha256", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Algorithm")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Algorithm", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-Signature")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-Signature", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-SignedHeaders", valid_603444
  var valid_603445 = header.getOrDefault("X-Amz-Credential")
  valid_603445 = validateParameter(valid_603445, JString, required = false,
                                 default = nil)
  if valid_603445 != nil:
    section.add "X-Amz-Credential", valid_603445
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603446 = formData.getOrDefault("DBSecurityGroupName")
  valid_603446 = validateParameter(valid_603446, JString, required = true,
                                 default = nil)
  if valid_603446 != nil:
    section.add "DBSecurityGroupName", valid_603446
  var valid_603447 = formData.getOrDefault("Tags")
  valid_603447 = validateParameter(valid_603447, JArray, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "Tags", valid_603447
  var valid_603448 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_603448 = validateParameter(valid_603448, JString, required = true,
                                 default = nil)
  if valid_603448 != nil:
    section.add "DBSecurityGroupDescription", valid_603448
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603449: Call_PostCreateDBSecurityGroup_603434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603449.validator(path, query, header, formData, body)
  let scheme = call_603449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603449.url(scheme.get, call_603449.host, call_603449.base,
                         call_603449.route, valid.getOrDefault("path"))
  result = hook(call_603449, url, valid)

proc call*(call_603450: Call_PostCreateDBSecurityGroup_603434;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_603451 = newJObject()
  var formData_603452 = newJObject()
  add(formData_603452, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_603452.add "Tags", Tags
  add(query_603451, "Action", newJString(Action))
  add(formData_603452, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603451, "Version", newJString(Version))
  result = call_603450.call(nil, query_603451, nil, formData_603452, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_603434(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_603435, base: "/",
    url: url_PostCreateDBSecurityGroup_603436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_603416 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSecurityGroup_603418(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_603417(path: JsonNode; query: JsonNode;
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
  var valid_603419 = query.getOrDefault("DBSecurityGroupName")
  valid_603419 = validateParameter(valid_603419, JString, required = true,
                                 default = nil)
  if valid_603419 != nil:
    section.add "DBSecurityGroupName", valid_603419
  var valid_603420 = query.getOrDefault("DBSecurityGroupDescription")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = nil)
  if valid_603420 != nil:
    section.add "DBSecurityGroupDescription", valid_603420
  var valid_603421 = query.getOrDefault("Tags")
  valid_603421 = validateParameter(valid_603421, JArray, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "Tags", valid_603421
  var valid_603422 = query.getOrDefault("Action")
  valid_603422 = validateParameter(valid_603422, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603422 != nil:
    section.add "Action", valid_603422
  var valid_603423 = query.getOrDefault("Version")
  valid_603423 = validateParameter(valid_603423, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603423 != nil:
    section.add "Version", valid_603423
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603424 = header.getOrDefault("X-Amz-Date")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Date", valid_603424
  var valid_603425 = header.getOrDefault("X-Amz-Security-Token")
  valid_603425 = validateParameter(valid_603425, JString, required = false,
                                 default = nil)
  if valid_603425 != nil:
    section.add "X-Amz-Security-Token", valid_603425
  var valid_603426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603426 = validateParameter(valid_603426, JString, required = false,
                                 default = nil)
  if valid_603426 != nil:
    section.add "X-Amz-Content-Sha256", valid_603426
  var valid_603427 = header.getOrDefault("X-Amz-Algorithm")
  valid_603427 = validateParameter(valid_603427, JString, required = false,
                                 default = nil)
  if valid_603427 != nil:
    section.add "X-Amz-Algorithm", valid_603427
  var valid_603428 = header.getOrDefault("X-Amz-Signature")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Signature", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-SignedHeaders", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Credential")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Credential", valid_603430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603431: Call_GetCreateDBSecurityGroup_603416; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603431.validator(path, query, header, formData, body)
  let scheme = call_603431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603431.url(scheme.get, call_603431.host, call_603431.base,
                         call_603431.route, valid.getOrDefault("path"))
  result = hook(call_603431, url, valid)

proc call*(call_603432: Call_GetCreateDBSecurityGroup_603416;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603433 = newJObject()
  add(query_603433, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603433, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_603433.add "Tags", Tags
  add(query_603433, "Action", newJString(Action))
  add(query_603433, "Version", newJString(Version))
  result = call_603432.call(nil, query_603433, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_603416(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_603417, base: "/",
    url: url_GetCreateDBSecurityGroup_603418, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_603471 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSnapshot_603473(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_603472(path: JsonNode; query: JsonNode;
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
  var valid_603474 = query.getOrDefault("Action")
  valid_603474 = validateParameter(valid_603474, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603474 != nil:
    section.add "Action", valid_603474
  var valid_603475 = query.getOrDefault("Version")
  valid_603475 = validateParameter(valid_603475, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603475 != nil:
    section.add "Version", valid_603475
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603476 = header.getOrDefault("X-Amz-Date")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Date", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Security-Token")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Security-Token", valid_603477
  var valid_603478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603478 = validateParameter(valid_603478, JString, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "X-Amz-Content-Sha256", valid_603478
  var valid_603479 = header.getOrDefault("X-Amz-Algorithm")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Algorithm", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Signature")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Signature", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-SignedHeaders", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Credential")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Credential", valid_603482
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603483 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603483 = validateParameter(valid_603483, JString, required = true,
                                 default = nil)
  if valid_603483 != nil:
    section.add "DBInstanceIdentifier", valid_603483
  var valid_603484 = formData.getOrDefault("Tags")
  valid_603484 = validateParameter(valid_603484, JArray, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "Tags", valid_603484
  var valid_603485 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603485 = validateParameter(valid_603485, JString, required = true,
                                 default = nil)
  if valid_603485 != nil:
    section.add "DBSnapshotIdentifier", valid_603485
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603486: Call_PostCreateDBSnapshot_603471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603486.validator(path, query, header, formData, body)
  let scheme = call_603486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603486.url(scheme.get, call_603486.host, call_603486.base,
                         call_603486.route, valid.getOrDefault("path"))
  result = hook(call_603486, url, valid)

proc call*(call_603487: Call_PostCreateDBSnapshot_603471;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603488 = newJObject()
  var formData_603489 = newJObject()
  add(formData_603489, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_603489.add "Tags", Tags
  add(formData_603489, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603488, "Action", newJString(Action))
  add(query_603488, "Version", newJString(Version))
  result = call_603487.call(nil, query_603488, nil, formData_603489, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_603471(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_603472, base: "/",
    url: url_PostCreateDBSnapshot_603473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_603453 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSnapshot_603455(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_603454(path: JsonNode; query: JsonNode;
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
  var valid_603456 = query.getOrDefault("Tags")
  valid_603456 = validateParameter(valid_603456, JArray, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "Tags", valid_603456
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603457 = query.getOrDefault("Action")
  valid_603457 = validateParameter(valid_603457, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603457 != nil:
    section.add "Action", valid_603457
  var valid_603458 = query.getOrDefault("Version")
  valid_603458 = validateParameter(valid_603458, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603458 != nil:
    section.add "Version", valid_603458
  var valid_603459 = query.getOrDefault("DBInstanceIdentifier")
  valid_603459 = validateParameter(valid_603459, JString, required = true,
                                 default = nil)
  if valid_603459 != nil:
    section.add "DBInstanceIdentifier", valid_603459
  var valid_603460 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603460 = validateParameter(valid_603460, JString, required = true,
                                 default = nil)
  if valid_603460 != nil:
    section.add "DBSnapshotIdentifier", valid_603460
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603461 = header.getOrDefault("X-Amz-Date")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Date", valid_603461
  var valid_603462 = header.getOrDefault("X-Amz-Security-Token")
  valid_603462 = validateParameter(valid_603462, JString, required = false,
                                 default = nil)
  if valid_603462 != nil:
    section.add "X-Amz-Security-Token", valid_603462
  var valid_603463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "X-Amz-Content-Sha256", valid_603463
  var valid_603464 = header.getOrDefault("X-Amz-Algorithm")
  valid_603464 = validateParameter(valid_603464, JString, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "X-Amz-Algorithm", valid_603464
  var valid_603465 = header.getOrDefault("X-Amz-Signature")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "X-Amz-Signature", valid_603465
  var valid_603466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-SignedHeaders", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Credential")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Credential", valid_603467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603468: Call_GetCreateDBSnapshot_603453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603468.validator(path, query, header, formData, body)
  let scheme = call_603468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603468.url(scheme.get, call_603468.host, call_603468.base,
                         call_603468.route, valid.getOrDefault("path"))
  result = hook(call_603468, url, valid)

proc call*(call_603469: Call_GetCreateDBSnapshot_603453;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603470 = newJObject()
  if Tags != nil:
    query_603470.add "Tags", Tags
  add(query_603470, "Action", newJString(Action))
  add(query_603470, "Version", newJString(Version))
  add(query_603470, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603470, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603469.call(nil, query_603470, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_603453(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_603454, base: "/",
    url: url_GetCreateDBSnapshot_603455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603509 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSubnetGroup_603511(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_603510(path: JsonNode; query: JsonNode;
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
  var valid_603512 = query.getOrDefault("Action")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603512 != nil:
    section.add "Action", valid_603512
  var valid_603513 = query.getOrDefault("Version")
  valid_603513 = validateParameter(valid_603513, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603513 != nil:
    section.add "Version", valid_603513
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603514 = header.getOrDefault("X-Amz-Date")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Date", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Security-Token")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Security-Token", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Content-Sha256", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Algorithm")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Algorithm", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Signature")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Signature", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-SignedHeaders", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Credential")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Credential", valid_603520
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_603521 = formData.getOrDefault("Tags")
  valid_603521 = validateParameter(valid_603521, JArray, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "Tags", valid_603521
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603522 = formData.getOrDefault("DBSubnetGroupName")
  valid_603522 = validateParameter(valid_603522, JString, required = true,
                                 default = nil)
  if valid_603522 != nil:
    section.add "DBSubnetGroupName", valid_603522
  var valid_603523 = formData.getOrDefault("SubnetIds")
  valid_603523 = validateParameter(valid_603523, JArray, required = true, default = nil)
  if valid_603523 != nil:
    section.add "SubnetIds", valid_603523
  var valid_603524 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603524 = validateParameter(valid_603524, JString, required = true,
                                 default = nil)
  if valid_603524 != nil:
    section.add "DBSubnetGroupDescription", valid_603524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603525: Call_PostCreateDBSubnetGroup_603509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603525.validator(path, query, header, formData, body)
  let scheme = call_603525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603525.url(scheme.get, call_603525.host, call_603525.base,
                         call_603525.route, valid.getOrDefault("path"))
  result = hook(call_603525, url, valid)

proc call*(call_603526: Call_PostCreateDBSubnetGroup_603509;
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
  var query_603527 = newJObject()
  var formData_603528 = newJObject()
  if Tags != nil:
    formData_603528.add "Tags", Tags
  add(formData_603528, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603528.add "SubnetIds", SubnetIds
  add(query_603527, "Action", newJString(Action))
  add(formData_603528, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603527, "Version", newJString(Version))
  result = call_603526.call(nil, query_603527, nil, formData_603528, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603509(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603510, base: "/",
    url: url_PostCreateDBSubnetGroup_603511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603490 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSubnetGroup_603492(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_603491(path: JsonNode; query: JsonNode;
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
  var valid_603493 = query.getOrDefault("Tags")
  valid_603493 = validateParameter(valid_603493, JArray, required = false,
                                 default = nil)
  if valid_603493 != nil:
    section.add "Tags", valid_603493
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603494 = query.getOrDefault("Action")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603494 != nil:
    section.add "Action", valid_603494
  var valid_603495 = query.getOrDefault("DBSubnetGroupName")
  valid_603495 = validateParameter(valid_603495, JString, required = true,
                                 default = nil)
  if valid_603495 != nil:
    section.add "DBSubnetGroupName", valid_603495
  var valid_603496 = query.getOrDefault("SubnetIds")
  valid_603496 = validateParameter(valid_603496, JArray, required = true, default = nil)
  if valid_603496 != nil:
    section.add "SubnetIds", valid_603496
  var valid_603497 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = nil)
  if valid_603497 != nil:
    section.add "DBSubnetGroupDescription", valid_603497
  var valid_603498 = query.getOrDefault("Version")
  valid_603498 = validateParameter(valid_603498, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603498 != nil:
    section.add "Version", valid_603498
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Security-Token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Security-Token", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Content-Sha256", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Algorithm")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Algorithm", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Signature")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Signature", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-SignedHeaders", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Credential")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Credential", valid_603505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603506: Call_GetCreateDBSubnetGroup_603490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603506.validator(path, query, header, formData, body)
  let scheme = call_603506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603506.url(scheme.get, call_603506.host, call_603506.base,
                         call_603506.route, valid.getOrDefault("path"))
  result = hook(call_603506, url, valid)

proc call*(call_603507: Call_GetCreateDBSubnetGroup_603490;
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
  var query_603508 = newJObject()
  if Tags != nil:
    query_603508.add "Tags", Tags
  add(query_603508, "Action", newJString(Action))
  add(query_603508, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603508.add "SubnetIds", SubnetIds
  add(query_603508, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603508, "Version", newJString(Version))
  result = call_603507.call(nil, query_603508, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603490(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603491, base: "/",
    url: url_GetCreateDBSubnetGroup_603492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_603551 = ref object of OpenApiRestCall_602417
proc url_PostCreateEventSubscription_603553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_603552(path: JsonNode; query: JsonNode;
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
  var valid_603554 = query.getOrDefault("Action")
  valid_603554 = validateParameter(valid_603554, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603554 != nil:
    section.add "Action", valid_603554
  var valid_603555 = query.getOrDefault("Version")
  valid_603555 = validateParameter(valid_603555, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603555 != nil:
    section.add "Version", valid_603555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603556 = header.getOrDefault("X-Amz-Date")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Date", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-Security-Token")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-Security-Token", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Content-Sha256", valid_603558
  var valid_603559 = header.getOrDefault("X-Amz-Algorithm")
  valid_603559 = validateParameter(valid_603559, JString, required = false,
                                 default = nil)
  if valid_603559 != nil:
    section.add "X-Amz-Algorithm", valid_603559
  var valid_603560 = header.getOrDefault("X-Amz-Signature")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "X-Amz-Signature", valid_603560
  var valid_603561 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603561 = validateParameter(valid_603561, JString, required = false,
                                 default = nil)
  if valid_603561 != nil:
    section.add "X-Amz-SignedHeaders", valid_603561
  var valid_603562 = header.getOrDefault("X-Amz-Credential")
  valid_603562 = validateParameter(valid_603562, JString, required = false,
                                 default = nil)
  if valid_603562 != nil:
    section.add "X-Amz-Credential", valid_603562
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
  var valid_603563 = formData.getOrDefault("Enabled")
  valid_603563 = validateParameter(valid_603563, JBool, required = false, default = nil)
  if valid_603563 != nil:
    section.add "Enabled", valid_603563
  var valid_603564 = formData.getOrDefault("EventCategories")
  valid_603564 = validateParameter(valid_603564, JArray, required = false,
                                 default = nil)
  if valid_603564 != nil:
    section.add "EventCategories", valid_603564
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_603565 = formData.getOrDefault("SnsTopicArn")
  valid_603565 = validateParameter(valid_603565, JString, required = true,
                                 default = nil)
  if valid_603565 != nil:
    section.add "SnsTopicArn", valid_603565
  var valid_603566 = formData.getOrDefault("SourceIds")
  valid_603566 = validateParameter(valid_603566, JArray, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "SourceIds", valid_603566
  var valid_603567 = formData.getOrDefault("Tags")
  valid_603567 = validateParameter(valid_603567, JArray, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "Tags", valid_603567
  var valid_603568 = formData.getOrDefault("SubscriptionName")
  valid_603568 = validateParameter(valid_603568, JString, required = true,
                                 default = nil)
  if valid_603568 != nil:
    section.add "SubscriptionName", valid_603568
  var valid_603569 = formData.getOrDefault("SourceType")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "SourceType", valid_603569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603570: Call_PostCreateEventSubscription_603551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603570.validator(path, query, header, formData, body)
  let scheme = call_603570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603570.url(scheme.get, call_603570.host, call_603570.base,
                         call_603570.route, valid.getOrDefault("path"))
  result = hook(call_603570, url, valid)

proc call*(call_603571: Call_PostCreateEventSubscription_603551;
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
  var query_603572 = newJObject()
  var formData_603573 = newJObject()
  add(formData_603573, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_603573.add "EventCategories", EventCategories
  add(formData_603573, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_603573.add "SourceIds", SourceIds
  if Tags != nil:
    formData_603573.add "Tags", Tags
  add(formData_603573, "SubscriptionName", newJString(SubscriptionName))
  add(query_603572, "Action", newJString(Action))
  add(query_603572, "Version", newJString(Version))
  add(formData_603573, "SourceType", newJString(SourceType))
  result = call_603571.call(nil, query_603572, nil, formData_603573, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_603551(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_603552, base: "/",
    url: url_PostCreateEventSubscription_603553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_603529 = ref object of OpenApiRestCall_602417
proc url_GetCreateEventSubscription_603531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_603530(path: JsonNode; query: JsonNode;
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
  var valid_603532 = query.getOrDefault("SourceType")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "SourceType", valid_603532
  var valid_603533 = query.getOrDefault("SourceIds")
  valid_603533 = validateParameter(valid_603533, JArray, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "SourceIds", valid_603533
  var valid_603534 = query.getOrDefault("Enabled")
  valid_603534 = validateParameter(valid_603534, JBool, required = false, default = nil)
  if valid_603534 != nil:
    section.add "Enabled", valid_603534
  var valid_603535 = query.getOrDefault("Tags")
  valid_603535 = validateParameter(valid_603535, JArray, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "Tags", valid_603535
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603536 = query.getOrDefault("Action")
  valid_603536 = validateParameter(valid_603536, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603536 != nil:
    section.add "Action", valid_603536
  var valid_603537 = query.getOrDefault("SnsTopicArn")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = nil)
  if valid_603537 != nil:
    section.add "SnsTopicArn", valid_603537
  var valid_603538 = query.getOrDefault("EventCategories")
  valid_603538 = validateParameter(valid_603538, JArray, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "EventCategories", valid_603538
  var valid_603539 = query.getOrDefault("SubscriptionName")
  valid_603539 = validateParameter(valid_603539, JString, required = true,
                                 default = nil)
  if valid_603539 != nil:
    section.add "SubscriptionName", valid_603539
  var valid_603540 = query.getOrDefault("Version")
  valid_603540 = validateParameter(valid_603540, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603540 != nil:
    section.add "Version", valid_603540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603541 = header.getOrDefault("X-Amz-Date")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Date", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-Security-Token")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-Security-Token", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Content-Sha256", valid_603543
  var valid_603544 = header.getOrDefault("X-Amz-Algorithm")
  valid_603544 = validateParameter(valid_603544, JString, required = false,
                                 default = nil)
  if valid_603544 != nil:
    section.add "X-Amz-Algorithm", valid_603544
  var valid_603545 = header.getOrDefault("X-Amz-Signature")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "X-Amz-Signature", valid_603545
  var valid_603546 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603546 = validateParameter(valid_603546, JString, required = false,
                                 default = nil)
  if valid_603546 != nil:
    section.add "X-Amz-SignedHeaders", valid_603546
  var valid_603547 = header.getOrDefault("X-Amz-Credential")
  valid_603547 = validateParameter(valid_603547, JString, required = false,
                                 default = nil)
  if valid_603547 != nil:
    section.add "X-Amz-Credential", valid_603547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603548: Call_GetCreateEventSubscription_603529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603548.validator(path, query, header, formData, body)
  let scheme = call_603548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603548.url(scheme.get, call_603548.host, call_603548.base,
                         call_603548.route, valid.getOrDefault("path"))
  result = hook(call_603548, url, valid)

proc call*(call_603549: Call_GetCreateEventSubscription_603529;
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
  var query_603550 = newJObject()
  add(query_603550, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_603550.add "SourceIds", SourceIds
  add(query_603550, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_603550.add "Tags", Tags
  add(query_603550, "Action", newJString(Action))
  add(query_603550, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_603550.add "EventCategories", EventCategories
  add(query_603550, "SubscriptionName", newJString(SubscriptionName))
  add(query_603550, "Version", newJString(Version))
  result = call_603549.call(nil, query_603550, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_603529(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_603530, base: "/",
    url: url_GetCreateEventSubscription_603531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_603594 = ref object of OpenApiRestCall_602417
proc url_PostCreateOptionGroup_603596(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_603595(path: JsonNode; query: JsonNode;
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
  var valid_603597 = query.getOrDefault("Action")
  valid_603597 = validateParameter(valid_603597, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603597 != nil:
    section.add "Action", valid_603597
  var valid_603598 = query.getOrDefault("Version")
  valid_603598 = validateParameter(valid_603598, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603598 != nil:
    section.add "Version", valid_603598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603599 = header.getOrDefault("X-Amz-Date")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Date", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Security-Token")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Security-Token", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Algorithm")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Algorithm", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Signature")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Signature", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-SignedHeaders", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Credential")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Credential", valid_603605
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_603606 = formData.getOrDefault("MajorEngineVersion")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = nil)
  if valid_603606 != nil:
    section.add "MajorEngineVersion", valid_603606
  var valid_603607 = formData.getOrDefault("OptionGroupName")
  valid_603607 = validateParameter(valid_603607, JString, required = true,
                                 default = nil)
  if valid_603607 != nil:
    section.add "OptionGroupName", valid_603607
  var valid_603608 = formData.getOrDefault("Tags")
  valid_603608 = validateParameter(valid_603608, JArray, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "Tags", valid_603608
  var valid_603609 = formData.getOrDefault("EngineName")
  valid_603609 = validateParameter(valid_603609, JString, required = true,
                                 default = nil)
  if valid_603609 != nil:
    section.add "EngineName", valid_603609
  var valid_603610 = formData.getOrDefault("OptionGroupDescription")
  valid_603610 = validateParameter(valid_603610, JString, required = true,
                                 default = nil)
  if valid_603610 != nil:
    section.add "OptionGroupDescription", valid_603610
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603611: Call_PostCreateOptionGroup_603594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603611.validator(path, query, header, formData, body)
  let scheme = call_603611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603611.url(scheme.get, call_603611.host, call_603611.base,
                         call_603611.route, valid.getOrDefault("path"))
  result = hook(call_603611, url, valid)

proc call*(call_603612: Call_PostCreateOptionGroup_603594;
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
  var query_603613 = newJObject()
  var formData_603614 = newJObject()
  add(formData_603614, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_603614, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603614.add "Tags", Tags
  add(query_603613, "Action", newJString(Action))
  add(formData_603614, "EngineName", newJString(EngineName))
  add(formData_603614, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_603613, "Version", newJString(Version))
  result = call_603612.call(nil, query_603613, nil, formData_603614, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_603594(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_603595, base: "/",
    url: url_PostCreateOptionGroup_603596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_603574 = ref object of OpenApiRestCall_602417
proc url_GetCreateOptionGroup_603576(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_603575(path: JsonNode; query: JsonNode;
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
  var valid_603577 = query.getOrDefault("OptionGroupName")
  valid_603577 = validateParameter(valid_603577, JString, required = true,
                                 default = nil)
  if valid_603577 != nil:
    section.add "OptionGroupName", valid_603577
  var valid_603578 = query.getOrDefault("Tags")
  valid_603578 = validateParameter(valid_603578, JArray, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "Tags", valid_603578
  var valid_603579 = query.getOrDefault("OptionGroupDescription")
  valid_603579 = validateParameter(valid_603579, JString, required = true,
                                 default = nil)
  if valid_603579 != nil:
    section.add "OptionGroupDescription", valid_603579
  var valid_603580 = query.getOrDefault("Action")
  valid_603580 = validateParameter(valid_603580, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603580 != nil:
    section.add "Action", valid_603580
  var valid_603581 = query.getOrDefault("Version")
  valid_603581 = validateParameter(valid_603581, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603581 != nil:
    section.add "Version", valid_603581
  var valid_603582 = query.getOrDefault("EngineName")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = nil)
  if valid_603582 != nil:
    section.add "EngineName", valid_603582
  var valid_603583 = query.getOrDefault("MajorEngineVersion")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = nil)
  if valid_603583 != nil:
    section.add "MajorEngineVersion", valid_603583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603584 = header.getOrDefault("X-Amz-Date")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Date", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Security-Token")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Security-Token", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Algorithm")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Algorithm", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Signature")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Signature", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Credential")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Credential", valid_603590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603591: Call_GetCreateOptionGroup_603574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603591.validator(path, query, header, formData, body)
  let scheme = call_603591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603591.url(scheme.get, call_603591.host, call_603591.base,
                         call_603591.route, valid.getOrDefault("path"))
  result = hook(call_603591, url, valid)

proc call*(call_603592: Call_GetCreateOptionGroup_603574; OptionGroupName: string;
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
  var query_603593 = newJObject()
  add(query_603593, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_603593.add "Tags", Tags
  add(query_603593, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_603593, "Action", newJString(Action))
  add(query_603593, "Version", newJString(Version))
  add(query_603593, "EngineName", newJString(EngineName))
  add(query_603593, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603592.call(nil, query_603593, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_603574(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_603575, base: "/",
    url: url_GetCreateOptionGroup_603576, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603633 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBInstance_603635(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_603634(path: JsonNode; query: JsonNode;
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
  var valid_603636 = query.getOrDefault("Action")
  valid_603636 = validateParameter(valid_603636, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603636 != nil:
    section.add "Action", valid_603636
  var valid_603637 = query.getOrDefault("Version")
  valid_603637 = validateParameter(valid_603637, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603637 != nil:
    section.add "Version", valid_603637
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603638 = header.getOrDefault("X-Amz-Date")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Date", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Security-Token")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Security-Token", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Content-Sha256", valid_603640
  var valid_603641 = header.getOrDefault("X-Amz-Algorithm")
  valid_603641 = validateParameter(valid_603641, JString, required = false,
                                 default = nil)
  if valid_603641 != nil:
    section.add "X-Amz-Algorithm", valid_603641
  var valid_603642 = header.getOrDefault("X-Amz-Signature")
  valid_603642 = validateParameter(valid_603642, JString, required = false,
                                 default = nil)
  if valid_603642 != nil:
    section.add "X-Amz-Signature", valid_603642
  var valid_603643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603643 = validateParameter(valid_603643, JString, required = false,
                                 default = nil)
  if valid_603643 != nil:
    section.add "X-Amz-SignedHeaders", valid_603643
  var valid_603644 = header.getOrDefault("X-Amz-Credential")
  valid_603644 = validateParameter(valid_603644, JString, required = false,
                                 default = nil)
  if valid_603644 != nil:
    section.add "X-Amz-Credential", valid_603644
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603645 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603645 = validateParameter(valid_603645, JString, required = true,
                                 default = nil)
  if valid_603645 != nil:
    section.add "DBInstanceIdentifier", valid_603645
  var valid_603646 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603646 = validateParameter(valid_603646, JString, required = false,
                                 default = nil)
  if valid_603646 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603646
  var valid_603647 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603647 = validateParameter(valid_603647, JBool, required = false, default = nil)
  if valid_603647 != nil:
    section.add "SkipFinalSnapshot", valid_603647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603648: Call_PostDeleteDBInstance_603633; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603648.validator(path, query, header, formData, body)
  let scheme = call_603648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603648.url(scheme.get, call_603648.host, call_603648.base,
                         call_603648.route, valid.getOrDefault("path"))
  result = hook(call_603648, url, valid)

proc call*(call_603649: Call_PostDeleteDBInstance_603633;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2014-09-01";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_603650 = newJObject()
  var formData_603651 = newJObject()
  add(formData_603651, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603651, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603650, "Action", newJString(Action))
  add(query_603650, "Version", newJString(Version))
  add(formData_603651, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603649.call(nil, query_603650, nil, formData_603651, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603633(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603634, base: "/",
    url: url_PostDeleteDBInstance_603635, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603615 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBInstance_603617(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_603616(path: JsonNode; query: JsonNode;
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
  var valid_603618 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603618
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603619 = query.getOrDefault("Action")
  valid_603619 = validateParameter(valid_603619, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603619 != nil:
    section.add "Action", valid_603619
  var valid_603620 = query.getOrDefault("SkipFinalSnapshot")
  valid_603620 = validateParameter(valid_603620, JBool, required = false, default = nil)
  if valid_603620 != nil:
    section.add "SkipFinalSnapshot", valid_603620
  var valid_603621 = query.getOrDefault("Version")
  valid_603621 = validateParameter(valid_603621, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603621 != nil:
    section.add "Version", valid_603621
  var valid_603622 = query.getOrDefault("DBInstanceIdentifier")
  valid_603622 = validateParameter(valid_603622, JString, required = true,
                                 default = nil)
  if valid_603622 != nil:
    section.add "DBInstanceIdentifier", valid_603622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603623 = header.getOrDefault("X-Amz-Date")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Date", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Security-Token")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Security-Token", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Content-Sha256", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Algorithm")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Algorithm", valid_603626
  var valid_603627 = header.getOrDefault("X-Amz-Signature")
  valid_603627 = validateParameter(valid_603627, JString, required = false,
                                 default = nil)
  if valid_603627 != nil:
    section.add "X-Amz-Signature", valid_603627
  var valid_603628 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603628 = validateParameter(valid_603628, JString, required = false,
                                 default = nil)
  if valid_603628 != nil:
    section.add "X-Amz-SignedHeaders", valid_603628
  var valid_603629 = header.getOrDefault("X-Amz-Credential")
  valid_603629 = validateParameter(valid_603629, JString, required = false,
                                 default = nil)
  if valid_603629 != nil:
    section.add "X-Amz-Credential", valid_603629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603630: Call_GetDeleteDBInstance_603615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603630.validator(path, query, header, formData, body)
  let scheme = call_603630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603630.url(scheme.get, call_603630.host, call_603630.base,
                         call_603630.route, valid.getOrDefault("path"))
  result = hook(call_603630, url, valid)

proc call*(call_603631: Call_GetDeleteDBInstance_603615;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_603632 = newJObject()
  add(query_603632, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603632, "Action", newJString(Action))
  add(query_603632, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603632, "Version", newJString(Version))
  add(query_603632, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603631.call(nil, query_603632, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603615(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603616, base: "/",
    url: url_GetDeleteDBInstance_603617, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_603668 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBParameterGroup_603670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_603669(path: JsonNode; query: JsonNode;
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
  var valid_603671 = query.getOrDefault("Action")
  valid_603671 = validateParameter(valid_603671, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603671 != nil:
    section.add "Action", valid_603671
  var valid_603672 = query.getOrDefault("Version")
  valid_603672 = validateParameter(valid_603672, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603672 != nil:
    section.add "Version", valid_603672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603673 = header.getOrDefault("X-Amz-Date")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Date", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Security-Token")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Security-Token", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Content-Sha256", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-Algorithm")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-Algorithm", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Signature")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Signature", valid_603677
  var valid_603678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603678 = validateParameter(valid_603678, JString, required = false,
                                 default = nil)
  if valid_603678 != nil:
    section.add "X-Amz-SignedHeaders", valid_603678
  var valid_603679 = header.getOrDefault("X-Amz-Credential")
  valid_603679 = validateParameter(valid_603679, JString, required = false,
                                 default = nil)
  if valid_603679 != nil:
    section.add "X-Amz-Credential", valid_603679
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603680 = formData.getOrDefault("DBParameterGroupName")
  valid_603680 = validateParameter(valid_603680, JString, required = true,
                                 default = nil)
  if valid_603680 != nil:
    section.add "DBParameterGroupName", valid_603680
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603681: Call_PostDeleteDBParameterGroup_603668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603681.validator(path, query, header, formData, body)
  let scheme = call_603681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603681.url(scheme.get, call_603681.host, call_603681.base,
                         call_603681.route, valid.getOrDefault("path"))
  result = hook(call_603681, url, valid)

proc call*(call_603682: Call_PostDeleteDBParameterGroup_603668;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603683 = newJObject()
  var formData_603684 = newJObject()
  add(formData_603684, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603683, "Action", newJString(Action))
  add(query_603683, "Version", newJString(Version))
  result = call_603682.call(nil, query_603683, nil, formData_603684, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_603668(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_603669, base: "/",
    url: url_PostDeleteDBParameterGroup_603670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_603652 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBParameterGroup_603654(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_603653(path: JsonNode; query: JsonNode;
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
  var valid_603655 = query.getOrDefault("DBParameterGroupName")
  valid_603655 = validateParameter(valid_603655, JString, required = true,
                                 default = nil)
  if valid_603655 != nil:
    section.add "DBParameterGroupName", valid_603655
  var valid_603656 = query.getOrDefault("Action")
  valid_603656 = validateParameter(valid_603656, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603656 != nil:
    section.add "Action", valid_603656
  var valid_603657 = query.getOrDefault("Version")
  valid_603657 = validateParameter(valid_603657, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603657 != nil:
    section.add "Version", valid_603657
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603658 = header.getOrDefault("X-Amz-Date")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Date", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Security-Token")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Security-Token", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Content-Sha256", valid_603660
  var valid_603661 = header.getOrDefault("X-Amz-Algorithm")
  valid_603661 = validateParameter(valid_603661, JString, required = false,
                                 default = nil)
  if valid_603661 != nil:
    section.add "X-Amz-Algorithm", valid_603661
  var valid_603662 = header.getOrDefault("X-Amz-Signature")
  valid_603662 = validateParameter(valid_603662, JString, required = false,
                                 default = nil)
  if valid_603662 != nil:
    section.add "X-Amz-Signature", valid_603662
  var valid_603663 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603663 = validateParameter(valid_603663, JString, required = false,
                                 default = nil)
  if valid_603663 != nil:
    section.add "X-Amz-SignedHeaders", valid_603663
  var valid_603664 = header.getOrDefault("X-Amz-Credential")
  valid_603664 = validateParameter(valid_603664, JString, required = false,
                                 default = nil)
  if valid_603664 != nil:
    section.add "X-Amz-Credential", valid_603664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603665: Call_GetDeleteDBParameterGroup_603652; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603665.validator(path, query, header, formData, body)
  let scheme = call_603665.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603665.url(scheme.get, call_603665.host, call_603665.base,
                         call_603665.route, valid.getOrDefault("path"))
  result = hook(call_603665, url, valid)

proc call*(call_603666: Call_GetDeleteDBParameterGroup_603652;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603667 = newJObject()
  add(query_603667, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603667, "Action", newJString(Action))
  add(query_603667, "Version", newJString(Version))
  result = call_603666.call(nil, query_603667, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_603652(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_603653, base: "/",
    url: url_GetDeleteDBParameterGroup_603654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_603701 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSecurityGroup_603703(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_603702(path: JsonNode; query: JsonNode;
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
  var valid_603704 = query.getOrDefault("Action")
  valid_603704 = validateParameter(valid_603704, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603704 != nil:
    section.add "Action", valid_603704
  var valid_603705 = query.getOrDefault("Version")
  valid_603705 = validateParameter(valid_603705, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603705 != nil:
    section.add "Version", valid_603705
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603706 = header.getOrDefault("X-Amz-Date")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Date", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Security-Token")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Security-Token", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Content-Sha256", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-Algorithm")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-Algorithm", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Signature")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Signature", valid_603710
  var valid_603711 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603711 = validateParameter(valid_603711, JString, required = false,
                                 default = nil)
  if valid_603711 != nil:
    section.add "X-Amz-SignedHeaders", valid_603711
  var valid_603712 = header.getOrDefault("X-Amz-Credential")
  valid_603712 = validateParameter(valid_603712, JString, required = false,
                                 default = nil)
  if valid_603712 != nil:
    section.add "X-Amz-Credential", valid_603712
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603713 = formData.getOrDefault("DBSecurityGroupName")
  valid_603713 = validateParameter(valid_603713, JString, required = true,
                                 default = nil)
  if valid_603713 != nil:
    section.add "DBSecurityGroupName", valid_603713
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603714: Call_PostDeleteDBSecurityGroup_603701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603714.validator(path, query, header, formData, body)
  let scheme = call_603714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603714.url(scheme.get, call_603714.host, call_603714.base,
                         call_603714.route, valid.getOrDefault("path"))
  result = hook(call_603714, url, valid)

proc call*(call_603715: Call_PostDeleteDBSecurityGroup_603701;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603716 = newJObject()
  var formData_603717 = newJObject()
  add(formData_603717, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603716, "Action", newJString(Action))
  add(query_603716, "Version", newJString(Version))
  result = call_603715.call(nil, query_603716, nil, formData_603717, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_603701(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_603702, base: "/",
    url: url_PostDeleteDBSecurityGroup_603703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_603685 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSecurityGroup_603687(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_603686(path: JsonNode; query: JsonNode;
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
  var valid_603688 = query.getOrDefault("DBSecurityGroupName")
  valid_603688 = validateParameter(valid_603688, JString, required = true,
                                 default = nil)
  if valid_603688 != nil:
    section.add "DBSecurityGroupName", valid_603688
  var valid_603689 = query.getOrDefault("Action")
  valid_603689 = validateParameter(valid_603689, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603689 != nil:
    section.add "Action", valid_603689
  var valid_603690 = query.getOrDefault("Version")
  valid_603690 = validateParameter(valid_603690, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603690 != nil:
    section.add "Version", valid_603690
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603691 = header.getOrDefault("X-Amz-Date")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Date", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Security-Token")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Security-Token", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Content-Sha256", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-Algorithm")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-Algorithm", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Signature")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Signature", valid_603695
  var valid_603696 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603696 = validateParameter(valid_603696, JString, required = false,
                                 default = nil)
  if valid_603696 != nil:
    section.add "X-Amz-SignedHeaders", valid_603696
  var valid_603697 = header.getOrDefault("X-Amz-Credential")
  valid_603697 = validateParameter(valid_603697, JString, required = false,
                                 default = nil)
  if valid_603697 != nil:
    section.add "X-Amz-Credential", valid_603697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603698: Call_GetDeleteDBSecurityGroup_603685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603698.validator(path, query, header, formData, body)
  let scheme = call_603698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603698.url(scheme.get, call_603698.host, call_603698.base,
                         call_603698.route, valid.getOrDefault("path"))
  result = hook(call_603698, url, valid)

proc call*(call_603699: Call_GetDeleteDBSecurityGroup_603685;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603700 = newJObject()
  add(query_603700, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603700, "Action", newJString(Action))
  add(query_603700, "Version", newJString(Version))
  result = call_603699.call(nil, query_603700, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_603685(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_603686, base: "/",
    url: url_GetDeleteDBSecurityGroup_603687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_603734 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSnapshot_603736(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_603735(path: JsonNode; query: JsonNode;
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
  var valid_603737 = query.getOrDefault("Action")
  valid_603737 = validateParameter(valid_603737, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603737 != nil:
    section.add "Action", valid_603737
  var valid_603738 = query.getOrDefault("Version")
  valid_603738 = validateParameter(valid_603738, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603738 != nil:
    section.add "Version", valid_603738
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Security-Token")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Security-Token", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Content-Sha256", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Algorithm")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Algorithm", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Signature")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Signature", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-SignedHeaders", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Credential")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Credential", valid_603745
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_603746 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = nil)
  if valid_603746 != nil:
    section.add "DBSnapshotIdentifier", valid_603746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603747: Call_PostDeleteDBSnapshot_603734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603747.validator(path, query, header, formData, body)
  let scheme = call_603747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603747.url(scheme.get, call_603747.host, call_603747.base,
                         call_603747.route, valid.getOrDefault("path"))
  result = hook(call_603747, url, valid)

proc call*(call_603748: Call_PostDeleteDBSnapshot_603734;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603749 = newJObject()
  var formData_603750 = newJObject()
  add(formData_603750, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603749, "Action", newJString(Action))
  add(query_603749, "Version", newJString(Version))
  result = call_603748.call(nil, query_603749, nil, formData_603750, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_603734(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_603735, base: "/",
    url: url_PostDeleteDBSnapshot_603736, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_603718 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSnapshot_603720(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_603719(path: JsonNode; query: JsonNode;
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
  var valid_603721 = query.getOrDefault("Action")
  valid_603721 = validateParameter(valid_603721, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603721 != nil:
    section.add "Action", valid_603721
  var valid_603722 = query.getOrDefault("Version")
  valid_603722 = validateParameter(valid_603722, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603722 != nil:
    section.add "Version", valid_603722
  var valid_603723 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603723 = validateParameter(valid_603723, JString, required = true,
                                 default = nil)
  if valid_603723 != nil:
    section.add "DBSnapshotIdentifier", valid_603723
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Security-Token")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Security-Token", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Content-Sha256", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Algorithm")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Algorithm", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Signature")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Signature", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-SignedHeaders", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Credential")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Credential", valid_603730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603731: Call_GetDeleteDBSnapshot_603718; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603731.validator(path, query, header, formData, body)
  let scheme = call_603731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603731.url(scheme.get, call_603731.host, call_603731.base,
                         call_603731.route, valid.getOrDefault("path"))
  result = hook(call_603731, url, valid)

proc call*(call_603732: Call_GetDeleteDBSnapshot_603718;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603733 = newJObject()
  add(query_603733, "Action", newJString(Action))
  add(query_603733, "Version", newJString(Version))
  add(query_603733, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603732.call(nil, query_603733, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_603718(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_603719, base: "/",
    url: url_GetDeleteDBSnapshot_603720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603767 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSubnetGroup_603769(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_603768(path: JsonNode; query: JsonNode;
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
  var valid_603770 = query.getOrDefault("Action")
  valid_603770 = validateParameter(valid_603770, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603770 != nil:
    section.add "Action", valid_603770
  var valid_603771 = query.getOrDefault("Version")
  valid_603771 = validateParameter(valid_603771, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603771 != nil:
    section.add "Version", valid_603771
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603772 = header.getOrDefault("X-Amz-Date")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Date", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Security-Token")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Security-Token", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Content-Sha256", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Algorithm")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Algorithm", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Signature")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Signature", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-SignedHeaders", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Credential")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Credential", valid_603778
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603779 = formData.getOrDefault("DBSubnetGroupName")
  valid_603779 = validateParameter(valid_603779, JString, required = true,
                                 default = nil)
  if valid_603779 != nil:
    section.add "DBSubnetGroupName", valid_603779
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603780: Call_PostDeleteDBSubnetGroup_603767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603780.validator(path, query, header, formData, body)
  let scheme = call_603780.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603780.url(scheme.get, call_603780.host, call_603780.base,
                         call_603780.route, valid.getOrDefault("path"))
  result = hook(call_603780, url, valid)

proc call*(call_603781: Call_PostDeleteDBSubnetGroup_603767;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603782 = newJObject()
  var formData_603783 = newJObject()
  add(formData_603783, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603782, "Action", newJString(Action))
  add(query_603782, "Version", newJString(Version))
  result = call_603781.call(nil, query_603782, nil, formData_603783, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603767(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603768, base: "/",
    url: url_PostDeleteDBSubnetGroup_603769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603751 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSubnetGroup_603753(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_603752(path: JsonNode; query: JsonNode;
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
  var valid_603754 = query.getOrDefault("Action")
  valid_603754 = validateParameter(valid_603754, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603754 != nil:
    section.add "Action", valid_603754
  var valid_603755 = query.getOrDefault("DBSubnetGroupName")
  valid_603755 = validateParameter(valid_603755, JString, required = true,
                                 default = nil)
  if valid_603755 != nil:
    section.add "DBSubnetGroupName", valid_603755
  var valid_603756 = query.getOrDefault("Version")
  valid_603756 = validateParameter(valid_603756, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603756 != nil:
    section.add "Version", valid_603756
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603757 = header.getOrDefault("X-Amz-Date")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Date", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Security-Token")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Security-Token", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Content-Sha256", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Algorithm")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Algorithm", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Signature")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Signature", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-SignedHeaders", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Credential")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Credential", valid_603763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603764: Call_GetDeleteDBSubnetGroup_603751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603764.validator(path, query, header, formData, body)
  let scheme = call_603764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603764.url(scheme.get, call_603764.host, call_603764.base,
                         call_603764.route, valid.getOrDefault("path"))
  result = hook(call_603764, url, valid)

proc call*(call_603765: Call_GetDeleteDBSubnetGroup_603751;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603766 = newJObject()
  add(query_603766, "Action", newJString(Action))
  add(query_603766, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603766, "Version", newJString(Version))
  result = call_603765.call(nil, query_603766, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603751(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603752, base: "/",
    url: url_GetDeleteDBSubnetGroup_603753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_603800 = ref object of OpenApiRestCall_602417
proc url_PostDeleteEventSubscription_603802(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_603801(path: JsonNode; query: JsonNode;
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
  var valid_603803 = query.getOrDefault("Action")
  valid_603803 = validateParameter(valid_603803, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603803 != nil:
    section.add "Action", valid_603803
  var valid_603804 = query.getOrDefault("Version")
  valid_603804 = validateParameter(valid_603804, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603804 != nil:
    section.add "Version", valid_603804
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603805 = header.getOrDefault("X-Amz-Date")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Date", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Security-Token")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Security-Token", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Content-Sha256", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Algorithm")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Algorithm", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-Signature")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-Signature", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-SignedHeaders", valid_603810
  var valid_603811 = header.getOrDefault("X-Amz-Credential")
  valid_603811 = validateParameter(valid_603811, JString, required = false,
                                 default = nil)
  if valid_603811 != nil:
    section.add "X-Amz-Credential", valid_603811
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603812 = formData.getOrDefault("SubscriptionName")
  valid_603812 = validateParameter(valid_603812, JString, required = true,
                                 default = nil)
  if valid_603812 != nil:
    section.add "SubscriptionName", valid_603812
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603813: Call_PostDeleteEventSubscription_603800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603813.validator(path, query, header, formData, body)
  let scheme = call_603813.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603813.url(scheme.get, call_603813.host, call_603813.base,
                         call_603813.route, valid.getOrDefault("path"))
  result = hook(call_603813, url, valid)

proc call*(call_603814: Call_PostDeleteEventSubscription_603800;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603815 = newJObject()
  var formData_603816 = newJObject()
  add(formData_603816, "SubscriptionName", newJString(SubscriptionName))
  add(query_603815, "Action", newJString(Action))
  add(query_603815, "Version", newJString(Version))
  result = call_603814.call(nil, query_603815, nil, formData_603816, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_603800(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_603801, base: "/",
    url: url_PostDeleteEventSubscription_603802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_603784 = ref object of OpenApiRestCall_602417
proc url_GetDeleteEventSubscription_603786(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_603785(path: JsonNode; query: JsonNode;
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
  var valid_603787 = query.getOrDefault("Action")
  valid_603787 = validateParameter(valid_603787, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603787 != nil:
    section.add "Action", valid_603787
  var valid_603788 = query.getOrDefault("SubscriptionName")
  valid_603788 = validateParameter(valid_603788, JString, required = true,
                                 default = nil)
  if valid_603788 != nil:
    section.add "SubscriptionName", valid_603788
  var valid_603789 = query.getOrDefault("Version")
  valid_603789 = validateParameter(valid_603789, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603789 != nil:
    section.add "Version", valid_603789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603790 = header.getOrDefault("X-Amz-Date")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Date", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Security-Token")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Security-Token", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Content-Sha256", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Algorithm")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Algorithm", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Signature")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Signature", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-SignedHeaders", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Credential")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Credential", valid_603796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603797: Call_GetDeleteEventSubscription_603784; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603797.validator(path, query, header, formData, body)
  let scheme = call_603797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603797.url(scheme.get, call_603797.host, call_603797.base,
                         call_603797.route, valid.getOrDefault("path"))
  result = hook(call_603797, url, valid)

proc call*(call_603798: Call_GetDeleteEventSubscription_603784;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603799 = newJObject()
  add(query_603799, "Action", newJString(Action))
  add(query_603799, "SubscriptionName", newJString(SubscriptionName))
  add(query_603799, "Version", newJString(Version))
  result = call_603798.call(nil, query_603799, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_603784(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_603785, base: "/",
    url: url_GetDeleteEventSubscription_603786,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_603833 = ref object of OpenApiRestCall_602417
proc url_PostDeleteOptionGroup_603835(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_603834(path: JsonNode; query: JsonNode;
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
  var valid_603836 = query.getOrDefault("Action")
  valid_603836 = validateParameter(valid_603836, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603836 != nil:
    section.add "Action", valid_603836
  var valid_603837 = query.getOrDefault("Version")
  valid_603837 = validateParameter(valid_603837, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603837 != nil:
    section.add "Version", valid_603837
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603838 = header.getOrDefault("X-Amz-Date")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Date", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Security-Token")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Security-Token", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Content-Sha256", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Algorithm")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Algorithm", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-Signature")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-Signature", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-SignedHeaders", valid_603843
  var valid_603844 = header.getOrDefault("X-Amz-Credential")
  valid_603844 = validateParameter(valid_603844, JString, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "X-Amz-Credential", valid_603844
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603845 = formData.getOrDefault("OptionGroupName")
  valid_603845 = validateParameter(valid_603845, JString, required = true,
                                 default = nil)
  if valid_603845 != nil:
    section.add "OptionGroupName", valid_603845
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603846: Call_PostDeleteOptionGroup_603833; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603846.validator(path, query, header, formData, body)
  let scheme = call_603846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603846.url(scheme.get, call_603846.host, call_603846.base,
                         call_603846.route, valid.getOrDefault("path"))
  result = hook(call_603846, url, valid)

proc call*(call_603847: Call_PostDeleteOptionGroup_603833; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603848 = newJObject()
  var formData_603849 = newJObject()
  add(formData_603849, "OptionGroupName", newJString(OptionGroupName))
  add(query_603848, "Action", newJString(Action))
  add(query_603848, "Version", newJString(Version))
  result = call_603847.call(nil, query_603848, nil, formData_603849, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_603833(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_603834, base: "/",
    url: url_PostDeleteOptionGroup_603835, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_603817 = ref object of OpenApiRestCall_602417
proc url_GetDeleteOptionGroup_603819(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_603818(path: JsonNode; query: JsonNode;
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
  var valid_603820 = query.getOrDefault("OptionGroupName")
  valid_603820 = validateParameter(valid_603820, JString, required = true,
                                 default = nil)
  if valid_603820 != nil:
    section.add "OptionGroupName", valid_603820
  var valid_603821 = query.getOrDefault("Action")
  valid_603821 = validateParameter(valid_603821, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603821 != nil:
    section.add "Action", valid_603821
  var valid_603822 = query.getOrDefault("Version")
  valid_603822 = validateParameter(valid_603822, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603822 != nil:
    section.add "Version", valid_603822
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603823 = header.getOrDefault("X-Amz-Date")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Date", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Security-Token")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Security-Token", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-Content-Sha256", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Algorithm")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Algorithm", valid_603826
  var valid_603827 = header.getOrDefault("X-Amz-Signature")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "X-Amz-Signature", valid_603827
  var valid_603828 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603828 = validateParameter(valid_603828, JString, required = false,
                                 default = nil)
  if valid_603828 != nil:
    section.add "X-Amz-SignedHeaders", valid_603828
  var valid_603829 = header.getOrDefault("X-Amz-Credential")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "X-Amz-Credential", valid_603829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603830: Call_GetDeleteOptionGroup_603817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603830.validator(path, query, header, formData, body)
  let scheme = call_603830.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603830.url(scheme.get, call_603830.host, call_603830.base,
                         call_603830.route, valid.getOrDefault("path"))
  result = hook(call_603830, url, valid)

proc call*(call_603831: Call_GetDeleteOptionGroup_603817; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2014-09-01"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603832 = newJObject()
  add(query_603832, "OptionGroupName", newJString(OptionGroupName))
  add(query_603832, "Action", newJString(Action))
  add(query_603832, "Version", newJString(Version))
  result = call_603831.call(nil, query_603832, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_603817(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_603818, base: "/",
    url: url_GetDeleteOptionGroup_603819, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603873 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBEngineVersions_603875(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_603874(path: JsonNode; query: JsonNode;
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
  var valid_603876 = query.getOrDefault("Action")
  valid_603876 = validateParameter(valid_603876, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603876 != nil:
    section.add "Action", valid_603876
  var valid_603877 = query.getOrDefault("Version")
  valid_603877 = validateParameter(valid_603877, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603877 != nil:
    section.add "Version", valid_603877
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603878 = header.getOrDefault("X-Amz-Date")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Date", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Security-Token")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Security-Token", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Content-Sha256", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Algorithm")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Algorithm", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-Signature")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Signature", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-SignedHeaders", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Credential")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Credential", valid_603884
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
  var valid_603885 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603885 = validateParameter(valid_603885, JBool, required = false, default = nil)
  if valid_603885 != nil:
    section.add "ListSupportedCharacterSets", valid_603885
  var valid_603886 = formData.getOrDefault("Engine")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "Engine", valid_603886
  var valid_603887 = formData.getOrDefault("Marker")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "Marker", valid_603887
  var valid_603888 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "DBParameterGroupFamily", valid_603888
  var valid_603889 = formData.getOrDefault("Filters")
  valid_603889 = validateParameter(valid_603889, JArray, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "Filters", valid_603889
  var valid_603890 = formData.getOrDefault("MaxRecords")
  valid_603890 = validateParameter(valid_603890, JInt, required = false, default = nil)
  if valid_603890 != nil:
    section.add "MaxRecords", valid_603890
  var valid_603891 = formData.getOrDefault("EngineVersion")
  valid_603891 = validateParameter(valid_603891, JString, required = false,
                                 default = nil)
  if valid_603891 != nil:
    section.add "EngineVersion", valid_603891
  var valid_603892 = formData.getOrDefault("DefaultOnly")
  valid_603892 = validateParameter(valid_603892, JBool, required = false, default = nil)
  if valid_603892 != nil:
    section.add "DefaultOnly", valid_603892
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603893: Call_PostDescribeDBEngineVersions_603873; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603893.validator(path, query, header, formData, body)
  let scheme = call_603893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603893.url(scheme.get, call_603893.host, call_603893.base,
                         call_603893.route, valid.getOrDefault("path"))
  result = hook(call_603893, url, valid)

proc call*(call_603894: Call_PostDescribeDBEngineVersions_603873;
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
  var query_603895 = newJObject()
  var formData_603896 = newJObject()
  add(formData_603896, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603896, "Engine", newJString(Engine))
  add(formData_603896, "Marker", newJString(Marker))
  add(query_603895, "Action", newJString(Action))
  add(formData_603896, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603896.add "Filters", Filters
  add(formData_603896, "MaxRecords", newJInt(MaxRecords))
  add(formData_603896, "EngineVersion", newJString(EngineVersion))
  add(query_603895, "Version", newJString(Version))
  add(formData_603896, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603894.call(nil, query_603895, nil, formData_603896, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603873(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603874, base: "/",
    url: url_PostDescribeDBEngineVersions_603875,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603850 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBEngineVersions_603852(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_603851(path: JsonNode; query: JsonNode;
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
  var valid_603853 = query.getOrDefault("Engine")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "Engine", valid_603853
  var valid_603854 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603854 = validateParameter(valid_603854, JBool, required = false, default = nil)
  if valid_603854 != nil:
    section.add "ListSupportedCharacterSets", valid_603854
  var valid_603855 = query.getOrDefault("MaxRecords")
  valid_603855 = validateParameter(valid_603855, JInt, required = false, default = nil)
  if valid_603855 != nil:
    section.add "MaxRecords", valid_603855
  var valid_603856 = query.getOrDefault("DBParameterGroupFamily")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "DBParameterGroupFamily", valid_603856
  var valid_603857 = query.getOrDefault("Filters")
  valid_603857 = validateParameter(valid_603857, JArray, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "Filters", valid_603857
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603858 = query.getOrDefault("Action")
  valid_603858 = validateParameter(valid_603858, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603858 != nil:
    section.add "Action", valid_603858
  var valid_603859 = query.getOrDefault("Marker")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "Marker", valid_603859
  var valid_603860 = query.getOrDefault("EngineVersion")
  valid_603860 = validateParameter(valid_603860, JString, required = false,
                                 default = nil)
  if valid_603860 != nil:
    section.add "EngineVersion", valid_603860
  var valid_603861 = query.getOrDefault("DefaultOnly")
  valid_603861 = validateParameter(valid_603861, JBool, required = false, default = nil)
  if valid_603861 != nil:
    section.add "DefaultOnly", valid_603861
  var valid_603862 = query.getOrDefault("Version")
  valid_603862 = validateParameter(valid_603862, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603862 != nil:
    section.add "Version", valid_603862
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603863 = header.getOrDefault("X-Amz-Date")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Date", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Security-Token")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Security-Token", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Content-Sha256", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Algorithm")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Algorithm", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-Signature")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Signature", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-SignedHeaders", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Credential")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Credential", valid_603869
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603870: Call_GetDescribeDBEngineVersions_603850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603870.validator(path, query, header, formData, body)
  let scheme = call_603870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603870.url(scheme.get, call_603870.host, call_603870.base,
                         call_603870.route, valid.getOrDefault("path"))
  result = hook(call_603870, url, valid)

proc call*(call_603871: Call_GetDescribeDBEngineVersions_603850;
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
  var query_603872 = newJObject()
  add(query_603872, "Engine", newJString(Engine))
  add(query_603872, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603872, "MaxRecords", newJInt(MaxRecords))
  add(query_603872, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603872.add "Filters", Filters
  add(query_603872, "Action", newJString(Action))
  add(query_603872, "Marker", newJString(Marker))
  add(query_603872, "EngineVersion", newJString(EngineVersion))
  add(query_603872, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603872, "Version", newJString(Version))
  result = call_603871.call(nil, query_603872, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603850(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603851, base: "/",
    url: url_GetDescribeDBEngineVersions_603852,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603916 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBInstances_603918(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_603917(path: JsonNode; query: JsonNode;
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
  var valid_603919 = query.getOrDefault("Action")
  valid_603919 = validateParameter(valid_603919, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603919 != nil:
    section.add "Action", valid_603919
  var valid_603920 = query.getOrDefault("Version")
  valid_603920 = validateParameter(valid_603920, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603920 != nil:
    section.add "Version", valid_603920
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603921 = header.getOrDefault("X-Amz-Date")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Date", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Security-Token")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Security-Token", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Content-Sha256", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Algorithm")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Algorithm", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Signature")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Signature", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-SignedHeaders", valid_603926
  var valid_603927 = header.getOrDefault("X-Amz-Credential")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "X-Amz-Credential", valid_603927
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603928 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "DBInstanceIdentifier", valid_603928
  var valid_603929 = formData.getOrDefault("Marker")
  valid_603929 = validateParameter(valid_603929, JString, required = false,
                                 default = nil)
  if valid_603929 != nil:
    section.add "Marker", valid_603929
  var valid_603930 = formData.getOrDefault("Filters")
  valid_603930 = validateParameter(valid_603930, JArray, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "Filters", valid_603930
  var valid_603931 = formData.getOrDefault("MaxRecords")
  valid_603931 = validateParameter(valid_603931, JInt, required = false, default = nil)
  if valid_603931 != nil:
    section.add "MaxRecords", valid_603931
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603932: Call_PostDescribeDBInstances_603916; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603932.validator(path, query, header, formData, body)
  let scheme = call_603932.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603932.url(scheme.get, call_603932.host, call_603932.base,
                         call_603932.route, valid.getOrDefault("path"))
  result = hook(call_603932, url, valid)

proc call*(call_603933: Call_PostDescribeDBInstances_603916;
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
  var query_603934 = newJObject()
  var formData_603935 = newJObject()
  add(formData_603935, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603935, "Marker", newJString(Marker))
  add(query_603934, "Action", newJString(Action))
  if Filters != nil:
    formData_603935.add "Filters", Filters
  add(formData_603935, "MaxRecords", newJInt(MaxRecords))
  add(query_603934, "Version", newJString(Version))
  result = call_603933.call(nil, query_603934, nil, formData_603935, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603916(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603917, base: "/",
    url: url_PostDescribeDBInstances_603918, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603897 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBInstances_603899(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_603898(path: JsonNode; query: JsonNode;
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
  var valid_603900 = query.getOrDefault("MaxRecords")
  valid_603900 = validateParameter(valid_603900, JInt, required = false, default = nil)
  if valid_603900 != nil:
    section.add "MaxRecords", valid_603900
  var valid_603901 = query.getOrDefault("Filters")
  valid_603901 = validateParameter(valid_603901, JArray, required = false,
                                 default = nil)
  if valid_603901 != nil:
    section.add "Filters", valid_603901
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603902 = query.getOrDefault("Action")
  valid_603902 = validateParameter(valid_603902, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603902 != nil:
    section.add "Action", valid_603902
  var valid_603903 = query.getOrDefault("Marker")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "Marker", valid_603903
  var valid_603904 = query.getOrDefault("Version")
  valid_603904 = validateParameter(valid_603904, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603904 != nil:
    section.add "Version", valid_603904
  var valid_603905 = query.getOrDefault("DBInstanceIdentifier")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "DBInstanceIdentifier", valid_603905
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603906 = header.getOrDefault("X-Amz-Date")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Date", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Security-Token")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Security-Token", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Content-Sha256", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Algorithm")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Algorithm", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Signature")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Signature", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-SignedHeaders", valid_603911
  var valid_603912 = header.getOrDefault("X-Amz-Credential")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "X-Amz-Credential", valid_603912
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603913: Call_GetDescribeDBInstances_603897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603913.validator(path, query, header, formData, body)
  let scheme = call_603913.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603913.url(scheme.get, call_603913.host, call_603913.base,
                         call_603913.route, valid.getOrDefault("path"))
  result = hook(call_603913, url, valid)

proc call*(call_603914: Call_GetDescribeDBInstances_603897; MaxRecords: int = 0;
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
  var query_603915 = newJObject()
  add(query_603915, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603915.add "Filters", Filters
  add(query_603915, "Action", newJString(Action))
  add(query_603915, "Marker", newJString(Marker))
  add(query_603915, "Version", newJString(Version))
  add(query_603915, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603914.call(nil, query_603915, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603897(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603898, base: "/",
    url: url_GetDescribeDBInstances_603899, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_603958 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBLogFiles_603960(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_603959(path: JsonNode; query: JsonNode;
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
  var valid_603961 = query.getOrDefault("Action")
  valid_603961 = validateParameter(valid_603961, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603961 != nil:
    section.add "Action", valid_603961
  var valid_603962 = query.getOrDefault("Version")
  valid_603962 = validateParameter(valid_603962, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603962 != nil:
    section.add "Version", valid_603962
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603963 = header.getOrDefault("X-Amz-Date")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-Date", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-Security-Token")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Security-Token", valid_603964
  var valid_603965 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-Content-Sha256", valid_603965
  var valid_603966 = header.getOrDefault("X-Amz-Algorithm")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "X-Amz-Algorithm", valid_603966
  var valid_603967 = header.getOrDefault("X-Amz-Signature")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "X-Amz-Signature", valid_603967
  var valid_603968 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-SignedHeaders", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Credential")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Credential", valid_603969
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
  var valid_603970 = formData.getOrDefault("FilenameContains")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "FilenameContains", valid_603970
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603971 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603971 = validateParameter(valid_603971, JString, required = true,
                                 default = nil)
  if valid_603971 != nil:
    section.add "DBInstanceIdentifier", valid_603971
  var valid_603972 = formData.getOrDefault("FileSize")
  valid_603972 = validateParameter(valid_603972, JInt, required = false, default = nil)
  if valid_603972 != nil:
    section.add "FileSize", valid_603972
  var valid_603973 = formData.getOrDefault("Marker")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "Marker", valid_603973
  var valid_603974 = formData.getOrDefault("Filters")
  valid_603974 = validateParameter(valid_603974, JArray, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "Filters", valid_603974
  var valid_603975 = formData.getOrDefault("MaxRecords")
  valid_603975 = validateParameter(valid_603975, JInt, required = false, default = nil)
  if valid_603975 != nil:
    section.add "MaxRecords", valid_603975
  var valid_603976 = formData.getOrDefault("FileLastWritten")
  valid_603976 = validateParameter(valid_603976, JInt, required = false, default = nil)
  if valid_603976 != nil:
    section.add "FileLastWritten", valid_603976
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603977: Call_PostDescribeDBLogFiles_603958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603977.validator(path, query, header, formData, body)
  let scheme = call_603977.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603977.url(scheme.get, call_603977.host, call_603977.base,
                         call_603977.route, valid.getOrDefault("path"))
  result = hook(call_603977, url, valid)

proc call*(call_603978: Call_PostDescribeDBLogFiles_603958;
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
  var query_603979 = newJObject()
  var formData_603980 = newJObject()
  add(formData_603980, "FilenameContains", newJString(FilenameContains))
  add(formData_603980, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603980, "FileSize", newJInt(FileSize))
  add(formData_603980, "Marker", newJString(Marker))
  add(query_603979, "Action", newJString(Action))
  if Filters != nil:
    formData_603980.add "Filters", Filters
  add(formData_603980, "MaxRecords", newJInt(MaxRecords))
  add(formData_603980, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603979, "Version", newJString(Version))
  result = call_603978.call(nil, query_603979, nil, formData_603980, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_603958(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_603959, base: "/",
    url: url_PostDescribeDBLogFiles_603960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_603936 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBLogFiles_603938(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_603937(path: JsonNode; query: JsonNode;
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
  var valid_603939 = query.getOrDefault("FileLastWritten")
  valid_603939 = validateParameter(valid_603939, JInt, required = false, default = nil)
  if valid_603939 != nil:
    section.add "FileLastWritten", valid_603939
  var valid_603940 = query.getOrDefault("MaxRecords")
  valid_603940 = validateParameter(valid_603940, JInt, required = false, default = nil)
  if valid_603940 != nil:
    section.add "MaxRecords", valid_603940
  var valid_603941 = query.getOrDefault("FilenameContains")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "FilenameContains", valid_603941
  var valid_603942 = query.getOrDefault("FileSize")
  valid_603942 = validateParameter(valid_603942, JInt, required = false, default = nil)
  if valid_603942 != nil:
    section.add "FileSize", valid_603942
  var valid_603943 = query.getOrDefault("Filters")
  valid_603943 = validateParameter(valid_603943, JArray, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "Filters", valid_603943
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603944 = query.getOrDefault("Action")
  valid_603944 = validateParameter(valid_603944, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603944 != nil:
    section.add "Action", valid_603944
  var valid_603945 = query.getOrDefault("Marker")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "Marker", valid_603945
  var valid_603946 = query.getOrDefault("Version")
  valid_603946 = validateParameter(valid_603946, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603946 != nil:
    section.add "Version", valid_603946
  var valid_603947 = query.getOrDefault("DBInstanceIdentifier")
  valid_603947 = validateParameter(valid_603947, JString, required = true,
                                 default = nil)
  if valid_603947 != nil:
    section.add "DBInstanceIdentifier", valid_603947
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603948 = header.getOrDefault("X-Amz-Date")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Date", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-Security-Token")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Security-Token", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Content-Sha256", valid_603950
  var valid_603951 = header.getOrDefault("X-Amz-Algorithm")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "X-Amz-Algorithm", valid_603951
  var valid_603952 = header.getOrDefault("X-Amz-Signature")
  valid_603952 = validateParameter(valid_603952, JString, required = false,
                                 default = nil)
  if valid_603952 != nil:
    section.add "X-Amz-Signature", valid_603952
  var valid_603953 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-SignedHeaders", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Credential")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Credential", valid_603954
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603955: Call_GetDescribeDBLogFiles_603936; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603955.validator(path, query, header, formData, body)
  let scheme = call_603955.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603955.url(scheme.get, call_603955.host, call_603955.base,
                         call_603955.route, valid.getOrDefault("path"))
  result = hook(call_603955, url, valid)

proc call*(call_603956: Call_GetDescribeDBLogFiles_603936;
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
  var query_603957 = newJObject()
  add(query_603957, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603957, "MaxRecords", newJInt(MaxRecords))
  add(query_603957, "FilenameContains", newJString(FilenameContains))
  add(query_603957, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_603957.add "Filters", Filters
  add(query_603957, "Action", newJString(Action))
  add(query_603957, "Marker", newJString(Marker))
  add(query_603957, "Version", newJString(Version))
  add(query_603957, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603956.call(nil, query_603957, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_603936(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_603937, base: "/",
    url: url_GetDescribeDBLogFiles_603938, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_604000 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBParameterGroups_604002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_604001(path: JsonNode; query: JsonNode;
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
  var valid_604003 = query.getOrDefault("Action")
  valid_604003 = validateParameter(valid_604003, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_604003 != nil:
    section.add "Action", valid_604003
  var valid_604004 = query.getOrDefault("Version")
  valid_604004 = validateParameter(valid_604004, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604004 != nil:
    section.add "Version", valid_604004
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604005 = header.getOrDefault("X-Amz-Date")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Date", valid_604005
  var valid_604006 = header.getOrDefault("X-Amz-Security-Token")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "X-Amz-Security-Token", valid_604006
  var valid_604007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Content-Sha256", valid_604007
  var valid_604008 = header.getOrDefault("X-Amz-Algorithm")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "X-Amz-Algorithm", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-Signature")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Signature", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-SignedHeaders", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-Credential")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-Credential", valid_604011
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604012 = formData.getOrDefault("DBParameterGroupName")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "DBParameterGroupName", valid_604012
  var valid_604013 = formData.getOrDefault("Marker")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "Marker", valid_604013
  var valid_604014 = formData.getOrDefault("Filters")
  valid_604014 = validateParameter(valid_604014, JArray, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "Filters", valid_604014
  var valid_604015 = formData.getOrDefault("MaxRecords")
  valid_604015 = validateParameter(valid_604015, JInt, required = false, default = nil)
  if valid_604015 != nil:
    section.add "MaxRecords", valid_604015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604016: Call_PostDescribeDBParameterGroups_604000; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604016.validator(path, query, header, formData, body)
  let scheme = call_604016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604016.url(scheme.get, call_604016.host, call_604016.base,
                         call_604016.route, valid.getOrDefault("path"))
  result = hook(call_604016, url, valid)

proc call*(call_604017: Call_PostDescribeDBParameterGroups_604000;
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
  var query_604018 = newJObject()
  var formData_604019 = newJObject()
  add(formData_604019, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604019, "Marker", newJString(Marker))
  add(query_604018, "Action", newJString(Action))
  if Filters != nil:
    formData_604019.add "Filters", Filters
  add(formData_604019, "MaxRecords", newJInt(MaxRecords))
  add(query_604018, "Version", newJString(Version))
  result = call_604017.call(nil, query_604018, nil, formData_604019, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_604000(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_604001, base: "/",
    url: url_PostDescribeDBParameterGroups_604002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_603981 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBParameterGroups_603983(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_603982(path: JsonNode; query: JsonNode;
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
  var valid_603984 = query.getOrDefault("MaxRecords")
  valid_603984 = validateParameter(valid_603984, JInt, required = false, default = nil)
  if valid_603984 != nil:
    section.add "MaxRecords", valid_603984
  var valid_603985 = query.getOrDefault("Filters")
  valid_603985 = validateParameter(valid_603985, JArray, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "Filters", valid_603985
  var valid_603986 = query.getOrDefault("DBParameterGroupName")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "DBParameterGroupName", valid_603986
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603987 = query.getOrDefault("Action")
  valid_603987 = validateParameter(valid_603987, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603987 != nil:
    section.add "Action", valid_603987
  var valid_603988 = query.getOrDefault("Marker")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "Marker", valid_603988
  var valid_603989 = query.getOrDefault("Version")
  valid_603989 = validateParameter(valid_603989, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_603989 != nil:
    section.add "Version", valid_603989
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603990 = header.getOrDefault("X-Amz-Date")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Date", valid_603990
  var valid_603991 = header.getOrDefault("X-Amz-Security-Token")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "X-Amz-Security-Token", valid_603991
  var valid_603992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Content-Sha256", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Algorithm")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Algorithm", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Signature")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Signature", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-SignedHeaders", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Credential")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Credential", valid_603996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603997: Call_GetDescribeDBParameterGroups_603981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603997.validator(path, query, header, formData, body)
  let scheme = call_603997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603997.url(scheme.get, call_603997.host, call_603997.base,
                         call_603997.route, valid.getOrDefault("path"))
  result = hook(call_603997, url, valid)

proc call*(call_603998: Call_GetDescribeDBParameterGroups_603981;
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
  var query_603999 = newJObject()
  add(query_603999, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603999.add "Filters", Filters
  add(query_603999, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603999, "Action", newJString(Action))
  add(query_603999, "Marker", newJString(Marker))
  add(query_603999, "Version", newJString(Version))
  result = call_603998.call(nil, query_603999, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_603981(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_603982, base: "/",
    url: url_GetDescribeDBParameterGroups_603983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_604040 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBParameters_604042(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_604041(path: JsonNode; query: JsonNode;
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
  var valid_604043 = query.getOrDefault("Action")
  valid_604043 = validateParameter(valid_604043, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_604043 != nil:
    section.add "Action", valid_604043
  var valid_604044 = query.getOrDefault("Version")
  valid_604044 = validateParameter(valid_604044, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604044 != nil:
    section.add "Version", valid_604044
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604045 = header.getOrDefault("X-Amz-Date")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-Date", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Security-Token")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Security-Token", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Content-Sha256", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-Algorithm")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Algorithm", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Signature")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Signature", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-SignedHeaders", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-Credential")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-Credential", valid_604051
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604052 = formData.getOrDefault("DBParameterGroupName")
  valid_604052 = validateParameter(valid_604052, JString, required = true,
                                 default = nil)
  if valid_604052 != nil:
    section.add "DBParameterGroupName", valid_604052
  var valid_604053 = formData.getOrDefault("Marker")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "Marker", valid_604053
  var valid_604054 = formData.getOrDefault("Filters")
  valid_604054 = validateParameter(valid_604054, JArray, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "Filters", valid_604054
  var valid_604055 = formData.getOrDefault("MaxRecords")
  valid_604055 = validateParameter(valid_604055, JInt, required = false, default = nil)
  if valid_604055 != nil:
    section.add "MaxRecords", valid_604055
  var valid_604056 = formData.getOrDefault("Source")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "Source", valid_604056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604057: Call_PostDescribeDBParameters_604040; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604057.validator(path, query, header, formData, body)
  let scheme = call_604057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604057.url(scheme.get, call_604057.host, call_604057.base,
                         call_604057.route, valid.getOrDefault("path"))
  result = hook(call_604057, url, valid)

proc call*(call_604058: Call_PostDescribeDBParameters_604040;
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
  var query_604059 = newJObject()
  var formData_604060 = newJObject()
  add(formData_604060, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604060, "Marker", newJString(Marker))
  add(query_604059, "Action", newJString(Action))
  if Filters != nil:
    formData_604060.add "Filters", Filters
  add(formData_604060, "MaxRecords", newJInt(MaxRecords))
  add(query_604059, "Version", newJString(Version))
  add(formData_604060, "Source", newJString(Source))
  result = call_604058.call(nil, query_604059, nil, formData_604060, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_604040(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_604041, base: "/",
    url: url_PostDescribeDBParameters_604042, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_604020 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBParameters_604022(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_604021(path: JsonNode; query: JsonNode;
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
  var valid_604023 = query.getOrDefault("MaxRecords")
  valid_604023 = validateParameter(valid_604023, JInt, required = false, default = nil)
  if valid_604023 != nil:
    section.add "MaxRecords", valid_604023
  var valid_604024 = query.getOrDefault("Filters")
  valid_604024 = validateParameter(valid_604024, JArray, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "Filters", valid_604024
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_604025 = query.getOrDefault("DBParameterGroupName")
  valid_604025 = validateParameter(valid_604025, JString, required = true,
                                 default = nil)
  if valid_604025 != nil:
    section.add "DBParameterGroupName", valid_604025
  var valid_604026 = query.getOrDefault("Action")
  valid_604026 = validateParameter(valid_604026, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_604026 != nil:
    section.add "Action", valid_604026
  var valid_604027 = query.getOrDefault("Marker")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "Marker", valid_604027
  var valid_604028 = query.getOrDefault("Source")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "Source", valid_604028
  var valid_604029 = query.getOrDefault("Version")
  valid_604029 = validateParameter(valid_604029, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604029 != nil:
    section.add "Version", valid_604029
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604030 = header.getOrDefault("X-Amz-Date")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-Date", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Security-Token")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Security-Token", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Content-Sha256", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Algorithm")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Algorithm", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Signature")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Signature", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-SignedHeaders", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-Credential")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Credential", valid_604036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604037: Call_GetDescribeDBParameters_604020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604037.validator(path, query, header, formData, body)
  let scheme = call_604037.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604037.url(scheme.get, call_604037.host, call_604037.base,
                         call_604037.route, valid.getOrDefault("path"))
  result = hook(call_604037, url, valid)

proc call*(call_604038: Call_GetDescribeDBParameters_604020;
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
  var query_604039 = newJObject()
  add(query_604039, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604039.add "Filters", Filters
  add(query_604039, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604039, "Action", newJString(Action))
  add(query_604039, "Marker", newJString(Marker))
  add(query_604039, "Source", newJString(Source))
  add(query_604039, "Version", newJString(Version))
  result = call_604038.call(nil, query_604039, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_604020(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_604021, base: "/",
    url: url_GetDescribeDBParameters_604022, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_604080 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSecurityGroups_604082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_604081(path: JsonNode; query: JsonNode;
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
  var valid_604083 = query.getOrDefault("Action")
  valid_604083 = validateParameter(valid_604083, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_604083 != nil:
    section.add "Action", valid_604083
  var valid_604084 = query.getOrDefault("Version")
  valid_604084 = validateParameter(valid_604084, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604084 != nil:
    section.add "Version", valid_604084
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604085 = header.getOrDefault("X-Amz-Date")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Date", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Security-Token")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Security-Token", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Content-Sha256", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-Algorithm")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-Algorithm", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Signature")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Signature", valid_604089
  var valid_604090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "X-Amz-SignedHeaders", valid_604090
  var valid_604091 = header.getOrDefault("X-Amz-Credential")
  valid_604091 = validateParameter(valid_604091, JString, required = false,
                                 default = nil)
  if valid_604091 != nil:
    section.add "X-Amz-Credential", valid_604091
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604092 = formData.getOrDefault("DBSecurityGroupName")
  valid_604092 = validateParameter(valid_604092, JString, required = false,
                                 default = nil)
  if valid_604092 != nil:
    section.add "DBSecurityGroupName", valid_604092
  var valid_604093 = formData.getOrDefault("Marker")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "Marker", valid_604093
  var valid_604094 = formData.getOrDefault("Filters")
  valid_604094 = validateParameter(valid_604094, JArray, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "Filters", valid_604094
  var valid_604095 = formData.getOrDefault("MaxRecords")
  valid_604095 = validateParameter(valid_604095, JInt, required = false, default = nil)
  if valid_604095 != nil:
    section.add "MaxRecords", valid_604095
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604096: Call_PostDescribeDBSecurityGroups_604080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604096.validator(path, query, header, formData, body)
  let scheme = call_604096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604096.url(scheme.get, call_604096.host, call_604096.base,
                         call_604096.route, valid.getOrDefault("path"))
  result = hook(call_604096, url, valid)

proc call*(call_604097: Call_PostDescribeDBSecurityGroups_604080;
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
  var query_604098 = newJObject()
  var formData_604099 = newJObject()
  add(formData_604099, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604099, "Marker", newJString(Marker))
  add(query_604098, "Action", newJString(Action))
  if Filters != nil:
    formData_604099.add "Filters", Filters
  add(formData_604099, "MaxRecords", newJInt(MaxRecords))
  add(query_604098, "Version", newJString(Version))
  result = call_604097.call(nil, query_604098, nil, formData_604099, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_604080(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_604081, base: "/",
    url: url_PostDescribeDBSecurityGroups_604082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_604061 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSecurityGroups_604063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_604062(path: JsonNode; query: JsonNode;
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
  var valid_604064 = query.getOrDefault("MaxRecords")
  valid_604064 = validateParameter(valid_604064, JInt, required = false, default = nil)
  if valid_604064 != nil:
    section.add "MaxRecords", valid_604064
  var valid_604065 = query.getOrDefault("DBSecurityGroupName")
  valid_604065 = validateParameter(valid_604065, JString, required = false,
                                 default = nil)
  if valid_604065 != nil:
    section.add "DBSecurityGroupName", valid_604065
  var valid_604066 = query.getOrDefault("Filters")
  valid_604066 = validateParameter(valid_604066, JArray, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "Filters", valid_604066
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604067 = query.getOrDefault("Action")
  valid_604067 = validateParameter(valid_604067, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_604067 != nil:
    section.add "Action", valid_604067
  var valid_604068 = query.getOrDefault("Marker")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "Marker", valid_604068
  var valid_604069 = query.getOrDefault("Version")
  valid_604069 = validateParameter(valid_604069, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604069 != nil:
    section.add "Version", valid_604069
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604070 = header.getOrDefault("X-Amz-Date")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Date", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Security-Token")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Security-Token", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Content-Sha256", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-Algorithm")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Algorithm", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Signature")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Signature", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-SignedHeaders", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Credential")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Credential", valid_604076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604077: Call_GetDescribeDBSecurityGroups_604061; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604077.validator(path, query, header, formData, body)
  let scheme = call_604077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604077.url(scheme.get, call_604077.host, call_604077.base,
                         call_604077.route, valid.getOrDefault("path"))
  result = hook(call_604077, url, valid)

proc call*(call_604078: Call_GetDescribeDBSecurityGroups_604061;
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
  var query_604079 = newJObject()
  add(query_604079, "MaxRecords", newJInt(MaxRecords))
  add(query_604079, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_604079.add "Filters", Filters
  add(query_604079, "Action", newJString(Action))
  add(query_604079, "Marker", newJString(Marker))
  add(query_604079, "Version", newJString(Version))
  result = call_604078.call(nil, query_604079, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_604061(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_604062, base: "/",
    url: url_GetDescribeDBSecurityGroups_604063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_604121 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSnapshots_604123(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_604122(path: JsonNode; query: JsonNode;
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
  var valid_604124 = query.getOrDefault("Action")
  valid_604124 = validateParameter(valid_604124, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604124 != nil:
    section.add "Action", valid_604124
  var valid_604125 = query.getOrDefault("Version")
  valid_604125 = validateParameter(valid_604125, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604125 != nil:
    section.add "Version", valid_604125
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604126 = header.getOrDefault("X-Amz-Date")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Date", valid_604126
  var valid_604127 = header.getOrDefault("X-Amz-Security-Token")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "X-Amz-Security-Token", valid_604127
  var valid_604128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Content-Sha256", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Algorithm")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Algorithm", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Signature")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Signature", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-SignedHeaders", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Credential")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Credential", valid_604132
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604133 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "DBInstanceIdentifier", valid_604133
  var valid_604134 = formData.getOrDefault("SnapshotType")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "SnapshotType", valid_604134
  var valid_604135 = formData.getOrDefault("Marker")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "Marker", valid_604135
  var valid_604136 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "DBSnapshotIdentifier", valid_604136
  var valid_604137 = formData.getOrDefault("Filters")
  valid_604137 = validateParameter(valid_604137, JArray, required = false,
                                 default = nil)
  if valid_604137 != nil:
    section.add "Filters", valid_604137
  var valid_604138 = formData.getOrDefault("MaxRecords")
  valid_604138 = validateParameter(valid_604138, JInt, required = false, default = nil)
  if valid_604138 != nil:
    section.add "MaxRecords", valid_604138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604139: Call_PostDescribeDBSnapshots_604121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604139.validator(path, query, header, formData, body)
  let scheme = call_604139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604139.url(scheme.get, call_604139.host, call_604139.base,
                         call_604139.route, valid.getOrDefault("path"))
  result = hook(call_604139, url, valid)

proc call*(call_604140: Call_PostDescribeDBSnapshots_604121;
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
  var query_604141 = newJObject()
  var formData_604142 = newJObject()
  add(formData_604142, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604142, "SnapshotType", newJString(SnapshotType))
  add(formData_604142, "Marker", newJString(Marker))
  add(formData_604142, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604141, "Action", newJString(Action))
  if Filters != nil:
    formData_604142.add "Filters", Filters
  add(formData_604142, "MaxRecords", newJInt(MaxRecords))
  add(query_604141, "Version", newJString(Version))
  result = call_604140.call(nil, query_604141, nil, formData_604142, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_604121(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_604122, base: "/",
    url: url_PostDescribeDBSnapshots_604123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_604100 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSnapshots_604102(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_604101(path: JsonNode; query: JsonNode;
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
  var valid_604103 = query.getOrDefault("MaxRecords")
  valid_604103 = validateParameter(valid_604103, JInt, required = false, default = nil)
  if valid_604103 != nil:
    section.add "MaxRecords", valid_604103
  var valid_604104 = query.getOrDefault("Filters")
  valid_604104 = validateParameter(valid_604104, JArray, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "Filters", valid_604104
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604105 = query.getOrDefault("Action")
  valid_604105 = validateParameter(valid_604105, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604105 != nil:
    section.add "Action", valid_604105
  var valid_604106 = query.getOrDefault("Marker")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "Marker", valid_604106
  var valid_604107 = query.getOrDefault("SnapshotType")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "SnapshotType", valid_604107
  var valid_604108 = query.getOrDefault("Version")
  valid_604108 = validateParameter(valid_604108, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604108 != nil:
    section.add "Version", valid_604108
  var valid_604109 = query.getOrDefault("DBInstanceIdentifier")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "DBInstanceIdentifier", valid_604109
  var valid_604110 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "DBSnapshotIdentifier", valid_604110
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604111 = header.getOrDefault("X-Amz-Date")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Date", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Security-Token")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Security-Token", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-Content-Sha256", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Algorithm")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Algorithm", valid_604114
  var valid_604115 = header.getOrDefault("X-Amz-Signature")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "X-Amz-Signature", valid_604115
  var valid_604116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604116 = validateParameter(valid_604116, JString, required = false,
                                 default = nil)
  if valid_604116 != nil:
    section.add "X-Amz-SignedHeaders", valid_604116
  var valid_604117 = header.getOrDefault("X-Amz-Credential")
  valid_604117 = validateParameter(valid_604117, JString, required = false,
                                 default = nil)
  if valid_604117 != nil:
    section.add "X-Amz-Credential", valid_604117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604118: Call_GetDescribeDBSnapshots_604100; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604118.validator(path, query, header, formData, body)
  let scheme = call_604118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604118.url(scheme.get, call_604118.host, call_604118.base,
                         call_604118.route, valid.getOrDefault("path"))
  result = hook(call_604118, url, valid)

proc call*(call_604119: Call_GetDescribeDBSnapshots_604100; MaxRecords: int = 0;
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
  var query_604120 = newJObject()
  add(query_604120, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604120.add "Filters", Filters
  add(query_604120, "Action", newJString(Action))
  add(query_604120, "Marker", newJString(Marker))
  add(query_604120, "SnapshotType", newJString(SnapshotType))
  add(query_604120, "Version", newJString(Version))
  add(query_604120, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604120, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604119.call(nil, query_604120, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_604100(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_604101, base: "/",
    url: url_GetDescribeDBSnapshots_604102, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_604162 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSubnetGroups_604164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_604163(path: JsonNode; query: JsonNode;
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
  var valid_604165 = query.getOrDefault("Action")
  valid_604165 = validateParameter(valid_604165, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604165 != nil:
    section.add "Action", valid_604165
  var valid_604166 = query.getOrDefault("Version")
  valid_604166 = validateParameter(valid_604166, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604166 != nil:
    section.add "Version", valid_604166
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604167 = header.getOrDefault("X-Amz-Date")
  valid_604167 = validateParameter(valid_604167, JString, required = false,
                                 default = nil)
  if valid_604167 != nil:
    section.add "X-Amz-Date", valid_604167
  var valid_604168 = header.getOrDefault("X-Amz-Security-Token")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "X-Amz-Security-Token", valid_604168
  var valid_604169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604169 = validateParameter(valid_604169, JString, required = false,
                                 default = nil)
  if valid_604169 != nil:
    section.add "X-Amz-Content-Sha256", valid_604169
  var valid_604170 = header.getOrDefault("X-Amz-Algorithm")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Algorithm", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-Signature")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Signature", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-SignedHeaders", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Credential")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Credential", valid_604173
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604174 = formData.getOrDefault("DBSubnetGroupName")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "DBSubnetGroupName", valid_604174
  var valid_604175 = formData.getOrDefault("Marker")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "Marker", valid_604175
  var valid_604176 = formData.getOrDefault("Filters")
  valid_604176 = validateParameter(valid_604176, JArray, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "Filters", valid_604176
  var valid_604177 = formData.getOrDefault("MaxRecords")
  valid_604177 = validateParameter(valid_604177, JInt, required = false, default = nil)
  if valid_604177 != nil:
    section.add "MaxRecords", valid_604177
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604178: Call_PostDescribeDBSubnetGroups_604162; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604178.validator(path, query, header, formData, body)
  let scheme = call_604178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604178.url(scheme.get, call_604178.host, call_604178.base,
                         call_604178.route, valid.getOrDefault("path"))
  result = hook(call_604178, url, valid)

proc call*(call_604179: Call_PostDescribeDBSubnetGroups_604162;
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
  var query_604180 = newJObject()
  var formData_604181 = newJObject()
  add(formData_604181, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604181, "Marker", newJString(Marker))
  add(query_604180, "Action", newJString(Action))
  if Filters != nil:
    formData_604181.add "Filters", Filters
  add(formData_604181, "MaxRecords", newJInt(MaxRecords))
  add(query_604180, "Version", newJString(Version))
  result = call_604179.call(nil, query_604180, nil, formData_604181, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_604162(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_604163, base: "/",
    url: url_PostDescribeDBSubnetGroups_604164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_604143 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSubnetGroups_604145(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_604144(path: JsonNode; query: JsonNode;
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
  var valid_604146 = query.getOrDefault("MaxRecords")
  valid_604146 = validateParameter(valid_604146, JInt, required = false, default = nil)
  if valid_604146 != nil:
    section.add "MaxRecords", valid_604146
  var valid_604147 = query.getOrDefault("Filters")
  valid_604147 = validateParameter(valid_604147, JArray, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "Filters", valid_604147
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604148 = query.getOrDefault("Action")
  valid_604148 = validateParameter(valid_604148, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604148 != nil:
    section.add "Action", valid_604148
  var valid_604149 = query.getOrDefault("Marker")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "Marker", valid_604149
  var valid_604150 = query.getOrDefault("DBSubnetGroupName")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "DBSubnetGroupName", valid_604150
  var valid_604151 = query.getOrDefault("Version")
  valid_604151 = validateParameter(valid_604151, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604151 != nil:
    section.add "Version", valid_604151
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604152 = header.getOrDefault("X-Amz-Date")
  valid_604152 = validateParameter(valid_604152, JString, required = false,
                                 default = nil)
  if valid_604152 != nil:
    section.add "X-Amz-Date", valid_604152
  var valid_604153 = header.getOrDefault("X-Amz-Security-Token")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Security-Token", valid_604153
  var valid_604154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Content-Sha256", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Algorithm")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Algorithm", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Signature")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Signature", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-SignedHeaders", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Credential")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Credential", valid_604158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604159: Call_GetDescribeDBSubnetGroups_604143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604159.validator(path, query, header, formData, body)
  let scheme = call_604159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604159.url(scheme.get, call_604159.host, call_604159.base,
                         call_604159.route, valid.getOrDefault("path"))
  result = hook(call_604159, url, valid)

proc call*(call_604160: Call_GetDescribeDBSubnetGroups_604143; MaxRecords: int = 0;
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
  var query_604161 = newJObject()
  add(query_604161, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604161.add "Filters", Filters
  add(query_604161, "Action", newJString(Action))
  add(query_604161, "Marker", newJString(Marker))
  add(query_604161, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604161, "Version", newJString(Version))
  result = call_604160.call(nil, query_604161, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_604143(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_604144, base: "/",
    url: url_GetDescribeDBSubnetGroups_604145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_604201 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEngineDefaultParameters_604203(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_604202(path: JsonNode;
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
  var valid_604204 = query.getOrDefault("Action")
  valid_604204 = validateParameter(valid_604204, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604204 != nil:
    section.add "Action", valid_604204
  var valid_604205 = query.getOrDefault("Version")
  valid_604205 = validateParameter(valid_604205, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604205 != nil:
    section.add "Version", valid_604205
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604206 = header.getOrDefault("X-Amz-Date")
  valid_604206 = validateParameter(valid_604206, JString, required = false,
                                 default = nil)
  if valid_604206 != nil:
    section.add "X-Amz-Date", valid_604206
  var valid_604207 = header.getOrDefault("X-Amz-Security-Token")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "X-Amz-Security-Token", valid_604207
  var valid_604208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604208 = validateParameter(valid_604208, JString, required = false,
                                 default = nil)
  if valid_604208 != nil:
    section.add "X-Amz-Content-Sha256", valid_604208
  var valid_604209 = header.getOrDefault("X-Amz-Algorithm")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "X-Amz-Algorithm", valid_604209
  var valid_604210 = header.getOrDefault("X-Amz-Signature")
  valid_604210 = validateParameter(valid_604210, JString, required = false,
                                 default = nil)
  if valid_604210 != nil:
    section.add "X-Amz-Signature", valid_604210
  var valid_604211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604211 = validateParameter(valid_604211, JString, required = false,
                                 default = nil)
  if valid_604211 != nil:
    section.add "X-Amz-SignedHeaders", valid_604211
  var valid_604212 = header.getOrDefault("X-Amz-Credential")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "X-Amz-Credential", valid_604212
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604213 = formData.getOrDefault("Marker")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "Marker", valid_604213
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604214 = formData.getOrDefault("DBParameterGroupFamily")
  valid_604214 = validateParameter(valid_604214, JString, required = true,
                                 default = nil)
  if valid_604214 != nil:
    section.add "DBParameterGroupFamily", valid_604214
  var valid_604215 = formData.getOrDefault("Filters")
  valid_604215 = validateParameter(valid_604215, JArray, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "Filters", valid_604215
  var valid_604216 = formData.getOrDefault("MaxRecords")
  valid_604216 = validateParameter(valid_604216, JInt, required = false, default = nil)
  if valid_604216 != nil:
    section.add "MaxRecords", valid_604216
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604217: Call_PostDescribeEngineDefaultParameters_604201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604217.validator(path, query, header, formData, body)
  let scheme = call_604217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604217.url(scheme.get, call_604217.host, call_604217.base,
                         call_604217.route, valid.getOrDefault("path"))
  result = hook(call_604217, url, valid)

proc call*(call_604218: Call_PostDescribeEngineDefaultParameters_604201;
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
  var query_604219 = newJObject()
  var formData_604220 = newJObject()
  add(formData_604220, "Marker", newJString(Marker))
  add(query_604219, "Action", newJString(Action))
  add(formData_604220, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_604220.add "Filters", Filters
  add(formData_604220, "MaxRecords", newJInt(MaxRecords))
  add(query_604219, "Version", newJString(Version))
  result = call_604218.call(nil, query_604219, nil, formData_604220, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_604201(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_604202, base: "/",
    url: url_PostDescribeEngineDefaultParameters_604203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_604182 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEngineDefaultParameters_604184(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_604183(path: JsonNode;
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
  var valid_604185 = query.getOrDefault("MaxRecords")
  valid_604185 = validateParameter(valid_604185, JInt, required = false, default = nil)
  if valid_604185 != nil:
    section.add "MaxRecords", valid_604185
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604186 = query.getOrDefault("DBParameterGroupFamily")
  valid_604186 = validateParameter(valid_604186, JString, required = true,
                                 default = nil)
  if valid_604186 != nil:
    section.add "DBParameterGroupFamily", valid_604186
  var valid_604187 = query.getOrDefault("Filters")
  valid_604187 = validateParameter(valid_604187, JArray, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "Filters", valid_604187
  var valid_604188 = query.getOrDefault("Action")
  valid_604188 = validateParameter(valid_604188, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604188 != nil:
    section.add "Action", valid_604188
  var valid_604189 = query.getOrDefault("Marker")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "Marker", valid_604189
  var valid_604190 = query.getOrDefault("Version")
  valid_604190 = validateParameter(valid_604190, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604190 != nil:
    section.add "Version", valid_604190
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604191 = header.getOrDefault("X-Amz-Date")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Date", valid_604191
  var valid_604192 = header.getOrDefault("X-Amz-Security-Token")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "X-Amz-Security-Token", valid_604192
  var valid_604193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604193 = validateParameter(valid_604193, JString, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "X-Amz-Content-Sha256", valid_604193
  var valid_604194 = header.getOrDefault("X-Amz-Algorithm")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Algorithm", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Signature")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Signature", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-SignedHeaders", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Credential")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Credential", valid_604197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604198: Call_GetDescribeEngineDefaultParameters_604182;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604198.validator(path, query, header, formData, body)
  let scheme = call_604198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604198.url(scheme.get, call_604198.host, call_604198.base,
                         call_604198.route, valid.getOrDefault("path"))
  result = hook(call_604198, url, valid)

proc call*(call_604199: Call_GetDescribeEngineDefaultParameters_604182;
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
  var query_604200 = newJObject()
  add(query_604200, "MaxRecords", newJInt(MaxRecords))
  add(query_604200, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_604200.add "Filters", Filters
  add(query_604200, "Action", newJString(Action))
  add(query_604200, "Marker", newJString(Marker))
  add(query_604200, "Version", newJString(Version))
  result = call_604199.call(nil, query_604200, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_604182(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_604183, base: "/",
    url: url_GetDescribeEngineDefaultParameters_604184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604238 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEventCategories_604240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_604239(path: JsonNode; query: JsonNode;
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
  var valid_604241 = query.getOrDefault("Action")
  valid_604241 = validateParameter(valid_604241, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604241 != nil:
    section.add "Action", valid_604241
  var valid_604242 = query.getOrDefault("Version")
  valid_604242 = validateParameter(valid_604242, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604242 != nil:
    section.add "Version", valid_604242
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604243 = header.getOrDefault("X-Amz-Date")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-Date", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Security-Token")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Security-Token", valid_604244
  var valid_604245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "X-Amz-Content-Sha256", valid_604245
  var valid_604246 = header.getOrDefault("X-Amz-Algorithm")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "X-Amz-Algorithm", valid_604246
  var valid_604247 = header.getOrDefault("X-Amz-Signature")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "X-Amz-Signature", valid_604247
  var valid_604248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "X-Amz-SignedHeaders", valid_604248
  var valid_604249 = header.getOrDefault("X-Amz-Credential")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "X-Amz-Credential", valid_604249
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_604250 = formData.getOrDefault("Filters")
  valid_604250 = validateParameter(valid_604250, JArray, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "Filters", valid_604250
  var valid_604251 = formData.getOrDefault("SourceType")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "SourceType", valid_604251
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604252: Call_PostDescribeEventCategories_604238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604252.validator(path, query, header, formData, body)
  let scheme = call_604252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604252.url(scheme.get, call_604252.host, call_604252.base,
                         call_604252.route, valid.getOrDefault("path"))
  result = hook(call_604252, url, valid)

proc call*(call_604253: Call_PostDescribeEventCategories_604238;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_604254 = newJObject()
  var formData_604255 = newJObject()
  add(query_604254, "Action", newJString(Action))
  if Filters != nil:
    formData_604255.add "Filters", Filters
  add(query_604254, "Version", newJString(Version))
  add(formData_604255, "SourceType", newJString(SourceType))
  result = call_604253.call(nil, query_604254, nil, formData_604255, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604238(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604239, base: "/",
    url: url_PostDescribeEventCategories_604240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604221 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEventCategories_604223(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_604222(path: JsonNode; query: JsonNode;
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
  var valid_604224 = query.getOrDefault("SourceType")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "SourceType", valid_604224
  var valid_604225 = query.getOrDefault("Filters")
  valid_604225 = validateParameter(valid_604225, JArray, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "Filters", valid_604225
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604226 = query.getOrDefault("Action")
  valid_604226 = validateParameter(valid_604226, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604226 != nil:
    section.add "Action", valid_604226
  var valid_604227 = query.getOrDefault("Version")
  valid_604227 = validateParameter(valid_604227, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604227 != nil:
    section.add "Version", valid_604227
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604228 = header.getOrDefault("X-Amz-Date")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-Date", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Security-Token")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Security-Token", valid_604229
  var valid_604230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604230 = validateParameter(valid_604230, JString, required = false,
                                 default = nil)
  if valid_604230 != nil:
    section.add "X-Amz-Content-Sha256", valid_604230
  var valid_604231 = header.getOrDefault("X-Amz-Algorithm")
  valid_604231 = validateParameter(valid_604231, JString, required = false,
                                 default = nil)
  if valid_604231 != nil:
    section.add "X-Amz-Algorithm", valid_604231
  var valid_604232 = header.getOrDefault("X-Amz-Signature")
  valid_604232 = validateParameter(valid_604232, JString, required = false,
                                 default = nil)
  if valid_604232 != nil:
    section.add "X-Amz-Signature", valid_604232
  var valid_604233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604233 = validateParameter(valid_604233, JString, required = false,
                                 default = nil)
  if valid_604233 != nil:
    section.add "X-Amz-SignedHeaders", valid_604233
  var valid_604234 = header.getOrDefault("X-Amz-Credential")
  valid_604234 = validateParameter(valid_604234, JString, required = false,
                                 default = nil)
  if valid_604234 != nil:
    section.add "X-Amz-Credential", valid_604234
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604235: Call_GetDescribeEventCategories_604221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604235.validator(path, query, header, formData, body)
  let scheme = call_604235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604235.url(scheme.get, call_604235.host, call_604235.base,
                         call_604235.route, valid.getOrDefault("path"))
  result = hook(call_604235, url, valid)

proc call*(call_604236: Call_GetDescribeEventCategories_604221;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2014-09-01"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604237 = newJObject()
  add(query_604237, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_604237.add "Filters", Filters
  add(query_604237, "Action", newJString(Action))
  add(query_604237, "Version", newJString(Version))
  result = call_604236.call(nil, query_604237, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604221(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604222, base: "/",
    url: url_GetDescribeEventCategories_604223,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_604275 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEventSubscriptions_604277(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_604276(path: JsonNode;
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
  var valid_604278 = query.getOrDefault("Action")
  valid_604278 = validateParameter(valid_604278, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604278 != nil:
    section.add "Action", valid_604278
  var valid_604279 = query.getOrDefault("Version")
  valid_604279 = validateParameter(valid_604279, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604279 != nil:
    section.add "Version", valid_604279
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604280 = header.getOrDefault("X-Amz-Date")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Date", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Security-Token")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Security-Token", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Content-Sha256", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-Algorithm")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Algorithm", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Signature")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Signature", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-SignedHeaders", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Credential")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Credential", valid_604286
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604287 = formData.getOrDefault("Marker")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "Marker", valid_604287
  var valid_604288 = formData.getOrDefault("SubscriptionName")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "SubscriptionName", valid_604288
  var valid_604289 = formData.getOrDefault("Filters")
  valid_604289 = validateParameter(valid_604289, JArray, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "Filters", valid_604289
  var valid_604290 = formData.getOrDefault("MaxRecords")
  valid_604290 = validateParameter(valid_604290, JInt, required = false, default = nil)
  if valid_604290 != nil:
    section.add "MaxRecords", valid_604290
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604291: Call_PostDescribeEventSubscriptions_604275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604291.validator(path, query, header, formData, body)
  let scheme = call_604291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604291.url(scheme.get, call_604291.host, call_604291.base,
                         call_604291.route, valid.getOrDefault("path"))
  result = hook(call_604291, url, valid)

proc call*(call_604292: Call_PostDescribeEventSubscriptions_604275;
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
  var query_604293 = newJObject()
  var formData_604294 = newJObject()
  add(formData_604294, "Marker", newJString(Marker))
  add(formData_604294, "SubscriptionName", newJString(SubscriptionName))
  add(query_604293, "Action", newJString(Action))
  if Filters != nil:
    formData_604294.add "Filters", Filters
  add(formData_604294, "MaxRecords", newJInt(MaxRecords))
  add(query_604293, "Version", newJString(Version))
  result = call_604292.call(nil, query_604293, nil, formData_604294, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_604275(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_604276, base: "/",
    url: url_PostDescribeEventSubscriptions_604277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_604256 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEventSubscriptions_604258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_604257(path: JsonNode; query: JsonNode;
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
  var valid_604259 = query.getOrDefault("MaxRecords")
  valid_604259 = validateParameter(valid_604259, JInt, required = false, default = nil)
  if valid_604259 != nil:
    section.add "MaxRecords", valid_604259
  var valid_604260 = query.getOrDefault("Filters")
  valid_604260 = validateParameter(valid_604260, JArray, required = false,
                                 default = nil)
  if valid_604260 != nil:
    section.add "Filters", valid_604260
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604261 = query.getOrDefault("Action")
  valid_604261 = validateParameter(valid_604261, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604261 != nil:
    section.add "Action", valid_604261
  var valid_604262 = query.getOrDefault("Marker")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "Marker", valid_604262
  var valid_604263 = query.getOrDefault("SubscriptionName")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "SubscriptionName", valid_604263
  var valid_604264 = query.getOrDefault("Version")
  valid_604264 = validateParameter(valid_604264, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604264 != nil:
    section.add "Version", valid_604264
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604265 = header.getOrDefault("X-Amz-Date")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Date", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Security-Token")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Security-Token", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Content-Sha256", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-Algorithm")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Algorithm", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Signature")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Signature", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-SignedHeaders", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Credential")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Credential", valid_604271
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604272: Call_GetDescribeEventSubscriptions_604256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604272.validator(path, query, header, formData, body)
  let scheme = call_604272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604272.url(scheme.get, call_604272.host, call_604272.base,
                         call_604272.route, valid.getOrDefault("path"))
  result = hook(call_604272, url, valid)

proc call*(call_604273: Call_GetDescribeEventSubscriptions_604256;
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
  var query_604274 = newJObject()
  add(query_604274, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604274.add "Filters", Filters
  add(query_604274, "Action", newJString(Action))
  add(query_604274, "Marker", newJString(Marker))
  add(query_604274, "SubscriptionName", newJString(SubscriptionName))
  add(query_604274, "Version", newJString(Version))
  result = call_604273.call(nil, query_604274, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_604256(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_604257, base: "/",
    url: url_GetDescribeEventSubscriptions_604258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604319 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEvents_604321(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_604320(path: JsonNode; query: JsonNode;
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
  var valid_604322 = query.getOrDefault("Action")
  valid_604322 = validateParameter(valid_604322, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604322 != nil:
    section.add "Action", valid_604322
  var valid_604323 = query.getOrDefault("Version")
  valid_604323 = validateParameter(valid_604323, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604323 != nil:
    section.add "Version", valid_604323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604324 = header.getOrDefault("X-Amz-Date")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Date", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Security-Token")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Security-Token", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-Content-Sha256", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Algorithm")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Algorithm", valid_604327
  var valid_604328 = header.getOrDefault("X-Amz-Signature")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Signature", valid_604328
  var valid_604329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-SignedHeaders", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-Credential")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-Credential", valid_604330
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
  var valid_604331 = formData.getOrDefault("SourceIdentifier")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "SourceIdentifier", valid_604331
  var valid_604332 = formData.getOrDefault("EventCategories")
  valid_604332 = validateParameter(valid_604332, JArray, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "EventCategories", valid_604332
  var valid_604333 = formData.getOrDefault("Marker")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "Marker", valid_604333
  var valid_604334 = formData.getOrDefault("StartTime")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "StartTime", valid_604334
  var valid_604335 = formData.getOrDefault("Duration")
  valid_604335 = validateParameter(valid_604335, JInt, required = false, default = nil)
  if valid_604335 != nil:
    section.add "Duration", valid_604335
  var valid_604336 = formData.getOrDefault("Filters")
  valid_604336 = validateParameter(valid_604336, JArray, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "Filters", valid_604336
  var valid_604337 = formData.getOrDefault("EndTime")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "EndTime", valid_604337
  var valid_604338 = formData.getOrDefault("MaxRecords")
  valid_604338 = validateParameter(valid_604338, JInt, required = false, default = nil)
  if valid_604338 != nil:
    section.add "MaxRecords", valid_604338
  var valid_604339 = formData.getOrDefault("SourceType")
  valid_604339 = validateParameter(valid_604339, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604339 != nil:
    section.add "SourceType", valid_604339
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604340: Call_PostDescribeEvents_604319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604340.validator(path, query, header, formData, body)
  let scheme = call_604340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604340.url(scheme.get, call_604340.host, call_604340.base,
                         call_604340.route, valid.getOrDefault("path"))
  result = hook(call_604340, url, valid)

proc call*(call_604341: Call_PostDescribeEvents_604319;
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
  var query_604342 = newJObject()
  var formData_604343 = newJObject()
  add(formData_604343, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604343.add "EventCategories", EventCategories
  add(formData_604343, "Marker", newJString(Marker))
  add(formData_604343, "StartTime", newJString(StartTime))
  add(query_604342, "Action", newJString(Action))
  add(formData_604343, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_604343.add "Filters", Filters
  add(formData_604343, "EndTime", newJString(EndTime))
  add(formData_604343, "MaxRecords", newJInt(MaxRecords))
  add(query_604342, "Version", newJString(Version))
  add(formData_604343, "SourceType", newJString(SourceType))
  result = call_604341.call(nil, query_604342, nil, formData_604343, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604319(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604320, base: "/",
    url: url_PostDescribeEvents_604321, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604295 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEvents_604297(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_604296(path: JsonNode; query: JsonNode;
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
  var valid_604298 = query.getOrDefault("SourceType")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604298 != nil:
    section.add "SourceType", valid_604298
  var valid_604299 = query.getOrDefault("MaxRecords")
  valid_604299 = validateParameter(valid_604299, JInt, required = false, default = nil)
  if valid_604299 != nil:
    section.add "MaxRecords", valid_604299
  var valid_604300 = query.getOrDefault("StartTime")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "StartTime", valid_604300
  var valid_604301 = query.getOrDefault("Filters")
  valid_604301 = validateParameter(valid_604301, JArray, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "Filters", valid_604301
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604302 = query.getOrDefault("Action")
  valid_604302 = validateParameter(valid_604302, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604302 != nil:
    section.add "Action", valid_604302
  var valid_604303 = query.getOrDefault("SourceIdentifier")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "SourceIdentifier", valid_604303
  var valid_604304 = query.getOrDefault("Marker")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "Marker", valid_604304
  var valid_604305 = query.getOrDefault("EventCategories")
  valid_604305 = validateParameter(valid_604305, JArray, required = false,
                                 default = nil)
  if valid_604305 != nil:
    section.add "EventCategories", valid_604305
  var valid_604306 = query.getOrDefault("Duration")
  valid_604306 = validateParameter(valid_604306, JInt, required = false, default = nil)
  if valid_604306 != nil:
    section.add "Duration", valid_604306
  var valid_604307 = query.getOrDefault("EndTime")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "EndTime", valid_604307
  var valid_604308 = query.getOrDefault("Version")
  valid_604308 = validateParameter(valid_604308, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604308 != nil:
    section.add "Version", valid_604308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604309 = header.getOrDefault("X-Amz-Date")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "X-Amz-Date", valid_604309
  var valid_604310 = header.getOrDefault("X-Amz-Security-Token")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "X-Amz-Security-Token", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-Content-Sha256", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Algorithm")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Algorithm", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Signature")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Signature", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-SignedHeaders", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Credential")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Credential", valid_604315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604316: Call_GetDescribeEvents_604295; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604316.validator(path, query, header, formData, body)
  let scheme = call_604316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604316.url(scheme.get, call_604316.host, call_604316.base,
                         call_604316.route, valid.getOrDefault("path"))
  result = hook(call_604316, url, valid)

proc call*(call_604317: Call_GetDescribeEvents_604295;
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
  var query_604318 = newJObject()
  add(query_604318, "SourceType", newJString(SourceType))
  add(query_604318, "MaxRecords", newJInt(MaxRecords))
  add(query_604318, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_604318.add "Filters", Filters
  add(query_604318, "Action", newJString(Action))
  add(query_604318, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604318, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604318.add "EventCategories", EventCategories
  add(query_604318, "Duration", newJInt(Duration))
  add(query_604318, "EndTime", newJString(EndTime))
  add(query_604318, "Version", newJString(Version))
  result = call_604317.call(nil, query_604318, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604295(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604296,
    base: "/", url: url_GetDescribeEvents_604297,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_604364 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOptionGroupOptions_604366(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_604365(path: JsonNode;
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
  var valid_604367 = query.getOrDefault("Action")
  valid_604367 = validateParameter(valid_604367, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604367 != nil:
    section.add "Action", valid_604367
  var valid_604368 = query.getOrDefault("Version")
  valid_604368 = validateParameter(valid_604368, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604368 != nil:
    section.add "Version", valid_604368
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604369 = header.getOrDefault("X-Amz-Date")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Date", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Security-Token")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Security-Token", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Content-Sha256", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Algorithm")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Algorithm", valid_604372
  var valid_604373 = header.getOrDefault("X-Amz-Signature")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "X-Amz-Signature", valid_604373
  var valid_604374 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604374 = validateParameter(valid_604374, JString, required = false,
                                 default = nil)
  if valid_604374 != nil:
    section.add "X-Amz-SignedHeaders", valid_604374
  var valid_604375 = header.getOrDefault("X-Amz-Credential")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-Credential", valid_604375
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604376 = formData.getOrDefault("MajorEngineVersion")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "MajorEngineVersion", valid_604376
  var valid_604377 = formData.getOrDefault("Marker")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "Marker", valid_604377
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_604378 = formData.getOrDefault("EngineName")
  valid_604378 = validateParameter(valid_604378, JString, required = true,
                                 default = nil)
  if valid_604378 != nil:
    section.add "EngineName", valid_604378
  var valid_604379 = formData.getOrDefault("Filters")
  valid_604379 = validateParameter(valid_604379, JArray, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "Filters", valid_604379
  var valid_604380 = formData.getOrDefault("MaxRecords")
  valid_604380 = validateParameter(valid_604380, JInt, required = false, default = nil)
  if valid_604380 != nil:
    section.add "MaxRecords", valid_604380
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604381: Call_PostDescribeOptionGroupOptions_604364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604381.validator(path, query, header, formData, body)
  let scheme = call_604381.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604381.url(scheme.get, call_604381.host, call_604381.base,
                         call_604381.route, valid.getOrDefault("path"))
  result = hook(call_604381, url, valid)

proc call*(call_604382: Call_PostDescribeOptionGroupOptions_604364;
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
  var query_604383 = newJObject()
  var formData_604384 = newJObject()
  add(formData_604384, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604384, "Marker", newJString(Marker))
  add(query_604383, "Action", newJString(Action))
  add(formData_604384, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604384.add "Filters", Filters
  add(formData_604384, "MaxRecords", newJInt(MaxRecords))
  add(query_604383, "Version", newJString(Version))
  result = call_604382.call(nil, query_604383, nil, formData_604384, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_604364(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_604365, base: "/",
    url: url_PostDescribeOptionGroupOptions_604366,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_604344 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOptionGroupOptions_604346(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_604345(path: JsonNode; query: JsonNode;
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
  var valid_604347 = query.getOrDefault("MaxRecords")
  valid_604347 = validateParameter(valid_604347, JInt, required = false, default = nil)
  if valid_604347 != nil:
    section.add "MaxRecords", valid_604347
  var valid_604348 = query.getOrDefault("Filters")
  valid_604348 = validateParameter(valid_604348, JArray, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "Filters", valid_604348
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604349 = query.getOrDefault("Action")
  valid_604349 = validateParameter(valid_604349, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604349 != nil:
    section.add "Action", valid_604349
  var valid_604350 = query.getOrDefault("Marker")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "Marker", valid_604350
  var valid_604351 = query.getOrDefault("Version")
  valid_604351 = validateParameter(valid_604351, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604351 != nil:
    section.add "Version", valid_604351
  var valid_604352 = query.getOrDefault("EngineName")
  valid_604352 = validateParameter(valid_604352, JString, required = true,
                                 default = nil)
  if valid_604352 != nil:
    section.add "EngineName", valid_604352
  var valid_604353 = query.getOrDefault("MajorEngineVersion")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "MajorEngineVersion", valid_604353
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604354 = header.getOrDefault("X-Amz-Date")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Date", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Security-Token")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Security-Token", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Content-Sha256", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Algorithm")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Algorithm", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Signature")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Signature", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-SignedHeaders", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-Credential")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Credential", valid_604360
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604361: Call_GetDescribeOptionGroupOptions_604344; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604361.validator(path, query, header, formData, body)
  let scheme = call_604361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604361.url(scheme.get, call_604361.host, call_604361.base,
                         call_604361.route, valid.getOrDefault("path"))
  result = hook(call_604361, url, valid)

proc call*(call_604362: Call_GetDescribeOptionGroupOptions_604344;
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
  var query_604363 = newJObject()
  add(query_604363, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604363.add "Filters", Filters
  add(query_604363, "Action", newJString(Action))
  add(query_604363, "Marker", newJString(Marker))
  add(query_604363, "Version", newJString(Version))
  add(query_604363, "EngineName", newJString(EngineName))
  add(query_604363, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604362.call(nil, query_604363, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_604344(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_604345, base: "/",
    url: url_GetDescribeOptionGroupOptions_604346,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_604406 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOptionGroups_604408(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_604407(path: JsonNode; query: JsonNode;
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
  var valid_604409 = query.getOrDefault("Action")
  valid_604409 = validateParameter(valid_604409, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604409 != nil:
    section.add "Action", valid_604409
  var valid_604410 = query.getOrDefault("Version")
  valid_604410 = validateParameter(valid_604410, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604410 != nil:
    section.add "Version", valid_604410
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604411 = header.getOrDefault("X-Amz-Date")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-Date", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Security-Token")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Security-Token", valid_604412
  var valid_604413 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "X-Amz-Content-Sha256", valid_604413
  var valid_604414 = header.getOrDefault("X-Amz-Algorithm")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "X-Amz-Algorithm", valid_604414
  var valid_604415 = header.getOrDefault("X-Amz-Signature")
  valid_604415 = validateParameter(valid_604415, JString, required = false,
                                 default = nil)
  if valid_604415 != nil:
    section.add "X-Amz-Signature", valid_604415
  var valid_604416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "X-Amz-SignedHeaders", valid_604416
  var valid_604417 = header.getOrDefault("X-Amz-Credential")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "X-Amz-Credential", valid_604417
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604418 = formData.getOrDefault("MajorEngineVersion")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "MajorEngineVersion", valid_604418
  var valid_604419 = formData.getOrDefault("OptionGroupName")
  valid_604419 = validateParameter(valid_604419, JString, required = false,
                                 default = nil)
  if valid_604419 != nil:
    section.add "OptionGroupName", valid_604419
  var valid_604420 = formData.getOrDefault("Marker")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "Marker", valid_604420
  var valid_604421 = formData.getOrDefault("EngineName")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "EngineName", valid_604421
  var valid_604422 = formData.getOrDefault("Filters")
  valid_604422 = validateParameter(valid_604422, JArray, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "Filters", valid_604422
  var valid_604423 = formData.getOrDefault("MaxRecords")
  valid_604423 = validateParameter(valid_604423, JInt, required = false, default = nil)
  if valid_604423 != nil:
    section.add "MaxRecords", valid_604423
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604424: Call_PostDescribeOptionGroups_604406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604424.validator(path, query, header, formData, body)
  let scheme = call_604424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604424.url(scheme.get, call_604424.host, call_604424.base,
                         call_604424.route, valid.getOrDefault("path"))
  result = hook(call_604424, url, valid)

proc call*(call_604425: Call_PostDescribeOptionGroups_604406;
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
  var query_604426 = newJObject()
  var formData_604427 = newJObject()
  add(formData_604427, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604427, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604427, "Marker", newJString(Marker))
  add(query_604426, "Action", newJString(Action))
  add(formData_604427, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604427.add "Filters", Filters
  add(formData_604427, "MaxRecords", newJInt(MaxRecords))
  add(query_604426, "Version", newJString(Version))
  result = call_604425.call(nil, query_604426, nil, formData_604427, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_604406(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_604407, base: "/",
    url: url_PostDescribeOptionGroups_604408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_604385 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOptionGroups_604387(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_604386(path: JsonNode; query: JsonNode;
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
  var valid_604388 = query.getOrDefault("MaxRecords")
  valid_604388 = validateParameter(valid_604388, JInt, required = false, default = nil)
  if valid_604388 != nil:
    section.add "MaxRecords", valid_604388
  var valid_604389 = query.getOrDefault("OptionGroupName")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "OptionGroupName", valid_604389
  var valid_604390 = query.getOrDefault("Filters")
  valid_604390 = validateParameter(valid_604390, JArray, required = false,
                                 default = nil)
  if valid_604390 != nil:
    section.add "Filters", valid_604390
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604391 = query.getOrDefault("Action")
  valid_604391 = validateParameter(valid_604391, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604391 != nil:
    section.add "Action", valid_604391
  var valid_604392 = query.getOrDefault("Marker")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "Marker", valid_604392
  var valid_604393 = query.getOrDefault("Version")
  valid_604393 = validateParameter(valid_604393, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604393 != nil:
    section.add "Version", valid_604393
  var valid_604394 = query.getOrDefault("EngineName")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "EngineName", valid_604394
  var valid_604395 = query.getOrDefault("MajorEngineVersion")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "MajorEngineVersion", valid_604395
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604396 = header.getOrDefault("X-Amz-Date")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-Date", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-Security-Token")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-Security-Token", valid_604397
  var valid_604398 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "X-Amz-Content-Sha256", valid_604398
  var valid_604399 = header.getOrDefault("X-Amz-Algorithm")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "X-Amz-Algorithm", valid_604399
  var valid_604400 = header.getOrDefault("X-Amz-Signature")
  valid_604400 = validateParameter(valid_604400, JString, required = false,
                                 default = nil)
  if valid_604400 != nil:
    section.add "X-Amz-Signature", valid_604400
  var valid_604401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-SignedHeaders", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Credential")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Credential", valid_604402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604403: Call_GetDescribeOptionGroups_604385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604403.validator(path, query, header, formData, body)
  let scheme = call_604403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604403.url(scheme.get, call_604403.host, call_604403.base,
                         call_604403.route, valid.getOrDefault("path"))
  result = hook(call_604403, url, valid)

proc call*(call_604404: Call_GetDescribeOptionGroups_604385; MaxRecords: int = 0;
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
  var query_604405 = newJObject()
  add(query_604405, "MaxRecords", newJInt(MaxRecords))
  add(query_604405, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_604405.add "Filters", Filters
  add(query_604405, "Action", newJString(Action))
  add(query_604405, "Marker", newJString(Marker))
  add(query_604405, "Version", newJString(Version))
  add(query_604405, "EngineName", newJString(EngineName))
  add(query_604405, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604404.call(nil, query_604405, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_604385(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_604386, base: "/",
    url: url_GetDescribeOptionGroups_604387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604451 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOrderableDBInstanceOptions_604453(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604452(path: JsonNode;
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
  var valid_604454 = query.getOrDefault("Action")
  valid_604454 = validateParameter(valid_604454, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604454 != nil:
    section.add "Action", valid_604454
  var valid_604455 = query.getOrDefault("Version")
  valid_604455 = validateParameter(valid_604455, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604455 != nil:
    section.add "Version", valid_604455
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604456 = header.getOrDefault("X-Amz-Date")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-Date", valid_604456
  var valid_604457 = header.getOrDefault("X-Amz-Security-Token")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "X-Amz-Security-Token", valid_604457
  var valid_604458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Content-Sha256", valid_604458
  var valid_604459 = header.getOrDefault("X-Amz-Algorithm")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-Algorithm", valid_604459
  var valid_604460 = header.getOrDefault("X-Amz-Signature")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "X-Amz-Signature", valid_604460
  var valid_604461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "X-Amz-SignedHeaders", valid_604461
  var valid_604462 = header.getOrDefault("X-Amz-Credential")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Credential", valid_604462
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
  var valid_604463 = formData.getOrDefault("Engine")
  valid_604463 = validateParameter(valid_604463, JString, required = true,
                                 default = nil)
  if valid_604463 != nil:
    section.add "Engine", valid_604463
  var valid_604464 = formData.getOrDefault("Marker")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "Marker", valid_604464
  var valid_604465 = formData.getOrDefault("Vpc")
  valid_604465 = validateParameter(valid_604465, JBool, required = false, default = nil)
  if valid_604465 != nil:
    section.add "Vpc", valid_604465
  var valid_604466 = formData.getOrDefault("DBInstanceClass")
  valid_604466 = validateParameter(valid_604466, JString, required = false,
                                 default = nil)
  if valid_604466 != nil:
    section.add "DBInstanceClass", valid_604466
  var valid_604467 = formData.getOrDefault("Filters")
  valid_604467 = validateParameter(valid_604467, JArray, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "Filters", valid_604467
  var valid_604468 = formData.getOrDefault("LicenseModel")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "LicenseModel", valid_604468
  var valid_604469 = formData.getOrDefault("MaxRecords")
  valid_604469 = validateParameter(valid_604469, JInt, required = false, default = nil)
  if valid_604469 != nil:
    section.add "MaxRecords", valid_604469
  var valid_604470 = formData.getOrDefault("EngineVersion")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "EngineVersion", valid_604470
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604471: Call_PostDescribeOrderableDBInstanceOptions_604451;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604471.validator(path, query, header, formData, body)
  let scheme = call_604471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604471.url(scheme.get, call_604471.host, call_604471.base,
                         call_604471.route, valid.getOrDefault("path"))
  result = hook(call_604471, url, valid)

proc call*(call_604472: Call_PostDescribeOrderableDBInstanceOptions_604451;
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
  var query_604473 = newJObject()
  var formData_604474 = newJObject()
  add(formData_604474, "Engine", newJString(Engine))
  add(formData_604474, "Marker", newJString(Marker))
  add(query_604473, "Action", newJString(Action))
  add(formData_604474, "Vpc", newJBool(Vpc))
  add(formData_604474, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604474.add "Filters", Filters
  add(formData_604474, "LicenseModel", newJString(LicenseModel))
  add(formData_604474, "MaxRecords", newJInt(MaxRecords))
  add(formData_604474, "EngineVersion", newJString(EngineVersion))
  add(query_604473, "Version", newJString(Version))
  result = call_604472.call(nil, query_604473, nil, formData_604474, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604451(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604452, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604428 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOrderableDBInstanceOptions_604430(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604429(path: JsonNode;
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
  var valid_604431 = query.getOrDefault("Engine")
  valid_604431 = validateParameter(valid_604431, JString, required = true,
                                 default = nil)
  if valid_604431 != nil:
    section.add "Engine", valid_604431
  var valid_604432 = query.getOrDefault("MaxRecords")
  valid_604432 = validateParameter(valid_604432, JInt, required = false, default = nil)
  if valid_604432 != nil:
    section.add "MaxRecords", valid_604432
  var valid_604433 = query.getOrDefault("Filters")
  valid_604433 = validateParameter(valid_604433, JArray, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "Filters", valid_604433
  var valid_604434 = query.getOrDefault("LicenseModel")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "LicenseModel", valid_604434
  var valid_604435 = query.getOrDefault("Vpc")
  valid_604435 = validateParameter(valid_604435, JBool, required = false, default = nil)
  if valid_604435 != nil:
    section.add "Vpc", valid_604435
  var valid_604436 = query.getOrDefault("DBInstanceClass")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "DBInstanceClass", valid_604436
  var valid_604437 = query.getOrDefault("Action")
  valid_604437 = validateParameter(valid_604437, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604437 != nil:
    section.add "Action", valid_604437
  var valid_604438 = query.getOrDefault("Marker")
  valid_604438 = validateParameter(valid_604438, JString, required = false,
                                 default = nil)
  if valid_604438 != nil:
    section.add "Marker", valid_604438
  var valid_604439 = query.getOrDefault("EngineVersion")
  valid_604439 = validateParameter(valid_604439, JString, required = false,
                                 default = nil)
  if valid_604439 != nil:
    section.add "EngineVersion", valid_604439
  var valid_604440 = query.getOrDefault("Version")
  valid_604440 = validateParameter(valid_604440, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604440 != nil:
    section.add "Version", valid_604440
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604441 = header.getOrDefault("X-Amz-Date")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "X-Amz-Date", valid_604441
  var valid_604442 = header.getOrDefault("X-Amz-Security-Token")
  valid_604442 = validateParameter(valid_604442, JString, required = false,
                                 default = nil)
  if valid_604442 != nil:
    section.add "X-Amz-Security-Token", valid_604442
  var valid_604443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "X-Amz-Content-Sha256", valid_604443
  var valid_604444 = header.getOrDefault("X-Amz-Algorithm")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Algorithm", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Signature")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Signature", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-SignedHeaders", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Credential")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Credential", valid_604447
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604448: Call_GetDescribeOrderableDBInstanceOptions_604428;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604448.validator(path, query, header, formData, body)
  let scheme = call_604448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604448.url(scheme.get, call_604448.host, call_604448.base,
                         call_604448.route, valid.getOrDefault("path"))
  result = hook(call_604448, url, valid)

proc call*(call_604449: Call_GetDescribeOrderableDBInstanceOptions_604428;
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
  var query_604450 = newJObject()
  add(query_604450, "Engine", newJString(Engine))
  add(query_604450, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604450.add "Filters", Filters
  add(query_604450, "LicenseModel", newJString(LicenseModel))
  add(query_604450, "Vpc", newJBool(Vpc))
  add(query_604450, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604450, "Action", newJString(Action))
  add(query_604450, "Marker", newJString(Marker))
  add(query_604450, "EngineVersion", newJString(EngineVersion))
  add(query_604450, "Version", newJString(Version))
  result = call_604449.call(nil, query_604450, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604428(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604429, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_604500 = ref object of OpenApiRestCall_602417
proc url_PostDescribeReservedDBInstances_604502(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_604501(path: JsonNode;
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
  var valid_604503 = query.getOrDefault("Action")
  valid_604503 = validateParameter(valid_604503, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604503 != nil:
    section.add "Action", valid_604503
  var valid_604504 = query.getOrDefault("Version")
  valid_604504 = validateParameter(valid_604504, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604504 != nil:
    section.add "Version", valid_604504
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604505 = header.getOrDefault("X-Amz-Date")
  valid_604505 = validateParameter(valid_604505, JString, required = false,
                                 default = nil)
  if valid_604505 != nil:
    section.add "X-Amz-Date", valid_604505
  var valid_604506 = header.getOrDefault("X-Amz-Security-Token")
  valid_604506 = validateParameter(valid_604506, JString, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "X-Amz-Security-Token", valid_604506
  var valid_604507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604507 = validateParameter(valid_604507, JString, required = false,
                                 default = nil)
  if valid_604507 != nil:
    section.add "X-Amz-Content-Sha256", valid_604507
  var valid_604508 = header.getOrDefault("X-Amz-Algorithm")
  valid_604508 = validateParameter(valid_604508, JString, required = false,
                                 default = nil)
  if valid_604508 != nil:
    section.add "X-Amz-Algorithm", valid_604508
  var valid_604509 = header.getOrDefault("X-Amz-Signature")
  valid_604509 = validateParameter(valid_604509, JString, required = false,
                                 default = nil)
  if valid_604509 != nil:
    section.add "X-Amz-Signature", valid_604509
  var valid_604510 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "X-Amz-SignedHeaders", valid_604510
  var valid_604511 = header.getOrDefault("X-Amz-Credential")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "X-Amz-Credential", valid_604511
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
  var valid_604512 = formData.getOrDefault("OfferingType")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "OfferingType", valid_604512
  var valid_604513 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "ReservedDBInstanceId", valid_604513
  var valid_604514 = formData.getOrDefault("Marker")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "Marker", valid_604514
  var valid_604515 = formData.getOrDefault("MultiAZ")
  valid_604515 = validateParameter(valid_604515, JBool, required = false, default = nil)
  if valid_604515 != nil:
    section.add "MultiAZ", valid_604515
  var valid_604516 = formData.getOrDefault("Duration")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "Duration", valid_604516
  var valid_604517 = formData.getOrDefault("DBInstanceClass")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "DBInstanceClass", valid_604517
  var valid_604518 = formData.getOrDefault("Filters")
  valid_604518 = validateParameter(valid_604518, JArray, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "Filters", valid_604518
  var valid_604519 = formData.getOrDefault("ProductDescription")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "ProductDescription", valid_604519
  var valid_604520 = formData.getOrDefault("MaxRecords")
  valid_604520 = validateParameter(valid_604520, JInt, required = false, default = nil)
  if valid_604520 != nil:
    section.add "MaxRecords", valid_604520
  var valid_604521 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604521 = validateParameter(valid_604521, JString, required = false,
                                 default = nil)
  if valid_604521 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604521
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604522: Call_PostDescribeReservedDBInstances_604500;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604522.validator(path, query, header, formData, body)
  let scheme = call_604522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604522.url(scheme.get, call_604522.host, call_604522.base,
                         call_604522.route, valid.getOrDefault("path"))
  result = hook(call_604522, url, valid)

proc call*(call_604523: Call_PostDescribeReservedDBInstances_604500;
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
  var query_604524 = newJObject()
  var formData_604525 = newJObject()
  add(formData_604525, "OfferingType", newJString(OfferingType))
  add(formData_604525, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604525, "Marker", newJString(Marker))
  add(formData_604525, "MultiAZ", newJBool(MultiAZ))
  add(query_604524, "Action", newJString(Action))
  add(formData_604525, "Duration", newJString(Duration))
  add(formData_604525, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604525.add "Filters", Filters
  add(formData_604525, "ProductDescription", newJString(ProductDescription))
  add(formData_604525, "MaxRecords", newJInt(MaxRecords))
  add(formData_604525, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604524, "Version", newJString(Version))
  result = call_604523.call(nil, query_604524, nil, formData_604525, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_604500(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_604501, base: "/",
    url: url_PostDescribeReservedDBInstances_604502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_604475 = ref object of OpenApiRestCall_602417
proc url_GetDescribeReservedDBInstances_604477(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_604476(path: JsonNode;
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
  var valid_604478 = query.getOrDefault("ProductDescription")
  valid_604478 = validateParameter(valid_604478, JString, required = false,
                                 default = nil)
  if valid_604478 != nil:
    section.add "ProductDescription", valid_604478
  var valid_604479 = query.getOrDefault("MaxRecords")
  valid_604479 = validateParameter(valid_604479, JInt, required = false, default = nil)
  if valid_604479 != nil:
    section.add "MaxRecords", valid_604479
  var valid_604480 = query.getOrDefault("OfferingType")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "OfferingType", valid_604480
  var valid_604481 = query.getOrDefault("Filters")
  valid_604481 = validateParameter(valid_604481, JArray, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "Filters", valid_604481
  var valid_604482 = query.getOrDefault("MultiAZ")
  valid_604482 = validateParameter(valid_604482, JBool, required = false, default = nil)
  if valid_604482 != nil:
    section.add "MultiAZ", valid_604482
  var valid_604483 = query.getOrDefault("ReservedDBInstanceId")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "ReservedDBInstanceId", valid_604483
  var valid_604484 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604484
  var valid_604485 = query.getOrDefault("DBInstanceClass")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "DBInstanceClass", valid_604485
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604486 = query.getOrDefault("Action")
  valid_604486 = validateParameter(valid_604486, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604486 != nil:
    section.add "Action", valid_604486
  var valid_604487 = query.getOrDefault("Marker")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "Marker", valid_604487
  var valid_604488 = query.getOrDefault("Duration")
  valid_604488 = validateParameter(valid_604488, JString, required = false,
                                 default = nil)
  if valid_604488 != nil:
    section.add "Duration", valid_604488
  var valid_604489 = query.getOrDefault("Version")
  valid_604489 = validateParameter(valid_604489, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604489 != nil:
    section.add "Version", valid_604489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604490 = header.getOrDefault("X-Amz-Date")
  valid_604490 = validateParameter(valid_604490, JString, required = false,
                                 default = nil)
  if valid_604490 != nil:
    section.add "X-Amz-Date", valid_604490
  var valid_604491 = header.getOrDefault("X-Amz-Security-Token")
  valid_604491 = validateParameter(valid_604491, JString, required = false,
                                 default = nil)
  if valid_604491 != nil:
    section.add "X-Amz-Security-Token", valid_604491
  var valid_604492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604492 = validateParameter(valid_604492, JString, required = false,
                                 default = nil)
  if valid_604492 != nil:
    section.add "X-Amz-Content-Sha256", valid_604492
  var valid_604493 = header.getOrDefault("X-Amz-Algorithm")
  valid_604493 = validateParameter(valid_604493, JString, required = false,
                                 default = nil)
  if valid_604493 != nil:
    section.add "X-Amz-Algorithm", valid_604493
  var valid_604494 = header.getOrDefault("X-Amz-Signature")
  valid_604494 = validateParameter(valid_604494, JString, required = false,
                                 default = nil)
  if valid_604494 != nil:
    section.add "X-Amz-Signature", valid_604494
  var valid_604495 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-SignedHeaders", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Credential")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Credential", valid_604496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604497: Call_GetDescribeReservedDBInstances_604475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604497.validator(path, query, header, formData, body)
  let scheme = call_604497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604497.url(scheme.get, call_604497.host, call_604497.base,
                         call_604497.route, valid.getOrDefault("path"))
  result = hook(call_604497, url, valid)

proc call*(call_604498: Call_GetDescribeReservedDBInstances_604475;
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
  var query_604499 = newJObject()
  add(query_604499, "ProductDescription", newJString(ProductDescription))
  add(query_604499, "MaxRecords", newJInt(MaxRecords))
  add(query_604499, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604499.add "Filters", Filters
  add(query_604499, "MultiAZ", newJBool(MultiAZ))
  add(query_604499, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604499, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604499, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604499, "Action", newJString(Action))
  add(query_604499, "Marker", newJString(Marker))
  add(query_604499, "Duration", newJString(Duration))
  add(query_604499, "Version", newJString(Version))
  result = call_604498.call(nil, query_604499, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_604475(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_604476, base: "/",
    url: url_GetDescribeReservedDBInstances_604477,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_604550 = ref object of OpenApiRestCall_602417
proc url_PostDescribeReservedDBInstancesOfferings_604552(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_604551(path: JsonNode;
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
  var valid_604553 = query.getOrDefault("Action")
  valid_604553 = validateParameter(valid_604553, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604553 != nil:
    section.add "Action", valid_604553
  var valid_604554 = query.getOrDefault("Version")
  valid_604554 = validateParameter(valid_604554, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604554 != nil:
    section.add "Version", valid_604554
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604555 = header.getOrDefault("X-Amz-Date")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-Date", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-Security-Token")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-Security-Token", valid_604556
  var valid_604557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604557 = validateParameter(valid_604557, JString, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "X-Amz-Content-Sha256", valid_604557
  var valid_604558 = header.getOrDefault("X-Amz-Algorithm")
  valid_604558 = validateParameter(valid_604558, JString, required = false,
                                 default = nil)
  if valid_604558 != nil:
    section.add "X-Amz-Algorithm", valid_604558
  var valid_604559 = header.getOrDefault("X-Amz-Signature")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "X-Amz-Signature", valid_604559
  var valid_604560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "X-Amz-SignedHeaders", valid_604560
  var valid_604561 = header.getOrDefault("X-Amz-Credential")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "X-Amz-Credential", valid_604561
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
  var valid_604562 = formData.getOrDefault("OfferingType")
  valid_604562 = validateParameter(valid_604562, JString, required = false,
                                 default = nil)
  if valid_604562 != nil:
    section.add "OfferingType", valid_604562
  var valid_604563 = formData.getOrDefault("Marker")
  valid_604563 = validateParameter(valid_604563, JString, required = false,
                                 default = nil)
  if valid_604563 != nil:
    section.add "Marker", valid_604563
  var valid_604564 = formData.getOrDefault("MultiAZ")
  valid_604564 = validateParameter(valid_604564, JBool, required = false, default = nil)
  if valid_604564 != nil:
    section.add "MultiAZ", valid_604564
  var valid_604565 = formData.getOrDefault("Duration")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "Duration", valid_604565
  var valid_604566 = formData.getOrDefault("DBInstanceClass")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "DBInstanceClass", valid_604566
  var valid_604567 = formData.getOrDefault("Filters")
  valid_604567 = validateParameter(valid_604567, JArray, required = false,
                                 default = nil)
  if valid_604567 != nil:
    section.add "Filters", valid_604567
  var valid_604568 = formData.getOrDefault("ProductDescription")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "ProductDescription", valid_604568
  var valid_604569 = formData.getOrDefault("MaxRecords")
  valid_604569 = validateParameter(valid_604569, JInt, required = false, default = nil)
  if valid_604569 != nil:
    section.add "MaxRecords", valid_604569
  var valid_604570 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604571: Call_PostDescribeReservedDBInstancesOfferings_604550;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604571.validator(path, query, header, formData, body)
  let scheme = call_604571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604571.url(scheme.get, call_604571.host, call_604571.base,
                         call_604571.route, valid.getOrDefault("path"))
  result = hook(call_604571, url, valid)

proc call*(call_604572: Call_PostDescribeReservedDBInstancesOfferings_604550;
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
  var query_604573 = newJObject()
  var formData_604574 = newJObject()
  add(formData_604574, "OfferingType", newJString(OfferingType))
  add(formData_604574, "Marker", newJString(Marker))
  add(formData_604574, "MultiAZ", newJBool(MultiAZ))
  add(query_604573, "Action", newJString(Action))
  add(formData_604574, "Duration", newJString(Duration))
  add(formData_604574, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604574.add "Filters", Filters
  add(formData_604574, "ProductDescription", newJString(ProductDescription))
  add(formData_604574, "MaxRecords", newJInt(MaxRecords))
  add(formData_604574, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604573, "Version", newJString(Version))
  result = call_604572.call(nil, query_604573, nil, formData_604574, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_604550(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_604551,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_604552,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_604526 = ref object of OpenApiRestCall_602417
proc url_GetDescribeReservedDBInstancesOfferings_604528(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_604527(path: JsonNode;
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
  var valid_604529 = query.getOrDefault("ProductDescription")
  valid_604529 = validateParameter(valid_604529, JString, required = false,
                                 default = nil)
  if valid_604529 != nil:
    section.add "ProductDescription", valid_604529
  var valid_604530 = query.getOrDefault("MaxRecords")
  valid_604530 = validateParameter(valid_604530, JInt, required = false, default = nil)
  if valid_604530 != nil:
    section.add "MaxRecords", valid_604530
  var valid_604531 = query.getOrDefault("OfferingType")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "OfferingType", valid_604531
  var valid_604532 = query.getOrDefault("Filters")
  valid_604532 = validateParameter(valid_604532, JArray, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "Filters", valid_604532
  var valid_604533 = query.getOrDefault("MultiAZ")
  valid_604533 = validateParameter(valid_604533, JBool, required = false, default = nil)
  if valid_604533 != nil:
    section.add "MultiAZ", valid_604533
  var valid_604534 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604534
  var valid_604535 = query.getOrDefault("DBInstanceClass")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "DBInstanceClass", valid_604535
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604536 = query.getOrDefault("Action")
  valid_604536 = validateParameter(valid_604536, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604536 != nil:
    section.add "Action", valid_604536
  var valid_604537 = query.getOrDefault("Marker")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "Marker", valid_604537
  var valid_604538 = query.getOrDefault("Duration")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "Duration", valid_604538
  var valid_604539 = query.getOrDefault("Version")
  valid_604539 = validateParameter(valid_604539, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604539 != nil:
    section.add "Version", valid_604539
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604540 = header.getOrDefault("X-Amz-Date")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-Date", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Security-Token")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Security-Token", valid_604541
  var valid_604542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604542 = validateParameter(valid_604542, JString, required = false,
                                 default = nil)
  if valid_604542 != nil:
    section.add "X-Amz-Content-Sha256", valid_604542
  var valid_604543 = header.getOrDefault("X-Amz-Algorithm")
  valid_604543 = validateParameter(valid_604543, JString, required = false,
                                 default = nil)
  if valid_604543 != nil:
    section.add "X-Amz-Algorithm", valid_604543
  var valid_604544 = header.getOrDefault("X-Amz-Signature")
  valid_604544 = validateParameter(valid_604544, JString, required = false,
                                 default = nil)
  if valid_604544 != nil:
    section.add "X-Amz-Signature", valid_604544
  var valid_604545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "X-Amz-SignedHeaders", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-Credential")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-Credential", valid_604546
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604547: Call_GetDescribeReservedDBInstancesOfferings_604526;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604547.validator(path, query, header, formData, body)
  let scheme = call_604547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604547.url(scheme.get, call_604547.host, call_604547.base,
                         call_604547.route, valid.getOrDefault("path"))
  result = hook(call_604547, url, valid)

proc call*(call_604548: Call_GetDescribeReservedDBInstancesOfferings_604526;
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
  var query_604549 = newJObject()
  add(query_604549, "ProductDescription", newJString(ProductDescription))
  add(query_604549, "MaxRecords", newJInt(MaxRecords))
  add(query_604549, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604549.add "Filters", Filters
  add(query_604549, "MultiAZ", newJBool(MultiAZ))
  add(query_604549, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604549, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604549, "Action", newJString(Action))
  add(query_604549, "Marker", newJString(Marker))
  add(query_604549, "Duration", newJString(Duration))
  add(query_604549, "Version", newJString(Version))
  result = call_604548.call(nil, query_604549, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_604526(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_604527, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_604528,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_604594 = ref object of OpenApiRestCall_602417
proc url_PostDownloadDBLogFilePortion_604596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_604595(path: JsonNode; query: JsonNode;
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
  var valid_604597 = query.getOrDefault("Action")
  valid_604597 = validateParameter(valid_604597, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604597 != nil:
    section.add "Action", valid_604597
  var valid_604598 = query.getOrDefault("Version")
  valid_604598 = validateParameter(valid_604598, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604598 != nil:
    section.add "Version", valid_604598
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604599 = header.getOrDefault("X-Amz-Date")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "X-Amz-Date", valid_604599
  var valid_604600 = header.getOrDefault("X-Amz-Security-Token")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Security-Token", valid_604600
  var valid_604601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-Content-Sha256", valid_604601
  var valid_604602 = header.getOrDefault("X-Amz-Algorithm")
  valid_604602 = validateParameter(valid_604602, JString, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "X-Amz-Algorithm", valid_604602
  var valid_604603 = header.getOrDefault("X-Amz-Signature")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-Signature", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-SignedHeaders", valid_604604
  var valid_604605 = header.getOrDefault("X-Amz-Credential")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Credential", valid_604605
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_604606 = formData.getOrDefault("NumberOfLines")
  valid_604606 = validateParameter(valid_604606, JInt, required = false, default = nil)
  if valid_604606 != nil:
    section.add "NumberOfLines", valid_604606
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604607 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604607 = validateParameter(valid_604607, JString, required = true,
                                 default = nil)
  if valid_604607 != nil:
    section.add "DBInstanceIdentifier", valid_604607
  var valid_604608 = formData.getOrDefault("Marker")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "Marker", valid_604608
  var valid_604609 = formData.getOrDefault("LogFileName")
  valid_604609 = validateParameter(valid_604609, JString, required = true,
                                 default = nil)
  if valid_604609 != nil:
    section.add "LogFileName", valid_604609
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604610: Call_PostDownloadDBLogFilePortion_604594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604610.validator(path, query, header, formData, body)
  let scheme = call_604610.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604610.url(scheme.get, call_604610.host, call_604610.base,
                         call_604610.route, valid.getOrDefault("path"))
  result = hook(call_604610, url, valid)

proc call*(call_604611: Call_PostDownloadDBLogFilePortion_604594;
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
  var query_604612 = newJObject()
  var formData_604613 = newJObject()
  add(formData_604613, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_604613, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604613, "Marker", newJString(Marker))
  add(query_604612, "Action", newJString(Action))
  add(formData_604613, "LogFileName", newJString(LogFileName))
  add(query_604612, "Version", newJString(Version))
  result = call_604611.call(nil, query_604612, nil, formData_604613, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_604594(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_604595, base: "/",
    url: url_PostDownloadDBLogFilePortion_604596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_604575 = ref object of OpenApiRestCall_602417
proc url_GetDownloadDBLogFilePortion_604577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_604576(path: JsonNode; query: JsonNode;
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
  var valid_604578 = query.getOrDefault("NumberOfLines")
  valid_604578 = validateParameter(valid_604578, JInt, required = false, default = nil)
  if valid_604578 != nil:
    section.add "NumberOfLines", valid_604578
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_604579 = query.getOrDefault("LogFileName")
  valid_604579 = validateParameter(valid_604579, JString, required = true,
                                 default = nil)
  if valid_604579 != nil:
    section.add "LogFileName", valid_604579
  var valid_604580 = query.getOrDefault("Action")
  valid_604580 = validateParameter(valid_604580, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604580 != nil:
    section.add "Action", valid_604580
  var valid_604581 = query.getOrDefault("Marker")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "Marker", valid_604581
  var valid_604582 = query.getOrDefault("Version")
  valid_604582 = validateParameter(valid_604582, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604582 != nil:
    section.add "Version", valid_604582
  var valid_604583 = query.getOrDefault("DBInstanceIdentifier")
  valid_604583 = validateParameter(valid_604583, JString, required = true,
                                 default = nil)
  if valid_604583 != nil:
    section.add "DBInstanceIdentifier", valid_604583
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604584 = header.getOrDefault("X-Amz-Date")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-Date", valid_604584
  var valid_604585 = header.getOrDefault("X-Amz-Security-Token")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Security-Token", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Content-Sha256", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Algorithm")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Algorithm", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-Signature")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Signature", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-SignedHeaders", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Credential")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Credential", valid_604590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604591: Call_GetDownloadDBLogFilePortion_604575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604591.validator(path, query, header, formData, body)
  let scheme = call_604591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604591.url(scheme.get, call_604591.host, call_604591.base,
                         call_604591.route, valid.getOrDefault("path"))
  result = hook(call_604591, url, valid)

proc call*(call_604592: Call_GetDownloadDBLogFilePortion_604575;
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
  var query_604593 = newJObject()
  add(query_604593, "NumberOfLines", newJInt(NumberOfLines))
  add(query_604593, "LogFileName", newJString(LogFileName))
  add(query_604593, "Action", newJString(Action))
  add(query_604593, "Marker", newJString(Marker))
  add(query_604593, "Version", newJString(Version))
  add(query_604593, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604592.call(nil, query_604593, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_604575(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_604576, base: "/",
    url: url_GetDownloadDBLogFilePortion_604577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604631 = ref object of OpenApiRestCall_602417
proc url_PostListTagsForResource_604633(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_604632(path: JsonNode; query: JsonNode;
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
  var valid_604634 = query.getOrDefault("Action")
  valid_604634 = validateParameter(valid_604634, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604634 != nil:
    section.add "Action", valid_604634
  var valid_604635 = query.getOrDefault("Version")
  valid_604635 = validateParameter(valid_604635, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604635 != nil:
    section.add "Version", valid_604635
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604636 = header.getOrDefault("X-Amz-Date")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-Date", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-Security-Token")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Security-Token", valid_604637
  var valid_604638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "X-Amz-Content-Sha256", valid_604638
  var valid_604639 = header.getOrDefault("X-Amz-Algorithm")
  valid_604639 = validateParameter(valid_604639, JString, required = false,
                                 default = nil)
  if valid_604639 != nil:
    section.add "X-Amz-Algorithm", valid_604639
  var valid_604640 = header.getOrDefault("X-Amz-Signature")
  valid_604640 = validateParameter(valid_604640, JString, required = false,
                                 default = nil)
  if valid_604640 != nil:
    section.add "X-Amz-Signature", valid_604640
  var valid_604641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "X-Amz-SignedHeaders", valid_604641
  var valid_604642 = header.getOrDefault("X-Amz-Credential")
  valid_604642 = validateParameter(valid_604642, JString, required = false,
                                 default = nil)
  if valid_604642 != nil:
    section.add "X-Amz-Credential", valid_604642
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_604643 = formData.getOrDefault("Filters")
  valid_604643 = validateParameter(valid_604643, JArray, required = false,
                                 default = nil)
  if valid_604643 != nil:
    section.add "Filters", valid_604643
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604644 = formData.getOrDefault("ResourceName")
  valid_604644 = validateParameter(valid_604644, JString, required = true,
                                 default = nil)
  if valid_604644 != nil:
    section.add "ResourceName", valid_604644
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604645: Call_PostListTagsForResource_604631; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604645.validator(path, query, header, formData, body)
  let scheme = call_604645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604645.url(scheme.get, call_604645.host, call_604645.base,
                         call_604645.route, valid.getOrDefault("path"))
  result = hook(call_604645, url, valid)

proc call*(call_604646: Call_PostListTagsForResource_604631; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2014-09-01"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604647 = newJObject()
  var formData_604648 = newJObject()
  add(query_604647, "Action", newJString(Action))
  if Filters != nil:
    formData_604648.add "Filters", Filters
  add(formData_604648, "ResourceName", newJString(ResourceName))
  add(query_604647, "Version", newJString(Version))
  result = call_604646.call(nil, query_604647, nil, formData_604648, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604631(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604632, base: "/",
    url: url_PostListTagsForResource_604633, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604614 = ref object of OpenApiRestCall_602417
proc url_GetListTagsForResource_604616(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_604615(path: JsonNode; query: JsonNode;
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
  var valid_604617 = query.getOrDefault("Filters")
  valid_604617 = validateParameter(valid_604617, JArray, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "Filters", valid_604617
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_604618 = query.getOrDefault("ResourceName")
  valid_604618 = validateParameter(valid_604618, JString, required = true,
                                 default = nil)
  if valid_604618 != nil:
    section.add "ResourceName", valid_604618
  var valid_604619 = query.getOrDefault("Action")
  valid_604619 = validateParameter(valid_604619, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604619 != nil:
    section.add "Action", valid_604619
  var valid_604620 = query.getOrDefault("Version")
  valid_604620 = validateParameter(valid_604620, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604620 != nil:
    section.add "Version", valid_604620
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604621 = header.getOrDefault("X-Amz-Date")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-Date", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-Security-Token")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-Security-Token", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Content-Sha256", valid_604623
  var valid_604624 = header.getOrDefault("X-Amz-Algorithm")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "X-Amz-Algorithm", valid_604624
  var valid_604625 = header.getOrDefault("X-Amz-Signature")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "X-Amz-Signature", valid_604625
  var valid_604626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604626 = validateParameter(valid_604626, JString, required = false,
                                 default = nil)
  if valid_604626 != nil:
    section.add "X-Amz-SignedHeaders", valid_604626
  var valid_604627 = header.getOrDefault("X-Amz-Credential")
  valid_604627 = validateParameter(valid_604627, JString, required = false,
                                 default = nil)
  if valid_604627 != nil:
    section.add "X-Amz-Credential", valid_604627
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604628: Call_GetListTagsForResource_604614; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604628.validator(path, query, header, formData, body)
  let scheme = call_604628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604628.url(scheme.get, call_604628.host, call_604628.base,
                         call_604628.route, valid.getOrDefault("path"))
  result = hook(call_604628, url, valid)

proc call*(call_604629: Call_GetListTagsForResource_604614; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2014-09-01"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604630 = newJObject()
  if Filters != nil:
    query_604630.add "Filters", Filters
  add(query_604630, "ResourceName", newJString(ResourceName))
  add(query_604630, "Action", newJString(Action))
  add(query_604630, "Version", newJString(Version))
  result = call_604629.call(nil, query_604630, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604614(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604615, base: "/",
    url: url_GetListTagsForResource_604616, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604685 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBInstance_604687(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_604686(path: JsonNode; query: JsonNode;
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
  var valid_604688 = query.getOrDefault("Action")
  valid_604688 = validateParameter(valid_604688, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604688 != nil:
    section.add "Action", valid_604688
  var valid_604689 = query.getOrDefault("Version")
  valid_604689 = validateParameter(valid_604689, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604689 != nil:
    section.add "Version", valid_604689
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604690 = header.getOrDefault("X-Amz-Date")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-Date", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-Security-Token")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Security-Token", valid_604691
  var valid_604692 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "X-Amz-Content-Sha256", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-Algorithm")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-Algorithm", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Signature")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Signature", valid_604694
  var valid_604695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604695 = validateParameter(valid_604695, JString, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "X-Amz-SignedHeaders", valid_604695
  var valid_604696 = header.getOrDefault("X-Amz-Credential")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-Credential", valid_604696
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
  var valid_604697 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "PreferredMaintenanceWindow", valid_604697
  var valid_604698 = formData.getOrDefault("DBSecurityGroups")
  valid_604698 = validateParameter(valid_604698, JArray, required = false,
                                 default = nil)
  if valid_604698 != nil:
    section.add "DBSecurityGroups", valid_604698
  var valid_604699 = formData.getOrDefault("ApplyImmediately")
  valid_604699 = validateParameter(valid_604699, JBool, required = false, default = nil)
  if valid_604699 != nil:
    section.add "ApplyImmediately", valid_604699
  var valid_604700 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604700 = validateParameter(valid_604700, JArray, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "VpcSecurityGroupIds", valid_604700
  var valid_604701 = formData.getOrDefault("Iops")
  valid_604701 = validateParameter(valid_604701, JInt, required = false, default = nil)
  if valid_604701 != nil:
    section.add "Iops", valid_604701
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604702 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604702 = validateParameter(valid_604702, JString, required = true,
                                 default = nil)
  if valid_604702 != nil:
    section.add "DBInstanceIdentifier", valid_604702
  var valid_604703 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604703 = validateParameter(valid_604703, JInt, required = false, default = nil)
  if valid_604703 != nil:
    section.add "BackupRetentionPeriod", valid_604703
  var valid_604704 = formData.getOrDefault("DBParameterGroupName")
  valid_604704 = validateParameter(valid_604704, JString, required = false,
                                 default = nil)
  if valid_604704 != nil:
    section.add "DBParameterGroupName", valid_604704
  var valid_604705 = formData.getOrDefault("OptionGroupName")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "OptionGroupName", valid_604705
  var valid_604706 = formData.getOrDefault("MasterUserPassword")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "MasterUserPassword", valid_604706
  var valid_604707 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604707 = validateParameter(valid_604707, JString, required = false,
                                 default = nil)
  if valid_604707 != nil:
    section.add "NewDBInstanceIdentifier", valid_604707
  var valid_604708 = formData.getOrDefault("TdeCredentialArn")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "TdeCredentialArn", valid_604708
  var valid_604709 = formData.getOrDefault("TdeCredentialPassword")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "TdeCredentialPassword", valid_604709
  var valid_604710 = formData.getOrDefault("MultiAZ")
  valid_604710 = validateParameter(valid_604710, JBool, required = false, default = nil)
  if valid_604710 != nil:
    section.add "MultiAZ", valid_604710
  var valid_604711 = formData.getOrDefault("AllocatedStorage")
  valid_604711 = validateParameter(valid_604711, JInt, required = false, default = nil)
  if valid_604711 != nil:
    section.add "AllocatedStorage", valid_604711
  var valid_604712 = formData.getOrDefault("StorageType")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "StorageType", valid_604712
  var valid_604713 = formData.getOrDefault("DBInstanceClass")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "DBInstanceClass", valid_604713
  var valid_604714 = formData.getOrDefault("PreferredBackupWindow")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "PreferredBackupWindow", valid_604714
  var valid_604715 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604715 = validateParameter(valid_604715, JBool, required = false, default = nil)
  if valid_604715 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604715
  var valid_604716 = formData.getOrDefault("EngineVersion")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "EngineVersion", valid_604716
  var valid_604717 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_604717 = validateParameter(valid_604717, JBool, required = false, default = nil)
  if valid_604717 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604717
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604718: Call_PostModifyDBInstance_604685; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604718.validator(path, query, header, formData, body)
  let scheme = call_604718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604718.url(scheme.get, call_604718.host, call_604718.base,
                         call_604718.route, valid.getOrDefault("path"))
  result = hook(call_604718, url, valid)

proc call*(call_604719: Call_PostModifyDBInstance_604685;
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
  var query_604720 = newJObject()
  var formData_604721 = newJObject()
  add(formData_604721, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_604721.add "DBSecurityGroups", DBSecurityGroups
  add(formData_604721, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_604721.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604721, "Iops", newJInt(Iops))
  add(formData_604721, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604721, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604721, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604721, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604721, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604721, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_604721, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_604721, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_604721, "MultiAZ", newJBool(MultiAZ))
  add(query_604720, "Action", newJString(Action))
  add(formData_604721, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_604721, "StorageType", newJString(StorageType))
  add(formData_604721, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604721, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604721, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604721, "EngineVersion", newJString(EngineVersion))
  add(query_604720, "Version", newJString(Version))
  add(formData_604721, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_604719.call(nil, query_604720, nil, formData_604721, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604685(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604686, base: "/",
    url: url_PostModifyDBInstance_604687, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604649 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBInstance_604651(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_604650(path: JsonNode; query: JsonNode;
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
  var valid_604652 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "PreferredMaintenanceWindow", valid_604652
  var valid_604653 = query.getOrDefault("AllocatedStorage")
  valid_604653 = validateParameter(valid_604653, JInt, required = false, default = nil)
  if valid_604653 != nil:
    section.add "AllocatedStorage", valid_604653
  var valid_604654 = query.getOrDefault("StorageType")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "StorageType", valid_604654
  var valid_604655 = query.getOrDefault("OptionGroupName")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "OptionGroupName", valid_604655
  var valid_604656 = query.getOrDefault("DBSecurityGroups")
  valid_604656 = validateParameter(valid_604656, JArray, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "DBSecurityGroups", valid_604656
  var valid_604657 = query.getOrDefault("MasterUserPassword")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "MasterUserPassword", valid_604657
  var valid_604658 = query.getOrDefault("Iops")
  valid_604658 = validateParameter(valid_604658, JInt, required = false, default = nil)
  if valid_604658 != nil:
    section.add "Iops", valid_604658
  var valid_604659 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604659 = validateParameter(valid_604659, JArray, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "VpcSecurityGroupIds", valid_604659
  var valid_604660 = query.getOrDefault("MultiAZ")
  valid_604660 = validateParameter(valid_604660, JBool, required = false, default = nil)
  if valid_604660 != nil:
    section.add "MultiAZ", valid_604660
  var valid_604661 = query.getOrDefault("TdeCredentialPassword")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "TdeCredentialPassword", valid_604661
  var valid_604662 = query.getOrDefault("BackupRetentionPeriod")
  valid_604662 = validateParameter(valid_604662, JInt, required = false, default = nil)
  if valid_604662 != nil:
    section.add "BackupRetentionPeriod", valid_604662
  var valid_604663 = query.getOrDefault("DBParameterGroupName")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "DBParameterGroupName", valid_604663
  var valid_604664 = query.getOrDefault("DBInstanceClass")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "DBInstanceClass", valid_604664
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604665 = query.getOrDefault("Action")
  valid_604665 = validateParameter(valid_604665, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604665 != nil:
    section.add "Action", valid_604665
  var valid_604666 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_604666 = validateParameter(valid_604666, JBool, required = false, default = nil)
  if valid_604666 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604666
  var valid_604667 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604667 = validateParameter(valid_604667, JString, required = false,
                                 default = nil)
  if valid_604667 != nil:
    section.add "NewDBInstanceIdentifier", valid_604667
  var valid_604668 = query.getOrDefault("TdeCredentialArn")
  valid_604668 = validateParameter(valid_604668, JString, required = false,
                                 default = nil)
  if valid_604668 != nil:
    section.add "TdeCredentialArn", valid_604668
  var valid_604669 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604669 = validateParameter(valid_604669, JBool, required = false, default = nil)
  if valid_604669 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604669
  var valid_604670 = query.getOrDefault("EngineVersion")
  valid_604670 = validateParameter(valid_604670, JString, required = false,
                                 default = nil)
  if valid_604670 != nil:
    section.add "EngineVersion", valid_604670
  var valid_604671 = query.getOrDefault("PreferredBackupWindow")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "PreferredBackupWindow", valid_604671
  var valid_604672 = query.getOrDefault("Version")
  valid_604672 = validateParameter(valid_604672, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604672 != nil:
    section.add "Version", valid_604672
  var valid_604673 = query.getOrDefault("DBInstanceIdentifier")
  valid_604673 = validateParameter(valid_604673, JString, required = true,
                                 default = nil)
  if valid_604673 != nil:
    section.add "DBInstanceIdentifier", valid_604673
  var valid_604674 = query.getOrDefault("ApplyImmediately")
  valid_604674 = validateParameter(valid_604674, JBool, required = false, default = nil)
  if valid_604674 != nil:
    section.add "ApplyImmediately", valid_604674
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604675 = header.getOrDefault("X-Amz-Date")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Date", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-Security-Token")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Security-Token", valid_604676
  var valid_604677 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604677 = validateParameter(valid_604677, JString, required = false,
                                 default = nil)
  if valid_604677 != nil:
    section.add "X-Amz-Content-Sha256", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-Algorithm")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-Algorithm", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Signature")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Signature", valid_604679
  var valid_604680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "X-Amz-SignedHeaders", valid_604680
  var valid_604681 = header.getOrDefault("X-Amz-Credential")
  valid_604681 = validateParameter(valid_604681, JString, required = false,
                                 default = nil)
  if valid_604681 != nil:
    section.add "X-Amz-Credential", valid_604681
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604682: Call_GetModifyDBInstance_604649; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604682.validator(path, query, header, formData, body)
  let scheme = call_604682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604682.url(scheme.get, call_604682.host, call_604682.base,
                         call_604682.route, valid.getOrDefault("path"))
  result = hook(call_604682, url, valid)

proc call*(call_604683: Call_GetModifyDBInstance_604649;
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
  var query_604684 = newJObject()
  add(query_604684, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604684, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_604684, "StorageType", newJString(StorageType))
  add(query_604684, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_604684.add "DBSecurityGroups", DBSecurityGroups
  add(query_604684, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_604684, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_604684.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_604684, "MultiAZ", newJBool(MultiAZ))
  add(query_604684, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_604684, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604684, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604684, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604684, "Action", newJString(Action))
  add(query_604684, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_604684, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604684, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_604684, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604684, "EngineVersion", newJString(EngineVersion))
  add(query_604684, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604684, "Version", newJString(Version))
  add(query_604684, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604684, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604683.call(nil, query_604684, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604649(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604650, base: "/",
    url: url_GetModifyDBInstance_604651, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_604739 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBParameterGroup_604741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_604740(path: JsonNode; query: JsonNode;
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
  var valid_604742 = query.getOrDefault("Action")
  valid_604742 = validateParameter(valid_604742, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604742 != nil:
    section.add "Action", valid_604742
  var valid_604743 = query.getOrDefault("Version")
  valid_604743 = validateParameter(valid_604743, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604743 != nil:
    section.add "Version", valid_604743
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604744 = header.getOrDefault("X-Amz-Date")
  valid_604744 = validateParameter(valid_604744, JString, required = false,
                                 default = nil)
  if valid_604744 != nil:
    section.add "X-Amz-Date", valid_604744
  var valid_604745 = header.getOrDefault("X-Amz-Security-Token")
  valid_604745 = validateParameter(valid_604745, JString, required = false,
                                 default = nil)
  if valid_604745 != nil:
    section.add "X-Amz-Security-Token", valid_604745
  var valid_604746 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604746 = validateParameter(valid_604746, JString, required = false,
                                 default = nil)
  if valid_604746 != nil:
    section.add "X-Amz-Content-Sha256", valid_604746
  var valid_604747 = header.getOrDefault("X-Amz-Algorithm")
  valid_604747 = validateParameter(valid_604747, JString, required = false,
                                 default = nil)
  if valid_604747 != nil:
    section.add "X-Amz-Algorithm", valid_604747
  var valid_604748 = header.getOrDefault("X-Amz-Signature")
  valid_604748 = validateParameter(valid_604748, JString, required = false,
                                 default = nil)
  if valid_604748 != nil:
    section.add "X-Amz-Signature", valid_604748
  var valid_604749 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604749 = validateParameter(valid_604749, JString, required = false,
                                 default = nil)
  if valid_604749 != nil:
    section.add "X-Amz-SignedHeaders", valid_604749
  var valid_604750 = header.getOrDefault("X-Amz-Credential")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-Credential", valid_604750
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604751 = formData.getOrDefault("DBParameterGroupName")
  valid_604751 = validateParameter(valid_604751, JString, required = true,
                                 default = nil)
  if valid_604751 != nil:
    section.add "DBParameterGroupName", valid_604751
  var valid_604752 = formData.getOrDefault("Parameters")
  valid_604752 = validateParameter(valid_604752, JArray, required = true, default = nil)
  if valid_604752 != nil:
    section.add "Parameters", valid_604752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604753: Call_PostModifyDBParameterGroup_604739; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604753.validator(path, query, header, formData, body)
  let scheme = call_604753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604753.url(scheme.get, call_604753.host, call_604753.base,
                         call_604753.route, valid.getOrDefault("path"))
  result = hook(call_604753, url, valid)

proc call*(call_604754: Call_PostModifyDBParameterGroup_604739;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604755 = newJObject()
  var formData_604756 = newJObject()
  add(formData_604756, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604756.add "Parameters", Parameters
  add(query_604755, "Action", newJString(Action))
  add(query_604755, "Version", newJString(Version))
  result = call_604754.call(nil, query_604755, nil, formData_604756, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_604739(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_604740, base: "/",
    url: url_PostModifyDBParameterGroup_604741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_604722 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBParameterGroup_604724(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_604723(path: JsonNode; query: JsonNode;
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
  var valid_604725 = query.getOrDefault("DBParameterGroupName")
  valid_604725 = validateParameter(valid_604725, JString, required = true,
                                 default = nil)
  if valid_604725 != nil:
    section.add "DBParameterGroupName", valid_604725
  var valid_604726 = query.getOrDefault("Parameters")
  valid_604726 = validateParameter(valid_604726, JArray, required = true, default = nil)
  if valid_604726 != nil:
    section.add "Parameters", valid_604726
  var valid_604727 = query.getOrDefault("Action")
  valid_604727 = validateParameter(valid_604727, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604727 != nil:
    section.add "Action", valid_604727
  var valid_604728 = query.getOrDefault("Version")
  valid_604728 = validateParameter(valid_604728, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604728 != nil:
    section.add "Version", valid_604728
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604729 = header.getOrDefault("X-Amz-Date")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "X-Amz-Date", valid_604729
  var valid_604730 = header.getOrDefault("X-Amz-Security-Token")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "X-Amz-Security-Token", valid_604730
  var valid_604731 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "X-Amz-Content-Sha256", valid_604731
  var valid_604732 = header.getOrDefault("X-Amz-Algorithm")
  valid_604732 = validateParameter(valid_604732, JString, required = false,
                                 default = nil)
  if valid_604732 != nil:
    section.add "X-Amz-Algorithm", valid_604732
  var valid_604733 = header.getOrDefault("X-Amz-Signature")
  valid_604733 = validateParameter(valid_604733, JString, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "X-Amz-Signature", valid_604733
  var valid_604734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604734 = validateParameter(valid_604734, JString, required = false,
                                 default = nil)
  if valid_604734 != nil:
    section.add "X-Amz-SignedHeaders", valid_604734
  var valid_604735 = header.getOrDefault("X-Amz-Credential")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-Credential", valid_604735
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604736: Call_GetModifyDBParameterGroup_604722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604736.validator(path, query, header, formData, body)
  let scheme = call_604736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604736.url(scheme.get, call_604736.host, call_604736.base,
                         call_604736.route, valid.getOrDefault("path"))
  result = hook(call_604736, url, valid)

proc call*(call_604737: Call_GetModifyDBParameterGroup_604722;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604738 = newJObject()
  add(query_604738, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604738.add "Parameters", Parameters
  add(query_604738, "Action", newJString(Action))
  add(query_604738, "Version", newJString(Version))
  result = call_604737.call(nil, query_604738, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_604722(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_604723, base: "/",
    url: url_GetModifyDBParameterGroup_604724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604775 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBSubnetGroup_604777(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_604776(path: JsonNode; query: JsonNode;
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
  var valid_604778 = query.getOrDefault("Action")
  valid_604778 = validateParameter(valid_604778, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604778 != nil:
    section.add "Action", valid_604778
  var valid_604779 = query.getOrDefault("Version")
  valid_604779 = validateParameter(valid_604779, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604779 != nil:
    section.add "Version", valid_604779
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604780 = header.getOrDefault("X-Amz-Date")
  valid_604780 = validateParameter(valid_604780, JString, required = false,
                                 default = nil)
  if valid_604780 != nil:
    section.add "X-Amz-Date", valid_604780
  var valid_604781 = header.getOrDefault("X-Amz-Security-Token")
  valid_604781 = validateParameter(valid_604781, JString, required = false,
                                 default = nil)
  if valid_604781 != nil:
    section.add "X-Amz-Security-Token", valid_604781
  var valid_604782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604782 = validateParameter(valid_604782, JString, required = false,
                                 default = nil)
  if valid_604782 != nil:
    section.add "X-Amz-Content-Sha256", valid_604782
  var valid_604783 = header.getOrDefault("X-Amz-Algorithm")
  valid_604783 = validateParameter(valid_604783, JString, required = false,
                                 default = nil)
  if valid_604783 != nil:
    section.add "X-Amz-Algorithm", valid_604783
  var valid_604784 = header.getOrDefault("X-Amz-Signature")
  valid_604784 = validateParameter(valid_604784, JString, required = false,
                                 default = nil)
  if valid_604784 != nil:
    section.add "X-Amz-Signature", valid_604784
  var valid_604785 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604785 = validateParameter(valid_604785, JString, required = false,
                                 default = nil)
  if valid_604785 != nil:
    section.add "X-Amz-SignedHeaders", valid_604785
  var valid_604786 = header.getOrDefault("X-Amz-Credential")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-Credential", valid_604786
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_604787 = formData.getOrDefault("DBSubnetGroupName")
  valid_604787 = validateParameter(valid_604787, JString, required = true,
                                 default = nil)
  if valid_604787 != nil:
    section.add "DBSubnetGroupName", valid_604787
  var valid_604788 = formData.getOrDefault("SubnetIds")
  valid_604788 = validateParameter(valid_604788, JArray, required = true, default = nil)
  if valid_604788 != nil:
    section.add "SubnetIds", valid_604788
  var valid_604789 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604789 = validateParameter(valid_604789, JString, required = false,
                                 default = nil)
  if valid_604789 != nil:
    section.add "DBSubnetGroupDescription", valid_604789
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604790: Call_PostModifyDBSubnetGroup_604775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604790.validator(path, query, header, formData, body)
  let scheme = call_604790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604790.url(scheme.get, call_604790.host, call_604790.base,
                         call_604790.route, valid.getOrDefault("path"))
  result = hook(call_604790, url, valid)

proc call*(call_604791: Call_PostModifyDBSubnetGroup_604775;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604792 = newJObject()
  var formData_604793 = newJObject()
  add(formData_604793, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604793.add "SubnetIds", SubnetIds
  add(query_604792, "Action", newJString(Action))
  add(formData_604793, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604792, "Version", newJString(Version))
  result = call_604791.call(nil, query_604792, nil, formData_604793, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604775(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604776, base: "/",
    url: url_PostModifyDBSubnetGroup_604777, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604757 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBSubnetGroup_604759(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_604758(path: JsonNode; query: JsonNode;
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
  var valid_604760 = query.getOrDefault("Action")
  valid_604760 = validateParameter(valid_604760, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604760 != nil:
    section.add "Action", valid_604760
  var valid_604761 = query.getOrDefault("DBSubnetGroupName")
  valid_604761 = validateParameter(valid_604761, JString, required = true,
                                 default = nil)
  if valid_604761 != nil:
    section.add "DBSubnetGroupName", valid_604761
  var valid_604762 = query.getOrDefault("SubnetIds")
  valid_604762 = validateParameter(valid_604762, JArray, required = true, default = nil)
  if valid_604762 != nil:
    section.add "SubnetIds", valid_604762
  var valid_604763 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604763 = validateParameter(valid_604763, JString, required = false,
                                 default = nil)
  if valid_604763 != nil:
    section.add "DBSubnetGroupDescription", valid_604763
  var valid_604764 = query.getOrDefault("Version")
  valid_604764 = validateParameter(valid_604764, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604764 != nil:
    section.add "Version", valid_604764
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604765 = header.getOrDefault("X-Amz-Date")
  valid_604765 = validateParameter(valid_604765, JString, required = false,
                                 default = nil)
  if valid_604765 != nil:
    section.add "X-Amz-Date", valid_604765
  var valid_604766 = header.getOrDefault("X-Amz-Security-Token")
  valid_604766 = validateParameter(valid_604766, JString, required = false,
                                 default = nil)
  if valid_604766 != nil:
    section.add "X-Amz-Security-Token", valid_604766
  var valid_604767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604767 = validateParameter(valid_604767, JString, required = false,
                                 default = nil)
  if valid_604767 != nil:
    section.add "X-Amz-Content-Sha256", valid_604767
  var valid_604768 = header.getOrDefault("X-Amz-Algorithm")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Algorithm", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Signature")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Signature", valid_604769
  var valid_604770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604770 = validateParameter(valid_604770, JString, required = false,
                                 default = nil)
  if valid_604770 != nil:
    section.add "X-Amz-SignedHeaders", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-Credential")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-Credential", valid_604771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604772: Call_GetModifyDBSubnetGroup_604757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604772.validator(path, query, header, formData, body)
  let scheme = call_604772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604772.url(scheme.get, call_604772.host, call_604772.base,
                         call_604772.route, valid.getOrDefault("path"))
  result = hook(call_604772, url, valid)

proc call*(call_604773: Call_GetModifyDBSubnetGroup_604757;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2014-09-01"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604774 = newJObject()
  add(query_604774, "Action", newJString(Action))
  add(query_604774, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604774.add "SubnetIds", SubnetIds
  add(query_604774, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604774, "Version", newJString(Version))
  result = call_604773.call(nil, query_604774, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604757(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604758, base: "/",
    url: url_GetModifyDBSubnetGroup_604759, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_604814 = ref object of OpenApiRestCall_602417
proc url_PostModifyEventSubscription_604816(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_604815(path: JsonNode; query: JsonNode;
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
  var valid_604817 = query.getOrDefault("Action")
  valid_604817 = validateParameter(valid_604817, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604817 != nil:
    section.add "Action", valid_604817
  var valid_604818 = query.getOrDefault("Version")
  valid_604818 = validateParameter(valid_604818, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604818 != nil:
    section.add "Version", valid_604818
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604819 = header.getOrDefault("X-Amz-Date")
  valid_604819 = validateParameter(valid_604819, JString, required = false,
                                 default = nil)
  if valid_604819 != nil:
    section.add "X-Amz-Date", valid_604819
  var valid_604820 = header.getOrDefault("X-Amz-Security-Token")
  valid_604820 = validateParameter(valid_604820, JString, required = false,
                                 default = nil)
  if valid_604820 != nil:
    section.add "X-Amz-Security-Token", valid_604820
  var valid_604821 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604821 = validateParameter(valid_604821, JString, required = false,
                                 default = nil)
  if valid_604821 != nil:
    section.add "X-Amz-Content-Sha256", valid_604821
  var valid_604822 = header.getOrDefault("X-Amz-Algorithm")
  valid_604822 = validateParameter(valid_604822, JString, required = false,
                                 default = nil)
  if valid_604822 != nil:
    section.add "X-Amz-Algorithm", valid_604822
  var valid_604823 = header.getOrDefault("X-Amz-Signature")
  valid_604823 = validateParameter(valid_604823, JString, required = false,
                                 default = nil)
  if valid_604823 != nil:
    section.add "X-Amz-Signature", valid_604823
  var valid_604824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604824 = validateParameter(valid_604824, JString, required = false,
                                 default = nil)
  if valid_604824 != nil:
    section.add "X-Amz-SignedHeaders", valid_604824
  var valid_604825 = header.getOrDefault("X-Amz-Credential")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Credential", valid_604825
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_604826 = formData.getOrDefault("Enabled")
  valid_604826 = validateParameter(valid_604826, JBool, required = false, default = nil)
  if valid_604826 != nil:
    section.add "Enabled", valid_604826
  var valid_604827 = formData.getOrDefault("EventCategories")
  valid_604827 = validateParameter(valid_604827, JArray, required = false,
                                 default = nil)
  if valid_604827 != nil:
    section.add "EventCategories", valid_604827
  var valid_604828 = formData.getOrDefault("SnsTopicArn")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "SnsTopicArn", valid_604828
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_604829 = formData.getOrDefault("SubscriptionName")
  valid_604829 = validateParameter(valid_604829, JString, required = true,
                                 default = nil)
  if valid_604829 != nil:
    section.add "SubscriptionName", valid_604829
  var valid_604830 = formData.getOrDefault("SourceType")
  valid_604830 = validateParameter(valid_604830, JString, required = false,
                                 default = nil)
  if valid_604830 != nil:
    section.add "SourceType", valid_604830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604831: Call_PostModifyEventSubscription_604814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604831.validator(path, query, header, formData, body)
  let scheme = call_604831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604831.url(scheme.get, call_604831.host, call_604831.base,
                         call_604831.route, valid.getOrDefault("path"))
  result = hook(call_604831, url, valid)

proc call*(call_604832: Call_PostModifyEventSubscription_604814;
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
  var query_604833 = newJObject()
  var formData_604834 = newJObject()
  add(formData_604834, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_604834.add "EventCategories", EventCategories
  add(formData_604834, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_604834, "SubscriptionName", newJString(SubscriptionName))
  add(query_604833, "Action", newJString(Action))
  add(query_604833, "Version", newJString(Version))
  add(formData_604834, "SourceType", newJString(SourceType))
  result = call_604832.call(nil, query_604833, nil, formData_604834, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_604814(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_604815, base: "/",
    url: url_PostModifyEventSubscription_604816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_604794 = ref object of OpenApiRestCall_602417
proc url_GetModifyEventSubscription_604796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_604795(path: JsonNode; query: JsonNode;
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
  var valid_604797 = query.getOrDefault("SourceType")
  valid_604797 = validateParameter(valid_604797, JString, required = false,
                                 default = nil)
  if valid_604797 != nil:
    section.add "SourceType", valid_604797
  var valid_604798 = query.getOrDefault("Enabled")
  valid_604798 = validateParameter(valid_604798, JBool, required = false, default = nil)
  if valid_604798 != nil:
    section.add "Enabled", valid_604798
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604799 = query.getOrDefault("Action")
  valid_604799 = validateParameter(valid_604799, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604799 != nil:
    section.add "Action", valid_604799
  var valid_604800 = query.getOrDefault("SnsTopicArn")
  valid_604800 = validateParameter(valid_604800, JString, required = false,
                                 default = nil)
  if valid_604800 != nil:
    section.add "SnsTopicArn", valid_604800
  var valid_604801 = query.getOrDefault("EventCategories")
  valid_604801 = validateParameter(valid_604801, JArray, required = false,
                                 default = nil)
  if valid_604801 != nil:
    section.add "EventCategories", valid_604801
  var valid_604802 = query.getOrDefault("SubscriptionName")
  valid_604802 = validateParameter(valid_604802, JString, required = true,
                                 default = nil)
  if valid_604802 != nil:
    section.add "SubscriptionName", valid_604802
  var valid_604803 = query.getOrDefault("Version")
  valid_604803 = validateParameter(valid_604803, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604803 != nil:
    section.add "Version", valid_604803
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604804 = header.getOrDefault("X-Amz-Date")
  valid_604804 = validateParameter(valid_604804, JString, required = false,
                                 default = nil)
  if valid_604804 != nil:
    section.add "X-Amz-Date", valid_604804
  var valid_604805 = header.getOrDefault("X-Amz-Security-Token")
  valid_604805 = validateParameter(valid_604805, JString, required = false,
                                 default = nil)
  if valid_604805 != nil:
    section.add "X-Amz-Security-Token", valid_604805
  var valid_604806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604806 = validateParameter(valid_604806, JString, required = false,
                                 default = nil)
  if valid_604806 != nil:
    section.add "X-Amz-Content-Sha256", valid_604806
  var valid_604807 = header.getOrDefault("X-Amz-Algorithm")
  valid_604807 = validateParameter(valid_604807, JString, required = false,
                                 default = nil)
  if valid_604807 != nil:
    section.add "X-Amz-Algorithm", valid_604807
  var valid_604808 = header.getOrDefault("X-Amz-Signature")
  valid_604808 = validateParameter(valid_604808, JString, required = false,
                                 default = nil)
  if valid_604808 != nil:
    section.add "X-Amz-Signature", valid_604808
  var valid_604809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604809 = validateParameter(valid_604809, JString, required = false,
                                 default = nil)
  if valid_604809 != nil:
    section.add "X-Amz-SignedHeaders", valid_604809
  var valid_604810 = header.getOrDefault("X-Amz-Credential")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Credential", valid_604810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604811: Call_GetModifyEventSubscription_604794; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604811.validator(path, query, header, formData, body)
  let scheme = call_604811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604811.url(scheme.get, call_604811.host, call_604811.base,
                         call_604811.route, valid.getOrDefault("path"))
  result = hook(call_604811, url, valid)

proc call*(call_604812: Call_GetModifyEventSubscription_604794;
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
  var query_604813 = newJObject()
  add(query_604813, "SourceType", newJString(SourceType))
  add(query_604813, "Enabled", newJBool(Enabled))
  add(query_604813, "Action", newJString(Action))
  add(query_604813, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_604813.add "EventCategories", EventCategories
  add(query_604813, "SubscriptionName", newJString(SubscriptionName))
  add(query_604813, "Version", newJString(Version))
  result = call_604812.call(nil, query_604813, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_604794(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_604795, base: "/",
    url: url_GetModifyEventSubscription_604796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_604854 = ref object of OpenApiRestCall_602417
proc url_PostModifyOptionGroup_604856(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_604855(path: JsonNode; query: JsonNode;
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
  var valid_604857 = query.getOrDefault("Action")
  valid_604857 = validateParameter(valid_604857, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604857 != nil:
    section.add "Action", valid_604857
  var valid_604858 = query.getOrDefault("Version")
  valid_604858 = validateParameter(valid_604858, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604858 != nil:
    section.add "Version", valid_604858
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604859 = header.getOrDefault("X-Amz-Date")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Date", valid_604859
  var valid_604860 = header.getOrDefault("X-Amz-Security-Token")
  valid_604860 = validateParameter(valid_604860, JString, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "X-Amz-Security-Token", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-Content-Sha256", valid_604861
  var valid_604862 = header.getOrDefault("X-Amz-Algorithm")
  valid_604862 = validateParameter(valid_604862, JString, required = false,
                                 default = nil)
  if valid_604862 != nil:
    section.add "X-Amz-Algorithm", valid_604862
  var valid_604863 = header.getOrDefault("X-Amz-Signature")
  valid_604863 = validateParameter(valid_604863, JString, required = false,
                                 default = nil)
  if valid_604863 != nil:
    section.add "X-Amz-Signature", valid_604863
  var valid_604864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604864 = validateParameter(valid_604864, JString, required = false,
                                 default = nil)
  if valid_604864 != nil:
    section.add "X-Amz-SignedHeaders", valid_604864
  var valid_604865 = header.getOrDefault("X-Amz-Credential")
  valid_604865 = validateParameter(valid_604865, JString, required = false,
                                 default = nil)
  if valid_604865 != nil:
    section.add "X-Amz-Credential", valid_604865
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_604866 = formData.getOrDefault("OptionsToRemove")
  valid_604866 = validateParameter(valid_604866, JArray, required = false,
                                 default = nil)
  if valid_604866 != nil:
    section.add "OptionsToRemove", valid_604866
  var valid_604867 = formData.getOrDefault("ApplyImmediately")
  valid_604867 = validateParameter(valid_604867, JBool, required = false, default = nil)
  if valid_604867 != nil:
    section.add "ApplyImmediately", valid_604867
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_604868 = formData.getOrDefault("OptionGroupName")
  valid_604868 = validateParameter(valid_604868, JString, required = true,
                                 default = nil)
  if valid_604868 != nil:
    section.add "OptionGroupName", valid_604868
  var valid_604869 = formData.getOrDefault("OptionsToInclude")
  valid_604869 = validateParameter(valid_604869, JArray, required = false,
                                 default = nil)
  if valid_604869 != nil:
    section.add "OptionsToInclude", valid_604869
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604870: Call_PostModifyOptionGroup_604854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604870.validator(path, query, header, formData, body)
  let scheme = call_604870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604870.url(scheme.get, call_604870.host, call_604870.base,
                         call_604870.route, valid.getOrDefault("path"))
  result = hook(call_604870, url, valid)

proc call*(call_604871: Call_PostModifyOptionGroup_604854; OptionGroupName: string;
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
  var query_604872 = newJObject()
  var formData_604873 = newJObject()
  if OptionsToRemove != nil:
    formData_604873.add "OptionsToRemove", OptionsToRemove
  add(formData_604873, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604873, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_604873.add "OptionsToInclude", OptionsToInclude
  add(query_604872, "Action", newJString(Action))
  add(query_604872, "Version", newJString(Version))
  result = call_604871.call(nil, query_604872, nil, formData_604873, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_604854(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_604855, base: "/",
    url: url_PostModifyOptionGroup_604856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_604835 = ref object of OpenApiRestCall_602417
proc url_GetModifyOptionGroup_604837(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_604836(path: JsonNode; query: JsonNode;
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
  var valid_604838 = query.getOrDefault("OptionGroupName")
  valid_604838 = validateParameter(valid_604838, JString, required = true,
                                 default = nil)
  if valid_604838 != nil:
    section.add "OptionGroupName", valid_604838
  var valid_604839 = query.getOrDefault("OptionsToRemove")
  valid_604839 = validateParameter(valid_604839, JArray, required = false,
                                 default = nil)
  if valid_604839 != nil:
    section.add "OptionsToRemove", valid_604839
  var valid_604840 = query.getOrDefault("Action")
  valid_604840 = validateParameter(valid_604840, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604840 != nil:
    section.add "Action", valid_604840
  var valid_604841 = query.getOrDefault("Version")
  valid_604841 = validateParameter(valid_604841, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604841 != nil:
    section.add "Version", valid_604841
  var valid_604842 = query.getOrDefault("ApplyImmediately")
  valid_604842 = validateParameter(valid_604842, JBool, required = false, default = nil)
  if valid_604842 != nil:
    section.add "ApplyImmediately", valid_604842
  var valid_604843 = query.getOrDefault("OptionsToInclude")
  valid_604843 = validateParameter(valid_604843, JArray, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "OptionsToInclude", valid_604843
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604844 = header.getOrDefault("X-Amz-Date")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Date", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Security-Token")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Security-Token", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Content-Sha256", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-Algorithm")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-Algorithm", valid_604847
  var valid_604848 = header.getOrDefault("X-Amz-Signature")
  valid_604848 = validateParameter(valid_604848, JString, required = false,
                                 default = nil)
  if valid_604848 != nil:
    section.add "X-Amz-Signature", valid_604848
  var valid_604849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604849 = validateParameter(valid_604849, JString, required = false,
                                 default = nil)
  if valid_604849 != nil:
    section.add "X-Amz-SignedHeaders", valid_604849
  var valid_604850 = header.getOrDefault("X-Amz-Credential")
  valid_604850 = validateParameter(valid_604850, JString, required = false,
                                 default = nil)
  if valid_604850 != nil:
    section.add "X-Amz-Credential", valid_604850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604851: Call_GetModifyOptionGroup_604835; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604851.validator(path, query, header, formData, body)
  let scheme = call_604851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604851.url(scheme.get, call_604851.host, call_604851.base,
                         call_604851.route, valid.getOrDefault("path"))
  result = hook(call_604851, url, valid)

proc call*(call_604852: Call_GetModifyOptionGroup_604835; OptionGroupName: string;
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
  var query_604853 = newJObject()
  add(query_604853, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_604853.add "OptionsToRemove", OptionsToRemove
  add(query_604853, "Action", newJString(Action))
  add(query_604853, "Version", newJString(Version))
  add(query_604853, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_604853.add "OptionsToInclude", OptionsToInclude
  result = call_604852.call(nil, query_604853, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_604835(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_604836, base: "/",
    url: url_GetModifyOptionGroup_604837, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_604892 = ref object of OpenApiRestCall_602417
proc url_PostPromoteReadReplica_604894(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_604893(path: JsonNode; query: JsonNode;
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
  var valid_604895 = query.getOrDefault("Action")
  valid_604895 = validateParameter(valid_604895, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604895 != nil:
    section.add "Action", valid_604895
  var valid_604896 = query.getOrDefault("Version")
  valid_604896 = validateParameter(valid_604896, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604896 != nil:
    section.add "Version", valid_604896
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604897 = header.getOrDefault("X-Amz-Date")
  valid_604897 = validateParameter(valid_604897, JString, required = false,
                                 default = nil)
  if valid_604897 != nil:
    section.add "X-Amz-Date", valid_604897
  var valid_604898 = header.getOrDefault("X-Amz-Security-Token")
  valid_604898 = validateParameter(valid_604898, JString, required = false,
                                 default = nil)
  if valid_604898 != nil:
    section.add "X-Amz-Security-Token", valid_604898
  var valid_604899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604899 = validateParameter(valid_604899, JString, required = false,
                                 default = nil)
  if valid_604899 != nil:
    section.add "X-Amz-Content-Sha256", valid_604899
  var valid_604900 = header.getOrDefault("X-Amz-Algorithm")
  valid_604900 = validateParameter(valid_604900, JString, required = false,
                                 default = nil)
  if valid_604900 != nil:
    section.add "X-Amz-Algorithm", valid_604900
  var valid_604901 = header.getOrDefault("X-Amz-Signature")
  valid_604901 = validateParameter(valid_604901, JString, required = false,
                                 default = nil)
  if valid_604901 != nil:
    section.add "X-Amz-Signature", valid_604901
  var valid_604902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604902 = validateParameter(valid_604902, JString, required = false,
                                 default = nil)
  if valid_604902 != nil:
    section.add "X-Amz-SignedHeaders", valid_604902
  var valid_604903 = header.getOrDefault("X-Amz-Credential")
  valid_604903 = validateParameter(valid_604903, JString, required = false,
                                 default = nil)
  if valid_604903 != nil:
    section.add "X-Amz-Credential", valid_604903
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604904 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604904 = validateParameter(valid_604904, JString, required = true,
                                 default = nil)
  if valid_604904 != nil:
    section.add "DBInstanceIdentifier", valid_604904
  var valid_604905 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604905 = validateParameter(valid_604905, JInt, required = false, default = nil)
  if valid_604905 != nil:
    section.add "BackupRetentionPeriod", valid_604905
  var valid_604906 = formData.getOrDefault("PreferredBackupWindow")
  valid_604906 = validateParameter(valid_604906, JString, required = false,
                                 default = nil)
  if valid_604906 != nil:
    section.add "PreferredBackupWindow", valid_604906
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604907: Call_PostPromoteReadReplica_604892; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604907.validator(path, query, header, formData, body)
  let scheme = call_604907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604907.url(scheme.get, call_604907.host, call_604907.base,
                         call_604907.route, valid.getOrDefault("path"))
  result = hook(call_604907, url, valid)

proc call*(call_604908: Call_PostPromoteReadReplica_604892;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_604909 = newJObject()
  var formData_604910 = newJObject()
  add(formData_604910, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604910, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604909, "Action", newJString(Action))
  add(formData_604910, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604909, "Version", newJString(Version))
  result = call_604908.call(nil, query_604909, nil, formData_604910, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_604892(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_604893, base: "/",
    url: url_PostPromoteReadReplica_604894, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_604874 = ref object of OpenApiRestCall_602417
proc url_GetPromoteReadReplica_604876(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_604875(path: JsonNode; query: JsonNode;
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
  var valid_604877 = query.getOrDefault("BackupRetentionPeriod")
  valid_604877 = validateParameter(valid_604877, JInt, required = false, default = nil)
  if valid_604877 != nil:
    section.add "BackupRetentionPeriod", valid_604877
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604878 = query.getOrDefault("Action")
  valid_604878 = validateParameter(valid_604878, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604878 != nil:
    section.add "Action", valid_604878
  var valid_604879 = query.getOrDefault("PreferredBackupWindow")
  valid_604879 = validateParameter(valid_604879, JString, required = false,
                                 default = nil)
  if valid_604879 != nil:
    section.add "PreferredBackupWindow", valid_604879
  var valid_604880 = query.getOrDefault("Version")
  valid_604880 = validateParameter(valid_604880, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604880 != nil:
    section.add "Version", valid_604880
  var valid_604881 = query.getOrDefault("DBInstanceIdentifier")
  valid_604881 = validateParameter(valid_604881, JString, required = true,
                                 default = nil)
  if valid_604881 != nil:
    section.add "DBInstanceIdentifier", valid_604881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604882 = header.getOrDefault("X-Amz-Date")
  valid_604882 = validateParameter(valid_604882, JString, required = false,
                                 default = nil)
  if valid_604882 != nil:
    section.add "X-Amz-Date", valid_604882
  var valid_604883 = header.getOrDefault("X-Amz-Security-Token")
  valid_604883 = validateParameter(valid_604883, JString, required = false,
                                 default = nil)
  if valid_604883 != nil:
    section.add "X-Amz-Security-Token", valid_604883
  var valid_604884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604884 = validateParameter(valid_604884, JString, required = false,
                                 default = nil)
  if valid_604884 != nil:
    section.add "X-Amz-Content-Sha256", valid_604884
  var valid_604885 = header.getOrDefault("X-Amz-Algorithm")
  valid_604885 = validateParameter(valid_604885, JString, required = false,
                                 default = nil)
  if valid_604885 != nil:
    section.add "X-Amz-Algorithm", valid_604885
  var valid_604886 = header.getOrDefault("X-Amz-Signature")
  valid_604886 = validateParameter(valid_604886, JString, required = false,
                                 default = nil)
  if valid_604886 != nil:
    section.add "X-Amz-Signature", valid_604886
  var valid_604887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604887 = validateParameter(valid_604887, JString, required = false,
                                 default = nil)
  if valid_604887 != nil:
    section.add "X-Amz-SignedHeaders", valid_604887
  var valid_604888 = header.getOrDefault("X-Amz-Credential")
  valid_604888 = validateParameter(valid_604888, JString, required = false,
                                 default = nil)
  if valid_604888 != nil:
    section.add "X-Amz-Credential", valid_604888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604889: Call_GetPromoteReadReplica_604874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604889.validator(path, query, header, formData, body)
  let scheme = call_604889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604889.url(scheme.get, call_604889.host, call_604889.base,
                         call_604889.route, valid.getOrDefault("path"))
  result = hook(call_604889, url, valid)

proc call*(call_604890: Call_GetPromoteReadReplica_604874;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2014-09-01"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604891 = newJObject()
  add(query_604891, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604891, "Action", newJString(Action))
  add(query_604891, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604891, "Version", newJString(Version))
  add(query_604891, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604890.call(nil, query_604891, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_604874(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_604875, base: "/",
    url: url_GetPromoteReadReplica_604876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_604930 = ref object of OpenApiRestCall_602417
proc url_PostPurchaseReservedDBInstancesOffering_604932(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_604931(path: JsonNode;
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
  var valid_604933 = query.getOrDefault("Action")
  valid_604933 = validateParameter(valid_604933, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604933 != nil:
    section.add "Action", valid_604933
  var valid_604934 = query.getOrDefault("Version")
  valid_604934 = validateParameter(valid_604934, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604934 != nil:
    section.add "Version", valid_604934
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604935 = header.getOrDefault("X-Amz-Date")
  valid_604935 = validateParameter(valid_604935, JString, required = false,
                                 default = nil)
  if valid_604935 != nil:
    section.add "X-Amz-Date", valid_604935
  var valid_604936 = header.getOrDefault("X-Amz-Security-Token")
  valid_604936 = validateParameter(valid_604936, JString, required = false,
                                 default = nil)
  if valid_604936 != nil:
    section.add "X-Amz-Security-Token", valid_604936
  var valid_604937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604937 = validateParameter(valid_604937, JString, required = false,
                                 default = nil)
  if valid_604937 != nil:
    section.add "X-Amz-Content-Sha256", valid_604937
  var valid_604938 = header.getOrDefault("X-Amz-Algorithm")
  valid_604938 = validateParameter(valid_604938, JString, required = false,
                                 default = nil)
  if valid_604938 != nil:
    section.add "X-Amz-Algorithm", valid_604938
  var valid_604939 = header.getOrDefault("X-Amz-Signature")
  valid_604939 = validateParameter(valid_604939, JString, required = false,
                                 default = nil)
  if valid_604939 != nil:
    section.add "X-Amz-Signature", valid_604939
  var valid_604940 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604940 = validateParameter(valid_604940, JString, required = false,
                                 default = nil)
  if valid_604940 != nil:
    section.add "X-Amz-SignedHeaders", valid_604940
  var valid_604941 = header.getOrDefault("X-Amz-Credential")
  valid_604941 = validateParameter(valid_604941, JString, required = false,
                                 default = nil)
  if valid_604941 != nil:
    section.add "X-Amz-Credential", valid_604941
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_604942 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604942 = validateParameter(valid_604942, JString, required = false,
                                 default = nil)
  if valid_604942 != nil:
    section.add "ReservedDBInstanceId", valid_604942
  var valid_604943 = formData.getOrDefault("Tags")
  valid_604943 = validateParameter(valid_604943, JArray, required = false,
                                 default = nil)
  if valid_604943 != nil:
    section.add "Tags", valid_604943
  var valid_604944 = formData.getOrDefault("DBInstanceCount")
  valid_604944 = validateParameter(valid_604944, JInt, required = false, default = nil)
  if valid_604944 != nil:
    section.add "DBInstanceCount", valid_604944
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604945 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604945 = validateParameter(valid_604945, JString, required = true,
                                 default = nil)
  if valid_604945 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604945
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604946: Call_PostPurchaseReservedDBInstancesOffering_604930;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604946.validator(path, query, header, formData, body)
  let scheme = call_604946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604946.url(scheme.get, call_604946.host, call_604946.base,
                         call_604946.route, valid.getOrDefault("path"))
  result = hook(call_604946, url, valid)

proc call*(call_604947: Call_PostPurchaseReservedDBInstancesOffering_604930;
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
  var query_604948 = newJObject()
  var formData_604949 = newJObject()
  add(formData_604949, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_604949.add "Tags", Tags
  add(formData_604949, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604948, "Action", newJString(Action))
  add(formData_604949, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604948, "Version", newJString(Version))
  result = call_604947.call(nil, query_604948, nil, formData_604949, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_604930(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_604931, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_604932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_604911 = ref object of OpenApiRestCall_602417
proc url_GetPurchaseReservedDBInstancesOffering_604913(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_604912(path: JsonNode;
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
  var valid_604914 = query.getOrDefault("DBInstanceCount")
  valid_604914 = validateParameter(valid_604914, JInt, required = false, default = nil)
  if valid_604914 != nil:
    section.add "DBInstanceCount", valid_604914
  var valid_604915 = query.getOrDefault("Tags")
  valid_604915 = validateParameter(valid_604915, JArray, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "Tags", valid_604915
  var valid_604916 = query.getOrDefault("ReservedDBInstanceId")
  valid_604916 = validateParameter(valid_604916, JString, required = false,
                                 default = nil)
  if valid_604916 != nil:
    section.add "ReservedDBInstanceId", valid_604916
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604917 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604917 = validateParameter(valid_604917, JString, required = true,
                                 default = nil)
  if valid_604917 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604917
  var valid_604918 = query.getOrDefault("Action")
  valid_604918 = validateParameter(valid_604918, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604918 != nil:
    section.add "Action", valid_604918
  var valid_604919 = query.getOrDefault("Version")
  valid_604919 = validateParameter(valid_604919, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604919 != nil:
    section.add "Version", valid_604919
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604920 = header.getOrDefault("X-Amz-Date")
  valid_604920 = validateParameter(valid_604920, JString, required = false,
                                 default = nil)
  if valid_604920 != nil:
    section.add "X-Amz-Date", valid_604920
  var valid_604921 = header.getOrDefault("X-Amz-Security-Token")
  valid_604921 = validateParameter(valid_604921, JString, required = false,
                                 default = nil)
  if valid_604921 != nil:
    section.add "X-Amz-Security-Token", valid_604921
  var valid_604922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604922 = validateParameter(valid_604922, JString, required = false,
                                 default = nil)
  if valid_604922 != nil:
    section.add "X-Amz-Content-Sha256", valid_604922
  var valid_604923 = header.getOrDefault("X-Amz-Algorithm")
  valid_604923 = validateParameter(valid_604923, JString, required = false,
                                 default = nil)
  if valid_604923 != nil:
    section.add "X-Amz-Algorithm", valid_604923
  var valid_604924 = header.getOrDefault("X-Amz-Signature")
  valid_604924 = validateParameter(valid_604924, JString, required = false,
                                 default = nil)
  if valid_604924 != nil:
    section.add "X-Amz-Signature", valid_604924
  var valid_604925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604925 = validateParameter(valid_604925, JString, required = false,
                                 default = nil)
  if valid_604925 != nil:
    section.add "X-Amz-SignedHeaders", valid_604925
  var valid_604926 = header.getOrDefault("X-Amz-Credential")
  valid_604926 = validateParameter(valid_604926, JString, required = false,
                                 default = nil)
  if valid_604926 != nil:
    section.add "X-Amz-Credential", valid_604926
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604927: Call_GetPurchaseReservedDBInstancesOffering_604911;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604927.validator(path, query, header, formData, body)
  let scheme = call_604927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604927.url(scheme.get, call_604927.host, call_604927.base,
                         call_604927.route, valid.getOrDefault("path"))
  result = hook(call_604927, url, valid)

proc call*(call_604928: Call_GetPurchaseReservedDBInstancesOffering_604911;
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
  var query_604929 = newJObject()
  add(query_604929, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_604929.add "Tags", Tags
  add(query_604929, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604929, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604929, "Action", newJString(Action))
  add(query_604929, "Version", newJString(Version))
  result = call_604928.call(nil, query_604929, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_604911(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_604912, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_604913,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604967 = ref object of OpenApiRestCall_602417
proc url_PostRebootDBInstance_604969(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_604968(path: JsonNode; query: JsonNode;
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
  var valid_604970 = query.getOrDefault("Action")
  valid_604970 = validateParameter(valid_604970, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604970 != nil:
    section.add "Action", valid_604970
  var valid_604971 = query.getOrDefault("Version")
  valid_604971 = validateParameter(valid_604971, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604971 != nil:
    section.add "Version", valid_604971
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604972 = header.getOrDefault("X-Amz-Date")
  valid_604972 = validateParameter(valid_604972, JString, required = false,
                                 default = nil)
  if valid_604972 != nil:
    section.add "X-Amz-Date", valid_604972
  var valid_604973 = header.getOrDefault("X-Amz-Security-Token")
  valid_604973 = validateParameter(valid_604973, JString, required = false,
                                 default = nil)
  if valid_604973 != nil:
    section.add "X-Amz-Security-Token", valid_604973
  var valid_604974 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604974 = validateParameter(valid_604974, JString, required = false,
                                 default = nil)
  if valid_604974 != nil:
    section.add "X-Amz-Content-Sha256", valid_604974
  var valid_604975 = header.getOrDefault("X-Amz-Algorithm")
  valid_604975 = validateParameter(valid_604975, JString, required = false,
                                 default = nil)
  if valid_604975 != nil:
    section.add "X-Amz-Algorithm", valid_604975
  var valid_604976 = header.getOrDefault("X-Amz-Signature")
  valid_604976 = validateParameter(valid_604976, JString, required = false,
                                 default = nil)
  if valid_604976 != nil:
    section.add "X-Amz-Signature", valid_604976
  var valid_604977 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604977 = validateParameter(valid_604977, JString, required = false,
                                 default = nil)
  if valid_604977 != nil:
    section.add "X-Amz-SignedHeaders", valid_604977
  var valid_604978 = header.getOrDefault("X-Amz-Credential")
  valid_604978 = validateParameter(valid_604978, JString, required = false,
                                 default = nil)
  if valid_604978 != nil:
    section.add "X-Amz-Credential", valid_604978
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604979 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604979 = validateParameter(valid_604979, JString, required = true,
                                 default = nil)
  if valid_604979 != nil:
    section.add "DBInstanceIdentifier", valid_604979
  var valid_604980 = formData.getOrDefault("ForceFailover")
  valid_604980 = validateParameter(valid_604980, JBool, required = false, default = nil)
  if valid_604980 != nil:
    section.add "ForceFailover", valid_604980
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604981: Call_PostRebootDBInstance_604967; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604981.validator(path, query, header, formData, body)
  let scheme = call_604981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604981.url(scheme.get, call_604981.host, call_604981.base,
                         call_604981.route, valid.getOrDefault("path"))
  result = hook(call_604981, url, valid)

proc call*(call_604982: Call_PostRebootDBInstance_604967;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_604983 = newJObject()
  var formData_604984 = newJObject()
  add(formData_604984, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604983, "Action", newJString(Action))
  add(formData_604984, "ForceFailover", newJBool(ForceFailover))
  add(query_604983, "Version", newJString(Version))
  result = call_604982.call(nil, query_604983, nil, formData_604984, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604967(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604968, base: "/",
    url: url_PostRebootDBInstance_604969, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604950 = ref object of OpenApiRestCall_602417
proc url_GetRebootDBInstance_604952(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_604951(path: JsonNode; query: JsonNode;
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
  var valid_604953 = query.getOrDefault("Action")
  valid_604953 = validateParameter(valid_604953, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604953 != nil:
    section.add "Action", valid_604953
  var valid_604954 = query.getOrDefault("ForceFailover")
  valid_604954 = validateParameter(valid_604954, JBool, required = false, default = nil)
  if valid_604954 != nil:
    section.add "ForceFailover", valid_604954
  var valid_604955 = query.getOrDefault("Version")
  valid_604955 = validateParameter(valid_604955, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604955 != nil:
    section.add "Version", valid_604955
  var valid_604956 = query.getOrDefault("DBInstanceIdentifier")
  valid_604956 = validateParameter(valid_604956, JString, required = true,
                                 default = nil)
  if valid_604956 != nil:
    section.add "DBInstanceIdentifier", valid_604956
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604957 = header.getOrDefault("X-Amz-Date")
  valid_604957 = validateParameter(valid_604957, JString, required = false,
                                 default = nil)
  if valid_604957 != nil:
    section.add "X-Amz-Date", valid_604957
  var valid_604958 = header.getOrDefault("X-Amz-Security-Token")
  valid_604958 = validateParameter(valid_604958, JString, required = false,
                                 default = nil)
  if valid_604958 != nil:
    section.add "X-Amz-Security-Token", valid_604958
  var valid_604959 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604959 = validateParameter(valid_604959, JString, required = false,
                                 default = nil)
  if valid_604959 != nil:
    section.add "X-Amz-Content-Sha256", valid_604959
  var valid_604960 = header.getOrDefault("X-Amz-Algorithm")
  valid_604960 = validateParameter(valid_604960, JString, required = false,
                                 default = nil)
  if valid_604960 != nil:
    section.add "X-Amz-Algorithm", valid_604960
  var valid_604961 = header.getOrDefault("X-Amz-Signature")
  valid_604961 = validateParameter(valid_604961, JString, required = false,
                                 default = nil)
  if valid_604961 != nil:
    section.add "X-Amz-Signature", valid_604961
  var valid_604962 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604962 = validateParameter(valid_604962, JString, required = false,
                                 default = nil)
  if valid_604962 != nil:
    section.add "X-Amz-SignedHeaders", valid_604962
  var valid_604963 = header.getOrDefault("X-Amz-Credential")
  valid_604963 = validateParameter(valid_604963, JString, required = false,
                                 default = nil)
  if valid_604963 != nil:
    section.add "X-Amz-Credential", valid_604963
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604964: Call_GetRebootDBInstance_604950; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604964.validator(path, query, header, formData, body)
  let scheme = call_604964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604964.url(scheme.get, call_604964.host, call_604964.base,
                         call_604964.route, valid.getOrDefault("path"))
  result = hook(call_604964, url, valid)

proc call*(call_604965: Call_GetRebootDBInstance_604950;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604966 = newJObject()
  add(query_604966, "Action", newJString(Action))
  add(query_604966, "ForceFailover", newJBool(ForceFailover))
  add(query_604966, "Version", newJString(Version))
  add(query_604966, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604965.call(nil, query_604966, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604950(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604951, base: "/",
    url: url_GetRebootDBInstance_604952, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_605002 = ref object of OpenApiRestCall_602417
proc url_PostRemoveSourceIdentifierFromSubscription_605004(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_605003(path: JsonNode;
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
  var valid_605005 = query.getOrDefault("Action")
  valid_605005 = validateParameter(valid_605005, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_605005 != nil:
    section.add "Action", valid_605005
  var valid_605006 = query.getOrDefault("Version")
  valid_605006 = validateParameter(valid_605006, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605006 != nil:
    section.add "Version", valid_605006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605007 = header.getOrDefault("X-Amz-Date")
  valid_605007 = validateParameter(valid_605007, JString, required = false,
                                 default = nil)
  if valid_605007 != nil:
    section.add "X-Amz-Date", valid_605007
  var valid_605008 = header.getOrDefault("X-Amz-Security-Token")
  valid_605008 = validateParameter(valid_605008, JString, required = false,
                                 default = nil)
  if valid_605008 != nil:
    section.add "X-Amz-Security-Token", valid_605008
  var valid_605009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "X-Amz-Content-Sha256", valid_605009
  var valid_605010 = header.getOrDefault("X-Amz-Algorithm")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "X-Amz-Algorithm", valid_605010
  var valid_605011 = header.getOrDefault("X-Amz-Signature")
  valid_605011 = validateParameter(valid_605011, JString, required = false,
                                 default = nil)
  if valid_605011 != nil:
    section.add "X-Amz-Signature", valid_605011
  var valid_605012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605012 = validateParameter(valid_605012, JString, required = false,
                                 default = nil)
  if valid_605012 != nil:
    section.add "X-Amz-SignedHeaders", valid_605012
  var valid_605013 = header.getOrDefault("X-Amz-Credential")
  valid_605013 = validateParameter(valid_605013, JString, required = false,
                                 default = nil)
  if valid_605013 != nil:
    section.add "X-Amz-Credential", valid_605013
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_605014 = formData.getOrDefault("SourceIdentifier")
  valid_605014 = validateParameter(valid_605014, JString, required = true,
                                 default = nil)
  if valid_605014 != nil:
    section.add "SourceIdentifier", valid_605014
  var valid_605015 = formData.getOrDefault("SubscriptionName")
  valid_605015 = validateParameter(valid_605015, JString, required = true,
                                 default = nil)
  if valid_605015 != nil:
    section.add "SubscriptionName", valid_605015
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605016: Call_PostRemoveSourceIdentifierFromSubscription_605002;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605016.validator(path, query, header, formData, body)
  let scheme = call_605016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605016.url(scheme.get, call_605016.host, call_605016.base,
                         call_605016.route, valid.getOrDefault("path"))
  result = hook(call_605016, url, valid)

proc call*(call_605017: Call_PostRemoveSourceIdentifierFromSubscription_605002;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_605018 = newJObject()
  var formData_605019 = newJObject()
  add(formData_605019, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_605019, "SubscriptionName", newJString(SubscriptionName))
  add(query_605018, "Action", newJString(Action))
  add(query_605018, "Version", newJString(Version))
  result = call_605017.call(nil, query_605018, nil, formData_605019, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_605002(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_605003,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_605004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_604985 = ref object of OpenApiRestCall_602417
proc url_GetRemoveSourceIdentifierFromSubscription_604987(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_604986(path: JsonNode;
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
  var valid_604988 = query.getOrDefault("Action")
  valid_604988 = validateParameter(valid_604988, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604988 != nil:
    section.add "Action", valid_604988
  var valid_604989 = query.getOrDefault("SourceIdentifier")
  valid_604989 = validateParameter(valid_604989, JString, required = true,
                                 default = nil)
  if valid_604989 != nil:
    section.add "SourceIdentifier", valid_604989
  var valid_604990 = query.getOrDefault("SubscriptionName")
  valid_604990 = validateParameter(valid_604990, JString, required = true,
                                 default = nil)
  if valid_604990 != nil:
    section.add "SubscriptionName", valid_604990
  var valid_604991 = query.getOrDefault("Version")
  valid_604991 = validateParameter(valid_604991, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_604991 != nil:
    section.add "Version", valid_604991
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604992 = header.getOrDefault("X-Amz-Date")
  valid_604992 = validateParameter(valid_604992, JString, required = false,
                                 default = nil)
  if valid_604992 != nil:
    section.add "X-Amz-Date", valid_604992
  var valid_604993 = header.getOrDefault("X-Amz-Security-Token")
  valid_604993 = validateParameter(valid_604993, JString, required = false,
                                 default = nil)
  if valid_604993 != nil:
    section.add "X-Amz-Security-Token", valid_604993
  var valid_604994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "X-Amz-Content-Sha256", valid_604994
  var valid_604995 = header.getOrDefault("X-Amz-Algorithm")
  valid_604995 = validateParameter(valid_604995, JString, required = false,
                                 default = nil)
  if valid_604995 != nil:
    section.add "X-Amz-Algorithm", valid_604995
  var valid_604996 = header.getOrDefault("X-Amz-Signature")
  valid_604996 = validateParameter(valid_604996, JString, required = false,
                                 default = nil)
  if valid_604996 != nil:
    section.add "X-Amz-Signature", valid_604996
  var valid_604997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604997 = validateParameter(valid_604997, JString, required = false,
                                 default = nil)
  if valid_604997 != nil:
    section.add "X-Amz-SignedHeaders", valid_604997
  var valid_604998 = header.getOrDefault("X-Amz-Credential")
  valid_604998 = validateParameter(valid_604998, JString, required = false,
                                 default = nil)
  if valid_604998 != nil:
    section.add "X-Amz-Credential", valid_604998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604999: Call_GetRemoveSourceIdentifierFromSubscription_604985;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604999.validator(path, query, header, formData, body)
  let scheme = call_604999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604999.url(scheme.get, call_604999.host, call_604999.base,
                         call_604999.route, valid.getOrDefault("path"))
  result = hook(call_604999, url, valid)

proc call*(call_605000: Call_GetRemoveSourceIdentifierFromSubscription_604985;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2014-09-01"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_605001 = newJObject()
  add(query_605001, "Action", newJString(Action))
  add(query_605001, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_605001, "SubscriptionName", newJString(SubscriptionName))
  add(query_605001, "Version", newJString(Version))
  result = call_605000.call(nil, query_605001, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_604985(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_604986,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_604987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_605037 = ref object of OpenApiRestCall_602417
proc url_PostRemoveTagsFromResource_605039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_605038(path: JsonNode; query: JsonNode;
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
  var valid_605040 = query.getOrDefault("Action")
  valid_605040 = validateParameter(valid_605040, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_605040 != nil:
    section.add "Action", valid_605040
  var valid_605041 = query.getOrDefault("Version")
  valid_605041 = validateParameter(valid_605041, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605041 != nil:
    section.add "Version", valid_605041
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605042 = header.getOrDefault("X-Amz-Date")
  valid_605042 = validateParameter(valid_605042, JString, required = false,
                                 default = nil)
  if valid_605042 != nil:
    section.add "X-Amz-Date", valid_605042
  var valid_605043 = header.getOrDefault("X-Amz-Security-Token")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "X-Amz-Security-Token", valid_605043
  var valid_605044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605044 = validateParameter(valid_605044, JString, required = false,
                                 default = nil)
  if valid_605044 != nil:
    section.add "X-Amz-Content-Sha256", valid_605044
  var valid_605045 = header.getOrDefault("X-Amz-Algorithm")
  valid_605045 = validateParameter(valid_605045, JString, required = false,
                                 default = nil)
  if valid_605045 != nil:
    section.add "X-Amz-Algorithm", valid_605045
  var valid_605046 = header.getOrDefault("X-Amz-Signature")
  valid_605046 = validateParameter(valid_605046, JString, required = false,
                                 default = nil)
  if valid_605046 != nil:
    section.add "X-Amz-Signature", valid_605046
  var valid_605047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605047 = validateParameter(valid_605047, JString, required = false,
                                 default = nil)
  if valid_605047 != nil:
    section.add "X-Amz-SignedHeaders", valid_605047
  var valid_605048 = header.getOrDefault("X-Amz-Credential")
  valid_605048 = validateParameter(valid_605048, JString, required = false,
                                 default = nil)
  if valid_605048 != nil:
    section.add "X-Amz-Credential", valid_605048
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_605049 = formData.getOrDefault("TagKeys")
  valid_605049 = validateParameter(valid_605049, JArray, required = true, default = nil)
  if valid_605049 != nil:
    section.add "TagKeys", valid_605049
  var valid_605050 = formData.getOrDefault("ResourceName")
  valid_605050 = validateParameter(valid_605050, JString, required = true,
                                 default = nil)
  if valid_605050 != nil:
    section.add "ResourceName", valid_605050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605051: Call_PostRemoveTagsFromResource_605037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605051.validator(path, query, header, formData, body)
  let scheme = call_605051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605051.url(scheme.get, call_605051.host, call_605051.base,
                         call_605051.route, valid.getOrDefault("path"))
  result = hook(call_605051, url, valid)

proc call*(call_605052: Call_PostRemoveTagsFromResource_605037; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2014-09-01"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_605053 = newJObject()
  var formData_605054 = newJObject()
  add(query_605053, "Action", newJString(Action))
  if TagKeys != nil:
    formData_605054.add "TagKeys", TagKeys
  add(formData_605054, "ResourceName", newJString(ResourceName))
  add(query_605053, "Version", newJString(Version))
  result = call_605052.call(nil, query_605053, nil, formData_605054, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_605037(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_605038, base: "/",
    url: url_PostRemoveTagsFromResource_605039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_605020 = ref object of OpenApiRestCall_602417
proc url_GetRemoveTagsFromResource_605022(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_605021(path: JsonNode; query: JsonNode;
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
  var valid_605023 = query.getOrDefault("ResourceName")
  valid_605023 = validateParameter(valid_605023, JString, required = true,
                                 default = nil)
  if valid_605023 != nil:
    section.add "ResourceName", valid_605023
  var valid_605024 = query.getOrDefault("Action")
  valid_605024 = validateParameter(valid_605024, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_605024 != nil:
    section.add "Action", valid_605024
  var valid_605025 = query.getOrDefault("TagKeys")
  valid_605025 = validateParameter(valid_605025, JArray, required = true, default = nil)
  if valid_605025 != nil:
    section.add "TagKeys", valid_605025
  var valid_605026 = query.getOrDefault("Version")
  valid_605026 = validateParameter(valid_605026, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605026 != nil:
    section.add "Version", valid_605026
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605027 = header.getOrDefault("X-Amz-Date")
  valid_605027 = validateParameter(valid_605027, JString, required = false,
                                 default = nil)
  if valid_605027 != nil:
    section.add "X-Amz-Date", valid_605027
  var valid_605028 = header.getOrDefault("X-Amz-Security-Token")
  valid_605028 = validateParameter(valid_605028, JString, required = false,
                                 default = nil)
  if valid_605028 != nil:
    section.add "X-Amz-Security-Token", valid_605028
  var valid_605029 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605029 = validateParameter(valid_605029, JString, required = false,
                                 default = nil)
  if valid_605029 != nil:
    section.add "X-Amz-Content-Sha256", valid_605029
  var valid_605030 = header.getOrDefault("X-Amz-Algorithm")
  valid_605030 = validateParameter(valid_605030, JString, required = false,
                                 default = nil)
  if valid_605030 != nil:
    section.add "X-Amz-Algorithm", valid_605030
  var valid_605031 = header.getOrDefault("X-Amz-Signature")
  valid_605031 = validateParameter(valid_605031, JString, required = false,
                                 default = nil)
  if valid_605031 != nil:
    section.add "X-Amz-Signature", valid_605031
  var valid_605032 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605032 = validateParameter(valid_605032, JString, required = false,
                                 default = nil)
  if valid_605032 != nil:
    section.add "X-Amz-SignedHeaders", valid_605032
  var valid_605033 = header.getOrDefault("X-Amz-Credential")
  valid_605033 = validateParameter(valid_605033, JString, required = false,
                                 default = nil)
  if valid_605033 != nil:
    section.add "X-Amz-Credential", valid_605033
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605034: Call_GetRemoveTagsFromResource_605020; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605034.validator(path, query, header, formData, body)
  let scheme = call_605034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605034.url(scheme.get, call_605034.host, call_605034.base,
                         call_605034.route, valid.getOrDefault("path"))
  result = hook(call_605034, url, valid)

proc call*(call_605035: Call_GetRemoveTagsFromResource_605020;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2014-09-01"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_605036 = newJObject()
  add(query_605036, "ResourceName", newJString(ResourceName))
  add(query_605036, "Action", newJString(Action))
  if TagKeys != nil:
    query_605036.add "TagKeys", TagKeys
  add(query_605036, "Version", newJString(Version))
  result = call_605035.call(nil, query_605036, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_605020(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_605021, base: "/",
    url: url_GetRemoveTagsFromResource_605022,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_605073 = ref object of OpenApiRestCall_602417
proc url_PostResetDBParameterGroup_605075(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_605074(path: JsonNode; query: JsonNode;
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
  var valid_605076 = query.getOrDefault("Action")
  valid_605076 = validateParameter(valid_605076, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_605076 != nil:
    section.add "Action", valid_605076
  var valid_605077 = query.getOrDefault("Version")
  valid_605077 = validateParameter(valid_605077, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605077 != nil:
    section.add "Version", valid_605077
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605078 = header.getOrDefault("X-Amz-Date")
  valid_605078 = validateParameter(valid_605078, JString, required = false,
                                 default = nil)
  if valid_605078 != nil:
    section.add "X-Amz-Date", valid_605078
  var valid_605079 = header.getOrDefault("X-Amz-Security-Token")
  valid_605079 = validateParameter(valid_605079, JString, required = false,
                                 default = nil)
  if valid_605079 != nil:
    section.add "X-Amz-Security-Token", valid_605079
  var valid_605080 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605080 = validateParameter(valid_605080, JString, required = false,
                                 default = nil)
  if valid_605080 != nil:
    section.add "X-Amz-Content-Sha256", valid_605080
  var valid_605081 = header.getOrDefault("X-Amz-Algorithm")
  valid_605081 = validateParameter(valid_605081, JString, required = false,
                                 default = nil)
  if valid_605081 != nil:
    section.add "X-Amz-Algorithm", valid_605081
  var valid_605082 = header.getOrDefault("X-Amz-Signature")
  valid_605082 = validateParameter(valid_605082, JString, required = false,
                                 default = nil)
  if valid_605082 != nil:
    section.add "X-Amz-Signature", valid_605082
  var valid_605083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605083 = validateParameter(valid_605083, JString, required = false,
                                 default = nil)
  if valid_605083 != nil:
    section.add "X-Amz-SignedHeaders", valid_605083
  var valid_605084 = header.getOrDefault("X-Amz-Credential")
  valid_605084 = validateParameter(valid_605084, JString, required = false,
                                 default = nil)
  if valid_605084 != nil:
    section.add "X-Amz-Credential", valid_605084
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_605085 = formData.getOrDefault("DBParameterGroupName")
  valid_605085 = validateParameter(valid_605085, JString, required = true,
                                 default = nil)
  if valid_605085 != nil:
    section.add "DBParameterGroupName", valid_605085
  var valid_605086 = formData.getOrDefault("Parameters")
  valid_605086 = validateParameter(valid_605086, JArray, required = false,
                                 default = nil)
  if valid_605086 != nil:
    section.add "Parameters", valid_605086
  var valid_605087 = formData.getOrDefault("ResetAllParameters")
  valid_605087 = validateParameter(valid_605087, JBool, required = false, default = nil)
  if valid_605087 != nil:
    section.add "ResetAllParameters", valid_605087
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605088: Call_PostResetDBParameterGroup_605073; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605088.validator(path, query, header, formData, body)
  let scheme = call_605088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605088.url(scheme.get, call_605088.host, call_605088.base,
                         call_605088.route, valid.getOrDefault("path"))
  result = hook(call_605088, url, valid)

proc call*(call_605089: Call_PostResetDBParameterGroup_605073;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_605090 = newJObject()
  var formData_605091 = newJObject()
  add(formData_605091, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_605091.add "Parameters", Parameters
  add(query_605090, "Action", newJString(Action))
  add(formData_605091, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_605090, "Version", newJString(Version))
  result = call_605089.call(nil, query_605090, nil, formData_605091, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_605073(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_605074, base: "/",
    url: url_PostResetDBParameterGroup_605075,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_605055 = ref object of OpenApiRestCall_602417
proc url_GetResetDBParameterGroup_605057(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_605056(path: JsonNode; query: JsonNode;
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
  var valid_605058 = query.getOrDefault("DBParameterGroupName")
  valid_605058 = validateParameter(valid_605058, JString, required = true,
                                 default = nil)
  if valid_605058 != nil:
    section.add "DBParameterGroupName", valid_605058
  var valid_605059 = query.getOrDefault("Parameters")
  valid_605059 = validateParameter(valid_605059, JArray, required = false,
                                 default = nil)
  if valid_605059 != nil:
    section.add "Parameters", valid_605059
  var valid_605060 = query.getOrDefault("Action")
  valid_605060 = validateParameter(valid_605060, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_605060 != nil:
    section.add "Action", valid_605060
  var valid_605061 = query.getOrDefault("ResetAllParameters")
  valid_605061 = validateParameter(valid_605061, JBool, required = false, default = nil)
  if valid_605061 != nil:
    section.add "ResetAllParameters", valid_605061
  var valid_605062 = query.getOrDefault("Version")
  valid_605062 = validateParameter(valid_605062, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605062 != nil:
    section.add "Version", valid_605062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605063 = header.getOrDefault("X-Amz-Date")
  valid_605063 = validateParameter(valid_605063, JString, required = false,
                                 default = nil)
  if valid_605063 != nil:
    section.add "X-Amz-Date", valid_605063
  var valid_605064 = header.getOrDefault("X-Amz-Security-Token")
  valid_605064 = validateParameter(valid_605064, JString, required = false,
                                 default = nil)
  if valid_605064 != nil:
    section.add "X-Amz-Security-Token", valid_605064
  var valid_605065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605065 = validateParameter(valid_605065, JString, required = false,
                                 default = nil)
  if valid_605065 != nil:
    section.add "X-Amz-Content-Sha256", valid_605065
  var valid_605066 = header.getOrDefault("X-Amz-Algorithm")
  valid_605066 = validateParameter(valid_605066, JString, required = false,
                                 default = nil)
  if valid_605066 != nil:
    section.add "X-Amz-Algorithm", valid_605066
  var valid_605067 = header.getOrDefault("X-Amz-Signature")
  valid_605067 = validateParameter(valid_605067, JString, required = false,
                                 default = nil)
  if valid_605067 != nil:
    section.add "X-Amz-Signature", valid_605067
  var valid_605068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605068 = validateParameter(valid_605068, JString, required = false,
                                 default = nil)
  if valid_605068 != nil:
    section.add "X-Amz-SignedHeaders", valid_605068
  var valid_605069 = header.getOrDefault("X-Amz-Credential")
  valid_605069 = validateParameter(valid_605069, JString, required = false,
                                 default = nil)
  if valid_605069 != nil:
    section.add "X-Amz-Credential", valid_605069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605070: Call_GetResetDBParameterGroup_605055; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_605070.validator(path, query, header, formData, body)
  let scheme = call_605070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605070.url(scheme.get, call_605070.host, call_605070.base,
                         call_605070.route, valid.getOrDefault("path"))
  result = hook(call_605070, url, valid)

proc call*(call_605071: Call_GetResetDBParameterGroup_605055;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2014-09-01"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_605072 = newJObject()
  add(query_605072, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_605072.add "Parameters", Parameters
  add(query_605072, "Action", newJString(Action))
  add(query_605072, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_605072, "Version", newJString(Version))
  result = call_605071.call(nil, query_605072, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_605055(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_605056, base: "/",
    url: url_GetResetDBParameterGroup_605057, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_605125 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBInstanceFromDBSnapshot_605127(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_605126(path: JsonNode;
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
  var valid_605128 = query.getOrDefault("Action")
  valid_605128 = validateParameter(valid_605128, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605128 != nil:
    section.add "Action", valid_605128
  var valid_605129 = query.getOrDefault("Version")
  valid_605129 = validateParameter(valid_605129, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605129 != nil:
    section.add "Version", valid_605129
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605130 = header.getOrDefault("X-Amz-Date")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "X-Amz-Date", valid_605130
  var valid_605131 = header.getOrDefault("X-Amz-Security-Token")
  valid_605131 = validateParameter(valid_605131, JString, required = false,
                                 default = nil)
  if valid_605131 != nil:
    section.add "X-Amz-Security-Token", valid_605131
  var valid_605132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605132 = validateParameter(valid_605132, JString, required = false,
                                 default = nil)
  if valid_605132 != nil:
    section.add "X-Amz-Content-Sha256", valid_605132
  var valid_605133 = header.getOrDefault("X-Amz-Algorithm")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "X-Amz-Algorithm", valid_605133
  var valid_605134 = header.getOrDefault("X-Amz-Signature")
  valid_605134 = validateParameter(valid_605134, JString, required = false,
                                 default = nil)
  if valid_605134 != nil:
    section.add "X-Amz-Signature", valid_605134
  var valid_605135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605135 = validateParameter(valid_605135, JString, required = false,
                                 default = nil)
  if valid_605135 != nil:
    section.add "X-Amz-SignedHeaders", valid_605135
  var valid_605136 = header.getOrDefault("X-Amz-Credential")
  valid_605136 = validateParameter(valid_605136, JString, required = false,
                                 default = nil)
  if valid_605136 != nil:
    section.add "X-Amz-Credential", valid_605136
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
  var valid_605137 = formData.getOrDefault("Port")
  valid_605137 = validateParameter(valid_605137, JInt, required = false, default = nil)
  if valid_605137 != nil:
    section.add "Port", valid_605137
  var valid_605138 = formData.getOrDefault("Engine")
  valid_605138 = validateParameter(valid_605138, JString, required = false,
                                 default = nil)
  if valid_605138 != nil:
    section.add "Engine", valid_605138
  var valid_605139 = formData.getOrDefault("Iops")
  valid_605139 = validateParameter(valid_605139, JInt, required = false, default = nil)
  if valid_605139 != nil:
    section.add "Iops", valid_605139
  var valid_605140 = formData.getOrDefault("DBName")
  valid_605140 = validateParameter(valid_605140, JString, required = false,
                                 default = nil)
  if valid_605140 != nil:
    section.add "DBName", valid_605140
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_605141 = formData.getOrDefault("DBInstanceIdentifier")
  valid_605141 = validateParameter(valid_605141, JString, required = true,
                                 default = nil)
  if valid_605141 != nil:
    section.add "DBInstanceIdentifier", valid_605141
  var valid_605142 = formData.getOrDefault("OptionGroupName")
  valid_605142 = validateParameter(valid_605142, JString, required = false,
                                 default = nil)
  if valid_605142 != nil:
    section.add "OptionGroupName", valid_605142
  var valid_605143 = formData.getOrDefault("Tags")
  valid_605143 = validateParameter(valid_605143, JArray, required = false,
                                 default = nil)
  if valid_605143 != nil:
    section.add "Tags", valid_605143
  var valid_605144 = formData.getOrDefault("TdeCredentialArn")
  valid_605144 = validateParameter(valid_605144, JString, required = false,
                                 default = nil)
  if valid_605144 != nil:
    section.add "TdeCredentialArn", valid_605144
  var valid_605145 = formData.getOrDefault("DBSubnetGroupName")
  valid_605145 = validateParameter(valid_605145, JString, required = false,
                                 default = nil)
  if valid_605145 != nil:
    section.add "DBSubnetGroupName", valid_605145
  var valid_605146 = formData.getOrDefault("TdeCredentialPassword")
  valid_605146 = validateParameter(valid_605146, JString, required = false,
                                 default = nil)
  if valid_605146 != nil:
    section.add "TdeCredentialPassword", valid_605146
  var valid_605147 = formData.getOrDefault("AvailabilityZone")
  valid_605147 = validateParameter(valid_605147, JString, required = false,
                                 default = nil)
  if valid_605147 != nil:
    section.add "AvailabilityZone", valid_605147
  var valid_605148 = formData.getOrDefault("MultiAZ")
  valid_605148 = validateParameter(valid_605148, JBool, required = false, default = nil)
  if valid_605148 != nil:
    section.add "MultiAZ", valid_605148
  var valid_605149 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_605149 = validateParameter(valid_605149, JString, required = true,
                                 default = nil)
  if valid_605149 != nil:
    section.add "DBSnapshotIdentifier", valid_605149
  var valid_605150 = formData.getOrDefault("PubliclyAccessible")
  valid_605150 = validateParameter(valid_605150, JBool, required = false, default = nil)
  if valid_605150 != nil:
    section.add "PubliclyAccessible", valid_605150
  var valid_605151 = formData.getOrDefault("StorageType")
  valid_605151 = validateParameter(valid_605151, JString, required = false,
                                 default = nil)
  if valid_605151 != nil:
    section.add "StorageType", valid_605151
  var valid_605152 = formData.getOrDefault("DBInstanceClass")
  valid_605152 = validateParameter(valid_605152, JString, required = false,
                                 default = nil)
  if valid_605152 != nil:
    section.add "DBInstanceClass", valid_605152
  var valid_605153 = formData.getOrDefault("LicenseModel")
  valid_605153 = validateParameter(valid_605153, JString, required = false,
                                 default = nil)
  if valid_605153 != nil:
    section.add "LicenseModel", valid_605153
  var valid_605154 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605154 = validateParameter(valid_605154, JBool, required = false, default = nil)
  if valid_605154 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605154
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605155: Call_PostRestoreDBInstanceFromDBSnapshot_605125;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605155.validator(path, query, header, formData, body)
  let scheme = call_605155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605155.url(scheme.get, call_605155.host, call_605155.base,
                         call_605155.route, valid.getOrDefault("path"))
  result = hook(call_605155, url, valid)

proc call*(call_605156: Call_PostRestoreDBInstanceFromDBSnapshot_605125;
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
  var query_605157 = newJObject()
  var formData_605158 = newJObject()
  add(formData_605158, "Port", newJInt(Port))
  add(formData_605158, "Engine", newJString(Engine))
  add(formData_605158, "Iops", newJInt(Iops))
  add(formData_605158, "DBName", newJString(DBName))
  add(formData_605158, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_605158, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605158.add "Tags", Tags
  add(formData_605158, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_605158, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605158, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_605158, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605158, "MultiAZ", newJBool(MultiAZ))
  add(formData_605158, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_605157, "Action", newJString(Action))
  add(formData_605158, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605158, "StorageType", newJString(StorageType))
  add(formData_605158, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605158, "LicenseModel", newJString(LicenseModel))
  add(formData_605158, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605157, "Version", newJString(Version))
  result = call_605156.call(nil, query_605157, nil, formData_605158, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_605125(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_605126, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_605127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_605092 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBInstanceFromDBSnapshot_605094(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_605093(path: JsonNode;
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
  var valid_605095 = query.getOrDefault("Engine")
  valid_605095 = validateParameter(valid_605095, JString, required = false,
                                 default = nil)
  if valid_605095 != nil:
    section.add "Engine", valid_605095
  var valid_605096 = query.getOrDefault("StorageType")
  valid_605096 = validateParameter(valid_605096, JString, required = false,
                                 default = nil)
  if valid_605096 != nil:
    section.add "StorageType", valid_605096
  var valid_605097 = query.getOrDefault("OptionGroupName")
  valid_605097 = validateParameter(valid_605097, JString, required = false,
                                 default = nil)
  if valid_605097 != nil:
    section.add "OptionGroupName", valid_605097
  var valid_605098 = query.getOrDefault("AvailabilityZone")
  valid_605098 = validateParameter(valid_605098, JString, required = false,
                                 default = nil)
  if valid_605098 != nil:
    section.add "AvailabilityZone", valid_605098
  var valid_605099 = query.getOrDefault("Iops")
  valid_605099 = validateParameter(valid_605099, JInt, required = false, default = nil)
  if valid_605099 != nil:
    section.add "Iops", valid_605099
  var valid_605100 = query.getOrDefault("MultiAZ")
  valid_605100 = validateParameter(valid_605100, JBool, required = false, default = nil)
  if valid_605100 != nil:
    section.add "MultiAZ", valid_605100
  var valid_605101 = query.getOrDefault("TdeCredentialPassword")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "TdeCredentialPassword", valid_605101
  var valid_605102 = query.getOrDefault("LicenseModel")
  valid_605102 = validateParameter(valid_605102, JString, required = false,
                                 default = nil)
  if valid_605102 != nil:
    section.add "LicenseModel", valid_605102
  var valid_605103 = query.getOrDefault("Tags")
  valid_605103 = validateParameter(valid_605103, JArray, required = false,
                                 default = nil)
  if valid_605103 != nil:
    section.add "Tags", valid_605103
  var valid_605104 = query.getOrDefault("DBName")
  valid_605104 = validateParameter(valid_605104, JString, required = false,
                                 default = nil)
  if valid_605104 != nil:
    section.add "DBName", valid_605104
  var valid_605105 = query.getOrDefault("DBInstanceClass")
  valid_605105 = validateParameter(valid_605105, JString, required = false,
                                 default = nil)
  if valid_605105 != nil:
    section.add "DBInstanceClass", valid_605105
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605106 = query.getOrDefault("Action")
  valid_605106 = validateParameter(valid_605106, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605106 != nil:
    section.add "Action", valid_605106
  var valid_605107 = query.getOrDefault("DBSubnetGroupName")
  valid_605107 = validateParameter(valid_605107, JString, required = false,
                                 default = nil)
  if valid_605107 != nil:
    section.add "DBSubnetGroupName", valid_605107
  var valid_605108 = query.getOrDefault("TdeCredentialArn")
  valid_605108 = validateParameter(valid_605108, JString, required = false,
                                 default = nil)
  if valid_605108 != nil:
    section.add "TdeCredentialArn", valid_605108
  var valid_605109 = query.getOrDefault("PubliclyAccessible")
  valid_605109 = validateParameter(valid_605109, JBool, required = false, default = nil)
  if valid_605109 != nil:
    section.add "PubliclyAccessible", valid_605109
  var valid_605110 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605110 = validateParameter(valid_605110, JBool, required = false, default = nil)
  if valid_605110 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605110
  var valid_605111 = query.getOrDefault("Port")
  valid_605111 = validateParameter(valid_605111, JInt, required = false, default = nil)
  if valid_605111 != nil:
    section.add "Port", valid_605111
  var valid_605112 = query.getOrDefault("Version")
  valid_605112 = validateParameter(valid_605112, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605112 != nil:
    section.add "Version", valid_605112
  var valid_605113 = query.getOrDefault("DBInstanceIdentifier")
  valid_605113 = validateParameter(valid_605113, JString, required = true,
                                 default = nil)
  if valid_605113 != nil:
    section.add "DBInstanceIdentifier", valid_605113
  var valid_605114 = query.getOrDefault("DBSnapshotIdentifier")
  valid_605114 = validateParameter(valid_605114, JString, required = true,
                                 default = nil)
  if valid_605114 != nil:
    section.add "DBSnapshotIdentifier", valid_605114
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605115 = header.getOrDefault("X-Amz-Date")
  valid_605115 = validateParameter(valid_605115, JString, required = false,
                                 default = nil)
  if valid_605115 != nil:
    section.add "X-Amz-Date", valid_605115
  var valid_605116 = header.getOrDefault("X-Amz-Security-Token")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-Security-Token", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-Content-Sha256", valid_605117
  var valid_605118 = header.getOrDefault("X-Amz-Algorithm")
  valid_605118 = validateParameter(valid_605118, JString, required = false,
                                 default = nil)
  if valid_605118 != nil:
    section.add "X-Amz-Algorithm", valid_605118
  var valid_605119 = header.getOrDefault("X-Amz-Signature")
  valid_605119 = validateParameter(valid_605119, JString, required = false,
                                 default = nil)
  if valid_605119 != nil:
    section.add "X-Amz-Signature", valid_605119
  var valid_605120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605120 = validateParameter(valid_605120, JString, required = false,
                                 default = nil)
  if valid_605120 != nil:
    section.add "X-Amz-SignedHeaders", valid_605120
  var valid_605121 = header.getOrDefault("X-Amz-Credential")
  valid_605121 = validateParameter(valid_605121, JString, required = false,
                                 default = nil)
  if valid_605121 != nil:
    section.add "X-Amz-Credential", valid_605121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605122: Call_GetRestoreDBInstanceFromDBSnapshot_605092;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605122.validator(path, query, header, formData, body)
  let scheme = call_605122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605122.url(scheme.get, call_605122.host, call_605122.base,
                         call_605122.route, valid.getOrDefault("path"))
  result = hook(call_605122, url, valid)

proc call*(call_605123: Call_GetRestoreDBInstanceFromDBSnapshot_605092;
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
  var query_605124 = newJObject()
  add(query_605124, "Engine", newJString(Engine))
  add(query_605124, "StorageType", newJString(StorageType))
  add(query_605124, "OptionGroupName", newJString(OptionGroupName))
  add(query_605124, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605124, "Iops", newJInt(Iops))
  add(query_605124, "MultiAZ", newJBool(MultiAZ))
  add(query_605124, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_605124, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605124.add "Tags", Tags
  add(query_605124, "DBName", newJString(DBName))
  add(query_605124, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605124, "Action", newJString(Action))
  add(query_605124, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605124, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_605124, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605124, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605124, "Port", newJInt(Port))
  add(query_605124, "Version", newJString(Version))
  add(query_605124, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_605124, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_605123.call(nil, query_605124, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_605092(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_605093, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_605094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_605194 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBInstanceToPointInTime_605196(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_605195(path: JsonNode;
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
  var valid_605197 = query.getOrDefault("Action")
  valid_605197 = validateParameter(valid_605197, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605197 != nil:
    section.add "Action", valid_605197
  var valid_605198 = query.getOrDefault("Version")
  valid_605198 = validateParameter(valid_605198, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605198 != nil:
    section.add "Version", valid_605198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605199 = header.getOrDefault("X-Amz-Date")
  valid_605199 = validateParameter(valid_605199, JString, required = false,
                                 default = nil)
  if valid_605199 != nil:
    section.add "X-Amz-Date", valid_605199
  var valid_605200 = header.getOrDefault("X-Amz-Security-Token")
  valid_605200 = validateParameter(valid_605200, JString, required = false,
                                 default = nil)
  if valid_605200 != nil:
    section.add "X-Amz-Security-Token", valid_605200
  var valid_605201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605201 = validateParameter(valid_605201, JString, required = false,
                                 default = nil)
  if valid_605201 != nil:
    section.add "X-Amz-Content-Sha256", valid_605201
  var valid_605202 = header.getOrDefault("X-Amz-Algorithm")
  valid_605202 = validateParameter(valid_605202, JString, required = false,
                                 default = nil)
  if valid_605202 != nil:
    section.add "X-Amz-Algorithm", valid_605202
  var valid_605203 = header.getOrDefault("X-Amz-Signature")
  valid_605203 = validateParameter(valid_605203, JString, required = false,
                                 default = nil)
  if valid_605203 != nil:
    section.add "X-Amz-Signature", valid_605203
  var valid_605204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605204 = validateParameter(valid_605204, JString, required = false,
                                 default = nil)
  if valid_605204 != nil:
    section.add "X-Amz-SignedHeaders", valid_605204
  var valid_605205 = header.getOrDefault("X-Amz-Credential")
  valid_605205 = validateParameter(valid_605205, JString, required = false,
                                 default = nil)
  if valid_605205 != nil:
    section.add "X-Amz-Credential", valid_605205
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
  var valid_605206 = formData.getOrDefault("UseLatestRestorableTime")
  valid_605206 = validateParameter(valid_605206, JBool, required = false, default = nil)
  if valid_605206 != nil:
    section.add "UseLatestRestorableTime", valid_605206
  var valid_605207 = formData.getOrDefault("Port")
  valid_605207 = validateParameter(valid_605207, JInt, required = false, default = nil)
  if valid_605207 != nil:
    section.add "Port", valid_605207
  var valid_605208 = formData.getOrDefault("Engine")
  valid_605208 = validateParameter(valid_605208, JString, required = false,
                                 default = nil)
  if valid_605208 != nil:
    section.add "Engine", valid_605208
  var valid_605209 = formData.getOrDefault("Iops")
  valid_605209 = validateParameter(valid_605209, JInt, required = false, default = nil)
  if valid_605209 != nil:
    section.add "Iops", valid_605209
  var valid_605210 = formData.getOrDefault("DBName")
  valid_605210 = validateParameter(valid_605210, JString, required = false,
                                 default = nil)
  if valid_605210 != nil:
    section.add "DBName", valid_605210
  var valid_605211 = formData.getOrDefault("OptionGroupName")
  valid_605211 = validateParameter(valid_605211, JString, required = false,
                                 default = nil)
  if valid_605211 != nil:
    section.add "OptionGroupName", valid_605211
  var valid_605212 = formData.getOrDefault("Tags")
  valid_605212 = validateParameter(valid_605212, JArray, required = false,
                                 default = nil)
  if valid_605212 != nil:
    section.add "Tags", valid_605212
  var valid_605213 = formData.getOrDefault("TdeCredentialArn")
  valid_605213 = validateParameter(valid_605213, JString, required = false,
                                 default = nil)
  if valid_605213 != nil:
    section.add "TdeCredentialArn", valid_605213
  var valid_605214 = formData.getOrDefault("DBSubnetGroupName")
  valid_605214 = validateParameter(valid_605214, JString, required = false,
                                 default = nil)
  if valid_605214 != nil:
    section.add "DBSubnetGroupName", valid_605214
  var valid_605215 = formData.getOrDefault("TdeCredentialPassword")
  valid_605215 = validateParameter(valid_605215, JString, required = false,
                                 default = nil)
  if valid_605215 != nil:
    section.add "TdeCredentialPassword", valid_605215
  var valid_605216 = formData.getOrDefault("AvailabilityZone")
  valid_605216 = validateParameter(valid_605216, JString, required = false,
                                 default = nil)
  if valid_605216 != nil:
    section.add "AvailabilityZone", valid_605216
  var valid_605217 = formData.getOrDefault("MultiAZ")
  valid_605217 = validateParameter(valid_605217, JBool, required = false, default = nil)
  if valid_605217 != nil:
    section.add "MultiAZ", valid_605217
  var valid_605218 = formData.getOrDefault("RestoreTime")
  valid_605218 = validateParameter(valid_605218, JString, required = false,
                                 default = nil)
  if valid_605218 != nil:
    section.add "RestoreTime", valid_605218
  var valid_605219 = formData.getOrDefault("PubliclyAccessible")
  valid_605219 = validateParameter(valid_605219, JBool, required = false, default = nil)
  if valid_605219 != nil:
    section.add "PubliclyAccessible", valid_605219
  var valid_605220 = formData.getOrDefault("StorageType")
  valid_605220 = validateParameter(valid_605220, JString, required = false,
                                 default = nil)
  if valid_605220 != nil:
    section.add "StorageType", valid_605220
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_605221 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_605221 = validateParameter(valid_605221, JString, required = true,
                                 default = nil)
  if valid_605221 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605221
  var valid_605222 = formData.getOrDefault("DBInstanceClass")
  valid_605222 = validateParameter(valid_605222, JString, required = false,
                                 default = nil)
  if valid_605222 != nil:
    section.add "DBInstanceClass", valid_605222
  var valid_605223 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_605223 = validateParameter(valid_605223, JString, required = true,
                                 default = nil)
  if valid_605223 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605223
  var valid_605224 = formData.getOrDefault("LicenseModel")
  valid_605224 = validateParameter(valid_605224, JString, required = false,
                                 default = nil)
  if valid_605224 != nil:
    section.add "LicenseModel", valid_605224
  var valid_605225 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605225 = validateParameter(valid_605225, JBool, required = false, default = nil)
  if valid_605225 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605225
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605226: Call_PostRestoreDBInstanceToPointInTime_605194;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605226.validator(path, query, header, formData, body)
  let scheme = call_605226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605226.url(scheme.get, call_605226.host, call_605226.base,
                         call_605226.route, valid.getOrDefault("path"))
  result = hook(call_605226, url, valid)

proc call*(call_605227: Call_PostRestoreDBInstanceToPointInTime_605194;
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
  var query_605228 = newJObject()
  var formData_605229 = newJObject()
  add(formData_605229, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_605229, "Port", newJInt(Port))
  add(formData_605229, "Engine", newJString(Engine))
  add(formData_605229, "Iops", newJInt(Iops))
  add(formData_605229, "DBName", newJString(DBName))
  add(formData_605229, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605229.add "Tags", Tags
  add(formData_605229, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_605229, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605229, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(formData_605229, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605229, "MultiAZ", newJBool(MultiAZ))
  add(query_605228, "Action", newJString(Action))
  add(formData_605229, "RestoreTime", newJString(RestoreTime))
  add(formData_605229, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605229, "StorageType", newJString(StorageType))
  add(formData_605229, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_605229, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605229, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_605229, "LicenseModel", newJString(LicenseModel))
  add(formData_605229, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605228, "Version", newJString(Version))
  result = call_605227.call(nil, query_605228, nil, formData_605229, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_605194(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_605195, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_605196,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_605159 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBInstanceToPointInTime_605161(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_605160(path: JsonNode;
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
  var valid_605162 = query.getOrDefault("Engine")
  valid_605162 = validateParameter(valid_605162, JString, required = false,
                                 default = nil)
  if valid_605162 != nil:
    section.add "Engine", valid_605162
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_605163 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_605163 = validateParameter(valid_605163, JString, required = true,
                                 default = nil)
  if valid_605163 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605163
  var valid_605164 = query.getOrDefault("StorageType")
  valid_605164 = validateParameter(valid_605164, JString, required = false,
                                 default = nil)
  if valid_605164 != nil:
    section.add "StorageType", valid_605164
  var valid_605165 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_605165 = validateParameter(valid_605165, JString, required = true,
                                 default = nil)
  if valid_605165 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605165
  var valid_605166 = query.getOrDefault("AvailabilityZone")
  valid_605166 = validateParameter(valid_605166, JString, required = false,
                                 default = nil)
  if valid_605166 != nil:
    section.add "AvailabilityZone", valid_605166
  var valid_605167 = query.getOrDefault("Iops")
  valid_605167 = validateParameter(valid_605167, JInt, required = false, default = nil)
  if valid_605167 != nil:
    section.add "Iops", valid_605167
  var valid_605168 = query.getOrDefault("OptionGroupName")
  valid_605168 = validateParameter(valid_605168, JString, required = false,
                                 default = nil)
  if valid_605168 != nil:
    section.add "OptionGroupName", valid_605168
  var valid_605169 = query.getOrDefault("RestoreTime")
  valid_605169 = validateParameter(valid_605169, JString, required = false,
                                 default = nil)
  if valid_605169 != nil:
    section.add "RestoreTime", valid_605169
  var valid_605170 = query.getOrDefault("MultiAZ")
  valid_605170 = validateParameter(valid_605170, JBool, required = false, default = nil)
  if valid_605170 != nil:
    section.add "MultiAZ", valid_605170
  var valid_605171 = query.getOrDefault("TdeCredentialPassword")
  valid_605171 = validateParameter(valid_605171, JString, required = false,
                                 default = nil)
  if valid_605171 != nil:
    section.add "TdeCredentialPassword", valid_605171
  var valid_605172 = query.getOrDefault("LicenseModel")
  valid_605172 = validateParameter(valid_605172, JString, required = false,
                                 default = nil)
  if valid_605172 != nil:
    section.add "LicenseModel", valid_605172
  var valid_605173 = query.getOrDefault("Tags")
  valid_605173 = validateParameter(valid_605173, JArray, required = false,
                                 default = nil)
  if valid_605173 != nil:
    section.add "Tags", valid_605173
  var valid_605174 = query.getOrDefault("DBName")
  valid_605174 = validateParameter(valid_605174, JString, required = false,
                                 default = nil)
  if valid_605174 != nil:
    section.add "DBName", valid_605174
  var valid_605175 = query.getOrDefault("DBInstanceClass")
  valid_605175 = validateParameter(valid_605175, JString, required = false,
                                 default = nil)
  if valid_605175 != nil:
    section.add "DBInstanceClass", valid_605175
  var valid_605176 = query.getOrDefault("Action")
  valid_605176 = validateParameter(valid_605176, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605176 != nil:
    section.add "Action", valid_605176
  var valid_605177 = query.getOrDefault("UseLatestRestorableTime")
  valid_605177 = validateParameter(valid_605177, JBool, required = false, default = nil)
  if valid_605177 != nil:
    section.add "UseLatestRestorableTime", valid_605177
  var valid_605178 = query.getOrDefault("DBSubnetGroupName")
  valid_605178 = validateParameter(valid_605178, JString, required = false,
                                 default = nil)
  if valid_605178 != nil:
    section.add "DBSubnetGroupName", valid_605178
  var valid_605179 = query.getOrDefault("TdeCredentialArn")
  valid_605179 = validateParameter(valid_605179, JString, required = false,
                                 default = nil)
  if valid_605179 != nil:
    section.add "TdeCredentialArn", valid_605179
  var valid_605180 = query.getOrDefault("PubliclyAccessible")
  valid_605180 = validateParameter(valid_605180, JBool, required = false, default = nil)
  if valid_605180 != nil:
    section.add "PubliclyAccessible", valid_605180
  var valid_605181 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605181 = validateParameter(valid_605181, JBool, required = false, default = nil)
  if valid_605181 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605181
  var valid_605182 = query.getOrDefault("Port")
  valid_605182 = validateParameter(valid_605182, JInt, required = false, default = nil)
  if valid_605182 != nil:
    section.add "Port", valid_605182
  var valid_605183 = query.getOrDefault("Version")
  valid_605183 = validateParameter(valid_605183, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605183 != nil:
    section.add "Version", valid_605183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605184 = header.getOrDefault("X-Amz-Date")
  valid_605184 = validateParameter(valid_605184, JString, required = false,
                                 default = nil)
  if valid_605184 != nil:
    section.add "X-Amz-Date", valid_605184
  var valid_605185 = header.getOrDefault("X-Amz-Security-Token")
  valid_605185 = validateParameter(valid_605185, JString, required = false,
                                 default = nil)
  if valid_605185 != nil:
    section.add "X-Amz-Security-Token", valid_605185
  var valid_605186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605186 = validateParameter(valid_605186, JString, required = false,
                                 default = nil)
  if valid_605186 != nil:
    section.add "X-Amz-Content-Sha256", valid_605186
  var valid_605187 = header.getOrDefault("X-Amz-Algorithm")
  valid_605187 = validateParameter(valid_605187, JString, required = false,
                                 default = nil)
  if valid_605187 != nil:
    section.add "X-Amz-Algorithm", valid_605187
  var valid_605188 = header.getOrDefault("X-Amz-Signature")
  valid_605188 = validateParameter(valid_605188, JString, required = false,
                                 default = nil)
  if valid_605188 != nil:
    section.add "X-Amz-Signature", valid_605188
  var valid_605189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605189 = validateParameter(valid_605189, JString, required = false,
                                 default = nil)
  if valid_605189 != nil:
    section.add "X-Amz-SignedHeaders", valid_605189
  var valid_605190 = header.getOrDefault("X-Amz-Credential")
  valid_605190 = validateParameter(valid_605190, JString, required = false,
                                 default = nil)
  if valid_605190 != nil:
    section.add "X-Amz-Credential", valid_605190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605191: Call_GetRestoreDBInstanceToPointInTime_605159;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605191.validator(path, query, header, formData, body)
  let scheme = call_605191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605191.url(scheme.get, call_605191.host, call_605191.base,
                         call_605191.route, valid.getOrDefault("path"))
  result = hook(call_605191, url, valid)

proc call*(call_605192: Call_GetRestoreDBInstanceToPointInTime_605159;
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
  var query_605193 = newJObject()
  add(query_605193, "Engine", newJString(Engine))
  add(query_605193, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_605193, "StorageType", newJString(StorageType))
  add(query_605193, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_605193, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605193, "Iops", newJInt(Iops))
  add(query_605193, "OptionGroupName", newJString(OptionGroupName))
  add(query_605193, "RestoreTime", newJString(RestoreTime))
  add(query_605193, "MultiAZ", newJBool(MultiAZ))
  add(query_605193, "TdeCredentialPassword", newJString(TdeCredentialPassword))
  add(query_605193, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605193.add "Tags", Tags
  add(query_605193, "DBName", newJString(DBName))
  add(query_605193, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605193, "Action", newJString(Action))
  add(query_605193, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_605193, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605193, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_605193, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605193, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605193, "Port", newJInt(Port))
  add(query_605193, "Version", newJString(Version))
  result = call_605192.call(nil, query_605193, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_605159(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_605160, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_605161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_605250 = ref object of OpenApiRestCall_602417
proc url_PostRevokeDBSecurityGroupIngress_605252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_605251(path: JsonNode;
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
  var valid_605253 = query.getOrDefault("Action")
  valid_605253 = validateParameter(valid_605253, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605253 != nil:
    section.add "Action", valid_605253
  var valid_605254 = query.getOrDefault("Version")
  valid_605254 = validateParameter(valid_605254, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605254 != nil:
    section.add "Version", valid_605254
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605255 = header.getOrDefault("X-Amz-Date")
  valid_605255 = validateParameter(valid_605255, JString, required = false,
                                 default = nil)
  if valid_605255 != nil:
    section.add "X-Amz-Date", valid_605255
  var valid_605256 = header.getOrDefault("X-Amz-Security-Token")
  valid_605256 = validateParameter(valid_605256, JString, required = false,
                                 default = nil)
  if valid_605256 != nil:
    section.add "X-Amz-Security-Token", valid_605256
  var valid_605257 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605257 = validateParameter(valid_605257, JString, required = false,
                                 default = nil)
  if valid_605257 != nil:
    section.add "X-Amz-Content-Sha256", valid_605257
  var valid_605258 = header.getOrDefault("X-Amz-Algorithm")
  valid_605258 = validateParameter(valid_605258, JString, required = false,
                                 default = nil)
  if valid_605258 != nil:
    section.add "X-Amz-Algorithm", valid_605258
  var valid_605259 = header.getOrDefault("X-Amz-Signature")
  valid_605259 = validateParameter(valid_605259, JString, required = false,
                                 default = nil)
  if valid_605259 != nil:
    section.add "X-Amz-Signature", valid_605259
  var valid_605260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605260 = validateParameter(valid_605260, JString, required = false,
                                 default = nil)
  if valid_605260 != nil:
    section.add "X-Amz-SignedHeaders", valid_605260
  var valid_605261 = header.getOrDefault("X-Amz-Credential")
  valid_605261 = validateParameter(valid_605261, JString, required = false,
                                 default = nil)
  if valid_605261 != nil:
    section.add "X-Amz-Credential", valid_605261
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605262 = formData.getOrDefault("DBSecurityGroupName")
  valid_605262 = validateParameter(valid_605262, JString, required = true,
                                 default = nil)
  if valid_605262 != nil:
    section.add "DBSecurityGroupName", valid_605262
  var valid_605263 = formData.getOrDefault("EC2SecurityGroupName")
  valid_605263 = validateParameter(valid_605263, JString, required = false,
                                 default = nil)
  if valid_605263 != nil:
    section.add "EC2SecurityGroupName", valid_605263
  var valid_605264 = formData.getOrDefault("EC2SecurityGroupId")
  valid_605264 = validateParameter(valid_605264, JString, required = false,
                                 default = nil)
  if valid_605264 != nil:
    section.add "EC2SecurityGroupId", valid_605264
  var valid_605265 = formData.getOrDefault("CIDRIP")
  valid_605265 = validateParameter(valid_605265, JString, required = false,
                                 default = nil)
  if valid_605265 != nil:
    section.add "CIDRIP", valid_605265
  var valid_605266 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605266 = validateParameter(valid_605266, JString, required = false,
                                 default = nil)
  if valid_605266 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605266
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605267: Call_PostRevokeDBSecurityGroupIngress_605250;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605267.validator(path, query, header, formData, body)
  let scheme = call_605267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605267.url(scheme.get, call_605267.host, call_605267.base,
                         call_605267.route, valid.getOrDefault("path"))
  result = hook(call_605267, url, valid)

proc call*(call_605268: Call_PostRevokeDBSecurityGroupIngress_605250;
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
  var query_605269 = newJObject()
  var formData_605270 = newJObject()
  add(formData_605270, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605269, "Action", newJString(Action))
  add(formData_605270, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_605270, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_605270, "CIDRIP", newJString(CIDRIP))
  add(query_605269, "Version", newJString(Version))
  add(formData_605270, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_605268.call(nil, query_605269, nil, formData_605270, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_605250(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_605251, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_605252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_605230 = ref object of OpenApiRestCall_602417
proc url_GetRevokeDBSecurityGroupIngress_605232(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_605231(path: JsonNode;
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
  var valid_605233 = query.getOrDefault("EC2SecurityGroupId")
  valid_605233 = validateParameter(valid_605233, JString, required = false,
                                 default = nil)
  if valid_605233 != nil:
    section.add "EC2SecurityGroupId", valid_605233
  var valid_605234 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605234 = validateParameter(valid_605234, JString, required = false,
                                 default = nil)
  if valid_605234 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605234
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605235 = query.getOrDefault("DBSecurityGroupName")
  valid_605235 = validateParameter(valid_605235, JString, required = true,
                                 default = nil)
  if valid_605235 != nil:
    section.add "DBSecurityGroupName", valid_605235
  var valid_605236 = query.getOrDefault("Action")
  valid_605236 = validateParameter(valid_605236, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605236 != nil:
    section.add "Action", valid_605236
  var valid_605237 = query.getOrDefault("CIDRIP")
  valid_605237 = validateParameter(valid_605237, JString, required = false,
                                 default = nil)
  if valid_605237 != nil:
    section.add "CIDRIP", valid_605237
  var valid_605238 = query.getOrDefault("EC2SecurityGroupName")
  valid_605238 = validateParameter(valid_605238, JString, required = false,
                                 default = nil)
  if valid_605238 != nil:
    section.add "EC2SecurityGroupName", valid_605238
  var valid_605239 = query.getOrDefault("Version")
  valid_605239 = validateParameter(valid_605239, JString, required = true,
                                 default = newJString("2014-09-01"))
  if valid_605239 != nil:
    section.add "Version", valid_605239
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605240 = header.getOrDefault("X-Amz-Date")
  valid_605240 = validateParameter(valid_605240, JString, required = false,
                                 default = nil)
  if valid_605240 != nil:
    section.add "X-Amz-Date", valid_605240
  var valid_605241 = header.getOrDefault("X-Amz-Security-Token")
  valid_605241 = validateParameter(valid_605241, JString, required = false,
                                 default = nil)
  if valid_605241 != nil:
    section.add "X-Amz-Security-Token", valid_605241
  var valid_605242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605242 = validateParameter(valid_605242, JString, required = false,
                                 default = nil)
  if valid_605242 != nil:
    section.add "X-Amz-Content-Sha256", valid_605242
  var valid_605243 = header.getOrDefault("X-Amz-Algorithm")
  valid_605243 = validateParameter(valid_605243, JString, required = false,
                                 default = nil)
  if valid_605243 != nil:
    section.add "X-Amz-Algorithm", valid_605243
  var valid_605244 = header.getOrDefault("X-Amz-Signature")
  valid_605244 = validateParameter(valid_605244, JString, required = false,
                                 default = nil)
  if valid_605244 != nil:
    section.add "X-Amz-Signature", valid_605244
  var valid_605245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605245 = validateParameter(valid_605245, JString, required = false,
                                 default = nil)
  if valid_605245 != nil:
    section.add "X-Amz-SignedHeaders", valid_605245
  var valid_605246 = header.getOrDefault("X-Amz-Credential")
  valid_605246 = validateParameter(valid_605246, JString, required = false,
                                 default = nil)
  if valid_605246 != nil:
    section.add "X-Amz-Credential", valid_605246
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605247: Call_GetRevokeDBSecurityGroupIngress_605230;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605247.validator(path, query, header, formData, body)
  let scheme = call_605247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605247.url(scheme.get, call_605247.host, call_605247.base,
                         call_605247.route, valid.getOrDefault("path"))
  result = hook(call_605247, url, valid)

proc call*(call_605248: Call_GetRevokeDBSecurityGroupIngress_605230;
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
  var query_605249 = newJObject()
  add(query_605249, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_605249, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_605249, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605249, "Action", newJString(Action))
  add(query_605249, "CIDRIP", newJString(CIDRIP))
  add(query_605249, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_605249, "Version", newJString(Version))
  result = call_605248.call(nil, query_605249, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_605230(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_605231, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_605232,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

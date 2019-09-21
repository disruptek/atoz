
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
          Version: string = "2013-09-09"): Recallable =
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
                                 default = newJString("2013-09-09"))
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
                                 default = newJString("2013-09-09"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
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
  Call_PostCopyDBSnapshot_603138 = ref object of OpenApiRestCall_602417
proc url_PostCopyDBSnapshot_603140(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_603139(path: JsonNode; query: JsonNode;
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
  var valid_603141 = query.getOrDefault("Action")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603141 != nil:
    section.add "Action", valid_603141
  var valid_603142 = query.getOrDefault("Version")
  valid_603142 = validateParameter(valid_603142, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603142 != nil:
    section.add "Version", valid_603142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603143 = header.getOrDefault("X-Amz-Date")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Date", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Security-Token")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Security-Token", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Content-Sha256", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Algorithm")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Algorithm", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Signature")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Signature", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-SignedHeaders", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Credential")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Credential", valid_603149
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603150 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = nil)
  if valid_603150 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603150
  var valid_603151 = formData.getOrDefault("Tags")
  valid_603151 = validateParameter(valid_603151, JArray, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "Tags", valid_603151
  var valid_603152 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603152 = validateParameter(valid_603152, JString, required = true,
                                 default = nil)
  if valid_603152 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603153: Call_PostCopyDBSnapshot_603138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603153.validator(path, query, header, formData, body)
  let scheme = call_603153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603153.url(scheme.get, call_603153.host, call_603153.base,
                         call_603153.route, valid.getOrDefault("path"))
  result = hook(call_603153, url, valid)

proc call*(call_603154: Call_PostCopyDBSnapshot_603138;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603155 = newJObject()
  var formData_603156 = newJObject()
  add(formData_603156, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_603156.add "Tags", Tags
  add(query_603155, "Action", newJString(Action))
  add(formData_603156, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603155, "Version", newJString(Version))
  result = call_603154.call(nil, query_603155, nil, formData_603156, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_603138(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_603139, base: "/",
    url: url_PostCopyDBSnapshot_603140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_603120 = ref object of OpenApiRestCall_602417
proc url_GetCopyDBSnapshot_603122(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCopyDBSnapshot_603121(path: JsonNode; query: JsonNode;
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
  var valid_603123 = query.getOrDefault("Tags")
  valid_603123 = validateParameter(valid_603123, JArray, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "Tags", valid_603123
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603124 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = nil)
  if valid_603124 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603124
  var valid_603125 = query.getOrDefault("Action")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603125 != nil:
    section.add "Action", valid_603125
  var valid_603126 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = nil)
  if valid_603126 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603126
  var valid_603127 = query.getOrDefault("Version")
  valid_603127 = validateParameter(valid_603127, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603135: Call_GetCopyDBSnapshot_603120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603135.validator(path, query, header, formData, body)
  let scheme = call_603135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603135.url(scheme.get, call_603135.host, call_603135.base,
                         call_603135.route, valid.getOrDefault("path"))
  result = hook(call_603135, url, valid)

proc call*(call_603136: Call_GetCopyDBSnapshot_603120;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603137 = newJObject()
  if Tags != nil:
    query_603137.add "Tags", Tags
  add(query_603137, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603137, "Action", newJString(Action))
  add(query_603137, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603137, "Version", newJString(Version))
  result = call_603136.call(nil, query_603137, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_603120(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_603121,
    base: "/", url: url_GetCopyDBSnapshot_603122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603197 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBInstance_603199(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_603198(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603200 = query.getOrDefault("Action")
  valid_603200 = validateParameter(valid_603200, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603200 != nil:
    section.add "Action", valid_603200
  var valid_603201 = query.getOrDefault("Version")
  valid_603201 = validateParameter(valid_603201, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603201 != nil:
    section.add "Version", valid_603201
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603202 = header.getOrDefault("X-Amz-Date")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Date", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Security-Token")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Security-Token", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-Content-Sha256", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Algorithm")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Algorithm", valid_603205
  var valid_603206 = header.getOrDefault("X-Amz-Signature")
  valid_603206 = validateParameter(valid_603206, JString, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "X-Amz-Signature", valid_603206
  var valid_603207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "X-Amz-SignedHeaders", valid_603207
  var valid_603208 = header.getOrDefault("X-Amz-Credential")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "X-Amz-Credential", valid_603208
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
  var valid_603209 = formData.getOrDefault("DBSecurityGroups")
  valid_603209 = validateParameter(valid_603209, JArray, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "DBSecurityGroups", valid_603209
  var valid_603210 = formData.getOrDefault("Port")
  valid_603210 = validateParameter(valid_603210, JInt, required = false, default = nil)
  if valid_603210 != nil:
    section.add "Port", valid_603210
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603211 = formData.getOrDefault("Engine")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = nil)
  if valid_603211 != nil:
    section.add "Engine", valid_603211
  var valid_603212 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603212 = validateParameter(valid_603212, JArray, required = false,
                                 default = nil)
  if valid_603212 != nil:
    section.add "VpcSecurityGroupIds", valid_603212
  var valid_603213 = formData.getOrDefault("Iops")
  valid_603213 = validateParameter(valid_603213, JInt, required = false, default = nil)
  if valid_603213 != nil:
    section.add "Iops", valid_603213
  var valid_603214 = formData.getOrDefault("DBName")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "DBName", valid_603214
  var valid_603215 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = nil)
  if valid_603215 != nil:
    section.add "DBInstanceIdentifier", valid_603215
  var valid_603216 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603216 = validateParameter(valid_603216, JInt, required = false, default = nil)
  if valid_603216 != nil:
    section.add "BackupRetentionPeriod", valid_603216
  var valid_603217 = formData.getOrDefault("DBParameterGroupName")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "DBParameterGroupName", valid_603217
  var valid_603218 = formData.getOrDefault("OptionGroupName")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "OptionGroupName", valid_603218
  var valid_603219 = formData.getOrDefault("Tags")
  valid_603219 = validateParameter(valid_603219, JArray, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "Tags", valid_603219
  var valid_603220 = formData.getOrDefault("MasterUserPassword")
  valid_603220 = validateParameter(valid_603220, JString, required = true,
                                 default = nil)
  if valid_603220 != nil:
    section.add "MasterUserPassword", valid_603220
  var valid_603221 = formData.getOrDefault("DBSubnetGroupName")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "DBSubnetGroupName", valid_603221
  var valid_603222 = formData.getOrDefault("AvailabilityZone")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "AvailabilityZone", valid_603222
  var valid_603223 = formData.getOrDefault("MultiAZ")
  valid_603223 = validateParameter(valid_603223, JBool, required = false, default = nil)
  if valid_603223 != nil:
    section.add "MultiAZ", valid_603223
  var valid_603224 = formData.getOrDefault("AllocatedStorage")
  valid_603224 = validateParameter(valid_603224, JInt, required = true, default = nil)
  if valid_603224 != nil:
    section.add "AllocatedStorage", valid_603224
  var valid_603225 = formData.getOrDefault("PubliclyAccessible")
  valid_603225 = validateParameter(valid_603225, JBool, required = false, default = nil)
  if valid_603225 != nil:
    section.add "PubliclyAccessible", valid_603225
  var valid_603226 = formData.getOrDefault("MasterUsername")
  valid_603226 = validateParameter(valid_603226, JString, required = true,
                                 default = nil)
  if valid_603226 != nil:
    section.add "MasterUsername", valid_603226
  var valid_603227 = formData.getOrDefault("DBInstanceClass")
  valid_603227 = validateParameter(valid_603227, JString, required = true,
                                 default = nil)
  if valid_603227 != nil:
    section.add "DBInstanceClass", valid_603227
  var valid_603228 = formData.getOrDefault("CharacterSetName")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "CharacterSetName", valid_603228
  var valid_603229 = formData.getOrDefault("PreferredBackupWindow")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "PreferredBackupWindow", valid_603229
  var valid_603230 = formData.getOrDefault("LicenseModel")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "LicenseModel", valid_603230
  var valid_603231 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603231 = validateParameter(valid_603231, JBool, required = false, default = nil)
  if valid_603231 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603231
  var valid_603232 = formData.getOrDefault("EngineVersion")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "EngineVersion", valid_603232
  var valid_603233 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "PreferredMaintenanceWindow", valid_603233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603234: Call_PostCreateDBInstance_603197; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603234.validator(path, query, header, formData, body)
  let scheme = call_603234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603234.url(scheme.get, call_603234.host, call_603234.base,
                         call_603234.route, valid.getOrDefault("path"))
  result = hook(call_603234, url, valid)

proc call*(call_603235: Call_PostCreateDBInstance_603197; Engine: string;
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
  var query_603236 = newJObject()
  var formData_603237 = newJObject()
  if DBSecurityGroups != nil:
    formData_603237.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603237, "Port", newJInt(Port))
  add(formData_603237, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_603237.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603237, "Iops", newJInt(Iops))
  add(formData_603237, "DBName", newJString(DBName))
  add(formData_603237, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603237, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603237, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603237, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603237.add "Tags", Tags
  add(formData_603237, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603237, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603237, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603237, "MultiAZ", newJBool(MultiAZ))
  add(query_603236, "Action", newJString(Action))
  add(formData_603237, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_603237, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603237, "MasterUsername", newJString(MasterUsername))
  add(formData_603237, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603237, "CharacterSetName", newJString(CharacterSetName))
  add(formData_603237, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603237, "LicenseModel", newJString(LicenseModel))
  add(formData_603237, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603237, "EngineVersion", newJString(EngineVersion))
  add(query_603236, "Version", newJString(Version))
  add(formData_603237, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603235.call(nil, query_603236, nil, formData_603237, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603197(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603198, base: "/",
    url: url_PostCreateDBInstance_603199, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603157 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBInstance_603159(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_603158(path: JsonNode; query: JsonNode;
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
  var valid_603160 = query.getOrDefault("Engine")
  valid_603160 = validateParameter(valid_603160, JString, required = true,
                                 default = nil)
  if valid_603160 != nil:
    section.add "Engine", valid_603160
  var valid_603161 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "PreferredMaintenanceWindow", valid_603161
  var valid_603162 = query.getOrDefault("AllocatedStorage")
  valid_603162 = validateParameter(valid_603162, JInt, required = true, default = nil)
  if valid_603162 != nil:
    section.add "AllocatedStorage", valid_603162
  var valid_603163 = query.getOrDefault("OptionGroupName")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "OptionGroupName", valid_603163
  var valid_603164 = query.getOrDefault("DBSecurityGroups")
  valid_603164 = validateParameter(valid_603164, JArray, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "DBSecurityGroups", valid_603164
  var valid_603165 = query.getOrDefault("MasterUserPassword")
  valid_603165 = validateParameter(valid_603165, JString, required = true,
                                 default = nil)
  if valid_603165 != nil:
    section.add "MasterUserPassword", valid_603165
  var valid_603166 = query.getOrDefault("AvailabilityZone")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "AvailabilityZone", valid_603166
  var valid_603167 = query.getOrDefault("Iops")
  valid_603167 = validateParameter(valid_603167, JInt, required = false, default = nil)
  if valid_603167 != nil:
    section.add "Iops", valid_603167
  var valid_603168 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603168 = validateParameter(valid_603168, JArray, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "VpcSecurityGroupIds", valid_603168
  var valid_603169 = query.getOrDefault("MultiAZ")
  valid_603169 = validateParameter(valid_603169, JBool, required = false, default = nil)
  if valid_603169 != nil:
    section.add "MultiAZ", valid_603169
  var valid_603170 = query.getOrDefault("LicenseModel")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "LicenseModel", valid_603170
  var valid_603171 = query.getOrDefault("BackupRetentionPeriod")
  valid_603171 = validateParameter(valid_603171, JInt, required = false, default = nil)
  if valid_603171 != nil:
    section.add "BackupRetentionPeriod", valid_603171
  var valid_603172 = query.getOrDefault("DBName")
  valid_603172 = validateParameter(valid_603172, JString, required = false,
                                 default = nil)
  if valid_603172 != nil:
    section.add "DBName", valid_603172
  var valid_603173 = query.getOrDefault("DBParameterGroupName")
  valid_603173 = validateParameter(valid_603173, JString, required = false,
                                 default = nil)
  if valid_603173 != nil:
    section.add "DBParameterGroupName", valid_603173
  var valid_603174 = query.getOrDefault("Tags")
  valid_603174 = validateParameter(valid_603174, JArray, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "Tags", valid_603174
  var valid_603175 = query.getOrDefault("DBInstanceClass")
  valid_603175 = validateParameter(valid_603175, JString, required = true,
                                 default = nil)
  if valid_603175 != nil:
    section.add "DBInstanceClass", valid_603175
  var valid_603176 = query.getOrDefault("Action")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603176 != nil:
    section.add "Action", valid_603176
  var valid_603177 = query.getOrDefault("DBSubnetGroupName")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "DBSubnetGroupName", valid_603177
  var valid_603178 = query.getOrDefault("CharacterSetName")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "CharacterSetName", valid_603178
  var valid_603179 = query.getOrDefault("PubliclyAccessible")
  valid_603179 = validateParameter(valid_603179, JBool, required = false, default = nil)
  if valid_603179 != nil:
    section.add "PubliclyAccessible", valid_603179
  var valid_603180 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603180 = validateParameter(valid_603180, JBool, required = false, default = nil)
  if valid_603180 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603180
  var valid_603181 = query.getOrDefault("EngineVersion")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "EngineVersion", valid_603181
  var valid_603182 = query.getOrDefault("Port")
  valid_603182 = validateParameter(valid_603182, JInt, required = false, default = nil)
  if valid_603182 != nil:
    section.add "Port", valid_603182
  var valid_603183 = query.getOrDefault("PreferredBackupWindow")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "PreferredBackupWindow", valid_603183
  var valid_603184 = query.getOrDefault("Version")
  valid_603184 = validateParameter(valid_603184, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603184 != nil:
    section.add "Version", valid_603184
  var valid_603185 = query.getOrDefault("DBInstanceIdentifier")
  valid_603185 = validateParameter(valid_603185, JString, required = true,
                                 default = nil)
  if valid_603185 != nil:
    section.add "DBInstanceIdentifier", valid_603185
  var valid_603186 = query.getOrDefault("MasterUsername")
  valid_603186 = validateParameter(valid_603186, JString, required = true,
                                 default = nil)
  if valid_603186 != nil:
    section.add "MasterUsername", valid_603186
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603187 = header.getOrDefault("X-Amz-Date")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Date", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Security-Token")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Security-Token", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-Content-Sha256", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Algorithm")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Algorithm", valid_603190
  var valid_603191 = header.getOrDefault("X-Amz-Signature")
  valid_603191 = validateParameter(valid_603191, JString, required = false,
                                 default = nil)
  if valid_603191 != nil:
    section.add "X-Amz-Signature", valid_603191
  var valid_603192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "X-Amz-SignedHeaders", valid_603192
  var valid_603193 = header.getOrDefault("X-Amz-Credential")
  valid_603193 = validateParameter(valid_603193, JString, required = false,
                                 default = nil)
  if valid_603193 != nil:
    section.add "X-Amz-Credential", valid_603193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603194: Call_GetCreateDBInstance_603157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603194.validator(path, query, header, formData, body)
  let scheme = call_603194.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603194.url(scheme.get, call_603194.host, call_603194.base,
                         call_603194.route, valid.getOrDefault("path"))
  result = hook(call_603194, url, valid)

proc call*(call_603195: Call_GetCreateDBInstance_603157; Engine: string;
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
  var query_603196 = newJObject()
  add(query_603196, "Engine", newJString(Engine))
  add(query_603196, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603196, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603196, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_603196.add "DBSecurityGroups", DBSecurityGroups
  add(query_603196, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603196, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603196, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_603196.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603196, "MultiAZ", newJBool(MultiAZ))
  add(query_603196, "LicenseModel", newJString(LicenseModel))
  add(query_603196, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603196, "DBName", newJString(DBName))
  add(query_603196, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_603196.add "Tags", Tags
  add(query_603196, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603196, "Action", newJString(Action))
  add(query_603196, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603196, "CharacterSetName", newJString(CharacterSetName))
  add(query_603196, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603196, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603196, "EngineVersion", newJString(EngineVersion))
  add(query_603196, "Port", newJInt(Port))
  add(query_603196, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603196, "Version", newJString(Version))
  add(query_603196, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603196, "MasterUsername", newJString(MasterUsername))
  result = call_603195.call(nil, query_603196, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603157(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603158, base: "/",
    url: url_GetCreateDBInstance_603159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_603264 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBInstanceReadReplica_603266(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_603265(path: JsonNode;
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
  var valid_603267 = query.getOrDefault("Action")
  valid_603267 = validateParameter(valid_603267, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603267 != nil:
    section.add "Action", valid_603267
  var valid_603268 = query.getOrDefault("Version")
  valid_603268 = validateParameter(valid_603268, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603268 != nil:
    section.add "Version", valid_603268
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603269 = header.getOrDefault("X-Amz-Date")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Date", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Security-Token")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Security-Token", valid_603270
  var valid_603271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "X-Amz-Content-Sha256", valid_603271
  var valid_603272 = header.getOrDefault("X-Amz-Algorithm")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "X-Amz-Algorithm", valid_603272
  var valid_603273 = header.getOrDefault("X-Amz-Signature")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "X-Amz-Signature", valid_603273
  var valid_603274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "X-Amz-SignedHeaders", valid_603274
  var valid_603275 = header.getOrDefault("X-Amz-Credential")
  valid_603275 = validateParameter(valid_603275, JString, required = false,
                                 default = nil)
  if valid_603275 != nil:
    section.add "X-Amz-Credential", valid_603275
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
  var valid_603276 = formData.getOrDefault("Port")
  valid_603276 = validateParameter(valid_603276, JInt, required = false, default = nil)
  if valid_603276 != nil:
    section.add "Port", valid_603276
  var valid_603277 = formData.getOrDefault("Iops")
  valid_603277 = validateParameter(valid_603277, JInt, required = false, default = nil)
  if valid_603277 != nil:
    section.add "Iops", valid_603277
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603278 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603278 = validateParameter(valid_603278, JString, required = true,
                                 default = nil)
  if valid_603278 != nil:
    section.add "DBInstanceIdentifier", valid_603278
  var valid_603279 = formData.getOrDefault("OptionGroupName")
  valid_603279 = validateParameter(valid_603279, JString, required = false,
                                 default = nil)
  if valid_603279 != nil:
    section.add "OptionGroupName", valid_603279
  var valid_603280 = formData.getOrDefault("Tags")
  valid_603280 = validateParameter(valid_603280, JArray, required = false,
                                 default = nil)
  if valid_603280 != nil:
    section.add "Tags", valid_603280
  var valid_603281 = formData.getOrDefault("DBSubnetGroupName")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "DBSubnetGroupName", valid_603281
  var valid_603282 = formData.getOrDefault("AvailabilityZone")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "AvailabilityZone", valid_603282
  var valid_603283 = formData.getOrDefault("PubliclyAccessible")
  valid_603283 = validateParameter(valid_603283, JBool, required = false, default = nil)
  if valid_603283 != nil:
    section.add "PubliclyAccessible", valid_603283
  var valid_603284 = formData.getOrDefault("DBInstanceClass")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "DBInstanceClass", valid_603284
  var valid_603285 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603285 = validateParameter(valid_603285, JString, required = true,
                                 default = nil)
  if valid_603285 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603285
  var valid_603286 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603286 = validateParameter(valid_603286, JBool, required = false, default = nil)
  if valid_603286 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603286
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603287: Call_PostCreateDBInstanceReadReplica_603264;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603287.validator(path, query, header, formData, body)
  let scheme = call_603287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603287.url(scheme.get, call_603287.host, call_603287.base,
                         call_603287.route, valid.getOrDefault("path"))
  result = hook(call_603287, url, valid)

proc call*(call_603288: Call_PostCreateDBInstanceReadReplica_603264;
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
  var query_603289 = newJObject()
  var formData_603290 = newJObject()
  add(formData_603290, "Port", newJInt(Port))
  add(formData_603290, "Iops", newJInt(Iops))
  add(formData_603290, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603290, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603290.add "Tags", Tags
  add(formData_603290, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603290, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603289, "Action", newJString(Action))
  add(formData_603290, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603290, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603290, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603290, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603289, "Version", newJString(Version))
  result = call_603288.call(nil, query_603289, nil, formData_603290, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_603264(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_603265, base: "/",
    url: url_PostCreateDBInstanceReadReplica_603266,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_603238 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBInstanceReadReplica_603240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_603239(path: JsonNode;
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
  var valid_603241 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = nil)
  if valid_603241 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603241
  var valid_603242 = query.getOrDefault("OptionGroupName")
  valid_603242 = validateParameter(valid_603242, JString, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "OptionGroupName", valid_603242
  var valid_603243 = query.getOrDefault("AvailabilityZone")
  valid_603243 = validateParameter(valid_603243, JString, required = false,
                                 default = nil)
  if valid_603243 != nil:
    section.add "AvailabilityZone", valid_603243
  var valid_603244 = query.getOrDefault("Iops")
  valid_603244 = validateParameter(valid_603244, JInt, required = false, default = nil)
  if valid_603244 != nil:
    section.add "Iops", valid_603244
  var valid_603245 = query.getOrDefault("Tags")
  valid_603245 = validateParameter(valid_603245, JArray, required = false,
                                 default = nil)
  if valid_603245 != nil:
    section.add "Tags", valid_603245
  var valid_603246 = query.getOrDefault("DBInstanceClass")
  valid_603246 = validateParameter(valid_603246, JString, required = false,
                                 default = nil)
  if valid_603246 != nil:
    section.add "DBInstanceClass", valid_603246
  var valid_603247 = query.getOrDefault("Action")
  valid_603247 = validateParameter(valid_603247, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603247 != nil:
    section.add "Action", valid_603247
  var valid_603248 = query.getOrDefault("DBSubnetGroupName")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "DBSubnetGroupName", valid_603248
  var valid_603249 = query.getOrDefault("PubliclyAccessible")
  valid_603249 = validateParameter(valid_603249, JBool, required = false, default = nil)
  if valid_603249 != nil:
    section.add "PubliclyAccessible", valid_603249
  var valid_603250 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603250 = validateParameter(valid_603250, JBool, required = false, default = nil)
  if valid_603250 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603250
  var valid_603251 = query.getOrDefault("Port")
  valid_603251 = validateParameter(valid_603251, JInt, required = false, default = nil)
  if valid_603251 != nil:
    section.add "Port", valid_603251
  var valid_603252 = query.getOrDefault("Version")
  valid_603252 = validateParameter(valid_603252, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603252 != nil:
    section.add "Version", valid_603252
  var valid_603253 = query.getOrDefault("DBInstanceIdentifier")
  valid_603253 = validateParameter(valid_603253, JString, required = true,
                                 default = nil)
  if valid_603253 != nil:
    section.add "DBInstanceIdentifier", valid_603253
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603254 = header.getOrDefault("X-Amz-Date")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Date", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Security-Token")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Security-Token", valid_603255
  var valid_603256 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603256 = validateParameter(valid_603256, JString, required = false,
                                 default = nil)
  if valid_603256 != nil:
    section.add "X-Amz-Content-Sha256", valid_603256
  var valid_603257 = header.getOrDefault("X-Amz-Algorithm")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "X-Amz-Algorithm", valid_603257
  var valid_603258 = header.getOrDefault("X-Amz-Signature")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "X-Amz-Signature", valid_603258
  var valid_603259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "X-Amz-SignedHeaders", valid_603259
  var valid_603260 = header.getOrDefault("X-Amz-Credential")
  valid_603260 = validateParameter(valid_603260, JString, required = false,
                                 default = nil)
  if valid_603260 != nil:
    section.add "X-Amz-Credential", valid_603260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603261: Call_GetCreateDBInstanceReadReplica_603238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603261.validator(path, query, header, formData, body)
  let scheme = call_603261.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603261.url(scheme.get, call_603261.host, call_603261.base,
                         call_603261.route, valid.getOrDefault("path"))
  result = hook(call_603261, url, valid)

proc call*(call_603262: Call_GetCreateDBInstanceReadReplica_603238;
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
  var query_603263 = newJObject()
  add(query_603263, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603263, "OptionGroupName", newJString(OptionGroupName))
  add(query_603263, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603263, "Iops", newJInt(Iops))
  if Tags != nil:
    query_603263.add "Tags", Tags
  add(query_603263, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603263, "Action", newJString(Action))
  add(query_603263, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603263, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603263, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603263, "Port", newJInt(Port))
  add(query_603263, "Version", newJString(Version))
  add(query_603263, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603262.call(nil, query_603263, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_603238(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_603239, base: "/",
    url: url_GetCreateDBInstanceReadReplica_603240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_603310 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBParameterGroup_603312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_603311(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603313 = query.getOrDefault("Action")
  valid_603313 = validateParameter(valid_603313, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603313 != nil:
    section.add "Action", valid_603313
  var valid_603314 = query.getOrDefault("Version")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603314 != nil:
    section.add "Version", valid_603314
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Content-Sha256", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Algorithm")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Algorithm", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Signature")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Signature", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-SignedHeaders", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Credential")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Credential", valid_603321
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603322 = formData.getOrDefault("DBParameterGroupName")
  valid_603322 = validateParameter(valid_603322, JString, required = true,
                                 default = nil)
  if valid_603322 != nil:
    section.add "DBParameterGroupName", valid_603322
  var valid_603323 = formData.getOrDefault("Tags")
  valid_603323 = validateParameter(valid_603323, JArray, required = false,
                                 default = nil)
  if valid_603323 != nil:
    section.add "Tags", valid_603323
  var valid_603324 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = nil)
  if valid_603324 != nil:
    section.add "DBParameterGroupFamily", valid_603324
  var valid_603325 = formData.getOrDefault("Description")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = nil)
  if valid_603325 != nil:
    section.add "Description", valid_603325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603326: Call_PostCreateDBParameterGroup_603310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603326.validator(path, query, header, formData, body)
  let scheme = call_603326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603326.url(scheme.get, call_603326.host, call_603326.base,
                         call_603326.route, valid.getOrDefault("path"))
  result = hook(call_603326, url, valid)

proc call*(call_603327: Call_PostCreateDBParameterGroup_603310;
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
  var query_603328 = newJObject()
  var formData_603329 = newJObject()
  add(formData_603329, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_603329.add "Tags", Tags
  add(query_603328, "Action", newJString(Action))
  add(formData_603329, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603328, "Version", newJString(Version))
  add(formData_603329, "Description", newJString(Description))
  result = call_603327.call(nil, query_603328, nil, formData_603329, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_603310(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_603311, base: "/",
    url: url_PostCreateDBParameterGroup_603312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_603291 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBParameterGroup_603293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_603292(path: JsonNode; query: JsonNode;
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
  var valid_603294 = query.getOrDefault("Description")
  valid_603294 = validateParameter(valid_603294, JString, required = true,
                                 default = nil)
  if valid_603294 != nil:
    section.add "Description", valid_603294
  var valid_603295 = query.getOrDefault("DBParameterGroupFamily")
  valid_603295 = validateParameter(valid_603295, JString, required = true,
                                 default = nil)
  if valid_603295 != nil:
    section.add "DBParameterGroupFamily", valid_603295
  var valid_603296 = query.getOrDefault("Tags")
  valid_603296 = validateParameter(valid_603296, JArray, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "Tags", valid_603296
  var valid_603297 = query.getOrDefault("DBParameterGroupName")
  valid_603297 = validateParameter(valid_603297, JString, required = true,
                                 default = nil)
  if valid_603297 != nil:
    section.add "DBParameterGroupName", valid_603297
  var valid_603298 = query.getOrDefault("Action")
  valid_603298 = validateParameter(valid_603298, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603298 != nil:
    section.add "Action", valid_603298
  var valid_603299 = query.getOrDefault("Version")
  valid_603299 = validateParameter(valid_603299, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603299 != nil:
    section.add "Version", valid_603299
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603300 = header.getOrDefault("X-Amz-Date")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Date", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Security-Token")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Security-Token", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Content-Sha256", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Algorithm")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Algorithm", valid_603303
  var valid_603304 = header.getOrDefault("X-Amz-Signature")
  valid_603304 = validateParameter(valid_603304, JString, required = false,
                                 default = nil)
  if valid_603304 != nil:
    section.add "X-Amz-Signature", valid_603304
  var valid_603305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603305 = validateParameter(valid_603305, JString, required = false,
                                 default = nil)
  if valid_603305 != nil:
    section.add "X-Amz-SignedHeaders", valid_603305
  var valid_603306 = header.getOrDefault("X-Amz-Credential")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Credential", valid_603306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603307: Call_GetCreateDBParameterGroup_603291; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603307.validator(path, query, header, formData, body)
  let scheme = call_603307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603307.url(scheme.get, call_603307.host, call_603307.base,
                         call_603307.route, valid.getOrDefault("path"))
  result = hook(call_603307, url, valid)

proc call*(call_603308: Call_GetCreateDBParameterGroup_603291; Description: string;
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
  var query_603309 = newJObject()
  add(query_603309, "Description", newJString(Description))
  add(query_603309, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_603309.add "Tags", Tags
  add(query_603309, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603309, "Action", newJString(Action))
  add(query_603309, "Version", newJString(Version))
  result = call_603308.call(nil, query_603309, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_603291(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_603292, base: "/",
    url: url_GetCreateDBParameterGroup_603293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_603348 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSecurityGroup_603350(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_603349(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603351 = query.getOrDefault("Action")
  valid_603351 = validateParameter(valid_603351, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603351 != nil:
    section.add "Action", valid_603351
  var valid_603352 = query.getOrDefault("Version")
  valid_603352 = validateParameter(valid_603352, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603352 != nil:
    section.add "Version", valid_603352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603353 = header.getOrDefault("X-Amz-Date")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Date", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-Security-Token")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-Security-Token", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Content-Sha256", valid_603355
  var valid_603356 = header.getOrDefault("X-Amz-Algorithm")
  valid_603356 = validateParameter(valid_603356, JString, required = false,
                                 default = nil)
  if valid_603356 != nil:
    section.add "X-Amz-Algorithm", valid_603356
  var valid_603357 = header.getOrDefault("X-Amz-Signature")
  valid_603357 = validateParameter(valid_603357, JString, required = false,
                                 default = nil)
  if valid_603357 != nil:
    section.add "X-Amz-Signature", valid_603357
  var valid_603358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603358 = validateParameter(valid_603358, JString, required = false,
                                 default = nil)
  if valid_603358 != nil:
    section.add "X-Amz-SignedHeaders", valid_603358
  var valid_603359 = header.getOrDefault("X-Amz-Credential")
  valid_603359 = validateParameter(valid_603359, JString, required = false,
                                 default = nil)
  if valid_603359 != nil:
    section.add "X-Amz-Credential", valid_603359
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603360 = formData.getOrDefault("DBSecurityGroupName")
  valid_603360 = validateParameter(valid_603360, JString, required = true,
                                 default = nil)
  if valid_603360 != nil:
    section.add "DBSecurityGroupName", valid_603360
  var valid_603361 = formData.getOrDefault("Tags")
  valid_603361 = validateParameter(valid_603361, JArray, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "Tags", valid_603361
  var valid_603362 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = nil)
  if valid_603362 != nil:
    section.add "DBSecurityGroupDescription", valid_603362
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603363: Call_PostCreateDBSecurityGroup_603348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603363.validator(path, query, header, formData, body)
  let scheme = call_603363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603363.url(scheme.get, call_603363.host, call_603363.base,
                         call_603363.route, valid.getOrDefault("path"))
  result = hook(call_603363, url, valid)

proc call*(call_603364: Call_PostCreateDBSecurityGroup_603348;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_603365 = newJObject()
  var formData_603366 = newJObject()
  add(formData_603366, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_603366.add "Tags", Tags
  add(query_603365, "Action", newJString(Action))
  add(formData_603366, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603365, "Version", newJString(Version))
  result = call_603364.call(nil, query_603365, nil, formData_603366, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_603348(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_603349, base: "/",
    url: url_PostCreateDBSecurityGroup_603350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_603330 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSecurityGroup_603332(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_603331(path: JsonNode; query: JsonNode;
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
  var valid_603333 = query.getOrDefault("DBSecurityGroupName")
  valid_603333 = validateParameter(valid_603333, JString, required = true,
                                 default = nil)
  if valid_603333 != nil:
    section.add "DBSecurityGroupName", valid_603333
  var valid_603334 = query.getOrDefault("DBSecurityGroupDescription")
  valid_603334 = validateParameter(valid_603334, JString, required = true,
                                 default = nil)
  if valid_603334 != nil:
    section.add "DBSecurityGroupDescription", valid_603334
  var valid_603335 = query.getOrDefault("Tags")
  valid_603335 = validateParameter(valid_603335, JArray, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "Tags", valid_603335
  var valid_603336 = query.getOrDefault("Action")
  valid_603336 = validateParameter(valid_603336, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603336 != nil:
    section.add "Action", valid_603336
  var valid_603337 = query.getOrDefault("Version")
  valid_603337 = validateParameter(valid_603337, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603337 != nil:
    section.add "Version", valid_603337
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603338 = header.getOrDefault("X-Amz-Date")
  valid_603338 = validateParameter(valid_603338, JString, required = false,
                                 default = nil)
  if valid_603338 != nil:
    section.add "X-Amz-Date", valid_603338
  var valid_603339 = header.getOrDefault("X-Amz-Security-Token")
  valid_603339 = validateParameter(valid_603339, JString, required = false,
                                 default = nil)
  if valid_603339 != nil:
    section.add "X-Amz-Security-Token", valid_603339
  var valid_603340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603340 = validateParameter(valid_603340, JString, required = false,
                                 default = nil)
  if valid_603340 != nil:
    section.add "X-Amz-Content-Sha256", valid_603340
  var valid_603341 = header.getOrDefault("X-Amz-Algorithm")
  valid_603341 = validateParameter(valid_603341, JString, required = false,
                                 default = nil)
  if valid_603341 != nil:
    section.add "X-Amz-Algorithm", valid_603341
  var valid_603342 = header.getOrDefault("X-Amz-Signature")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Signature", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-SignedHeaders", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Credential")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Credential", valid_603344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603345: Call_GetCreateDBSecurityGroup_603330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603345.validator(path, query, header, formData, body)
  let scheme = call_603345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603345.url(scheme.get, call_603345.host, call_603345.base,
                         call_603345.route, valid.getOrDefault("path"))
  result = hook(call_603345, url, valid)

proc call*(call_603346: Call_GetCreateDBSecurityGroup_603330;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603347 = newJObject()
  add(query_603347, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603347, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_603347.add "Tags", Tags
  add(query_603347, "Action", newJString(Action))
  add(query_603347, "Version", newJString(Version))
  result = call_603346.call(nil, query_603347, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_603330(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_603331, base: "/",
    url: url_GetCreateDBSecurityGroup_603332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_603385 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSnapshot_603387(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_603386(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603388 = query.getOrDefault("Action")
  valid_603388 = validateParameter(valid_603388, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603388 != nil:
    section.add "Action", valid_603388
  var valid_603389 = query.getOrDefault("Version")
  valid_603389 = validateParameter(valid_603389, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603389 != nil:
    section.add "Version", valid_603389
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603390 = header.getOrDefault("X-Amz-Date")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Date", valid_603390
  var valid_603391 = header.getOrDefault("X-Amz-Security-Token")
  valid_603391 = validateParameter(valid_603391, JString, required = false,
                                 default = nil)
  if valid_603391 != nil:
    section.add "X-Amz-Security-Token", valid_603391
  var valid_603392 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603392 = validateParameter(valid_603392, JString, required = false,
                                 default = nil)
  if valid_603392 != nil:
    section.add "X-Amz-Content-Sha256", valid_603392
  var valid_603393 = header.getOrDefault("X-Amz-Algorithm")
  valid_603393 = validateParameter(valid_603393, JString, required = false,
                                 default = nil)
  if valid_603393 != nil:
    section.add "X-Amz-Algorithm", valid_603393
  var valid_603394 = header.getOrDefault("X-Amz-Signature")
  valid_603394 = validateParameter(valid_603394, JString, required = false,
                                 default = nil)
  if valid_603394 != nil:
    section.add "X-Amz-Signature", valid_603394
  var valid_603395 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-SignedHeaders", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Credential")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Credential", valid_603396
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603397 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603397 = validateParameter(valid_603397, JString, required = true,
                                 default = nil)
  if valid_603397 != nil:
    section.add "DBInstanceIdentifier", valid_603397
  var valid_603398 = formData.getOrDefault("Tags")
  valid_603398 = validateParameter(valid_603398, JArray, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "Tags", valid_603398
  var valid_603399 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603399 = validateParameter(valid_603399, JString, required = true,
                                 default = nil)
  if valid_603399 != nil:
    section.add "DBSnapshotIdentifier", valid_603399
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603400: Call_PostCreateDBSnapshot_603385; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603400.validator(path, query, header, formData, body)
  let scheme = call_603400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603400.url(scheme.get, call_603400.host, call_603400.base,
                         call_603400.route, valid.getOrDefault("path"))
  result = hook(call_603400, url, valid)

proc call*(call_603401: Call_PostCreateDBSnapshot_603385;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603402 = newJObject()
  var formData_603403 = newJObject()
  add(formData_603403, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_603403.add "Tags", Tags
  add(formData_603403, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603402, "Action", newJString(Action))
  add(query_603402, "Version", newJString(Version))
  result = call_603401.call(nil, query_603402, nil, formData_603403, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_603385(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_603386, base: "/",
    url: url_PostCreateDBSnapshot_603387, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_603367 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSnapshot_603369(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_603368(path: JsonNode; query: JsonNode;
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
  var valid_603370 = query.getOrDefault("Tags")
  valid_603370 = validateParameter(valid_603370, JArray, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "Tags", valid_603370
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603371 = query.getOrDefault("Action")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603371 != nil:
    section.add "Action", valid_603371
  var valid_603372 = query.getOrDefault("Version")
  valid_603372 = validateParameter(valid_603372, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603372 != nil:
    section.add "Version", valid_603372
  var valid_603373 = query.getOrDefault("DBInstanceIdentifier")
  valid_603373 = validateParameter(valid_603373, JString, required = true,
                                 default = nil)
  if valid_603373 != nil:
    section.add "DBInstanceIdentifier", valid_603373
  var valid_603374 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = nil)
  if valid_603374 != nil:
    section.add "DBSnapshotIdentifier", valid_603374
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603375 = header.getOrDefault("X-Amz-Date")
  valid_603375 = validateParameter(valid_603375, JString, required = false,
                                 default = nil)
  if valid_603375 != nil:
    section.add "X-Amz-Date", valid_603375
  var valid_603376 = header.getOrDefault("X-Amz-Security-Token")
  valid_603376 = validateParameter(valid_603376, JString, required = false,
                                 default = nil)
  if valid_603376 != nil:
    section.add "X-Amz-Security-Token", valid_603376
  var valid_603377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Content-Sha256", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Algorithm")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Algorithm", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Signature")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Signature", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-SignedHeaders", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Credential")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Credential", valid_603381
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603382: Call_GetCreateDBSnapshot_603367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603382.validator(path, query, header, formData, body)
  let scheme = call_603382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603382.url(scheme.get, call_603382.host, call_603382.base,
                         call_603382.route, valid.getOrDefault("path"))
  result = hook(call_603382, url, valid)

proc call*(call_603383: Call_GetCreateDBSnapshot_603367;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603384 = newJObject()
  if Tags != nil:
    query_603384.add "Tags", Tags
  add(query_603384, "Action", newJString(Action))
  add(query_603384, "Version", newJString(Version))
  add(query_603384, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603384, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603383.call(nil, query_603384, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_603367(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_603368, base: "/",
    url: url_GetCreateDBSnapshot_603369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603423 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSubnetGroup_603425(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_603424(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603426 = query.getOrDefault("Action")
  valid_603426 = validateParameter(valid_603426, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603426 != nil:
    section.add "Action", valid_603426
  var valid_603427 = query.getOrDefault("Version")
  valid_603427 = validateParameter(valid_603427, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603427 != nil:
    section.add "Version", valid_603427
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603428 = header.getOrDefault("X-Amz-Date")
  valid_603428 = validateParameter(valid_603428, JString, required = false,
                                 default = nil)
  if valid_603428 != nil:
    section.add "X-Amz-Date", valid_603428
  var valid_603429 = header.getOrDefault("X-Amz-Security-Token")
  valid_603429 = validateParameter(valid_603429, JString, required = false,
                                 default = nil)
  if valid_603429 != nil:
    section.add "X-Amz-Security-Token", valid_603429
  var valid_603430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "X-Amz-Content-Sha256", valid_603430
  var valid_603431 = header.getOrDefault("X-Amz-Algorithm")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Algorithm", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Signature")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Signature", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-SignedHeaders", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Credential")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Credential", valid_603434
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_603435 = formData.getOrDefault("Tags")
  valid_603435 = validateParameter(valid_603435, JArray, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "Tags", valid_603435
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603436 = formData.getOrDefault("DBSubnetGroupName")
  valid_603436 = validateParameter(valid_603436, JString, required = true,
                                 default = nil)
  if valid_603436 != nil:
    section.add "DBSubnetGroupName", valid_603436
  var valid_603437 = formData.getOrDefault("SubnetIds")
  valid_603437 = validateParameter(valid_603437, JArray, required = true, default = nil)
  if valid_603437 != nil:
    section.add "SubnetIds", valid_603437
  var valid_603438 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603438 = validateParameter(valid_603438, JString, required = true,
                                 default = nil)
  if valid_603438 != nil:
    section.add "DBSubnetGroupDescription", valid_603438
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603439: Call_PostCreateDBSubnetGroup_603423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603439.validator(path, query, header, formData, body)
  let scheme = call_603439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603439.url(scheme.get, call_603439.host, call_603439.base,
                         call_603439.route, valid.getOrDefault("path"))
  result = hook(call_603439, url, valid)

proc call*(call_603440: Call_PostCreateDBSubnetGroup_603423;
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
  var query_603441 = newJObject()
  var formData_603442 = newJObject()
  if Tags != nil:
    formData_603442.add "Tags", Tags
  add(formData_603442, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603442.add "SubnetIds", SubnetIds
  add(query_603441, "Action", newJString(Action))
  add(formData_603442, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603441, "Version", newJString(Version))
  result = call_603440.call(nil, query_603441, nil, formData_603442, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603423(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603424, base: "/",
    url: url_PostCreateDBSubnetGroup_603425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603404 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSubnetGroup_603406(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_603405(path: JsonNode; query: JsonNode;
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
  var valid_603407 = query.getOrDefault("Tags")
  valid_603407 = validateParameter(valid_603407, JArray, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "Tags", valid_603407
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603408 = query.getOrDefault("Action")
  valid_603408 = validateParameter(valid_603408, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603408 != nil:
    section.add "Action", valid_603408
  var valid_603409 = query.getOrDefault("DBSubnetGroupName")
  valid_603409 = validateParameter(valid_603409, JString, required = true,
                                 default = nil)
  if valid_603409 != nil:
    section.add "DBSubnetGroupName", valid_603409
  var valid_603410 = query.getOrDefault("SubnetIds")
  valid_603410 = validateParameter(valid_603410, JArray, required = true, default = nil)
  if valid_603410 != nil:
    section.add "SubnetIds", valid_603410
  var valid_603411 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603411 = validateParameter(valid_603411, JString, required = true,
                                 default = nil)
  if valid_603411 != nil:
    section.add "DBSubnetGroupDescription", valid_603411
  var valid_603412 = query.getOrDefault("Version")
  valid_603412 = validateParameter(valid_603412, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603412 != nil:
    section.add "Version", valid_603412
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603413 = header.getOrDefault("X-Amz-Date")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Date", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Security-Token")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Security-Token", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-Content-Sha256", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Algorithm")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Algorithm", valid_603416
  var valid_603417 = header.getOrDefault("X-Amz-Signature")
  valid_603417 = validateParameter(valid_603417, JString, required = false,
                                 default = nil)
  if valid_603417 != nil:
    section.add "X-Amz-Signature", valid_603417
  var valid_603418 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-SignedHeaders", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Credential")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Credential", valid_603419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603420: Call_GetCreateDBSubnetGroup_603404; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603420.validator(path, query, header, formData, body)
  let scheme = call_603420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603420.url(scheme.get, call_603420.host, call_603420.base,
                         call_603420.route, valid.getOrDefault("path"))
  result = hook(call_603420, url, valid)

proc call*(call_603421: Call_GetCreateDBSubnetGroup_603404;
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
  var query_603422 = newJObject()
  if Tags != nil:
    query_603422.add "Tags", Tags
  add(query_603422, "Action", newJString(Action))
  add(query_603422, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603422.add "SubnetIds", SubnetIds
  add(query_603422, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603422, "Version", newJString(Version))
  result = call_603421.call(nil, query_603422, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603404(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603405, base: "/",
    url: url_GetCreateDBSubnetGroup_603406, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_603465 = ref object of OpenApiRestCall_602417
proc url_PostCreateEventSubscription_603467(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_603466(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603468 = query.getOrDefault("Action")
  valid_603468 = validateParameter(valid_603468, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603468 != nil:
    section.add "Action", valid_603468
  var valid_603469 = query.getOrDefault("Version")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603469 != nil:
    section.add "Version", valid_603469
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603470 = header.getOrDefault("X-Amz-Date")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Date", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-Security-Token")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Security-Token", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Content-Sha256", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Algorithm")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Algorithm", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Signature")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Signature", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-SignedHeaders", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-Credential")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-Credential", valid_603476
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
  var valid_603477 = formData.getOrDefault("Enabled")
  valid_603477 = validateParameter(valid_603477, JBool, required = false, default = nil)
  if valid_603477 != nil:
    section.add "Enabled", valid_603477
  var valid_603478 = formData.getOrDefault("EventCategories")
  valid_603478 = validateParameter(valid_603478, JArray, required = false,
                                 default = nil)
  if valid_603478 != nil:
    section.add "EventCategories", valid_603478
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_603479 = formData.getOrDefault("SnsTopicArn")
  valid_603479 = validateParameter(valid_603479, JString, required = true,
                                 default = nil)
  if valid_603479 != nil:
    section.add "SnsTopicArn", valid_603479
  var valid_603480 = formData.getOrDefault("SourceIds")
  valid_603480 = validateParameter(valid_603480, JArray, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "SourceIds", valid_603480
  var valid_603481 = formData.getOrDefault("Tags")
  valid_603481 = validateParameter(valid_603481, JArray, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "Tags", valid_603481
  var valid_603482 = formData.getOrDefault("SubscriptionName")
  valid_603482 = validateParameter(valid_603482, JString, required = true,
                                 default = nil)
  if valid_603482 != nil:
    section.add "SubscriptionName", valid_603482
  var valid_603483 = formData.getOrDefault("SourceType")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "SourceType", valid_603483
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603484: Call_PostCreateEventSubscription_603465; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603484.validator(path, query, header, formData, body)
  let scheme = call_603484.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603484.url(scheme.get, call_603484.host, call_603484.base,
                         call_603484.route, valid.getOrDefault("path"))
  result = hook(call_603484, url, valid)

proc call*(call_603485: Call_PostCreateEventSubscription_603465;
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
  var query_603486 = newJObject()
  var formData_603487 = newJObject()
  add(formData_603487, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_603487.add "EventCategories", EventCategories
  add(formData_603487, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_603487.add "SourceIds", SourceIds
  if Tags != nil:
    formData_603487.add "Tags", Tags
  add(formData_603487, "SubscriptionName", newJString(SubscriptionName))
  add(query_603486, "Action", newJString(Action))
  add(query_603486, "Version", newJString(Version))
  add(formData_603487, "SourceType", newJString(SourceType))
  result = call_603485.call(nil, query_603486, nil, formData_603487, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_603465(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_603466, base: "/",
    url: url_PostCreateEventSubscription_603467,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_603443 = ref object of OpenApiRestCall_602417
proc url_GetCreateEventSubscription_603445(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_603444(path: JsonNode; query: JsonNode;
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
  var valid_603446 = query.getOrDefault("SourceType")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "SourceType", valid_603446
  var valid_603447 = query.getOrDefault("SourceIds")
  valid_603447 = validateParameter(valid_603447, JArray, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "SourceIds", valid_603447
  var valid_603448 = query.getOrDefault("Enabled")
  valid_603448 = validateParameter(valid_603448, JBool, required = false, default = nil)
  if valid_603448 != nil:
    section.add "Enabled", valid_603448
  var valid_603449 = query.getOrDefault("Tags")
  valid_603449 = validateParameter(valid_603449, JArray, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "Tags", valid_603449
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603450 = query.getOrDefault("Action")
  valid_603450 = validateParameter(valid_603450, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603450 != nil:
    section.add "Action", valid_603450
  var valid_603451 = query.getOrDefault("SnsTopicArn")
  valid_603451 = validateParameter(valid_603451, JString, required = true,
                                 default = nil)
  if valid_603451 != nil:
    section.add "SnsTopicArn", valid_603451
  var valid_603452 = query.getOrDefault("EventCategories")
  valid_603452 = validateParameter(valid_603452, JArray, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "EventCategories", valid_603452
  var valid_603453 = query.getOrDefault("SubscriptionName")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = nil)
  if valid_603453 != nil:
    section.add "SubscriptionName", valid_603453
  var valid_603454 = query.getOrDefault("Version")
  valid_603454 = validateParameter(valid_603454, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603454 != nil:
    section.add "Version", valid_603454
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603455 = header.getOrDefault("X-Amz-Date")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Date", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Security-Token")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Security-Token", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Content-Sha256", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-Algorithm")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-Algorithm", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Signature")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Signature", valid_603459
  var valid_603460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603460 = validateParameter(valid_603460, JString, required = false,
                                 default = nil)
  if valid_603460 != nil:
    section.add "X-Amz-SignedHeaders", valid_603460
  var valid_603461 = header.getOrDefault("X-Amz-Credential")
  valid_603461 = validateParameter(valid_603461, JString, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "X-Amz-Credential", valid_603461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603462: Call_GetCreateEventSubscription_603443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603462.validator(path, query, header, formData, body)
  let scheme = call_603462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603462.url(scheme.get, call_603462.host, call_603462.base,
                         call_603462.route, valid.getOrDefault("path"))
  result = hook(call_603462, url, valid)

proc call*(call_603463: Call_GetCreateEventSubscription_603443;
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
  var query_603464 = newJObject()
  add(query_603464, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_603464.add "SourceIds", SourceIds
  add(query_603464, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_603464.add "Tags", Tags
  add(query_603464, "Action", newJString(Action))
  add(query_603464, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_603464.add "EventCategories", EventCategories
  add(query_603464, "SubscriptionName", newJString(SubscriptionName))
  add(query_603464, "Version", newJString(Version))
  result = call_603463.call(nil, query_603464, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_603443(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_603444, base: "/",
    url: url_GetCreateEventSubscription_603445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_603508 = ref object of OpenApiRestCall_602417
proc url_PostCreateOptionGroup_603510(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_603509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603511 = query.getOrDefault("Action")
  valid_603511 = validateParameter(valid_603511, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603511 != nil:
    section.add "Action", valid_603511
  var valid_603512 = query.getOrDefault("Version")
  valid_603512 = validateParameter(valid_603512, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603512 != nil:
    section.add "Version", valid_603512
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603513 = header.getOrDefault("X-Amz-Date")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Date", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Security-Token")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Security-Token", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Content-Sha256", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Algorithm")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Algorithm", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-Signature")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Signature", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-SignedHeaders", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Credential")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Credential", valid_603519
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_603520 = formData.getOrDefault("MajorEngineVersion")
  valid_603520 = validateParameter(valid_603520, JString, required = true,
                                 default = nil)
  if valid_603520 != nil:
    section.add "MajorEngineVersion", valid_603520
  var valid_603521 = formData.getOrDefault("OptionGroupName")
  valid_603521 = validateParameter(valid_603521, JString, required = true,
                                 default = nil)
  if valid_603521 != nil:
    section.add "OptionGroupName", valid_603521
  var valid_603522 = formData.getOrDefault("Tags")
  valid_603522 = validateParameter(valid_603522, JArray, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "Tags", valid_603522
  var valid_603523 = formData.getOrDefault("EngineName")
  valid_603523 = validateParameter(valid_603523, JString, required = true,
                                 default = nil)
  if valid_603523 != nil:
    section.add "EngineName", valid_603523
  var valid_603524 = formData.getOrDefault("OptionGroupDescription")
  valid_603524 = validateParameter(valid_603524, JString, required = true,
                                 default = nil)
  if valid_603524 != nil:
    section.add "OptionGroupDescription", valid_603524
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603525: Call_PostCreateOptionGroup_603508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603525.validator(path, query, header, formData, body)
  let scheme = call_603525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603525.url(scheme.get, call_603525.host, call_603525.base,
                         call_603525.route, valid.getOrDefault("path"))
  result = hook(call_603525, url, valid)

proc call*(call_603526: Call_PostCreateOptionGroup_603508;
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
  var query_603527 = newJObject()
  var formData_603528 = newJObject()
  add(formData_603528, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_603528, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_603528.add "Tags", Tags
  add(query_603527, "Action", newJString(Action))
  add(formData_603528, "EngineName", newJString(EngineName))
  add(formData_603528, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_603527, "Version", newJString(Version))
  result = call_603526.call(nil, query_603527, nil, formData_603528, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_603508(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_603509, base: "/",
    url: url_PostCreateOptionGroup_603510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_603488 = ref object of OpenApiRestCall_602417
proc url_GetCreateOptionGroup_603490(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_603489(path: JsonNode; query: JsonNode;
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
  var valid_603491 = query.getOrDefault("OptionGroupName")
  valid_603491 = validateParameter(valid_603491, JString, required = true,
                                 default = nil)
  if valid_603491 != nil:
    section.add "OptionGroupName", valid_603491
  var valid_603492 = query.getOrDefault("Tags")
  valid_603492 = validateParameter(valid_603492, JArray, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "Tags", valid_603492
  var valid_603493 = query.getOrDefault("OptionGroupDescription")
  valid_603493 = validateParameter(valid_603493, JString, required = true,
                                 default = nil)
  if valid_603493 != nil:
    section.add "OptionGroupDescription", valid_603493
  var valid_603494 = query.getOrDefault("Action")
  valid_603494 = validateParameter(valid_603494, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603494 != nil:
    section.add "Action", valid_603494
  var valid_603495 = query.getOrDefault("Version")
  valid_603495 = validateParameter(valid_603495, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603495 != nil:
    section.add "Version", valid_603495
  var valid_603496 = query.getOrDefault("EngineName")
  valid_603496 = validateParameter(valid_603496, JString, required = true,
                                 default = nil)
  if valid_603496 != nil:
    section.add "EngineName", valid_603496
  var valid_603497 = query.getOrDefault("MajorEngineVersion")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = nil)
  if valid_603497 != nil:
    section.add "MajorEngineVersion", valid_603497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603498 = header.getOrDefault("X-Amz-Date")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Date", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-Security-Token")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Security-Token", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Content-Sha256", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Algorithm")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Algorithm", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Signature")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Signature", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-SignedHeaders", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-Credential")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-Credential", valid_603504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603505: Call_GetCreateOptionGroup_603488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603505.validator(path, query, header, formData, body)
  let scheme = call_603505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603505.url(scheme.get, call_603505.host, call_603505.base,
                         call_603505.route, valid.getOrDefault("path"))
  result = hook(call_603505, url, valid)

proc call*(call_603506: Call_GetCreateOptionGroup_603488; OptionGroupName: string;
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
  var query_603507 = newJObject()
  add(query_603507, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_603507.add "Tags", Tags
  add(query_603507, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_603507, "Action", newJString(Action))
  add(query_603507, "Version", newJString(Version))
  add(query_603507, "EngineName", newJString(EngineName))
  add(query_603507, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603506.call(nil, query_603507, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_603488(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_603489, base: "/",
    url: url_GetCreateOptionGroup_603490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603547 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBInstance_603549(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_603548(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603550 = query.getOrDefault("Action")
  valid_603550 = validateParameter(valid_603550, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603550 != nil:
    section.add "Action", valid_603550
  var valid_603551 = query.getOrDefault("Version")
  valid_603551 = validateParameter(valid_603551, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603551 != nil:
    section.add "Version", valid_603551
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603552 = header.getOrDefault("X-Amz-Date")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Date", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Security-Token")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Security-Token", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Content-Sha256", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-Algorithm")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-Algorithm", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Signature")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Signature", valid_603556
  var valid_603557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603557 = validateParameter(valid_603557, JString, required = false,
                                 default = nil)
  if valid_603557 != nil:
    section.add "X-Amz-SignedHeaders", valid_603557
  var valid_603558 = header.getOrDefault("X-Amz-Credential")
  valid_603558 = validateParameter(valid_603558, JString, required = false,
                                 default = nil)
  if valid_603558 != nil:
    section.add "X-Amz-Credential", valid_603558
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603559 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603559 = validateParameter(valid_603559, JString, required = true,
                                 default = nil)
  if valid_603559 != nil:
    section.add "DBInstanceIdentifier", valid_603559
  var valid_603560 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603560 = validateParameter(valid_603560, JString, required = false,
                                 default = nil)
  if valid_603560 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603560
  var valid_603561 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603561 = validateParameter(valid_603561, JBool, required = false, default = nil)
  if valid_603561 != nil:
    section.add "SkipFinalSnapshot", valid_603561
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603562: Call_PostDeleteDBInstance_603547; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603562.validator(path, query, header, formData, body)
  let scheme = call_603562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603562.url(scheme.get, call_603562.host, call_603562.base,
                         call_603562.route, valid.getOrDefault("path"))
  result = hook(call_603562, url, valid)

proc call*(call_603563: Call_PostDeleteDBInstance_603547;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_603564 = newJObject()
  var formData_603565 = newJObject()
  add(formData_603565, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603565, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603564, "Action", newJString(Action))
  add(query_603564, "Version", newJString(Version))
  add(formData_603565, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603563.call(nil, query_603564, nil, formData_603565, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603547(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603548, base: "/",
    url: url_PostDeleteDBInstance_603549, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603529 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBInstance_603531(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_603530(path: JsonNode; query: JsonNode;
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
  var valid_603532 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603532
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603533 = query.getOrDefault("Action")
  valid_603533 = validateParameter(valid_603533, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603533 != nil:
    section.add "Action", valid_603533
  var valid_603534 = query.getOrDefault("SkipFinalSnapshot")
  valid_603534 = validateParameter(valid_603534, JBool, required = false, default = nil)
  if valid_603534 != nil:
    section.add "SkipFinalSnapshot", valid_603534
  var valid_603535 = query.getOrDefault("Version")
  valid_603535 = validateParameter(valid_603535, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603535 != nil:
    section.add "Version", valid_603535
  var valid_603536 = query.getOrDefault("DBInstanceIdentifier")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = nil)
  if valid_603536 != nil:
    section.add "DBInstanceIdentifier", valid_603536
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603537 = header.getOrDefault("X-Amz-Date")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-Date", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Security-Token")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Security-Token", valid_603538
  var valid_603539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603539 = validateParameter(valid_603539, JString, required = false,
                                 default = nil)
  if valid_603539 != nil:
    section.add "X-Amz-Content-Sha256", valid_603539
  var valid_603540 = header.getOrDefault("X-Amz-Algorithm")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "X-Amz-Algorithm", valid_603540
  var valid_603541 = header.getOrDefault("X-Amz-Signature")
  valid_603541 = validateParameter(valid_603541, JString, required = false,
                                 default = nil)
  if valid_603541 != nil:
    section.add "X-Amz-Signature", valid_603541
  var valid_603542 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603542 = validateParameter(valid_603542, JString, required = false,
                                 default = nil)
  if valid_603542 != nil:
    section.add "X-Amz-SignedHeaders", valid_603542
  var valid_603543 = header.getOrDefault("X-Amz-Credential")
  valid_603543 = validateParameter(valid_603543, JString, required = false,
                                 default = nil)
  if valid_603543 != nil:
    section.add "X-Amz-Credential", valid_603543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603544: Call_GetDeleteDBInstance_603529; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603544.validator(path, query, header, formData, body)
  let scheme = call_603544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603544.url(scheme.get, call_603544.host, call_603544.base,
                         call_603544.route, valid.getOrDefault("path"))
  result = hook(call_603544, url, valid)

proc call*(call_603545: Call_GetDeleteDBInstance_603529;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_603546 = newJObject()
  add(query_603546, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603546, "Action", newJString(Action))
  add(query_603546, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603546, "Version", newJString(Version))
  add(query_603546, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603545.call(nil, query_603546, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603529(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603530, base: "/",
    url: url_GetDeleteDBInstance_603531, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_603582 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBParameterGroup_603584(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_603583(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603585 = query.getOrDefault("Action")
  valid_603585 = validateParameter(valid_603585, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603585 != nil:
    section.add "Action", valid_603585
  var valid_603586 = query.getOrDefault("Version")
  valid_603586 = validateParameter(valid_603586, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603586 != nil:
    section.add "Version", valid_603586
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603587 = header.getOrDefault("X-Amz-Date")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Date", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Security-Token")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Security-Token", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Content-Sha256", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Algorithm")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Algorithm", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Signature")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Signature", valid_603591
  var valid_603592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603592 = validateParameter(valid_603592, JString, required = false,
                                 default = nil)
  if valid_603592 != nil:
    section.add "X-Amz-SignedHeaders", valid_603592
  var valid_603593 = header.getOrDefault("X-Amz-Credential")
  valid_603593 = validateParameter(valid_603593, JString, required = false,
                                 default = nil)
  if valid_603593 != nil:
    section.add "X-Amz-Credential", valid_603593
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603594 = formData.getOrDefault("DBParameterGroupName")
  valid_603594 = validateParameter(valid_603594, JString, required = true,
                                 default = nil)
  if valid_603594 != nil:
    section.add "DBParameterGroupName", valid_603594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603595: Call_PostDeleteDBParameterGroup_603582; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603595.validator(path, query, header, formData, body)
  let scheme = call_603595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603595.url(scheme.get, call_603595.host, call_603595.base,
                         call_603595.route, valid.getOrDefault("path"))
  result = hook(call_603595, url, valid)

proc call*(call_603596: Call_PostDeleteDBParameterGroup_603582;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603597 = newJObject()
  var formData_603598 = newJObject()
  add(formData_603598, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603597, "Action", newJString(Action))
  add(query_603597, "Version", newJString(Version))
  result = call_603596.call(nil, query_603597, nil, formData_603598, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_603582(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_603583, base: "/",
    url: url_PostDeleteDBParameterGroup_603584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_603566 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBParameterGroup_603568(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_603567(path: JsonNode; query: JsonNode;
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
  var valid_603569 = query.getOrDefault("DBParameterGroupName")
  valid_603569 = validateParameter(valid_603569, JString, required = true,
                                 default = nil)
  if valid_603569 != nil:
    section.add "DBParameterGroupName", valid_603569
  var valid_603570 = query.getOrDefault("Action")
  valid_603570 = validateParameter(valid_603570, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603570 != nil:
    section.add "Action", valid_603570
  var valid_603571 = query.getOrDefault("Version")
  valid_603571 = validateParameter(valid_603571, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603571 != nil:
    section.add "Version", valid_603571
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603572 = header.getOrDefault("X-Amz-Date")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-Date", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Security-Token")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Security-Token", valid_603573
  var valid_603574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603574 = validateParameter(valid_603574, JString, required = false,
                                 default = nil)
  if valid_603574 != nil:
    section.add "X-Amz-Content-Sha256", valid_603574
  var valid_603575 = header.getOrDefault("X-Amz-Algorithm")
  valid_603575 = validateParameter(valid_603575, JString, required = false,
                                 default = nil)
  if valid_603575 != nil:
    section.add "X-Amz-Algorithm", valid_603575
  var valid_603576 = header.getOrDefault("X-Amz-Signature")
  valid_603576 = validateParameter(valid_603576, JString, required = false,
                                 default = nil)
  if valid_603576 != nil:
    section.add "X-Amz-Signature", valid_603576
  var valid_603577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603577 = validateParameter(valid_603577, JString, required = false,
                                 default = nil)
  if valid_603577 != nil:
    section.add "X-Amz-SignedHeaders", valid_603577
  var valid_603578 = header.getOrDefault("X-Amz-Credential")
  valid_603578 = validateParameter(valid_603578, JString, required = false,
                                 default = nil)
  if valid_603578 != nil:
    section.add "X-Amz-Credential", valid_603578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603579: Call_GetDeleteDBParameterGroup_603566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603579.validator(path, query, header, formData, body)
  let scheme = call_603579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603579.url(scheme.get, call_603579.host, call_603579.base,
                         call_603579.route, valid.getOrDefault("path"))
  result = hook(call_603579, url, valid)

proc call*(call_603580: Call_GetDeleteDBParameterGroup_603566;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603581 = newJObject()
  add(query_603581, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603581, "Action", newJString(Action))
  add(query_603581, "Version", newJString(Version))
  result = call_603580.call(nil, query_603581, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_603566(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_603567, base: "/",
    url: url_GetDeleteDBParameterGroup_603568,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_603615 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSecurityGroup_603617(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_603616(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603618 = query.getOrDefault("Action")
  valid_603618 = validateParameter(valid_603618, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603618 != nil:
    section.add "Action", valid_603618
  var valid_603619 = query.getOrDefault("Version")
  valid_603619 = validateParameter(valid_603619, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603619 != nil:
    section.add "Version", valid_603619
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603620 = header.getOrDefault("X-Amz-Date")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Date", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Security-Token")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Security-Token", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Content-Sha256", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Algorithm")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Algorithm", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Signature")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Signature", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-SignedHeaders", valid_603625
  var valid_603626 = header.getOrDefault("X-Amz-Credential")
  valid_603626 = validateParameter(valid_603626, JString, required = false,
                                 default = nil)
  if valid_603626 != nil:
    section.add "X-Amz-Credential", valid_603626
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603627 = formData.getOrDefault("DBSecurityGroupName")
  valid_603627 = validateParameter(valid_603627, JString, required = true,
                                 default = nil)
  if valid_603627 != nil:
    section.add "DBSecurityGroupName", valid_603627
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603628: Call_PostDeleteDBSecurityGroup_603615; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603628.validator(path, query, header, formData, body)
  let scheme = call_603628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603628.url(scheme.get, call_603628.host, call_603628.base,
                         call_603628.route, valid.getOrDefault("path"))
  result = hook(call_603628, url, valid)

proc call*(call_603629: Call_PostDeleteDBSecurityGroup_603615;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603630 = newJObject()
  var formData_603631 = newJObject()
  add(formData_603631, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603630, "Action", newJString(Action))
  add(query_603630, "Version", newJString(Version))
  result = call_603629.call(nil, query_603630, nil, formData_603631, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_603615(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_603616, base: "/",
    url: url_PostDeleteDBSecurityGroup_603617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_603599 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSecurityGroup_603601(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_603600(path: JsonNode; query: JsonNode;
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
  var valid_603602 = query.getOrDefault("DBSecurityGroupName")
  valid_603602 = validateParameter(valid_603602, JString, required = true,
                                 default = nil)
  if valid_603602 != nil:
    section.add "DBSecurityGroupName", valid_603602
  var valid_603603 = query.getOrDefault("Action")
  valid_603603 = validateParameter(valid_603603, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603603 != nil:
    section.add "Action", valid_603603
  var valid_603604 = query.getOrDefault("Version")
  valid_603604 = validateParameter(valid_603604, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603604 != nil:
    section.add "Version", valid_603604
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603605 = header.getOrDefault("X-Amz-Date")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Date", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Security-Token")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Security-Token", valid_603606
  var valid_603607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603607 = validateParameter(valid_603607, JString, required = false,
                                 default = nil)
  if valid_603607 != nil:
    section.add "X-Amz-Content-Sha256", valid_603607
  var valid_603608 = header.getOrDefault("X-Amz-Algorithm")
  valid_603608 = validateParameter(valid_603608, JString, required = false,
                                 default = nil)
  if valid_603608 != nil:
    section.add "X-Amz-Algorithm", valid_603608
  var valid_603609 = header.getOrDefault("X-Amz-Signature")
  valid_603609 = validateParameter(valid_603609, JString, required = false,
                                 default = nil)
  if valid_603609 != nil:
    section.add "X-Amz-Signature", valid_603609
  var valid_603610 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603610 = validateParameter(valid_603610, JString, required = false,
                                 default = nil)
  if valid_603610 != nil:
    section.add "X-Amz-SignedHeaders", valid_603610
  var valid_603611 = header.getOrDefault("X-Amz-Credential")
  valid_603611 = validateParameter(valid_603611, JString, required = false,
                                 default = nil)
  if valid_603611 != nil:
    section.add "X-Amz-Credential", valid_603611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603612: Call_GetDeleteDBSecurityGroup_603599; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603612.validator(path, query, header, formData, body)
  let scheme = call_603612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603612.url(scheme.get, call_603612.host, call_603612.base,
                         call_603612.route, valid.getOrDefault("path"))
  result = hook(call_603612, url, valid)

proc call*(call_603613: Call_GetDeleteDBSecurityGroup_603599;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603614 = newJObject()
  add(query_603614, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603614, "Action", newJString(Action))
  add(query_603614, "Version", newJString(Version))
  result = call_603613.call(nil, query_603614, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_603599(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_603600, base: "/",
    url: url_GetDeleteDBSecurityGroup_603601, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_603648 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSnapshot_603650(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_603649(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603651 = query.getOrDefault("Action")
  valid_603651 = validateParameter(valid_603651, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603651 != nil:
    section.add "Action", valid_603651
  var valid_603652 = query.getOrDefault("Version")
  valid_603652 = validateParameter(valid_603652, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603652 != nil:
    section.add "Version", valid_603652
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603653 = header.getOrDefault("X-Amz-Date")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Date", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Security-Token")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Security-Token", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Content-Sha256", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Algorithm")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Algorithm", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Signature")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Signature", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-SignedHeaders", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-Credential")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-Credential", valid_603659
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_603660 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603660 = validateParameter(valid_603660, JString, required = true,
                                 default = nil)
  if valid_603660 != nil:
    section.add "DBSnapshotIdentifier", valid_603660
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603661: Call_PostDeleteDBSnapshot_603648; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603661.validator(path, query, header, formData, body)
  let scheme = call_603661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603661.url(scheme.get, call_603661.host, call_603661.base,
                         call_603661.route, valid.getOrDefault("path"))
  result = hook(call_603661, url, valid)

proc call*(call_603662: Call_PostDeleteDBSnapshot_603648;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603663 = newJObject()
  var formData_603664 = newJObject()
  add(formData_603664, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603663, "Action", newJString(Action))
  add(query_603663, "Version", newJString(Version))
  result = call_603662.call(nil, query_603663, nil, formData_603664, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_603648(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_603649, base: "/",
    url: url_PostDeleteDBSnapshot_603650, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_603632 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSnapshot_603634(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_603633(path: JsonNode; query: JsonNode;
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
  var valid_603635 = query.getOrDefault("Action")
  valid_603635 = validateParameter(valid_603635, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603635 != nil:
    section.add "Action", valid_603635
  var valid_603636 = query.getOrDefault("Version")
  valid_603636 = validateParameter(valid_603636, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603636 != nil:
    section.add "Version", valid_603636
  var valid_603637 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603637 = validateParameter(valid_603637, JString, required = true,
                                 default = nil)
  if valid_603637 != nil:
    section.add "DBSnapshotIdentifier", valid_603637
  result.add "query", section
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603645: Call_GetDeleteDBSnapshot_603632; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603645.validator(path, query, header, formData, body)
  let scheme = call_603645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603645.url(scheme.get, call_603645.host, call_603645.base,
                         call_603645.route, valid.getOrDefault("path"))
  result = hook(call_603645, url, valid)

proc call*(call_603646: Call_GetDeleteDBSnapshot_603632;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603647 = newJObject()
  add(query_603647, "Action", newJString(Action))
  add(query_603647, "Version", newJString(Version))
  add(query_603647, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603646.call(nil, query_603647, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_603632(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_603633, base: "/",
    url: url_GetDeleteDBSnapshot_603634, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603681 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSubnetGroup_603683(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_603682(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603684 = query.getOrDefault("Action")
  valid_603684 = validateParameter(valid_603684, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603684 != nil:
    section.add "Action", valid_603684
  var valid_603685 = query.getOrDefault("Version")
  valid_603685 = validateParameter(valid_603685, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603685 != nil:
    section.add "Version", valid_603685
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603686 = header.getOrDefault("X-Amz-Date")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Date", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Security-Token")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Security-Token", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Content-Sha256", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-Algorithm")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Algorithm", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Signature")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Signature", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-SignedHeaders", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Credential")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Credential", valid_603692
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603693 = formData.getOrDefault("DBSubnetGroupName")
  valid_603693 = validateParameter(valid_603693, JString, required = true,
                                 default = nil)
  if valid_603693 != nil:
    section.add "DBSubnetGroupName", valid_603693
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603694: Call_PostDeleteDBSubnetGroup_603681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603694.validator(path, query, header, formData, body)
  let scheme = call_603694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603694.url(scheme.get, call_603694.host, call_603694.base,
                         call_603694.route, valid.getOrDefault("path"))
  result = hook(call_603694, url, valid)

proc call*(call_603695: Call_PostDeleteDBSubnetGroup_603681;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603696 = newJObject()
  var formData_603697 = newJObject()
  add(formData_603697, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603696, "Action", newJString(Action))
  add(query_603696, "Version", newJString(Version))
  result = call_603695.call(nil, query_603696, nil, formData_603697, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603681(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603682, base: "/",
    url: url_PostDeleteDBSubnetGroup_603683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603665 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSubnetGroup_603667(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_603666(path: JsonNode; query: JsonNode;
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
  var valid_603668 = query.getOrDefault("Action")
  valid_603668 = validateParameter(valid_603668, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603668 != nil:
    section.add "Action", valid_603668
  var valid_603669 = query.getOrDefault("DBSubnetGroupName")
  valid_603669 = validateParameter(valid_603669, JString, required = true,
                                 default = nil)
  if valid_603669 != nil:
    section.add "DBSubnetGroupName", valid_603669
  var valid_603670 = query.getOrDefault("Version")
  valid_603670 = validateParameter(valid_603670, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603670 != nil:
    section.add "Version", valid_603670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603671 = header.getOrDefault("X-Amz-Date")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Date", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Security-Token")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Security-Token", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Content-Sha256", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-Algorithm")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-Algorithm", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Signature")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Signature", valid_603675
  var valid_603676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603676 = validateParameter(valid_603676, JString, required = false,
                                 default = nil)
  if valid_603676 != nil:
    section.add "X-Amz-SignedHeaders", valid_603676
  var valid_603677 = header.getOrDefault("X-Amz-Credential")
  valid_603677 = validateParameter(valid_603677, JString, required = false,
                                 default = nil)
  if valid_603677 != nil:
    section.add "X-Amz-Credential", valid_603677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603678: Call_GetDeleteDBSubnetGroup_603665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603678.validator(path, query, header, formData, body)
  let scheme = call_603678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603678.url(scheme.get, call_603678.host, call_603678.base,
                         call_603678.route, valid.getOrDefault("path"))
  result = hook(call_603678, url, valid)

proc call*(call_603679: Call_GetDeleteDBSubnetGroup_603665;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603680 = newJObject()
  add(query_603680, "Action", newJString(Action))
  add(query_603680, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603680, "Version", newJString(Version))
  result = call_603679.call(nil, query_603680, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603665(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603666, base: "/",
    url: url_GetDeleteDBSubnetGroup_603667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_603714 = ref object of OpenApiRestCall_602417
proc url_PostDeleteEventSubscription_603716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_603715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603717 = query.getOrDefault("Action")
  valid_603717 = validateParameter(valid_603717, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603717 != nil:
    section.add "Action", valid_603717
  var valid_603718 = query.getOrDefault("Version")
  valid_603718 = validateParameter(valid_603718, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603718 != nil:
    section.add "Version", valid_603718
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603719 = header.getOrDefault("X-Amz-Date")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Date", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Security-Token")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Security-Token", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Content-Sha256", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-Algorithm")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-Algorithm", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Signature")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Signature", valid_603723
  var valid_603724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-SignedHeaders", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Credential")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Credential", valid_603725
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603726 = formData.getOrDefault("SubscriptionName")
  valid_603726 = validateParameter(valid_603726, JString, required = true,
                                 default = nil)
  if valid_603726 != nil:
    section.add "SubscriptionName", valid_603726
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603727: Call_PostDeleteEventSubscription_603714; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603727.validator(path, query, header, formData, body)
  let scheme = call_603727.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603727.url(scheme.get, call_603727.host, call_603727.base,
                         call_603727.route, valid.getOrDefault("path"))
  result = hook(call_603727, url, valid)

proc call*(call_603728: Call_PostDeleteEventSubscription_603714;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603729 = newJObject()
  var formData_603730 = newJObject()
  add(formData_603730, "SubscriptionName", newJString(SubscriptionName))
  add(query_603729, "Action", newJString(Action))
  add(query_603729, "Version", newJString(Version))
  result = call_603728.call(nil, query_603729, nil, formData_603730, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_603714(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_603715, base: "/",
    url: url_PostDeleteEventSubscription_603716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_603698 = ref object of OpenApiRestCall_602417
proc url_GetDeleteEventSubscription_603700(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_603699(path: JsonNode; query: JsonNode;
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
  var valid_603701 = query.getOrDefault("Action")
  valid_603701 = validateParameter(valid_603701, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603701 != nil:
    section.add "Action", valid_603701
  var valid_603702 = query.getOrDefault("SubscriptionName")
  valid_603702 = validateParameter(valid_603702, JString, required = true,
                                 default = nil)
  if valid_603702 != nil:
    section.add "SubscriptionName", valid_603702
  var valid_603703 = query.getOrDefault("Version")
  valid_603703 = validateParameter(valid_603703, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603703 != nil:
    section.add "Version", valid_603703
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603704 = header.getOrDefault("X-Amz-Date")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Date", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Security-Token")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Security-Token", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Content-Sha256", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Algorithm")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Algorithm", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Signature")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Signature", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-SignedHeaders", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Credential")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Credential", valid_603710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603711: Call_GetDeleteEventSubscription_603698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603711.validator(path, query, header, formData, body)
  let scheme = call_603711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603711.url(scheme.get, call_603711.host, call_603711.base,
                         call_603711.route, valid.getOrDefault("path"))
  result = hook(call_603711, url, valid)

proc call*(call_603712: Call_GetDeleteEventSubscription_603698;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603713 = newJObject()
  add(query_603713, "Action", newJString(Action))
  add(query_603713, "SubscriptionName", newJString(SubscriptionName))
  add(query_603713, "Version", newJString(Version))
  result = call_603712.call(nil, query_603713, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_603698(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_603699, base: "/",
    url: url_GetDeleteEventSubscription_603700,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_603747 = ref object of OpenApiRestCall_602417
proc url_PostDeleteOptionGroup_603749(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_603748(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603750 = query.getOrDefault("Action")
  valid_603750 = validateParameter(valid_603750, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603750 != nil:
    section.add "Action", valid_603750
  var valid_603751 = query.getOrDefault("Version")
  valid_603751 = validateParameter(valid_603751, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603751 != nil:
    section.add "Version", valid_603751
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603752 = header.getOrDefault("X-Amz-Date")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Date", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Security-Token")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Security-Token", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Content-Sha256", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-Algorithm")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-Algorithm", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-Signature")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Signature", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-SignedHeaders", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Credential")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Credential", valid_603758
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603759 = formData.getOrDefault("OptionGroupName")
  valid_603759 = validateParameter(valid_603759, JString, required = true,
                                 default = nil)
  if valid_603759 != nil:
    section.add "OptionGroupName", valid_603759
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603760: Call_PostDeleteOptionGroup_603747; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603760.validator(path, query, header, formData, body)
  let scheme = call_603760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603760.url(scheme.get, call_603760.host, call_603760.base,
                         call_603760.route, valid.getOrDefault("path"))
  result = hook(call_603760, url, valid)

proc call*(call_603761: Call_PostDeleteOptionGroup_603747; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603762 = newJObject()
  var formData_603763 = newJObject()
  add(formData_603763, "OptionGroupName", newJString(OptionGroupName))
  add(query_603762, "Action", newJString(Action))
  add(query_603762, "Version", newJString(Version))
  result = call_603761.call(nil, query_603762, nil, formData_603763, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_603747(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_603748, base: "/",
    url: url_PostDeleteOptionGroup_603749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_603731 = ref object of OpenApiRestCall_602417
proc url_GetDeleteOptionGroup_603733(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_603732(path: JsonNode; query: JsonNode;
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
  var valid_603734 = query.getOrDefault("OptionGroupName")
  valid_603734 = validateParameter(valid_603734, JString, required = true,
                                 default = nil)
  if valid_603734 != nil:
    section.add "OptionGroupName", valid_603734
  var valid_603735 = query.getOrDefault("Action")
  valid_603735 = validateParameter(valid_603735, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603735 != nil:
    section.add "Action", valid_603735
  var valid_603736 = query.getOrDefault("Version")
  valid_603736 = validateParameter(valid_603736, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603736 != nil:
    section.add "Version", valid_603736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603737 = header.getOrDefault("X-Amz-Date")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-Date", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Security-Token")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Security-Token", valid_603738
  var valid_603739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Content-Sha256", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Algorithm")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Algorithm", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Signature")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Signature", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-SignedHeaders", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Credential")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Credential", valid_603743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603744: Call_GetDeleteOptionGroup_603731; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603744.validator(path, query, header, formData, body)
  let scheme = call_603744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603744.url(scheme.get, call_603744.host, call_603744.base,
                         call_603744.route, valid.getOrDefault("path"))
  result = hook(call_603744, url, valid)

proc call*(call_603745: Call_GetDeleteOptionGroup_603731; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603746 = newJObject()
  add(query_603746, "OptionGroupName", newJString(OptionGroupName))
  add(query_603746, "Action", newJString(Action))
  add(query_603746, "Version", newJString(Version))
  result = call_603745.call(nil, query_603746, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_603731(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_603732, base: "/",
    url: url_GetDeleteOptionGroup_603733, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603787 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBEngineVersions_603789(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_603788(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603790 = query.getOrDefault("Action")
  valid_603790 = validateParameter(valid_603790, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603790 != nil:
    section.add "Action", valid_603790
  var valid_603791 = query.getOrDefault("Version")
  valid_603791 = validateParameter(valid_603791, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603791 != nil:
    section.add "Version", valid_603791
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603792 = header.getOrDefault("X-Amz-Date")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Date", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Security-Token")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Security-Token", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-Content-Sha256", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Algorithm")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Algorithm", valid_603795
  var valid_603796 = header.getOrDefault("X-Amz-Signature")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "X-Amz-Signature", valid_603796
  var valid_603797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-SignedHeaders", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Credential")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Credential", valid_603798
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
  var valid_603799 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603799 = validateParameter(valid_603799, JBool, required = false, default = nil)
  if valid_603799 != nil:
    section.add "ListSupportedCharacterSets", valid_603799
  var valid_603800 = formData.getOrDefault("Engine")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "Engine", valid_603800
  var valid_603801 = formData.getOrDefault("Marker")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "Marker", valid_603801
  var valid_603802 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "DBParameterGroupFamily", valid_603802
  var valid_603803 = formData.getOrDefault("Filters")
  valid_603803 = validateParameter(valid_603803, JArray, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "Filters", valid_603803
  var valid_603804 = formData.getOrDefault("MaxRecords")
  valid_603804 = validateParameter(valid_603804, JInt, required = false, default = nil)
  if valid_603804 != nil:
    section.add "MaxRecords", valid_603804
  var valid_603805 = formData.getOrDefault("EngineVersion")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "EngineVersion", valid_603805
  var valid_603806 = formData.getOrDefault("DefaultOnly")
  valid_603806 = validateParameter(valid_603806, JBool, required = false, default = nil)
  if valid_603806 != nil:
    section.add "DefaultOnly", valid_603806
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603807: Call_PostDescribeDBEngineVersions_603787; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603807.validator(path, query, header, formData, body)
  let scheme = call_603807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603807.url(scheme.get, call_603807.host, call_603807.base,
                         call_603807.route, valid.getOrDefault("path"))
  result = hook(call_603807, url, valid)

proc call*(call_603808: Call_PostDescribeDBEngineVersions_603787;
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
  var query_603809 = newJObject()
  var formData_603810 = newJObject()
  add(formData_603810, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603810, "Engine", newJString(Engine))
  add(formData_603810, "Marker", newJString(Marker))
  add(query_603809, "Action", newJString(Action))
  add(formData_603810, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_603810.add "Filters", Filters
  add(formData_603810, "MaxRecords", newJInt(MaxRecords))
  add(formData_603810, "EngineVersion", newJString(EngineVersion))
  add(query_603809, "Version", newJString(Version))
  add(formData_603810, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603808.call(nil, query_603809, nil, formData_603810, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603787(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603788, base: "/",
    url: url_PostDescribeDBEngineVersions_603789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603764 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBEngineVersions_603766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_603765(path: JsonNode; query: JsonNode;
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
  var valid_603767 = query.getOrDefault("Engine")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "Engine", valid_603767
  var valid_603768 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603768 = validateParameter(valid_603768, JBool, required = false, default = nil)
  if valid_603768 != nil:
    section.add "ListSupportedCharacterSets", valid_603768
  var valid_603769 = query.getOrDefault("MaxRecords")
  valid_603769 = validateParameter(valid_603769, JInt, required = false, default = nil)
  if valid_603769 != nil:
    section.add "MaxRecords", valid_603769
  var valid_603770 = query.getOrDefault("DBParameterGroupFamily")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "DBParameterGroupFamily", valid_603770
  var valid_603771 = query.getOrDefault("Filters")
  valid_603771 = validateParameter(valid_603771, JArray, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "Filters", valid_603771
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603772 = query.getOrDefault("Action")
  valid_603772 = validateParameter(valid_603772, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603772 != nil:
    section.add "Action", valid_603772
  var valid_603773 = query.getOrDefault("Marker")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "Marker", valid_603773
  var valid_603774 = query.getOrDefault("EngineVersion")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "EngineVersion", valid_603774
  var valid_603775 = query.getOrDefault("DefaultOnly")
  valid_603775 = validateParameter(valid_603775, JBool, required = false, default = nil)
  if valid_603775 != nil:
    section.add "DefaultOnly", valid_603775
  var valid_603776 = query.getOrDefault("Version")
  valid_603776 = validateParameter(valid_603776, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603776 != nil:
    section.add "Version", valid_603776
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603777 = header.getOrDefault("X-Amz-Date")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Date", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Security-Token")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Security-Token", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-Content-Sha256", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Algorithm")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Algorithm", valid_603780
  var valid_603781 = header.getOrDefault("X-Amz-Signature")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "X-Amz-Signature", valid_603781
  var valid_603782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603782 = validateParameter(valid_603782, JString, required = false,
                                 default = nil)
  if valid_603782 != nil:
    section.add "X-Amz-SignedHeaders", valid_603782
  var valid_603783 = header.getOrDefault("X-Amz-Credential")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "X-Amz-Credential", valid_603783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603784: Call_GetDescribeDBEngineVersions_603764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603784.validator(path, query, header, formData, body)
  let scheme = call_603784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603784.url(scheme.get, call_603784.host, call_603784.base,
                         call_603784.route, valid.getOrDefault("path"))
  result = hook(call_603784, url, valid)

proc call*(call_603785: Call_GetDescribeDBEngineVersions_603764;
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
  var query_603786 = newJObject()
  add(query_603786, "Engine", newJString(Engine))
  add(query_603786, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603786, "MaxRecords", newJInt(MaxRecords))
  add(query_603786, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_603786.add "Filters", Filters
  add(query_603786, "Action", newJString(Action))
  add(query_603786, "Marker", newJString(Marker))
  add(query_603786, "EngineVersion", newJString(EngineVersion))
  add(query_603786, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603786, "Version", newJString(Version))
  result = call_603785.call(nil, query_603786, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603764(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603765, base: "/",
    url: url_GetDescribeDBEngineVersions_603766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603830 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBInstances_603832(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_603831(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603833 = query.getOrDefault("Action")
  valid_603833 = validateParameter(valid_603833, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603833 != nil:
    section.add "Action", valid_603833
  var valid_603834 = query.getOrDefault("Version")
  valid_603834 = validateParameter(valid_603834, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603834 != nil:
    section.add "Version", valid_603834
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603835 = header.getOrDefault("X-Amz-Date")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-Date", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Security-Token")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Security-Token", valid_603836
  var valid_603837 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Content-Sha256", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Algorithm")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Algorithm", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Signature")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Signature", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-SignedHeaders", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Credential")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Credential", valid_603841
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603842 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "DBInstanceIdentifier", valid_603842
  var valid_603843 = formData.getOrDefault("Marker")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "Marker", valid_603843
  var valid_603844 = formData.getOrDefault("Filters")
  valid_603844 = validateParameter(valid_603844, JArray, required = false,
                                 default = nil)
  if valid_603844 != nil:
    section.add "Filters", valid_603844
  var valid_603845 = formData.getOrDefault("MaxRecords")
  valid_603845 = validateParameter(valid_603845, JInt, required = false, default = nil)
  if valid_603845 != nil:
    section.add "MaxRecords", valid_603845
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603846: Call_PostDescribeDBInstances_603830; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603846.validator(path, query, header, formData, body)
  let scheme = call_603846.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603846.url(scheme.get, call_603846.host, call_603846.base,
                         call_603846.route, valid.getOrDefault("path"))
  result = hook(call_603846, url, valid)

proc call*(call_603847: Call_PostDescribeDBInstances_603830;
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
  var query_603848 = newJObject()
  var formData_603849 = newJObject()
  add(formData_603849, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603849, "Marker", newJString(Marker))
  add(query_603848, "Action", newJString(Action))
  if Filters != nil:
    formData_603849.add "Filters", Filters
  add(formData_603849, "MaxRecords", newJInt(MaxRecords))
  add(query_603848, "Version", newJString(Version))
  result = call_603847.call(nil, query_603848, nil, formData_603849, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603830(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603831, base: "/",
    url: url_PostDescribeDBInstances_603832, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603811 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBInstances_603813(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_603812(path: JsonNode; query: JsonNode;
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
  var valid_603814 = query.getOrDefault("MaxRecords")
  valid_603814 = validateParameter(valid_603814, JInt, required = false, default = nil)
  if valid_603814 != nil:
    section.add "MaxRecords", valid_603814
  var valid_603815 = query.getOrDefault("Filters")
  valid_603815 = validateParameter(valid_603815, JArray, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "Filters", valid_603815
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603816 = query.getOrDefault("Action")
  valid_603816 = validateParameter(valid_603816, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603816 != nil:
    section.add "Action", valid_603816
  var valid_603817 = query.getOrDefault("Marker")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "Marker", valid_603817
  var valid_603818 = query.getOrDefault("Version")
  valid_603818 = validateParameter(valid_603818, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603818 != nil:
    section.add "Version", valid_603818
  var valid_603819 = query.getOrDefault("DBInstanceIdentifier")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "DBInstanceIdentifier", valid_603819
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603820 = header.getOrDefault("X-Amz-Date")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "X-Amz-Date", valid_603820
  var valid_603821 = header.getOrDefault("X-Amz-Security-Token")
  valid_603821 = validateParameter(valid_603821, JString, required = false,
                                 default = nil)
  if valid_603821 != nil:
    section.add "X-Amz-Security-Token", valid_603821
  var valid_603822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603822 = validateParameter(valid_603822, JString, required = false,
                                 default = nil)
  if valid_603822 != nil:
    section.add "X-Amz-Content-Sha256", valid_603822
  var valid_603823 = header.getOrDefault("X-Amz-Algorithm")
  valid_603823 = validateParameter(valid_603823, JString, required = false,
                                 default = nil)
  if valid_603823 != nil:
    section.add "X-Amz-Algorithm", valid_603823
  var valid_603824 = header.getOrDefault("X-Amz-Signature")
  valid_603824 = validateParameter(valid_603824, JString, required = false,
                                 default = nil)
  if valid_603824 != nil:
    section.add "X-Amz-Signature", valid_603824
  var valid_603825 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603825 = validateParameter(valid_603825, JString, required = false,
                                 default = nil)
  if valid_603825 != nil:
    section.add "X-Amz-SignedHeaders", valid_603825
  var valid_603826 = header.getOrDefault("X-Amz-Credential")
  valid_603826 = validateParameter(valid_603826, JString, required = false,
                                 default = nil)
  if valid_603826 != nil:
    section.add "X-Amz-Credential", valid_603826
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603827: Call_GetDescribeDBInstances_603811; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603827.validator(path, query, header, formData, body)
  let scheme = call_603827.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603827.url(scheme.get, call_603827.host, call_603827.base,
                         call_603827.route, valid.getOrDefault("path"))
  result = hook(call_603827, url, valid)

proc call*(call_603828: Call_GetDescribeDBInstances_603811; MaxRecords: int = 0;
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
  var query_603829 = newJObject()
  add(query_603829, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603829.add "Filters", Filters
  add(query_603829, "Action", newJString(Action))
  add(query_603829, "Marker", newJString(Marker))
  add(query_603829, "Version", newJString(Version))
  add(query_603829, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603828.call(nil, query_603829, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603811(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603812, base: "/",
    url: url_GetDescribeDBInstances_603813, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_603872 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBLogFiles_603874(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_603873(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603875 = query.getOrDefault("Action")
  valid_603875 = validateParameter(valid_603875, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603875 != nil:
    section.add "Action", valid_603875
  var valid_603876 = query.getOrDefault("Version")
  valid_603876 = validateParameter(valid_603876, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603876 != nil:
    section.add "Version", valid_603876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603877 = header.getOrDefault("X-Amz-Date")
  valid_603877 = validateParameter(valid_603877, JString, required = false,
                                 default = nil)
  if valid_603877 != nil:
    section.add "X-Amz-Date", valid_603877
  var valid_603878 = header.getOrDefault("X-Amz-Security-Token")
  valid_603878 = validateParameter(valid_603878, JString, required = false,
                                 default = nil)
  if valid_603878 != nil:
    section.add "X-Amz-Security-Token", valid_603878
  var valid_603879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603879 = validateParameter(valid_603879, JString, required = false,
                                 default = nil)
  if valid_603879 != nil:
    section.add "X-Amz-Content-Sha256", valid_603879
  var valid_603880 = header.getOrDefault("X-Amz-Algorithm")
  valid_603880 = validateParameter(valid_603880, JString, required = false,
                                 default = nil)
  if valid_603880 != nil:
    section.add "X-Amz-Algorithm", valid_603880
  var valid_603881 = header.getOrDefault("X-Amz-Signature")
  valid_603881 = validateParameter(valid_603881, JString, required = false,
                                 default = nil)
  if valid_603881 != nil:
    section.add "X-Amz-Signature", valid_603881
  var valid_603882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-SignedHeaders", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Credential")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Credential", valid_603883
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
  var valid_603884 = formData.getOrDefault("FilenameContains")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "FilenameContains", valid_603884
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603885 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603885 = validateParameter(valid_603885, JString, required = true,
                                 default = nil)
  if valid_603885 != nil:
    section.add "DBInstanceIdentifier", valid_603885
  var valid_603886 = formData.getOrDefault("FileSize")
  valid_603886 = validateParameter(valid_603886, JInt, required = false, default = nil)
  if valid_603886 != nil:
    section.add "FileSize", valid_603886
  var valid_603887 = formData.getOrDefault("Marker")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "Marker", valid_603887
  var valid_603888 = formData.getOrDefault("Filters")
  valid_603888 = validateParameter(valid_603888, JArray, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "Filters", valid_603888
  var valid_603889 = formData.getOrDefault("MaxRecords")
  valid_603889 = validateParameter(valid_603889, JInt, required = false, default = nil)
  if valid_603889 != nil:
    section.add "MaxRecords", valid_603889
  var valid_603890 = formData.getOrDefault("FileLastWritten")
  valid_603890 = validateParameter(valid_603890, JInt, required = false, default = nil)
  if valid_603890 != nil:
    section.add "FileLastWritten", valid_603890
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603891: Call_PostDescribeDBLogFiles_603872; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603891.validator(path, query, header, formData, body)
  let scheme = call_603891.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603891.url(scheme.get, call_603891.host, call_603891.base,
                         call_603891.route, valid.getOrDefault("path"))
  result = hook(call_603891, url, valid)

proc call*(call_603892: Call_PostDescribeDBLogFiles_603872;
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
  var query_603893 = newJObject()
  var formData_603894 = newJObject()
  add(formData_603894, "FilenameContains", newJString(FilenameContains))
  add(formData_603894, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603894, "FileSize", newJInt(FileSize))
  add(formData_603894, "Marker", newJString(Marker))
  add(query_603893, "Action", newJString(Action))
  if Filters != nil:
    formData_603894.add "Filters", Filters
  add(formData_603894, "MaxRecords", newJInt(MaxRecords))
  add(formData_603894, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603893, "Version", newJString(Version))
  result = call_603892.call(nil, query_603893, nil, formData_603894, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_603872(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_603873, base: "/",
    url: url_PostDescribeDBLogFiles_603874, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_603850 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBLogFiles_603852(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_603851(path: JsonNode; query: JsonNode;
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
  var valid_603853 = query.getOrDefault("FileLastWritten")
  valid_603853 = validateParameter(valid_603853, JInt, required = false, default = nil)
  if valid_603853 != nil:
    section.add "FileLastWritten", valid_603853
  var valid_603854 = query.getOrDefault("MaxRecords")
  valid_603854 = validateParameter(valid_603854, JInt, required = false, default = nil)
  if valid_603854 != nil:
    section.add "MaxRecords", valid_603854
  var valid_603855 = query.getOrDefault("FilenameContains")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "FilenameContains", valid_603855
  var valid_603856 = query.getOrDefault("FileSize")
  valid_603856 = validateParameter(valid_603856, JInt, required = false, default = nil)
  if valid_603856 != nil:
    section.add "FileSize", valid_603856
  var valid_603857 = query.getOrDefault("Filters")
  valid_603857 = validateParameter(valid_603857, JArray, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "Filters", valid_603857
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603858 = query.getOrDefault("Action")
  valid_603858 = validateParameter(valid_603858, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603858 != nil:
    section.add "Action", valid_603858
  var valid_603859 = query.getOrDefault("Marker")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "Marker", valid_603859
  var valid_603860 = query.getOrDefault("Version")
  valid_603860 = validateParameter(valid_603860, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603860 != nil:
    section.add "Version", valid_603860
  var valid_603861 = query.getOrDefault("DBInstanceIdentifier")
  valid_603861 = validateParameter(valid_603861, JString, required = true,
                                 default = nil)
  if valid_603861 != nil:
    section.add "DBInstanceIdentifier", valid_603861
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603862 = header.getOrDefault("X-Amz-Date")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "X-Amz-Date", valid_603862
  var valid_603863 = header.getOrDefault("X-Amz-Security-Token")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "X-Amz-Security-Token", valid_603863
  var valid_603864 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603864 = validateParameter(valid_603864, JString, required = false,
                                 default = nil)
  if valid_603864 != nil:
    section.add "X-Amz-Content-Sha256", valid_603864
  var valid_603865 = header.getOrDefault("X-Amz-Algorithm")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "X-Amz-Algorithm", valid_603865
  var valid_603866 = header.getOrDefault("X-Amz-Signature")
  valid_603866 = validateParameter(valid_603866, JString, required = false,
                                 default = nil)
  if valid_603866 != nil:
    section.add "X-Amz-Signature", valid_603866
  var valid_603867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-SignedHeaders", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Credential")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Credential", valid_603868
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603869: Call_GetDescribeDBLogFiles_603850; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603869.validator(path, query, header, formData, body)
  let scheme = call_603869.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603869.url(scheme.get, call_603869.host, call_603869.base,
                         call_603869.route, valid.getOrDefault("path"))
  result = hook(call_603869, url, valid)

proc call*(call_603870: Call_GetDescribeDBLogFiles_603850;
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
  var query_603871 = newJObject()
  add(query_603871, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603871, "MaxRecords", newJInt(MaxRecords))
  add(query_603871, "FilenameContains", newJString(FilenameContains))
  add(query_603871, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_603871.add "Filters", Filters
  add(query_603871, "Action", newJString(Action))
  add(query_603871, "Marker", newJString(Marker))
  add(query_603871, "Version", newJString(Version))
  add(query_603871, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603870.call(nil, query_603871, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_603850(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_603851, base: "/",
    url: url_GetDescribeDBLogFiles_603852, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_603914 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBParameterGroups_603916(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_603915(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603917 = query.getOrDefault("Action")
  valid_603917 = validateParameter(valid_603917, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603917 != nil:
    section.add "Action", valid_603917
  var valid_603918 = query.getOrDefault("Version")
  valid_603918 = validateParameter(valid_603918, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603918 != nil:
    section.add "Version", valid_603918
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603919 = header.getOrDefault("X-Amz-Date")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Date", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-Security-Token")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Security-Token", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Content-Sha256", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Algorithm")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Algorithm", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Signature")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Signature", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-SignedHeaders", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-Credential")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-Credential", valid_603925
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603926 = formData.getOrDefault("DBParameterGroupName")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "DBParameterGroupName", valid_603926
  var valid_603927 = formData.getOrDefault("Marker")
  valid_603927 = validateParameter(valid_603927, JString, required = false,
                                 default = nil)
  if valid_603927 != nil:
    section.add "Marker", valid_603927
  var valid_603928 = formData.getOrDefault("Filters")
  valid_603928 = validateParameter(valid_603928, JArray, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "Filters", valid_603928
  var valid_603929 = formData.getOrDefault("MaxRecords")
  valid_603929 = validateParameter(valid_603929, JInt, required = false, default = nil)
  if valid_603929 != nil:
    section.add "MaxRecords", valid_603929
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603930: Call_PostDescribeDBParameterGroups_603914; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603930.validator(path, query, header, formData, body)
  let scheme = call_603930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603930.url(scheme.get, call_603930.host, call_603930.base,
                         call_603930.route, valid.getOrDefault("path"))
  result = hook(call_603930, url, valid)

proc call*(call_603931: Call_PostDescribeDBParameterGroups_603914;
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
  var query_603932 = newJObject()
  var formData_603933 = newJObject()
  add(formData_603933, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603933, "Marker", newJString(Marker))
  add(query_603932, "Action", newJString(Action))
  if Filters != nil:
    formData_603933.add "Filters", Filters
  add(formData_603933, "MaxRecords", newJInt(MaxRecords))
  add(query_603932, "Version", newJString(Version))
  result = call_603931.call(nil, query_603932, nil, formData_603933, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_603914(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_603915, base: "/",
    url: url_PostDescribeDBParameterGroups_603916,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_603895 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBParameterGroups_603897(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_603896(path: JsonNode; query: JsonNode;
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
  var valid_603898 = query.getOrDefault("MaxRecords")
  valid_603898 = validateParameter(valid_603898, JInt, required = false, default = nil)
  if valid_603898 != nil:
    section.add "MaxRecords", valid_603898
  var valid_603899 = query.getOrDefault("Filters")
  valid_603899 = validateParameter(valid_603899, JArray, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "Filters", valid_603899
  var valid_603900 = query.getOrDefault("DBParameterGroupName")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "DBParameterGroupName", valid_603900
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603901 = query.getOrDefault("Action")
  valid_603901 = validateParameter(valid_603901, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603901 != nil:
    section.add "Action", valid_603901
  var valid_603902 = query.getOrDefault("Marker")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "Marker", valid_603902
  var valid_603903 = query.getOrDefault("Version")
  valid_603903 = validateParameter(valid_603903, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603903 != nil:
    section.add "Version", valid_603903
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603904 = header.getOrDefault("X-Amz-Date")
  valid_603904 = validateParameter(valid_603904, JString, required = false,
                                 default = nil)
  if valid_603904 != nil:
    section.add "X-Amz-Date", valid_603904
  var valid_603905 = header.getOrDefault("X-Amz-Security-Token")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Security-Token", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Content-Sha256", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Algorithm")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Algorithm", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Signature")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Signature", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-SignedHeaders", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-Credential")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-Credential", valid_603910
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603911: Call_GetDescribeDBParameterGroups_603895; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603911.validator(path, query, header, formData, body)
  let scheme = call_603911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603911.url(scheme.get, call_603911.host, call_603911.base,
                         call_603911.route, valid.getOrDefault("path"))
  result = hook(call_603911, url, valid)

proc call*(call_603912: Call_GetDescribeDBParameterGroups_603895;
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
  var query_603913 = newJObject()
  add(query_603913, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603913.add "Filters", Filters
  add(query_603913, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603913, "Action", newJString(Action))
  add(query_603913, "Marker", newJString(Marker))
  add(query_603913, "Version", newJString(Version))
  result = call_603912.call(nil, query_603913, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_603895(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_603896, base: "/",
    url: url_GetDescribeDBParameterGroups_603897,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_603954 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBParameters_603956(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_603955(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603957 = query.getOrDefault("Action")
  valid_603957 = validateParameter(valid_603957, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603957 != nil:
    section.add "Action", valid_603957
  var valid_603958 = query.getOrDefault("Version")
  valid_603958 = validateParameter(valid_603958, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603958 != nil:
    section.add "Version", valid_603958
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603959 = header.getOrDefault("X-Amz-Date")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Date", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Security-Token")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Security-Token", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Content-Sha256", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Algorithm")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Algorithm", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-Signature")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-Signature", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-SignedHeaders", valid_603964
  var valid_603965 = header.getOrDefault("X-Amz-Credential")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "X-Amz-Credential", valid_603965
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603966 = formData.getOrDefault("DBParameterGroupName")
  valid_603966 = validateParameter(valid_603966, JString, required = true,
                                 default = nil)
  if valid_603966 != nil:
    section.add "DBParameterGroupName", valid_603966
  var valid_603967 = formData.getOrDefault("Marker")
  valid_603967 = validateParameter(valid_603967, JString, required = false,
                                 default = nil)
  if valid_603967 != nil:
    section.add "Marker", valid_603967
  var valid_603968 = formData.getOrDefault("Filters")
  valid_603968 = validateParameter(valid_603968, JArray, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "Filters", valid_603968
  var valid_603969 = formData.getOrDefault("MaxRecords")
  valid_603969 = validateParameter(valid_603969, JInt, required = false, default = nil)
  if valid_603969 != nil:
    section.add "MaxRecords", valid_603969
  var valid_603970 = formData.getOrDefault("Source")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "Source", valid_603970
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603971: Call_PostDescribeDBParameters_603954; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603971.validator(path, query, header, formData, body)
  let scheme = call_603971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603971.url(scheme.get, call_603971.host, call_603971.base,
                         call_603971.route, valid.getOrDefault("path"))
  result = hook(call_603971, url, valid)

proc call*(call_603972: Call_PostDescribeDBParameters_603954;
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
  var query_603973 = newJObject()
  var formData_603974 = newJObject()
  add(formData_603974, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603974, "Marker", newJString(Marker))
  add(query_603973, "Action", newJString(Action))
  if Filters != nil:
    formData_603974.add "Filters", Filters
  add(formData_603974, "MaxRecords", newJInt(MaxRecords))
  add(query_603973, "Version", newJString(Version))
  add(formData_603974, "Source", newJString(Source))
  result = call_603972.call(nil, query_603973, nil, formData_603974, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_603954(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_603955, base: "/",
    url: url_PostDescribeDBParameters_603956, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_603934 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBParameters_603936(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_603935(path: JsonNode; query: JsonNode;
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
  var valid_603937 = query.getOrDefault("MaxRecords")
  valid_603937 = validateParameter(valid_603937, JInt, required = false, default = nil)
  if valid_603937 != nil:
    section.add "MaxRecords", valid_603937
  var valid_603938 = query.getOrDefault("Filters")
  valid_603938 = validateParameter(valid_603938, JArray, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "Filters", valid_603938
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_603939 = query.getOrDefault("DBParameterGroupName")
  valid_603939 = validateParameter(valid_603939, JString, required = true,
                                 default = nil)
  if valid_603939 != nil:
    section.add "DBParameterGroupName", valid_603939
  var valid_603940 = query.getOrDefault("Action")
  valid_603940 = validateParameter(valid_603940, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603940 != nil:
    section.add "Action", valid_603940
  var valid_603941 = query.getOrDefault("Marker")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "Marker", valid_603941
  var valid_603942 = query.getOrDefault("Source")
  valid_603942 = validateParameter(valid_603942, JString, required = false,
                                 default = nil)
  if valid_603942 != nil:
    section.add "Source", valid_603942
  var valid_603943 = query.getOrDefault("Version")
  valid_603943 = validateParameter(valid_603943, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603943 != nil:
    section.add "Version", valid_603943
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603944 = header.getOrDefault("X-Amz-Date")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Date", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Security-Token")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Security-Token", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Content-Sha256", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Algorithm")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Algorithm", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-Signature")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-Signature", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-SignedHeaders", valid_603949
  var valid_603950 = header.getOrDefault("X-Amz-Credential")
  valid_603950 = validateParameter(valid_603950, JString, required = false,
                                 default = nil)
  if valid_603950 != nil:
    section.add "X-Amz-Credential", valid_603950
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603951: Call_GetDescribeDBParameters_603934; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603951.validator(path, query, header, formData, body)
  let scheme = call_603951.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603951.url(scheme.get, call_603951.host, call_603951.base,
                         call_603951.route, valid.getOrDefault("path"))
  result = hook(call_603951, url, valid)

proc call*(call_603952: Call_GetDescribeDBParameters_603934;
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
  var query_603953 = newJObject()
  add(query_603953, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_603953.add "Filters", Filters
  add(query_603953, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603953, "Action", newJString(Action))
  add(query_603953, "Marker", newJString(Marker))
  add(query_603953, "Source", newJString(Source))
  add(query_603953, "Version", newJString(Version))
  result = call_603952.call(nil, query_603953, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_603934(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_603935, base: "/",
    url: url_GetDescribeDBParameters_603936, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_603994 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSecurityGroups_603996(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_603995(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603997 = query.getOrDefault("Action")
  valid_603997 = validateParameter(valid_603997, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603997 != nil:
    section.add "Action", valid_603997
  var valid_603998 = query.getOrDefault("Version")
  valid_603998 = validateParameter(valid_603998, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603998 != nil:
    section.add "Version", valid_603998
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603999 = header.getOrDefault("X-Amz-Date")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Date", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Security-Token")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Security-Token", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Content-Sha256", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-Algorithm")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-Algorithm", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Signature")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Signature", valid_604003
  var valid_604004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "X-Amz-SignedHeaders", valid_604004
  var valid_604005 = header.getOrDefault("X-Amz-Credential")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "X-Amz-Credential", valid_604005
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604006 = formData.getOrDefault("DBSecurityGroupName")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "DBSecurityGroupName", valid_604006
  var valid_604007 = formData.getOrDefault("Marker")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "Marker", valid_604007
  var valid_604008 = formData.getOrDefault("Filters")
  valid_604008 = validateParameter(valid_604008, JArray, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "Filters", valid_604008
  var valid_604009 = formData.getOrDefault("MaxRecords")
  valid_604009 = validateParameter(valid_604009, JInt, required = false, default = nil)
  if valid_604009 != nil:
    section.add "MaxRecords", valid_604009
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604010: Call_PostDescribeDBSecurityGroups_603994; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604010.validator(path, query, header, formData, body)
  let scheme = call_604010.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604010.url(scheme.get, call_604010.host, call_604010.base,
                         call_604010.route, valid.getOrDefault("path"))
  result = hook(call_604010, url, valid)

proc call*(call_604011: Call_PostDescribeDBSecurityGroups_603994;
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
  var query_604012 = newJObject()
  var formData_604013 = newJObject()
  add(formData_604013, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_604013, "Marker", newJString(Marker))
  add(query_604012, "Action", newJString(Action))
  if Filters != nil:
    formData_604013.add "Filters", Filters
  add(formData_604013, "MaxRecords", newJInt(MaxRecords))
  add(query_604012, "Version", newJString(Version))
  result = call_604011.call(nil, query_604012, nil, formData_604013, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_603994(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_603995, base: "/",
    url: url_PostDescribeDBSecurityGroups_603996,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_603975 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSecurityGroups_603977(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_603976(path: JsonNode; query: JsonNode;
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
  var valid_603978 = query.getOrDefault("MaxRecords")
  valid_603978 = validateParameter(valid_603978, JInt, required = false, default = nil)
  if valid_603978 != nil:
    section.add "MaxRecords", valid_603978
  var valid_603979 = query.getOrDefault("DBSecurityGroupName")
  valid_603979 = validateParameter(valid_603979, JString, required = false,
                                 default = nil)
  if valid_603979 != nil:
    section.add "DBSecurityGroupName", valid_603979
  var valid_603980 = query.getOrDefault("Filters")
  valid_603980 = validateParameter(valid_603980, JArray, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "Filters", valid_603980
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603981 = query.getOrDefault("Action")
  valid_603981 = validateParameter(valid_603981, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603981 != nil:
    section.add "Action", valid_603981
  var valid_603982 = query.getOrDefault("Marker")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "Marker", valid_603982
  var valid_603983 = query.getOrDefault("Version")
  valid_603983 = validateParameter(valid_603983, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_603983 != nil:
    section.add "Version", valid_603983
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603984 = header.getOrDefault("X-Amz-Date")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Date", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Security-Token")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Security-Token", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Content-Sha256", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-Algorithm")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-Algorithm", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Signature")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Signature", valid_603988
  var valid_603989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603989 = validateParameter(valid_603989, JString, required = false,
                                 default = nil)
  if valid_603989 != nil:
    section.add "X-Amz-SignedHeaders", valid_603989
  var valid_603990 = header.getOrDefault("X-Amz-Credential")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "X-Amz-Credential", valid_603990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603991: Call_GetDescribeDBSecurityGroups_603975; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603991.validator(path, query, header, formData, body)
  let scheme = call_603991.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603991.url(scheme.get, call_603991.host, call_603991.base,
                         call_603991.route, valid.getOrDefault("path"))
  result = hook(call_603991, url, valid)

proc call*(call_603992: Call_GetDescribeDBSecurityGroups_603975;
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
  var query_603993 = newJObject()
  add(query_603993, "MaxRecords", newJInt(MaxRecords))
  add(query_603993, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_603993.add "Filters", Filters
  add(query_603993, "Action", newJString(Action))
  add(query_603993, "Marker", newJString(Marker))
  add(query_603993, "Version", newJString(Version))
  result = call_603992.call(nil, query_603993, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_603975(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_603976, base: "/",
    url: url_GetDescribeDBSecurityGroups_603977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_604035 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSnapshots_604037(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_604036(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604038 = query.getOrDefault("Action")
  valid_604038 = validateParameter(valid_604038, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604038 != nil:
    section.add "Action", valid_604038
  var valid_604039 = query.getOrDefault("Version")
  valid_604039 = validateParameter(valid_604039, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604039 != nil:
    section.add "Version", valid_604039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604040 = header.getOrDefault("X-Amz-Date")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Date", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-Security-Token")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-Security-Token", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Content-Sha256", valid_604042
  var valid_604043 = header.getOrDefault("X-Amz-Algorithm")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "X-Amz-Algorithm", valid_604043
  var valid_604044 = header.getOrDefault("X-Amz-Signature")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "X-Amz-Signature", valid_604044
  var valid_604045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604045 = validateParameter(valid_604045, JString, required = false,
                                 default = nil)
  if valid_604045 != nil:
    section.add "X-Amz-SignedHeaders", valid_604045
  var valid_604046 = header.getOrDefault("X-Amz-Credential")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Credential", valid_604046
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604047 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "DBInstanceIdentifier", valid_604047
  var valid_604048 = formData.getOrDefault("SnapshotType")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "SnapshotType", valid_604048
  var valid_604049 = formData.getOrDefault("Marker")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "Marker", valid_604049
  var valid_604050 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "DBSnapshotIdentifier", valid_604050
  var valid_604051 = formData.getOrDefault("Filters")
  valid_604051 = validateParameter(valid_604051, JArray, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "Filters", valid_604051
  var valid_604052 = formData.getOrDefault("MaxRecords")
  valid_604052 = validateParameter(valid_604052, JInt, required = false, default = nil)
  if valid_604052 != nil:
    section.add "MaxRecords", valid_604052
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604053: Call_PostDescribeDBSnapshots_604035; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604053.validator(path, query, header, formData, body)
  let scheme = call_604053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604053.url(scheme.get, call_604053.host, call_604053.base,
                         call_604053.route, valid.getOrDefault("path"))
  result = hook(call_604053, url, valid)

proc call*(call_604054: Call_PostDescribeDBSnapshots_604035;
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
  var query_604055 = newJObject()
  var formData_604056 = newJObject()
  add(formData_604056, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604056, "SnapshotType", newJString(SnapshotType))
  add(formData_604056, "Marker", newJString(Marker))
  add(formData_604056, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604055, "Action", newJString(Action))
  if Filters != nil:
    formData_604056.add "Filters", Filters
  add(formData_604056, "MaxRecords", newJInt(MaxRecords))
  add(query_604055, "Version", newJString(Version))
  result = call_604054.call(nil, query_604055, nil, formData_604056, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_604035(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_604036, base: "/",
    url: url_PostDescribeDBSnapshots_604037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_604014 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSnapshots_604016(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_604015(path: JsonNode; query: JsonNode;
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
  var valid_604017 = query.getOrDefault("MaxRecords")
  valid_604017 = validateParameter(valid_604017, JInt, required = false, default = nil)
  if valid_604017 != nil:
    section.add "MaxRecords", valid_604017
  var valid_604018 = query.getOrDefault("Filters")
  valid_604018 = validateParameter(valid_604018, JArray, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "Filters", valid_604018
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604019 = query.getOrDefault("Action")
  valid_604019 = validateParameter(valid_604019, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604019 != nil:
    section.add "Action", valid_604019
  var valid_604020 = query.getOrDefault("Marker")
  valid_604020 = validateParameter(valid_604020, JString, required = false,
                                 default = nil)
  if valid_604020 != nil:
    section.add "Marker", valid_604020
  var valid_604021 = query.getOrDefault("SnapshotType")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "SnapshotType", valid_604021
  var valid_604022 = query.getOrDefault("Version")
  valid_604022 = validateParameter(valid_604022, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604022 != nil:
    section.add "Version", valid_604022
  var valid_604023 = query.getOrDefault("DBInstanceIdentifier")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "DBInstanceIdentifier", valid_604023
  var valid_604024 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "DBSnapshotIdentifier", valid_604024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604025 = header.getOrDefault("X-Amz-Date")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Date", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-Security-Token")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-Security-Token", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Content-Sha256", valid_604027
  var valid_604028 = header.getOrDefault("X-Amz-Algorithm")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "X-Amz-Algorithm", valid_604028
  var valid_604029 = header.getOrDefault("X-Amz-Signature")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "X-Amz-Signature", valid_604029
  var valid_604030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604030 = validateParameter(valid_604030, JString, required = false,
                                 default = nil)
  if valid_604030 != nil:
    section.add "X-Amz-SignedHeaders", valid_604030
  var valid_604031 = header.getOrDefault("X-Amz-Credential")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Credential", valid_604031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604032: Call_GetDescribeDBSnapshots_604014; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604032.validator(path, query, header, formData, body)
  let scheme = call_604032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604032.url(scheme.get, call_604032.host, call_604032.base,
                         call_604032.route, valid.getOrDefault("path"))
  result = hook(call_604032, url, valid)

proc call*(call_604033: Call_GetDescribeDBSnapshots_604014; MaxRecords: int = 0;
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
  var query_604034 = newJObject()
  add(query_604034, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604034.add "Filters", Filters
  add(query_604034, "Action", newJString(Action))
  add(query_604034, "Marker", newJString(Marker))
  add(query_604034, "SnapshotType", newJString(SnapshotType))
  add(query_604034, "Version", newJString(Version))
  add(query_604034, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604034, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604033.call(nil, query_604034, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_604014(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_604015, base: "/",
    url: url_GetDescribeDBSnapshots_604016, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_604076 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSubnetGroups_604078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_604077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604079 = query.getOrDefault("Action")
  valid_604079 = validateParameter(valid_604079, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604079 != nil:
    section.add "Action", valid_604079
  var valid_604080 = query.getOrDefault("Version")
  valid_604080 = validateParameter(valid_604080, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604080 != nil:
    section.add "Version", valid_604080
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604081 = header.getOrDefault("X-Amz-Date")
  valid_604081 = validateParameter(valid_604081, JString, required = false,
                                 default = nil)
  if valid_604081 != nil:
    section.add "X-Amz-Date", valid_604081
  var valid_604082 = header.getOrDefault("X-Amz-Security-Token")
  valid_604082 = validateParameter(valid_604082, JString, required = false,
                                 default = nil)
  if valid_604082 != nil:
    section.add "X-Amz-Security-Token", valid_604082
  var valid_604083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Content-Sha256", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Algorithm")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Algorithm", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Signature")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Signature", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-SignedHeaders", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Credential")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Credential", valid_604087
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604088 = formData.getOrDefault("DBSubnetGroupName")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "DBSubnetGroupName", valid_604088
  var valid_604089 = formData.getOrDefault("Marker")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "Marker", valid_604089
  var valid_604090 = formData.getOrDefault("Filters")
  valid_604090 = validateParameter(valid_604090, JArray, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "Filters", valid_604090
  var valid_604091 = formData.getOrDefault("MaxRecords")
  valid_604091 = validateParameter(valid_604091, JInt, required = false, default = nil)
  if valid_604091 != nil:
    section.add "MaxRecords", valid_604091
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604092: Call_PostDescribeDBSubnetGroups_604076; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604092.validator(path, query, header, formData, body)
  let scheme = call_604092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604092.url(scheme.get, call_604092.host, call_604092.base,
                         call_604092.route, valid.getOrDefault("path"))
  result = hook(call_604092, url, valid)

proc call*(call_604093: Call_PostDescribeDBSubnetGroups_604076;
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
  var query_604094 = newJObject()
  var formData_604095 = newJObject()
  add(formData_604095, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604095, "Marker", newJString(Marker))
  add(query_604094, "Action", newJString(Action))
  if Filters != nil:
    formData_604095.add "Filters", Filters
  add(formData_604095, "MaxRecords", newJInt(MaxRecords))
  add(query_604094, "Version", newJString(Version))
  result = call_604093.call(nil, query_604094, nil, formData_604095, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_604076(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_604077, base: "/",
    url: url_PostDescribeDBSubnetGroups_604078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_604057 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSubnetGroups_604059(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_604058(path: JsonNode; query: JsonNode;
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
  var valid_604060 = query.getOrDefault("MaxRecords")
  valid_604060 = validateParameter(valid_604060, JInt, required = false, default = nil)
  if valid_604060 != nil:
    section.add "MaxRecords", valid_604060
  var valid_604061 = query.getOrDefault("Filters")
  valid_604061 = validateParameter(valid_604061, JArray, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "Filters", valid_604061
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604062 = query.getOrDefault("Action")
  valid_604062 = validateParameter(valid_604062, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604062 != nil:
    section.add "Action", valid_604062
  var valid_604063 = query.getOrDefault("Marker")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "Marker", valid_604063
  var valid_604064 = query.getOrDefault("DBSubnetGroupName")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "DBSubnetGroupName", valid_604064
  var valid_604065 = query.getOrDefault("Version")
  valid_604065 = validateParameter(valid_604065, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604065 != nil:
    section.add "Version", valid_604065
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604066 = header.getOrDefault("X-Amz-Date")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "X-Amz-Date", valid_604066
  var valid_604067 = header.getOrDefault("X-Amz-Security-Token")
  valid_604067 = validateParameter(valid_604067, JString, required = false,
                                 default = nil)
  if valid_604067 != nil:
    section.add "X-Amz-Security-Token", valid_604067
  var valid_604068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-Content-Sha256", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Algorithm")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Algorithm", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Signature")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Signature", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-SignedHeaders", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Credential")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Credential", valid_604072
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604073: Call_GetDescribeDBSubnetGroups_604057; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604073.validator(path, query, header, formData, body)
  let scheme = call_604073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604073.url(scheme.get, call_604073.host, call_604073.base,
                         call_604073.route, valid.getOrDefault("path"))
  result = hook(call_604073, url, valid)

proc call*(call_604074: Call_GetDescribeDBSubnetGroups_604057; MaxRecords: int = 0;
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
  var query_604075 = newJObject()
  add(query_604075, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604075.add "Filters", Filters
  add(query_604075, "Action", newJString(Action))
  add(query_604075, "Marker", newJString(Marker))
  add(query_604075, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604075, "Version", newJString(Version))
  result = call_604074.call(nil, query_604075, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_604057(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_604058, base: "/",
    url: url_GetDescribeDBSubnetGroups_604059,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_604115 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEngineDefaultParameters_604117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_604116(path: JsonNode;
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
  var valid_604118 = query.getOrDefault("Action")
  valid_604118 = validateParameter(valid_604118, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604118 != nil:
    section.add "Action", valid_604118
  var valid_604119 = query.getOrDefault("Version")
  valid_604119 = validateParameter(valid_604119, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604119 != nil:
    section.add "Version", valid_604119
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604120 = header.getOrDefault("X-Amz-Date")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Date", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Security-Token")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Security-Token", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Content-Sha256", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-Algorithm")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-Algorithm", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Signature")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Signature", valid_604124
  var valid_604125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "X-Amz-SignedHeaders", valid_604125
  var valid_604126 = header.getOrDefault("X-Amz-Credential")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "X-Amz-Credential", valid_604126
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604127 = formData.getOrDefault("Marker")
  valid_604127 = validateParameter(valid_604127, JString, required = false,
                                 default = nil)
  if valid_604127 != nil:
    section.add "Marker", valid_604127
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604128 = formData.getOrDefault("DBParameterGroupFamily")
  valid_604128 = validateParameter(valid_604128, JString, required = true,
                                 default = nil)
  if valid_604128 != nil:
    section.add "DBParameterGroupFamily", valid_604128
  var valid_604129 = formData.getOrDefault("Filters")
  valid_604129 = validateParameter(valid_604129, JArray, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "Filters", valid_604129
  var valid_604130 = formData.getOrDefault("MaxRecords")
  valid_604130 = validateParameter(valid_604130, JInt, required = false, default = nil)
  if valid_604130 != nil:
    section.add "MaxRecords", valid_604130
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604131: Call_PostDescribeEngineDefaultParameters_604115;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604131.validator(path, query, header, formData, body)
  let scheme = call_604131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604131.url(scheme.get, call_604131.host, call_604131.base,
                         call_604131.route, valid.getOrDefault("path"))
  result = hook(call_604131, url, valid)

proc call*(call_604132: Call_PostDescribeEngineDefaultParameters_604115;
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
  var query_604133 = newJObject()
  var formData_604134 = newJObject()
  add(formData_604134, "Marker", newJString(Marker))
  add(query_604133, "Action", newJString(Action))
  add(formData_604134, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_604134.add "Filters", Filters
  add(formData_604134, "MaxRecords", newJInt(MaxRecords))
  add(query_604133, "Version", newJString(Version))
  result = call_604132.call(nil, query_604133, nil, formData_604134, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_604115(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_604116, base: "/",
    url: url_PostDescribeEngineDefaultParameters_604117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_604096 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEngineDefaultParameters_604098(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_604097(path: JsonNode;
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
  var valid_604099 = query.getOrDefault("MaxRecords")
  valid_604099 = validateParameter(valid_604099, JInt, required = false, default = nil)
  if valid_604099 != nil:
    section.add "MaxRecords", valid_604099
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604100 = query.getOrDefault("DBParameterGroupFamily")
  valid_604100 = validateParameter(valid_604100, JString, required = true,
                                 default = nil)
  if valid_604100 != nil:
    section.add "DBParameterGroupFamily", valid_604100
  var valid_604101 = query.getOrDefault("Filters")
  valid_604101 = validateParameter(valid_604101, JArray, required = false,
                                 default = nil)
  if valid_604101 != nil:
    section.add "Filters", valid_604101
  var valid_604102 = query.getOrDefault("Action")
  valid_604102 = validateParameter(valid_604102, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604102 != nil:
    section.add "Action", valid_604102
  var valid_604103 = query.getOrDefault("Marker")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "Marker", valid_604103
  var valid_604104 = query.getOrDefault("Version")
  valid_604104 = validateParameter(valid_604104, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604104 != nil:
    section.add "Version", valid_604104
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604105 = header.getOrDefault("X-Amz-Date")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Date", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Security-Token")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Security-Token", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Content-Sha256", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-Algorithm")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Algorithm", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Signature")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Signature", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-SignedHeaders", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Credential")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Credential", valid_604111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604112: Call_GetDescribeEngineDefaultParameters_604096;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604112.validator(path, query, header, formData, body)
  let scheme = call_604112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604112.url(scheme.get, call_604112.host, call_604112.base,
                         call_604112.route, valid.getOrDefault("path"))
  result = hook(call_604112, url, valid)

proc call*(call_604113: Call_GetDescribeEngineDefaultParameters_604096;
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
  var query_604114 = newJObject()
  add(query_604114, "MaxRecords", newJInt(MaxRecords))
  add(query_604114, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_604114.add "Filters", Filters
  add(query_604114, "Action", newJString(Action))
  add(query_604114, "Marker", newJString(Marker))
  add(query_604114, "Version", newJString(Version))
  result = call_604113.call(nil, query_604114, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_604096(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_604097, base: "/",
    url: url_GetDescribeEngineDefaultParameters_604098,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604152 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEventCategories_604154(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_604153(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604155 = query.getOrDefault("Action")
  valid_604155 = validateParameter(valid_604155, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604155 != nil:
    section.add "Action", valid_604155
  var valid_604156 = query.getOrDefault("Version")
  valid_604156 = validateParameter(valid_604156, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604156 != nil:
    section.add "Version", valid_604156
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604157 = header.getOrDefault("X-Amz-Date")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Date", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-Security-Token")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-Security-Token", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Content-Sha256", valid_604159
  var valid_604160 = header.getOrDefault("X-Amz-Algorithm")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "X-Amz-Algorithm", valid_604160
  var valid_604161 = header.getOrDefault("X-Amz-Signature")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "X-Amz-Signature", valid_604161
  var valid_604162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "X-Amz-SignedHeaders", valid_604162
  var valid_604163 = header.getOrDefault("X-Amz-Credential")
  valid_604163 = validateParameter(valid_604163, JString, required = false,
                                 default = nil)
  if valid_604163 != nil:
    section.add "X-Amz-Credential", valid_604163
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_604164 = formData.getOrDefault("Filters")
  valid_604164 = validateParameter(valid_604164, JArray, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "Filters", valid_604164
  var valid_604165 = formData.getOrDefault("SourceType")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "SourceType", valid_604165
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604166: Call_PostDescribeEventCategories_604152; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604166.validator(path, query, header, formData, body)
  let scheme = call_604166.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604166.url(scheme.get, call_604166.host, call_604166.base,
                         call_604166.route, valid.getOrDefault("path"))
  result = hook(call_604166, url, valid)

proc call*(call_604167: Call_PostDescribeEventCategories_604152;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_604168 = newJObject()
  var formData_604169 = newJObject()
  add(query_604168, "Action", newJString(Action))
  if Filters != nil:
    formData_604169.add "Filters", Filters
  add(query_604168, "Version", newJString(Version))
  add(formData_604169, "SourceType", newJString(SourceType))
  result = call_604167.call(nil, query_604168, nil, formData_604169, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604152(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604153, base: "/",
    url: url_PostDescribeEventCategories_604154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604135 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEventCategories_604137(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_604136(path: JsonNode; query: JsonNode;
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
  var valid_604138 = query.getOrDefault("SourceType")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "SourceType", valid_604138
  var valid_604139 = query.getOrDefault("Filters")
  valid_604139 = validateParameter(valid_604139, JArray, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "Filters", valid_604139
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604140 = query.getOrDefault("Action")
  valid_604140 = validateParameter(valid_604140, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604140 != nil:
    section.add "Action", valid_604140
  var valid_604141 = query.getOrDefault("Version")
  valid_604141 = validateParameter(valid_604141, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604141 != nil:
    section.add "Version", valid_604141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604142 = header.getOrDefault("X-Amz-Date")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Date", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-Security-Token")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Security-Token", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Content-Sha256", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Algorithm")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Algorithm", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Signature")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Signature", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-SignedHeaders", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-Credential")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-Credential", valid_604148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604149: Call_GetDescribeEventCategories_604135; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604149.validator(path, query, header, formData, body)
  let scheme = call_604149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604149.url(scheme.get, call_604149.host, call_604149.base,
                         call_604149.route, valid.getOrDefault("path"))
  result = hook(call_604149, url, valid)

proc call*(call_604150: Call_GetDescribeEventCategories_604135;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604151 = newJObject()
  add(query_604151, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_604151.add "Filters", Filters
  add(query_604151, "Action", newJString(Action))
  add(query_604151, "Version", newJString(Version))
  result = call_604150.call(nil, query_604151, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604135(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604136, base: "/",
    url: url_GetDescribeEventCategories_604137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_604189 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEventSubscriptions_604191(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_604190(path: JsonNode;
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
  var valid_604192 = query.getOrDefault("Action")
  valid_604192 = validateParameter(valid_604192, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604192 != nil:
    section.add "Action", valid_604192
  var valid_604193 = query.getOrDefault("Version")
  valid_604193 = validateParameter(valid_604193, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604193 != nil:
    section.add "Version", valid_604193
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604194 = header.getOrDefault("X-Amz-Date")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "X-Amz-Date", valid_604194
  var valid_604195 = header.getOrDefault("X-Amz-Security-Token")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Security-Token", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Content-Sha256", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Algorithm")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Algorithm", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Signature")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Signature", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-SignedHeaders", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-Credential")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-Credential", valid_604200
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604201 = formData.getOrDefault("Marker")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "Marker", valid_604201
  var valid_604202 = formData.getOrDefault("SubscriptionName")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "SubscriptionName", valid_604202
  var valid_604203 = formData.getOrDefault("Filters")
  valid_604203 = validateParameter(valid_604203, JArray, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "Filters", valid_604203
  var valid_604204 = formData.getOrDefault("MaxRecords")
  valid_604204 = validateParameter(valid_604204, JInt, required = false, default = nil)
  if valid_604204 != nil:
    section.add "MaxRecords", valid_604204
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604205: Call_PostDescribeEventSubscriptions_604189; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604205.validator(path, query, header, formData, body)
  let scheme = call_604205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604205.url(scheme.get, call_604205.host, call_604205.base,
                         call_604205.route, valid.getOrDefault("path"))
  result = hook(call_604205, url, valid)

proc call*(call_604206: Call_PostDescribeEventSubscriptions_604189;
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
  var query_604207 = newJObject()
  var formData_604208 = newJObject()
  add(formData_604208, "Marker", newJString(Marker))
  add(formData_604208, "SubscriptionName", newJString(SubscriptionName))
  add(query_604207, "Action", newJString(Action))
  if Filters != nil:
    formData_604208.add "Filters", Filters
  add(formData_604208, "MaxRecords", newJInt(MaxRecords))
  add(query_604207, "Version", newJString(Version))
  result = call_604206.call(nil, query_604207, nil, formData_604208, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_604189(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_604190, base: "/",
    url: url_PostDescribeEventSubscriptions_604191,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_604170 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEventSubscriptions_604172(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_604171(path: JsonNode; query: JsonNode;
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
  var valid_604173 = query.getOrDefault("MaxRecords")
  valid_604173 = validateParameter(valid_604173, JInt, required = false, default = nil)
  if valid_604173 != nil:
    section.add "MaxRecords", valid_604173
  var valid_604174 = query.getOrDefault("Filters")
  valid_604174 = validateParameter(valid_604174, JArray, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "Filters", valid_604174
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604175 = query.getOrDefault("Action")
  valid_604175 = validateParameter(valid_604175, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604175 != nil:
    section.add "Action", valid_604175
  var valid_604176 = query.getOrDefault("Marker")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "Marker", valid_604176
  var valid_604177 = query.getOrDefault("SubscriptionName")
  valid_604177 = validateParameter(valid_604177, JString, required = false,
                                 default = nil)
  if valid_604177 != nil:
    section.add "SubscriptionName", valid_604177
  var valid_604178 = query.getOrDefault("Version")
  valid_604178 = validateParameter(valid_604178, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604178 != nil:
    section.add "Version", valid_604178
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604179 = header.getOrDefault("X-Amz-Date")
  valid_604179 = validateParameter(valid_604179, JString, required = false,
                                 default = nil)
  if valid_604179 != nil:
    section.add "X-Amz-Date", valid_604179
  var valid_604180 = header.getOrDefault("X-Amz-Security-Token")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Security-Token", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Content-Sha256", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Algorithm")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Algorithm", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Signature")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Signature", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-SignedHeaders", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-Credential")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Credential", valid_604185
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604186: Call_GetDescribeEventSubscriptions_604170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604186.validator(path, query, header, formData, body)
  let scheme = call_604186.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604186.url(scheme.get, call_604186.host, call_604186.base,
                         call_604186.route, valid.getOrDefault("path"))
  result = hook(call_604186, url, valid)

proc call*(call_604187: Call_GetDescribeEventSubscriptions_604170;
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
  var query_604188 = newJObject()
  add(query_604188, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604188.add "Filters", Filters
  add(query_604188, "Action", newJString(Action))
  add(query_604188, "Marker", newJString(Marker))
  add(query_604188, "SubscriptionName", newJString(SubscriptionName))
  add(query_604188, "Version", newJString(Version))
  result = call_604187.call(nil, query_604188, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_604170(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_604171, base: "/",
    url: url_GetDescribeEventSubscriptions_604172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604233 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEvents_604235(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_604234(path: JsonNode; query: JsonNode;
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
  var valid_604236 = query.getOrDefault("Action")
  valid_604236 = validateParameter(valid_604236, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604236 != nil:
    section.add "Action", valid_604236
  var valid_604237 = query.getOrDefault("Version")
  valid_604237 = validateParameter(valid_604237, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604237 != nil:
    section.add "Version", valid_604237
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604238 = header.getOrDefault("X-Amz-Date")
  valid_604238 = validateParameter(valid_604238, JString, required = false,
                                 default = nil)
  if valid_604238 != nil:
    section.add "X-Amz-Date", valid_604238
  var valid_604239 = header.getOrDefault("X-Amz-Security-Token")
  valid_604239 = validateParameter(valid_604239, JString, required = false,
                                 default = nil)
  if valid_604239 != nil:
    section.add "X-Amz-Security-Token", valid_604239
  var valid_604240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604240 = validateParameter(valid_604240, JString, required = false,
                                 default = nil)
  if valid_604240 != nil:
    section.add "X-Amz-Content-Sha256", valid_604240
  var valid_604241 = header.getOrDefault("X-Amz-Algorithm")
  valid_604241 = validateParameter(valid_604241, JString, required = false,
                                 default = nil)
  if valid_604241 != nil:
    section.add "X-Amz-Algorithm", valid_604241
  var valid_604242 = header.getOrDefault("X-Amz-Signature")
  valid_604242 = validateParameter(valid_604242, JString, required = false,
                                 default = nil)
  if valid_604242 != nil:
    section.add "X-Amz-Signature", valid_604242
  var valid_604243 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604243 = validateParameter(valid_604243, JString, required = false,
                                 default = nil)
  if valid_604243 != nil:
    section.add "X-Amz-SignedHeaders", valid_604243
  var valid_604244 = header.getOrDefault("X-Amz-Credential")
  valid_604244 = validateParameter(valid_604244, JString, required = false,
                                 default = nil)
  if valid_604244 != nil:
    section.add "X-Amz-Credential", valid_604244
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
  var valid_604245 = formData.getOrDefault("SourceIdentifier")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "SourceIdentifier", valid_604245
  var valid_604246 = formData.getOrDefault("EventCategories")
  valid_604246 = validateParameter(valid_604246, JArray, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "EventCategories", valid_604246
  var valid_604247 = formData.getOrDefault("Marker")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "Marker", valid_604247
  var valid_604248 = formData.getOrDefault("StartTime")
  valid_604248 = validateParameter(valid_604248, JString, required = false,
                                 default = nil)
  if valid_604248 != nil:
    section.add "StartTime", valid_604248
  var valid_604249 = formData.getOrDefault("Duration")
  valid_604249 = validateParameter(valid_604249, JInt, required = false, default = nil)
  if valid_604249 != nil:
    section.add "Duration", valid_604249
  var valid_604250 = formData.getOrDefault("Filters")
  valid_604250 = validateParameter(valid_604250, JArray, required = false,
                                 default = nil)
  if valid_604250 != nil:
    section.add "Filters", valid_604250
  var valid_604251 = formData.getOrDefault("EndTime")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "EndTime", valid_604251
  var valid_604252 = formData.getOrDefault("MaxRecords")
  valid_604252 = validateParameter(valid_604252, JInt, required = false, default = nil)
  if valid_604252 != nil:
    section.add "MaxRecords", valid_604252
  var valid_604253 = formData.getOrDefault("SourceType")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604253 != nil:
    section.add "SourceType", valid_604253
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604254: Call_PostDescribeEvents_604233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604254.validator(path, query, header, formData, body)
  let scheme = call_604254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604254.url(scheme.get, call_604254.host, call_604254.base,
                         call_604254.route, valid.getOrDefault("path"))
  result = hook(call_604254, url, valid)

proc call*(call_604255: Call_PostDescribeEvents_604233;
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
  var query_604256 = newJObject()
  var formData_604257 = newJObject()
  add(formData_604257, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604257.add "EventCategories", EventCategories
  add(formData_604257, "Marker", newJString(Marker))
  add(formData_604257, "StartTime", newJString(StartTime))
  add(query_604256, "Action", newJString(Action))
  add(formData_604257, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_604257.add "Filters", Filters
  add(formData_604257, "EndTime", newJString(EndTime))
  add(formData_604257, "MaxRecords", newJInt(MaxRecords))
  add(query_604256, "Version", newJString(Version))
  add(formData_604257, "SourceType", newJString(SourceType))
  result = call_604255.call(nil, query_604256, nil, formData_604257, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604233(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604234, base: "/",
    url: url_PostDescribeEvents_604235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604209 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEvents_604211(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_604210(path: JsonNode; query: JsonNode;
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
  var valid_604212 = query.getOrDefault("SourceType")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604212 != nil:
    section.add "SourceType", valid_604212
  var valid_604213 = query.getOrDefault("MaxRecords")
  valid_604213 = validateParameter(valid_604213, JInt, required = false, default = nil)
  if valid_604213 != nil:
    section.add "MaxRecords", valid_604213
  var valid_604214 = query.getOrDefault("StartTime")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "StartTime", valid_604214
  var valid_604215 = query.getOrDefault("Filters")
  valid_604215 = validateParameter(valid_604215, JArray, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "Filters", valid_604215
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604216 = query.getOrDefault("Action")
  valid_604216 = validateParameter(valid_604216, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604216 != nil:
    section.add "Action", valid_604216
  var valid_604217 = query.getOrDefault("SourceIdentifier")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "SourceIdentifier", valid_604217
  var valid_604218 = query.getOrDefault("Marker")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "Marker", valid_604218
  var valid_604219 = query.getOrDefault("EventCategories")
  valid_604219 = validateParameter(valid_604219, JArray, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "EventCategories", valid_604219
  var valid_604220 = query.getOrDefault("Duration")
  valid_604220 = validateParameter(valid_604220, JInt, required = false, default = nil)
  if valid_604220 != nil:
    section.add "Duration", valid_604220
  var valid_604221 = query.getOrDefault("EndTime")
  valid_604221 = validateParameter(valid_604221, JString, required = false,
                                 default = nil)
  if valid_604221 != nil:
    section.add "EndTime", valid_604221
  var valid_604222 = query.getOrDefault("Version")
  valid_604222 = validateParameter(valid_604222, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604222 != nil:
    section.add "Version", valid_604222
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604223 = header.getOrDefault("X-Amz-Date")
  valid_604223 = validateParameter(valid_604223, JString, required = false,
                                 default = nil)
  if valid_604223 != nil:
    section.add "X-Amz-Date", valid_604223
  var valid_604224 = header.getOrDefault("X-Amz-Security-Token")
  valid_604224 = validateParameter(valid_604224, JString, required = false,
                                 default = nil)
  if valid_604224 != nil:
    section.add "X-Amz-Security-Token", valid_604224
  var valid_604225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604225 = validateParameter(valid_604225, JString, required = false,
                                 default = nil)
  if valid_604225 != nil:
    section.add "X-Amz-Content-Sha256", valid_604225
  var valid_604226 = header.getOrDefault("X-Amz-Algorithm")
  valid_604226 = validateParameter(valid_604226, JString, required = false,
                                 default = nil)
  if valid_604226 != nil:
    section.add "X-Amz-Algorithm", valid_604226
  var valid_604227 = header.getOrDefault("X-Amz-Signature")
  valid_604227 = validateParameter(valid_604227, JString, required = false,
                                 default = nil)
  if valid_604227 != nil:
    section.add "X-Amz-Signature", valid_604227
  var valid_604228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604228 = validateParameter(valid_604228, JString, required = false,
                                 default = nil)
  if valid_604228 != nil:
    section.add "X-Amz-SignedHeaders", valid_604228
  var valid_604229 = header.getOrDefault("X-Amz-Credential")
  valid_604229 = validateParameter(valid_604229, JString, required = false,
                                 default = nil)
  if valid_604229 != nil:
    section.add "X-Amz-Credential", valid_604229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604230: Call_GetDescribeEvents_604209; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604230.validator(path, query, header, formData, body)
  let scheme = call_604230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604230.url(scheme.get, call_604230.host, call_604230.base,
                         call_604230.route, valid.getOrDefault("path"))
  result = hook(call_604230, url, valid)

proc call*(call_604231: Call_GetDescribeEvents_604209;
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
  var query_604232 = newJObject()
  add(query_604232, "SourceType", newJString(SourceType))
  add(query_604232, "MaxRecords", newJInt(MaxRecords))
  add(query_604232, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_604232.add "Filters", Filters
  add(query_604232, "Action", newJString(Action))
  add(query_604232, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604232, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604232.add "EventCategories", EventCategories
  add(query_604232, "Duration", newJInt(Duration))
  add(query_604232, "EndTime", newJString(EndTime))
  add(query_604232, "Version", newJString(Version))
  result = call_604231.call(nil, query_604232, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604209(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604210,
    base: "/", url: url_GetDescribeEvents_604211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_604278 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOptionGroupOptions_604280(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_604279(path: JsonNode;
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
  var valid_604281 = query.getOrDefault("Action")
  valid_604281 = validateParameter(valid_604281, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604281 != nil:
    section.add "Action", valid_604281
  var valid_604282 = query.getOrDefault("Version")
  valid_604282 = validateParameter(valid_604282, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604282 != nil:
    section.add "Version", valid_604282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604283 = header.getOrDefault("X-Amz-Date")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-Date", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Security-Token")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Security-Token", valid_604284
  var valid_604285 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "X-Amz-Content-Sha256", valid_604285
  var valid_604286 = header.getOrDefault("X-Amz-Algorithm")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "X-Amz-Algorithm", valid_604286
  var valid_604287 = header.getOrDefault("X-Amz-Signature")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "X-Amz-Signature", valid_604287
  var valid_604288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "X-Amz-SignedHeaders", valid_604288
  var valid_604289 = header.getOrDefault("X-Amz-Credential")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "X-Amz-Credential", valid_604289
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604290 = formData.getOrDefault("MajorEngineVersion")
  valid_604290 = validateParameter(valid_604290, JString, required = false,
                                 default = nil)
  if valid_604290 != nil:
    section.add "MajorEngineVersion", valid_604290
  var valid_604291 = formData.getOrDefault("Marker")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "Marker", valid_604291
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_604292 = formData.getOrDefault("EngineName")
  valid_604292 = validateParameter(valid_604292, JString, required = true,
                                 default = nil)
  if valid_604292 != nil:
    section.add "EngineName", valid_604292
  var valid_604293 = formData.getOrDefault("Filters")
  valid_604293 = validateParameter(valid_604293, JArray, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "Filters", valid_604293
  var valid_604294 = formData.getOrDefault("MaxRecords")
  valid_604294 = validateParameter(valid_604294, JInt, required = false, default = nil)
  if valid_604294 != nil:
    section.add "MaxRecords", valid_604294
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604295: Call_PostDescribeOptionGroupOptions_604278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604295.validator(path, query, header, formData, body)
  let scheme = call_604295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604295.url(scheme.get, call_604295.host, call_604295.base,
                         call_604295.route, valid.getOrDefault("path"))
  result = hook(call_604295, url, valid)

proc call*(call_604296: Call_PostDescribeOptionGroupOptions_604278;
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
  var query_604297 = newJObject()
  var formData_604298 = newJObject()
  add(formData_604298, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604298, "Marker", newJString(Marker))
  add(query_604297, "Action", newJString(Action))
  add(formData_604298, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604298.add "Filters", Filters
  add(formData_604298, "MaxRecords", newJInt(MaxRecords))
  add(query_604297, "Version", newJString(Version))
  result = call_604296.call(nil, query_604297, nil, formData_604298, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_604278(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_604279, base: "/",
    url: url_PostDescribeOptionGroupOptions_604280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_604258 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOptionGroupOptions_604260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_604259(path: JsonNode; query: JsonNode;
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
  var valid_604261 = query.getOrDefault("MaxRecords")
  valid_604261 = validateParameter(valid_604261, JInt, required = false, default = nil)
  if valid_604261 != nil:
    section.add "MaxRecords", valid_604261
  var valid_604262 = query.getOrDefault("Filters")
  valid_604262 = validateParameter(valid_604262, JArray, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "Filters", valid_604262
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604263 = query.getOrDefault("Action")
  valid_604263 = validateParameter(valid_604263, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604263 != nil:
    section.add "Action", valid_604263
  var valid_604264 = query.getOrDefault("Marker")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "Marker", valid_604264
  var valid_604265 = query.getOrDefault("Version")
  valid_604265 = validateParameter(valid_604265, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604265 != nil:
    section.add "Version", valid_604265
  var valid_604266 = query.getOrDefault("EngineName")
  valid_604266 = validateParameter(valid_604266, JString, required = true,
                                 default = nil)
  if valid_604266 != nil:
    section.add "EngineName", valid_604266
  var valid_604267 = query.getOrDefault("MajorEngineVersion")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "MajorEngineVersion", valid_604267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604268 = header.getOrDefault("X-Amz-Date")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-Date", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Security-Token")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Security-Token", valid_604269
  var valid_604270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604270 = validateParameter(valid_604270, JString, required = false,
                                 default = nil)
  if valid_604270 != nil:
    section.add "X-Amz-Content-Sha256", valid_604270
  var valid_604271 = header.getOrDefault("X-Amz-Algorithm")
  valid_604271 = validateParameter(valid_604271, JString, required = false,
                                 default = nil)
  if valid_604271 != nil:
    section.add "X-Amz-Algorithm", valid_604271
  var valid_604272 = header.getOrDefault("X-Amz-Signature")
  valid_604272 = validateParameter(valid_604272, JString, required = false,
                                 default = nil)
  if valid_604272 != nil:
    section.add "X-Amz-Signature", valid_604272
  var valid_604273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604273 = validateParameter(valid_604273, JString, required = false,
                                 default = nil)
  if valid_604273 != nil:
    section.add "X-Amz-SignedHeaders", valid_604273
  var valid_604274 = header.getOrDefault("X-Amz-Credential")
  valid_604274 = validateParameter(valid_604274, JString, required = false,
                                 default = nil)
  if valid_604274 != nil:
    section.add "X-Amz-Credential", valid_604274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604275: Call_GetDescribeOptionGroupOptions_604258; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604275.validator(path, query, header, formData, body)
  let scheme = call_604275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604275.url(scheme.get, call_604275.host, call_604275.base,
                         call_604275.route, valid.getOrDefault("path"))
  result = hook(call_604275, url, valid)

proc call*(call_604276: Call_GetDescribeOptionGroupOptions_604258;
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
  var query_604277 = newJObject()
  add(query_604277, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604277.add "Filters", Filters
  add(query_604277, "Action", newJString(Action))
  add(query_604277, "Marker", newJString(Marker))
  add(query_604277, "Version", newJString(Version))
  add(query_604277, "EngineName", newJString(EngineName))
  add(query_604277, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604276.call(nil, query_604277, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_604258(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_604259, base: "/",
    url: url_GetDescribeOptionGroupOptions_604260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_604320 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOptionGroups_604322(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_604321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604323 = query.getOrDefault("Action")
  valid_604323 = validateParameter(valid_604323, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604323 != nil:
    section.add "Action", valid_604323
  var valid_604324 = query.getOrDefault("Version")
  valid_604324 = validateParameter(valid_604324, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604324 != nil:
    section.add "Version", valid_604324
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604325 = header.getOrDefault("X-Amz-Date")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Date", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-Security-Token")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-Security-Token", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Content-Sha256", valid_604327
  var valid_604328 = header.getOrDefault("X-Amz-Algorithm")
  valid_604328 = validateParameter(valid_604328, JString, required = false,
                                 default = nil)
  if valid_604328 != nil:
    section.add "X-Amz-Algorithm", valid_604328
  var valid_604329 = header.getOrDefault("X-Amz-Signature")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "X-Amz-Signature", valid_604329
  var valid_604330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604330 = validateParameter(valid_604330, JString, required = false,
                                 default = nil)
  if valid_604330 != nil:
    section.add "X-Amz-SignedHeaders", valid_604330
  var valid_604331 = header.getOrDefault("X-Amz-Credential")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "X-Amz-Credential", valid_604331
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604332 = formData.getOrDefault("MajorEngineVersion")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "MajorEngineVersion", valid_604332
  var valid_604333 = formData.getOrDefault("OptionGroupName")
  valid_604333 = validateParameter(valid_604333, JString, required = false,
                                 default = nil)
  if valid_604333 != nil:
    section.add "OptionGroupName", valid_604333
  var valid_604334 = formData.getOrDefault("Marker")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "Marker", valid_604334
  var valid_604335 = formData.getOrDefault("EngineName")
  valid_604335 = validateParameter(valid_604335, JString, required = false,
                                 default = nil)
  if valid_604335 != nil:
    section.add "EngineName", valid_604335
  var valid_604336 = formData.getOrDefault("Filters")
  valid_604336 = validateParameter(valid_604336, JArray, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "Filters", valid_604336
  var valid_604337 = formData.getOrDefault("MaxRecords")
  valid_604337 = validateParameter(valid_604337, JInt, required = false, default = nil)
  if valid_604337 != nil:
    section.add "MaxRecords", valid_604337
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604338: Call_PostDescribeOptionGroups_604320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604338.validator(path, query, header, formData, body)
  let scheme = call_604338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604338.url(scheme.get, call_604338.host, call_604338.base,
                         call_604338.route, valid.getOrDefault("path"))
  result = hook(call_604338, url, valid)

proc call*(call_604339: Call_PostDescribeOptionGroups_604320;
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
  var query_604340 = newJObject()
  var formData_604341 = newJObject()
  add(formData_604341, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604341, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604341, "Marker", newJString(Marker))
  add(query_604340, "Action", newJString(Action))
  add(formData_604341, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_604341.add "Filters", Filters
  add(formData_604341, "MaxRecords", newJInt(MaxRecords))
  add(query_604340, "Version", newJString(Version))
  result = call_604339.call(nil, query_604340, nil, formData_604341, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_604320(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_604321, base: "/",
    url: url_PostDescribeOptionGroups_604322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_604299 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOptionGroups_604301(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_604300(path: JsonNode; query: JsonNode;
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
  var valid_604302 = query.getOrDefault("MaxRecords")
  valid_604302 = validateParameter(valid_604302, JInt, required = false, default = nil)
  if valid_604302 != nil:
    section.add "MaxRecords", valid_604302
  var valid_604303 = query.getOrDefault("OptionGroupName")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "OptionGroupName", valid_604303
  var valid_604304 = query.getOrDefault("Filters")
  valid_604304 = validateParameter(valid_604304, JArray, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "Filters", valid_604304
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604305 = query.getOrDefault("Action")
  valid_604305 = validateParameter(valid_604305, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604305 != nil:
    section.add "Action", valid_604305
  var valid_604306 = query.getOrDefault("Marker")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "Marker", valid_604306
  var valid_604307 = query.getOrDefault("Version")
  valid_604307 = validateParameter(valid_604307, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604307 != nil:
    section.add "Version", valid_604307
  var valid_604308 = query.getOrDefault("EngineName")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "EngineName", valid_604308
  var valid_604309 = query.getOrDefault("MajorEngineVersion")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "MajorEngineVersion", valid_604309
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604310 = header.getOrDefault("X-Amz-Date")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "X-Amz-Date", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-Security-Token")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-Security-Token", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Content-Sha256", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Algorithm")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Algorithm", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-Signature")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Signature", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-SignedHeaders", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-Credential")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-Credential", valid_604316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604317: Call_GetDescribeOptionGroups_604299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604317.validator(path, query, header, formData, body)
  let scheme = call_604317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604317.url(scheme.get, call_604317.host, call_604317.base,
                         call_604317.route, valid.getOrDefault("path"))
  result = hook(call_604317, url, valid)

proc call*(call_604318: Call_GetDescribeOptionGroups_604299; MaxRecords: int = 0;
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
  var query_604319 = newJObject()
  add(query_604319, "MaxRecords", newJInt(MaxRecords))
  add(query_604319, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_604319.add "Filters", Filters
  add(query_604319, "Action", newJString(Action))
  add(query_604319, "Marker", newJString(Marker))
  add(query_604319, "Version", newJString(Version))
  add(query_604319, "EngineName", newJString(EngineName))
  add(query_604319, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604318.call(nil, query_604319, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_604299(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_604300, base: "/",
    url: url_GetDescribeOptionGroups_604301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604365 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOrderableDBInstanceOptions_604367(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604366(path: JsonNode;
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
  var valid_604368 = query.getOrDefault("Action")
  valid_604368 = validateParameter(valid_604368, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604368 != nil:
    section.add "Action", valid_604368
  var valid_604369 = query.getOrDefault("Version")
  valid_604369 = validateParameter(valid_604369, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604369 != nil:
    section.add "Version", valid_604369
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604370 = header.getOrDefault("X-Amz-Date")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Date", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-Security-Token")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Security-Token", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Content-Sha256", valid_604372
  var valid_604373 = header.getOrDefault("X-Amz-Algorithm")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "X-Amz-Algorithm", valid_604373
  var valid_604374 = header.getOrDefault("X-Amz-Signature")
  valid_604374 = validateParameter(valid_604374, JString, required = false,
                                 default = nil)
  if valid_604374 != nil:
    section.add "X-Amz-Signature", valid_604374
  var valid_604375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "X-Amz-SignedHeaders", valid_604375
  var valid_604376 = header.getOrDefault("X-Amz-Credential")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "X-Amz-Credential", valid_604376
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
  var valid_604377 = formData.getOrDefault("Engine")
  valid_604377 = validateParameter(valid_604377, JString, required = true,
                                 default = nil)
  if valid_604377 != nil:
    section.add "Engine", valid_604377
  var valid_604378 = formData.getOrDefault("Marker")
  valid_604378 = validateParameter(valid_604378, JString, required = false,
                                 default = nil)
  if valid_604378 != nil:
    section.add "Marker", valid_604378
  var valid_604379 = formData.getOrDefault("Vpc")
  valid_604379 = validateParameter(valid_604379, JBool, required = false, default = nil)
  if valid_604379 != nil:
    section.add "Vpc", valid_604379
  var valid_604380 = formData.getOrDefault("DBInstanceClass")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "DBInstanceClass", valid_604380
  var valid_604381 = formData.getOrDefault("Filters")
  valid_604381 = validateParameter(valid_604381, JArray, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "Filters", valid_604381
  var valid_604382 = formData.getOrDefault("LicenseModel")
  valid_604382 = validateParameter(valid_604382, JString, required = false,
                                 default = nil)
  if valid_604382 != nil:
    section.add "LicenseModel", valid_604382
  var valid_604383 = formData.getOrDefault("MaxRecords")
  valid_604383 = validateParameter(valid_604383, JInt, required = false, default = nil)
  if valid_604383 != nil:
    section.add "MaxRecords", valid_604383
  var valid_604384 = formData.getOrDefault("EngineVersion")
  valid_604384 = validateParameter(valid_604384, JString, required = false,
                                 default = nil)
  if valid_604384 != nil:
    section.add "EngineVersion", valid_604384
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604385: Call_PostDescribeOrderableDBInstanceOptions_604365;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604385.validator(path, query, header, formData, body)
  let scheme = call_604385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604385.url(scheme.get, call_604385.host, call_604385.base,
                         call_604385.route, valid.getOrDefault("path"))
  result = hook(call_604385, url, valid)

proc call*(call_604386: Call_PostDescribeOrderableDBInstanceOptions_604365;
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
  var query_604387 = newJObject()
  var formData_604388 = newJObject()
  add(formData_604388, "Engine", newJString(Engine))
  add(formData_604388, "Marker", newJString(Marker))
  add(query_604387, "Action", newJString(Action))
  add(formData_604388, "Vpc", newJBool(Vpc))
  add(formData_604388, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604388.add "Filters", Filters
  add(formData_604388, "LicenseModel", newJString(LicenseModel))
  add(formData_604388, "MaxRecords", newJInt(MaxRecords))
  add(formData_604388, "EngineVersion", newJString(EngineVersion))
  add(query_604387, "Version", newJString(Version))
  result = call_604386.call(nil, query_604387, nil, formData_604388, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604365(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604366, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604367,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604342 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOrderableDBInstanceOptions_604344(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604343(path: JsonNode;
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
  var valid_604345 = query.getOrDefault("Engine")
  valid_604345 = validateParameter(valid_604345, JString, required = true,
                                 default = nil)
  if valid_604345 != nil:
    section.add "Engine", valid_604345
  var valid_604346 = query.getOrDefault("MaxRecords")
  valid_604346 = validateParameter(valid_604346, JInt, required = false, default = nil)
  if valid_604346 != nil:
    section.add "MaxRecords", valid_604346
  var valid_604347 = query.getOrDefault("Filters")
  valid_604347 = validateParameter(valid_604347, JArray, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "Filters", valid_604347
  var valid_604348 = query.getOrDefault("LicenseModel")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "LicenseModel", valid_604348
  var valid_604349 = query.getOrDefault("Vpc")
  valid_604349 = validateParameter(valid_604349, JBool, required = false, default = nil)
  if valid_604349 != nil:
    section.add "Vpc", valid_604349
  var valid_604350 = query.getOrDefault("DBInstanceClass")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "DBInstanceClass", valid_604350
  var valid_604351 = query.getOrDefault("Action")
  valid_604351 = validateParameter(valid_604351, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604351 != nil:
    section.add "Action", valid_604351
  var valid_604352 = query.getOrDefault("Marker")
  valid_604352 = validateParameter(valid_604352, JString, required = false,
                                 default = nil)
  if valid_604352 != nil:
    section.add "Marker", valid_604352
  var valid_604353 = query.getOrDefault("EngineVersion")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "EngineVersion", valid_604353
  var valid_604354 = query.getOrDefault("Version")
  valid_604354 = validateParameter(valid_604354, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604354 != nil:
    section.add "Version", valid_604354
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604355 = header.getOrDefault("X-Amz-Date")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Date", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Security-Token")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Security-Token", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Content-Sha256", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-Algorithm")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Algorithm", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-Signature")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-Signature", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-SignedHeaders", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Credential")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Credential", valid_604361
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604362: Call_GetDescribeOrderableDBInstanceOptions_604342;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604362.validator(path, query, header, formData, body)
  let scheme = call_604362.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604362.url(scheme.get, call_604362.host, call_604362.base,
                         call_604362.route, valid.getOrDefault("path"))
  result = hook(call_604362, url, valid)

proc call*(call_604363: Call_GetDescribeOrderableDBInstanceOptions_604342;
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
  var query_604364 = newJObject()
  add(query_604364, "Engine", newJString(Engine))
  add(query_604364, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_604364.add "Filters", Filters
  add(query_604364, "LicenseModel", newJString(LicenseModel))
  add(query_604364, "Vpc", newJBool(Vpc))
  add(query_604364, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604364, "Action", newJString(Action))
  add(query_604364, "Marker", newJString(Marker))
  add(query_604364, "EngineVersion", newJString(EngineVersion))
  add(query_604364, "Version", newJString(Version))
  result = call_604363.call(nil, query_604364, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604342(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604343, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604344,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_604414 = ref object of OpenApiRestCall_602417
proc url_PostDescribeReservedDBInstances_604416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_604415(path: JsonNode;
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
  var valid_604417 = query.getOrDefault("Action")
  valid_604417 = validateParameter(valid_604417, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604417 != nil:
    section.add "Action", valid_604417
  var valid_604418 = query.getOrDefault("Version")
  valid_604418 = validateParameter(valid_604418, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604418 != nil:
    section.add "Version", valid_604418
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604419 = header.getOrDefault("X-Amz-Date")
  valid_604419 = validateParameter(valid_604419, JString, required = false,
                                 default = nil)
  if valid_604419 != nil:
    section.add "X-Amz-Date", valid_604419
  var valid_604420 = header.getOrDefault("X-Amz-Security-Token")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "X-Amz-Security-Token", valid_604420
  var valid_604421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "X-Amz-Content-Sha256", valid_604421
  var valid_604422 = header.getOrDefault("X-Amz-Algorithm")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "X-Amz-Algorithm", valid_604422
  var valid_604423 = header.getOrDefault("X-Amz-Signature")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "X-Amz-Signature", valid_604423
  var valid_604424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "X-Amz-SignedHeaders", valid_604424
  var valid_604425 = header.getOrDefault("X-Amz-Credential")
  valid_604425 = validateParameter(valid_604425, JString, required = false,
                                 default = nil)
  if valid_604425 != nil:
    section.add "X-Amz-Credential", valid_604425
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
  var valid_604426 = formData.getOrDefault("OfferingType")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "OfferingType", valid_604426
  var valid_604427 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "ReservedDBInstanceId", valid_604427
  var valid_604428 = formData.getOrDefault("Marker")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "Marker", valid_604428
  var valid_604429 = formData.getOrDefault("MultiAZ")
  valid_604429 = validateParameter(valid_604429, JBool, required = false, default = nil)
  if valid_604429 != nil:
    section.add "MultiAZ", valid_604429
  var valid_604430 = formData.getOrDefault("Duration")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "Duration", valid_604430
  var valid_604431 = formData.getOrDefault("DBInstanceClass")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "DBInstanceClass", valid_604431
  var valid_604432 = formData.getOrDefault("Filters")
  valid_604432 = validateParameter(valid_604432, JArray, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "Filters", valid_604432
  var valid_604433 = formData.getOrDefault("ProductDescription")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "ProductDescription", valid_604433
  var valid_604434 = formData.getOrDefault("MaxRecords")
  valid_604434 = validateParameter(valid_604434, JInt, required = false, default = nil)
  if valid_604434 != nil:
    section.add "MaxRecords", valid_604434
  var valid_604435 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604435
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604436: Call_PostDescribeReservedDBInstances_604414;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604436.validator(path, query, header, formData, body)
  let scheme = call_604436.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604436.url(scheme.get, call_604436.host, call_604436.base,
                         call_604436.route, valid.getOrDefault("path"))
  result = hook(call_604436, url, valid)

proc call*(call_604437: Call_PostDescribeReservedDBInstances_604414;
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
  var query_604438 = newJObject()
  var formData_604439 = newJObject()
  add(formData_604439, "OfferingType", newJString(OfferingType))
  add(formData_604439, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604439, "Marker", newJString(Marker))
  add(formData_604439, "MultiAZ", newJBool(MultiAZ))
  add(query_604438, "Action", newJString(Action))
  add(formData_604439, "Duration", newJString(Duration))
  add(formData_604439, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604439.add "Filters", Filters
  add(formData_604439, "ProductDescription", newJString(ProductDescription))
  add(formData_604439, "MaxRecords", newJInt(MaxRecords))
  add(formData_604439, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604438, "Version", newJString(Version))
  result = call_604437.call(nil, query_604438, nil, formData_604439, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_604414(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_604415, base: "/",
    url: url_PostDescribeReservedDBInstances_604416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_604389 = ref object of OpenApiRestCall_602417
proc url_GetDescribeReservedDBInstances_604391(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_604390(path: JsonNode;
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
  var valid_604392 = query.getOrDefault("ProductDescription")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "ProductDescription", valid_604392
  var valid_604393 = query.getOrDefault("MaxRecords")
  valid_604393 = validateParameter(valid_604393, JInt, required = false, default = nil)
  if valid_604393 != nil:
    section.add "MaxRecords", valid_604393
  var valid_604394 = query.getOrDefault("OfferingType")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "OfferingType", valid_604394
  var valid_604395 = query.getOrDefault("Filters")
  valid_604395 = validateParameter(valid_604395, JArray, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "Filters", valid_604395
  var valid_604396 = query.getOrDefault("MultiAZ")
  valid_604396 = validateParameter(valid_604396, JBool, required = false, default = nil)
  if valid_604396 != nil:
    section.add "MultiAZ", valid_604396
  var valid_604397 = query.getOrDefault("ReservedDBInstanceId")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "ReservedDBInstanceId", valid_604397
  var valid_604398 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604398
  var valid_604399 = query.getOrDefault("DBInstanceClass")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "DBInstanceClass", valid_604399
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604400 = query.getOrDefault("Action")
  valid_604400 = validateParameter(valid_604400, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604400 != nil:
    section.add "Action", valid_604400
  var valid_604401 = query.getOrDefault("Marker")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "Marker", valid_604401
  var valid_604402 = query.getOrDefault("Duration")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "Duration", valid_604402
  var valid_604403 = query.getOrDefault("Version")
  valid_604403 = validateParameter(valid_604403, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604403 != nil:
    section.add "Version", valid_604403
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604404 = header.getOrDefault("X-Amz-Date")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Date", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Security-Token")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Security-Token", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Content-Sha256", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Algorithm")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Algorithm", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Signature")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Signature", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-SignedHeaders", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-Credential")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Credential", valid_604410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604411: Call_GetDescribeReservedDBInstances_604389; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604411.validator(path, query, header, formData, body)
  let scheme = call_604411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604411.url(scheme.get, call_604411.host, call_604411.base,
                         call_604411.route, valid.getOrDefault("path"))
  result = hook(call_604411, url, valid)

proc call*(call_604412: Call_GetDescribeReservedDBInstances_604389;
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
  var query_604413 = newJObject()
  add(query_604413, "ProductDescription", newJString(ProductDescription))
  add(query_604413, "MaxRecords", newJInt(MaxRecords))
  add(query_604413, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604413.add "Filters", Filters
  add(query_604413, "MultiAZ", newJBool(MultiAZ))
  add(query_604413, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604413, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604413, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604413, "Action", newJString(Action))
  add(query_604413, "Marker", newJString(Marker))
  add(query_604413, "Duration", newJString(Duration))
  add(query_604413, "Version", newJString(Version))
  result = call_604412.call(nil, query_604413, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_604389(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_604390, base: "/",
    url: url_GetDescribeReservedDBInstances_604391,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_604464 = ref object of OpenApiRestCall_602417
proc url_PostDescribeReservedDBInstancesOfferings_604466(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_604465(path: JsonNode;
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
  var valid_604467 = query.getOrDefault("Action")
  valid_604467 = validateParameter(valid_604467, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604467 != nil:
    section.add "Action", valid_604467
  var valid_604468 = query.getOrDefault("Version")
  valid_604468 = validateParameter(valid_604468, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604468 != nil:
    section.add "Version", valid_604468
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604469 = header.getOrDefault("X-Amz-Date")
  valid_604469 = validateParameter(valid_604469, JString, required = false,
                                 default = nil)
  if valid_604469 != nil:
    section.add "X-Amz-Date", valid_604469
  var valid_604470 = header.getOrDefault("X-Amz-Security-Token")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "X-Amz-Security-Token", valid_604470
  var valid_604471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "X-Amz-Content-Sha256", valid_604471
  var valid_604472 = header.getOrDefault("X-Amz-Algorithm")
  valid_604472 = validateParameter(valid_604472, JString, required = false,
                                 default = nil)
  if valid_604472 != nil:
    section.add "X-Amz-Algorithm", valid_604472
  var valid_604473 = header.getOrDefault("X-Amz-Signature")
  valid_604473 = validateParameter(valid_604473, JString, required = false,
                                 default = nil)
  if valid_604473 != nil:
    section.add "X-Amz-Signature", valid_604473
  var valid_604474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "X-Amz-SignedHeaders", valid_604474
  var valid_604475 = header.getOrDefault("X-Amz-Credential")
  valid_604475 = validateParameter(valid_604475, JString, required = false,
                                 default = nil)
  if valid_604475 != nil:
    section.add "X-Amz-Credential", valid_604475
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
  var valid_604476 = formData.getOrDefault("OfferingType")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "OfferingType", valid_604476
  var valid_604477 = formData.getOrDefault("Marker")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "Marker", valid_604477
  var valid_604478 = formData.getOrDefault("MultiAZ")
  valid_604478 = validateParameter(valid_604478, JBool, required = false, default = nil)
  if valid_604478 != nil:
    section.add "MultiAZ", valid_604478
  var valid_604479 = formData.getOrDefault("Duration")
  valid_604479 = validateParameter(valid_604479, JString, required = false,
                                 default = nil)
  if valid_604479 != nil:
    section.add "Duration", valid_604479
  var valid_604480 = formData.getOrDefault("DBInstanceClass")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "DBInstanceClass", valid_604480
  var valid_604481 = formData.getOrDefault("Filters")
  valid_604481 = validateParameter(valid_604481, JArray, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "Filters", valid_604481
  var valid_604482 = formData.getOrDefault("ProductDescription")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "ProductDescription", valid_604482
  var valid_604483 = formData.getOrDefault("MaxRecords")
  valid_604483 = validateParameter(valid_604483, JInt, required = false, default = nil)
  if valid_604483 != nil:
    section.add "MaxRecords", valid_604483
  var valid_604484 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604484
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604485: Call_PostDescribeReservedDBInstancesOfferings_604464;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604485.validator(path, query, header, formData, body)
  let scheme = call_604485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604485.url(scheme.get, call_604485.host, call_604485.base,
                         call_604485.route, valid.getOrDefault("path"))
  result = hook(call_604485, url, valid)

proc call*(call_604486: Call_PostDescribeReservedDBInstancesOfferings_604464;
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
  var query_604487 = newJObject()
  var formData_604488 = newJObject()
  add(formData_604488, "OfferingType", newJString(OfferingType))
  add(formData_604488, "Marker", newJString(Marker))
  add(formData_604488, "MultiAZ", newJBool(MultiAZ))
  add(query_604487, "Action", newJString(Action))
  add(formData_604488, "Duration", newJString(Duration))
  add(formData_604488, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_604488.add "Filters", Filters
  add(formData_604488, "ProductDescription", newJString(ProductDescription))
  add(formData_604488, "MaxRecords", newJInt(MaxRecords))
  add(formData_604488, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604487, "Version", newJString(Version))
  result = call_604486.call(nil, query_604487, nil, formData_604488, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_604464(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_604465,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_604466,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_604440 = ref object of OpenApiRestCall_602417
proc url_GetDescribeReservedDBInstancesOfferings_604442(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_604441(path: JsonNode;
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
  var valid_604443 = query.getOrDefault("ProductDescription")
  valid_604443 = validateParameter(valid_604443, JString, required = false,
                                 default = nil)
  if valid_604443 != nil:
    section.add "ProductDescription", valid_604443
  var valid_604444 = query.getOrDefault("MaxRecords")
  valid_604444 = validateParameter(valid_604444, JInt, required = false, default = nil)
  if valid_604444 != nil:
    section.add "MaxRecords", valid_604444
  var valid_604445 = query.getOrDefault("OfferingType")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "OfferingType", valid_604445
  var valid_604446 = query.getOrDefault("Filters")
  valid_604446 = validateParameter(valid_604446, JArray, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "Filters", valid_604446
  var valid_604447 = query.getOrDefault("MultiAZ")
  valid_604447 = validateParameter(valid_604447, JBool, required = false, default = nil)
  if valid_604447 != nil:
    section.add "MultiAZ", valid_604447
  var valid_604448 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604448
  var valid_604449 = query.getOrDefault("DBInstanceClass")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "DBInstanceClass", valid_604449
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604450 = query.getOrDefault("Action")
  valid_604450 = validateParameter(valid_604450, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604450 != nil:
    section.add "Action", valid_604450
  var valid_604451 = query.getOrDefault("Marker")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "Marker", valid_604451
  var valid_604452 = query.getOrDefault("Duration")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "Duration", valid_604452
  var valid_604453 = query.getOrDefault("Version")
  valid_604453 = validateParameter(valid_604453, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604453 != nil:
    section.add "Version", valid_604453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604454 = header.getOrDefault("X-Amz-Date")
  valid_604454 = validateParameter(valid_604454, JString, required = false,
                                 default = nil)
  if valid_604454 != nil:
    section.add "X-Amz-Date", valid_604454
  var valid_604455 = header.getOrDefault("X-Amz-Security-Token")
  valid_604455 = validateParameter(valid_604455, JString, required = false,
                                 default = nil)
  if valid_604455 != nil:
    section.add "X-Amz-Security-Token", valid_604455
  var valid_604456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604456 = validateParameter(valid_604456, JString, required = false,
                                 default = nil)
  if valid_604456 != nil:
    section.add "X-Amz-Content-Sha256", valid_604456
  var valid_604457 = header.getOrDefault("X-Amz-Algorithm")
  valid_604457 = validateParameter(valid_604457, JString, required = false,
                                 default = nil)
  if valid_604457 != nil:
    section.add "X-Amz-Algorithm", valid_604457
  var valid_604458 = header.getOrDefault("X-Amz-Signature")
  valid_604458 = validateParameter(valid_604458, JString, required = false,
                                 default = nil)
  if valid_604458 != nil:
    section.add "X-Amz-Signature", valid_604458
  var valid_604459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-SignedHeaders", valid_604459
  var valid_604460 = header.getOrDefault("X-Amz-Credential")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "X-Amz-Credential", valid_604460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604461: Call_GetDescribeReservedDBInstancesOfferings_604440;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604461.validator(path, query, header, formData, body)
  let scheme = call_604461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604461.url(scheme.get, call_604461.host, call_604461.base,
                         call_604461.route, valid.getOrDefault("path"))
  result = hook(call_604461, url, valid)

proc call*(call_604462: Call_GetDescribeReservedDBInstancesOfferings_604440;
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
  var query_604463 = newJObject()
  add(query_604463, "ProductDescription", newJString(ProductDescription))
  add(query_604463, "MaxRecords", newJInt(MaxRecords))
  add(query_604463, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_604463.add "Filters", Filters
  add(query_604463, "MultiAZ", newJBool(MultiAZ))
  add(query_604463, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604463, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604463, "Action", newJString(Action))
  add(query_604463, "Marker", newJString(Marker))
  add(query_604463, "Duration", newJString(Duration))
  add(query_604463, "Version", newJString(Version))
  result = call_604462.call(nil, query_604463, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_604440(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_604441, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_604442,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_604508 = ref object of OpenApiRestCall_602417
proc url_PostDownloadDBLogFilePortion_604510(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_604509(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604511 = query.getOrDefault("Action")
  valid_604511 = validateParameter(valid_604511, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604511 != nil:
    section.add "Action", valid_604511
  var valid_604512 = query.getOrDefault("Version")
  valid_604512 = validateParameter(valid_604512, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604512 != nil:
    section.add "Version", valid_604512
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604513 = header.getOrDefault("X-Amz-Date")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "X-Amz-Date", valid_604513
  var valid_604514 = header.getOrDefault("X-Amz-Security-Token")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "X-Amz-Security-Token", valid_604514
  var valid_604515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604515 = validateParameter(valid_604515, JString, required = false,
                                 default = nil)
  if valid_604515 != nil:
    section.add "X-Amz-Content-Sha256", valid_604515
  var valid_604516 = header.getOrDefault("X-Amz-Algorithm")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "X-Amz-Algorithm", valid_604516
  var valid_604517 = header.getOrDefault("X-Amz-Signature")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "X-Amz-Signature", valid_604517
  var valid_604518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604518 = validateParameter(valid_604518, JString, required = false,
                                 default = nil)
  if valid_604518 != nil:
    section.add "X-Amz-SignedHeaders", valid_604518
  var valid_604519 = header.getOrDefault("X-Amz-Credential")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "X-Amz-Credential", valid_604519
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_604520 = formData.getOrDefault("NumberOfLines")
  valid_604520 = validateParameter(valid_604520, JInt, required = false, default = nil)
  if valid_604520 != nil:
    section.add "NumberOfLines", valid_604520
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604521 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604521 = validateParameter(valid_604521, JString, required = true,
                                 default = nil)
  if valid_604521 != nil:
    section.add "DBInstanceIdentifier", valid_604521
  var valid_604522 = formData.getOrDefault("Marker")
  valid_604522 = validateParameter(valid_604522, JString, required = false,
                                 default = nil)
  if valid_604522 != nil:
    section.add "Marker", valid_604522
  var valid_604523 = formData.getOrDefault("LogFileName")
  valid_604523 = validateParameter(valid_604523, JString, required = true,
                                 default = nil)
  if valid_604523 != nil:
    section.add "LogFileName", valid_604523
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604524: Call_PostDownloadDBLogFilePortion_604508; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604524.validator(path, query, header, formData, body)
  let scheme = call_604524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604524.url(scheme.get, call_604524.host, call_604524.base,
                         call_604524.route, valid.getOrDefault("path"))
  result = hook(call_604524, url, valid)

proc call*(call_604525: Call_PostDownloadDBLogFilePortion_604508;
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
  var query_604526 = newJObject()
  var formData_604527 = newJObject()
  add(formData_604527, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_604527, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604527, "Marker", newJString(Marker))
  add(query_604526, "Action", newJString(Action))
  add(formData_604527, "LogFileName", newJString(LogFileName))
  add(query_604526, "Version", newJString(Version))
  result = call_604525.call(nil, query_604526, nil, formData_604527, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_604508(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_604509, base: "/",
    url: url_PostDownloadDBLogFilePortion_604510,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_604489 = ref object of OpenApiRestCall_602417
proc url_GetDownloadDBLogFilePortion_604491(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_604490(path: JsonNode; query: JsonNode;
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
  var valid_604492 = query.getOrDefault("NumberOfLines")
  valid_604492 = validateParameter(valid_604492, JInt, required = false, default = nil)
  if valid_604492 != nil:
    section.add "NumberOfLines", valid_604492
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_604493 = query.getOrDefault("LogFileName")
  valid_604493 = validateParameter(valid_604493, JString, required = true,
                                 default = nil)
  if valid_604493 != nil:
    section.add "LogFileName", valid_604493
  var valid_604494 = query.getOrDefault("Action")
  valid_604494 = validateParameter(valid_604494, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604494 != nil:
    section.add "Action", valid_604494
  var valid_604495 = query.getOrDefault("Marker")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "Marker", valid_604495
  var valid_604496 = query.getOrDefault("Version")
  valid_604496 = validateParameter(valid_604496, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604496 != nil:
    section.add "Version", valid_604496
  var valid_604497 = query.getOrDefault("DBInstanceIdentifier")
  valid_604497 = validateParameter(valid_604497, JString, required = true,
                                 default = nil)
  if valid_604497 != nil:
    section.add "DBInstanceIdentifier", valid_604497
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604498 = header.getOrDefault("X-Amz-Date")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Date", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Security-Token")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Security-Token", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Content-Sha256", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-Algorithm")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-Algorithm", valid_604501
  var valid_604502 = header.getOrDefault("X-Amz-Signature")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Signature", valid_604502
  var valid_604503 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "X-Amz-SignedHeaders", valid_604503
  var valid_604504 = header.getOrDefault("X-Amz-Credential")
  valid_604504 = validateParameter(valid_604504, JString, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "X-Amz-Credential", valid_604504
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604505: Call_GetDownloadDBLogFilePortion_604489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604505.validator(path, query, header, formData, body)
  let scheme = call_604505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604505.url(scheme.get, call_604505.host, call_604505.base,
                         call_604505.route, valid.getOrDefault("path"))
  result = hook(call_604505, url, valid)

proc call*(call_604506: Call_GetDownloadDBLogFilePortion_604489;
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
  var query_604507 = newJObject()
  add(query_604507, "NumberOfLines", newJInt(NumberOfLines))
  add(query_604507, "LogFileName", newJString(LogFileName))
  add(query_604507, "Action", newJString(Action))
  add(query_604507, "Marker", newJString(Marker))
  add(query_604507, "Version", newJString(Version))
  add(query_604507, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604506.call(nil, query_604507, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_604489(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_604490, base: "/",
    url: url_GetDownloadDBLogFilePortion_604491,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604545 = ref object of OpenApiRestCall_602417
proc url_PostListTagsForResource_604547(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_604546(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604548 = query.getOrDefault("Action")
  valid_604548 = validateParameter(valid_604548, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604548 != nil:
    section.add "Action", valid_604548
  var valid_604549 = query.getOrDefault("Version")
  valid_604549 = validateParameter(valid_604549, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604549 != nil:
    section.add "Version", valid_604549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604550 = header.getOrDefault("X-Amz-Date")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Date", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-Security-Token")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-Security-Token", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-Content-Sha256", valid_604552
  var valid_604553 = header.getOrDefault("X-Amz-Algorithm")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "X-Amz-Algorithm", valid_604553
  var valid_604554 = header.getOrDefault("X-Amz-Signature")
  valid_604554 = validateParameter(valid_604554, JString, required = false,
                                 default = nil)
  if valid_604554 != nil:
    section.add "X-Amz-Signature", valid_604554
  var valid_604555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604555 = validateParameter(valid_604555, JString, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "X-Amz-SignedHeaders", valid_604555
  var valid_604556 = header.getOrDefault("X-Amz-Credential")
  valid_604556 = validateParameter(valid_604556, JString, required = false,
                                 default = nil)
  if valid_604556 != nil:
    section.add "X-Amz-Credential", valid_604556
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_604557 = formData.getOrDefault("Filters")
  valid_604557 = validateParameter(valid_604557, JArray, required = false,
                                 default = nil)
  if valid_604557 != nil:
    section.add "Filters", valid_604557
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604558 = formData.getOrDefault("ResourceName")
  valid_604558 = validateParameter(valid_604558, JString, required = true,
                                 default = nil)
  if valid_604558 != nil:
    section.add "ResourceName", valid_604558
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604559: Call_PostListTagsForResource_604545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604559.validator(path, query, header, formData, body)
  let scheme = call_604559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604559.url(scheme.get, call_604559.host, call_604559.base,
                         call_604559.route, valid.getOrDefault("path"))
  result = hook(call_604559, url, valid)

proc call*(call_604560: Call_PostListTagsForResource_604545; ResourceName: string;
          Action: string = "ListTagsForResource"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604561 = newJObject()
  var formData_604562 = newJObject()
  add(query_604561, "Action", newJString(Action))
  if Filters != nil:
    formData_604562.add "Filters", Filters
  add(formData_604562, "ResourceName", newJString(ResourceName))
  add(query_604561, "Version", newJString(Version))
  result = call_604560.call(nil, query_604561, nil, formData_604562, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604545(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604546, base: "/",
    url: url_PostListTagsForResource_604547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604528 = ref object of OpenApiRestCall_602417
proc url_GetListTagsForResource_604530(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_604529(path: JsonNode; query: JsonNode;
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
  var valid_604531 = query.getOrDefault("Filters")
  valid_604531 = validateParameter(valid_604531, JArray, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "Filters", valid_604531
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_604532 = query.getOrDefault("ResourceName")
  valid_604532 = validateParameter(valid_604532, JString, required = true,
                                 default = nil)
  if valid_604532 != nil:
    section.add "ResourceName", valid_604532
  var valid_604533 = query.getOrDefault("Action")
  valid_604533 = validateParameter(valid_604533, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604533 != nil:
    section.add "Action", valid_604533
  var valid_604534 = query.getOrDefault("Version")
  valid_604534 = validateParameter(valid_604534, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604534 != nil:
    section.add "Version", valid_604534
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604535 = header.getOrDefault("X-Amz-Date")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Date", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-Security-Token")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-Security-Token", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-Content-Sha256", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Algorithm")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Algorithm", valid_604538
  var valid_604539 = header.getOrDefault("X-Amz-Signature")
  valid_604539 = validateParameter(valid_604539, JString, required = false,
                                 default = nil)
  if valid_604539 != nil:
    section.add "X-Amz-Signature", valid_604539
  var valid_604540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604540 = validateParameter(valid_604540, JString, required = false,
                                 default = nil)
  if valid_604540 != nil:
    section.add "X-Amz-SignedHeaders", valid_604540
  var valid_604541 = header.getOrDefault("X-Amz-Credential")
  valid_604541 = validateParameter(valid_604541, JString, required = false,
                                 default = nil)
  if valid_604541 != nil:
    section.add "X-Amz-Credential", valid_604541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604542: Call_GetListTagsForResource_604528; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604542.validator(path, query, header, formData, body)
  let scheme = call_604542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604542.url(scheme.get, call_604542.host, call_604542.base,
                         call_604542.route, valid.getOrDefault("path"))
  result = hook(call_604542, url, valid)

proc call*(call_604543: Call_GetListTagsForResource_604528; ResourceName: string;
          Filters: JsonNode = nil; Action: string = "ListTagsForResource";
          Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604544 = newJObject()
  if Filters != nil:
    query_604544.add "Filters", Filters
  add(query_604544, "ResourceName", newJString(ResourceName))
  add(query_604544, "Action", newJString(Action))
  add(query_604544, "Version", newJString(Version))
  result = call_604543.call(nil, query_604544, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604528(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604529, base: "/",
    url: url_GetListTagsForResource_604530, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604596 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBInstance_604598(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_604597(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604599 = query.getOrDefault("Action")
  valid_604599 = validateParameter(valid_604599, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604599 != nil:
    section.add "Action", valid_604599
  var valid_604600 = query.getOrDefault("Version")
  valid_604600 = validateParameter(valid_604600, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604600 != nil:
    section.add "Version", valid_604600
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604601 = header.getOrDefault("X-Amz-Date")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-Date", valid_604601
  var valid_604602 = header.getOrDefault("X-Amz-Security-Token")
  valid_604602 = validateParameter(valid_604602, JString, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "X-Amz-Security-Token", valid_604602
  var valid_604603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "X-Amz-Content-Sha256", valid_604603
  var valid_604604 = header.getOrDefault("X-Amz-Algorithm")
  valid_604604 = validateParameter(valid_604604, JString, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "X-Amz-Algorithm", valid_604604
  var valid_604605 = header.getOrDefault("X-Amz-Signature")
  valid_604605 = validateParameter(valid_604605, JString, required = false,
                                 default = nil)
  if valid_604605 != nil:
    section.add "X-Amz-Signature", valid_604605
  var valid_604606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604606 = validateParameter(valid_604606, JString, required = false,
                                 default = nil)
  if valid_604606 != nil:
    section.add "X-Amz-SignedHeaders", valid_604606
  var valid_604607 = header.getOrDefault("X-Amz-Credential")
  valid_604607 = validateParameter(valid_604607, JString, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "X-Amz-Credential", valid_604607
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
  var valid_604608 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "PreferredMaintenanceWindow", valid_604608
  var valid_604609 = formData.getOrDefault("DBSecurityGroups")
  valid_604609 = validateParameter(valid_604609, JArray, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "DBSecurityGroups", valid_604609
  var valid_604610 = formData.getOrDefault("ApplyImmediately")
  valid_604610 = validateParameter(valid_604610, JBool, required = false, default = nil)
  if valid_604610 != nil:
    section.add "ApplyImmediately", valid_604610
  var valid_604611 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604611 = validateParameter(valid_604611, JArray, required = false,
                                 default = nil)
  if valid_604611 != nil:
    section.add "VpcSecurityGroupIds", valid_604611
  var valid_604612 = formData.getOrDefault("Iops")
  valid_604612 = validateParameter(valid_604612, JInt, required = false, default = nil)
  if valid_604612 != nil:
    section.add "Iops", valid_604612
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604613 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604613 = validateParameter(valid_604613, JString, required = true,
                                 default = nil)
  if valid_604613 != nil:
    section.add "DBInstanceIdentifier", valid_604613
  var valid_604614 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604614 = validateParameter(valid_604614, JInt, required = false, default = nil)
  if valid_604614 != nil:
    section.add "BackupRetentionPeriod", valid_604614
  var valid_604615 = formData.getOrDefault("DBParameterGroupName")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "DBParameterGroupName", valid_604615
  var valid_604616 = formData.getOrDefault("OptionGroupName")
  valid_604616 = validateParameter(valid_604616, JString, required = false,
                                 default = nil)
  if valid_604616 != nil:
    section.add "OptionGroupName", valid_604616
  var valid_604617 = formData.getOrDefault("MasterUserPassword")
  valid_604617 = validateParameter(valid_604617, JString, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "MasterUserPassword", valid_604617
  var valid_604618 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "NewDBInstanceIdentifier", valid_604618
  var valid_604619 = formData.getOrDefault("MultiAZ")
  valid_604619 = validateParameter(valid_604619, JBool, required = false, default = nil)
  if valid_604619 != nil:
    section.add "MultiAZ", valid_604619
  var valid_604620 = formData.getOrDefault("AllocatedStorage")
  valid_604620 = validateParameter(valid_604620, JInt, required = false, default = nil)
  if valid_604620 != nil:
    section.add "AllocatedStorage", valid_604620
  var valid_604621 = formData.getOrDefault("DBInstanceClass")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "DBInstanceClass", valid_604621
  var valid_604622 = formData.getOrDefault("PreferredBackupWindow")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "PreferredBackupWindow", valid_604622
  var valid_604623 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604623 = validateParameter(valid_604623, JBool, required = false, default = nil)
  if valid_604623 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604623
  var valid_604624 = formData.getOrDefault("EngineVersion")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "EngineVersion", valid_604624
  var valid_604625 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_604625 = validateParameter(valid_604625, JBool, required = false, default = nil)
  if valid_604625 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604625
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604626: Call_PostModifyDBInstance_604596; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604626.validator(path, query, header, formData, body)
  let scheme = call_604626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604626.url(scheme.get, call_604626.host, call_604626.base,
                         call_604626.route, valid.getOrDefault("path"))
  result = hook(call_604626, url, valid)

proc call*(call_604627: Call_PostModifyDBInstance_604596;
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
  var query_604628 = newJObject()
  var formData_604629 = newJObject()
  add(formData_604629, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_604629.add "DBSecurityGroups", DBSecurityGroups
  add(formData_604629, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_604629.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604629, "Iops", newJInt(Iops))
  add(formData_604629, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604629, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604629, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604629, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604629, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604629, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_604629, "MultiAZ", newJBool(MultiAZ))
  add(query_604628, "Action", newJString(Action))
  add(formData_604629, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_604629, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604629, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604629, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604629, "EngineVersion", newJString(EngineVersion))
  add(query_604628, "Version", newJString(Version))
  add(formData_604629, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_604627.call(nil, query_604628, nil, formData_604629, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604596(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604597, base: "/",
    url: url_PostModifyDBInstance_604598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604563 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBInstance_604565(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_604564(path: JsonNode; query: JsonNode;
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
  var valid_604566 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "PreferredMaintenanceWindow", valid_604566
  var valid_604567 = query.getOrDefault("AllocatedStorage")
  valid_604567 = validateParameter(valid_604567, JInt, required = false, default = nil)
  if valid_604567 != nil:
    section.add "AllocatedStorage", valid_604567
  var valid_604568 = query.getOrDefault("OptionGroupName")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "OptionGroupName", valid_604568
  var valid_604569 = query.getOrDefault("DBSecurityGroups")
  valid_604569 = validateParameter(valid_604569, JArray, required = false,
                                 default = nil)
  if valid_604569 != nil:
    section.add "DBSecurityGroups", valid_604569
  var valid_604570 = query.getOrDefault("MasterUserPassword")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "MasterUserPassword", valid_604570
  var valid_604571 = query.getOrDefault("Iops")
  valid_604571 = validateParameter(valid_604571, JInt, required = false, default = nil)
  if valid_604571 != nil:
    section.add "Iops", valid_604571
  var valid_604572 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604572 = validateParameter(valid_604572, JArray, required = false,
                                 default = nil)
  if valid_604572 != nil:
    section.add "VpcSecurityGroupIds", valid_604572
  var valid_604573 = query.getOrDefault("MultiAZ")
  valid_604573 = validateParameter(valid_604573, JBool, required = false, default = nil)
  if valid_604573 != nil:
    section.add "MultiAZ", valid_604573
  var valid_604574 = query.getOrDefault("BackupRetentionPeriod")
  valid_604574 = validateParameter(valid_604574, JInt, required = false, default = nil)
  if valid_604574 != nil:
    section.add "BackupRetentionPeriod", valid_604574
  var valid_604575 = query.getOrDefault("DBParameterGroupName")
  valid_604575 = validateParameter(valid_604575, JString, required = false,
                                 default = nil)
  if valid_604575 != nil:
    section.add "DBParameterGroupName", valid_604575
  var valid_604576 = query.getOrDefault("DBInstanceClass")
  valid_604576 = validateParameter(valid_604576, JString, required = false,
                                 default = nil)
  if valid_604576 != nil:
    section.add "DBInstanceClass", valid_604576
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604577 = query.getOrDefault("Action")
  valid_604577 = validateParameter(valid_604577, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604577 != nil:
    section.add "Action", valid_604577
  var valid_604578 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_604578 = validateParameter(valid_604578, JBool, required = false, default = nil)
  if valid_604578 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604578
  var valid_604579 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604579 = validateParameter(valid_604579, JString, required = false,
                                 default = nil)
  if valid_604579 != nil:
    section.add "NewDBInstanceIdentifier", valid_604579
  var valid_604580 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604580 = validateParameter(valid_604580, JBool, required = false, default = nil)
  if valid_604580 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604580
  var valid_604581 = query.getOrDefault("EngineVersion")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "EngineVersion", valid_604581
  var valid_604582 = query.getOrDefault("PreferredBackupWindow")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "PreferredBackupWindow", valid_604582
  var valid_604583 = query.getOrDefault("Version")
  valid_604583 = validateParameter(valid_604583, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604583 != nil:
    section.add "Version", valid_604583
  var valid_604584 = query.getOrDefault("DBInstanceIdentifier")
  valid_604584 = validateParameter(valid_604584, JString, required = true,
                                 default = nil)
  if valid_604584 != nil:
    section.add "DBInstanceIdentifier", valid_604584
  var valid_604585 = query.getOrDefault("ApplyImmediately")
  valid_604585 = validateParameter(valid_604585, JBool, required = false, default = nil)
  if valid_604585 != nil:
    section.add "ApplyImmediately", valid_604585
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604586 = header.getOrDefault("X-Amz-Date")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Date", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Security-Token")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Security-Token", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-Content-Sha256", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Algorithm")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Algorithm", valid_604589
  var valid_604590 = header.getOrDefault("X-Amz-Signature")
  valid_604590 = validateParameter(valid_604590, JString, required = false,
                                 default = nil)
  if valid_604590 != nil:
    section.add "X-Amz-Signature", valid_604590
  var valid_604591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604591 = validateParameter(valid_604591, JString, required = false,
                                 default = nil)
  if valid_604591 != nil:
    section.add "X-Amz-SignedHeaders", valid_604591
  var valid_604592 = header.getOrDefault("X-Amz-Credential")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "X-Amz-Credential", valid_604592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604593: Call_GetModifyDBInstance_604563; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604593.validator(path, query, header, formData, body)
  let scheme = call_604593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604593.url(scheme.get, call_604593.host, call_604593.base,
                         call_604593.route, valid.getOrDefault("path"))
  result = hook(call_604593, url, valid)

proc call*(call_604594: Call_GetModifyDBInstance_604563;
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
  var query_604595 = newJObject()
  add(query_604595, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604595, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_604595, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_604595.add "DBSecurityGroups", DBSecurityGroups
  add(query_604595, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_604595, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_604595.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_604595, "MultiAZ", newJBool(MultiAZ))
  add(query_604595, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604595, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604595, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604595, "Action", newJString(Action))
  add(query_604595, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_604595, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604595, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604595, "EngineVersion", newJString(EngineVersion))
  add(query_604595, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604595, "Version", newJString(Version))
  add(query_604595, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604595, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604594.call(nil, query_604595, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604563(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604564, base: "/",
    url: url_GetModifyDBInstance_604565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_604647 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBParameterGroup_604649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_604648(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604650 = query.getOrDefault("Action")
  valid_604650 = validateParameter(valid_604650, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604650 != nil:
    section.add "Action", valid_604650
  var valid_604651 = query.getOrDefault("Version")
  valid_604651 = validateParameter(valid_604651, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604651 != nil:
    section.add "Version", valid_604651
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604652 = header.getOrDefault("X-Amz-Date")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-Date", valid_604652
  var valid_604653 = header.getOrDefault("X-Amz-Security-Token")
  valid_604653 = validateParameter(valid_604653, JString, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "X-Amz-Security-Token", valid_604653
  var valid_604654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604654 = validateParameter(valid_604654, JString, required = false,
                                 default = nil)
  if valid_604654 != nil:
    section.add "X-Amz-Content-Sha256", valid_604654
  var valid_604655 = header.getOrDefault("X-Amz-Algorithm")
  valid_604655 = validateParameter(valid_604655, JString, required = false,
                                 default = nil)
  if valid_604655 != nil:
    section.add "X-Amz-Algorithm", valid_604655
  var valid_604656 = header.getOrDefault("X-Amz-Signature")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "X-Amz-Signature", valid_604656
  var valid_604657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "X-Amz-SignedHeaders", valid_604657
  var valid_604658 = header.getOrDefault("X-Amz-Credential")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "X-Amz-Credential", valid_604658
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604659 = formData.getOrDefault("DBParameterGroupName")
  valid_604659 = validateParameter(valid_604659, JString, required = true,
                                 default = nil)
  if valid_604659 != nil:
    section.add "DBParameterGroupName", valid_604659
  var valid_604660 = formData.getOrDefault("Parameters")
  valid_604660 = validateParameter(valid_604660, JArray, required = true, default = nil)
  if valid_604660 != nil:
    section.add "Parameters", valid_604660
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604661: Call_PostModifyDBParameterGroup_604647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604661.validator(path, query, header, formData, body)
  let scheme = call_604661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604661.url(scheme.get, call_604661.host, call_604661.base,
                         call_604661.route, valid.getOrDefault("path"))
  result = hook(call_604661, url, valid)

proc call*(call_604662: Call_PostModifyDBParameterGroup_604647;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604663 = newJObject()
  var formData_604664 = newJObject()
  add(formData_604664, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604664.add "Parameters", Parameters
  add(query_604663, "Action", newJString(Action))
  add(query_604663, "Version", newJString(Version))
  result = call_604662.call(nil, query_604663, nil, formData_604664, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_604647(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_604648, base: "/",
    url: url_PostModifyDBParameterGroup_604649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_604630 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBParameterGroup_604632(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_604631(path: JsonNode; query: JsonNode;
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
  var valid_604633 = query.getOrDefault("DBParameterGroupName")
  valid_604633 = validateParameter(valid_604633, JString, required = true,
                                 default = nil)
  if valid_604633 != nil:
    section.add "DBParameterGroupName", valid_604633
  var valid_604634 = query.getOrDefault("Parameters")
  valid_604634 = validateParameter(valid_604634, JArray, required = true, default = nil)
  if valid_604634 != nil:
    section.add "Parameters", valid_604634
  var valid_604635 = query.getOrDefault("Action")
  valid_604635 = validateParameter(valid_604635, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604635 != nil:
    section.add "Action", valid_604635
  var valid_604636 = query.getOrDefault("Version")
  valid_604636 = validateParameter(valid_604636, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604636 != nil:
    section.add "Version", valid_604636
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604637 = header.getOrDefault("X-Amz-Date")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-Date", valid_604637
  var valid_604638 = header.getOrDefault("X-Amz-Security-Token")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "X-Amz-Security-Token", valid_604638
  var valid_604639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604639 = validateParameter(valid_604639, JString, required = false,
                                 default = nil)
  if valid_604639 != nil:
    section.add "X-Amz-Content-Sha256", valid_604639
  var valid_604640 = header.getOrDefault("X-Amz-Algorithm")
  valid_604640 = validateParameter(valid_604640, JString, required = false,
                                 default = nil)
  if valid_604640 != nil:
    section.add "X-Amz-Algorithm", valid_604640
  var valid_604641 = header.getOrDefault("X-Amz-Signature")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "X-Amz-Signature", valid_604641
  var valid_604642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604642 = validateParameter(valid_604642, JString, required = false,
                                 default = nil)
  if valid_604642 != nil:
    section.add "X-Amz-SignedHeaders", valid_604642
  var valid_604643 = header.getOrDefault("X-Amz-Credential")
  valid_604643 = validateParameter(valid_604643, JString, required = false,
                                 default = nil)
  if valid_604643 != nil:
    section.add "X-Amz-Credential", valid_604643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604644: Call_GetModifyDBParameterGroup_604630; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604644.validator(path, query, header, formData, body)
  let scheme = call_604644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604644.url(scheme.get, call_604644.host, call_604644.base,
                         call_604644.route, valid.getOrDefault("path"))
  result = hook(call_604644, url, valid)

proc call*(call_604645: Call_GetModifyDBParameterGroup_604630;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604646 = newJObject()
  add(query_604646, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604646.add "Parameters", Parameters
  add(query_604646, "Action", newJString(Action))
  add(query_604646, "Version", newJString(Version))
  result = call_604645.call(nil, query_604646, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_604630(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_604631, base: "/",
    url: url_GetModifyDBParameterGroup_604632,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604683 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBSubnetGroup_604685(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_604684(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604686 = query.getOrDefault("Action")
  valid_604686 = validateParameter(valid_604686, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604686 != nil:
    section.add "Action", valid_604686
  var valid_604687 = query.getOrDefault("Version")
  valid_604687 = validateParameter(valid_604687, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604687 != nil:
    section.add "Version", valid_604687
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604688 = header.getOrDefault("X-Amz-Date")
  valid_604688 = validateParameter(valid_604688, JString, required = false,
                                 default = nil)
  if valid_604688 != nil:
    section.add "X-Amz-Date", valid_604688
  var valid_604689 = header.getOrDefault("X-Amz-Security-Token")
  valid_604689 = validateParameter(valid_604689, JString, required = false,
                                 default = nil)
  if valid_604689 != nil:
    section.add "X-Amz-Security-Token", valid_604689
  var valid_604690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-Content-Sha256", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-Algorithm")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Algorithm", valid_604691
  var valid_604692 = header.getOrDefault("X-Amz-Signature")
  valid_604692 = validateParameter(valid_604692, JString, required = false,
                                 default = nil)
  if valid_604692 != nil:
    section.add "X-Amz-Signature", valid_604692
  var valid_604693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604693 = validateParameter(valid_604693, JString, required = false,
                                 default = nil)
  if valid_604693 != nil:
    section.add "X-Amz-SignedHeaders", valid_604693
  var valid_604694 = header.getOrDefault("X-Amz-Credential")
  valid_604694 = validateParameter(valid_604694, JString, required = false,
                                 default = nil)
  if valid_604694 != nil:
    section.add "X-Amz-Credential", valid_604694
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_604695 = formData.getOrDefault("DBSubnetGroupName")
  valid_604695 = validateParameter(valid_604695, JString, required = true,
                                 default = nil)
  if valid_604695 != nil:
    section.add "DBSubnetGroupName", valid_604695
  var valid_604696 = formData.getOrDefault("SubnetIds")
  valid_604696 = validateParameter(valid_604696, JArray, required = true, default = nil)
  if valid_604696 != nil:
    section.add "SubnetIds", valid_604696
  var valid_604697 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "DBSubnetGroupDescription", valid_604697
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604698: Call_PostModifyDBSubnetGroup_604683; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604698.validator(path, query, header, formData, body)
  let scheme = call_604698.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604698.url(scheme.get, call_604698.host, call_604698.base,
                         call_604698.route, valid.getOrDefault("path"))
  result = hook(call_604698, url, valid)

proc call*(call_604699: Call_PostModifyDBSubnetGroup_604683;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604700 = newJObject()
  var formData_604701 = newJObject()
  add(formData_604701, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604701.add "SubnetIds", SubnetIds
  add(query_604700, "Action", newJString(Action))
  add(formData_604701, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604700, "Version", newJString(Version))
  result = call_604699.call(nil, query_604700, nil, formData_604701, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604683(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604684, base: "/",
    url: url_PostModifyDBSubnetGroup_604685, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604665 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBSubnetGroup_604667(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_604666(path: JsonNode; query: JsonNode;
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
  var valid_604668 = query.getOrDefault("Action")
  valid_604668 = validateParameter(valid_604668, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604668 != nil:
    section.add "Action", valid_604668
  var valid_604669 = query.getOrDefault("DBSubnetGroupName")
  valid_604669 = validateParameter(valid_604669, JString, required = true,
                                 default = nil)
  if valid_604669 != nil:
    section.add "DBSubnetGroupName", valid_604669
  var valid_604670 = query.getOrDefault("SubnetIds")
  valid_604670 = validateParameter(valid_604670, JArray, required = true, default = nil)
  if valid_604670 != nil:
    section.add "SubnetIds", valid_604670
  var valid_604671 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "DBSubnetGroupDescription", valid_604671
  var valid_604672 = query.getOrDefault("Version")
  valid_604672 = validateParameter(valid_604672, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604672 != nil:
    section.add "Version", valid_604672
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604673 = header.getOrDefault("X-Amz-Date")
  valid_604673 = validateParameter(valid_604673, JString, required = false,
                                 default = nil)
  if valid_604673 != nil:
    section.add "X-Amz-Date", valid_604673
  var valid_604674 = header.getOrDefault("X-Amz-Security-Token")
  valid_604674 = validateParameter(valid_604674, JString, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "X-Amz-Security-Token", valid_604674
  var valid_604675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Content-Sha256", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-Algorithm")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-Algorithm", valid_604676
  var valid_604677 = header.getOrDefault("X-Amz-Signature")
  valid_604677 = validateParameter(valid_604677, JString, required = false,
                                 default = nil)
  if valid_604677 != nil:
    section.add "X-Amz-Signature", valid_604677
  var valid_604678 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604678 = validateParameter(valid_604678, JString, required = false,
                                 default = nil)
  if valid_604678 != nil:
    section.add "X-Amz-SignedHeaders", valid_604678
  var valid_604679 = header.getOrDefault("X-Amz-Credential")
  valid_604679 = validateParameter(valid_604679, JString, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "X-Amz-Credential", valid_604679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604680: Call_GetModifyDBSubnetGroup_604665; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604680.validator(path, query, header, formData, body)
  let scheme = call_604680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604680.url(scheme.get, call_604680.host, call_604680.base,
                         call_604680.route, valid.getOrDefault("path"))
  result = hook(call_604680, url, valid)

proc call*(call_604681: Call_GetModifyDBSubnetGroup_604665;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604682 = newJObject()
  add(query_604682, "Action", newJString(Action))
  add(query_604682, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604682.add "SubnetIds", SubnetIds
  add(query_604682, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604682, "Version", newJString(Version))
  result = call_604681.call(nil, query_604682, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604665(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604666, base: "/",
    url: url_GetModifyDBSubnetGroup_604667, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_604722 = ref object of OpenApiRestCall_602417
proc url_PostModifyEventSubscription_604724(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_604723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604725 = query.getOrDefault("Action")
  valid_604725 = validateParameter(valid_604725, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604725 != nil:
    section.add "Action", valid_604725
  var valid_604726 = query.getOrDefault("Version")
  valid_604726 = validateParameter(valid_604726, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604726 != nil:
    section.add "Version", valid_604726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604727 = header.getOrDefault("X-Amz-Date")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-Date", valid_604727
  var valid_604728 = header.getOrDefault("X-Amz-Security-Token")
  valid_604728 = validateParameter(valid_604728, JString, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "X-Amz-Security-Token", valid_604728
  var valid_604729 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604729 = validateParameter(valid_604729, JString, required = false,
                                 default = nil)
  if valid_604729 != nil:
    section.add "X-Amz-Content-Sha256", valid_604729
  var valid_604730 = header.getOrDefault("X-Amz-Algorithm")
  valid_604730 = validateParameter(valid_604730, JString, required = false,
                                 default = nil)
  if valid_604730 != nil:
    section.add "X-Amz-Algorithm", valid_604730
  var valid_604731 = header.getOrDefault("X-Amz-Signature")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "X-Amz-Signature", valid_604731
  var valid_604732 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604732 = validateParameter(valid_604732, JString, required = false,
                                 default = nil)
  if valid_604732 != nil:
    section.add "X-Amz-SignedHeaders", valid_604732
  var valid_604733 = header.getOrDefault("X-Amz-Credential")
  valid_604733 = validateParameter(valid_604733, JString, required = false,
                                 default = nil)
  if valid_604733 != nil:
    section.add "X-Amz-Credential", valid_604733
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_604734 = formData.getOrDefault("Enabled")
  valid_604734 = validateParameter(valid_604734, JBool, required = false, default = nil)
  if valid_604734 != nil:
    section.add "Enabled", valid_604734
  var valid_604735 = formData.getOrDefault("EventCategories")
  valid_604735 = validateParameter(valid_604735, JArray, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "EventCategories", valid_604735
  var valid_604736 = formData.getOrDefault("SnsTopicArn")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "SnsTopicArn", valid_604736
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_604737 = formData.getOrDefault("SubscriptionName")
  valid_604737 = validateParameter(valid_604737, JString, required = true,
                                 default = nil)
  if valid_604737 != nil:
    section.add "SubscriptionName", valid_604737
  var valid_604738 = formData.getOrDefault("SourceType")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "SourceType", valid_604738
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604739: Call_PostModifyEventSubscription_604722; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604739.validator(path, query, header, formData, body)
  let scheme = call_604739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604739.url(scheme.get, call_604739.host, call_604739.base,
                         call_604739.route, valid.getOrDefault("path"))
  result = hook(call_604739, url, valid)

proc call*(call_604740: Call_PostModifyEventSubscription_604722;
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
  var query_604741 = newJObject()
  var formData_604742 = newJObject()
  add(formData_604742, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_604742.add "EventCategories", EventCategories
  add(formData_604742, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_604742, "SubscriptionName", newJString(SubscriptionName))
  add(query_604741, "Action", newJString(Action))
  add(query_604741, "Version", newJString(Version))
  add(formData_604742, "SourceType", newJString(SourceType))
  result = call_604740.call(nil, query_604741, nil, formData_604742, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_604722(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_604723, base: "/",
    url: url_PostModifyEventSubscription_604724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_604702 = ref object of OpenApiRestCall_602417
proc url_GetModifyEventSubscription_604704(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_604703(path: JsonNode; query: JsonNode;
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
  var valid_604705 = query.getOrDefault("SourceType")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "SourceType", valid_604705
  var valid_604706 = query.getOrDefault("Enabled")
  valid_604706 = validateParameter(valid_604706, JBool, required = false, default = nil)
  if valid_604706 != nil:
    section.add "Enabled", valid_604706
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604707 = query.getOrDefault("Action")
  valid_604707 = validateParameter(valid_604707, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604707 != nil:
    section.add "Action", valid_604707
  var valid_604708 = query.getOrDefault("SnsTopicArn")
  valid_604708 = validateParameter(valid_604708, JString, required = false,
                                 default = nil)
  if valid_604708 != nil:
    section.add "SnsTopicArn", valid_604708
  var valid_604709 = query.getOrDefault("EventCategories")
  valid_604709 = validateParameter(valid_604709, JArray, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "EventCategories", valid_604709
  var valid_604710 = query.getOrDefault("SubscriptionName")
  valid_604710 = validateParameter(valid_604710, JString, required = true,
                                 default = nil)
  if valid_604710 != nil:
    section.add "SubscriptionName", valid_604710
  var valid_604711 = query.getOrDefault("Version")
  valid_604711 = validateParameter(valid_604711, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604711 != nil:
    section.add "Version", valid_604711
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604712 = header.getOrDefault("X-Amz-Date")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Date", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-Security-Token")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-Security-Token", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-Content-Sha256", valid_604714
  var valid_604715 = header.getOrDefault("X-Amz-Algorithm")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-Algorithm", valid_604715
  var valid_604716 = header.getOrDefault("X-Amz-Signature")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "X-Amz-Signature", valid_604716
  var valid_604717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604717 = validateParameter(valid_604717, JString, required = false,
                                 default = nil)
  if valid_604717 != nil:
    section.add "X-Amz-SignedHeaders", valid_604717
  var valid_604718 = header.getOrDefault("X-Amz-Credential")
  valid_604718 = validateParameter(valid_604718, JString, required = false,
                                 default = nil)
  if valid_604718 != nil:
    section.add "X-Amz-Credential", valid_604718
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604719: Call_GetModifyEventSubscription_604702; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604719.validator(path, query, header, formData, body)
  let scheme = call_604719.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604719.url(scheme.get, call_604719.host, call_604719.base,
                         call_604719.route, valid.getOrDefault("path"))
  result = hook(call_604719, url, valid)

proc call*(call_604720: Call_GetModifyEventSubscription_604702;
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
  var query_604721 = newJObject()
  add(query_604721, "SourceType", newJString(SourceType))
  add(query_604721, "Enabled", newJBool(Enabled))
  add(query_604721, "Action", newJString(Action))
  add(query_604721, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_604721.add "EventCategories", EventCategories
  add(query_604721, "SubscriptionName", newJString(SubscriptionName))
  add(query_604721, "Version", newJString(Version))
  result = call_604720.call(nil, query_604721, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_604702(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_604703, base: "/",
    url: url_GetModifyEventSubscription_604704,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_604762 = ref object of OpenApiRestCall_602417
proc url_PostModifyOptionGroup_604764(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_604763(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604765 = query.getOrDefault("Action")
  valid_604765 = validateParameter(valid_604765, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604765 != nil:
    section.add "Action", valid_604765
  var valid_604766 = query.getOrDefault("Version")
  valid_604766 = validateParameter(valid_604766, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604766 != nil:
    section.add "Version", valid_604766
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604767 = header.getOrDefault("X-Amz-Date")
  valid_604767 = validateParameter(valid_604767, JString, required = false,
                                 default = nil)
  if valid_604767 != nil:
    section.add "X-Amz-Date", valid_604767
  var valid_604768 = header.getOrDefault("X-Amz-Security-Token")
  valid_604768 = validateParameter(valid_604768, JString, required = false,
                                 default = nil)
  if valid_604768 != nil:
    section.add "X-Amz-Security-Token", valid_604768
  var valid_604769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604769 = validateParameter(valid_604769, JString, required = false,
                                 default = nil)
  if valid_604769 != nil:
    section.add "X-Amz-Content-Sha256", valid_604769
  var valid_604770 = header.getOrDefault("X-Amz-Algorithm")
  valid_604770 = validateParameter(valid_604770, JString, required = false,
                                 default = nil)
  if valid_604770 != nil:
    section.add "X-Amz-Algorithm", valid_604770
  var valid_604771 = header.getOrDefault("X-Amz-Signature")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-Signature", valid_604771
  var valid_604772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604772 = validateParameter(valid_604772, JString, required = false,
                                 default = nil)
  if valid_604772 != nil:
    section.add "X-Amz-SignedHeaders", valid_604772
  var valid_604773 = header.getOrDefault("X-Amz-Credential")
  valid_604773 = validateParameter(valid_604773, JString, required = false,
                                 default = nil)
  if valid_604773 != nil:
    section.add "X-Amz-Credential", valid_604773
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_604774 = formData.getOrDefault("OptionsToRemove")
  valid_604774 = validateParameter(valid_604774, JArray, required = false,
                                 default = nil)
  if valid_604774 != nil:
    section.add "OptionsToRemove", valid_604774
  var valid_604775 = formData.getOrDefault("ApplyImmediately")
  valid_604775 = validateParameter(valid_604775, JBool, required = false, default = nil)
  if valid_604775 != nil:
    section.add "ApplyImmediately", valid_604775
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_604776 = formData.getOrDefault("OptionGroupName")
  valid_604776 = validateParameter(valid_604776, JString, required = true,
                                 default = nil)
  if valid_604776 != nil:
    section.add "OptionGroupName", valid_604776
  var valid_604777 = formData.getOrDefault("OptionsToInclude")
  valid_604777 = validateParameter(valid_604777, JArray, required = false,
                                 default = nil)
  if valid_604777 != nil:
    section.add "OptionsToInclude", valid_604777
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604778: Call_PostModifyOptionGroup_604762; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604778.validator(path, query, header, formData, body)
  let scheme = call_604778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604778.url(scheme.get, call_604778.host, call_604778.base,
                         call_604778.route, valid.getOrDefault("path"))
  result = hook(call_604778, url, valid)

proc call*(call_604779: Call_PostModifyOptionGroup_604762; OptionGroupName: string;
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
  var query_604780 = newJObject()
  var formData_604781 = newJObject()
  if OptionsToRemove != nil:
    formData_604781.add "OptionsToRemove", OptionsToRemove
  add(formData_604781, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604781, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_604781.add "OptionsToInclude", OptionsToInclude
  add(query_604780, "Action", newJString(Action))
  add(query_604780, "Version", newJString(Version))
  result = call_604779.call(nil, query_604780, nil, formData_604781, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_604762(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_604763, base: "/",
    url: url_PostModifyOptionGroup_604764, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_604743 = ref object of OpenApiRestCall_602417
proc url_GetModifyOptionGroup_604745(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_604744(path: JsonNode; query: JsonNode;
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
  var valid_604746 = query.getOrDefault("OptionGroupName")
  valid_604746 = validateParameter(valid_604746, JString, required = true,
                                 default = nil)
  if valid_604746 != nil:
    section.add "OptionGroupName", valid_604746
  var valid_604747 = query.getOrDefault("OptionsToRemove")
  valid_604747 = validateParameter(valid_604747, JArray, required = false,
                                 default = nil)
  if valid_604747 != nil:
    section.add "OptionsToRemove", valid_604747
  var valid_604748 = query.getOrDefault("Action")
  valid_604748 = validateParameter(valid_604748, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604748 != nil:
    section.add "Action", valid_604748
  var valid_604749 = query.getOrDefault("Version")
  valid_604749 = validateParameter(valid_604749, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604749 != nil:
    section.add "Version", valid_604749
  var valid_604750 = query.getOrDefault("ApplyImmediately")
  valid_604750 = validateParameter(valid_604750, JBool, required = false, default = nil)
  if valid_604750 != nil:
    section.add "ApplyImmediately", valid_604750
  var valid_604751 = query.getOrDefault("OptionsToInclude")
  valid_604751 = validateParameter(valid_604751, JArray, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "OptionsToInclude", valid_604751
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604752 = header.getOrDefault("X-Amz-Date")
  valid_604752 = validateParameter(valid_604752, JString, required = false,
                                 default = nil)
  if valid_604752 != nil:
    section.add "X-Amz-Date", valid_604752
  var valid_604753 = header.getOrDefault("X-Amz-Security-Token")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-Security-Token", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-Content-Sha256", valid_604754
  var valid_604755 = header.getOrDefault("X-Amz-Algorithm")
  valid_604755 = validateParameter(valid_604755, JString, required = false,
                                 default = nil)
  if valid_604755 != nil:
    section.add "X-Amz-Algorithm", valid_604755
  var valid_604756 = header.getOrDefault("X-Amz-Signature")
  valid_604756 = validateParameter(valid_604756, JString, required = false,
                                 default = nil)
  if valid_604756 != nil:
    section.add "X-Amz-Signature", valid_604756
  var valid_604757 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604757 = validateParameter(valid_604757, JString, required = false,
                                 default = nil)
  if valid_604757 != nil:
    section.add "X-Amz-SignedHeaders", valid_604757
  var valid_604758 = header.getOrDefault("X-Amz-Credential")
  valid_604758 = validateParameter(valid_604758, JString, required = false,
                                 default = nil)
  if valid_604758 != nil:
    section.add "X-Amz-Credential", valid_604758
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604759: Call_GetModifyOptionGroup_604743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604759.validator(path, query, header, formData, body)
  let scheme = call_604759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604759.url(scheme.get, call_604759.host, call_604759.base,
                         call_604759.route, valid.getOrDefault("path"))
  result = hook(call_604759, url, valid)

proc call*(call_604760: Call_GetModifyOptionGroup_604743; OptionGroupName: string;
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
  var query_604761 = newJObject()
  add(query_604761, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_604761.add "OptionsToRemove", OptionsToRemove
  add(query_604761, "Action", newJString(Action))
  add(query_604761, "Version", newJString(Version))
  add(query_604761, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_604761.add "OptionsToInclude", OptionsToInclude
  result = call_604760.call(nil, query_604761, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_604743(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_604744, base: "/",
    url: url_GetModifyOptionGroup_604745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_604800 = ref object of OpenApiRestCall_602417
proc url_PostPromoteReadReplica_604802(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_604801(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604803 = query.getOrDefault("Action")
  valid_604803 = validateParameter(valid_604803, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604803 != nil:
    section.add "Action", valid_604803
  var valid_604804 = query.getOrDefault("Version")
  valid_604804 = validateParameter(valid_604804, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604804 != nil:
    section.add "Version", valid_604804
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604805 = header.getOrDefault("X-Amz-Date")
  valid_604805 = validateParameter(valid_604805, JString, required = false,
                                 default = nil)
  if valid_604805 != nil:
    section.add "X-Amz-Date", valid_604805
  var valid_604806 = header.getOrDefault("X-Amz-Security-Token")
  valid_604806 = validateParameter(valid_604806, JString, required = false,
                                 default = nil)
  if valid_604806 != nil:
    section.add "X-Amz-Security-Token", valid_604806
  var valid_604807 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604807 = validateParameter(valid_604807, JString, required = false,
                                 default = nil)
  if valid_604807 != nil:
    section.add "X-Amz-Content-Sha256", valid_604807
  var valid_604808 = header.getOrDefault("X-Amz-Algorithm")
  valid_604808 = validateParameter(valid_604808, JString, required = false,
                                 default = nil)
  if valid_604808 != nil:
    section.add "X-Amz-Algorithm", valid_604808
  var valid_604809 = header.getOrDefault("X-Amz-Signature")
  valid_604809 = validateParameter(valid_604809, JString, required = false,
                                 default = nil)
  if valid_604809 != nil:
    section.add "X-Amz-Signature", valid_604809
  var valid_604810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-SignedHeaders", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Credential")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Credential", valid_604811
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604812 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604812 = validateParameter(valid_604812, JString, required = true,
                                 default = nil)
  if valid_604812 != nil:
    section.add "DBInstanceIdentifier", valid_604812
  var valid_604813 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604813 = validateParameter(valid_604813, JInt, required = false, default = nil)
  if valid_604813 != nil:
    section.add "BackupRetentionPeriod", valid_604813
  var valid_604814 = formData.getOrDefault("PreferredBackupWindow")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "PreferredBackupWindow", valid_604814
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604815: Call_PostPromoteReadReplica_604800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604815.validator(path, query, header, formData, body)
  let scheme = call_604815.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604815.url(scheme.get, call_604815.host, call_604815.base,
                         call_604815.route, valid.getOrDefault("path"))
  result = hook(call_604815, url, valid)

proc call*(call_604816: Call_PostPromoteReadReplica_604800;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_604817 = newJObject()
  var formData_604818 = newJObject()
  add(formData_604818, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604818, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604817, "Action", newJString(Action))
  add(formData_604818, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604817, "Version", newJString(Version))
  result = call_604816.call(nil, query_604817, nil, formData_604818, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_604800(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_604801, base: "/",
    url: url_PostPromoteReadReplica_604802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_604782 = ref object of OpenApiRestCall_602417
proc url_GetPromoteReadReplica_604784(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_604783(path: JsonNode; query: JsonNode;
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
  var valid_604785 = query.getOrDefault("BackupRetentionPeriod")
  valid_604785 = validateParameter(valid_604785, JInt, required = false, default = nil)
  if valid_604785 != nil:
    section.add "BackupRetentionPeriod", valid_604785
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604786 = query.getOrDefault("Action")
  valid_604786 = validateParameter(valid_604786, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604786 != nil:
    section.add "Action", valid_604786
  var valid_604787 = query.getOrDefault("PreferredBackupWindow")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "PreferredBackupWindow", valid_604787
  var valid_604788 = query.getOrDefault("Version")
  valid_604788 = validateParameter(valid_604788, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604788 != nil:
    section.add "Version", valid_604788
  var valid_604789 = query.getOrDefault("DBInstanceIdentifier")
  valid_604789 = validateParameter(valid_604789, JString, required = true,
                                 default = nil)
  if valid_604789 != nil:
    section.add "DBInstanceIdentifier", valid_604789
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604790 = header.getOrDefault("X-Amz-Date")
  valid_604790 = validateParameter(valid_604790, JString, required = false,
                                 default = nil)
  if valid_604790 != nil:
    section.add "X-Amz-Date", valid_604790
  var valid_604791 = header.getOrDefault("X-Amz-Security-Token")
  valid_604791 = validateParameter(valid_604791, JString, required = false,
                                 default = nil)
  if valid_604791 != nil:
    section.add "X-Amz-Security-Token", valid_604791
  var valid_604792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604792 = validateParameter(valid_604792, JString, required = false,
                                 default = nil)
  if valid_604792 != nil:
    section.add "X-Amz-Content-Sha256", valid_604792
  var valid_604793 = header.getOrDefault("X-Amz-Algorithm")
  valid_604793 = validateParameter(valid_604793, JString, required = false,
                                 default = nil)
  if valid_604793 != nil:
    section.add "X-Amz-Algorithm", valid_604793
  var valid_604794 = header.getOrDefault("X-Amz-Signature")
  valid_604794 = validateParameter(valid_604794, JString, required = false,
                                 default = nil)
  if valid_604794 != nil:
    section.add "X-Amz-Signature", valid_604794
  var valid_604795 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604795 = validateParameter(valid_604795, JString, required = false,
                                 default = nil)
  if valid_604795 != nil:
    section.add "X-Amz-SignedHeaders", valid_604795
  var valid_604796 = header.getOrDefault("X-Amz-Credential")
  valid_604796 = validateParameter(valid_604796, JString, required = false,
                                 default = nil)
  if valid_604796 != nil:
    section.add "X-Amz-Credential", valid_604796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604797: Call_GetPromoteReadReplica_604782; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604797.validator(path, query, header, formData, body)
  let scheme = call_604797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604797.url(scheme.get, call_604797.host, call_604797.base,
                         call_604797.route, valid.getOrDefault("path"))
  result = hook(call_604797, url, valid)

proc call*(call_604798: Call_GetPromoteReadReplica_604782;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604799 = newJObject()
  add(query_604799, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604799, "Action", newJString(Action))
  add(query_604799, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604799, "Version", newJString(Version))
  add(query_604799, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604798.call(nil, query_604799, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_604782(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_604783, base: "/",
    url: url_GetPromoteReadReplica_604784, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_604838 = ref object of OpenApiRestCall_602417
proc url_PostPurchaseReservedDBInstancesOffering_604840(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_604839(path: JsonNode;
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
  var valid_604841 = query.getOrDefault("Action")
  valid_604841 = validateParameter(valid_604841, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604841 != nil:
    section.add "Action", valid_604841
  var valid_604842 = query.getOrDefault("Version")
  valid_604842 = validateParameter(valid_604842, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604842 != nil:
    section.add "Version", valid_604842
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604843 = header.getOrDefault("X-Amz-Date")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Date", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Security-Token")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Security-Token", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Content-Sha256", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-Algorithm")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Algorithm", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-Signature")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-Signature", valid_604847
  var valid_604848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604848 = validateParameter(valid_604848, JString, required = false,
                                 default = nil)
  if valid_604848 != nil:
    section.add "X-Amz-SignedHeaders", valid_604848
  var valid_604849 = header.getOrDefault("X-Amz-Credential")
  valid_604849 = validateParameter(valid_604849, JString, required = false,
                                 default = nil)
  if valid_604849 != nil:
    section.add "X-Amz-Credential", valid_604849
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_604850 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604850 = validateParameter(valid_604850, JString, required = false,
                                 default = nil)
  if valid_604850 != nil:
    section.add "ReservedDBInstanceId", valid_604850
  var valid_604851 = formData.getOrDefault("Tags")
  valid_604851 = validateParameter(valid_604851, JArray, required = false,
                                 default = nil)
  if valid_604851 != nil:
    section.add "Tags", valid_604851
  var valid_604852 = formData.getOrDefault("DBInstanceCount")
  valid_604852 = validateParameter(valid_604852, JInt, required = false, default = nil)
  if valid_604852 != nil:
    section.add "DBInstanceCount", valid_604852
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604853 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604853 = validateParameter(valid_604853, JString, required = true,
                                 default = nil)
  if valid_604853 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604853
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604854: Call_PostPurchaseReservedDBInstancesOffering_604838;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604854.validator(path, query, header, formData, body)
  let scheme = call_604854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604854.url(scheme.get, call_604854.host, call_604854.base,
                         call_604854.route, valid.getOrDefault("path"))
  result = hook(call_604854, url, valid)

proc call*(call_604855: Call_PostPurchaseReservedDBInstancesOffering_604838;
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
  var query_604856 = newJObject()
  var formData_604857 = newJObject()
  add(formData_604857, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_604857.add "Tags", Tags
  add(formData_604857, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604856, "Action", newJString(Action))
  add(formData_604857, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604856, "Version", newJString(Version))
  result = call_604855.call(nil, query_604856, nil, formData_604857, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_604838(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_604839, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_604840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_604819 = ref object of OpenApiRestCall_602417
proc url_GetPurchaseReservedDBInstancesOffering_604821(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_604820(path: JsonNode;
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
  var valid_604822 = query.getOrDefault("DBInstanceCount")
  valid_604822 = validateParameter(valid_604822, JInt, required = false, default = nil)
  if valid_604822 != nil:
    section.add "DBInstanceCount", valid_604822
  var valid_604823 = query.getOrDefault("Tags")
  valid_604823 = validateParameter(valid_604823, JArray, required = false,
                                 default = nil)
  if valid_604823 != nil:
    section.add "Tags", valid_604823
  var valid_604824 = query.getOrDefault("ReservedDBInstanceId")
  valid_604824 = validateParameter(valid_604824, JString, required = false,
                                 default = nil)
  if valid_604824 != nil:
    section.add "ReservedDBInstanceId", valid_604824
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604825 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604825 = validateParameter(valid_604825, JString, required = true,
                                 default = nil)
  if valid_604825 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604825
  var valid_604826 = query.getOrDefault("Action")
  valid_604826 = validateParameter(valid_604826, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604826 != nil:
    section.add "Action", valid_604826
  var valid_604827 = query.getOrDefault("Version")
  valid_604827 = validateParameter(valid_604827, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604827 != nil:
    section.add "Version", valid_604827
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604828 = header.getOrDefault("X-Amz-Date")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-Date", valid_604828
  var valid_604829 = header.getOrDefault("X-Amz-Security-Token")
  valid_604829 = validateParameter(valid_604829, JString, required = false,
                                 default = nil)
  if valid_604829 != nil:
    section.add "X-Amz-Security-Token", valid_604829
  var valid_604830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604830 = validateParameter(valid_604830, JString, required = false,
                                 default = nil)
  if valid_604830 != nil:
    section.add "X-Amz-Content-Sha256", valid_604830
  var valid_604831 = header.getOrDefault("X-Amz-Algorithm")
  valid_604831 = validateParameter(valid_604831, JString, required = false,
                                 default = nil)
  if valid_604831 != nil:
    section.add "X-Amz-Algorithm", valid_604831
  var valid_604832 = header.getOrDefault("X-Amz-Signature")
  valid_604832 = validateParameter(valid_604832, JString, required = false,
                                 default = nil)
  if valid_604832 != nil:
    section.add "X-Amz-Signature", valid_604832
  var valid_604833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604833 = validateParameter(valid_604833, JString, required = false,
                                 default = nil)
  if valid_604833 != nil:
    section.add "X-Amz-SignedHeaders", valid_604833
  var valid_604834 = header.getOrDefault("X-Amz-Credential")
  valid_604834 = validateParameter(valid_604834, JString, required = false,
                                 default = nil)
  if valid_604834 != nil:
    section.add "X-Amz-Credential", valid_604834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604835: Call_GetPurchaseReservedDBInstancesOffering_604819;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604835.validator(path, query, header, formData, body)
  let scheme = call_604835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604835.url(scheme.get, call_604835.host, call_604835.base,
                         call_604835.route, valid.getOrDefault("path"))
  result = hook(call_604835, url, valid)

proc call*(call_604836: Call_GetPurchaseReservedDBInstancesOffering_604819;
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
  var query_604837 = newJObject()
  add(query_604837, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_604837.add "Tags", Tags
  add(query_604837, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604837, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604837, "Action", newJString(Action))
  add(query_604837, "Version", newJString(Version))
  result = call_604836.call(nil, query_604837, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_604819(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_604820, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_604821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604875 = ref object of OpenApiRestCall_602417
proc url_PostRebootDBInstance_604877(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_604876(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604878 = query.getOrDefault("Action")
  valid_604878 = validateParameter(valid_604878, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604878 != nil:
    section.add "Action", valid_604878
  var valid_604879 = query.getOrDefault("Version")
  valid_604879 = validateParameter(valid_604879, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604879 != nil:
    section.add "Version", valid_604879
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604880 = header.getOrDefault("X-Amz-Date")
  valid_604880 = validateParameter(valid_604880, JString, required = false,
                                 default = nil)
  if valid_604880 != nil:
    section.add "X-Amz-Date", valid_604880
  var valid_604881 = header.getOrDefault("X-Amz-Security-Token")
  valid_604881 = validateParameter(valid_604881, JString, required = false,
                                 default = nil)
  if valid_604881 != nil:
    section.add "X-Amz-Security-Token", valid_604881
  var valid_604882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604882 = validateParameter(valid_604882, JString, required = false,
                                 default = nil)
  if valid_604882 != nil:
    section.add "X-Amz-Content-Sha256", valid_604882
  var valid_604883 = header.getOrDefault("X-Amz-Algorithm")
  valid_604883 = validateParameter(valid_604883, JString, required = false,
                                 default = nil)
  if valid_604883 != nil:
    section.add "X-Amz-Algorithm", valid_604883
  var valid_604884 = header.getOrDefault("X-Amz-Signature")
  valid_604884 = validateParameter(valid_604884, JString, required = false,
                                 default = nil)
  if valid_604884 != nil:
    section.add "X-Amz-Signature", valid_604884
  var valid_604885 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604885 = validateParameter(valid_604885, JString, required = false,
                                 default = nil)
  if valid_604885 != nil:
    section.add "X-Amz-SignedHeaders", valid_604885
  var valid_604886 = header.getOrDefault("X-Amz-Credential")
  valid_604886 = validateParameter(valid_604886, JString, required = false,
                                 default = nil)
  if valid_604886 != nil:
    section.add "X-Amz-Credential", valid_604886
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604887 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604887 = validateParameter(valid_604887, JString, required = true,
                                 default = nil)
  if valid_604887 != nil:
    section.add "DBInstanceIdentifier", valid_604887
  var valid_604888 = formData.getOrDefault("ForceFailover")
  valid_604888 = validateParameter(valid_604888, JBool, required = false, default = nil)
  if valid_604888 != nil:
    section.add "ForceFailover", valid_604888
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604889: Call_PostRebootDBInstance_604875; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604889.validator(path, query, header, formData, body)
  let scheme = call_604889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604889.url(scheme.get, call_604889.host, call_604889.base,
                         call_604889.route, valid.getOrDefault("path"))
  result = hook(call_604889, url, valid)

proc call*(call_604890: Call_PostRebootDBInstance_604875;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_604891 = newJObject()
  var formData_604892 = newJObject()
  add(formData_604892, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604891, "Action", newJString(Action))
  add(formData_604892, "ForceFailover", newJBool(ForceFailover))
  add(query_604891, "Version", newJString(Version))
  result = call_604890.call(nil, query_604891, nil, formData_604892, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604875(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604876, base: "/",
    url: url_PostRebootDBInstance_604877, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604858 = ref object of OpenApiRestCall_602417
proc url_GetRebootDBInstance_604860(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_604859(path: JsonNode; query: JsonNode;
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
  var valid_604861 = query.getOrDefault("Action")
  valid_604861 = validateParameter(valid_604861, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604861 != nil:
    section.add "Action", valid_604861
  var valid_604862 = query.getOrDefault("ForceFailover")
  valid_604862 = validateParameter(valid_604862, JBool, required = false, default = nil)
  if valid_604862 != nil:
    section.add "ForceFailover", valid_604862
  var valid_604863 = query.getOrDefault("Version")
  valid_604863 = validateParameter(valid_604863, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604863 != nil:
    section.add "Version", valid_604863
  var valid_604864 = query.getOrDefault("DBInstanceIdentifier")
  valid_604864 = validateParameter(valid_604864, JString, required = true,
                                 default = nil)
  if valid_604864 != nil:
    section.add "DBInstanceIdentifier", valid_604864
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604865 = header.getOrDefault("X-Amz-Date")
  valid_604865 = validateParameter(valid_604865, JString, required = false,
                                 default = nil)
  if valid_604865 != nil:
    section.add "X-Amz-Date", valid_604865
  var valid_604866 = header.getOrDefault("X-Amz-Security-Token")
  valid_604866 = validateParameter(valid_604866, JString, required = false,
                                 default = nil)
  if valid_604866 != nil:
    section.add "X-Amz-Security-Token", valid_604866
  var valid_604867 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604867 = validateParameter(valid_604867, JString, required = false,
                                 default = nil)
  if valid_604867 != nil:
    section.add "X-Amz-Content-Sha256", valid_604867
  var valid_604868 = header.getOrDefault("X-Amz-Algorithm")
  valid_604868 = validateParameter(valid_604868, JString, required = false,
                                 default = nil)
  if valid_604868 != nil:
    section.add "X-Amz-Algorithm", valid_604868
  var valid_604869 = header.getOrDefault("X-Amz-Signature")
  valid_604869 = validateParameter(valid_604869, JString, required = false,
                                 default = nil)
  if valid_604869 != nil:
    section.add "X-Amz-Signature", valid_604869
  var valid_604870 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604870 = validateParameter(valid_604870, JString, required = false,
                                 default = nil)
  if valid_604870 != nil:
    section.add "X-Amz-SignedHeaders", valid_604870
  var valid_604871 = header.getOrDefault("X-Amz-Credential")
  valid_604871 = validateParameter(valid_604871, JString, required = false,
                                 default = nil)
  if valid_604871 != nil:
    section.add "X-Amz-Credential", valid_604871
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604872: Call_GetRebootDBInstance_604858; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604872.validator(path, query, header, formData, body)
  let scheme = call_604872.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604872.url(scheme.get, call_604872.host, call_604872.base,
                         call_604872.route, valid.getOrDefault("path"))
  result = hook(call_604872, url, valid)

proc call*(call_604873: Call_GetRebootDBInstance_604858;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604874 = newJObject()
  add(query_604874, "Action", newJString(Action))
  add(query_604874, "ForceFailover", newJBool(ForceFailover))
  add(query_604874, "Version", newJString(Version))
  add(query_604874, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604873.call(nil, query_604874, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604858(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604859, base: "/",
    url: url_GetRebootDBInstance_604860, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_604910 = ref object of OpenApiRestCall_602417
proc url_PostRemoveSourceIdentifierFromSubscription_604912(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_604911(path: JsonNode;
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
  var valid_604913 = query.getOrDefault("Action")
  valid_604913 = validateParameter(valid_604913, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604913 != nil:
    section.add "Action", valid_604913
  var valid_604914 = query.getOrDefault("Version")
  valid_604914 = validateParameter(valid_604914, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604914 != nil:
    section.add "Version", valid_604914
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604915 = header.getOrDefault("X-Amz-Date")
  valid_604915 = validateParameter(valid_604915, JString, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "X-Amz-Date", valid_604915
  var valid_604916 = header.getOrDefault("X-Amz-Security-Token")
  valid_604916 = validateParameter(valid_604916, JString, required = false,
                                 default = nil)
  if valid_604916 != nil:
    section.add "X-Amz-Security-Token", valid_604916
  var valid_604917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604917 = validateParameter(valid_604917, JString, required = false,
                                 default = nil)
  if valid_604917 != nil:
    section.add "X-Amz-Content-Sha256", valid_604917
  var valid_604918 = header.getOrDefault("X-Amz-Algorithm")
  valid_604918 = validateParameter(valid_604918, JString, required = false,
                                 default = nil)
  if valid_604918 != nil:
    section.add "X-Amz-Algorithm", valid_604918
  var valid_604919 = header.getOrDefault("X-Amz-Signature")
  valid_604919 = validateParameter(valid_604919, JString, required = false,
                                 default = nil)
  if valid_604919 != nil:
    section.add "X-Amz-Signature", valid_604919
  var valid_604920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604920 = validateParameter(valid_604920, JString, required = false,
                                 default = nil)
  if valid_604920 != nil:
    section.add "X-Amz-SignedHeaders", valid_604920
  var valid_604921 = header.getOrDefault("X-Amz-Credential")
  valid_604921 = validateParameter(valid_604921, JString, required = false,
                                 default = nil)
  if valid_604921 != nil:
    section.add "X-Amz-Credential", valid_604921
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_604922 = formData.getOrDefault("SourceIdentifier")
  valid_604922 = validateParameter(valid_604922, JString, required = true,
                                 default = nil)
  if valid_604922 != nil:
    section.add "SourceIdentifier", valid_604922
  var valid_604923 = formData.getOrDefault("SubscriptionName")
  valid_604923 = validateParameter(valid_604923, JString, required = true,
                                 default = nil)
  if valid_604923 != nil:
    section.add "SubscriptionName", valid_604923
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604924: Call_PostRemoveSourceIdentifierFromSubscription_604910;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604924.validator(path, query, header, formData, body)
  let scheme = call_604924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604924.url(scheme.get, call_604924.host, call_604924.base,
                         call_604924.route, valid.getOrDefault("path"))
  result = hook(call_604924, url, valid)

proc call*(call_604925: Call_PostRemoveSourceIdentifierFromSubscription_604910;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604926 = newJObject()
  var formData_604927 = newJObject()
  add(formData_604927, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_604927, "SubscriptionName", newJString(SubscriptionName))
  add(query_604926, "Action", newJString(Action))
  add(query_604926, "Version", newJString(Version))
  result = call_604925.call(nil, query_604926, nil, formData_604927, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_604910(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_604911,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_604912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_604893 = ref object of OpenApiRestCall_602417
proc url_GetRemoveSourceIdentifierFromSubscription_604895(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_604894(path: JsonNode;
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
  var valid_604896 = query.getOrDefault("Action")
  valid_604896 = validateParameter(valid_604896, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604896 != nil:
    section.add "Action", valid_604896
  var valid_604897 = query.getOrDefault("SourceIdentifier")
  valid_604897 = validateParameter(valid_604897, JString, required = true,
                                 default = nil)
  if valid_604897 != nil:
    section.add "SourceIdentifier", valid_604897
  var valid_604898 = query.getOrDefault("SubscriptionName")
  valid_604898 = validateParameter(valid_604898, JString, required = true,
                                 default = nil)
  if valid_604898 != nil:
    section.add "SubscriptionName", valid_604898
  var valid_604899 = query.getOrDefault("Version")
  valid_604899 = validateParameter(valid_604899, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604899 != nil:
    section.add "Version", valid_604899
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604900 = header.getOrDefault("X-Amz-Date")
  valid_604900 = validateParameter(valid_604900, JString, required = false,
                                 default = nil)
  if valid_604900 != nil:
    section.add "X-Amz-Date", valid_604900
  var valid_604901 = header.getOrDefault("X-Amz-Security-Token")
  valid_604901 = validateParameter(valid_604901, JString, required = false,
                                 default = nil)
  if valid_604901 != nil:
    section.add "X-Amz-Security-Token", valid_604901
  var valid_604902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604902 = validateParameter(valid_604902, JString, required = false,
                                 default = nil)
  if valid_604902 != nil:
    section.add "X-Amz-Content-Sha256", valid_604902
  var valid_604903 = header.getOrDefault("X-Amz-Algorithm")
  valid_604903 = validateParameter(valid_604903, JString, required = false,
                                 default = nil)
  if valid_604903 != nil:
    section.add "X-Amz-Algorithm", valid_604903
  var valid_604904 = header.getOrDefault("X-Amz-Signature")
  valid_604904 = validateParameter(valid_604904, JString, required = false,
                                 default = nil)
  if valid_604904 != nil:
    section.add "X-Amz-Signature", valid_604904
  var valid_604905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604905 = validateParameter(valid_604905, JString, required = false,
                                 default = nil)
  if valid_604905 != nil:
    section.add "X-Amz-SignedHeaders", valid_604905
  var valid_604906 = header.getOrDefault("X-Amz-Credential")
  valid_604906 = validateParameter(valid_604906, JString, required = false,
                                 default = nil)
  if valid_604906 != nil:
    section.add "X-Amz-Credential", valid_604906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604907: Call_GetRemoveSourceIdentifierFromSubscription_604893;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604907.validator(path, query, header, formData, body)
  let scheme = call_604907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604907.url(scheme.get, call_604907.host, call_604907.base,
                         call_604907.route, valid.getOrDefault("path"))
  result = hook(call_604907, url, valid)

proc call*(call_604908: Call_GetRemoveSourceIdentifierFromSubscription_604893;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_604909 = newJObject()
  add(query_604909, "Action", newJString(Action))
  add(query_604909, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604909, "SubscriptionName", newJString(SubscriptionName))
  add(query_604909, "Version", newJString(Version))
  result = call_604908.call(nil, query_604909, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_604893(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_604894,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_604895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_604945 = ref object of OpenApiRestCall_602417
proc url_PostRemoveTagsFromResource_604947(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_604946(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604948 = query.getOrDefault("Action")
  valid_604948 = validateParameter(valid_604948, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604948 != nil:
    section.add "Action", valid_604948
  var valid_604949 = query.getOrDefault("Version")
  valid_604949 = validateParameter(valid_604949, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604949 != nil:
    section.add "Version", valid_604949
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604950 = header.getOrDefault("X-Amz-Date")
  valid_604950 = validateParameter(valid_604950, JString, required = false,
                                 default = nil)
  if valid_604950 != nil:
    section.add "X-Amz-Date", valid_604950
  var valid_604951 = header.getOrDefault("X-Amz-Security-Token")
  valid_604951 = validateParameter(valid_604951, JString, required = false,
                                 default = nil)
  if valid_604951 != nil:
    section.add "X-Amz-Security-Token", valid_604951
  var valid_604952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604952 = validateParameter(valid_604952, JString, required = false,
                                 default = nil)
  if valid_604952 != nil:
    section.add "X-Amz-Content-Sha256", valid_604952
  var valid_604953 = header.getOrDefault("X-Amz-Algorithm")
  valid_604953 = validateParameter(valid_604953, JString, required = false,
                                 default = nil)
  if valid_604953 != nil:
    section.add "X-Amz-Algorithm", valid_604953
  var valid_604954 = header.getOrDefault("X-Amz-Signature")
  valid_604954 = validateParameter(valid_604954, JString, required = false,
                                 default = nil)
  if valid_604954 != nil:
    section.add "X-Amz-Signature", valid_604954
  var valid_604955 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604955 = validateParameter(valid_604955, JString, required = false,
                                 default = nil)
  if valid_604955 != nil:
    section.add "X-Amz-SignedHeaders", valid_604955
  var valid_604956 = header.getOrDefault("X-Amz-Credential")
  valid_604956 = validateParameter(valid_604956, JString, required = false,
                                 default = nil)
  if valid_604956 != nil:
    section.add "X-Amz-Credential", valid_604956
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604957 = formData.getOrDefault("TagKeys")
  valid_604957 = validateParameter(valid_604957, JArray, required = true, default = nil)
  if valid_604957 != nil:
    section.add "TagKeys", valid_604957
  var valid_604958 = formData.getOrDefault("ResourceName")
  valid_604958 = validateParameter(valid_604958, JString, required = true,
                                 default = nil)
  if valid_604958 != nil:
    section.add "ResourceName", valid_604958
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604959: Call_PostRemoveTagsFromResource_604945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604959.validator(path, query, header, formData, body)
  let scheme = call_604959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604959.url(scheme.get, call_604959.host, call_604959.base,
                         call_604959.route, valid.getOrDefault("path"))
  result = hook(call_604959, url, valid)

proc call*(call_604960: Call_PostRemoveTagsFromResource_604945; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604961 = newJObject()
  var formData_604962 = newJObject()
  add(query_604961, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604962.add "TagKeys", TagKeys
  add(formData_604962, "ResourceName", newJString(ResourceName))
  add(query_604961, "Version", newJString(Version))
  result = call_604960.call(nil, query_604961, nil, formData_604962, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_604945(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_604946, base: "/",
    url: url_PostRemoveTagsFromResource_604947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_604928 = ref object of OpenApiRestCall_602417
proc url_GetRemoveTagsFromResource_604930(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_604929(path: JsonNode; query: JsonNode;
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
  var valid_604931 = query.getOrDefault("ResourceName")
  valid_604931 = validateParameter(valid_604931, JString, required = true,
                                 default = nil)
  if valid_604931 != nil:
    section.add "ResourceName", valid_604931
  var valid_604932 = query.getOrDefault("Action")
  valid_604932 = validateParameter(valid_604932, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604932 != nil:
    section.add "Action", valid_604932
  var valid_604933 = query.getOrDefault("TagKeys")
  valid_604933 = validateParameter(valid_604933, JArray, required = true, default = nil)
  if valid_604933 != nil:
    section.add "TagKeys", valid_604933
  var valid_604934 = query.getOrDefault("Version")
  valid_604934 = validateParameter(valid_604934, JString, required = true,
                                 default = newJString("2013-09-09"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604942: Call_GetRemoveTagsFromResource_604928; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604942.validator(path, query, header, formData, body)
  let scheme = call_604942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604942.url(scheme.get, call_604942.host, call_604942.base,
                         call_604942.route, valid.getOrDefault("path"))
  result = hook(call_604942, url, valid)

proc call*(call_604943: Call_GetRemoveTagsFromResource_604928;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_604944 = newJObject()
  add(query_604944, "ResourceName", newJString(ResourceName))
  add(query_604944, "Action", newJString(Action))
  if TagKeys != nil:
    query_604944.add "TagKeys", TagKeys
  add(query_604944, "Version", newJString(Version))
  result = call_604943.call(nil, query_604944, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_604928(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_604929, base: "/",
    url: url_GetRemoveTagsFromResource_604930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_604981 = ref object of OpenApiRestCall_602417
proc url_PostResetDBParameterGroup_604983(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_604982(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604984 = query.getOrDefault("Action")
  valid_604984 = validateParameter(valid_604984, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604984 != nil:
    section.add "Action", valid_604984
  var valid_604985 = query.getOrDefault("Version")
  valid_604985 = validateParameter(valid_604985, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604985 != nil:
    section.add "Version", valid_604985
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604986 = header.getOrDefault("X-Amz-Date")
  valid_604986 = validateParameter(valid_604986, JString, required = false,
                                 default = nil)
  if valid_604986 != nil:
    section.add "X-Amz-Date", valid_604986
  var valid_604987 = header.getOrDefault("X-Amz-Security-Token")
  valid_604987 = validateParameter(valid_604987, JString, required = false,
                                 default = nil)
  if valid_604987 != nil:
    section.add "X-Amz-Security-Token", valid_604987
  var valid_604988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604988 = validateParameter(valid_604988, JString, required = false,
                                 default = nil)
  if valid_604988 != nil:
    section.add "X-Amz-Content-Sha256", valid_604988
  var valid_604989 = header.getOrDefault("X-Amz-Algorithm")
  valid_604989 = validateParameter(valid_604989, JString, required = false,
                                 default = nil)
  if valid_604989 != nil:
    section.add "X-Amz-Algorithm", valid_604989
  var valid_604990 = header.getOrDefault("X-Amz-Signature")
  valid_604990 = validateParameter(valid_604990, JString, required = false,
                                 default = nil)
  if valid_604990 != nil:
    section.add "X-Amz-Signature", valid_604990
  var valid_604991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604991 = validateParameter(valid_604991, JString, required = false,
                                 default = nil)
  if valid_604991 != nil:
    section.add "X-Amz-SignedHeaders", valid_604991
  var valid_604992 = header.getOrDefault("X-Amz-Credential")
  valid_604992 = validateParameter(valid_604992, JString, required = false,
                                 default = nil)
  if valid_604992 != nil:
    section.add "X-Amz-Credential", valid_604992
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604993 = formData.getOrDefault("DBParameterGroupName")
  valid_604993 = validateParameter(valid_604993, JString, required = true,
                                 default = nil)
  if valid_604993 != nil:
    section.add "DBParameterGroupName", valid_604993
  var valid_604994 = formData.getOrDefault("Parameters")
  valid_604994 = validateParameter(valid_604994, JArray, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "Parameters", valid_604994
  var valid_604995 = formData.getOrDefault("ResetAllParameters")
  valid_604995 = validateParameter(valid_604995, JBool, required = false, default = nil)
  if valid_604995 != nil:
    section.add "ResetAllParameters", valid_604995
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604996: Call_PostResetDBParameterGroup_604981; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604996.validator(path, query, header, formData, body)
  let scheme = call_604996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604996.url(scheme.get, call_604996.host, call_604996.base,
                         call_604996.route, valid.getOrDefault("path"))
  result = hook(call_604996, url, valid)

proc call*(call_604997: Call_PostResetDBParameterGroup_604981;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604998 = newJObject()
  var formData_604999 = newJObject()
  add(formData_604999, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604999.add "Parameters", Parameters
  add(query_604998, "Action", newJString(Action))
  add(formData_604999, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604998, "Version", newJString(Version))
  result = call_604997.call(nil, query_604998, nil, formData_604999, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_604981(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_604982, base: "/",
    url: url_PostResetDBParameterGroup_604983,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_604963 = ref object of OpenApiRestCall_602417
proc url_GetResetDBParameterGroup_604965(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_604964(path: JsonNode; query: JsonNode;
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
  var valid_604966 = query.getOrDefault("DBParameterGroupName")
  valid_604966 = validateParameter(valid_604966, JString, required = true,
                                 default = nil)
  if valid_604966 != nil:
    section.add "DBParameterGroupName", valid_604966
  var valid_604967 = query.getOrDefault("Parameters")
  valid_604967 = validateParameter(valid_604967, JArray, required = false,
                                 default = nil)
  if valid_604967 != nil:
    section.add "Parameters", valid_604967
  var valid_604968 = query.getOrDefault("Action")
  valid_604968 = validateParameter(valid_604968, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604968 != nil:
    section.add "Action", valid_604968
  var valid_604969 = query.getOrDefault("ResetAllParameters")
  valid_604969 = validateParameter(valid_604969, JBool, required = false, default = nil)
  if valid_604969 != nil:
    section.add "ResetAllParameters", valid_604969
  var valid_604970 = query.getOrDefault("Version")
  valid_604970 = validateParameter(valid_604970, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_604970 != nil:
    section.add "Version", valid_604970
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604971 = header.getOrDefault("X-Amz-Date")
  valid_604971 = validateParameter(valid_604971, JString, required = false,
                                 default = nil)
  if valid_604971 != nil:
    section.add "X-Amz-Date", valid_604971
  var valid_604972 = header.getOrDefault("X-Amz-Security-Token")
  valid_604972 = validateParameter(valid_604972, JString, required = false,
                                 default = nil)
  if valid_604972 != nil:
    section.add "X-Amz-Security-Token", valid_604972
  var valid_604973 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604973 = validateParameter(valid_604973, JString, required = false,
                                 default = nil)
  if valid_604973 != nil:
    section.add "X-Amz-Content-Sha256", valid_604973
  var valid_604974 = header.getOrDefault("X-Amz-Algorithm")
  valid_604974 = validateParameter(valid_604974, JString, required = false,
                                 default = nil)
  if valid_604974 != nil:
    section.add "X-Amz-Algorithm", valid_604974
  var valid_604975 = header.getOrDefault("X-Amz-Signature")
  valid_604975 = validateParameter(valid_604975, JString, required = false,
                                 default = nil)
  if valid_604975 != nil:
    section.add "X-Amz-Signature", valid_604975
  var valid_604976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604976 = validateParameter(valid_604976, JString, required = false,
                                 default = nil)
  if valid_604976 != nil:
    section.add "X-Amz-SignedHeaders", valid_604976
  var valid_604977 = header.getOrDefault("X-Amz-Credential")
  valid_604977 = validateParameter(valid_604977, JString, required = false,
                                 default = nil)
  if valid_604977 != nil:
    section.add "X-Amz-Credential", valid_604977
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604978: Call_GetResetDBParameterGroup_604963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604978.validator(path, query, header, formData, body)
  let scheme = call_604978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604978.url(scheme.get, call_604978.host, call_604978.base,
                         call_604978.route, valid.getOrDefault("path"))
  result = hook(call_604978, url, valid)

proc call*(call_604979: Call_GetResetDBParameterGroup_604963;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604980 = newJObject()
  add(query_604980, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604980.add "Parameters", Parameters
  add(query_604980, "Action", newJString(Action))
  add(query_604980, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604980, "Version", newJString(Version))
  result = call_604979.call(nil, query_604980, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_604963(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_604964, base: "/",
    url: url_GetResetDBParameterGroup_604965, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_605030 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBInstanceFromDBSnapshot_605032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_605031(path: JsonNode;
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
  var valid_605033 = query.getOrDefault("Action")
  valid_605033 = validateParameter(valid_605033, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605033 != nil:
    section.add "Action", valid_605033
  var valid_605034 = query.getOrDefault("Version")
  valid_605034 = validateParameter(valid_605034, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605034 != nil:
    section.add "Version", valid_605034
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605035 = header.getOrDefault("X-Amz-Date")
  valid_605035 = validateParameter(valid_605035, JString, required = false,
                                 default = nil)
  if valid_605035 != nil:
    section.add "X-Amz-Date", valid_605035
  var valid_605036 = header.getOrDefault("X-Amz-Security-Token")
  valid_605036 = validateParameter(valid_605036, JString, required = false,
                                 default = nil)
  if valid_605036 != nil:
    section.add "X-Amz-Security-Token", valid_605036
  var valid_605037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605037 = validateParameter(valid_605037, JString, required = false,
                                 default = nil)
  if valid_605037 != nil:
    section.add "X-Amz-Content-Sha256", valid_605037
  var valid_605038 = header.getOrDefault("X-Amz-Algorithm")
  valid_605038 = validateParameter(valid_605038, JString, required = false,
                                 default = nil)
  if valid_605038 != nil:
    section.add "X-Amz-Algorithm", valid_605038
  var valid_605039 = header.getOrDefault("X-Amz-Signature")
  valid_605039 = validateParameter(valid_605039, JString, required = false,
                                 default = nil)
  if valid_605039 != nil:
    section.add "X-Amz-Signature", valid_605039
  var valid_605040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605040 = validateParameter(valid_605040, JString, required = false,
                                 default = nil)
  if valid_605040 != nil:
    section.add "X-Amz-SignedHeaders", valid_605040
  var valid_605041 = header.getOrDefault("X-Amz-Credential")
  valid_605041 = validateParameter(valid_605041, JString, required = false,
                                 default = nil)
  if valid_605041 != nil:
    section.add "X-Amz-Credential", valid_605041
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
  var valid_605042 = formData.getOrDefault("Port")
  valid_605042 = validateParameter(valid_605042, JInt, required = false, default = nil)
  if valid_605042 != nil:
    section.add "Port", valid_605042
  var valid_605043 = formData.getOrDefault("Engine")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "Engine", valid_605043
  var valid_605044 = formData.getOrDefault("Iops")
  valid_605044 = validateParameter(valid_605044, JInt, required = false, default = nil)
  if valid_605044 != nil:
    section.add "Iops", valid_605044
  var valid_605045 = formData.getOrDefault("DBName")
  valid_605045 = validateParameter(valid_605045, JString, required = false,
                                 default = nil)
  if valid_605045 != nil:
    section.add "DBName", valid_605045
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_605046 = formData.getOrDefault("DBInstanceIdentifier")
  valid_605046 = validateParameter(valid_605046, JString, required = true,
                                 default = nil)
  if valid_605046 != nil:
    section.add "DBInstanceIdentifier", valid_605046
  var valid_605047 = formData.getOrDefault("OptionGroupName")
  valid_605047 = validateParameter(valid_605047, JString, required = false,
                                 default = nil)
  if valid_605047 != nil:
    section.add "OptionGroupName", valid_605047
  var valid_605048 = formData.getOrDefault("Tags")
  valid_605048 = validateParameter(valid_605048, JArray, required = false,
                                 default = nil)
  if valid_605048 != nil:
    section.add "Tags", valid_605048
  var valid_605049 = formData.getOrDefault("DBSubnetGroupName")
  valid_605049 = validateParameter(valid_605049, JString, required = false,
                                 default = nil)
  if valid_605049 != nil:
    section.add "DBSubnetGroupName", valid_605049
  var valid_605050 = formData.getOrDefault("AvailabilityZone")
  valid_605050 = validateParameter(valid_605050, JString, required = false,
                                 default = nil)
  if valid_605050 != nil:
    section.add "AvailabilityZone", valid_605050
  var valid_605051 = formData.getOrDefault("MultiAZ")
  valid_605051 = validateParameter(valid_605051, JBool, required = false, default = nil)
  if valid_605051 != nil:
    section.add "MultiAZ", valid_605051
  var valid_605052 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_605052 = validateParameter(valid_605052, JString, required = true,
                                 default = nil)
  if valid_605052 != nil:
    section.add "DBSnapshotIdentifier", valid_605052
  var valid_605053 = formData.getOrDefault("PubliclyAccessible")
  valid_605053 = validateParameter(valid_605053, JBool, required = false, default = nil)
  if valid_605053 != nil:
    section.add "PubliclyAccessible", valid_605053
  var valid_605054 = formData.getOrDefault("DBInstanceClass")
  valid_605054 = validateParameter(valid_605054, JString, required = false,
                                 default = nil)
  if valid_605054 != nil:
    section.add "DBInstanceClass", valid_605054
  var valid_605055 = formData.getOrDefault("LicenseModel")
  valid_605055 = validateParameter(valid_605055, JString, required = false,
                                 default = nil)
  if valid_605055 != nil:
    section.add "LicenseModel", valid_605055
  var valid_605056 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605056 = validateParameter(valid_605056, JBool, required = false, default = nil)
  if valid_605056 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605056
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605057: Call_PostRestoreDBInstanceFromDBSnapshot_605030;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605057.validator(path, query, header, formData, body)
  let scheme = call_605057.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605057.url(scheme.get, call_605057.host, call_605057.base,
                         call_605057.route, valid.getOrDefault("path"))
  result = hook(call_605057, url, valid)

proc call*(call_605058: Call_PostRestoreDBInstanceFromDBSnapshot_605030;
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
  var query_605059 = newJObject()
  var formData_605060 = newJObject()
  add(formData_605060, "Port", newJInt(Port))
  add(formData_605060, "Engine", newJString(Engine))
  add(formData_605060, "Iops", newJInt(Iops))
  add(formData_605060, "DBName", newJString(DBName))
  add(formData_605060, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_605060, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605060.add "Tags", Tags
  add(formData_605060, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605060, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605060, "MultiAZ", newJBool(MultiAZ))
  add(formData_605060, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_605059, "Action", newJString(Action))
  add(formData_605060, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605060, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605060, "LicenseModel", newJString(LicenseModel))
  add(formData_605060, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605059, "Version", newJString(Version))
  result = call_605058.call(nil, query_605059, nil, formData_605060, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_605030(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_605031, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_605032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_605000 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBInstanceFromDBSnapshot_605002(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_605001(path: JsonNode;
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
  var valid_605003 = query.getOrDefault("Engine")
  valid_605003 = validateParameter(valid_605003, JString, required = false,
                                 default = nil)
  if valid_605003 != nil:
    section.add "Engine", valid_605003
  var valid_605004 = query.getOrDefault("OptionGroupName")
  valid_605004 = validateParameter(valid_605004, JString, required = false,
                                 default = nil)
  if valid_605004 != nil:
    section.add "OptionGroupName", valid_605004
  var valid_605005 = query.getOrDefault("AvailabilityZone")
  valid_605005 = validateParameter(valid_605005, JString, required = false,
                                 default = nil)
  if valid_605005 != nil:
    section.add "AvailabilityZone", valid_605005
  var valid_605006 = query.getOrDefault("Iops")
  valid_605006 = validateParameter(valid_605006, JInt, required = false, default = nil)
  if valid_605006 != nil:
    section.add "Iops", valid_605006
  var valid_605007 = query.getOrDefault("MultiAZ")
  valid_605007 = validateParameter(valid_605007, JBool, required = false, default = nil)
  if valid_605007 != nil:
    section.add "MultiAZ", valid_605007
  var valid_605008 = query.getOrDefault("LicenseModel")
  valid_605008 = validateParameter(valid_605008, JString, required = false,
                                 default = nil)
  if valid_605008 != nil:
    section.add "LicenseModel", valid_605008
  var valid_605009 = query.getOrDefault("Tags")
  valid_605009 = validateParameter(valid_605009, JArray, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "Tags", valid_605009
  var valid_605010 = query.getOrDefault("DBName")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "DBName", valid_605010
  var valid_605011 = query.getOrDefault("DBInstanceClass")
  valid_605011 = validateParameter(valid_605011, JString, required = false,
                                 default = nil)
  if valid_605011 != nil:
    section.add "DBInstanceClass", valid_605011
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_605012 = query.getOrDefault("Action")
  valid_605012 = validateParameter(valid_605012, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_605012 != nil:
    section.add "Action", valid_605012
  var valid_605013 = query.getOrDefault("DBSubnetGroupName")
  valid_605013 = validateParameter(valid_605013, JString, required = false,
                                 default = nil)
  if valid_605013 != nil:
    section.add "DBSubnetGroupName", valid_605013
  var valid_605014 = query.getOrDefault("PubliclyAccessible")
  valid_605014 = validateParameter(valid_605014, JBool, required = false, default = nil)
  if valid_605014 != nil:
    section.add "PubliclyAccessible", valid_605014
  var valid_605015 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605015 = validateParameter(valid_605015, JBool, required = false, default = nil)
  if valid_605015 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605015
  var valid_605016 = query.getOrDefault("Port")
  valid_605016 = validateParameter(valid_605016, JInt, required = false, default = nil)
  if valid_605016 != nil:
    section.add "Port", valid_605016
  var valid_605017 = query.getOrDefault("Version")
  valid_605017 = validateParameter(valid_605017, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605017 != nil:
    section.add "Version", valid_605017
  var valid_605018 = query.getOrDefault("DBInstanceIdentifier")
  valid_605018 = validateParameter(valid_605018, JString, required = true,
                                 default = nil)
  if valid_605018 != nil:
    section.add "DBInstanceIdentifier", valid_605018
  var valid_605019 = query.getOrDefault("DBSnapshotIdentifier")
  valid_605019 = validateParameter(valid_605019, JString, required = true,
                                 default = nil)
  if valid_605019 != nil:
    section.add "DBSnapshotIdentifier", valid_605019
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605020 = header.getOrDefault("X-Amz-Date")
  valid_605020 = validateParameter(valid_605020, JString, required = false,
                                 default = nil)
  if valid_605020 != nil:
    section.add "X-Amz-Date", valid_605020
  var valid_605021 = header.getOrDefault("X-Amz-Security-Token")
  valid_605021 = validateParameter(valid_605021, JString, required = false,
                                 default = nil)
  if valid_605021 != nil:
    section.add "X-Amz-Security-Token", valid_605021
  var valid_605022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605022 = validateParameter(valid_605022, JString, required = false,
                                 default = nil)
  if valid_605022 != nil:
    section.add "X-Amz-Content-Sha256", valid_605022
  var valid_605023 = header.getOrDefault("X-Amz-Algorithm")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "X-Amz-Algorithm", valid_605023
  var valid_605024 = header.getOrDefault("X-Amz-Signature")
  valid_605024 = validateParameter(valid_605024, JString, required = false,
                                 default = nil)
  if valid_605024 != nil:
    section.add "X-Amz-Signature", valid_605024
  var valid_605025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605025 = validateParameter(valid_605025, JString, required = false,
                                 default = nil)
  if valid_605025 != nil:
    section.add "X-Amz-SignedHeaders", valid_605025
  var valid_605026 = header.getOrDefault("X-Amz-Credential")
  valid_605026 = validateParameter(valid_605026, JString, required = false,
                                 default = nil)
  if valid_605026 != nil:
    section.add "X-Amz-Credential", valid_605026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605027: Call_GetRestoreDBInstanceFromDBSnapshot_605000;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605027.validator(path, query, header, formData, body)
  let scheme = call_605027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605027.url(scheme.get, call_605027.host, call_605027.base,
                         call_605027.route, valid.getOrDefault("path"))
  result = hook(call_605027, url, valid)

proc call*(call_605028: Call_GetRestoreDBInstanceFromDBSnapshot_605000;
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
  var query_605029 = newJObject()
  add(query_605029, "Engine", newJString(Engine))
  add(query_605029, "OptionGroupName", newJString(OptionGroupName))
  add(query_605029, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605029, "Iops", newJInt(Iops))
  add(query_605029, "MultiAZ", newJBool(MultiAZ))
  add(query_605029, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605029.add "Tags", Tags
  add(query_605029, "DBName", newJString(DBName))
  add(query_605029, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605029, "Action", newJString(Action))
  add(query_605029, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605029, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605029, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605029, "Port", newJInt(Port))
  add(query_605029, "Version", newJString(Version))
  add(query_605029, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_605029, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_605028.call(nil, query_605029, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_605000(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_605001, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_605002,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_605093 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBInstanceToPointInTime_605095(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_605094(path: JsonNode;
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
  var valid_605096 = query.getOrDefault("Action")
  valid_605096 = validateParameter(valid_605096, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605096 != nil:
    section.add "Action", valid_605096
  var valid_605097 = query.getOrDefault("Version")
  valid_605097 = validateParameter(valid_605097, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605097 != nil:
    section.add "Version", valid_605097
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605098 = header.getOrDefault("X-Amz-Date")
  valid_605098 = validateParameter(valid_605098, JString, required = false,
                                 default = nil)
  if valid_605098 != nil:
    section.add "X-Amz-Date", valid_605098
  var valid_605099 = header.getOrDefault("X-Amz-Security-Token")
  valid_605099 = validateParameter(valid_605099, JString, required = false,
                                 default = nil)
  if valid_605099 != nil:
    section.add "X-Amz-Security-Token", valid_605099
  var valid_605100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "X-Amz-Content-Sha256", valid_605100
  var valid_605101 = header.getOrDefault("X-Amz-Algorithm")
  valid_605101 = validateParameter(valid_605101, JString, required = false,
                                 default = nil)
  if valid_605101 != nil:
    section.add "X-Amz-Algorithm", valid_605101
  var valid_605102 = header.getOrDefault("X-Amz-Signature")
  valid_605102 = validateParameter(valid_605102, JString, required = false,
                                 default = nil)
  if valid_605102 != nil:
    section.add "X-Amz-Signature", valid_605102
  var valid_605103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605103 = validateParameter(valid_605103, JString, required = false,
                                 default = nil)
  if valid_605103 != nil:
    section.add "X-Amz-SignedHeaders", valid_605103
  var valid_605104 = header.getOrDefault("X-Amz-Credential")
  valid_605104 = validateParameter(valid_605104, JString, required = false,
                                 default = nil)
  if valid_605104 != nil:
    section.add "X-Amz-Credential", valid_605104
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
  var valid_605105 = formData.getOrDefault("UseLatestRestorableTime")
  valid_605105 = validateParameter(valid_605105, JBool, required = false, default = nil)
  if valid_605105 != nil:
    section.add "UseLatestRestorableTime", valid_605105
  var valid_605106 = formData.getOrDefault("Port")
  valid_605106 = validateParameter(valid_605106, JInt, required = false, default = nil)
  if valid_605106 != nil:
    section.add "Port", valid_605106
  var valid_605107 = formData.getOrDefault("Engine")
  valid_605107 = validateParameter(valid_605107, JString, required = false,
                                 default = nil)
  if valid_605107 != nil:
    section.add "Engine", valid_605107
  var valid_605108 = formData.getOrDefault("Iops")
  valid_605108 = validateParameter(valid_605108, JInt, required = false, default = nil)
  if valid_605108 != nil:
    section.add "Iops", valid_605108
  var valid_605109 = formData.getOrDefault("DBName")
  valid_605109 = validateParameter(valid_605109, JString, required = false,
                                 default = nil)
  if valid_605109 != nil:
    section.add "DBName", valid_605109
  var valid_605110 = formData.getOrDefault("OptionGroupName")
  valid_605110 = validateParameter(valid_605110, JString, required = false,
                                 default = nil)
  if valid_605110 != nil:
    section.add "OptionGroupName", valid_605110
  var valid_605111 = formData.getOrDefault("Tags")
  valid_605111 = validateParameter(valid_605111, JArray, required = false,
                                 default = nil)
  if valid_605111 != nil:
    section.add "Tags", valid_605111
  var valid_605112 = formData.getOrDefault("DBSubnetGroupName")
  valid_605112 = validateParameter(valid_605112, JString, required = false,
                                 default = nil)
  if valid_605112 != nil:
    section.add "DBSubnetGroupName", valid_605112
  var valid_605113 = formData.getOrDefault("AvailabilityZone")
  valid_605113 = validateParameter(valid_605113, JString, required = false,
                                 default = nil)
  if valid_605113 != nil:
    section.add "AvailabilityZone", valid_605113
  var valid_605114 = formData.getOrDefault("MultiAZ")
  valid_605114 = validateParameter(valid_605114, JBool, required = false, default = nil)
  if valid_605114 != nil:
    section.add "MultiAZ", valid_605114
  var valid_605115 = formData.getOrDefault("RestoreTime")
  valid_605115 = validateParameter(valid_605115, JString, required = false,
                                 default = nil)
  if valid_605115 != nil:
    section.add "RestoreTime", valid_605115
  var valid_605116 = formData.getOrDefault("PubliclyAccessible")
  valid_605116 = validateParameter(valid_605116, JBool, required = false, default = nil)
  if valid_605116 != nil:
    section.add "PubliclyAccessible", valid_605116
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_605117 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_605117 = validateParameter(valid_605117, JString, required = true,
                                 default = nil)
  if valid_605117 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605117
  var valid_605118 = formData.getOrDefault("DBInstanceClass")
  valid_605118 = validateParameter(valid_605118, JString, required = false,
                                 default = nil)
  if valid_605118 != nil:
    section.add "DBInstanceClass", valid_605118
  var valid_605119 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_605119 = validateParameter(valid_605119, JString, required = true,
                                 default = nil)
  if valid_605119 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605119
  var valid_605120 = formData.getOrDefault("LicenseModel")
  valid_605120 = validateParameter(valid_605120, JString, required = false,
                                 default = nil)
  if valid_605120 != nil:
    section.add "LicenseModel", valid_605120
  var valid_605121 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605121 = validateParameter(valid_605121, JBool, required = false, default = nil)
  if valid_605121 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605121
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605122: Call_PostRestoreDBInstanceToPointInTime_605093;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605122.validator(path, query, header, formData, body)
  let scheme = call_605122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605122.url(scheme.get, call_605122.host, call_605122.base,
                         call_605122.route, valid.getOrDefault("path"))
  result = hook(call_605122, url, valid)

proc call*(call_605123: Call_PostRestoreDBInstanceToPointInTime_605093;
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
  var query_605124 = newJObject()
  var formData_605125 = newJObject()
  add(formData_605125, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_605125, "Port", newJInt(Port))
  add(formData_605125, "Engine", newJString(Engine))
  add(formData_605125, "Iops", newJInt(Iops))
  add(formData_605125, "DBName", newJString(DBName))
  add(formData_605125, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_605125.add "Tags", Tags
  add(formData_605125, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605125, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605125, "MultiAZ", newJBool(MultiAZ))
  add(query_605124, "Action", newJString(Action))
  add(formData_605125, "RestoreTime", newJString(RestoreTime))
  add(formData_605125, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605125, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_605125, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605125, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_605125, "LicenseModel", newJString(LicenseModel))
  add(formData_605125, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605124, "Version", newJString(Version))
  result = call_605123.call(nil, query_605124, nil, formData_605125, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_605093(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_605094, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_605095,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_605061 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBInstanceToPointInTime_605063(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_605062(path: JsonNode;
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
  var valid_605064 = query.getOrDefault("Engine")
  valid_605064 = validateParameter(valid_605064, JString, required = false,
                                 default = nil)
  if valid_605064 != nil:
    section.add "Engine", valid_605064
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_605065 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_605065 = validateParameter(valid_605065, JString, required = true,
                                 default = nil)
  if valid_605065 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605065
  var valid_605066 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_605066 = validateParameter(valid_605066, JString, required = true,
                                 default = nil)
  if valid_605066 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605066
  var valid_605067 = query.getOrDefault("AvailabilityZone")
  valid_605067 = validateParameter(valid_605067, JString, required = false,
                                 default = nil)
  if valid_605067 != nil:
    section.add "AvailabilityZone", valid_605067
  var valid_605068 = query.getOrDefault("Iops")
  valid_605068 = validateParameter(valid_605068, JInt, required = false, default = nil)
  if valid_605068 != nil:
    section.add "Iops", valid_605068
  var valid_605069 = query.getOrDefault("OptionGroupName")
  valid_605069 = validateParameter(valid_605069, JString, required = false,
                                 default = nil)
  if valid_605069 != nil:
    section.add "OptionGroupName", valid_605069
  var valid_605070 = query.getOrDefault("RestoreTime")
  valid_605070 = validateParameter(valid_605070, JString, required = false,
                                 default = nil)
  if valid_605070 != nil:
    section.add "RestoreTime", valid_605070
  var valid_605071 = query.getOrDefault("MultiAZ")
  valid_605071 = validateParameter(valid_605071, JBool, required = false, default = nil)
  if valid_605071 != nil:
    section.add "MultiAZ", valid_605071
  var valid_605072 = query.getOrDefault("LicenseModel")
  valid_605072 = validateParameter(valid_605072, JString, required = false,
                                 default = nil)
  if valid_605072 != nil:
    section.add "LicenseModel", valid_605072
  var valid_605073 = query.getOrDefault("Tags")
  valid_605073 = validateParameter(valid_605073, JArray, required = false,
                                 default = nil)
  if valid_605073 != nil:
    section.add "Tags", valid_605073
  var valid_605074 = query.getOrDefault("DBName")
  valid_605074 = validateParameter(valid_605074, JString, required = false,
                                 default = nil)
  if valid_605074 != nil:
    section.add "DBName", valid_605074
  var valid_605075 = query.getOrDefault("DBInstanceClass")
  valid_605075 = validateParameter(valid_605075, JString, required = false,
                                 default = nil)
  if valid_605075 != nil:
    section.add "DBInstanceClass", valid_605075
  var valid_605076 = query.getOrDefault("Action")
  valid_605076 = validateParameter(valid_605076, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605076 != nil:
    section.add "Action", valid_605076
  var valid_605077 = query.getOrDefault("UseLatestRestorableTime")
  valid_605077 = validateParameter(valid_605077, JBool, required = false, default = nil)
  if valid_605077 != nil:
    section.add "UseLatestRestorableTime", valid_605077
  var valid_605078 = query.getOrDefault("DBSubnetGroupName")
  valid_605078 = validateParameter(valid_605078, JString, required = false,
                                 default = nil)
  if valid_605078 != nil:
    section.add "DBSubnetGroupName", valid_605078
  var valid_605079 = query.getOrDefault("PubliclyAccessible")
  valid_605079 = validateParameter(valid_605079, JBool, required = false, default = nil)
  if valid_605079 != nil:
    section.add "PubliclyAccessible", valid_605079
  var valid_605080 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605080 = validateParameter(valid_605080, JBool, required = false, default = nil)
  if valid_605080 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605080
  var valid_605081 = query.getOrDefault("Port")
  valid_605081 = validateParameter(valid_605081, JInt, required = false, default = nil)
  if valid_605081 != nil:
    section.add "Port", valid_605081
  var valid_605082 = query.getOrDefault("Version")
  valid_605082 = validateParameter(valid_605082, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605082 != nil:
    section.add "Version", valid_605082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605083 = header.getOrDefault("X-Amz-Date")
  valid_605083 = validateParameter(valid_605083, JString, required = false,
                                 default = nil)
  if valid_605083 != nil:
    section.add "X-Amz-Date", valid_605083
  var valid_605084 = header.getOrDefault("X-Amz-Security-Token")
  valid_605084 = validateParameter(valid_605084, JString, required = false,
                                 default = nil)
  if valid_605084 != nil:
    section.add "X-Amz-Security-Token", valid_605084
  var valid_605085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605085 = validateParameter(valid_605085, JString, required = false,
                                 default = nil)
  if valid_605085 != nil:
    section.add "X-Amz-Content-Sha256", valid_605085
  var valid_605086 = header.getOrDefault("X-Amz-Algorithm")
  valid_605086 = validateParameter(valid_605086, JString, required = false,
                                 default = nil)
  if valid_605086 != nil:
    section.add "X-Amz-Algorithm", valid_605086
  var valid_605087 = header.getOrDefault("X-Amz-Signature")
  valid_605087 = validateParameter(valid_605087, JString, required = false,
                                 default = nil)
  if valid_605087 != nil:
    section.add "X-Amz-Signature", valid_605087
  var valid_605088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605088 = validateParameter(valid_605088, JString, required = false,
                                 default = nil)
  if valid_605088 != nil:
    section.add "X-Amz-SignedHeaders", valid_605088
  var valid_605089 = header.getOrDefault("X-Amz-Credential")
  valid_605089 = validateParameter(valid_605089, JString, required = false,
                                 default = nil)
  if valid_605089 != nil:
    section.add "X-Amz-Credential", valid_605089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605090: Call_GetRestoreDBInstanceToPointInTime_605061;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605090.validator(path, query, header, formData, body)
  let scheme = call_605090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605090.url(scheme.get, call_605090.host, call_605090.base,
                         call_605090.route, valid.getOrDefault("path"))
  result = hook(call_605090, url, valid)

proc call*(call_605091: Call_GetRestoreDBInstanceToPointInTime_605061;
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
  var query_605092 = newJObject()
  add(query_605092, "Engine", newJString(Engine))
  add(query_605092, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_605092, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_605092, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605092, "Iops", newJInt(Iops))
  add(query_605092, "OptionGroupName", newJString(OptionGroupName))
  add(query_605092, "RestoreTime", newJString(RestoreTime))
  add(query_605092, "MultiAZ", newJBool(MultiAZ))
  add(query_605092, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_605092.add "Tags", Tags
  add(query_605092, "DBName", newJString(DBName))
  add(query_605092, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605092, "Action", newJString(Action))
  add(query_605092, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_605092, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605092, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605092, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605092, "Port", newJInt(Port))
  add(query_605092, "Version", newJString(Version))
  result = call_605091.call(nil, query_605092, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_605061(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_605062, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_605063,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_605146 = ref object of OpenApiRestCall_602417
proc url_PostRevokeDBSecurityGroupIngress_605148(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_605147(path: JsonNode;
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
  var valid_605149 = query.getOrDefault("Action")
  valid_605149 = validateParameter(valid_605149, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605149 != nil:
    section.add "Action", valid_605149
  var valid_605150 = query.getOrDefault("Version")
  valid_605150 = validateParameter(valid_605150, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605150 != nil:
    section.add "Version", valid_605150
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605151 = header.getOrDefault("X-Amz-Date")
  valid_605151 = validateParameter(valid_605151, JString, required = false,
                                 default = nil)
  if valid_605151 != nil:
    section.add "X-Amz-Date", valid_605151
  var valid_605152 = header.getOrDefault("X-Amz-Security-Token")
  valid_605152 = validateParameter(valid_605152, JString, required = false,
                                 default = nil)
  if valid_605152 != nil:
    section.add "X-Amz-Security-Token", valid_605152
  var valid_605153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605153 = validateParameter(valid_605153, JString, required = false,
                                 default = nil)
  if valid_605153 != nil:
    section.add "X-Amz-Content-Sha256", valid_605153
  var valid_605154 = header.getOrDefault("X-Amz-Algorithm")
  valid_605154 = validateParameter(valid_605154, JString, required = false,
                                 default = nil)
  if valid_605154 != nil:
    section.add "X-Amz-Algorithm", valid_605154
  var valid_605155 = header.getOrDefault("X-Amz-Signature")
  valid_605155 = validateParameter(valid_605155, JString, required = false,
                                 default = nil)
  if valid_605155 != nil:
    section.add "X-Amz-Signature", valid_605155
  var valid_605156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605156 = validateParameter(valid_605156, JString, required = false,
                                 default = nil)
  if valid_605156 != nil:
    section.add "X-Amz-SignedHeaders", valid_605156
  var valid_605157 = header.getOrDefault("X-Amz-Credential")
  valid_605157 = validateParameter(valid_605157, JString, required = false,
                                 default = nil)
  if valid_605157 != nil:
    section.add "X-Amz-Credential", valid_605157
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605158 = formData.getOrDefault("DBSecurityGroupName")
  valid_605158 = validateParameter(valid_605158, JString, required = true,
                                 default = nil)
  if valid_605158 != nil:
    section.add "DBSecurityGroupName", valid_605158
  var valid_605159 = formData.getOrDefault("EC2SecurityGroupName")
  valid_605159 = validateParameter(valid_605159, JString, required = false,
                                 default = nil)
  if valid_605159 != nil:
    section.add "EC2SecurityGroupName", valid_605159
  var valid_605160 = formData.getOrDefault("EC2SecurityGroupId")
  valid_605160 = validateParameter(valid_605160, JString, required = false,
                                 default = nil)
  if valid_605160 != nil:
    section.add "EC2SecurityGroupId", valid_605160
  var valid_605161 = formData.getOrDefault("CIDRIP")
  valid_605161 = validateParameter(valid_605161, JString, required = false,
                                 default = nil)
  if valid_605161 != nil:
    section.add "CIDRIP", valid_605161
  var valid_605162 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605162 = validateParameter(valid_605162, JString, required = false,
                                 default = nil)
  if valid_605162 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605163: Call_PostRevokeDBSecurityGroupIngress_605146;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605163.validator(path, query, header, formData, body)
  let scheme = call_605163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605163.url(scheme.get, call_605163.host, call_605163.base,
                         call_605163.route, valid.getOrDefault("path"))
  result = hook(call_605163, url, valid)

proc call*(call_605164: Call_PostRevokeDBSecurityGroupIngress_605146;
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
  var query_605165 = newJObject()
  var formData_605166 = newJObject()
  add(formData_605166, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605165, "Action", newJString(Action))
  add(formData_605166, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_605166, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_605166, "CIDRIP", newJString(CIDRIP))
  add(query_605165, "Version", newJString(Version))
  add(formData_605166, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_605164.call(nil, query_605165, nil, formData_605166, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_605146(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_605147, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_605148,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_605126 = ref object of OpenApiRestCall_602417
proc url_GetRevokeDBSecurityGroupIngress_605128(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_605127(path: JsonNode;
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
  var valid_605129 = query.getOrDefault("EC2SecurityGroupId")
  valid_605129 = validateParameter(valid_605129, JString, required = false,
                                 default = nil)
  if valid_605129 != nil:
    section.add "EC2SecurityGroupId", valid_605129
  var valid_605130 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605130 = validateParameter(valid_605130, JString, required = false,
                                 default = nil)
  if valid_605130 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605130
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605131 = query.getOrDefault("DBSecurityGroupName")
  valid_605131 = validateParameter(valid_605131, JString, required = true,
                                 default = nil)
  if valid_605131 != nil:
    section.add "DBSecurityGroupName", valid_605131
  var valid_605132 = query.getOrDefault("Action")
  valid_605132 = validateParameter(valid_605132, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605132 != nil:
    section.add "Action", valid_605132
  var valid_605133 = query.getOrDefault("CIDRIP")
  valid_605133 = validateParameter(valid_605133, JString, required = false,
                                 default = nil)
  if valid_605133 != nil:
    section.add "CIDRIP", valid_605133
  var valid_605134 = query.getOrDefault("EC2SecurityGroupName")
  valid_605134 = validateParameter(valid_605134, JString, required = false,
                                 default = nil)
  if valid_605134 != nil:
    section.add "EC2SecurityGroupName", valid_605134
  var valid_605135 = query.getOrDefault("Version")
  valid_605135 = validateParameter(valid_605135, JString, required = true,
                                 default = newJString("2013-09-09"))
  if valid_605135 != nil:
    section.add "Version", valid_605135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605136 = header.getOrDefault("X-Amz-Date")
  valid_605136 = validateParameter(valid_605136, JString, required = false,
                                 default = nil)
  if valid_605136 != nil:
    section.add "X-Amz-Date", valid_605136
  var valid_605137 = header.getOrDefault("X-Amz-Security-Token")
  valid_605137 = validateParameter(valid_605137, JString, required = false,
                                 default = nil)
  if valid_605137 != nil:
    section.add "X-Amz-Security-Token", valid_605137
  var valid_605138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605138 = validateParameter(valid_605138, JString, required = false,
                                 default = nil)
  if valid_605138 != nil:
    section.add "X-Amz-Content-Sha256", valid_605138
  var valid_605139 = header.getOrDefault("X-Amz-Algorithm")
  valid_605139 = validateParameter(valid_605139, JString, required = false,
                                 default = nil)
  if valid_605139 != nil:
    section.add "X-Amz-Algorithm", valid_605139
  var valid_605140 = header.getOrDefault("X-Amz-Signature")
  valid_605140 = validateParameter(valid_605140, JString, required = false,
                                 default = nil)
  if valid_605140 != nil:
    section.add "X-Amz-Signature", valid_605140
  var valid_605141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605141 = validateParameter(valid_605141, JString, required = false,
                                 default = nil)
  if valid_605141 != nil:
    section.add "X-Amz-SignedHeaders", valid_605141
  var valid_605142 = header.getOrDefault("X-Amz-Credential")
  valid_605142 = validateParameter(valid_605142, JString, required = false,
                                 default = nil)
  if valid_605142 != nil:
    section.add "X-Amz-Credential", valid_605142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605143: Call_GetRevokeDBSecurityGroupIngress_605126;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605143.validator(path, query, header, formData, body)
  let scheme = call_605143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605143.url(scheme.get, call_605143.host, call_605143.base,
                         call_605143.route, valid.getOrDefault("path"))
  result = hook(call_605143, url, valid)

proc call*(call_605144: Call_GetRevokeDBSecurityGroupIngress_605126;
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
  var query_605145 = newJObject()
  add(query_605145, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_605145, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_605145, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605145, "Action", newJString(Action))
  add(query_605145, "CIDRIP", newJString(CIDRIP))
  add(query_605145, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_605145, "Version", newJString(Version))
  result = call_605144.call(nil, query_605145, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_605126(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_605127, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_605128,
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


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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
          Version: string = "2013-02-12"): Recallable =
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
                                 default = newJString("2013-02-12"))
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
                                 default = newJString("2013-02-12"))
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
          EC2SecurityGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
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
  Call_PostCopyDBSnapshot_603137 = ref object of OpenApiRestCall_602417
proc url_PostCopyDBSnapshot_603139(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCopyDBSnapshot_603138(path: JsonNode; query: JsonNode;
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
  var valid_603140 = query.getOrDefault("Action")
  valid_603140 = validateParameter(valid_603140, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603140 != nil:
    section.add "Action", valid_603140
  var valid_603141 = query.getOrDefault("Version")
  valid_603141 = validateParameter(valid_603141, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603141 != nil:
    section.add "Version", valid_603141
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603142 = header.getOrDefault("X-Amz-Date")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-Date", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Security-Token")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Security-Token", valid_603143
  var valid_603144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603144 = validateParameter(valid_603144, JString, required = false,
                                 default = nil)
  if valid_603144 != nil:
    section.add "X-Amz-Content-Sha256", valid_603144
  var valid_603145 = header.getOrDefault("X-Amz-Algorithm")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "X-Amz-Algorithm", valid_603145
  var valid_603146 = header.getOrDefault("X-Amz-Signature")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Signature", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-SignedHeaders", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Credential")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Credential", valid_603148
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603149 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603149 = validateParameter(valid_603149, JString, required = true,
                                 default = nil)
  if valid_603149 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603149
  var valid_603150 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603150 = validateParameter(valid_603150, JString, required = true,
                                 default = nil)
  if valid_603150 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603150
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603151: Call_PostCopyDBSnapshot_603137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603151.validator(path, query, header, formData, body)
  let scheme = call_603151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603151.url(scheme.get, call_603151.host, call_603151.base,
                         call_603151.route, valid.getOrDefault("path"))
  result = hook(call_603151, url, valid)

proc call*(call_603152: Call_PostCopyDBSnapshot_603137;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603153 = newJObject()
  var formData_603154 = newJObject()
  add(formData_603154, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603153, "Action", newJString(Action))
  add(formData_603154, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603153, "Version", newJString(Version))
  result = call_603152.call(nil, query_603153, nil, formData_603154, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_603137(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_603138, base: "/",
    url: url_PostCopyDBSnapshot_603139, schemes: {Scheme.Https, Scheme.Http})
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
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603123 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603123 = validateParameter(valid_603123, JString, required = true,
                                 default = nil)
  if valid_603123 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603123
  var valid_603124 = query.getOrDefault("Action")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603124 != nil:
    section.add "Action", valid_603124
  var valid_603125 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = nil)
  if valid_603125 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603125
  var valid_603126 = query.getOrDefault("Version")
  valid_603126 = validateParameter(valid_603126, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603126 != nil:
    section.add "Version", valid_603126
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603127 = header.getOrDefault("X-Amz-Date")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Date", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Security-Token")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Security-Token", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Content-Sha256", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Algorithm")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Algorithm", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-Signature")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-Signature", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-SignedHeaders", valid_603132
  var valid_603133 = header.getOrDefault("X-Amz-Credential")
  valid_603133 = validateParameter(valid_603133, JString, required = false,
                                 default = nil)
  if valid_603133 != nil:
    section.add "X-Amz-Credential", valid_603133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603134: Call_GetCopyDBSnapshot_603120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603134.validator(path, query, header, formData, body)
  let scheme = call_603134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603134.url(scheme.get, call_603134.host, call_603134.base,
                         call_603134.route, valid.getOrDefault("path"))
  result = hook(call_603134, url, valid)

proc call*(call_603135: Call_GetCopyDBSnapshot_603120;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603136 = newJObject()
  add(query_603136, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603136, "Action", newJString(Action))
  add(query_603136, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603136, "Version", newJString(Version))
  result = call_603135.call(nil, query_603136, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_603120(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_603121,
    base: "/", url: url_GetCopyDBSnapshot_603122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603194 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBInstance_603196(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstance_603195(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603197 = query.getOrDefault("Action")
  valid_603197 = validateParameter(valid_603197, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603197 != nil:
    section.add "Action", valid_603197
  var valid_603198 = query.getOrDefault("Version")
  valid_603198 = validateParameter(valid_603198, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603198 != nil:
    section.add "Version", valid_603198
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603199 = header.getOrDefault("X-Amz-Date")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Date", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-Security-Token")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-Security-Token", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Content-Sha256", valid_603201
  var valid_603202 = header.getOrDefault("X-Amz-Algorithm")
  valid_603202 = validateParameter(valid_603202, JString, required = false,
                                 default = nil)
  if valid_603202 != nil:
    section.add "X-Amz-Algorithm", valid_603202
  var valid_603203 = header.getOrDefault("X-Amz-Signature")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "X-Amz-Signature", valid_603203
  var valid_603204 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "X-Amz-SignedHeaders", valid_603204
  var valid_603205 = header.getOrDefault("X-Amz-Credential")
  valid_603205 = validateParameter(valid_603205, JString, required = false,
                                 default = nil)
  if valid_603205 != nil:
    section.add "X-Amz-Credential", valid_603205
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
  var valid_603206 = formData.getOrDefault("DBSecurityGroups")
  valid_603206 = validateParameter(valid_603206, JArray, required = false,
                                 default = nil)
  if valid_603206 != nil:
    section.add "DBSecurityGroups", valid_603206
  var valid_603207 = formData.getOrDefault("Port")
  valid_603207 = validateParameter(valid_603207, JInt, required = false, default = nil)
  if valid_603207 != nil:
    section.add "Port", valid_603207
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603208 = formData.getOrDefault("Engine")
  valid_603208 = validateParameter(valid_603208, JString, required = true,
                                 default = nil)
  if valid_603208 != nil:
    section.add "Engine", valid_603208
  var valid_603209 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603209 = validateParameter(valid_603209, JArray, required = false,
                                 default = nil)
  if valid_603209 != nil:
    section.add "VpcSecurityGroupIds", valid_603209
  var valid_603210 = formData.getOrDefault("Iops")
  valid_603210 = validateParameter(valid_603210, JInt, required = false, default = nil)
  if valid_603210 != nil:
    section.add "Iops", valid_603210
  var valid_603211 = formData.getOrDefault("DBName")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "DBName", valid_603211
  var valid_603212 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = nil)
  if valid_603212 != nil:
    section.add "DBInstanceIdentifier", valid_603212
  var valid_603213 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603213 = validateParameter(valid_603213, JInt, required = false, default = nil)
  if valid_603213 != nil:
    section.add "BackupRetentionPeriod", valid_603213
  var valid_603214 = formData.getOrDefault("DBParameterGroupName")
  valid_603214 = validateParameter(valid_603214, JString, required = false,
                                 default = nil)
  if valid_603214 != nil:
    section.add "DBParameterGroupName", valid_603214
  var valid_603215 = formData.getOrDefault("OptionGroupName")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "OptionGroupName", valid_603215
  var valid_603216 = formData.getOrDefault("MasterUserPassword")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "MasterUserPassword", valid_603216
  var valid_603217 = formData.getOrDefault("DBSubnetGroupName")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "DBSubnetGroupName", valid_603217
  var valid_603218 = formData.getOrDefault("AvailabilityZone")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "AvailabilityZone", valid_603218
  var valid_603219 = formData.getOrDefault("MultiAZ")
  valid_603219 = validateParameter(valid_603219, JBool, required = false, default = nil)
  if valid_603219 != nil:
    section.add "MultiAZ", valid_603219
  var valid_603220 = formData.getOrDefault("AllocatedStorage")
  valid_603220 = validateParameter(valid_603220, JInt, required = true, default = nil)
  if valid_603220 != nil:
    section.add "AllocatedStorage", valid_603220
  var valid_603221 = formData.getOrDefault("PubliclyAccessible")
  valid_603221 = validateParameter(valid_603221, JBool, required = false, default = nil)
  if valid_603221 != nil:
    section.add "PubliclyAccessible", valid_603221
  var valid_603222 = formData.getOrDefault("MasterUsername")
  valid_603222 = validateParameter(valid_603222, JString, required = true,
                                 default = nil)
  if valid_603222 != nil:
    section.add "MasterUsername", valid_603222
  var valid_603223 = formData.getOrDefault("DBInstanceClass")
  valid_603223 = validateParameter(valid_603223, JString, required = true,
                                 default = nil)
  if valid_603223 != nil:
    section.add "DBInstanceClass", valid_603223
  var valid_603224 = formData.getOrDefault("CharacterSetName")
  valid_603224 = validateParameter(valid_603224, JString, required = false,
                                 default = nil)
  if valid_603224 != nil:
    section.add "CharacterSetName", valid_603224
  var valid_603225 = formData.getOrDefault("PreferredBackupWindow")
  valid_603225 = validateParameter(valid_603225, JString, required = false,
                                 default = nil)
  if valid_603225 != nil:
    section.add "PreferredBackupWindow", valid_603225
  var valid_603226 = formData.getOrDefault("LicenseModel")
  valid_603226 = validateParameter(valid_603226, JString, required = false,
                                 default = nil)
  if valid_603226 != nil:
    section.add "LicenseModel", valid_603226
  var valid_603227 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603227 = validateParameter(valid_603227, JBool, required = false, default = nil)
  if valid_603227 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603227
  var valid_603228 = formData.getOrDefault("EngineVersion")
  valid_603228 = validateParameter(valid_603228, JString, required = false,
                                 default = nil)
  if valid_603228 != nil:
    section.add "EngineVersion", valid_603228
  var valid_603229 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603229 = validateParameter(valid_603229, JString, required = false,
                                 default = nil)
  if valid_603229 != nil:
    section.add "PreferredMaintenanceWindow", valid_603229
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603230: Call_PostCreateDBInstance_603194; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603230.validator(path, query, header, formData, body)
  let scheme = call_603230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603230.url(scheme.get, call_603230.host, call_603230.base,
                         call_603230.route, valid.getOrDefault("path"))
  result = hook(call_603230, url, valid)

proc call*(call_603231: Call_PostCreateDBInstance_603194; Engine: string;
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
  var query_603232 = newJObject()
  var formData_603233 = newJObject()
  if DBSecurityGroups != nil:
    formData_603233.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603233, "Port", newJInt(Port))
  add(formData_603233, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_603233.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603233, "Iops", newJInt(Iops))
  add(formData_603233, "DBName", newJString(DBName))
  add(formData_603233, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603233, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603233, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603233, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603233, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603233, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603233, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603233, "MultiAZ", newJBool(MultiAZ))
  add(query_603232, "Action", newJString(Action))
  add(formData_603233, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_603233, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603233, "MasterUsername", newJString(MasterUsername))
  add(formData_603233, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603233, "CharacterSetName", newJString(CharacterSetName))
  add(formData_603233, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603233, "LicenseModel", newJString(LicenseModel))
  add(formData_603233, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603233, "EngineVersion", newJString(EngineVersion))
  add(query_603232, "Version", newJString(Version))
  add(formData_603233, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603231.call(nil, query_603232, nil, formData_603233, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603194(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603195, base: "/",
    url: url_PostCreateDBInstance_603196, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603155 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBInstance_603157(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstance_603156(path: JsonNode; query: JsonNode;
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
  var valid_603158 = query.getOrDefault("Engine")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "Engine", valid_603158
  var valid_603159 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603159 = validateParameter(valid_603159, JString, required = false,
                                 default = nil)
  if valid_603159 != nil:
    section.add "PreferredMaintenanceWindow", valid_603159
  var valid_603160 = query.getOrDefault("AllocatedStorage")
  valid_603160 = validateParameter(valid_603160, JInt, required = true, default = nil)
  if valid_603160 != nil:
    section.add "AllocatedStorage", valid_603160
  var valid_603161 = query.getOrDefault("OptionGroupName")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "OptionGroupName", valid_603161
  var valid_603162 = query.getOrDefault("DBSecurityGroups")
  valid_603162 = validateParameter(valid_603162, JArray, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "DBSecurityGroups", valid_603162
  var valid_603163 = query.getOrDefault("MasterUserPassword")
  valid_603163 = validateParameter(valid_603163, JString, required = true,
                                 default = nil)
  if valid_603163 != nil:
    section.add "MasterUserPassword", valid_603163
  var valid_603164 = query.getOrDefault("AvailabilityZone")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "AvailabilityZone", valid_603164
  var valid_603165 = query.getOrDefault("Iops")
  valid_603165 = validateParameter(valid_603165, JInt, required = false, default = nil)
  if valid_603165 != nil:
    section.add "Iops", valid_603165
  var valid_603166 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603166 = validateParameter(valid_603166, JArray, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "VpcSecurityGroupIds", valid_603166
  var valid_603167 = query.getOrDefault("MultiAZ")
  valid_603167 = validateParameter(valid_603167, JBool, required = false, default = nil)
  if valid_603167 != nil:
    section.add "MultiAZ", valid_603167
  var valid_603168 = query.getOrDefault("LicenseModel")
  valid_603168 = validateParameter(valid_603168, JString, required = false,
                                 default = nil)
  if valid_603168 != nil:
    section.add "LicenseModel", valid_603168
  var valid_603169 = query.getOrDefault("BackupRetentionPeriod")
  valid_603169 = validateParameter(valid_603169, JInt, required = false, default = nil)
  if valid_603169 != nil:
    section.add "BackupRetentionPeriod", valid_603169
  var valid_603170 = query.getOrDefault("DBName")
  valid_603170 = validateParameter(valid_603170, JString, required = false,
                                 default = nil)
  if valid_603170 != nil:
    section.add "DBName", valid_603170
  var valid_603171 = query.getOrDefault("DBParameterGroupName")
  valid_603171 = validateParameter(valid_603171, JString, required = false,
                                 default = nil)
  if valid_603171 != nil:
    section.add "DBParameterGroupName", valid_603171
  var valid_603172 = query.getOrDefault("DBInstanceClass")
  valid_603172 = validateParameter(valid_603172, JString, required = true,
                                 default = nil)
  if valid_603172 != nil:
    section.add "DBInstanceClass", valid_603172
  var valid_603173 = query.getOrDefault("Action")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603173 != nil:
    section.add "Action", valid_603173
  var valid_603174 = query.getOrDefault("DBSubnetGroupName")
  valid_603174 = validateParameter(valid_603174, JString, required = false,
                                 default = nil)
  if valid_603174 != nil:
    section.add "DBSubnetGroupName", valid_603174
  var valid_603175 = query.getOrDefault("CharacterSetName")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "CharacterSetName", valid_603175
  var valid_603176 = query.getOrDefault("PubliclyAccessible")
  valid_603176 = validateParameter(valid_603176, JBool, required = false, default = nil)
  if valid_603176 != nil:
    section.add "PubliclyAccessible", valid_603176
  var valid_603177 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603177 = validateParameter(valid_603177, JBool, required = false, default = nil)
  if valid_603177 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603177
  var valid_603178 = query.getOrDefault("EngineVersion")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "EngineVersion", valid_603178
  var valid_603179 = query.getOrDefault("Port")
  valid_603179 = validateParameter(valid_603179, JInt, required = false, default = nil)
  if valid_603179 != nil:
    section.add "Port", valid_603179
  var valid_603180 = query.getOrDefault("PreferredBackupWindow")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "PreferredBackupWindow", valid_603180
  var valid_603181 = query.getOrDefault("Version")
  valid_603181 = validateParameter(valid_603181, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603181 != nil:
    section.add "Version", valid_603181
  var valid_603182 = query.getOrDefault("DBInstanceIdentifier")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = nil)
  if valid_603182 != nil:
    section.add "DBInstanceIdentifier", valid_603182
  var valid_603183 = query.getOrDefault("MasterUsername")
  valid_603183 = validateParameter(valid_603183, JString, required = true,
                                 default = nil)
  if valid_603183 != nil:
    section.add "MasterUsername", valid_603183
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603184 = header.getOrDefault("X-Amz-Date")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Date", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-Security-Token")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-Security-Token", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Content-Sha256", valid_603186
  var valid_603187 = header.getOrDefault("X-Amz-Algorithm")
  valid_603187 = validateParameter(valid_603187, JString, required = false,
                                 default = nil)
  if valid_603187 != nil:
    section.add "X-Amz-Algorithm", valid_603187
  var valid_603188 = header.getOrDefault("X-Amz-Signature")
  valid_603188 = validateParameter(valid_603188, JString, required = false,
                                 default = nil)
  if valid_603188 != nil:
    section.add "X-Amz-Signature", valid_603188
  var valid_603189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603189 = validateParameter(valid_603189, JString, required = false,
                                 default = nil)
  if valid_603189 != nil:
    section.add "X-Amz-SignedHeaders", valid_603189
  var valid_603190 = header.getOrDefault("X-Amz-Credential")
  valid_603190 = validateParameter(valid_603190, JString, required = false,
                                 default = nil)
  if valid_603190 != nil:
    section.add "X-Amz-Credential", valid_603190
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603191: Call_GetCreateDBInstance_603155; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603191.validator(path, query, header, formData, body)
  let scheme = call_603191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603191.url(scheme.get, call_603191.host, call_603191.base,
                         call_603191.route, valid.getOrDefault("path"))
  result = hook(call_603191, url, valid)

proc call*(call_603192: Call_GetCreateDBInstance_603155; Engine: string;
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
  var query_603193 = newJObject()
  add(query_603193, "Engine", newJString(Engine))
  add(query_603193, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603193, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603193, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_603193.add "DBSecurityGroups", DBSecurityGroups
  add(query_603193, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603193, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603193, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_603193.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603193, "MultiAZ", newJBool(MultiAZ))
  add(query_603193, "LicenseModel", newJString(LicenseModel))
  add(query_603193, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603193, "DBName", newJString(DBName))
  add(query_603193, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603193, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603193, "Action", newJString(Action))
  add(query_603193, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603193, "CharacterSetName", newJString(CharacterSetName))
  add(query_603193, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603193, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603193, "EngineVersion", newJString(EngineVersion))
  add(query_603193, "Port", newJInt(Port))
  add(query_603193, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603193, "Version", newJString(Version))
  add(query_603193, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603193, "MasterUsername", newJString(MasterUsername))
  result = call_603192.call(nil, query_603193, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603155(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603156, base: "/",
    url: url_GetCreateDBInstance_603157, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_603258 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBInstanceReadReplica_603260(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBInstanceReadReplica_603259(path: JsonNode;
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
  var valid_603261 = query.getOrDefault("Action")
  valid_603261 = validateParameter(valid_603261, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603261 != nil:
    section.add "Action", valid_603261
  var valid_603262 = query.getOrDefault("Version")
  valid_603262 = validateParameter(valid_603262, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603262 != nil:
    section.add "Version", valid_603262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603263 = header.getOrDefault("X-Amz-Date")
  valid_603263 = validateParameter(valid_603263, JString, required = false,
                                 default = nil)
  if valid_603263 != nil:
    section.add "X-Amz-Date", valid_603263
  var valid_603264 = header.getOrDefault("X-Amz-Security-Token")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Security-Token", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Content-Sha256", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Algorithm")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Algorithm", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Signature")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Signature", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-SignedHeaders", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-Credential")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-Credential", valid_603269
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
  var valid_603270 = formData.getOrDefault("Port")
  valid_603270 = validateParameter(valid_603270, JInt, required = false, default = nil)
  if valid_603270 != nil:
    section.add "Port", valid_603270
  var valid_603271 = formData.getOrDefault("Iops")
  valid_603271 = validateParameter(valid_603271, JInt, required = false, default = nil)
  if valid_603271 != nil:
    section.add "Iops", valid_603271
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603272 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603272 = validateParameter(valid_603272, JString, required = true,
                                 default = nil)
  if valid_603272 != nil:
    section.add "DBInstanceIdentifier", valid_603272
  var valid_603273 = formData.getOrDefault("OptionGroupName")
  valid_603273 = validateParameter(valid_603273, JString, required = false,
                                 default = nil)
  if valid_603273 != nil:
    section.add "OptionGroupName", valid_603273
  var valid_603274 = formData.getOrDefault("AvailabilityZone")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "AvailabilityZone", valid_603274
  var valid_603275 = formData.getOrDefault("PubliclyAccessible")
  valid_603275 = validateParameter(valid_603275, JBool, required = false, default = nil)
  if valid_603275 != nil:
    section.add "PubliclyAccessible", valid_603275
  var valid_603276 = formData.getOrDefault("DBInstanceClass")
  valid_603276 = validateParameter(valid_603276, JString, required = false,
                                 default = nil)
  if valid_603276 != nil:
    section.add "DBInstanceClass", valid_603276
  var valid_603277 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603277 = validateParameter(valid_603277, JString, required = true,
                                 default = nil)
  if valid_603277 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603277
  var valid_603278 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603278 = validateParameter(valid_603278, JBool, required = false, default = nil)
  if valid_603278 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603278
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603279: Call_PostCreateDBInstanceReadReplica_603258;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603279.validator(path, query, header, formData, body)
  let scheme = call_603279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603279.url(scheme.get, call_603279.host, call_603279.base,
                         call_603279.route, valid.getOrDefault("path"))
  result = hook(call_603279, url, valid)

proc call*(call_603280: Call_PostCreateDBInstanceReadReplica_603258;
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
  var query_603281 = newJObject()
  var formData_603282 = newJObject()
  add(formData_603282, "Port", newJInt(Port))
  add(formData_603282, "Iops", newJInt(Iops))
  add(formData_603282, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603282, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603282, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603281, "Action", newJString(Action))
  add(formData_603282, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603282, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603282, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603282, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603281, "Version", newJString(Version))
  result = call_603280.call(nil, query_603281, nil, formData_603282, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_603258(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_603259, base: "/",
    url: url_PostCreateDBInstanceReadReplica_603260,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_603234 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBInstanceReadReplica_603236(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBInstanceReadReplica_603235(path: JsonNode;
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
  var valid_603237 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603237
  var valid_603238 = query.getOrDefault("OptionGroupName")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "OptionGroupName", valid_603238
  var valid_603239 = query.getOrDefault("AvailabilityZone")
  valid_603239 = validateParameter(valid_603239, JString, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "AvailabilityZone", valid_603239
  var valid_603240 = query.getOrDefault("Iops")
  valid_603240 = validateParameter(valid_603240, JInt, required = false, default = nil)
  if valid_603240 != nil:
    section.add "Iops", valid_603240
  var valid_603241 = query.getOrDefault("DBInstanceClass")
  valid_603241 = validateParameter(valid_603241, JString, required = false,
                                 default = nil)
  if valid_603241 != nil:
    section.add "DBInstanceClass", valid_603241
  var valid_603242 = query.getOrDefault("Action")
  valid_603242 = validateParameter(valid_603242, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603242 != nil:
    section.add "Action", valid_603242
  var valid_603243 = query.getOrDefault("PubliclyAccessible")
  valid_603243 = validateParameter(valid_603243, JBool, required = false, default = nil)
  if valid_603243 != nil:
    section.add "PubliclyAccessible", valid_603243
  var valid_603244 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603244 = validateParameter(valid_603244, JBool, required = false, default = nil)
  if valid_603244 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603244
  var valid_603245 = query.getOrDefault("Port")
  valid_603245 = validateParameter(valid_603245, JInt, required = false, default = nil)
  if valid_603245 != nil:
    section.add "Port", valid_603245
  var valid_603246 = query.getOrDefault("Version")
  valid_603246 = validateParameter(valid_603246, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603246 != nil:
    section.add "Version", valid_603246
  var valid_603247 = query.getOrDefault("DBInstanceIdentifier")
  valid_603247 = validateParameter(valid_603247, JString, required = true,
                                 default = nil)
  if valid_603247 != nil:
    section.add "DBInstanceIdentifier", valid_603247
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603248 = header.getOrDefault("X-Amz-Date")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "X-Amz-Date", valid_603248
  var valid_603249 = header.getOrDefault("X-Amz-Security-Token")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Security-Token", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Content-Sha256", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Algorithm")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Algorithm", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Signature")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Signature", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-SignedHeaders", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-Credential")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-Credential", valid_603254
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603255: Call_GetCreateDBInstanceReadReplica_603234; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603255.validator(path, query, header, formData, body)
  let scheme = call_603255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603255.url(scheme.get, call_603255.host, call_603255.base,
                         call_603255.route, valid.getOrDefault("path"))
  result = hook(call_603255, url, valid)

proc call*(call_603256: Call_GetCreateDBInstanceReadReplica_603234;
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
  var query_603257 = newJObject()
  add(query_603257, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603257, "OptionGroupName", newJString(OptionGroupName))
  add(query_603257, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603257, "Iops", newJInt(Iops))
  add(query_603257, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603257, "Action", newJString(Action))
  add(query_603257, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603257, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603257, "Port", newJInt(Port))
  add(query_603257, "Version", newJString(Version))
  add(query_603257, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603256.call(nil, query_603257, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_603234(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_603235, base: "/",
    url: url_GetCreateDBInstanceReadReplica_603236,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_603301 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBParameterGroup_603303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBParameterGroup_603302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603304 = query.getOrDefault("Action")
  valid_603304 = validateParameter(valid_603304, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603304 != nil:
    section.add "Action", valid_603304
  var valid_603305 = query.getOrDefault("Version")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603305 != nil:
    section.add "Version", valid_603305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603306 = header.getOrDefault("X-Amz-Date")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "X-Amz-Date", valid_603306
  var valid_603307 = header.getOrDefault("X-Amz-Security-Token")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "X-Amz-Security-Token", valid_603307
  var valid_603308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603308 = validateParameter(valid_603308, JString, required = false,
                                 default = nil)
  if valid_603308 != nil:
    section.add "X-Amz-Content-Sha256", valid_603308
  var valid_603309 = header.getOrDefault("X-Amz-Algorithm")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "X-Amz-Algorithm", valid_603309
  var valid_603310 = header.getOrDefault("X-Amz-Signature")
  valid_603310 = validateParameter(valid_603310, JString, required = false,
                                 default = nil)
  if valid_603310 != nil:
    section.add "X-Amz-Signature", valid_603310
  var valid_603311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603311 = validateParameter(valid_603311, JString, required = false,
                                 default = nil)
  if valid_603311 != nil:
    section.add "X-Amz-SignedHeaders", valid_603311
  var valid_603312 = header.getOrDefault("X-Amz-Credential")
  valid_603312 = validateParameter(valid_603312, JString, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "X-Amz-Credential", valid_603312
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603313 = formData.getOrDefault("DBParameterGroupName")
  valid_603313 = validateParameter(valid_603313, JString, required = true,
                                 default = nil)
  if valid_603313 != nil:
    section.add "DBParameterGroupName", valid_603313
  var valid_603314 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = nil)
  if valid_603314 != nil:
    section.add "DBParameterGroupFamily", valid_603314
  var valid_603315 = formData.getOrDefault("Description")
  valid_603315 = validateParameter(valid_603315, JString, required = true,
                                 default = nil)
  if valid_603315 != nil:
    section.add "Description", valid_603315
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603316: Call_PostCreateDBParameterGroup_603301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603316.validator(path, query, header, formData, body)
  let scheme = call_603316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603316.url(scheme.get, call_603316.host, call_603316.base,
                         call_603316.route, valid.getOrDefault("path"))
  result = hook(call_603316, url, valid)

proc call*(call_603317: Call_PostCreateDBParameterGroup_603301;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_603318 = newJObject()
  var formData_603319 = newJObject()
  add(formData_603319, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603318, "Action", newJString(Action))
  add(formData_603319, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603318, "Version", newJString(Version))
  add(formData_603319, "Description", newJString(Description))
  result = call_603317.call(nil, query_603318, nil, formData_603319, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_603301(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_603302, base: "/",
    url: url_PostCreateDBParameterGroup_603303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_603283 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBParameterGroup_603285(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBParameterGroup_603284(path: JsonNode; query: JsonNode;
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
  var valid_603286 = query.getOrDefault("Description")
  valid_603286 = validateParameter(valid_603286, JString, required = true,
                                 default = nil)
  if valid_603286 != nil:
    section.add "Description", valid_603286
  var valid_603287 = query.getOrDefault("DBParameterGroupFamily")
  valid_603287 = validateParameter(valid_603287, JString, required = true,
                                 default = nil)
  if valid_603287 != nil:
    section.add "DBParameterGroupFamily", valid_603287
  var valid_603288 = query.getOrDefault("DBParameterGroupName")
  valid_603288 = validateParameter(valid_603288, JString, required = true,
                                 default = nil)
  if valid_603288 != nil:
    section.add "DBParameterGroupName", valid_603288
  var valid_603289 = query.getOrDefault("Action")
  valid_603289 = validateParameter(valid_603289, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603289 != nil:
    section.add "Action", valid_603289
  var valid_603290 = query.getOrDefault("Version")
  valid_603290 = validateParameter(valid_603290, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603290 != nil:
    section.add "Version", valid_603290
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603291 = header.getOrDefault("X-Amz-Date")
  valid_603291 = validateParameter(valid_603291, JString, required = false,
                                 default = nil)
  if valid_603291 != nil:
    section.add "X-Amz-Date", valid_603291
  var valid_603292 = header.getOrDefault("X-Amz-Security-Token")
  valid_603292 = validateParameter(valid_603292, JString, required = false,
                                 default = nil)
  if valid_603292 != nil:
    section.add "X-Amz-Security-Token", valid_603292
  var valid_603293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603293 = validateParameter(valid_603293, JString, required = false,
                                 default = nil)
  if valid_603293 != nil:
    section.add "X-Amz-Content-Sha256", valid_603293
  var valid_603294 = header.getOrDefault("X-Amz-Algorithm")
  valid_603294 = validateParameter(valid_603294, JString, required = false,
                                 default = nil)
  if valid_603294 != nil:
    section.add "X-Amz-Algorithm", valid_603294
  var valid_603295 = header.getOrDefault("X-Amz-Signature")
  valid_603295 = validateParameter(valid_603295, JString, required = false,
                                 default = nil)
  if valid_603295 != nil:
    section.add "X-Amz-Signature", valid_603295
  var valid_603296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-SignedHeaders", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Credential")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Credential", valid_603297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603298: Call_GetCreateDBParameterGroup_603283; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603298.validator(path, query, header, formData, body)
  let scheme = call_603298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603298.url(scheme.get, call_603298.host, call_603298.base,
                         call_603298.route, valid.getOrDefault("path"))
  result = hook(call_603298, url, valid)

proc call*(call_603299: Call_GetCreateDBParameterGroup_603283; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603300 = newJObject()
  add(query_603300, "Description", newJString(Description))
  add(query_603300, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_603300, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603300, "Action", newJString(Action))
  add(query_603300, "Version", newJString(Version))
  result = call_603299.call(nil, query_603300, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_603283(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_603284, base: "/",
    url: url_GetCreateDBParameterGroup_603285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_603337 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSecurityGroup_603339(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSecurityGroup_603338(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603340 = query.getOrDefault("Action")
  valid_603340 = validateParameter(valid_603340, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603340 != nil:
    section.add "Action", valid_603340
  var valid_603341 = query.getOrDefault("Version")
  valid_603341 = validateParameter(valid_603341, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603341 != nil:
    section.add "Version", valid_603341
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603342 = header.getOrDefault("X-Amz-Date")
  valid_603342 = validateParameter(valid_603342, JString, required = false,
                                 default = nil)
  if valid_603342 != nil:
    section.add "X-Amz-Date", valid_603342
  var valid_603343 = header.getOrDefault("X-Amz-Security-Token")
  valid_603343 = validateParameter(valid_603343, JString, required = false,
                                 default = nil)
  if valid_603343 != nil:
    section.add "X-Amz-Security-Token", valid_603343
  var valid_603344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603344 = validateParameter(valid_603344, JString, required = false,
                                 default = nil)
  if valid_603344 != nil:
    section.add "X-Amz-Content-Sha256", valid_603344
  var valid_603345 = header.getOrDefault("X-Amz-Algorithm")
  valid_603345 = validateParameter(valid_603345, JString, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "X-Amz-Algorithm", valid_603345
  var valid_603346 = header.getOrDefault("X-Amz-Signature")
  valid_603346 = validateParameter(valid_603346, JString, required = false,
                                 default = nil)
  if valid_603346 != nil:
    section.add "X-Amz-Signature", valid_603346
  var valid_603347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603347 = validateParameter(valid_603347, JString, required = false,
                                 default = nil)
  if valid_603347 != nil:
    section.add "X-Amz-SignedHeaders", valid_603347
  var valid_603348 = header.getOrDefault("X-Amz-Credential")
  valid_603348 = validateParameter(valid_603348, JString, required = false,
                                 default = nil)
  if valid_603348 != nil:
    section.add "X-Amz-Credential", valid_603348
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603349 = formData.getOrDefault("DBSecurityGroupName")
  valid_603349 = validateParameter(valid_603349, JString, required = true,
                                 default = nil)
  if valid_603349 != nil:
    section.add "DBSecurityGroupName", valid_603349
  var valid_603350 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_603350 = validateParameter(valid_603350, JString, required = true,
                                 default = nil)
  if valid_603350 != nil:
    section.add "DBSecurityGroupDescription", valid_603350
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603351: Call_PostCreateDBSecurityGroup_603337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603351.validator(path, query, header, formData, body)
  let scheme = call_603351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603351.url(scheme.get, call_603351.host, call_603351.base,
                         call_603351.route, valid.getOrDefault("path"))
  result = hook(call_603351, url, valid)

proc call*(call_603352: Call_PostCreateDBSecurityGroup_603337;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_603353 = newJObject()
  var formData_603354 = newJObject()
  add(formData_603354, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603353, "Action", newJString(Action))
  add(formData_603354, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603353, "Version", newJString(Version))
  result = call_603352.call(nil, query_603353, nil, formData_603354, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_603337(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_603338, base: "/",
    url: url_PostCreateDBSecurityGroup_603339,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_603320 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSecurityGroup_603322(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSecurityGroup_603321(path: JsonNode; query: JsonNode;
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
  var valid_603323 = query.getOrDefault("DBSecurityGroupName")
  valid_603323 = validateParameter(valid_603323, JString, required = true,
                                 default = nil)
  if valid_603323 != nil:
    section.add "DBSecurityGroupName", valid_603323
  var valid_603324 = query.getOrDefault("DBSecurityGroupDescription")
  valid_603324 = validateParameter(valid_603324, JString, required = true,
                                 default = nil)
  if valid_603324 != nil:
    section.add "DBSecurityGroupDescription", valid_603324
  var valid_603325 = query.getOrDefault("Action")
  valid_603325 = validateParameter(valid_603325, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603325 != nil:
    section.add "Action", valid_603325
  var valid_603326 = query.getOrDefault("Version")
  valid_603326 = validateParameter(valid_603326, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603326 != nil:
    section.add "Version", valid_603326
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603327 = header.getOrDefault("X-Amz-Date")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Date", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Security-Token")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Security-Token", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-Content-Sha256", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Algorithm")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Algorithm", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Signature")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Signature", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-SignedHeaders", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Credential")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Credential", valid_603333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603334: Call_GetCreateDBSecurityGroup_603320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603334.validator(path, query, header, formData, body)
  let scheme = call_603334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603334.url(scheme.get, call_603334.host, call_603334.base,
                         call_603334.route, valid.getOrDefault("path"))
  result = hook(call_603334, url, valid)

proc call*(call_603335: Call_GetCreateDBSecurityGroup_603320;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603336 = newJObject()
  add(query_603336, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603336, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603336, "Action", newJString(Action))
  add(query_603336, "Version", newJString(Version))
  result = call_603335.call(nil, query_603336, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_603320(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_603321, base: "/",
    url: url_GetCreateDBSecurityGroup_603322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_603372 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSnapshot_603374(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSnapshot_603373(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603375 = query.getOrDefault("Action")
  valid_603375 = validateParameter(valid_603375, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603375 != nil:
    section.add "Action", valid_603375
  var valid_603376 = query.getOrDefault("Version")
  valid_603376 = validateParameter(valid_603376, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603376 != nil:
    section.add "Version", valid_603376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603377 = header.getOrDefault("X-Amz-Date")
  valid_603377 = validateParameter(valid_603377, JString, required = false,
                                 default = nil)
  if valid_603377 != nil:
    section.add "X-Amz-Date", valid_603377
  var valid_603378 = header.getOrDefault("X-Amz-Security-Token")
  valid_603378 = validateParameter(valid_603378, JString, required = false,
                                 default = nil)
  if valid_603378 != nil:
    section.add "X-Amz-Security-Token", valid_603378
  var valid_603379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603379 = validateParameter(valid_603379, JString, required = false,
                                 default = nil)
  if valid_603379 != nil:
    section.add "X-Amz-Content-Sha256", valid_603379
  var valid_603380 = header.getOrDefault("X-Amz-Algorithm")
  valid_603380 = validateParameter(valid_603380, JString, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "X-Amz-Algorithm", valid_603380
  var valid_603381 = header.getOrDefault("X-Amz-Signature")
  valid_603381 = validateParameter(valid_603381, JString, required = false,
                                 default = nil)
  if valid_603381 != nil:
    section.add "X-Amz-Signature", valid_603381
  var valid_603382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603382 = validateParameter(valid_603382, JString, required = false,
                                 default = nil)
  if valid_603382 != nil:
    section.add "X-Amz-SignedHeaders", valid_603382
  var valid_603383 = header.getOrDefault("X-Amz-Credential")
  valid_603383 = validateParameter(valid_603383, JString, required = false,
                                 default = nil)
  if valid_603383 != nil:
    section.add "X-Amz-Credential", valid_603383
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603384 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603384 = validateParameter(valid_603384, JString, required = true,
                                 default = nil)
  if valid_603384 != nil:
    section.add "DBInstanceIdentifier", valid_603384
  var valid_603385 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603385 = validateParameter(valid_603385, JString, required = true,
                                 default = nil)
  if valid_603385 != nil:
    section.add "DBSnapshotIdentifier", valid_603385
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603386: Call_PostCreateDBSnapshot_603372; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603386.validator(path, query, header, formData, body)
  let scheme = call_603386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603386.url(scheme.get, call_603386.host, call_603386.base,
                         call_603386.route, valid.getOrDefault("path"))
  result = hook(call_603386, url, valid)

proc call*(call_603387: Call_PostCreateDBSnapshot_603372;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603388 = newJObject()
  var formData_603389 = newJObject()
  add(formData_603389, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603389, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603388, "Action", newJString(Action))
  add(query_603388, "Version", newJString(Version))
  result = call_603387.call(nil, query_603388, nil, formData_603389, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_603372(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_603373, base: "/",
    url: url_PostCreateDBSnapshot_603374, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_603355 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSnapshot_603357(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSnapshot_603356(path: JsonNode; query: JsonNode;
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
  var valid_603358 = query.getOrDefault("Action")
  valid_603358 = validateParameter(valid_603358, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603358 != nil:
    section.add "Action", valid_603358
  var valid_603359 = query.getOrDefault("Version")
  valid_603359 = validateParameter(valid_603359, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603359 != nil:
    section.add "Version", valid_603359
  var valid_603360 = query.getOrDefault("DBInstanceIdentifier")
  valid_603360 = validateParameter(valid_603360, JString, required = true,
                                 default = nil)
  if valid_603360 != nil:
    section.add "DBInstanceIdentifier", valid_603360
  var valid_603361 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603361 = validateParameter(valid_603361, JString, required = true,
                                 default = nil)
  if valid_603361 != nil:
    section.add "DBSnapshotIdentifier", valid_603361
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603362 = header.getOrDefault("X-Amz-Date")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Date", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Security-Token")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Security-Token", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Content-Sha256", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Algorithm")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Algorithm", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Signature")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Signature", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-SignedHeaders", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Credential")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Credential", valid_603368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603369: Call_GetCreateDBSnapshot_603355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603369.validator(path, query, header, formData, body)
  let scheme = call_603369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603369.url(scheme.get, call_603369.host, call_603369.base,
                         call_603369.route, valid.getOrDefault("path"))
  result = hook(call_603369, url, valid)

proc call*(call_603370: Call_GetCreateDBSnapshot_603355;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603371 = newJObject()
  add(query_603371, "Action", newJString(Action))
  add(query_603371, "Version", newJString(Version))
  add(query_603371, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603371, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603370.call(nil, query_603371, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_603355(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_603356, base: "/",
    url: url_GetCreateDBSnapshot_603357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603408 = ref object of OpenApiRestCall_602417
proc url_PostCreateDBSubnetGroup_603410(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDBSubnetGroup_603409(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603411 = query.getOrDefault("Action")
  valid_603411 = validateParameter(valid_603411, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603411 != nil:
    section.add "Action", valid_603411
  var valid_603412 = query.getOrDefault("Version")
  valid_603412 = validateParameter(valid_603412, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603420 = formData.getOrDefault("DBSubnetGroupName")
  valid_603420 = validateParameter(valid_603420, JString, required = true,
                                 default = nil)
  if valid_603420 != nil:
    section.add "DBSubnetGroupName", valid_603420
  var valid_603421 = formData.getOrDefault("SubnetIds")
  valid_603421 = validateParameter(valid_603421, JArray, required = true, default = nil)
  if valid_603421 != nil:
    section.add "SubnetIds", valid_603421
  var valid_603422 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603422 = validateParameter(valid_603422, JString, required = true,
                                 default = nil)
  if valid_603422 != nil:
    section.add "DBSubnetGroupDescription", valid_603422
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603423: Call_PostCreateDBSubnetGroup_603408; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603423.validator(path, query, header, formData, body)
  let scheme = call_603423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603423.url(scheme.get, call_603423.host, call_603423.base,
                         call_603423.route, valid.getOrDefault("path"))
  result = hook(call_603423, url, valid)

proc call*(call_603424: Call_PostCreateDBSubnetGroup_603408;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_603425 = newJObject()
  var formData_603426 = newJObject()
  add(formData_603426, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603426.add "SubnetIds", SubnetIds
  add(query_603425, "Action", newJString(Action))
  add(formData_603426, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603425, "Version", newJString(Version))
  result = call_603424.call(nil, query_603425, nil, formData_603426, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603408(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603409, base: "/",
    url: url_PostCreateDBSubnetGroup_603410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603390 = ref object of OpenApiRestCall_602417
proc url_GetCreateDBSubnetGroup_603392(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDBSubnetGroup_603391(path: JsonNode; query: JsonNode;
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
  var valid_603393 = query.getOrDefault("Action")
  valid_603393 = validateParameter(valid_603393, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603393 != nil:
    section.add "Action", valid_603393
  var valid_603394 = query.getOrDefault("DBSubnetGroupName")
  valid_603394 = validateParameter(valid_603394, JString, required = true,
                                 default = nil)
  if valid_603394 != nil:
    section.add "DBSubnetGroupName", valid_603394
  var valid_603395 = query.getOrDefault("SubnetIds")
  valid_603395 = validateParameter(valid_603395, JArray, required = true, default = nil)
  if valid_603395 != nil:
    section.add "SubnetIds", valid_603395
  var valid_603396 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603396 = validateParameter(valid_603396, JString, required = true,
                                 default = nil)
  if valid_603396 != nil:
    section.add "DBSubnetGroupDescription", valid_603396
  var valid_603397 = query.getOrDefault("Version")
  valid_603397 = validateParameter(valid_603397, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603397 != nil:
    section.add "Version", valid_603397
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603398 = header.getOrDefault("X-Amz-Date")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Date", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Security-Token")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Security-Token", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Content-Sha256", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Algorithm")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Algorithm", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Signature")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Signature", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-SignedHeaders", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-Credential")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-Credential", valid_603404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603405: Call_GetCreateDBSubnetGroup_603390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603405.validator(path, query, header, formData, body)
  let scheme = call_603405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603405.url(scheme.get, call_603405.host, call_603405.base,
                         call_603405.route, valid.getOrDefault("path"))
  result = hook(call_603405, url, valid)

proc call*(call_603406: Call_GetCreateDBSubnetGroup_603390;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-02-12"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_603407 = newJObject()
  add(query_603407, "Action", newJString(Action))
  add(query_603407, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603407.add "SubnetIds", SubnetIds
  add(query_603407, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603407, "Version", newJString(Version))
  result = call_603406.call(nil, query_603407, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603390(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603391, base: "/",
    url: url_GetCreateDBSubnetGroup_603392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_603448 = ref object of OpenApiRestCall_602417
proc url_PostCreateEventSubscription_603450(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateEventSubscription_603449(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603451 = query.getOrDefault("Action")
  valid_603451 = validateParameter(valid_603451, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603451 != nil:
    section.add "Action", valid_603451
  var valid_603452 = query.getOrDefault("Version")
  valid_603452 = validateParameter(valid_603452, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603452 != nil:
    section.add "Version", valid_603452
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603453 = header.getOrDefault("X-Amz-Date")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Date", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Security-Token")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Security-Token", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Content-Sha256", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-Algorithm")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-Algorithm", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Signature")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Signature", valid_603457
  var valid_603458 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603458 = validateParameter(valid_603458, JString, required = false,
                                 default = nil)
  if valid_603458 != nil:
    section.add "X-Amz-SignedHeaders", valid_603458
  var valid_603459 = header.getOrDefault("X-Amz-Credential")
  valid_603459 = validateParameter(valid_603459, JString, required = false,
                                 default = nil)
  if valid_603459 != nil:
    section.add "X-Amz-Credential", valid_603459
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_603460 = formData.getOrDefault("Enabled")
  valid_603460 = validateParameter(valid_603460, JBool, required = false, default = nil)
  if valid_603460 != nil:
    section.add "Enabled", valid_603460
  var valid_603461 = formData.getOrDefault("EventCategories")
  valid_603461 = validateParameter(valid_603461, JArray, required = false,
                                 default = nil)
  if valid_603461 != nil:
    section.add "EventCategories", valid_603461
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_603462 = formData.getOrDefault("SnsTopicArn")
  valid_603462 = validateParameter(valid_603462, JString, required = true,
                                 default = nil)
  if valid_603462 != nil:
    section.add "SnsTopicArn", valid_603462
  var valid_603463 = formData.getOrDefault("SourceIds")
  valid_603463 = validateParameter(valid_603463, JArray, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "SourceIds", valid_603463
  var valid_603464 = formData.getOrDefault("SubscriptionName")
  valid_603464 = validateParameter(valid_603464, JString, required = true,
                                 default = nil)
  if valid_603464 != nil:
    section.add "SubscriptionName", valid_603464
  var valid_603465 = formData.getOrDefault("SourceType")
  valid_603465 = validateParameter(valid_603465, JString, required = false,
                                 default = nil)
  if valid_603465 != nil:
    section.add "SourceType", valid_603465
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603466: Call_PostCreateEventSubscription_603448; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603466.validator(path, query, header, formData, body)
  let scheme = call_603466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603466.url(scheme.get, call_603466.host, call_603466.base,
                         call_603466.route, valid.getOrDefault("path"))
  result = hook(call_603466, url, valid)

proc call*(call_603467: Call_PostCreateEventSubscription_603448;
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
  var query_603468 = newJObject()
  var formData_603469 = newJObject()
  add(formData_603469, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_603469.add "EventCategories", EventCategories
  add(formData_603469, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_603469.add "SourceIds", SourceIds
  add(formData_603469, "SubscriptionName", newJString(SubscriptionName))
  add(query_603468, "Action", newJString(Action))
  add(query_603468, "Version", newJString(Version))
  add(formData_603469, "SourceType", newJString(SourceType))
  result = call_603467.call(nil, query_603468, nil, formData_603469, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_603448(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_603449, base: "/",
    url: url_PostCreateEventSubscription_603450,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_603427 = ref object of OpenApiRestCall_602417
proc url_GetCreateEventSubscription_603429(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateEventSubscription_603428(path: JsonNode; query: JsonNode;
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
  var valid_603430 = query.getOrDefault("SourceType")
  valid_603430 = validateParameter(valid_603430, JString, required = false,
                                 default = nil)
  if valid_603430 != nil:
    section.add "SourceType", valid_603430
  var valid_603431 = query.getOrDefault("SourceIds")
  valid_603431 = validateParameter(valid_603431, JArray, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "SourceIds", valid_603431
  var valid_603432 = query.getOrDefault("Enabled")
  valid_603432 = validateParameter(valid_603432, JBool, required = false, default = nil)
  if valid_603432 != nil:
    section.add "Enabled", valid_603432
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603433 = query.getOrDefault("Action")
  valid_603433 = validateParameter(valid_603433, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603433 != nil:
    section.add "Action", valid_603433
  var valid_603434 = query.getOrDefault("SnsTopicArn")
  valid_603434 = validateParameter(valid_603434, JString, required = true,
                                 default = nil)
  if valid_603434 != nil:
    section.add "SnsTopicArn", valid_603434
  var valid_603435 = query.getOrDefault("EventCategories")
  valid_603435 = validateParameter(valid_603435, JArray, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "EventCategories", valid_603435
  var valid_603436 = query.getOrDefault("SubscriptionName")
  valid_603436 = validateParameter(valid_603436, JString, required = true,
                                 default = nil)
  if valid_603436 != nil:
    section.add "SubscriptionName", valid_603436
  var valid_603437 = query.getOrDefault("Version")
  valid_603437 = validateParameter(valid_603437, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603437 != nil:
    section.add "Version", valid_603437
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603438 = header.getOrDefault("X-Amz-Date")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-Date", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Security-Token")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Security-Token", valid_603439
  var valid_603440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603440 = validateParameter(valid_603440, JString, required = false,
                                 default = nil)
  if valid_603440 != nil:
    section.add "X-Amz-Content-Sha256", valid_603440
  var valid_603441 = header.getOrDefault("X-Amz-Algorithm")
  valid_603441 = validateParameter(valid_603441, JString, required = false,
                                 default = nil)
  if valid_603441 != nil:
    section.add "X-Amz-Algorithm", valid_603441
  var valid_603442 = header.getOrDefault("X-Amz-Signature")
  valid_603442 = validateParameter(valid_603442, JString, required = false,
                                 default = nil)
  if valid_603442 != nil:
    section.add "X-Amz-Signature", valid_603442
  var valid_603443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603443 = validateParameter(valid_603443, JString, required = false,
                                 default = nil)
  if valid_603443 != nil:
    section.add "X-Amz-SignedHeaders", valid_603443
  var valid_603444 = header.getOrDefault("X-Amz-Credential")
  valid_603444 = validateParameter(valid_603444, JString, required = false,
                                 default = nil)
  if valid_603444 != nil:
    section.add "X-Amz-Credential", valid_603444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603445: Call_GetCreateEventSubscription_603427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603445.validator(path, query, header, formData, body)
  let scheme = call_603445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603445.url(scheme.get, call_603445.host, call_603445.base,
                         call_603445.route, valid.getOrDefault("path"))
  result = hook(call_603445, url, valid)

proc call*(call_603446: Call_GetCreateEventSubscription_603427;
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
  var query_603447 = newJObject()
  add(query_603447, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_603447.add "SourceIds", SourceIds
  add(query_603447, "Enabled", newJBool(Enabled))
  add(query_603447, "Action", newJString(Action))
  add(query_603447, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_603447.add "EventCategories", EventCategories
  add(query_603447, "SubscriptionName", newJString(SubscriptionName))
  add(query_603447, "Version", newJString(Version))
  result = call_603446.call(nil, query_603447, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_603427(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_603428, base: "/",
    url: url_GetCreateEventSubscription_603429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_603489 = ref object of OpenApiRestCall_602417
proc url_PostCreateOptionGroup_603491(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateOptionGroup_603490(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603492 = query.getOrDefault("Action")
  valid_603492 = validateParameter(valid_603492, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603492 != nil:
    section.add "Action", valid_603492
  var valid_603493 = query.getOrDefault("Version")
  valid_603493 = validateParameter(valid_603493, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603493 != nil:
    section.add "Version", valid_603493
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603494 = header.getOrDefault("X-Amz-Date")
  valid_603494 = validateParameter(valid_603494, JString, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "X-Amz-Date", valid_603494
  var valid_603495 = header.getOrDefault("X-Amz-Security-Token")
  valid_603495 = validateParameter(valid_603495, JString, required = false,
                                 default = nil)
  if valid_603495 != nil:
    section.add "X-Amz-Security-Token", valid_603495
  var valid_603496 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603496 = validateParameter(valid_603496, JString, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "X-Amz-Content-Sha256", valid_603496
  var valid_603497 = header.getOrDefault("X-Amz-Algorithm")
  valid_603497 = validateParameter(valid_603497, JString, required = false,
                                 default = nil)
  if valid_603497 != nil:
    section.add "X-Amz-Algorithm", valid_603497
  var valid_603498 = header.getOrDefault("X-Amz-Signature")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "X-Amz-Signature", valid_603498
  var valid_603499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-SignedHeaders", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Credential")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Credential", valid_603500
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_603501 = formData.getOrDefault("MajorEngineVersion")
  valid_603501 = validateParameter(valid_603501, JString, required = true,
                                 default = nil)
  if valid_603501 != nil:
    section.add "MajorEngineVersion", valid_603501
  var valid_603502 = formData.getOrDefault("OptionGroupName")
  valid_603502 = validateParameter(valid_603502, JString, required = true,
                                 default = nil)
  if valid_603502 != nil:
    section.add "OptionGroupName", valid_603502
  var valid_603503 = formData.getOrDefault("EngineName")
  valid_603503 = validateParameter(valid_603503, JString, required = true,
                                 default = nil)
  if valid_603503 != nil:
    section.add "EngineName", valid_603503
  var valid_603504 = formData.getOrDefault("OptionGroupDescription")
  valid_603504 = validateParameter(valid_603504, JString, required = true,
                                 default = nil)
  if valid_603504 != nil:
    section.add "OptionGroupDescription", valid_603504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603505: Call_PostCreateOptionGroup_603489; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603505.validator(path, query, header, formData, body)
  let scheme = call_603505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603505.url(scheme.get, call_603505.host, call_603505.base,
                         call_603505.route, valid.getOrDefault("path"))
  result = hook(call_603505, url, valid)

proc call*(call_603506: Call_PostCreateOptionGroup_603489;
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
  var query_603507 = newJObject()
  var formData_603508 = newJObject()
  add(formData_603508, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_603508, "OptionGroupName", newJString(OptionGroupName))
  add(query_603507, "Action", newJString(Action))
  add(formData_603508, "EngineName", newJString(EngineName))
  add(formData_603508, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_603507, "Version", newJString(Version))
  result = call_603506.call(nil, query_603507, nil, formData_603508, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_603489(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_603490, base: "/",
    url: url_PostCreateOptionGroup_603491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_603470 = ref object of OpenApiRestCall_602417
proc url_GetCreateOptionGroup_603472(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateOptionGroup_603471(path: JsonNode; query: JsonNode;
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
  var valid_603473 = query.getOrDefault("OptionGroupName")
  valid_603473 = validateParameter(valid_603473, JString, required = true,
                                 default = nil)
  if valid_603473 != nil:
    section.add "OptionGroupName", valid_603473
  var valid_603474 = query.getOrDefault("OptionGroupDescription")
  valid_603474 = validateParameter(valid_603474, JString, required = true,
                                 default = nil)
  if valid_603474 != nil:
    section.add "OptionGroupDescription", valid_603474
  var valid_603475 = query.getOrDefault("Action")
  valid_603475 = validateParameter(valid_603475, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603475 != nil:
    section.add "Action", valid_603475
  var valid_603476 = query.getOrDefault("Version")
  valid_603476 = validateParameter(valid_603476, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603476 != nil:
    section.add "Version", valid_603476
  var valid_603477 = query.getOrDefault("EngineName")
  valid_603477 = validateParameter(valid_603477, JString, required = true,
                                 default = nil)
  if valid_603477 != nil:
    section.add "EngineName", valid_603477
  var valid_603478 = query.getOrDefault("MajorEngineVersion")
  valid_603478 = validateParameter(valid_603478, JString, required = true,
                                 default = nil)
  if valid_603478 != nil:
    section.add "MajorEngineVersion", valid_603478
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603479 = header.getOrDefault("X-Amz-Date")
  valid_603479 = validateParameter(valid_603479, JString, required = false,
                                 default = nil)
  if valid_603479 != nil:
    section.add "X-Amz-Date", valid_603479
  var valid_603480 = header.getOrDefault("X-Amz-Security-Token")
  valid_603480 = validateParameter(valid_603480, JString, required = false,
                                 default = nil)
  if valid_603480 != nil:
    section.add "X-Amz-Security-Token", valid_603480
  var valid_603481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603481 = validateParameter(valid_603481, JString, required = false,
                                 default = nil)
  if valid_603481 != nil:
    section.add "X-Amz-Content-Sha256", valid_603481
  var valid_603482 = header.getOrDefault("X-Amz-Algorithm")
  valid_603482 = validateParameter(valid_603482, JString, required = false,
                                 default = nil)
  if valid_603482 != nil:
    section.add "X-Amz-Algorithm", valid_603482
  var valid_603483 = header.getOrDefault("X-Amz-Signature")
  valid_603483 = validateParameter(valid_603483, JString, required = false,
                                 default = nil)
  if valid_603483 != nil:
    section.add "X-Amz-Signature", valid_603483
  var valid_603484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-SignedHeaders", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Credential")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Credential", valid_603485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603486: Call_GetCreateOptionGroup_603470; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603486.validator(path, query, header, formData, body)
  let scheme = call_603486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603486.url(scheme.get, call_603486.host, call_603486.base,
                         call_603486.route, valid.getOrDefault("path"))
  result = hook(call_603486, url, valid)

proc call*(call_603487: Call_GetCreateOptionGroup_603470; OptionGroupName: string;
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
  var query_603488 = newJObject()
  add(query_603488, "OptionGroupName", newJString(OptionGroupName))
  add(query_603488, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_603488, "Action", newJString(Action))
  add(query_603488, "Version", newJString(Version))
  add(query_603488, "EngineName", newJString(EngineName))
  add(query_603488, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603487.call(nil, query_603488, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_603470(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_603471, base: "/",
    url: url_GetCreateOptionGroup_603472, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603527 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBInstance_603529(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBInstance_603528(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603530 = query.getOrDefault("Action")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603530 != nil:
    section.add "Action", valid_603530
  var valid_603531 = query.getOrDefault("Version")
  valid_603531 = validateParameter(valid_603531, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603531 != nil:
    section.add "Version", valid_603531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603532 = header.getOrDefault("X-Amz-Date")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Date", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Security-Token")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Security-Token", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Content-Sha256", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Algorithm")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Algorithm", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Signature")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Signature", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-SignedHeaders", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Credential")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Credential", valid_603538
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603539 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603539 = validateParameter(valid_603539, JString, required = true,
                                 default = nil)
  if valid_603539 != nil:
    section.add "DBInstanceIdentifier", valid_603539
  var valid_603540 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603540 = validateParameter(valid_603540, JString, required = false,
                                 default = nil)
  if valid_603540 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603540
  var valid_603541 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603541 = validateParameter(valid_603541, JBool, required = false, default = nil)
  if valid_603541 != nil:
    section.add "SkipFinalSnapshot", valid_603541
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603542: Call_PostDeleteDBInstance_603527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603542.validator(path, query, header, formData, body)
  let scheme = call_603542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603542.url(scheme.get, call_603542.host, call_603542.base,
                         call_603542.route, valid.getOrDefault("path"))
  result = hook(call_603542, url, valid)

proc call*(call_603543: Call_PostDeleteDBInstance_603527;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-02-12";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_603544 = newJObject()
  var formData_603545 = newJObject()
  add(formData_603545, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603545, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603544, "Action", newJString(Action))
  add(query_603544, "Version", newJString(Version))
  add(formData_603545, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603543.call(nil, query_603544, nil, formData_603545, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603527(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603528, base: "/",
    url: url_PostDeleteDBInstance_603529, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603509 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBInstance_603511(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBInstance_603510(path: JsonNode; query: JsonNode;
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
  var valid_603512 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603512
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603513 = query.getOrDefault("Action")
  valid_603513 = validateParameter(valid_603513, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603513 != nil:
    section.add "Action", valid_603513
  var valid_603514 = query.getOrDefault("SkipFinalSnapshot")
  valid_603514 = validateParameter(valid_603514, JBool, required = false, default = nil)
  if valid_603514 != nil:
    section.add "SkipFinalSnapshot", valid_603514
  var valid_603515 = query.getOrDefault("Version")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603515 != nil:
    section.add "Version", valid_603515
  var valid_603516 = query.getOrDefault("DBInstanceIdentifier")
  valid_603516 = validateParameter(valid_603516, JString, required = true,
                                 default = nil)
  if valid_603516 != nil:
    section.add "DBInstanceIdentifier", valid_603516
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Security-Token")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Security-Token", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Content-Sha256", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Algorithm")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Algorithm", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Signature")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Signature", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-SignedHeaders", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Credential")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Credential", valid_603523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603524: Call_GetDeleteDBInstance_603509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603524.validator(path, query, header, formData, body)
  let scheme = call_603524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603524.url(scheme.get, call_603524.host, call_603524.base,
                         call_603524.route, valid.getOrDefault("path"))
  result = hook(call_603524, url, valid)

proc call*(call_603525: Call_GetDeleteDBInstance_603509;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_603526 = newJObject()
  add(query_603526, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603526, "Action", newJString(Action))
  add(query_603526, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603526, "Version", newJString(Version))
  add(query_603526, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603525.call(nil, query_603526, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603509(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603510, base: "/",
    url: url_GetDeleteDBInstance_603511, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_603562 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBParameterGroup_603564(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBParameterGroup_603563(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603565 = query.getOrDefault("Action")
  valid_603565 = validateParameter(valid_603565, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603565 != nil:
    section.add "Action", valid_603565
  var valid_603566 = query.getOrDefault("Version")
  valid_603566 = validateParameter(valid_603566, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603566 != nil:
    section.add "Version", valid_603566
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603567 = header.getOrDefault("X-Amz-Date")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Date", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Security-Token")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Security-Token", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Content-Sha256", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-Algorithm")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-Algorithm", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Signature")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Signature", valid_603571
  var valid_603572 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603572 = validateParameter(valid_603572, JString, required = false,
                                 default = nil)
  if valid_603572 != nil:
    section.add "X-Amz-SignedHeaders", valid_603572
  var valid_603573 = header.getOrDefault("X-Amz-Credential")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "X-Amz-Credential", valid_603573
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603574 = formData.getOrDefault("DBParameterGroupName")
  valid_603574 = validateParameter(valid_603574, JString, required = true,
                                 default = nil)
  if valid_603574 != nil:
    section.add "DBParameterGroupName", valid_603574
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603575: Call_PostDeleteDBParameterGroup_603562; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603575.validator(path, query, header, formData, body)
  let scheme = call_603575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603575.url(scheme.get, call_603575.host, call_603575.base,
                         call_603575.route, valid.getOrDefault("path"))
  result = hook(call_603575, url, valid)

proc call*(call_603576: Call_PostDeleteDBParameterGroup_603562;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603577 = newJObject()
  var formData_603578 = newJObject()
  add(formData_603578, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603577, "Action", newJString(Action))
  add(query_603577, "Version", newJString(Version))
  result = call_603576.call(nil, query_603577, nil, formData_603578, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_603562(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_603563, base: "/",
    url: url_PostDeleteDBParameterGroup_603564,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_603546 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBParameterGroup_603548(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBParameterGroup_603547(path: JsonNode; query: JsonNode;
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
  var valid_603549 = query.getOrDefault("DBParameterGroupName")
  valid_603549 = validateParameter(valid_603549, JString, required = true,
                                 default = nil)
  if valid_603549 != nil:
    section.add "DBParameterGroupName", valid_603549
  var valid_603550 = query.getOrDefault("Action")
  valid_603550 = validateParameter(valid_603550, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603550 != nil:
    section.add "Action", valid_603550
  var valid_603551 = query.getOrDefault("Version")
  valid_603551 = validateParameter(valid_603551, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603559: Call_GetDeleteDBParameterGroup_603546; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603559.validator(path, query, header, formData, body)
  let scheme = call_603559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603559.url(scheme.get, call_603559.host, call_603559.base,
                         call_603559.route, valid.getOrDefault("path"))
  result = hook(call_603559, url, valid)

proc call*(call_603560: Call_GetDeleteDBParameterGroup_603546;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603561 = newJObject()
  add(query_603561, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603561, "Action", newJString(Action))
  add(query_603561, "Version", newJString(Version))
  result = call_603560.call(nil, query_603561, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_603546(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_603547, base: "/",
    url: url_GetDeleteDBParameterGroup_603548,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_603595 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSecurityGroup_603597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSecurityGroup_603596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603598 = query.getOrDefault("Action")
  valid_603598 = validateParameter(valid_603598, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603598 != nil:
    section.add "Action", valid_603598
  var valid_603599 = query.getOrDefault("Version")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603599 != nil:
    section.add "Version", valid_603599
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603600 = header.getOrDefault("X-Amz-Date")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Date", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Security-Token")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Security-Token", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Content-Sha256", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Algorithm")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Algorithm", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-Signature")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-Signature", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-SignedHeaders", valid_603605
  var valid_603606 = header.getOrDefault("X-Amz-Credential")
  valid_603606 = validateParameter(valid_603606, JString, required = false,
                                 default = nil)
  if valid_603606 != nil:
    section.add "X-Amz-Credential", valid_603606
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603607 = formData.getOrDefault("DBSecurityGroupName")
  valid_603607 = validateParameter(valid_603607, JString, required = true,
                                 default = nil)
  if valid_603607 != nil:
    section.add "DBSecurityGroupName", valid_603607
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603608: Call_PostDeleteDBSecurityGroup_603595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603608.validator(path, query, header, formData, body)
  let scheme = call_603608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603608.url(scheme.get, call_603608.host, call_603608.base,
                         call_603608.route, valid.getOrDefault("path"))
  result = hook(call_603608, url, valid)

proc call*(call_603609: Call_PostDeleteDBSecurityGroup_603595;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603610 = newJObject()
  var formData_603611 = newJObject()
  add(formData_603611, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603610, "Action", newJString(Action))
  add(query_603610, "Version", newJString(Version))
  result = call_603609.call(nil, query_603610, nil, formData_603611, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_603595(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_603596, base: "/",
    url: url_PostDeleteDBSecurityGroup_603597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_603579 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSecurityGroup_603581(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSecurityGroup_603580(path: JsonNode; query: JsonNode;
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
  var valid_603582 = query.getOrDefault("DBSecurityGroupName")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = nil)
  if valid_603582 != nil:
    section.add "DBSecurityGroupName", valid_603582
  var valid_603583 = query.getOrDefault("Action")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603583 != nil:
    section.add "Action", valid_603583
  var valid_603584 = query.getOrDefault("Version")
  valid_603584 = validateParameter(valid_603584, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603584 != nil:
    section.add "Version", valid_603584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603585 = header.getOrDefault("X-Amz-Date")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Date", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Security-Token")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Security-Token", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Content-Sha256", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Algorithm")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Algorithm", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-Signature")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-Signature", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-SignedHeaders", valid_603590
  var valid_603591 = header.getOrDefault("X-Amz-Credential")
  valid_603591 = validateParameter(valid_603591, JString, required = false,
                                 default = nil)
  if valid_603591 != nil:
    section.add "X-Amz-Credential", valid_603591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603592: Call_GetDeleteDBSecurityGroup_603579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_GetDeleteDBSecurityGroup_603579;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603594 = newJObject()
  add(query_603594, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603594, "Action", newJString(Action))
  add(query_603594, "Version", newJString(Version))
  result = call_603593.call(nil, query_603594, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_603579(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_603580, base: "/",
    url: url_GetDeleteDBSecurityGroup_603581, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_603628 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSnapshot_603630(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSnapshot_603629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603631 = query.getOrDefault("Action")
  valid_603631 = validateParameter(valid_603631, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603631 != nil:
    section.add "Action", valid_603631
  var valid_603632 = query.getOrDefault("Version")
  valid_603632 = validateParameter(valid_603632, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603632 != nil:
    section.add "Version", valid_603632
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603633 = header.getOrDefault("X-Amz-Date")
  valid_603633 = validateParameter(valid_603633, JString, required = false,
                                 default = nil)
  if valid_603633 != nil:
    section.add "X-Amz-Date", valid_603633
  var valid_603634 = header.getOrDefault("X-Amz-Security-Token")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Security-Token", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Content-Sha256", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Algorithm")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Algorithm", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Signature")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Signature", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-SignedHeaders", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-Credential")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-Credential", valid_603639
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_603640 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603640 = validateParameter(valid_603640, JString, required = true,
                                 default = nil)
  if valid_603640 != nil:
    section.add "DBSnapshotIdentifier", valid_603640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603641: Call_PostDeleteDBSnapshot_603628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603641.validator(path, query, header, formData, body)
  let scheme = call_603641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603641.url(scheme.get, call_603641.host, call_603641.base,
                         call_603641.route, valid.getOrDefault("path"))
  result = hook(call_603641, url, valid)

proc call*(call_603642: Call_PostDeleteDBSnapshot_603628;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603643 = newJObject()
  var formData_603644 = newJObject()
  add(formData_603644, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603643, "Action", newJString(Action))
  add(query_603643, "Version", newJString(Version))
  result = call_603642.call(nil, query_603643, nil, formData_603644, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_603628(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_603629, base: "/",
    url: url_PostDeleteDBSnapshot_603630, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_603612 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSnapshot_603614(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSnapshot_603613(path: JsonNode; query: JsonNode;
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
  var valid_603615 = query.getOrDefault("Action")
  valid_603615 = validateParameter(valid_603615, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603615 != nil:
    section.add "Action", valid_603615
  var valid_603616 = query.getOrDefault("Version")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603616 != nil:
    section.add "Version", valid_603616
  var valid_603617 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = nil)
  if valid_603617 != nil:
    section.add "DBSnapshotIdentifier", valid_603617
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603618 = header.getOrDefault("X-Amz-Date")
  valid_603618 = validateParameter(valid_603618, JString, required = false,
                                 default = nil)
  if valid_603618 != nil:
    section.add "X-Amz-Date", valid_603618
  var valid_603619 = header.getOrDefault("X-Amz-Security-Token")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Security-Token", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Content-Sha256", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Algorithm")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Algorithm", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Signature")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Signature", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-SignedHeaders", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-Credential")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-Credential", valid_603624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603625: Call_GetDeleteDBSnapshot_603612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603625.validator(path, query, header, formData, body)
  let scheme = call_603625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603625.url(scheme.get, call_603625.host, call_603625.base,
                         call_603625.route, valid.getOrDefault("path"))
  result = hook(call_603625, url, valid)

proc call*(call_603626: Call_GetDeleteDBSnapshot_603612;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603627 = newJObject()
  add(query_603627, "Action", newJString(Action))
  add(query_603627, "Version", newJString(Version))
  add(query_603627, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603626.call(nil, query_603627, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_603612(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_603613, base: "/",
    url: url_GetDeleteDBSnapshot_603614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603661 = ref object of OpenApiRestCall_602417
proc url_PostDeleteDBSubnetGroup_603663(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDBSubnetGroup_603662(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603664 = query.getOrDefault("Action")
  valid_603664 = validateParameter(valid_603664, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603664 != nil:
    section.add "Action", valid_603664
  var valid_603665 = query.getOrDefault("Version")
  valid_603665 = validateParameter(valid_603665, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603665 != nil:
    section.add "Version", valid_603665
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603666 = header.getOrDefault("X-Amz-Date")
  valid_603666 = validateParameter(valid_603666, JString, required = false,
                                 default = nil)
  if valid_603666 != nil:
    section.add "X-Amz-Date", valid_603666
  var valid_603667 = header.getOrDefault("X-Amz-Security-Token")
  valid_603667 = validateParameter(valid_603667, JString, required = false,
                                 default = nil)
  if valid_603667 != nil:
    section.add "X-Amz-Security-Token", valid_603667
  var valid_603668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603668 = validateParameter(valid_603668, JString, required = false,
                                 default = nil)
  if valid_603668 != nil:
    section.add "X-Amz-Content-Sha256", valid_603668
  var valid_603669 = header.getOrDefault("X-Amz-Algorithm")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Algorithm", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Signature")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Signature", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-SignedHeaders", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Credential")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Credential", valid_603672
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603673 = formData.getOrDefault("DBSubnetGroupName")
  valid_603673 = validateParameter(valid_603673, JString, required = true,
                                 default = nil)
  if valid_603673 != nil:
    section.add "DBSubnetGroupName", valid_603673
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603674: Call_PostDeleteDBSubnetGroup_603661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603674.validator(path, query, header, formData, body)
  let scheme = call_603674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603674.url(scheme.get, call_603674.host, call_603674.base,
                         call_603674.route, valid.getOrDefault("path"))
  result = hook(call_603674, url, valid)

proc call*(call_603675: Call_PostDeleteDBSubnetGroup_603661;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603676 = newJObject()
  var formData_603677 = newJObject()
  add(formData_603677, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603676, "Action", newJString(Action))
  add(query_603676, "Version", newJString(Version))
  result = call_603675.call(nil, query_603676, nil, formData_603677, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603661(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603662, base: "/",
    url: url_PostDeleteDBSubnetGroup_603663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603645 = ref object of OpenApiRestCall_602417
proc url_GetDeleteDBSubnetGroup_603647(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDBSubnetGroup_603646(path: JsonNode; query: JsonNode;
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
  var valid_603648 = query.getOrDefault("Action")
  valid_603648 = validateParameter(valid_603648, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603648 != nil:
    section.add "Action", valid_603648
  var valid_603649 = query.getOrDefault("DBSubnetGroupName")
  valid_603649 = validateParameter(valid_603649, JString, required = true,
                                 default = nil)
  if valid_603649 != nil:
    section.add "DBSubnetGroupName", valid_603649
  var valid_603650 = query.getOrDefault("Version")
  valid_603650 = validateParameter(valid_603650, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603650 != nil:
    section.add "Version", valid_603650
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603651 = header.getOrDefault("X-Amz-Date")
  valid_603651 = validateParameter(valid_603651, JString, required = false,
                                 default = nil)
  if valid_603651 != nil:
    section.add "X-Amz-Date", valid_603651
  var valid_603652 = header.getOrDefault("X-Amz-Security-Token")
  valid_603652 = validateParameter(valid_603652, JString, required = false,
                                 default = nil)
  if valid_603652 != nil:
    section.add "X-Amz-Security-Token", valid_603652
  var valid_603653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603653 = validateParameter(valid_603653, JString, required = false,
                                 default = nil)
  if valid_603653 != nil:
    section.add "X-Amz-Content-Sha256", valid_603653
  var valid_603654 = header.getOrDefault("X-Amz-Algorithm")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Algorithm", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Signature")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Signature", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-SignedHeaders", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Credential")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Credential", valid_603657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603658: Call_GetDeleteDBSubnetGroup_603645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603658.validator(path, query, header, formData, body)
  let scheme = call_603658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603658.url(scheme.get, call_603658.host, call_603658.base,
                         call_603658.route, valid.getOrDefault("path"))
  result = hook(call_603658, url, valid)

proc call*(call_603659: Call_GetDeleteDBSubnetGroup_603645;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603660 = newJObject()
  add(query_603660, "Action", newJString(Action))
  add(query_603660, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603660, "Version", newJString(Version))
  result = call_603659.call(nil, query_603660, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603645(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603646, base: "/",
    url: url_GetDeleteDBSubnetGroup_603647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_603694 = ref object of OpenApiRestCall_602417
proc url_PostDeleteEventSubscription_603696(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteEventSubscription_603695(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603697 = query.getOrDefault("Action")
  valid_603697 = validateParameter(valid_603697, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603697 != nil:
    section.add "Action", valid_603697
  var valid_603698 = query.getOrDefault("Version")
  valid_603698 = validateParameter(valid_603698, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603698 != nil:
    section.add "Version", valid_603698
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603699 = header.getOrDefault("X-Amz-Date")
  valid_603699 = validateParameter(valid_603699, JString, required = false,
                                 default = nil)
  if valid_603699 != nil:
    section.add "X-Amz-Date", valid_603699
  var valid_603700 = header.getOrDefault("X-Amz-Security-Token")
  valid_603700 = validateParameter(valid_603700, JString, required = false,
                                 default = nil)
  if valid_603700 != nil:
    section.add "X-Amz-Security-Token", valid_603700
  var valid_603701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603701 = validateParameter(valid_603701, JString, required = false,
                                 default = nil)
  if valid_603701 != nil:
    section.add "X-Amz-Content-Sha256", valid_603701
  var valid_603702 = header.getOrDefault("X-Amz-Algorithm")
  valid_603702 = validateParameter(valid_603702, JString, required = false,
                                 default = nil)
  if valid_603702 != nil:
    section.add "X-Amz-Algorithm", valid_603702
  var valid_603703 = header.getOrDefault("X-Amz-Signature")
  valid_603703 = validateParameter(valid_603703, JString, required = false,
                                 default = nil)
  if valid_603703 != nil:
    section.add "X-Amz-Signature", valid_603703
  var valid_603704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-SignedHeaders", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Credential")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Credential", valid_603705
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603706 = formData.getOrDefault("SubscriptionName")
  valid_603706 = validateParameter(valid_603706, JString, required = true,
                                 default = nil)
  if valid_603706 != nil:
    section.add "SubscriptionName", valid_603706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603707: Call_PostDeleteEventSubscription_603694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603707.validator(path, query, header, formData, body)
  let scheme = call_603707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603707.url(scheme.get, call_603707.host, call_603707.base,
                         call_603707.route, valid.getOrDefault("path"))
  result = hook(call_603707, url, valid)

proc call*(call_603708: Call_PostDeleteEventSubscription_603694;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603709 = newJObject()
  var formData_603710 = newJObject()
  add(formData_603710, "SubscriptionName", newJString(SubscriptionName))
  add(query_603709, "Action", newJString(Action))
  add(query_603709, "Version", newJString(Version))
  result = call_603708.call(nil, query_603709, nil, formData_603710, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_603694(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_603695, base: "/",
    url: url_PostDeleteEventSubscription_603696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_603678 = ref object of OpenApiRestCall_602417
proc url_GetDeleteEventSubscription_603680(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteEventSubscription_603679(path: JsonNode; query: JsonNode;
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
  var valid_603681 = query.getOrDefault("Action")
  valid_603681 = validateParameter(valid_603681, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603681 != nil:
    section.add "Action", valid_603681
  var valid_603682 = query.getOrDefault("SubscriptionName")
  valid_603682 = validateParameter(valid_603682, JString, required = true,
                                 default = nil)
  if valid_603682 != nil:
    section.add "SubscriptionName", valid_603682
  var valid_603683 = query.getOrDefault("Version")
  valid_603683 = validateParameter(valid_603683, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603683 != nil:
    section.add "Version", valid_603683
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603684 = header.getOrDefault("X-Amz-Date")
  valid_603684 = validateParameter(valid_603684, JString, required = false,
                                 default = nil)
  if valid_603684 != nil:
    section.add "X-Amz-Date", valid_603684
  var valid_603685 = header.getOrDefault("X-Amz-Security-Token")
  valid_603685 = validateParameter(valid_603685, JString, required = false,
                                 default = nil)
  if valid_603685 != nil:
    section.add "X-Amz-Security-Token", valid_603685
  var valid_603686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603686 = validateParameter(valid_603686, JString, required = false,
                                 default = nil)
  if valid_603686 != nil:
    section.add "X-Amz-Content-Sha256", valid_603686
  var valid_603687 = header.getOrDefault("X-Amz-Algorithm")
  valid_603687 = validateParameter(valid_603687, JString, required = false,
                                 default = nil)
  if valid_603687 != nil:
    section.add "X-Amz-Algorithm", valid_603687
  var valid_603688 = header.getOrDefault("X-Amz-Signature")
  valid_603688 = validateParameter(valid_603688, JString, required = false,
                                 default = nil)
  if valid_603688 != nil:
    section.add "X-Amz-Signature", valid_603688
  var valid_603689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-SignedHeaders", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Credential")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Credential", valid_603690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603691: Call_GetDeleteEventSubscription_603678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603691.validator(path, query, header, formData, body)
  let scheme = call_603691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603691.url(scheme.get, call_603691.host, call_603691.base,
                         call_603691.route, valid.getOrDefault("path"))
  result = hook(call_603691, url, valid)

proc call*(call_603692: Call_GetDeleteEventSubscription_603678;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603693 = newJObject()
  add(query_603693, "Action", newJString(Action))
  add(query_603693, "SubscriptionName", newJString(SubscriptionName))
  add(query_603693, "Version", newJString(Version))
  result = call_603692.call(nil, query_603693, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_603678(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_603679, base: "/",
    url: url_GetDeleteEventSubscription_603680,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_603727 = ref object of OpenApiRestCall_602417
proc url_PostDeleteOptionGroup_603729(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteOptionGroup_603728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603730 = query.getOrDefault("Action")
  valid_603730 = validateParameter(valid_603730, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603730 != nil:
    section.add "Action", valid_603730
  var valid_603731 = query.getOrDefault("Version")
  valid_603731 = validateParameter(valid_603731, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603731 != nil:
    section.add "Version", valid_603731
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603732 = header.getOrDefault("X-Amz-Date")
  valid_603732 = validateParameter(valid_603732, JString, required = false,
                                 default = nil)
  if valid_603732 != nil:
    section.add "X-Amz-Date", valid_603732
  var valid_603733 = header.getOrDefault("X-Amz-Security-Token")
  valid_603733 = validateParameter(valid_603733, JString, required = false,
                                 default = nil)
  if valid_603733 != nil:
    section.add "X-Amz-Security-Token", valid_603733
  var valid_603734 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603734 = validateParameter(valid_603734, JString, required = false,
                                 default = nil)
  if valid_603734 != nil:
    section.add "X-Amz-Content-Sha256", valid_603734
  var valid_603735 = header.getOrDefault("X-Amz-Algorithm")
  valid_603735 = validateParameter(valid_603735, JString, required = false,
                                 default = nil)
  if valid_603735 != nil:
    section.add "X-Amz-Algorithm", valid_603735
  var valid_603736 = header.getOrDefault("X-Amz-Signature")
  valid_603736 = validateParameter(valid_603736, JString, required = false,
                                 default = nil)
  if valid_603736 != nil:
    section.add "X-Amz-Signature", valid_603736
  var valid_603737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603737 = validateParameter(valid_603737, JString, required = false,
                                 default = nil)
  if valid_603737 != nil:
    section.add "X-Amz-SignedHeaders", valid_603737
  var valid_603738 = header.getOrDefault("X-Amz-Credential")
  valid_603738 = validateParameter(valid_603738, JString, required = false,
                                 default = nil)
  if valid_603738 != nil:
    section.add "X-Amz-Credential", valid_603738
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603739 = formData.getOrDefault("OptionGroupName")
  valid_603739 = validateParameter(valid_603739, JString, required = true,
                                 default = nil)
  if valid_603739 != nil:
    section.add "OptionGroupName", valid_603739
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603740: Call_PostDeleteOptionGroup_603727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603740.validator(path, query, header, formData, body)
  let scheme = call_603740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603740.url(scheme.get, call_603740.host, call_603740.base,
                         call_603740.route, valid.getOrDefault("path"))
  result = hook(call_603740, url, valid)

proc call*(call_603741: Call_PostDeleteOptionGroup_603727; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603742 = newJObject()
  var formData_603743 = newJObject()
  add(formData_603743, "OptionGroupName", newJString(OptionGroupName))
  add(query_603742, "Action", newJString(Action))
  add(query_603742, "Version", newJString(Version))
  result = call_603741.call(nil, query_603742, nil, formData_603743, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_603727(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_603728, base: "/",
    url: url_PostDeleteOptionGroup_603729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_603711 = ref object of OpenApiRestCall_602417
proc url_GetDeleteOptionGroup_603713(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteOptionGroup_603712(path: JsonNode; query: JsonNode;
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
  var valid_603714 = query.getOrDefault("OptionGroupName")
  valid_603714 = validateParameter(valid_603714, JString, required = true,
                                 default = nil)
  if valid_603714 != nil:
    section.add "OptionGroupName", valid_603714
  var valid_603715 = query.getOrDefault("Action")
  valid_603715 = validateParameter(valid_603715, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603715 != nil:
    section.add "Action", valid_603715
  var valid_603716 = query.getOrDefault("Version")
  valid_603716 = validateParameter(valid_603716, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603716 != nil:
    section.add "Version", valid_603716
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603717 = header.getOrDefault("X-Amz-Date")
  valid_603717 = validateParameter(valid_603717, JString, required = false,
                                 default = nil)
  if valid_603717 != nil:
    section.add "X-Amz-Date", valid_603717
  var valid_603718 = header.getOrDefault("X-Amz-Security-Token")
  valid_603718 = validateParameter(valid_603718, JString, required = false,
                                 default = nil)
  if valid_603718 != nil:
    section.add "X-Amz-Security-Token", valid_603718
  var valid_603719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603719 = validateParameter(valid_603719, JString, required = false,
                                 default = nil)
  if valid_603719 != nil:
    section.add "X-Amz-Content-Sha256", valid_603719
  var valid_603720 = header.getOrDefault("X-Amz-Algorithm")
  valid_603720 = validateParameter(valid_603720, JString, required = false,
                                 default = nil)
  if valid_603720 != nil:
    section.add "X-Amz-Algorithm", valid_603720
  var valid_603721 = header.getOrDefault("X-Amz-Signature")
  valid_603721 = validateParameter(valid_603721, JString, required = false,
                                 default = nil)
  if valid_603721 != nil:
    section.add "X-Amz-Signature", valid_603721
  var valid_603722 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603722 = validateParameter(valid_603722, JString, required = false,
                                 default = nil)
  if valid_603722 != nil:
    section.add "X-Amz-SignedHeaders", valid_603722
  var valid_603723 = header.getOrDefault("X-Amz-Credential")
  valid_603723 = validateParameter(valid_603723, JString, required = false,
                                 default = nil)
  if valid_603723 != nil:
    section.add "X-Amz-Credential", valid_603723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603724: Call_GetDeleteOptionGroup_603711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603724.validator(path, query, header, formData, body)
  let scheme = call_603724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603724.url(scheme.get, call_603724.host, call_603724.base,
                         call_603724.route, valid.getOrDefault("path"))
  result = hook(call_603724, url, valid)

proc call*(call_603725: Call_GetDeleteOptionGroup_603711; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-02-12"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603726 = newJObject()
  add(query_603726, "OptionGroupName", newJString(OptionGroupName))
  add(query_603726, "Action", newJString(Action))
  add(query_603726, "Version", newJString(Version))
  result = call_603725.call(nil, query_603726, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_603711(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_603712, base: "/",
    url: url_GetDeleteOptionGroup_603713, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603766 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBEngineVersions_603768(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBEngineVersions_603767(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603769 = query.getOrDefault("Action")
  valid_603769 = validateParameter(valid_603769, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603769 != nil:
    section.add "Action", valid_603769
  var valid_603770 = query.getOrDefault("Version")
  valid_603770 = validateParameter(valid_603770, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603770 != nil:
    section.add "Version", valid_603770
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603771 = header.getOrDefault("X-Amz-Date")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Date", valid_603771
  var valid_603772 = header.getOrDefault("X-Amz-Security-Token")
  valid_603772 = validateParameter(valid_603772, JString, required = false,
                                 default = nil)
  if valid_603772 != nil:
    section.add "X-Amz-Security-Token", valid_603772
  var valid_603773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603773 = validateParameter(valid_603773, JString, required = false,
                                 default = nil)
  if valid_603773 != nil:
    section.add "X-Amz-Content-Sha256", valid_603773
  var valid_603774 = header.getOrDefault("X-Amz-Algorithm")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Algorithm", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Signature")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Signature", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-SignedHeaders", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Credential")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Credential", valid_603777
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
  var valid_603778 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603778 = validateParameter(valid_603778, JBool, required = false, default = nil)
  if valid_603778 != nil:
    section.add "ListSupportedCharacterSets", valid_603778
  var valid_603779 = formData.getOrDefault("Engine")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "Engine", valid_603779
  var valid_603780 = formData.getOrDefault("Marker")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "Marker", valid_603780
  var valid_603781 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603781 = validateParameter(valid_603781, JString, required = false,
                                 default = nil)
  if valid_603781 != nil:
    section.add "DBParameterGroupFamily", valid_603781
  var valid_603782 = formData.getOrDefault("MaxRecords")
  valid_603782 = validateParameter(valid_603782, JInt, required = false, default = nil)
  if valid_603782 != nil:
    section.add "MaxRecords", valid_603782
  var valid_603783 = formData.getOrDefault("EngineVersion")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "EngineVersion", valid_603783
  var valid_603784 = formData.getOrDefault("DefaultOnly")
  valid_603784 = validateParameter(valid_603784, JBool, required = false, default = nil)
  if valid_603784 != nil:
    section.add "DefaultOnly", valid_603784
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603785: Call_PostDescribeDBEngineVersions_603766; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603785.validator(path, query, header, formData, body)
  let scheme = call_603785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603785.url(scheme.get, call_603785.host, call_603785.base,
                         call_603785.route, valid.getOrDefault("path"))
  result = hook(call_603785, url, valid)

proc call*(call_603786: Call_PostDescribeDBEngineVersions_603766;
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
  var query_603787 = newJObject()
  var formData_603788 = newJObject()
  add(formData_603788, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603788, "Engine", newJString(Engine))
  add(formData_603788, "Marker", newJString(Marker))
  add(query_603787, "Action", newJString(Action))
  add(formData_603788, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_603788, "MaxRecords", newJInt(MaxRecords))
  add(formData_603788, "EngineVersion", newJString(EngineVersion))
  add(query_603787, "Version", newJString(Version))
  add(formData_603788, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603786.call(nil, query_603787, nil, formData_603788, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603766(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603767, base: "/",
    url: url_PostDescribeDBEngineVersions_603768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603744 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBEngineVersions_603746(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBEngineVersions_603745(path: JsonNode; query: JsonNode;
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
  var valid_603747 = query.getOrDefault("Engine")
  valid_603747 = validateParameter(valid_603747, JString, required = false,
                                 default = nil)
  if valid_603747 != nil:
    section.add "Engine", valid_603747
  var valid_603748 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603748 = validateParameter(valid_603748, JBool, required = false, default = nil)
  if valid_603748 != nil:
    section.add "ListSupportedCharacterSets", valid_603748
  var valid_603749 = query.getOrDefault("MaxRecords")
  valid_603749 = validateParameter(valid_603749, JInt, required = false, default = nil)
  if valid_603749 != nil:
    section.add "MaxRecords", valid_603749
  var valid_603750 = query.getOrDefault("DBParameterGroupFamily")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "DBParameterGroupFamily", valid_603750
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603751 = query.getOrDefault("Action")
  valid_603751 = validateParameter(valid_603751, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603751 != nil:
    section.add "Action", valid_603751
  var valid_603752 = query.getOrDefault("Marker")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "Marker", valid_603752
  var valid_603753 = query.getOrDefault("EngineVersion")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "EngineVersion", valid_603753
  var valid_603754 = query.getOrDefault("DefaultOnly")
  valid_603754 = validateParameter(valid_603754, JBool, required = false, default = nil)
  if valid_603754 != nil:
    section.add "DefaultOnly", valid_603754
  var valid_603755 = query.getOrDefault("Version")
  valid_603755 = validateParameter(valid_603755, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603755 != nil:
    section.add "Version", valid_603755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603756 = header.getOrDefault("X-Amz-Date")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Date", valid_603756
  var valid_603757 = header.getOrDefault("X-Amz-Security-Token")
  valid_603757 = validateParameter(valid_603757, JString, required = false,
                                 default = nil)
  if valid_603757 != nil:
    section.add "X-Amz-Security-Token", valid_603757
  var valid_603758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603758 = validateParameter(valid_603758, JString, required = false,
                                 default = nil)
  if valid_603758 != nil:
    section.add "X-Amz-Content-Sha256", valid_603758
  var valid_603759 = header.getOrDefault("X-Amz-Algorithm")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Algorithm", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Signature")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Signature", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-SignedHeaders", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Credential")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Credential", valid_603762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603763: Call_GetDescribeDBEngineVersions_603744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603763.validator(path, query, header, formData, body)
  let scheme = call_603763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603763.url(scheme.get, call_603763.host, call_603763.base,
                         call_603763.route, valid.getOrDefault("path"))
  result = hook(call_603763, url, valid)

proc call*(call_603764: Call_GetDescribeDBEngineVersions_603744;
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
  var query_603765 = newJObject()
  add(query_603765, "Engine", newJString(Engine))
  add(query_603765, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603765, "MaxRecords", newJInt(MaxRecords))
  add(query_603765, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_603765, "Action", newJString(Action))
  add(query_603765, "Marker", newJString(Marker))
  add(query_603765, "EngineVersion", newJString(EngineVersion))
  add(query_603765, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603765, "Version", newJString(Version))
  result = call_603764.call(nil, query_603765, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603744(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603745, base: "/",
    url: url_GetDescribeDBEngineVersions_603746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603807 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBInstances_603809(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBInstances_603808(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603810 = query.getOrDefault("Action")
  valid_603810 = validateParameter(valid_603810, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603810 != nil:
    section.add "Action", valid_603810
  var valid_603811 = query.getOrDefault("Version")
  valid_603811 = validateParameter(valid_603811, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603811 != nil:
    section.add "Version", valid_603811
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603812 = header.getOrDefault("X-Amz-Date")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "X-Amz-Date", valid_603812
  var valid_603813 = header.getOrDefault("X-Amz-Security-Token")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "X-Amz-Security-Token", valid_603813
  var valid_603814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "X-Amz-Content-Sha256", valid_603814
  var valid_603815 = header.getOrDefault("X-Amz-Algorithm")
  valid_603815 = validateParameter(valid_603815, JString, required = false,
                                 default = nil)
  if valid_603815 != nil:
    section.add "X-Amz-Algorithm", valid_603815
  var valid_603816 = header.getOrDefault("X-Amz-Signature")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "X-Amz-Signature", valid_603816
  var valid_603817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603817 = validateParameter(valid_603817, JString, required = false,
                                 default = nil)
  if valid_603817 != nil:
    section.add "X-Amz-SignedHeaders", valid_603817
  var valid_603818 = header.getOrDefault("X-Amz-Credential")
  valid_603818 = validateParameter(valid_603818, JString, required = false,
                                 default = nil)
  if valid_603818 != nil:
    section.add "X-Amz-Credential", valid_603818
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603819 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603819 = validateParameter(valid_603819, JString, required = false,
                                 default = nil)
  if valid_603819 != nil:
    section.add "DBInstanceIdentifier", valid_603819
  var valid_603820 = formData.getOrDefault("Marker")
  valid_603820 = validateParameter(valid_603820, JString, required = false,
                                 default = nil)
  if valid_603820 != nil:
    section.add "Marker", valid_603820
  var valid_603821 = formData.getOrDefault("MaxRecords")
  valid_603821 = validateParameter(valid_603821, JInt, required = false, default = nil)
  if valid_603821 != nil:
    section.add "MaxRecords", valid_603821
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603822: Call_PostDescribeDBInstances_603807; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603822.validator(path, query, header, formData, body)
  let scheme = call_603822.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603822.url(scheme.get, call_603822.host, call_603822.base,
                         call_603822.route, valid.getOrDefault("path"))
  result = hook(call_603822, url, valid)

proc call*(call_603823: Call_PostDescribeDBInstances_603807;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_603824 = newJObject()
  var formData_603825 = newJObject()
  add(formData_603825, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603825, "Marker", newJString(Marker))
  add(query_603824, "Action", newJString(Action))
  add(formData_603825, "MaxRecords", newJInt(MaxRecords))
  add(query_603824, "Version", newJString(Version))
  result = call_603823.call(nil, query_603824, nil, formData_603825, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603807(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603808, base: "/",
    url: url_PostDescribeDBInstances_603809, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603789 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBInstances_603791(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBInstances_603790(path: JsonNode; query: JsonNode;
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
  var valid_603792 = query.getOrDefault("MaxRecords")
  valid_603792 = validateParameter(valid_603792, JInt, required = false, default = nil)
  if valid_603792 != nil:
    section.add "MaxRecords", valid_603792
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603793 = query.getOrDefault("Action")
  valid_603793 = validateParameter(valid_603793, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603793 != nil:
    section.add "Action", valid_603793
  var valid_603794 = query.getOrDefault("Marker")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "Marker", valid_603794
  var valid_603795 = query.getOrDefault("Version")
  valid_603795 = validateParameter(valid_603795, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603795 != nil:
    section.add "Version", valid_603795
  var valid_603796 = query.getOrDefault("DBInstanceIdentifier")
  valid_603796 = validateParameter(valid_603796, JString, required = false,
                                 default = nil)
  if valid_603796 != nil:
    section.add "DBInstanceIdentifier", valid_603796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603797 = header.getOrDefault("X-Amz-Date")
  valid_603797 = validateParameter(valid_603797, JString, required = false,
                                 default = nil)
  if valid_603797 != nil:
    section.add "X-Amz-Date", valid_603797
  var valid_603798 = header.getOrDefault("X-Amz-Security-Token")
  valid_603798 = validateParameter(valid_603798, JString, required = false,
                                 default = nil)
  if valid_603798 != nil:
    section.add "X-Amz-Security-Token", valid_603798
  var valid_603799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603799 = validateParameter(valid_603799, JString, required = false,
                                 default = nil)
  if valid_603799 != nil:
    section.add "X-Amz-Content-Sha256", valid_603799
  var valid_603800 = header.getOrDefault("X-Amz-Algorithm")
  valid_603800 = validateParameter(valid_603800, JString, required = false,
                                 default = nil)
  if valid_603800 != nil:
    section.add "X-Amz-Algorithm", valid_603800
  var valid_603801 = header.getOrDefault("X-Amz-Signature")
  valid_603801 = validateParameter(valid_603801, JString, required = false,
                                 default = nil)
  if valid_603801 != nil:
    section.add "X-Amz-Signature", valid_603801
  var valid_603802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603802 = validateParameter(valid_603802, JString, required = false,
                                 default = nil)
  if valid_603802 != nil:
    section.add "X-Amz-SignedHeaders", valid_603802
  var valid_603803 = header.getOrDefault("X-Amz-Credential")
  valid_603803 = validateParameter(valid_603803, JString, required = false,
                                 default = nil)
  if valid_603803 != nil:
    section.add "X-Amz-Credential", valid_603803
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603804: Call_GetDescribeDBInstances_603789; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603804.validator(path, query, header, formData, body)
  let scheme = call_603804.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603804.url(scheme.get, call_603804.host, call_603804.base,
                         call_603804.route, valid.getOrDefault("path"))
  result = hook(call_603804, url, valid)

proc call*(call_603805: Call_GetDescribeDBInstances_603789; MaxRecords: int = 0;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-02-12"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_603806 = newJObject()
  add(query_603806, "MaxRecords", newJInt(MaxRecords))
  add(query_603806, "Action", newJString(Action))
  add(query_603806, "Marker", newJString(Marker))
  add(query_603806, "Version", newJString(Version))
  add(query_603806, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603805.call(nil, query_603806, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603789(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603790, base: "/",
    url: url_GetDescribeDBInstances_603791, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_603847 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBLogFiles_603849(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBLogFiles_603848(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603850 = query.getOrDefault("Action")
  valid_603850 = validateParameter(valid_603850, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603850 != nil:
    section.add "Action", valid_603850
  var valid_603851 = query.getOrDefault("Version")
  valid_603851 = validateParameter(valid_603851, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603851 != nil:
    section.add "Version", valid_603851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603852 = header.getOrDefault("X-Amz-Date")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "X-Amz-Date", valid_603852
  var valid_603853 = header.getOrDefault("X-Amz-Security-Token")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "X-Amz-Security-Token", valid_603853
  var valid_603854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603854 = validateParameter(valid_603854, JString, required = false,
                                 default = nil)
  if valid_603854 != nil:
    section.add "X-Amz-Content-Sha256", valid_603854
  var valid_603855 = header.getOrDefault("X-Amz-Algorithm")
  valid_603855 = validateParameter(valid_603855, JString, required = false,
                                 default = nil)
  if valid_603855 != nil:
    section.add "X-Amz-Algorithm", valid_603855
  var valid_603856 = header.getOrDefault("X-Amz-Signature")
  valid_603856 = validateParameter(valid_603856, JString, required = false,
                                 default = nil)
  if valid_603856 != nil:
    section.add "X-Amz-Signature", valid_603856
  var valid_603857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603857 = validateParameter(valid_603857, JString, required = false,
                                 default = nil)
  if valid_603857 != nil:
    section.add "X-Amz-SignedHeaders", valid_603857
  var valid_603858 = header.getOrDefault("X-Amz-Credential")
  valid_603858 = validateParameter(valid_603858, JString, required = false,
                                 default = nil)
  if valid_603858 != nil:
    section.add "X-Amz-Credential", valid_603858
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_603859 = formData.getOrDefault("FilenameContains")
  valid_603859 = validateParameter(valid_603859, JString, required = false,
                                 default = nil)
  if valid_603859 != nil:
    section.add "FilenameContains", valid_603859
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603860 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603860 = validateParameter(valid_603860, JString, required = true,
                                 default = nil)
  if valid_603860 != nil:
    section.add "DBInstanceIdentifier", valid_603860
  var valid_603861 = formData.getOrDefault("FileSize")
  valid_603861 = validateParameter(valid_603861, JInt, required = false, default = nil)
  if valid_603861 != nil:
    section.add "FileSize", valid_603861
  var valid_603862 = formData.getOrDefault("Marker")
  valid_603862 = validateParameter(valid_603862, JString, required = false,
                                 default = nil)
  if valid_603862 != nil:
    section.add "Marker", valid_603862
  var valid_603863 = formData.getOrDefault("MaxRecords")
  valid_603863 = validateParameter(valid_603863, JInt, required = false, default = nil)
  if valid_603863 != nil:
    section.add "MaxRecords", valid_603863
  var valid_603864 = formData.getOrDefault("FileLastWritten")
  valid_603864 = validateParameter(valid_603864, JInt, required = false, default = nil)
  if valid_603864 != nil:
    section.add "FileLastWritten", valid_603864
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603865: Call_PostDescribeDBLogFiles_603847; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603865.validator(path, query, header, formData, body)
  let scheme = call_603865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603865.url(scheme.get, call_603865.host, call_603865.base,
                         call_603865.route, valid.getOrDefault("path"))
  result = hook(call_603865, url, valid)

proc call*(call_603866: Call_PostDescribeDBLogFiles_603847;
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
  var query_603867 = newJObject()
  var formData_603868 = newJObject()
  add(formData_603868, "FilenameContains", newJString(FilenameContains))
  add(formData_603868, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603868, "FileSize", newJInt(FileSize))
  add(formData_603868, "Marker", newJString(Marker))
  add(query_603867, "Action", newJString(Action))
  add(formData_603868, "MaxRecords", newJInt(MaxRecords))
  add(formData_603868, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603867, "Version", newJString(Version))
  result = call_603866.call(nil, query_603867, nil, formData_603868, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_603847(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_603848, base: "/",
    url: url_PostDescribeDBLogFiles_603849, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_603826 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBLogFiles_603828(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBLogFiles_603827(path: JsonNode; query: JsonNode;
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
  var valid_603829 = query.getOrDefault("FileLastWritten")
  valid_603829 = validateParameter(valid_603829, JInt, required = false, default = nil)
  if valid_603829 != nil:
    section.add "FileLastWritten", valid_603829
  var valid_603830 = query.getOrDefault("MaxRecords")
  valid_603830 = validateParameter(valid_603830, JInt, required = false, default = nil)
  if valid_603830 != nil:
    section.add "MaxRecords", valid_603830
  var valid_603831 = query.getOrDefault("FilenameContains")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "FilenameContains", valid_603831
  var valid_603832 = query.getOrDefault("FileSize")
  valid_603832 = validateParameter(valid_603832, JInt, required = false, default = nil)
  if valid_603832 != nil:
    section.add "FileSize", valid_603832
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603833 = query.getOrDefault("Action")
  valid_603833 = validateParameter(valid_603833, JString, required = true,
                                 default = newJString("DescribeDBLogFiles"))
  if valid_603833 != nil:
    section.add "Action", valid_603833
  var valid_603834 = query.getOrDefault("Marker")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "Marker", valid_603834
  var valid_603835 = query.getOrDefault("Version")
  valid_603835 = validateParameter(valid_603835, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603835 != nil:
    section.add "Version", valid_603835
  var valid_603836 = query.getOrDefault("DBInstanceIdentifier")
  valid_603836 = validateParameter(valid_603836, JString, required = true,
                                 default = nil)
  if valid_603836 != nil:
    section.add "DBInstanceIdentifier", valid_603836
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603837 = header.getOrDefault("X-Amz-Date")
  valid_603837 = validateParameter(valid_603837, JString, required = false,
                                 default = nil)
  if valid_603837 != nil:
    section.add "X-Amz-Date", valid_603837
  var valid_603838 = header.getOrDefault("X-Amz-Security-Token")
  valid_603838 = validateParameter(valid_603838, JString, required = false,
                                 default = nil)
  if valid_603838 != nil:
    section.add "X-Amz-Security-Token", valid_603838
  var valid_603839 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603839 = validateParameter(valid_603839, JString, required = false,
                                 default = nil)
  if valid_603839 != nil:
    section.add "X-Amz-Content-Sha256", valid_603839
  var valid_603840 = header.getOrDefault("X-Amz-Algorithm")
  valid_603840 = validateParameter(valid_603840, JString, required = false,
                                 default = nil)
  if valid_603840 != nil:
    section.add "X-Amz-Algorithm", valid_603840
  var valid_603841 = header.getOrDefault("X-Amz-Signature")
  valid_603841 = validateParameter(valid_603841, JString, required = false,
                                 default = nil)
  if valid_603841 != nil:
    section.add "X-Amz-Signature", valid_603841
  var valid_603842 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603842 = validateParameter(valid_603842, JString, required = false,
                                 default = nil)
  if valid_603842 != nil:
    section.add "X-Amz-SignedHeaders", valid_603842
  var valid_603843 = header.getOrDefault("X-Amz-Credential")
  valid_603843 = validateParameter(valid_603843, JString, required = false,
                                 default = nil)
  if valid_603843 != nil:
    section.add "X-Amz-Credential", valid_603843
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603844: Call_GetDescribeDBLogFiles_603826; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603844.validator(path, query, header, formData, body)
  let scheme = call_603844.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603844.url(scheme.get, call_603844.host, call_603844.base,
                         call_603844.route, valid.getOrDefault("path"))
  result = hook(call_603844, url, valid)

proc call*(call_603845: Call_GetDescribeDBLogFiles_603826;
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
  var query_603846 = newJObject()
  add(query_603846, "FileLastWritten", newJInt(FileLastWritten))
  add(query_603846, "MaxRecords", newJInt(MaxRecords))
  add(query_603846, "FilenameContains", newJString(FilenameContains))
  add(query_603846, "FileSize", newJInt(FileSize))
  add(query_603846, "Action", newJString(Action))
  add(query_603846, "Marker", newJString(Marker))
  add(query_603846, "Version", newJString(Version))
  add(query_603846, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603845.call(nil, query_603846, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_603826(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_603827, base: "/",
    url: url_GetDescribeDBLogFiles_603828, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_603887 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBParameterGroups_603889(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameterGroups_603888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603890 = query.getOrDefault("Action")
  valid_603890 = validateParameter(valid_603890, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603890 != nil:
    section.add "Action", valid_603890
  var valid_603891 = query.getOrDefault("Version")
  valid_603891 = validateParameter(valid_603891, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603891 != nil:
    section.add "Version", valid_603891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603892 = header.getOrDefault("X-Amz-Date")
  valid_603892 = validateParameter(valid_603892, JString, required = false,
                                 default = nil)
  if valid_603892 != nil:
    section.add "X-Amz-Date", valid_603892
  var valid_603893 = header.getOrDefault("X-Amz-Security-Token")
  valid_603893 = validateParameter(valid_603893, JString, required = false,
                                 default = nil)
  if valid_603893 != nil:
    section.add "X-Amz-Security-Token", valid_603893
  var valid_603894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603894 = validateParameter(valid_603894, JString, required = false,
                                 default = nil)
  if valid_603894 != nil:
    section.add "X-Amz-Content-Sha256", valid_603894
  var valid_603895 = header.getOrDefault("X-Amz-Algorithm")
  valid_603895 = validateParameter(valid_603895, JString, required = false,
                                 default = nil)
  if valid_603895 != nil:
    section.add "X-Amz-Algorithm", valid_603895
  var valid_603896 = header.getOrDefault("X-Amz-Signature")
  valid_603896 = validateParameter(valid_603896, JString, required = false,
                                 default = nil)
  if valid_603896 != nil:
    section.add "X-Amz-Signature", valid_603896
  var valid_603897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603897 = validateParameter(valid_603897, JString, required = false,
                                 default = nil)
  if valid_603897 != nil:
    section.add "X-Amz-SignedHeaders", valid_603897
  var valid_603898 = header.getOrDefault("X-Amz-Credential")
  valid_603898 = validateParameter(valid_603898, JString, required = false,
                                 default = nil)
  if valid_603898 != nil:
    section.add "X-Amz-Credential", valid_603898
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603899 = formData.getOrDefault("DBParameterGroupName")
  valid_603899 = validateParameter(valid_603899, JString, required = false,
                                 default = nil)
  if valid_603899 != nil:
    section.add "DBParameterGroupName", valid_603899
  var valid_603900 = formData.getOrDefault("Marker")
  valid_603900 = validateParameter(valid_603900, JString, required = false,
                                 default = nil)
  if valid_603900 != nil:
    section.add "Marker", valid_603900
  var valid_603901 = formData.getOrDefault("MaxRecords")
  valid_603901 = validateParameter(valid_603901, JInt, required = false, default = nil)
  if valid_603901 != nil:
    section.add "MaxRecords", valid_603901
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603902: Call_PostDescribeDBParameterGroups_603887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603902.validator(path, query, header, formData, body)
  let scheme = call_603902.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603902.url(scheme.get, call_603902.host, call_603902.base,
                         call_603902.route, valid.getOrDefault("path"))
  result = hook(call_603902, url, valid)

proc call*(call_603903: Call_PostDescribeDBParameterGroups_603887;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_603904 = newJObject()
  var formData_603905 = newJObject()
  add(formData_603905, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603905, "Marker", newJString(Marker))
  add(query_603904, "Action", newJString(Action))
  add(formData_603905, "MaxRecords", newJInt(MaxRecords))
  add(query_603904, "Version", newJString(Version))
  result = call_603903.call(nil, query_603904, nil, formData_603905, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_603887(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_603888, base: "/",
    url: url_PostDescribeDBParameterGroups_603889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_603869 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBParameterGroups_603871(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameterGroups_603870(path: JsonNode; query: JsonNode;
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
  var valid_603872 = query.getOrDefault("MaxRecords")
  valid_603872 = validateParameter(valid_603872, JInt, required = false, default = nil)
  if valid_603872 != nil:
    section.add "MaxRecords", valid_603872
  var valid_603873 = query.getOrDefault("DBParameterGroupName")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "DBParameterGroupName", valid_603873
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603874 = query.getOrDefault("Action")
  valid_603874 = validateParameter(valid_603874, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603874 != nil:
    section.add "Action", valid_603874
  var valid_603875 = query.getOrDefault("Marker")
  valid_603875 = validateParameter(valid_603875, JString, required = false,
                                 default = nil)
  if valid_603875 != nil:
    section.add "Marker", valid_603875
  var valid_603876 = query.getOrDefault("Version")
  valid_603876 = validateParameter(valid_603876, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603884: Call_GetDescribeDBParameterGroups_603869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603884.validator(path, query, header, formData, body)
  let scheme = call_603884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603884.url(scheme.get, call_603884.host, call_603884.base,
                         call_603884.route, valid.getOrDefault("path"))
  result = hook(call_603884, url, valid)

proc call*(call_603885: Call_GetDescribeDBParameterGroups_603869;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_603886 = newJObject()
  add(query_603886, "MaxRecords", newJInt(MaxRecords))
  add(query_603886, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603886, "Action", newJString(Action))
  add(query_603886, "Marker", newJString(Marker))
  add(query_603886, "Version", newJString(Version))
  result = call_603885.call(nil, query_603886, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_603869(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_603870, base: "/",
    url: url_GetDescribeDBParameterGroups_603871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_603925 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBParameters_603927(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBParameters_603926(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603928 = query.getOrDefault("Action")
  valid_603928 = validateParameter(valid_603928, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603928 != nil:
    section.add "Action", valid_603928
  var valid_603929 = query.getOrDefault("Version")
  valid_603929 = validateParameter(valid_603929, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603929 != nil:
    section.add "Version", valid_603929
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603930 = header.getOrDefault("X-Amz-Date")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "X-Amz-Date", valid_603930
  var valid_603931 = header.getOrDefault("X-Amz-Security-Token")
  valid_603931 = validateParameter(valid_603931, JString, required = false,
                                 default = nil)
  if valid_603931 != nil:
    section.add "X-Amz-Security-Token", valid_603931
  var valid_603932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603932 = validateParameter(valid_603932, JString, required = false,
                                 default = nil)
  if valid_603932 != nil:
    section.add "X-Amz-Content-Sha256", valid_603932
  var valid_603933 = header.getOrDefault("X-Amz-Algorithm")
  valid_603933 = validateParameter(valid_603933, JString, required = false,
                                 default = nil)
  if valid_603933 != nil:
    section.add "X-Amz-Algorithm", valid_603933
  var valid_603934 = header.getOrDefault("X-Amz-Signature")
  valid_603934 = validateParameter(valid_603934, JString, required = false,
                                 default = nil)
  if valid_603934 != nil:
    section.add "X-Amz-Signature", valid_603934
  var valid_603935 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603935 = validateParameter(valid_603935, JString, required = false,
                                 default = nil)
  if valid_603935 != nil:
    section.add "X-Amz-SignedHeaders", valid_603935
  var valid_603936 = header.getOrDefault("X-Amz-Credential")
  valid_603936 = validateParameter(valid_603936, JString, required = false,
                                 default = nil)
  if valid_603936 != nil:
    section.add "X-Amz-Credential", valid_603936
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603937 = formData.getOrDefault("DBParameterGroupName")
  valid_603937 = validateParameter(valid_603937, JString, required = true,
                                 default = nil)
  if valid_603937 != nil:
    section.add "DBParameterGroupName", valid_603937
  var valid_603938 = formData.getOrDefault("Marker")
  valid_603938 = validateParameter(valid_603938, JString, required = false,
                                 default = nil)
  if valid_603938 != nil:
    section.add "Marker", valid_603938
  var valid_603939 = formData.getOrDefault("MaxRecords")
  valid_603939 = validateParameter(valid_603939, JInt, required = false, default = nil)
  if valid_603939 != nil:
    section.add "MaxRecords", valid_603939
  var valid_603940 = formData.getOrDefault("Source")
  valid_603940 = validateParameter(valid_603940, JString, required = false,
                                 default = nil)
  if valid_603940 != nil:
    section.add "Source", valid_603940
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603941: Call_PostDescribeDBParameters_603925; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603941.validator(path, query, header, formData, body)
  let scheme = call_603941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603941.url(scheme.get, call_603941.host, call_603941.base,
                         call_603941.route, valid.getOrDefault("path"))
  result = hook(call_603941, url, valid)

proc call*(call_603942: Call_PostDescribeDBParameters_603925;
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
  var query_603943 = newJObject()
  var formData_603944 = newJObject()
  add(formData_603944, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603944, "Marker", newJString(Marker))
  add(query_603943, "Action", newJString(Action))
  add(formData_603944, "MaxRecords", newJInt(MaxRecords))
  add(query_603943, "Version", newJString(Version))
  add(formData_603944, "Source", newJString(Source))
  result = call_603942.call(nil, query_603943, nil, formData_603944, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_603925(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_603926, base: "/",
    url: url_PostDescribeDBParameters_603927, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_603906 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBParameters_603908(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBParameters_603907(path: JsonNode; query: JsonNode;
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
  var valid_603909 = query.getOrDefault("MaxRecords")
  valid_603909 = validateParameter(valid_603909, JInt, required = false, default = nil)
  if valid_603909 != nil:
    section.add "MaxRecords", valid_603909
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_603910 = query.getOrDefault("DBParameterGroupName")
  valid_603910 = validateParameter(valid_603910, JString, required = true,
                                 default = nil)
  if valid_603910 != nil:
    section.add "DBParameterGroupName", valid_603910
  var valid_603911 = query.getOrDefault("Action")
  valid_603911 = validateParameter(valid_603911, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603911 != nil:
    section.add "Action", valid_603911
  var valid_603912 = query.getOrDefault("Marker")
  valid_603912 = validateParameter(valid_603912, JString, required = false,
                                 default = nil)
  if valid_603912 != nil:
    section.add "Marker", valid_603912
  var valid_603913 = query.getOrDefault("Source")
  valid_603913 = validateParameter(valid_603913, JString, required = false,
                                 default = nil)
  if valid_603913 != nil:
    section.add "Source", valid_603913
  var valid_603914 = query.getOrDefault("Version")
  valid_603914 = validateParameter(valid_603914, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603914 != nil:
    section.add "Version", valid_603914
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603915 = header.getOrDefault("X-Amz-Date")
  valid_603915 = validateParameter(valid_603915, JString, required = false,
                                 default = nil)
  if valid_603915 != nil:
    section.add "X-Amz-Date", valid_603915
  var valid_603916 = header.getOrDefault("X-Amz-Security-Token")
  valid_603916 = validateParameter(valid_603916, JString, required = false,
                                 default = nil)
  if valid_603916 != nil:
    section.add "X-Amz-Security-Token", valid_603916
  var valid_603917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603917 = validateParameter(valid_603917, JString, required = false,
                                 default = nil)
  if valid_603917 != nil:
    section.add "X-Amz-Content-Sha256", valid_603917
  var valid_603918 = header.getOrDefault("X-Amz-Algorithm")
  valid_603918 = validateParameter(valid_603918, JString, required = false,
                                 default = nil)
  if valid_603918 != nil:
    section.add "X-Amz-Algorithm", valid_603918
  var valid_603919 = header.getOrDefault("X-Amz-Signature")
  valid_603919 = validateParameter(valid_603919, JString, required = false,
                                 default = nil)
  if valid_603919 != nil:
    section.add "X-Amz-Signature", valid_603919
  var valid_603920 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-SignedHeaders", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Credential")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Credential", valid_603921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603922: Call_GetDescribeDBParameters_603906; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603922.validator(path, query, header, formData, body)
  let scheme = call_603922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603922.url(scheme.get, call_603922.host, call_603922.base,
                         call_603922.route, valid.getOrDefault("path"))
  result = hook(call_603922, url, valid)

proc call*(call_603923: Call_GetDescribeDBParameters_603906;
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
  var query_603924 = newJObject()
  add(query_603924, "MaxRecords", newJInt(MaxRecords))
  add(query_603924, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603924, "Action", newJString(Action))
  add(query_603924, "Marker", newJString(Marker))
  add(query_603924, "Source", newJString(Source))
  add(query_603924, "Version", newJString(Version))
  result = call_603923.call(nil, query_603924, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_603906(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_603907, base: "/",
    url: url_GetDescribeDBParameters_603908, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_603963 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSecurityGroups_603965(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSecurityGroups_603964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603966 = query.getOrDefault("Action")
  valid_603966 = validateParameter(valid_603966, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603966 != nil:
    section.add "Action", valid_603966
  var valid_603967 = query.getOrDefault("Version")
  valid_603967 = validateParameter(valid_603967, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603967 != nil:
    section.add "Version", valid_603967
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603968 = header.getOrDefault("X-Amz-Date")
  valid_603968 = validateParameter(valid_603968, JString, required = false,
                                 default = nil)
  if valid_603968 != nil:
    section.add "X-Amz-Date", valid_603968
  var valid_603969 = header.getOrDefault("X-Amz-Security-Token")
  valid_603969 = validateParameter(valid_603969, JString, required = false,
                                 default = nil)
  if valid_603969 != nil:
    section.add "X-Amz-Security-Token", valid_603969
  var valid_603970 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603970 = validateParameter(valid_603970, JString, required = false,
                                 default = nil)
  if valid_603970 != nil:
    section.add "X-Amz-Content-Sha256", valid_603970
  var valid_603971 = header.getOrDefault("X-Amz-Algorithm")
  valid_603971 = validateParameter(valid_603971, JString, required = false,
                                 default = nil)
  if valid_603971 != nil:
    section.add "X-Amz-Algorithm", valid_603971
  var valid_603972 = header.getOrDefault("X-Amz-Signature")
  valid_603972 = validateParameter(valid_603972, JString, required = false,
                                 default = nil)
  if valid_603972 != nil:
    section.add "X-Amz-Signature", valid_603972
  var valid_603973 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603973 = validateParameter(valid_603973, JString, required = false,
                                 default = nil)
  if valid_603973 != nil:
    section.add "X-Amz-SignedHeaders", valid_603973
  var valid_603974 = header.getOrDefault("X-Amz-Credential")
  valid_603974 = validateParameter(valid_603974, JString, required = false,
                                 default = nil)
  if valid_603974 != nil:
    section.add "X-Amz-Credential", valid_603974
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603975 = formData.getOrDefault("DBSecurityGroupName")
  valid_603975 = validateParameter(valid_603975, JString, required = false,
                                 default = nil)
  if valid_603975 != nil:
    section.add "DBSecurityGroupName", valid_603975
  var valid_603976 = formData.getOrDefault("Marker")
  valid_603976 = validateParameter(valid_603976, JString, required = false,
                                 default = nil)
  if valid_603976 != nil:
    section.add "Marker", valid_603976
  var valid_603977 = formData.getOrDefault("MaxRecords")
  valid_603977 = validateParameter(valid_603977, JInt, required = false, default = nil)
  if valid_603977 != nil:
    section.add "MaxRecords", valid_603977
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603978: Call_PostDescribeDBSecurityGroups_603963; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603978.validator(path, query, header, formData, body)
  let scheme = call_603978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603978.url(scheme.get, call_603978.host, call_603978.base,
                         call_603978.route, valid.getOrDefault("path"))
  result = hook(call_603978, url, valid)

proc call*(call_603979: Call_PostDescribeDBSecurityGroups_603963;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_603980 = newJObject()
  var formData_603981 = newJObject()
  add(formData_603981, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_603981, "Marker", newJString(Marker))
  add(query_603980, "Action", newJString(Action))
  add(formData_603981, "MaxRecords", newJInt(MaxRecords))
  add(query_603980, "Version", newJString(Version))
  result = call_603979.call(nil, query_603980, nil, formData_603981, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_603963(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_603964, base: "/",
    url: url_PostDescribeDBSecurityGroups_603965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_603945 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSecurityGroups_603947(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSecurityGroups_603946(path: JsonNode; query: JsonNode;
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
  var valid_603948 = query.getOrDefault("MaxRecords")
  valid_603948 = validateParameter(valid_603948, JInt, required = false, default = nil)
  if valid_603948 != nil:
    section.add "MaxRecords", valid_603948
  var valid_603949 = query.getOrDefault("DBSecurityGroupName")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "DBSecurityGroupName", valid_603949
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603950 = query.getOrDefault("Action")
  valid_603950 = validateParameter(valid_603950, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603950 != nil:
    section.add "Action", valid_603950
  var valid_603951 = query.getOrDefault("Marker")
  valid_603951 = validateParameter(valid_603951, JString, required = false,
                                 default = nil)
  if valid_603951 != nil:
    section.add "Marker", valid_603951
  var valid_603952 = query.getOrDefault("Version")
  valid_603952 = validateParameter(valid_603952, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603952 != nil:
    section.add "Version", valid_603952
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603953 = header.getOrDefault("X-Amz-Date")
  valid_603953 = validateParameter(valid_603953, JString, required = false,
                                 default = nil)
  if valid_603953 != nil:
    section.add "X-Amz-Date", valid_603953
  var valid_603954 = header.getOrDefault("X-Amz-Security-Token")
  valid_603954 = validateParameter(valid_603954, JString, required = false,
                                 default = nil)
  if valid_603954 != nil:
    section.add "X-Amz-Security-Token", valid_603954
  var valid_603955 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603955 = validateParameter(valid_603955, JString, required = false,
                                 default = nil)
  if valid_603955 != nil:
    section.add "X-Amz-Content-Sha256", valid_603955
  var valid_603956 = header.getOrDefault("X-Amz-Algorithm")
  valid_603956 = validateParameter(valid_603956, JString, required = false,
                                 default = nil)
  if valid_603956 != nil:
    section.add "X-Amz-Algorithm", valid_603956
  var valid_603957 = header.getOrDefault("X-Amz-Signature")
  valid_603957 = validateParameter(valid_603957, JString, required = false,
                                 default = nil)
  if valid_603957 != nil:
    section.add "X-Amz-Signature", valid_603957
  var valid_603958 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-SignedHeaders", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Credential")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Credential", valid_603959
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603960: Call_GetDescribeDBSecurityGroups_603945; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603960.validator(path, query, header, formData, body)
  let scheme = call_603960.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603960.url(scheme.get, call_603960.host, call_603960.base,
                         call_603960.route, valid.getOrDefault("path"))
  result = hook(call_603960, url, valid)

proc call*(call_603961: Call_GetDescribeDBSecurityGroups_603945;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_603962 = newJObject()
  add(query_603962, "MaxRecords", newJInt(MaxRecords))
  add(query_603962, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603962, "Action", newJString(Action))
  add(query_603962, "Marker", newJString(Marker))
  add(query_603962, "Version", newJString(Version))
  result = call_603961.call(nil, query_603962, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_603945(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_603946, base: "/",
    url: url_GetDescribeDBSecurityGroups_603947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_604002 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSnapshots_604004(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSnapshots_604003(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604005 = query.getOrDefault("Action")
  valid_604005 = validateParameter(valid_604005, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_604005 != nil:
    section.add "Action", valid_604005
  var valid_604006 = query.getOrDefault("Version")
  valid_604006 = validateParameter(valid_604006, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604006 != nil:
    section.add "Version", valid_604006
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604007 = header.getOrDefault("X-Amz-Date")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "X-Amz-Date", valid_604007
  var valid_604008 = header.getOrDefault("X-Amz-Security-Token")
  valid_604008 = validateParameter(valid_604008, JString, required = false,
                                 default = nil)
  if valid_604008 != nil:
    section.add "X-Amz-Security-Token", valid_604008
  var valid_604009 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604009 = validateParameter(valid_604009, JString, required = false,
                                 default = nil)
  if valid_604009 != nil:
    section.add "X-Amz-Content-Sha256", valid_604009
  var valid_604010 = header.getOrDefault("X-Amz-Algorithm")
  valid_604010 = validateParameter(valid_604010, JString, required = false,
                                 default = nil)
  if valid_604010 != nil:
    section.add "X-Amz-Algorithm", valid_604010
  var valid_604011 = header.getOrDefault("X-Amz-Signature")
  valid_604011 = validateParameter(valid_604011, JString, required = false,
                                 default = nil)
  if valid_604011 != nil:
    section.add "X-Amz-Signature", valid_604011
  var valid_604012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604012 = validateParameter(valid_604012, JString, required = false,
                                 default = nil)
  if valid_604012 != nil:
    section.add "X-Amz-SignedHeaders", valid_604012
  var valid_604013 = header.getOrDefault("X-Amz-Credential")
  valid_604013 = validateParameter(valid_604013, JString, required = false,
                                 default = nil)
  if valid_604013 != nil:
    section.add "X-Amz-Credential", valid_604013
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604014 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604014 = validateParameter(valid_604014, JString, required = false,
                                 default = nil)
  if valid_604014 != nil:
    section.add "DBInstanceIdentifier", valid_604014
  var valid_604015 = formData.getOrDefault("SnapshotType")
  valid_604015 = validateParameter(valid_604015, JString, required = false,
                                 default = nil)
  if valid_604015 != nil:
    section.add "SnapshotType", valid_604015
  var valid_604016 = formData.getOrDefault("Marker")
  valid_604016 = validateParameter(valid_604016, JString, required = false,
                                 default = nil)
  if valid_604016 != nil:
    section.add "Marker", valid_604016
  var valid_604017 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604017 = validateParameter(valid_604017, JString, required = false,
                                 default = nil)
  if valid_604017 != nil:
    section.add "DBSnapshotIdentifier", valid_604017
  var valid_604018 = formData.getOrDefault("MaxRecords")
  valid_604018 = validateParameter(valid_604018, JInt, required = false, default = nil)
  if valid_604018 != nil:
    section.add "MaxRecords", valid_604018
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604019: Call_PostDescribeDBSnapshots_604002; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604019.validator(path, query, header, formData, body)
  let scheme = call_604019.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604019.url(scheme.get, call_604019.host, call_604019.base,
                         call_604019.route, valid.getOrDefault("path"))
  result = hook(call_604019, url, valid)

proc call*(call_604020: Call_PostDescribeDBSnapshots_604002;
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
  var query_604021 = newJObject()
  var formData_604022 = newJObject()
  add(formData_604022, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604022, "SnapshotType", newJString(SnapshotType))
  add(formData_604022, "Marker", newJString(Marker))
  add(formData_604022, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604021, "Action", newJString(Action))
  add(formData_604022, "MaxRecords", newJInt(MaxRecords))
  add(query_604021, "Version", newJString(Version))
  result = call_604020.call(nil, query_604021, nil, formData_604022, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_604002(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_604003, base: "/",
    url: url_PostDescribeDBSnapshots_604004, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_603982 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSnapshots_603984(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSnapshots_603983(path: JsonNode; query: JsonNode;
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
  var valid_603985 = query.getOrDefault("MaxRecords")
  valid_603985 = validateParameter(valid_603985, JInt, required = false, default = nil)
  if valid_603985 != nil:
    section.add "MaxRecords", valid_603985
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603986 = query.getOrDefault("Action")
  valid_603986 = validateParameter(valid_603986, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_603986 != nil:
    section.add "Action", valid_603986
  var valid_603987 = query.getOrDefault("Marker")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "Marker", valid_603987
  var valid_603988 = query.getOrDefault("SnapshotType")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "SnapshotType", valid_603988
  var valid_603989 = query.getOrDefault("Version")
  valid_603989 = validateParameter(valid_603989, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_603989 != nil:
    section.add "Version", valid_603989
  var valid_603990 = query.getOrDefault("DBInstanceIdentifier")
  valid_603990 = validateParameter(valid_603990, JString, required = false,
                                 default = nil)
  if valid_603990 != nil:
    section.add "DBInstanceIdentifier", valid_603990
  var valid_603991 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603991 = validateParameter(valid_603991, JString, required = false,
                                 default = nil)
  if valid_603991 != nil:
    section.add "DBSnapshotIdentifier", valid_603991
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603992 = header.getOrDefault("X-Amz-Date")
  valid_603992 = validateParameter(valid_603992, JString, required = false,
                                 default = nil)
  if valid_603992 != nil:
    section.add "X-Amz-Date", valid_603992
  var valid_603993 = header.getOrDefault("X-Amz-Security-Token")
  valid_603993 = validateParameter(valid_603993, JString, required = false,
                                 default = nil)
  if valid_603993 != nil:
    section.add "X-Amz-Security-Token", valid_603993
  var valid_603994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603994 = validateParameter(valid_603994, JString, required = false,
                                 default = nil)
  if valid_603994 != nil:
    section.add "X-Amz-Content-Sha256", valid_603994
  var valid_603995 = header.getOrDefault("X-Amz-Algorithm")
  valid_603995 = validateParameter(valid_603995, JString, required = false,
                                 default = nil)
  if valid_603995 != nil:
    section.add "X-Amz-Algorithm", valid_603995
  var valid_603996 = header.getOrDefault("X-Amz-Signature")
  valid_603996 = validateParameter(valid_603996, JString, required = false,
                                 default = nil)
  if valid_603996 != nil:
    section.add "X-Amz-Signature", valid_603996
  var valid_603997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-SignedHeaders", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Credential")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Credential", valid_603998
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603999: Call_GetDescribeDBSnapshots_603982; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603999.validator(path, query, header, formData, body)
  let scheme = call_603999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603999.url(scheme.get, call_603999.host, call_603999.base,
                         call_603999.route, valid.getOrDefault("path"))
  result = hook(call_603999, url, valid)

proc call*(call_604000: Call_GetDescribeDBSnapshots_603982; MaxRecords: int = 0;
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
  var query_604001 = newJObject()
  add(query_604001, "MaxRecords", newJInt(MaxRecords))
  add(query_604001, "Action", newJString(Action))
  add(query_604001, "Marker", newJString(Marker))
  add(query_604001, "SnapshotType", newJString(SnapshotType))
  add(query_604001, "Version", newJString(Version))
  add(query_604001, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604001, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604000.call(nil, query_604001, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_603982(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_603983, base: "/",
    url: url_GetDescribeDBSnapshots_603984, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_604041 = ref object of OpenApiRestCall_602417
proc url_PostDescribeDBSubnetGroups_604043(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDBSubnetGroups_604042(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604044 = query.getOrDefault("Action")
  valid_604044 = validateParameter(valid_604044, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604044 != nil:
    section.add "Action", valid_604044
  var valid_604045 = query.getOrDefault("Version")
  valid_604045 = validateParameter(valid_604045, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604045 != nil:
    section.add "Version", valid_604045
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604046 = header.getOrDefault("X-Amz-Date")
  valid_604046 = validateParameter(valid_604046, JString, required = false,
                                 default = nil)
  if valid_604046 != nil:
    section.add "X-Amz-Date", valid_604046
  var valid_604047 = header.getOrDefault("X-Amz-Security-Token")
  valid_604047 = validateParameter(valid_604047, JString, required = false,
                                 default = nil)
  if valid_604047 != nil:
    section.add "X-Amz-Security-Token", valid_604047
  var valid_604048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604048 = validateParameter(valid_604048, JString, required = false,
                                 default = nil)
  if valid_604048 != nil:
    section.add "X-Amz-Content-Sha256", valid_604048
  var valid_604049 = header.getOrDefault("X-Amz-Algorithm")
  valid_604049 = validateParameter(valid_604049, JString, required = false,
                                 default = nil)
  if valid_604049 != nil:
    section.add "X-Amz-Algorithm", valid_604049
  var valid_604050 = header.getOrDefault("X-Amz-Signature")
  valid_604050 = validateParameter(valid_604050, JString, required = false,
                                 default = nil)
  if valid_604050 != nil:
    section.add "X-Amz-Signature", valid_604050
  var valid_604051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604051 = validateParameter(valid_604051, JString, required = false,
                                 default = nil)
  if valid_604051 != nil:
    section.add "X-Amz-SignedHeaders", valid_604051
  var valid_604052 = header.getOrDefault("X-Amz-Credential")
  valid_604052 = validateParameter(valid_604052, JString, required = false,
                                 default = nil)
  if valid_604052 != nil:
    section.add "X-Amz-Credential", valid_604052
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604053 = formData.getOrDefault("DBSubnetGroupName")
  valid_604053 = validateParameter(valid_604053, JString, required = false,
                                 default = nil)
  if valid_604053 != nil:
    section.add "DBSubnetGroupName", valid_604053
  var valid_604054 = formData.getOrDefault("Marker")
  valid_604054 = validateParameter(valid_604054, JString, required = false,
                                 default = nil)
  if valid_604054 != nil:
    section.add "Marker", valid_604054
  var valid_604055 = formData.getOrDefault("MaxRecords")
  valid_604055 = validateParameter(valid_604055, JInt, required = false, default = nil)
  if valid_604055 != nil:
    section.add "MaxRecords", valid_604055
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604056: Call_PostDescribeDBSubnetGroups_604041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604056.validator(path, query, header, formData, body)
  let scheme = call_604056.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604056.url(scheme.get, call_604056.host, call_604056.base,
                         call_604056.route, valid.getOrDefault("path"))
  result = hook(call_604056, url, valid)

proc call*(call_604057: Call_PostDescribeDBSubnetGroups_604041;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604058 = newJObject()
  var formData_604059 = newJObject()
  add(formData_604059, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604059, "Marker", newJString(Marker))
  add(query_604058, "Action", newJString(Action))
  add(formData_604059, "MaxRecords", newJInt(MaxRecords))
  add(query_604058, "Version", newJString(Version))
  result = call_604057.call(nil, query_604058, nil, formData_604059, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_604041(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_604042, base: "/",
    url: url_PostDescribeDBSubnetGroups_604043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_604023 = ref object of OpenApiRestCall_602417
proc url_GetDescribeDBSubnetGroups_604025(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDBSubnetGroups_604024(path: JsonNode; query: JsonNode;
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
  var valid_604026 = query.getOrDefault("MaxRecords")
  valid_604026 = validateParameter(valid_604026, JInt, required = false, default = nil)
  if valid_604026 != nil:
    section.add "MaxRecords", valid_604026
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604027 = query.getOrDefault("Action")
  valid_604027 = validateParameter(valid_604027, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604027 != nil:
    section.add "Action", valid_604027
  var valid_604028 = query.getOrDefault("Marker")
  valid_604028 = validateParameter(valid_604028, JString, required = false,
                                 default = nil)
  if valid_604028 != nil:
    section.add "Marker", valid_604028
  var valid_604029 = query.getOrDefault("DBSubnetGroupName")
  valid_604029 = validateParameter(valid_604029, JString, required = false,
                                 default = nil)
  if valid_604029 != nil:
    section.add "DBSubnetGroupName", valid_604029
  var valid_604030 = query.getOrDefault("Version")
  valid_604030 = validateParameter(valid_604030, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604030 != nil:
    section.add "Version", valid_604030
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604031 = header.getOrDefault("X-Amz-Date")
  valid_604031 = validateParameter(valid_604031, JString, required = false,
                                 default = nil)
  if valid_604031 != nil:
    section.add "X-Amz-Date", valid_604031
  var valid_604032 = header.getOrDefault("X-Amz-Security-Token")
  valid_604032 = validateParameter(valid_604032, JString, required = false,
                                 default = nil)
  if valid_604032 != nil:
    section.add "X-Amz-Security-Token", valid_604032
  var valid_604033 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604033 = validateParameter(valid_604033, JString, required = false,
                                 default = nil)
  if valid_604033 != nil:
    section.add "X-Amz-Content-Sha256", valid_604033
  var valid_604034 = header.getOrDefault("X-Amz-Algorithm")
  valid_604034 = validateParameter(valid_604034, JString, required = false,
                                 default = nil)
  if valid_604034 != nil:
    section.add "X-Amz-Algorithm", valid_604034
  var valid_604035 = header.getOrDefault("X-Amz-Signature")
  valid_604035 = validateParameter(valid_604035, JString, required = false,
                                 default = nil)
  if valid_604035 != nil:
    section.add "X-Amz-Signature", valid_604035
  var valid_604036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-SignedHeaders", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Credential")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Credential", valid_604037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604038: Call_GetDescribeDBSubnetGroups_604023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604038.validator(path, query, header, formData, body)
  let scheme = call_604038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604038.url(scheme.get, call_604038.host, call_604038.base,
                         call_604038.route, valid.getOrDefault("path"))
  result = hook(call_604038, url, valid)

proc call*(call_604039: Call_GetDescribeDBSubnetGroups_604023; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_604040 = newJObject()
  add(query_604040, "MaxRecords", newJInt(MaxRecords))
  add(query_604040, "Action", newJString(Action))
  add(query_604040, "Marker", newJString(Marker))
  add(query_604040, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604040, "Version", newJString(Version))
  result = call_604039.call(nil, query_604040, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_604023(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_604024, base: "/",
    url: url_GetDescribeDBSubnetGroups_604025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_604078 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEngineDefaultParameters_604080(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEngineDefaultParameters_604079(path: JsonNode;
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
  var valid_604081 = query.getOrDefault("Action")
  valid_604081 = validateParameter(valid_604081, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604081 != nil:
    section.add "Action", valid_604081
  var valid_604082 = query.getOrDefault("Version")
  valid_604082 = validateParameter(valid_604082, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604082 != nil:
    section.add "Version", valid_604082
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604083 = header.getOrDefault("X-Amz-Date")
  valid_604083 = validateParameter(valid_604083, JString, required = false,
                                 default = nil)
  if valid_604083 != nil:
    section.add "X-Amz-Date", valid_604083
  var valid_604084 = header.getOrDefault("X-Amz-Security-Token")
  valid_604084 = validateParameter(valid_604084, JString, required = false,
                                 default = nil)
  if valid_604084 != nil:
    section.add "X-Amz-Security-Token", valid_604084
  var valid_604085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604085 = validateParameter(valid_604085, JString, required = false,
                                 default = nil)
  if valid_604085 != nil:
    section.add "X-Amz-Content-Sha256", valid_604085
  var valid_604086 = header.getOrDefault("X-Amz-Algorithm")
  valid_604086 = validateParameter(valid_604086, JString, required = false,
                                 default = nil)
  if valid_604086 != nil:
    section.add "X-Amz-Algorithm", valid_604086
  var valid_604087 = header.getOrDefault("X-Amz-Signature")
  valid_604087 = validateParameter(valid_604087, JString, required = false,
                                 default = nil)
  if valid_604087 != nil:
    section.add "X-Amz-Signature", valid_604087
  var valid_604088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604088 = validateParameter(valid_604088, JString, required = false,
                                 default = nil)
  if valid_604088 != nil:
    section.add "X-Amz-SignedHeaders", valid_604088
  var valid_604089 = header.getOrDefault("X-Amz-Credential")
  valid_604089 = validateParameter(valid_604089, JString, required = false,
                                 default = nil)
  if valid_604089 != nil:
    section.add "X-Amz-Credential", valid_604089
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604090 = formData.getOrDefault("Marker")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "Marker", valid_604090
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604091 = formData.getOrDefault("DBParameterGroupFamily")
  valid_604091 = validateParameter(valid_604091, JString, required = true,
                                 default = nil)
  if valid_604091 != nil:
    section.add "DBParameterGroupFamily", valid_604091
  var valid_604092 = formData.getOrDefault("MaxRecords")
  valid_604092 = validateParameter(valid_604092, JInt, required = false, default = nil)
  if valid_604092 != nil:
    section.add "MaxRecords", valid_604092
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604093: Call_PostDescribeEngineDefaultParameters_604078;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604093.validator(path, query, header, formData, body)
  let scheme = call_604093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604093.url(scheme.get, call_604093.host, call_604093.base,
                         call_604093.route, valid.getOrDefault("path"))
  result = hook(call_604093, url, valid)

proc call*(call_604094: Call_PostDescribeEngineDefaultParameters_604078;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604095 = newJObject()
  var formData_604096 = newJObject()
  add(formData_604096, "Marker", newJString(Marker))
  add(query_604095, "Action", newJString(Action))
  add(formData_604096, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_604096, "MaxRecords", newJInt(MaxRecords))
  add(query_604095, "Version", newJString(Version))
  result = call_604094.call(nil, query_604095, nil, formData_604096, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_604078(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_604079, base: "/",
    url: url_PostDescribeEngineDefaultParameters_604080,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_604060 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEngineDefaultParameters_604062(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEngineDefaultParameters_604061(path: JsonNode;
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
  var valid_604063 = query.getOrDefault("MaxRecords")
  valid_604063 = validateParameter(valid_604063, JInt, required = false, default = nil)
  if valid_604063 != nil:
    section.add "MaxRecords", valid_604063
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604064 = query.getOrDefault("DBParameterGroupFamily")
  valid_604064 = validateParameter(valid_604064, JString, required = true,
                                 default = nil)
  if valid_604064 != nil:
    section.add "DBParameterGroupFamily", valid_604064
  var valid_604065 = query.getOrDefault("Action")
  valid_604065 = validateParameter(valid_604065, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604065 != nil:
    section.add "Action", valid_604065
  var valid_604066 = query.getOrDefault("Marker")
  valid_604066 = validateParameter(valid_604066, JString, required = false,
                                 default = nil)
  if valid_604066 != nil:
    section.add "Marker", valid_604066
  var valid_604067 = query.getOrDefault("Version")
  valid_604067 = validateParameter(valid_604067, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604067 != nil:
    section.add "Version", valid_604067
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604068 = header.getOrDefault("X-Amz-Date")
  valid_604068 = validateParameter(valid_604068, JString, required = false,
                                 default = nil)
  if valid_604068 != nil:
    section.add "X-Amz-Date", valid_604068
  var valid_604069 = header.getOrDefault("X-Amz-Security-Token")
  valid_604069 = validateParameter(valid_604069, JString, required = false,
                                 default = nil)
  if valid_604069 != nil:
    section.add "X-Amz-Security-Token", valid_604069
  var valid_604070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604070 = validateParameter(valid_604070, JString, required = false,
                                 default = nil)
  if valid_604070 != nil:
    section.add "X-Amz-Content-Sha256", valid_604070
  var valid_604071 = header.getOrDefault("X-Amz-Algorithm")
  valid_604071 = validateParameter(valid_604071, JString, required = false,
                                 default = nil)
  if valid_604071 != nil:
    section.add "X-Amz-Algorithm", valid_604071
  var valid_604072 = header.getOrDefault("X-Amz-Signature")
  valid_604072 = validateParameter(valid_604072, JString, required = false,
                                 default = nil)
  if valid_604072 != nil:
    section.add "X-Amz-Signature", valid_604072
  var valid_604073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-SignedHeaders", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Credential")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Credential", valid_604074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604075: Call_GetDescribeEngineDefaultParameters_604060;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604075.validator(path, query, header, formData, body)
  let scheme = call_604075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604075.url(scheme.get, call_604075.host, call_604075.base,
                         call_604075.route, valid.getOrDefault("path"))
  result = hook(call_604075, url, valid)

proc call*(call_604076: Call_GetDescribeEngineDefaultParameters_604060;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_604077 = newJObject()
  add(query_604077, "MaxRecords", newJInt(MaxRecords))
  add(query_604077, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_604077, "Action", newJString(Action))
  add(query_604077, "Marker", newJString(Marker))
  add(query_604077, "Version", newJString(Version))
  result = call_604076.call(nil, query_604077, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_604060(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_604061, base: "/",
    url: url_GetDescribeEngineDefaultParameters_604062,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604113 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEventCategories_604115(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventCategories_604114(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604116 = query.getOrDefault("Action")
  valid_604116 = validateParameter(valid_604116, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604116 != nil:
    section.add "Action", valid_604116
  var valid_604117 = query.getOrDefault("Version")
  valid_604117 = validateParameter(valid_604117, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604117 != nil:
    section.add "Version", valid_604117
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604118 = header.getOrDefault("X-Amz-Date")
  valid_604118 = validateParameter(valid_604118, JString, required = false,
                                 default = nil)
  if valid_604118 != nil:
    section.add "X-Amz-Date", valid_604118
  var valid_604119 = header.getOrDefault("X-Amz-Security-Token")
  valid_604119 = validateParameter(valid_604119, JString, required = false,
                                 default = nil)
  if valid_604119 != nil:
    section.add "X-Amz-Security-Token", valid_604119
  var valid_604120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604120 = validateParameter(valid_604120, JString, required = false,
                                 default = nil)
  if valid_604120 != nil:
    section.add "X-Amz-Content-Sha256", valid_604120
  var valid_604121 = header.getOrDefault("X-Amz-Algorithm")
  valid_604121 = validateParameter(valid_604121, JString, required = false,
                                 default = nil)
  if valid_604121 != nil:
    section.add "X-Amz-Algorithm", valid_604121
  var valid_604122 = header.getOrDefault("X-Amz-Signature")
  valid_604122 = validateParameter(valid_604122, JString, required = false,
                                 default = nil)
  if valid_604122 != nil:
    section.add "X-Amz-Signature", valid_604122
  var valid_604123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604123 = validateParameter(valid_604123, JString, required = false,
                                 default = nil)
  if valid_604123 != nil:
    section.add "X-Amz-SignedHeaders", valid_604123
  var valid_604124 = header.getOrDefault("X-Amz-Credential")
  valid_604124 = validateParameter(valid_604124, JString, required = false,
                                 default = nil)
  if valid_604124 != nil:
    section.add "X-Amz-Credential", valid_604124
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_604125 = formData.getOrDefault("SourceType")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "SourceType", valid_604125
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604126: Call_PostDescribeEventCategories_604113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604126.validator(path, query, header, formData, body)
  let scheme = call_604126.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604126.url(scheme.get, call_604126.host, call_604126.base,
                         call_604126.route, valid.getOrDefault("path"))
  result = hook(call_604126, url, valid)

proc call*(call_604127: Call_PostDescribeEventCategories_604113;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_604128 = newJObject()
  var formData_604129 = newJObject()
  add(query_604128, "Action", newJString(Action))
  add(query_604128, "Version", newJString(Version))
  add(formData_604129, "SourceType", newJString(SourceType))
  result = call_604127.call(nil, query_604128, nil, formData_604129, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604113(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604114, base: "/",
    url: url_PostDescribeEventCategories_604115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604097 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEventCategories_604099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventCategories_604098(path: JsonNode; query: JsonNode;
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
  var valid_604100 = query.getOrDefault("SourceType")
  valid_604100 = validateParameter(valid_604100, JString, required = false,
                                 default = nil)
  if valid_604100 != nil:
    section.add "SourceType", valid_604100
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604101 = query.getOrDefault("Action")
  valid_604101 = validateParameter(valid_604101, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604101 != nil:
    section.add "Action", valid_604101
  var valid_604102 = query.getOrDefault("Version")
  valid_604102 = validateParameter(valid_604102, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604102 != nil:
    section.add "Version", valid_604102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604103 = header.getOrDefault("X-Amz-Date")
  valid_604103 = validateParameter(valid_604103, JString, required = false,
                                 default = nil)
  if valid_604103 != nil:
    section.add "X-Amz-Date", valid_604103
  var valid_604104 = header.getOrDefault("X-Amz-Security-Token")
  valid_604104 = validateParameter(valid_604104, JString, required = false,
                                 default = nil)
  if valid_604104 != nil:
    section.add "X-Amz-Security-Token", valid_604104
  var valid_604105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604105 = validateParameter(valid_604105, JString, required = false,
                                 default = nil)
  if valid_604105 != nil:
    section.add "X-Amz-Content-Sha256", valid_604105
  var valid_604106 = header.getOrDefault("X-Amz-Algorithm")
  valid_604106 = validateParameter(valid_604106, JString, required = false,
                                 default = nil)
  if valid_604106 != nil:
    section.add "X-Amz-Algorithm", valid_604106
  var valid_604107 = header.getOrDefault("X-Amz-Signature")
  valid_604107 = validateParameter(valid_604107, JString, required = false,
                                 default = nil)
  if valid_604107 != nil:
    section.add "X-Amz-Signature", valid_604107
  var valid_604108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-SignedHeaders", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Credential")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Credential", valid_604109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604110: Call_GetDescribeEventCategories_604097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604110.validator(path, query, header, formData, body)
  let scheme = call_604110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604110.url(scheme.get, call_604110.host, call_604110.base,
                         call_604110.route, valid.getOrDefault("path"))
  result = hook(call_604110, url, valid)

proc call*(call_604111: Call_GetDescribeEventCategories_604097;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604112 = newJObject()
  add(query_604112, "SourceType", newJString(SourceType))
  add(query_604112, "Action", newJString(Action))
  add(query_604112, "Version", newJString(Version))
  result = call_604111.call(nil, query_604112, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604097(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604098, base: "/",
    url: url_GetDescribeEventCategories_604099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_604148 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEventSubscriptions_604150(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEventSubscriptions_604149(path: JsonNode;
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
  var valid_604151 = query.getOrDefault("Action")
  valid_604151 = validateParameter(valid_604151, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604151 != nil:
    section.add "Action", valid_604151
  var valid_604152 = query.getOrDefault("Version")
  valid_604152 = validateParameter(valid_604152, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604152 != nil:
    section.add "Version", valid_604152
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604153 = header.getOrDefault("X-Amz-Date")
  valid_604153 = validateParameter(valid_604153, JString, required = false,
                                 default = nil)
  if valid_604153 != nil:
    section.add "X-Amz-Date", valid_604153
  var valid_604154 = header.getOrDefault("X-Amz-Security-Token")
  valid_604154 = validateParameter(valid_604154, JString, required = false,
                                 default = nil)
  if valid_604154 != nil:
    section.add "X-Amz-Security-Token", valid_604154
  var valid_604155 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604155 = validateParameter(valid_604155, JString, required = false,
                                 default = nil)
  if valid_604155 != nil:
    section.add "X-Amz-Content-Sha256", valid_604155
  var valid_604156 = header.getOrDefault("X-Amz-Algorithm")
  valid_604156 = validateParameter(valid_604156, JString, required = false,
                                 default = nil)
  if valid_604156 != nil:
    section.add "X-Amz-Algorithm", valid_604156
  var valid_604157 = header.getOrDefault("X-Amz-Signature")
  valid_604157 = validateParameter(valid_604157, JString, required = false,
                                 default = nil)
  if valid_604157 != nil:
    section.add "X-Amz-Signature", valid_604157
  var valid_604158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604158 = validateParameter(valid_604158, JString, required = false,
                                 default = nil)
  if valid_604158 != nil:
    section.add "X-Amz-SignedHeaders", valid_604158
  var valid_604159 = header.getOrDefault("X-Amz-Credential")
  valid_604159 = validateParameter(valid_604159, JString, required = false,
                                 default = nil)
  if valid_604159 != nil:
    section.add "X-Amz-Credential", valid_604159
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604160 = formData.getOrDefault("Marker")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = nil)
  if valid_604160 != nil:
    section.add "Marker", valid_604160
  var valid_604161 = formData.getOrDefault("SubscriptionName")
  valid_604161 = validateParameter(valid_604161, JString, required = false,
                                 default = nil)
  if valid_604161 != nil:
    section.add "SubscriptionName", valid_604161
  var valid_604162 = formData.getOrDefault("MaxRecords")
  valid_604162 = validateParameter(valid_604162, JInt, required = false, default = nil)
  if valid_604162 != nil:
    section.add "MaxRecords", valid_604162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604163: Call_PostDescribeEventSubscriptions_604148; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604163.validator(path, query, header, formData, body)
  let scheme = call_604163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604163.url(scheme.get, call_604163.host, call_604163.base,
                         call_604163.route, valid.getOrDefault("path"))
  result = hook(call_604163, url, valid)

proc call*(call_604164: Call_PostDescribeEventSubscriptions_604148;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-02-12"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604165 = newJObject()
  var formData_604166 = newJObject()
  add(formData_604166, "Marker", newJString(Marker))
  add(formData_604166, "SubscriptionName", newJString(SubscriptionName))
  add(query_604165, "Action", newJString(Action))
  add(formData_604166, "MaxRecords", newJInt(MaxRecords))
  add(query_604165, "Version", newJString(Version))
  result = call_604164.call(nil, query_604165, nil, formData_604166, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_604148(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_604149, base: "/",
    url: url_PostDescribeEventSubscriptions_604150,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_604130 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEventSubscriptions_604132(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEventSubscriptions_604131(path: JsonNode; query: JsonNode;
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
  var valid_604133 = query.getOrDefault("MaxRecords")
  valid_604133 = validateParameter(valid_604133, JInt, required = false, default = nil)
  if valid_604133 != nil:
    section.add "MaxRecords", valid_604133
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604134 = query.getOrDefault("Action")
  valid_604134 = validateParameter(valid_604134, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604134 != nil:
    section.add "Action", valid_604134
  var valid_604135 = query.getOrDefault("Marker")
  valid_604135 = validateParameter(valid_604135, JString, required = false,
                                 default = nil)
  if valid_604135 != nil:
    section.add "Marker", valid_604135
  var valid_604136 = query.getOrDefault("SubscriptionName")
  valid_604136 = validateParameter(valid_604136, JString, required = false,
                                 default = nil)
  if valid_604136 != nil:
    section.add "SubscriptionName", valid_604136
  var valid_604137 = query.getOrDefault("Version")
  valid_604137 = validateParameter(valid_604137, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604137 != nil:
    section.add "Version", valid_604137
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604138 = header.getOrDefault("X-Amz-Date")
  valid_604138 = validateParameter(valid_604138, JString, required = false,
                                 default = nil)
  if valid_604138 != nil:
    section.add "X-Amz-Date", valid_604138
  var valid_604139 = header.getOrDefault("X-Amz-Security-Token")
  valid_604139 = validateParameter(valid_604139, JString, required = false,
                                 default = nil)
  if valid_604139 != nil:
    section.add "X-Amz-Security-Token", valid_604139
  var valid_604140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604140 = validateParameter(valid_604140, JString, required = false,
                                 default = nil)
  if valid_604140 != nil:
    section.add "X-Amz-Content-Sha256", valid_604140
  var valid_604141 = header.getOrDefault("X-Amz-Algorithm")
  valid_604141 = validateParameter(valid_604141, JString, required = false,
                                 default = nil)
  if valid_604141 != nil:
    section.add "X-Amz-Algorithm", valid_604141
  var valid_604142 = header.getOrDefault("X-Amz-Signature")
  valid_604142 = validateParameter(valid_604142, JString, required = false,
                                 default = nil)
  if valid_604142 != nil:
    section.add "X-Amz-Signature", valid_604142
  var valid_604143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-SignedHeaders", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Credential")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Credential", valid_604144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604145: Call_GetDescribeEventSubscriptions_604130; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604145.validator(path, query, header, formData, body)
  let scheme = call_604145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604145.url(scheme.get, call_604145.host, call_604145.base,
                         call_604145.route, valid.getOrDefault("path"))
  result = hook(call_604145, url, valid)

proc call*(call_604146: Call_GetDescribeEventSubscriptions_604130;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_604147 = newJObject()
  add(query_604147, "MaxRecords", newJInt(MaxRecords))
  add(query_604147, "Action", newJString(Action))
  add(query_604147, "Marker", newJString(Marker))
  add(query_604147, "SubscriptionName", newJString(SubscriptionName))
  add(query_604147, "Version", newJString(Version))
  result = call_604146.call(nil, query_604147, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_604130(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_604131, base: "/",
    url: url_GetDescribeEventSubscriptions_604132,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604190 = ref object of OpenApiRestCall_602417
proc url_PostDescribeEvents_604192(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeEvents_604191(path: JsonNode; query: JsonNode;
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
  var valid_604193 = query.getOrDefault("Action")
  valid_604193 = validateParameter(valid_604193, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604193 != nil:
    section.add "Action", valid_604193
  var valid_604194 = query.getOrDefault("Version")
  valid_604194 = validateParameter(valid_604194, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604194 != nil:
    section.add "Version", valid_604194
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604195 = header.getOrDefault("X-Amz-Date")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "X-Amz-Date", valid_604195
  var valid_604196 = header.getOrDefault("X-Amz-Security-Token")
  valid_604196 = validateParameter(valid_604196, JString, required = false,
                                 default = nil)
  if valid_604196 != nil:
    section.add "X-Amz-Security-Token", valid_604196
  var valid_604197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "X-Amz-Content-Sha256", valid_604197
  var valid_604198 = header.getOrDefault("X-Amz-Algorithm")
  valid_604198 = validateParameter(valid_604198, JString, required = false,
                                 default = nil)
  if valid_604198 != nil:
    section.add "X-Amz-Algorithm", valid_604198
  var valid_604199 = header.getOrDefault("X-Amz-Signature")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = nil)
  if valid_604199 != nil:
    section.add "X-Amz-Signature", valid_604199
  var valid_604200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604200 = validateParameter(valid_604200, JString, required = false,
                                 default = nil)
  if valid_604200 != nil:
    section.add "X-Amz-SignedHeaders", valid_604200
  var valid_604201 = header.getOrDefault("X-Amz-Credential")
  valid_604201 = validateParameter(valid_604201, JString, required = false,
                                 default = nil)
  if valid_604201 != nil:
    section.add "X-Amz-Credential", valid_604201
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
  var valid_604202 = formData.getOrDefault("SourceIdentifier")
  valid_604202 = validateParameter(valid_604202, JString, required = false,
                                 default = nil)
  if valid_604202 != nil:
    section.add "SourceIdentifier", valid_604202
  var valid_604203 = formData.getOrDefault("EventCategories")
  valid_604203 = validateParameter(valid_604203, JArray, required = false,
                                 default = nil)
  if valid_604203 != nil:
    section.add "EventCategories", valid_604203
  var valid_604204 = formData.getOrDefault("Marker")
  valid_604204 = validateParameter(valid_604204, JString, required = false,
                                 default = nil)
  if valid_604204 != nil:
    section.add "Marker", valid_604204
  var valid_604205 = formData.getOrDefault("StartTime")
  valid_604205 = validateParameter(valid_604205, JString, required = false,
                                 default = nil)
  if valid_604205 != nil:
    section.add "StartTime", valid_604205
  var valid_604206 = formData.getOrDefault("Duration")
  valid_604206 = validateParameter(valid_604206, JInt, required = false, default = nil)
  if valid_604206 != nil:
    section.add "Duration", valid_604206
  var valid_604207 = formData.getOrDefault("EndTime")
  valid_604207 = validateParameter(valid_604207, JString, required = false,
                                 default = nil)
  if valid_604207 != nil:
    section.add "EndTime", valid_604207
  var valid_604208 = formData.getOrDefault("MaxRecords")
  valid_604208 = validateParameter(valid_604208, JInt, required = false, default = nil)
  if valid_604208 != nil:
    section.add "MaxRecords", valid_604208
  var valid_604209 = formData.getOrDefault("SourceType")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604209 != nil:
    section.add "SourceType", valid_604209
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604210: Call_PostDescribeEvents_604190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604210.validator(path, query, header, formData, body)
  let scheme = call_604210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604210.url(scheme.get, call_604210.host, call_604210.base,
                         call_604210.route, valid.getOrDefault("path"))
  result = hook(call_604210, url, valid)

proc call*(call_604211: Call_PostDescribeEvents_604190;
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
  var query_604212 = newJObject()
  var formData_604213 = newJObject()
  add(formData_604213, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604213.add "EventCategories", EventCategories
  add(formData_604213, "Marker", newJString(Marker))
  add(formData_604213, "StartTime", newJString(StartTime))
  add(query_604212, "Action", newJString(Action))
  add(formData_604213, "Duration", newJInt(Duration))
  add(formData_604213, "EndTime", newJString(EndTime))
  add(formData_604213, "MaxRecords", newJInt(MaxRecords))
  add(query_604212, "Version", newJString(Version))
  add(formData_604213, "SourceType", newJString(SourceType))
  result = call_604211.call(nil, query_604212, nil, formData_604213, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604190(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604191, base: "/",
    url: url_PostDescribeEvents_604192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604167 = ref object of OpenApiRestCall_602417
proc url_GetDescribeEvents_604169(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeEvents_604168(path: JsonNode; query: JsonNode;
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
  var valid_604170 = query.getOrDefault("SourceType")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604170 != nil:
    section.add "SourceType", valid_604170
  var valid_604171 = query.getOrDefault("MaxRecords")
  valid_604171 = validateParameter(valid_604171, JInt, required = false, default = nil)
  if valid_604171 != nil:
    section.add "MaxRecords", valid_604171
  var valid_604172 = query.getOrDefault("StartTime")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "StartTime", valid_604172
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604173 = query.getOrDefault("Action")
  valid_604173 = validateParameter(valid_604173, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604173 != nil:
    section.add "Action", valid_604173
  var valid_604174 = query.getOrDefault("SourceIdentifier")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "SourceIdentifier", valid_604174
  var valid_604175 = query.getOrDefault("Marker")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "Marker", valid_604175
  var valid_604176 = query.getOrDefault("EventCategories")
  valid_604176 = validateParameter(valid_604176, JArray, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "EventCategories", valid_604176
  var valid_604177 = query.getOrDefault("Duration")
  valid_604177 = validateParameter(valid_604177, JInt, required = false, default = nil)
  if valid_604177 != nil:
    section.add "Duration", valid_604177
  var valid_604178 = query.getOrDefault("EndTime")
  valid_604178 = validateParameter(valid_604178, JString, required = false,
                                 default = nil)
  if valid_604178 != nil:
    section.add "EndTime", valid_604178
  var valid_604179 = query.getOrDefault("Version")
  valid_604179 = validateParameter(valid_604179, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604179 != nil:
    section.add "Version", valid_604179
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604180 = header.getOrDefault("X-Amz-Date")
  valid_604180 = validateParameter(valid_604180, JString, required = false,
                                 default = nil)
  if valid_604180 != nil:
    section.add "X-Amz-Date", valid_604180
  var valid_604181 = header.getOrDefault("X-Amz-Security-Token")
  valid_604181 = validateParameter(valid_604181, JString, required = false,
                                 default = nil)
  if valid_604181 != nil:
    section.add "X-Amz-Security-Token", valid_604181
  var valid_604182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604182 = validateParameter(valid_604182, JString, required = false,
                                 default = nil)
  if valid_604182 != nil:
    section.add "X-Amz-Content-Sha256", valid_604182
  var valid_604183 = header.getOrDefault("X-Amz-Algorithm")
  valid_604183 = validateParameter(valid_604183, JString, required = false,
                                 default = nil)
  if valid_604183 != nil:
    section.add "X-Amz-Algorithm", valid_604183
  var valid_604184 = header.getOrDefault("X-Amz-Signature")
  valid_604184 = validateParameter(valid_604184, JString, required = false,
                                 default = nil)
  if valid_604184 != nil:
    section.add "X-Amz-Signature", valid_604184
  var valid_604185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-SignedHeaders", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-Credential")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Credential", valid_604186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604187: Call_GetDescribeEvents_604167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604187.validator(path, query, header, formData, body)
  let scheme = call_604187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604187.url(scheme.get, call_604187.host, call_604187.base,
                         call_604187.route, valid.getOrDefault("path"))
  result = hook(call_604187, url, valid)

proc call*(call_604188: Call_GetDescribeEvents_604167;
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
  var query_604189 = newJObject()
  add(query_604189, "SourceType", newJString(SourceType))
  add(query_604189, "MaxRecords", newJInt(MaxRecords))
  add(query_604189, "StartTime", newJString(StartTime))
  add(query_604189, "Action", newJString(Action))
  add(query_604189, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604189, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604189.add "EventCategories", EventCategories
  add(query_604189, "Duration", newJInt(Duration))
  add(query_604189, "EndTime", newJString(EndTime))
  add(query_604189, "Version", newJString(Version))
  result = call_604188.call(nil, query_604189, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604167(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604168,
    base: "/", url: url_GetDescribeEvents_604169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_604233 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOptionGroupOptions_604235(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroupOptions_604234(path: JsonNode;
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
  var valid_604236 = query.getOrDefault("Action")
  valid_604236 = validateParameter(valid_604236, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604236 != nil:
    section.add "Action", valid_604236
  var valid_604237 = query.getOrDefault("Version")
  valid_604237 = validateParameter(valid_604237, JString, required = true,
                                 default = newJString("2013-02-12"))
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
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604245 = formData.getOrDefault("MajorEngineVersion")
  valid_604245 = validateParameter(valid_604245, JString, required = false,
                                 default = nil)
  if valid_604245 != nil:
    section.add "MajorEngineVersion", valid_604245
  var valid_604246 = formData.getOrDefault("Marker")
  valid_604246 = validateParameter(valid_604246, JString, required = false,
                                 default = nil)
  if valid_604246 != nil:
    section.add "Marker", valid_604246
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_604247 = formData.getOrDefault("EngineName")
  valid_604247 = validateParameter(valid_604247, JString, required = true,
                                 default = nil)
  if valid_604247 != nil:
    section.add "EngineName", valid_604247
  var valid_604248 = formData.getOrDefault("MaxRecords")
  valid_604248 = validateParameter(valid_604248, JInt, required = false, default = nil)
  if valid_604248 != nil:
    section.add "MaxRecords", valid_604248
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604249: Call_PostDescribeOptionGroupOptions_604233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604249.validator(path, query, header, formData, body)
  let scheme = call_604249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604249.url(scheme.get, call_604249.host, call_604249.base,
                         call_604249.route, valid.getOrDefault("path"))
  result = hook(call_604249, url, valid)

proc call*(call_604250: Call_PostDescribeOptionGroupOptions_604233;
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
  var query_604251 = newJObject()
  var formData_604252 = newJObject()
  add(formData_604252, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604252, "Marker", newJString(Marker))
  add(query_604251, "Action", newJString(Action))
  add(formData_604252, "EngineName", newJString(EngineName))
  add(formData_604252, "MaxRecords", newJInt(MaxRecords))
  add(query_604251, "Version", newJString(Version))
  result = call_604250.call(nil, query_604251, nil, formData_604252, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_604233(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_604234, base: "/",
    url: url_PostDescribeOptionGroupOptions_604235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_604214 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOptionGroupOptions_604216(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroupOptions_604215(path: JsonNode; query: JsonNode;
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
  var valid_604217 = query.getOrDefault("MaxRecords")
  valid_604217 = validateParameter(valid_604217, JInt, required = false, default = nil)
  if valid_604217 != nil:
    section.add "MaxRecords", valid_604217
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604218 = query.getOrDefault("Action")
  valid_604218 = validateParameter(valid_604218, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604218 != nil:
    section.add "Action", valid_604218
  var valid_604219 = query.getOrDefault("Marker")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "Marker", valid_604219
  var valid_604220 = query.getOrDefault("Version")
  valid_604220 = validateParameter(valid_604220, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604220 != nil:
    section.add "Version", valid_604220
  var valid_604221 = query.getOrDefault("EngineName")
  valid_604221 = validateParameter(valid_604221, JString, required = true,
                                 default = nil)
  if valid_604221 != nil:
    section.add "EngineName", valid_604221
  var valid_604222 = query.getOrDefault("MajorEngineVersion")
  valid_604222 = validateParameter(valid_604222, JString, required = false,
                                 default = nil)
  if valid_604222 != nil:
    section.add "MajorEngineVersion", valid_604222
  result.add "query", section
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

proc call*(call_604230: Call_GetDescribeOptionGroupOptions_604214; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604230.validator(path, query, header, formData, body)
  let scheme = call_604230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604230.url(scheme.get, call_604230.host, call_604230.base,
                         call_604230.route, valid.getOrDefault("path"))
  result = hook(call_604230, url, valid)

proc call*(call_604231: Call_GetDescribeOptionGroupOptions_604214;
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
  var query_604232 = newJObject()
  add(query_604232, "MaxRecords", newJInt(MaxRecords))
  add(query_604232, "Action", newJString(Action))
  add(query_604232, "Marker", newJString(Marker))
  add(query_604232, "Version", newJString(Version))
  add(query_604232, "EngineName", newJString(EngineName))
  add(query_604232, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604231.call(nil, query_604232, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_604214(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_604215, base: "/",
    url: url_GetDescribeOptionGroupOptions_604216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_604273 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOptionGroups_604275(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOptionGroups_604274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604276 = query.getOrDefault("Action")
  valid_604276 = validateParameter(valid_604276, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604276 != nil:
    section.add "Action", valid_604276
  var valid_604277 = query.getOrDefault("Version")
  valid_604277 = validateParameter(valid_604277, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604277 != nil:
    section.add "Version", valid_604277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604278 = header.getOrDefault("X-Amz-Date")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "X-Amz-Date", valid_604278
  var valid_604279 = header.getOrDefault("X-Amz-Security-Token")
  valid_604279 = validateParameter(valid_604279, JString, required = false,
                                 default = nil)
  if valid_604279 != nil:
    section.add "X-Amz-Security-Token", valid_604279
  var valid_604280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604280 = validateParameter(valid_604280, JString, required = false,
                                 default = nil)
  if valid_604280 != nil:
    section.add "X-Amz-Content-Sha256", valid_604280
  var valid_604281 = header.getOrDefault("X-Amz-Algorithm")
  valid_604281 = validateParameter(valid_604281, JString, required = false,
                                 default = nil)
  if valid_604281 != nil:
    section.add "X-Amz-Algorithm", valid_604281
  var valid_604282 = header.getOrDefault("X-Amz-Signature")
  valid_604282 = validateParameter(valid_604282, JString, required = false,
                                 default = nil)
  if valid_604282 != nil:
    section.add "X-Amz-Signature", valid_604282
  var valid_604283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604283 = validateParameter(valid_604283, JString, required = false,
                                 default = nil)
  if valid_604283 != nil:
    section.add "X-Amz-SignedHeaders", valid_604283
  var valid_604284 = header.getOrDefault("X-Amz-Credential")
  valid_604284 = validateParameter(valid_604284, JString, required = false,
                                 default = nil)
  if valid_604284 != nil:
    section.add "X-Amz-Credential", valid_604284
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604285 = formData.getOrDefault("MajorEngineVersion")
  valid_604285 = validateParameter(valid_604285, JString, required = false,
                                 default = nil)
  if valid_604285 != nil:
    section.add "MajorEngineVersion", valid_604285
  var valid_604286 = formData.getOrDefault("OptionGroupName")
  valid_604286 = validateParameter(valid_604286, JString, required = false,
                                 default = nil)
  if valid_604286 != nil:
    section.add "OptionGroupName", valid_604286
  var valid_604287 = formData.getOrDefault("Marker")
  valid_604287 = validateParameter(valid_604287, JString, required = false,
                                 default = nil)
  if valid_604287 != nil:
    section.add "Marker", valid_604287
  var valid_604288 = formData.getOrDefault("EngineName")
  valid_604288 = validateParameter(valid_604288, JString, required = false,
                                 default = nil)
  if valid_604288 != nil:
    section.add "EngineName", valid_604288
  var valid_604289 = formData.getOrDefault("MaxRecords")
  valid_604289 = validateParameter(valid_604289, JInt, required = false, default = nil)
  if valid_604289 != nil:
    section.add "MaxRecords", valid_604289
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604290: Call_PostDescribeOptionGroups_604273; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604290.validator(path, query, header, formData, body)
  let scheme = call_604290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604290.url(scheme.get, call_604290.host, call_604290.base,
                         call_604290.route, valid.getOrDefault("path"))
  result = hook(call_604290, url, valid)

proc call*(call_604291: Call_PostDescribeOptionGroups_604273;
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
  var query_604292 = newJObject()
  var formData_604293 = newJObject()
  add(formData_604293, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604293, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604293, "Marker", newJString(Marker))
  add(query_604292, "Action", newJString(Action))
  add(formData_604293, "EngineName", newJString(EngineName))
  add(formData_604293, "MaxRecords", newJInt(MaxRecords))
  add(query_604292, "Version", newJString(Version))
  result = call_604291.call(nil, query_604292, nil, formData_604293, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_604273(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_604274, base: "/",
    url: url_PostDescribeOptionGroups_604275, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_604253 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOptionGroups_604255(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOptionGroups_604254(path: JsonNode; query: JsonNode;
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
  var valid_604256 = query.getOrDefault("MaxRecords")
  valid_604256 = validateParameter(valid_604256, JInt, required = false, default = nil)
  if valid_604256 != nil:
    section.add "MaxRecords", valid_604256
  var valid_604257 = query.getOrDefault("OptionGroupName")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "OptionGroupName", valid_604257
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604258 = query.getOrDefault("Action")
  valid_604258 = validateParameter(valid_604258, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604258 != nil:
    section.add "Action", valid_604258
  var valid_604259 = query.getOrDefault("Marker")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "Marker", valid_604259
  var valid_604260 = query.getOrDefault("Version")
  valid_604260 = validateParameter(valid_604260, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604260 != nil:
    section.add "Version", valid_604260
  var valid_604261 = query.getOrDefault("EngineName")
  valid_604261 = validateParameter(valid_604261, JString, required = false,
                                 default = nil)
  if valid_604261 != nil:
    section.add "EngineName", valid_604261
  var valid_604262 = query.getOrDefault("MajorEngineVersion")
  valid_604262 = validateParameter(valid_604262, JString, required = false,
                                 default = nil)
  if valid_604262 != nil:
    section.add "MajorEngineVersion", valid_604262
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604263 = header.getOrDefault("X-Amz-Date")
  valid_604263 = validateParameter(valid_604263, JString, required = false,
                                 default = nil)
  if valid_604263 != nil:
    section.add "X-Amz-Date", valid_604263
  var valid_604264 = header.getOrDefault("X-Amz-Security-Token")
  valid_604264 = validateParameter(valid_604264, JString, required = false,
                                 default = nil)
  if valid_604264 != nil:
    section.add "X-Amz-Security-Token", valid_604264
  var valid_604265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604265 = validateParameter(valid_604265, JString, required = false,
                                 default = nil)
  if valid_604265 != nil:
    section.add "X-Amz-Content-Sha256", valid_604265
  var valid_604266 = header.getOrDefault("X-Amz-Algorithm")
  valid_604266 = validateParameter(valid_604266, JString, required = false,
                                 default = nil)
  if valid_604266 != nil:
    section.add "X-Amz-Algorithm", valid_604266
  var valid_604267 = header.getOrDefault("X-Amz-Signature")
  valid_604267 = validateParameter(valid_604267, JString, required = false,
                                 default = nil)
  if valid_604267 != nil:
    section.add "X-Amz-Signature", valid_604267
  var valid_604268 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604268 = validateParameter(valid_604268, JString, required = false,
                                 default = nil)
  if valid_604268 != nil:
    section.add "X-Amz-SignedHeaders", valid_604268
  var valid_604269 = header.getOrDefault("X-Amz-Credential")
  valid_604269 = validateParameter(valid_604269, JString, required = false,
                                 default = nil)
  if valid_604269 != nil:
    section.add "X-Amz-Credential", valid_604269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604270: Call_GetDescribeOptionGroups_604253; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604270.validator(path, query, header, formData, body)
  let scheme = call_604270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604270.url(scheme.get, call_604270.host, call_604270.base,
                         call_604270.route, valid.getOrDefault("path"))
  result = hook(call_604270, url, valid)

proc call*(call_604271: Call_GetDescribeOptionGroups_604253; MaxRecords: int = 0;
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
  var query_604272 = newJObject()
  add(query_604272, "MaxRecords", newJInt(MaxRecords))
  add(query_604272, "OptionGroupName", newJString(OptionGroupName))
  add(query_604272, "Action", newJString(Action))
  add(query_604272, "Marker", newJString(Marker))
  add(query_604272, "Version", newJString(Version))
  add(query_604272, "EngineName", newJString(EngineName))
  add(query_604272, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604271.call(nil, query_604272, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_604253(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_604254, base: "/",
    url: url_GetDescribeOptionGroups_604255, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604316 = ref object of OpenApiRestCall_602417
proc url_PostDescribeOrderableDBInstanceOptions_604318(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604317(path: JsonNode;
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
  var valid_604319 = query.getOrDefault("Action")
  valid_604319 = validateParameter(valid_604319, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604319 != nil:
    section.add "Action", valid_604319
  var valid_604320 = query.getOrDefault("Version")
  valid_604320 = validateParameter(valid_604320, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604320 != nil:
    section.add "Version", valid_604320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604321 = header.getOrDefault("X-Amz-Date")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "X-Amz-Date", valid_604321
  var valid_604322 = header.getOrDefault("X-Amz-Security-Token")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "X-Amz-Security-Token", valid_604322
  var valid_604323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604323 = validateParameter(valid_604323, JString, required = false,
                                 default = nil)
  if valid_604323 != nil:
    section.add "X-Amz-Content-Sha256", valid_604323
  var valid_604324 = header.getOrDefault("X-Amz-Algorithm")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "X-Amz-Algorithm", valid_604324
  var valid_604325 = header.getOrDefault("X-Amz-Signature")
  valid_604325 = validateParameter(valid_604325, JString, required = false,
                                 default = nil)
  if valid_604325 != nil:
    section.add "X-Amz-Signature", valid_604325
  var valid_604326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604326 = validateParameter(valid_604326, JString, required = false,
                                 default = nil)
  if valid_604326 != nil:
    section.add "X-Amz-SignedHeaders", valid_604326
  var valid_604327 = header.getOrDefault("X-Amz-Credential")
  valid_604327 = validateParameter(valid_604327, JString, required = false,
                                 default = nil)
  if valid_604327 != nil:
    section.add "X-Amz-Credential", valid_604327
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
  var valid_604328 = formData.getOrDefault("Engine")
  valid_604328 = validateParameter(valid_604328, JString, required = true,
                                 default = nil)
  if valid_604328 != nil:
    section.add "Engine", valid_604328
  var valid_604329 = formData.getOrDefault("Marker")
  valid_604329 = validateParameter(valid_604329, JString, required = false,
                                 default = nil)
  if valid_604329 != nil:
    section.add "Marker", valid_604329
  var valid_604330 = formData.getOrDefault("Vpc")
  valid_604330 = validateParameter(valid_604330, JBool, required = false, default = nil)
  if valid_604330 != nil:
    section.add "Vpc", valid_604330
  var valid_604331 = formData.getOrDefault("DBInstanceClass")
  valid_604331 = validateParameter(valid_604331, JString, required = false,
                                 default = nil)
  if valid_604331 != nil:
    section.add "DBInstanceClass", valid_604331
  var valid_604332 = formData.getOrDefault("LicenseModel")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "LicenseModel", valid_604332
  var valid_604333 = formData.getOrDefault("MaxRecords")
  valid_604333 = validateParameter(valid_604333, JInt, required = false, default = nil)
  if valid_604333 != nil:
    section.add "MaxRecords", valid_604333
  var valid_604334 = formData.getOrDefault("EngineVersion")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "EngineVersion", valid_604334
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604335: Call_PostDescribeOrderableDBInstanceOptions_604316;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604335.validator(path, query, header, formData, body)
  let scheme = call_604335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604335.url(scheme.get, call_604335.host, call_604335.base,
                         call_604335.route, valid.getOrDefault("path"))
  result = hook(call_604335, url, valid)

proc call*(call_604336: Call_PostDescribeOrderableDBInstanceOptions_604316;
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
  var query_604337 = newJObject()
  var formData_604338 = newJObject()
  add(formData_604338, "Engine", newJString(Engine))
  add(formData_604338, "Marker", newJString(Marker))
  add(query_604337, "Action", newJString(Action))
  add(formData_604338, "Vpc", newJBool(Vpc))
  add(formData_604338, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604338, "LicenseModel", newJString(LicenseModel))
  add(formData_604338, "MaxRecords", newJInt(MaxRecords))
  add(formData_604338, "EngineVersion", newJString(EngineVersion))
  add(query_604337, "Version", newJString(Version))
  result = call_604336.call(nil, query_604337, nil, formData_604338, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604316(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604317, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604294 = ref object of OpenApiRestCall_602417
proc url_GetDescribeOrderableDBInstanceOptions_604296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604295(path: JsonNode;
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
  var valid_604297 = query.getOrDefault("Engine")
  valid_604297 = validateParameter(valid_604297, JString, required = true,
                                 default = nil)
  if valid_604297 != nil:
    section.add "Engine", valid_604297
  var valid_604298 = query.getOrDefault("MaxRecords")
  valid_604298 = validateParameter(valid_604298, JInt, required = false, default = nil)
  if valid_604298 != nil:
    section.add "MaxRecords", valid_604298
  var valid_604299 = query.getOrDefault("LicenseModel")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "LicenseModel", valid_604299
  var valid_604300 = query.getOrDefault("Vpc")
  valid_604300 = validateParameter(valid_604300, JBool, required = false, default = nil)
  if valid_604300 != nil:
    section.add "Vpc", valid_604300
  var valid_604301 = query.getOrDefault("DBInstanceClass")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "DBInstanceClass", valid_604301
  var valid_604302 = query.getOrDefault("Action")
  valid_604302 = validateParameter(valid_604302, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604302 != nil:
    section.add "Action", valid_604302
  var valid_604303 = query.getOrDefault("Marker")
  valid_604303 = validateParameter(valid_604303, JString, required = false,
                                 default = nil)
  if valid_604303 != nil:
    section.add "Marker", valid_604303
  var valid_604304 = query.getOrDefault("EngineVersion")
  valid_604304 = validateParameter(valid_604304, JString, required = false,
                                 default = nil)
  if valid_604304 != nil:
    section.add "EngineVersion", valid_604304
  var valid_604305 = query.getOrDefault("Version")
  valid_604305 = validateParameter(valid_604305, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604305 != nil:
    section.add "Version", valid_604305
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604306 = header.getOrDefault("X-Amz-Date")
  valid_604306 = validateParameter(valid_604306, JString, required = false,
                                 default = nil)
  if valid_604306 != nil:
    section.add "X-Amz-Date", valid_604306
  var valid_604307 = header.getOrDefault("X-Amz-Security-Token")
  valid_604307 = validateParameter(valid_604307, JString, required = false,
                                 default = nil)
  if valid_604307 != nil:
    section.add "X-Amz-Security-Token", valid_604307
  var valid_604308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604308 = validateParameter(valid_604308, JString, required = false,
                                 default = nil)
  if valid_604308 != nil:
    section.add "X-Amz-Content-Sha256", valid_604308
  var valid_604309 = header.getOrDefault("X-Amz-Algorithm")
  valid_604309 = validateParameter(valid_604309, JString, required = false,
                                 default = nil)
  if valid_604309 != nil:
    section.add "X-Amz-Algorithm", valid_604309
  var valid_604310 = header.getOrDefault("X-Amz-Signature")
  valid_604310 = validateParameter(valid_604310, JString, required = false,
                                 default = nil)
  if valid_604310 != nil:
    section.add "X-Amz-Signature", valid_604310
  var valid_604311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-SignedHeaders", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Credential")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Credential", valid_604312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604313: Call_GetDescribeOrderableDBInstanceOptions_604294;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604313.validator(path, query, header, formData, body)
  let scheme = call_604313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604313.url(scheme.get, call_604313.host, call_604313.base,
                         call_604313.route, valid.getOrDefault("path"))
  result = hook(call_604313, url, valid)

proc call*(call_604314: Call_GetDescribeOrderableDBInstanceOptions_604294;
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
  var query_604315 = newJObject()
  add(query_604315, "Engine", newJString(Engine))
  add(query_604315, "MaxRecords", newJInt(MaxRecords))
  add(query_604315, "LicenseModel", newJString(LicenseModel))
  add(query_604315, "Vpc", newJBool(Vpc))
  add(query_604315, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604315, "Action", newJString(Action))
  add(query_604315, "Marker", newJString(Marker))
  add(query_604315, "EngineVersion", newJString(EngineVersion))
  add(query_604315, "Version", newJString(Version))
  result = call_604314.call(nil, query_604315, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604294(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604295, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_604363 = ref object of OpenApiRestCall_602417
proc url_PostDescribeReservedDBInstances_604365(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstances_604364(path: JsonNode;
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
  var valid_604366 = query.getOrDefault("Action")
  valid_604366 = validateParameter(valid_604366, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604366 != nil:
    section.add "Action", valid_604366
  var valid_604367 = query.getOrDefault("Version")
  valid_604367 = validateParameter(valid_604367, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604367 != nil:
    section.add "Version", valid_604367
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604368 = header.getOrDefault("X-Amz-Date")
  valid_604368 = validateParameter(valid_604368, JString, required = false,
                                 default = nil)
  if valid_604368 != nil:
    section.add "X-Amz-Date", valid_604368
  var valid_604369 = header.getOrDefault("X-Amz-Security-Token")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "X-Amz-Security-Token", valid_604369
  var valid_604370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "X-Amz-Content-Sha256", valid_604370
  var valid_604371 = header.getOrDefault("X-Amz-Algorithm")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "X-Amz-Algorithm", valid_604371
  var valid_604372 = header.getOrDefault("X-Amz-Signature")
  valid_604372 = validateParameter(valid_604372, JString, required = false,
                                 default = nil)
  if valid_604372 != nil:
    section.add "X-Amz-Signature", valid_604372
  var valid_604373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "X-Amz-SignedHeaders", valid_604373
  var valid_604374 = header.getOrDefault("X-Amz-Credential")
  valid_604374 = validateParameter(valid_604374, JString, required = false,
                                 default = nil)
  if valid_604374 != nil:
    section.add "X-Amz-Credential", valid_604374
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
  var valid_604375 = formData.getOrDefault("OfferingType")
  valid_604375 = validateParameter(valid_604375, JString, required = false,
                                 default = nil)
  if valid_604375 != nil:
    section.add "OfferingType", valid_604375
  var valid_604376 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604376 = validateParameter(valid_604376, JString, required = false,
                                 default = nil)
  if valid_604376 != nil:
    section.add "ReservedDBInstanceId", valid_604376
  var valid_604377 = formData.getOrDefault("Marker")
  valid_604377 = validateParameter(valid_604377, JString, required = false,
                                 default = nil)
  if valid_604377 != nil:
    section.add "Marker", valid_604377
  var valid_604378 = formData.getOrDefault("MultiAZ")
  valid_604378 = validateParameter(valid_604378, JBool, required = false, default = nil)
  if valid_604378 != nil:
    section.add "MultiAZ", valid_604378
  var valid_604379 = formData.getOrDefault("Duration")
  valid_604379 = validateParameter(valid_604379, JString, required = false,
                                 default = nil)
  if valid_604379 != nil:
    section.add "Duration", valid_604379
  var valid_604380 = formData.getOrDefault("DBInstanceClass")
  valid_604380 = validateParameter(valid_604380, JString, required = false,
                                 default = nil)
  if valid_604380 != nil:
    section.add "DBInstanceClass", valid_604380
  var valid_604381 = formData.getOrDefault("ProductDescription")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "ProductDescription", valid_604381
  var valid_604382 = formData.getOrDefault("MaxRecords")
  valid_604382 = validateParameter(valid_604382, JInt, required = false, default = nil)
  if valid_604382 != nil:
    section.add "MaxRecords", valid_604382
  var valid_604383 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604384: Call_PostDescribeReservedDBInstances_604363;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604384.validator(path, query, header, formData, body)
  let scheme = call_604384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604384.url(scheme.get, call_604384.host, call_604384.base,
                         call_604384.route, valid.getOrDefault("path"))
  result = hook(call_604384, url, valid)

proc call*(call_604385: Call_PostDescribeReservedDBInstances_604363;
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
  var query_604386 = newJObject()
  var formData_604387 = newJObject()
  add(formData_604387, "OfferingType", newJString(OfferingType))
  add(formData_604387, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604387, "Marker", newJString(Marker))
  add(formData_604387, "MultiAZ", newJBool(MultiAZ))
  add(query_604386, "Action", newJString(Action))
  add(formData_604387, "Duration", newJString(Duration))
  add(formData_604387, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604387, "ProductDescription", newJString(ProductDescription))
  add(formData_604387, "MaxRecords", newJInt(MaxRecords))
  add(formData_604387, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604386, "Version", newJString(Version))
  result = call_604385.call(nil, query_604386, nil, formData_604387, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_604363(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_604364, base: "/",
    url: url_PostDescribeReservedDBInstances_604365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_604339 = ref object of OpenApiRestCall_602417
proc url_GetDescribeReservedDBInstances_604341(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstances_604340(path: JsonNode;
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
  var valid_604342 = query.getOrDefault("ProductDescription")
  valid_604342 = validateParameter(valid_604342, JString, required = false,
                                 default = nil)
  if valid_604342 != nil:
    section.add "ProductDescription", valid_604342
  var valid_604343 = query.getOrDefault("MaxRecords")
  valid_604343 = validateParameter(valid_604343, JInt, required = false, default = nil)
  if valid_604343 != nil:
    section.add "MaxRecords", valid_604343
  var valid_604344 = query.getOrDefault("OfferingType")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "OfferingType", valid_604344
  var valid_604345 = query.getOrDefault("MultiAZ")
  valid_604345 = validateParameter(valid_604345, JBool, required = false, default = nil)
  if valid_604345 != nil:
    section.add "MultiAZ", valid_604345
  var valid_604346 = query.getOrDefault("ReservedDBInstanceId")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "ReservedDBInstanceId", valid_604346
  var valid_604347 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604347
  var valid_604348 = query.getOrDefault("DBInstanceClass")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "DBInstanceClass", valid_604348
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604349 = query.getOrDefault("Action")
  valid_604349 = validateParameter(valid_604349, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604349 != nil:
    section.add "Action", valid_604349
  var valid_604350 = query.getOrDefault("Marker")
  valid_604350 = validateParameter(valid_604350, JString, required = false,
                                 default = nil)
  if valid_604350 != nil:
    section.add "Marker", valid_604350
  var valid_604351 = query.getOrDefault("Duration")
  valid_604351 = validateParameter(valid_604351, JString, required = false,
                                 default = nil)
  if valid_604351 != nil:
    section.add "Duration", valid_604351
  var valid_604352 = query.getOrDefault("Version")
  valid_604352 = validateParameter(valid_604352, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604352 != nil:
    section.add "Version", valid_604352
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604353 = header.getOrDefault("X-Amz-Date")
  valid_604353 = validateParameter(valid_604353, JString, required = false,
                                 default = nil)
  if valid_604353 != nil:
    section.add "X-Amz-Date", valid_604353
  var valid_604354 = header.getOrDefault("X-Amz-Security-Token")
  valid_604354 = validateParameter(valid_604354, JString, required = false,
                                 default = nil)
  if valid_604354 != nil:
    section.add "X-Amz-Security-Token", valid_604354
  var valid_604355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604355 = validateParameter(valid_604355, JString, required = false,
                                 default = nil)
  if valid_604355 != nil:
    section.add "X-Amz-Content-Sha256", valid_604355
  var valid_604356 = header.getOrDefault("X-Amz-Algorithm")
  valid_604356 = validateParameter(valid_604356, JString, required = false,
                                 default = nil)
  if valid_604356 != nil:
    section.add "X-Amz-Algorithm", valid_604356
  var valid_604357 = header.getOrDefault("X-Amz-Signature")
  valid_604357 = validateParameter(valid_604357, JString, required = false,
                                 default = nil)
  if valid_604357 != nil:
    section.add "X-Amz-Signature", valid_604357
  var valid_604358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-SignedHeaders", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-Credential")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-Credential", valid_604359
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604360: Call_GetDescribeReservedDBInstances_604339; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604360.validator(path, query, header, formData, body)
  let scheme = call_604360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604360.url(scheme.get, call_604360.host, call_604360.base,
                         call_604360.route, valid.getOrDefault("path"))
  result = hook(call_604360, url, valid)

proc call*(call_604361: Call_GetDescribeReservedDBInstances_604339;
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
  var query_604362 = newJObject()
  add(query_604362, "ProductDescription", newJString(ProductDescription))
  add(query_604362, "MaxRecords", newJInt(MaxRecords))
  add(query_604362, "OfferingType", newJString(OfferingType))
  add(query_604362, "MultiAZ", newJBool(MultiAZ))
  add(query_604362, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604362, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604362, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604362, "Action", newJString(Action))
  add(query_604362, "Marker", newJString(Marker))
  add(query_604362, "Duration", newJString(Duration))
  add(query_604362, "Version", newJString(Version))
  result = call_604361.call(nil, query_604362, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_604339(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_604340, base: "/",
    url: url_GetDescribeReservedDBInstances_604341,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_604411 = ref object of OpenApiRestCall_602417
proc url_PostDescribeReservedDBInstancesOfferings_604413(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeReservedDBInstancesOfferings_604412(path: JsonNode;
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
  var valid_604414 = query.getOrDefault("Action")
  valid_604414 = validateParameter(valid_604414, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604414 != nil:
    section.add "Action", valid_604414
  var valid_604415 = query.getOrDefault("Version")
  valid_604415 = validateParameter(valid_604415, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604415 != nil:
    section.add "Version", valid_604415
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604416 = header.getOrDefault("X-Amz-Date")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "X-Amz-Date", valid_604416
  var valid_604417 = header.getOrDefault("X-Amz-Security-Token")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "X-Amz-Security-Token", valid_604417
  var valid_604418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "X-Amz-Content-Sha256", valid_604418
  var valid_604419 = header.getOrDefault("X-Amz-Algorithm")
  valid_604419 = validateParameter(valid_604419, JString, required = false,
                                 default = nil)
  if valid_604419 != nil:
    section.add "X-Amz-Algorithm", valid_604419
  var valid_604420 = header.getOrDefault("X-Amz-Signature")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "X-Amz-Signature", valid_604420
  var valid_604421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604421 = validateParameter(valid_604421, JString, required = false,
                                 default = nil)
  if valid_604421 != nil:
    section.add "X-Amz-SignedHeaders", valid_604421
  var valid_604422 = header.getOrDefault("X-Amz-Credential")
  valid_604422 = validateParameter(valid_604422, JString, required = false,
                                 default = nil)
  if valid_604422 != nil:
    section.add "X-Amz-Credential", valid_604422
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
  var valid_604423 = formData.getOrDefault("OfferingType")
  valid_604423 = validateParameter(valid_604423, JString, required = false,
                                 default = nil)
  if valid_604423 != nil:
    section.add "OfferingType", valid_604423
  var valid_604424 = formData.getOrDefault("Marker")
  valid_604424 = validateParameter(valid_604424, JString, required = false,
                                 default = nil)
  if valid_604424 != nil:
    section.add "Marker", valid_604424
  var valid_604425 = formData.getOrDefault("MultiAZ")
  valid_604425 = validateParameter(valid_604425, JBool, required = false, default = nil)
  if valid_604425 != nil:
    section.add "MultiAZ", valid_604425
  var valid_604426 = formData.getOrDefault("Duration")
  valid_604426 = validateParameter(valid_604426, JString, required = false,
                                 default = nil)
  if valid_604426 != nil:
    section.add "Duration", valid_604426
  var valid_604427 = formData.getOrDefault("DBInstanceClass")
  valid_604427 = validateParameter(valid_604427, JString, required = false,
                                 default = nil)
  if valid_604427 != nil:
    section.add "DBInstanceClass", valid_604427
  var valid_604428 = formData.getOrDefault("ProductDescription")
  valid_604428 = validateParameter(valid_604428, JString, required = false,
                                 default = nil)
  if valid_604428 != nil:
    section.add "ProductDescription", valid_604428
  var valid_604429 = formData.getOrDefault("MaxRecords")
  valid_604429 = validateParameter(valid_604429, JInt, required = false, default = nil)
  if valid_604429 != nil:
    section.add "MaxRecords", valid_604429
  var valid_604430 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604430 = validateParameter(valid_604430, JString, required = false,
                                 default = nil)
  if valid_604430 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604430
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604431: Call_PostDescribeReservedDBInstancesOfferings_604411;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604431.validator(path, query, header, formData, body)
  let scheme = call_604431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604431.url(scheme.get, call_604431.host, call_604431.base,
                         call_604431.route, valid.getOrDefault("path"))
  result = hook(call_604431, url, valid)

proc call*(call_604432: Call_PostDescribeReservedDBInstancesOfferings_604411;
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
  var query_604433 = newJObject()
  var formData_604434 = newJObject()
  add(formData_604434, "OfferingType", newJString(OfferingType))
  add(formData_604434, "Marker", newJString(Marker))
  add(formData_604434, "MultiAZ", newJBool(MultiAZ))
  add(query_604433, "Action", newJString(Action))
  add(formData_604434, "Duration", newJString(Duration))
  add(formData_604434, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604434, "ProductDescription", newJString(ProductDescription))
  add(formData_604434, "MaxRecords", newJInt(MaxRecords))
  add(formData_604434, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604433, "Version", newJString(Version))
  result = call_604432.call(nil, query_604433, nil, formData_604434, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_604411(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_604412,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_604413,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_604388 = ref object of OpenApiRestCall_602417
proc url_GetDescribeReservedDBInstancesOfferings_604390(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeReservedDBInstancesOfferings_604389(path: JsonNode;
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
  var valid_604391 = query.getOrDefault("ProductDescription")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "ProductDescription", valid_604391
  var valid_604392 = query.getOrDefault("MaxRecords")
  valid_604392 = validateParameter(valid_604392, JInt, required = false, default = nil)
  if valid_604392 != nil:
    section.add "MaxRecords", valid_604392
  var valid_604393 = query.getOrDefault("OfferingType")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "OfferingType", valid_604393
  var valid_604394 = query.getOrDefault("MultiAZ")
  valid_604394 = validateParameter(valid_604394, JBool, required = false, default = nil)
  if valid_604394 != nil:
    section.add "MultiAZ", valid_604394
  var valid_604395 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604395
  var valid_604396 = query.getOrDefault("DBInstanceClass")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "DBInstanceClass", valid_604396
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604397 = query.getOrDefault("Action")
  valid_604397 = validateParameter(valid_604397, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604397 != nil:
    section.add "Action", valid_604397
  var valid_604398 = query.getOrDefault("Marker")
  valid_604398 = validateParameter(valid_604398, JString, required = false,
                                 default = nil)
  if valid_604398 != nil:
    section.add "Marker", valid_604398
  var valid_604399 = query.getOrDefault("Duration")
  valid_604399 = validateParameter(valid_604399, JString, required = false,
                                 default = nil)
  if valid_604399 != nil:
    section.add "Duration", valid_604399
  var valid_604400 = query.getOrDefault("Version")
  valid_604400 = validateParameter(valid_604400, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604400 != nil:
    section.add "Version", valid_604400
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604401 = header.getOrDefault("X-Amz-Date")
  valid_604401 = validateParameter(valid_604401, JString, required = false,
                                 default = nil)
  if valid_604401 != nil:
    section.add "X-Amz-Date", valid_604401
  var valid_604402 = header.getOrDefault("X-Amz-Security-Token")
  valid_604402 = validateParameter(valid_604402, JString, required = false,
                                 default = nil)
  if valid_604402 != nil:
    section.add "X-Amz-Security-Token", valid_604402
  var valid_604403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604403 = validateParameter(valid_604403, JString, required = false,
                                 default = nil)
  if valid_604403 != nil:
    section.add "X-Amz-Content-Sha256", valid_604403
  var valid_604404 = header.getOrDefault("X-Amz-Algorithm")
  valid_604404 = validateParameter(valid_604404, JString, required = false,
                                 default = nil)
  if valid_604404 != nil:
    section.add "X-Amz-Algorithm", valid_604404
  var valid_604405 = header.getOrDefault("X-Amz-Signature")
  valid_604405 = validateParameter(valid_604405, JString, required = false,
                                 default = nil)
  if valid_604405 != nil:
    section.add "X-Amz-Signature", valid_604405
  var valid_604406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-SignedHeaders", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Credential")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Credential", valid_604407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604408: Call_GetDescribeReservedDBInstancesOfferings_604388;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604408.validator(path, query, header, formData, body)
  let scheme = call_604408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604408.url(scheme.get, call_604408.host, call_604408.base,
                         call_604408.route, valid.getOrDefault("path"))
  result = hook(call_604408, url, valid)

proc call*(call_604409: Call_GetDescribeReservedDBInstancesOfferings_604388;
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
  var query_604410 = newJObject()
  add(query_604410, "ProductDescription", newJString(ProductDescription))
  add(query_604410, "MaxRecords", newJInt(MaxRecords))
  add(query_604410, "OfferingType", newJString(OfferingType))
  add(query_604410, "MultiAZ", newJBool(MultiAZ))
  add(query_604410, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604410, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604410, "Action", newJString(Action))
  add(query_604410, "Marker", newJString(Marker))
  add(query_604410, "Duration", newJString(Duration))
  add(query_604410, "Version", newJString(Version))
  result = call_604409.call(nil, query_604410, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_604388(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_604389, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_604390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_604454 = ref object of OpenApiRestCall_602417
proc url_PostDownloadDBLogFilePortion_604456(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDownloadDBLogFilePortion_604455(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604457 = query.getOrDefault("Action")
  valid_604457 = validateParameter(valid_604457, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604457 != nil:
    section.add "Action", valid_604457
  var valid_604458 = query.getOrDefault("Version")
  valid_604458 = validateParameter(valid_604458, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604458 != nil:
    section.add "Version", valid_604458
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604459 = header.getOrDefault("X-Amz-Date")
  valid_604459 = validateParameter(valid_604459, JString, required = false,
                                 default = nil)
  if valid_604459 != nil:
    section.add "X-Amz-Date", valid_604459
  var valid_604460 = header.getOrDefault("X-Amz-Security-Token")
  valid_604460 = validateParameter(valid_604460, JString, required = false,
                                 default = nil)
  if valid_604460 != nil:
    section.add "X-Amz-Security-Token", valid_604460
  var valid_604461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "X-Amz-Content-Sha256", valid_604461
  var valid_604462 = header.getOrDefault("X-Amz-Algorithm")
  valid_604462 = validateParameter(valid_604462, JString, required = false,
                                 default = nil)
  if valid_604462 != nil:
    section.add "X-Amz-Algorithm", valid_604462
  var valid_604463 = header.getOrDefault("X-Amz-Signature")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "X-Amz-Signature", valid_604463
  var valid_604464 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604464 = validateParameter(valid_604464, JString, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "X-Amz-SignedHeaders", valid_604464
  var valid_604465 = header.getOrDefault("X-Amz-Credential")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "X-Amz-Credential", valid_604465
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_604466 = formData.getOrDefault("NumberOfLines")
  valid_604466 = validateParameter(valid_604466, JInt, required = false, default = nil)
  if valid_604466 != nil:
    section.add "NumberOfLines", valid_604466
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604467 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604467 = validateParameter(valid_604467, JString, required = true,
                                 default = nil)
  if valid_604467 != nil:
    section.add "DBInstanceIdentifier", valid_604467
  var valid_604468 = formData.getOrDefault("Marker")
  valid_604468 = validateParameter(valid_604468, JString, required = false,
                                 default = nil)
  if valid_604468 != nil:
    section.add "Marker", valid_604468
  var valid_604469 = formData.getOrDefault("LogFileName")
  valid_604469 = validateParameter(valid_604469, JString, required = true,
                                 default = nil)
  if valid_604469 != nil:
    section.add "LogFileName", valid_604469
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604470: Call_PostDownloadDBLogFilePortion_604454; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604470.validator(path, query, header, formData, body)
  let scheme = call_604470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604470.url(scheme.get, call_604470.host, call_604470.base,
                         call_604470.route, valid.getOrDefault("path"))
  result = hook(call_604470, url, valid)

proc call*(call_604471: Call_PostDownloadDBLogFilePortion_604454;
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
  var query_604472 = newJObject()
  var formData_604473 = newJObject()
  add(formData_604473, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_604473, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604473, "Marker", newJString(Marker))
  add(query_604472, "Action", newJString(Action))
  add(formData_604473, "LogFileName", newJString(LogFileName))
  add(query_604472, "Version", newJString(Version))
  result = call_604471.call(nil, query_604472, nil, formData_604473, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_604454(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_604455, base: "/",
    url: url_PostDownloadDBLogFilePortion_604456,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_604435 = ref object of OpenApiRestCall_602417
proc url_GetDownloadDBLogFilePortion_604437(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDownloadDBLogFilePortion_604436(path: JsonNode; query: JsonNode;
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
  var valid_604438 = query.getOrDefault("NumberOfLines")
  valid_604438 = validateParameter(valid_604438, JInt, required = false, default = nil)
  if valid_604438 != nil:
    section.add "NumberOfLines", valid_604438
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_604439 = query.getOrDefault("LogFileName")
  valid_604439 = validateParameter(valid_604439, JString, required = true,
                                 default = nil)
  if valid_604439 != nil:
    section.add "LogFileName", valid_604439
  var valid_604440 = query.getOrDefault("Action")
  valid_604440 = validateParameter(valid_604440, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_604440 != nil:
    section.add "Action", valid_604440
  var valid_604441 = query.getOrDefault("Marker")
  valid_604441 = validateParameter(valid_604441, JString, required = false,
                                 default = nil)
  if valid_604441 != nil:
    section.add "Marker", valid_604441
  var valid_604442 = query.getOrDefault("Version")
  valid_604442 = validateParameter(valid_604442, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604442 != nil:
    section.add "Version", valid_604442
  var valid_604443 = query.getOrDefault("DBInstanceIdentifier")
  valid_604443 = validateParameter(valid_604443, JString, required = true,
                                 default = nil)
  if valid_604443 != nil:
    section.add "DBInstanceIdentifier", valid_604443
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604444 = header.getOrDefault("X-Amz-Date")
  valid_604444 = validateParameter(valid_604444, JString, required = false,
                                 default = nil)
  if valid_604444 != nil:
    section.add "X-Amz-Date", valid_604444
  var valid_604445 = header.getOrDefault("X-Amz-Security-Token")
  valid_604445 = validateParameter(valid_604445, JString, required = false,
                                 default = nil)
  if valid_604445 != nil:
    section.add "X-Amz-Security-Token", valid_604445
  var valid_604446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-Content-Sha256", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Algorithm")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Algorithm", valid_604447
  var valid_604448 = header.getOrDefault("X-Amz-Signature")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "X-Amz-Signature", valid_604448
  var valid_604449 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "X-Amz-SignedHeaders", valid_604449
  var valid_604450 = header.getOrDefault("X-Amz-Credential")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Credential", valid_604450
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604451: Call_GetDownloadDBLogFilePortion_604435; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604451.validator(path, query, header, formData, body)
  let scheme = call_604451.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604451.url(scheme.get, call_604451.host, call_604451.base,
                         call_604451.route, valid.getOrDefault("path"))
  result = hook(call_604451, url, valid)

proc call*(call_604452: Call_GetDownloadDBLogFilePortion_604435;
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
  var query_604453 = newJObject()
  add(query_604453, "NumberOfLines", newJInt(NumberOfLines))
  add(query_604453, "LogFileName", newJString(LogFileName))
  add(query_604453, "Action", newJString(Action))
  add(query_604453, "Marker", newJString(Marker))
  add(query_604453, "Version", newJString(Version))
  add(query_604453, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604452.call(nil, query_604453, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_604435(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_604436, base: "/",
    url: url_GetDownloadDBLogFilePortion_604437,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604490 = ref object of OpenApiRestCall_602417
proc url_PostListTagsForResource_604492(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostListTagsForResource_604491(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604493 = query.getOrDefault("Action")
  valid_604493 = validateParameter(valid_604493, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604493 != nil:
    section.add "Action", valid_604493
  var valid_604494 = query.getOrDefault("Version")
  valid_604494 = validateParameter(valid_604494, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604494 != nil:
    section.add "Version", valid_604494
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604495 = header.getOrDefault("X-Amz-Date")
  valid_604495 = validateParameter(valid_604495, JString, required = false,
                                 default = nil)
  if valid_604495 != nil:
    section.add "X-Amz-Date", valid_604495
  var valid_604496 = header.getOrDefault("X-Amz-Security-Token")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Security-Token", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-Content-Sha256", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-Algorithm")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Algorithm", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Signature")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Signature", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-SignedHeaders", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-Credential")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-Credential", valid_604501
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604502 = formData.getOrDefault("ResourceName")
  valid_604502 = validateParameter(valid_604502, JString, required = true,
                                 default = nil)
  if valid_604502 != nil:
    section.add "ResourceName", valid_604502
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604503: Call_PostListTagsForResource_604490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604503.validator(path, query, header, formData, body)
  let scheme = call_604503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604503.url(scheme.get, call_604503.host, call_604503.base,
                         call_604503.route, valid.getOrDefault("path"))
  result = hook(call_604503, url, valid)

proc call*(call_604504: Call_PostListTagsForResource_604490; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604505 = newJObject()
  var formData_604506 = newJObject()
  add(query_604505, "Action", newJString(Action))
  add(formData_604506, "ResourceName", newJString(ResourceName))
  add(query_604505, "Version", newJString(Version))
  result = call_604504.call(nil, query_604505, nil, formData_604506, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604490(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604491, base: "/",
    url: url_PostListTagsForResource_604492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604474 = ref object of OpenApiRestCall_602417
proc url_GetListTagsForResource_604476(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetListTagsForResource_604475(path: JsonNode; query: JsonNode;
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
  var valid_604477 = query.getOrDefault("ResourceName")
  valid_604477 = validateParameter(valid_604477, JString, required = true,
                                 default = nil)
  if valid_604477 != nil:
    section.add "ResourceName", valid_604477
  var valid_604478 = query.getOrDefault("Action")
  valid_604478 = validateParameter(valid_604478, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604478 != nil:
    section.add "Action", valid_604478
  var valid_604479 = query.getOrDefault("Version")
  valid_604479 = validateParameter(valid_604479, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604479 != nil:
    section.add "Version", valid_604479
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604480 = header.getOrDefault("X-Amz-Date")
  valid_604480 = validateParameter(valid_604480, JString, required = false,
                                 default = nil)
  if valid_604480 != nil:
    section.add "X-Amz-Date", valid_604480
  var valid_604481 = header.getOrDefault("X-Amz-Security-Token")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Security-Token", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Content-Sha256", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Algorithm")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Algorithm", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Signature")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Signature", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-SignedHeaders", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-Credential")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-Credential", valid_604486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604487: Call_GetListTagsForResource_604474; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604487.validator(path, query, header, formData, body)
  let scheme = call_604487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604487.url(scheme.get, call_604487.host, call_604487.base,
                         call_604487.route, valid.getOrDefault("path"))
  result = hook(call_604487, url, valid)

proc call*(call_604488: Call_GetListTagsForResource_604474; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-02-12"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604489 = newJObject()
  add(query_604489, "ResourceName", newJString(ResourceName))
  add(query_604489, "Action", newJString(Action))
  add(query_604489, "Version", newJString(Version))
  result = call_604488.call(nil, query_604489, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604474(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604475, base: "/",
    url: url_GetListTagsForResource_604476, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604540 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBInstance_604542(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBInstance_604541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604543 = query.getOrDefault("Action")
  valid_604543 = validateParameter(valid_604543, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604543 != nil:
    section.add "Action", valid_604543
  var valid_604544 = query.getOrDefault("Version")
  valid_604544 = validateParameter(valid_604544, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604544 != nil:
    section.add "Version", valid_604544
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604545 = header.getOrDefault("X-Amz-Date")
  valid_604545 = validateParameter(valid_604545, JString, required = false,
                                 default = nil)
  if valid_604545 != nil:
    section.add "X-Amz-Date", valid_604545
  var valid_604546 = header.getOrDefault("X-Amz-Security-Token")
  valid_604546 = validateParameter(valid_604546, JString, required = false,
                                 default = nil)
  if valid_604546 != nil:
    section.add "X-Amz-Security-Token", valid_604546
  var valid_604547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "X-Amz-Content-Sha256", valid_604547
  var valid_604548 = header.getOrDefault("X-Amz-Algorithm")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "X-Amz-Algorithm", valid_604548
  var valid_604549 = header.getOrDefault("X-Amz-Signature")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "X-Amz-Signature", valid_604549
  var valid_604550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-SignedHeaders", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-Credential")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-Credential", valid_604551
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
  var valid_604552 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "PreferredMaintenanceWindow", valid_604552
  var valid_604553 = formData.getOrDefault("DBSecurityGroups")
  valid_604553 = validateParameter(valid_604553, JArray, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "DBSecurityGroups", valid_604553
  var valid_604554 = formData.getOrDefault("ApplyImmediately")
  valid_604554 = validateParameter(valid_604554, JBool, required = false, default = nil)
  if valid_604554 != nil:
    section.add "ApplyImmediately", valid_604554
  var valid_604555 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604555 = validateParameter(valid_604555, JArray, required = false,
                                 default = nil)
  if valid_604555 != nil:
    section.add "VpcSecurityGroupIds", valid_604555
  var valid_604556 = formData.getOrDefault("Iops")
  valid_604556 = validateParameter(valid_604556, JInt, required = false, default = nil)
  if valid_604556 != nil:
    section.add "Iops", valid_604556
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604557 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604557 = validateParameter(valid_604557, JString, required = true,
                                 default = nil)
  if valid_604557 != nil:
    section.add "DBInstanceIdentifier", valid_604557
  var valid_604558 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604558 = validateParameter(valid_604558, JInt, required = false, default = nil)
  if valid_604558 != nil:
    section.add "BackupRetentionPeriod", valid_604558
  var valid_604559 = formData.getOrDefault("DBParameterGroupName")
  valid_604559 = validateParameter(valid_604559, JString, required = false,
                                 default = nil)
  if valid_604559 != nil:
    section.add "DBParameterGroupName", valid_604559
  var valid_604560 = formData.getOrDefault("OptionGroupName")
  valid_604560 = validateParameter(valid_604560, JString, required = false,
                                 default = nil)
  if valid_604560 != nil:
    section.add "OptionGroupName", valid_604560
  var valid_604561 = formData.getOrDefault("MasterUserPassword")
  valid_604561 = validateParameter(valid_604561, JString, required = false,
                                 default = nil)
  if valid_604561 != nil:
    section.add "MasterUserPassword", valid_604561
  var valid_604562 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604562 = validateParameter(valid_604562, JString, required = false,
                                 default = nil)
  if valid_604562 != nil:
    section.add "NewDBInstanceIdentifier", valid_604562
  var valid_604563 = formData.getOrDefault("MultiAZ")
  valid_604563 = validateParameter(valid_604563, JBool, required = false, default = nil)
  if valid_604563 != nil:
    section.add "MultiAZ", valid_604563
  var valid_604564 = formData.getOrDefault("AllocatedStorage")
  valid_604564 = validateParameter(valid_604564, JInt, required = false, default = nil)
  if valid_604564 != nil:
    section.add "AllocatedStorage", valid_604564
  var valid_604565 = formData.getOrDefault("DBInstanceClass")
  valid_604565 = validateParameter(valid_604565, JString, required = false,
                                 default = nil)
  if valid_604565 != nil:
    section.add "DBInstanceClass", valid_604565
  var valid_604566 = formData.getOrDefault("PreferredBackupWindow")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "PreferredBackupWindow", valid_604566
  var valid_604567 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604567 = validateParameter(valid_604567, JBool, required = false, default = nil)
  if valid_604567 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604567
  var valid_604568 = formData.getOrDefault("EngineVersion")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "EngineVersion", valid_604568
  var valid_604569 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_604569 = validateParameter(valid_604569, JBool, required = false, default = nil)
  if valid_604569 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604569
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604570: Call_PostModifyDBInstance_604540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604570.validator(path, query, header, formData, body)
  let scheme = call_604570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604570.url(scheme.get, call_604570.host, call_604570.base,
                         call_604570.route, valid.getOrDefault("path"))
  result = hook(call_604570, url, valid)

proc call*(call_604571: Call_PostModifyDBInstance_604540;
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
  var query_604572 = newJObject()
  var formData_604573 = newJObject()
  add(formData_604573, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_604573.add "DBSecurityGroups", DBSecurityGroups
  add(formData_604573, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_604573.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604573, "Iops", newJInt(Iops))
  add(formData_604573, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604573, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604573, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604573, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604573, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604573, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_604573, "MultiAZ", newJBool(MultiAZ))
  add(query_604572, "Action", newJString(Action))
  add(formData_604573, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_604573, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604573, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604573, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604573, "EngineVersion", newJString(EngineVersion))
  add(query_604572, "Version", newJString(Version))
  add(formData_604573, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_604571.call(nil, query_604572, nil, formData_604573, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604540(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604541, base: "/",
    url: url_PostModifyDBInstance_604542, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604507 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBInstance_604509(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBInstance_604508(path: JsonNode; query: JsonNode;
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
  var valid_604510 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "PreferredMaintenanceWindow", valid_604510
  var valid_604511 = query.getOrDefault("AllocatedStorage")
  valid_604511 = validateParameter(valid_604511, JInt, required = false, default = nil)
  if valid_604511 != nil:
    section.add "AllocatedStorage", valid_604511
  var valid_604512 = query.getOrDefault("OptionGroupName")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "OptionGroupName", valid_604512
  var valid_604513 = query.getOrDefault("DBSecurityGroups")
  valid_604513 = validateParameter(valid_604513, JArray, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "DBSecurityGroups", valid_604513
  var valid_604514 = query.getOrDefault("MasterUserPassword")
  valid_604514 = validateParameter(valid_604514, JString, required = false,
                                 default = nil)
  if valid_604514 != nil:
    section.add "MasterUserPassword", valid_604514
  var valid_604515 = query.getOrDefault("Iops")
  valid_604515 = validateParameter(valid_604515, JInt, required = false, default = nil)
  if valid_604515 != nil:
    section.add "Iops", valid_604515
  var valid_604516 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604516 = validateParameter(valid_604516, JArray, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "VpcSecurityGroupIds", valid_604516
  var valid_604517 = query.getOrDefault("MultiAZ")
  valid_604517 = validateParameter(valid_604517, JBool, required = false, default = nil)
  if valid_604517 != nil:
    section.add "MultiAZ", valid_604517
  var valid_604518 = query.getOrDefault("BackupRetentionPeriod")
  valid_604518 = validateParameter(valid_604518, JInt, required = false, default = nil)
  if valid_604518 != nil:
    section.add "BackupRetentionPeriod", valid_604518
  var valid_604519 = query.getOrDefault("DBParameterGroupName")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "DBParameterGroupName", valid_604519
  var valid_604520 = query.getOrDefault("DBInstanceClass")
  valid_604520 = validateParameter(valid_604520, JString, required = false,
                                 default = nil)
  if valid_604520 != nil:
    section.add "DBInstanceClass", valid_604520
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604521 = query.getOrDefault("Action")
  valid_604521 = validateParameter(valid_604521, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604521 != nil:
    section.add "Action", valid_604521
  var valid_604522 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_604522 = validateParameter(valid_604522, JBool, required = false, default = nil)
  if valid_604522 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604522
  var valid_604523 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604523 = validateParameter(valid_604523, JString, required = false,
                                 default = nil)
  if valid_604523 != nil:
    section.add "NewDBInstanceIdentifier", valid_604523
  var valid_604524 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604524 = validateParameter(valid_604524, JBool, required = false, default = nil)
  if valid_604524 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604524
  var valid_604525 = query.getOrDefault("EngineVersion")
  valid_604525 = validateParameter(valid_604525, JString, required = false,
                                 default = nil)
  if valid_604525 != nil:
    section.add "EngineVersion", valid_604525
  var valid_604526 = query.getOrDefault("PreferredBackupWindow")
  valid_604526 = validateParameter(valid_604526, JString, required = false,
                                 default = nil)
  if valid_604526 != nil:
    section.add "PreferredBackupWindow", valid_604526
  var valid_604527 = query.getOrDefault("Version")
  valid_604527 = validateParameter(valid_604527, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604527 != nil:
    section.add "Version", valid_604527
  var valid_604528 = query.getOrDefault("DBInstanceIdentifier")
  valid_604528 = validateParameter(valid_604528, JString, required = true,
                                 default = nil)
  if valid_604528 != nil:
    section.add "DBInstanceIdentifier", valid_604528
  var valid_604529 = query.getOrDefault("ApplyImmediately")
  valid_604529 = validateParameter(valid_604529, JBool, required = false, default = nil)
  if valid_604529 != nil:
    section.add "ApplyImmediately", valid_604529
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604530 = header.getOrDefault("X-Amz-Date")
  valid_604530 = validateParameter(valid_604530, JString, required = false,
                                 default = nil)
  if valid_604530 != nil:
    section.add "X-Amz-Date", valid_604530
  var valid_604531 = header.getOrDefault("X-Amz-Security-Token")
  valid_604531 = validateParameter(valid_604531, JString, required = false,
                                 default = nil)
  if valid_604531 != nil:
    section.add "X-Amz-Security-Token", valid_604531
  var valid_604532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604532 = validateParameter(valid_604532, JString, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "X-Amz-Content-Sha256", valid_604532
  var valid_604533 = header.getOrDefault("X-Amz-Algorithm")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-Algorithm", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-Signature")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-Signature", valid_604534
  var valid_604535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-SignedHeaders", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-Credential")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-Credential", valid_604536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604537: Call_GetModifyDBInstance_604507; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604537.validator(path, query, header, formData, body)
  let scheme = call_604537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604537.url(scheme.get, call_604537.host, call_604537.base,
                         call_604537.route, valid.getOrDefault("path"))
  result = hook(call_604537, url, valid)

proc call*(call_604538: Call_GetModifyDBInstance_604507;
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
  var query_604539 = newJObject()
  add(query_604539, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604539, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_604539, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_604539.add "DBSecurityGroups", DBSecurityGroups
  add(query_604539, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_604539, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_604539.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_604539, "MultiAZ", newJBool(MultiAZ))
  add(query_604539, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604539, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604539, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604539, "Action", newJString(Action))
  add(query_604539, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_604539, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604539, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604539, "EngineVersion", newJString(EngineVersion))
  add(query_604539, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604539, "Version", newJString(Version))
  add(query_604539, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604539, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604538.call(nil, query_604539, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604507(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604508, base: "/",
    url: url_GetModifyDBInstance_604509, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_604591 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBParameterGroup_604593(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBParameterGroup_604592(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604594 = query.getOrDefault("Action")
  valid_604594 = validateParameter(valid_604594, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604594 != nil:
    section.add "Action", valid_604594
  var valid_604595 = query.getOrDefault("Version")
  valid_604595 = validateParameter(valid_604595, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604595 != nil:
    section.add "Version", valid_604595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604596 = header.getOrDefault("X-Amz-Date")
  valid_604596 = validateParameter(valid_604596, JString, required = false,
                                 default = nil)
  if valid_604596 != nil:
    section.add "X-Amz-Date", valid_604596
  var valid_604597 = header.getOrDefault("X-Amz-Security-Token")
  valid_604597 = validateParameter(valid_604597, JString, required = false,
                                 default = nil)
  if valid_604597 != nil:
    section.add "X-Amz-Security-Token", valid_604597
  var valid_604598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604598 = validateParameter(valid_604598, JString, required = false,
                                 default = nil)
  if valid_604598 != nil:
    section.add "X-Amz-Content-Sha256", valid_604598
  var valid_604599 = header.getOrDefault("X-Amz-Algorithm")
  valid_604599 = validateParameter(valid_604599, JString, required = false,
                                 default = nil)
  if valid_604599 != nil:
    section.add "X-Amz-Algorithm", valid_604599
  var valid_604600 = header.getOrDefault("X-Amz-Signature")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "X-Amz-Signature", valid_604600
  var valid_604601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604601 = validateParameter(valid_604601, JString, required = false,
                                 default = nil)
  if valid_604601 != nil:
    section.add "X-Amz-SignedHeaders", valid_604601
  var valid_604602 = header.getOrDefault("X-Amz-Credential")
  valid_604602 = validateParameter(valid_604602, JString, required = false,
                                 default = nil)
  if valid_604602 != nil:
    section.add "X-Amz-Credential", valid_604602
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604603 = formData.getOrDefault("DBParameterGroupName")
  valid_604603 = validateParameter(valid_604603, JString, required = true,
                                 default = nil)
  if valid_604603 != nil:
    section.add "DBParameterGroupName", valid_604603
  var valid_604604 = formData.getOrDefault("Parameters")
  valid_604604 = validateParameter(valid_604604, JArray, required = true, default = nil)
  if valid_604604 != nil:
    section.add "Parameters", valid_604604
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604605: Call_PostModifyDBParameterGroup_604591; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604605.validator(path, query, header, formData, body)
  let scheme = call_604605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604605.url(scheme.get, call_604605.host, call_604605.base,
                         call_604605.route, valid.getOrDefault("path"))
  result = hook(call_604605, url, valid)

proc call*(call_604606: Call_PostModifyDBParameterGroup_604591;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604607 = newJObject()
  var formData_604608 = newJObject()
  add(formData_604608, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604608.add "Parameters", Parameters
  add(query_604607, "Action", newJString(Action))
  add(query_604607, "Version", newJString(Version))
  result = call_604606.call(nil, query_604607, nil, formData_604608, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_604591(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_604592, base: "/",
    url: url_PostModifyDBParameterGroup_604593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_604574 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBParameterGroup_604576(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBParameterGroup_604575(path: JsonNode; query: JsonNode;
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
  var valid_604577 = query.getOrDefault("DBParameterGroupName")
  valid_604577 = validateParameter(valid_604577, JString, required = true,
                                 default = nil)
  if valid_604577 != nil:
    section.add "DBParameterGroupName", valid_604577
  var valid_604578 = query.getOrDefault("Parameters")
  valid_604578 = validateParameter(valid_604578, JArray, required = true, default = nil)
  if valid_604578 != nil:
    section.add "Parameters", valid_604578
  var valid_604579 = query.getOrDefault("Action")
  valid_604579 = validateParameter(valid_604579, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604579 != nil:
    section.add "Action", valid_604579
  var valid_604580 = query.getOrDefault("Version")
  valid_604580 = validateParameter(valid_604580, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604580 != nil:
    section.add "Version", valid_604580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604581 = header.getOrDefault("X-Amz-Date")
  valid_604581 = validateParameter(valid_604581, JString, required = false,
                                 default = nil)
  if valid_604581 != nil:
    section.add "X-Amz-Date", valid_604581
  var valid_604582 = header.getOrDefault("X-Amz-Security-Token")
  valid_604582 = validateParameter(valid_604582, JString, required = false,
                                 default = nil)
  if valid_604582 != nil:
    section.add "X-Amz-Security-Token", valid_604582
  var valid_604583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604583 = validateParameter(valid_604583, JString, required = false,
                                 default = nil)
  if valid_604583 != nil:
    section.add "X-Amz-Content-Sha256", valid_604583
  var valid_604584 = header.getOrDefault("X-Amz-Algorithm")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-Algorithm", valid_604584
  var valid_604585 = header.getOrDefault("X-Amz-Signature")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Signature", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-SignedHeaders", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Credential")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Credential", valid_604587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604588: Call_GetModifyDBParameterGroup_604574; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604588.validator(path, query, header, formData, body)
  let scheme = call_604588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604588.url(scheme.get, call_604588.host, call_604588.base,
                         call_604588.route, valid.getOrDefault("path"))
  result = hook(call_604588, url, valid)

proc call*(call_604589: Call_GetModifyDBParameterGroup_604574;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604590 = newJObject()
  add(query_604590, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604590.add "Parameters", Parameters
  add(query_604590, "Action", newJString(Action))
  add(query_604590, "Version", newJString(Version))
  result = call_604589.call(nil, query_604590, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_604574(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_604575, base: "/",
    url: url_GetModifyDBParameterGroup_604576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604627 = ref object of OpenApiRestCall_602417
proc url_PostModifyDBSubnetGroup_604629(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyDBSubnetGroup_604628(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604630 = query.getOrDefault("Action")
  valid_604630 = validateParameter(valid_604630, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604630 != nil:
    section.add "Action", valid_604630
  var valid_604631 = query.getOrDefault("Version")
  valid_604631 = validateParameter(valid_604631, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604631 != nil:
    section.add "Version", valid_604631
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604632 = header.getOrDefault("X-Amz-Date")
  valid_604632 = validateParameter(valid_604632, JString, required = false,
                                 default = nil)
  if valid_604632 != nil:
    section.add "X-Amz-Date", valid_604632
  var valid_604633 = header.getOrDefault("X-Amz-Security-Token")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "X-Amz-Security-Token", valid_604633
  var valid_604634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604634 = validateParameter(valid_604634, JString, required = false,
                                 default = nil)
  if valid_604634 != nil:
    section.add "X-Amz-Content-Sha256", valid_604634
  var valid_604635 = header.getOrDefault("X-Amz-Algorithm")
  valid_604635 = validateParameter(valid_604635, JString, required = false,
                                 default = nil)
  if valid_604635 != nil:
    section.add "X-Amz-Algorithm", valid_604635
  var valid_604636 = header.getOrDefault("X-Amz-Signature")
  valid_604636 = validateParameter(valid_604636, JString, required = false,
                                 default = nil)
  if valid_604636 != nil:
    section.add "X-Amz-Signature", valid_604636
  var valid_604637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604637 = validateParameter(valid_604637, JString, required = false,
                                 default = nil)
  if valid_604637 != nil:
    section.add "X-Amz-SignedHeaders", valid_604637
  var valid_604638 = header.getOrDefault("X-Amz-Credential")
  valid_604638 = validateParameter(valid_604638, JString, required = false,
                                 default = nil)
  if valid_604638 != nil:
    section.add "X-Amz-Credential", valid_604638
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_604639 = formData.getOrDefault("DBSubnetGroupName")
  valid_604639 = validateParameter(valid_604639, JString, required = true,
                                 default = nil)
  if valid_604639 != nil:
    section.add "DBSubnetGroupName", valid_604639
  var valid_604640 = formData.getOrDefault("SubnetIds")
  valid_604640 = validateParameter(valid_604640, JArray, required = true, default = nil)
  if valid_604640 != nil:
    section.add "SubnetIds", valid_604640
  var valid_604641 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604641 = validateParameter(valid_604641, JString, required = false,
                                 default = nil)
  if valid_604641 != nil:
    section.add "DBSubnetGroupDescription", valid_604641
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604642: Call_PostModifyDBSubnetGroup_604627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604642.validator(path, query, header, formData, body)
  let scheme = call_604642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604642.url(scheme.get, call_604642.host, call_604642.base,
                         call_604642.route, valid.getOrDefault("path"))
  result = hook(call_604642, url, valid)

proc call*(call_604643: Call_PostModifyDBSubnetGroup_604627;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604644 = newJObject()
  var formData_604645 = newJObject()
  add(formData_604645, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604645.add "SubnetIds", SubnetIds
  add(query_604644, "Action", newJString(Action))
  add(formData_604645, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604644, "Version", newJString(Version))
  result = call_604643.call(nil, query_604644, nil, formData_604645, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604627(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604628, base: "/",
    url: url_PostModifyDBSubnetGroup_604629, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604609 = ref object of OpenApiRestCall_602417
proc url_GetModifyDBSubnetGroup_604611(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyDBSubnetGroup_604610(path: JsonNode; query: JsonNode;
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
  var valid_604612 = query.getOrDefault("Action")
  valid_604612 = validateParameter(valid_604612, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604612 != nil:
    section.add "Action", valid_604612
  var valid_604613 = query.getOrDefault("DBSubnetGroupName")
  valid_604613 = validateParameter(valid_604613, JString, required = true,
                                 default = nil)
  if valid_604613 != nil:
    section.add "DBSubnetGroupName", valid_604613
  var valid_604614 = query.getOrDefault("SubnetIds")
  valid_604614 = validateParameter(valid_604614, JArray, required = true, default = nil)
  if valid_604614 != nil:
    section.add "SubnetIds", valid_604614
  var valid_604615 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604615 = validateParameter(valid_604615, JString, required = false,
                                 default = nil)
  if valid_604615 != nil:
    section.add "DBSubnetGroupDescription", valid_604615
  var valid_604616 = query.getOrDefault("Version")
  valid_604616 = validateParameter(valid_604616, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604616 != nil:
    section.add "Version", valid_604616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604617 = header.getOrDefault("X-Amz-Date")
  valid_604617 = validateParameter(valid_604617, JString, required = false,
                                 default = nil)
  if valid_604617 != nil:
    section.add "X-Amz-Date", valid_604617
  var valid_604618 = header.getOrDefault("X-Amz-Security-Token")
  valid_604618 = validateParameter(valid_604618, JString, required = false,
                                 default = nil)
  if valid_604618 != nil:
    section.add "X-Amz-Security-Token", valid_604618
  var valid_604619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604619 = validateParameter(valid_604619, JString, required = false,
                                 default = nil)
  if valid_604619 != nil:
    section.add "X-Amz-Content-Sha256", valid_604619
  var valid_604620 = header.getOrDefault("X-Amz-Algorithm")
  valid_604620 = validateParameter(valid_604620, JString, required = false,
                                 default = nil)
  if valid_604620 != nil:
    section.add "X-Amz-Algorithm", valid_604620
  var valid_604621 = header.getOrDefault("X-Amz-Signature")
  valid_604621 = validateParameter(valid_604621, JString, required = false,
                                 default = nil)
  if valid_604621 != nil:
    section.add "X-Amz-Signature", valid_604621
  var valid_604622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-SignedHeaders", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Credential")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Credential", valid_604623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604624: Call_GetModifyDBSubnetGroup_604609; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604624.validator(path, query, header, formData, body)
  let scheme = call_604624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604624.url(scheme.get, call_604624.host, call_604624.base,
                         call_604624.route, valid.getOrDefault("path"))
  result = hook(call_604624, url, valid)

proc call*(call_604625: Call_GetModifyDBSubnetGroup_604609;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-02-12"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604626 = newJObject()
  add(query_604626, "Action", newJString(Action))
  add(query_604626, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604626.add "SubnetIds", SubnetIds
  add(query_604626, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604626, "Version", newJString(Version))
  result = call_604625.call(nil, query_604626, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604609(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604610, base: "/",
    url: url_GetModifyDBSubnetGroup_604611, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_604666 = ref object of OpenApiRestCall_602417
proc url_PostModifyEventSubscription_604668(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyEventSubscription_604667(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604669 = query.getOrDefault("Action")
  valid_604669 = validateParameter(valid_604669, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604669 != nil:
    section.add "Action", valid_604669
  var valid_604670 = query.getOrDefault("Version")
  valid_604670 = validateParameter(valid_604670, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604670 != nil:
    section.add "Version", valid_604670
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604671 = header.getOrDefault("X-Amz-Date")
  valid_604671 = validateParameter(valid_604671, JString, required = false,
                                 default = nil)
  if valid_604671 != nil:
    section.add "X-Amz-Date", valid_604671
  var valid_604672 = header.getOrDefault("X-Amz-Security-Token")
  valid_604672 = validateParameter(valid_604672, JString, required = false,
                                 default = nil)
  if valid_604672 != nil:
    section.add "X-Amz-Security-Token", valid_604672
  var valid_604673 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604673 = validateParameter(valid_604673, JString, required = false,
                                 default = nil)
  if valid_604673 != nil:
    section.add "X-Amz-Content-Sha256", valid_604673
  var valid_604674 = header.getOrDefault("X-Amz-Algorithm")
  valid_604674 = validateParameter(valid_604674, JString, required = false,
                                 default = nil)
  if valid_604674 != nil:
    section.add "X-Amz-Algorithm", valid_604674
  var valid_604675 = header.getOrDefault("X-Amz-Signature")
  valid_604675 = validateParameter(valid_604675, JString, required = false,
                                 default = nil)
  if valid_604675 != nil:
    section.add "X-Amz-Signature", valid_604675
  var valid_604676 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604676 = validateParameter(valid_604676, JString, required = false,
                                 default = nil)
  if valid_604676 != nil:
    section.add "X-Amz-SignedHeaders", valid_604676
  var valid_604677 = header.getOrDefault("X-Amz-Credential")
  valid_604677 = validateParameter(valid_604677, JString, required = false,
                                 default = nil)
  if valid_604677 != nil:
    section.add "X-Amz-Credential", valid_604677
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_604678 = formData.getOrDefault("Enabled")
  valid_604678 = validateParameter(valid_604678, JBool, required = false, default = nil)
  if valid_604678 != nil:
    section.add "Enabled", valid_604678
  var valid_604679 = formData.getOrDefault("EventCategories")
  valid_604679 = validateParameter(valid_604679, JArray, required = false,
                                 default = nil)
  if valid_604679 != nil:
    section.add "EventCategories", valid_604679
  var valid_604680 = formData.getOrDefault("SnsTopicArn")
  valid_604680 = validateParameter(valid_604680, JString, required = false,
                                 default = nil)
  if valid_604680 != nil:
    section.add "SnsTopicArn", valid_604680
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_604681 = formData.getOrDefault("SubscriptionName")
  valid_604681 = validateParameter(valid_604681, JString, required = true,
                                 default = nil)
  if valid_604681 != nil:
    section.add "SubscriptionName", valid_604681
  var valid_604682 = formData.getOrDefault("SourceType")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "SourceType", valid_604682
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604683: Call_PostModifyEventSubscription_604666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604683.validator(path, query, header, formData, body)
  let scheme = call_604683.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604683.url(scheme.get, call_604683.host, call_604683.base,
                         call_604683.route, valid.getOrDefault("path"))
  result = hook(call_604683, url, valid)

proc call*(call_604684: Call_PostModifyEventSubscription_604666;
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
  var query_604685 = newJObject()
  var formData_604686 = newJObject()
  add(formData_604686, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_604686.add "EventCategories", EventCategories
  add(formData_604686, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_604686, "SubscriptionName", newJString(SubscriptionName))
  add(query_604685, "Action", newJString(Action))
  add(query_604685, "Version", newJString(Version))
  add(formData_604686, "SourceType", newJString(SourceType))
  result = call_604684.call(nil, query_604685, nil, formData_604686, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_604666(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_604667, base: "/",
    url: url_PostModifyEventSubscription_604668,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_604646 = ref object of OpenApiRestCall_602417
proc url_GetModifyEventSubscription_604648(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyEventSubscription_604647(path: JsonNode; query: JsonNode;
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
  var valid_604649 = query.getOrDefault("SourceType")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "SourceType", valid_604649
  var valid_604650 = query.getOrDefault("Enabled")
  valid_604650 = validateParameter(valid_604650, JBool, required = false, default = nil)
  if valid_604650 != nil:
    section.add "Enabled", valid_604650
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604651 = query.getOrDefault("Action")
  valid_604651 = validateParameter(valid_604651, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604651 != nil:
    section.add "Action", valid_604651
  var valid_604652 = query.getOrDefault("SnsTopicArn")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "SnsTopicArn", valid_604652
  var valid_604653 = query.getOrDefault("EventCategories")
  valid_604653 = validateParameter(valid_604653, JArray, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "EventCategories", valid_604653
  var valid_604654 = query.getOrDefault("SubscriptionName")
  valid_604654 = validateParameter(valid_604654, JString, required = true,
                                 default = nil)
  if valid_604654 != nil:
    section.add "SubscriptionName", valid_604654
  var valid_604655 = query.getOrDefault("Version")
  valid_604655 = validateParameter(valid_604655, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604655 != nil:
    section.add "Version", valid_604655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604656 = header.getOrDefault("X-Amz-Date")
  valid_604656 = validateParameter(valid_604656, JString, required = false,
                                 default = nil)
  if valid_604656 != nil:
    section.add "X-Amz-Date", valid_604656
  var valid_604657 = header.getOrDefault("X-Amz-Security-Token")
  valid_604657 = validateParameter(valid_604657, JString, required = false,
                                 default = nil)
  if valid_604657 != nil:
    section.add "X-Amz-Security-Token", valid_604657
  var valid_604658 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604658 = validateParameter(valid_604658, JString, required = false,
                                 default = nil)
  if valid_604658 != nil:
    section.add "X-Amz-Content-Sha256", valid_604658
  var valid_604659 = header.getOrDefault("X-Amz-Algorithm")
  valid_604659 = validateParameter(valid_604659, JString, required = false,
                                 default = nil)
  if valid_604659 != nil:
    section.add "X-Amz-Algorithm", valid_604659
  var valid_604660 = header.getOrDefault("X-Amz-Signature")
  valid_604660 = validateParameter(valid_604660, JString, required = false,
                                 default = nil)
  if valid_604660 != nil:
    section.add "X-Amz-Signature", valid_604660
  var valid_604661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604661 = validateParameter(valid_604661, JString, required = false,
                                 default = nil)
  if valid_604661 != nil:
    section.add "X-Amz-SignedHeaders", valid_604661
  var valid_604662 = header.getOrDefault("X-Amz-Credential")
  valid_604662 = validateParameter(valid_604662, JString, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "X-Amz-Credential", valid_604662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604663: Call_GetModifyEventSubscription_604646; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604663.validator(path, query, header, formData, body)
  let scheme = call_604663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604663.url(scheme.get, call_604663.host, call_604663.base,
                         call_604663.route, valid.getOrDefault("path"))
  result = hook(call_604663, url, valid)

proc call*(call_604664: Call_GetModifyEventSubscription_604646;
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
  var query_604665 = newJObject()
  add(query_604665, "SourceType", newJString(SourceType))
  add(query_604665, "Enabled", newJBool(Enabled))
  add(query_604665, "Action", newJString(Action))
  add(query_604665, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_604665.add "EventCategories", EventCategories
  add(query_604665, "SubscriptionName", newJString(SubscriptionName))
  add(query_604665, "Version", newJString(Version))
  result = call_604664.call(nil, query_604665, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_604646(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_604647, base: "/",
    url: url_GetModifyEventSubscription_604648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_604706 = ref object of OpenApiRestCall_602417
proc url_PostModifyOptionGroup_604708(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostModifyOptionGroup_604707(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604709 = query.getOrDefault("Action")
  valid_604709 = validateParameter(valid_604709, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604709 != nil:
    section.add "Action", valid_604709
  var valid_604710 = query.getOrDefault("Version")
  valid_604710 = validateParameter(valid_604710, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604710 != nil:
    section.add "Version", valid_604710
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604711 = header.getOrDefault("X-Amz-Date")
  valid_604711 = validateParameter(valid_604711, JString, required = false,
                                 default = nil)
  if valid_604711 != nil:
    section.add "X-Amz-Date", valid_604711
  var valid_604712 = header.getOrDefault("X-Amz-Security-Token")
  valid_604712 = validateParameter(valid_604712, JString, required = false,
                                 default = nil)
  if valid_604712 != nil:
    section.add "X-Amz-Security-Token", valid_604712
  var valid_604713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604713 = validateParameter(valid_604713, JString, required = false,
                                 default = nil)
  if valid_604713 != nil:
    section.add "X-Amz-Content-Sha256", valid_604713
  var valid_604714 = header.getOrDefault("X-Amz-Algorithm")
  valid_604714 = validateParameter(valid_604714, JString, required = false,
                                 default = nil)
  if valid_604714 != nil:
    section.add "X-Amz-Algorithm", valid_604714
  var valid_604715 = header.getOrDefault("X-Amz-Signature")
  valid_604715 = validateParameter(valid_604715, JString, required = false,
                                 default = nil)
  if valid_604715 != nil:
    section.add "X-Amz-Signature", valid_604715
  var valid_604716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604716 = validateParameter(valid_604716, JString, required = false,
                                 default = nil)
  if valid_604716 != nil:
    section.add "X-Amz-SignedHeaders", valid_604716
  var valid_604717 = header.getOrDefault("X-Amz-Credential")
  valid_604717 = validateParameter(valid_604717, JString, required = false,
                                 default = nil)
  if valid_604717 != nil:
    section.add "X-Amz-Credential", valid_604717
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_604718 = formData.getOrDefault("OptionsToRemove")
  valid_604718 = validateParameter(valid_604718, JArray, required = false,
                                 default = nil)
  if valid_604718 != nil:
    section.add "OptionsToRemove", valid_604718
  var valid_604719 = formData.getOrDefault("ApplyImmediately")
  valid_604719 = validateParameter(valid_604719, JBool, required = false, default = nil)
  if valid_604719 != nil:
    section.add "ApplyImmediately", valid_604719
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_604720 = formData.getOrDefault("OptionGroupName")
  valid_604720 = validateParameter(valid_604720, JString, required = true,
                                 default = nil)
  if valid_604720 != nil:
    section.add "OptionGroupName", valid_604720
  var valid_604721 = formData.getOrDefault("OptionsToInclude")
  valid_604721 = validateParameter(valid_604721, JArray, required = false,
                                 default = nil)
  if valid_604721 != nil:
    section.add "OptionsToInclude", valid_604721
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604722: Call_PostModifyOptionGroup_604706; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604722.validator(path, query, header, formData, body)
  let scheme = call_604722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604722.url(scheme.get, call_604722.host, call_604722.base,
                         call_604722.route, valid.getOrDefault("path"))
  result = hook(call_604722, url, valid)

proc call*(call_604723: Call_PostModifyOptionGroup_604706; OptionGroupName: string;
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
  var query_604724 = newJObject()
  var formData_604725 = newJObject()
  if OptionsToRemove != nil:
    formData_604725.add "OptionsToRemove", OptionsToRemove
  add(formData_604725, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604725, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_604725.add "OptionsToInclude", OptionsToInclude
  add(query_604724, "Action", newJString(Action))
  add(query_604724, "Version", newJString(Version))
  result = call_604723.call(nil, query_604724, nil, formData_604725, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_604706(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_604707, base: "/",
    url: url_PostModifyOptionGroup_604708, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_604687 = ref object of OpenApiRestCall_602417
proc url_GetModifyOptionGroup_604689(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetModifyOptionGroup_604688(path: JsonNode; query: JsonNode;
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
  var valid_604690 = query.getOrDefault("OptionGroupName")
  valid_604690 = validateParameter(valid_604690, JString, required = true,
                                 default = nil)
  if valid_604690 != nil:
    section.add "OptionGroupName", valid_604690
  var valid_604691 = query.getOrDefault("OptionsToRemove")
  valid_604691 = validateParameter(valid_604691, JArray, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "OptionsToRemove", valid_604691
  var valid_604692 = query.getOrDefault("Action")
  valid_604692 = validateParameter(valid_604692, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604692 != nil:
    section.add "Action", valid_604692
  var valid_604693 = query.getOrDefault("Version")
  valid_604693 = validateParameter(valid_604693, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604693 != nil:
    section.add "Version", valid_604693
  var valid_604694 = query.getOrDefault("ApplyImmediately")
  valid_604694 = validateParameter(valid_604694, JBool, required = false, default = nil)
  if valid_604694 != nil:
    section.add "ApplyImmediately", valid_604694
  var valid_604695 = query.getOrDefault("OptionsToInclude")
  valid_604695 = validateParameter(valid_604695, JArray, required = false,
                                 default = nil)
  if valid_604695 != nil:
    section.add "OptionsToInclude", valid_604695
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604696 = header.getOrDefault("X-Amz-Date")
  valid_604696 = validateParameter(valid_604696, JString, required = false,
                                 default = nil)
  if valid_604696 != nil:
    section.add "X-Amz-Date", valid_604696
  var valid_604697 = header.getOrDefault("X-Amz-Security-Token")
  valid_604697 = validateParameter(valid_604697, JString, required = false,
                                 default = nil)
  if valid_604697 != nil:
    section.add "X-Amz-Security-Token", valid_604697
  var valid_604698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604698 = validateParameter(valid_604698, JString, required = false,
                                 default = nil)
  if valid_604698 != nil:
    section.add "X-Amz-Content-Sha256", valid_604698
  var valid_604699 = header.getOrDefault("X-Amz-Algorithm")
  valid_604699 = validateParameter(valid_604699, JString, required = false,
                                 default = nil)
  if valid_604699 != nil:
    section.add "X-Amz-Algorithm", valid_604699
  var valid_604700 = header.getOrDefault("X-Amz-Signature")
  valid_604700 = validateParameter(valid_604700, JString, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "X-Amz-Signature", valid_604700
  var valid_604701 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604701 = validateParameter(valid_604701, JString, required = false,
                                 default = nil)
  if valid_604701 != nil:
    section.add "X-Amz-SignedHeaders", valid_604701
  var valid_604702 = header.getOrDefault("X-Amz-Credential")
  valid_604702 = validateParameter(valid_604702, JString, required = false,
                                 default = nil)
  if valid_604702 != nil:
    section.add "X-Amz-Credential", valid_604702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604703: Call_GetModifyOptionGroup_604687; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604703.validator(path, query, header, formData, body)
  let scheme = call_604703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604703.url(scheme.get, call_604703.host, call_604703.base,
                         call_604703.route, valid.getOrDefault("path"))
  result = hook(call_604703, url, valid)

proc call*(call_604704: Call_GetModifyOptionGroup_604687; OptionGroupName: string;
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
  var query_604705 = newJObject()
  add(query_604705, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_604705.add "OptionsToRemove", OptionsToRemove
  add(query_604705, "Action", newJString(Action))
  add(query_604705, "Version", newJString(Version))
  add(query_604705, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_604705.add "OptionsToInclude", OptionsToInclude
  result = call_604704.call(nil, query_604705, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_604687(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_604688, base: "/",
    url: url_GetModifyOptionGroup_604689, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_604744 = ref object of OpenApiRestCall_602417
proc url_PostPromoteReadReplica_604746(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPromoteReadReplica_604745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604747 = query.getOrDefault("Action")
  valid_604747 = validateParameter(valid_604747, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604747 != nil:
    section.add "Action", valid_604747
  var valid_604748 = query.getOrDefault("Version")
  valid_604748 = validateParameter(valid_604748, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604748 != nil:
    section.add "Version", valid_604748
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604749 = header.getOrDefault("X-Amz-Date")
  valid_604749 = validateParameter(valid_604749, JString, required = false,
                                 default = nil)
  if valid_604749 != nil:
    section.add "X-Amz-Date", valid_604749
  var valid_604750 = header.getOrDefault("X-Amz-Security-Token")
  valid_604750 = validateParameter(valid_604750, JString, required = false,
                                 default = nil)
  if valid_604750 != nil:
    section.add "X-Amz-Security-Token", valid_604750
  var valid_604751 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604751 = validateParameter(valid_604751, JString, required = false,
                                 default = nil)
  if valid_604751 != nil:
    section.add "X-Amz-Content-Sha256", valid_604751
  var valid_604752 = header.getOrDefault("X-Amz-Algorithm")
  valid_604752 = validateParameter(valid_604752, JString, required = false,
                                 default = nil)
  if valid_604752 != nil:
    section.add "X-Amz-Algorithm", valid_604752
  var valid_604753 = header.getOrDefault("X-Amz-Signature")
  valid_604753 = validateParameter(valid_604753, JString, required = false,
                                 default = nil)
  if valid_604753 != nil:
    section.add "X-Amz-Signature", valid_604753
  var valid_604754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604754 = validateParameter(valid_604754, JString, required = false,
                                 default = nil)
  if valid_604754 != nil:
    section.add "X-Amz-SignedHeaders", valid_604754
  var valid_604755 = header.getOrDefault("X-Amz-Credential")
  valid_604755 = validateParameter(valid_604755, JString, required = false,
                                 default = nil)
  if valid_604755 != nil:
    section.add "X-Amz-Credential", valid_604755
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604756 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604756 = validateParameter(valid_604756, JString, required = true,
                                 default = nil)
  if valid_604756 != nil:
    section.add "DBInstanceIdentifier", valid_604756
  var valid_604757 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604757 = validateParameter(valid_604757, JInt, required = false, default = nil)
  if valid_604757 != nil:
    section.add "BackupRetentionPeriod", valid_604757
  var valid_604758 = formData.getOrDefault("PreferredBackupWindow")
  valid_604758 = validateParameter(valid_604758, JString, required = false,
                                 default = nil)
  if valid_604758 != nil:
    section.add "PreferredBackupWindow", valid_604758
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604759: Call_PostPromoteReadReplica_604744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604759.validator(path, query, header, formData, body)
  let scheme = call_604759.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604759.url(scheme.get, call_604759.host, call_604759.base,
                         call_604759.route, valid.getOrDefault("path"))
  result = hook(call_604759, url, valid)

proc call*(call_604760: Call_PostPromoteReadReplica_604744;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_604761 = newJObject()
  var formData_604762 = newJObject()
  add(formData_604762, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604762, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604761, "Action", newJString(Action))
  add(formData_604762, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604761, "Version", newJString(Version))
  result = call_604760.call(nil, query_604761, nil, formData_604762, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_604744(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_604745, base: "/",
    url: url_PostPromoteReadReplica_604746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_604726 = ref object of OpenApiRestCall_602417
proc url_GetPromoteReadReplica_604728(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPromoteReadReplica_604727(path: JsonNode; query: JsonNode;
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
  var valid_604729 = query.getOrDefault("BackupRetentionPeriod")
  valid_604729 = validateParameter(valid_604729, JInt, required = false, default = nil)
  if valid_604729 != nil:
    section.add "BackupRetentionPeriod", valid_604729
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604730 = query.getOrDefault("Action")
  valid_604730 = validateParameter(valid_604730, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604730 != nil:
    section.add "Action", valid_604730
  var valid_604731 = query.getOrDefault("PreferredBackupWindow")
  valid_604731 = validateParameter(valid_604731, JString, required = false,
                                 default = nil)
  if valid_604731 != nil:
    section.add "PreferredBackupWindow", valid_604731
  var valid_604732 = query.getOrDefault("Version")
  valid_604732 = validateParameter(valid_604732, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604732 != nil:
    section.add "Version", valid_604732
  var valid_604733 = query.getOrDefault("DBInstanceIdentifier")
  valid_604733 = validateParameter(valid_604733, JString, required = true,
                                 default = nil)
  if valid_604733 != nil:
    section.add "DBInstanceIdentifier", valid_604733
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604734 = header.getOrDefault("X-Amz-Date")
  valid_604734 = validateParameter(valid_604734, JString, required = false,
                                 default = nil)
  if valid_604734 != nil:
    section.add "X-Amz-Date", valid_604734
  var valid_604735 = header.getOrDefault("X-Amz-Security-Token")
  valid_604735 = validateParameter(valid_604735, JString, required = false,
                                 default = nil)
  if valid_604735 != nil:
    section.add "X-Amz-Security-Token", valid_604735
  var valid_604736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604736 = validateParameter(valid_604736, JString, required = false,
                                 default = nil)
  if valid_604736 != nil:
    section.add "X-Amz-Content-Sha256", valid_604736
  var valid_604737 = header.getOrDefault("X-Amz-Algorithm")
  valid_604737 = validateParameter(valid_604737, JString, required = false,
                                 default = nil)
  if valid_604737 != nil:
    section.add "X-Amz-Algorithm", valid_604737
  var valid_604738 = header.getOrDefault("X-Amz-Signature")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-Signature", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-SignedHeaders", valid_604739
  var valid_604740 = header.getOrDefault("X-Amz-Credential")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "X-Amz-Credential", valid_604740
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604741: Call_GetPromoteReadReplica_604726; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604741.validator(path, query, header, formData, body)
  let scheme = call_604741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604741.url(scheme.get, call_604741.host, call_604741.base,
                         call_604741.route, valid.getOrDefault("path"))
  result = hook(call_604741, url, valid)

proc call*(call_604742: Call_GetPromoteReadReplica_604726;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-02-12"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604743 = newJObject()
  add(query_604743, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604743, "Action", newJString(Action))
  add(query_604743, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604743, "Version", newJString(Version))
  add(query_604743, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604742.call(nil, query_604743, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_604726(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_604727, base: "/",
    url: url_GetPromoteReadReplica_604728, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_604781 = ref object of OpenApiRestCall_602417
proc url_PostPurchaseReservedDBInstancesOffering_604783(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostPurchaseReservedDBInstancesOffering_604782(path: JsonNode;
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
  var valid_604784 = query.getOrDefault("Action")
  valid_604784 = validateParameter(valid_604784, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604784 != nil:
    section.add "Action", valid_604784
  var valid_604785 = query.getOrDefault("Version")
  valid_604785 = validateParameter(valid_604785, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604785 != nil:
    section.add "Version", valid_604785
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604786 = header.getOrDefault("X-Amz-Date")
  valid_604786 = validateParameter(valid_604786, JString, required = false,
                                 default = nil)
  if valid_604786 != nil:
    section.add "X-Amz-Date", valid_604786
  var valid_604787 = header.getOrDefault("X-Amz-Security-Token")
  valid_604787 = validateParameter(valid_604787, JString, required = false,
                                 default = nil)
  if valid_604787 != nil:
    section.add "X-Amz-Security-Token", valid_604787
  var valid_604788 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604788 = validateParameter(valid_604788, JString, required = false,
                                 default = nil)
  if valid_604788 != nil:
    section.add "X-Amz-Content-Sha256", valid_604788
  var valid_604789 = header.getOrDefault("X-Amz-Algorithm")
  valid_604789 = validateParameter(valid_604789, JString, required = false,
                                 default = nil)
  if valid_604789 != nil:
    section.add "X-Amz-Algorithm", valid_604789
  var valid_604790 = header.getOrDefault("X-Amz-Signature")
  valid_604790 = validateParameter(valid_604790, JString, required = false,
                                 default = nil)
  if valid_604790 != nil:
    section.add "X-Amz-Signature", valid_604790
  var valid_604791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604791 = validateParameter(valid_604791, JString, required = false,
                                 default = nil)
  if valid_604791 != nil:
    section.add "X-Amz-SignedHeaders", valid_604791
  var valid_604792 = header.getOrDefault("X-Amz-Credential")
  valid_604792 = validateParameter(valid_604792, JString, required = false,
                                 default = nil)
  if valid_604792 != nil:
    section.add "X-Amz-Credential", valid_604792
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_604793 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604793 = validateParameter(valid_604793, JString, required = false,
                                 default = nil)
  if valid_604793 != nil:
    section.add "ReservedDBInstanceId", valid_604793
  var valid_604794 = formData.getOrDefault("DBInstanceCount")
  valid_604794 = validateParameter(valid_604794, JInt, required = false, default = nil)
  if valid_604794 != nil:
    section.add "DBInstanceCount", valid_604794
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604795 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604795 = validateParameter(valid_604795, JString, required = true,
                                 default = nil)
  if valid_604795 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604795
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604796: Call_PostPurchaseReservedDBInstancesOffering_604781;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604796.validator(path, query, header, formData, body)
  let scheme = call_604796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604796.url(scheme.get, call_604796.host, call_604796.base,
                         call_604796.route, valid.getOrDefault("path"))
  result = hook(call_604796, url, valid)

proc call*(call_604797: Call_PostPurchaseReservedDBInstancesOffering_604781;
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
  var query_604798 = newJObject()
  var formData_604799 = newJObject()
  add(formData_604799, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604799, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604798, "Action", newJString(Action))
  add(formData_604799, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604798, "Version", newJString(Version))
  result = call_604797.call(nil, query_604798, nil, formData_604799, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_604781(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_604782, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_604783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_604763 = ref object of OpenApiRestCall_602417
proc url_GetPurchaseReservedDBInstancesOffering_604765(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetPurchaseReservedDBInstancesOffering_604764(path: JsonNode;
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
  var valid_604766 = query.getOrDefault("DBInstanceCount")
  valid_604766 = validateParameter(valid_604766, JInt, required = false, default = nil)
  if valid_604766 != nil:
    section.add "DBInstanceCount", valid_604766
  var valid_604767 = query.getOrDefault("ReservedDBInstanceId")
  valid_604767 = validateParameter(valid_604767, JString, required = false,
                                 default = nil)
  if valid_604767 != nil:
    section.add "ReservedDBInstanceId", valid_604767
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604768 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604768 = validateParameter(valid_604768, JString, required = true,
                                 default = nil)
  if valid_604768 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604768
  var valid_604769 = query.getOrDefault("Action")
  valid_604769 = validateParameter(valid_604769, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604769 != nil:
    section.add "Action", valid_604769
  var valid_604770 = query.getOrDefault("Version")
  valid_604770 = validateParameter(valid_604770, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604770 != nil:
    section.add "Version", valid_604770
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604771 = header.getOrDefault("X-Amz-Date")
  valid_604771 = validateParameter(valid_604771, JString, required = false,
                                 default = nil)
  if valid_604771 != nil:
    section.add "X-Amz-Date", valid_604771
  var valid_604772 = header.getOrDefault("X-Amz-Security-Token")
  valid_604772 = validateParameter(valid_604772, JString, required = false,
                                 default = nil)
  if valid_604772 != nil:
    section.add "X-Amz-Security-Token", valid_604772
  var valid_604773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604773 = validateParameter(valid_604773, JString, required = false,
                                 default = nil)
  if valid_604773 != nil:
    section.add "X-Amz-Content-Sha256", valid_604773
  var valid_604774 = header.getOrDefault("X-Amz-Algorithm")
  valid_604774 = validateParameter(valid_604774, JString, required = false,
                                 default = nil)
  if valid_604774 != nil:
    section.add "X-Amz-Algorithm", valid_604774
  var valid_604775 = header.getOrDefault("X-Amz-Signature")
  valid_604775 = validateParameter(valid_604775, JString, required = false,
                                 default = nil)
  if valid_604775 != nil:
    section.add "X-Amz-Signature", valid_604775
  var valid_604776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604776 = validateParameter(valid_604776, JString, required = false,
                                 default = nil)
  if valid_604776 != nil:
    section.add "X-Amz-SignedHeaders", valid_604776
  var valid_604777 = header.getOrDefault("X-Amz-Credential")
  valid_604777 = validateParameter(valid_604777, JString, required = false,
                                 default = nil)
  if valid_604777 != nil:
    section.add "X-Amz-Credential", valid_604777
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604778: Call_GetPurchaseReservedDBInstancesOffering_604763;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604778.validator(path, query, header, formData, body)
  let scheme = call_604778.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604778.url(scheme.get, call_604778.host, call_604778.base,
                         call_604778.route, valid.getOrDefault("path"))
  result = hook(call_604778, url, valid)

proc call*(call_604779: Call_GetPurchaseReservedDBInstancesOffering_604763;
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
  var query_604780 = newJObject()
  add(query_604780, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604780, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604780, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604780, "Action", newJString(Action))
  add(query_604780, "Version", newJString(Version))
  result = call_604779.call(nil, query_604780, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_604763(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_604764, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_604765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604817 = ref object of OpenApiRestCall_602417
proc url_PostRebootDBInstance_604819(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRebootDBInstance_604818(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604820 = query.getOrDefault("Action")
  valid_604820 = validateParameter(valid_604820, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604820 != nil:
    section.add "Action", valid_604820
  var valid_604821 = query.getOrDefault("Version")
  valid_604821 = validateParameter(valid_604821, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604821 != nil:
    section.add "Version", valid_604821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604822 = header.getOrDefault("X-Amz-Date")
  valid_604822 = validateParameter(valid_604822, JString, required = false,
                                 default = nil)
  if valid_604822 != nil:
    section.add "X-Amz-Date", valid_604822
  var valid_604823 = header.getOrDefault("X-Amz-Security-Token")
  valid_604823 = validateParameter(valid_604823, JString, required = false,
                                 default = nil)
  if valid_604823 != nil:
    section.add "X-Amz-Security-Token", valid_604823
  var valid_604824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604824 = validateParameter(valid_604824, JString, required = false,
                                 default = nil)
  if valid_604824 != nil:
    section.add "X-Amz-Content-Sha256", valid_604824
  var valid_604825 = header.getOrDefault("X-Amz-Algorithm")
  valid_604825 = validateParameter(valid_604825, JString, required = false,
                                 default = nil)
  if valid_604825 != nil:
    section.add "X-Amz-Algorithm", valid_604825
  var valid_604826 = header.getOrDefault("X-Amz-Signature")
  valid_604826 = validateParameter(valid_604826, JString, required = false,
                                 default = nil)
  if valid_604826 != nil:
    section.add "X-Amz-Signature", valid_604826
  var valid_604827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604827 = validateParameter(valid_604827, JString, required = false,
                                 default = nil)
  if valid_604827 != nil:
    section.add "X-Amz-SignedHeaders", valid_604827
  var valid_604828 = header.getOrDefault("X-Amz-Credential")
  valid_604828 = validateParameter(valid_604828, JString, required = false,
                                 default = nil)
  if valid_604828 != nil:
    section.add "X-Amz-Credential", valid_604828
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604829 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604829 = validateParameter(valid_604829, JString, required = true,
                                 default = nil)
  if valid_604829 != nil:
    section.add "DBInstanceIdentifier", valid_604829
  var valid_604830 = formData.getOrDefault("ForceFailover")
  valid_604830 = validateParameter(valid_604830, JBool, required = false, default = nil)
  if valid_604830 != nil:
    section.add "ForceFailover", valid_604830
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604831: Call_PostRebootDBInstance_604817; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604831.validator(path, query, header, formData, body)
  let scheme = call_604831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604831.url(scheme.get, call_604831.host, call_604831.base,
                         call_604831.route, valid.getOrDefault("path"))
  result = hook(call_604831, url, valid)

proc call*(call_604832: Call_PostRebootDBInstance_604817;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_604833 = newJObject()
  var formData_604834 = newJObject()
  add(formData_604834, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604833, "Action", newJString(Action))
  add(formData_604834, "ForceFailover", newJBool(ForceFailover))
  add(query_604833, "Version", newJString(Version))
  result = call_604832.call(nil, query_604833, nil, formData_604834, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604817(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604818, base: "/",
    url: url_PostRebootDBInstance_604819, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604800 = ref object of OpenApiRestCall_602417
proc url_GetRebootDBInstance_604802(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRebootDBInstance_604801(path: JsonNode; query: JsonNode;
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
  var valid_604803 = query.getOrDefault("Action")
  valid_604803 = validateParameter(valid_604803, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604803 != nil:
    section.add "Action", valid_604803
  var valid_604804 = query.getOrDefault("ForceFailover")
  valid_604804 = validateParameter(valid_604804, JBool, required = false, default = nil)
  if valid_604804 != nil:
    section.add "ForceFailover", valid_604804
  var valid_604805 = query.getOrDefault("Version")
  valid_604805 = validateParameter(valid_604805, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604805 != nil:
    section.add "Version", valid_604805
  var valid_604806 = query.getOrDefault("DBInstanceIdentifier")
  valid_604806 = validateParameter(valid_604806, JString, required = true,
                                 default = nil)
  if valid_604806 != nil:
    section.add "DBInstanceIdentifier", valid_604806
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604807 = header.getOrDefault("X-Amz-Date")
  valid_604807 = validateParameter(valid_604807, JString, required = false,
                                 default = nil)
  if valid_604807 != nil:
    section.add "X-Amz-Date", valid_604807
  var valid_604808 = header.getOrDefault("X-Amz-Security-Token")
  valid_604808 = validateParameter(valid_604808, JString, required = false,
                                 default = nil)
  if valid_604808 != nil:
    section.add "X-Amz-Security-Token", valid_604808
  var valid_604809 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604809 = validateParameter(valid_604809, JString, required = false,
                                 default = nil)
  if valid_604809 != nil:
    section.add "X-Amz-Content-Sha256", valid_604809
  var valid_604810 = header.getOrDefault("X-Amz-Algorithm")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Algorithm", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Signature")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Signature", valid_604811
  var valid_604812 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604812 = validateParameter(valid_604812, JString, required = false,
                                 default = nil)
  if valid_604812 != nil:
    section.add "X-Amz-SignedHeaders", valid_604812
  var valid_604813 = header.getOrDefault("X-Amz-Credential")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-Credential", valid_604813
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604814: Call_GetRebootDBInstance_604800; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604814.validator(path, query, header, formData, body)
  let scheme = call_604814.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604814.url(scheme.get, call_604814.host, call_604814.base,
                         call_604814.route, valid.getOrDefault("path"))
  result = hook(call_604814, url, valid)

proc call*(call_604815: Call_GetRebootDBInstance_604800;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604816 = newJObject()
  add(query_604816, "Action", newJString(Action))
  add(query_604816, "ForceFailover", newJBool(ForceFailover))
  add(query_604816, "Version", newJString(Version))
  add(query_604816, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604815.call(nil, query_604816, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604800(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604801, base: "/",
    url: url_GetRebootDBInstance_604802, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_604852 = ref object of OpenApiRestCall_602417
proc url_PostRemoveSourceIdentifierFromSubscription_604854(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_604853(path: JsonNode;
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
  var valid_604855 = query.getOrDefault("Action")
  valid_604855 = validateParameter(valid_604855, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604855 != nil:
    section.add "Action", valid_604855
  var valid_604856 = query.getOrDefault("Version")
  valid_604856 = validateParameter(valid_604856, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604856 != nil:
    section.add "Version", valid_604856
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604857 = header.getOrDefault("X-Amz-Date")
  valid_604857 = validateParameter(valid_604857, JString, required = false,
                                 default = nil)
  if valid_604857 != nil:
    section.add "X-Amz-Date", valid_604857
  var valid_604858 = header.getOrDefault("X-Amz-Security-Token")
  valid_604858 = validateParameter(valid_604858, JString, required = false,
                                 default = nil)
  if valid_604858 != nil:
    section.add "X-Amz-Security-Token", valid_604858
  var valid_604859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604859 = validateParameter(valid_604859, JString, required = false,
                                 default = nil)
  if valid_604859 != nil:
    section.add "X-Amz-Content-Sha256", valid_604859
  var valid_604860 = header.getOrDefault("X-Amz-Algorithm")
  valid_604860 = validateParameter(valid_604860, JString, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "X-Amz-Algorithm", valid_604860
  var valid_604861 = header.getOrDefault("X-Amz-Signature")
  valid_604861 = validateParameter(valid_604861, JString, required = false,
                                 default = nil)
  if valid_604861 != nil:
    section.add "X-Amz-Signature", valid_604861
  var valid_604862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604862 = validateParameter(valid_604862, JString, required = false,
                                 default = nil)
  if valid_604862 != nil:
    section.add "X-Amz-SignedHeaders", valid_604862
  var valid_604863 = header.getOrDefault("X-Amz-Credential")
  valid_604863 = validateParameter(valid_604863, JString, required = false,
                                 default = nil)
  if valid_604863 != nil:
    section.add "X-Amz-Credential", valid_604863
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_604864 = formData.getOrDefault("SourceIdentifier")
  valid_604864 = validateParameter(valid_604864, JString, required = true,
                                 default = nil)
  if valid_604864 != nil:
    section.add "SourceIdentifier", valid_604864
  var valid_604865 = formData.getOrDefault("SubscriptionName")
  valid_604865 = validateParameter(valid_604865, JString, required = true,
                                 default = nil)
  if valid_604865 != nil:
    section.add "SubscriptionName", valid_604865
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604866: Call_PostRemoveSourceIdentifierFromSubscription_604852;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604866.validator(path, query, header, formData, body)
  let scheme = call_604866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604866.url(scheme.get, call_604866.host, call_604866.base,
                         call_604866.route, valid.getOrDefault("path"))
  result = hook(call_604866, url, valid)

proc call*(call_604867: Call_PostRemoveSourceIdentifierFromSubscription_604852;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604868 = newJObject()
  var formData_604869 = newJObject()
  add(formData_604869, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_604869, "SubscriptionName", newJString(SubscriptionName))
  add(query_604868, "Action", newJString(Action))
  add(query_604868, "Version", newJString(Version))
  result = call_604867.call(nil, query_604868, nil, formData_604869, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_604852(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_604853,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_604854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_604835 = ref object of OpenApiRestCall_602417
proc url_GetRemoveSourceIdentifierFromSubscription_604837(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_604836(path: JsonNode;
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
  var valid_604838 = query.getOrDefault("Action")
  valid_604838 = validateParameter(valid_604838, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604838 != nil:
    section.add "Action", valid_604838
  var valid_604839 = query.getOrDefault("SourceIdentifier")
  valid_604839 = validateParameter(valid_604839, JString, required = true,
                                 default = nil)
  if valid_604839 != nil:
    section.add "SourceIdentifier", valid_604839
  var valid_604840 = query.getOrDefault("SubscriptionName")
  valid_604840 = validateParameter(valid_604840, JString, required = true,
                                 default = nil)
  if valid_604840 != nil:
    section.add "SubscriptionName", valid_604840
  var valid_604841 = query.getOrDefault("Version")
  valid_604841 = validateParameter(valid_604841, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604841 != nil:
    section.add "Version", valid_604841
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604842 = header.getOrDefault("X-Amz-Date")
  valid_604842 = validateParameter(valid_604842, JString, required = false,
                                 default = nil)
  if valid_604842 != nil:
    section.add "X-Amz-Date", valid_604842
  var valid_604843 = header.getOrDefault("X-Amz-Security-Token")
  valid_604843 = validateParameter(valid_604843, JString, required = false,
                                 default = nil)
  if valid_604843 != nil:
    section.add "X-Amz-Security-Token", valid_604843
  var valid_604844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604844 = validateParameter(valid_604844, JString, required = false,
                                 default = nil)
  if valid_604844 != nil:
    section.add "X-Amz-Content-Sha256", valid_604844
  var valid_604845 = header.getOrDefault("X-Amz-Algorithm")
  valid_604845 = validateParameter(valid_604845, JString, required = false,
                                 default = nil)
  if valid_604845 != nil:
    section.add "X-Amz-Algorithm", valid_604845
  var valid_604846 = header.getOrDefault("X-Amz-Signature")
  valid_604846 = validateParameter(valid_604846, JString, required = false,
                                 default = nil)
  if valid_604846 != nil:
    section.add "X-Amz-Signature", valid_604846
  var valid_604847 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604847 = validateParameter(valid_604847, JString, required = false,
                                 default = nil)
  if valid_604847 != nil:
    section.add "X-Amz-SignedHeaders", valid_604847
  var valid_604848 = header.getOrDefault("X-Amz-Credential")
  valid_604848 = validateParameter(valid_604848, JString, required = false,
                                 default = nil)
  if valid_604848 != nil:
    section.add "X-Amz-Credential", valid_604848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604849: Call_GetRemoveSourceIdentifierFromSubscription_604835;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604849.validator(path, query, header, formData, body)
  let scheme = call_604849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604849.url(scheme.get, call_604849.host, call_604849.base,
                         call_604849.route, valid.getOrDefault("path"))
  result = hook(call_604849, url, valid)

proc call*(call_604850: Call_GetRemoveSourceIdentifierFromSubscription_604835;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-02-12"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_604851 = newJObject()
  add(query_604851, "Action", newJString(Action))
  add(query_604851, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604851, "SubscriptionName", newJString(SubscriptionName))
  add(query_604851, "Version", newJString(Version))
  result = call_604850.call(nil, query_604851, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_604835(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_604836,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_604837,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_604887 = ref object of OpenApiRestCall_602417
proc url_PostRemoveTagsFromResource_604889(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRemoveTagsFromResource_604888(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604890 = query.getOrDefault("Action")
  valid_604890 = validateParameter(valid_604890, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604890 != nil:
    section.add "Action", valid_604890
  var valid_604891 = query.getOrDefault("Version")
  valid_604891 = validateParameter(valid_604891, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604891 != nil:
    section.add "Version", valid_604891
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604892 = header.getOrDefault("X-Amz-Date")
  valid_604892 = validateParameter(valid_604892, JString, required = false,
                                 default = nil)
  if valid_604892 != nil:
    section.add "X-Amz-Date", valid_604892
  var valid_604893 = header.getOrDefault("X-Amz-Security-Token")
  valid_604893 = validateParameter(valid_604893, JString, required = false,
                                 default = nil)
  if valid_604893 != nil:
    section.add "X-Amz-Security-Token", valid_604893
  var valid_604894 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604894 = validateParameter(valid_604894, JString, required = false,
                                 default = nil)
  if valid_604894 != nil:
    section.add "X-Amz-Content-Sha256", valid_604894
  var valid_604895 = header.getOrDefault("X-Amz-Algorithm")
  valid_604895 = validateParameter(valid_604895, JString, required = false,
                                 default = nil)
  if valid_604895 != nil:
    section.add "X-Amz-Algorithm", valid_604895
  var valid_604896 = header.getOrDefault("X-Amz-Signature")
  valid_604896 = validateParameter(valid_604896, JString, required = false,
                                 default = nil)
  if valid_604896 != nil:
    section.add "X-Amz-Signature", valid_604896
  var valid_604897 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604897 = validateParameter(valid_604897, JString, required = false,
                                 default = nil)
  if valid_604897 != nil:
    section.add "X-Amz-SignedHeaders", valid_604897
  var valid_604898 = header.getOrDefault("X-Amz-Credential")
  valid_604898 = validateParameter(valid_604898, JString, required = false,
                                 default = nil)
  if valid_604898 != nil:
    section.add "X-Amz-Credential", valid_604898
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604899 = formData.getOrDefault("TagKeys")
  valid_604899 = validateParameter(valid_604899, JArray, required = true, default = nil)
  if valid_604899 != nil:
    section.add "TagKeys", valid_604899
  var valid_604900 = formData.getOrDefault("ResourceName")
  valid_604900 = validateParameter(valid_604900, JString, required = true,
                                 default = nil)
  if valid_604900 != nil:
    section.add "ResourceName", valid_604900
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604901: Call_PostRemoveTagsFromResource_604887; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604901.validator(path, query, header, formData, body)
  let scheme = call_604901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604901.url(scheme.get, call_604901.host, call_604901.base,
                         call_604901.route, valid.getOrDefault("path"))
  result = hook(call_604901, url, valid)

proc call*(call_604902: Call_PostRemoveTagsFromResource_604887; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-02-12"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604903 = newJObject()
  var formData_604904 = newJObject()
  add(query_604903, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604904.add "TagKeys", TagKeys
  add(formData_604904, "ResourceName", newJString(ResourceName))
  add(query_604903, "Version", newJString(Version))
  result = call_604902.call(nil, query_604903, nil, formData_604904, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_604887(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_604888, base: "/",
    url: url_PostRemoveTagsFromResource_604889,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_604870 = ref object of OpenApiRestCall_602417
proc url_GetRemoveTagsFromResource_604872(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRemoveTagsFromResource_604871(path: JsonNode; query: JsonNode;
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
  var valid_604873 = query.getOrDefault("ResourceName")
  valid_604873 = validateParameter(valid_604873, JString, required = true,
                                 default = nil)
  if valid_604873 != nil:
    section.add "ResourceName", valid_604873
  var valid_604874 = query.getOrDefault("Action")
  valid_604874 = validateParameter(valid_604874, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604874 != nil:
    section.add "Action", valid_604874
  var valid_604875 = query.getOrDefault("TagKeys")
  valid_604875 = validateParameter(valid_604875, JArray, required = true, default = nil)
  if valid_604875 != nil:
    section.add "TagKeys", valid_604875
  var valid_604876 = query.getOrDefault("Version")
  valid_604876 = validateParameter(valid_604876, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604876 != nil:
    section.add "Version", valid_604876
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604877 = header.getOrDefault("X-Amz-Date")
  valid_604877 = validateParameter(valid_604877, JString, required = false,
                                 default = nil)
  if valid_604877 != nil:
    section.add "X-Amz-Date", valid_604877
  var valid_604878 = header.getOrDefault("X-Amz-Security-Token")
  valid_604878 = validateParameter(valid_604878, JString, required = false,
                                 default = nil)
  if valid_604878 != nil:
    section.add "X-Amz-Security-Token", valid_604878
  var valid_604879 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604879 = validateParameter(valid_604879, JString, required = false,
                                 default = nil)
  if valid_604879 != nil:
    section.add "X-Amz-Content-Sha256", valid_604879
  var valid_604880 = header.getOrDefault("X-Amz-Algorithm")
  valid_604880 = validateParameter(valid_604880, JString, required = false,
                                 default = nil)
  if valid_604880 != nil:
    section.add "X-Amz-Algorithm", valid_604880
  var valid_604881 = header.getOrDefault("X-Amz-Signature")
  valid_604881 = validateParameter(valid_604881, JString, required = false,
                                 default = nil)
  if valid_604881 != nil:
    section.add "X-Amz-Signature", valid_604881
  var valid_604882 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604882 = validateParameter(valid_604882, JString, required = false,
                                 default = nil)
  if valid_604882 != nil:
    section.add "X-Amz-SignedHeaders", valid_604882
  var valid_604883 = header.getOrDefault("X-Amz-Credential")
  valid_604883 = validateParameter(valid_604883, JString, required = false,
                                 default = nil)
  if valid_604883 != nil:
    section.add "X-Amz-Credential", valid_604883
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604884: Call_GetRemoveTagsFromResource_604870; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604884.validator(path, query, header, formData, body)
  let scheme = call_604884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604884.url(scheme.get, call_604884.host, call_604884.base,
                         call_604884.route, valid.getOrDefault("path"))
  result = hook(call_604884, url, valid)

proc call*(call_604885: Call_GetRemoveTagsFromResource_604870;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-02-12"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_604886 = newJObject()
  add(query_604886, "ResourceName", newJString(ResourceName))
  add(query_604886, "Action", newJString(Action))
  if TagKeys != nil:
    query_604886.add "TagKeys", TagKeys
  add(query_604886, "Version", newJString(Version))
  result = call_604885.call(nil, query_604886, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_604870(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_604871, base: "/",
    url: url_GetRemoveTagsFromResource_604872,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_604923 = ref object of OpenApiRestCall_602417
proc url_PostResetDBParameterGroup_604925(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostResetDBParameterGroup_604924(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604926 = query.getOrDefault("Action")
  valid_604926 = validateParameter(valid_604926, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604926 != nil:
    section.add "Action", valid_604926
  var valid_604927 = query.getOrDefault("Version")
  valid_604927 = validateParameter(valid_604927, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604927 != nil:
    section.add "Version", valid_604927
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604928 = header.getOrDefault("X-Amz-Date")
  valid_604928 = validateParameter(valid_604928, JString, required = false,
                                 default = nil)
  if valid_604928 != nil:
    section.add "X-Amz-Date", valid_604928
  var valid_604929 = header.getOrDefault("X-Amz-Security-Token")
  valid_604929 = validateParameter(valid_604929, JString, required = false,
                                 default = nil)
  if valid_604929 != nil:
    section.add "X-Amz-Security-Token", valid_604929
  var valid_604930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-Content-Sha256", valid_604930
  var valid_604931 = header.getOrDefault("X-Amz-Algorithm")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-Algorithm", valid_604931
  var valid_604932 = header.getOrDefault("X-Amz-Signature")
  valid_604932 = validateParameter(valid_604932, JString, required = false,
                                 default = nil)
  if valid_604932 != nil:
    section.add "X-Amz-Signature", valid_604932
  var valid_604933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604933 = validateParameter(valid_604933, JString, required = false,
                                 default = nil)
  if valid_604933 != nil:
    section.add "X-Amz-SignedHeaders", valid_604933
  var valid_604934 = header.getOrDefault("X-Amz-Credential")
  valid_604934 = validateParameter(valid_604934, JString, required = false,
                                 default = nil)
  if valid_604934 != nil:
    section.add "X-Amz-Credential", valid_604934
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604935 = formData.getOrDefault("DBParameterGroupName")
  valid_604935 = validateParameter(valid_604935, JString, required = true,
                                 default = nil)
  if valid_604935 != nil:
    section.add "DBParameterGroupName", valid_604935
  var valid_604936 = formData.getOrDefault("Parameters")
  valid_604936 = validateParameter(valid_604936, JArray, required = false,
                                 default = nil)
  if valid_604936 != nil:
    section.add "Parameters", valid_604936
  var valid_604937 = formData.getOrDefault("ResetAllParameters")
  valid_604937 = validateParameter(valid_604937, JBool, required = false, default = nil)
  if valid_604937 != nil:
    section.add "ResetAllParameters", valid_604937
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604938: Call_PostResetDBParameterGroup_604923; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604938.validator(path, query, header, formData, body)
  let scheme = call_604938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604938.url(scheme.get, call_604938.host, call_604938.base,
                         call_604938.route, valid.getOrDefault("path"))
  result = hook(call_604938, url, valid)

proc call*(call_604939: Call_PostResetDBParameterGroup_604923;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604940 = newJObject()
  var formData_604941 = newJObject()
  add(formData_604941, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604941.add "Parameters", Parameters
  add(query_604940, "Action", newJString(Action))
  add(formData_604941, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604940, "Version", newJString(Version))
  result = call_604939.call(nil, query_604940, nil, formData_604941, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_604923(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_604924, base: "/",
    url: url_PostResetDBParameterGroup_604925,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_604905 = ref object of OpenApiRestCall_602417
proc url_GetResetDBParameterGroup_604907(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResetDBParameterGroup_604906(path: JsonNode; query: JsonNode;
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
  var valid_604908 = query.getOrDefault("DBParameterGroupName")
  valid_604908 = validateParameter(valid_604908, JString, required = true,
                                 default = nil)
  if valid_604908 != nil:
    section.add "DBParameterGroupName", valid_604908
  var valid_604909 = query.getOrDefault("Parameters")
  valid_604909 = validateParameter(valid_604909, JArray, required = false,
                                 default = nil)
  if valid_604909 != nil:
    section.add "Parameters", valid_604909
  var valid_604910 = query.getOrDefault("Action")
  valid_604910 = validateParameter(valid_604910, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604910 != nil:
    section.add "Action", valid_604910
  var valid_604911 = query.getOrDefault("ResetAllParameters")
  valid_604911 = validateParameter(valid_604911, JBool, required = false, default = nil)
  if valid_604911 != nil:
    section.add "ResetAllParameters", valid_604911
  var valid_604912 = query.getOrDefault("Version")
  valid_604912 = validateParameter(valid_604912, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604912 != nil:
    section.add "Version", valid_604912
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604913 = header.getOrDefault("X-Amz-Date")
  valid_604913 = validateParameter(valid_604913, JString, required = false,
                                 default = nil)
  if valid_604913 != nil:
    section.add "X-Amz-Date", valid_604913
  var valid_604914 = header.getOrDefault("X-Amz-Security-Token")
  valid_604914 = validateParameter(valid_604914, JString, required = false,
                                 default = nil)
  if valid_604914 != nil:
    section.add "X-Amz-Security-Token", valid_604914
  var valid_604915 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604915 = validateParameter(valid_604915, JString, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "X-Amz-Content-Sha256", valid_604915
  var valid_604916 = header.getOrDefault("X-Amz-Algorithm")
  valid_604916 = validateParameter(valid_604916, JString, required = false,
                                 default = nil)
  if valid_604916 != nil:
    section.add "X-Amz-Algorithm", valid_604916
  var valid_604917 = header.getOrDefault("X-Amz-Signature")
  valid_604917 = validateParameter(valid_604917, JString, required = false,
                                 default = nil)
  if valid_604917 != nil:
    section.add "X-Amz-Signature", valid_604917
  var valid_604918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604918 = validateParameter(valid_604918, JString, required = false,
                                 default = nil)
  if valid_604918 != nil:
    section.add "X-Amz-SignedHeaders", valid_604918
  var valid_604919 = header.getOrDefault("X-Amz-Credential")
  valid_604919 = validateParameter(valid_604919, JString, required = false,
                                 default = nil)
  if valid_604919 != nil:
    section.add "X-Amz-Credential", valid_604919
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604920: Call_GetResetDBParameterGroup_604905; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604920.validator(path, query, header, formData, body)
  let scheme = call_604920.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604920.url(scheme.get, call_604920.host, call_604920.base,
                         call_604920.route, valid.getOrDefault("path"))
  result = hook(call_604920, url, valid)

proc call*(call_604921: Call_GetResetDBParameterGroup_604905;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-02-12"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604922 = newJObject()
  add(query_604922, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604922.add "Parameters", Parameters
  add(query_604922, "Action", newJString(Action))
  add(query_604922, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604922, "Version", newJString(Version))
  result = call_604921.call(nil, query_604922, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_604905(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_604906, base: "/",
    url: url_GetResetDBParameterGroup_604907, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_604971 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBInstanceFromDBSnapshot_604973(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_604972(path: JsonNode;
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
  var valid_604974 = query.getOrDefault("Action")
  valid_604974 = validateParameter(valid_604974, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_604974 != nil:
    section.add "Action", valid_604974
  var valid_604975 = query.getOrDefault("Version")
  valid_604975 = validateParameter(valid_604975, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604975 != nil:
    section.add "Version", valid_604975
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604976 = header.getOrDefault("X-Amz-Date")
  valid_604976 = validateParameter(valid_604976, JString, required = false,
                                 default = nil)
  if valid_604976 != nil:
    section.add "X-Amz-Date", valid_604976
  var valid_604977 = header.getOrDefault("X-Amz-Security-Token")
  valid_604977 = validateParameter(valid_604977, JString, required = false,
                                 default = nil)
  if valid_604977 != nil:
    section.add "X-Amz-Security-Token", valid_604977
  var valid_604978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604978 = validateParameter(valid_604978, JString, required = false,
                                 default = nil)
  if valid_604978 != nil:
    section.add "X-Amz-Content-Sha256", valid_604978
  var valid_604979 = header.getOrDefault("X-Amz-Algorithm")
  valid_604979 = validateParameter(valid_604979, JString, required = false,
                                 default = nil)
  if valid_604979 != nil:
    section.add "X-Amz-Algorithm", valid_604979
  var valid_604980 = header.getOrDefault("X-Amz-Signature")
  valid_604980 = validateParameter(valid_604980, JString, required = false,
                                 default = nil)
  if valid_604980 != nil:
    section.add "X-Amz-Signature", valid_604980
  var valid_604981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604981 = validateParameter(valid_604981, JString, required = false,
                                 default = nil)
  if valid_604981 != nil:
    section.add "X-Amz-SignedHeaders", valid_604981
  var valid_604982 = header.getOrDefault("X-Amz-Credential")
  valid_604982 = validateParameter(valid_604982, JString, required = false,
                                 default = nil)
  if valid_604982 != nil:
    section.add "X-Amz-Credential", valid_604982
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
  var valid_604983 = formData.getOrDefault("Port")
  valid_604983 = validateParameter(valid_604983, JInt, required = false, default = nil)
  if valid_604983 != nil:
    section.add "Port", valid_604983
  var valid_604984 = formData.getOrDefault("Engine")
  valid_604984 = validateParameter(valid_604984, JString, required = false,
                                 default = nil)
  if valid_604984 != nil:
    section.add "Engine", valid_604984
  var valid_604985 = formData.getOrDefault("Iops")
  valid_604985 = validateParameter(valid_604985, JInt, required = false, default = nil)
  if valid_604985 != nil:
    section.add "Iops", valid_604985
  var valid_604986 = formData.getOrDefault("DBName")
  valid_604986 = validateParameter(valid_604986, JString, required = false,
                                 default = nil)
  if valid_604986 != nil:
    section.add "DBName", valid_604986
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604987 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604987 = validateParameter(valid_604987, JString, required = true,
                                 default = nil)
  if valid_604987 != nil:
    section.add "DBInstanceIdentifier", valid_604987
  var valid_604988 = formData.getOrDefault("OptionGroupName")
  valid_604988 = validateParameter(valid_604988, JString, required = false,
                                 default = nil)
  if valid_604988 != nil:
    section.add "OptionGroupName", valid_604988
  var valid_604989 = formData.getOrDefault("DBSubnetGroupName")
  valid_604989 = validateParameter(valid_604989, JString, required = false,
                                 default = nil)
  if valid_604989 != nil:
    section.add "DBSubnetGroupName", valid_604989
  var valid_604990 = formData.getOrDefault("AvailabilityZone")
  valid_604990 = validateParameter(valid_604990, JString, required = false,
                                 default = nil)
  if valid_604990 != nil:
    section.add "AvailabilityZone", valid_604990
  var valid_604991 = formData.getOrDefault("MultiAZ")
  valid_604991 = validateParameter(valid_604991, JBool, required = false, default = nil)
  if valid_604991 != nil:
    section.add "MultiAZ", valid_604991
  var valid_604992 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604992 = validateParameter(valid_604992, JString, required = true,
                                 default = nil)
  if valid_604992 != nil:
    section.add "DBSnapshotIdentifier", valid_604992
  var valid_604993 = formData.getOrDefault("PubliclyAccessible")
  valid_604993 = validateParameter(valid_604993, JBool, required = false, default = nil)
  if valid_604993 != nil:
    section.add "PubliclyAccessible", valid_604993
  var valid_604994 = formData.getOrDefault("DBInstanceClass")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "DBInstanceClass", valid_604994
  var valid_604995 = formData.getOrDefault("LicenseModel")
  valid_604995 = validateParameter(valid_604995, JString, required = false,
                                 default = nil)
  if valid_604995 != nil:
    section.add "LicenseModel", valid_604995
  var valid_604996 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604996 = validateParameter(valid_604996, JBool, required = false, default = nil)
  if valid_604996 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604996
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604997: Call_PostRestoreDBInstanceFromDBSnapshot_604971;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604997.validator(path, query, header, formData, body)
  let scheme = call_604997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604997.url(scheme.get, call_604997.host, call_604997.base,
                         call_604997.route, valid.getOrDefault("path"))
  result = hook(call_604997, url, valid)

proc call*(call_604998: Call_PostRestoreDBInstanceFromDBSnapshot_604971;
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
  var query_604999 = newJObject()
  var formData_605000 = newJObject()
  add(formData_605000, "Port", newJInt(Port))
  add(formData_605000, "Engine", newJString(Engine))
  add(formData_605000, "Iops", newJInt(Iops))
  add(formData_605000, "DBName", newJString(DBName))
  add(formData_605000, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_605000, "OptionGroupName", newJString(OptionGroupName))
  add(formData_605000, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605000, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605000, "MultiAZ", newJBool(MultiAZ))
  add(formData_605000, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604999, "Action", newJString(Action))
  add(formData_605000, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605000, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605000, "LicenseModel", newJString(LicenseModel))
  add(formData_605000, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_604999, "Version", newJString(Version))
  result = call_604998.call(nil, query_604999, nil, formData_605000, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_604971(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_604972, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_604973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_604942 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBInstanceFromDBSnapshot_604944(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_604943(path: JsonNode;
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
  var valid_604945 = query.getOrDefault("Engine")
  valid_604945 = validateParameter(valid_604945, JString, required = false,
                                 default = nil)
  if valid_604945 != nil:
    section.add "Engine", valid_604945
  var valid_604946 = query.getOrDefault("OptionGroupName")
  valid_604946 = validateParameter(valid_604946, JString, required = false,
                                 default = nil)
  if valid_604946 != nil:
    section.add "OptionGroupName", valid_604946
  var valid_604947 = query.getOrDefault("AvailabilityZone")
  valid_604947 = validateParameter(valid_604947, JString, required = false,
                                 default = nil)
  if valid_604947 != nil:
    section.add "AvailabilityZone", valid_604947
  var valid_604948 = query.getOrDefault("Iops")
  valid_604948 = validateParameter(valid_604948, JInt, required = false, default = nil)
  if valid_604948 != nil:
    section.add "Iops", valid_604948
  var valid_604949 = query.getOrDefault("MultiAZ")
  valid_604949 = validateParameter(valid_604949, JBool, required = false, default = nil)
  if valid_604949 != nil:
    section.add "MultiAZ", valid_604949
  var valid_604950 = query.getOrDefault("LicenseModel")
  valid_604950 = validateParameter(valid_604950, JString, required = false,
                                 default = nil)
  if valid_604950 != nil:
    section.add "LicenseModel", valid_604950
  var valid_604951 = query.getOrDefault("DBName")
  valid_604951 = validateParameter(valid_604951, JString, required = false,
                                 default = nil)
  if valid_604951 != nil:
    section.add "DBName", valid_604951
  var valid_604952 = query.getOrDefault("DBInstanceClass")
  valid_604952 = validateParameter(valid_604952, JString, required = false,
                                 default = nil)
  if valid_604952 != nil:
    section.add "DBInstanceClass", valid_604952
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604953 = query.getOrDefault("Action")
  valid_604953 = validateParameter(valid_604953, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_604953 != nil:
    section.add "Action", valid_604953
  var valid_604954 = query.getOrDefault("DBSubnetGroupName")
  valid_604954 = validateParameter(valid_604954, JString, required = false,
                                 default = nil)
  if valid_604954 != nil:
    section.add "DBSubnetGroupName", valid_604954
  var valid_604955 = query.getOrDefault("PubliclyAccessible")
  valid_604955 = validateParameter(valid_604955, JBool, required = false, default = nil)
  if valid_604955 != nil:
    section.add "PubliclyAccessible", valid_604955
  var valid_604956 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604956 = validateParameter(valid_604956, JBool, required = false, default = nil)
  if valid_604956 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604956
  var valid_604957 = query.getOrDefault("Port")
  valid_604957 = validateParameter(valid_604957, JInt, required = false, default = nil)
  if valid_604957 != nil:
    section.add "Port", valid_604957
  var valid_604958 = query.getOrDefault("Version")
  valid_604958 = validateParameter(valid_604958, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_604958 != nil:
    section.add "Version", valid_604958
  var valid_604959 = query.getOrDefault("DBInstanceIdentifier")
  valid_604959 = validateParameter(valid_604959, JString, required = true,
                                 default = nil)
  if valid_604959 != nil:
    section.add "DBInstanceIdentifier", valid_604959
  var valid_604960 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604960 = validateParameter(valid_604960, JString, required = true,
                                 default = nil)
  if valid_604960 != nil:
    section.add "DBSnapshotIdentifier", valid_604960
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604961 = header.getOrDefault("X-Amz-Date")
  valid_604961 = validateParameter(valid_604961, JString, required = false,
                                 default = nil)
  if valid_604961 != nil:
    section.add "X-Amz-Date", valid_604961
  var valid_604962 = header.getOrDefault("X-Amz-Security-Token")
  valid_604962 = validateParameter(valid_604962, JString, required = false,
                                 default = nil)
  if valid_604962 != nil:
    section.add "X-Amz-Security-Token", valid_604962
  var valid_604963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604963 = validateParameter(valid_604963, JString, required = false,
                                 default = nil)
  if valid_604963 != nil:
    section.add "X-Amz-Content-Sha256", valid_604963
  var valid_604964 = header.getOrDefault("X-Amz-Algorithm")
  valid_604964 = validateParameter(valid_604964, JString, required = false,
                                 default = nil)
  if valid_604964 != nil:
    section.add "X-Amz-Algorithm", valid_604964
  var valid_604965 = header.getOrDefault("X-Amz-Signature")
  valid_604965 = validateParameter(valid_604965, JString, required = false,
                                 default = nil)
  if valid_604965 != nil:
    section.add "X-Amz-Signature", valid_604965
  var valid_604966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604966 = validateParameter(valid_604966, JString, required = false,
                                 default = nil)
  if valid_604966 != nil:
    section.add "X-Amz-SignedHeaders", valid_604966
  var valid_604967 = header.getOrDefault("X-Amz-Credential")
  valid_604967 = validateParameter(valid_604967, JString, required = false,
                                 default = nil)
  if valid_604967 != nil:
    section.add "X-Amz-Credential", valid_604967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604968: Call_GetRestoreDBInstanceFromDBSnapshot_604942;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604968.validator(path, query, header, formData, body)
  let scheme = call_604968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604968.url(scheme.get, call_604968.host, call_604968.base,
                         call_604968.route, valid.getOrDefault("path"))
  result = hook(call_604968, url, valid)

proc call*(call_604969: Call_GetRestoreDBInstanceFromDBSnapshot_604942;
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
  var query_604970 = newJObject()
  add(query_604970, "Engine", newJString(Engine))
  add(query_604970, "OptionGroupName", newJString(OptionGroupName))
  add(query_604970, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_604970, "Iops", newJInt(Iops))
  add(query_604970, "MultiAZ", newJBool(MultiAZ))
  add(query_604970, "LicenseModel", newJString(LicenseModel))
  add(query_604970, "DBName", newJString(DBName))
  add(query_604970, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604970, "Action", newJString(Action))
  add(query_604970, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604970, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604970, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604970, "Port", newJInt(Port))
  add(query_604970, "Version", newJString(Version))
  add(query_604970, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604970, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604969.call(nil, query_604970, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_604942(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_604943, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_604944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_605032 = ref object of OpenApiRestCall_602417
proc url_PostRestoreDBInstanceToPointInTime_605034(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRestoreDBInstanceToPointInTime_605033(path: JsonNode;
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
  var valid_605035 = query.getOrDefault("Action")
  valid_605035 = validateParameter(valid_605035, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605035 != nil:
    section.add "Action", valid_605035
  var valid_605036 = query.getOrDefault("Version")
  valid_605036 = validateParameter(valid_605036, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605036 != nil:
    section.add "Version", valid_605036
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605037 = header.getOrDefault("X-Amz-Date")
  valid_605037 = validateParameter(valid_605037, JString, required = false,
                                 default = nil)
  if valid_605037 != nil:
    section.add "X-Amz-Date", valid_605037
  var valid_605038 = header.getOrDefault("X-Amz-Security-Token")
  valid_605038 = validateParameter(valid_605038, JString, required = false,
                                 default = nil)
  if valid_605038 != nil:
    section.add "X-Amz-Security-Token", valid_605038
  var valid_605039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605039 = validateParameter(valid_605039, JString, required = false,
                                 default = nil)
  if valid_605039 != nil:
    section.add "X-Amz-Content-Sha256", valid_605039
  var valid_605040 = header.getOrDefault("X-Amz-Algorithm")
  valid_605040 = validateParameter(valid_605040, JString, required = false,
                                 default = nil)
  if valid_605040 != nil:
    section.add "X-Amz-Algorithm", valid_605040
  var valid_605041 = header.getOrDefault("X-Amz-Signature")
  valid_605041 = validateParameter(valid_605041, JString, required = false,
                                 default = nil)
  if valid_605041 != nil:
    section.add "X-Amz-Signature", valid_605041
  var valid_605042 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605042 = validateParameter(valid_605042, JString, required = false,
                                 default = nil)
  if valid_605042 != nil:
    section.add "X-Amz-SignedHeaders", valid_605042
  var valid_605043 = header.getOrDefault("X-Amz-Credential")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "X-Amz-Credential", valid_605043
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
  var valid_605044 = formData.getOrDefault("UseLatestRestorableTime")
  valid_605044 = validateParameter(valid_605044, JBool, required = false, default = nil)
  if valid_605044 != nil:
    section.add "UseLatestRestorableTime", valid_605044
  var valid_605045 = formData.getOrDefault("Port")
  valid_605045 = validateParameter(valid_605045, JInt, required = false, default = nil)
  if valid_605045 != nil:
    section.add "Port", valid_605045
  var valid_605046 = formData.getOrDefault("Engine")
  valid_605046 = validateParameter(valid_605046, JString, required = false,
                                 default = nil)
  if valid_605046 != nil:
    section.add "Engine", valid_605046
  var valid_605047 = formData.getOrDefault("Iops")
  valid_605047 = validateParameter(valid_605047, JInt, required = false, default = nil)
  if valid_605047 != nil:
    section.add "Iops", valid_605047
  var valid_605048 = formData.getOrDefault("DBName")
  valid_605048 = validateParameter(valid_605048, JString, required = false,
                                 default = nil)
  if valid_605048 != nil:
    section.add "DBName", valid_605048
  var valid_605049 = formData.getOrDefault("OptionGroupName")
  valid_605049 = validateParameter(valid_605049, JString, required = false,
                                 default = nil)
  if valid_605049 != nil:
    section.add "OptionGroupName", valid_605049
  var valid_605050 = formData.getOrDefault("DBSubnetGroupName")
  valid_605050 = validateParameter(valid_605050, JString, required = false,
                                 default = nil)
  if valid_605050 != nil:
    section.add "DBSubnetGroupName", valid_605050
  var valid_605051 = formData.getOrDefault("AvailabilityZone")
  valid_605051 = validateParameter(valid_605051, JString, required = false,
                                 default = nil)
  if valid_605051 != nil:
    section.add "AvailabilityZone", valid_605051
  var valid_605052 = formData.getOrDefault("MultiAZ")
  valid_605052 = validateParameter(valid_605052, JBool, required = false, default = nil)
  if valid_605052 != nil:
    section.add "MultiAZ", valid_605052
  var valid_605053 = formData.getOrDefault("RestoreTime")
  valid_605053 = validateParameter(valid_605053, JString, required = false,
                                 default = nil)
  if valid_605053 != nil:
    section.add "RestoreTime", valid_605053
  var valid_605054 = formData.getOrDefault("PubliclyAccessible")
  valid_605054 = validateParameter(valid_605054, JBool, required = false, default = nil)
  if valid_605054 != nil:
    section.add "PubliclyAccessible", valid_605054
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_605055 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_605055 = validateParameter(valid_605055, JString, required = true,
                                 default = nil)
  if valid_605055 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605055
  var valid_605056 = formData.getOrDefault("DBInstanceClass")
  valid_605056 = validateParameter(valid_605056, JString, required = false,
                                 default = nil)
  if valid_605056 != nil:
    section.add "DBInstanceClass", valid_605056
  var valid_605057 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_605057 = validateParameter(valid_605057, JString, required = true,
                                 default = nil)
  if valid_605057 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605057
  var valid_605058 = formData.getOrDefault("LicenseModel")
  valid_605058 = validateParameter(valid_605058, JString, required = false,
                                 default = nil)
  if valid_605058 != nil:
    section.add "LicenseModel", valid_605058
  var valid_605059 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605059 = validateParameter(valid_605059, JBool, required = false, default = nil)
  if valid_605059 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605059
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605060: Call_PostRestoreDBInstanceToPointInTime_605032;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605060.validator(path, query, header, formData, body)
  let scheme = call_605060.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605060.url(scheme.get, call_605060.host, call_605060.base,
                         call_605060.route, valid.getOrDefault("path"))
  result = hook(call_605060, url, valid)

proc call*(call_605061: Call_PostRestoreDBInstanceToPointInTime_605032;
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
  var query_605062 = newJObject()
  var formData_605063 = newJObject()
  add(formData_605063, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_605063, "Port", newJInt(Port))
  add(formData_605063, "Engine", newJString(Engine))
  add(formData_605063, "Iops", newJInt(Iops))
  add(formData_605063, "DBName", newJString(DBName))
  add(formData_605063, "OptionGroupName", newJString(OptionGroupName))
  add(formData_605063, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605063, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605063, "MultiAZ", newJBool(MultiAZ))
  add(query_605062, "Action", newJString(Action))
  add(formData_605063, "RestoreTime", newJString(RestoreTime))
  add(formData_605063, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605063, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_605063, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605063, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_605063, "LicenseModel", newJString(LicenseModel))
  add(formData_605063, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605062, "Version", newJString(Version))
  result = call_605061.call(nil, query_605062, nil, formData_605063, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_605032(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_605033, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_605034,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_605001 = ref object of OpenApiRestCall_602417
proc url_GetRestoreDBInstanceToPointInTime_605003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRestoreDBInstanceToPointInTime_605002(path: JsonNode;
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
  var valid_605004 = query.getOrDefault("Engine")
  valid_605004 = validateParameter(valid_605004, JString, required = false,
                                 default = nil)
  if valid_605004 != nil:
    section.add "Engine", valid_605004
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_605005 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_605005 = validateParameter(valid_605005, JString, required = true,
                                 default = nil)
  if valid_605005 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605005
  var valid_605006 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_605006 = validateParameter(valid_605006, JString, required = true,
                                 default = nil)
  if valid_605006 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605006
  var valid_605007 = query.getOrDefault("AvailabilityZone")
  valid_605007 = validateParameter(valid_605007, JString, required = false,
                                 default = nil)
  if valid_605007 != nil:
    section.add "AvailabilityZone", valid_605007
  var valid_605008 = query.getOrDefault("Iops")
  valid_605008 = validateParameter(valid_605008, JInt, required = false, default = nil)
  if valid_605008 != nil:
    section.add "Iops", valid_605008
  var valid_605009 = query.getOrDefault("OptionGroupName")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "OptionGroupName", valid_605009
  var valid_605010 = query.getOrDefault("RestoreTime")
  valid_605010 = validateParameter(valid_605010, JString, required = false,
                                 default = nil)
  if valid_605010 != nil:
    section.add "RestoreTime", valid_605010
  var valid_605011 = query.getOrDefault("MultiAZ")
  valid_605011 = validateParameter(valid_605011, JBool, required = false, default = nil)
  if valid_605011 != nil:
    section.add "MultiAZ", valid_605011
  var valid_605012 = query.getOrDefault("LicenseModel")
  valid_605012 = validateParameter(valid_605012, JString, required = false,
                                 default = nil)
  if valid_605012 != nil:
    section.add "LicenseModel", valid_605012
  var valid_605013 = query.getOrDefault("DBName")
  valid_605013 = validateParameter(valid_605013, JString, required = false,
                                 default = nil)
  if valid_605013 != nil:
    section.add "DBName", valid_605013
  var valid_605014 = query.getOrDefault("DBInstanceClass")
  valid_605014 = validateParameter(valid_605014, JString, required = false,
                                 default = nil)
  if valid_605014 != nil:
    section.add "DBInstanceClass", valid_605014
  var valid_605015 = query.getOrDefault("Action")
  valid_605015 = validateParameter(valid_605015, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_605015 != nil:
    section.add "Action", valid_605015
  var valid_605016 = query.getOrDefault("UseLatestRestorableTime")
  valid_605016 = validateParameter(valid_605016, JBool, required = false, default = nil)
  if valid_605016 != nil:
    section.add "UseLatestRestorableTime", valid_605016
  var valid_605017 = query.getOrDefault("DBSubnetGroupName")
  valid_605017 = validateParameter(valid_605017, JString, required = false,
                                 default = nil)
  if valid_605017 != nil:
    section.add "DBSubnetGroupName", valid_605017
  var valid_605018 = query.getOrDefault("PubliclyAccessible")
  valid_605018 = validateParameter(valid_605018, JBool, required = false, default = nil)
  if valid_605018 != nil:
    section.add "PubliclyAccessible", valid_605018
  var valid_605019 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_605019 = validateParameter(valid_605019, JBool, required = false, default = nil)
  if valid_605019 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605019
  var valid_605020 = query.getOrDefault("Port")
  valid_605020 = validateParameter(valid_605020, JInt, required = false, default = nil)
  if valid_605020 != nil:
    section.add "Port", valid_605020
  var valid_605021 = query.getOrDefault("Version")
  valid_605021 = validateParameter(valid_605021, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605021 != nil:
    section.add "Version", valid_605021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605022 = header.getOrDefault("X-Amz-Date")
  valid_605022 = validateParameter(valid_605022, JString, required = false,
                                 default = nil)
  if valid_605022 != nil:
    section.add "X-Amz-Date", valid_605022
  var valid_605023 = header.getOrDefault("X-Amz-Security-Token")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "X-Amz-Security-Token", valid_605023
  var valid_605024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605024 = validateParameter(valid_605024, JString, required = false,
                                 default = nil)
  if valid_605024 != nil:
    section.add "X-Amz-Content-Sha256", valid_605024
  var valid_605025 = header.getOrDefault("X-Amz-Algorithm")
  valid_605025 = validateParameter(valid_605025, JString, required = false,
                                 default = nil)
  if valid_605025 != nil:
    section.add "X-Amz-Algorithm", valid_605025
  var valid_605026 = header.getOrDefault("X-Amz-Signature")
  valid_605026 = validateParameter(valid_605026, JString, required = false,
                                 default = nil)
  if valid_605026 != nil:
    section.add "X-Amz-Signature", valid_605026
  var valid_605027 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605027 = validateParameter(valid_605027, JString, required = false,
                                 default = nil)
  if valid_605027 != nil:
    section.add "X-Amz-SignedHeaders", valid_605027
  var valid_605028 = header.getOrDefault("X-Amz-Credential")
  valid_605028 = validateParameter(valid_605028, JString, required = false,
                                 default = nil)
  if valid_605028 != nil:
    section.add "X-Amz-Credential", valid_605028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605029: Call_GetRestoreDBInstanceToPointInTime_605001;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605029.validator(path, query, header, formData, body)
  let scheme = call_605029.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605029.url(scheme.get, call_605029.host, call_605029.base,
                         call_605029.route, valid.getOrDefault("path"))
  result = hook(call_605029, url, valid)

proc call*(call_605030: Call_GetRestoreDBInstanceToPointInTime_605001;
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
  var query_605031 = newJObject()
  add(query_605031, "Engine", newJString(Engine))
  add(query_605031, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_605031, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_605031, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_605031, "Iops", newJInt(Iops))
  add(query_605031, "OptionGroupName", newJString(OptionGroupName))
  add(query_605031, "RestoreTime", newJString(RestoreTime))
  add(query_605031, "MultiAZ", newJBool(MultiAZ))
  add(query_605031, "LicenseModel", newJString(LicenseModel))
  add(query_605031, "DBName", newJString(DBName))
  add(query_605031, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_605031, "Action", newJString(Action))
  add(query_605031, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_605031, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_605031, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_605031, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_605031, "Port", newJInt(Port))
  add(query_605031, "Version", newJString(Version))
  result = call_605030.call(nil, query_605031, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_605001(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_605002, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_605003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_605084 = ref object of OpenApiRestCall_602417
proc url_PostRevokeDBSecurityGroupIngress_605086(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostRevokeDBSecurityGroupIngress_605085(path: JsonNode;
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
  var valid_605087 = query.getOrDefault("Action")
  valid_605087 = validateParameter(valid_605087, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605087 != nil:
    section.add "Action", valid_605087
  var valid_605088 = query.getOrDefault("Version")
  valid_605088 = validateParameter(valid_605088, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605088 != nil:
    section.add "Version", valid_605088
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605089 = header.getOrDefault("X-Amz-Date")
  valid_605089 = validateParameter(valid_605089, JString, required = false,
                                 default = nil)
  if valid_605089 != nil:
    section.add "X-Amz-Date", valid_605089
  var valid_605090 = header.getOrDefault("X-Amz-Security-Token")
  valid_605090 = validateParameter(valid_605090, JString, required = false,
                                 default = nil)
  if valid_605090 != nil:
    section.add "X-Amz-Security-Token", valid_605090
  var valid_605091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605091 = validateParameter(valid_605091, JString, required = false,
                                 default = nil)
  if valid_605091 != nil:
    section.add "X-Amz-Content-Sha256", valid_605091
  var valid_605092 = header.getOrDefault("X-Amz-Algorithm")
  valid_605092 = validateParameter(valid_605092, JString, required = false,
                                 default = nil)
  if valid_605092 != nil:
    section.add "X-Amz-Algorithm", valid_605092
  var valid_605093 = header.getOrDefault("X-Amz-Signature")
  valid_605093 = validateParameter(valid_605093, JString, required = false,
                                 default = nil)
  if valid_605093 != nil:
    section.add "X-Amz-Signature", valid_605093
  var valid_605094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605094 = validateParameter(valid_605094, JString, required = false,
                                 default = nil)
  if valid_605094 != nil:
    section.add "X-Amz-SignedHeaders", valid_605094
  var valid_605095 = header.getOrDefault("X-Amz-Credential")
  valid_605095 = validateParameter(valid_605095, JString, required = false,
                                 default = nil)
  if valid_605095 != nil:
    section.add "X-Amz-Credential", valid_605095
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605096 = formData.getOrDefault("DBSecurityGroupName")
  valid_605096 = validateParameter(valid_605096, JString, required = true,
                                 default = nil)
  if valid_605096 != nil:
    section.add "DBSecurityGroupName", valid_605096
  var valid_605097 = formData.getOrDefault("EC2SecurityGroupName")
  valid_605097 = validateParameter(valid_605097, JString, required = false,
                                 default = nil)
  if valid_605097 != nil:
    section.add "EC2SecurityGroupName", valid_605097
  var valid_605098 = formData.getOrDefault("EC2SecurityGroupId")
  valid_605098 = validateParameter(valid_605098, JString, required = false,
                                 default = nil)
  if valid_605098 != nil:
    section.add "EC2SecurityGroupId", valid_605098
  var valid_605099 = formData.getOrDefault("CIDRIP")
  valid_605099 = validateParameter(valid_605099, JString, required = false,
                                 default = nil)
  if valid_605099 != nil:
    section.add "CIDRIP", valid_605099
  var valid_605100 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605100 = validateParameter(valid_605100, JString, required = false,
                                 default = nil)
  if valid_605100 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605100
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605101: Call_PostRevokeDBSecurityGroupIngress_605084;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605101.validator(path, query, header, formData, body)
  let scheme = call_605101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605101.url(scheme.get, call_605101.host, call_605101.base,
                         call_605101.route, valid.getOrDefault("path"))
  result = hook(call_605101, url, valid)

proc call*(call_605102: Call_PostRevokeDBSecurityGroupIngress_605084;
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
  var query_605103 = newJObject()
  var formData_605104 = newJObject()
  add(formData_605104, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605103, "Action", newJString(Action))
  add(formData_605104, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_605104, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_605104, "CIDRIP", newJString(CIDRIP))
  add(query_605103, "Version", newJString(Version))
  add(formData_605104, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_605102.call(nil, query_605103, nil, formData_605104, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_605084(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_605085, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_605086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_605064 = ref object of OpenApiRestCall_602417
proc url_GetRevokeDBSecurityGroupIngress_605066(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetRevokeDBSecurityGroupIngress_605065(path: JsonNode;
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
  var valid_605067 = query.getOrDefault("EC2SecurityGroupId")
  valid_605067 = validateParameter(valid_605067, JString, required = false,
                                 default = nil)
  if valid_605067 != nil:
    section.add "EC2SecurityGroupId", valid_605067
  var valid_605068 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605068 = validateParameter(valid_605068, JString, required = false,
                                 default = nil)
  if valid_605068 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605068
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605069 = query.getOrDefault("DBSecurityGroupName")
  valid_605069 = validateParameter(valid_605069, JString, required = true,
                                 default = nil)
  if valid_605069 != nil:
    section.add "DBSecurityGroupName", valid_605069
  var valid_605070 = query.getOrDefault("Action")
  valid_605070 = validateParameter(valid_605070, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605070 != nil:
    section.add "Action", valid_605070
  var valid_605071 = query.getOrDefault("CIDRIP")
  valid_605071 = validateParameter(valid_605071, JString, required = false,
                                 default = nil)
  if valid_605071 != nil:
    section.add "CIDRIP", valid_605071
  var valid_605072 = query.getOrDefault("EC2SecurityGroupName")
  valid_605072 = validateParameter(valid_605072, JString, required = false,
                                 default = nil)
  if valid_605072 != nil:
    section.add "EC2SecurityGroupName", valid_605072
  var valid_605073 = query.getOrDefault("Version")
  valid_605073 = validateParameter(valid_605073, JString, required = true,
                                 default = newJString("2013-02-12"))
  if valid_605073 != nil:
    section.add "Version", valid_605073
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605074 = header.getOrDefault("X-Amz-Date")
  valid_605074 = validateParameter(valid_605074, JString, required = false,
                                 default = nil)
  if valid_605074 != nil:
    section.add "X-Amz-Date", valid_605074
  var valid_605075 = header.getOrDefault("X-Amz-Security-Token")
  valid_605075 = validateParameter(valid_605075, JString, required = false,
                                 default = nil)
  if valid_605075 != nil:
    section.add "X-Amz-Security-Token", valid_605075
  var valid_605076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605076 = validateParameter(valid_605076, JString, required = false,
                                 default = nil)
  if valid_605076 != nil:
    section.add "X-Amz-Content-Sha256", valid_605076
  var valid_605077 = header.getOrDefault("X-Amz-Algorithm")
  valid_605077 = validateParameter(valid_605077, JString, required = false,
                                 default = nil)
  if valid_605077 != nil:
    section.add "X-Amz-Algorithm", valid_605077
  var valid_605078 = header.getOrDefault("X-Amz-Signature")
  valid_605078 = validateParameter(valid_605078, JString, required = false,
                                 default = nil)
  if valid_605078 != nil:
    section.add "X-Amz-Signature", valid_605078
  var valid_605079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605079 = validateParameter(valid_605079, JString, required = false,
                                 default = nil)
  if valid_605079 != nil:
    section.add "X-Amz-SignedHeaders", valid_605079
  var valid_605080 = header.getOrDefault("X-Amz-Credential")
  valid_605080 = validateParameter(valid_605080, JString, required = false,
                                 default = nil)
  if valid_605080 != nil:
    section.add "X-Amz-Credential", valid_605080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605081: Call_GetRevokeDBSecurityGroupIngress_605064;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605081.validator(path, query, header, formData, body)
  let scheme = call_605081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605081.url(scheme.get, call_605081.host, call_605081.base,
                         call_605081.route, valid.getOrDefault("path"))
  result = hook(call_605081, url, valid)

proc call*(call_605082: Call_GetRevokeDBSecurityGroupIngress_605064;
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
  var query_605083 = newJObject()
  add(query_605083, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_605083, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_605083, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605083, "Action", newJString(Action))
  add(query_605083, "CIDRIP", newJString(CIDRIP))
  add(query_605083, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_605083, "Version", newJString(Version))
  result = call_605082.call(nil, query_605083, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_605064(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_605065, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_605066,
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

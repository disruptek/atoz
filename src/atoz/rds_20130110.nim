
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_602450 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602450](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602450): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_603059 = ref object of OpenApiRestCall_602450
proc url_PostAddSourceIdentifierToSubscription_603061(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_603060(path: JsonNode;
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
  var valid_603062 = query.getOrDefault("Action")
  valid_603062 = validateParameter(valid_603062, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_603062 != nil:
    section.add "Action", valid_603062
  var valid_603063 = query.getOrDefault("Version")
  valid_603063 = validateParameter(valid_603063, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603063 != nil:
    section.add "Version", valid_603063
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603064 = header.getOrDefault("X-Amz-Date")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "X-Amz-Date", valid_603064
  var valid_603065 = header.getOrDefault("X-Amz-Security-Token")
  valid_603065 = validateParameter(valid_603065, JString, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "X-Amz-Security-Token", valid_603065
  var valid_603066 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "X-Amz-Content-Sha256", valid_603066
  var valid_603067 = header.getOrDefault("X-Amz-Algorithm")
  valid_603067 = validateParameter(valid_603067, JString, required = false,
                                 default = nil)
  if valid_603067 != nil:
    section.add "X-Amz-Algorithm", valid_603067
  var valid_603068 = header.getOrDefault("X-Amz-Signature")
  valid_603068 = validateParameter(valid_603068, JString, required = false,
                                 default = nil)
  if valid_603068 != nil:
    section.add "X-Amz-Signature", valid_603068
  var valid_603069 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603069 = validateParameter(valid_603069, JString, required = false,
                                 default = nil)
  if valid_603069 != nil:
    section.add "X-Amz-SignedHeaders", valid_603069
  var valid_603070 = header.getOrDefault("X-Amz-Credential")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Credential", valid_603070
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_603071 = formData.getOrDefault("SourceIdentifier")
  valid_603071 = validateParameter(valid_603071, JString, required = true,
                                 default = nil)
  if valid_603071 != nil:
    section.add "SourceIdentifier", valid_603071
  var valid_603072 = formData.getOrDefault("SubscriptionName")
  valid_603072 = validateParameter(valid_603072, JString, required = true,
                                 default = nil)
  if valid_603072 != nil:
    section.add "SubscriptionName", valid_603072
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603073: Call_PostAddSourceIdentifierToSubscription_603059;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603073.validator(path, query, header, formData, body)
  let scheme = call_603073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603073.url(scheme.get, call_603073.host, call_603073.base,
                         call_603073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603073, url, valid)

proc call*(call_603074: Call_PostAddSourceIdentifierToSubscription_603059;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603075 = newJObject()
  var formData_603076 = newJObject()
  add(formData_603076, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_603076, "SubscriptionName", newJString(SubscriptionName))
  add(query_603075, "Action", newJString(Action))
  add(query_603075, "Version", newJString(Version))
  result = call_603074.call(nil, query_603075, nil, formData_603076, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_603059(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_603060, base: "/",
    url: url_PostAddSourceIdentifierToSubscription_603061,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_602787 = ref object of OpenApiRestCall_602450
proc url_GetAddSourceIdentifierToSubscription_602789(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_602788(path: JsonNode;
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
  var valid_602914 = query.getOrDefault("Action")
  valid_602914 = validateParameter(valid_602914, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_602914 != nil:
    section.add "Action", valid_602914
  var valid_602915 = query.getOrDefault("SourceIdentifier")
  valid_602915 = validateParameter(valid_602915, JString, required = true,
                                 default = nil)
  if valid_602915 != nil:
    section.add "SourceIdentifier", valid_602915
  var valid_602916 = query.getOrDefault("SubscriptionName")
  valid_602916 = validateParameter(valid_602916, JString, required = true,
                                 default = nil)
  if valid_602916 != nil:
    section.add "SubscriptionName", valid_602916
  var valid_602917 = query.getOrDefault("Version")
  valid_602917 = validateParameter(valid_602917, JString, required = true,
                                 default = newJString("2013-01-10"))
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

proc call*(call_602947: Call_GetAddSourceIdentifierToSubscription_602787;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_602947.validator(path, query, header, formData, body)
  let scheme = call_602947.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602947.url(scheme.get, call_602947.host, call_602947.base,
                         call_602947.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_602947, url, valid)

proc call*(call_603018: Call_GetAddSourceIdentifierToSubscription_602787;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603019 = newJObject()
  add(query_603019, "Action", newJString(Action))
  add(query_603019, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_603019, "SubscriptionName", newJString(SubscriptionName))
  add(query_603019, "Version", newJString(Version))
  result = call_603018.call(nil, query_603019, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_602787(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_602788, base: "/",
    url: url_GetAddSourceIdentifierToSubscription_602789,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_603094 = ref object of OpenApiRestCall_602450
proc url_PostAddTagsToResource_603096(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAddTagsToResource_603095(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603097 = query.getOrDefault("Action")
  valid_603097 = validateParameter(valid_603097, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_603097 != nil:
    section.add "Action", valid_603097
  var valid_603098 = query.getOrDefault("Version")
  valid_603098 = validateParameter(valid_603098, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603098 != nil:
    section.add "Version", valid_603098
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603099 = header.getOrDefault("X-Amz-Date")
  valid_603099 = validateParameter(valid_603099, JString, required = false,
                                 default = nil)
  if valid_603099 != nil:
    section.add "X-Amz-Date", valid_603099
  var valid_603100 = header.getOrDefault("X-Amz-Security-Token")
  valid_603100 = validateParameter(valid_603100, JString, required = false,
                                 default = nil)
  if valid_603100 != nil:
    section.add "X-Amz-Security-Token", valid_603100
  var valid_603101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603101 = validateParameter(valid_603101, JString, required = false,
                                 default = nil)
  if valid_603101 != nil:
    section.add "X-Amz-Content-Sha256", valid_603101
  var valid_603102 = header.getOrDefault("X-Amz-Algorithm")
  valid_603102 = validateParameter(valid_603102, JString, required = false,
                                 default = nil)
  if valid_603102 != nil:
    section.add "X-Amz-Algorithm", valid_603102
  var valid_603103 = header.getOrDefault("X-Amz-Signature")
  valid_603103 = validateParameter(valid_603103, JString, required = false,
                                 default = nil)
  if valid_603103 != nil:
    section.add "X-Amz-Signature", valid_603103
  var valid_603104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603104 = validateParameter(valid_603104, JString, required = false,
                                 default = nil)
  if valid_603104 != nil:
    section.add "X-Amz-SignedHeaders", valid_603104
  var valid_603105 = header.getOrDefault("X-Amz-Credential")
  valid_603105 = validateParameter(valid_603105, JString, required = false,
                                 default = nil)
  if valid_603105 != nil:
    section.add "X-Amz-Credential", valid_603105
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_603106 = formData.getOrDefault("Tags")
  valid_603106 = validateParameter(valid_603106, JArray, required = true, default = nil)
  if valid_603106 != nil:
    section.add "Tags", valid_603106
  var valid_603107 = formData.getOrDefault("ResourceName")
  valid_603107 = validateParameter(valid_603107, JString, required = true,
                                 default = nil)
  if valid_603107 != nil:
    section.add "ResourceName", valid_603107
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603108: Call_PostAddTagsToResource_603094; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603108.validator(path, query, header, formData, body)
  let scheme = call_603108.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603108.url(scheme.get, call_603108.host, call_603108.base,
                         call_603108.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603108, url, valid)

proc call*(call_603109: Call_PostAddTagsToResource_603094; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_603110 = newJObject()
  var formData_603111 = newJObject()
  if Tags != nil:
    formData_603111.add "Tags", Tags
  add(query_603110, "Action", newJString(Action))
  add(formData_603111, "ResourceName", newJString(ResourceName))
  add(query_603110, "Version", newJString(Version))
  result = call_603109.call(nil, query_603110, nil, formData_603111, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_603094(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_603095, base: "/",
    url: url_PostAddTagsToResource_603096, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_603077 = ref object of OpenApiRestCall_602450
proc url_GetAddTagsToResource_603079(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAddTagsToResource_603078(path: JsonNode; query: JsonNode;
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
  var valid_603080 = query.getOrDefault("Tags")
  valid_603080 = validateParameter(valid_603080, JArray, required = true, default = nil)
  if valid_603080 != nil:
    section.add "Tags", valid_603080
  var valid_603081 = query.getOrDefault("ResourceName")
  valid_603081 = validateParameter(valid_603081, JString, required = true,
                                 default = nil)
  if valid_603081 != nil:
    section.add "ResourceName", valid_603081
  var valid_603082 = query.getOrDefault("Action")
  valid_603082 = validateParameter(valid_603082, JString, required = true,
                                 default = newJString("AddTagsToResource"))
  if valid_603082 != nil:
    section.add "Action", valid_603082
  var valid_603083 = query.getOrDefault("Version")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603083 != nil:
    section.add "Version", valid_603083
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603084 = header.getOrDefault("X-Amz-Date")
  valid_603084 = validateParameter(valid_603084, JString, required = false,
                                 default = nil)
  if valid_603084 != nil:
    section.add "X-Amz-Date", valid_603084
  var valid_603085 = header.getOrDefault("X-Amz-Security-Token")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Security-Token", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Content-Sha256", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Algorithm")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Algorithm", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Signature")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Signature", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-SignedHeaders", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-Credential")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-Credential", valid_603090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603091: Call_GetAddTagsToResource_603077; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603091.validator(path, query, header, formData, body)
  let scheme = call_603091.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603091.url(scheme.get, call_603091.host, call_603091.base,
                         call_603091.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603091, url, valid)

proc call*(call_603092: Call_GetAddTagsToResource_603077; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-01-10"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603093 = newJObject()
  if Tags != nil:
    query_603093.add "Tags", Tags
  add(query_603093, "ResourceName", newJString(ResourceName))
  add(query_603093, "Action", newJString(Action))
  add(query_603093, "Version", newJString(Version))
  result = call_603092.call(nil, query_603093, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_603077(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_603078, base: "/",
    url: url_GetAddTagsToResource_603079, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_603132 = ref object of OpenApiRestCall_602450
proc url_PostAuthorizeDBSecurityGroupIngress_603134(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_603133(path: JsonNode;
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
  var valid_603135 = query.getOrDefault("Action")
  valid_603135 = validateParameter(valid_603135, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_603135 != nil:
    section.add "Action", valid_603135
  var valid_603136 = query.getOrDefault("Version")
  valid_603136 = validateParameter(valid_603136, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603136 != nil:
    section.add "Version", valid_603136
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603137 = header.getOrDefault("X-Amz-Date")
  valid_603137 = validateParameter(valid_603137, JString, required = false,
                                 default = nil)
  if valid_603137 != nil:
    section.add "X-Amz-Date", valid_603137
  var valid_603138 = header.getOrDefault("X-Amz-Security-Token")
  valid_603138 = validateParameter(valid_603138, JString, required = false,
                                 default = nil)
  if valid_603138 != nil:
    section.add "X-Amz-Security-Token", valid_603138
  var valid_603139 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603139 = validateParameter(valid_603139, JString, required = false,
                                 default = nil)
  if valid_603139 != nil:
    section.add "X-Amz-Content-Sha256", valid_603139
  var valid_603140 = header.getOrDefault("X-Amz-Algorithm")
  valid_603140 = validateParameter(valid_603140, JString, required = false,
                                 default = nil)
  if valid_603140 != nil:
    section.add "X-Amz-Algorithm", valid_603140
  var valid_603141 = header.getOrDefault("X-Amz-Signature")
  valid_603141 = validateParameter(valid_603141, JString, required = false,
                                 default = nil)
  if valid_603141 != nil:
    section.add "X-Amz-Signature", valid_603141
  var valid_603142 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603142 = validateParameter(valid_603142, JString, required = false,
                                 default = nil)
  if valid_603142 != nil:
    section.add "X-Amz-SignedHeaders", valid_603142
  var valid_603143 = header.getOrDefault("X-Amz-Credential")
  valid_603143 = validateParameter(valid_603143, JString, required = false,
                                 default = nil)
  if valid_603143 != nil:
    section.add "X-Amz-Credential", valid_603143
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603144 = formData.getOrDefault("DBSecurityGroupName")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "DBSecurityGroupName", valid_603144
  var valid_603145 = formData.getOrDefault("EC2SecurityGroupName")
  valid_603145 = validateParameter(valid_603145, JString, required = false,
                                 default = nil)
  if valid_603145 != nil:
    section.add "EC2SecurityGroupName", valid_603145
  var valid_603146 = formData.getOrDefault("EC2SecurityGroupId")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "EC2SecurityGroupId", valid_603146
  var valid_603147 = formData.getOrDefault("CIDRIP")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "CIDRIP", valid_603147
  var valid_603148 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603148
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603149: Call_PostAuthorizeDBSecurityGroupIngress_603132;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603149.validator(path, query, header, formData, body)
  let scheme = call_603149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603149.url(scheme.get, call_603149.host, call_603149.base,
                         call_603149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603149, url, valid)

proc call*(call_603150: Call_PostAuthorizeDBSecurityGroupIngress_603132;
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
  var query_603151 = newJObject()
  var formData_603152 = newJObject()
  add(formData_603152, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603151, "Action", newJString(Action))
  add(formData_603152, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_603152, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_603152, "CIDRIP", newJString(CIDRIP))
  add(query_603151, "Version", newJString(Version))
  add(formData_603152, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_603150.call(nil, query_603151, nil, formData_603152, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_603132(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_603133, base: "/",
    url: url_PostAuthorizeDBSecurityGroupIngress_603134,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_603112 = ref object of OpenApiRestCall_602450
proc url_GetAuthorizeDBSecurityGroupIngress_603114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_603113(path: JsonNode;
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
  var valid_603115 = query.getOrDefault("EC2SecurityGroupId")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "EC2SecurityGroupId", valid_603115
  var valid_603116 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_603116
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603117 = query.getOrDefault("DBSecurityGroupName")
  valid_603117 = validateParameter(valid_603117, JString, required = true,
                                 default = nil)
  if valid_603117 != nil:
    section.add "DBSecurityGroupName", valid_603117
  var valid_603118 = query.getOrDefault("Action")
  valid_603118 = validateParameter(valid_603118, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_603118 != nil:
    section.add "Action", valid_603118
  var valid_603119 = query.getOrDefault("CIDRIP")
  valid_603119 = validateParameter(valid_603119, JString, required = false,
                                 default = nil)
  if valid_603119 != nil:
    section.add "CIDRIP", valid_603119
  var valid_603120 = query.getOrDefault("EC2SecurityGroupName")
  valid_603120 = validateParameter(valid_603120, JString, required = false,
                                 default = nil)
  if valid_603120 != nil:
    section.add "EC2SecurityGroupName", valid_603120
  var valid_603121 = query.getOrDefault("Version")
  valid_603121 = validateParameter(valid_603121, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603121 != nil:
    section.add "Version", valid_603121
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603122 = header.getOrDefault("X-Amz-Date")
  valid_603122 = validateParameter(valid_603122, JString, required = false,
                                 default = nil)
  if valid_603122 != nil:
    section.add "X-Amz-Date", valid_603122
  var valid_603123 = header.getOrDefault("X-Amz-Security-Token")
  valid_603123 = validateParameter(valid_603123, JString, required = false,
                                 default = nil)
  if valid_603123 != nil:
    section.add "X-Amz-Security-Token", valid_603123
  var valid_603124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603124 = validateParameter(valid_603124, JString, required = false,
                                 default = nil)
  if valid_603124 != nil:
    section.add "X-Amz-Content-Sha256", valid_603124
  var valid_603125 = header.getOrDefault("X-Amz-Algorithm")
  valid_603125 = validateParameter(valid_603125, JString, required = false,
                                 default = nil)
  if valid_603125 != nil:
    section.add "X-Amz-Algorithm", valid_603125
  var valid_603126 = header.getOrDefault("X-Amz-Signature")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Signature", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-SignedHeaders", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Credential")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Credential", valid_603128
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603129: Call_GetAuthorizeDBSecurityGroupIngress_603112;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603129.validator(path, query, header, formData, body)
  let scheme = call_603129.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603129.url(scheme.get, call_603129.host, call_603129.base,
                         call_603129.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603129, url, valid)

proc call*(call_603130: Call_GetAuthorizeDBSecurityGroupIngress_603112;
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
  var query_603131 = newJObject()
  add(query_603131, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_603131, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_603131, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603131, "Action", newJString(Action))
  add(query_603131, "CIDRIP", newJString(CIDRIP))
  add(query_603131, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_603131, "Version", newJString(Version))
  result = call_603130.call(nil, query_603131, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_603112(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_603113, base: "/",
    url: url_GetAuthorizeDBSecurityGroupIngress_603114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_603170 = ref object of OpenApiRestCall_602450
proc url_PostCopyDBSnapshot_603172(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCopyDBSnapshot_603171(path: JsonNode; query: JsonNode;
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
  var valid_603173 = query.getOrDefault("Action")
  valid_603173 = validateParameter(valid_603173, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603173 != nil:
    section.add "Action", valid_603173
  var valid_603174 = query.getOrDefault("Version")
  valid_603174 = validateParameter(valid_603174, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603174 != nil:
    section.add "Version", valid_603174
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603175 = header.getOrDefault("X-Amz-Date")
  valid_603175 = validateParameter(valid_603175, JString, required = false,
                                 default = nil)
  if valid_603175 != nil:
    section.add "X-Amz-Date", valid_603175
  var valid_603176 = header.getOrDefault("X-Amz-Security-Token")
  valid_603176 = validateParameter(valid_603176, JString, required = false,
                                 default = nil)
  if valid_603176 != nil:
    section.add "X-Amz-Security-Token", valid_603176
  var valid_603177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603177 = validateParameter(valid_603177, JString, required = false,
                                 default = nil)
  if valid_603177 != nil:
    section.add "X-Amz-Content-Sha256", valid_603177
  var valid_603178 = header.getOrDefault("X-Amz-Algorithm")
  valid_603178 = validateParameter(valid_603178, JString, required = false,
                                 default = nil)
  if valid_603178 != nil:
    section.add "X-Amz-Algorithm", valid_603178
  var valid_603179 = header.getOrDefault("X-Amz-Signature")
  valid_603179 = validateParameter(valid_603179, JString, required = false,
                                 default = nil)
  if valid_603179 != nil:
    section.add "X-Amz-Signature", valid_603179
  var valid_603180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-SignedHeaders", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Credential")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Credential", valid_603181
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_603182 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603182 = validateParameter(valid_603182, JString, required = true,
                                 default = nil)
  if valid_603182 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603182
  var valid_603183 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603183 = validateParameter(valid_603183, JString, required = true,
                                 default = nil)
  if valid_603183 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603183
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603184: Call_PostCopyDBSnapshot_603170; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603184.validator(path, query, header, formData, body)
  let scheme = call_603184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603184.url(scheme.get, call_603184.host, call_603184.base,
                         call_603184.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603184, url, valid)

proc call*(call_603185: Call_PostCopyDBSnapshot_603170;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603186 = newJObject()
  var formData_603187 = newJObject()
  add(formData_603187, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603186, "Action", newJString(Action))
  add(formData_603187, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603186, "Version", newJString(Version))
  result = call_603185.call(nil, query_603186, nil, formData_603187, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_603170(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_603171, base: "/",
    url: url_PostCopyDBSnapshot_603172, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_603153 = ref object of OpenApiRestCall_602450
proc url_GetCopyDBSnapshot_603155(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCopyDBSnapshot_603154(path: JsonNode; query: JsonNode;
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
  var valid_603156 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_603156 = validateParameter(valid_603156, JString, required = true,
                                 default = nil)
  if valid_603156 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_603156
  var valid_603157 = query.getOrDefault("Action")
  valid_603157 = validateParameter(valid_603157, JString, required = true,
                                 default = newJString("CopyDBSnapshot"))
  if valid_603157 != nil:
    section.add "Action", valid_603157
  var valid_603158 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_603158 = validateParameter(valid_603158, JString, required = true,
                                 default = nil)
  if valid_603158 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_603158
  var valid_603159 = query.getOrDefault("Version")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603159 != nil:
    section.add "Version", valid_603159
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603160 = header.getOrDefault("X-Amz-Date")
  valid_603160 = validateParameter(valid_603160, JString, required = false,
                                 default = nil)
  if valid_603160 != nil:
    section.add "X-Amz-Date", valid_603160
  var valid_603161 = header.getOrDefault("X-Amz-Security-Token")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Security-Token", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Content-Sha256", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Algorithm")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Algorithm", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Signature")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Signature", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-SignedHeaders", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-Credential")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-Credential", valid_603166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603167: Call_GetCopyDBSnapshot_603153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603167.validator(path, query, header, formData, body)
  let scheme = call_603167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603167.url(scheme.get, call_603167.host, call_603167.base,
                         call_603167.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603167, url, valid)

proc call*(call_603168: Call_GetCopyDBSnapshot_603153;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Action: string = "CopyDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_603169 = newJObject()
  add(query_603169, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_603169, "Action", newJString(Action))
  add(query_603169, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_603169, "Version", newJString(Version))
  result = call_603168.call(nil, query_603169, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_603153(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_603154,
    base: "/", url: url_GetCopyDBSnapshot_603155,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_603227 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBInstance_603229(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstance_603228(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603230 = query.getOrDefault("Action")
  valid_603230 = validateParameter(valid_603230, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603230 != nil:
    section.add "Action", valid_603230
  var valid_603231 = query.getOrDefault("Version")
  valid_603231 = validateParameter(valid_603231, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603231 != nil:
    section.add "Version", valid_603231
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603232 = header.getOrDefault("X-Amz-Date")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Date", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Security-Token")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Security-Token", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Content-Sha256", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-Algorithm")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-Algorithm", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Signature")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Signature", valid_603236
  var valid_603237 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603237 = validateParameter(valid_603237, JString, required = false,
                                 default = nil)
  if valid_603237 != nil:
    section.add "X-Amz-SignedHeaders", valid_603237
  var valid_603238 = header.getOrDefault("X-Amz-Credential")
  valid_603238 = validateParameter(valid_603238, JString, required = false,
                                 default = nil)
  if valid_603238 != nil:
    section.add "X-Amz-Credential", valid_603238
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
  var valid_603239 = formData.getOrDefault("DBSecurityGroups")
  valid_603239 = validateParameter(valid_603239, JArray, required = false,
                                 default = nil)
  if valid_603239 != nil:
    section.add "DBSecurityGroups", valid_603239
  var valid_603240 = formData.getOrDefault("Port")
  valid_603240 = validateParameter(valid_603240, JInt, required = false, default = nil)
  if valid_603240 != nil:
    section.add "Port", valid_603240
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_603241 = formData.getOrDefault("Engine")
  valid_603241 = validateParameter(valid_603241, JString, required = true,
                                 default = nil)
  if valid_603241 != nil:
    section.add "Engine", valid_603241
  var valid_603242 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_603242 = validateParameter(valid_603242, JArray, required = false,
                                 default = nil)
  if valid_603242 != nil:
    section.add "VpcSecurityGroupIds", valid_603242
  var valid_603243 = formData.getOrDefault("Iops")
  valid_603243 = validateParameter(valid_603243, JInt, required = false, default = nil)
  if valid_603243 != nil:
    section.add "Iops", valid_603243
  var valid_603244 = formData.getOrDefault("DBName")
  valid_603244 = validateParameter(valid_603244, JString, required = false,
                                 default = nil)
  if valid_603244 != nil:
    section.add "DBName", valid_603244
  var valid_603245 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603245 = validateParameter(valid_603245, JString, required = true,
                                 default = nil)
  if valid_603245 != nil:
    section.add "DBInstanceIdentifier", valid_603245
  var valid_603246 = formData.getOrDefault("BackupRetentionPeriod")
  valid_603246 = validateParameter(valid_603246, JInt, required = false, default = nil)
  if valid_603246 != nil:
    section.add "BackupRetentionPeriod", valid_603246
  var valid_603247 = formData.getOrDefault("DBParameterGroupName")
  valid_603247 = validateParameter(valid_603247, JString, required = false,
                                 default = nil)
  if valid_603247 != nil:
    section.add "DBParameterGroupName", valid_603247
  var valid_603248 = formData.getOrDefault("OptionGroupName")
  valid_603248 = validateParameter(valid_603248, JString, required = false,
                                 default = nil)
  if valid_603248 != nil:
    section.add "OptionGroupName", valid_603248
  var valid_603249 = formData.getOrDefault("MasterUserPassword")
  valid_603249 = validateParameter(valid_603249, JString, required = true,
                                 default = nil)
  if valid_603249 != nil:
    section.add "MasterUserPassword", valid_603249
  var valid_603250 = formData.getOrDefault("DBSubnetGroupName")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "DBSubnetGroupName", valid_603250
  var valid_603251 = formData.getOrDefault("AvailabilityZone")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "AvailabilityZone", valid_603251
  var valid_603252 = formData.getOrDefault("MultiAZ")
  valid_603252 = validateParameter(valid_603252, JBool, required = false, default = nil)
  if valid_603252 != nil:
    section.add "MultiAZ", valid_603252
  var valid_603253 = formData.getOrDefault("AllocatedStorage")
  valid_603253 = validateParameter(valid_603253, JInt, required = true, default = nil)
  if valid_603253 != nil:
    section.add "AllocatedStorage", valid_603253
  var valid_603254 = formData.getOrDefault("PubliclyAccessible")
  valid_603254 = validateParameter(valid_603254, JBool, required = false, default = nil)
  if valid_603254 != nil:
    section.add "PubliclyAccessible", valid_603254
  var valid_603255 = formData.getOrDefault("MasterUsername")
  valid_603255 = validateParameter(valid_603255, JString, required = true,
                                 default = nil)
  if valid_603255 != nil:
    section.add "MasterUsername", valid_603255
  var valid_603256 = formData.getOrDefault("DBInstanceClass")
  valid_603256 = validateParameter(valid_603256, JString, required = true,
                                 default = nil)
  if valid_603256 != nil:
    section.add "DBInstanceClass", valid_603256
  var valid_603257 = formData.getOrDefault("CharacterSetName")
  valid_603257 = validateParameter(valid_603257, JString, required = false,
                                 default = nil)
  if valid_603257 != nil:
    section.add "CharacterSetName", valid_603257
  var valid_603258 = formData.getOrDefault("PreferredBackupWindow")
  valid_603258 = validateParameter(valid_603258, JString, required = false,
                                 default = nil)
  if valid_603258 != nil:
    section.add "PreferredBackupWindow", valid_603258
  var valid_603259 = formData.getOrDefault("LicenseModel")
  valid_603259 = validateParameter(valid_603259, JString, required = false,
                                 default = nil)
  if valid_603259 != nil:
    section.add "LicenseModel", valid_603259
  var valid_603260 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603260 = validateParameter(valid_603260, JBool, required = false, default = nil)
  if valid_603260 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603260
  var valid_603261 = formData.getOrDefault("EngineVersion")
  valid_603261 = validateParameter(valid_603261, JString, required = false,
                                 default = nil)
  if valid_603261 != nil:
    section.add "EngineVersion", valid_603261
  var valid_603262 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_603262 = validateParameter(valid_603262, JString, required = false,
                                 default = nil)
  if valid_603262 != nil:
    section.add "PreferredMaintenanceWindow", valid_603262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603263: Call_PostCreateDBInstance_603227; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603263.validator(path, query, header, formData, body)
  let scheme = call_603263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603263.url(scheme.get, call_603263.host, call_603263.base,
                         call_603263.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603263, url, valid)

proc call*(call_603264: Call_PostCreateDBInstance_603227; Engine: string;
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
  var query_603265 = newJObject()
  var formData_603266 = newJObject()
  if DBSecurityGroups != nil:
    formData_603266.add "DBSecurityGroups", DBSecurityGroups
  add(formData_603266, "Port", newJInt(Port))
  add(formData_603266, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_603266.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_603266, "Iops", newJInt(Iops))
  add(formData_603266, "DBName", newJString(DBName))
  add(formData_603266, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603266, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_603266, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603266, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603266, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_603266, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_603266, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_603266, "MultiAZ", newJBool(MultiAZ))
  add(query_603265, "Action", newJString(Action))
  add(formData_603266, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_603266, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603266, "MasterUsername", newJString(MasterUsername))
  add(formData_603266, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603266, "CharacterSetName", newJString(CharacterSetName))
  add(formData_603266, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_603266, "LicenseModel", newJString(LicenseModel))
  add(formData_603266, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_603266, "EngineVersion", newJString(EngineVersion))
  add(query_603265, "Version", newJString(Version))
  add(formData_603266, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_603264.call(nil, query_603265, nil, formData_603266, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_603227(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_603228, base: "/",
    url: url_PostCreateDBInstance_603229, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_603188 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBInstance_603190(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstance_603189(path: JsonNode; query: JsonNode;
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
  var valid_603191 = query.getOrDefault("Engine")
  valid_603191 = validateParameter(valid_603191, JString, required = true,
                                 default = nil)
  if valid_603191 != nil:
    section.add "Engine", valid_603191
  var valid_603192 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_603192 = validateParameter(valid_603192, JString, required = false,
                                 default = nil)
  if valid_603192 != nil:
    section.add "PreferredMaintenanceWindow", valid_603192
  var valid_603193 = query.getOrDefault("AllocatedStorage")
  valid_603193 = validateParameter(valid_603193, JInt, required = true, default = nil)
  if valid_603193 != nil:
    section.add "AllocatedStorage", valid_603193
  var valid_603194 = query.getOrDefault("OptionGroupName")
  valid_603194 = validateParameter(valid_603194, JString, required = false,
                                 default = nil)
  if valid_603194 != nil:
    section.add "OptionGroupName", valid_603194
  var valid_603195 = query.getOrDefault("DBSecurityGroups")
  valid_603195 = validateParameter(valid_603195, JArray, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "DBSecurityGroups", valid_603195
  var valid_603196 = query.getOrDefault("MasterUserPassword")
  valid_603196 = validateParameter(valid_603196, JString, required = true,
                                 default = nil)
  if valid_603196 != nil:
    section.add "MasterUserPassword", valid_603196
  var valid_603197 = query.getOrDefault("AvailabilityZone")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "AvailabilityZone", valid_603197
  var valid_603198 = query.getOrDefault("Iops")
  valid_603198 = validateParameter(valid_603198, JInt, required = false, default = nil)
  if valid_603198 != nil:
    section.add "Iops", valid_603198
  var valid_603199 = query.getOrDefault("VpcSecurityGroupIds")
  valid_603199 = validateParameter(valid_603199, JArray, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "VpcSecurityGroupIds", valid_603199
  var valid_603200 = query.getOrDefault("MultiAZ")
  valid_603200 = validateParameter(valid_603200, JBool, required = false, default = nil)
  if valid_603200 != nil:
    section.add "MultiAZ", valid_603200
  var valid_603201 = query.getOrDefault("LicenseModel")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "LicenseModel", valid_603201
  var valid_603202 = query.getOrDefault("BackupRetentionPeriod")
  valid_603202 = validateParameter(valid_603202, JInt, required = false, default = nil)
  if valid_603202 != nil:
    section.add "BackupRetentionPeriod", valid_603202
  var valid_603203 = query.getOrDefault("DBName")
  valid_603203 = validateParameter(valid_603203, JString, required = false,
                                 default = nil)
  if valid_603203 != nil:
    section.add "DBName", valid_603203
  var valid_603204 = query.getOrDefault("DBParameterGroupName")
  valid_603204 = validateParameter(valid_603204, JString, required = false,
                                 default = nil)
  if valid_603204 != nil:
    section.add "DBParameterGroupName", valid_603204
  var valid_603205 = query.getOrDefault("DBInstanceClass")
  valid_603205 = validateParameter(valid_603205, JString, required = true,
                                 default = nil)
  if valid_603205 != nil:
    section.add "DBInstanceClass", valid_603205
  var valid_603206 = query.getOrDefault("Action")
  valid_603206 = validateParameter(valid_603206, JString, required = true,
                                 default = newJString("CreateDBInstance"))
  if valid_603206 != nil:
    section.add "Action", valid_603206
  var valid_603207 = query.getOrDefault("DBSubnetGroupName")
  valid_603207 = validateParameter(valid_603207, JString, required = false,
                                 default = nil)
  if valid_603207 != nil:
    section.add "DBSubnetGroupName", valid_603207
  var valid_603208 = query.getOrDefault("CharacterSetName")
  valid_603208 = validateParameter(valid_603208, JString, required = false,
                                 default = nil)
  if valid_603208 != nil:
    section.add "CharacterSetName", valid_603208
  var valid_603209 = query.getOrDefault("PubliclyAccessible")
  valid_603209 = validateParameter(valid_603209, JBool, required = false, default = nil)
  if valid_603209 != nil:
    section.add "PubliclyAccessible", valid_603209
  var valid_603210 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603210 = validateParameter(valid_603210, JBool, required = false, default = nil)
  if valid_603210 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603210
  var valid_603211 = query.getOrDefault("EngineVersion")
  valid_603211 = validateParameter(valid_603211, JString, required = false,
                                 default = nil)
  if valid_603211 != nil:
    section.add "EngineVersion", valid_603211
  var valid_603212 = query.getOrDefault("Port")
  valid_603212 = validateParameter(valid_603212, JInt, required = false, default = nil)
  if valid_603212 != nil:
    section.add "Port", valid_603212
  var valid_603213 = query.getOrDefault("PreferredBackupWindow")
  valid_603213 = validateParameter(valid_603213, JString, required = false,
                                 default = nil)
  if valid_603213 != nil:
    section.add "PreferredBackupWindow", valid_603213
  var valid_603214 = query.getOrDefault("Version")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603214 != nil:
    section.add "Version", valid_603214
  var valid_603215 = query.getOrDefault("DBInstanceIdentifier")
  valid_603215 = validateParameter(valid_603215, JString, required = true,
                                 default = nil)
  if valid_603215 != nil:
    section.add "DBInstanceIdentifier", valid_603215
  var valid_603216 = query.getOrDefault("MasterUsername")
  valid_603216 = validateParameter(valid_603216, JString, required = true,
                                 default = nil)
  if valid_603216 != nil:
    section.add "MasterUsername", valid_603216
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603217 = header.getOrDefault("X-Amz-Date")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Date", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Security-Token")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Security-Token", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Content-Sha256", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-Algorithm")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-Algorithm", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Signature")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Signature", valid_603221
  var valid_603222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603222 = validateParameter(valid_603222, JString, required = false,
                                 default = nil)
  if valid_603222 != nil:
    section.add "X-Amz-SignedHeaders", valid_603222
  var valid_603223 = header.getOrDefault("X-Amz-Credential")
  valid_603223 = validateParameter(valid_603223, JString, required = false,
                                 default = nil)
  if valid_603223 != nil:
    section.add "X-Amz-Credential", valid_603223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603224: Call_GetCreateDBInstance_603188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603224.validator(path, query, header, formData, body)
  let scheme = call_603224.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603224.url(scheme.get, call_603224.host, call_603224.base,
                         call_603224.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603224, url, valid)

proc call*(call_603225: Call_GetCreateDBInstance_603188; Engine: string;
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
  var query_603226 = newJObject()
  add(query_603226, "Engine", newJString(Engine))
  add(query_603226, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_603226, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_603226, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_603226.add "DBSecurityGroups", DBSecurityGroups
  add(query_603226, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_603226, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603226, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_603226.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_603226, "MultiAZ", newJBool(MultiAZ))
  add(query_603226, "LicenseModel", newJString(LicenseModel))
  add(query_603226, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_603226, "DBName", newJString(DBName))
  add(query_603226, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603226, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603226, "Action", newJString(Action))
  add(query_603226, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603226, "CharacterSetName", newJString(CharacterSetName))
  add(query_603226, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603226, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603226, "EngineVersion", newJString(EngineVersion))
  add(query_603226, "Port", newJInt(Port))
  add(query_603226, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_603226, "Version", newJString(Version))
  add(query_603226, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603226, "MasterUsername", newJString(MasterUsername))
  result = call_603225.call(nil, query_603226, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_603188(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_603189, base: "/",
    url: url_GetCreateDBInstance_603190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_603291 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBInstanceReadReplica_603293(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_603292(path: JsonNode;
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
  var valid_603294 = query.getOrDefault("Action")
  valid_603294 = validateParameter(valid_603294, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603294 != nil:
    section.add "Action", valid_603294
  var valid_603295 = query.getOrDefault("Version")
  valid_603295 = validateParameter(valid_603295, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603295 != nil:
    section.add "Version", valid_603295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603296 = header.getOrDefault("X-Amz-Date")
  valid_603296 = validateParameter(valid_603296, JString, required = false,
                                 default = nil)
  if valid_603296 != nil:
    section.add "X-Amz-Date", valid_603296
  var valid_603297 = header.getOrDefault("X-Amz-Security-Token")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Security-Token", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Content-Sha256", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Algorithm")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Algorithm", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Signature")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Signature", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-SignedHeaders", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-Credential")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-Credential", valid_603302
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
  var valid_603303 = formData.getOrDefault("Port")
  valid_603303 = validateParameter(valid_603303, JInt, required = false, default = nil)
  if valid_603303 != nil:
    section.add "Port", valid_603303
  var valid_603304 = formData.getOrDefault("Iops")
  valid_603304 = validateParameter(valid_603304, JInt, required = false, default = nil)
  if valid_603304 != nil:
    section.add "Iops", valid_603304
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603305 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603305 = validateParameter(valid_603305, JString, required = true,
                                 default = nil)
  if valid_603305 != nil:
    section.add "DBInstanceIdentifier", valid_603305
  var valid_603306 = formData.getOrDefault("OptionGroupName")
  valid_603306 = validateParameter(valid_603306, JString, required = false,
                                 default = nil)
  if valid_603306 != nil:
    section.add "OptionGroupName", valid_603306
  var valid_603307 = formData.getOrDefault("AvailabilityZone")
  valid_603307 = validateParameter(valid_603307, JString, required = false,
                                 default = nil)
  if valid_603307 != nil:
    section.add "AvailabilityZone", valid_603307
  var valid_603308 = formData.getOrDefault("PubliclyAccessible")
  valid_603308 = validateParameter(valid_603308, JBool, required = false, default = nil)
  if valid_603308 != nil:
    section.add "PubliclyAccessible", valid_603308
  var valid_603309 = formData.getOrDefault("DBInstanceClass")
  valid_603309 = validateParameter(valid_603309, JString, required = false,
                                 default = nil)
  if valid_603309 != nil:
    section.add "DBInstanceClass", valid_603309
  var valid_603310 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_603310 = validateParameter(valid_603310, JString, required = true,
                                 default = nil)
  if valid_603310 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603310
  var valid_603311 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_603311 = validateParameter(valid_603311, JBool, required = false, default = nil)
  if valid_603311 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603311
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603312: Call_PostCreateDBInstanceReadReplica_603291;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_603312.validator(path, query, header, formData, body)
  let scheme = call_603312.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603312.url(scheme.get, call_603312.host, call_603312.base,
                         call_603312.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603312, url, valid)

proc call*(call_603313: Call_PostCreateDBInstanceReadReplica_603291;
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
  var query_603314 = newJObject()
  var formData_603315 = newJObject()
  add(formData_603315, "Port", newJInt(Port))
  add(formData_603315, "Iops", newJInt(Iops))
  add(formData_603315, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603315, "OptionGroupName", newJString(OptionGroupName))
  add(formData_603315, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603314, "Action", newJString(Action))
  add(formData_603315, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_603315, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_603315, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_603315, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_603314, "Version", newJString(Version))
  result = call_603313.call(nil, query_603314, nil, formData_603315, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_603291(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_603292, base: "/",
    url: url_PostCreateDBInstanceReadReplica_603293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_603267 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBInstanceReadReplica_603269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_603268(path: JsonNode;
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
  var valid_603270 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_603270 = validateParameter(valid_603270, JString, required = true,
                                 default = nil)
  if valid_603270 != nil:
    section.add "SourceDBInstanceIdentifier", valid_603270
  var valid_603271 = query.getOrDefault("OptionGroupName")
  valid_603271 = validateParameter(valid_603271, JString, required = false,
                                 default = nil)
  if valid_603271 != nil:
    section.add "OptionGroupName", valid_603271
  var valid_603272 = query.getOrDefault("AvailabilityZone")
  valid_603272 = validateParameter(valid_603272, JString, required = false,
                                 default = nil)
  if valid_603272 != nil:
    section.add "AvailabilityZone", valid_603272
  var valid_603273 = query.getOrDefault("Iops")
  valid_603273 = validateParameter(valid_603273, JInt, required = false, default = nil)
  if valid_603273 != nil:
    section.add "Iops", valid_603273
  var valid_603274 = query.getOrDefault("DBInstanceClass")
  valid_603274 = validateParameter(valid_603274, JString, required = false,
                                 default = nil)
  if valid_603274 != nil:
    section.add "DBInstanceClass", valid_603274
  var valid_603275 = query.getOrDefault("Action")
  valid_603275 = validateParameter(valid_603275, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_603275 != nil:
    section.add "Action", valid_603275
  var valid_603276 = query.getOrDefault("PubliclyAccessible")
  valid_603276 = validateParameter(valid_603276, JBool, required = false, default = nil)
  if valid_603276 != nil:
    section.add "PubliclyAccessible", valid_603276
  var valid_603277 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_603277 = validateParameter(valid_603277, JBool, required = false, default = nil)
  if valid_603277 != nil:
    section.add "AutoMinorVersionUpgrade", valid_603277
  var valid_603278 = query.getOrDefault("Port")
  valid_603278 = validateParameter(valid_603278, JInt, required = false, default = nil)
  if valid_603278 != nil:
    section.add "Port", valid_603278
  var valid_603279 = query.getOrDefault("Version")
  valid_603279 = validateParameter(valid_603279, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603279 != nil:
    section.add "Version", valid_603279
  var valid_603280 = query.getOrDefault("DBInstanceIdentifier")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = nil)
  if valid_603280 != nil:
    section.add "DBInstanceIdentifier", valid_603280
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603281 = header.getOrDefault("X-Amz-Date")
  valid_603281 = validateParameter(valid_603281, JString, required = false,
                                 default = nil)
  if valid_603281 != nil:
    section.add "X-Amz-Date", valid_603281
  var valid_603282 = header.getOrDefault("X-Amz-Security-Token")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Security-Token", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Content-Sha256", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Algorithm")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Algorithm", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Signature")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Signature", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-SignedHeaders", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-Credential")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-Credential", valid_603287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603288: Call_GetCreateDBInstanceReadReplica_603267; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603288.validator(path, query, header, formData, body)
  let scheme = call_603288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603288.url(scheme.get, call_603288.host, call_603288.base,
                         call_603288.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603288, url, valid)

proc call*(call_603289: Call_GetCreateDBInstanceReadReplica_603267;
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
  var query_603290 = newJObject()
  add(query_603290, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_603290, "OptionGroupName", newJString(OptionGroupName))
  add(query_603290, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_603290, "Iops", newJInt(Iops))
  add(query_603290, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_603290, "Action", newJString(Action))
  add(query_603290, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_603290, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_603290, "Port", newJInt(Port))
  add(query_603290, "Version", newJString(Version))
  add(query_603290, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603289.call(nil, query_603290, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_603267(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_603268, base: "/",
    url: url_GetCreateDBInstanceReadReplica_603269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_603334 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBParameterGroup_603336(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBParameterGroup_603335(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603337 = query.getOrDefault("Action")
  valid_603337 = validateParameter(valid_603337, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603337 != nil:
    section.add "Action", valid_603337
  var valid_603338 = query.getOrDefault("Version")
  valid_603338 = validateParameter(valid_603338, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603338 != nil:
    section.add "Version", valid_603338
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603346 = formData.getOrDefault("DBParameterGroupName")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = nil)
  if valid_603346 != nil:
    section.add "DBParameterGroupName", valid_603346
  var valid_603347 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = nil)
  if valid_603347 != nil:
    section.add "DBParameterGroupFamily", valid_603347
  var valid_603348 = formData.getOrDefault("Description")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = nil)
  if valid_603348 != nil:
    section.add "Description", valid_603348
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603349: Call_PostCreateDBParameterGroup_603334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603349.validator(path, query, header, formData, body)
  let scheme = call_603349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603349.url(scheme.get, call_603349.host, call_603349.base,
                         call_603349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603349, url, valid)

proc call*(call_603350: Call_PostCreateDBParameterGroup_603334;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Action: string = "CreateDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_603351 = newJObject()
  var formData_603352 = newJObject()
  add(formData_603352, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603351, "Action", newJString(Action))
  add(formData_603352, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_603351, "Version", newJString(Version))
  add(formData_603352, "Description", newJString(Description))
  result = call_603350.call(nil, query_603351, nil, formData_603352, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_603334(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_603335, base: "/",
    url: url_PostCreateDBParameterGroup_603336,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_603316 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBParameterGroup_603318(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBParameterGroup_603317(path: JsonNode; query: JsonNode;
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
  var valid_603319 = query.getOrDefault("Description")
  valid_603319 = validateParameter(valid_603319, JString, required = true,
                                 default = nil)
  if valid_603319 != nil:
    section.add "Description", valid_603319
  var valid_603320 = query.getOrDefault("DBParameterGroupFamily")
  valid_603320 = validateParameter(valid_603320, JString, required = true,
                                 default = nil)
  if valid_603320 != nil:
    section.add "DBParameterGroupFamily", valid_603320
  var valid_603321 = query.getOrDefault("DBParameterGroupName")
  valid_603321 = validateParameter(valid_603321, JString, required = true,
                                 default = nil)
  if valid_603321 != nil:
    section.add "DBParameterGroupName", valid_603321
  var valid_603322 = query.getOrDefault("Action")
  valid_603322 = validateParameter(valid_603322, JString, required = true,
                                 default = newJString("CreateDBParameterGroup"))
  if valid_603322 != nil:
    section.add "Action", valid_603322
  var valid_603323 = query.getOrDefault("Version")
  valid_603323 = validateParameter(valid_603323, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603323 != nil:
    section.add "Version", valid_603323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603324 = header.getOrDefault("X-Amz-Date")
  valid_603324 = validateParameter(valid_603324, JString, required = false,
                                 default = nil)
  if valid_603324 != nil:
    section.add "X-Amz-Date", valid_603324
  var valid_603325 = header.getOrDefault("X-Amz-Security-Token")
  valid_603325 = validateParameter(valid_603325, JString, required = false,
                                 default = nil)
  if valid_603325 != nil:
    section.add "X-Amz-Security-Token", valid_603325
  var valid_603326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603326 = validateParameter(valid_603326, JString, required = false,
                                 default = nil)
  if valid_603326 != nil:
    section.add "X-Amz-Content-Sha256", valid_603326
  var valid_603327 = header.getOrDefault("X-Amz-Algorithm")
  valid_603327 = validateParameter(valid_603327, JString, required = false,
                                 default = nil)
  if valid_603327 != nil:
    section.add "X-Amz-Algorithm", valid_603327
  var valid_603328 = header.getOrDefault("X-Amz-Signature")
  valid_603328 = validateParameter(valid_603328, JString, required = false,
                                 default = nil)
  if valid_603328 != nil:
    section.add "X-Amz-Signature", valid_603328
  var valid_603329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603329 = validateParameter(valid_603329, JString, required = false,
                                 default = nil)
  if valid_603329 != nil:
    section.add "X-Amz-SignedHeaders", valid_603329
  var valid_603330 = header.getOrDefault("X-Amz-Credential")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Credential", valid_603330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603331: Call_GetCreateDBParameterGroup_603316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603331.validator(path, query, header, formData, body)
  let scheme = call_603331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603331.url(scheme.get, call_603331.host, call_603331.base,
                         call_603331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603331, url, valid)

proc call*(call_603332: Call_GetCreateDBParameterGroup_603316; Description: string;
          DBParameterGroupFamily: string; DBParameterGroupName: string;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603333 = newJObject()
  add(query_603333, "Description", newJString(Description))
  add(query_603333, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_603333, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603333, "Action", newJString(Action))
  add(query_603333, "Version", newJString(Version))
  result = call_603332.call(nil, query_603333, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_603316(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_603317, base: "/",
    url: url_GetCreateDBParameterGroup_603318,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_603370 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSecurityGroup_603372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSecurityGroup_603371(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603373 = query.getOrDefault("Action")
  valid_603373 = validateParameter(valid_603373, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603373 != nil:
    section.add "Action", valid_603373
  var valid_603374 = query.getOrDefault("Version")
  valid_603374 = validateParameter(valid_603374, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603374 != nil:
    section.add "Version", valid_603374
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603382 = formData.getOrDefault("DBSecurityGroupName")
  valid_603382 = validateParameter(valid_603382, JString, required = true,
                                 default = nil)
  if valid_603382 != nil:
    section.add "DBSecurityGroupName", valid_603382
  var valid_603383 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_603383 = validateParameter(valid_603383, JString, required = true,
                                 default = nil)
  if valid_603383 != nil:
    section.add "DBSecurityGroupDescription", valid_603383
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603384: Call_PostCreateDBSecurityGroup_603370; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603384.validator(path, query, header, formData, body)
  let scheme = call_603384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603384.url(scheme.get, call_603384.host, call_603384.base,
                         call_603384.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603384, url, valid)

proc call*(call_603385: Call_PostCreateDBSecurityGroup_603370;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_603386 = newJObject()
  var formData_603387 = newJObject()
  add(formData_603387, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603386, "Action", newJString(Action))
  add(formData_603387, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603386, "Version", newJString(Version))
  result = call_603385.call(nil, query_603386, nil, formData_603387, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_603370(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_603371, base: "/",
    url: url_PostCreateDBSecurityGroup_603372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_603353 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSecurityGroup_603355(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSecurityGroup_603354(path: JsonNode; query: JsonNode;
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
  var valid_603356 = query.getOrDefault("DBSecurityGroupName")
  valid_603356 = validateParameter(valid_603356, JString, required = true,
                                 default = nil)
  if valid_603356 != nil:
    section.add "DBSecurityGroupName", valid_603356
  var valid_603357 = query.getOrDefault("DBSecurityGroupDescription")
  valid_603357 = validateParameter(valid_603357, JString, required = true,
                                 default = nil)
  if valid_603357 != nil:
    section.add "DBSecurityGroupDescription", valid_603357
  var valid_603358 = query.getOrDefault("Action")
  valid_603358 = validateParameter(valid_603358, JString, required = true,
                                 default = newJString("CreateDBSecurityGroup"))
  if valid_603358 != nil:
    section.add "Action", valid_603358
  var valid_603359 = query.getOrDefault("Version")
  valid_603359 = validateParameter(valid_603359, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603359 != nil:
    section.add "Version", valid_603359
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603360 = header.getOrDefault("X-Amz-Date")
  valid_603360 = validateParameter(valid_603360, JString, required = false,
                                 default = nil)
  if valid_603360 != nil:
    section.add "X-Amz-Date", valid_603360
  var valid_603361 = header.getOrDefault("X-Amz-Security-Token")
  valid_603361 = validateParameter(valid_603361, JString, required = false,
                                 default = nil)
  if valid_603361 != nil:
    section.add "X-Amz-Security-Token", valid_603361
  var valid_603362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603362 = validateParameter(valid_603362, JString, required = false,
                                 default = nil)
  if valid_603362 != nil:
    section.add "X-Amz-Content-Sha256", valid_603362
  var valid_603363 = header.getOrDefault("X-Amz-Algorithm")
  valid_603363 = validateParameter(valid_603363, JString, required = false,
                                 default = nil)
  if valid_603363 != nil:
    section.add "X-Amz-Algorithm", valid_603363
  var valid_603364 = header.getOrDefault("X-Amz-Signature")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Signature", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-SignedHeaders", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Credential")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Credential", valid_603366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603367: Call_GetCreateDBSecurityGroup_603353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603367.validator(path, query, header, formData, body)
  let scheme = call_603367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603367.url(scheme.get, call_603367.host, call_603367.base,
                         call_603367.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603367, url, valid)

proc call*(call_603368: Call_GetCreateDBSecurityGroup_603353;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Action: string = "CreateDBSecurityGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603369 = newJObject()
  add(query_603369, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603369, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_603369, "Action", newJString(Action))
  add(query_603369, "Version", newJString(Version))
  result = call_603368.call(nil, query_603369, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_603353(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_603354, base: "/",
    url: url_GetCreateDBSecurityGroup_603355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_603405 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSnapshot_603407(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSnapshot_603406(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603408 = query.getOrDefault("Action")
  valid_603408 = validateParameter(valid_603408, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603408 != nil:
    section.add "Action", valid_603408
  var valid_603409 = query.getOrDefault("Version")
  valid_603409 = validateParameter(valid_603409, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603409 != nil:
    section.add "Version", valid_603409
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603410 = header.getOrDefault("X-Amz-Date")
  valid_603410 = validateParameter(valid_603410, JString, required = false,
                                 default = nil)
  if valid_603410 != nil:
    section.add "X-Amz-Date", valid_603410
  var valid_603411 = header.getOrDefault("X-Amz-Security-Token")
  valid_603411 = validateParameter(valid_603411, JString, required = false,
                                 default = nil)
  if valid_603411 != nil:
    section.add "X-Amz-Security-Token", valid_603411
  var valid_603412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603412 = validateParameter(valid_603412, JString, required = false,
                                 default = nil)
  if valid_603412 != nil:
    section.add "X-Amz-Content-Sha256", valid_603412
  var valid_603413 = header.getOrDefault("X-Amz-Algorithm")
  valid_603413 = validateParameter(valid_603413, JString, required = false,
                                 default = nil)
  if valid_603413 != nil:
    section.add "X-Amz-Algorithm", valid_603413
  var valid_603414 = header.getOrDefault("X-Amz-Signature")
  valid_603414 = validateParameter(valid_603414, JString, required = false,
                                 default = nil)
  if valid_603414 != nil:
    section.add "X-Amz-Signature", valid_603414
  var valid_603415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603415 = validateParameter(valid_603415, JString, required = false,
                                 default = nil)
  if valid_603415 != nil:
    section.add "X-Amz-SignedHeaders", valid_603415
  var valid_603416 = header.getOrDefault("X-Amz-Credential")
  valid_603416 = validateParameter(valid_603416, JString, required = false,
                                 default = nil)
  if valid_603416 != nil:
    section.add "X-Amz-Credential", valid_603416
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603417 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603417 = validateParameter(valid_603417, JString, required = true,
                                 default = nil)
  if valid_603417 != nil:
    section.add "DBInstanceIdentifier", valid_603417
  var valid_603418 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603418 = validateParameter(valid_603418, JString, required = true,
                                 default = nil)
  if valid_603418 != nil:
    section.add "DBSnapshotIdentifier", valid_603418
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603419: Call_PostCreateDBSnapshot_603405; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603419.validator(path, query, header, formData, body)
  let scheme = call_603419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603419.url(scheme.get, call_603419.host, call_603419.base,
                         call_603419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603419, url, valid)

proc call*(call_603420: Call_PostCreateDBSnapshot_603405;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603421 = newJObject()
  var formData_603422 = newJObject()
  add(formData_603422, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603422, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603421, "Action", newJString(Action))
  add(query_603421, "Version", newJString(Version))
  result = call_603420.call(nil, query_603421, nil, formData_603422, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_603405(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_603406, base: "/",
    url: url_PostCreateDBSnapshot_603407, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_603388 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSnapshot_603390(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSnapshot_603389(path: JsonNode; query: JsonNode;
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
  var valid_603391 = query.getOrDefault("Action")
  valid_603391 = validateParameter(valid_603391, JString, required = true,
                                 default = newJString("CreateDBSnapshot"))
  if valid_603391 != nil:
    section.add "Action", valid_603391
  var valid_603392 = query.getOrDefault("Version")
  valid_603392 = validateParameter(valid_603392, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603392 != nil:
    section.add "Version", valid_603392
  var valid_603393 = query.getOrDefault("DBInstanceIdentifier")
  valid_603393 = validateParameter(valid_603393, JString, required = true,
                                 default = nil)
  if valid_603393 != nil:
    section.add "DBInstanceIdentifier", valid_603393
  var valid_603394 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603394 = validateParameter(valid_603394, JString, required = true,
                                 default = nil)
  if valid_603394 != nil:
    section.add "DBSnapshotIdentifier", valid_603394
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603395 = header.getOrDefault("X-Amz-Date")
  valid_603395 = validateParameter(valid_603395, JString, required = false,
                                 default = nil)
  if valid_603395 != nil:
    section.add "X-Amz-Date", valid_603395
  var valid_603396 = header.getOrDefault("X-Amz-Security-Token")
  valid_603396 = validateParameter(valid_603396, JString, required = false,
                                 default = nil)
  if valid_603396 != nil:
    section.add "X-Amz-Security-Token", valid_603396
  var valid_603397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603397 = validateParameter(valid_603397, JString, required = false,
                                 default = nil)
  if valid_603397 != nil:
    section.add "X-Amz-Content-Sha256", valid_603397
  var valid_603398 = header.getOrDefault("X-Amz-Algorithm")
  valid_603398 = validateParameter(valid_603398, JString, required = false,
                                 default = nil)
  if valid_603398 != nil:
    section.add "X-Amz-Algorithm", valid_603398
  var valid_603399 = header.getOrDefault("X-Amz-Signature")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Signature", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-SignedHeaders", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Credential")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Credential", valid_603401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603402: Call_GetCreateDBSnapshot_603388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603402.validator(path, query, header, formData, body)
  let scheme = call_603402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603402.url(scheme.get, call_603402.host, call_603402.base,
                         call_603402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603402, url, valid)

proc call*(call_603403: Call_GetCreateDBSnapshot_603388;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Action: string = "CreateDBSnapshot"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603404 = newJObject()
  add(query_603404, "Action", newJString(Action))
  add(query_603404, "Version", newJString(Version))
  add(query_603404, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603404, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603403.call(nil, query_603404, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_603388(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_603389, base: "/",
    url: url_GetCreateDBSnapshot_603390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_603441 = ref object of OpenApiRestCall_602450
proc url_PostCreateDBSubnetGroup_603443(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateDBSubnetGroup_603442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603444 = query.getOrDefault("Action")
  valid_603444 = validateParameter(valid_603444, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603444 != nil:
    section.add "Action", valid_603444
  var valid_603445 = query.getOrDefault("Version")
  valid_603445 = validateParameter(valid_603445, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603445 != nil:
    section.add "Version", valid_603445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603446 = header.getOrDefault("X-Amz-Date")
  valid_603446 = validateParameter(valid_603446, JString, required = false,
                                 default = nil)
  if valid_603446 != nil:
    section.add "X-Amz-Date", valid_603446
  var valid_603447 = header.getOrDefault("X-Amz-Security-Token")
  valid_603447 = validateParameter(valid_603447, JString, required = false,
                                 default = nil)
  if valid_603447 != nil:
    section.add "X-Amz-Security-Token", valid_603447
  var valid_603448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603448 = validateParameter(valid_603448, JString, required = false,
                                 default = nil)
  if valid_603448 != nil:
    section.add "X-Amz-Content-Sha256", valid_603448
  var valid_603449 = header.getOrDefault("X-Amz-Algorithm")
  valid_603449 = validateParameter(valid_603449, JString, required = false,
                                 default = nil)
  if valid_603449 != nil:
    section.add "X-Amz-Algorithm", valid_603449
  var valid_603450 = header.getOrDefault("X-Amz-Signature")
  valid_603450 = validateParameter(valid_603450, JString, required = false,
                                 default = nil)
  if valid_603450 != nil:
    section.add "X-Amz-Signature", valid_603450
  var valid_603451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-SignedHeaders", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Credential")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Credential", valid_603452
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603453 = formData.getOrDefault("DBSubnetGroupName")
  valid_603453 = validateParameter(valid_603453, JString, required = true,
                                 default = nil)
  if valid_603453 != nil:
    section.add "DBSubnetGroupName", valid_603453
  var valid_603454 = formData.getOrDefault("SubnetIds")
  valid_603454 = validateParameter(valid_603454, JArray, required = true, default = nil)
  if valid_603454 != nil:
    section.add "SubnetIds", valid_603454
  var valid_603455 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_603455 = validateParameter(valid_603455, JString, required = true,
                                 default = nil)
  if valid_603455 != nil:
    section.add "DBSubnetGroupDescription", valid_603455
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603456: Call_PostCreateDBSubnetGroup_603441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603456.validator(path, query, header, formData, body)
  let scheme = call_603456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603456.url(scheme.get, call_603456.host, call_603456.base,
                         call_603456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603456, url, valid)

proc call*(call_603457: Call_PostCreateDBSubnetGroup_603441;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_603458 = newJObject()
  var formData_603459 = newJObject()
  add(formData_603459, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_603459.add "SubnetIds", SubnetIds
  add(query_603458, "Action", newJString(Action))
  add(formData_603459, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603458, "Version", newJString(Version))
  result = call_603457.call(nil, query_603458, nil, formData_603459, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_603441(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_603442, base: "/",
    url: url_PostCreateDBSubnetGroup_603443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_603423 = ref object of OpenApiRestCall_602450
proc url_GetCreateDBSubnetGroup_603425(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateDBSubnetGroup_603424(path: JsonNode; query: JsonNode;
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
  var valid_603426 = query.getOrDefault("Action")
  valid_603426 = validateParameter(valid_603426, JString, required = true,
                                 default = newJString("CreateDBSubnetGroup"))
  if valid_603426 != nil:
    section.add "Action", valid_603426
  var valid_603427 = query.getOrDefault("DBSubnetGroupName")
  valid_603427 = validateParameter(valid_603427, JString, required = true,
                                 default = nil)
  if valid_603427 != nil:
    section.add "DBSubnetGroupName", valid_603427
  var valid_603428 = query.getOrDefault("SubnetIds")
  valid_603428 = validateParameter(valid_603428, JArray, required = true, default = nil)
  if valid_603428 != nil:
    section.add "SubnetIds", valid_603428
  var valid_603429 = query.getOrDefault("DBSubnetGroupDescription")
  valid_603429 = validateParameter(valid_603429, JString, required = true,
                                 default = nil)
  if valid_603429 != nil:
    section.add "DBSubnetGroupDescription", valid_603429
  var valid_603430 = query.getOrDefault("Version")
  valid_603430 = validateParameter(valid_603430, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603430 != nil:
    section.add "Version", valid_603430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603431 = header.getOrDefault("X-Amz-Date")
  valid_603431 = validateParameter(valid_603431, JString, required = false,
                                 default = nil)
  if valid_603431 != nil:
    section.add "X-Amz-Date", valid_603431
  var valid_603432 = header.getOrDefault("X-Amz-Security-Token")
  valid_603432 = validateParameter(valid_603432, JString, required = false,
                                 default = nil)
  if valid_603432 != nil:
    section.add "X-Amz-Security-Token", valid_603432
  var valid_603433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Content-Sha256", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Algorithm")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Algorithm", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Signature")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Signature", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-SignedHeaders", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Credential")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Credential", valid_603437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603438: Call_GetCreateDBSubnetGroup_603423; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603438.validator(path, query, header, formData, body)
  let scheme = call_603438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603438.url(scheme.get, call_603438.host, call_603438.base,
                         call_603438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603438, url, valid)

proc call*(call_603439: Call_GetCreateDBSubnetGroup_603423;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-01-10"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_603440 = newJObject()
  add(query_603440, "Action", newJString(Action))
  add(query_603440, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_603440.add "SubnetIds", SubnetIds
  add(query_603440, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_603440, "Version", newJString(Version))
  result = call_603439.call(nil, query_603440, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_603423(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_603424, base: "/",
    url: url_GetCreateDBSubnetGroup_603425, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_603481 = ref object of OpenApiRestCall_602450
proc url_PostCreateEventSubscription_603483(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateEventSubscription_603482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603484 = query.getOrDefault("Action")
  valid_603484 = validateParameter(valid_603484, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603484 != nil:
    section.add "Action", valid_603484
  var valid_603485 = query.getOrDefault("Version")
  valid_603485 = validateParameter(valid_603485, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603485 != nil:
    section.add "Version", valid_603485
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603486 = header.getOrDefault("X-Amz-Date")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Date", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Security-Token")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Security-Token", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Content-Sha256", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-Algorithm")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-Algorithm", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Signature")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Signature", valid_603490
  var valid_603491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603491 = validateParameter(valid_603491, JString, required = false,
                                 default = nil)
  if valid_603491 != nil:
    section.add "X-Amz-SignedHeaders", valid_603491
  var valid_603492 = header.getOrDefault("X-Amz-Credential")
  valid_603492 = validateParameter(valid_603492, JString, required = false,
                                 default = nil)
  if valid_603492 != nil:
    section.add "X-Amz-Credential", valid_603492
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_603493 = formData.getOrDefault("Enabled")
  valid_603493 = validateParameter(valid_603493, JBool, required = false, default = nil)
  if valid_603493 != nil:
    section.add "Enabled", valid_603493
  var valid_603494 = formData.getOrDefault("EventCategories")
  valid_603494 = validateParameter(valid_603494, JArray, required = false,
                                 default = nil)
  if valid_603494 != nil:
    section.add "EventCategories", valid_603494
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_603495 = formData.getOrDefault("SnsTopicArn")
  valid_603495 = validateParameter(valid_603495, JString, required = true,
                                 default = nil)
  if valid_603495 != nil:
    section.add "SnsTopicArn", valid_603495
  var valid_603496 = formData.getOrDefault("SourceIds")
  valid_603496 = validateParameter(valid_603496, JArray, required = false,
                                 default = nil)
  if valid_603496 != nil:
    section.add "SourceIds", valid_603496
  var valid_603497 = formData.getOrDefault("SubscriptionName")
  valid_603497 = validateParameter(valid_603497, JString, required = true,
                                 default = nil)
  if valid_603497 != nil:
    section.add "SubscriptionName", valid_603497
  var valid_603498 = formData.getOrDefault("SourceType")
  valid_603498 = validateParameter(valid_603498, JString, required = false,
                                 default = nil)
  if valid_603498 != nil:
    section.add "SourceType", valid_603498
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603499: Call_PostCreateEventSubscription_603481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603499.validator(path, query, header, formData, body)
  let scheme = call_603499.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603499.url(scheme.get, call_603499.host, call_603499.base,
                         call_603499.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603499, url, valid)

proc call*(call_603500: Call_PostCreateEventSubscription_603481;
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
  var query_603501 = newJObject()
  var formData_603502 = newJObject()
  add(formData_603502, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_603502.add "EventCategories", EventCategories
  add(formData_603502, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_603502.add "SourceIds", SourceIds
  add(formData_603502, "SubscriptionName", newJString(SubscriptionName))
  add(query_603501, "Action", newJString(Action))
  add(query_603501, "Version", newJString(Version))
  add(formData_603502, "SourceType", newJString(SourceType))
  result = call_603500.call(nil, query_603501, nil, formData_603502, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_603481(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_603482, base: "/",
    url: url_PostCreateEventSubscription_603483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_603460 = ref object of OpenApiRestCall_602450
proc url_GetCreateEventSubscription_603462(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateEventSubscription_603461(path: JsonNode; query: JsonNode;
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
  var valid_603463 = query.getOrDefault("SourceType")
  valid_603463 = validateParameter(valid_603463, JString, required = false,
                                 default = nil)
  if valid_603463 != nil:
    section.add "SourceType", valid_603463
  var valid_603464 = query.getOrDefault("SourceIds")
  valid_603464 = validateParameter(valid_603464, JArray, required = false,
                                 default = nil)
  if valid_603464 != nil:
    section.add "SourceIds", valid_603464
  var valid_603465 = query.getOrDefault("Enabled")
  valid_603465 = validateParameter(valid_603465, JBool, required = false, default = nil)
  if valid_603465 != nil:
    section.add "Enabled", valid_603465
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603466 = query.getOrDefault("Action")
  valid_603466 = validateParameter(valid_603466, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_603466 != nil:
    section.add "Action", valid_603466
  var valid_603467 = query.getOrDefault("SnsTopicArn")
  valid_603467 = validateParameter(valid_603467, JString, required = true,
                                 default = nil)
  if valid_603467 != nil:
    section.add "SnsTopicArn", valid_603467
  var valid_603468 = query.getOrDefault("EventCategories")
  valid_603468 = validateParameter(valid_603468, JArray, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "EventCategories", valid_603468
  var valid_603469 = query.getOrDefault("SubscriptionName")
  valid_603469 = validateParameter(valid_603469, JString, required = true,
                                 default = nil)
  if valid_603469 != nil:
    section.add "SubscriptionName", valid_603469
  var valid_603470 = query.getOrDefault("Version")
  valid_603470 = validateParameter(valid_603470, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603470 != nil:
    section.add "Version", valid_603470
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603471 = header.getOrDefault("X-Amz-Date")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-Date", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Security-Token")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Security-Token", valid_603472
  var valid_603473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603473 = validateParameter(valid_603473, JString, required = false,
                                 default = nil)
  if valid_603473 != nil:
    section.add "X-Amz-Content-Sha256", valid_603473
  var valid_603474 = header.getOrDefault("X-Amz-Algorithm")
  valid_603474 = validateParameter(valid_603474, JString, required = false,
                                 default = nil)
  if valid_603474 != nil:
    section.add "X-Amz-Algorithm", valid_603474
  var valid_603475 = header.getOrDefault("X-Amz-Signature")
  valid_603475 = validateParameter(valid_603475, JString, required = false,
                                 default = nil)
  if valid_603475 != nil:
    section.add "X-Amz-Signature", valid_603475
  var valid_603476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603476 = validateParameter(valid_603476, JString, required = false,
                                 default = nil)
  if valid_603476 != nil:
    section.add "X-Amz-SignedHeaders", valid_603476
  var valid_603477 = header.getOrDefault("X-Amz-Credential")
  valid_603477 = validateParameter(valid_603477, JString, required = false,
                                 default = nil)
  if valid_603477 != nil:
    section.add "X-Amz-Credential", valid_603477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603478: Call_GetCreateEventSubscription_603460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603478.validator(path, query, header, formData, body)
  let scheme = call_603478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603478.url(scheme.get, call_603478.host, call_603478.base,
                         call_603478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603478, url, valid)

proc call*(call_603479: Call_GetCreateEventSubscription_603460;
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
  var query_603480 = newJObject()
  add(query_603480, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_603480.add "SourceIds", SourceIds
  add(query_603480, "Enabled", newJBool(Enabled))
  add(query_603480, "Action", newJString(Action))
  add(query_603480, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_603480.add "EventCategories", EventCategories
  add(query_603480, "SubscriptionName", newJString(SubscriptionName))
  add(query_603480, "Version", newJString(Version))
  result = call_603479.call(nil, query_603480, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_603460(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_603461, base: "/",
    url: url_GetCreateEventSubscription_603462,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_603522 = ref object of OpenApiRestCall_602450
proc url_PostCreateOptionGroup_603524(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostCreateOptionGroup_603523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603525 = query.getOrDefault("Action")
  valid_603525 = validateParameter(valid_603525, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603525 != nil:
    section.add "Action", valid_603525
  var valid_603526 = query.getOrDefault("Version")
  valid_603526 = validateParameter(valid_603526, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603526 != nil:
    section.add "Version", valid_603526
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603527 = header.getOrDefault("X-Amz-Date")
  valid_603527 = validateParameter(valid_603527, JString, required = false,
                                 default = nil)
  if valid_603527 != nil:
    section.add "X-Amz-Date", valid_603527
  var valid_603528 = header.getOrDefault("X-Amz-Security-Token")
  valid_603528 = validateParameter(valid_603528, JString, required = false,
                                 default = nil)
  if valid_603528 != nil:
    section.add "X-Amz-Security-Token", valid_603528
  var valid_603529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603529 = validateParameter(valid_603529, JString, required = false,
                                 default = nil)
  if valid_603529 != nil:
    section.add "X-Amz-Content-Sha256", valid_603529
  var valid_603530 = header.getOrDefault("X-Amz-Algorithm")
  valid_603530 = validateParameter(valid_603530, JString, required = false,
                                 default = nil)
  if valid_603530 != nil:
    section.add "X-Amz-Algorithm", valid_603530
  var valid_603531 = header.getOrDefault("X-Amz-Signature")
  valid_603531 = validateParameter(valid_603531, JString, required = false,
                                 default = nil)
  if valid_603531 != nil:
    section.add "X-Amz-Signature", valid_603531
  var valid_603532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-SignedHeaders", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Credential")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Credential", valid_603533
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_603534 = formData.getOrDefault("MajorEngineVersion")
  valid_603534 = validateParameter(valid_603534, JString, required = true,
                                 default = nil)
  if valid_603534 != nil:
    section.add "MajorEngineVersion", valid_603534
  var valid_603535 = formData.getOrDefault("OptionGroupName")
  valid_603535 = validateParameter(valid_603535, JString, required = true,
                                 default = nil)
  if valid_603535 != nil:
    section.add "OptionGroupName", valid_603535
  var valid_603536 = formData.getOrDefault("EngineName")
  valid_603536 = validateParameter(valid_603536, JString, required = true,
                                 default = nil)
  if valid_603536 != nil:
    section.add "EngineName", valid_603536
  var valid_603537 = formData.getOrDefault("OptionGroupDescription")
  valid_603537 = validateParameter(valid_603537, JString, required = true,
                                 default = nil)
  if valid_603537 != nil:
    section.add "OptionGroupDescription", valid_603537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603538: Call_PostCreateOptionGroup_603522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603538.validator(path, query, header, formData, body)
  let scheme = call_603538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603538.url(scheme.get, call_603538.host, call_603538.base,
                         call_603538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603538, url, valid)

proc call*(call_603539: Call_PostCreateOptionGroup_603522;
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
  var query_603540 = newJObject()
  var formData_603541 = newJObject()
  add(formData_603541, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_603541, "OptionGroupName", newJString(OptionGroupName))
  add(query_603540, "Action", newJString(Action))
  add(formData_603541, "EngineName", newJString(EngineName))
  add(formData_603541, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_603540, "Version", newJString(Version))
  result = call_603539.call(nil, query_603540, nil, formData_603541, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_603522(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_603523, base: "/",
    url: url_PostCreateOptionGroup_603524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_603503 = ref object of OpenApiRestCall_602450
proc url_GetCreateOptionGroup_603505(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetCreateOptionGroup_603504(path: JsonNode; query: JsonNode;
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
  var valid_603506 = query.getOrDefault("OptionGroupName")
  valid_603506 = validateParameter(valid_603506, JString, required = true,
                                 default = nil)
  if valid_603506 != nil:
    section.add "OptionGroupName", valid_603506
  var valid_603507 = query.getOrDefault("OptionGroupDescription")
  valid_603507 = validateParameter(valid_603507, JString, required = true,
                                 default = nil)
  if valid_603507 != nil:
    section.add "OptionGroupDescription", valid_603507
  var valid_603508 = query.getOrDefault("Action")
  valid_603508 = validateParameter(valid_603508, JString, required = true,
                                 default = newJString("CreateOptionGroup"))
  if valid_603508 != nil:
    section.add "Action", valid_603508
  var valid_603509 = query.getOrDefault("Version")
  valid_603509 = validateParameter(valid_603509, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603509 != nil:
    section.add "Version", valid_603509
  var valid_603510 = query.getOrDefault("EngineName")
  valid_603510 = validateParameter(valid_603510, JString, required = true,
                                 default = nil)
  if valid_603510 != nil:
    section.add "EngineName", valid_603510
  var valid_603511 = query.getOrDefault("MajorEngineVersion")
  valid_603511 = validateParameter(valid_603511, JString, required = true,
                                 default = nil)
  if valid_603511 != nil:
    section.add "MajorEngineVersion", valid_603511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603512 = header.getOrDefault("X-Amz-Date")
  valid_603512 = validateParameter(valid_603512, JString, required = false,
                                 default = nil)
  if valid_603512 != nil:
    section.add "X-Amz-Date", valid_603512
  var valid_603513 = header.getOrDefault("X-Amz-Security-Token")
  valid_603513 = validateParameter(valid_603513, JString, required = false,
                                 default = nil)
  if valid_603513 != nil:
    section.add "X-Amz-Security-Token", valid_603513
  var valid_603514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603514 = validateParameter(valid_603514, JString, required = false,
                                 default = nil)
  if valid_603514 != nil:
    section.add "X-Amz-Content-Sha256", valid_603514
  var valid_603515 = header.getOrDefault("X-Amz-Algorithm")
  valid_603515 = validateParameter(valid_603515, JString, required = false,
                                 default = nil)
  if valid_603515 != nil:
    section.add "X-Amz-Algorithm", valid_603515
  var valid_603516 = header.getOrDefault("X-Amz-Signature")
  valid_603516 = validateParameter(valid_603516, JString, required = false,
                                 default = nil)
  if valid_603516 != nil:
    section.add "X-Amz-Signature", valid_603516
  var valid_603517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-SignedHeaders", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Credential")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Credential", valid_603518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603519: Call_GetCreateOptionGroup_603503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603519.validator(path, query, header, formData, body)
  let scheme = call_603519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603519.url(scheme.get, call_603519.host, call_603519.base,
                         call_603519.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603519, url, valid)

proc call*(call_603520: Call_GetCreateOptionGroup_603503; OptionGroupName: string;
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
  var query_603521 = newJObject()
  add(query_603521, "OptionGroupName", newJString(OptionGroupName))
  add(query_603521, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_603521, "Action", newJString(Action))
  add(query_603521, "Version", newJString(Version))
  add(query_603521, "EngineName", newJString(EngineName))
  add(query_603521, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_603520.call(nil, query_603521, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_603503(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_603504, base: "/",
    url: url_GetCreateOptionGroup_603505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_603560 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBInstance_603562(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBInstance_603561(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603563 = query.getOrDefault("Action")
  valid_603563 = validateParameter(valid_603563, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603563 != nil:
    section.add "Action", valid_603563
  var valid_603564 = query.getOrDefault("Version")
  valid_603564 = validateParameter(valid_603564, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603564 != nil:
    section.add "Version", valid_603564
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603565 = header.getOrDefault("X-Amz-Date")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Date", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Security-Token")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Security-Token", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Content-Sha256", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Algorithm")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Algorithm", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Signature")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Signature", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-SignedHeaders", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Credential")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Credential", valid_603571
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_603572 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603572 = validateParameter(valid_603572, JString, required = true,
                                 default = nil)
  if valid_603572 != nil:
    section.add "DBInstanceIdentifier", valid_603572
  var valid_603573 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603573 = validateParameter(valid_603573, JString, required = false,
                                 default = nil)
  if valid_603573 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603573
  var valid_603574 = formData.getOrDefault("SkipFinalSnapshot")
  valid_603574 = validateParameter(valid_603574, JBool, required = false, default = nil)
  if valid_603574 != nil:
    section.add "SkipFinalSnapshot", valid_603574
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603575: Call_PostDeleteDBInstance_603560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603575.validator(path, query, header, formData, body)
  let scheme = call_603575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603575.url(scheme.get, call_603575.host, call_603575.base,
                         call_603575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603575, url, valid)

proc call*(call_603576: Call_PostDeleteDBInstance_603560;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-01-10";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_603577 = newJObject()
  var formData_603578 = newJObject()
  add(formData_603578, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603578, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603577, "Action", newJString(Action))
  add(query_603577, "Version", newJString(Version))
  add(formData_603578, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_603576.call(nil, query_603577, nil, formData_603578, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_603560(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_603561, base: "/",
    url: url_PostDeleteDBInstance_603562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_603542 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBInstance_603544(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBInstance_603543(path: JsonNode; query: JsonNode;
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
  var valid_603545 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_603545 = validateParameter(valid_603545, JString, required = false,
                                 default = nil)
  if valid_603545 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_603545
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603546 = query.getOrDefault("Action")
  valid_603546 = validateParameter(valid_603546, JString, required = true,
                                 default = newJString("DeleteDBInstance"))
  if valid_603546 != nil:
    section.add "Action", valid_603546
  var valid_603547 = query.getOrDefault("SkipFinalSnapshot")
  valid_603547 = validateParameter(valid_603547, JBool, required = false, default = nil)
  if valid_603547 != nil:
    section.add "SkipFinalSnapshot", valid_603547
  var valid_603548 = query.getOrDefault("Version")
  valid_603548 = validateParameter(valid_603548, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603548 != nil:
    section.add "Version", valid_603548
  var valid_603549 = query.getOrDefault("DBInstanceIdentifier")
  valid_603549 = validateParameter(valid_603549, JString, required = true,
                                 default = nil)
  if valid_603549 != nil:
    section.add "DBInstanceIdentifier", valid_603549
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603550 = header.getOrDefault("X-Amz-Date")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Date", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Security-Token")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Security-Token", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Content-Sha256", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Algorithm")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Algorithm", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Signature")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Signature", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-SignedHeaders", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Credential")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Credential", valid_603556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603557: Call_GetDeleteDBInstance_603542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603557.validator(path, query, header, formData, body)
  let scheme = call_603557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603557.url(scheme.get, call_603557.host, call_603557.base,
                         call_603557.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603557, url, valid)

proc call*(call_603558: Call_GetDeleteDBInstance_603542;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_603559 = newJObject()
  add(query_603559, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_603559, "Action", newJString(Action))
  add(query_603559, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_603559, "Version", newJString(Version))
  add(query_603559, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603558.call(nil, query_603559, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_603542(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_603543, base: "/",
    url: url_GetDeleteDBInstance_603544, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_603595 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBParameterGroup_603597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBParameterGroup_603596(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603598 != nil:
    section.add "Action", valid_603598
  var valid_603599 = query.getOrDefault("Version")
  valid_603599 = validateParameter(valid_603599, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603607 = formData.getOrDefault("DBParameterGroupName")
  valid_603607 = validateParameter(valid_603607, JString, required = true,
                                 default = nil)
  if valid_603607 != nil:
    section.add "DBParameterGroupName", valid_603607
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603608: Call_PostDeleteDBParameterGroup_603595; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603608.validator(path, query, header, formData, body)
  let scheme = call_603608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603608.url(scheme.get, call_603608.host, call_603608.base,
                         call_603608.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603608, url, valid)

proc call*(call_603609: Call_PostDeleteDBParameterGroup_603595;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603610 = newJObject()
  var formData_603611 = newJObject()
  add(formData_603611, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603610, "Action", newJString(Action))
  add(query_603610, "Version", newJString(Version))
  result = call_603609.call(nil, query_603610, nil, formData_603611, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_603595(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_603596, base: "/",
    url: url_PostDeleteDBParameterGroup_603597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_603579 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBParameterGroup_603581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBParameterGroup_603580(path: JsonNode; query: JsonNode;
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
  var valid_603582 = query.getOrDefault("DBParameterGroupName")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = nil)
  if valid_603582 != nil:
    section.add "DBParameterGroupName", valid_603582
  var valid_603583 = query.getOrDefault("Action")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = newJString("DeleteDBParameterGroup"))
  if valid_603583 != nil:
    section.add "Action", valid_603583
  var valid_603584 = query.getOrDefault("Version")
  valid_603584 = validateParameter(valid_603584, JString, required = true,
                                 default = newJString("2013-01-10"))
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

proc call*(call_603592: Call_GetDeleteDBParameterGroup_603579; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603592.validator(path, query, header, formData, body)
  let scheme = call_603592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603592.url(scheme.get, call_603592.host, call_603592.base,
                         call_603592.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603592, url, valid)

proc call*(call_603593: Call_GetDeleteDBParameterGroup_603579;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603594 = newJObject()
  add(query_603594, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603594, "Action", newJString(Action))
  add(query_603594, "Version", newJString(Version))
  result = call_603593.call(nil, query_603594, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_603579(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_603580, base: "/",
    url: url_GetDeleteDBParameterGroup_603581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_603628 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSecurityGroup_603630(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSecurityGroup_603629(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603631 != nil:
    section.add "Action", valid_603631
  var valid_603632 = query.getOrDefault("Version")
  valid_603632 = validateParameter(valid_603632, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_603640 = formData.getOrDefault("DBSecurityGroupName")
  valid_603640 = validateParameter(valid_603640, JString, required = true,
                                 default = nil)
  if valid_603640 != nil:
    section.add "DBSecurityGroupName", valid_603640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603641: Call_PostDeleteDBSecurityGroup_603628; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603641.validator(path, query, header, formData, body)
  let scheme = call_603641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603641.url(scheme.get, call_603641.host, call_603641.base,
                         call_603641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603641, url, valid)

proc call*(call_603642: Call_PostDeleteDBSecurityGroup_603628;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603643 = newJObject()
  var formData_603644 = newJObject()
  add(formData_603644, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603643, "Action", newJString(Action))
  add(query_603643, "Version", newJString(Version))
  result = call_603642.call(nil, query_603643, nil, formData_603644, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_603628(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_603629, base: "/",
    url: url_PostDeleteDBSecurityGroup_603630,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_603612 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSecurityGroup_603614(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSecurityGroup_603613(path: JsonNode; query: JsonNode;
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
  var valid_603615 = query.getOrDefault("DBSecurityGroupName")
  valid_603615 = validateParameter(valid_603615, JString, required = true,
                                 default = nil)
  if valid_603615 != nil:
    section.add "DBSecurityGroupName", valid_603615
  var valid_603616 = query.getOrDefault("Action")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = newJString("DeleteDBSecurityGroup"))
  if valid_603616 != nil:
    section.add "Action", valid_603616
  var valid_603617 = query.getOrDefault("Version")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603617 != nil:
    section.add "Version", valid_603617
  result.add "query", section
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

proc call*(call_603625: Call_GetDeleteDBSecurityGroup_603612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603625.validator(path, query, header, formData, body)
  let scheme = call_603625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603625.url(scheme.get, call_603625.host, call_603625.base,
                         call_603625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603625, url, valid)

proc call*(call_603626: Call_GetDeleteDBSecurityGroup_603612;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603627 = newJObject()
  add(query_603627, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603627, "Action", newJString(Action))
  add(query_603627, "Version", newJString(Version))
  result = call_603626.call(nil, query_603627, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_603612(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_603613, base: "/",
    url: url_GetDeleteDBSecurityGroup_603614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_603661 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSnapshot_603663(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSnapshot_603662(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603664 != nil:
    section.add "Action", valid_603664
  var valid_603665 = query.getOrDefault("Version")
  valid_603665 = validateParameter(valid_603665, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_603673 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_603673 = validateParameter(valid_603673, JString, required = true,
                                 default = nil)
  if valid_603673 != nil:
    section.add "DBSnapshotIdentifier", valid_603673
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603674: Call_PostDeleteDBSnapshot_603661; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603674.validator(path, query, header, formData, body)
  let scheme = call_603674.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603674.url(scheme.get, call_603674.host, call_603674.base,
                         call_603674.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603674, url, valid)

proc call*(call_603675: Call_PostDeleteDBSnapshot_603661;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603676 = newJObject()
  var formData_603677 = newJObject()
  add(formData_603677, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_603676, "Action", newJString(Action))
  add(query_603676, "Version", newJString(Version))
  result = call_603675.call(nil, query_603676, nil, formData_603677, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_603661(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_603662, base: "/",
    url: url_PostDeleteDBSnapshot_603663, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_603645 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSnapshot_603647(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSnapshot_603646(path: JsonNode; query: JsonNode;
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
  var valid_603648 = query.getOrDefault("Action")
  valid_603648 = validateParameter(valid_603648, JString, required = true,
                                 default = newJString("DeleteDBSnapshot"))
  if valid_603648 != nil:
    section.add "Action", valid_603648
  var valid_603649 = query.getOrDefault("Version")
  valid_603649 = validateParameter(valid_603649, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603649 != nil:
    section.add "Version", valid_603649
  var valid_603650 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603650 = validateParameter(valid_603650, JString, required = true,
                                 default = nil)
  if valid_603650 != nil:
    section.add "DBSnapshotIdentifier", valid_603650
  result.add "query", section
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

proc call*(call_603658: Call_GetDeleteDBSnapshot_603645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603658.validator(path, query, header, formData, body)
  let scheme = call_603658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603658.url(scheme.get, call_603658.host, call_603658.base,
                         call_603658.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603658, url, valid)

proc call*(call_603659: Call_GetDeleteDBSnapshot_603645;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_603660 = newJObject()
  add(query_603660, "Action", newJString(Action))
  add(query_603660, "Version", newJString(Version))
  add(query_603660, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603659.call(nil, query_603660, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_603645(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_603646, base: "/",
    url: url_GetDeleteDBSnapshot_603647, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_603694 = ref object of OpenApiRestCall_602450
proc url_PostDeleteDBSubnetGroup_603696(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteDBSubnetGroup_603695(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_603697 = validateParameter(valid_603697, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603697 != nil:
    section.add "Action", valid_603697
  var valid_603698 = query.getOrDefault("Version")
  valid_603698 = validateParameter(valid_603698, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_603706 = formData.getOrDefault("DBSubnetGroupName")
  valid_603706 = validateParameter(valid_603706, JString, required = true,
                                 default = nil)
  if valid_603706 != nil:
    section.add "DBSubnetGroupName", valid_603706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603707: Call_PostDeleteDBSubnetGroup_603694; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603707.validator(path, query, header, formData, body)
  let scheme = call_603707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603707.url(scheme.get, call_603707.host, call_603707.base,
                         call_603707.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603707, url, valid)

proc call*(call_603708: Call_PostDeleteDBSubnetGroup_603694;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603709 = newJObject()
  var formData_603710 = newJObject()
  add(formData_603710, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603709, "Action", newJString(Action))
  add(query_603709, "Version", newJString(Version))
  result = call_603708.call(nil, query_603709, nil, formData_603710, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_603694(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_603695, base: "/",
    url: url_PostDeleteDBSubnetGroup_603696, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_603678 = ref object of OpenApiRestCall_602450
proc url_GetDeleteDBSubnetGroup_603680(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteDBSubnetGroup_603679(path: JsonNode; query: JsonNode;
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
  var valid_603681 = query.getOrDefault("Action")
  valid_603681 = validateParameter(valid_603681, JString, required = true,
                                 default = newJString("DeleteDBSubnetGroup"))
  if valid_603681 != nil:
    section.add "Action", valid_603681
  var valid_603682 = query.getOrDefault("DBSubnetGroupName")
  valid_603682 = validateParameter(valid_603682, JString, required = true,
                                 default = nil)
  if valid_603682 != nil:
    section.add "DBSubnetGroupName", valid_603682
  var valid_603683 = query.getOrDefault("Version")
  valid_603683 = validateParameter(valid_603683, JString, required = true,
                                 default = newJString("2013-01-10"))
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

proc call*(call_603691: Call_GetDeleteDBSubnetGroup_603678; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603691.validator(path, query, header, formData, body)
  let scheme = call_603691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603691.url(scheme.get, call_603691.host, call_603691.base,
                         call_603691.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603691, url, valid)

proc call*(call_603692: Call_GetDeleteDBSubnetGroup_603678;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_603693 = newJObject()
  add(query_603693, "Action", newJString(Action))
  add(query_603693, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_603693, "Version", newJString(Version))
  result = call_603692.call(nil, query_603693, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_603678(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_603679, base: "/",
    url: url_GetDeleteDBSubnetGroup_603680, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_603727 = ref object of OpenApiRestCall_602450
proc url_PostDeleteEventSubscription_603729(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteEventSubscription_603728(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_603730 = validateParameter(valid_603730, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603730 != nil:
    section.add "Action", valid_603730
  var valid_603731 = query.getOrDefault("Version")
  valid_603731 = validateParameter(valid_603731, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_603739 = formData.getOrDefault("SubscriptionName")
  valid_603739 = validateParameter(valid_603739, JString, required = true,
                                 default = nil)
  if valid_603739 != nil:
    section.add "SubscriptionName", valid_603739
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603740: Call_PostDeleteEventSubscription_603727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603740.validator(path, query, header, formData, body)
  let scheme = call_603740.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603740.url(scheme.get, call_603740.host, call_603740.base,
                         call_603740.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603740, url, valid)

proc call*(call_603741: Call_PostDeleteEventSubscription_603727;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603742 = newJObject()
  var formData_603743 = newJObject()
  add(formData_603743, "SubscriptionName", newJString(SubscriptionName))
  add(query_603742, "Action", newJString(Action))
  add(query_603742, "Version", newJString(Version))
  result = call_603741.call(nil, query_603742, nil, formData_603743, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_603727(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_603728, base: "/",
    url: url_PostDeleteEventSubscription_603729,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_603711 = ref object of OpenApiRestCall_602450
proc url_GetDeleteEventSubscription_603713(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteEventSubscription_603712(path: JsonNode; query: JsonNode;
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
  var valid_603714 = query.getOrDefault("Action")
  valid_603714 = validateParameter(valid_603714, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_603714 != nil:
    section.add "Action", valid_603714
  var valid_603715 = query.getOrDefault("SubscriptionName")
  valid_603715 = validateParameter(valid_603715, JString, required = true,
                                 default = nil)
  if valid_603715 != nil:
    section.add "SubscriptionName", valid_603715
  var valid_603716 = query.getOrDefault("Version")
  valid_603716 = validateParameter(valid_603716, JString, required = true,
                                 default = newJString("2013-01-10"))
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

proc call*(call_603724: Call_GetDeleteEventSubscription_603711; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603724.validator(path, query, header, formData, body)
  let scheme = call_603724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603724.url(scheme.get, call_603724.host, call_603724.base,
                         call_603724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603724, url, valid)

proc call*(call_603725: Call_GetDeleteEventSubscription_603711;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_603726 = newJObject()
  add(query_603726, "Action", newJString(Action))
  add(query_603726, "SubscriptionName", newJString(SubscriptionName))
  add(query_603726, "Version", newJString(Version))
  result = call_603725.call(nil, query_603726, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_603711(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_603712, base: "/",
    url: url_GetDeleteEventSubscription_603713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_603760 = ref object of OpenApiRestCall_602450
proc url_PostDeleteOptionGroup_603762(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDeleteOptionGroup_603761(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603763 = query.getOrDefault("Action")
  valid_603763 = validateParameter(valid_603763, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603763 != nil:
    section.add "Action", valid_603763
  var valid_603764 = query.getOrDefault("Version")
  valid_603764 = validateParameter(valid_603764, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603764 != nil:
    section.add "Version", valid_603764
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603765 = header.getOrDefault("X-Amz-Date")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Date", valid_603765
  var valid_603766 = header.getOrDefault("X-Amz-Security-Token")
  valid_603766 = validateParameter(valid_603766, JString, required = false,
                                 default = nil)
  if valid_603766 != nil:
    section.add "X-Amz-Security-Token", valid_603766
  var valid_603767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603767 = validateParameter(valid_603767, JString, required = false,
                                 default = nil)
  if valid_603767 != nil:
    section.add "X-Amz-Content-Sha256", valid_603767
  var valid_603768 = header.getOrDefault("X-Amz-Algorithm")
  valid_603768 = validateParameter(valid_603768, JString, required = false,
                                 default = nil)
  if valid_603768 != nil:
    section.add "X-Amz-Algorithm", valid_603768
  var valid_603769 = header.getOrDefault("X-Amz-Signature")
  valid_603769 = validateParameter(valid_603769, JString, required = false,
                                 default = nil)
  if valid_603769 != nil:
    section.add "X-Amz-Signature", valid_603769
  var valid_603770 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603770 = validateParameter(valid_603770, JString, required = false,
                                 default = nil)
  if valid_603770 != nil:
    section.add "X-Amz-SignedHeaders", valid_603770
  var valid_603771 = header.getOrDefault("X-Amz-Credential")
  valid_603771 = validateParameter(valid_603771, JString, required = false,
                                 default = nil)
  if valid_603771 != nil:
    section.add "X-Amz-Credential", valid_603771
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_603772 = formData.getOrDefault("OptionGroupName")
  valid_603772 = validateParameter(valid_603772, JString, required = true,
                                 default = nil)
  if valid_603772 != nil:
    section.add "OptionGroupName", valid_603772
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603773: Call_PostDeleteOptionGroup_603760; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603773.validator(path, query, header, formData, body)
  let scheme = call_603773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603773.url(scheme.get, call_603773.host, call_603773.base,
                         call_603773.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603773, url, valid)

proc call*(call_603774: Call_PostDeleteOptionGroup_603760; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603775 = newJObject()
  var formData_603776 = newJObject()
  add(formData_603776, "OptionGroupName", newJString(OptionGroupName))
  add(query_603775, "Action", newJString(Action))
  add(query_603775, "Version", newJString(Version))
  result = call_603774.call(nil, query_603775, nil, formData_603776, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_603760(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_603761, base: "/",
    url: url_PostDeleteOptionGroup_603762, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_603744 = ref object of OpenApiRestCall_602450
proc url_GetDeleteOptionGroup_603746(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDeleteOptionGroup_603745(path: JsonNode; query: JsonNode;
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
  var valid_603747 = query.getOrDefault("OptionGroupName")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = nil)
  if valid_603747 != nil:
    section.add "OptionGroupName", valid_603747
  var valid_603748 = query.getOrDefault("Action")
  valid_603748 = validateParameter(valid_603748, JString, required = true,
                                 default = newJString("DeleteOptionGroup"))
  if valid_603748 != nil:
    section.add "Action", valid_603748
  var valid_603749 = query.getOrDefault("Version")
  valid_603749 = validateParameter(valid_603749, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603749 != nil:
    section.add "Version", valid_603749
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603750 = header.getOrDefault("X-Amz-Date")
  valid_603750 = validateParameter(valid_603750, JString, required = false,
                                 default = nil)
  if valid_603750 != nil:
    section.add "X-Amz-Date", valid_603750
  var valid_603751 = header.getOrDefault("X-Amz-Security-Token")
  valid_603751 = validateParameter(valid_603751, JString, required = false,
                                 default = nil)
  if valid_603751 != nil:
    section.add "X-Amz-Security-Token", valid_603751
  var valid_603752 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603752 = validateParameter(valid_603752, JString, required = false,
                                 default = nil)
  if valid_603752 != nil:
    section.add "X-Amz-Content-Sha256", valid_603752
  var valid_603753 = header.getOrDefault("X-Amz-Algorithm")
  valid_603753 = validateParameter(valid_603753, JString, required = false,
                                 default = nil)
  if valid_603753 != nil:
    section.add "X-Amz-Algorithm", valid_603753
  var valid_603754 = header.getOrDefault("X-Amz-Signature")
  valid_603754 = validateParameter(valid_603754, JString, required = false,
                                 default = nil)
  if valid_603754 != nil:
    section.add "X-Amz-Signature", valid_603754
  var valid_603755 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603755 = validateParameter(valid_603755, JString, required = false,
                                 default = nil)
  if valid_603755 != nil:
    section.add "X-Amz-SignedHeaders", valid_603755
  var valid_603756 = header.getOrDefault("X-Amz-Credential")
  valid_603756 = validateParameter(valid_603756, JString, required = false,
                                 default = nil)
  if valid_603756 != nil:
    section.add "X-Amz-Credential", valid_603756
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603757: Call_GetDeleteOptionGroup_603744; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603757.validator(path, query, header, formData, body)
  let scheme = call_603757.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603757.url(scheme.get, call_603757.host, call_603757.base,
                         call_603757.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603757, url, valid)

proc call*(call_603758: Call_GetDeleteOptionGroup_603744; OptionGroupName: string;
          Action: string = "DeleteOptionGroup"; Version: string = "2013-01-10"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603759 = newJObject()
  add(query_603759, "OptionGroupName", newJString(OptionGroupName))
  add(query_603759, "Action", newJString(Action))
  add(query_603759, "Version", newJString(Version))
  result = call_603758.call(nil, query_603759, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_603744(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_603745, base: "/",
    url: url_GetDeleteOptionGroup_603746, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_603799 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBEngineVersions_603801(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBEngineVersions_603800(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603802 = query.getOrDefault("Action")
  valid_603802 = validateParameter(valid_603802, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603802 != nil:
    section.add "Action", valid_603802
  var valid_603803 = query.getOrDefault("Version")
  valid_603803 = validateParameter(valid_603803, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603803 != nil:
    section.add "Version", valid_603803
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603804 = header.getOrDefault("X-Amz-Date")
  valid_603804 = validateParameter(valid_603804, JString, required = false,
                                 default = nil)
  if valid_603804 != nil:
    section.add "X-Amz-Date", valid_603804
  var valid_603805 = header.getOrDefault("X-Amz-Security-Token")
  valid_603805 = validateParameter(valid_603805, JString, required = false,
                                 default = nil)
  if valid_603805 != nil:
    section.add "X-Amz-Security-Token", valid_603805
  var valid_603806 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603806 = validateParameter(valid_603806, JString, required = false,
                                 default = nil)
  if valid_603806 != nil:
    section.add "X-Amz-Content-Sha256", valid_603806
  var valid_603807 = header.getOrDefault("X-Amz-Algorithm")
  valid_603807 = validateParameter(valid_603807, JString, required = false,
                                 default = nil)
  if valid_603807 != nil:
    section.add "X-Amz-Algorithm", valid_603807
  var valid_603808 = header.getOrDefault("X-Amz-Signature")
  valid_603808 = validateParameter(valid_603808, JString, required = false,
                                 default = nil)
  if valid_603808 != nil:
    section.add "X-Amz-Signature", valid_603808
  var valid_603809 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603809 = validateParameter(valid_603809, JString, required = false,
                                 default = nil)
  if valid_603809 != nil:
    section.add "X-Amz-SignedHeaders", valid_603809
  var valid_603810 = header.getOrDefault("X-Amz-Credential")
  valid_603810 = validateParameter(valid_603810, JString, required = false,
                                 default = nil)
  if valid_603810 != nil:
    section.add "X-Amz-Credential", valid_603810
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
  var valid_603811 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_603811 = validateParameter(valid_603811, JBool, required = false, default = nil)
  if valid_603811 != nil:
    section.add "ListSupportedCharacterSets", valid_603811
  var valid_603812 = formData.getOrDefault("Engine")
  valid_603812 = validateParameter(valid_603812, JString, required = false,
                                 default = nil)
  if valid_603812 != nil:
    section.add "Engine", valid_603812
  var valid_603813 = formData.getOrDefault("Marker")
  valid_603813 = validateParameter(valid_603813, JString, required = false,
                                 default = nil)
  if valid_603813 != nil:
    section.add "Marker", valid_603813
  var valid_603814 = formData.getOrDefault("DBParameterGroupFamily")
  valid_603814 = validateParameter(valid_603814, JString, required = false,
                                 default = nil)
  if valid_603814 != nil:
    section.add "DBParameterGroupFamily", valid_603814
  var valid_603815 = formData.getOrDefault("MaxRecords")
  valid_603815 = validateParameter(valid_603815, JInt, required = false, default = nil)
  if valid_603815 != nil:
    section.add "MaxRecords", valid_603815
  var valid_603816 = formData.getOrDefault("EngineVersion")
  valid_603816 = validateParameter(valid_603816, JString, required = false,
                                 default = nil)
  if valid_603816 != nil:
    section.add "EngineVersion", valid_603816
  var valid_603817 = formData.getOrDefault("DefaultOnly")
  valid_603817 = validateParameter(valid_603817, JBool, required = false, default = nil)
  if valid_603817 != nil:
    section.add "DefaultOnly", valid_603817
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603818: Call_PostDescribeDBEngineVersions_603799; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603818.validator(path, query, header, formData, body)
  let scheme = call_603818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603818.url(scheme.get, call_603818.host, call_603818.base,
                         call_603818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603818, url, valid)

proc call*(call_603819: Call_PostDescribeDBEngineVersions_603799;
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
  var query_603820 = newJObject()
  var formData_603821 = newJObject()
  add(formData_603821, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_603821, "Engine", newJString(Engine))
  add(formData_603821, "Marker", newJString(Marker))
  add(query_603820, "Action", newJString(Action))
  add(formData_603821, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_603821, "MaxRecords", newJInt(MaxRecords))
  add(formData_603821, "EngineVersion", newJString(EngineVersion))
  add(query_603820, "Version", newJString(Version))
  add(formData_603821, "DefaultOnly", newJBool(DefaultOnly))
  result = call_603819.call(nil, query_603820, nil, formData_603821, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_603799(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_603800, base: "/",
    url: url_PostDescribeDBEngineVersions_603801,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_603777 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBEngineVersions_603779(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBEngineVersions_603778(path: JsonNode; query: JsonNode;
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
  var valid_603780 = query.getOrDefault("Engine")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "Engine", valid_603780
  var valid_603781 = query.getOrDefault("ListSupportedCharacterSets")
  valid_603781 = validateParameter(valid_603781, JBool, required = false, default = nil)
  if valid_603781 != nil:
    section.add "ListSupportedCharacterSets", valid_603781
  var valid_603782 = query.getOrDefault("MaxRecords")
  valid_603782 = validateParameter(valid_603782, JInt, required = false, default = nil)
  if valid_603782 != nil:
    section.add "MaxRecords", valid_603782
  var valid_603783 = query.getOrDefault("DBParameterGroupFamily")
  valid_603783 = validateParameter(valid_603783, JString, required = false,
                                 default = nil)
  if valid_603783 != nil:
    section.add "DBParameterGroupFamily", valid_603783
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603784 = query.getOrDefault("Action")
  valid_603784 = validateParameter(valid_603784, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_603784 != nil:
    section.add "Action", valid_603784
  var valid_603785 = query.getOrDefault("Marker")
  valid_603785 = validateParameter(valid_603785, JString, required = false,
                                 default = nil)
  if valid_603785 != nil:
    section.add "Marker", valid_603785
  var valid_603786 = query.getOrDefault("EngineVersion")
  valid_603786 = validateParameter(valid_603786, JString, required = false,
                                 default = nil)
  if valid_603786 != nil:
    section.add "EngineVersion", valid_603786
  var valid_603787 = query.getOrDefault("DefaultOnly")
  valid_603787 = validateParameter(valid_603787, JBool, required = false, default = nil)
  if valid_603787 != nil:
    section.add "DefaultOnly", valid_603787
  var valid_603788 = query.getOrDefault("Version")
  valid_603788 = validateParameter(valid_603788, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603788 != nil:
    section.add "Version", valid_603788
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603789 = header.getOrDefault("X-Amz-Date")
  valid_603789 = validateParameter(valid_603789, JString, required = false,
                                 default = nil)
  if valid_603789 != nil:
    section.add "X-Amz-Date", valid_603789
  var valid_603790 = header.getOrDefault("X-Amz-Security-Token")
  valid_603790 = validateParameter(valid_603790, JString, required = false,
                                 default = nil)
  if valid_603790 != nil:
    section.add "X-Amz-Security-Token", valid_603790
  var valid_603791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603791 = validateParameter(valid_603791, JString, required = false,
                                 default = nil)
  if valid_603791 != nil:
    section.add "X-Amz-Content-Sha256", valid_603791
  var valid_603792 = header.getOrDefault("X-Amz-Algorithm")
  valid_603792 = validateParameter(valid_603792, JString, required = false,
                                 default = nil)
  if valid_603792 != nil:
    section.add "X-Amz-Algorithm", valid_603792
  var valid_603793 = header.getOrDefault("X-Amz-Signature")
  valid_603793 = validateParameter(valid_603793, JString, required = false,
                                 default = nil)
  if valid_603793 != nil:
    section.add "X-Amz-Signature", valid_603793
  var valid_603794 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603794 = validateParameter(valid_603794, JString, required = false,
                                 default = nil)
  if valid_603794 != nil:
    section.add "X-Amz-SignedHeaders", valid_603794
  var valid_603795 = header.getOrDefault("X-Amz-Credential")
  valid_603795 = validateParameter(valid_603795, JString, required = false,
                                 default = nil)
  if valid_603795 != nil:
    section.add "X-Amz-Credential", valid_603795
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603796: Call_GetDescribeDBEngineVersions_603777; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603796.validator(path, query, header, formData, body)
  let scheme = call_603796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603796.url(scheme.get, call_603796.host, call_603796.base,
                         call_603796.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603796, url, valid)

proc call*(call_603797: Call_GetDescribeDBEngineVersions_603777;
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
  var query_603798 = newJObject()
  add(query_603798, "Engine", newJString(Engine))
  add(query_603798, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_603798, "MaxRecords", newJInt(MaxRecords))
  add(query_603798, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_603798, "Action", newJString(Action))
  add(query_603798, "Marker", newJString(Marker))
  add(query_603798, "EngineVersion", newJString(EngineVersion))
  add(query_603798, "DefaultOnly", newJBool(DefaultOnly))
  add(query_603798, "Version", newJString(Version))
  result = call_603797.call(nil, query_603798, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_603777(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_603778, base: "/",
    url: url_GetDescribeDBEngineVersions_603779,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_603840 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBInstances_603842(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBInstances_603841(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603843 = query.getOrDefault("Action")
  valid_603843 = validateParameter(valid_603843, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603843 != nil:
    section.add "Action", valid_603843
  var valid_603844 = query.getOrDefault("Version")
  valid_603844 = validateParameter(valid_603844, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603844 != nil:
    section.add "Version", valid_603844
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603845 = header.getOrDefault("X-Amz-Date")
  valid_603845 = validateParameter(valid_603845, JString, required = false,
                                 default = nil)
  if valid_603845 != nil:
    section.add "X-Amz-Date", valid_603845
  var valid_603846 = header.getOrDefault("X-Amz-Security-Token")
  valid_603846 = validateParameter(valid_603846, JString, required = false,
                                 default = nil)
  if valid_603846 != nil:
    section.add "X-Amz-Security-Token", valid_603846
  var valid_603847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603847 = validateParameter(valid_603847, JString, required = false,
                                 default = nil)
  if valid_603847 != nil:
    section.add "X-Amz-Content-Sha256", valid_603847
  var valid_603848 = header.getOrDefault("X-Amz-Algorithm")
  valid_603848 = validateParameter(valid_603848, JString, required = false,
                                 default = nil)
  if valid_603848 != nil:
    section.add "X-Amz-Algorithm", valid_603848
  var valid_603849 = header.getOrDefault("X-Amz-Signature")
  valid_603849 = validateParameter(valid_603849, JString, required = false,
                                 default = nil)
  if valid_603849 != nil:
    section.add "X-Amz-Signature", valid_603849
  var valid_603850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603850 = validateParameter(valid_603850, JString, required = false,
                                 default = nil)
  if valid_603850 != nil:
    section.add "X-Amz-SignedHeaders", valid_603850
  var valid_603851 = header.getOrDefault("X-Amz-Credential")
  valid_603851 = validateParameter(valid_603851, JString, required = false,
                                 default = nil)
  if valid_603851 != nil:
    section.add "X-Amz-Credential", valid_603851
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603852 = formData.getOrDefault("DBInstanceIdentifier")
  valid_603852 = validateParameter(valid_603852, JString, required = false,
                                 default = nil)
  if valid_603852 != nil:
    section.add "DBInstanceIdentifier", valid_603852
  var valid_603853 = formData.getOrDefault("Marker")
  valid_603853 = validateParameter(valid_603853, JString, required = false,
                                 default = nil)
  if valid_603853 != nil:
    section.add "Marker", valid_603853
  var valid_603854 = formData.getOrDefault("MaxRecords")
  valid_603854 = validateParameter(valid_603854, JInt, required = false, default = nil)
  if valid_603854 != nil:
    section.add "MaxRecords", valid_603854
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603855: Call_PostDescribeDBInstances_603840; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603855.validator(path, query, header, formData, body)
  let scheme = call_603855.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603855.url(scheme.get, call_603855.host, call_603855.base,
                         call_603855.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603855, url, valid)

proc call*(call_603856: Call_PostDescribeDBInstances_603840;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_603857 = newJObject()
  var formData_603858 = newJObject()
  add(formData_603858, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_603858, "Marker", newJString(Marker))
  add(query_603857, "Action", newJString(Action))
  add(formData_603858, "MaxRecords", newJInt(MaxRecords))
  add(query_603857, "Version", newJString(Version))
  result = call_603856.call(nil, query_603857, nil, formData_603858, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_603840(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_603841, base: "/",
    url: url_PostDescribeDBInstances_603842, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_603822 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBInstances_603824(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBInstances_603823(path: JsonNode; query: JsonNode;
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
  var valid_603825 = query.getOrDefault("MaxRecords")
  valid_603825 = validateParameter(valid_603825, JInt, required = false, default = nil)
  if valid_603825 != nil:
    section.add "MaxRecords", valid_603825
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603826 = query.getOrDefault("Action")
  valid_603826 = validateParameter(valid_603826, JString, required = true,
                                 default = newJString("DescribeDBInstances"))
  if valid_603826 != nil:
    section.add "Action", valid_603826
  var valid_603827 = query.getOrDefault("Marker")
  valid_603827 = validateParameter(valid_603827, JString, required = false,
                                 default = nil)
  if valid_603827 != nil:
    section.add "Marker", valid_603827
  var valid_603828 = query.getOrDefault("Version")
  valid_603828 = validateParameter(valid_603828, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603828 != nil:
    section.add "Version", valid_603828
  var valid_603829 = query.getOrDefault("DBInstanceIdentifier")
  valid_603829 = validateParameter(valid_603829, JString, required = false,
                                 default = nil)
  if valid_603829 != nil:
    section.add "DBInstanceIdentifier", valid_603829
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603830 = header.getOrDefault("X-Amz-Date")
  valid_603830 = validateParameter(valid_603830, JString, required = false,
                                 default = nil)
  if valid_603830 != nil:
    section.add "X-Amz-Date", valid_603830
  var valid_603831 = header.getOrDefault("X-Amz-Security-Token")
  valid_603831 = validateParameter(valid_603831, JString, required = false,
                                 default = nil)
  if valid_603831 != nil:
    section.add "X-Amz-Security-Token", valid_603831
  var valid_603832 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603832 = validateParameter(valid_603832, JString, required = false,
                                 default = nil)
  if valid_603832 != nil:
    section.add "X-Amz-Content-Sha256", valid_603832
  var valid_603833 = header.getOrDefault("X-Amz-Algorithm")
  valid_603833 = validateParameter(valid_603833, JString, required = false,
                                 default = nil)
  if valid_603833 != nil:
    section.add "X-Amz-Algorithm", valid_603833
  var valid_603834 = header.getOrDefault("X-Amz-Signature")
  valid_603834 = validateParameter(valid_603834, JString, required = false,
                                 default = nil)
  if valid_603834 != nil:
    section.add "X-Amz-Signature", valid_603834
  var valid_603835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603835 = validateParameter(valid_603835, JString, required = false,
                                 default = nil)
  if valid_603835 != nil:
    section.add "X-Amz-SignedHeaders", valid_603835
  var valid_603836 = header.getOrDefault("X-Amz-Credential")
  valid_603836 = validateParameter(valid_603836, JString, required = false,
                                 default = nil)
  if valid_603836 != nil:
    section.add "X-Amz-Credential", valid_603836
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603837: Call_GetDescribeDBInstances_603822; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603837.validator(path, query, header, formData, body)
  let scheme = call_603837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603837.url(scheme.get, call_603837.host, call_603837.base,
                         call_603837.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603837, url, valid)

proc call*(call_603838: Call_GetDescribeDBInstances_603822; MaxRecords: int = 0;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-01-10"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_603839 = newJObject()
  add(query_603839, "MaxRecords", newJInt(MaxRecords))
  add(query_603839, "Action", newJString(Action))
  add(query_603839, "Marker", newJString(Marker))
  add(query_603839, "Version", newJString(Version))
  add(query_603839, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_603838.call(nil, query_603839, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_603822(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_603823, base: "/",
    url: url_GetDescribeDBInstances_603824, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_603877 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameterGroups_603879(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameterGroups_603878(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603880 = query.getOrDefault("Action")
  valid_603880 = validateParameter(valid_603880, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603880 != nil:
    section.add "Action", valid_603880
  var valid_603881 = query.getOrDefault("Version")
  valid_603881 = validateParameter(valid_603881, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603881 != nil:
    section.add "Version", valid_603881
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603882 = header.getOrDefault("X-Amz-Date")
  valid_603882 = validateParameter(valid_603882, JString, required = false,
                                 default = nil)
  if valid_603882 != nil:
    section.add "X-Amz-Date", valid_603882
  var valid_603883 = header.getOrDefault("X-Amz-Security-Token")
  valid_603883 = validateParameter(valid_603883, JString, required = false,
                                 default = nil)
  if valid_603883 != nil:
    section.add "X-Amz-Security-Token", valid_603883
  var valid_603884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603884 = validateParameter(valid_603884, JString, required = false,
                                 default = nil)
  if valid_603884 != nil:
    section.add "X-Amz-Content-Sha256", valid_603884
  var valid_603885 = header.getOrDefault("X-Amz-Algorithm")
  valid_603885 = validateParameter(valid_603885, JString, required = false,
                                 default = nil)
  if valid_603885 != nil:
    section.add "X-Amz-Algorithm", valid_603885
  var valid_603886 = header.getOrDefault("X-Amz-Signature")
  valid_603886 = validateParameter(valid_603886, JString, required = false,
                                 default = nil)
  if valid_603886 != nil:
    section.add "X-Amz-Signature", valid_603886
  var valid_603887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603887 = validateParameter(valid_603887, JString, required = false,
                                 default = nil)
  if valid_603887 != nil:
    section.add "X-Amz-SignedHeaders", valid_603887
  var valid_603888 = header.getOrDefault("X-Amz-Credential")
  valid_603888 = validateParameter(valid_603888, JString, required = false,
                                 default = nil)
  if valid_603888 != nil:
    section.add "X-Amz-Credential", valid_603888
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603889 = formData.getOrDefault("DBParameterGroupName")
  valid_603889 = validateParameter(valid_603889, JString, required = false,
                                 default = nil)
  if valid_603889 != nil:
    section.add "DBParameterGroupName", valid_603889
  var valid_603890 = formData.getOrDefault("Marker")
  valid_603890 = validateParameter(valid_603890, JString, required = false,
                                 default = nil)
  if valid_603890 != nil:
    section.add "Marker", valid_603890
  var valid_603891 = formData.getOrDefault("MaxRecords")
  valid_603891 = validateParameter(valid_603891, JInt, required = false, default = nil)
  if valid_603891 != nil:
    section.add "MaxRecords", valid_603891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603892: Call_PostDescribeDBParameterGroups_603877; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603892.validator(path, query, header, formData, body)
  let scheme = call_603892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603892.url(scheme.get, call_603892.host, call_603892.base,
                         call_603892.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603892, url, valid)

proc call*(call_603893: Call_PostDescribeDBParameterGroups_603877;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_603894 = newJObject()
  var formData_603895 = newJObject()
  add(formData_603895, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603895, "Marker", newJString(Marker))
  add(query_603894, "Action", newJString(Action))
  add(formData_603895, "MaxRecords", newJInt(MaxRecords))
  add(query_603894, "Version", newJString(Version))
  result = call_603893.call(nil, query_603894, nil, formData_603895, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_603877(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_603878, base: "/",
    url: url_PostDescribeDBParameterGroups_603879,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_603859 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameterGroups_603861(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameterGroups_603860(path: JsonNode; query: JsonNode;
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
  var valid_603862 = query.getOrDefault("MaxRecords")
  valid_603862 = validateParameter(valid_603862, JInt, required = false, default = nil)
  if valid_603862 != nil:
    section.add "MaxRecords", valid_603862
  var valid_603863 = query.getOrDefault("DBParameterGroupName")
  valid_603863 = validateParameter(valid_603863, JString, required = false,
                                 default = nil)
  if valid_603863 != nil:
    section.add "DBParameterGroupName", valid_603863
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603864 = query.getOrDefault("Action")
  valid_603864 = validateParameter(valid_603864, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_603864 != nil:
    section.add "Action", valid_603864
  var valid_603865 = query.getOrDefault("Marker")
  valid_603865 = validateParameter(valid_603865, JString, required = false,
                                 default = nil)
  if valid_603865 != nil:
    section.add "Marker", valid_603865
  var valid_603866 = query.getOrDefault("Version")
  valid_603866 = validateParameter(valid_603866, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603866 != nil:
    section.add "Version", valid_603866
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603867 = header.getOrDefault("X-Amz-Date")
  valid_603867 = validateParameter(valid_603867, JString, required = false,
                                 default = nil)
  if valid_603867 != nil:
    section.add "X-Amz-Date", valid_603867
  var valid_603868 = header.getOrDefault("X-Amz-Security-Token")
  valid_603868 = validateParameter(valid_603868, JString, required = false,
                                 default = nil)
  if valid_603868 != nil:
    section.add "X-Amz-Security-Token", valid_603868
  var valid_603869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603869 = validateParameter(valid_603869, JString, required = false,
                                 default = nil)
  if valid_603869 != nil:
    section.add "X-Amz-Content-Sha256", valid_603869
  var valid_603870 = header.getOrDefault("X-Amz-Algorithm")
  valid_603870 = validateParameter(valid_603870, JString, required = false,
                                 default = nil)
  if valid_603870 != nil:
    section.add "X-Amz-Algorithm", valid_603870
  var valid_603871 = header.getOrDefault("X-Amz-Signature")
  valid_603871 = validateParameter(valid_603871, JString, required = false,
                                 default = nil)
  if valid_603871 != nil:
    section.add "X-Amz-Signature", valid_603871
  var valid_603872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603872 = validateParameter(valid_603872, JString, required = false,
                                 default = nil)
  if valid_603872 != nil:
    section.add "X-Amz-SignedHeaders", valid_603872
  var valid_603873 = header.getOrDefault("X-Amz-Credential")
  valid_603873 = validateParameter(valid_603873, JString, required = false,
                                 default = nil)
  if valid_603873 != nil:
    section.add "X-Amz-Credential", valid_603873
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603874: Call_GetDescribeDBParameterGroups_603859; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603874.validator(path, query, header, formData, body)
  let scheme = call_603874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603874.url(scheme.get, call_603874.host, call_603874.base,
                         call_603874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603874, url, valid)

proc call*(call_603875: Call_GetDescribeDBParameterGroups_603859;
          MaxRecords: int = 0; DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_603876 = newJObject()
  add(query_603876, "MaxRecords", newJInt(MaxRecords))
  add(query_603876, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603876, "Action", newJString(Action))
  add(query_603876, "Marker", newJString(Marker))
  add(query_603876, "Version", newJString(Version))
  result = call_603875.call(nil, query_603876, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_603859(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_603860, base: "/",
    url: url_GetDescribeDBParameterGroups_603861,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_603915 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBParameters_603917(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBParameters_603916(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603918 = query.getOrDefault("Action")
  valid_603918 = validateParameter(valid_603918, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603918 != nil:
    section.add "Action", valid_603918
  var valid_603919 = query.getOrDefault("Version")
  valid_603919 = validateParameter(valid_603919, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603919 != nil:
    section.add "Version", valid_603919
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603920 = header.getOrDefault("X-Amz-Date")
  valid_603920 = validateParameter(valid_603920, JString, required = false,
                                 default = nil)
  if valid_603920 != nil:
    section.add "X-Amz-Date", valid_603920
  var valid_603921 = header.getOrDefault("X-Amz-Security-Token")
  valid_603921 = validateParameter(valid_603921, JString, required = false,
                                 default = nil)
  if valid_603921 != nil:
    section.add "X-Amz-Security-Token", valid_603921
  var valid_603922 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603922 = validateParameter(valid_603922, JString, required = false,
                                 default = nil)
  if valid_603922 != nil:
    section.add "X-Amz-Content-Sha256", valid_603922
  var valid_603923 = header.getOrDefault("X-Amz-Algorithm")
  valid_603923 = validateParameter(valid_603923, JString, required = false,
                                 default = nil)
  if valid_603923 != nil:
    section.add "X-Amz-Algorithm", valid_603923
  var valid_603924 = header.getOrDefault("X-Amz-Signature")
  valid_603924 = validateParameter(valid_603924, JString, required = false,
                                 default = nil)
  if valid_603924 != nil:
    section.add "X-Amz-Signature", valid_603924
  var valid_603925 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603925 = validateParameter(valid_603925, JString, required = false,
                                 default = nil)
  if valid_603925 != nil:
    section.add "X-Amz-SignedHeaders", valid_603925
  var valid_603926 = header.getOrDefault("X-Amz-Credential")
  valid_603926 = validateParameter(valid_603926, JString, required = false,
                                 default = nil)
  if valid_603926 != nil:
    section.add "X-Amz-Credential", valid_603926
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_603927 = formData.getOrDefault("DBParameterGroupName")
  valid_603927 = validateParameter(valid_603927, JString, required = true,
                                 default = nil)
  if valid_603927 != nil:
    section.add "DBParameterGroupName", valid_603927
  var valid_603928 = formData.getOrDefault("Marker")
  valid_603928 = validateParameter(valid_603928, JString, required = false,
                                 default = nil)
  if valid_603928 != nil:
    section.add "Marker", valid_603928
  var valid_603929 = formData.getOrDefault("MaxRecords")
  valid_603929 = validateParameter(valid_603929, JInt, required = false, default = nil)
  if valid_603929 != nil:
    section.add "MaxRecords", valid_603929
  var valid_603930 = formData.getOrDefault("Source")
  valid_603930 = validateParameter(valid_603930, JString, required = false,
                                 default = nil)
  if valid_603930 != nil:
    section.add "Source", valid_603930
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603931: Call_PostDescribeDBParameters_603915; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603931.validator(path, query, header, formData, body)
  let scheme = call_603931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603931.url(scheme.get, call_603931.host, call_603931.base,
                         call_603931.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603931, url, valid)

proc call*(call_603932: Call_PostDescribeDBParameters_603915;
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
  var query_603933 = newJObject()
  var formData_603934 = newJObject()
  add(formData_603934, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_603934, "Marker", newJString(Marker))
  add(query_603933, "Action", newJString(Action))
  add(formData_603934, "MaxRecords", newJInt(MaxRecords))
  add(query_603933, "Version", newJString(Version))
  add(formData_603934, "Source", newJString(Source))
  result = call_603932.call(nil, query_603933, nil, formData_603934, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_603915(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_603916, base: "/",
    url: url_PostDescribeDBParameters_603917, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_603896 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBParameters_603898(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBParameters_603897(path: JsonNode; query: JsonNode;
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
  var valid_603899 = query.getOrDefault("MaxRecords")
  valid_603899 = validateParameter(valid_603899, JInt, required = false, default = nil)
  if valid_603899 != nil:
    section.add "MaxRecords", valid_603899
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_603900 = query.getOrDefault("DBParameterGroupName")
  valid_603900 = validateParameter(valid_603900, JString, required = true,
                                 default = nil)
  if valid_603900 != nil:
    section.add "DBParameterGroupName", valid_603900
  var valid_603901 = query.getOrDefault("Action")
  valid_603901 = validateParameter(valid_603901, JString, required = true,
                                 default = newJString("DescribeDBParameters"))
  if valid_603901 != nil:
    section.add "Action", valid_603901
  var valid_603902 = query.getOrDefault("Marker")
  valid_603902 = validateParameter(valid_603902, JString, required = false,
                                 default = nil)
  if valid_603902 != nil:
    section.add "Marker", valid_603902
  var valid_603903 = query.getOrDefault("Source")
  valid_603903 = validateParameter(valid_603903, JString, required = false,
                                 default = nil)
  if valid_603903 != nil:
    section.add "Source", valid_603903
  var valid_603904 = query.getOrDefault("Version")
  valid_603904 = validateParameter(valid_603904, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603904 != nil:
    section.add "Version", valid_603904
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603905 = header.getOrDefault("X-Amz-Date")
  valid_603905 = validateParameter(valid_603905, JString, required = false,
                                 default = nil)
  if valid_603905 != nil:
    section.add "X-Amz-Date", valid_603905
  var valid_603906 = header.getOrDefault("X-Amz-Security-Token")
  valid_603906 = validateParameter(valid_603906, JString, required = false,
                                 default = nil)
  if valid_603906 != nil:
    section.add "X-Amz-Security-Token", valid_603906
  var valid_603907 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603907 = validateParameter(valid_603907, JString, required = false,
                                 default = nil)
  if valid_603907 != nil:
    section.add "X-Amz-Content-Sha256", valid_603907
  var valid_603908 = header.getOrDefault("X-Amz-Algorithm")
  valid_603908 = validateParameter(valid_603908, JString, required = false,
                                 default = nil)
  if valid_603908 != nil:
    section.add "X-Amz-Algorithm", valid_603908
  var valid_603909 = header.getOrDefault("X-Amz-Signature")
  valid_603909 = validateParameter(valid_603909, JString, required = false,
                                 default = nil)
  if valid_603909 != nil:
    section.add "X-Amz-Signature", valid_603909
  var valid_603910 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603910 = validateParameter(valid_603910, JString, required = false,
                                 default = nil)
  if valid_603910 != nil:
    section.add "X-Amz-SignedHeaders", valid_603910
  var valid_603911 = header.getOrDefault("X-Amz-Credential")
  valid_603911 = validateParameter(valid_603911, JString, required = false,
                                 default = nil)
  if valid_603911 != nil:
    section.add "X-Amz-Credential", valid_603911
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603912: Call_GetDescribeDBParameters_603896; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603912.validator(path, query, header, formData, body)
  let scheme = call_603912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603912.url(scheme.get, call_603912.host, call_603912.base,
                         call_603912.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603912, url, valid)

proc call*(call_603913: Call_GetDescribeDBParameters_603896;
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
  var query_603914 = newJObject()
  add(query_603914, "MaxRecords", newJInt(MaxRecords))
  add(query_603914, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_603914, "Action", newJString(Action))
  add(query_603914, "Marker", newJString(Marker))
  add(query_603914, "Source", newJString(Source))
  add(query_603914, "Version", newJString(Version))
  result = call_603913.call(nil, query_603914, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_603896(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_603897, base: "/",
    url: url_GetDescribeDBParameters_603898, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_603953 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSecurityGroups_603955(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSecurityGroups_603954(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603956 = query.getOrDefault("Action")
  valid_603956 = validateParameter(valid_603956, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603956 != nil:
    section.add "Action", valid_603956
  var valid_603957 = query.getOrDefault("Version")
  valid_603957 = validateParameter(valid_603957, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603957 != nil:
    section.add "Version", valid_603957
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603958 = header.getOrDefault("X-Amz-Date")
  valid_603958 = validateParameter(valid_603958, JString, required = false,
                                 default = nil)
  if valid_603958 != nil:
    section.add "X-Amz-Date", valid_603958
  var valid_603959 = header.getOrDefault("X-Amz-Security-Token")
  valid_603959 = validateParameter(valid_603959, JString, required = false,
                                 default = nil)
  if valid_603959 != nil:
    section.add "X-Amz-Security-Token", valid_603959
  var valid_603960 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603960 = validateParameter(valid_603960, JString, required = false,
                                 default = nil)
  if valid_603960 != nil:
    section.add "X-Amz-Content-Sha256", valid_603960
  var valid_603961 = header.getOrDefault("X-Amz-Algorithm")
  valid_603961 = validateParameter(valid_603961, JString, required = false,
                                 default = nil)
  if valid_603961 != nil:
    section.add "X-Amz-Algorithm", valid_603961
  var valid_603962 = header.getOrDefault("X-Amz-Signature")
  valid_603962 = validateParameter(valid_603962, JString, required = false,
                                 default = nil)
  if valid_603962 != nil:
    section.add "X-Amz-Signature", valid_603962
  var valid_603963 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603963 = validateParameter(valid_603963, JString, required = false,
                                 default = nil)
  if valid_603963 != nil:
    section.add "X-Amz-SignedHeaders", valid_603963
  var valid_603964 = header.getOrDefault("X-Amz-Credential")
  valid_603964 = validateParameter(valid_603964, JString, required = false,
                                 default = nil)
  if valid_603964 != nil:
    section.add "X-Amz-Credential", valid_603964
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_603965 = formData.getOrDefault("DBSecurityGroupName")
  valid_603965 = validateParameter(valid_603965, JString, required = false,
                                 default = nil)
  if valid_603965 != nil:
    section.add "DBSecurityGroupName", valid_603965
  var valid_603966 = formData.getOrDefault("Marker")
  valid_603966 = validateParameter(valid_603966, JString, required = false,
                                 default = nil)
  if valid_603966 != nil:
    section.add "Marker", valid_603966
  var valid_603967 = formData.getOrDefault("MaxRecords")
  valid_603967 = validateParameter(valid_603967, JInt, required = false, default = nil)
  if valid_603967 != nil:
    section.add "MaxRecords", valid_603967
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603968: Call_PostDescribeDBSecurityGroups_603953; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603968.validator(path, query, header, formData, body)
  let scheme = call_603968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603968.url(scheme.get, call_603968.host, call_603968.base,
                         call_603968.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603968, url, valid)

proc call*(call_603969: Call_PostDescribeDBSecurityGroups_603953;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_603970 = newJObject()
  var formData_603971 = newJObject()
  add(formData_603971, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_603971, "Marker", newJString(Marker))
  add(query_603970, "Action", newJString(Action))
  add(formData_603971, "MaxRecords", newJInt(MaxRecords))
  add(query_603970, "Version", newJString(Version))
  result = call_603969.call(nil, query_603970, nil, formData_603971, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_603953(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_603954, base: "/",
    url: url_PostDescribeDBSecurityGroups_603955,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_603935 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSecurityGroups_603937(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSecurityGroups_603936(path: JsonNode; query: JsonNode;
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
  var valid_603938 = query.getOrDefault("MaxRecords")
  valid_603938 = validateParameter(valid_603938, JInt, required = false, default = nil)
  if valid_603938 != nil:
    section.add "MaxRecords", valid_603938
  var valid_603939 = query.getOrDefault("DBSecurityGroupName")
  valid_603939 = validateParameter(valid_603939, JString, required = false,
                                 default = nil)
  if valid_603939 != nil:
    section.add "DBSecurityGroupName", valid_603939
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603940 = query.getOrDefault("Action")
  valid_603940 = validateParameter(valid_603940, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_603940 != nil:
    section.add "Action", valid_603940
  var valid_603941 = query.getOrDefault("Marker")
  valid_603941 = validateParameter(valid_603941, JString, required = false,
                                 default = nil)
  if valid_603941 != nil:
    section.add "Marker", valid_603941
  var valid_603942 = query.getOrDefault("Version")
  valid_603942 = validateParameter(valid_603942, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603942 != nil:
    section.add "Version", valid_603942
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603943 = header.getOrDefault("X-Amz-Date")
  valid_603943 = validateParameter(valid_603943, JString, required = false,
                                 default = nil)
  if valid_603943 != nil:
    section.add "X-Amz-Date", valid_603943
  var valid_603944 = header.getOrDefault("X-Amz-Security-Token")
  valid_603944 = validateParameter(valid_603944, JString, required = false,
                                 default = nil)
  if valid_603944 != nil:
    section.add "X-Amz-Security-Token", valid_603944
  var valid_603945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603945 = validateParameter(valid_603945, JString, required = false,
                                 default = nil)
  if valid_603945 != nil:
    section.add "X-Amz-Content-Sha256", valid_603945
  var valid_603946 = header.getOrDefault("X-Amz-Algorithm")
  valid_603946 = validateParameter(valid_603946, JString, required = false,
                                 default = nil)
  if valid_603946 != nil:
    section.add "X-Amz-Algorithm", valid_603946
  var valid_603947 = header.getOrDefault("X-Amz-Signature")
  valid_603947 = validateParameter(valid_603947, JString, required = false,
                                 default = nil)
  if valid_603947 != nil:
    section.add "X-Amz-Signature", valid_603947
  var valid_603948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603948 = validateParameter(valid_603948, JString, required = false,
                                 default = nil)
  if valid_603948 != nil:
    section.add "X-Amz-SignedHeaders", valid_603948
  var valid_603949 = header.getOrDefault("X-Amz-Credential")
  valid_603949 = validateParameter(valid_603949, JString, required = false,
                                 default = nil)
  if valid_603949 != nil:
    section.add "X-Amz-Credential", valid_603949
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603950: Call_GetDescribeDBSecurityGroups_603935; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603950.validator(path, query, header, formData, body)
  let scheme = call_603950.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603950.url(scheme.get, call_603950.host, call_603950.base,
                         call_603950.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603950, url, valid)

proc call*(call_603951: Call_GetDescribeDBSecurityGroups_603935;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Action: string = "DescribeDBSecurityGroups"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_603952 = newJObject()
  add(query_603952, "MaxRecords", newJInt(MaxRecords))
  add(query_603952, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_603952, "Action", newJString(Action))
  add(query_603952, "Marker", newJString(Marker))
  add(query_603952, "Version", newJString(Version))
  result = call_603951.call(nil, query_603952, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_603935(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_603936, base: "/",
    url: url_GetDescribeDBSecurityGroups_603937,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_603992 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSnapshots_603994(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSnapshots_603993(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603995 = query.getOrDefault("Action")
  valid_603995 = validateParameter(valid_603995, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_603995 != nil:
    section.add "Action", valid_603995
  var valid_603996 = query.getOrDefault("Version")
  valid_603996 = validateParameter(valid_603996, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603996 != nil:
    section.add "Version", valid_603996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603997 = header.getOrDefault("X-Amz-Date")
  valid_603997 = validateParameter(valid_603997, JString, required = false,
                                 default = nil)
  if valid_603997 != nil:
    section.add "X-Amz-Date", valid_603997
  var valid_603998 = header.getOrDefault("X-Amz-Security-Token")
  valid_603998 = validateParameter(valid_603998, JString, required = false,
                                 default = nil)
  if valid_603998 != nil:
    section.add "X-Amz-Security-Token", valid_603998
  var valid_603999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603999 = validateParameter(valid_603999, JString, required = false,
                                 default = nil)
  if valid_603999 != nil:
    section.add "X-Amz-Content-Sha256", valid_603999
  var valid_604000 = header.getOrDefault("X-Amz-Algorithm")
  valid_604000 = validateParameter(valid_604000, JString, required = false,
                                 default = nil)
  if valid_604000 != nil:
    section.add "X-Amz-Algorithm", valid_604000
  var valid_604001 = header.getOrDefault("X-Amz-Signature")
  valid_604001 = validateParameter(valid_604001, JString, required = false,
                                 default = nil)
  if valid_604001 != nil:
    section.add "X-Amz-Signature", valid_604001
  var valid_604002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604002 = validateParameter(valid_604002, JString, required = false,
                                 default = nil)
  if valid_604002 != nil:
    section.add "X-Amz-SignedHeaders", valid_604002
  var valid_604003 = header.getOrDefault("X-Amz-Credential")
  valid_604003 = validateParameter(valid_604003, JString, required = false,
                                 default = nil)
  if valid_604003 != nil:
    section.add "X-Amz-Credential", valid_604003
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604004 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604004 = validateParameter(valid_604004, JString, required = false,
                                 default = nil)
  if valid_604004 != nil:
    section.add "DBInstanceIdentifier", valid_604004
  var valid_604005 = formData.getOrDefault("SnapshotType")
  valid_604005 = validateParameter(valid_604005, JString, required = false,
                                 default = nil)
  if valid_604005 != nil:
    section.add "SnapshotType", valid_604005
  var valid_604006 = formData.getOrDefault("Marker")
  valid_604006 = validateParameter(valid_604006, JString, required = false,
                                 default = nil)
  if valid_604006 != nil:
    section.add "Marker", valid_604006
  var valid_604007 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604007 = validateParameter(valid_604007, JString, required = false,
                                 default = nil)
  if valid_604007 != nil:
    section.add "DBSnapshotIdentifier", valid_604007
  var valid_604008 = formData.getOrDefault("MaxRecords")
  valid_604008 = validateParameter(valid_604008, JInt, required = false, default = nil)
  if valid_604008 != nil:
    section.add "MaxRecords", valid_604008
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604009: Call_PostDescribeDBSnapshots_603992; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604009.validator(path, query, header, formData, body)
  let scheme = call_604009.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604009.url(scheme.get, call_604009.host, call_604009.base,
                         call_604009.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604009, url, valid)

proc call*(call_604010: Call_PostDescribeDBSnapshots_603992;
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
  var query_604011 = newJObject()
  var formData_604012 = newJObject()
  add(formData_604012, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604012, "SnapshotType", newJString(SnapshotType))
  add(formData_604012, "Marker", newJString(Marker))
  add(formData_604012, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604011, "Action", newJString(Action))
  add(formData_604012, "MaxRecords", newJInt(MaxRecords))
  add(query_604011, "Version", newJString(Version))
  result = call_604010.call(nil, query_604011, nil, formData_604012, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_603992(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_603993, base: "/",
    url: url_PostDescribeDBSnapshots_603994, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_603972 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSnapshots_603974(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSnapshots_603973(path: JsonNode; query: JsonNode;
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
  var valid_603975 = query.getOrDefault("MaxRecords")
  valid_603975 = validateParameter(valid_603975, JInt, required = false, default = nil)
  if valid_603975 != nil:
    section.add "MaxRecords", valid_603975
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603976 = query.getOrDefault("Action")
  valid_603976 = validateParameter(valid_603976, JString, required = true,
                                 default = newJString("DescribeDBSnapshots"))
  if valid_603976 != nil:
    section.add "Action", valid_603976
  var valid_603977 = query.getOrDefault("Marker")
  valid_603977 = validateParameter(valid_603977, JString, required = false,
                                 default = nil)
  if valid_603977 != nil:
    section.add "Marker", valid_603977
  var valid_603978 = query.getOrDefault("SnapshotType")
  valid_603978 = validateParameter(valid_603978, JString, required = false,
                                 default = nil)
  if valid_603978 != nil:
    section.add "SnapshotType", valid_603978
  var valid_603979 = query.getOrDefault("Version")
  valid_603979 = validateParameter(valid_603979, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_603979 != nil:
    section.add "Version", valid_603979
  var valid_603980 = query.getOrDefault("DBInstanceIdentifier")
  valid_603980 = validateParameter(valid_603980, JString, required = false,
                                 default = nil)
  if valid_603980 != nil:
    section.add "DBInstanceIdentifier", valid_603980
  var valid_603981 = query.getOrDefault("DBSnapshotIdentifier")
  valid_603981 = validateParameter(valid_603981, JString, required = false,
                                 default = nil)
  if valid_603981 != nil:
    section.add "DBSnapshotIdentifier", valid_603981
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_603982 = header.getOrDefault("X-Amz-Date")
  valid_603982 = validateParameter(valid_603982, JString, required = false,
                                 default = nil)
  if valid_603982 != nil:
    section.add "X-Amz-Date", valid_603982
  var valid_603983 = header.getOrDefault("X-Amz-Security-Token")
  valid_603983 = validateParameter(valid_603983, JString, required = false,
                                 default = nil)
  if valid_603983 != nil:
    section.add "X-Amz-Security-Token", valid_603983
  var valid_603984 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603984 = validateParameter(valid_603984, JString, required = false,
                                 default = nil)
  if valid_603984 != nil:
    section.add "X-Amz-Content-Sha256", valid_603984
  var valid_603985 = header.getOrDefault("X-Amz-Algorithm")
  valid_603985 = validateParameter(valid_603985, JString, required = false,
                                 default = nil)
  if valid_603985 != nil:
    section.add "X-Amz-Algorithm", valid_603985
  var valid_603986 = header.getOrDefault("X-Amz-Signature")
  valid_603986 = validateParameter(valid_603986, JString, required = false,
                                 default = nil)
  if valid_603986 != nil:
    section.add "X-Amz-Signature", valid_603986
  var valid_603987 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603987 = validateParameter(valid_603987, JString, required = false,
                                 default = nil)
  if valid_603987 != nil:
    section.add "X-Amz-SignedHeaders", valid_603987
  var valid_603988 = header.getOrDefault("X-Amz-Credential")
  valid_603988 = validateParameter(valid_603988, JString, required = false,
                                 default = nil)
  if valid_603988 != nil:
    section.add "X-Amz-Credential", valid_603988
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603989: Call_GetDescribeDBSnapshots_603972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_603989.validator(path, query, header, formData, body)
  let scheme = call_603989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603989.url(scheme.get, call_603989.host, call_603989.base,
                         call_603989.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_603989, url, valid)

proc call*(call_603990: Call_GetDescribeDBSnapshots_603972; MaxRecords: int = 0;
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
  var query_603991 = newJObject()
  add(query_603991, "MaxRecords", newJInt(MaxRecords))
  add(query_603991, "Action", newJString(Action))
  add(query_603991, "Marker", newJString(Marker))
  add(query_603991, "SnapshotType", newJString(SnapshotType))
  add(query_603991, "Version", newJString(Version))
  add(query_603991, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_603991, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_603990.call(nil, query_603991, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_603972(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_603973, base: "/",
    url: url_GetDescribeDBSnapshots_603974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_604031 = ref object of OpenApiRestCall_602450
proc url_PostDescribeDBSubnetGroups_604033(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeDBSubnetGroups_604032(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604034 = query.getOrDefault("Action")
  valid_604034 = validateParameter(valid_604034, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604034 != nil:
    section.add "Action", valid_604034
  var valid_604035 = query.getOrDefault("Version")
  valid_604035 = validateParameter(valid_604035, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604035 != nil:
    section.add "Version", valid_604035
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604036 = header.getOrDefault("X-Amz-Date")
  valid_604036 = validateParameter(valid_604036, JString, required = false,
                                 default = nil)
  if valid_604036 != nil:
    section.add "X-Amz-Date", valid_604036
  var valid_604037 = header.getOrDefault("X-Amz-Security-Token")
  valid_604037 = validateParameter(valid_604037, JString, required = false,
                                 default = nil)
  if valid_604037 != nil:
    section.add "X-Amz-Security-Token", valid_604037
  var valid_604038 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604038 = validateParameter(valid_604038, JString, required = false,
                                 default = nil)
  if valid_604038 != nil:
    section.add "X-Amz-Content-Sha256", valid_604038
  var valid_604039 = header.getOrDefault("X-Amz-Algorithm")
  valid_604039 = validateParameter(valid_604039, JString, required = false,
                                 default = nil)
  if valid_604039 != nil:
    section.add "X-Amz-Algorithm", valid_604039
  var valid_604040 = header.getOrDefault("X-Amz-Signature")
  valid_604040 = validateParameter(valid_604040, JString, required = false,
                                 default = nil)
  if valid_604040 != nil:
    section.add "X-Amz-Signature", valid_604040
  var valid_604041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604041 = validateParameter(valid_604041, JString, required = false,
                                 default = nil)
  if valid_604041 != nil:
    section.add "X-Amz-SignedHeaders", valid_604041
  var valid_604042 = header.getOrDefault("X-Amz-Credential")
  valid_604042 = validateParameter(valid_604042, JString, required = false,
                                 default = nil)
  if valid_604042 != nil:
    section.add "X-Amz-Credential", valid_604042
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604043 = formData.getOrDefault("DBSubnetGroupName")
  valid_604043 = validateParameter(valid_604043, JString, required = false,
                                 default = nil)
  if valid_604043 != nil:
    section.add "DBSubnetGroupName", valid_604043
  var valid_604044 = formData.getOrDefault("Marker")
  valid_604044 = validateParameter(valid_604044, JString, required = false,
                                 default = nil)
  if valid_604044 != nil:
    section.add "Marker", valid_604044
  var valid_604045 = formData.getOrDefault("MaxRecords")
  valid_604045 = validateParameter(valid_604045, JInt, required = false, default = nil)
  if valid_604045 != nil:
    section.add "MaxRecords", valid_604045
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604046: Call_PostDescribeDBSubnetGroups_604031; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604046.validator(path, query, header, formData, body)
  let scheme = call_604046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604046.url(scheme.get, call_604046.host, call_604046.base,
                         call_604046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604046, url, valid)

proc call*(call_604047: Call_PostDescribeDBSubnetGroups_604031;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604048 = newJObject()
  var formData_604049 = newJObject()
  add(formData_604049, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604049, "Marker", newJString(Marker))
  add(query_604048, "Action", newJString(Action))
  add(formData_604049, "MaxRecords", newJInt(MaxRecords))
  add(query_604048, "Version", newJString(Version))
  result = call_604047.call(nil, query_604048, nil, formData_604049, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_604031(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_604032, base: "/",
    url: url_PostDescribeDBSubnetGroups_604033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_604013 = ref object of OpenApiRestCall_602450
proc url_GetDescribeDBSubnetGroups_604015(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeDBSubnetGroups_604014(path: JsonNode; query: JsonNode;
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
  var valid_604016 = query.getOrDefault("MaxRecords")
  valid_604016 = validateParameter(valid_604016, JInt, required = false, default = nil)
  if valid_604016 != nil:
    section.add "MaxRecords", valid_604016
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604017 = query.getOrDefault("Action")
  valid_604017 = validateParameter(valid_604017, JString, required = true,
                                 default = newJString("DescribeDBSubnetGroups"))
  if valid_604017 != nil:
    section.add "Action", valid_604017
  var valid_604018 = query.getOrDefault("Marker")
  valid_604018 = validateParameter(valid_604018, JString, required = false,
                                 default = nil)
  if valid_604018 != nil:
    section.add "Marker", valid_604018
  var valid_604019 = query.getOrDefault("DBSubnetGroupName")
  valid_604019 = validateParameter(valid_604019, JString, required = false,
                                 default = nil)
  if valid_604019 != nil:
    section.add "DBSubnetGroupName", valid_604019
  var valid_604020 = query.getOrDefault("Version")
  valid_604020 = validateParameter(valid_604020, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604020 != nil:
    section.add "Version", valid_604020
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604021 = header.getOrDefault("X-Amz-Date")
  valid_604021 = validateParameter(valid_604021, JString, required = false,
                                 default = nil)
  if valid_604021 != nil:
    section.add "X-Amz-Date", valid_604021
  var valid_604022 = header.getOrDefault("X-Amz-Security-Token")
  valid_604022 = validateParameter(valid_604022, JString, required = false,
                                 default = nil)
  if valid_604022 != nil:
    section.add "X-Amz-Security-Token", valid_604022
  var valid_604023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604023 = validateParameter(valid_604023, JString, required = false,
                                 default = nil)
  if valid_604023 != nil:
    section.add "X-Amz-Content-Sha256", valid_604023
  var valid_604024 = header.getOrDefault("X-Amz-Algorithm")
  valid_604024 = validateParameter(valid_604024, JString, required = false,
                                 default = nil)
  if valid_604024 != nil:
    section.add "X-Amz-Algorithm", valid_604024
  var valid_604025 = header.getOrDefault("X-Amz-Signature")
  valid_604025 = validateParameter(valid_604025, JString, required = false,
                                 default = nil)
  if valid_604025 != nil:
    section.add "X-Amz-Signature", valid_604025
  var valid_604026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604026 = validateParameter(valid_604026, JString, required = false,
                                 default = nil)
  if valid_604026 != nil:
    section.add "X-Amz-SignedHeaders", valid_604026
  var valid_604027 = header.getOrDefault("X-Amz-Credential")
  valid_604027 = validateParameter(valid_604027, JString, required = false,
                                 default = nil)
  if valid_604027 != nil:
    section.add "X-Amz-Credential", valid_604027
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604028: Call_GetDescribeDBSubnetGroups_604013; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604028.validator(path, query, header, formData, body)
  let scheme = call_604028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604028.url(scheme.get, call_604028.host, call_604028.base,
                         call_604028.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604028, url, valid)

proc call*(call_604029: Call_GetDescribeDBSubnetGroups_604013; MaxRecords: int = 0;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_604030 = newJObject()
  add(query_604030, "MaxRecords", newJInt(MaxRecords))
  add(query_604030, "Action", newJString(Action))
  add(query_604030, "Marker", newJString(Marker))
  add(query_604030, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604030, "Version", newJString(Version))
  result = call_604029.call(nil, query_604030, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_604013(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_604014, base: "/",
    url: url_GetDescribeDBSubnetGroups_604015,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_604068 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEngineDefaultParameters_604070(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_604069(path: JsonNode;
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
  var valid_604071 = query.getOrDefault("Action")
  valid_604071 = validateParameter(valid_604071, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604071 != nil:
    section.add "Action", valid_604071
  var valid_604072 = query.getOrDefault("Version")
  valid_604072 = validateParameter(valid_604072, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604072 != nil:
    section.add "Version", valid_604072
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604073 = header.getOrDefault("X-Amz-Date")
  valid_604073 = validateParameter(valid_604073, JString, required = false,
                                 default = nil)
  if valid_604073 != nil:
    section.add "X-Amz-Date", valid_604073
  var valid_604074 = header.getOrDefault("X-Amz-Security-Token")
  valid_604074 = validateParameter(valid_604074, JString, required = false,
                                 default = nil)
  if valid_604074 != nil:
    section.add "X-Amz-Security-Token", valid_604074
  var valid_604075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604075 = validateParameter(valid_604075, JString, required = false,
                                 default = nil)
  if valid_604075 != nil:
    section.add "X-Amz-Content-Sha256", valid_604075
  var valid_604076 = header.getOrDefault("X-Amz-Algorithm")
  valid_604076 = validateParameter(valid_604076, JString, required = false,
                                 default = nil)
  if valid_604076 != nil:
    section.add "X-Amz-Algorithm", valid_604076
  var valid_604077 = header.getOrDefault("X-Amz-Signature")
  valid_604077 = validateParameter(valid_604077, JString, required = false,
                                 default = nil)
  if valid_604077 != nil:
    section.add "X-Amz-Signature", valid_604077
  var valid_604078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604078 = validateParameter(valid_604078, JString, required = false,
                                 default = nil)
  if valid_604078 != nil:
    section.add "X-Amz-SignedHeaders", valid_604078
  var valid_604079 = header.getOrDefault("X-Amz-Credential")
  valid_604079 = validateParameter(valid_604079, JString, required = false,
                                 default = nil)
  if valid_604079 != nil:
    section.add "X-Amz-Credential", valid_604079
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604080 = formData.getOrDefault("Marker")
  valid_604080 = validateParameter(valid_604080, JString, required = false,
                                 default = nil)
  if valid_604080 != nil:
    section.add "Marker", valid_604080
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604081 = formData.getOrDefault("DBParameterGroupFamily")
  valid_604081 = validateParameter(valid_604081, JString, required = true,
                                 default = nil)
  if valid_604081 != nil:
    section.add "DBParameterGroupFamily", valid_604081
  var valid_604082 = formData.getOrDefault("MaxRecords")
  valid_604082 = validateParameter(valid_604082, JInt, required = false, default = nil)
  if valid_604082 != nil:
    section.add "MaxRecords", valid_604082
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604083: Call_PostDescribeEngineDefaultParameters_604068;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604083.validator(path, query, header, formData, body)
  let scheme = call_604083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604083.url(scheme.get, call_604083.host, call_604083.base,
                         call_604083.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604083, url, valid)

proc call*(call_604084: Call_PostDescribeEngineDefaultParameters_604068;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604085 = newJObject()
  var formData_604086 = newJObject()
  add(formData_604086, "Marker", newJString(Marker))
  add(query_604085, "Action", newJString(Action))
  add(formData_604086, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(formData_604086, "MaxRecords", newJInt(MaxRecords))
  add(query_604085, "Version", newJString(Version))
  result = call_604084.call(nil, query_604085, nil, formData_604086, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_604068(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_604069, base: "/",
    url: url_PostDescribeEngineDefaultParameters_604070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_604050 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEngineDefaultParameters_604052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_604051(path: JsonNode;
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
  var valid_604053 = query.getOrDefault("MaxRecords")
  valid_604053 = validateParameter(valid_604053, JInt, required = false, default = nil)
  if valid_604053 != nil:
    section.add "MaxRecords", valid_604053
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_604054 = query.getOrDefault("DBParameterGroupFamily")
  valid_604054 = validateParameter(valid_604054, JString, required = true,
                                 default = nil)
  if valid_604054 != nil:
    section.add "DBParameterGroupFamily", valid_604054
  var valid_604055 = query.getOrDefault("Action")
  valid_604055 = validateParameter(valid_604055, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_604055 != nil:
    section.add "Action", valid_604055
  var valid_604056 = query.getOrDefault("Marker")
  valid_604056 = validateParameter(valid_604056, JString, required = false,
                                 default = nil)
  if valid_604056 != nil:
    section.add "Marker", valid_604056
  var valid_604057 = query.getOrDefault("Version")
  valid_604057 = validateParameter(valid_604057, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604057 != nil:
    section.add "Version", valid_604057
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604058 = header.getOrDefault("X-Amz-Date")
  valid_604058 = validateParameter(valid_604058, JString, required = false,
                                 default = nil)
  if valid_604058 != nil:
    section.add "X-Amz-Date", valid_604058
  var valid_604059 = header.getOrDefault("X-Amz-Security-Token")
  valid_604059 = validateParameter(valid_604059, JString, required = false,
                                 default = nil)
  if valid_604059 != nil:
    section.add "X-Amz-Security-Token", valid_604059
  var valid_604060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604060 = validateParameter(valid_604060, JString, required = false,
                                 default = nil)
  if valid_604060 != nil:
    section.add "X-Amz-Content-Sha256", valid_604060
  var valid_604061 = header.getOrDefault("X-Amz-Algorithm")
  valid_604061 = validateParameter(valid_604061, JString, required = false,
                                 default = nil)
  if valid_604061 != nil:
    section.add "X-Amz-Algorithm", valid_604061
  var valid_604062 = header.getOrDefault("X-Amz-Signature")
  valid_604062 = validateParameter(valid_604062, JString, required = false,
                                 default = nil)
  if valid_604062 != nil:
    section.add "X-Amz-Signature", valid_604062
  var valid_604063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604063 = validateParameter(valid_604063, JString, required = false,
                                 default = nil)
  if valid_604063 != nil:
    section.add "X-Amz-SignedHeaders", valid_604063
  var valid_604064 = header.getOrDefault("X-Amz-Credential")
  valid_604064 = validateParameter(valid_604064, JString, required = false,
                                 default = nil)
  if valid_604064 != nil:
    section.add "X-Amz-Credential", valid_604064
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604065: Call_GetDescribeEngineDefaultParameters_604050;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604065.validator(path, query, header, formData, body)
  let scheme = call_604065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604065.url(scheme.get, call_604065.host, call_604065.base,
                         call_604065.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604065, url, valid)

proc call*(call_604066: Call_GetDescribeEngineDefaultParameters_604050;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_604067 = newJObject()
  add(query_604067, "MaxRecords", newJInt(MaxRecords))
  add(query_604067, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  add(query_604067, "Action", newJString(Action))
  add(query_604067, "Marker", newJString(Marker))
  add(query_604067, "Version", newJString(Version))
  result = call_604066.call(nil, query_604067, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_604050(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_604051, base: "/",
    url: url_GetDescribeEngineDefaultParameters_604052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_604103 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventCategories_604105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventCategories_604104(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604106 = query.getOrDefault("Action")
  valid_604106 = validateParameter(valid_604106, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604106 != nil:
    section.add "Action", valid_604106
  var valid_604107 = query.getOrDefault("Version")
  valid_604107 = validateParameter(valid_604107, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604107 != nil:
    section.add "Version", valid_604107
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604108 = header.getOrDefault("X-Amz-Date")
  valid_604108 = validateParameter(valid_604108, JString, required = false,
                                 default = nil)
  if valid_604108 != nil:
    section.add "X-Amz-Date", valid_604108
  var valid_604109 = header.getOrDefault("X-Amz-Security-Token")
  valid_604109 = validateParameter(valid_604109, JString, required = false,
                                 default = nil)
  if valid_604109 != nil:
    section.add "X-Amz-Security-Token", valid_604109
  var valid_604110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604110 = validateParameter(valid_604110, JString, required = false,
                                 default = nil)
  if valid_604110 != nil:
    section.add "X-Amz-Content-Sha256", valid_604110
  var valid_604111 = header.getOrDefault("X-Amz-Algorithm")
  valid_604111 = validateParameter(valid_604111, JString, required = false,
                                 default = nil)
  if valid_604111 != nil:
    section.add "X-Amz-Algorithm", valid_604111
  var valid_604112 = header.getOrDefault("X-Amz-Signature")
  valid_604112 = validateParameter(valid_604112, JString, required = false,
                                 default = nil)
  if valid_604112 != nil:
    section.add "X-Amz-Signature", valid_604112
  var valid_604113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604113 = validateParameter(valid_604113, JString, required = false,
                                 default = nil)
  if valid_604113 != nil:
    section.add "X-Amz-SignedHeaders", valid_604113
  var valid_604114 = header.getOrDefault("X-Amz-Credential")
  valid_604114 = validateParameter(valid_604114, JString, required = false,
                                 default = nil)
  if valid_604114 != nil:
    section.add "X-Amz-Credential", valid_604114
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_604115 = formData.getOrDefault("SourceType")
  valid_604115 = validateParameter(valid_604115, JString, required = false,
                                 default = nil)
  if valid_604115 != nil:
    section.add "SourceType", valid_604115
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604116: Call_PostDescribeEventCategories_604103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604116.validator(path, query, header, formData, body)
  let scheme = call_604116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604116.url(scheme.get, call_604116.host, call_604116.base,
                         call_604116.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604116, url, valid)

proc call*(call_604117: Call_PostDescribeEventCategories_604103;
          Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_604118 = newJObject()
  var formData_604119 = newJObject()
  add(query_604118, "Action", newJString(Action))
  add(query_604118, "Version", newJString(Version))
  add(formData_604119, "SourceType", newJString(SourceType))
  result = call_604117.call(nil, query_604118, nil, formData_604119, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_604103(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_604104, base: "/",
    url: url_PostDescribeEventCategories_604105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_604087 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventCategories_604089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventCategories_604088(path: JsonNode; query: JsonNode;
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
  var valid_604090 = query.getOrDefault("SourceType")
  valid_604090 = validateParameter(valid_604090, JString, required = false,
                                 default = nil)
  if valid_604090 != nil:
    section.add "SourceType", valid_604090
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604091 = query.getOrDefault("Action")
  valid_604091 = validateParameter(valid_604091, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_604091 != nil:
    section.add "Action", valid_604091
  var valid_604092 = query.getOrDefault("Version")
  valid_604092 = validateParameter(valid_604092, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604092 != nil:
    section.add "Version", valid_604092
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604093 = header.getOrDefault("X-Amz-Date")
  valid_604093 = validateParameter(valid_604093, JString, required = false,
                                 default = nil)
  if valid_604093 != nil:
    section.add "X-Amz-Date", valid_604093
  var valid_604094 = header.getOrDefault("X-Amz-Security-Token")
  valid_604094 = validateParameter(valid_604094, JString, required = false,
                                 default = nil)
  if valid_604094 != nil:
    section.add "X-Amz-Security-Token", valid_604094
  var valid_604095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604095 = validateParameter(valid_604095, JString, required = false,
                                 default = nil)
  if valid_604095 != nil:
    section.add "X-Amz-Content-Sha256", valid_604095
  var valid_604096 = header.getOrDefault("X-Amz-Algorithm")
  valid_604096 = validateParameter(valid_604096, JString, required = false,
                                 default = nil)
  if valid_604096 != nil:
    section.add "X-Amz-Algorithm", valid_604096
  var valid_604097 = header.getOrDefault("X-Amz-Signature")
  valid_604097 = validateParameter(valid_604097, JString, required = false,
                                 default = nil)
  if valid_604097 != nil:
    section.add "X-Amz-Signature", valid_604097
  var valid_604098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604098 = validateParameter(valid_604098, JString, required = false,
                                 default = nil)
  if valid_604098 != nil:
    section.add "X-Amz-SignedHeaders", valid_604098
  var valid_604099 = header.getOrDefault("X-Amz-Credential")
  valid_604099 = validateParameter(valid_604099, JString, required = false,
                                 default = nil)
  if valid_604099 != nil:
    section.add "X-Amz-Credential", valid_604099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604100: Call_GetDescribeEventCategories_604087; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604100.validator(path, query, header, formData, body)
  let scheme = call_604100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604100.url(scheme.get, call_604100.host, call_604100.base,
                         call_604100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604100, url, valid)

proc call*(call_604101: Call_GetDescribeEventCategories_604087;
          SourceType: string = ""; Action: string = "DescribeEventCategories";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604102 = newJObject()
  add(query_604102, "SourceType", newJString(SourceType))
  add(query_604102, "Action", newJString(Action))
  add(query_604102, "Version", newJString(Version))
  result = call_604101.call(nil, query_604102, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_604087(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_604088, base: "/",
    url: url_GetDescribeEventCategories_604089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_604138 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEventSubscriptions_604140(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEventSubscriptions_604139(path: JsonNode;
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
  var valid_604141 = query.getOrDefault("Action")
  valid_604141 = validateParameter(valid_604141, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604141 != nil:
    section.add "Action", valid_604141
  var valid_604142 = query.getOrDefault("Version")
  valid_604142 = validateParameter(valid_604142, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604142 != nil:
    section.add "Version", valid_604142
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604143 = header.getOrDefault("X-Amz-Date")
  valid_604143 = validateParameter(valid_604143, JString, required = false,
                                 default = nil)
  if valid_604143 != nil:
    section.add "X-Amz-Date", valid_604143
  var valid_604144 = header.getOrDefault("X-Amz-Security-Token")
  valid_604144 = validateParameter(valid_604144, JString, required = false,
                                 default = nil)
  if valid_604144 != nil:
    section.add "X-Amz-Security-Token", valid_604144
  var valid_604145 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604145 = validateParameter(valid_604145, JString, required = false,
                                 default = nil)
  if valid_604145 != nil:
    section.add "X-Amz-Content-Sha256", valid_604145
  var valid_604146 = header.getOrDefault("X-Amz-Algorithm")
  valid_604146 = validateParameter(valid_604146, JString, required = false,
                                 default = nil)
  if valid_604146 != nil:
    section.add "X-Amz-Algorithm", valid_604146
  var valid_604147 = header.getOrDefault("X-Amz-Signature")
  valid_604147 = validateParameter(valid_604147, JString, required = false,
                                 default = nil)
  if valid_604147 != nil:
    section.add "X-Amz-Signature", valid_604147
  var valid_604148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604148 = validateParameter(valid_604148, JString, required = false,
                                 default = nil)
  if valid_604148 != nil:
    section.add "X-Amz-SignedHeaders", valid_604148
  var valid_604149 = header.getOrDefault("X-Amz-Credential")
  valid_604149 = validateParameter(valid_604149, JString, required = false,
                                 default = nil)
  if valid_604149 != nil:
    section.add "X-Amz-Credential", valid_604149
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604150 = formData.getOrDefault("Marker")
  valid_604150 = validateParameter(valid_604150, JString, required = false,
                                 default = nil)
  if valid_604150 != nil:
    section.add "Marker", valid_604150
  var valid_604151 = formData.getOrDefault("SubscriptionName")
  valid_604151 = validateParameter(valid_604151, JString, required = false,
                                 default = nil)
  if valid_604151 != nil:
    section.add "SubscriptionName", valid_604151
  var valid_604152 = formData.getOrDefault("MaxRecords")
  valid_604152 = validateParameter(valid_604152, JInt, required = false, default = nil)
  if valid_604152 != nil:
    section.add "MaxRecords", valid_604152
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604153: Call_PostDescribeEventSubscriptions_604138; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604153.validator(path, query, header, formData, body)
  let scheme = call_604153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604153.url(scheme.get, call_604153.host, call_604153.base,
                         call_604153.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604153, url, valid)

proc call*(call_604154: Call_PostDescribeEventSubscriptions_604138;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; MaxRecords: int = 0;
          Version: string = "2013-01-10"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_604155 = newJObject()
  var formData_604156 = newJObject()
  add(formData_604156, "Marker", newJString(Marker))
  add(formData_604156, "SubscriptionName", newJString(SubscriptionName))
  add(query_604155, "Action", newJString(Action))
  add(formData_604156, "MaxRecords", newJInt(MaxRecords))
  add(query_604155, "Version", newJString(Version))
  result = call_604154.call(nil, query_604155, nil, formData_604156, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_604138(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_604139, base: "/",
    url: url_PostDescribeEventSubscriptions_604140,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_604120 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEventSubscriptions_604122(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEventSubscriptions_604121(path: JsonNode; query: JsonNode;
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
  var valid_604123 = query.getOrDefault("MaxRecords")
  valid_604123 = validateParameter(valid_604123, JInt, required = false, default = nil)
  if valid_604123 != nil:
    section.add "MaxRecords", valid_604123
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604124 = query.getOrDefault("Action")
  valid_604124 = validateParameter(valid_604124, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_604124 != nil:
    section.add "Action", valid_604124
  var valid_604125 = query.getOrDefault("Marker")
  valid_604125 = validateParameter(valid_604125, JString, required = false,
                                 default = nil)
  if valid_604125 != nil:
    section.add "Marker", valid_604125
  var valid_604126 = query.getOrDefault("SubscriptionName")
  valid_604126 = validateParameter(valid_604126, JString, required = false,
                                 default = nil)
  if valid_604126 != nil:
    section.add "SubscriptionName", valid_604126
  var valid_604127 = query.getOrDefault("Version")
  valid_604127 = validateParameter(valid_604127, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604127 != nil:
    section.add "Version", valid_604127
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604128 = header.getOrDefault("X-Amz-Date")
  valid_604128 = validateParameter(valid_604128, JString, required = false,
                                 default = nil)
  if valid_604128 != nil:
    section.add "X-Amz-Date", valid_604128
  var valid_604129 = header.getOrDefault("X-Amz-Security-Token")
  valid_604129 = validateParameter(valid_604129, JString, required = false,
                                 default = nil)
  if valid_604129 != nil:
    section.add "X-Amz-Security-Token", valid_604129
  var valid_604130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604130 = validateParameter(valid_604130, JString, required = false,
                                 default = nil)
  if valid_604130 != nil:
    section.add "X-Amz-Content-Sha256", valid_604130
  var valid_604131 = header.getOrDefault("X-Amz-Algorithm")
  valid_604131 = validateParameter(valid_604131, JString, required = false,
                                 default = nil)
  if valid_604131 != nil:
    section.add "X-Amz-Algorithm", valid_604131
  var valid_604132 = header.getOrDefault("X-Amz-Signature")
  valid_604132 = validateParameter(valid_604132, JString, required = false,
                                 default = nil)
  if valid_604132 != nil:
    section.add "X-Amz-Signature", valid_604132
  var valid_604133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604133 = validateParameter(valid_604133, JString, required = false,
                                 default = nil)
  if valid_604133 != nil:
    section.add "X-Amz-SignedHeaders", valid_604133
  var valid_604134 = header.getOrDefault("X-Amz-Credential")
  valid_604134 = validateParameter(valid_604134, JString, required = false,
                                 default = nil)
  if valid_604134 != nil:
    section.add "X-Amz-Credential", valid_604134
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604135: Call_GetDescribeEventSubscriptions_604120; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604135.validator(path, query, header, formData, body)
  let scheme = call_604135.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604135.url(scheme.get, call_604135.host, call_604135.base,
                         call_604135.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604135, url, valid)

proc call*(call_604136: Call_GetDescribeEventSubscriptions_604120;
          MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
          Marker: string = ""; SubscriptionName: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_604137 = newJObject()
  add(query_604137, "MaxRecords", newJInt(MaxRecords))
  add(query_604137, "Action", newJString(Action))
  add(query_604137, "Marker", newJString(Marker))
  add(query_604137, "SubscriptionName", newJString(SubscriptionName))
  add(query_604137, "Version", newJString(Version))
  result = call_604136.call(nil, query_604137, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_604120(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_604121, base: "/",
    url: url_GetDescribeEventSubscriptions_604122,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_604180 = ref object of OpenApiRestCall_602450
proc url_PostDescribeEvents_604182(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeEvents_604181(path: JsonNode; query: JsonNode;
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
  var valid_604183 = query.getOrDefault("Action")
  valid_604183 = validateParameter(valid_604183, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604183 != nil:
    section.add "Action", valid_604183
  var valid_604184 = query.getOrDefault("Version")
  valid_604184 = validateParameter(valid_604184, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604184 != nil:
    section.add "Version", valid_604184
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604185 = header.getOrDefault("X-Amz-Date")
  valid_604185 = validateParameter(valid_604185, JString, required = false,
                                 default = nil)
  if valid_604185 != nil:
    section.add "X-Amz-Date", valid_604185
  var valid_604186 = header.getOrDefault("X-Amz-Security-Token")
  valid_604186 = validateParameter(valid_604186, JString, required = false,
                                 default = nil)
  if valid_604186 != nil:
    section.add "X-Amz-Security-Token", valid_604186
  var valid_604187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604187 = validateParameter(valid_604187, JString, required = false,
                                 default = nil)
  if valid_604187 != nil:
    section.add "X-Amz-Content-Sha256", valid_604187
  var valid_604188 = header.getOrDefault("X-Amz-Algorithm")
  valid_604188 = validateParameter(valid_604188, JString, required = false,
                                 default = nil)
  if valid_604188 != nil:
    section.add "X-Amz-Algorithm", valid_604188
  var valid_604189 = header.getOrDefault("X-Amz-Signature")
  valid_604189 = validateParameter(valid_604189, JString, required = false,
                                 default = nil)
  if valid_604189 != nil:
    section.add "X-Amz-Signature", valid_604189
  var valid_604190 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604190 = validateParameter(valid_604190, JString, required = false,
                                 default = nil)
  if valid_604190 != nil:
    section.add "X-Amz-SignedHeaders", valid_604190
  var valid_604191 = header.getOrDefault("X-Amz-Credential")
  valid_604191 = validateParameter(valid_604191, JString, required = false,
                                 default = nil)
  if valid_604191 != nil:
    section.add "X-Amz-Credential", valid_604191
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
  var valid_604192 = formData.getOrDefault("SourceIdentifier")
  valid_604192 = validateParameter(valid_604192, JString, required = false,
                                 default = nil)
  if valid_604192 != nil:
    section.add "SourceIdentifier", valid_604192
  var valid_604193 = formData.getOrDefault("EventCategories")
  valid_604193 = validateParameter(valid_604193, JArray, required = false,
                                 default = nil)
  if valid_604193 != nil:
    section.add "EventCategories", valid_604193
  var valid_604194 = formData.getOrDefault("Marker")
  valid_604194 = validateParameter(valid_604194, JString, required = false,
                                 default = nil)
  if valid_604194 != nil:
    section.add "Marker", valid_604194
  var valid_604195 = formData.getOrDefault("StartTime")
  valid_604195 = validateParameter(valid_604195, JString, required = false,
                                 default = nil)
  if valid_604195 != nil:
    section.add "StartTime", valid_604195
  var valid_604196 = formData.getOrDefault("Duration")
  valid_604196 = validateParameter(valid_604196, JInt, required = false, default = nil)
  if valid_604196 != nil:
    section.add "Duration", valid_604196
  var valid_604197 = formData.getOrDefault("EndTime")
  valid_604197 = validateParameter(valid_604197, JString, required = false,
                                 default = nil)
  if valid_604197 != nil:
    section.add "EndTime", valid_604197
  var valid_604198 = formData.getOrDefault("MaxRecords")
  valid_604198 = validateParameter(valid_604198, JInt, required = false, default = nil)
  if valid_604198 != nil:
    section.add "MaxRecords", valid_604198
  var valid_604199 = formData.getOrDefault("SourceType")
  valid_604199 = validateParameter(valid_604199, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604199 != nil:
    section.add "SourceType", valid_604199
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604200: Call_PostDescribeEvents_604180; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604200.validator(path, query, header, formData, body)
  let scheme = call_604200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604200.url(scheme.get, call_604200.host, call_604200.base,
                         call_604200.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604200, url, valid)

proc call*(call_604201: Call_PostDescribeEvents_604180;
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
  var query_604202 = newJObject()
  var formData_604203 = newJObject()
  add(formData_604203, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_604203.add "EventCategories", EventCategories
  add(formData_604203, "Marker", newJString(Marker))
  add(formData_604203, "StartTime", newJString(StartTime))
  add(query_604202, "Action", newJString(Action))
  add(formData_604203, "Duration", newJInt(Duration))
  add(formData_604203, "EndTime", newJString(EndTime))
  add(formData_604203, "MaxRecords", newJInt(MaxRecords))
  add(query_604202, "Version", newJString(Version))
  add(formData_604203, "SourceType", newJString(SourceType))
  result = call_604201.call(nil, query_604202, nil, formData_604203, nil)

var postDescribeEvents* = Call_PostDescribeEvents_604180(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_604181, base: "/",
    url: url_PostDescribeEvents_604182, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_604157 = ref object of OpenApiRestCall_602450
proc url_GetDescribeEvents_604159(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeEvents_604158(path: JsonNode; query: JsonNode;
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
  var valid_604160 = query.getOrDefault("SourceType")
  valid_604160 = validateParameter(valid_604160, JString, required = false,
                                 default = newJString("db-instance"))
  if valid_604160 != nil:
    section.add "SourceType", valid_604160
  var valid_604161 = query.getOrDefault("MaxRecords")
  valid_604161 = validateParameter(valid_604161, JInt, required = false, default = nil)
  if valid_604161 != nil:
    section.add "MaxRecords", valid_604161
  var valid_604162 = query.getOrDefault("StartTime")
  valid_604162 = validateParameter(valid_604162, JString, required = false,
                                 default = nil)
  if valid_604162 != nil:
    section.add "StartTime", valid_604162
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604163 = query.getOrDefault("Action")
  valid_604163 = validateParameter(valid_604163, JString, required = true,
                                 default = newJString("DescribeEvents"))
  if valid_604163 != nil:
    section.add "Action", valid_604163
  var valid_604164 = query.getOrDefault("SourceIdentifier")
  valid_604164 = validateParameter(valid_604164, JString, required = false,
                                 default = nil)
  if valid_604164 != nil:
    section.add "SourceIdentifier", valid_604164
  var valid_604165 = query.getOrDefault("Marker")
  valid_604165 = validateParameter(valid_604165, JString, required = false,
                                 default = nil)
  if valid_604165 != nil:
    section.add "Marker", valid_604165
  var valid_604166 = query.getOrDefault("EventCategories")
  valid_604166 = validateParameter(valid_604166, JArray, required = false,
                                 default = nil)
  if valid_604166 != nil:
    section.add "EventCategories", valid_604166
  var valid_604167 = query.getOrDefault("Duration")
  valid_604167 = validateParameter(valid_604167, JInt, required = false, default = nil)
  if valid_604167 != nil:
    section.add "Duration", valid_604167
  var valid_604168 = query.getOrDefault("EndTime")
  valid_604168 = validateParameter(valid_604168, JString, required = false,
                                 default = nil)
  if valid_604168 != nil:
    section.add "EndTime", valid_604168
  var valid_604169 = query.getOrDefault("Version")
  valid_604169 = validateParameter(valid_604169, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604169 != nil:
    section.add "Version", valid_604169
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604170 = header.getOrDefault("X-Amz-Date")
  valid_604170 = validateParameter(valid_604170, JString, required = false,
                                 default = nil)
  if valid_604170 != nil:
    section.add "X-Amz-Date", valid_604170
  var valid_604171 = header.getOrDefault("X-Amz-Security-Token")
  valid_604171 = validateParameter(valid_604171, JString, required = false,
                                 default = nil)
  if valid_604171 != nil:
    section.add "X-Amz-Security-Token", valid_604171
  var valid_604172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604172 = validateParameter(valid_604172, JString, required = false,
                                 default = nil)
  if valid_604172 != nil:
    section.add "X-Amz-Content-Sha256", valid_604172
  var valid_604173 = header.getOrDefault("X-Amz-Algorithm")
  valid_604173 = validateParameter(valid_604173, JString, required = false,
                                 default = nil)
  if valid_604173 != nil:
    section.add "X-Amz-Algorithm", valid_604173
  var valid_604174 = header.getOrDefault("X-Amz-Signature")
  valid_604174 = validateParameter(valid_604174, JString, required = false,
                                 default = nil)
  if valid_604174 != nil:
    section.add "X-Amz-Signature", valid_604174
  var valid_604175 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604175 = validateParameter(valid_604175, JString, required = false,
                                 default = nil)
  if valid_604175 != nil:
    section.add "X-Amz-SignedHeaders", valid_604175
  var valid_604176 = header.getOrDefault("X-Amz-Credential")
  valid_604176 = validateParameter(valid_604176, JString, required = false,
                                 default = nil)
  if valid_604176 != nil:
    section.add "X-Amz-Credential", valid_604176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604177: Call_GetDescribeEvents_604157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604177.validator(path, query, header, formData, body)
  let scheme = call_604177.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604177.url(scheme.get, call_604177.host, call_604177.base,
                         call_604177.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604177, url, valid)

proc call*(call_604178: Call_GetDescribeEvents_604157;
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
  var query_604179 = newJObject()
  add(query_604179, "SourceType", newJString(SourceType))
  add(query_604179, "MaxRecords", newJInt(MaxRecords))
  add(query_604179, "StartTime", newJString(StartTime))
  add(query_604179, "Action", newJString(Action))
  add(query_604179, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604179, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_604179.add "EventCategories", EventCategories
  add(query_604179, "Duration", newJInt(Duration))
  add(query_604179, "EndTime", newJString(EndTime))
  add(query_604179, "Version", newJString(Version))
  result = call_604178.call(nil, query_604179, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_604157(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_604158,
    base: "/", url: url_GetDescribeEvents_604159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_604223 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroupOptions_604225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroupOptions_604224(path: JsonNode;
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
  var valid_604226 = query.getOrDefault("Action")
  valid_604226 = validateParameter(valid_604226, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604226 != nil:
    section.add "Action", valid_604226
  var valid_604227 = query.getOrDefault("Version")
  valid_604227 = validateParameter(valid_604227, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604235 = formData.getOrDefault("MajorEngineVersion")
  valid_604235 = validateParameter(valid_604235, JString, required = false,
                                 default = nil)
  if valid_604235 != nil:
    section.add "MajorEngineVersion", valid_604235
  var valid_604236 = formData.getOrDefault("Marker")
  valid_604236 = validateParameter(valid_604236, JString, required = false,
                                 default = nil)
  if valid_604236 != nil:
    section.add "Marker", valid_604236
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_604237 = formData.getOrDefault("EngineName")
  valid_604237 = validateParameter(valid_604237, JString, required = true,
                                 default = nil)
  if valid_604237 != nil:
    section.add "EngineName", valid_604237
  var valid_604238 = formData.getOrDefault("MaxRecords")
  valid_604238 = validateParameter(valid_604238, JInt, required = false, default = nil)
  if valid_604238 != nil:
    section.add "MaxRecords", valid_604238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604239: Call_PostDescribeOptionGroupOptions_604223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604239.validator(path, query, header, formData, body)
  let scheme = call_604239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604239.url(scheme.get, call_604239.host, call_604239.base,
                         call_604239.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604239, url, valid)

proc call*(call_604240: Call_PostDescribeOptionGroupOptions_604223;
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
  var query_604241 = newJObject()
  var formData_604242 = newJObject()
  add(formData_604242, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604242, "Marker", newJString(Marker))
  add(query_604241, "Action", newJString(Action))
  add(formData_604242, "EngineName", newJString(EngineName))
  add(formData_604242, "MaxRecords", newJInt(MaxRecords))
  add(query_604241, "Version", newJString(Version))
  result = call_604240.call(nil, query_604241, nil, formData_604242, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_604223(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_604224, base: "/",
    url: url_PostDescribeOptionGroupOptions_604225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_604204 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroupOptions_604206(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroupOptions_604205(path: JsonNode; query: JsonNode;
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
  var valid_604207 = query.getOrDefault("MaxRecords")
  valid_604207 = validateParameter(valid_604207, JInt, required = false, default = nil)
  if valid_604207 != nil:
    section.add "MaxRecords", valid_604207
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604208 = query.getOrDefault("Action")
  valid_604208 = validateParameter(valid_604208, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_604208 != nil:
    section.add "Action", valid_604208
  var valid_604209 = query.getOrDefault("Marker")
  valid_604209 = validateParameter(valid_604209, JString, required = false,
                                 default = nil)
  if valid_604209 != nil:
    section.add "Marker", valid_604209
  var valid_604210 = query.getOrDefault("Version")
  valid_604210 = validateParameter(valid_604210, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604210 != nil:
    section.add "Version", valid_604210
  var valid_604211 = query.getOrDefault("EngineName")
  valid_604211 = validateParameter(valid_604211, JString, required = true,
                                 default = nil)
  if valid_604211 != nil:
    section.add "EngineName", valid_604211
  var valid_604212 = query.getOrDefault("MajorEngineVersion")
  valid_604212 = validateParameter(valid_604212, JString, required = false,
                                 default = nil)
  if valid_604212 != nil:
    section.add "MajorEngineVersion", valid_604212
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604213 = header.getOrDefault("X-Amz-Date")
  valid_604213 = validateParameter(valid_604213, JString, required = false,
                                 default = nil)
  if valid_604213 != nil:
    section.add "X-Amz-Date", valid_604213
  var valid_604214 = header.getOrDefault("X-Amz-Security-Token")
  valid_604214 = validateParameter(valid_604214, JString, required = false,
                                 default = nil)
  if valid_604214 != nil:
    section.add "X-Amz-Security-Token", valid_604214
  var valid_604215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604215 = validateParameter(valid_604215, JString, required = false,
                                 default = nil)
  if valid_604215 != nil:
    section.add "X-Amz-Content-Sha256", valid_604215
  var valid_604216 = header.getOrDefault("X-Amz-Algorithm")
  valid_604216 = validateParameter(valid_604216, JString, required = false,
                                 default = nil)
  if valid_604216 != nil:
    section.add "X-Amz-Algorithm", valid_604216
  var valid_604217 = header.getOrDefault("X-Amz-Signature")
  valid_604217 = validateParameter(valid_604217, JString, required = false,
                                 default = nil)
  if valid_604217 != nil:
    section.add "X-Amz-Signature", valid_604217
  var valid_604218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604218 = validateParameter(valid_604218, JString, required = false,
                                 default = nil)
  if valid_604218 != nil:
    section.add "X-Amz-SignedHeaders", valid_604218
  var valid_604219 = header.getOrDefault("X-Amz-Credential")
  valid_604219 = validateParameter(valid_604219, JString, required = false,
                                 default = nil)
  if valid_604219 != nil:
    section.add "X-Amz-Credential", valid_604219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604220: Call_GetDescribeOptionGroupOptions_604204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604220.validator(path, query, header, formData, body)
  let scheme = call_604220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604220.url(scheme.get, call_604220.host, call_604220.base,
                         call_604220.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604220, url, valid)

proc call*(call_604221: Call_GetDescribeOptionGroupOptions_604204;
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
  var query_604222 = newJObject()
  add(query_604222, "MaxRecords", newJInt(MaxRecords))
  add(query_604222, "Action", newJString(Action))
  add(query_604222, "Marker", newJString(Marker))
  add(query_604222, "Version", newJString(Version))
  add(query_604222, "EngineName", newJString(EngineName))
  add(query_604222, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604221.call(nil, query_604222, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_604204(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_604205, base: "/",
    url: url_GetDescribeOptionGroupOptions_604206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_604263 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOptionGroups_604265(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOptionGroups_604264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604266 = query.getOrDefault("Action")
  valid_604266 = validateParameter(valid_604266, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604266 != nil:
    section.add "Action", valid_604266
  var valid_604267 = query.getOrDefault("Version")
  valid_604267 = validateParameter(valid_604267, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604267 != nil:
    section.add "Version", valid_604267
  result.add "query", section
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
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_604275 = formData.getOrDefault("MajorEngineVersion")
  valid_604275 = validateParameter(valid_604275, JString, required = false,
                                 default = nil)
  if valid_604275 != nil:
    section.add "MajorEngineVersion", valid_604275
  var valid_604276 = formData.getOrDefault("OptionGroupName")
  valid_604276 = validateParameter(valid_604276, JString, required = false,
                                 default = nil)
  if valid_604276 != nil:
    section.add "OptionGroupName", valid_604276
  var valid_604277 = formData.getOrDefault("Marker")
  valid_604277 = validateParameter(valid_604277, JString, required = false,
                                 default = nil)
  if valid_604277 != nil:
    section.add "Marker", valid_604277
  var valid_604278 = formData.getOrDefault("EngineName")
  valid_604278 = validateParameter(valid_604278, JString, required = false,
                                 default = nil)
  if valid_604278 != nil:
    section.add "EngineName", valid_604278
  var valid_604279 = formData.getOrDefault("MaxRecords")
  valid_604279 = validateParameter(valid_604279, JInt, required = false, default = nil)
  if valid_604279 != nil:
    section.add "MaxRecords", valid_604279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604280: Call_PostDescribeOptionGroups_604263; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604280.validator(path, query, header, formData, body)
  let scheme = call_604280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604280.url(scheme.get, call_604280.host, call_604280.base,
                         call_604280.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604280, url, valid)

proc call*(call_604281: Call_PostDescribeOptionGroups_604263;
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
  var query_604282 = newJObject()
  var formData_604283 = newJObject()
  add(formData_604283, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_604283, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604283, "Marker", newJString(Marker))
  add(query_604282, "Action", newJString(Action))
  add(formData_604283, "EngineName", newJString(EngineName))
  add(formData_604283, "MaxRecords", newJInt(MaxRecords))
  add(query_604282, "Version", newJString(Version))
  result = call_604281.call(nil, query_604282, nil, formData_604283, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_604263(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_604264, base: "/",
    url: url_PostDescribeOptionGroups_604265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_604243 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOptionGroups_604245(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOptionGroups_604244(path: JsonNode; query: JsonNode;
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
  var valid_604246 = query.getOrDefault("MaxRecords")
  valid_604246 = validateParameter(valid_604246, JInt, required = false, default = nil)
  if valid_604246 != nil:
    section.add "MaxRecords", valid_604246
  var valid_604247 = query.getOrDefault("OptionGroupName")
  valid_604247 = validateParameter(valid_604247, JString, required = false,
                                 default = nil)
  if valid_604247 != nil:
    section.add "OptionGroupName", valid_604247
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604248 = query.getOrDefault("Action")
  valid_604248 = validateParameter(valid_604248, JString, required = true,
                                 default = newJString("DescribeOptionGroups"))
  if valid_604248 != nil:
    section.add "Action", valid_604248
  var valid_604249 = query.getOrDefault("Marker")
  valid_604249 = validateParameter(valid_604249, JString, required = false,
                                 default = nil)
  if valid_604249 != nil:
    section.add "Marker", valid_604249
  var valid_604250 = query.getOrDefault("Version")
  valid_604250 = validateParameter(valid_604250, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604250 != nil:
    section.add "Version", valid_604250
  var valid_604251 = query.getOrDefault("EngineName")
  valid_604251 = validateParameter(valid_604251, JString, required = false,
                                 default = nil)
  if valid_604251 != nil:
    section.add "EngineName", valid_604251
  var valid_604252 = query.getOrDefault("MajorEngineVersion")
  valid_604252 = validateParameter(valid_604252, JString, required = false,
                                 default = nil)
  if valid_604252 != nil:
    section.add "MajorEngineVersion", valid_604252
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604253 = header.getOrDefault("X-Amz-Date")
  valid_604253 = validateParameter(valid_604253, JString, required = false,
                                 default = nil)
  if valid_604253 != nil:
    section.add "X-Amz-Date", valid_604253
  var valid_604254 = header.getOrDefault("X-Amz-Security-Token")
  valid_604254 = validateParameter(valid_604254, JString, required = false,
                                 default = nil)
  if valid_604254 != nil:
    section.add "X-Amz-Security-Token", valid_604254
  var valid_604255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604255 = validateParameter(valid_604255, JString, required = false,
                                 default = nil)
  if valid_604255 != nil:
    section.add "X-Amz-Content-Sha256", valid_604255
  var valid_604256 = header.getOrDefault("X-Amz-Algorithm")
  valid_604256 = validateParameter(valid_604256, JString, required = false,
                                 default = nil)
  if valid_604256 != nil:
    section.add "X-Amz-Algorithm", valid_604256
  var valid_604257 = header.getOrDefault("X-Amz-Signature")
  valid_604257 = validateParameter(valid_604257, JString, required = false,
                                 default = nil)
  if valid_604257 != nil:
    section.add "X-Amz-Signature", valid_604257
  var valid_604258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604258 = validateParameter(valid_604258, JString, required = false,
                                 default = nil)
  if valid_604258 != nil:
    section.add "X-Amz-SignedHeaders", valid_604258
  var valid_604259 = header.getOrDefault("X-Amz-Credential")
  valid_604259 = validateParameter(valid_604259, JString, required = false,
                                 default = nil)
  if valid_604259 != nil:
    section.add "X-Amz-Credential", valid_604259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604260: Call_GetDescribeOptionGroups_604243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604260.validator(path, query, header, formData, body)
  let scheme = call_604260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604260.url(scheme.get, call_604260.host, call_604260.base,
                         call_604260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604260, url, valid)

proc call*(call_604261: Call_GetDescribeOptionGroups_604243; MaxRecords: int = 0;
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
  var query_604262 = newJObject()
  add(query_604262, "MaxRecords", newJInt(MaxRecords))
  add(query_604262, "OptionGroupName", newJString(OptionGroupName))
  add(query_604262, "Action", newJString(Action))
  add(query_604262, "Marker", newJString(Marker))
  add(query_604262, "Version", newJString(Version))
  add(query_604262, "EngineName", newJString(EngineName))
  add(query_604262, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_604261.call(nil, query_604262, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_604243(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_604244, base: "/",
    url: url_GetDescribeOptionGroups_604245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_604306 = ref object of OpenApiRestCall_602450
proc url_PostDescribeOrderableDBInstanceOptions_604308(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_604307(path: JsonNode;
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
  var valid_604309 = query.getOrDefault("Action")
  valid_604309 = validateParameter(valid_604309, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604309 != nil:
    section.add "Action", valid_604309
  var valid_604310 = query.getOrDefault("Version")
  valid_604310 = validateParameter(valid_604310, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604310 != nil:
    section.add "Version", valid_604310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604311 = header.getOrDefault("X-Amz-Date")
  valid_604311 = validateParameter(valid_604311, JString, required = false,
                                 default = nil)
  if valid_604311 != nil:
    section.add "X-Amz-Date", valid_604311
  var valid_604312 = header.getOrDefault("X-Amz-Security-Token")
  valid_604312 = validateParameter(valid_604312, JString, required = false,
                                 default = nil)
  if valid_604312 != nil:
    section.add "X-Amz-Security-Token", valid_604312
  var valid_604313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604313 = validateParameter(valid_604313, JString, required = false,
                                 default = nil)
  if valid_604313 != nil:
    section.add "X-Amz-Content-Sha256", valid_604313
  var valid_604314 = header.getOrDefault("X-Amz-Algorithm")
  valid_604314 = validateParameter(valid_604314, JString, required = false,
                                 default = nil)
  if valid_604314 != nil:
    section.add "X-Amz-Algorithm", valid_604314
  var valid_604315 = header.getOrDefault("X-Amz-Signature")
  valid_604315 = validateParameter(valid_604315, JString, required = false,
                                 default = nil)
  if valid_604315 != nil:
    section.add "X-Amz-Signature", valid_604315
  var valid_604316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604316 = validateParameter(valid_604316, JString, required = false,
                                 default = nil)
  if valid_604316 != nil:
    section.add "X-Amz-SignedHeaders", valid_604316
  var valid_604317 = header.getOrDefault("X-Amz-Credential")
  valid_604317 = validateParameter(valid_604317, JString, required = false,
                                 default = nil)
  if valid_604317 != nil:
    section.add "X-Amz-Credential", valid_604317
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
  var valid_604318 = formData.getOrDefault("Engine")
  valid_604318 = validateParameter(valid_604318, JString, required = true,
                                 default = nil)
  if valid_604318 != nil:
    section.add "Engine", valid_604318
  var valid_604319 = formData.getOrDefault("Marker")
  valid_604319 = validateParameter(valid_604319, JString, required = false,
                                 default = nil)
  if valid_604319 != nil:
    section.add "Marker", valid_604319
  var valid_604320 = formData.getOrDefault("Vpc")
  valid_604320 = validateParameter(valid_604320, JBool, required = false, default = nil)
  if valid_604320 != nil:
    section.add "Vpc", valid_604320
  var valid_604321 = formData.getOrDefault("DBInstanceClass")
  valid_604321 = validateParameter(valid_604321, JString, required = false,
                                 default = nil)
  if valid_604321 != nil:
    section.add "DBInstanceClass", valid_604321
  var valid_604322 = formData.getOrDefault("LicenseModel")
  valid_604322 = validateParameter(valid_604322, JString, required = false,
                                 default = nil)
  if valid_604322 != nil:
    section.add "LicenseModel", valid_604322
  var valid_604323 = formData.getOrDefault("MaxRecords")
  valid_604323 = validateParameter(valid_604323, JInt, required = false, default = nil)
  if valid_604323 != nil:
    section.add "MaxRecords", valid_604323
  var valid_604324 = formData.getOrDefault("EngineVersion")
  valid_604324 = validateParameter(valid_604324, JString, required = false,
                                 default = nil)
  if valid_604324 != nil:
    section.add "EngineVersion", valid_604324
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604325: Call_PostDescribeOrderableDBInstanceOptions_604306;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604325.validator(path, query, header, formData, body)
  let scheme = call_604325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604325.url(scheme.get, call_604325.host, call_604325.base,
                         call_604325.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604325, url, valid)

proc call*(call_604326: Call_PostDescribeOrderableDBInstanceOptions_604306;
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
  var query_604327 = newJObject()
  var formData_604328 = newJObject()
  add(formData_604328, "Engine", newJString(Engine))
  add(formData_604328, "Marker", newJString(Marker))
  add(query_604327, "Action", newJString(Action))
  add(formData_604328, "Vpc", newJBool(Vpc))
  add(formData_604328, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604328, "LicenseModel", newJString(LicenseModel))
  add(formData_604328, "MaxRecords", newJInt(MaxRecords))
  add(formData_604328, "EngineVersion", newJString(EngineVersion))
  add(query_604327, "Version", newJString(Version))
  result = call_604326.call(nil, query_604327, nil, formData_604328, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_604306(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_604307, base: "/",
    url: url_PostDescribeOrderableDBInstanceOptions_604308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_604284 = ref object of OpenApiRestCall_602450
proc url_GetDescribeOrderableDBInstanceOptions_604286(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_604285(path: JsonNode;
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
  var valid_604287 = query.getOrDefault("Engine")
  valid_604287 = validateParameter(valid_604287, JString, required = true,
                                 default = nil)
  if valid_604287 != nil:
    section.add "Engine", valid_604287
  var valid_604288 = query.getOrDefault("MaxRecords")
  valid_604288 = validateParameter(valid_604288, JInt, required = false, default = nil)
  if valid_604288 != nil:
    section.add "MaxRecords", valid_604288
  var valid_604289 = query.getOrDefault("LicenseModel")
  valid_604289 = validateParameter(valid_604289, JString, required = false,
                                 default = nil)
  if valid_604289 != nil:
    section.add "LicenseModel", valid_604289
  var valid_604290 = query.getOrDefault("Vpc")
  valid_604290 = validateParameter(valid_604290, JBool, required = false, default = nil)
  if valid_604290 != nil:
    section.add "Vpc", valid_604290
  var valid_604291 = query.getOrDefault("DBInstanceClass")
  valid_604291 = validateParameter(valid_604291, JString, required = false,
                                 default = nil)
  if valid_604291 != nil:
    section.add "DBInstanceClass", valid_604291
  var valid_604292 = query.getOrDefault("Action")
  valid_604292 = validateParameter(valid_604292, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_604292 != nil:
    section.add "Action", valid_604292
  var valid_604293 = query.getOrDefault("Marker")
  valid_604293 = validateParameter(valid_604293, JString, required = false,
                                 default = nil)
  if valid_604293 != nil:
    section.add "Marker", valid_604293
  var valid_604294 = query.getOrDefault("EngineVersion")
  valid_604294 = validateParameter(valid_604294, JString, required = false,
                                 default = nil)
  if valid_604294 != nil:
    section.add "EngineVersion", valid_604294
  var valid_604295 = query.getOrDefault("Version")
  valid_604295 = validateParameter(valid_604295, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604295 != nil:
    section.add "Version", valid_604295
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604296 = header.getOrDefault("X-Amz-Date")
  valid_604296 = validateParameter(valid_604296, JString, required = false,
                                 default = nil)
  if valid_604296 != nil:
    section.add "X-Amz-Date", valid_604296
  var valid_604297 = header.getOrDefault("X-Amz-Security-Token")
  valid_604297 = validateParameter(valid_604297, JString, required = false,
                                 default = nil)
  if valid_604297 != nil:
    section.add "X-Amz-Security-Token", valid_604297
  var valid_604298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604298 = validateParameter(valid_604298, JString, required = false,
                                 default = nil)
  if valid_604298 != nil:
    section.add "X-Amz-Content-Sha256", valid_604298
  var valid_604299 = header.getOrDefault("X-Amz-Algorithm")
  valid_604299 = validateParameter(valid_604299, JString, required = false,
                                 default = nil)
  if valid_604299 != nil:
    section.add "X-Amz-Algorithm", valid_604299
  var valid_604300 = header.getOrDefault("X-Amz-Signature")
  valid_604300 = validateParameter(valid_604300, JString, required = false,
                                 default = nil)
  if valid_604300 != nil:
    section.add "X-Amz-Signature", valid_604300
  var valid_604301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604301 = validateParameter(valid_604301, JString, required = false,
                                 default = nil)
  if valid_604301 != nil:
    section.add "X-Amz-SignedHeaders", valid_604301
  var valid_604302 = header.getOrDefault("X-Amz-Credential")
  valid_604302 = validateParameter(valid_604302, JString, required = false,
                                 default = nil)
  if valid_604302 != nil:
    section.add "X-Amz-Credential", valid_604302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604303: Call_GetDescribeOrderableDBInstanceOptions_604284;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604303.validator(path, query, header, formData, body)
  let scheme = call_604303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604303.url(scheme.get, call_604303.host, call_604303.base,
                         call_604303.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604303, url, valid)

proc call*(call_604304: Call_GetDescribeOrderableDBInstanceOptions_604284;
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
  var query_604305 = newJObject()
  add(query_604305, "Engine", newJString(Engine))
  add(query_604305, "MaxRecords", newJInt(MaxRecords))
  add(query_604305, "LicenseModel", newJString(LicenseModel))
  add(query_604305, "Vpc", newJBool(Vpc))
  add(query_604305, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604305, "Action", newJString(Action))
  add(query_604305, "Marker", newJString(Marker))
  add(query_604305, "EngineVersion", newJString(EngineVersion))
  add(query_604305, "Version", newJString(Version))
  result = call_604304.call(nil, query_604305, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_604284(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_604285, base: "/",
    url: url_GetDescribeOrderableDBInstanceOptions_604286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_604353 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstances_604355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstances_604354(path: JsonNode;
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
  var valid_604356 = query.getOrDefault("Action")
  valid_604356 = validateParameter(valid_604356, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604356 != nil:
    section.add "Action", valid_604356
  var valid_604357 = query.getOrDefault("Version")
  valid_604357 = validateParameter(valid_604357, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604357 != nil:
    section.add "Version", valid_604357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604358 = header.getOrDefault("X-Amz-Date")
  valid_604358 = validateParameter(valid_604358, JString, required = false,
                                 default = nil)
  if valid_604358 != nil:
    section.add "X-Amz-Date", valid_604358
  var valid_604359 = header.getOrDefault("X-Amz-Security-Token")
  valid_604359 = validateParameter(valid_604359, JString, required = false,
                                 default = nil)
  if valid_604359 != nil:
    section.add "X-Amz-Security-Token", valid_604359
  var valid_604360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604360 = validateParameter(valid_604360, JString, required = false,
                                 default = nil)
  if valid_604360 != nil:
    section.add "X-Amz-Content-Sha256", valid_604360
  var valid_604361 = header.getOrDefault("X-Amz-Algorithm")
  valid_604361 = validateParameter(valid_604361, JString, required = false,
                                 default = nil)
  if valid_604361 != nil:
    section.add "X-Amz-Algorithm", valid_604361
  var valid_604362 = header.getOrDefault("X-Amz-Signature")
  valid_604362 = validateParameter(valid_604362, JString, required = false,
                                 default = nil)
  if valid_604362 != nil:
    section.add "X-Amz-Signature", valid_604362
  var valid_604363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604363 = validateParameter(valid_604363, JString, required = false,
                                 default = nil)
  if valid_604363 != nil:
    section.add "X-Amz-SignedHeaders", valid_604363
  var valid_604364 = header.getOrDefault("X-Amz-Credential")
  valid_604364 = validateParameter(valid_604364, JString, required = false,
                                 default = nil)
  if valid_604364 != nil:
    section.add "X-Amz-Credential", valid_604364
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
  var valid_604365 = formData.getOrDefault("OfferingType")
  valid_604365 = validateParameter(valid_604365, JString, required = false,
                                 default = nil)
  if valid_604365 != nil:
    section.add "OfferingType", valid_604365
  var valid_604366 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604366 = validateParameter(valid_604366, JString, required = false,
                                 default = nil)
  if valid_604366 != nil:
    section.add "ReservedDBInstanceId", valid_604366
  var valid_604367 = formData.getOrDefault("Marker")
  valid_604367 = validateParameter(valid_604367, JString, required = false,
                                 default = nil)
  if valid_604367 != nil:
    section.add "Marker", valid_604367
  var valid_604368 = formData.getOrDefault("MultiAZ")
  valid_604368 = validateParameter(valid_604368, JBool, required = false, default = nil)
  if valid_604368 != nil:
    section.add "MultiAZ", valid_604368
  var valid_604369 = formData.getOrDefault("Duration")
  valid_604369 = validateParameter(valid_604369, JString, required = false,
                                 default = nil)
  if valid_604369 != nil:
    section.add "Duration", valid_604369
  var valid_604370 = formData.getOrDefault("DBInstanceClass")
  valid_604370 = validateParameter(valid_604370, JString, required = false,
                                 default = nil)
  if valid_604370 != nil:
    section.add "DBInstanceClass", valid_604370
  var valid_604371 = formData.getOrDefault("ProductDescription")
  valid_604371 = validateParameter(valid_604371, JString, required = false,
                                 default = nil)
  if valid_604371 != nil:
    section.add "ProductDescription", valid_604371
  var valid_604372 = formData.getOrDefault("MaxRecords")
  valid_604372 = validateParameter(valid_604372, JInt, required = false, default = nil)
  if valid_604372 != nil:
    section.add "MaxRecords", valid_604372
  var valid_604373 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604373 = validateParameter(valid_604373, JString, required = false,
                                 default = nil)
  if valid_604373 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604373
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604374: Call_PostDescribeReservedDBInstances_604353;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604374.validator(path, query, header, formData, body)
  let scheme = call_604374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604374.url(scheme.get, call_604374.host, call_604374.base,
                         call_604374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604374, url, valid)

proc call*(call_604375: Call_PostDescribeReservedDBInstances_604353;
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
  var query_604376 = newJObject()
  var formData_604377 = newJObject()
  add(formData_604377, "OfferingType", newJString(OfferingType))
  add(formData_604377, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604377, "Marker", newJString(Marker))
  add(formData_604377, "MultiAZ", newJBool(MultiAZ))
  add(query_604376, "Action", newJString(Action))
  add(formData_604377, "Duration", newJString(Duration))
  add(formData_604377, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604377, "ProductDescription", newJString(ProductDescription))
  add(formData_604377, "MaxRecords", newJInt(MaxRecords))
  add(formData_604377, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604376, "Version", newJString(Version))
  result = call_604375.call(nil, query_604376, nil, formData_604377, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_604353(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_604354, base: "/",
    url: url_PostDescribeReservedDBInstances_604355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_604329 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstances_604331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstances_604330(path: JsonNode;
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
  var valid_604332 = query.getOrDefault("ProductDescription")
  valid_604332 = validateParameter(valid_604332, JString, required = false,
                                 default = nil)
  if valid_604332 != nil:
    section.add "ProductDescription", valid_604332
  var valid_604333 = query.getOrDefault("MaxRecords")
  valid_604333 = validateParameter(valid_604333, JInt, required = false, default = nil)
  if valid_604333 != nil:
    section.add "MaxRecords", valid_604333
  var valid_604334 = query.getOrDefault("OfferingType")
  valid_604334 = validateParameter(valid_604334, JString, required = false,
                                 default = nil)
  if valid_604334 != nil:
    section.add "OfferingType", valid_604334
  var valid_604335 = query.getOrDefault("MultiAZ")
  valid_604335 = validateParameter(valid_604335, JBool, required = false, default = nil)
  if valid_604335 != nil:
    section.add "MultiAZ", valid_604335
  var valid_604336 = query.getOrDefault("ReservedDBInstanceId")
  valid_604336 = validateParameter(valid_604336, JString, required = false,
                                 default = nil)
  if valid_604336 != nil:
    section.add "ReservedDBInstanceId", valid_604336
  var valid_604337 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604337 = validateParameter(valid_604337, JString, required = false,
                                 default = nil)
  if valid_604337 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604337
  var valid_604338 = query.getOrDefault("DBInstanceClass")
  valid_604338 = validateParameter(valid_604338, JString, required = false,
                                 default = nil)
  if valid_604338 != nil:
    section.add "DBInstanceClass", valid_604338
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604339 = query.getOrDefault("Action")
  valid_604339 = validateParameter(valid_604339, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_604339 != nil:
    section.add "Action", valid_604339
  var valid_604340 = query.getOrDefault("Marker")
  valid_604340 = validateParameter(valid_604340, JString, required = false,
                                 default = nil)
  if valid_604340 != nil:
    section.add "Marker", valid_604340
  var valid_604341 = query.getOrDefault("Duration")
  valid_604341 = validateParameter(valid_604341, JString, required = false,
                                 default = nil)
  if valid_604341 != nil:
    section.add "Duration", valid_604341
  var valid_604342 = query.getOrDefault("Version")
  valid_604342 = validateParameter(valid_604342, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604342 != nil:
    section.add "Version", valid_604342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604343 = header.getOrDefault("X-Amz-Date")
  valid_604343 = validateParameter(valid_604343, JString, required = false,
                                 default = nil)
  if valid_604343 != nil:
    section.add "X-Amz-Date", valid_604343
  var valid_604344 = header.getOrDefault("X-Amz-Security-Token")
  valid_604344 = validateParameter(valid_604344, JString, required = false,
                                 default = nil)
  if valid_604344 != nil:
    section.add "X-Amz-Security-Token", valid_604344
  var valid_604345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604345 = validateParameter(valid_604345, JString, required = false,
                                 default = nil)
  if valid_604345 != nil:
    section.add "X-Amz-Content-Sha256", valid_604345
  var valid_604346 = header.getOrDefault("X-Amz-Algorithm")
  valid_604346 = validateParameter(valid_604346, JString, required = false,
                                 default = nil)
  if valid_604346 != nil:
    section.add "X-Amz-Algorithm", valid_604346
  var valid_604347 = header.getOrDefault("X-Amz-Signature")
  valid_604347 = validateParameter(valid_604347, JString, required = false,
                                 default = nil)
  if valid_604347 != nil:
    section.add "X-Amz-Signature", valid_604347
  var valid_604348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604348 = validateParameter(valid_604348, JString, required = false,
                                 default = nil)
  if valid_604348 != nil:
    section.add "X-Amz-SignedHeaders", valid_604348
  var valid_604349 = header.getOrDefault("X-Amz-Credential")
  valid_604349 = validateParameter(valid_604349, JString, required = false,
                                 default = nil)
  if valid_604349 != nil:
    section.add "X-Amz-Credential", valid_604349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604350: Call_GetDescribeReservedDBInstances_604329; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604350.validator(path, query, header, formData, body)
  let scheme = call_604350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604350.url(scheme.get, call_604350.host, call_604350.base,
                         call_604350.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604350, url, valid)

proc call*(call_604351: Call_GetDescribeReservedDBInstances_604329;
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
  var query_604352 = newJObject()
  add(query_604352, "ProductDescription", newJString(ProductDescription))
  add(query_604352, "MaxRecords", newJInt(MaxRecords))
  add(query_604352, "OfferingType", newJString(OfferingType))
  add(query_604352, "MultiAZ", newJBool(MultiAZ))
  add(query_604352, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604352, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604352, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604352, "Action", newJString(Action))
  add(query_604352, "Marker", newJString(Marker))
  add(query_604352, "Duration", newJString(Duration))
  add(query_604352, "Version", newJString(Version))
  result = call_604351.call(nil, query_604352, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_604329(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_604330, base: "/",
    url: url_GetDescribeReservedDBInstances_604331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_604401 = ref object of OpenApiRestCall_602450
proc url_PostDescribeReservedDBInstancesOfferings_604403(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_604402(path: JsonNode;
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
  var valid_604404 = query.getOrDefault("Action")
  valid_604404 = validateParameter(valid_604404, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604404 != nil:
    section.add "Action", valid_604404
  var valid_604405 = query.getOrDefault("Version")
  valid_604405 = validateParameter(valid_604405, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604405 != nil:
    section.add "Version", valid_604405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604406 = header.getOrDefault("X-Amz-Date")
  valid_604406 = validateParameter(valid_604406, JString, required = false,
                                 default = nil)
  if valid_604406 != nil:
    section.add "X-Amz-Date", valid_604406
  var valid_604407 = header.getOrDefault("X-Amz-Security-Token")
  valid_604407 = validateParameter(valid_604407, JString, required = false,
                                 default = nil)
  if valid_604407 != nil:
    section.add "X-Amz-Security-Token", valid_604407
  var valid_604408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604408 = validateParameter(valid_604408, JString, required = false,
                                 default = nil)
  if valid_604408 != nil:
    section.add "X-Amz-Content-Sha256", valid_604408
  var valid_604409 = header.getOrDefault("X-Amz-Algorithm")
  valid_604409 = validateParameter(valid_604409, JString, required = false,
                                 default = nil)
  if valid_604409 != nil:
    section.add "X-Amz-Algorithm", valid_604409
  var valid_604410 = header.getOrDefault("X-Amz-Signature")
  valid_604410 = validateParameter(valid_604410, JString, required = false,
                                 default = nil)
  if valid_604410 != nil:
    section.add "X-Amz-Signature", valid_604410
  var valid_604411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604411 = validateParameter(valid_604411, JString, required = false,
                                 default = nil)
  if valid_604411 != nil:
    section.add "X-Amz-SignedHeaders", valid_604411
  var valid_604412 = header.getOrDefault("X-Amz-Credential")
  valid_604412 = validateParameter(valid_604412, JString, required = false,
                                 default = nil)
  if valid_604412 != nil:
    section.add "X-Amz-Credential", valid_604412
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
  var valid_604413 = formData.getOrDefault("OfferingType")
  valid_604413 = validateParameter(valid_604413, JString, required = false,
                                 default = nil)
  if valid_604413 != nil:
    section.add "OfferingType", valid_604413
  var valid_604414 = formData.getOrDefault("Marker")
  valid_604414 = validateParameter(valid_604414, JString, required = false,
                                 default = nil)
  if valid_604414 != nil:
    section.add "Marker", valid_604414
  var valid_604415 = formData.getOrDefault("MultiAZ")
  valid_604415 = validateParameter(valid_604415, JBool, required = false, default = nil)
  if valid_604415 != nil:
    section.add "MultiAZ", valid_604415
  var valid_604416 = formData.getOrDefault("Duration")
  valid_604416 = validateParameter(valid_604416, JString, required = false,
                                 default = nil)
  if valid_604416 != nil:
    section.add "Duration", valid_604416
  var valid_604417 = formData.getOrDefault("DBInstanceClass")
  valid_604417 = validateParameter(valid_604417, JString, required = false,
                                 default = nil)
  if valid_604417 != nil:
    section.add "DBInstanceClass", valid_604417
  var valid_604418 = formData.getOrDefault("ProductDescription")
  valid_604418 = validateParameter(valid_604418, JString, required = false,
                                 default = nil)
  if valid_604418 != nil:
    section.add "ProductDescription", valid_604418
  var valid_604419 = formData.getOrDefault("MaxRecords")
  valid_604419 = validateParameter(valid_604419, JInt, required = false, default = nil)
  if valid_604419 != nil:
    section.add "MaxRecords", valid_604419
  var valid_604420 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604420 = validateParameter(valid_604420, JString, required = false,
                                 default = nil)
  if valid_604420 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604420
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604421: Call_PostDescribeReservedDBInstancesOfferings_604401;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604421.validator(path, query, header, formData, body)
  let scheme = call_604421.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604421.url(scheme.get, call_604421.host, call_604421.base,
                         call_604421.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604421, url, valid)

proc call*(call_604422: Call_PostDescribeReservedDBInstancesOfferings_604401;
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
  var query_604423 = newJObject()
  var formData_604424 = newJObject()
  add(formData_604424, "OfferingType", newJString(OfferingType))
  add(formData_604424, "Marker", newJString(Marker))
  add(formData_604424, "MultiAZ", newJBool(MultiAZ))
  add(query_604423, "Action", newJString(Action))
  add(formData_604424, "Duration", newJString(Duration))
  add(formData_604424, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604424, "ProductDescription", newJString(ProductDescription))
  add(formData_604424, "MaxRecords", newJInt(MaxRecords))
  add(formData_604424, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604423, "Version", newJString(Version))
  result = call_604422.call(nil, query_604423, nil, formData_604424, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_604401(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_604402,
    base: "/", url: url_PostDescribeReservedDBInstancesOfferings_604403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_604378 = ref object of OpenApiRestCall_602450
proc url_GetDescribeReservedDBInstancesOfferings_604380(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_604379(path: JsonNode;
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
  var valid_604381 = query.getOrDefault("ProductDescription")
  valid_604381 = validateParameter(valid_604381, JString, required = false,
                                 default = nil)
  if valid_604381 != nil:
    section.add "ProductDescription", valid_604381
  var valid_604382 = query.getOrDefault("MaxRecords")
  valid_604382 = validateParameter(valid_604382, JInt, required = false, default = nil)
  if valid_604382 != nil:
    section.add "MaxRecords", valid_604382
  var valid_604383 = query.getOrDefault("OfferingType")
  valid_604383 = validateParameter(valid_604383, JString, required = false,
                                 default = nil)
  if valid_604383 != nil:
    section.add "OfferingType", valid_604383
  var valid_604384 = query.getOrDefault("MultiAZ")
  valid_604384 = validateParameter(valid_604384, JBool, required = false, default = nil)
  if valid_604384 != nil:
    section.add "MultiAZ", valid_604384
  var valid_604385 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604385 = validateParameter(valid_604385, JString, required = false,
                                 default = nil)
  if valid_604385 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604385
  var valid_604386 = query.getOrDefault("DBInstanceClass")
  valid_604386 = validateParameter(valid_604386, JString, required = false,
                                 default = nil)
  if valid_604386 != nil:
    section.add "DBInstanceClass", valid_604386
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604387 = query.getOrDefault("Action")
  valid_604387 = validateParameter(valid_604387, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_604387 != nil:
    section.add "Action", valid_604387
  var valid_604388 = query.getOrDefault("Marker")
  valid_604388 = validateParameter(valid_604388, JString, required = false,
                                 default = nil)
  if valid_604388 != nil:
    section.add "Marker", valid_604388
  var valid_604389 = query.getOrDefault("Duration")
  valid_604389 = validateParameter(valid_604389, JString, required = false,
                                 default = nil)
  if valid_604389 != nil:
    section.add "Duration", valid_604389
  var valid_604390 = query.getOrDefault("Version")
  valid_604390 = validateParameter(valid_604390, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604390 != nil:
    section.add "Version", valid_604390
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604391 = header.getOrDefault("X-Amz-Date")
  valid_604391 = validateParameter(valid_604391, JString, required = false,
                                 default = nil)
  if valid_604391 != nil:
    section.add "X-Amz-Date", valid_604391
  var valid_604392 = header.getOrDefault("X-Amz-Security-Token")
  valid_604392 = validateParameter(valid_604392, JString, required = false,
                                 default = nil)
  if valid_604392 != nil:
    section.add "X-Amz-Security-Token", valid_604392
  var valid_604393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604393 = validateParameter(valid_604393, JString, required = false,
                                 default = nil)
  if valid_604393 != nil:
    section.add "X-Amz-Content-Sha256", valid_604393
  var valid_604394 = header.getOrDefault("X-Amz-Algorithm")
  valid_604394 = validateParameter(valid_604394, JString, required = false,
                                 default = nil)
  if valid_604394 != nil:
    section.add "X-Amz-Algorithm", valid_604394
  var valid_604395 = header.getOrDefault("X-Amz-Signature")
  valid_604395 = validateParameter(valid_604395, JString, required = false,
                                 default = nil)
  if valid_604395 != nil:
    section.add "X-Amz-Signature", valid_604395
  var valid_604396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604396 = validateParameter(valid_604396, JString, required = false,
                                 default = nil)
  if valid_604396 != nil:
    section.add "X-Amz-SignedHeaders", valid_604396
  var valid_604397 = header.getOrDefault("X-Amz-Credential")
  valid_604397 = validateParameter(valid_604397, JString, required = false,
                                 default = nil)
  if valid_604397 != nil:
    section.add "X-Amz-Credential", valid_604397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604398: Call_GetDescribeReservedDBInstancesOfferings_604378;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604398.validator(path, query, header, formData, body)
  let scheme = call_604398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604398.url(scheme.get, call_604398.host, call_604398.base,
                         call_604398.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604398, url, valid)

proc call*(call_604399: Call_GetDescribeReservedDBInstancesOfferings_604378;
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
  var query_604400 = newJObject()
  add(query_604400, "ProductDescription", newJString(ProductDescription))
  add(query_604400, "MaxRecords", newJInt(MaxRecords))
  add(query_604400, "OfferingType", newJString(OfferingType))
  add(query_604400, "MultiAZ", newJBool(MultiAZ))
  add(query_604400, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604400, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604400, "Action", newJString(Action))
  add(query_604400, "Marker", newJString(Marker))
  add(query_604400, "Duration", newJString(Duration))
  add(query_604400, "Version", newJString(Version))
  result = call_604399.call(nil, query_604400, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_604378(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_604379, base: "/",
    url: url_GetDescribeReservedDBInstancesOfferings_604380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_604441 = ref object of OpenApiRestCall_602450
proc url_PostListTagsForResource_604443(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostListTagsForResource_604442(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604444 = query.getOrDefault("Action")
  valid_604444 = validateParameter(valid_604444, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604444 != nil:
    section.add "Action", valid_604444
  var valid_604445 = query.getOrDefault("Version")
  valid_604445 = validateParameter(valid_604445, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604445 != nil:
    section.add "Version", valid_604445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604446 = header.getOrDefault("X-Amz-Date")
  valid_604446 = validateParameter(valid_604446, JString, required = false,
                                 default = nil)
  if valid_604446 != nil:
    section.add "X-Amz-Date", valid_604446
  var valid_604447 = header.getOrDefault("X-Amz-Security-Token")
  valid_604447 = validateParameter(valid_604447, JString, required = false,
                                 default = nil)
  if valid_604447 != nil:
    section.add "X-Amz-Security-Token", valid_604447
  var valid_604448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604448 = validateParameter(valid_604448, JString, required = false,
                                 default = nil)
  if valid_604448 != nil:
    section.add "X-Amz-Content-Sha256", valid_604448
  var valid_604449 = header.getOrDefault("X-Amz-Algorithm")
  valid_604449 = validateParameter(valid_604449, JString, required = false,
                                 default = nil)
  if valid_604449 != nil:
    section.add "X-Amz-Algorithm", valid_604449
  var valid_604450 = header.getOrDefault("X-Amz-Signature")
  valid_604450 = validateParameter(valid_604450, JString, required = false,
                                 default = nil)
  if valid_604450 != nil:
    section.add "X-Amz-Signature", valid_604450
  var valid_604451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604451 = validateParameter(valid_604451, JString, required = false,
                                 default = nil)
  if valid_604451 != nil:
    section.add "X-Amz-SignedHeaders", valid_604451
  var valid_604452 = header.getOrDefault("X-Amz-Credential")
  valid_604452 = validateParameter(valid_604452, JString, required = false,
                                 default = nil)
  if valid_604452 != nil:
    section.add "X-Amz-Credential", valid_604452
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_604453 = formData.getOrDefault("ResourceName")
  valid_604453 = validateParameter(valid_604453, JString, required = true,
                                 default = nil)
  if valid_604453 != nil:
    section.add "ResourceName", valid_604453
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604454: Call_PostListTagsForResource_604441; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604454.validator(path, query, header, formData, body)
  let scheme = call_604454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604454.url(scheme.get, call_604454.host, call_604454.base,
                         call_604454.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604454, url, valid)

proc call*(call_604455: Call_PostListTagsForResource_604441; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604456 = newJObject()
  var formData_604457 = newJObject()
  add(query_604456, "Action", newJString(Action))
  add(formData_604457, "ResourceName", newJString(ResourceName))
  add(query_604456, "Version", newJString(Version))
  result = call_604455.call(nil, query_604456, nil, formData_604457, nil)

var postListTagsForResource* = Call_PostListTagsForResource_604441(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_604442, base: "/",
    url: url_PostListTagsForResource_604443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_604425 = ref object of OpenApiRestCall_602450
proc url_GetListTagsForResource_604427(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetListTagsForResource_604426(path: JsonNode; query: JsonNode;
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
  var valid_604428 = query.getOrDefault("ResourceName")
  valid_604428 = validateParameter(valid_604428, JString, required = true,
                                 default = nil)
  if valid_604428 != nil:
    section.add "ResourceName", valid_604428
  var valid_604429 = query.getOrDefault("Action")
  valid_604429 = validateParameter(valid_604429, JString, required = true,
                                 default = newJString("ListTagsForResource"))
  if valid_604429 != nil:
    section.add "Action", valid_604429
  var valid_604430 = query.getOrDefault("Version")
  valid_604430 = validateParameter(valid_604430, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604430 != nil:
    section.add "Version", valid_604430
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604431 = header.getOrDefault("X-Amz-Date")
  valid_604431 = validateParameter(valid_604431, JString, required = false,
                                 default = nil)
  if valid_604431 != nil:
    section.add "X-Amz-Date", valid_604431
  var valid_604432 = header.getOrDefault("X-Amz-Security-Token")
  valid_604432 = validateParameter(valid_604432, JString, required = false,
                                 default = nil)
  if valid_604432 != nil:
    section.add "X-Amz-Security-Token", valid_604432
  var valid_604433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604433 = validateParameter(valid_604433, JString, required = false,
                                 default = nil)
  if valid_604433 != nil:
    section.add "X-Amz-Content-Sha256", valid_604433
  var valid_604434 = header.getOrDefault("X-Amz-Algorithm")
  valid_604434 = validateParameter(valid_604434, JString, required = false,
                                 default = nil)
  if valid_604434 != nil:
    section.add "X-Amz-Algorithm", valid_604434
  var valid_604435 = header.getOrDefault("X-Amz-Signature")
  valid_604435 = validateParameter(valid_604435, JString, required = false,
                                 default = nil)
  if valid_604435 != nil:
    section.add "X-Amz-Signature", valid_604435
  var valid_604436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604436 = validateParameter(valid_604436, JString, required = false,
                                 default = nil)
  if valid_604436 != nil:
    section.add "X-Amz-SignedHeaders", valid_604436
  var valid_604437 = header.getOrDefault("X-Amz-Credential")
  valid_604437 = validateParameter(valid_604437, JString, required = false,
                                 default = nil)
  if valid_604437 != nil:
    section.add "X-Amz-Credential", valid_604437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604438: Call_GetListTagsForResource_604425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604438.validator(path, query, header, formData, body)
  let scheme = call_604438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604438.url(scheme.get, call_604438.host, call_604438.base,
                         call_604438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604438, url, valid)

proc call*(call_604439: Call_GetListTagsForResource_604425; ResourceName: string;
          Action: string = "ListTagsForResource"; Version: string = "2013-01-10"): Recallable =
  ## getListTagsForResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604440 = newJObject()
  add(query_604440, "ResourceName", newJString(ResourceName))
  add(query_604440, "Action", newJString(Action))
  add(query_604440, "Version", newJString(Version))
  result = call_604439.call(nil, query_604440, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_604425(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_604426, base: "/",
    url: url_GetListTagsForResource_604427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_604491 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBInstance_604493(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBInstance_604492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604494 = query.getOrDefault("Action")
  valid_604494 = validateParameter(valid_604494, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604494 != nil:
    section.add "Action", valid_604494
  var valid_604495 = query.getOrDefault("Version")
  valid_604495 = validateParameter(valid_604495, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604495 != nil:
    section.add "Version", valid_604495
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604496 = header.getOrDefault("X-Amz-Date")
  valid_604496 = validateParameter(valid_604496, JString, required = false,
                                 default = nil)
  if valid_604496 != nil:
    section.add "X-Amz-Date", valid_604496
  var valid_604497 = header.getOrDefault("X-Amz-Security-Token")
  valid_604497 = validateParameter(valid_604497, JString, required = false,
                                 default = nil)
  if valid_604497 != nil:
    section.add "X-Amz-Security-Token", valid_604497
  var valid_604498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604498 = validateParameter(valid_604498, JString, required = false,
                                 default = nil)
  if valid_604498 != nil:
    section.add "X-Amz-Content-Sha256", valid_604498
  var valid_604499 = header.getOrDefault("X-Amz-Algorithm")
  valid_604499 = validateParameter(valid_604499, JString, required = false,
                                 default = nil)
  if valid_604499 != nil:
    section.add "X-Amz-Algorithm", valid_604499
  var valid_604500 = header.getOrDefault("X-Amz-Signature")
  valid_604500 = validateParameter(valid_604500, JString, required = false,
                                 default = nil)
  if valid_604500 != nil:
    section.add "X-Amz-Signature", valid_604500
  var valid_604501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604501 = validateParameter(valid_604501, JString, required = false,
                                 default = nil)
  if valid_604501 != nil:
    section.add "X-Amz-SignedHeaders", valid_604501
  var valid_604502 = header.getOrDefault("X-Amz-Credential")
  valid_604502 = validateParameter(valid_604502, JString, required = false,
                                 default = nil)
  if valid_604502 != nil:
    section.add "X-Amz-Credential", valid_604502
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
  var valid_604503 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_604503 = validateParameter(valid_604503, JString, required = false,
                                 default = nil)
  if valid_604503 != nil:
    section.add "PreferredMaintenanceWindow", valid_604503
  var valid_604504 = formData.getOrDefault("DBSecurityGroups")
  valid_604504 = validateParameter(valid_604504, JArray, required = false,
                                 default = nil)
  if valid_604504 != nil:
    section.add "DBSecurityGroups", valid_604504
  var valid_604505 = formData.getOrDefault("ApplyImmediately")
  valid_604505 = validateParameter(valid_604505, JBool, required = false, default = nil)
  if valid_604505 != nil:
    section.add "ApplyImmediately", valid_604505
  var valid_604506 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_604506 = validateParameter(valid_604506, JArray, required = false,
                                 default = nil)
  if valid_604506 != nil:
    section.add "VpcSecurityGroupIds", valid_604506
  var valid_604507 = formData.getOrDefault("Iops")
  valid_604507 = validateParameter(valid_604507, JInt, required = false, default = nil)
  if valid_604507 != nil:
    section.add "Iops", valid_604507
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604508 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604508 = validateParameter(valid_604508, JString, required = true,
                                 default = nil)
  if valid_604508 != nil:
    section.add "DBInstanceIdentifier", valid_604508
  var valid_604509 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604509 = validateParameter(valid_604509, JInt, required = false, default = nil)
  if valid_604509 != nil:
    section.add "BackupRetentionPeriod", valid_604509
  var valid_604510 = formData.getOrDefault("DBParameterGroupName")
  valid_604510 = validateParameter(valid_604510, JString, required = false,
                                 default = nil)
  if valid_604510 != nil:
    section.add "DBParameterGroupName", valid_604510
  var valid_604511 = formData.getOrDefault("OptionGroupName")
  valid_604511 = validateParameter(valid_604511, JString, required = false,
                                 default = nil)
  if valid_604511 != nil:
    section.add "OptionGroupName", valid_604511
  var valid_604512 = formData.getOrDefault("MasterUserPassword")
  valid_604512 = validateParameter(valid_604512, JString, required = false,
                                 default = nil)
  if valid_604512 != nil:
    section.add "MasterUserPassword", valid_604512
  var valid_604513 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_604513 = validateParameter(valid_604513, JString, required = false,
                                 default = nil)
  if valid_604513 != nil:
    section.add "NewDBInstanceIdentifier", valid_604513
  var valid_604514 = formData.getOrDefault("MultiAZ")
  valid_604514 = validateParameter(valid_604514, JBool, required = false, default = nil)
  if valid_604514 != nil:
    section.add "MultiAZ", valid_604514
  var valid_604515 = formData.getOrDefault("AllocatedStorage")
  valid_604515 = validateParameter(valid_604515, JInt, required = false, default = nil)
  if valid_604515 != nil:
    section.add "AllocatedStorage", valid_604515
  var valid_604516 = formData.getOrDefault("DBInstanceClass")
  valid_604516 = validateParameter(valid_604516, JString, required = false,
                                 default = nil)
  if valid_604516 != nil:
    section.add "DBInstanceClass", valid_604516
  var valid_604517 = formData.getOrDefault("PreferredBackupWindow")
  valid_604517 = validateParameter(valid_604517, JString, required = false,
                                 default = nil)
  if valid_604517 != nil:
    section.add "PreferredBackupWindow", valid_604517
  var valid_604518 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604518 = validateParameter(valid_604518, JBool, required = false, default = nil)
  if valid_604518 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604518
  var valid_604519 = formData.getOrDefault("EngineVersion")
  valid_604519 = validateParameter(valid_604519, JString, required = false,
                                 default = nil)
  if valid_604519 != nil:
    section.add "EngineVersion", valid_604519
  var valid_604520 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_604520 = validateParameter(valid_604520, JBool, required = false, default = nil)
  if valid_604520 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604520
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604521: Call_PostModifyDBInstance_604491; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604521.validator(path, query, header, formData, body)
  let scheme = call_604521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604521.url(scheme.get, call_604521.host, call_604521.base,
                         call_604521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604521, url, valid)

proc call*(call_604522: Call_PostModifyDBInstance_604491;
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
  var query_604523 = newJObject()
  var formData_604524 = newJObject()
  add(formData_604524, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_604524.add "DBSecurityGroups", DBSecurityGroups
  add(formData_604524, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_604524.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_604524, "Iops", newJInt(Iops))
  add(formData_604524, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604524, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_604524, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_604524, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604524, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_604524, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_604524, "MultiAZ", newJBool(MultiAZ))
  add(query_604523, "Action", newJString(Action))
  add(formData_604524, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_604524, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604524, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(formData_604524, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_604524, "EngineVersion", newJString(EngineVersion))
  add(query_604523, "Version", newJString(Version))
  add(formData_604524, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_604522.call(nil, query_604523, nil, formData_604524, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_604491(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_604492, base: "/",
    url: url_PostModifyDBInstance_604493, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_604458 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBInstance_604460(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBInstance_604459(path: JsonNode; query: JsonNode;
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
  var valid_604461 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_604461 = validateParameter(valid_604461, JString, required = false,
                                 default = nil)
  if valid_604461 != nil:
    section.add "PreferredMaintenanceWindow", valid_604461
  var valid_604462 = query.getOrDefault("AllocatedStorage")
  valid_604462 = validateParameter(valid_604462, JInt, required = false, default = nil)
  if valid_604462 != nil:
    section.add "AllocatedStorage", valid_604462
  var valid_604463 = query.getOrDefault("OptionGroupName")
  valid_604463 = validateParameter(valid_604463, JString, required = false,
                                 default = nil)
  if valid_604463 != nil:
    section.add "OptionGroupName", valid_604463
  var valid_604464 = query.getOrDefault("DBSecurityGroups")
  valid_604464 = validateParameter(valid_604464, JArray, required = false,
                                 default = nil)
  if valid_604464 != nil:
    section.add "DBSecurityGroups", valid_604464
  var valid_604465 = query.getOrDefault("MasterUserPassword")
  valid_604465 = validateParameter(valid_604465, JString, required = false,
                                 default = nil)
  if valid_604465 != nil:
    section.add "MasterUserPassword", valid_604465
  var valid_604466 = query.getOrDefault("Iops")
  valid_604466 = validateParameter(valid_604466, JInt, required = false, default = nil)
  if valid_604466 != nil:
    section.add "Iops", valid_604466
  var valid_604467 = query.getOrDefault("VpcSecurityGroupIds")
  valid_604467 = validateParameter(valid_604467, JArray, required = false,
                                 default = nil)
  if valid_604467 != nil:
    section.add "VpcSecurityGroupIds", valid_604467
  var valid_604468 = query.getOrDefault("MultiAZ")
  valid_604468 = validateParameter(valid_604468, JBool, required = false, default = nil)
  if valid_604468 != nil:
    section.add "MultiAZ", valid_604468
  var valid_604469 = query.getOrDefault("BackupRetentionPeriod")
  valid_604469 = validateParameter(valid_604469, JInt, required = false, default = nil)
  if valid_604469 != nil:
    section.add "BackupRetentionPeriod", valid_604469
  var valid_604470 = query.getOrDefault("DBParameterGroupName")
  valid_604470 = validateParameter(valid_604470, JString, required = false,
                                 default = nil)
  if valid_604470 != nil:
    section.add "DBParameterGroupName", valid_604470
  var valid_604471 = query.getOrDefault("DBInstanceClass")
  valid_604471 = validateParameter(valid_604471, JString, required = false,
                                 default = nil)
  if valid_604471 != nil:
    section.add "DBInstanceClass", valid_604471
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604472 = query.getOrDefault("Action")
  valid_604472 = validateParameter(valid_604472, JString, required = true,
                                 default = newJString("ModifyDBInstance"))
  if valid_604472 != nil:
    section.add "Action", valid_604472
  var valid_604473 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_604473 = validateParameter(valid_604473, JBool, required = false, default = nil)
  if valid_604473 != nil:
    section.add "AllowMajorVersionUpgrade", valid_604473
  var valid_604474 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_604474 = validateParameter(valid_604474, JString, required = false,
                                 default = nil)
  if valid_604474 != nil:
    section.add "NewDBInstanceIdentifier", valid_604474
  var valid_604475 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604475 = validateParameter(valid_604475, JBool, required = false, default = nil)
  if valid_604475 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604475
  var valid_604476 = query.getOrDefault("EngineVersion")
  valid_604476 = validateParameter(valid_604476, JString, required = false,
                                 default = nil)
  if valid_604476 != nil:
    section.add "EngineVersion", valid_604476
  var valid_604477 = query.getOrDefault("PreferredBackupWindow")
  valid_604477 = validateParameter(valid_604477, JString, required = false,
                                 default = nil)
  if valid_604477 != nil:
    section.add "PreferredBackupWindow", valid_604477
  var valid_604478 = query.getOrDefault("Version")
  valid_604478 = validateParameter(valid_604478, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604478 != nil:
    section.add "Version", valid_604478
  var valid_604479 = query.getOrDefault("DBInstanceIdentifier")
  valid_604479 = validateParameter(valid_604479, JString, required = true,
                                 default = nil)
  if valid_604479 != nil:
    section.add "DBInstanceIdentifier", valid_604479
  var valid_604480 = query.getOrDefault("ApplyImmediately")
  valid_604480 = validateParameter(valid_604480, JBool, required = false, default = nil)
  if valid_604480 != nil:
    section.add "ApplyImmediately", valid_604480
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604481 = header.getOrDefault("X-Amz-Date")
  valid_604481 = validateParameter(valid_604481, JString, required = false,
                                 default = nil)
  if valid_604481 != nil:
    section.add "X-Amz-Date", valid_604481
  var valid_604482 = header.getOrDefault("X-Amz-Security-Token")
  valid_604482 = validateParameter(valid_604482, JString, required = false,
                                 default = nil)
  if valid_604482 != nil:
    section.add "X-Amz-Security-Token", valid_604482
  var valid_604483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604483 = validateParameter(valid_604483, JString, required = false,
                                 default = nil)
  if valid_604483 != nil:
    section.add "X-Amz-Content-Sha256", valid_604483
  var valid_604484 = header.getOrDefault("X-Amz-Algorithm")
  valid_604484 = validateParameter(valid_604484, JString, required = false,
                                 default = nil)
  if valid_604484 != nil:
    section.add "X-Amz-Algorithm", valid_604484
  var valid_604485 = header.getOrDefault("X-Amz-Signature")
  valid_604485 = validateParameter(valid_604485, JString, required = false,
                                 default = nil)
  if valid_604485 != nil:
    section.add "X-Amz-Signature", valid_604485
  var valid_604486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604486 = validateParameter(valid_604486, JString, required = false,
                                 default = nil)
  if valid_604486 != nil:
    section.add "X-Amz-SignedHeaders", valid_604486
  var valid_604487 = header.getOrDefault("X-Amz-Credential")
  valid_604487 = validateParameter(valid_604487, JString, required = false,
                                 default = nil)
  if valid_604487 != nil:
    section.add "X-Amz-Credential", valid_604487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604488: Call_GetModifyDBInstance_604458; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604488.validator(path, query, header, formData, body)
  let scheme = call_604488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604488.url(scheme.get, call_604488.host, call_604488.base,
                         call_604488.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604488, url, valid)

proc call*(call_604489: Call_GetModifyDBInstance_604458;
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
  var query_604490 = newJObject()
  add(query_604490, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_604490, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_604490, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_604490.add "DBSecurityGroups", DBSecurityGroups
  add(query_604490, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_604490, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_604490.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_604490, "MultiAZ", newJBool(MultiAZ))
  add(query_604490, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604490, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_604490, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604490, "Action", newJString(Action))
  add(query_604490, "AllowMajorVersionUpgrade", newJBool(AllowMajorVersionUpgrade))
  add(query_604490, "NewDBInstanceIdentifier", newJString(NewDBInstanceIdentifier))
  add(query_604490, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604490, "EngineVersion", newJString(EngineVersion))
  add(query_604490, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604490, "Version", newJString(Version))
  add(query_604490, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604490, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_604489.call(nil, query_604490, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_604458(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_604459, base: "/",
    url: url_GetModifyDBInstance_604460, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_604542 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBParameterGroup_604544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBParameterGroup_604543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604545 = query.getOrDefault("Action")
  valid_604545 = validateParameter(valid_604545, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604545 != nil:
    section.add "Action", valid_604545
  var valid_604546 = query.getOrDefault("Version")
  valid_604546 = validateParameter(valid_604546, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604546 != nil:
    section.add "Version", valid_604546
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604547 = header.getOrDefault("X-Amz-Date")
  valid_604547 = validateParameter(valid_604547, JString, required = false,
                                 default = nil)
  if valid_604547 != nil:
    section.add "X-Amz-Date", valid_604547
  var valid_604548 = header.getOrDefault("X-Amz-Security-Token")
  valid_604548 = validateParameter(valid_604548, JString, required = false,
                                 default = nil)
  if valid_604548 != nil:
    section.add "X-Amz-Security-Token", valid_604548
  var valid_604549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604549 = validateParameter(valid_604549, JString, required = false,
                                 default = nil)
  if valid_604549 != nil:
    section.add "X-Amz-Content-Sha256", valid_604549
  var valid_604550 = header.getOrDefault("X-Amz-Algorithm")
  valid_604550 = validateParameter(valid_604550, JString, required = false,
                                 default = nil)
  if valid_604550 != nil:
    section.add "X-Amz-Algorithm", valid_604550
  var valid_604551 = header.getOrDefault("X-Amz-Signature")
  valid_604551 = validateParameter(valid_604551, JString, required = false,
                                 default = nil)
  if valid_604551 != nil:
    section.add "X-Amz-Signature", valid_604551
  var valid_604552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604552 = validateParameter(valid_604552, JString, required = false,
                                 default = nil)
  if valid_604552 != nil:
    section.add "X-Amz-SignedHeaders", valid_604552
  var valid_604553 = header.getOrDefault("X-Amz-Credential")
  valid_604553 = validateParameter(valid_604553, JString, required = false,
                                 default = nil)
  if valid_604553 != nil:
    section.add "X-Amz-Credential", valid_604553
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604554 = formData.getOrDefault("DBParameterGroupName")
  valid_604554 = validateParameter(valid_604554, JString, required = true,
                                 default = nil)
  if valid_604554 != nil:
    section.add "DBParameterGroupName", valid_604554
  var valid_604555 = formData.getOrDefault("Parameters")
  valid_604555 = validateParameter(valid_604555, JArray, required = true, default = nil)
  if valid_604555 != nil:
    section.add "Parameters", valid_604555
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604556: Call_PostModifyDBParameterGroup_604542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604556.validator(path, query, header, formData, body)
  let scheme = call_604556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604556.url(scheme.get, call_604556.host, call_604556.base,
                         call_604556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604556, url, valid)

proc call*(call_604557: Call_PostModifyDBParameterGroup_604542;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604558 = newJObject()
  var formData_604559 = newJObject()
  add(formData_604559, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604559.add "Parameters", Parameters
  add(query_604558, "Action", newJString(Action))
  add(query_604558, "Version", newJString(Version))
  result = call_604557.call(nil, query_604558, nil, formData_604559, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_604542(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_604543, base: "/",
    url: url_PostModifyDBParameterGroup_604544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_604525 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBParameterGroup_604527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBParameterGroup_604526(path: JsonNode; query: JsonNode;
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
  var valid_604528 = query.getOrDefault("DBParameterGroupName")
  valid_604528 = validateParameter(valid_604528, JString, required = true,
                                 default = nil)
  if valid_604528 != nil:
    section.add "DBParameterGroupName", valid_604528
  var valid_604529 = query.getOrDefault("Parameters")
  valid_604529 = validateParameter(valid_604529, JArray, required = true, default = nil)
  if valid_604529 != nil:
    section.add "Parameters", valid_604529
  var valid_604530 = query.getOrDefault("Action")
  valid_604530 = validateParameter(valid_604530, JString, required = true,
                                 default = newJString("ModifyDBParameterGroup"))
  if valid_604530 != nil:
    section.add "Action", valid_604530
  var valid_604531 = query.getOrDefault("Version")
  valid_604531 = validateParameter(valid_604531, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604531 != nil:
    section.add "Version", valid_604531
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604532 = header.getOrDefault("X-Amz-Date")
  valid_604532 = validateParameter(valid_604532, JString, required = false,
                                 default = nil)
  if valid_604532 != nil:
    section.add "X-Amz-Date", valid_604532
  var valid_604533 = header.getOrDefault("X-Amz-Security-Token")
  valid_604533 = validateParameter(valid_604533, JString, required = false,
                                 default = nil)
  if valid_604533 != nil:
    section.add "X-Amz-Security-Token", valid_604533
  var valid_604534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604534 = validateParameter(valid_604534, JString, required = false,
                                 default = nil)
  if valid_604534 != nil:
    section.add "X-Amz-Content-Sha256", valid_604534
  var valid_604535 = header.getOrDefault("X-Amz-Algorithm")
  valid_604535 = validateParameter(valid_604535, JString, required = false,
                                 default = nil)
  if valid_604535 != nil:
    section.add "X-Amz-Algorithm", valid_604535
  var valid_604536 = header.getOrDefault("X-Amz-Signature")
  valid_604536 = validateParameter(valid_604536, JString, required = false,
                                 default = nil)
  if valid_604536 != nil:
    section.add "X-Amz-Signature", valid_604536
  var valid_604537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604537 = validateParameter(valid_604537, JString, required = false,
                                 default = nil)
  if valid_604537 != nil:
    section.add "X-Amz-SignedHeaders", valid_604537
  var valid_604538 = header.getOrDefault("X-Amz-Credential")
  valid_604538 = validateParameter(valid_604538, JString, required = false,
                                 default = nil)
  if valid_604538 != nil:
    section.add "X-Amz-Credential", valid_604538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604539: Call_GetModifyDBParameterGroup_604525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604539.validator(path, query, header, formData, body)
  let scheme = call_604539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604539.url(scheme.get, call_604539.host, call_604539.base,
                         call_604539.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604539, url, valid)

proc call*(call_604540: Call_GetModifyDBParameterGroup_604525;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604541 = newJObject()
  add(query_604541, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604541.add "Parameters", Parameters
  add(query_604541, "Action", newJString(Action))
  add(query_604541, "Version", newJString(Version))
  result = call_604540.call(nil, query_604541, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_604525(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_604526, base: "/",
    url: url_GetModifyDBParameterGroup_604527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_604578 = ref object of OpenApiRestCall_602450
proc url_PostModifyDBSubnetGroup_604580(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyDBSubnetGroup_604579(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604581 = query.getOrDefault("Action")
  valid_604581 = validateParameter(valid_604581, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604581 != nil:
    section.add "Action", valid_604581
  var valid_604582 = query.getOrDefault("Version")
  valid_604582 = validateParameter(valid_604582, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604582 != nil:
    section.add "Version", valid_604582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604583 = header.getOrDefault("X-Amz-Date")
  valid_604583 = validateParameter(valid_604583, JString, required = false,
                                 default = nil)
  if valid_604583 != nil:
    section.add "X-Amz-Date", valid_604583
  var valid_604584 = header.getOrDefault("X-Amz-Security-Token")
  valid_604584 = validateParameter(valid_604584, JString, required = false,
                                 default = nil)
  if valid_604584 != nil:
    section.add "X-Amz-Security-Token", valid_604584
  var valid_604585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604585 = validateParameter(valid_604585, JString, required = false,
                                 default = nil)
  if valid_604585 != nil:
    section.add "X-Amz-Content-Sha256", valid_604585
  var valid_604586 = header.getOrDefault("X-Amz-Algorithm")
  valid_604586 = validateParameter(valid_604586, JString, required = false,
                                 default = nil)
  if valid_604586 != nil:
    section.add "X-Amz-Algorithm", valid_604586
  var valid_604587 = header.getOrDefault("X-Amz-Signature")
  valid_604587 = validateParameter(valid_604587, JString, required = false,
                                 default = nil)
  if valid_604587 != nil:
    section.add "X-Amz-Signature", valid_604587
  var valid_604588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604588 = validateParameter(valid_604588, JString, required = false,
                                 default = nil)
  if valid_604588 != nil:
    section.add "X-Amz-SignedHeaders", valid_604588
  var valid_604589 = header.getOrDefault("X-Amz-Credential")
  valid_604589 = validateParameter(valid_604589, JString, required = false,
                                 default = nil)
  if valid_604589 != nil:
    section.add "X-Amz-Credential", valid_604589
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_604590 = formData.getOrDefault("DBSubnetGroupName")
  valid_604590 = validateParameter(valid_604590, JString, required = true,
                                 default = nil)
  if valid_604590 != nil:
    section.add "DBSubnetGroupName", valid_604590
  var valid_604591 = formData.getOrDefault("SubnetIds")
  valid_604591 = validateParameter(valid_604591, JArray, required = true, default = nil)
  if valid_604591 != nil:
    section.add "SubnetIds", valid_604591
  var valid_604592 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_604592 = validateParameter(valid_604592, JString, required = false,
                                 default = nil)
  if valid_604592 != nil:
    section.add "DBSubnetGroupDescription", valid_604592
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604593: Call_PostModifyDBSubnetGroup_604578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604593.validator(path, query, header, formData, body)
  let scheme = call_604593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604593.url(scheme.get, call_604593.host, call_604593.base,
                         call_604593.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604593, url, valid)

proc call*(call_604594: Call_PostModifyDBSubnetGroup_604578;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604595 = newJObject()
  var formData_604596 = newJObject()
  add(formData_604596, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_604596.add "SubnetIds", SubnetIds
  add(query_604595, "Action", newJString(Action))
  add(formData_604596, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604595, "Version", newJString(Version))
  result = call_604594.call(nil, query_604595, nil, formData_604596, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_604578(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_604579, base: "/",
    url: url_PostModifyDBSubnetGroup_604580, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_604560 = ref object of OpenApiRestCall_602450
proc url_GetModifyDBSubnetGroup_604562(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyDBSubnetGroup_604561(path: JsonNode; query: JsonNode;
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
  var valid_604563 = query.getOrDefault("Action")
  valid_604563 = validateParameter(valid_604563, JString, required = true,
                                 default = newJString("ModifyDBSubnetGroup"))
  if valid_604563 != nil:
    section.add "Action", valid_604563
  var valid_604564 = query.getOrDefault("DBSubnetGroupName")
  valid_604564 = validateParameter(valid_604564, JString, required = true,
                                 default = nil)
  if valid_604564 != nil:
    section.add "DBSubnetGroupName", valid_604564
  var valid_604565 = query.getOrDefault("SubnetIds")
  valid_604565 = validateParameter(valid_604565, JArray, required = true, default = nil)
  if valid_604565 != nil:
    section.add "SubnetIds", valid_604565
  var valid_604566 = query.getOrDefault("DBSubnetGroupDescription")
  valid_604566 = validateParameter(valid_604566, JString, required = false,
                                 default = nil)
  if valid_604566 != nil:
    section.add "DBSubnetGroupDescription", valid_604566
  var valid_604567 = query.getOrDefault("Version")
  valid_604567 = validateParameter(valid_604567, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604567 != nil:
    section.add "Version", valid_604567
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604568 = header.getOrDefault("X-Amz-Date")
  valid_604568 = validateParameter(valid_604568, JString, required = false,
                                 default = nil)
  if valid_604568 != nil:
    section.add "X-Amz-Date", valid_604568
  var valid_604569 = header.getOrDefault("X-Amz-Security-Token")
  valid_604569 = validateParameter(valid_604569, JString, required = false,
                                 default = nil)
  if valid_604569 != nil:
    section.add "X-Amz-Security-Token", valid_604569
  var valid_604570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604570 = validateParameter(valid_604570, JString, required = false,
                                 default = nil)
  if valid_604570 != nil:
    section.add "X-Amz-Content-Sha256", valid_604570
  var valid_604571 = header.getOrDefault("X-Amz-Algorithm")
  valid_604571 = validateParameter(valid_604571, JString, required = false,
                                 default = nil)
  if valid_604571 != nil:
    section.add "X-Amz-Algorithm", valid_604571
  var valid_604572 = header.getOrDefault("X-Amz-Signature")
  valid_604572 = validateParameter(valid_604572, JString, required = false,
                                 default = nil)
  if valid_604572 != nil:
    section.add "X-Amz-Signature", valid_604572
  var valid_604573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604573 = validateParameter(valid_604573, JString, required = false,
                                 default = nil)
  if valid_604573 != nil:
    section.add "X-Amz-SignedHeaders", valid_604573
  var valid_604574 = header.getOrDefault("X-Amz-Credential")
  valid_604574 = validateParameter(valid_604574, JString, required = false,
                                 default = nil)
  if valid_604574 != nil:
    section.add "X-Amz-Credential", valid_604574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604575: Call_GetModifyDBSubnetGroup_604560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604575.validator(path, query, header, formData, body)
  let scheme = call_604575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604575.url(scheme.get, call_604575.host, call_604575.base,
                         call_604575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604575, url, valid)

proc call*(call_604576: Call_GetModifyDBSubnetGroup_604560;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-01-10"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_604577 = newJObject()
  add(query_604577, "Action", newJString(Action))
  add(query_604577, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_604577.add "SubnetIds", SubnetIds
  add(query_604577, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_604577, "Version", newJString(Version))
  result = call_604576.call(nil, query_604577, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_604560(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_604561, base: "/",
    url: url_GetModifyDBSubnetGroup_604562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_604617 = ref object of OpenApiRestCall_602450
proc url_PostModifyEventSubscription_604619(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyEventSubscription_604618(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604620 = query.getOrDefault("Action")
  valid_604620 = validateParameter(valid_604620, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604620 != nil:
    section.add "Action", valid_604620
  var valid_604621 = query.getOrDefault("Version")
  valid_604621 = validateParameter(valid_604621, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604621 != nil:
    section.add "Version", valid_604621
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604622 = header.getOrDefault("X-Amz-Date")
  valid_604622 = validateParameter(valid_604622, JString, required = false,
                                 default = nil)
  if valid_604622 != nil:
    section.add "X-Amz-Date", valid_604622
  var valid_604623 = header.getOrDefault("X-Amz-Security-Token")
  valid_604623 = validateParameter(valid_604623, JString, required = false,
                                 default = nil)
  if valid_604623 != nil:
    section.add "X-Amz-Security-Token", valid_604623
  var valid_604624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604624 = validateParameter(valid_604624, JString, required = false,
                                 default = nil)
  if valid_604624 != nil:
    section.add "X-Amz-Content-Sha256", valid_604624
  var valid_604625 = header.getOrDefault("X-Amz-Algorithm")
  valid_604625 = validateParameter(valid_604625, JString, required = false,
                                 default = nil)
  if valid_604625 != nil:
    section.add "X-Amz-Algorithm", valid_604625
  var valid_604626 = header.getOrDefault("X-Amz-Signature")
  valid_604626 = validateParameter(valid_604626, JString, required = false,
                                 default = nil)
  if valid_604626 != nil:
    section.add "X-Amz-Signature", valid_604626
  var valid_604627 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604627 = validateParameter(valid_604627, JString, required = false,
                                 default = nil)
  if valid_604627 != nil:
    section.add "X-Amz-SignedHeaders", valid_604627
  var valid_604628 = header.getOrDefault("X-Amz-Credential")
  valid_604628 = validateParameter(valid_604628, JString, required = false,
                                 default = nil)
  if valid_604628 != nil:
    section.add "X-Amz-Credential", valid_604628
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_604629 = formData.getOrDefault("Enabled")
  valid_604629 = validateParameter(valid_604629, JBool, required = false, default = nil)
  if valid_604629 != nil:
    section.add "Enabled", valid_604629
  var valid_604630 = formData.getOrDefault("EventCategories")
  valid_604630 = validateParameter(valid_604630, JArray, required = false,
                                 default = nil)
  if valid_604630 != nil:
    section.add "EventCategories", valid_604630
  var valid_604631 = formData.getOrDefault("SnsTopicArn")
  valid_604631 = validateParameter(valid_604631, JString, required = false,
                                 default = nil)
  if valid_604631 != nil:
    section.add "SnsTopicArn", valid_604631
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_604632 = formData.getOrDefault("SubscriptionName")
  valid_604632 = validateParameter(valid_604632, JString, required = true,
                                 default = nil)
  if valid_604632 != nil:
    section.add "SubscriptionName", valid_604632
  var valid_604633 = formData.getOrDefault("SourceType")
  valid_604633 = validateParameter(valid_604633, JString, required = false,
                                 default = nil)
  if valid_604633 != nil:
    section.add "SourceType", valid_604633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604634: Call_PostModifyEventSubscription_604617; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604634.validator(path, query, header, formData, body)
  let scheme = call_604634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604634.url(scheme.get, call_604634.host, call_604634.base,
                         call_604634.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604634, url, valid)

proc call*(call_604635: Call_PostModifyEventSubscription_604617;
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
  var query_604636 = newJObject()
  var formData_604637 = newJObject()
  add(formData_604637, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_604637.add "EventCategories", EventCategories
  add(formData_604637, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_604637, "SubscriptionName", newJString(SubscriptionName))
  add(query_604636, "Action", newJString(Action))
  add(query_604636, "Version", newJString(Version))
  add(formData_604637, "SourceType", newJString(SourceType))
  result = call_604635.call(nil, query_604636, nil, formData_604637, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_604617(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_604618, base: "/",
    url: url_PostModifyEventSubscription_604619,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_604597 = ref object of OpenApiRestCall_602450
proc url_GetModifyEventSubscription_604599(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyEventSubscription_604598(path: JsonNode; query: JsonNode;
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
  var valid_604600 = query.getOrDefault("SourceType")
  valid_604600 = validateParameter(valid_604600, JString, required = false,
                                 default = nil)
  if valid_604600 != nil:
    section.add "SourceType", valid_604600
  var valid_604601 = query.getOrDefault("Enabled")
  valid_604601 = validateParameter(valid_604601, JBool, required = false, default = nil)
  if valid_604601 != nil:
    section.add "Enabled", valid_604601
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604602 = query.getOrDefault("Action")
  valid_604602 = validateParameter(valid_604602, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_604602 != nil:
    section.add "Action", valid_604602
  var valid_604603 = query.getOrDefault("SnsTopicArn")
  valid_604603 = validateParameter(valid_604603, JString, required = false,
                                 default = nil)
  if valid_604603 != nil:
    section.add "SnsTopicArn", valid_604603
  var valid_604604 = query.getOrDefault("EventCategories")
  valid_604604 = validateParameter(valid_604604, JArray, required = false,
                                 default = nil)
  if valid_604604 != nil:
    section.add "EventCategories", valid_604604
  var valid_604605 = query.getOrDefault("SubscriptionName")
  valid_604605 = validateParameter(valid_604605, JString, required = true,
                                 default = nil)
  if valid_604605 != nil:
    section.add "SubscriptionName", valid_604605
  var valid_604606 = query.getOrDefault("Version")
  valid_604606 = validateParameter(valid_604606, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604606 != nil:
    section.add "Version", valid_604606
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604607 = header.getOrDefault("X-Amz-Date")
  valid_604607 = validateParameter(valid_604607, JString, required = false,
                                 default = nil)
  if valid_604607 != nil:
    section.add "X-Amz-Date", valid_604607
  var valid_604608 = header.getOrDefault("X-Amz-Security-Token")
  valid_604608 = validateParameter(valid_604608, JString, required = false,
                                 default = nil)
  if valid_604608 != nil:
    section.add "X-Amz-Security-Token", valid_604608
  var valid_604609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604609 = validateParameter(valid_604609, JString, required = false,
                                 default = nil)
  if valid_604609 != nil:
    section.add "X-Amz-Content-Sha256", valid_604609
  var valid_604610 = header.getOrDefault("X-Amz-Algorithm")
  valid_604610 = validateParameter(valid_604610, JString, required = false,
                                 default = nil)
  if valid_604610 != nil:
    section.add "X-Amz-Algorithm", valid_604610
  var valid_604611 = header.getOrDefault("X-Amz-Signature")
  valid_604611 = validateParameter(valid_604611, JString, required = false,
                                 default = nil)
  if valid_604611 != nil:
    section.add "X-Amz-Signature", valid_604611
  var valid_604612 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604612 = validateParameter(valid_604612, JString, required = false,
                                 default = nil)
  if valid_604612 != nil:
    section.add "X-Amz-SignedHeaders", valid_604612
  var valid_604613 = header.getOrDefault("X-Amz-Credential")
  valid_604613 = validateParameter(valid_604613, JString, required = false,
                                 default = nil)
  if valid_604613 != nil:
    section.add "X-Amz-Credential", valid_604613
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604614: Call_GetModifyEventSubscription_604597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604614.validator(path, query, header, formData, body)
  let scheme = call_604614.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604614.url(scheme.get, call_604614.host, call_604614.base,
                         call_604614.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604614, url, valid)

proc call*(call_604615: Call_GetModifyEventSubscription_604597;
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
  var query_604616 = newJObject()
  add(query_604616, "SourceType", newJString(SourceType))
  add(query_604616, "Enabled", newJBool(Enabled))
  add(query_604616, "Action", newJString(Action))
  add(query_604616, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_604616.add "EventCategories", EventCategories
  add(query_604616, "SubscriptionName", newJString(SubscriptionName))
  add(query_604616, "Version", newJString(Version))
  result = call_604615.call(nil, query_604616, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_604597(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_604598, base: "/",
    url: url_GetModifyEventSubscription_604599,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_604657 = ref object of OpenApiRestCall_602450
proc url_PostModifyOptionGroup_604659(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostModifyOptionGroup_604658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604660 = query.getOrDefault("Action")
  valid_604660 = validateParameter(valid_604660, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604660 != nil:
    section.add "Action", valid_604660
  var valid_604661 = query.getOrDefault("Version")
  valid_604661 = validateParameter(valid_604661, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604661 != nil:
    section.add "Version", valid_604661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604662 = header.getOrDefault("X-Amz-Date")
  valid_604662 = validateParameter(valid_604662, JString, required = false,
                                 default = nil)
  if valid_604662 != nil:
    section.add "X-Amz-Date", valid_604662
  var valid_604663 = header.getOrDefault("X-Amz-Security-Token")
  valid_604663 = validateParameter(valid_604663, JString, required = false,
                                 default = nil)
  if valid_604663 != nil:
    section.add "X-Amz-Security-Token", valid_604663
  var valid_604664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604664 = validateParameter(valid_604664, JString, required = false,
                                 default = nil)
  if valid_604664 != nil:
    section.add "X-Amz-Content-Sha256", valid_604664
  var valid_604665 = header.getOrDefault("X-Amz-Algorithm")
  valid_604665 = validateParameter(valid_604665, JString, required = false,
                                 default = nil)
  if valid_604665 != nil:
    section.add "X-Amz-Algorithm", valid_604665
  var valid_604666 = header.getOrDefault("X-Amz-Signature")
  valid_604666 = validateParameter(valid_604666, JString, required = false,
                                 default = nil)
  if valid_604666 != nil:
    section.add "X-Amz-Signature", valid_604666
  var valid_604667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604667 = validateParameter(valid_604667, JString, required = false,
                                 default = nil)
  if valid_604667 != nil:
    section.add "X-Amz-SignedHeaders", valid_604667
  var valid_604668 = header.getOrDefault("X-Amz-Credential")
  valid_604668 = validateParameter(valid_604668, JString, required = false,
                                 default = nil)
  if valid_604668 != nil:
    section.add "X-Amz-Credential", valid_604668
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_604669 = formData.getOrDefault("OptionsToRemove")
  valid_604669 = validateParameter(valid_604669, JArray, required = false,
                                 default = nil)
  if valid_604669 != nil:
    section.add "OptionsToRemove", valid_604669
  var valid_604670 = formData.getOrDefault("ApplyImmediately")
  valid_604670 = validateParameter(valid_604670, JBool, required = false, default = nil)
  if valid_604670 != nil:
    section.add "ApplyImmediately", valid_604670
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_604671 = formData.getOrDefault("OptionGroupName")
  valid_604671 = validateParameter(valid_604671, JString, required = true,
                                 default = nil)
  if valid_604671 != nil:
    section.add "OptionGroupName", valid_604671
  var valid_604672 = formData.getOrDefault("OptionsToInclude")
  valid_604672 = validateParameter(valid_604672, JArray, required = false,
                                 default = nil)
  if valid_604672 != nil:
    section.add "OptionsToInclude", valid_604672
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604673: Call_PostModifyOptionGroup_604657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604673.validator(path, query, header, formData, body)
  let scheme = call_604673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604673.url(scheme.get, call_604673.host, call_604673.base,
                         call_604673.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604673, url, valid)

proc call*(call_604674: Call_PostModifyOptionGroup_604657; OptionGroupName: string;
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
  var query_604675 = newJObject()
  var formData_604676 = newJObject()
  if OptionsToRemove != nil:
    formData_604676.add "OptionsToRemove", OptionsToRemove
  add(formData_604676, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_604676, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_604676.add "OptionsToInclude", OptionsToInclude
  add(query_604675, "Action", newJString(Action))
  add(query_604675, "Version", newJString(Version))
  result = call_604674.call(nil, query_604675, nil, formData_604676, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_604657(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_604658, base: "/",
    url: url_PostModifyOptionGroup_604659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_604638 = ref object of OpenApiRestCall_602450
proc url_GetModifyOptionGroup_604640(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetModifyOptionGroup_604639(path: JsonNode; query: JsonNode;
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
  var valid_604641 = query.getOrDefault("OptionGroupName")
  valid_604641 = validateParameter(valid_604641, JString, required = true,
                                 default = nil)
  if valid_604641 != nil:
    section.add "OptionGroupName", valid_604641
  var valid_604642 = query.getOrDefault("OptionsToRemove")
  valid_604642 = validateParameter(valid_604642, JArray, required = false,
                                 default = nil)
  if valid_604642 != nil:
    section.add "OptionsToRemove", valid_604642
  var valid_604643 = query.getOrDefault("Action")
  valid_604643 = validateParameter(valid_604643, JString, required = true,
                                 default = newJString("ModifyOptionGroup"))
  if valid_604643 != nil:
    section.add "Action", valid_604643
  var valid_604644 = query.getOrDefault("Version")
  valid_604644 = validateParameter(valid_604644, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604644 != nil:
    section.add "Version", valid_604644
  var valid_604645 = query.getOrDefault("ApplyImmediately")
  valid_604645 = validateParameter(valid_604645, JBool, required = false, default = nil)
  if valid_604645 != nil:
    section.add "ApplyImmediately", valid_604645
  var valid_604646 = query.getOrDefault("OptionsToInclude")
  valid_604646 = validateParameter(valid_604646, JArray, required = false,
                                 default = nil)
  if valid_604646 != nil:
    section.add "OptionsToInclude", valid_604646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604647 = header.getOrDefault("X-Amz-Date")
  valid_604647 = validateParameter(valid_604647, JString, required = false,
                                 default = nil)
  if valid_604647 != nil:
    section.add "X-Amz-Date", valid_604647
  var valid_604648 = header.getOrDefault("X-Amz-Security-Token")
  valid_604648 = validateParameter(valid_604648, JString, required = false,
                                 default = nil)
  if valid_604648 != nil:
    section.add "X-Amz-Security-Token", valid_604648
  var valid_604649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604649 = validateParameter(valid_604649, JString, required = false,
                                 default = nil)
  if valid_604649 != nil:
    section.add "X-Amz-Content-Sha256", valid_604649
  var valid_604650 = header.getOrDefault("X-Amz-Algorithm")
  valid_604650 = validateParameter(valid_604650, JString, required = false,
                                 default = nil)
  if valid_604650 != nil:
    section.add "X-Amz-Algorithm", valid_604650
  var valid_604651 = header.getOrDefault("X-Amz-Signature")
  valid_604651 = validateParameter(valid_604651, JString, required = false,
                                 default = nil)
  if valid_604651 != nil:
    section.add "X-Amz-Signature", valid_604651
  var valid_604652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604652 = validateParameter(valid_604652, JString, required = false,
                                 default = nil)
  if valid_604652 != nil:
    section.add "X-Amz-SignedHeaders", valid_604652
  var valid_604653 = header.getOrDefault("X-Amz-Credential")
  valid_604653 = validateParameter(valid_604653, JString, required = false,
                                 default = nil)
  if valid_604653 != nil:
    section.add "X-Amz-Credential", valid_604653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604654: Call_GetModifyOptionGroup_604638; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604654.validator(path, query, header, formData, body)
  let scheme = call_604654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604654.url(scheme.get, call_604654.host, call_604654.base,
                         call_604654.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604654, url, valid)

proc call*(call_604655: Call_GetModifyOptionGroup_604638; OptionGroupName: string;
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
  var query_604656 = newJObject()
  add(query_604656, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_604656.add "OptionsToRemove", OptionsToRemove
  add(query_604656, "Action", newJString(Action))
  add(query_604656, "Version", newJString(Version))
  add(query_604656, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_604656.add "OptionsToInclude", OptionsToInclude
  result = call_604655.call(nil, query_604656, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_604638(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_604639, base: "/",
    url: url_GetModifyOptionGroup_604640, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_604695 = ref object of OpenApiRestCall_602450
proc url_PostPromoteReadReplica_604697(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPromoteReadReplica_604696(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604698 = query.getOrDefault("Action")
  valid_604698 = validateParameter(valid_604698, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604698 != nil:
    section.add "Action", valid_604698
  var valid_604699 = query.getOrDefault("Version")
  valid_604699 = validateParameter(valid_604699, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604699 != nil:
    section.add "Version", valid_604699
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604700 = header.getOrDefault("X-Amz-Date")
  valid_604700 = validateParameter(valid_604700, JString, required = false,
                                 default = nil)
  if valid_604700 != nil:
    section.add "X-Amz-Date", valid_604700
  var valid_604701 = header.getOrDefault("X-Amz-Security-Token")
  valid_604701 = validateParameter(valid_604701, JString, required = false,
                                 default = nil)
  if valid_604701 != nil:
    section.add "X-Amz-Security-Token", valid_604701
  var valid_604702 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604702 = validateParameter(valid_604702, JString, required = false,
                                 default = nil)
  if valid_604702 != nil:
    section.add "X-Amz-Content-Sha256", valid_604702
  var valid_604703 = header.getOrDefault("X-Amz-Algorithm")
  valid_604703 = validateParameter(valid_604703, JString, required = false,
                                 default = nil)
  if valid_604703 != nil:
    section.add "X-Amz-Algorithm", valid_604703
  var valid_604704 = header.getOrDefault("X-Amz-Signature")
  valid_604704 = validateParameter(valid_604704, JString, required = false,
                                 default = nil)
  if valid_604704 != nil:
    section.add "X-Amz-Signature", valid_604704
  var valid_604705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604705 = validateParameter(valid_604705, JString, required = false,
                                 default = nil)
  if valid_604705 != nil:
    section.add "X-Amz-SignedHeaders", valid_604705
  var valid_604706 = header.getOrDefault("X-Amz-Credential")
  valid_604706 = validateParameter(valid_604706, JString, required = false,
                                 default = nil)
  if valid_604706 != nil:
    section.add "X-Amz-Credential", valid_604706
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604707 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604707 = validateParameter(valid_604707, JString, required = true,
                                 default = nil)
  if valid_604707 != nil:
    section.add "DBInstanceIdentifier", valid_604707
  var valid_604708 = formData.getOrDefault("BackupRetentionPeriod")
  valid_604708 = validateParameter(valid_604708, JInt, required = false, default = nil)
  if valid_604708 != nil:
    section.add "BackupRetentionPeriod", valid_604708
  var valid_604709 = formData.getOrDefault("PreferredBackupWindow")
  valid_604709 = validateParameter(valid_604709, JString, required = false,
                                 default = nil)
  if valid_604709 != nil:
    section.add "PreferredBackupWindow", valid_604709
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604710: Call_PostPromoteReadReplica_604695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604710.validator(path, query, header, formData, body)
  let scheme = call_604710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604710.url(scheme.get, call_604710.host, call_604710.base,
                         call_604710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604710, url, valid)

proc call*(call_604711: Call_PostPromoteReadReplica_604695;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_604712 = newJObject()
  var formData_604713 = newJObject()
  add(formData_604713, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604713, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604712, "Action", newJString(Action))
  add(formData_604713, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604712, "Version", newJString(Version))
  result = call_604711.call(nil, query_604712, nil, formData_604713, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_604695(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_604696, base: "/",
    url: url_PostPromoteReadReplica_604697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_604677 = ref object of OpenApiRestCall_602450
proc url_GetPromoteReadReplica_604679(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPromoteReadReplica_604678(path: JsonNode; query: JsonNode;
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
  var valid_604680 = query.getOrDefault("BackupRetentionPeriod")
  valid_604680 = validateParameter(valid_604680, JInt, required = false, default = nil)
  if valid_604680 != nil:
    section.add "BackupRetentionPeriod", valid_604680
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604681 = query.getOrDefault("Action")
  valid_604681 = validateParameter(valid_604681, JString, required = true,
                                 default = newJString("PromoteReadReplica"))
  if valid_604681 != nil:
    section.add "Action", valid_604681
  var valid_604682 = query.getOrDefault("PreferredBackupWindow")
  valid_604682 = validateParameter(valid_604682, JString, required = false,
                                 default = nil)
  if valid_604682 != nil:
    section.add "PreferredBackupWindow", valid_604682
  var valid_604683 = query.getOrDefault("Version")
  valid_604683 = validateParameter(valid_604683, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604683 != nil:
    section.add "Version", valid_604683
  var valid_604684 = query.getOrDefault("DBInstanceIdentifier")
  valid_604684 = validateParameter(valid_604684, JString, required = true,
                                 default = nil)
  if valid_604684 != nil:
    section.add "DBInstanceIdentifier", valid_604684
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604685 = header.getOrDefault("X-Amz-Date")
  valid_604685 = validateParameter(valid_604685, JString, required = false,
                                 default = nil)
  if valid_604685 != nil:
    section.add "X-Amz-Date", valid_604685
  var valid_604686 = header.getOrDefault("X-Amz-Security-Token")
  valid_604686 = validateParameter(valid_604686, JString, required = false,
                                 default = nil)
  if valid_604686 != nil:
    section.add "X-Amz-Security-Token", valid_604686
  var valid_604687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604687 = validateParameter(valid_604687, JString, required = false,
                                 default = nil)
  if valid_604687 != nil:
    section.add "X-Amz-Content-Sha256", valid_604687
  var valid_604688 = header.getOrDefault("X-Amz-Algorithm")
  valid_604688 = validateParameter(valid_604688, JString, required = false,
                                 default = nil)
  if valid_604688 != nil:
    section.add "X-Amz-Algorithm", valid_604688
  var valid_604689 = header.getOrDefault("X-Amz-Signature")
  valid_604689 = validateParameter(valid_604689, JString, required = false,
                                 default = nil)
  if valid_604689 != nil:
    section.add "X-Amz-Signature", valid_604689
  var valid_604690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604690 = validateParameter(valid_604690, JString, required = false,
                                 default = nil)
  if valid_604690 != nil:
    section.add "X-Amz-SignedHeaders", valid_604690
  var valid_604691 = header.getOrDefault("X-Amz-Credential")
  valid_604691 = validateParameter(valid_604691, JString, required = false,
                                 default = nil)
  if valid_604691 != nil:
    section.add "X-Amz-Credential", valid_604691
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604692: Call_GetPromoteReadReplica_604677; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604692.validator(path, query, header, formData, body)
  let scheme = call_604692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604692.url(scheme.get, call_604692.host, call_604692.base,
                         call_604692.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604692, url, valid)

proc call*(call_604693: Call_GetPromoteReadReplica_604677;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-01-10"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604694 = newJObject()
  add(query_604694, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_604694, "Action", newJString(Action))
  add(query_604694, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_604694, "Version", newJString(Version))
  add(query_604694, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604693.call(nil, query_604694, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_604677(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_604678, base: "/",
    url: url_GetPromoteReadReplica_604679, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_604732 = ref object of OpenApiRestCall_602450
proc url_PostPurchaseReservedDBInstancesOffering_604734(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_604733(path: JsonNode;
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
  var valid_604735 = query.getOrDefault("Action")
  valid_604735 = validateParameter(valid_604735, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604735 != nil:
    section.add "Action", valid_604735
  var valid_604736 = query.getOrDefault("Version")
  valid_604736 = validateParameter(valid_604736, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604736 != nil:
    section.add "Version", valid_604736
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604737 = header.getOrDefault("X-Amz-Date")
  valid_604737 = validateParameter(valid_604737, JString, required = false,
                                 default = nil)
  if valid_604737 != nil:
    section.add "X-Amz-Date", valid_604737
  var valid_604738 = header.getOrDefault("X-Amz-Security-Token")
  valid_604738 = validateParameter(valid_604738, JString, required = false,
                                 default = nil)
  if valid_604738 != nil:
    section.add "X-Amz-Security-Token", valid_604738
  var valid_604739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604739 = validateParameter(valid_604739, JString, required = false,
                                 default = nil)
  if valid_604739 != nil:
    section.add "X-Amz-Content-Sha256", valid_604739
  var valid_604740 = header.getOrDefault("X-Amz-Algorithm")
  valid_604740 = validateParameter(valid_604740, JString, required = false,
                                 default = nil)
  if valid_604740 != nil:
    section.add "X-Amz-Algorithm", valid_604740
  var valid_604741 = header.getOrDefault("X-Amz-Signature")
  valid_604741 = validateParameter(valid_604741, JString, required = false,
                                 default = nil)
  if valid_604741 != nil:
    section.add "X-Amz-Signature", valid_604741
  var valid_604742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604742 = validateParameter(valid_604742, JString, required = false,
                                 default = nil)
  if valid_604742 != nil:
    section.add "X-Amz-SignedHeaders", valid_604742
  var valid_604743 = header.getOrDefault("X-Amz-Credential")
  valid_604743 = validateParameter(valid_604743, JString, required = false,
                                 default = nil)
  if valid_604743 != nil:
    section.add "X-Amz-Credential", valid_604743
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_604744 = formData.getOrDefault("ReservedDBInstanceId")
  valid_604744 = validateParameter(valid_604744, JString, required = false,
                                 default = nil)
  if valid_604744 != nil:
    section.add "ReservedDBInstanceId", valid_604744
  var valid_604745 = formData.getOrDefault("DBInstanceCount")
  valid_604745 = validateParameter(valid_604745, JInt, required = false, default = nil)
  if valid_604745 != nil:
    section.add "DBInstanceCount", valid_604745
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604746 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604746 = validateParameter(valid_604746, JString, required = true,
                                 default = nil)
  if valid_604746 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604747: Call_PostPurchaseReservedDBInstancesOffering_604732;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604747.validator(path, query, header, formData, body)
  let scheme = call_604747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604747.url(scheme.get, call_604747.host, call_604747.base,
                         call_604747.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604747, url, valid)

proc call*(call_604748: Call_PostPurchaseReservedDBInstancesOffering_604732;
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
  var query_604749 = newJObject()
  var formData_604750 = newJObject()
  add(formData_604750, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_604750, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604749, "Action", newJString(Action))
  add(formData_604750, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604749, "Version", newJString(Version))
  result = call_604748.call(nil, query_604749, nil, formData_604750, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_604732(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_604733, base: "/",
    url: url_PostPurchaseReservedDBInstancesOffering_604734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_604714 = ref object of OpenApiRestCall_602450
proc url_GetPurchaseReservedDBInstancesOffering_604716(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_604715(path: JsonNode;
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
  var valid_604717 = query.getOrDefault("DBInstanceCount")
  valid_604717 = validateParameter(valid_604717, JInt, required = false, default = nil)
  if valid_604717 != nil:
    section.add "DBInstanceCount", valid_604717
  var valid_604718 = query.getOrDefault("ReservedDBInstanceId")
  valid_604718 = validateParameter(valid_604718, JString, required = false,
                                 default = nil)
  if valid_604718 != nil:
    section.add "ReservedDBInstanceId", valid_604718
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_604719 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_604719 = validateParameter(valid_604719, JString, required = true,
                                 default = nil)
  if valid_604719 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_604719
  var valid_604720 = query.getOrDefault("Action")
  valid_604720 = validateParameter(valid_604720, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_604720 != nil:
    section.add "Action", valid_604720
  var valid_604721 = query.getOrDefault("Version")
  valid_604721 = validateParameter(valid_604721, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604721 != nil:
    section.add "Version", valid_604721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604722 = header.getOrDefault("X-Amz-Date")
  valid_604722 = validateParameter(valid_604722, JString, required = false,
                                 default = nil)
  if valid_604722 != nil:
    section.add "X-Amz-Date", valid_604722
  var valid_604723 = header.getOrDefault("X-Amz-Security-Token")
  valid_604723 = validateParameter(valid_604723, JString, required = false,
                                 default = nil)
  if valid_604723 != nil:
    section.add "X-Amz-Security-Token", valid_604723
  var valid_604724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604724 = validateParameter(valid_604724, JString, required = false,
                                 default = nil)
  if valid_604724 != nil:
    section.add "X-Amz-Content-Sha256", valid_604724
  var valid_604725 = header.getOrDefault("X-Amz-Algorithm")
  valid_604725 = validateParameter(valid_604725, JString, required = false,
                                 default = nil)
  if valid_604725 != nil:
    section.add "X-Amz-Algorithm", valid_604725
  var valid_604726 = header.getOrDefault("X-Amz-Signature")
  valid_604726 = validateParameter(valid_604726, JString, required = false,
                                 default = nil)
  if valid_604726 != nil:
    section.add "X-Amz-Signature", valid_604726
  var valid_604727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604727 = validateParameter(valid_604727, JString, required = false,
                                 default = nil)
  if valid_604727 != nil:
    section.add "X-Amz-SignedHeaders", valid_604727
  var valid_604728 = header.getOrDefault("X-Amz-Credential")
  valid_604728 = validateParameter(valid_604728, JString, required = false,
                                 default = nil)
  if valid_604728 != nil:
    section.add "X-Amz-Credential", valid_604728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604729: Call_GetPurchaseReservedDBInstancesOffering_604714;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604729.validator(path, query, header, formData, body)
  let scheme = call_604729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604729.url(scheme.get, call_604729.host, call_604729.base,
                         call_604729.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604729, url, valid)

proc call*(call_604730: Call_GetPurchaseReservedDBInstancesOffering_604714;
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
  var query_604731 = newJObject()
  add(query_604731, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_604731, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_604731, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_604731, "Action", newJString(Action))
  add(query_604731, "Version", newJString(Version))
  result = call_604730.call(nil, query_604731, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_604714(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_604715, base: "/",
    url: url_GetPurchaseReservedDBInstancesOffering_604716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_604768 = ref object of OpenApiRestCall_602450
proc url_PostRebootDBInstance_604770(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRebootDBInstance_604769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604771 = query.getOrDefault("Action")
  valid_604771 = validateParameter(valid_604771, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604771 != nil:
    section.add "Action", valid_604771
  var valid_604772 = query.getOrDefault("Version")
  valid_604772 = validateParameter(valid_604772, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604772 != nil:
    section.add "Version", valid_604772
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604773 = header.getOrDefault("X-Amz-Date")
  valid_604773 = validateParameter(valid_604773, JString, required = false,
                                 default = nil)
  if valid_604773 != nil:
    section.add "X-Amz-Date", valid_604773
  var valid_604774 = header.getOrDefault("X-Amz-Security-Token")
  valid_604774 = validateParameter(valid_604774, JString, required = false,
                                 default = nil)
  if valid_604774 != nil:
    section.add "X-Amz-Security-Token", valid_604774
  var valid_604775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604775 = validateParameter(valid_604775, JString, required = false,
                                 default = nil)
  if valid_604775 != nil:
    section.add "X-Amz-Content-Sha256", valid_604775
  var valid_604776 = header.getOrDefault("X-Amz-Algorithm")
  valid_604776 = validateParameter(valid_604776, JString, required = false,
                                 default = nil)
  if valid_604776 != nil:
    section.add "X-Amz-Algorithm", valid_604776
  var valid_604777 = header.getOrDefault("X-Amz-Signature")
  valid_604777 = validateParameter(valid_604777, JString, required = false,
                                 default = nil)
  if valid_604777 != nil:
    section.add "X-Amz-Signature", valid_604777
  var valid_604778 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604778 = validateParameter(valid_604778, JString, required = false,
                                 default = nil)
  if valid_604778 != nil:
    section.add "X-Amz-SignedHeaders", valid_604778
  var valid_604779 = header.getOrDefault("X-Amz-Credential")
  valid_604779 = validateParameter(valid_604779, JString, required = false,
                                 default = nil)
  if valid_604779 != nil:
    section.add "X-Amz-Credential", valid_604779
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604780 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604780 = validateParameter(valid_604780, JString, required = true,
                                 default = nil)
  if valid_604780 != nil:
    section.add "DBInstanceIdentifier", valid_604780
  var valid_604781 = formData.getOrDefault("ForceFailover")
  valid_604781 = validateParameter(valid_604781, JBool, required = false, default = nil)
  if valid_604781 != nil:
    section.add "ForceFailover", valid_604781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604782: Call_PostRebootDBInstance_604768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604782.validator(path, query, header, formData, body)
  let scheme = call_604782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604782.url(scheme.get, call_604782.host, call_604782.base,
                         call_604782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604782, url, valid)

proc call*(call_604783: Call_PostRebootDBInstance_604768;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_604784 = newJObject()
  var formData_604785 = newJObject()
  add(formData_604785, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604784, "Action", newJString(Action))
  add(formData_604785, "ForceFailover", newJBool(ForceFailover))
  add(query_604784, "Version", newJString(Version))
  result = call_604783.call(nil, query_604784, nil, formData_604785, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_604768(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_604769, base: "/",
    url: url_PostRebootDBInstance_604770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_604751 = ref object of OpenApiRestCall_602450
proc url_GetRebootDBInstance_604753(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRebootDBInstance_604752(path: JsonNode; query: JsonNode;
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
  var valid_604754 = query.getOrDefault("Action")
  valid_604754 = validateParameter(valid_604754, JString, required = true,
                                 default = newJString("RebootDBInstance"))
  if valid_604754 != nil:
    section.add "Action", valid_604754
  var valid_604755 = query.getOrDefault("ForceFailover")
  valid_604755 = validateParameter(valid_604755, JBool, required = false, default = nil)
  if valid_604755 != nil:
    section.add "ForceFailover", valid_604755
  var valid_604756 = query.getOrDefault("Version")
  valid_604756 = validateParameter(valid_604756, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604756 != nil:
    section.add "Version", valid_604756
  var valid_604757 = query.getOrDefault("DBInstanceIdentifier")
  valid_604757 = validateParameter(valid_604757, JString, required = true,
                                 default = nil)
  if valid_604757 != nil:
    section.add "DBInstanceIdentifier", valid_604757
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604758 = header.getOrDefault("X-Amz-Date")
  valid_604758 = validateParameter(valid_604758, JString, required = false,
                                 default = nil)
  if valid_604758 != nil:
    section.add "X-Amz-Date", valid_604758
  var valid_604759 = header.getOrDefault("X-Amz-Security-Token")
  valid_604759 = validateParameter(valid_604759, JString, required = false,
                                 default = nil)
  if valid_604759 != nil:
    section.add "X-Amz-Security-Token", valid_604759
  var valid_604760 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604760 = validateParameter(valid_604760, JString, required = false,
                                 default = nil)
  if valid_604760 != nil:
    section.add "X-Amz-Content-Sha256", valid_604760
  var valid_604761 = header.getOrDefault("X-Amz-Algorithm")
  valid_604761 = validateParameter(valid_604761, JString, required = false,
                                 default = nil)
  if valid_604761 != nil:
    section.add "X-Amz-Algorithm", valid_604761
  var valid_604762 = header.getOrDefault("X-Amz-Signature")
  valid_604762 = validateParameter(valid_604762, JString, required = false,
                                 default = nil)
  if valid_604762 != nil:
    section.add "X-Amz-Signature", valid_604762
  var valid_604763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604763 = validateParameter(valid_604763, JString, required = false,
                                 default = nil)
  if valid_604763 != nil:
    section.add "X-Amz-SignedHeaders", valid_604763
  var valid_604764 = header.getOrDefault("X-Amz-Credential")
  valid_604764 = validateParameter(valid_604764, JString, required = false,
                                 default = nil)
  if valid_604764 != nil:
    section.add "X-Amz-Credential", valid_604764
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604765: Call_GetRebootDBInstance_604751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604765.validator(path, query, header, formData, body)
  let scheme = call_604765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604765.url(scheme.get, call_604765.host, call_604765.base,
                         call_604765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604765, url, valid)

proc call*(call_604766: Call_GetRebootDBInstance_604751;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_604767 = newJObject()
  add(query_604767, "Action", newJString(Action))
  add(query_604767, "ForceFailover", newJBool(ForceFailover))
  add(query_604767, "Version", newJString(Version))
  add(query_604767, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_604766.call(nil, query_604767, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_604751(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_604752, base: "/",
    url: url_GetRebootDBInstance_604753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_604803 = ref object of OpenApiRestCall_602450
proc url_PostRemoveSourceIdentifierFromSubscription_604805(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_604804(path: JsonNode;
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
  var valid_604806 = query.getOrDefault("Action")
  valid_604806 = validateParameter(valid_604806, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604806 != nil:
    section.add "Action", valid_604806
  var valid_604807 = query.getOrDefault("Version")
  valid_604807 = validateParameter(valid_604807, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604807 != nil:
    section.add "Version", valid_604807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604808 = header.getOrDefault("X-Amz-Date")
  valid_604808 = validateParameter(valid_604808, JString, required = false,
                                 default = nil)
  if valid_604808 != nil:
    section.add "X-Amz-Date", valid_604808
  var valid_604809 = header.getOrDefault("X-Amz-Security-Token")
  valid_604809 = validateParameter(valid_604809, JString, required = false,
                                 default = nil)
  if valid_604809 != nil:
    section.add "X-Amz-Security-Token", valid_604809
  var valid_604810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604810 = validateParameter(valid_604810, JString, required = false,
                                 default = nil)
  if valid_604810 != nil:
    section.add "X-Amz-Content-Sha256", valid_604810
  var valid_604811 = header.getOrDefault("X-Amz-Algorithm")
  valid_604811 = validateParameter(valid_604811, JString, required = false,
                                 default = nil)
  if valid_604811 != nil:
    section.add "X-Amz-Algorithm", valid_604811
  var valid_604812 = header.getOrDefault("X-Amz-Signature")
  valid_604812 = validateParameter(valid_604812, JString, required = false,
                                 default = nil)
  if valid_604812 != nil:
    section.add "X-Amz-Signature", valid_604812
  var valid_604813 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604813 = validateParameter(valid_604813, JString, required = false,
                                 default = nil)
  if valid_604813 != nil:
    section.add "X-Amz-SignedHeaders", valid_604813
  var valid_604814 = header.getOrDefault("X-Amz-Credential")
  valid_604814 = validateParameter(valid_604814, JString, required = false,
                                 default = nil)
  if valid_604814 != nil:
    section.add "X-Amz-Credential", valid_604814
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_604815 = formData.getOrDefault("SourceIdentifier")
  valid_604815 = validateParameter(valid_604815, JString, required = true,
                                 default = nil)
  if valid_604815 != nil:
    section.add "SourceIdentifier", valid_604815
  var valid_604816 = formData.getOrDefault("SubscriptionName")
  valid_604816 = validateParameter(valid_604816, JString, required = true,
                                 default = nil)
  if valid_604816 != nil:
    section.add "SubscriptionName", valid_604816
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604817: Call_PostRemoveSourceIdentifierFromSubscription_604803;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604817.validator(path, query, header, formData, body)
  let scheme = call_604817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604817.url(scheme.get, call_604817.host, call_604817.base,
                         call_604817.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604817, url, valid)

proc call*(call_604818: Call_PostRemoveSourceIdentifierFromSubscription_604803;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_604819 = newJObject()
  var formData_604820 = newJObject()
  add(formData_604820, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_604820, "SubscriptionName", newJString(SubscriptionName))
  add(query_604819, "Action", newJString(Action))
  add(query_604819, "Version", newJString(Version))
  result = call_604818.call(nil, query_604819, nil, formData_604820, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_604803(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_604804,
    base: "/", url: url_PostRemoveSourceIdentifierFromSubscription_604805,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_604786 = ref object of OpenApiRestCall_602450
proc url_GetRemoveSourceIdentifierFromSubscription_604788(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_604787(path: JsonNode;
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
  var valid_604789 = query.getOrDefault("Action")
  valid_604789 = validateParameter(valid_604789, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_604789 != nil:
    section.add "Action", valid_604789
  var valid_604790 = query.getOrDefault("SourceIdentifier")
  valid_604790 = validateParameter(valid_604790, JString, required = true,
                                 default = nil)
  if valid_604790 != nil:
    section.add "SourceIdentifier", valid_604790
  var valid_604791 = query.getOrDefault("SubscriptionName")
  valid_604791 = validateParameter(valid_604791, JString, required = true,
                                 default = nil)
  if valid_604791 != nil:
    section.add "SubscriptionName", valid_604791
  var valid_604792 = query.getOrDefault("Version")
  valid_604792 = validateParameter(valid_604792, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604792 != nil:
    section.add "Version", valid_604792
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604793 = header.getOrDefault("X-Amz-Date")
  valid_604793 = validateParameter(valid_604793, JString, required = false,
                                 default = nil)
  if valid_604793 != nil:
    section.add "X-Amz-Date", valid_604793
  var valid_604794 = header.getOrDefault("X-Amz-Security-Token")
  valid_604794 = validateParameter(valid_604794, JString, required = false,
                                 default = nil)
  if valid_604794 != nil:
    section.add "X-Amz-Security-Token", valid_604794
  var valid_604795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604795 = validateParameter(valid_604795, JString, required = false,
                                 default = nil)
  if valid_604795 != nil:
    section.add "X-Amz-Content-Sha256", valid_604795
  var valid_604796 = header.getOrDefault("X-Amz-Algorithm")
  valid_604796 = validateParameter(valid_604796, JString, required = false,
                                 default = nil)
  if valid_604796 != nil:
    section.add "X-Amz-Algorithm", valid_604796
  var valid_604797 = header.getOrDefault("X-Amz-Signature")
  valid_604797 = validateParameter(valid_604797, JString, required = false,
                                 default = nil)
  if valid_604797 != nil:
    section.add "X-Amz-Signature", valid_604797
  var valid_604798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604798 = validateParameter(valid_604798, JString, required = false,
                                 default = nil)
  if valid_604798 != nil:
    section.add "X-Amz-SignedHeaders", valid_604798
  var valid_604799 = header.getOrDefault("X-Amz-Credential")
  valid_604799 = validateParameter(valid_604799, JString, required = false,
                                 default = nil)
  if valid_604799 != nil:
    section.add "X-Amz-Credential", valid_604799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604800: Call_GetRemoveSourceIdentifierFromSubscription_604786;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604800.validator(path, query, header, formData, body)
  let scheme = call_604800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604800.url(scheme.get, call_604800.host, call_604800.base,
                         call_604800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604800, url, valid)

proc call*(call_604801: Call_GetRemoveSourceIdentifierFromSubscription_604786;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-01-10"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_604802 = newJObject()
  add(query_604802, "Action", newJString(Action))
  add(query_604802, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_604802, "SubscriptionName", newJString(SubscriptionName))
  add(query_604802, "Version", newJString(Version))
  result = call_604801.call(nil, query_604802, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_604786(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_604787,
    base: "/", url: url_GetRemoveSourceIdentifierFromSubscription_604788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_604838 = ref object of OpenApiRestCall_602450
proc url_PostRemoveTagsFromResource_604840(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRemoveTagsFromResource_604839(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  valid_604841 = validateParameter(valid_604841, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604841 != nil:
    section.add "Action", valid_604841
  var valid_604842 = query.getOrDefault("Version")
  valid_604842 = validateParameter(valid_604842, JString, required = true,
                                 default = newJString("2013-01-10"))
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
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_604850 = formData.getOrDefault("TagKeys")
  valid_604850 = validateParameter(valid_604850, JArray, required = true, default = nil)
  if valid_604850 != nil:
    section.add "TagKeys", valid_604850
  var valid_604851 = formData.getOrDefault("ResourceName")
  valid_604851 = validateParameter(valid_604851, JString, required = true,
                                 default = nil)
  if valid_604851 != nil:
    section.add "ResourceName", valid_604851
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604852: Call_PostRemoveTagsFromResource_604838; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604852.validator(path, query, header, formData, body)
  let scheme = call_604852.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604852.url(scheme.get, call_604852.host, call_604852.base,
                         call_604852.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604852, url, valid)

proc call*(call_604853: Call_PostRemoveTagsFromResource_604838; TagKeys: JsonNode;
          ResourceName: string; Action: string = "RemoveTagsFromResource";
          Version: string = "2013-01-10"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_604854 = newJObject()
  var formData_604855 = newJObject()
  add(query_604854, "Action", newJString(Action))
  if TagKeys != nil:
    formData_604855.add "TagKeys", TagKeys
  add(formData_604855, "ResourceName", newJString(ResourceName))
  add(query_604854, "Version", newJString(Version))
  result = call_604853.call(nil, query_604854, nil, formData_604855, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_604838(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_604839, base: "/",
    url: url_PostRemoveTagsFromResource_604840,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_604821 = ref object of OpenApiRestCall_602450
proc url_GetRemoveTagsFromResource_604823(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRemoveTagsFromResource_604822(path: JsonNode; query: JsonNode;
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
  var valid_604824 = query.getOrDefault("ResourceName")
  valid_604824 = validateParameter(valid_604824, JString, required = true,
                                 default = nil)
  if valid_604824 != nil:
    section.add "ResourceName", valid_604824
  var valid_604825 = query.getOrDefault("Action")
  valid_604825 = validateParameter(valid_604825, JString, required = true,
                                 default = newJString("RemoveTagsFromResource"))
  if valid_604825 != nil:
    section.add "Action", valid_604825
  var valid_604826 = query.getOrDefault("TagKeys")
  valid_604826 = validateParameter(valid_604826, JArray, required = true, default = nil)
  if valid_604826 != nil:
    section.add "TagKeys", valid_604826
  var valid_604827 = query.getOrDefault("Version")
  valid_604827 = validateParameter(valid_604827, JString, required = true,
                                 default = newJString("2013-01-10"))
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

proc call*(call_604835: Call_GetRemoveTagsFromResource_604821; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604835.validator(path, query, header, formData, body)
  let scheme = call_604835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604835.url(scheme.get, call_604835.host, call_604835.base,
                         call_604835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604835, url, valid)

proc call*(call_604836: Call_GetRemoveTagsFromResource_604821;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-01-10"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_604837 = newJObject()
  add(query_604837, "ResourceName", newJString(ResourceName))
  add(query_604837, "Action", newJString(Action))
  if TagKeys != nil:
    query_604837.add "TagKeys", TagKeys
  add(query_604837, "Version", newJString(Version))
  result = call_604836.call(nil, query_604837, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_604821(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_604822, base: "/",
    url: url_GetRemoveTagsFromResource_604823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_604874 = ref object of OpenApiRestCall_602450
proc url_PostResetDBParameterGroup_604876(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostResetDBParameterGroup_604875(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604877 = query.getOrDefault("Action")
  valid_604877 = validateParameter(valid_604877, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604877 != nil:
    section.add "Action", valid_604877
  var valid_604878 = query.getOrDefault("Version")
  valid_604878 = validateParameter(valid_604878, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604878 != nil:
    section.add "Version", valid_604878
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604879 = header.getOrDefault("X-Amz-Date")
  valid_604879 = validateParameter(valid_604879, JString, required = false,
                                 default = nil)
  if valid_604879 != nil:
    section.add "X-Amz-Date", valid_604879
  var valid_604880 = header.getOrDefault("X-Amz-Security-Token")
  valid_604880 = validateParameter(valid_604880, JString, required = false,
                                 default = nil)
  if valid_604880 != nil:
    section.add "X-Amz-Security-Token", valid_604880
  var valid_604881 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604881 = validateParameter(valid_604881, JString, required = false,
                                 default = nil)
  if valid_604881 != nil:
    section.add "X-Amz-Content-Sha256", valid_604881
  var valid_604882 = header.getOrDefault("X-Amz-Algorithm")
  valid_604882 = validateParameter(valid_604882, JString, required = false,
                                 default = nil)
  if valid_604882 != nil:
    section.add "X-Amz-Algorithm", valid_604882
  var valid_604883 = header.getOrDefault("X-Amz-Signature")
  valid_604883 = validateParameter(valid_604883, JString, required = false,
                                 default = nil)
  if valid_604883 != nil:
    section.add "X-Amz-Signature", valid_604883
  var valid_604884 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604884 = validateParameter(valid_604884, JString, required = false,
                                 default = nil)
  if valid_604884 != nil:
    section.add "X-Amz-SignedHeaders", valid_604884
  var valid_604885 = header.getOrDefault("X-Amz-Credential")
  valid_604885 = validateParameter(valid_604885, JString, required = false,
                                 default = nil)
  if valid_604885 != nil:
    section.add "X-Amz-Credential", valid_604885
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_604886 = formData.getOrDefault("DBParameterGroupName")
  valid_604886 = validateParameter(valid_604886, JString, required = true,
                                 default = nil)
  if valid_604886 != nil:
    section.add "DBParameterGroupName", valid_604886
  var valid_604887 = formData.getOrDefault("Parameters")
  valid_604887 = validateParameter(valid_604887, JArray, required = false,
                                 default = nil)
  if valid_604887 != nil:
    section.add "Parameters", valid_604887
  var valid_604888 = formData.getOrDefault("ResetAllParameters")
  valid_604888 = validateParameter(valid_604888, JBool, required = false, default = nil)
  if valid_604888 != nil:
    section.add "ResetAllParameters", valid_604888
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604889: Call_PostResetDBParameterGroup_604874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604889.validator(path, query, header, formData, body)
  let scheme = call_604889.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604889.url(scheme.get, call_604889.host, call_604889.base,
                         call_604889.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604889, url, valid)

proc call*(call_604890: Call_PostResetDBParameterGroup_604874;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604891 = newJObject()
  var formData_604892 = newJObject()
  add(formData_604892, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_604892.add "Parameters", Parameters
  add(query_604891, "Action", newJString(Action))
  add(formData_604892, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604891, "Version", newJString(Version))
  result = call_604890.call(nil, query_604891, nil, formData_604892, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_604874(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_604875, base: "/",
    url: url_PostResetDBParameterGroup_604876,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_604856 = ref object of OpenApiRestCall_602450
proc url_GetResetDBParameterGroup_604858(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetResetDBParameterGroup_604857(path: JsonNode; query: JsonNode;
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
  var valid_604859 = query.getOrDefault("DBParameterGroupName")
  valid_604859 = validateParameter(valid_604859, JString, required = true,
                                 default = nil)
  if valid_604859 != nil:
    section.add "DBParameterGroupName", valid_604859
  var valid_604860 = query.getOrDefault("Parameters")
  valid_604860 = validateParameter(valid_604860, JArray, required = false,
                                 default = nil)
  if valid_604860 != nil:
    section.add "Parameters", valid_604860
  var valid_604861 = query.getOrDefault("Action")
  valid_604861 = validateParameter(valid_604861, JString, required = true,
                                 default = newJString("ResetDBParameterGroup"))
  if valid_604861 != nil:
    section.add "Action", valid_604861
  var valid_604862 = query.getOrDefault("ResetAllParameters")
  valid_604862 = validateParameter(valid_604862, JBool, required = false, default = nil)
  if valid_604862 != nil:
    section.add "ResetAllParameters", valid_604862
  var valid_604863 = query.getOrDefault("Version")
  valid_604863 = validateParameter(valid_604863, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604863 != nil:
    section.add "Version", valid_604863
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604864 = header.getOrDefault("X-Amz-Date")
  valid_604864 = validateParameter(valid_604864, JString, required = false,
                                 default = nil)
  if valid_604864 != nil:
    section.add "X-Amz-Date", valid_604864
  var valid_604865 = header.getOrDefault("X-Amz-Security-Token")
  valid_604865 = validateParameter(valid_604865, JString, required = false,
                                 default = nil)
  if valid_604865 != nil:
    section.add "X-Amz-Security-Token", valid_604865
  var valid_604866 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604866 = validateParameter(valid_604866, JString, required = false,
                                 default = nil)
  if valid_604866 != nil:
    section.add "X-Amz-Content-Sha256", valid_604866
  var valid_604867 = header.getOrDefault("X-Amz-Algorithm")
  valid_604867 = validateParameter(valid_604867, JString, required = false,
                                 default = nil)
  if valid_604867 != nil:
    section.add "X-Amz-Algorithm", valid_604867
  var valid_604868 = header.getOrDefault("X-Amz-Signature")
  valid_604868 = validateParameter(valid_604868, JString, required = false,
                                 default = nil)
  if valid_604868 != nil:
    section.add "X-Amz-Signature", valid_604868
  var valid_604869 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604869 = validateParameter(valid_604869, JString, required = false,
                                 default = nil)
  if valid_604869 != nil:
    section.add "X-Amz-SignedHeaders", valid_604869
  var valid_604870 = header.getOrDefault("X-Amz-Credential")
  valid_604870 = validateParameter(valid_604870, JString, required = false,
                                 default = nil)
  if valid_604870 != nil:
    section.add "X-Amz-Credential", valid_604870
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604871: Call_GetResetDBParameterGroup_604856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_604871.validator(path, query, header, formData, body)
  let scheme = call_604871.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604871.url(scheme.get, call_604871.host, call_604871.base,
                         call_604871.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604871, url, valid)

proc call*(call_604872: Call_GetResetDBParameterGroup_604856;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-01-10"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_604873 = newJObject()
  add(query_604873, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_604873.add "Parameters", Parameters
  add(query_604873, "Action", newJString(Action))
  add(query_604873, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_604873, "Version", newJString(Version))
  result = call_604872.call(nil, query_604873, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_604856(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_604857, base: "/",
    url: url_GetResetDBParameterGroup_604858, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_604922 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceFromDBSnapshot_604924(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_604923(path: JsonNode;
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
  var valid_604925 = query.getOrDefault("Action")
  valid_604925 = validateParameter(valid_604925, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_604925 != nil:
    section.add "Action", valid_604925
  var valid_604926 = query.getOrDefault("Version")
  valid_604926 = validateParameter(valid_604926, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604926 != nil:
    section.add "Version", valid_604926
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604927 = header.getOrDefault("X-Amz-Date")
  valid_604927 = validateParameter(valid_604927, JString, required = false,
                                 default = nil)
  if valid_604927 != nil:
    section.add "X-Amz-Date", valid_604927
  var valid_604928 = header.getOrDefault("X-Amz-Security-Token")
  valid_604928 = validateParameter(valid_604928, JString, required = false,
                                 default = nil)
  if valid_604928 != nil:
    section.add "X-Amz-Security-Token", valid_604928
  var valid_604929 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604929 = validateParameter(valid_604929, JString, required = false,
                                 default = nil)
  if valid_604929 != nil:
    section.add "X-Amz-Content-Sha256", valid_604929
  var valid_604930 = header.getOrDefault("X-Amz-Algorithm")
  valid_604930 = validateParameter(valid_604930, JString, required = false,
                                 default = nil)
  if valid_604930 != nil:
    section.add "X-Amz-Algorithm", valid_604930
  var valid_604931 = header.getOrDefault("X-Amz-Signature")
  valid_604931 = validateParameter(valid_604931, JString, required = false,
                                 default = nil)
  if valid_604931 != nil:
    section.add "X-Amz-Signature", valid_604931
  var valid_604932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604932 = validateParameter(valid_604932, JString, required = false,
                                 default = nil)
  if valid_604932 != nil:
    section.add "X-Amz-SignedHeaders", valid_604932
  var valid_604933 = header.getOrDefault("X-Amz-Credential")
  valid_604933 = validateParameter(valid_604933, JString, required = false,
                                 default = nil)
  if valid_604933 != nil:
    section.add "X-Amz-Credential", valid_604933
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
  var valid_604934 = formData.getOrDefault("Port")
  valid_604934 = validateParameter(valid_604934, JInt, required = false, default = nil)
  if valid_604934 != nil:
    section.add "Port", valid_604934
  var valid_604935 = formData.getOrDefault("Engine")
  valid_604935 = validateParameter(valid_604935, JString, required = false,
                                 default = nil)
  if valid_604935 != nil:
    section.add "Engine", valid_604935
  var valid_604936 = formData.getOrDefault("Iops")
  valid_604936 = validateParameter(valid_604936, JInt, required = false, default = nil)
  if valid_604936 != nil:
    section.add "Iops", valid_604936
  var valid_604937 = formData.getOrDefault("DBName")
  valid_604937 = validateParameter(valid_604937, JString, required = false,
                                 default = nil)
  if valid_604937 != nil:
    section.add "DBName", valid_604937
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_604938 = formData.getOrDefault("DBInstanceIdentifier")
  valid_604938 = validateParameter(valid_604938, JString, required = true,
                                 default = nil)
  if valid_604938 != nil:
    section.add "DBInstanceIdentifier", valid_604938
  var valid_604939 = formData.getOrDefault("OptionGroupName")
  valid_604939 = validateParameter(valid_604939, JString, required = false,
                                 default = nil)
  if valid_604939 != nil:
    section.add "OptionGroupName", valid_604939
  var valid_604940 = formData.getOrDefault("DBSubnetGroupName")
  valid_604940 = validateParameter(valid_604940, JString, required = false,
                                 default = nil)
  if valid_604940 != nil:
    section.add "DBSubnetGroupName", valid_604940
  var valid_604941 = formData.getOrDefault("AvailabilityZone")
  valid_604941 = validateParameter(valid_604941, JString, required = false,
                                 default = nil)
  if valid_604941 != nil:
    section.add "AvailabilityZone", valid_604941
  var valid_604942 = formData.getOrDefault("MultiAZ")
  valid_604942 = validateParameter(valid_604942, JBool, required = false, default = nil)
  if valid_604942 != nil:
    section.add "MultiAZ", valid_604942
  var valid_604943 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_604943 = validateParameter(valid_604943, JString, required = true,
                                 default = nil)
  if valid_604943 != nil:
    section.add "DBSnapshotIdentifier", valid_604943
  var valid_604944 = formData.getOrDefault("PubliclyAccessible")
  valid_604944 = validateParameter(valid_604944, JBool, required = false, default = nil)
  if valid_604944 != nil:
    section.add "PubliclyAccessible", valid_604944
  var valid_604945 = formData.getOrDefault("DBInstanceClass")
  valid_604945 = validateParameter(valid_604945, JString, required = false,
                                 default = nil)
  if valid_604945 != nil:
    section.add "DBInstanceClass", valid_604945
  var valid_604946 = formData.getOrDefault("LicenseModel")
  valid_604946 = validateParameter(valid_604946, JString, required = false,
                                 default = nil)
  if valid_604946 != nil:
    section.add "LicenseModel", valid_604946
  var valid_604947 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_604947 = validateParameter(valid_604947, JBool, required = false, default = nil)
  if valid_604947 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604947
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604948: Call_PostRestoreDBInstanceFromDBSnapshot_604922;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604948.validator(path, query, header, formData, body)
  let scheme = call_604948.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604948.url(scheme.get, call_604948.host, call_604948.base,
                         call_604948.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604948, url, valid)

proc call*(call_604949: Call_PostRestoreDBInstanceFromDBSnapshot_604922;
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
  var query_604950 = newJObject()
  var formData_604951 = newJObject()
  add(formData_604951, "Port", newJInt(Port))
  add(formData_604951, "Engine", newJString(Engine))
  add(formData_604951, "Iops", newJInt(Iops))
  add(formData_604951, "DBName", newJString(DBName))
  add(formData_604951, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_604951, "OptionGroupName", newJString(OptionGroupName))
  add(formData_604951, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_604951, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_604951, "MultiAZ", newJBool(MultiAZ))
  add(formData_604951, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_604950, "Action", newJString(Action))
  add(formData_604951, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_604951, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_604951, "LicenseModel", newJString(LicenseModel))
  add(formData_604951, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_604950, "Version", newJString(Version))
  result = call_604949.call(nil, query_604950, nil, formData_604951, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_604922(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_604923, base: "/",
    url: url_PostRestoreDBInstanceFromDBSnapshot_604924,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_604893 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceFromDBSnapshot_604895(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_604894(path: JsonNode;
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
  var valid_604896 = query.getOrDefault("Engine")
  valid_604896 = validateParameter(valid_604896, JString, required = false,
                                 default = nil)
  if valid_604896 != nil:
    section.add "Engine", valid_604896
  var valid_604897 = query.getOrDefault("OptionGroupName")
  valid_604897 = validateParameter(valid_604897, JString, required = false,
                                 default = nil)
  if valid_604897 != nil:
    section.add "OptionGroupName", valid_604897
  var valid_604898 = query.getOrDefault("AvailabilityZone")
  valid_604898 = validateParameter(valid_604898, JString, required = false,
                                 default = nil)
  if valid_604898 != nil:
    section.add "AvailabilityZone", valid_604898
  var valid_604899 = query.getOrDefault("Iops")
  valid_604899 = validateParameter(valid_604899, JInt, required = false, default = nil)
  if valid_604899 != nil:
    section.add "Iops", valid_604899
  var valid_604900 = query.getOrDefault("MultiAZ")
  valid_604900 = validateParameter(valid_604900, JBool, required = false, default = nil)
  if valid_604900 != nil:
    section.add "MultiAZ", valid_604900
  var valid_604901 = query.getOrDefault("LicenseModel")
  valid_604901 = validateParameter(valid_604901, JString, required = false,
                                 default = nil)
  if valid_604901 != nil:
    section.add "LicenseModel", valid_604901
  var valid_604902 = query.getOrDefault("DBName")
  valid_604902 = validateParameter(valid_604902, JString, required = false,
                                 default = nil)
  if valid_604902 != nil:
    section.add "DBName", valid_604902
  var valid_604903 = query.getOrDefault("DBInstanceClass")
  valid_604903 = validateParameter(valid_604903, JString, required = false,
                                 default = nil)
  if valid_604903 != nil:
    section.add "DBInstanceClass", valid_604903
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_604904 = query.getOrDefault("Action")
  valid_604904 = validateParameter(valid_604904, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_604904 != nil:
    section.add "Action", valid_604904
  var valid_604905 = query.getOrDefault("DBSubnetGroupName")
  valid_604905 = validateParameter(valid_604905, JString, required = false,
                                 default = nil)
  if valid_604905 != nil:
    section.add "DBSubnetGroupName", valid_604905
  var valid_604906 = query.getOrDefault("PubliclyAccessible")
  valid_604906 = validateParameter(valid_604906, JBool, required = false, default = nil)
  if valid_604906 != nil:
    section.add "PubliclyAccessible", valid_604906
  var valid_604907 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604907 = validateParameter(valid_604907, JBool, required = false, default = nil)
  if valid_604907 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604907
  var valid_604908 = query.getOrDefault("Port")
  valid_604908 = validateParameter(valid_604908, JInt, required = false, default = nil)
  if valid_604908 != nil:
    section.add "Port", valid_604908
  var valid_604909 = query.getOrDefault("Version")
  valid_604909 = validateParameter(valid_604909, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604909 != nil:
    section.add "Version", valid_604909
  var valid_604910 = query.getOrDefault("DBInstanceIdentifier")
  valid_604910 = validateParameter(valid_604910, JString, required = true,
                                 default = nil)
  if valid_604910 != nil:
    section.add "DBInstanceIdentifier", valid_604910
  var valid_604911 = query.getOrDefault("DBSnapshotIdentifier")
  valid_604911 = validateParameter(valid_604911, JString, required = true,
                                 default = nil)
  if valid_604911 != nil:
    section.add "DBSnapshotIdentifier", valid_604911
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604912 = header.getOrDefault("X-Amz-Date")
  valid_604912 = validateParameter(valid_604912, JString, required = false,
                                 default = nil)
  if valid_604912 != nil:
    section.add "X-Amz-Date", valid_604912
  var valid_604913 = header.getOrDefault("X-Amz-Security-Token")
  valid_604913 = validateParameter(valid_604913, JString, required = false,
                                 default = nil)
  if valid_604913 != nil:
    section.add "X-Amz-Security-Token", valid_604913
  var valid_604914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604914 = validateParameter(valid_604914, JString, required = false,
                                 default = nil)
  if valid_604914 != nil:
    section.add "X-Amz-Content-Sha256", valid_604914
  var valid_604915 = header.getOrDefault("X-Amz-Algorithm")
  valid_604915 = validateParameter(valid_604915, JString, required = false,
                                 default = nil)
  if valid_604915 != nil:
    section.add "X-Amz-Algorithm", valid_604915
  var valid_604916 = header.getOrDefault("X-Amz-Signature")
  valid_604916 = validateParameter(valid_604916, JString, required = false,
                                 default = nil)
  if valid_604916 != nil:
    section.add "X-Amz-Signature", valid_604916
  var valid_604917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604917 = validateParameter(valid_604917, JString, required = false,
                                 default = nil)
  if valid_604917 != nil:
    section.add "X-Amz-SignedHeaders", valid_604917
  var valid_604918 = header.getOrDefault("X-Amz-Credential")
  valid_604918 = validateParameter(valid_604918, JString, required = false,
                                 default = nil)
  if valid_604918 != nil:
    section.add "X-Amz-Credential", valid_604918
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604919: Call_GetRestoreDBInstanceFromDBSnapshot_604893;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604919.validator(path, query, header, formData, body)
  let scheme = call_604919.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604919.url(scheme.get, call_604919.host, call_604919.base,
                         call_604919.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604919, url, valid)

proc call*(call_604920: Call_GetRestoreDBInstanceFromDBSnapshot_604893;
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
  var query_604921 = newJObject()
  add(query_604921, "Engine", newJString(Engine))
  add(query_604921, "OptionGroupName", newJString(OptionGroupName))
  add(query_604921, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_604921, "Iops", newJInt(Iops))
  add(query_604921, "MultiAZ", newJBool(MultiAZ))
  add(query_604921, "LicenseModel", newJString(LicenseModel))
  add(query_604921, "DBName", newJString(DBName))
  add(query_604921, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604921, "Action", newJString(Action))
  add(query_604921, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604921, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604921, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604921, "Port", newJInt(Port))
  add(query_604921, "Version", newJString(Version))
  add(query_604921, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_604921, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_604920.call(nil, query_604921, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_604893(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_604894, base: "/",
    url: url_GetRestoreDBInstanceFromDBSnapshot_604895,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_604983 = ref object of OpenApiRestCall_602450
proc url_PostRestoreDBInstanceToPointInTime_604985(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_604984(path: JsonNode;
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
  var valid_604986 = query.getOrDefault("Action")
  valid_604986 = validateParameter(valid_604986, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_604986 != nil:
    section.add "Action", valid_604986
  var valid_604987 = query.getOrDefault("Version")
  valid_604987 = validateParameter(valid_604987, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604987 != nil:
    section.add "Version", valid_604987
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604988 = header.getOrDefault("X-Amz-Date")
  valid_604988 = validateParameter(valid_604988, JString, required = false,
                                 default = nil)
  if valid_604988 != nil:
    section.add "X-Amz-Date", valid_604988
  var valid_604989 = header.getOrDefault("X-Amz-Security-Token")
  valid_604989 = validateParameter(valid_604989, JString, required = false,
                                 default = nil)
  if valid_604989 != nil:
    section.add "X-Amz-Security-Token", valid_604989
  var valid_604990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604990 = validateParameter(valid_604990, JString, required = false,
                                 default = nil)
  if valid_604990 != nil:
    section.add "X-Amz-Content-Sha256", valid_604990
  var valid_604991 = header.getOrDefault("X-Amz-Algorithm")
  valid_604991 = validateParameter(valid_604991, JString, required = false,
                                 default = nil)
  if valid_604991 != nil:
    section.add "X-Amz-Algorithm", valid_604991
  var valid_604992 = header.getOrDefault("X-Amz-Signature")
  valid_604992 = validateParameter(valid_604992, JString, required = false,
                                 default = nil)
  if valid_604992 != nil:
    section.add "X-Amz-Signature", valid_604992
  var valid_604993 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604993 = validateParameter(valid_604993, JString, required = false,
                                 default = nil)
  if valid_604993 != nil:
    section.add "X-Amz-SignedHeaders", valid_604993
  var valid_604994 = header.getOrDefault("X-Amz-Credential")
  valid_604994 = validateParameter(valid_604994, JString, required = false,
                                 default = nil)
  if valid_604994 != nil:
    section.add "X-Amz-Credential", valid_604994
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
  var valid_604995 = formData.getOrDefault("UseLatestRestorableTime")
  valid_604995 = validateParameter(valid_604995, JBool, required = false, default = nil)
  if valid_604995 != nil:
    section.add "UseLatestRestorableTime", valid_604995
  var valid_604996 = formData.getOrDefault("Port")
  valid_604996 = validateParameter(valid_604996, JInt, required = false, default = nil)
  if valid_604996 != nil:
    section.add "Port", valid_604996
  var valid_604997 = formData.getOrDefault("Engine")
  valid_604997 = validateParameter(valid_604997, JString, required = false,
                                 default = nil)
  if valid_604997 != nil:
    section.add "Engine", valid_604997
  var valid_604998 = formData.getOrDefault("Iops")
  valid_604998 = validateParameter(valid_604998, JInt, required = false, default = nil)
  if valid_604998 != nil:
    section.add "Iops", valid_604998
  var valid_604999 = formData.getOrDefault("DBName")
  valid_604999 = validateParameter(valid_604999, JString, required = false,
                                 default = nil)
  if valid_604999 != nil:
    section.add "DBName", valid_604999
  var valid_605000 = formData.getOrDefault("OptionGroupName")
  valid_605000 = validateParameter(valid_605000, JString, required = false,
                                 default = nil)
  if valid_605000 != nil:
    section.add "OptionGroupName", valid_605000
  var valid_605001 = formData.getOrDefault("DBSubnetGroupName")
  valid_605001 = validateParameter(valid_605001, JString, required = false,
                                 default = nil)
  if valid_605001 != nil:
    section.add "DBSubnetGroupName", valid_605001
  var valid_605002 = formData.getOrDefault("AvailabilityZone")
  valid_605002 = validateParameter(valid_605002, JString, required = false,
                                 default = nil)
  if valid_605002 != nil:
    section.add "AvailabilityZone", valid_605002
  var valid_605003 = formData.getOrDefault("MultiAZ")
  valid_605003 = validateParameter(valid_605003, JBool, required = false, default = nil)
  if valid_605003 != nil:
    section.add "MultiAZ", valid_605003
  var valid_605004 = formData.getOrDefault("RestoreTime")
  valid_605004 = validateParameter(valid_605004, JString, required = false,
                                 default = nil)
  if valid_605004 != nil:
    section.add "RestoreTime", valid_605004
  var valid_605005 = formData.getOrDefault("PubliclyAccessible")
  valid_605005 = validateParameter(valid_605005, JBool, required = false, default = nil)
  if valid_605005 != nil:
    section.add "PubliclyAccessible", valid_605005
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_605006 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_605006 = validateParameter(valid_605006, JString, required = true,
                                 default = nil)
  if valid_605006 != nil:
    section.add "TargetDBInstanceIdentifier", valid_605006
  var valid_605007 = formData.getOrDefault("DBInstanceClass")
  valid_605007 = validateParameter(valid_605007, JString, required = false,
                                 default = nil)
  if valid_605007 != nil:
    section.add "DBInstanceClass", valid_605007
  var valid_605008 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_605008 = validateParameter(valid_605008, JString, required = true,
                                 default = nil)
  if valid_605008 != nil:
    section.add "SourceDBInstanceIdentifier", valid_605008
  var valid_605009 = formData.getOrDefault("LicenseModel")
  valid_605009 = validateParameter(valid_605009, JString, required = false,
                                 default = nil)
  if valid_605009 != nil:
    section.add "LicenseModel", valid_605009
  var valid_605010 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_605010 = validateParameter(valid_605010, JBool, required = false, default = nil)
  if valid_605010 != nil:
    section.add "AutoMinorVersionUpgrade", valid_605010
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605011: Call_PostRestoreDBInstanceToPointInTime_604983;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605011.validator(path, query, header, formData, body)
  let scheme = call_605011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605011.url(scheme.get, call_605011.host, call_605011.base,
                         call_605011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605011, url, valid)

proc call*(call_605012: Call_PostRestoreDBInstanceToPointInTime_604983;
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
  var query_605013 = newJObject()
  var formData_605014 = newJObject()
  add(formData_605014, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_605014, "Port", newJInt(Port))
  add(formData_605014, "Engine", newJString(Engine))
  add(formData_605014, "Iops", newJInt(Iops))
  add(formData_605014, "DBName", newJString(DBName))
  add(formData_605014, "OptionGroupName", newJString(OptionGroupName))
  add(formData_605014, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_605014, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_605014, "MultiAZ", newJBool(MultiAZ))
  add(query_605013, "Action", newJString(Action))
  add(formData_605014, "RestoreTime", newJString(RestoreTime))
  add(formData_605014, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_605014, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_605014, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_605014, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_605014, "LicenseModel", newJString(LicenseModel))
  add(formData_605014, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_605013, "Version", newJString(Version))
  result = call_605012.call(nil, query_605013, nil, formData_605014, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_604983(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_604984, base: "/",
    url: url_PostRestoreDBInstanceToPointInTime_604985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_604952 = ref object of OpenApiRestCall_602450
proc url_GetRestoreDBInstanceToPointInTime_604954(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_604953(path: JsonNode;
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
  var valid_604955 = query.getOrDefault("Engine")
  valid_604955 = validateParameter(valid_604955, JString, required = false,
                                 default = nil)
  if valid_604955 != nil:
    section.add "Engine", valid_604955
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_604956 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_604956 = validateParameter(valid_604956, JString, required = true,
                                 default = nil)
  if valid_604956 != nil:
    section.add "SourceDBInstanceIdentifier", valid_604956
  var valid_604957 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_604957 = validateParameter(valid_604957, JString, required = true,
                                 default = nil)
  if valid_604957 != nil:
    section.add "TargetDBInstanceIdentifier", valid_604957
  var valid_604958 = query.getOrDefault("AvailabilityZone")
  valid_604958 = validateParameter(valid_604958, JString, required = false,
                                 default = nil)
  if valid_604958 != nil:
    section.add "AvailabilityZone", valid_604958
  var valid_604959 = query.getOrDefault("Iops")
  valid_604959 = validateParameter(valid_604959, JInt, required = false, default = nil)
  if valid_604959 != nil:
    section.add "Iops", valid_604959
  var valid_604960 = query.getOrDefault("OptionGroupName")
  valid_604960 = validateParameter(valid_604960, JString, required = false,
                                 default = nil)
  if valid_604960 != nil:
    section.add "OptionGroupName", valid_604960
  var valid_604961 = query.getOrDefault("RestoreTime")
  valid_604961 = validateParameter(valid_604961, JString, required = false,
                                 default = nil)
  if valid_604961 != nil:
    section.add "RestoreTime", valid_604961
  var valid_604962 = query.getOrDefault("MultiAZ")
  valid_604962 = validateParameter(valid_604962, JBool, required = false, default = nil)
  if valid_604962 != nil:
    section.add "MultiAZ", valid_604962
  var valid_604963 = query.getOrDefault("LicenseModel")
  valid_604963 = validateParameter(valid_604963, JString, required = false,
                                 default = nil)
  if valid_604963 != nil:
    section.add "LicenseModel", valid_604963
  var valid_604964 = query.getOrDefault("DBName")
  valid_604964 = validateParameter(valid_604964, JString, required = false,
                                 default = nil)
  if valid_604964 != nil:
    section.add "DBName", valid_604964
  var valid_604965 = query.getOrDefault("DBInstanceClass")
  valid_604965 = validateParameter(valid_604965, JString, required = false,
                                 default = nil)
  if valid_604965 != nil:
    section.add "DBInstanceClass", valid_604965
  var valid_604966 = query.getOrDefault("Action")
  valid_604966 = validateParameter(valid_604966, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_604966 != nil:
    section.add "Action", valid_604966
  var valid_604967 = query.getOrDefault("UseLatestRestorableTime")
  valid_604967 = validateParameter(valid_604967, JBool, required = false, default = nil)
  if valid_604967 != nil:
    section.add "UseLatestRestorableTime", valid_604967
  var valid_604968 = query.getOrDefault("DBSubnetGroupName")
  valid_604968 = validateParameter(valid_604968, JString, required = false,
                                 default = nil)
  if valid_604968 != nil:
    section.add "DBSubnetGroupName", valid_604968
  var valid_604969 = query.getOrDefault("PubliclyAccessible")
  valid_604969 = validateParameter(valid_604969, JBool, required = false, default = nil)
  if valid_604969 != nil:
    section.add "PubliclyAccessible", valid_604969
  var valid_604970 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_604970 = validateParameter(valid_604970, JBool, required = false, default = nil)
  if valid_604970 != nil:
    section.add "AutoMinorVersionUpgrade", valid_604970
  var valid_604971 = query.getOrDefault("Port")
  valid_604971 = validateParameter(valid_604971, JInt, required = false, default = nil)
  if valid_604971 != nil:
    section.add "Port", valid_604971
  var valid_604972 = query.getOrDefault("Version")
  valid_604972 = validateParameter(valid_604972, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_604972 != nil:
    section.add "Version", valid_604972
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_604973 = header.getOrDefault("X-Amz-Date")
  valid_604973 = validateParameter(valid_604973, JString, required = false,
                                 default = nil)
  if valid_604973 != nil:
    section.add "X-Amz-Date", valid_604973
  var valid_604974 = header.getOrDefault("X-Amz-Security-Token")
  valid_604974 = validateParameter(valid_604974, JString, required = false,
                                 default = nil)
  if valid_604974 != nil:
    section.add "X-Amz-Security-Token", valid_604974
  var valid_604975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_604975 = validateParameter(valid_604975, JString, required = false,
                                 default = nil)
  if valid_604975 != nil:
    section.add "X-Amz-Content-Sha256", valid_604975
  var valid_604976 = header.getOrDefault("X-Amz-Algorithm")
  valid_604976 = validateParameter(valid_604976, JString, required = false,
                                 default = nil)
  if valid_604976 != nil:
    section.add "X-Amz-Algorithm", valid_604976
  var valid_604977 = header.getOrDefault("X-Amz-Signature")
  valid_604977 = validateParameter(valid_604977, JString, required = false,
                                 default = nil)
  if valid_604977 != nil:
    section.add "X-Amz-Signature", valid_604977
  var valid_604978 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_604978 = validateParameter(valid_604978, JString, required = false,
                                 default = nil)
  if valid_604978 != nil:
    section.add "X-Amz-SignedHeaders", valid_604978
  var valid_604979 = header.getOrDefault("X-Amz-Credential")
  valid_604979 = validateParameter(valid_604979, JString, required = false,
                                 default = nil)
  if valid_604979 != nil:
    section.add "X-Amz-Credential", valid_604979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_604980: Call_GetRestoreDBInstanceToPointInTime_604952;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_604980.validator(path, query, header, formData, body)
  let scheme = call_604980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_604980.url(scheme.get, call_604980.host, call_604980.base,
                         call_604980.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_604980, url, valid)

proc call*(call_604981: Call_GetRestoreDBInstanceToPointInTime_604952;
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
  var query_604982 = newJObject()
  add(query_604982, "Engine", newJString(Engine))
  add(query_604982, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_604982, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_604982, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_604982, "Iops", newJInt(Iops))
  add(query_604982, "OptionGroupName", newJString(OptionGroupName))
  add(query_604982, "RestoreTime", newJString(RestoreTime))
  add(query_604982, "MultiAZ", newJBool(MultiAZ))
  add(query_604982, "LicenseModel", newJString(LicenseModel))
  add(query_604982, "DBName", newJString(DBName))
  add(query_604982, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_604982, "Action", newJString(Action))
  add(query_604982, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_604982, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_604982, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_604982, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_604982, "Port", newJInt(Port))
  add(query_604982, "Version", newJString(Version))
  result = call_604981.call(nil, query_604982, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_604952(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_604953, base: "/",
    url: url_GetRestoreDBInstanceToPointInTime_604954,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_605035 = ref object of OpenApiRestCall_602450
proc url_PostRevokeDBSecurityGroupIngress_605037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_605036(path: JsonNode;
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
  var valid_605038 = query.getOrDefault("Action")
  valid_605038 = validateParameter(valid_605038, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605038 != nil:
    section.add "Action", valid_605038
  var valid_605039 = query.getOrDefault("Version")
  valid_605039 = validateParameter(valid_605039, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_605039 != nil:
    section.add "Version", valid_605039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605040 = header.getOrDefault("X-Amz-Date")
  valid_605040 = validateParameter(valid_605040, JString, required = false,
                                 default = nil)
  if valid_605040 != nil:
    section.add "X-Amz-Date", valid_605040
  var valid_605041 = header.getOrDefault("X-Amz-Security-Token")
  valid_605041 = validateParameter(valid_605041, JString, required = false,
                                 default = nil)
  if valid_605041 != nil:
    section.add "X-Amz-Security-Token", valid_605041
  var valid_605042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605042 = validateParameter(valid_605042, JString, required = false,
                                 default = nil)
  if valid_605042 != nil:
    section.add "X-Amz-Content-Sha256", valid_605042
  var valid_605043 = header.getOrDefault("X-Amz-Algorithm")
  valid_605043 = validateParameter(valid_605043, JString, required = false,
                                 default = nil)
  if valid_605043 != nil:
    section.add "X-Amz-Algorithm", valid_605043
  var valid_605044 = header.getOrDefault("X-Amz-Signature")
  valid_605044 = validateParameter(valid_605044, JString, required = false,
                                 default = nil)
  if valid_605044 != nil:
    section.add "X-Amz-Signature", valid_605044
  var valid_605045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605045 = validateParameter(valid_605045, JString, required = false,
                                 default = nil)
  if valid_605045 != nil:
    section.add "X-Amz-SignedHeaders", valid_605045
  var valid_605046 = header.getOrDefault("X-Amz-Credential")
  valid_605046 = validateParameter(valid_605046, JString, required = false,
                                 default = nil)
  if valid_605046 != nil:
    section.add "X-Amz-Credential", valid_605046
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605047 = formData.getOrDefault("DBSecurityGroupName")
  valid_605047 = validateParameter(valid_605047, JString, required = true,
                                 default = nil)
  if valid_605047 != nil:
    section.add "DBSecurityGroupName", valid_605047
  var valid_605048 = formData.getOrDefault("EC2SecurityGroupName")
  valid_605048 = validateParameter(valid_605048, JString, required = false,
                                 default = nil)
  if valid_605048 != nil:
    section.add "EC2SecurityGroupName", valid_605048
  var valid_605049 = formData.getOrDefault("EC2SecurityGroupId")
  valid_605049 = validateParameter(valid_605049, JString, required = false,
                                 default = nil)
  if valid_605049 != nil:
    section.add "EC2SecurityGroupId", valid_605049
  var valid_605050 = formData.getOrDefault("CIDRIP")
  valid_605050 = validateParameter(valid_605050, JString, required = false,
                                 default = nil)
  if valid_605050 != nil:
    section.add "CIDRIP", valid_605050
  var valid_605051 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605051 = validateParameter(valid_605051, JString, required = false,
                                 default = nil)
  if valid_605051 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605052: Call_PostRevokeDBSecurityGroupIngress_605035;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605052.validator(path, query, header, formData, body)
  let scheme = call_605052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605052.url(scheme.get, call_605052.host, call_605052.base,
                         call_605052.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605052, url, valid)

proc call*(call_605053: Call_PostRevokeDBSecurityGroupIngress_605035;
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
  var query_605054 = newJObject()
  var formData_605055 = newJObject()
  add(formData_605055, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605054, "Action", newJString(Action))
  add(formData_605055, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_605055, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_605055, "CIDRIP", newJString(CIDRIP))
  add(query_605054, "Version", newJString(Version))
  add(formData_605055, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_605053.call(nil, query_605054, nil, formData_605055, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_605035(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_605036, base: "/",
    url: url_PostRevokeDBSecurityGroupIngress_605037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_605015 = ref object of OpenApiRestCall_602450
proc url_GetRevokeDBSecurityGroupIngress_605017(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_605016(path: JsonNode;
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
  var valid_605018 = query.getOrDefault("EC2SecurityGroupId")
  valid_605018 = validateParameter(valid_605018, JString, required = false,
                                 default = nil)
  if valid_605018 != nil:
    section.add "EC2SecurityGroupId", valid_605018
  var valid_605019 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_605019 = validateParameter(valid_605019, JString, required = false,
                                 default = nil)
  if valid_605019 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_605019
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_605020 = query.getOrDefault("DBSecurityGroupName")
  valid_605020 = validateParameter(valid_605020, JString, required = true,
                                 default = nil)
  if valid_605020 != nil:
    section.add "DBSecurityGroupName", valid_605020
  var valid_605021 = query.getOrDefault("Action")
  valid_605021 = validateParameter(valid_605021, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_605021 != nil:
    section.add "Action", valid_605021
  var valid_605022 = query.getOrDefault("CIDRIP")
  valid_605022 = validateParameter(valid_605022, JString, required = false,
                                 default = nil)
  if valid_605022 != nil:
    section.add "CIDRIP", valid_605022
  var valid_605023 = query.getOrDefault("EC2SecurityGroupName")
  valid_605023 = validateParameter(valid_605023, JString, required = false,
                                 default = nil)
  if valid_605023 != nil:
    section.add "EC2SecurityGroupName", valid_605023
  var valid_605024 = query.getOrDefault("Version")
  valid_605024 = validateParameter(valid_605024, JString, required = true,
                                 default = newJString("2013-01-10"))
  if valid_605024 != nil:
    section.add "Version", valid_605024
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_605025 = header.getOrDefault("X-Amz-Date")
  valid_605025 = validateParameter(valid_605025, JString, required = false,
                                 default = nil)
  if valid_605025 != nil:
    section.add "X-Amz-Date", valid_605025
  var valid_605026 = header.getOrDefault("X-Amz-Security-Token")
  valid_605026 = validateParameter(valid_605026, JString, required = false,
                                 default = nil)
  if valid_605026 != nil:
    section.add "X-Amz-Security-Token", valid_605026
  var valid_605027 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605027 = validateParameter(valid_605027, JString, required = false,
                                 default = nil)
  if valid_605027 != nil:
    section.add "X-Amz-Content-Sha256", valid_605027
  var valid_605028 = header.getOrDefault("X-Amz-Algorithm")
  valid_605028 = validateParameter(valid_605028, JString, required = false,
                                 default = nil)
  if valid_605028 != nil:
    section.add "X-Amz-Algorithm", valid_605028
  var valid_605029 = header.getOrDefault("X-Amz-Signature")
  valid_605029 = validateParameter(valid_605029, JString, required = false,
                                 default = nil)
  if valid_605029 != nil:
    section.add "X-Amz-Signature", valid_605029
  var valid_605030 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605030 = validateParameter(valid_605030, JString, required = false,
                                 default = nil)
  if valid_605030 != nil:
    section.add "X-Amz-SignedHeaders", valid_605030
  var valid_605031 = header.getOrDefault("X-Amz-Credential")
  valid_605031 = validateParameter(valid_605031, JString, required = false,
                                 default = nil)
  if valid_605031 != nil:
    section.add "X-Amz-Credential", valid_605031
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605032: Call_GetRevokeDBSecurityGroupIngress_605015;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  let valid = call_605032.validator(path, query, header, formData, body)
  let scheme = call_605032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605032.url(scheme.get, call_605032.host, call_605032.base,
                         call_605032.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_605032, url, valid)

proc call*(call_605033: Call_GetRevokeDBSecurityGroupIngress_605015;
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
  var query_605034 = newJObject()
  add(query_605034, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_605034, "EC2SecurityGroupOwnerId", newJString(EC2SecurityGroupOwnerId))
  add(query_605034, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_605034, "Action", newJString(Action))
  add(query_605034, "CIDRIP", newJString(CIDRIP))
  add(query_605034, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_605034, "Version", newJString(Version))
  result = call_605033.call(nil, query_605034, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_605015(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_605016, base: "/",
    url: url_GetRevokeDBSecurityGroupIngress_605017,
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
